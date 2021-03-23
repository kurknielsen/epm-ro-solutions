DECLARE
	v_SC_ID NUMBER(9);
	v_DISPLAY_ORDER NUMBER(4) := 0;
	v_TG TRANSACTION_TRAIT_GROUP%ROWTYPE;
	v_STATUS NUMBER;
	
	PROCEDURE PUT_TRAIT(
		p_TRAIT_GROUP_ID IN NUMBER,
		p_TRAIT_GROUP_TYPE IN VARCHAR2,
		p_TRAIT_GROUP_NAME IN VARCHAR2,
		p_TRAIT_GROUP_DESC IN VARCHAR2,
		p_TRAIT_GROUP_INTERVAL IN VARCHAR2,
		p_SHOWN_WITH_PQ IN NUMBER,
		p_SHOWN_WITH_OFFER IN NUMBER, -- not used
		p_TRAIT_CATEGORY IN VARCHAR2,
		p_DATA_TYPE IN VARCHAR2,
		p_COMBO_LIST IN VARCHAR2 DEFAULT NULL,
		p_EDIT_MASK IN VARCHAR2 DEFAULT NULL,
        p_AFTER_EDIT_VALIDATION IN VARCHAR2 DEFAULT NULL
		) IS
		
	BEGIN
		
		v_DISPLAY_ORDER := v_DISPLAY_ORDER + 1;

		-- Set common TG properties.
		v_TG.TRAIT_GROUP_INTERVAL := p_TRAIT_GROUP_INTERVAL;
		v_TG.IS_SERIES := 0;
		v_TG.IS_SPARSE := CASE p_TRAIT_GROUP_TYPE WHEN 'Default' THEN 1 ELSE 0 END;
		v_TG.IS_STATEMENT_TYPE_SPECIFIC := 0;
		v_TG.DEFAULT_NUMBER_OF_SETS := 0;
		v_TG.SC_ID := v_SC_ID;

		v_TG.TRAIT_GROUP_ID := p_TRAIT_GROUP_ID;
		v_TG.TRAIT_GROUP_NAME := 'MISO ' || p_TRAIT_GROUP_TYPE || ' ' || p_TRAIT_GROUP_NAME;
		v_TG.TRAIT_GROUP_DESC := p_TRAIT_GROUP_DESC;
		v_TG.DISPLAY_NAME := 'MISO';
		v_TG.DISPLAY_ORDER := v_DISPLAY_ORDER;
		v_TG.TRAIT_CATEGORY := 'Generation';
		v_TG.TRAIT_GROUP_TYPE := CASE WHEN p_SHOWN_WITH_PQ = 1 THEN 'Detail' ELSE 'Standard' END;
		
		TG.UPSERT_TRAIT_GROUP(v_TG);
		EM.PUT_TRANSACTION_TRAIT(v_TG.TRAIT_GROUP_ID, 1, 0, p_TRAIT_GROUP_TYPE || ' ' || p_TRAIT_GROUP_NAME, 1, p_DATA_TYPE, NULL, p_COMBO_LIST, p_EDIT_MASK, p_AFTER_EDIT_VALIDATION, v_STATUS);
	EXCEPTION
		WHEN OTHERS THEN
			UT.DEBUG_TRACE('TRAIT_GROUP:DID NOT SUCCESSFULLY CREATE ' || v_TG.TRAIT_GROUP_NAME || '.  STATUS=' || v_STATUS);
	END PUT_TRAIT;

BEGIN
	
	v_SC_ID := ID.ID_FOR_SC('MISO');
	PUT_TRAIT(MM_MISO_UTIL.g_TG_DEF_DISPATCH_MAX, 'Default', 'Dispatch Maximum', 'The resource''s maximum rate of energy production, in MW, to be considered for dispatch by the market clearing software.', 'Day', 0, 0, 'Default', 'Number');
	PUT_TRAIT(MM_MISO_UTIL.g_TG_DEF_DISPATCH_MIN, 'Default', 'Dispatch Minimum', 'The resource''s minimum rate of energy production, in MW, to be dispatched by the market clearing software including the capacity consumed by upward regulation and reserves.', 'Day', 0, 0, 'Default', 'Number');
	PUT_TRAIT(MM_MISO_UTIL.g_TG_DEF_EMER_MAX, 'Default', 'Emergency Maximum', 'The resource''s ultimate maximum rate of energy production in MW.', 'Day', 0, 0, 'Default', 'Number');
	PUT_TRAIT(MM_MISO_UTIL.g_TG_DEF_EMER_MIN, 'Default', 'Emergency Minimum', 'The resource''s ultimate minimum rate of energy production in MW.', 'Day', 0, 0, 'Default', 'Number');
	PUT_TRAIT(MM_MISO_UTIL.g_TG_DEF_DISPATCH_TEMP_LIM1, 'Default', 'Dispatch Temp Limit1', 'The first band of dispatch temperature limits stored as <MW>;<Temp>.', 'Day', 0, 0, 'Default', 'String', NULL, '#######.#;###.#');
	PUT_TRAIT(MM_MISO_UTIL.g_TG_DEF_DISPATCH_TEMP_LIM2, 'Default', 'Dispatch Temp Limit2', 'The second band of dispatch temperature limits.', 'Day', 0, 0, 'Default', 'String', NULL, '#######.#;###.#');
	PUT_TRAIT(MM_MISO_UTIL.g_TG_DEF_DISPATCH_TEMP_LIM3, 'Default', 'Dispatch Temp Limit3', 'The third band of dispatch temperature limits.', 'Day', 0, 0, 'Default', 'String', NULL, '#######.#;###.#');
	PUT_TRAIT(MM_MISO_UTIL.g_TG_DEF_EMER_TEMP_LIM1, 'Default', 'Emergency Temp Limit1', 'The first band of emergency temperature limits.', 'Day', 0, 0, 'Default', 'String', NULL, '#######.#;###.#');
	PUT_TRAIT(MM_MISO_UTIL.g_TG_DEF_EMER_TEMP_LIM2, 'Default', 'Emergency Temp Limit2', 'The second band of emergency temperature limits.', 'Day', 0, 0, 'Default', 'String', NULL, '#######.#;###.#');
	PUT_TRAIT(MM_MISO_UTIL.g_TG_DEF_EMER_TEMP_LIM3, 'Default', 'Emergency Temp Limit3', 'The third band of emergency temperature limits.', 'Day', 0, 0, 'Default', 'String', NULL, '#######.#;###.#');
	PUT_TRAIT(MM_MISO_UTIL.g_TG_DEF_NO_LOAD_COST, 'Default', 'No Load Cost', 'The default no load cost in $ per hour.', 'Day', 0, 0, 'Default', 'Number');
	PUT_TRAIT(MM_MISO_UTIL.g_TG_DEF_COLD_START_COST, 'Default', 'Cold Startup Cost', 'The cold startup cost in $ per hour.', 'Day', 0, 0, 'Default', 'Number');
	PUT_TRAIT(MM_MISO_UTIL.g_TG_DEF_INTER_START_COST, 'Default', 'Intermediate Startup Cost', 'The cold startup cost in $ per hour.', 'Day', 0, 0, 'Default', 'Number');
	PUT_TRAIT(MM_MISO_UTIL.g_TG_DEF_HOT_START_COST, 'Default', 'Hot Startup Cost', 'The cold startup cost in $ per hour.', 'Day', 0, 0, 'Default', 'Number');
	PUT_TRAIT(MM_MISO_UTIL.g_TG_DEF_RAMP_RATE, 'Default', 'Ramp Rate', 'The default ramp rate that is overridden by the ramp rate curve that can optionally be entered for generating units.', 'Day', 0, 0, 'Default', 'Number');
	PUT_TRAIT(MM_MISO_UTIL.g_TG_DEF_RESOURCE_STATUS, 'Default', 'Resource Status', 'The default resource status designating the resource commitment, either Unavailable, Economic, Emergency, or MustRun.', 'Day', 0, 0, 'Default', 'String', 'Economic|Emergency|MustRun|Unavailable');
	PUT_TRAIT(MM_MISO_UTIL.g_TG_OFF_DISPATCH_MAX, 'Offer', 'Dispatch Maximum', 'The resource''s maximum rate of energy production, in MW, to be considered for dispatch by the market clearing software.', 'Day', 0, 1, 'GEN', 'Number');
	PUT_TRAIT(MM_MISO_UTIL.g_TG_OFF_DISPATCH_MIN, 'Offer', 'Dispatch Minimum', 'The resource''s minimum rate of energy production, in MW, to be dispatched by the market clearing software including the capacity consumed by upward regulation and reserves.', 'Day', 0, 1, 'GEN', 'Number');
	PUT_TRAIT(MM_MISO_UTIL.g_TG_OFF_EMER_MAX, 'Offer', 'Emergency Maximum', 'The resource''s ultimate maximum rate of energy production in MW.', 'Day', 0, 1, 'GEN', 'Number');
	PUT_TRAIT(MM_MISO_UTIL.g_TG_OFF_EMER_MIN, 'Offer', 'Emergency Minimum', 'The resource''s ultimate minimum rate of energy production in MW.', 'Day', 0, 1, 'GEN', 'Number');
	PUT_TRAIT(MM_MISO_UTIL.g_TG_OFF_NO_LOAD_COST, 'Offer', 'No Load Cost', 'The hourly no load cost in $ per hour associated with an offer.', 'Hour', 1, 1, 'GEN', 'Number');
	PUT_TRAIT(MM_MISO_UTIL.g_TG_OFF_COLD_START_COST, 'Offer', 'Cold Startup Cost', 'The cold startup cost in $ per hour associated with an offer.', 'Day', 1, 1, 'GEN', 'Number');
	PUT_TRAIT(MM_MISO_UTIL.g_TG_OFF_INTER_START_COST, 'Offer', 'Intermediate Startup Cost', 'The cold startup cost in $ per hour associated with an offer.', 'Day', 0, 1, 'GEN', 'Number');
	PUT_TRAIT(MM_MISO_UTIL.g_TG_OFF_HOT_START_COST, 'Offer', 'Hot Startup Cost', 'The cold startup cost in $ per hour associated with an offer.', 'Day', 0, 1, 'GEN', 'Number');
	PUT_TRAIT(MM_MISO_UTIL.g_TG_OFF_COMMIT_STATUS, 'Offer', 'Commit Status', 'The hourly resource status designating the resource commitment, either Unavailable, Economic, Emergency, or MustRun.', 'Hour', 0, 1, 'GEN', 'String', 'Economic|Emergency|MustRun|Unavailable');
	PUT_TRAIT(MM_MISO_UTIL.g_TG_OFF_SELF_SCHEDULE, 'Offer', 'Self Schedule', 'The hourly MW self-schedule for a price-taker resource.', 'Hour', 0, 1, 'GEN', 'Number');
	PUT_TRAIT(MM_MISO_UTIL.g_TG_OFF_MIN_RUNTIME, 'Offer', 'Minimum Runtime', 'The minimum runtime of the resource specified in the format HHH:MM.', 'Day', 0, 1, 'GEN', 'String', NULL, '###:00');
	PUT_TRAIT(MM_MISO_UTIL.g_TG_OFF_MAX_RUNTIME, 'Offer', 'Maximum Runtime', 'The maximum runtime of the resource specified in the format HHH:MM.', 'Day', 0, 1, 'GEN', 'String', NULL, '###:00');
	PUT_TRAIT(MM_MISO_UTIL.g_TG_OFF_MIN_DOWNTIME, 'Offer', 'Minimum Downtime', 'The minimum downtime of the resource specified in the format HHH:MM.', 'Day', 0, 1, 'GEN', 'String', NULL, '###:00');
	PUT_TRAIT(MM_MISO_UTIL.g_TG_OFF_HOT_TO_COLD_TIME, 'Offer', 'Hot to Cold Time', 'The hot to cold transition time of the resource specified in the format HHH:MM.', 'Day', 0, 1, 'GEN', 'String', NULL, '###:00');
	PUT_TRAIT(MM_MISO_UTIL.g_TG_OFF_HOT_TO_INTER_TIME, 'Offer', 'Hot to Intermediate Time', 'The hot to intermediate transition time of the resource specified in the format HHH:MM.', 'Day', 0, 1, 'GEN', 'String', NULL, '###:00');
	PUT_TRAIT(MM_MISO_UTIL.g_TG_OFF_COLD_START_TIME, 'Offer', 'Cold Startup Time', 'The cold startup time of the resource specified in the format HHH:MM.', 'Day', 0, 1, 'GEN', 'String', NULL, '###:00');
	PUT_TRAIT(MM_MISO_UTIL.g_TG_OFF_INTER_START_TIME, 'Offer', 'Intermediate Startup Time', 'The intermediate startup time of the resource specified in the format HHH:MM.', 'Day', 0, 1, 'GEN', 'String', NULL, '###:00');
	PUT_TRAIT(MM_MISO_UTIL.g_TG_OFF_HOT_START_TIME, 'Offer', 'Hot Startup Time', 'The hot startup time of the resource specified in the format HHH:MM.', 'Day', 0, 1, 'GEN', 'String', NULL, '###:00');
	PUT_TRAIT(MM_MISO_UTIL.g_TG_OFF_COLD_NOTIF_TIME, 'Offer', 'Cold Notification Time', 'The time required prior to starting a resource that is cold, specified in the format HHH:MM.', 'Day', 0, 1, 'GEN', 'String', NULL, '###:00');
	PUT_TRAIT(MM_MISO_UTIL.g_TG_OFF_INTER_NOTIF_TIME, 'Offer', 'Intermediate Notification Time', 'The time required prior to starting a resource that is started already, specified in the format HHH:MM.', 'Day', 0, 1, 'GEN', 'String', NULL, '###:00');
	PUT_TRAIT(MM_MISO_UTIL.g_TG_OFF_HOT_NOTIF_TIME, 'Offer', 'Hot Notification Time', 'The time required prior to starting a resource that is hot, specified in the format HHH:MM.', 'Day', 0, 1, 'GEN', 'String', NULL, '###:00');
	PUT_TRAIT(MM_MISO_UTIL.g_TG_OFF_MAX_DAILY_STARTS, 'Offer', 'Maximum Daily Starts', 'The maximum daily starts allowed for the resource', 'Day', 0, 1, 'GEN', 'Number');
	PUT_TRAIT(MM_MISO_UTIL.g_TG_OFF_MAX_WEEKLY_STARTS, 'Offer', 'Maximum Weekly Starts', 'The maximum weekly starts allowed for the resource', 'Day', 0, 1, 'GEN', 'Number');
	PUT_TRAIT(MM_MISO_UTIL.g_TG_OFF_CONDENSE_AVAIL, 'Offer', 'Condensing Availability', 'Specifies whether condensing is available for this unit.  0 if false, or 1 if true.', 'Day', 0, 1, 'GEN', 'Boolean');
	PUT_TRAIT(MM_MISO_UTIL.g_TG_OFF_CONDENSE_NOTIF_TIME, 'Offer', 'Condense Notification Time', 'The notification time to switch to condensing operation, specified in the format HHH:MM.', 'Day', 0, 1, 'GEN', 'String', NULL, '###:00');
	PUT_TRAIT(MM_MISO_UTIL.g_TG_OFF_CONDENSE_START_COST, 'Offer', 'Condense Startup Cost', 'The condensing startup cost in $.', 'Day', 0, 1, 'GEN', 'Number');
	PUT_TRAIT(MM_MISO_UTIL.g_TG_OFF_CONDENSE_HOURLY_COST, 'Offer', 'Condense Hourly Cost', 'The condensing hourly cost in $.', 'Day', 0, 1, 'GEN', 'Number');
	PUT_TRAIT(MM_MISO_UTIL.g_TG_OFF_CONDENSE_POWER, 'Offer', 'Condense Power', 'The power available from condensing.', 'Day', 0, 1, 'GEN', 'Number');
	PUT_TRAIT(MM_MISO_UTIL.g_TG_OFF_SLOPE, 'Offer', 'Slope', 'Optional field specifying whether the price curve for this hour is to be interpreted as a piece-wise linear curve (slope is true) or a block curve (slope is false).  The default is block.', 'Hour', 1, 1, 'GEN', 'String', 'False|True');
	PUT_TRAIT(MM_MISO_UTIL.g_TG_UPD_DISPATCH_MAX, 'Update', 'Dispatch Maximum', 'The resource''s maximum rate of energy production, in MW, to be considered for dispatch by the market clearing software.', 'Hour', 0, 1, 'GEN', 'Number');
	PUT_TRAIT(MM_MISO_UTIL.g_TG_UPD_DISPATCH_MIN, 'Update', 'Dispatch Minimum', 'The resource''s minimum rate of energy production, in MW, to be dispatched by the market clearing software including the capacity consumed by upward regulation and reserves.', 'Hour', 0, 1, 'GEN', 'Number');
	PUT_TRAIT(MM_MISO_UTIL.g_TG_UPD_EMER_MAX, 'Update', 'Emergency Maximum', 'The resource''s ultimate maximum rate of energy production in MW.', 'Hour', 0, 1, 'GEN', 'Number');
	PUT_TRAIT(MM_MISO_UTIL.g_TG_UPD_EMER_MIN, 'Update', 'Emergency Minimum', 'The resource''s ultimate minimum rate of energy production in MW.', 'Hour', 0, 1, 'GEN', 'Number');
	PUT_TRAIT(MM_MISO_UTIL.g_TG_UPD_RESOURCE_STATUS, 'Update', 'Resource Status', 'The hourly interval resource status, either Unavailable, Economic, Emergency, or MustRun.', 'Hour', 0, 1, 'GEN', 'String', 'Economic|Emergency|MustRun|Unavailable');
	PUT_TRAIT(MM_MISO_UTIL.g_TG_UPD_SELF_DOWN_REG, 'Update', 'Self Scheduled Down Reg', 'MW value for downward regulation self-scheduled energy.', 'Hour', 0, 1, 'GEN', 'Number');
	PUT_TRAIT(MM_MISO_UTIL.g_TG_UPD_SELF_UP_REG, 'Update', 'Self Scheduled Up Reg', 'MW value for upward regulation self-scheduled energy.', 'Hour', 0, 1, 'GEN', 'Number');
	PUT_TRAIT(MM_MISO_UTIL.g_TG_UPD_SELF_RESERVE, 'Update', 'Self Scheduled Reserve', 'MW value for self-scheduled energy.', 'Hour', 0, 1, 'GEN', 'Number');
END;
/
