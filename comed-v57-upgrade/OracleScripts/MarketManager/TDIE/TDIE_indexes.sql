-- These are here instead of in MAIN/System/crebas.sql because they add overhead to storage
-- and only provide performance benefits for the TDIE_GEN_UNITS view. These indexes are not
-- necessary/useful for core retail functionality.

DECLARE
	c INTEGER;
    DUPLICATE_INDEXES EXCEPTION;
    PRAGMA EXCEPTION_INIT(DUPLICATE_INDEXES, -1408);  
    --To catch indexes with different names that have the same set of columns. 
BEGIN
	SELECT COUNT(*)
	INTO c
	FROM USER_INDEXES I
	WHERE I.INDEX_NAME = 'ACCOUNT_SERVICE_LOCATION_TDIE1';
	
	IF c = 0 THEN
        EXECUTE IMMEDIATE '
                CREATE UNIQUE INDEX ACCOUNT_SERVICE_LOCATION_TDIE1 ON ACCOUNT_SERVICE_LOCATION(SERVICE_LOCATION_ID, BEGIN_DATE, ACCOUNT_ID, END_DATE)
                  TABLESPACE NERO_INDEX
                  PCTFREE 10
                  INITRANS 2
                  MAXTRANS 255
                  STORAGE
                  (
                    INITIAL 64K
                    MINEXTENTS 1
                    MAXEXTENTS UNLIMITED
                  )';
        COMMIT;
	END IF;
EXCEPTION
    WHEN DUPLICATE_INDEXES THEN 
           NULL;
END;
/

DECLARE
	c INTEGER;
    DUPLICATE_INDEXES EXCEPTION;
    PRAGMA EXCEPTION_INIT(DUPLICATE_INDEXES, -1408);
BEGIN
	SELECT COUNT(*)
	INTO c
	FROM USER_INDEXES I
	WHERE I.INDEX_NAME = 'SERVICE_LOCATION_METER_TDIE1';
	
	IF c = 0 THEN
        EXECUTE IMMEDIATE '
                CREATE UNIQUE INDEX SERVICE_LOCATION_METER_TDIE1 ON SERVICE_LOCATION_METER(METER_ID, BEGIN_DATE, SERVICE_LOCATION_ID, END_DATE)
                  TABLESPACE NERO_INDEX
                  PCTFREE 10
                  INITRANS 2
                  MAXTRANS 255
                  STORAGE
                  (
                    INITIAL 64K
                    MINEXTENTS 1
                    MAXEXTENTS UNLIMITED
                  )';
        COMMIT;
	END IF;
EXCEPTION
    WHEN DUPLICATE_INDEXES THEN 
           NULL;
END;
/

DECLARE
	c INTEGER;
    DUPLICATE_INDEXES EXCEPTION;
    PRAGMA EXCEPTION_INIT(DUPLICATE_INDEXES, -1408);
BEGIN
	SELECT COUNT(*)
	INTO c
	FROM USER_INDEXES I
	WHERE I.INDEX_NAME = 'METER_SCHEDULE_GROUP_TDIE1';
	
	IF c = 0 THEN
        EXECUTE IMMEDIATE '
                CREATE UNIQUE INDEX METER_SCHEDULE_GROUP_TDIE1 ON METER_SCHEDULE_GROUP (SCHEDULE_GROUP_ID, BEGIN_DATE, METER_ID, END_DATE)
                  TABLESPACE NERO_INDEX
                  PCTFREE 10
                  INITRANS 2
                  MAXTRANS 255
                  STORAGE
                  (
                    INITIAL 64K
                    MINEXTENTS 1
                    MAXEXTENTS UNLIMITED
                  )';
        COMMIT;
	END IF;
EXCEPTION
    WHEN DUPLICATE_INDEXES THEN 
           NULL;
END;
/
