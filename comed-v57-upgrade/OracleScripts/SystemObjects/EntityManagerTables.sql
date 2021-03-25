--This procedure will drop and recreate all IO Tables.
--Custom settings will be lost.

DECLARE
    p_STATUS NUMBER;
BEGIN
    SO.GENERATE_ALL_IO_TABLES(p_STATUS);
END;
/

