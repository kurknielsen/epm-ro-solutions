DECLARE
	v_ACTION_ID NUMBER(9);
	v_ROLE_ID NUMBER(9);
	v_ACTION_NAME SYSTEM_ACTION.ACTION_NAME%TYPE := 'BGE Profiles Import';
BEGIN

	v_ACTION_ID := ID.ID_FOR_SYSTEM_ACTION(v_ACTION_NAME);
	IF v_ACTION_ID <= 0 THEN
		IO.PUT_SYSTEM_ACTION(v_ACTION_ID, v_ACTION_NAME, NULL, NULL, 0, 0, 'Profiling', 'Data Exchange',
			v_ACTION_NAME, 'MM_BGE.DATA_IMPORT', NULL, NULL, NULL);
			
		BEGIN
			SELECT ROLE_ID INTO v_ROLE_ID FROM RETAIL_OFFICE_ROLE WHERE ROLE_NAME = 'Administrator';
			INSERT INTO SYSTEM_ACTION_ROLE VALUES (v_ACTION_ID, v_ROLE_ID, 1, SYSDATE);
		EXCEPTION
			WHEN OTHERS THEN
				NULL;
		END; 
	END IF;
 
	COMMIT;
END;
/