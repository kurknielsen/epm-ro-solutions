DECLARE
	v_SEM_SET_ID NUMBER(9);

	PROCEDURE ADD_HOLIDAY_TO_SET
		(
		p_HOLIDAY_NAME IN VARCHAR2
		) AS
		v_HOLIDAY_ID NUMBER(9);
	BEGIN
		
		ID.ID_FOR_HOLIDAY(p_HOLIDAY_NAME, v_HOLIDAY_ID);	
		INSERT INTO HOLIDAY_SCHEDULE VALUES(v_SEM_SET_ID, v_HOLIDAY_ID, SYSDATE);
	EXCEPTION
		WHEN OTHERS THEN NULL;
	END ADD_HOLIDAY_TO_SET;
BEGIN
	SECURITY_CONTROLS.SET_CURRENT_ROLES(ID_TABLE(ID_TYPE(SECURITY_CONTROLS.g_SUPER_USER_ROLE_ID)));
	BEGIN
		SELECT HOLIDAY_SET_ID INTO v_SEM_SET_ID FROM HOLIDAY_SET WHERE HOLIDAY_SET_NAME = 'SEM';
	EXCEPTION 
		WHEN OTHERS THEN
			IO.PUT_HOLIDAY_SET(v_SEM_SET_ID, 'SEM', 'SEM', 'SEM Holidays', 0);
	END;

	ADD_HOLIDAY_TO_SET('New Year''s Day');
	ADD_HOLIDAY_TO_SET('St. Patrick''s Day');
	ADD_HOLIDAY_TO_SET('Good Friday');
	ADD_HOLIDAY_TO_SET('Easter Monday');
	ADD_HOLIDAY_TO_SET('May Day');
	ADD_HOLIDAY_TO_SET('May Bank Holiday (NI)');
	ADD_HOLIDAY_TO_SET('June Bank Holiday (ROI)');
	ADD_HOLIDAY_TO_SET('The Twelfth');
	ADD_HOLIDAY_TO_SET('August Bank Holiday (ROI)');
	ADD_HOLIDAY_TO_SET('August Bank Holiday');
	ADD_HOLIDAY_TO_SET('October Bank Holiday (ROI)');
	ADD_HOLIDAY_TO_SET('Christmas');
	ADD_HOLIDAY_TO_SET('Boxing Day');
END;
/
COMMIT;