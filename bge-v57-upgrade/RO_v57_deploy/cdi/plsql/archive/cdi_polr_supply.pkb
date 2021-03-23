CREATE OR REPLACE PACKAGE BODY CDI_POLR_SUPPLY AS

c_PACKAGE_NAME                 CONSTANT VARCHAR2(32) := 'CDI_POLR_SUPPLY';
c_STEP_NAME                    CONSTANT VARCHAR2(32) := '';
c_CALCULATE_POLR_SUPPLY        CONSTANT VARCHAR2(32) := 'CDI: Calculate POLR Supply';
c_DATE_TIME_FORMAT             CONSTANT VARCHAR2(32) := 'MM/DD/YYYY HH24:MI:SS';

g_FILES                   FILE_NAME_TABLE;
g_DERATION_FCTR_ID        INTERCHANGE_TRANSACTION.TRANSACTION_ID%TYPE;
g_500KV_ID                INTERCHANGE_TRANSACTION.TRANSACTION_ID%TYPE;
g_AREA_ID                 AREA.AREA_ID%TYPE;

PROCEDURE POLR_TYPE_ALL_LIST(p_CURSOR OUT GA.REFCURSOR) AS
BEGIN
   OPEN p_CURSOR FOR
      WITH POLR_TYPE AS
         (SELECT c_ALL "FROM_POLR_TYPE", 1 "SORT_ORDER" FROM DUAL
         UNION SELECT FROM_POLR_TYPE, 2 FROM CDI_POLR_TO_FROM_XREF
         UNION SELECT TO_POLR_TYPE, 2 FROM CDI_POLR_TO_FROM_XREF)
      SELECT FROM_POLR_TYPE, FROM_POLR_TYPE
      FROM POLR_TYPE
      ORDER BY 2, 1;
END POLR_TYPE_ALL_LIST;

PROCEDURE CUSTOMER_CLASS_ALL_LIST(p_CURSOR OUT GA.REFCURSOR) AS
BEGIN
   OPEN p_CURSOR FOR
      WITH CUSTOMER_CLASS AS
        (SELECT c_ALL "FROM_CUST_CLASS", 1 "SORT_ORDER" FROM DUAL
         UNION
         SELECT FROM_CUST_CLASS, 2 FROM CDI_POLR_TO_FROM_XREF
         UNION
         SELECT FROM_CUST_CLASS, 2 FROM CDI_POLR_TO_FROM_XREF)
      SELECT FROM_CUST_CLASS, FROM_CUST_CLASS
      FROM CUSTOMER_CLASS
      ORDER BY 2, 1;
END CUSTOMER_CLASS_ALL_LIST;

PROCEDURE FCLOSE_IF_OPENED(p_FILE_HANDLE IN OUT NOCOPY UTL_FILE.FILE_TYPE) as
BEGIN
   IF UTL_FILE.IS_OPEN(p_FILE_HANDLE) THEN
      UTL_FILE.FCLOSE(p_FILE_HANDLE);
   END IF;
EXCEPTION
   WHEN OTHERS THEN
      NULL;
END FCLOSE_IF_OPENED;

    PROCEDURE MOVE_FILE
        (p_SRC_DIR         IN VARCHAR2,
         p_SRC_FILENAME    IN VARCHAR2,
         p_NEW_DIR         IN VARCHAR2,
         p_NEW_FILENAME    IN VARCHAR2,
         p_OVERWRITE       IN BOOLEAN DEFAULT TRUE,
         p_ADD_TIME_EXT    IN BOOLEAN DEFAULT FALSE,
         p_STATUS          OUT NUMBER)
    IS

         v_NEW_FILENAME    VARCHAR2(256) := CASE WHEN p_ADD_TIME_EXT THEN
                                                      p_NEW_FILENAME||'.'||TO_CHAR(SYSDATE, 'YYYYMMDDHH24MISS')
                                                 ELSE
                                                      p_NEW_FILENAME
                                                 END;

     BEGIN

         p_STATUS := GA.SUCCESS;

         UTL_FILE.FRENAME(p_SRC_DIR, p_SRC_FILENAME, p_NEW_DIR, v_NEW_FILENAME, p_OVERWRITE);

     EXCEPTION
         WHEN OTHERS THEN
              p_STATUS := SQLCODE;

     END MOVE_FILE;
---------------------------------------
    FUNCTION PATH_FOR_DIRECTORY
        (p_DIR_OBJ         IN VARCHAR2)
        RETURN VARCHAR2
    IS

        v_DIRECTORY         VARCHAR2(1024);

    BEGIN

        SELECT  DIRECTORY_PATH
        INTO    v_DIRECTORY
        FROM    ALL_DIRECTORIES
        WHERE   DIRECTORY_NAME = p_DIR_OBJ;

        IF SUBSTR(v_DIRECTORY, -1) IN ('/','\') THEN
           v_DIRECTORY := SUBSTR(v_DIRECTORY,1,LENGTH(v_DIRECTORY)-1);
        END IF;

        RETURN v_DIRECTORY;

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
             RAISE ERR_PKG.e_ORACLE_DIRECTORY_NOT_FOUND;

    END PATH_FOR_DIRECTORY;
---------------------------------------
    PROCEDURE WRITE_TEXT_FILE
        (p_TEXT                 IN OUT GA.BIG_STRING_TABLE,
         p_DIR_OBJ              IN VARCHAR2,
         p_FILE_NAME            IN VARCHAR2,
         p_OPTIONAL_HEADER      IN VARCHAR2 DEFAULT NULL,
         p_STATUS               OUT NUMBER)
    IS

         v_FILE_HANDLE     UTL_FILE.FILE_TYPE;
         v_MESSAGE         VARCHAR2(512);

    BEGIN

         p_STATUS := GA.SUCCESS;
         g_SOURCE := NULL;

         v_FILE_HANDLE := UTL_FILE.FOPEN(p_DIR_OBJ, p_FILE_NAME, 'w', c_MAX_LINE_SIZE);

         g_RESULT := PLOG.UPDATE_PROCESS_PROGRESS(p_PROCESS_ID => g_PROCESS_DESCRIPTOR,
                                                  p_SO_FAR => NULL,
                                                  p_PROGRESS_DESCRIPTION => 'OPTIONAL HEADER');

         IF p_OPTIONAL_HEADER IS NOT NULL THEN
            UTL_FILE.PUT_LINE(v_FILE_HANDLE, p_OPTIONAL_HEADER);
         END IF;

         g_RESULT := PLOG.UPDATE_PROCESS_PROGRESS(p_PROCESS_ID => g_PROCESS_DESCRIPTOR,
                                                  p_SO_FAR => NULL,
                                                  p_PROGRESS_DESCRIPTION => 'UTL_FILE.PUT_LINE');

         FOR i IN 1..p_TEXT.COUNT LOOP

             g_SOURCE := SUBSTR(p_TEXT(i), 1, 1024);
             UTL_FILE.PUT_LINE(v_FILE_HANDLE, p_TEXT(i));

         END LOOP;

         FCLOSE_IF_OPENED(v_FILE_HANDLE);

    EXCEPTION
        WHEN OTHERS THEN
            p_STATUS := SQLCODE;
            v_MESSAGE := SUBSTR(SQLERRM, 1, 512);
            FCLOSE_IF_OPENED(v_FILE_HANDLE);
            g_RESULT := PLOG.LOG_PROCESS_EVENT(p_PROCESS_ID => g_PROCESS_DESCRIPTOR,
                                               p_SEVERITY_LEVEL => PLOG.c_SEV_ERROR,
                                               p_PROCEDURE_NAME => 'WRITE_TEXT_FILE',
                                               p_STEP_NAME => 'WRITE_TEXT_FILE',
                                               p_SOURCE => g_SOURCE,
                                               p_MESSAGE => v_MESSAGE,
                                               p_MESSAGE_DESCRIPTION => p_FILE_NAME||':  '||v_MESSAGE);

    END WRITE_TEXT_FILE;
---------------------------------------
    FUNCTION APPLY_500KV_LOSS
        (p_DATE                 IN DATE,
         p_VOLTAGE_CLASS        IN VARCHAR2,
         p_VALUE                IN NUMBER)
        RETURN NUMBER
    IS

        v_VALUE        NUMBER;
        v_MESSAGE      VARCHAR2(512);
        v_LOSS_FACTOR  NUMBER := 0.0;

    BEGIN

        g_RESULT := PLOG.UPDATE_PROCESS_PROGRESS(p_PROCESS_ID => g_PROCESS_DESCRIPTOR,
                                                 p_SO_FAR => NULL,
                                                 p_PROGRESS_DESCRIPTION => 'APPLY_500KV_LOSS');

        SELECT  p_VALUE / (1 + I.AMOUNT/(A.LOAD_VAL - I.AMOUNT))
        INTO    v_VALUE
        FROM    IT_SCHEDULE I,
                AREA_LOAD A
        WHERE   I.TRANSACTION_ID = g_500KV_ID
        AND     I.SCHEDULE_TYPE = GA.SCHEDULE_TYPE_FINAL
        AND     I.SCHEDULE_STATE = GA.EXTERNAL_STATE
        AND     I.SCHEDULE_DATE = p_DATE
        AND     I.AS_OF_DATE = c_LOW_DATE
        AND     A.CASE_ID = GA.BASE_CASE_ID
        AND     A.AREA_ID = g_AREA_ID
        AND     A.LOAD_CODE = 'A'
        AND     A.LOAD_DATE = p_DATE
        AND     A.AS_OF_DATE = c_LOW_DATE;

        BEGIN

            SELECT  /*+ ORDERED */
                    LFP.PATTERN_VAL
            INTO    v_LOSS_FACTOR
            FROM    LOSS_FACTOR LF, LOSS_FACTOR_MODEL LFM, LOSS_FACTOR_PATTERN LFP
            WHERE   LF.EXTERNAL_IDENTIFIER = p_VOLTAGE_CLASS
            AND     LF.LOSS_FACTOR_ID = LFM.LOSS_FACTOR_ID
            AND     LFM.PATTERN_ID = LFP.PATTERN_ID
            AND     LFM.BEGIN_DATE = LFP.PATTERN_DATE
            AND     LFM.LOSS_FACTOR_TYPE = c_BGE_LOSS_FACTOR_TYPE
            AND     LFM.LOSS_FACTOR_INTERVAL = c_BGE_LOSS_FACTOR_INTERVAL
            AND     FROM_CUT(p_DATE, c_TIME_ZONE) BETWEEN LFM.BEGIN_DATE AND NVL(LFM.END_DATE, c_HIGH_DATE);

        EXCEPTION
           WHEN NO_DATA_FOUND THEN
                v_LOSS_FACTOR := 0.0;
        END;

        RETURN v_VALUE/(1+v_LOSS_FACTOR);

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
             RETURN p_VALUE;
        WHEN ZERO_DIVIDE THEN
             RETURN p_VALUE;
        WHEN OTHERS THEN
             v_MESSAGE := SUBSTR(SQLERRM, 1, 512);
             g_RESULT := PLOG.LOG_PROCESS_EVENT(p_PROCESS_ID => g_PROCESS_DESCRIPTOR,
                                                p_SEVERITY_LEVEL => PLOG.c_SEV_ERROR,
                                                p_PROCEDURE_NAME => 'APPLY_500KV_LOSS',
                                                p_STEP_NAME => 'APPLY_500KV_LOSS',
                                                p_SOURCE => TO_CHAR(p_DATE, 'MM/DD/YYYY HH24:MI:SS'),
                                                p_MESSAGE => v_MESSAGE,
                                                p_MESSAGE_DESCRIPTION => v_MESSAGE);

    END APPLY_500KV_LOSS;
---------------------------------------
    FUNCTION APPLY_DERATION_FACTOR
        (p_DATE                 IN DATE,
         p_VALUE                IN NUMBER)
        RETURN NUMBER
    IS

        v_VALUE     NUMBER;
        v_MESSAGE   VARCHAR2(512);

    BEGIN

        g_RESULT := PLOG.UPDATE_PROCESS_PROGRESS(p_PROCESS_ID => g_PROCESS_DESCRIPTOR,
                                                 p_SO_FAR => NULL,
                                                 p_PROGRESS_DESCRIPTION => 'APPLY_DERATION_FACTOR');

        SELECT  (1 - NVL(I.AMOUNT, 0)) * p_VALUE
        INTO    v_VALUE
        FROM    IT_SCHEDULE I
        WHERE   I.TRANSACTION_ID = g_DERATION_FCTR_ID
        AND     I.SCHEDULE_TYPE = GA.SCHEDULE_TYPE_FINAL
        AND     I.SCHEDULE_STATE = GA.EXTERNAL_STATE
        AND     I.SCHEDULE_DATE = p_DATE
        AND     I.AS_OF_DATE = c_LOW_DATE;

        RETURN v_VALUE;

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
             RETURN p_VALUE;
        WHEN OTHERS THEN
             v_MESSAGE := SUBSTR(SQLERRM, 1, 512);
             g_RESULT := PLOG.LOG_PROCESS_EVENT(p_PROCESS_ID => g_PROCESS_DESCRIPTOR,
                                                p_SEVERITY_LEVEL => PLOG.c_SEV_ERROR,
                                                p_PROCEDURE_NAME => 'APPLY_DERATION_FACTOR',
                                                p_STEP_NAME => 'APPLY_DERATION_FACTOR',
                                                p_SOURCE => TO_CHAR(p_DATE, 'MM/DD/YYYY HH24:MI:SS'),
                                                p_MESSAGE => v_MESSAGE,
                                                p_MESSAGE_DESCRIPTION => v_MESSAGE);

    END APPLY_DERATION_FACTOR;
---------------------------------------
    PROCEDURE CALC_ICAP_SUPPLY
        (p_BEGIN_DATE           IN DATE,
         p_END_DATE             IN DATE,
         p_STATUS               OUT NUMBER,
         p_MESSAGE              OUT VARCHAR2)
    IS

         v_BEGIN_DATE       DATE := LAST_DAY(p_BEGIN_DATE);
         v_END_DATE         DATE := LAST_DAY(p_END_DATE);

    BEGIN

         p_STATUS := GA.SUCCESS;

         EXECUTE IMMEDIATE 'TRUNCATE TABLE CDI_POLR_SUPPLY_TEMP DROP STORAGE';

         DELETE FROM CDI_POLR_ICAP I
         WHERE  I.POLR_DATE BETWEEN v_BEGIN_DATE AND v_END_DATE;

         COMMIT;

         g_RESULT := PLOG.UPDATE_PROCESS_PROGRESS(p_PROCESS_ID => g_PROCESS_DESCRIPTOR,
                                                  p_SO_FAR => NULL,
                                                  p_PROGRESS_DESCRIPTION => 'WHILE LOOP - INSERT INTO CDI_POLR_SUPPLY_TEMP');

         WHILE v_BEGIN_DATE <= v_END_DATE LOOP

            INSERT INTO CDI_POLR_SUPPLY_TEMP(POLR_DATE, POLR_TYPE, CUSTOMER_CLASS, COMP_NONCOMP, KWH1, KWH2, PROCESS)
            SELECT  v_BEGIN_DATE,
                    B.POLR_TYPE,
                    SUBSTR(B.REPORTED_SEGMENT, 1, 3),
                    DECODE(B.SUPPLIER, 'DEFAULT', 'X', 'C'),
                    SUM(C.TAG_VAL),
                    COUNT(1),
                    'I'
            FROM    CDI_PLC_ICAP_TX C,
                    BGE_MASTER_ACCOUNT B
            WHERE   C.BILL_ACCOUNT = B.BILL_ACCOUNT
            AND     C.SERVICE_POINT = B.SERVICE_POINT
            AND     C.PREMISE_NUMBER = B.PREMISE_NUMBER
            AND     v_BEGIN_DATE BETWEEN C.BEGIN_DATE AND C.END_DATE
            AND     v_BEGIN_DATE BETWEEN B.EFFECTIVE_DATE AND B.TERMINATION_DATE
            AND     C.TAG_ID LIKE '%C'
            GROUP BY v_BEGIN_DATE,
                     B.POLR_TYPE,
                     SUBSTR(B.REPORTED_SEGMENT, 1, 3),
                     DECODE(B.SUPPLIER, 'DEFAULT', 'X', 'C');


            FOR OREC IN (SELECT  DISTINCT X.EFFECTIVE_DATE
                         FROM    CDI_POLR_TO_FROM_XREF X
                         WHERE   X.EFFECTIVE_DATE >= TRUNC(v_BEGIN_DATE, 'MONTH')
                            AND X.PROCESS='I'
                         ORDER BY X.EFFECTIVE_DATE)
            LOOP

               EXECUTE IMMEDIATE 'TRUNCATE TABLE CDI_POLR_ICAP_TEMP DROP STORAGE';

               INSERT INTO CDI_POLR_ICAP_TEMP(POLR_DATE, POLR_TYPE, CUSTOMER_CLASS, COMP_NONCOMP, CAPACITY_OBLIGATION, NUM_OF_ACCTS)
               SELECT   v_BEGIN_DATE,
                        NVL(X.TO_POLR_TYPE, T.POLR_TYPE)            POLR_TYPE,
                        NVL(X.TO_CUST_CLASS, T.CUSTOMER_CLASS)      CUST_CLASS,
                        NVL(X.TO_COMP_NONCOMP, T.COMP_NONCOMP)      COMP_NONCOMP,
                        T.KWH1 * NVL(X.KWH_PCT/100, 1)              CAPACITY_OBLIGATION,
                        T.KWH2 * NVL(X.COUNT_PCT/100, 1)            NUM_OF_ACCTS
               FROM     CDI_POLR_TO_FROM_XREF X,
                        CDI_POLR_SUPPLY_TEMP T
               WHERE    X.FROM_POLR_TYPE(+) = T.POLR_TYPE
               AND      X.FROM_CUST_CLASS(+) = T.CUSTOMER_CLASS
               AND      X.FROM_COMP_NONCOMP(+) = T.COMP_NONCOMP
               AND      X.PROCESS(+) = T.PROCESS
               AND      T.PROCESS = 'I'
               AND      T.POLR_DATE = v_BEGIN_DATE
               AND      X.EFFECTIVE_DATE(+) = OREC.EFFECTIVE_DATE;

               DELETE FROM CDI_POLR_SUPPLY_TEMP T
               WHERE  T.POLR_DATE = v_BEGIN_DATE
               AND    T.PROCESS = 'I';

               INSERT INTO CDI_POLR_SUPPLY_TEMP(POLR_DATE, POLR_TYPE, CUSTOMER_CLASS, COMP_NONCOMP, KWH1, KWH2, PROCESS)
               SELECT   T.POLR_DATE, T.POLR_TYPE, T.CUSTOMER_CLASS, T.COMP_NONCOMP, SUM(T.CAPACITY_OBLIGATION ), SUM(T.NUM_OF_ACCTS), 'I'
               FROM     CDI_POLR_ICAP_TEMP T
               GROUP BY T.POLR_DATE, T.POLR_TYPE, T.CUSTOMER_CLASS, T.COMP_NONCOMP
               HAVING   SUM(T.CAPACITY_OBLIGATION ) <> 0
               OR       SUM(T.NUM_OF_ACCTS) <> 0;

            END LOOP; -- BY XREF DATE --

            COMMIT;

            g_RESULT := PLOG.UPDATE_PROCESS_PROGRESS(p_PROCESS_ID => g_PROCESS_DESCRIPTOR,
                                                    p_SO_FAR => NULL,
                                                    p_PROGRESS_DESCRIPTION => 'INSERT INTO CDI_POLR_ICAP - '||TO_CHAR(v_BEGIN_DATE));

            INSERT INTO CDI_POLR_ICAP(POLR_DATE, POLR_TYPE, CUSTOMER_CLASS, COMP_NONCOMP, CAPACITY_OBLIGATION, NUM_OF_ACCTS)
            SELECT POLR_DATE, POLR_TYPE, CUSTOMER_CLASS, COMP_NONCOMP, SUM(KWH1), SUM(KWH2)
            FROM
            (
               SELECT  T.POLR_DATE, T.POLR_TYPE,
                     CASE
                        WHEN T.POLR_TYPE = 'PRL' AND T.CUSTOMER_CLASS IN ('RLX','RLH','RL1','RL2') THEN
                           'PRL'
                        WHEN T.POLR_TYPE = 'PRX' AND T.CUSTOMER_CLASS IN ('RXX','RHX') THEN
                           'PRX'
                     ELSE
                        T.CUSTOMER_CLASS
                     END AS CUSTOMER_CLASS,
                  T.COMP_NONCOMP, T.KWH1, T.KWH2
               FROM    CDI_POLR_SUPPLY_TEMP T
               WHERE   T.POLR_DATE = v_BEGIN_DATE
               AND     T.PROCESS = 'I'
            )
            GROUP BY POLR_DATE, POLR_TYPE, CUSTOMER_CLASS, COMP_NONCOMP;


            COMMIT;

            v_BEGIN_DATE := LAST_DAY(v_BEGIN_DATE + 1);

         END LOOP; -- BY MONTH --

         COMMIT;

         p_MESSAGE := c_ICAP||' calculation process is complete.';

    EXCEPTION
        WHEN OTHERS THEN
            p_STATUS := SQLCODE;
            p_MESSAGE := SUBSTR(c_ICAP||' - '||SQLERRM, 1, 255);
            g_RESULT := PLOG.LOG_PROCESS_EVENT(p_PROCESS_ID => g_PROCESS_DESCRIPTOR,
                                               p_SEVERITY_LEVEL => PLOG.c_SEV_ERROR,
                                               p_PROCEDURE_NAME => 'CALC_ICAP_SUPPLY',
                                               p_STEP_NAME => 'CALC_ICAP_SUPPLY',
                                               p_SOURCE => NULL,
                                               p_MESSAGE => p_MESSAGE,
                                               p_MESSAGE_DESCRIPTION => p_MESSAGE);

    END CALC_ICAP_SUPPLY;
---------------------------------------
    PROCEDURE CALC_ENERGY_SUPPLY
        (p_BEGIN_DATE           IN DATE,
         p_END_DATE             IN DATE,
         p_STATUS               OUT NUMBER,
         p_MESSAGE              OUT VARCHAR2)
    IS

         v_BEGIN_DATE       DATE;
         v_END_DATE         DATE;

    BEGIN
--===============================================================================================================================
         p_STATUS := GA.SUCCESS;

         IF TRUNC(p_BEGIN_DATE, 'MONTH') <> TRUNC(p_END_DATE,'MONTH') THEN
            RAISE_APPLICATION_ERROR(-20000,'ENERGY CALCULATION REQUEST CANNOT EXCEED ONE CALENDAR MONTH');
         END IF;

         UT.CUT_DATE_RANGE(GA.ELECTRIC_MODEL, p_BEGIN_DATE, p_END_DATE, c_TIME_ZONE, v_BEGIN_DATE, v_END_DATE);

         --v_BEGIN_DATE := TRUNC(v_BEGIN_DATE, 'HH');
         --v_END_DATE := TRUNC(v_END_DATE, 'HH');

         EXECUTE IMMEDIATE 'TRUNCATE TABLE CDI_POLR_SUPPLY_TEMP DROP STORAGE';

         g_RESULT := PLOG.UPDATE_PROCESS_PROGRESS(p_PROCESS_ID => g_PROCESS_DESCRIPTOR,
                                                  p_SO_FAR => NULL,
                                                  p_PROGRESS_DESCRIPTION => 'DELETE FROM CDI_POLR_ENERGY');

         DELETE FROM CDI_POLR_ENERGY E
         WHERE  E.POLR_DATE BETWEEN v_BEGIN_DATE AND v_END_DATE;

         COMMIT;

         g_RESULT := PLOG.UPDATE_PROCESS_PROGRESS(p_PROCESS_ID => g_PROCESS_DESCRIPTOR,
                                                  p_SO_FAR => NULL,
                                                  p_PROGRESS_DESCRIPTION => 'INSERT INTO CDI_POLR_SUPPLY_TEMP');

         --WHILE v_BEGIN_DATE <= v_END_DATE LOOP

             INSERT INTO CDI_POLR_SUPPLY_TEMP(POLR_DATE, POLR_TYPE, CUSTOMER_CLASS, COMP_NONCOMP, KWH1, KWH2, PROCESS)
             SELECT I.POLR_DATE,
                    I.POLR_TYPE,
                    I.CUSTOMER_CLASS,
                    I.COMP_NONCOMP,
                    SUM(I.KWH1),
                    SUM(I.KWH2),
                    'E'
             FROM   (SELECT  /*+ INDEX (A "CDI_ACCEPT_LOAD_IX01")*/    A.LOAD_DATE                                                                                                             POLR_DATE,
                                A.POLR_TYPE,
                                SUBSTR(A.REPORTING_SEGMENT, 1, 3)                                                                                       CUSTOMER_CLASS,
                                DECODE(A.ESP_NAME, 'DEFAULT', 'X', 'C')                                                                                 COMP_NONCOMP,
                                APPLY_500KV_LOSS(A.LOAD_DATE,
                                                 A.VOLTAGE_CLASS,
                                                 SUM(NVL(A.LOAD_VAL, 0) + NVL(A.TX_LOSS_VAL, 0) + NVL(A.DX_LOSS_VAL, 0) + NVL(A.UE_LOSS_VAL, 0)))       KWH1,
                                APPLY_DERATION_FACTOR(A.LOAD_DATE,
                                                      SUM(NVL(A.LOAD_VAL, 0) + NVL(A.TX_LOSS_VAL, 0) + NVL(A.DX_LOSS_VAL, 0) + NVL(A.UE_LOSS_VAL, 0)))  KWH2
                     FROM       CDI_ACCEPT_LOAD A
                     WHERE      A.LOAD_DATE BETWEEN v_BEGIN_DATE AND v_END_DATE
                     AND        A.STATEMENT_TYPE_ID = GA.SCHEDULE_TYPE_FINAL
                     AND        A.SCHEDULE_TYPE = 'A'
                     -- ABX 20080909 --
                     AND        A.IS_ALM = 0
                     GROUP BY   A.LOAD_DATE,
                                A.POLR_TYPE,
                                A.VOLTAGE_CLASS,
                                SUBSTR(A.REPORTING_SEGMENT, 1, 3),
                                DECODE(A.ESP_NAME, 'DEFAULT', 'X', 'C')) I
             GROUP BY I.POLR_DATE, I.POLR_TYPE, I.CUSTOMER_CLASS, I.COMP_NONCOMP;

         COMMIT;

            FOR OREC IN (SELECT  DISTINCT X.EFFECTIVE_DATE
                         FROM    CDI_POLR_TO_FROM_XREF X
                         WHERE   X.EFFECTIVE_DATE >= p_BEGIN_DATE
                            AND X.PROCESS='E'
                         ORDER BY X.EFFECTIVE_DATE)
            LOOP

               EXECUTE IMMEDIATE 'TRUNCATE TABLE CDI_POLR_ENERGY_TEMP DROP STORAGE';

               INSERT INTO CDI_POLR_ENERGY_TEMP(POLR_DATE, POLR_TYPE, CUSTOMER_CLASS, COMP_NONCOMP, KWH_PREMISE, KWH_GENERATION)
               SELECT   T.POLR_DATE,
                        NVL(X.TO_POLR_TYPE, T.POLR_TYPE)            POLR_TYPE,
                        NVL(X.TO_CUST_CLASS, T.CUSTOMER_CLASS)      CUST_CLASS,
                        NVL(X.TO_COMP_NONCOMP, T.COMP_NONCOMP)      COMP_NONCOMP,
                        T.KWH1 * NVL(X.KWH_PCT/100, 1)              KWH_PREMISE,
                        T.KWH2 * NVL(X.KWH_PCT/100, 1)              KWH_GENERATION
               FROM     CDI_POLR_TO_FROM_XREF X,
                        CDI_POLR_SUPPLY_TEMP T
               WHERE    X.FROM_POLR_TYPE(+) = T.POLR_TYPE
               AND      X.FROM_CUST_CLASS(+) = T.CUSTOMER_CLASS
               AND      X.FROM_COMP_NONCOMP(+) = T.COMP_NONCOMP
               AND      X.PROCESS(+) = T.PROCESS
               AND      T.PROCESS = 'E'
               AND      X.EFFECTIVE_DATE(+) = OREC.EFFECTIVE_DATE;

               EXECUTE IMMEDIATE 'TRUNCATE TABLE CDI_POLR_SUPPLY_TEMP DROP STORAGE';

               INSERT INTO CDI_POLR_SUPPLY_TEMP(POLR_DATE, POLR_TYPE, CUSTOMER_CLASS, COMP_NONCOMP, KWH1, KWH2, PROCESS)
               SELECT   T.POLR_DATE, T.POLR_TYPE, T.CUSTOMER_CLASS, T.COMP_NONCOMP, SUM(T.KWH_PREMISE ), SUM(T.KWH_GENERATION), 'I'
               FROM     CDI_POLR_ENERGY_TEMP T
               GROUP BY T.POLR_DATE, T.POLR_TYPE, T.CUSTOMER_CLASS, T.COMP_NONCOMP
               HAVING   SUM(T.KWH_PREMISE ) <> 0 OR  SUM(T.KWH_GENERATION) <> 0;

            END LOOP;

            COMMIT;

            g_RESULT := PLOG.UPDATE_PROCESS_PROGRESS(p_PROCESS_ID => g_PROCESS_DESCRIPTOR,
                                                    p_SO_FAR => NULL,
                                                    p_PROGRESS_DESCRIPTION => 'INSERT INTO CDI_POLR_ENERGY - '||TO_CHAR(v_BEGIN_DATE));

            INSERT INTO CDI_POLR_ENERGY(POLR_DATE, POLR_TYPE, CUSTOMER_CLASS, COMP_NONCOMP, KWH_PREMISE, KWH_GENERATION)
            SELECT POLR_DATE, POLR_TYPE, CUSTOMER_CLASS, COMP_NONCOMP, SUM(KWH1), SUM(KWH2)
            FROM
            (
               SELECT  T.POLR_DATE, T.POLR_TYPE,
                  CASE
                     WHEN T.POLR_TYPE = 'PRL' AND T.CUSTOMER_CLASS IN ('RLX','RLH','RL1','RL2') THEN
                        'PRL'
                     WHEN T.POLR_TYPE = 'PRX' AND T.CUSTOMER_CLASS IN ('RXX','RHX') THEN
                        'PRX'
                  ELSE
                     T.CUSTOMER_CLASS
                  END AS CUSTOMER_CLASS,
                  T.COMP_NONCOMP, T.KWH1, T.KWH2
               FROM    CDI_POLR_SUPPLY_TEMP T
            )
            GROUP BY POLR_DATE, POLR_TYPE, CUSTOMER_CLASS, COMP_NONCOMP;

            COMMIT;

--            v_BEGIN_DATE := ADVANCE_DATE(v_BEGIN_DATE, 'HOUR');

--         END LOOP; -- BY MONTH --

--         COMMIT;

         p_MESSAGE := c_ENERGY||' calculation process is complete.';
--===============================================================================================================================
--         p_STATUS := GA.SUCCESS;
--
--         UT.CUT_DATE_RANGE(GA.ELECTRIC_MODEL, p_BEGIN_DATE, p_END_DATE, c_TIME_ZONE, v_BEGIN_DATE, v_END_DATE);
--
--         EXECUTE IMMEDIATE 'TRUNCATE TABLE CDI_POLR_SUPPLY_TEMP DROP STORAGE';
--
--         g_RESULT := PLOG.UPDATE_PROCESS_PROGRESS(p_PROCESS_ID => g_PROCESS_DESCRIPTOR,
--                                                  p_SO_FAR => NULL,
--                                                  p_PROGRESS_DESCRIPTION => 'DELETE FROM CDI_POLR_ENERGY');

--         DELETE FROM CDI_POLR_ENERGY E
--         WHERE  E.POLR_DATE BETWEEN v_BEGIN_DATE AND v_END_DATE;

--         COMMIT;
--
--         g_RESULT := PLOG.UPDATE_PROCESS_PROGRESS(p_PROCESS_ID => g_PROCESS_DESCRIPTOR,
--                                                  p_SO_FAR => NULL,
--                                                  p_PROGRESS_DESCRIPTION => 'INSERT INTO CDI_POLR_SUPPLY_TEMP');

--         INSERT INTO CDI_POLR_SUPPLY_TEMP(POLR_DATE, POLR_TYPE, CUSTOMER_CLASS, COMP_NONCOMP, KWH1, KWH2, PROCESS)
--         SELECT I.POLR_DATE,
--                I.POLR_TYPE,
--                I.CUSTOMER_CLASS,
--                I.COMP_NONCOMP,
--                SUM(I.KWH1),
--                SUM(I.KWH2),
--                'E'
--         FROM   (SELECT     A.LOAD_DATE                                                                                                             POLR_DATE,
--                            A.POLR_TYPE,
--                            SUBSTR(A.REPORTING_SEGMENT, 1, 3)                                                                                       CUSTOMER_CLASS,
--                            DECODE(A.ESP_NAME, 'DEFAULT', 'X', 'C')                                                                                 COMP_NONCOMP,
--                            APPLY_500KV_LOSS(A.LOAD_DATE,
--                                             A.VOLTAGE_CLASS,
--                                             SUM(NVL(A.LOAD_VAL, 0) + NVL(A.TX_LOSS_VAL, 0) + NVL(A.DX_LOSS_VAL, 0) + NVL(A.UE_LOSS_VAL, 0)))       KWH1,
--                            APPLY_DERATION_FACTOR(A.LOAD_DATE,
--                                                  SUM(NVL(A.LOAD_VAL, 0) + NVL(A.TX_LOSS_VAL, 0) + NVL(A.DX_LOSS_VAL, 0) + NVL(A.UE_LOSS_VAL, 0)))  KWH2
--                 FROM       CDI_ACCEPT_LOAD A
--                 WHERE      A.LOAD_DATE BETWEEN v_BEGIN_DATE AND v_END_DATE
--                 AND        A.STATEMENT_TYPE_ID = GA.SCHEDULE_TYPE_FINAL
--                 AND        A.SCHEDULE_TYPE = 'A'
--                 GROUP BY   A.LOAD_DATE,
--                            A.POLR_TYPE,
--                            A.VOLTAGE_CLASS,
--                            SUBSTR(A.REPORTING_SEGMENT, 1, 3),
--                            DECODE(A.ESP_NAME, 'DEFAULT', 'X', 'C')) I
--         GROUP BY I.POLR_DATE, I.POLR_TYPE, I.CUSTOMER_CLASS, I.COMP_NONCOMP;
--
--         COMMIT;

--         g_RESULT := PLOG.UPDATE_PROCESS_PROGRESS(p_PROCESS_ID => g_PROCESS_DESCRIPTOR,
--                                                  p_SO_FAR => NULL,
--                                                  p_PROGRESS_DESCRIPTION => 'FOR LOOP - INSERT INTO CDI_POLR_ENERGY');
--
--         FOR REC IN (SELECT /*+ ORDERED */
--                            T.POLR_DATE,
--                            T.POLR_TYPE,
--                            T.CUSTOMER_CLASS,
--                            T.COMP_NONCOMP,
--                            SUM(T.KWH1)     KWH_PREMISE,
--                            SUM(T.KWH2)     KWH_GENERATION
--                     FROM   CDI_POLR_SUPPLY_TEMP T
--                     WHERE  T.PROCESS = 'E'
--                     GROUP BY T.POLR_DATE,
--                            T.POLR_TYPE,
--                            T.CUSTOMER_CLASS,
--                            T.COMP_NONCOMP
--                     ORDER BY 1, 2, 3, 4)
--         LOOP

--
--             INSERT INTO CDI_POLR_ENERGY(POLR_DATE, POLR_TYPE, CUSTOMER_CLASS, COMP_NONCOMP, KWH_PREMISE, KWH_GENERATION)
--             SELECT REC.POLR_DATE,
--                    X.TO_POLR_TYPE,
--                    X.TO_CUST_CLASS,
--                    X.TO_COMP_NONCOMP,
--                    REC.KWH_PREMISE * (X.KWH_PCT/100),
--                    REC.KWH_GENERATION * (X.KWH_PCT/100)
--             FROM   CDI_POLR_TO_FROM_XREF X
--             WHERE  X.FROM_POLR_TYPE = REC.POLR_TYPE
--             AND    X.FROM_CUST_CLASS = REC.CUSTOMER_CLASS
--             AND    X.FROM_COMP_NONCOMP = REC.COMP_NONCOMP
--             AND    X.PROCESS = 'E'
--             AND    X.EFFECTIVE_DATE BETWEEN REC.POLR_DATE AND v_END_DATE;
--
--             IF SQL%NOTFOUND THEN
--
--                INSERT INTO CDI_POLR_ENERGY(POLR_DATE, POLR_TYPE, CUSTOMER_CLASS, COMP_NONCOMP, KWH_PREMISE, KWH_GENERATION)
--                VALUES(REC.POLR_DATE, REC.POLR_TYPE, REC.CUSTOMER_CLASS, REC.COMP_NONCOMP, REC.KWH_PREMISE, REC.KWH_GENERATION);
--
--             END IF;

--         END LOOP;
--
--         COMMIT;
--
--         p_MESSAGE := c_ENERGY||' calculation process is complete.';

    EXCEPTION
        WHEN OTHERS THEN
             p_STATUS := SQLCODE;
             p_MESSAGE := SUBSTR(c_ENERGY||' - '||SQLERRM, 1, 255);
             g_RESULT := PLOG.LOG_PROCESS_EVENT(p_PROCESS_ID => g_PROCESS_DESCRIPTOR,
                                                p_SEVERITY_LEVEL => PLOG.c_SEV_ERROR,
                                                p_PROCEDURE_NAME => 'CALC_ENERGY_SUPPLY',
                                                p_STEP_NAME => 'CALC_ENERGY_SUPPLY',
                                                p_SOURCE => NULL,
                                                p_MESSAGE => p_MESSAGE,
                                                p_MESSAGE_DESCRIPTION => p_MESSAGE);

    END CALC_ENERGY_SUPPLY;
---------------------------------------
    PROCEDURE POLR_TO_FROM_XREF_REPORT
        (p_MODEL_ID             IN NUMBER,
         p_SCHEDULE_TYPE        IN VARCHAR2,
         p_BEGIN_DATE           IN DATE,
         p_END_DATE             IN DATE,
         p_AS_OF_DATE           IN DATE,
         p_TIME_ZONE            IN VARCHAR2,
         p_NOTUSED_ID1          IN NUMBER,
         p_NOTUSED_ID2          IN NUMBER,
         p_NOTUSED_ID3          IN NUMBER,
         p_PROCESS              IN CDI_POLR_TO_FROM_XREF.PROCESS%TYPE,
         p_POLR_TYPE            IN CDI_POLR_TO_FROM_XREF.FROM_POLR_TYPE%TYPE,
         p_CUST_CLASS           IN CDI_POLR_TO_FROM_XREF.FROM_CUST_CLASS%TYPE,
         p_COMP_NONCOMP         IN CDI_POLR_TO_FROM_XREF.FROM_COMP_NONCOMP%TYPE,
         p_STATUS               OUT NUMBER,
         p_CURSOR               OUT REF_CURSOR)
    IS
    BEGIN

         p_STATUS := GA.SUCCESS;

         OPEN p_CURSOR FOR
              SELECT    ROWIDTOCHAR(X.ROWID)                        ROW_ID,
                        DECODE(X.PROCESS, 'I', c_ICAP, c_ENERGY)    PROCESS,
                        X.FROM_POLR_TYPE,
                        X.FROM_CUST_CLASS,
                        X.FROM_COMP_NONCOMP,
                        X.TO_POLR_TYPE,
                        X.TO_CUST_CLASS,
                        X.TO_COMP_NONCOMP,
                        X.EFFECTIVE_DATE,
                        X.KWH_PCT,
                        X.COUNT_PCT,
                        X.ENTRY_DATE,
                        TO_CHAR(NULL)                               REMOVE,
                        SUM(X.KWH_PCT) OVER(PARTITION BY X.FROM_POLR_TYPE, X.FROM_CUST_CLASS, X.FROM_COMP_NONCOMP, X.EFFECTIVE_DATE)  SUM_KWH_PCT,
                        SUM(X.COUNT_PCT) OVER(PARTITION BY X.FROM_POLR_TYPE, X.FROM_CUST_CLASS, X.FROM_COMP_NONCOMP, X.EFFECTIVE_DATE) SUM_COUNT_PCT
              FROM      CDI_POLR_TO_FROM_XREF X
              WHERE     X.FROM_POLR_TYPE = DECODE(p_POLR_TYPE, c_ALL, X.FROM_POLR_TYPE , p_POLR_TYPE)
              AND       X.FROM_CUST_CLASS = DECODE(p_CUST_CLASS, c_ALL, X.FROM_CUST_CLASS , p_CUST_CLASS)
              AND       X.FROM_COMP_NONCOMP = DECODE(p_COMP_NONCOMP, c_ALL, X.FROM_COMP_NONCOMP , p_COMP_NONCOMP)
              AND       X.PROCESS = DECODE(p_PROCESS, c_ALL, X.PROCESS, SUBSTR(p_PROCESS, 1, 1))
              ORDER BY X.EFFECTIVE_DATE,
                       X.FROM_POLR_TYPE,
                       X.FROM_CUST_CLASS,
                       X.FROM_COMP_NONCOMP,
                       X.TO_POLR_TYPE,
                       X.TO_CUST_CLASS,
                       X.TO_COMP_NONCOMP;

    END POLR_TO_FROM_XREF_REPORT;
---------------------------------------
    PROCEDURE PUT_POLR_TO_FROM_XREF
        (p_ROW_ID               IN VARCHAR2,
         p_PROCESS              IN CDI_POLR_TO_FROM_XREF.PROCESS%TYPE,
         p_FROM_POLR_TYPE       IN CDI_POLR_TO_FROM_XREF.FROM_POLR_TYPE%TYPE,
         p_FROM_CUST_CLASS      IN CDI_POLR_TO_FROM_XREF.FROM_CUST_CLASS%TYPE,
         p_FROM_COMP_NONCOMP    IN CDI_POLR_TO_FROM_XREF.FROM_COMP_NONCOMP%TYPE,
         p_TO_POLR_TYPE         IN CDI_POLR_TO_FROM_XREF.TO_POLR_TYPE%TYPE,
         p_TO_CUST_CLASS        IN CDI_POLR_TO_FROM_XREF.TO_CUST_CLASS%TYPE,
         p_TO_COMP_NONCOMP      IN CDI_POLR_TO_FROM_XREF.TO_COMP_NONCOMP%TYPE,
         p_EFFECTIVE_DATE       IN CDI_POLR_TO_FROM_XREF.EFFECTIVE_DATE%TYPE,
         p_KWH_PCT              IN CDI_POLR_TO_FROM_XREF.KWH_PCT%TYPE,
         p_COUNT_PCT            IN CDI_POLR_TO_FROM_XREF.COUNT_PCT%TYPE,
         p_REMOVE               IN NUMBER,
         p_STATUS               OUT NUMBER)
    IS

         v_PROCESS              CDI_POLR_TO_FROM_XREF.PROCESS%TYPE := SUBSTR(p_PROCESS, 1, 1);

    BEGIN

         p_STATUS := GA.SUCCESS;

         IF (v_PROCESS = 'I' AND
             (p_FROM_POLR_TYPE IS NULL OR
              p_FROM_CUST_CLASS IS NULL OR
              p_FROM_COMP_NONCOMP IS NULL OR
              p_TO_POLR_TYPE IS NULL OR
              p_TO_CUST_CLASS IS NULL OR
              p_TO_COMP_NONCOMP IS NULL OR
              p_EFFECTIVE_DATE IS NULL OR
              p_KWH_PCT IS NULL OR
              p_COUNT_PCT IS NULL))
         OR (v_PROCESS = 'E' AND
             (p_FROM_POLR_TYPE IS NULL OR
              p_FROM_CUST_CLASS IS NULL OR
              p_FROM_COMP_NONCOMP IS NULL OR
              p_TO_POLR_TYPE IS NULL OR
              p_TO_CUST_CLASS IS NULL OR
              p_TO_COMP_NONCOMP IS NULL OR
              p_EFFECTIVE_DATE IS NULL OR
              p_KWH_PCT IS NULL))
         THEN

            RAISE_APPLICATION_ERROR(-20101, 'Missing required data - Make sure that all necessary fields have been entered.');

         END IF;

         IF NVL(p_REMOVE, 0) = 1 THEN

            DELETE FROM CDI_POLR_TO_FROM_XREF X
            WHERE X.ROWID = CHARTOROWID(p_ROW_ID);

         ELSE

            MERGE INTO CDI_POLR_TO_FROM_XREF X
            USING (SELECT       p_ROW_ID                                        ROW_ID,
                                UPPER(RPAD(p_FROM_POLR_TYPE, 3, 'X'))           FROM_POLR_TYPE,
                                UPPER(RPAD(p_FROM_CUST_CLASS, 3, 'X'))          FROM_CUST_CLASS,
                                UPPER(p_FROM_COMP_NONCOMP)                      FROM_COMP_NONCOMP,
                                UPPER(RPAD(p_TO_POLR_TYPE, 3, 'X'))             TO_POLR_TYPE,
                                UPPER(RPAD(p_TO_CUST_CLASS, 3, 'X'))            TO_CUST_CLASS,
                                UPPER(p_TO_COMP_NONCOMP)                        TO_COMP_NONCOMP,
                                p_EFFECTIVE_DATE                                EFFECTIVE_DATE,
                                p_KWH_PCT                                       KWH_PCT,
                                p_COUNT_PCT                                     COUNT_PCT
                   FROM         DUAL) D
            ON (X.ROWID = CHARTOROWID(D.ROW_ID))
            WHEN MATCHED THEN UPDATE
            SET X.FROM_POLR_TYPE = D.FROM_POLR_TYPE,
                X.FROM_CUST_CLASS = D.FROM_CUST_CLASS,
                X.FROM_COMP_NONCOMP = D.FROM_COMP_NONCOMP,
                X.TO_POLR_TYPE = D.TO_POLR_TYPE,
                X.TO_CUST_CLASS = D.TO_CUST_CLASS,
                X.TO_COMP_NONCOMP = D.TO_COMP_NONCOMP,
                X.EFFECTIVE_DATE = D.EFFECTIVE_DATE,
                X.KWH_PCT = D.KWH_PCT,
                X.COUNT_PCT = DECODE(v_PROCESS, 'I', D.COUNT_PCT, NULL),
                X.ENTRY_DATE = SYSDATE
            WHEN NOT MATCHED THEN INSERT
            VALUES(v_PROCESS,
                   D.FROM_POLR_TYPE,
                   D.FROM_CUST_CLASS,
                   D.FROM_COMP_NONCOMP,
                   D.TO_POLR_TYPE,
                   D.TO_CUST_CLASS,
                   D.TO_COMP_NONCOMP,
                   D.EFFECTIVE_DATE,
                   D.KWH_PCT,
                   DECODE(v_PROCESS, 'I', D.COUNT_PCT, NULL),
                   SYSDATE);

         END IF;

         COMMIT;

    END PUT_POLR_TO_FROM_XREF;

PROCEDURE POLR_SUPPLY_REPORT
   (
   p_MODEL_ID     IN NUMBER,
   p_SCHEDULE_TYPE IN VARCHAR2,
   p_BEGIN_DATE    IN DATE,
   p_END_DATE      IN DATE,
   p_AS_OF_DATE    IN DATE,
   p_TIME_ZONE     IN VARCHAR2,
   p_NOTUSED_ID1   IN NUMBER,
   p_NOTUSED_ID2   IN NUMBER,
   p_NOTUSED_ID3   IN NUMBER,
   p_PROCESS       IN VARCHAR2,
   p_CURSOR       OUT REF_CURSOR
   ) AS
v_BEGIN_DATE DATE;
v_END_DATE DATE;
BEGIN
   IF p_PROCESS = c_ENERGY THEN
      OPEN p_CURSOR FOR
         UT.CUT_DATE_RANGE(GA.ELECTRIC_MODEL, p_BEGIN_DATE, p_END_DATE, p_TIME_ZONE, v_BEGIN_DATE, v_END_DATE);
         SELECT FROM_CUT_AS_HED(POLR_DATE, c_TIME_ZONE) "POLR_DATE", POLR_TYPE || CUSTOMER_CLASS || COMP_NONCOMP "SUPPLIER", KWH_PREMISE, KWH_GENERATION, NULL "CAPACITY_OBLIGATION", NULL "NUMBER_OF_ACCOUNTS"
         FROM CDI_POLR_ENERGY
         WHERE POLR_DATE BETWEEN v_BEGIN_DATE AND v_END_DATE
         ORDER BY POLR_DATE, SUPPLIER;
   ELSIF p_PROCESS = c_ICAP THEN
      OPEN p_CURSOR FOR
         SELECT TO_CHAR(POLR_DATE, c_DATE_TIME_FORMAT) "POLR_DATE", POLR_TYPE || CUSTOMER_CLASS || COMP_NONCOMP "SUPPLIER", NULL "KWH_PREMISE", NULL "KWH_GENERATION", ROUND(CAPACITY_OBLIGATION, 2), "CAPACITY_OBLIGATION", NUMBER_OF_ACCOUNTS
         FROM CDI_POLR_ICAP
         WHERE POLR_DATE BETWEEN TRUNC(p_BEGIN_DATE, 'MONTH') AND LAST_DAY(p_END_DATE)
         ORDER BY POLR_DATE, SUPPLIER;
   END IF;
END POLR_SUPPLY_REPORT;

PROCEDURE CALC_POLR_SUPPLY
   (
   p_BEGIN_DATE IN DATE,
   p_END_DATE   IN DATE,
   p_PROCESS    IN VARCHAR2,
   p_STATUS    OUT NUMBER,
   p_MESSAGE   OUT VARCHAR2
   ) AS
v_PROCEDURE_NAME VARCHAR2(32) := 'CALC_POLR_SUPPLY';
v_MARK_TIME PLS_INTEGER := DBMS_UTILITY.GET_TIME;
BEGIN
   LOGS.START_PROCESS(c_CALCULATE_POLR_SUPPLY);
   LOGS.LOG_INFO(c_CALCULATE_POLR_SUPPLY, v_PROCEDURE_NAME, c_STEP_NAME, c_PACKAGE_NAME); 
   IF p_PROCESS = c_ENERGY THEN  
      CALC_ENERGY_SUPPLY(p_BEGIN_DATE, p_END_DATE, p_STATUS, p_MESSAGE);
   ELSIF p_PROCESS = c_ICAP THEN
      CALC_ICAP_SUPPLY(p_BEGIN_DATE, p_END_DATE, p_STATUS, p_MESSAGE);
   END IF;
   LOGS.LOG_INFO(c_CALCULATE_POLR_SUPPLY || ' Complete. Elapsed Seconds: ' || TO_CHAR(ROUND((DBMS_UTILITY.GET_TIME-v_MARK_TIME)/100)), v_PROCEDURE_NAME, c_STEP_NAME, c_PACKAGE_NAME);
   LOGS.STOP_PROCESS(p_MESSAGE, p_STATUS);
EXCEPTION
   WHEN OTHERS THEN
      p_STATUS := SQLCODE;
      p_MESSAGE := SQLERRM;
      ROLLBACK;
      ERRS.ABORT_PROCESS;
END CALC_POLR_SUPPLY;

PROCEDURE GENERATE_FILES
(
p_BEGIN_DATE IN DATE,
p_END_DATE   IN DATE,
p_PROCESS    IN VARCHAR2,
p_STATUS    OUT NUMBER,
p_MESSAGE   OUT VARCHAR2
) AS

         t_TEXT                 GA.BIG_STRING_TABLE;
         v_FILENAME             VARCHAR2(128) := p_PROCESS||'_'||
                                                 TO_CHAR(p_BEGIN_DATE, 'MMDDYYYY')||'_'||
                                                 TO_CHAR(p_END_DATE, 'MMDDYYYY')||'_'||
                                                 TO_CHAR(SYSDATE, 'MMDDYYYY')||'.csv';
         v_HEADER               VARCHAR2(512) := CASE p_PROCESS WHEN c_ENERGY THEN
                                                                     c_ENERGY_HEADER
                                                                ELSE
                                                                     c_ICAP_HEADER
                                                                END;

    BEGIN

         p_STATUS := GA.SUCCESS;

         g_PROCESS_DESCRIPTOR := PLOG.LOG_PROCESS_START(p_PROCESS_NAME => 'GENERATE_FILES',
                                                        p_TARGET_START_DATE => p_BEGIN_DATE,
                                                        p_TARGET_STOP_DATE => p_END_DATE,
                                                        p_PARAMETERS => 'Filename:  '||v_FILENAME);

         IF p_PROCESS = c_ENERGY THEN

            g_RESULT := PLOG.UPDATE_PROCESS_PROGRESS(p_PROCESS_ID => g_PROCESS_DESCRIPTOR,
                                                     p_SO_FAR => NULL,
                                                     p_PROGRESS_DESCRIPTION => 'SELECT FROM CDI_POLR_ENERGY');

            SELECT  TO_CHAR(E.POLR_DATE, 'MM/DD/YYYY HH24:MI:SS')||c_COMMA||
                    E.POLR_TYPE||
                    E.CUSTOMER_CLASS||
                    E.COMP_NONCOMP||c_COMMA||
                    TO_CHAR(ROUND(E.KWH_PREMISE, 2))||c_COMMA||
                    TO_CHAR(ROUND(E.KWH_GENERATION, 2))
            BULK COLLECT INTO t_TEXT
            FROM    CDI_POLR_ENERGY E
            WHERE   E.POLR_DATE BETWEEN p_BEGIN_DATE AND p_END_DATE
            ORDER BY E.POLR_DATE, E.POLR_TYPE, E.CUSTOMER_CLASS, E.COMP_NONCOMP;

         ELSIF p_PROCESS = c_ICAP THEN

            g_RESULT := PLOG.UPDATE_PROCESS_PROGRESS(p_PROCESS_ID => g_PROCESS_DESCRIPTOR,
                                                     p_SO_FAR => NULL,
                                                     p_PROGRESS_DESCRIPTION => 'SELECT FROM CDI_POLR_ICAP_TEMP');

            SELECT  I.POLR_TYPE||
                    I.CUSTOMER_CLASS||
                    I.COMP_NONCOMP||c_COMMA||
                    TO_CHAR(I.POLR_DATE, 'MM/DD/YYYY HH24:MI:SS')||c_COMMA||
                    TO_CHAR(ROUND(I.CAPACITY_OBLIGATION, 2))||c_COMMA||
                    TRIM(TO_CHAR(I.NUM_OF_ACCTS, '999999999.00'))
            BULK COLLECT INTO t_TEXT
            FROM    CDI_POLR_ICAP_TEMP I
            WHERE   I.POLR_DATE BETWEEN p_BEGIN_DATE AND p_END_DATE
            ORDER BY I.POLR_DATE, I.POLR_TYPE, I.CUSTOMER_CLASS, I.COMP_NONCOMP;

         END IF;

         WRITE_TEXT_FILE(t_TEXT, c_DIR_OBJ, v_FILENAME, v_HEADER, p_STATUS);

         IF p_STATUS <> GA.SUCCESS THEN
            g_PROCESS_DESCRIPTOR := PLOG.LOG_PROCESS_END(p_PROCESS_ID => g_PROCESS_DESCRIPTOR,
                                                         p_RETURN_CODE => PLOG.c_SEV_ERROR,
                                                         p_EXTENDED_RETURN_CODE => p_STATUS,
                                                         p_MESSAGE => 'GENERATE_FILES: '||p_PROCESS,
                                                         p_MESSAGE_DESCRIPTION => 'WRITE_TEXT_FILE ERROR');
         END IF;

         p_MESSAGE := p_PROCESS||' file generation is complete';

         g_PROCESS_DESCRIPTOR := PLOG.LOG_PROCESS_END(p_PROCESS_ID => g_PROCESS_DESCRIPTOR,
                                                      p_RETURN_CODE => PLOG.c_OK,
                                                      p_EXTENDED_RETURN_CODE => PLOG.c_OK,
                                                      p_MESSAGE => 'GENERATE_FILES: '||p_PROCESS,
                                                      p_MESSAGE_DESCRIPTION => p_MESSAGE);

    EXCEPTION
        WHEN OTHERS THEN
            p_STATUS := SQLCODE;
            p_MESSAGE := SUBSTR(p_PROCESS||' - '||SQLERRM, 1, 255);
            g_PROCESS_DESCRIPTOR := PLOG.LOG_PROCESS_END(p_PROCESS_ID => g_PROCESS_DESCRIPTOR,
                                                         p_RETURN_CODE => PLOG.c_SEV_ERROR,
                                                         p_EXTENDED_RETURN_CODE => p_STATUS,
                                                         p_MESSAGE => 'GENERATE_FILES: '||p_PROCESS,
                                                         p_MESSAGE_DESCRIPTION => p_MESSAGE);

    END GENERATE_FILES;
---------------------------------------
BEGIN

    SELECT  T.TRANSACTION_ID
    INTO    g_DERATION_FCTR_ID
    FROM    INTERCHANGE_TRANSACTION T
    WHERE   T.TRANSACTION_NAME = 'Deration Factor';

    SELECT  T.TRANSACTION_ID
    INTO    g_500KV_ID
    FROM    INTERCHANGE_TRANSACTION T
    WHERE   T.TRANSACTION_NAME = '500kV Losses';

    SELECT  A.AREA_ID
    INTO    g_AREA_ID
    FROM    AREA A
    WHERE   A.AREA_NAME = 'BGE System';
---------------------------------------
END CDI_POLR_SUPPLY;
/
