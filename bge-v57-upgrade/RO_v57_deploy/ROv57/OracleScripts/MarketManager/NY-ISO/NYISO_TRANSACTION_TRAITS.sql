DECLARE
	v_TG TRANSACTION_TRAIT_GROUP%ROWTYPE;
	v_STATUS NUMBER;

BEGIN
	-- Set common TG properties.
	v_TG.TRAIT_GROUP_INTERVAL := 'Hour';
	v_TG.TRAIT_GROUP_ALIAS := '?';
	v_TG.TRAIT_GROUP_DESC := 'Generated on ' || UT.TRACE_DATE(SYSDATE) || ' by COMMON_TRANSACTION_TRAITS script.';
	v_TG.SC_ID := ID.ID_FOR_SC('NYISO');
	v_TG.TRAIT_CATEGORY := '%';
	v_TG.IS_SPARSE := 0;
	v_TG.IS_STATEMENT_TYPE_SPECIFIC := 0;
	v_TG.IS_SERIES := 0;
	v_TG.DEFAULT_NUMBER_OF_SETS := 0;

	-- ==============================
	-- Price Cap MW $/MW Pairs
	-- ==============================
	BEGIN
		
		v_TG.TRAIT_GROUP_ID := MM_NYISO_UTIL.g_TG_PRICE_CAP_1;
		v_TG.TRAIT_GROUP_NAME :=  'NYISO Price Cap #1';
		v_TG.DISPLAY_NAME := v_TG.TRAIT_GROUP_NAME;
		v_TG.DISPLAY_ORDER := 89;
		
		TG.UPSERT_TRAIT_GROUP(v_TG);
		
		EM.PUT_TRANSACTION_TRAIT(v_TG.TRAIT_GROUP_ID, MM_NYISO_UTIL.g_TT_MW, 0, 'MW',
			1, 'Number', NULL, NULL, NULL, NULL, v_STATUS);
		EM.PUT_TRANSACTION_TRAIT(v_TG.TRAIT_GROUP_ID, MM_NYISO_UTIL.g_TT_COST, 0, '$/MW',
			2, 'Number', 'Currency', NULL, NULL, NULL, v_STATUS);
		
		v_TG.TRAIT_GROUP_ID := MM_NYISO_UTIL.g_TG_PRICE_CAP_2;
		v_TG.TRAIT_GROUP_NAME := 'NYISO Price Cap #2';
		v_TG.DISPLAY_NAME := v_TG.TRAIT_GROUP_NAME;
		v_TG.DISPLAY_ORDER := 90;
		
		TG.UPSERT_TRAIT_GROUP(v_TG);
		
		EM.PUT_TRANSACTION_TRAIT( v_TG.TRAIT_GROUP_ID, MM_NYISO_UTIL.g_TT_MW, 0, 'MW',
			1, 'Number', NULL, NULL, NULL, NULL, v_STATUS);
		EM.PUT_TRANSACTION_TRAIT(v_TG.TRAIT_GROUP_ID, MM_NYISO_UTIL.g_TT_COST, 0, '$/MW',
			2, 'Number', 'Currency', NULL, NULL, NULL, v_STATUS);
			
		v_TG.TRAIT_GROUP_ID := MM_NYISO_UTIL.g_TG_PRICE_CAP_3;
		v_TG.TRAIT_GROUP_NAME := 'NYISO Price Cap #3';
		v_TG.DISPLAY_NAME := v_TG.TRAIT_GROUP_NAME;
		v_TG.DISPLAY_ORDER := 91;
		
		TG.UPSERT_TRAIT_GROUP(v_TG);
		
		EM.PUT_TRANSACTION_TRAIT(v_TG.TRAIT_GROUP_ID, MM_NYISO_UTIL.g_TT_MW, 0, 'MW',
			1, 'Number', NULL, NULL, NULL, NULL, v_STATUS);
		EM.PUT_TRANSACTION_TRAIT(v_TG.TRAIT_GROUP_ID, MM_NYISO_UTIL.g_TT_COST, 0, '$/MW',
			2, 'Number', 'Currency', NULL, NULL, NULL, v_STATUS);
		
        update system_object
        set object_display_name = 'MW'
        where object_name like 'NYISO Price Cap #%' and object_order = 1;
    	
    	update system_object
        set object_display_name = '$/MW'
        where object_name like 'NYISO Price Cap #%' and object_order = 2;

	
	EXCEPTION
		WHEN OTHERS THEN
			UT.DEBUG_TRACE('TRAIT_GROUP:DID NOT SUCCESSFULLY CREATE ' || v_TG.TRAIT_GROUP_NAME || '.  STATUS=' || v_STATUS);
	END;	
	
	-- ==============================
	-- Interruptible Price Cap MW $/MW Pair
	-- ==============================
	BEGIN
		v_TG.TRAIT_GROUP_ID := MM_NYISO_UTIL.g_TG_INTERRUPTIBLE_CAPPED;
		v_TG.TRAIT_GROUP_NAME := 'NYISO Int Price Cap';
		v_TG.DISPLAY_NAME := v_TG.TRAIT_GROUP_NAME;
		v_TG.DISPLAY_ORDER := 92;
		v_TG.IS_SERIES := 0;
		v_TG.DEFAULT_NUMBER_OF_SETS := 0;
		
		TG.UPSERT_TRAIT_GROUP(v_TG);
		
		EM.PUT_TRANSACTION_TRAIT(v_TG.TRAIT_GROUP_ID, MM_NYISO_UTIL.g_TT_MW, 0, 'MW',
 			3, 'Number', NULL, NULL, NULL, NULL, v_STATUS);	
		EM.PUT_TRANSACTION_TRAIT(v_TG.TRAIT_GROUP_ID, MM_NYISO_UTIL.g_TT_COST, 0, '$/MW',
			4, 'Number', 'Currency', NULL, NULL, NULL, v_STATUS);
	
        update system_object
        set object_display_name = 'MW'
        where object_name like v_TG.TRAIT_GROUP_NAME || '%' and object_order = 1;
        
    	update system_object
        set object_display_name = '$/MW'
        where object_name like v_TG.TRAIT_GROUP_NAME || '%' and object_order = 2;
		
	EXCEPTION
		WHEN OTHERS THEN
			UT.DEBUG_TRACE('TRAIT_GROUP:DID NOT SUCCESSFULLY CREATE ' || v_TG.TRAIT_GROUP_NAME || '.  STATUS=' || v_STATUS);
	END;	

	-- ==============================
	-- Interruptible Fixed MW $/MW Pair
	-- ==============================
	BEGIN
		v_TG.TRAIT_GROUP_ID := MM_NYISO_UTIL.g_TG_INTERRUPTIBLE_FIXED;
		v_TG.TRAIT_GROUP_NAME := 'NYISO Int Fixed';
		v_TG.DISPLAY_NAME := v_TG.TRAIT_GROUP_NAME;
		v_TG.DISPLAY_ORDER := 93;
		v_TG.IS_SERIES := 0;
		v_TG.DEFAULT_NUMBER_OF_SETS := 0;
		
		TG.UPSERT_TRAIT_GROUP(v_TG);
		
		EM.PUT_TRANSACTION_TRAIT(v_TG.TRAIT_GROUP_ID, MM_NYISO_UTIL.g_TT_MW, 0, 'MW',
 			5, 'Number', NULL, NULL, NULL, NULL, v_STATUS);	
		EM.PUT_TRANSACTION_TRAIT(v_TG.TRAIT_GROUP_ID, MM_NYISO_UTIL.g_TT_COST, 0, '$/MW',
			6, 'Number', 'Currency', NULL, NULL, NULL, v_STATUS);
			
    	update system_object
        set object_display_name = 'MW'
        where object_name like v_TG.TRAIT_GROUP_NAME || '%' and object_order = 1;
        
        update system_object
        set object_display_name = '$/MW'
        where object_name like v_TG.TRAIT_GROUP_NAME || '%' and object_order = 2;

	EXCEPTION
		WHEN OTHERS THEN
			UT.DEBUG_TRACE('TRAIT_GROUP:DID NOT SUCCESSFULLY CREATE ' || v_TG.TRAIT_GROUP_NAME || '.  STATUS=' || v_STATUS);
	END;


END;
/

