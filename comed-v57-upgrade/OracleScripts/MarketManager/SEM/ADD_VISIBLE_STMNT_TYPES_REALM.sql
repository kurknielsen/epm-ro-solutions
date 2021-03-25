DECLARE
	v_ID          NUMBER(9);
	v_COLUMN_VALS VARCHAR2(4000);
    i INTEGER;
	-- This cursor contains the list of Statement Types to EXCLUDE!
    -- Updated list provided by JC on 5/14/2012
    CURSOR C IS
		SELECT STATEMENT_TYPE_ID
		FROM STATEMENT_TYPE
		WHERE STATEMENT_TYPE_NAME IN
			  ('Not Assigned',
               'Indicative Actual',
               'Revised','Within-day Actual',
               'Ex-Ante Nom.',
               'Modified Nom.',
               'Revised Nom.',
               'Indicative Nom.',
               'Initial Nom.',
               'Forecast');      
BEGIN
    SELECT COUNT(*)
    INTO i
    FROM SYSTEM_REALM S
    WHERE S.REALM_NAME = 'Visible Statement Types';
    
    IF i = 0 THEN 
    
        IO.PUT_SYSTEM_REALM(O_OID              => v_ID,
                            p_REALM_NAME       => 'Visible Statement Types',
                            p_REALM_ALIAS      => 'Visible Statement Types',
                            p_REALM_DESC       => 'Visible Statement Types',
                            p_REALM_ID         => 0,
                            p_ENTITY_DOMAIN_ID => EC.ED_STATEMENT_TYPE,
                            p_REALM_CALC_TYPE  => 0,
                            p_CUSTOM_QUERY     => '?');
                        
    ELSE 
    
        SELECT REALM_ID
        INTO v_ID
        FROM SYSTEM_REALM S
        WHERE S.REALM_NAME = 'Visible Statement Types';
        
    END IF;

	-- update roles for Select by Statement Type from All Data to Visible Statement Types
    UPDATE SYSTEM_ACTION_ROLE SET REALM_ID = v_ID WHERE ACTION_ID=(SELECT ACTION_ID FROM system_action WHERE action_name='Select by Statement Type');
    
    FOR R IN C LOOP
    v_COLUMN_VALS := v_COLUMN_VALS || '''' ||  R.STATEMENT_TYPE_ID || ''',';
    END LOOP;
    
    v_COLUMN_VALS := SUBSTR(v_COLUMN_VALS, 1, LENGTH(v_COLUMN_VALS)-1);
    
    SELECT COUNT(*)
    INTO i
    FROM SYSTEM_REALM_COLUMN S
    WHERE S.ENTITY_COLUMN = 'STATEMENT_TYPE_ID'
    AND   S.REALM_ID = v_ID;

    IF i = 0 THEN
    
    INSERT INTO SYSTEM_REALM_COLUMN VALUES (v_ID, 'STATEMENT_TYPE_ID', 1, v_COLUMN_VALS, SYSDATE);
    
    ELSE
    
    UPDATE SYSTEM_REALM_COLUMN S
    SET S.COLUMN_VALS = v_COLUMN_VALS,
        S.IS_EXCLUDING_VALS = 1,
        S.ENTRY_DATE = SYSDATE
    WHERE S.REALM_ID = v_ID
    AND S.ENTITY_COLUMN = 'STATEMENT_TYPE_ID';
    
    END IF;
    
	COMMIT;
END;
/
