CREATE OR REPLACE TRIGGER IT_SCHEDULE_UPDATE_TXN_DATE
    AFTER INSERT OR UPDATE ON IT_SCHEDULE
    FOR EACH ROW
DECLARE
    v_BEGIN_DATE DATE;
    v_END_DATE DATE;
    v_SCHEDULE_DATE DATE;
BEGIN
    v_SCHEDULE_DATE := TRUNC(FROM_CUT(:NEW.SCHEDULE_DATE, GA.LOCAL_TIME_ZONE)-1/86400);

    SELECT BEGIN_DATE, END_DATE
    INTO v_BEGIN_DATE, v_END_DATE
    FROM INTERCHANGE_TRANSACTION IT
    WHERE IT.TRANSACTION_ID = :NEW.TRANSACTION_ID;

    IF TRUNC(v_SCHEDULE_DATE) < v_BEGIN_DATE OR v_SCHEDULE_DATE > NVL(v_END_DATE, CONSTANTS.HIGH_DATE) THEN
        UPDATE INTERCHANGE_TRANSACTION
        SET BEGIN_DATE = LEAST(v_SCHEDULE_DATE, v_BEGIN_DATE),
        END_DATE = CASE WHEN v_END_DATE IS NULL
            THEN v_END_DATE
            ELSE GREATEST(v_SCHEDULE_DATE, NVL(v_END_DATE, CONSTANTS.HIGH_DATE))
          END
        WHERE TRANSACTION_ID = :NEW.TRANSACTION_ID;
    END IF;
END;
/