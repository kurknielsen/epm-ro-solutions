CREATE OR REPLACE FUNCTION ENTITY_NAME_FROM_ID_TABLE
	(
    p_TABLE_NAME IN VARCHAR,
    p_ENTITY_ID IN NUMBER
    ) RETURN VARCHAR IS
--Revision: $Revision: 1.10 $

-- Answer the ENTITY_NAME for the specified ENTITY_ID,
-- and TABLE_NAME in the NERO_TABLE_PROPERTY_INDEX table.

v_NAME VARCHAR2(64);
v_ID_FIELD VARCHAR2(64);
v_NAME_FIELD VARCHAR2(64);

BEGIN
	-- get the entity's ID_FIELD from the NERO_TABLE_PROPERTY_INDEX table
    SELECT RTRIM(LTRIM(UPPER(B.PRIMARY_ID_COLUMN)))
    INTO v_ID_FIELD
    FROM NERO_TABLE_PROPERTY_INDEX B
    WHERE RTRIM(LTRIM(UPPER(B.TABLE_NAME))) = RTRIM(LTRIM(UPPER(p_TABLE_NAME)));
        
    v_NAME_FIELD := SUBSTR(v_ID_FIELD,1,LENGTH(v_ID_FIELD)-2)||'NAME';
    
    EXECUTE IMMEDIATE 
            'SELECT '||v_NAME_FIELD 
            ||' FROM '||p_TABLE_NAME
            ||' WHERE '||v_ID_FIELD||' = :v1'
    	INTO v_NAME USING p_ENTITY_ID;
    
    RETURN v_NAME;

EXCEPTION
	WHEN OTHERS THEN
    	RETURN NULL;
END ENTITY_NAME_FROM_ID_TABLE;
/