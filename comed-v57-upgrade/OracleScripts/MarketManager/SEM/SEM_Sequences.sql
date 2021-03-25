-- Create sequence 
DECLARE
    C NUMBER;
    BEGIN
        SELECT COUNT(*) INTO C FROM USER_SEQUENCES WHERE SEQUENCE_NAME = 'SEM_CFD_INVOICE_ID';
        IF C = 0  THEN
        EXECUTE IMMEDIATE '
            CREATE SEQUENCE SEM_CFD_INVOICE_ID
            MINVALUE 1
            MAXVALUE 999999999
            START WITH 1
            INCREMENT BY 1
            CACHE 20';   
        END IF;
    END;
/

-- TLAF sequence
DECLARE
    C NUMBER;
    BEGIN
        SELECT COUNT(*) INTO C FROM USER_SEQUENCES WHERE SEQUENCE_NAME = 'TLAF_SEQ';
        IF C = 0  THEN
        EXECUTE IMMEDIATE '
            CREATE SEQUENCE TLAF_SEQ
            START WITH 1
            MAXVALUE 999999999999999999999999999
            MINVALUE 1
            NOCYCLE
            CACHE 20
            NOORDER';  
        END IF;
    END;
/

DECLARE
    C NUMBER;
    BEGIN
        SELECT COUNT(*) INTO C FROM USER_SEQUENCES WHERE SEQUENCE_NAME = 'SEM_MP_INFO_SEQ';
        IF C = 0  THEN
        EXECUTE IMMEDIATE '
            CREATE SEQUENCE SEM_MP_INFO_SEQ  
            MINVALUE 0 
            MAXVALUE 99999999999 
            INCREMENT BY 1 
            START WITH 1000 
            CACHE 20 
            ORDER  
            CYCLE';
        END IF;
    END;
/
DECLARE
    C NUMBER;
    BEGIN
        SELECT COUNT(*) INTO C FROM USER_SEQUENCES WHERE SEQUENCE_NAME = 'SEM_CANCELLED_SRA_SEQ';
        IF C = 0  THEN
        EXECUTE IMMEDIATE '
            CREATE SEQUENCE SEM_CANCELLED_SRA_SEQ  
            MINVALUE 0 
            MAXVALUE 99999999999 
            INCREMENT BY 1 
            START WITH 1000 
            CACHE 20 
            ORDER';
        END IF;
    END;
/	