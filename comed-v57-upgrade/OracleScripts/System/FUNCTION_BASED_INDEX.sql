DECLARE
v_COUNT NUMBER;
BEGIN
    SELECT COUNT(1)
    INTO v_COUNT
    FROM USER_OBJECTS O
    WHERE O.OBJECT_NAME = 'SERVICE_CONSUMPTION_IDX1';      
    
    IF v_COUNT = 0 THEN
        DBMS_OUTPUT.PUT_LINE('Creating SERVICE_CONSUMPTION_IDX1 Index...');
		EXECUTE IMMEDIATE
            'CREATE index SERVICE_CONSUMPTION_IDX1 on SERVICE_CONSUMPTION (NVL(BILL_PROCESSED_DATE, LOW_DATE), ENTRY_DATE)
               storage
               (
                   initial 64K
                   next 64K
                   pctincrease 0
               )
            tablespace NERO_INDEX';
	ELSE
		DBMS_OUTPUT.PUT_LINE('Skip Creating SERVICE_CONSUMPTION_IDX1 Index. It already exists.');
    END IF;
END;
/
