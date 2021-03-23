DECLARE
	v_DISPLAY_ORDER BINARY_INTEGER := 0;
	v_TG TRANSACTION_TRAIT_GROUP%ROWTYPE;
	v_STATUS NUMBER;
	v_PREV_TRAIT_GROUP_ID NUMBER(9) := -1;

	PROCEDURE PUT_TRAIT
		(
		p_TRAIT_GROUP_ID IN NUMBER,
		p_TRAIT_GROUP_NAME IN VARCHAR2,
		p_TRAIT_INDEX IN NUMBER,
		p_TRAIT_NAME IN VARCHAR2,
		p_TRAIT_INTERVAL IN VARCHAR2,
		p_EDIT_TYPE IN VARCHAR2,
		p_TRAIT_CATEGORY IN VARCHAR2,
		p_TRAIT_GROUP_TYPE IN VARCHAR2,
		p_IS_SPARSE IN NUMBER := 0,
		p_IS_SERIES IN NUMBER := 0,
		p_DEFAULT_NUM_SETS IN NUMBER := 3,
		p_FORMAT IN VARCHAR2 := NULL,
		p_COMBO_LIST IN VARCHAR2 := NULL,
		p_EDIT_MASK IN VARCHAR2 := NULL,
		p_AFTER_EDIT_VALIDATION IN VARCHAR2 := NULL,
		p_IS_STATEMENT_TYPE_SPECIFIC IN NUMBER := 0
		) AS
		v_DATA_TYPE VARCHAR2(16);
	BEGIN
		v_DISPLAY_ORDER := v_DISPLAY_ORDER + 1;

		v_DATA_TYPE := CASE p_EDIT_TYPE
			WHEN 'Checkbox' THEN 'Boolean'
			WHEN 'Normal' THEN 'String'
			WHEN 'Combo' THEN 'String'
			WHEN 'Date-Picker' THEN 'Date'
			ELSE 'Number'
		END;

		v_TG.TRAIT_GROUP_INTERVAL := p_TRAIT_INTERVAL;
		v_TG.IS_SPARSE := p_IS_SPARSE;
		v_TG.IS_STATEMENT_TYPE_SPECIFIC := p_IS_STATEMENT_TYPE_SPECIFIC;
		v_TG.TRAIT_GROUP_ID := p_TRAIT_GROUP_ID;
		v_TG.TRAIT_GROUP_NAME := 'SEM ' || p_TRAIT_GROUP_NAME;
		v_TG.DISPLAY_ORDER := v_DISPLAY_ORDER;
		v_TG.TRAIT_CATEGORY := p_TRAIT_CATEGORY;
		v_TG.TRAIT_GROUP_TYPE := p_TRAIT_GROUP_TYPE;
		v_TG.IS_SERIES := p_IS_SERIES;
		v_TG.DEFAULT_NUMBER_OF_SETS := p_DEFAULT_NUM_SETS;
        v_TG.ENTRY_DATE := SYSDATE;

		--Non-Series Trait Groups -- Trait name is null.
		IF p_TRAIT_NAME IS NULL THEN
			v_TG.DISPLAY_NAME := 'SEM';

			TG.UPSERT_TRAIT_GROUP(v_TG);
			EM.PUT_TRANSACTION_TRAIT(v_TG.TRAIT_GROUP_ID, 1, 0, p_TRAIT_GROUP_NAME, 1, v_DATA_TYPE, p_FORMAT, p_COMBO_LIST, p_EDIT_MASK, p_AFTER_EDIT_VALIDATION);
		ELSE
			v_TG.DISPLAY_NAME := p_TRAIT_GROUP_NAME;

			IF v_PREV_TRAIT_GROUP_ID <> v_TG.TRAIT_GROUP_ID THEN
				TG.UPSERT_TRAIT_GROUP(v_TG);
			END IF;

			EM.PUT_TRANSACTION_TRAIT(
				v_TG.TRAIT_GROUP_ID, p_TRAIT_INDEX, 0, p_TRAIT_NAME, p_TRAIT_INDEX, v_DATA_TYPE, p_FORMAT, p_COMBO_LIST, p_EDIT_MASK, p_AFTER_EDIT_VALIDATION);
		END IF;

		v_PREV_TRAIT_GROUP_ID := v_TG.TRAIT_GROUP_ID;

	END PUT_TRAIT;

BEGIN -- MAIN
	v_TG.TRAIT_GROUP_ALIAS := '?';
	v_TG.TRAIT_GROUP_DESC := 'SEM Trait';
	v_TG.SC_ID := ID.ID_FOR_SC('SEM');

-- Common to All
PUT_TRAIT( MM_SEM_UTIL.g_TG_EXT_IDENT, 'External Identifier', 1, '', 'Day', 'Normal', '%', 'Offer Info - %');
PUT_TRAIT( MM_SEM_UTIL.g_TG_SEM_TXN_ID, 'SEM Transaction ID', 1, '', 'Day', 'Normal', '%', 'Offer Info - %');

-- SRAs
PUT_TRAIT( MM_SEM_UTIL.g_TG_SRA_START_TIME, 'Start Time', 1, '', 'Day', 'Normal', 'SRA', '%');
PUT_TRAIT( MM_SEM_UTIL.g_TG_SRA_VALUE, 'Monetary Value', 1, '', 'Day', 'Numeric', 'SRA', '%');
PUT_TRAIT( MM_SEM_UTIL.g_TG_SRA_VALIDITY_STATUS, 'Validity Status', 1, 'Rejected', 'Day', 'Checkbox', 'SRA', '%');
PUT_TRAIT(MM_SEM_UTIL.g_TG_SRA_VALIDITY_STATUS, 'Validity Status', 2, 'Cancelled', 'Day', 'Checkbox', 'SRA', '%');

-- Units
-- Under test
PUT_TRAIT( MM_SEM_UTIL.g_TG_GEN_UNDER_TEST, 'Under Test', MM_SEM_UTIL.g_TI_UNDER_TEST, '', 'Day', 'Checkbox', 'Generation | Load', 'Offer Info - PPMG,VPMG,PPTG');
PUT_TRAIT( MM_SEM_UTIL.g_TG_GEN_UNDER_TEST, 'Under Test', MM_SEM_UTIL.g_TI_STATUS, 'Under Test Status', 'Day', 'Normal', '', '');
PUT_TRAIT( MM_SEM_UTIL.g_TG_GEN_UNDER_TEST, 'Under Test', MM_SEM_UTIL.g_TI_TXN_ID, 'Under Test Txn ID', 'Day', 'Normal', '', '');

PUT_TRAIT( MM_SEM_UTIL.g_TG_STANDING_OFFER, 'Standing Offer', MM_SEM_UTIL.g_TI_STANDING_TYPE, 'Standing Type', 'Day', 'Combo', 'Generation | Load | Nomination', 'Offer Info - %', p_COMBO_LIST => 'None|ALL|MON|TUE|WED|THU|FRI|SAT|SUN');
PUT_TRAIT( MM_SEM_UTIL.g_TG_STANDING_OFFER, 'Standing Offer', MM_SEM_UTIL.g_TI_STANDING_EXPIRY_DATE, 'Standing Expiry Date', 'Day', 'Date-Picker', '', '', p_FORMAT => 'yyyy-MM-dd');
-- Offer data (CO)
PUT_TRAIT( MM_SEM_UTIL.g_TG_IC_MAX_CAP, 'Max Capacity', MM_SEM_UTIL.g_TI_IC_MAX_IMPORT, 'Import', '30 Minute', 'Numeric', 'Nomination', 'CO - I');
PUT_TRAIT( MM_SEM_UTIL.g_TG_IC_MAX_CAP, 'Max Capacity', MM_SEM_UTIL.g_TI_IC_MAX_EXPORT, 'Export', '30 Minute', 'Numeric', '', '');
PUT_TRAIT( MM_SEM_UTIL.g_TG_OFFER_FORECAST, 'Forecast', MM_SEM_UTIL.g_TI_GEN_FORECAST_MIN, 'Min MW', '30 Minute', 'Numeric', 'Generation | Load', 'CO - %');
PUT_TRAIT( MM_SEM_UTIL.g_TG_OFFER_FORECAST, 'Forecast', MM_SEM_UTIL.g_TI_GEN_FORECAST_MAX, 'Max MW', '30 Minute', 'Numeric', '', '');
PUT_TRAIT( MM_SEM_UTIL.g_TG_OFFER_FORECAST, 'Forecast', MM_SEM_UTIL.g_TI_GEN_FORECAST_MIN_OUTPUT, 'Min Output MW', '30 Minute', 'Numeric', '', '');
PUT_TRAIT( MM_SEM_UTIL.g_TG_OFFER_FORECAST, 'Forecast', MM_SEM_UTIL.g_TI_GEN_FORECAST_FUEL_USE, 'Fuel Use', '30 Minute', 'Combo', 'Generation | Load', '', p_COMBO_LIST => 'PRIMARY|SECONDARY');
PUT_TRAIT( MM_SEM_UTIL.g_TG_OFFER_FORECAST, 'Forecast', MM_SEM_UTIL.g_TI_GEN_FORECAST_2ND_MAX_MW, 'Secondary Max MW', '30 Minute', 'Numeric', 'Generation | Load', '');
PUT_TRAIT( MM_SEM_UTIL.g_TG_OFFER_NO_LOAD_COST, 'No Load Cost', 1, '', 'Day', 'Numeric', 'Generation | Load', 'CO - DU,PPMG,VPMG,PPTG');
PUT_TRAIT( MM_SEM_UTIL.g_TG_OFFER_NOM_PROFILE, 'Nomination Profile', MM_SEM_UTIL.g_TI_OFFER_1ST_NOM_PROFILE, 'Primary', '30 Minute', 'Numeric', 'Generation | Load', 'CO - SU,PPTG,VPTG');
PUT_TRAIT( MM_SEM_UTIL.g_TG_OFFER_NOM_PROFILE, 'Nomination Profile', MM_SEM_UTIL.g_TI_OFFER_2ND_NOM_PROFILE, 'Secondary', '30 Minute', 'Numeric', 'Generation | Load', 'CO - SU,PPTG,VPTG');
PUT_TRAIT( MM_SEM_UTIL.g_TG_OFFER_DEC_PRICE, 'Decremental Price', 1, '', '30 Minute', 'Numeric', 'Generation | Load', 'CO - SU,PPTG,VPTG');
PUT_TRAIT( MM_SEM_UTIL.g_TG_GEN_STARTUP_COSTS, 'Startup Costs', MM_SEM_UTIL.g_TI_GEN_HOT_START_COST, 'Hot Start', 'Day', 'Numeric', 'Generation', 'CO - PPMG,VPMG,PPTG');
PUT_TRAIT( MM_SEM_UTIL.g_TG_GEN_STARTUP_COSTS, 'Startup Costs', MM_SEM_UTIL.g_TI_GEN_WARM_START_COST, 'Warm Start', 'Day', 'Numeric', '', '');
PUT_TRAIT( MM_SEM_UTIL.g_TG_GEN_STARTUP_COSTS, 'Startup Costs', MM_SEM_UTIL.g_TI_GEN_COLD_START_COST, 'Cold Start', 'Day', 'Numeric', '', '');
PUT_TRAIT( MM_SEM_UTIL.g_TG_GEN_SPIN_GEN_COST, 'Spinning Generation Cost', 1, '', 'Day', 'Numeric', 'Generation', 'CO - %');
PUT_TRAIT( MM_SEM_UTIL.g_TG_GEN_SPIN_PUMP_COST, 'Spinning Pump Cost', 1, '', 'Day', 'Numeric', 'Generation', 'CO(PS)');
PUT_TRAIT( MM_SEM_UTIL.g_TG_GEN_MIN_GEN_COST, 'Minimum Generation Cost', 1, '', 'Day', 'Numeric', 'Generation', 'CO - %');
PUT_TRAIT( MM_SEM_UTIL.g_TG_GEN_RESERVOIR_CO, 'Reservoir Level', MM_SEM_UTIL.g_TI_GEN_RESERVOIR_TARGET_MWH, 'Target Level MWH', 'Day', 'Numeric', 'Generation', 'CO(PS)');
PUT_TRAIT( MM_SEM_UTIL.g_TG_GEN_RESERVOIR_CO, 'Reservoir Level', MM_SEM_UTIL.g_TI_GEN_RESERVOIR_TARGET_PCT, 'Target Level %', 'Day', 'Numeric', '', '');
PUT_TRAIT( MM_SEM_UTIL.g_TG_GEN_RESERVOIR_CO, 'Reservoir Level', MM_SEM_UTIL.g_TI_GEN_RESERVOIR_PRIOR_MWH, 'Prior Day End Level MWH', 'Day', 'Numeric', '', '');
PUT_TRAIT( MM_SEM_UTIL.g_TG_GEN_RESERVOIR_CO, 'Reservoir Level', MM_SEM_UTIL.g_TI_GEN_RESERVOIR_OP_CAP_MWH, 'Operational Cap MWH', 'Day', 'Numeric', '', '');
PUT_TRAIT( MM_SEM_UTIL.g_TG_GEN_LIMIT, 'Energy Limited', MM_SEM_UTIL.g_TI_GEN_LIMIT_MWH, 'Limit MWH', 'Day', 'Numeric', 'Generation', 'CO(EL)');
PUT_TRAIT( MM_SEM_UTIL.g_TG_GEN_LIMIT, 'Energy Limited', MM_SEM_UTIL.g_TI_GEN_LIMIT_FACTOR, 'Limit Factor', 'Day', 'Numeric', '', '');
PUT_TRAIT( MM_SEM_UTIL.g_TG_GEN_IS_LIMITED, 'Energy Limited?', 1, '', '30 Minute', 'Checkbox', 'Generation', 'CO(EL)');
PUT_TRAIT( MM_SEM_UTIL.g_TG_LOAD_SHUTDOWN_COST, 'Shutdown Cost', 1, '', 'Day', 'Numeric', 'Load', 'CO - DU');
-- Registration data (TO)
PUT_TRAIT( MM_SEM_UTIL.g_TG_GEN_MAX_GEN, 'Maximum Generation', 1, '', 'Day', 'Numeric', 'Generation', 'TO - %', 1);
PUT_TRAIT( MM_SEM_UTIL.g_TG_GEN_MIN_ONTIME, 'Minimum On Time', 1, '', 'Day', 'Numeric', 'Generation', 'TO - PPMG,PPTG,VPMG,VPTG', 1);
PUT_TRAIT( MM_SEM_UTIL.g_TG_GEN_MIN_OFFTIME, 'Minimum Off Time', 1, '', 'Day', 'Numeric', 'Generation', 'TO - PPMG,PPTG,VPMG,VPTG', 1);
PUT_TRAIT( MM_SEM_UTIL.g_TG_GEN_MIN_STABLE_GEN, 'Minimum Stable Generation', 1, '', 'Day', 'Numeric', 'Generation', 'TO - PPMG,PPTG,VPMG,VPTG', 1);
PUT_TRAIT( MM_SEM_UTIL.g_TG_GEN_CYCLE_EFF, 'Cycle Efficiency', 1, '', 'Day', 'Numeric', 'Generation', 'TO(PS)');
PUT_TRAIT( MM_SEM_UTIL.g_TG_GEN_BLOCK_LOAD, 'Block Load', MM_SEM_UTIL.g_TI_BLOCK_LOAD_HOT, 'Hot', 'Day', 'Numeric', 'Generation', 'TO(BL)', 1);
PUT_TRAIT( MM_SEM_UTIL.g_TG_GEN_BLOCK_LOAD, 'Block Load', MM_SEM_UTIL.g_TI_BLOCK_LOAD_WARM, 'Warm', 'Day', 'Numeric', '', '', 1);
PUT_TRAIT( MM_SEM_UTIL.g_TG_GEN_BLOCK_LOAD, 'Block Load', MM_SEM_UTIL.g_TI_BLOCK_LOAD_COLD, 'Cold', 'Day', 'Numeric', '', '', 1);
PUT_TRAIT( MM_SEM_UTIL.g_TG_GEN_DELOADING, 'Deloading', MM_SEM_UTIL.g_TI_DELOAD_RATE, 'Rate', 'Day', 'Numeric', 'Generation', 'TO - PPMG,PPTG,VPMG,VPTG', 1, 1, 2);
PUT_TRAIT( MM_SEM_UTIL.g_TG_GEN_DELOADING, 'Deloading', MM_SEM_UTIL.g_TI_DELOAD_BREAKPOINT, 'Breakpoint', 'Day', 'Numeric', '', '', 1);
PUT_TRAIT( MM_SEM_UTIL.g_TG_GEN_DWELL_TIME, 'Dwell Time', MM_SEM_UTIL.g_TI_DWELL_TIME, 'Time', 'Day', 'Numeric', 'Generation', 'TO - PPMG,PPTG,VPMG,VPTG', 1, 1, 3);
PUT_TRAIT( MM_SEM_UTIL.g_TG_GEN_DWELL_TIME, 'Dwell Time', MM_SEM_UTIL.g_TI_DWELL_TRIGGER_POINT, 'Trigger Point', 'Day', 'Numeric', '', '', 1);
PUT_TRAIT( MM_SEM_UTIL.g_TG_GEN_END_STARTUP, 'End Point of Start Up Period', 1, '', 'Day', 'Numeric', 'Generation', 'TO - PPMG,PPTG,VPMG,VPTG', 1);
PUT_TRAIT( MM_SEM_UTIL.g_TG_GEN_LOADING_HOT, 'Loading - Hot', MM_SEM_UTIL.g_TI_LOADING_HOT_RATE, 'Rate', 'Day', 'Numeric', 'Generation', 'TO - PPMG,PPTG,VPMG,VPTG', 1, 1, 3);
PUT_TRAIT( MM_SEM_UTIL.g_TG_GEN_LOADING_HOT, 'Loading - Hot', MM_SEM_UTIL.g_TI_LOADING_HOT_BREAKPOINT, 'Breakpoint', 'Day', 'Numeric', '', '', 1);
PUT_TRAIT( MM_SEM_UTIL.g_TG_GEN_LOADING_WARM, 'Loading - Warm', MM_SEM_UTIL.g_TI_LOADING_WARM_RATE, 'Rate', 'Day', 'Numeric', 'Generation', 'TO - PPMG,PPTG,VPMG,VPTG', 1, 1, 3);
PUT_TRAIT( MM_SEM_UTIL.g_TG_GEN_LOADING_WARM, 'Loading - Warm', MM_SEM_UTIL.g_TI_LOADING_WARM_BREAKPOINT, 'Breakpoint', 'Day', 'Numeric', '', '', 1);
PUT_TRAIT( MM_SEM_UTIL.g_TG_GEN_LOADING_COLD, 'Loading - Cold', MM_SEM_UTIL.g_TI_LOADING_COLD_RATE, 'Rate', 'Day', 'Numeric', 'Generation', 'TO - PPMG,PPTG,VPMG,VPTG', 1, 1, 3);
PUT_TRAIT( MM_SEM_UTIL.g_TG_GEN_LOADING_COLD, 'Loading - Cold', MM_SEM_UTIL.g_TI_LOADING_COLD_BREAKPOINT, 'Breakpoint', 'Day', 'Numeric', '', '', 1);
PUT_TRAIT( MM_SEM_UTIL.g_TG_GEN_MIN_GEN, 'Minimum Generation', 1, '', 'Day', 'Numeric', 'Generation', 'TO - PPMG,PPTG,VPMG,VPTG', 1);
PUT_TRAIT( MM_SEM_UTIL.g_TG_GEN_RAMP_UP, 'Ramp Up Rates', MM_SEM_UTIL.g_TI_RAMP_UP_RATE, 'Rate', 'Day', 'Numeric', 'Generation', 'TO - PPMG,PPTG,VPMG,VPTG', 1, 1, 5);
PUT_TRAIT( MM_SEM_UTIL.g_TG_GEN_RAMP_UP, 'Ramp Up Rates', MM_SEM_UTIL.g_TI_RAMP_UP_BREAKPOINT, 'Breakpoint', 'Day', 'Numeric', '', '', 1);
PUT_TRAIT( MM_SEM_UTIL.g_TG_GEN_RAMP_DOWN, 'Ramp Down Rates', MM_SEM_UTIL.g_TI_RAMP_DOWN_RATE, 'Rate', 'Day', 'Numeric', 'Generation', 'TO - PPMG,PPTG,VPMG,VPTG', 1, 1, 5);
PUT_TRAIT( MM_SEM_UTIL.g_TG_GEN_RAMP_DOWN, 'Ramp Down Rates', MM_SEM_UTIL.g_TI_RAMP_DOWN_BREAKPOINT, 'Breakpoint', 'Day', 'Numeric', '', '', 1);
PUT_TRAIT( MM_SEM_UTIL.g_TG_GEN_SOAK_TIME_HOT, 'Soak Time - Hot', MM_SEM_UTIL.g_TI_SOAK_TIME_HOT, 'Time', 'Day', 'Numeric', 'Generation', 'TO - PPMG,PPTG,VPMG,VPTG', 1, 1, 2);
PUT_TRAIT( MM_SEM_UTIL.g_TG_GEN_SOAK_TIME_HOT, 'Soak Time - Hot', MM_SEM_UTIL.g_TI_SOAK_TRIGGER_POINT_HOT, 'Trigger Point', 'Day', 'Numeric', '', '', 1);
PUT_TRAIT( MM_SEM_UTIL.g_TG_GEN_SOAK_TIME_WARM, 'Soak Time - Warm', MM_SEM_UTIL.g_TI_SOAK_TIME_WARM, 'Time', 'Day', 'Numeric', 'Generation', 'TO - PPMG,PPTG,VPMG,VPTG', 1, 1, 2);
PUT_TRAIT( MM_SEM_UTIL.g_TG_GEN_SOAK_TIME_WARM, 'Soak Time - Warm', MM_SEM_UTIL.g_TI_SOAK_TRIGGER_POINT_WARM, 'Trigger Point', 'Day', 'Numeric', '', '', 1);
PUT_TRAIT( MM_SEM_UTIL.g_TG_GEN_SOAK_TIME_COLD, 'Soak Time - Cold', MM_SEM_UTIL.g_TI_SOAK_TIME_COLD, 'Time', 'Day', 'Numeric', 'Generation', 'TO - PPMG,PPTG,VPMG,VPTG', 1, 1, 2);
PUT_TRAIT( MM_SEM_UTIL.g_TG_GEN_SOAK_TIME_COLD, 'Soak Time - Cold', MM_SEM_UTIL.g_TI_SOAK_TRIGGER_POINT_COLD, 'Trigger Point', 'Day', 'Numeric', '', '', 1);
PUT_TRAIT( MM_SEM_UTIL.g_TG_GEN_RESERVOIR_TO, 'Reservoir Capacity', MM_SEM_UTIL.g_TI_GEN_RESERVOIR_MAX_CAP, 'Max Capacity', 'Day', 'Numeric', 'Generation', 'TO(PS)', 1);
PUT_TRAIT( MM_SEM_UTIL.g_TG_GEN_RESERVOIR_TO, 'Reservoir Capacity', MM_SEM_UTIL.g_TI_GEN_RESERVOIR_MIN_CAP, 'Min Capacity', 'Day', 'Numeric', '', '', 1);
PUT_TRAIT( MM_SEM_UTIL.g_TG_GEN_RESERVOIR_TO, 'Reservoir Capacity', MM_SEM_UTIL.g_TI_GEN_RESERVOIR_PUMP_CAP, 'Pumping Capacity', 'Day', 'Numeric', '', '', 1);
PUT_TRAIT( MM_SEM_UTIL.g_TG_GEN_SYNC_TIME, 'Min Sync Time ', MM_SEM_UTIL.g_TI_GEN_SYNC_TIME_HOT, 'Hot', 'Day', 'Numeric', 'Generation', 'TO - PPMG,PPTG,VPMG,VPTG', 1);
PUT_TRAIT( MM_SEM_UTIL.g_TG_GEN_SYNC_TIME, 'Min Sync Time ', MM_SEM_UTIL.g_TI_GEN_SYNC_TIME_WARM, 'Warm', 'Day', 'Numeric', '', '', 1);
PUT_TRAIT( MM_SEM_UTIL.g_TG_GEN_SYNC_TIME, 'Min Sync Time ', MM_SEM_UTIL.g_TI_GEN_SYNC_TIME_COLD, 'Cold', 'Day', 'Numeric', '', '', 1);
PUT_TRAIT( MM_SEM_UTIL.g_TG_GEN_HR_ELAPSED_SYNC, 'Num Hours Elapsed - Sync', MM_SEM_UTIL.g_TI_GEN_HR_ELAPSED_SYNC_HOT, 'Hot', 'Day', 'Numeric', 'Generation', 'TO - PPMG,PPTG,VPMG,VPTG', 1);
PUT_TRAIT( MM_SEM_UTIL.g_TG_GEN_HR_ELAPSED_SYNC, 'Num Hours Elapsed - Sync', MM_SEM_UTIL.g_TI_GEN_HR_ELAPSED_SYNC_WARM, 'Warm', 'Day', 'Numeric', '', '', 1);
PUT_TRAIT( MM_SEM_UTIL.g_TG_GEN_HR_ELAPSED_SYNC, 'Num Hours Elapsed - Sync', MM_SEM_UTIL.g_TI_GEN_HR_ELAPSED_SYNC_COLD, 'Cold', 'Day', 'Numeric', '', '', 1);
PUT_TRAIT( MM_SEM_UTIL.g_TG_GEN_ST_MAX_CAP, 'Short-Term Max Capacity', 1, '', 'Day', 'Numeric', 'Generation', 'TO - PPMG,PPTG,VPMG,VPTG', 1);
PUT_TRAIT( MM_SEM_UTIL.g_TG_GEN_ST_MAX_TIME, 'Short-Term Max Time', 1, '', 'Day', 'Numeric', 'Generation', 'TO - PPMG,PPTG,VPMG,VPTG', 1);
PUT_TRAIT( MM_SEM_UTIL.g_TG_OFFER_MAX_ONTIME, 'Maximum On Time', 1, '', 'Day', 'Numeric', 'Generation | Load', 'TO - PPMG,PPTG,VPMG,VPTG, DU', 1);
PUT_TRAIT( MM_SEM_UTIL.g_TG_OFFER_MAX_OFFTIME, 'Maximum Off Time', 1, '', 'Day', 'Numeric', 'Generation | Load', 'TO - PPMG,PPTG,VPMG,VPTG, DU', 1);
PUT_TRAIT( MM_SEM_UTIL.g_TG_GEN_FORBIDDEN, 'Forbidden Range', MM_SEM_UTIL.g_TI_GEN_FORBIDDEN_START, 'Start', 'Day', 'Numeric', 'Generation', 'TO - PPMG,PPTG,VPMG,VPTG', 1, 1, 2);
PUT_TRAIT( MM_SEM_UTIL.g_TG_GEN_FORBIDDEN, 'Forbidden Range', MM_SEM_UTIL.g_TI_GEN_FORBIDDEN_END, 'End', 'Day', 'Numeric', '', '', 1);
PUT_TRAIT( MM_SEM_UTIL.g_TG_GEN_FIXED_LOAD, 'Fixed Unit Load', 1, '', 'Day', 'Numeric', 'Generation', 'TO - %', 1);
PUT_TRAIT( MM_SEM_UTIL.g_TG_GEN_SCALAR_LOAD, 'Unit Scalar Load', 1, '', 'Day', 'Numeric', 'Generation', 'TO - %', 1);
PUT_TRAIT( MM_SEM_UTIL.g_TG_GEN_STARTUP_TIMES, 'Startup Times', MM_SEM_UTIL.g_TI_GEN_HOT_START_TIME, 'Hot Start', 'Day', 'Numeric', 'Generation', 1);
PUT_TRAIT( MM_SEM_UTIL.g_TG_GEN_STARTUP_TIMES, 'Startup Times', MM_SEM_UTIL.g_TI_GEN_WARM_START_TIME, 'Warm Start', 'Day', 'Numeric', '', '', 1);
PUT_TRAIT( MM_SEM_UTIL.g_TG_GEN_STARTUP_TIMES, 'Startup Times', MM_SEM_UTIL.g_TI_GEN_COLD_START_TIME, 'Cold Start', 'Day', 'Numeric', '', '', 1);
PUT_TRAIT( MM_SEM_UTIL.g_TG_GEN_NUM_STARTS, 'Number of Starts', 1, '', 'Day', 'Numeric', 'Generation', 'TO - PPMG,PPTG,VPMG,VPTG', 1);
PUT_TRAIT( MM_SEM_UTIL.g_TG_GEN_NUM_RUN_HOURS, 'Number of Run Hours', 1, '', 'Day', 'Numeric', 'Generation', 'TO - PPMG,PPTG,VPMG,VPTG', 1);
PUT_TRAIT( MM_SEM_UTIL.g_TG_GEN_MODES_OPERATION, 'Modes of Operation', 1, '', 'Day', '?', 'Generation', '?', 1);
PUT_TRAIT( MM_SEM_UTIL.g_TG_GEN_DROOP, 'Droop', 1, '', 'Day', '?', 'Generation', '?', 1);
PUT_TRAIT( MM_SEM_UTIL.g_TG_GEN_REG_FIRM_CAPACITY, 'Registered Firm Capacity', 1, '', 'Day', 'Numeric', 'Generation', '?', 1);
PUT_TRAIT( MM_SEM_UTIL.g_TG_GEN_NONFIRM_ACCESS_CAP, 'Non-Firm Access Quantity', 1, '', 'Day', 'Numeric', 'Generation', '?', 1);
PUT_TRAIT( MM_SEM_UTIL.g_TG_LOAD_MAX_RAMP_UP, 'Max Ramp Up', 1, '', 'Day', 'Numeric', 'Load', 'TO - DU', 1);
PUT_TRAIT( MM_SEM_UTIL.g_TG_LOAD_MAX_RAMP_DOWN, 'Max Ramp Down', 1, '', 'Day', 'Numeric', 'Load', 'TO - DU', 1);
PUT_TRAIT( MM_SEM_UTIL.g_TG_LOAD_DISP_CAPACITY, 'Dispatchable Capacity', 1, '', 'Day', 'Numeric', 'Load', 'TO - DU', 1);
PUT_TRAIT( MM_SEM_UTIL.g_TG_LOAD_NONDISP_CAPACITY, 'Non-Dispatchable Capacity', 1, '', 'Day', 'Numeric', 'Load', 'TO - DU', 1);
PUT_TRAIT( MM_SEM_UTIL.g_TG_SEM_GATE_REFERENCE, 'Gate Reference', 1, '', '30 Minute', 'Normal', 'Gate Reference', '');
PUT_TRAIT( MM_SEM_UTIL.g_TG_SEM_TRADED_EXPOSURE, 'Traded Exposure', MM_SEM_UTIL.g_TI_SEM_TRADED_EXP_ETEV, 'ETEV', '30 Minute', 'Numeric', 'Traded Exposure', '?', 0, 0, 3, NULL, NULL, NULL, NULL, 1);
PUT_TRAIT( MM_SEM_UTIL.g_TG_SEM_TRADED_EXPOSURE, 'Traded Exposure', MM_SEM_UTIL.g_TI_SEM_TRADED_EXP_CTEV, 'CTEV', '30 Minute', 'Numeric', 'Traded Exposure', '?', 0, 0, 3, NULL, NULL, NULL, NULL, 1);
PUT_TRAIT( MM_SEM_UTIL.g_TG_SEM_TRADED_EXPOSURE, 'Traded Exposure', MM_SEM_UTIL.g_TI_SEM_TRADED_EXP_LLQ, 'LLQ', '30 Minute', 'Numeric', 'Traded Exposure', '?', 0, 0, 3, NULL, NULL, NULL, NULL, 1);
PUT_TRAIT( MM_SEM_UTIL.g_TG_SEM_TRADED_EXPOSURE, 'Traded Exposure', MM_SEM_UTIL.g_TI_SEM_TRADED_EXP_HLQ, 'HLQ', '30 Minute', 'Numeric', 'Traded Exposure', '?', 0, 0, 3, NULL, NULL, NULL, NULL, 1);
PUT_TRAIT( MM_SEM_UTIL.g_TG_SEM_TRADED_EXPOSURE, 'Traded Exposure', MM_SEM_UTIL.g_TI_SEM_TRADED_EXP_MIUN, 'MIUN', '30 Minute', 'Numeric', 'Traded Exposure', '?', 0, 0, 3, NULL, NULL, NULL, NULL, 1);
PUT_TRAIT( MM_SEM_UTIL.g_TG_SEM_TRADED_EXPOSURE, 'Traded Exposure', MM_SEM_UTIL.g_TI_SEM_TRADED_EXP_MSQ, 'MSQ', '30 Minute', 'Numeric', 'Traded Exposure', '?', 0, 0, 3, NULL, NULL, NULL, NULL, 1);
COMMIT;
END;
/
