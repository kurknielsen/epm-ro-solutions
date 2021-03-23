--------------------------------------------------------------------------------
PROMPT Create sequence TDIE_ID...
DECLARE
    C NUMBER;
    BEGIN
        SELECT COUNT(*) INTO C FROM USER_SEQUENCES WHERE SEQUENCE_NAME = 'TDIE_ID';
        IF C = 0  THEN
        EXECUTE IMMEDIATE '
            CREATE SEQUENCE TDIE_ID
            MINVALUE 0
            MAXVALUE 99999999999
            START WITH 1000
            INCREMENT BY 1
            CACHE 20
            CYCLE
            ORDER';   
        END IF;
    END;
/
--------------------------------------------------------------------------------
PROMPT Create sequence TDIE_DETAIL_ID...
DECLARE
    C NUMBER;
    BEGIN
        SELECT COUNT(*) INTO C FROM USER_SEQUENCES WHERE SEQUENCE_NAME = 'TDIE_DETAIL_ID';
        IF C = 0  THEN
        EXECUTE IMMEDIATE '
            CREATE SEQUENCE TDIE_DETAIL_ID
            MINVALUE 0
            MAXVALUE 99999999999
            START WITH 1000
            INCREMENT BY 1
            CACHE 20
            CYCLE
            ORDER';   
        END IF;
    END;
/
--------------------------------------------------------------------------------
PROMPT Create sequence TDIE_VALIDATION_ID...
DECLARE
    C NUMBER;
    BEGIN
        SELECT COUNT(*) INTO C FROM USER_SEQUENCES WHERE SEQUENCE_NAME = 'TDIE_VALIDATION_ID';
        IF C = 0  THEN
        EXECUTE IMMEDIATE '
            CREATE SEQUENCE TDIE_VALIDATION_ID
            MINVALUE 0
            MAXVALUE 99999999999
            START WITH 1000
            INCREMENT BY 1
            CACHE 20
            CYCLE
            ORDER';   
        END IF;
    END;
/