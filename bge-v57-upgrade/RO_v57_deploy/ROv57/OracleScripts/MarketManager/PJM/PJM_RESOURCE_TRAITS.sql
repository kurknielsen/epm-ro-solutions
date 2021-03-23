DECLARE
	v_SC_ID NUMBER(9);
	v_DISPLAY_ORDER NUMBER(4) := 0;
	v_TG TRANSACTION_TRAIT_GROUP%ROWTYPE;
	v_PREV_TRAIT_GROUP_ID NUMBER(9) := -1;
	v_STATUS NUMBER;
	
	PROCEDURE PUT_TRAIT(
		p_TRAIT_GROUP_ID IN NUMBER, 
		p_TRAIT_GROUP_PJM_TYPE IN VARCHAR2,
		p_TRAIT_GROUP_NAME IN VARCHAR2,
		p_DISPLAY_NAME IN VARCHAR2,
		p_TRAIT_GROUP_INTERVAL IN VARCHAR2,
		p_TRAIT_GROUP_TYPE IN VARCHAR2,
		p_TRAIT_CATEGORY IN VARCHAR2,
		p_DATA_TYPE IN VARCHAR2,
		p_COMBO_LIST IN VARCHAR2 DEFAULT NULL,
		p_EDIT_MASK IN VARCHAR2 DEFAULT NULL,
		p_TRAIT_NAME IN VARCHAR2 DEFAULT NULL,
		p_TRAIT_INDEX IN NUMBER DEFAULT 1
		) IS
		
	BEGIN
		v_DISPLAY_ORDER := v_DISPLAY_ORDER + 10;

		-- Set common TG properties.
		v_TG.SC_ID := v_SC_ID;
		v_TG.TRAIT_GROUP_INTERVAL := p_TRAIT_GROUP_INTERVAL;
		v_TG.IS_SPARSE := 0;
		v_TG.IS_STATEMENT_TYPE_SPECIFIC := 0;
		v_TG.TRAIT_GROUP_ID := p_TRAIT_GROUP_ID;
		v_TG.TRAIT_GROUP_NAME := 'PJM ' || p_TRAIT_GROUP_PJM_TYPE || ' ' || p_TRAIT_GROUP_NAME;
		v_TG.TRAIT_GROUP_DESC := NULL;
		v_TG.DISPLAY_ORDER := v_DISPLAY_ORDER;
		v_TG.TRAIT_CATEGORY := p_TRAIT_CATEGORY;
		v_TG.TRAIT_GROUP_TYPE := p_TRAIT_GROUP_TYPE;

		--Non-Series Trait Groups -- Trait Name is Null
		IF p_TRAIT_NAME IS NULL THEN
			v_TG.IS_SERIES := 0;
			v_TG.DEFAULT_NUMBER_OF_SETS := 0;
			v_TG.DISPLAY_NAME := 'PJM';
	
			TG.UPSERT_TRAIT_GROUP(v_TG);
			EM.PUT_TRANSACTION_TRAIT(v_TG.TRAIT_GROUP_ID, 1, 0, NVL(p_DISPLAY_NAME, p_TRAIT_GROUP_NAME), 1, p_DATA_TYPE, NULL, p_COMBO_LIST, p_EDIT_MASK, NULL);
		--Series Trait Groups specify a Trait Name
		ELSE
			v_TG.IS_SERIES := 1;
			v_TG.DEFAULT_NUMBER_OF_SETS := 4;
			v_TG.DISPLAY_NAME := p_TRAIT_GROUP_NAME;
			
			IF v_PREV_TRAIT_GROUP_ID <> v_TG.TRAIT_GROUP_ID THEN
				TG.UPSERT_TRAIT_GROUP(v_TG);
			END IF;
			EM.PUT_TRANSACTION_TRAIT(v_TG.TRAIT_GROUP_ID, p_TRAIT_INDEX, 0, p_TRAIT_NAME, p_TRAIT_INDEX, p_DATA_TYPE, NULL, p_COMBO_LIST, p_EDIT_MASK, NULL);
		END IF;
		v_PREV_TRAIT_GROUP_ID := v_TG.TRAIT_GROUP_ID;
		
	EXCEPTION
		WHEN OTHERS THEN
			UT.DEBUG_TRACE('TRAIT_GROUP:DID NOT SUCCESSFULLY CREATE ' || v_TG.TRAIT_GROUP_NAME);
	END PUT_TRAIT;

BEGIN

	v_SC_ID := ID.ID_FOR_SC('PJM');
	
	-- Schedule Traits
	PUT_TRAIT(MM_PJM_UTIL.g_TG_SCH_MARKET, 'Schedule', 'Market', '', 'Day', 'Detail', 'Schedule', 'String');
	PUT_TRAIT(MM_PJM_UTIL.g_TG_SCH_USE_STARTUP_NO_LOAD, 'Schedule', 'UseStartupNoLoad', '', 'Day', 'Detail', 'Schedule', 'String', 'true|false');
	PUT_TRAIT(MM_PJM_UTIL.g_TG_SCH_PRIMARY_FUEL, 'Schedule', 'PrimaryFuel', '', 'Day', 'Detail', 'Schedule', 'String');
	PUT_TRAIT(MM_PJM_UTIL.g_TG_SCH_SECONDARY_FUEL, 'Schedule', 'SecondaryFuel', '', 'Day', 'Detail', 'Schedule', 'String');
	PUT_TRAIT(MM_PJM_UTIL.g_TG_SEL_AVAILABLE, 'Selection', 'Available', 'Available', 'Day', 'Summary', 'Schedule', 'String', 'true|false');
	
	PUT_TRAIT(MM_PJM_UTIL.g_TG_SCH_EMER_MIN, 'Schedule', 'MinEmergencyMW', 'Emer Min', 'Day', 'Summary', 'Schedule', 'Number');
	PUT_TRAIT(MM_PJM_UTIL.g_TG_SCH_ECON_MIN, 'Schedule', 'MinEconomicMW', 'Econ Min', 'Day', 'Summary', 'Schedule', 'Number');
	PUT_TRAIT(MM_PJM_UTIL.g_TG_SCH_ECON_MAX, 'Schedule', 'MaxEconomicMW', 'Econ Max', 'Day', 'Summary', 'Schedule', 'Number');
	PUT_TRAIT(MM_PJM_UTIL.g_TG_SCH_EMER_MAX, 'Schedule', 'MaxEmergencyMW', 'Emer Max', 'Day', 'Summary', 'Schedule', 'Number');
	PUT_TRAIT(MM_PJM_UTIL.g_TG_SCH_MIN_RUNTIME, 'Schedule', 'MinRuntime', '', 'Day', 'Detail', 'Schedule', 'String');
	PUT_TRAIT(MM_PJM_UTIL.g_TG_SCH_MAX_RUNTIME, 'Schedule', 'MaxRuntime', '', 'Day', 'Detail', 'Schedule', 'String');
	PUT_TRAIT(MM_PJM_UTIL.g_TG_SCH_MIN_DOWNTIME, 'Schedule', 'MinDowntime', '', 'Day', 'Detail', 'Schedule', 'String');
	PUT_TRAIT(MM_PJM_UTIL.g_TG_SCH_HOT_TO_COLD_TIME, 'Schedule', 'HotToColdTime', '', 'Day', 'Detail', 'Schedule', 'String');
	PUT_TRAIT(MM_PJM_UTIL.g_TG_SCH_HOT_TO_INTER_TIME, 'Schedule', 'HotToIntermediateTime', '', 'Day', 'Detail', 'Schedule', 'String');
	PUT_TRAIT(MM_PJM_UTIL.g_TG_SCH_COLD_START_TIME, 'Schedule', 'ColdStartupTime', '', 'Day', 'Detail', 'Schedule', 'String');
	PUT_TRAIT(MM_PJM_UTIL.g_TG_SCH_INTER_START_TIME, 'Schedule', 'IntermediateStartupTime', '', 'Day', 'Detail', 'Schedule', 'String');
	PUT_TRAIT(MM_PJM_UTIL.g_TG_SCH_HOT_START_TIME, 'Schedule', 'HotStartupTime', '', 'Day', 'Detail', 'Schedule', 'String');
	PUT_TRAIT(MM_PJM_UTIL.g_TG_SCH_COLD_NOTIF_TIME, 'Schedule', 'ColdNotificationTime', '', 'Day', 'Detail', 'Schedule', 'String');
	PUT_TRAIT(MM_PJM_UTIL.g_TG_SCH_INTER_NOTIF_TIME, 'Schedule', 'IntermediateNotificationTime', '', 'Day', 'Detail', 'Schedule', 'String');
	PUT_TRAIT(MM_PJM_UTIL.g_TG_SCH_HOT_NOTIF_TIME, 'Schedule', 'HotNotificationTime', '', 'Day', 'Detail', 'Schedule', 'String');
	PUT_TRAIT(MM_PJM_UTIL.g_TG_SCH_MAX_DAILY_STARTS, 'Schedule', 'MaxDailyStarts', '', 'Day', 'Detail', 'Schedule', 'Number');
	PUT_TRAIT(MM_PJM_UTIL.g_TG_SCH_MAX_WEEKLY_STARTS, 'Schedule', 'MaxWeeklyStarts', '', 'Day', 'Detail', 'Schedule', 'Number');
	PUT_TRAIT(MM_PJM_UTIL.g_TG_SCH_MAX_WEEKLY_ENERGY, 'Schedule', 'MaxWeeklyEnergy', '', 'Day', 'Detail', 'Schedule', 'Number');
	PUT_TRAIT(MM_PJM_UTIL.g_TG_SCH_NO_LOAD_COST, 'Schedule', 'NoLoadCost', '', 'Day', 'Detail', 'Schedule', 'Number');
	PUT_TRAIT(MM_PJM_UTIL.g_TG_SCH_COLD_START_COST, 'Schedule', 'ColdStartupCost', '', 'Day', 'Detail', 'Schedule', 'Number');
	PUT_TRAIT(MM_PJM_UTIL.g_TG_SCH_INTER_START_COST, 'Schedule', 'IntermediateStartupCost', '', 'Day', 'Detail', 'Schedule', 'Number');
	PUT_TRAIT(MM_PJM_UTIL.g_TG_SCH_HOT_START_COST, 'Schedule', 'HotStartupCost', '', 'Day', 'Detail', 'Schedule', 'Number');
    PUT_TRAIT(MM_PJM_UTIL.g_TG_SCH_UNAVAILABLE, 'Schedule', 'Unavailable', '', 'Day', 'Detail', 'Schedule', 'String');
    PUT_TRAIT(MM_PJM_UTIL.g_TG_SCH_SELF_SCHEDULED, 'Schedule', 'SelfScheduled', '', 'Day', 'Detail', 'Schedule', 'String');
    PUT_TRAIT(MM_PJM_UTIL.g_TG_SCH_CONDENSE_AVAILABLE, 'Schedule', 'CondenseAvailable', '', 'Day', 'Detail', 'Schedule', 'String');
    PUT_TRAIT(MM_PJM_UTIL.g_TG_SCH_SPIN_AS_CONDENSER, 'Schedule', 'SpinAsCondenser', '', 'Day', 'Detail', 'Schedule', 'String');
    PUT_TRAIT(MM_PJM_UTIL.g_TG_SCH_SELF_SCHED_MW, 'Schedule', 'SelfScheduledMW', '', 'Hour', 'Detail', 'Schedule', 'Number');
	
	v_DISPLAY_ORDER := 0;
	PUT_TRAIT(MM_PJM_UTIL.g_TG_OFF_SLOPE, 'Offer', 'Slope', '', 'Day', 'Summary', 'Schedule', 'String', 'Block Mode|Point Slope');
	
	v_DISPLAY_ORDER := 0;
	-- Non-Series Unit Detail Traits
	PUT_TRAIT(MM_PJM_UTIL.g_TG_DEF_COMMIT_STATUS, 'UnitDetail', 'CommitStatus', '', 'Day', 'UnitDetail', 'Unit Data', 'String', 'Unavailable|Economic|Emergency|MustRun');
	PUT_TRAIT(MM_PJM_UTIL.g_TG_DEF_FIXED_GEN, 'UnitDetail', 'FixedGen', '', 'Day', 'UnitDetail', 'Unit Data', 'String', 'true|false');
	PUT_TRAIT(MM_PJM_UTIL.g_TG_DEF_EMER_MIN, 'UnitDetail', 'MinEmergencyLimit', 'Emer Min', 'Day', 'UnitDetail', 'Unit Data', 'Number');
	PUT_TRAIT(MM_PJM_UTIL.g_TG_DEF_ECON_MIN, 'UnitDetail', 'MinEconomicLimit', 'Econ Min', 'Day', 'UnitDetail', 'Unit Data', 'Number');
	PUT_TRAIT(MM_PJM_UTIL.g_TG_DEF_ECON_MAX, 'UnitDetail', 'MaxEconomicLimit', 'Econ Max', 'Day', 'UnitDetail', 'Unit Data', 'Number');
	PUT_TRAIT(MM_PJM_UTIL.g_TG_DEF_EMER_MAX, 'UnitDetail', 'MaxEmergencyLimit', 'Emer Max', 'Day', 'UnitDetail', 'Unit Data', 'Number');
	PUT_TRAIT(MM_PJM_UTIL.g_TG_DEF_REGULATION_MIN, 'UnitDetail', 'MinRegulationLimit', 'Reg Min', 'Day', 'UnitDetail', 'Unit Data', 'Number');
	PUT_TRAIT(MM_PJM_UTIL.g_TG_DEF_REGULATION_MAX, 'UnitDetail', 'MaxRegulationLimit', 'Reg Max', 'Day', 'UnitDetail', 'Unit Data', 'Number');
	PUT_TRAIT(MM_PJM_UTIL.g_TG_DEF_SPINNING_MAX, 'UnitDetail', 'MaxSpinningLimit', 'Spin Min', 'Day', 'UnitDetail', 'Unit Data', 'Number');
	PUT_TRAIT(MM_PJM_UTIL.g_TG_DEF_RAMP_RATE, 'UnitDetail', 'DefaultRampRate', '', 'Day', 'UnitDetail', 'Unit Data', 'Number');
	PUT_TRAIT(MM_PJM_UTIL.g_TG_DEF_CONDENSE_AVAILABLE, 'UnitDetail', 'CondenseAvailable', '', 'Day', 'UnitDetail', 'Unit Data', 'String', 'true|false');
	PUT_TRAIT(MM_PJM_UTIL.g_TG_DEF_CONDENSE_START_COST, 'UnitDetail', 'CondenseStartupCost', '', 'Day', 'UnitDetail', 'Unit Data', 'Number');
	PUT_TRAIT(MM_PJM_UTIL.g_TG_DEF_CONDENSE_ENERGY_USAGE, 'UnitDetail', 'CondenseEnergyUsage', '', 'Day', 'UnitDetail', 'Unit Data', 'Number');
	PUT_TRAIT(MM_PJM_UTIL.g_TG_DEF_CONDENSE_NOTIF, 'UnitDetail', 'CondenseNotification', '', 'Day', 'UnitDetail', 'Unit Data', 'Number');    
	PUT_TRAIT(MM_PJM_UTIL.g_TG_DEF_CONDENSE_HOURLY_COST, 'UnitDetail', 'CondenseHourlyCost', '', 'Day', 'UnitDetail', 'Unit Data', 'Number');
	PUT_TRAIT(MM_PJM_UTIL.g_TG_DEF_LOW_ECON_MW, 'UnitDetail', 'LowEconomicTempRangeMW', '', 'Day', 'UnitDetail', 'None', 'Number');
	PUT_TRAIT(MM_PJM_UTIL.g_TG_DEF_LOW_ECON_TEMP, 'UnitDetail', 'LowEconomicTempRangeTemp', '', 'Day', 'UnitDetail', 'None', 'Number');
	PUT_TRAIT(MM_PJM_UTIL.g_TG_DEF_MID_ECON_MW, 'UnitDetail', 'MidEconomicTempRangeMW', '', 'Day', 'UnitDetail', 'None', 'Number');
	PUT_TRAIT(MM_PJM_UTIL.g_TG_DEF_MID_ECON_TEMP, 'UnitDetail', 'MidEconomicTempRangeTemp', '', 'Day', 'UnitDetail', 'None', 'Number');
	PUT_TRAIT(MM_PJM_UTIL.g_TG_DEF_HIGH_ECON_MW, 'UnitDetail', 'HighEconomicTempRangeMW', '', 'Day', 'UnitDetail', 'None', 'Number');
	PUT_TRAIT(MM_PJM_UTIL.g_TG_DEF_HIGH_ECON_TEMP, 'UnitDetail', 'HighEconomicTempRangeTemp', '', 'Day', 'UnitDetail', 'None', 'Number');
	PUT_TRAIT(MM_PJM_UTIL.g_TG_DEF_LOW_EMER_MW, 'UnitDetail', 'LowEmergencyTempRangeMW', '', 'Day', 'UnitDetail', 'None', 'Number');
	PUT_TRAIT(MM_PJM_UTIL.g_TG_DEF_LOW_EMER_TEMP, 'UnitDetail', 'LowEmergencyTempRangeTemp', '', 'Day', 'UnitDetail', 'None', 'Number');
	PUT_TRAIT(MM_PJM_UTIL.g_TG_DEF_MID_EMER_MW, 'UnitDetail', 'MidEmergencyTempRangeMW', '', 'Day', 'UnitDetail', 'None', 'Number');
	PUT_TRAIT(MM_PJM_UTIL.g_TG_DEF_MID_EMER_TEMP, 'UnitDetail', 'MidEmergencyTempRangeTemp', '', 'Day', 'UnitDetail', 'None', 'Number');
	PUT_TRAIT(MM_PJM_UTIL.g_TG_DEF_HIGH_EMER_MW, 'UnitDetail', 'HighEmergencyTempRangeMW', '', 'Day', 'UnitDetail', 'None', 'Number');
	PUT_TRAIT(MM_PJM_UTIL.g_TG_DEF_HIGH_EMER_TEMP, 'UnitDetail', 'HighEmergencyTempRangeTemp', '', 'Day', 'UnitDetail', 'None', 'Number');
	PUT_TRAIT(MM_PJM_UTIL.g_TG_DEF_CC_MIN_TIME_BETWEEN, 'UnitDetail', 'CCMinTimeBetweenStartups', 'CC Min Time', 'Day', 'UnitDetail', 'None', 'Number');
	PUT_TRAIT(MM_PJM_UTIL.g_TG_DEF_CC_ALLOW_SIMPLE_CYCLE, 'UnitDetail', 'CCAllowSimpleCycle', 'CC Allow Simple', 'Day', 'UnitDetail', 'None', 'String', 'true|false');
	PUT_TRAIT(MM_PJM_UTIL.g_TG_DEF_CC_FACTOR, 'UnitDetail', 'CCFactor', 'CC Factor', 'Day', 'UnitDetail', 'None', 'Number');
	PUT_TRAIT(MM_PJM_UTIL.g_TG_DEF_PS_PUMPING_FACTOR, 'UnitDetail', 'PSPumpingFactor', 'PS Pump Factor', 'Day', 'UnitDetail', 'None', 'Number');
	PUT_TRAIT(MM_PJM_UTIL.g_TG_DEF_PS_INITIAL_MWH, 'UnitDetail', 'PSInitialMWH', 'PS Initial MWH', 'Day', 'UnitDetail', 'None', 'Number');
	PUT_TRAIT(MM_PJM_UTIL.g_TG_DEF_PS_FINAL_MWH, 'UnitDetail', 'PSFinalMWH', 'PS Final MWH', 'Day', 'UnitDetail', 'None', 'Number');
	PUT_TRAIT(MM_PJM_UTIL.g_TG_DEF_PS_MAX_MWH, 'UnitDetail', 'PSMaxMWH', 'PS Max MWH', 'Day', 'UnitDetail', 'None', 'Number');
	PUT_TRAIT(MM_PJM_UTIL.g_TG_DEF_PS_MIN_MWH, 'UnitDetail', 'PSMinMWH', 'PS Min MWH', 'Day', 'UnitDetail', 'None', 'Number');
	PUT_TRAIT(MM_PJM_UTIL.g_TG_DEF_PS_MIN_GEN_MW, 'UnitDetail', 'PSMinGenMW', 'PS Min Gen', 'Day', 'UnitDetail', 'None', 'Number');
	PUT_TRAIT(MM_PJM_UTIL.g_TG_DEF_PS_MIN_PUMP_MW, 'UnitDetail', 'PSMinPumpMW', 'PS Min Pump', 'Day', 'UnitDetail', 'None', 'Number');
     --Parameter Limits
    PUT_TRAIT(MM_PJM_UTIL.g_TG_DEF_PARAM_LIMIT_DESC, 'UnitDetail', 'ParamLimitDesc', 'Param Limit Descr', 'Day', 'UnitDetail', 'Unit Data', 'String');
    PUT_TRAIT(MM_PJM_UTIL.g_TG_DEF_MAX_DAILY_START_LIMIT, 'UnitDetail', 'MaxDailyStartsLimit', 'Max Daily Starts Limit', 'Day', 'UnitDetail', 'Unit Data', 'Number');
    PUT_TRAIT(MM_PJM_UTIL.g_TG_DEF_MAX_WEEKLY_STRT_LIMIT, 'UnitDetail', 'MaxWeeklyStartsLimit', 'Max Weekly Starts Limit', 'Day', 'UnitDetail', 'Unit Data', 'Number');
    PUT_TRAIT(MM_PJM_UTIL.g_TG_DEF_MIN_RUNTIME_LIMIT, 'UnitDetail', 'MinRuntimeLimit', 'Min Runtime Limit', 'Day', 'UnitDetail', 'Unit Data', 'Number');
    PUT_TRAIT(MM_PJM_UTIL.g_TG_DEF_MIN_DOWNTIME_LIMIT, 'UnitDetail', 'MinDowntimeLimit', 'Min Downtime Limit', 'Day', 'UnitDetail', 'Unit Data', 'Number');
    PUT_TRAIT(MM_PJM_UTIL.g_TG_DEF_TURNDOWN_RATIO_LIMIT, 'UnitDetail', 'TurnDownRatioLimit', 'Turndown Ratio Limit', 'Day', 'UnitDetail', 'Unit Data', 'Number');
    

	--Series Unit Detail Traits.
	PUT_TRAIT(MM_PJM_UTIL.g_TG_DEF_ENERGY_RAMP_CURVE, 'UnitDetail', 'EnergyRampCurve', 'Energy Ramp', 'Day', 'UnitDetail', 'Unit Data', 'Number', NULL, NULL, 'MW',  MM_PJM_UTIL.g_TI_DEF_ENERGY_RAMP_MW);
	PUT_TRAIT(MM_PJM_UTIL.g_TG_DEF_ENERGY_RAMP_CURVE, 'UnitDetail', 'EnergyRampCurve', 'Energy Ramp', 'Day', 'UnitDetail', 'Unit Data', 'Number', NULL, NULL, 'Rate',  MM_PJM_UTIL.g_TI_DEF_ENERGY_RAMP_RATE);
	PUT_TRAIT(MM_PJM_UTIL.g_TG_DEF_SPIN_RAMP_CURVE, 'UnitDetail', 'SpinRampCurve', 'Spin Ramp', 'Day', 'UnitDetail', 'Unit Data', 'Number', NULL, NULL, 'MW',  MM_PJM_UTIL.g_TI_DEF_SPIN_RAMP_MW);
	PUT_TRAIT(MM_PJM_UTIL.g_TG_DEF_SPIN_RAMP_CURVE, 'UnitDetail', 'SpinRampCurve', 'Spin Ramp', 'Day', 'UnitDetail', 'Unit Data', 'Number', NULL, NULL, 'Rate',  MM_PJM_UTIL.g_TI_DEF_SPIN_RAMP_RATE);
	PUT_TRAIT(MM_PJM_UTIL.g_TG_DEF_DEFAULT_STARTUP_COST, 'UnitDetail', 'StartupCosts', 'Startup Costs', 'Day', 'UnitDetail', 'Unit Data', 'Number', NULL, NULL, 'Interval',  MM_PJM_UTIL.g_TI_DEF_DSC_INTERVAL);
    PUT_TRAIT(MM_PJM_UTIL.g_TG_DEF_DEFAULT_STARTUP_COST, 'UnitDetail', 'StartupCosts', 'Startup Costs', 'Day', 'UnitDetail', 'Unit Data', 'String', 'true|false', NULL, 'Use Cost Based',  MM_PJM_UTIL.g_TI_DEF_DSC_USESTARTUP);   
	PUT_TRAIT(MM_PJM_UTIL.g_TG_DEF_DEFAULT_STARTUP_COST, 'UnitDetail', 'StartupCosts', 'Startup Costs', 'Day', 'UnitDetail', 'Unit Data', 'Number', NULL, NULL, 'No Load',  MM_PJM_UTIL.g_TI_DEF_DSC_NOLOADCOST);
	PUT_TRAIT(MM_PJM_UTIL.g_TG_DEF_DEFAULT_STARTUP_COST, 'UnitDetail', 'StartupCosts', 'Startup Costs', 'Day', 'UnitDetail', 'Unit Data', 'Number', NULL, NULL, 'Cold Startup',  MM_PJM_UTIL.g_TI_DEF_DSC_COLDSTARTUPCOST);
	PUT_TRAIT(MM_PJM_UTIL.g_TG_DEF_DEFAULT_STARTUP_COST, 'UnitDetail', 'StartupCosts', 'Startup Costs', 'Day', 'UnitDetail', 'Unit Data', 'Number', NULL, NULL, 'Inter Startup',  MM_PJM_UTIL.g_TI_DEF_DSC_INTMDSARTUPCOST);
	PUT_TRAIT(MM_PJM_UTIL.g_TG_DEF_DEFAULT_STARTUP_COST, 'UnitDetail', 'StartupCosts', 'Startup Costs', 'Day', 'UnitDetail', 'Unit Data', 'Number', NULL, NULL, 'Hot Startup',  MM_PJM_UTIL.g_TI_DEF_DSC_HOTSTARTUPCOST);
	
	--Unit Update Traits
	v_DISPLAY_ORDER := 0;
	PUT_TRAIT(MM_PJM_UTIL.g_TG_UPD_EMER_MIN, 'Update', 'MinEmergencyLimit', 'Emer Min', 'Hour', 'Summary', 'Unit Data', 'Number');
	PUT_TRAIT(MM_PJM_UTIL.g_TG_UPD_ECON_MIN, 'Update', 'MinEconomicLimit', 'Econ Min', 'Hour', 'Summary', 'Unit Data', 'Number');
	PUT_TRAIT(MM_PJM_UTIL.g_TG_UPD_ECON_MAX, 'Update', 'MaxEconomicLimit', 'Econ Max', 'Hour', 'Summary', 'Unit Data', 'Number');
	PUT_TRAIT(MM_PJM_UTIL.g_TG_UPD_EMER_MAX, 'Update', 'MaxEmergencyLimit', 'Emer Max', 'Hour', 'Summary', 'Unit Data', 'Number');
	PUT_TRAIT(MM_PJM_UTIL.g_TG_UPD_COMMIT_STATUS, 'Update', 'CommitStatus', 'Run State', 'Hour', 'Summary', 'Unit Data', 'String', 'Economic|Unavailable|Emergency|MustRun');
	PUT_TRAIT(MM_PJM_UTIL.g_TG_UPD_FIXED_GEN, 'Update', 'FixedUnit Data', '', 'Hour', 'Detail', 'Unit Data', 'Number');
-- These next four default limits are just informational query results, and should just be ignored (MW).
 	PUT_TRAIT(MM_PJM_UTIL.g_TG_UPD_DEF_EMER_MIN, 'Update', 'DefMinEmergencyLimit', 'Def Emer Min', 'Hour', 'Detail', 'Unit Data', 'Number');
 	PUT_TRAIT(MM_PJM_UTIL.g_TG_UPD_DEF_ECON_MIN, 'Update', 'DefMinEconomicLimit', 'Def Econ Min', 'Hour', 'Detail', 'Unit Data', 'Number');
 	PUT_TRAIT(MM_PJM_UTIL.g_TG_UPD_DEF_ECON_MAX, 'Update', 'DefMaxEconomicLimit', 'Def Econ Max', 'Hour', 'Detail', 'Unit Data', 'Number');
 	PUT_TRAIT(MM_PJM_UTIL.g_TG_UPD_DEF_EMER_MAX, 'Update', 'DefMaxEmergencyLimit', 'Def Emer Max', 'Hour', 'Detail', 'Unit Data', 'Number'); 
	PUT_TRAIT(MM_PJM_UTIL.g_TG_UPD_NOTIF_TIME, 'Update', 'NotificationTime', 'Notif Time', 'Hour', 'Detail', 'Unit Data', 'Number');
	PUT_TRAIT(MM_PJM_UTIL.g_TG_UPD_PS_MIN_GEN_MW, 'Update', 'MinGenMW', 'Min Gen', 'Hour', 'Detail', 'Unit Data', 'Number');
	PUT_TRAIT(MM_PJM_UTIL.g_TG_UPD_PS_MIN_PUMP_MW, 'Update', 'MinPumpMW', 'Min Pump', 'Hour', 'Detail', 'Unit Data', 'Number');
    
	
	v_DISPLAY_ORDER := 0;
    PUT_TRAIT(MM_PJM_UTIL.g_TG_MR_ACTIVE_SCHEDULE, 'MarketResults', 'ActiveSchedule', '', 'Hour', 'Detail', 'Generation', 'Number');
    
	v_DISPLAY_ORDER := 0;
    PUT_TRAIT(MM_PJM_UTIL.g_TG_OUT_DA_STARTUP_CST_APPLY, 'Output', 'DAStartUpCostApplied', '', 'Hour', 'Detail', 'Generation', 'Number');
    PUT_TRAIT(MM_PJM_UTIL.g_TG_OUT_DA_NOLOAD_CST_APPLY, 'Output', 'DANoLoadCostApplied', '', 'Hour', 'Detail', 'Generation', 'Number');
    PUT_TRAIT(MM_PJM_UTIL.g_TG_OUT_RT_STARTUP_CST_APPLY, 'Output', 'RTStartUpCostApplied', '', 'Hour', 'Detail', 'Generation', 'Number');	
    PUT_TRAIT(MM_PJM_UTIL.g_TG_OUT_RT_NOLOAD_CST_APPLY, 'Output', 'RTNoLoadCostApplied', '', 'Hour', 'Detail', 'Generation', 'Number');
	PUT_TRAIT(MM_PJM_UTIL.g_TG_OUT_DESIRED_MWH, 'Output', 'DesiredMW', '', 'Hour', 'Detail', 'Generation', 'Number');
    PUT_TRAIT(MM_PJM_UTIL.g_TG_OUT_SCHEDULE_ID, 'Output', 'ActiveSchedule', '', 'Hour', 'Detail', 'Generation', 'String');
    PUT_TRAIT(MM_PJM_UTIL.g_TG_OUT_MWH_REDUCED, 'Output', 'MWH_Reduced', '', 'Hour', 'Detail', 'Generation', 'String');
    PUT_TRAIT(MM_PJM_UTIL.g_TG_OUT_FOLLOW_PJM_DISPATCH, 'Output', 'FollowingPJMDispatch', '', 'Hour', 'Detail', 'Generation', 'Number');
	PUT_TRAIT(MM_PJM_UTIL.g_TG_OUT_ACTUAL_GEN_MKT_RESULT, 'Output', 'ActualGenMktResult', '', 'Hour', 'None', 'Generation', 'Number');
	
	--Regulation Update/Offer Traits
	v_DISPLAY_ORDER := 0;
	PUT_TRAIT(MM_PJM_UTIL.g_TG_REG_UPD_MW, 'RegUpdate', 'MW', 'MW', 'Hour', 'Summary', 'Regulation', 'Number');
	PUT_TRAIT(MM_PJM_UTIL.g_TG_REG_UPD_MIN_MW, 'RegUpdate', 'MinMW', 'Min MW', 'Hour', 'Summary', 'Regulation', 'Number');
	PUT_TRAIT(MM_PJM_UTIL.g_TG_REG_UPD_MAX_MW, 'RegUpdate', 'MaxMW', 'Max MW', 'Hour', 'Summary', 'Regulation', 'Number');
	PUT_TRAIT(MM_PJM_UTIL.g_TG_REG_UPD_UNAVAILABLE, 'RegUpdate', 'Unavailable', 'Unavailable', 'Hour', 'Summary', 'Regulation', 'String', 'true|false');
	PUT_TRAIT(MM_PJM_UTIL.g_TG_REG_UPD_SELF_SCHEDULED, 'RegUpdate', 'SelfScheduled', 'Self Sched', 'Hour', 'Summary', 'Regulation', 'String', 'true|false');
	PUT_TRAIT(MM_PJM_UTIL.g_TG_REG_UPD_SPILLING, 'RegUpdate', 'Spilling', 'Spilling', 'Hour', 'Summary', 'Regulation', 'String', 'true|false');
	PUT_TRAIT(MM_PJM_UTIL.g_TG_REG_OFF_UNAVAILABLE, 'RegOffer', 'Unavailable', 'Unavailable', 'Day', 'Detail', 'Regulation', 'String', 'true|false');
	PUT_TRAIT(MM_PJM_UTIL.g_TG_REG_OFF_SELF_SCHEDULED, 'RegOffer', 'SelfScheduled', 'Self Sched', 'Day', 'Detail', 'Regulation', 'String', 'true|false');
	PUT_TRAIT(MM_PJM_UTIL.g_TG_REG_OFF_MINIMUM_MW, 'RegOffer', 'MinMW', 'Min MW', 'Day', 'Detail', 'Regulation', 'Number');

	--Spinning Reserve Update/Offer Traits
	v_DISPLAY_ORDER := 0;
	PUT_TRAIT(MM_PJM_UTIL.g_TG_SPIN_UPD_OFFER_MW, 'SpinUpdate', 'Offer MW', 'Offer MW', 'Hour', 'Summary', 'Spinning Reserve', 'Number');
	PUT_TRAIT(MM_PJM_UTIL.g_TG_SPIN_UPD_MAX_MW, 'SpinUpdate', 'SpinMax', 'Spin Max', 'Hour', 'Summary', 'Spinning Reserve', 'Number');
	PUT_TRAIT(MM_PJM_UTIL.g_TG_SPIN_UPD_UNAVAILABLE, 'SpinUpdate', 'Unavailable', 'Unavailable', 'Hour', 'Summary', 'Spinning Reserve', 'String', 'true|false');
	PUT_TRAIT(MM_PJM_UTIL.g_TG_SPIN_UPD_SELF_SCHEDULED, 'SpinUpdate', 'SelfScheduledMW', 'Self Sched MW', 'Hour', 'Summary', 'Spinning Reserve', 'Number');
	PUT_TRAIT(MM_PJM_UTIL.g_TG_SPIN_OFF_COND_AVAILABLE, 'SpinOffer', 'CondenseAvailable', 'Condense', 'Day', 'Detail', 'Spinning Reserve', 'String', 'true|false');
	PUT_TRAIT(MM_PJM_UTIL.g_TG_SPIN_OFF_COND_START_COST, 'SpinOffer', 'CondenseStartupCost', '', 'Day', 'Detail', 'Spinning Reserve', 'Number');
	PUT_TRAIT(MM_PJM_UTIL.g_TG_SPIN_OFF_COND_EN_USAGE, 'SpinOffer', 'CondenseEnergyUsage', '', 'Day', 'Detail', 'Spinning Reserve', 'Number');
	PUT_TRAIT(MM_PJM_UTIL.g_TG_SPIN_OFF_COND_TO_GEN_COST, 'SpinOffer', 'CondenseToGenCost', '', 'Day', 'Detail', 'Spinning Reserve', 'Number');
	PUT_TRAIT(MM_PJM_UTIL.g_TG_SPIN_OFF_SPIN_AS_COND, 'SpinOffer', 'SpinAsCondenser', '', 'Day', 'Detail', 'Spinning Reserve', 'String', 'true|false');
	PUT_TRAIT(MM_PJM_UTIL.g_TG_SPIN_OFF_FULL_LOAD_HR, 'SpinOffer', 'FullLoadHR', '', 'Day', 'Detail', 'Spinning Reserve', 'Number');
	PUT_TRAIT(MM_PJM_UTIL.g_TG_SPIN_OFF_REDUCED_LOAD_HR, 'SpinOffer', 'ReducedLoadHR', '', 'Day', 'Detail', 'Spinning Reserve', 'Number');
	PUT_TRAIT(MM_PJM_UTIL.g_TG_SPIN_OFF_VOM_RATE, 'SpinOffer', 'VOMRate', '', 'Day', 'Detail', 'Spinning Reserve', 'Number');
	
END;
/

