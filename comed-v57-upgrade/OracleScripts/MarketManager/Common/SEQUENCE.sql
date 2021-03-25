-- Market Manager Id
PROMPT Create sequence MMID...
DECLARE
    C NUMBER;
    BEGIN
        SELECT COUNT(*) INTO C FROM USER_SEQUENCES WHERE SEQUENCE_NAME = 'MMID';
        IF C = 0  THEN
        EXECUTE IMMEDIATE '
            CREATE SEQUENCE MMID
            INCREMENT BY 1
            START WITH 1';   
        END IF;
    END;
/


