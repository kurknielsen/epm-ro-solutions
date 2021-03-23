DECLARE
	v_SC_ID NUMBER(9);
	v_DISPLAY_ORDER NUMBER(4) := 1;
	
	PROCEDURE PUT_RESOURCE_TRAIT(
		p_RESOURCE_TRAIT_NAME IN VARCHAR2,
		p_RESOURCE_TRAIT_DESC IN VARCHAR2,
		p_RESOURCE_TRAIT_INTERVAL IN VARCHAR2,
		p_SHOWN_WITH_PQ NUMBER,
		p_SHOWN_WITH_OFFER NUMBER,
		p_DATA_TYPE VARCHAR2,
		p_TRAIT_CATEGORY VARCHAR2,
		p_EDIT_MASK VARCHAR2 DEFAULT NULL,
		p_COMBO_LIST VARCHAR2 DEFAULT NULL
		) IS
		
	v_RESOURCE_TRAIT_ID NUMBER(9);
	BEGIN
		BEGIN
			SELECT RESOURCE_TRAIT_ID INTO v_RESOURCE_TRAIT_ID
			FROM RESOURCE_TRAIT
			WHERE RESOURCE_TRAIT_NAME = p_RESOURCE_TRAIT_NAME;
		EXCEPTION
			WHEN OTHERS THEN
				v_RESOURCE_TRAIT_ID := 0;
		END;

		IO.PUT_RESOURCE_TRAIT(v_RESOURCE_TRAIT_ID, 'IMO ' || p_RESOURCE_TRAIT_NAME, p_RESOURCE_TRAIT_NAME, p_RESOURCE_TRAIT_DESC, v_RESOURCE_TRAIT_ID, p_RESOURCE_TRAIT_INTERVAL, v_SC_ID, p_RESOURCE_TRAIT_NAME, v_DISPLAY_ORDER, p_SHOWN_WITH_PQ, p_SHOWN_WITH_OFFER,
			p_TRAIT_CATEGORY, p_DATA_TYPE, p_EDIT_MASK, p_COMBO_LIST);
		v_DISPLAY_ORDER := v_DISPLAY_ORDER + 1;
	END PUT_RESOURCE_TRAIT;
BEGIN
	
	v_SC_ID := ID.ID_FOR_SC('IMO');
	DELETE RESOURCE_TRAIT WHERE SC_ID = v_SC_ID;
	PUT_RESOURCE_TRAIT('Load Point', 'The hourly load point of the bid.', 'Hour', 1, 1, 'Number', 'Energy');
	PUT_RESOURCE_TRAIT('Expiration Date', 'The date on which the Standing Bid expires.', 'Day', 0, 1, 'String', '%', '##/##/####');
	PUT_RESOURCE_TRAIT('Day Type', 'The day name abbreviation of the day for which the Standing Bid applies.', 'Day', 0, 1, 'String', '%', NULL, 'All|Mon|Tue|Wed|Thu|Fri|Sat|Sun');
	PUT_RESOURCE_TRAIT('Energy Limit', '', 'Day', 0, 1, 'Number', 'Energy');
	PUT_RESOURCE_TRAIT('Operating Reserve Ramp Rate', '', 'Day', 0, 1, 'Number', 'Energy');
END;
/
