set define off

set serveroutput on

DECLARE
	v_BEGIN_DATE	DATE := DATE '2005-01-01';

	v_ESBN_SC_ID	NUMBER(9);
	v_NIE_SC_ID		NUMBER(9);
	v_SEM_SC_ID		NUMBER(9);
	
	v_ENERGY_COMMODITY_ID	NUMBER(9);
	v_RET_LOAD_COMMODITY_ID	NUMBER(9);
	
	v_LOAD_CALC_REALM_ID	NUMBER(9);
	v_NPG_CALC_REALM_ID		NUMBER(9);
	v_RESULT_CALC_REALM_ID	NUMBER(9);
	
	v_SU_SYS_REALM_ID		NUMBER(9);
	v_LOAD_SYS_REALM_ID		NUMBER(9);
	v_NPG_SYS_REALM_ID		NUMBER(9);
	
	v_COMPONENT_ID		NUMBER(9);
	v_CALC_PROC_ID		NUMBER(9);

	v_SCHED_TABLE_ID	NUMBER(9);

	v_LOAD_REACTOR_PROC_ID	NUMBER(9);
	v_NPG_REACTOR_PROC_ID	NUMBER(9);
		
BEGIN
	SAVEPOINT SCRIPT_START;

	--------------------------------------
	-- Look-up some entity IDs
	--------------------------------------

	-- Get SC IDs
	v_ESBN_SC_ID := MM_TDIE_UTIL.g_ESBN_SC_ID;
	v_NIE_SC_ID := MM_TDIE_UTIL.g_NIE_SC_ID;
	v_SEM_SC_ID := MM_SEM_UTIL.SEM_SC_ID;
	
	-- Now look-up commodity IDs
	v_ENERGY_COMMODITY_ID := EI.GET_ID_FROM_ALIAS('Energy', EC.ED_IT_COMMODITY);
	v_RET_LOAD_COMMODITY_ID := EI.GET_ID_FROM_ALIAS('Retail Load', EC.ED_IT_COMMODITY);
	

	--================================================================================================
	-- Create Calculation Realms
	--================================================================================================

	--------------------------------------
	-- This realm represents all TDIE accepted load schedules for a given SEM SU.
	-- The SEM SU is a service point ID indicated by the identifier ${:pod}
	--------------------------------------
	v_load_calc_realm_id := EI.GET_ID_FROM_ALIAS('TDIE Load Schedules for SU', EC.ED_CALC_REALM, 1);
	if v_load_calc_realm_id is null then
		v_load_calc_realm_id := 0; -- indicates to create new
	else
		-- clean-up child tables - re-created below
		delete system_realm_column where realm_id = v_load_calc_realm_id;
	end if;
	
	IO.PUT_SYSTEM_REALM(
		v_load_calc_realm_id, --o_oid
		'TDIE Load Schedules for SU', --p_realm_name
		'TDIE Load Schedules for SU', --p_realm_alias
		'TDIE Load Schedules for SU', --p_realm_desc
		v_load_calc_realm_id, --p_realm_id
		ec.ED_TRANSACTION, --p_entity_domain_id
		2, --p_realm_calc_type
		null --p_custom_query	
		);
	
	insert into system_realm_column (realm_id, entity_column, is_excluding_vals, column_vals, entry_date)
		values (v_load_calc_realm_id, 'SC_ID', 0, ''''||v_esbn_sc_id||''','''||v_nie_sc_id||'''', sysdate);
	insert into system_realm_column (realm_id, entity_column, is_excluding_vals, column_vals, entry_date)
		values (v_load_calc_realm_id, 'POD_ID', 0, '${:pod}', sysdate);
	insert into system_realm_column (realm_id, entity_column, is_excluding_vals, column_vals, entry_date)
		values (v_load_calc_realm_id, 'TRANSACTION_TYPE', 0, '''Load''', sysdate);
	insert into system_realm_column (realm_id, entity_column, is_excluding_vals, column_vals, entry_date)
		values (v_load_calc_realm_id, 'COMMODITY_ID', 0, ''''||v_ret_load_commodity_id||'''', sysdate);
		
	--------------------------------------
	-- This realm represents all TDIE non-participant generation schedules for a given SEM SU.
	-- The SEM SU is a service point ID indicated by the identifier ${:pod}
	--------------------------------------
	v_npg_calc_realm_id := EI.GET_ID_FROM_ALIAS('TDIE Non-Pt.Gen.Schedules for SU', EC.ED_CALC_REALM, 1);
	if v_npg_calc_realm_id is null then	
		v_npg_calc_realm_id := 0; -- indicates to create new
	else
		-- clean-up child tables - re-created below
		delete system_realm_column where realm_id = v_npg_calc_realm_id;
	end if;

	IO.PUT_SYSTEM_REALM(
		v_npg_calc_realm_id, --o_oid
		'TDIE Non-Pt.Gen.Schedules for SU', --p_realm_name
		'TDIE Non-Pt.Gen.Schedules for SU', --p_realm_alias
		'TDIE Non-Participant Generation Schedules for SU', --p_realm_desc
		v_npg_calc_realm_id, --p_realm_id
		ec.ED_TRANSACTION, --p_entity_domain_id
		2, --p_realm_calc_type
		'WHERE tbl.pod_id in (select gu.gen_sp_id from tdie_gen_units gu where gu.su_sp_id = ${:pod} AND TRUNC(:process_date - (1/86400)) BETWEEN gu.BEGIN_DATE AND nvl(gu.END_DATE,HIGH_DATE))' --p_custom_query	
		);

	insert into system_realm_column (realm_id, entity_column, is_excluding_vals, column_vals, entry_date)
		values (v_npg_calc_realm_id, 'SC_ID', 0, ''''||v_esbn_sc_id||''','''||v_nie_sc_id||'''', sysdate);
	insert into system_realm_column (realm_id, entity_column, is_excluding_vals, column_vals, entry_date)
		values (v_npg_calc_realm_id, 'TRANSACTION_TYPE', 0, '''Load''', sysdate);
	insert into system_realm_column (realm_id, entity_column, is_excluding_vals, column_vals, entry_date)
		values (v_npg_calc_realm_id, 'COMMODITY_ID', 0, ''''||v_RET_LOAD_COMMODITY_ID||'''', sysdate);
		
	--------------------------------------
	-- This realm represents the single SEM Net Demand schedule for a given SU.
	-- The SEM SU is a service point ID indicated by the identifier ${:pod}
	--------------------------------------
	v_result_calc_realm_id := EI.GET_ID_FROM_ALIAS('TDIE Net Demand for SU', EC.ED_CALC_REALM, 1);
	if v_result_calc_realm_id is null then	
		v_result_calc_realm_id := 0; -- indicates to create new
	else
		-- clean-up child tables - re-created below
		delete system_realm_column where realm_id = v_result_calc_realm_id;
	end if;

	IO.PUT_SYSTEM_REALM(
		v_result_calc_realm_id, --o_oid
		'TDIE Net Demand for SU', --p_realm_name
		'TDIE Net Demand for SU', --p_realm_alias
		'TDIE Net Demand for SU', --p_realm_desc
		v_result_calc_realm_id, --p_realm_id
		ec.ED_TRANSACTION, --p_entity_domain_id
		2, --p_realm_calc_type
		null --p_custom_query	
		);

	insert into system_realm_column (realm_id, entity_column, is_excluding_vals, column_vals, entry_date)
		values (v_result_calc_realm_id, 'SC_ID', 0, ''''||v_sem_sc_id||'''', sysdate);
	insert into system_realm_column (realm_id, entity_column, is_excluding_vals, column_vals, entry_date)
		values (v_result_calc_realm_id, 'POD_ID', 0, '${:pod}', sysdate);
	insert into system_realm_column (realm_id, entity_column, is_excluding_vals, column_vals, entry_date)
		values (v_result_calc_realm_id, 'TRANSACTION_TYPE', 0, '''Net Demand''', sysdate);
	insert into system_realm_column (realm_id, entity_column, is_excluding_vals, column_vals, entry_date)
		values (v_result_calc_realm_id, 'COMMODITY_ID', 0, ''''||v_energy_commodity_id||'''', sysdate);


	--================================================================================================
	-- Create System Realms
	--================================================================================================

	--------------------------------------
	-- This realm represents all service points that are (or at one point were) SEM SU delivery points.
	--------------------------------------
	v_su_sys_realm_id := EI.GET_ID_FROM_ALIAS('SEM SU Service Points', EC.ED_SYSTEM_REALM, 1);
	if v_su_sys_realm_id is null then	
		v_su_sys_realm_id := 0; -- indicates to create new
	else
		-- clean-up child tables - re-created below
		delete system_realm_column where realm_id = v_su_sys_realm_id;
	end if;
	
	IO.PUT_SYSTEM_REALM(
		v_su_sys_realm_id, --o_oid
		'SEM SU Service Points', --p_realm_name
		'SEM SU Service Points', --p_realm_alias
		'SEM SU Service Points', --p_realm_desc
		v_su_sys_realm_id, --p_realm_id
		ec.ED_SERVICE_POINT, --p_entity_domain_id
		0, --p_realm_calc_type
		'WHERE EXISTS (SELECT 1 FROM SEM_MP_UNITS SMU WHERE SMU.RESOURCE_TYPE = ''SU'' AND SMU.POD_ID = TBL.SERVICE_POINT_ID)' --p_custom_query	
		);
	
	sd.POPULATE_ENTITIES_FOR_REALM(p_REALM_ID => v_su_sys_realm_id);

	--------------------------------------
	-- This realm represents all TDIE load schedules.
	--------------------------------------
	v_load_sys_realm_id := EI.GET_ID_FROM_ALIAS('TDIE Load Schedules', EC.ED_SYSTEM_REALM, 1);
	if v_load_sys_realm_id is null then	
		v_load_sys_realm_id := 0; -- indicates to create new
	else
		-- clean-up child tables - re-created below
		delete system_realm_column where realm_id = v_load_sys_realm_id;
	end if;

	IO.PUT_SYSTEM_REALM(
		v_load_sys_realm_id, --o_oid
		'TDIE Load Schedules', --p_realm_name
		'TDIE Load Schedules', --p_realm_alias
		'TDIE Load Schedules', --p_realm_desc
		v_load_sys_realm_id, --p_realm_id
		ec.ED_TRANSACTION, --p_entity_domain_id
		0, --p_realm_calc_type
		'WHERE EXISTS (SELECT 1 FROM SEM_MP_UNITS SMU WHERE SMU.RESOURCE_TYPE = ''SU'' AND SMU.POD_ID = TBL.POD_ID)' --p_custom_query	
		);

	insert into system_realm_column (realm_id, entity_column, is_excluding_vals, column_vals, entry_date)
		values (v_load_sys_realm_id, 'SC_ID', 0, ''''||v_esbn_sc_id||''','''||v_nie_sc_id||'''', sysdate);
	insert into system_realm_column (realm_id, entity_column, is_excluding_vals, column_vals, entry_date)
		values (v_load_sys_realm_id, 'TRANSACTION_TYPE', 0, '''Load''', sysdate);
	insert into system_realm_column (realm_id, entity_column, is_excluding_vals, column_vals, entry_date)
		values (v_load_sys_realm_id, 'COMMODITY_ID', 0, ''''||v_ret_load_commodity_id||'''', sysdate);

	sd.POPULATE_ENTITIES_FOR_REALM(p_REALM_ID => v_load_sys_realm_id);

	--------------------------------------
	-- This realm represents all TDIE non-participant generation schedules.
	--------------------------------------
	v_npg_sys_realm_id := EI.GET_ID_FROM_ALIAS('TDIE Non-Part.Gen.Schedules', EC.ED_SYSTEM_REALM, 1);
	if v_npg_sys_realm_id is null then	
		v_npg_sys_realm_id := 0; -- indicates to create new
	else
		-- clean-up child tables - re-created below
		delete system_realm_column where realm_id = v_npg_sys_realm_id;
	end if;
	
	IO.PUT_SYSTEM_REALM(
		v_npg_sys_realm_id, --o_oid
		'TDIE Non-Part.Gen.Schedules', --p_realm_name
		'TDIE Non-Part.Gen.Schedules', --p_realm_alias
		'TDIE Non-Participant Generation Schedules', --p_realm_desc
		v_npg_sys_realm_id, --p_realm_id
		ec.ED_TRANSACTION, --p_entity_domain_id
		0, --p_realm_calc_type
		'WHERE EXISTS (SELECT 1 FROM TDIE_GEN_UNITS TGU WHERE TGU.GEN_SP_ID = TBL.POD_ID)' --p_custom_query	
		);

	insert into system_realm_column (realm_id, entity_column, is_excluding_vals, column_vals, entry_date)
		values (v_npg_sys_realm_id, 'SC_ID', 0, ''''||v_esbn_sc_id||''','''||v_nie_sc_id||'''', sysdate);
	insert into system_realm_column (realm_id, entity_column, is_excluding_vals, column_vals, entry_date)
		values (v_npg_sys_realm_id, 'TRANSACTION_TYPE', 0, '''Load''', sysdate);
	insert into system_realm_column (realm_id, entity_column, is_excluding_vals, column_vals, entry_date)
		values (v_npg_sys_realm_id, 'COMMODITY_ID', 0, ''''||v_RET_LOAD_COMMODITY_ID||'''', sysdate);

	sd.POPULATE_ENTITIES_FOR_REALM(p_REALM_ID => v_npg_sys_realm_id);


	--================================================================================================
	-- Create Calculation Component
	--================================================================================================

	--------------------------------------
	-- This component calculates the Net Demand for a SEM SU (supplier unit).
	--------------------------------------
	v_COMPONENT_ID := EI.GET_ID_FROM_ALIAS('Aggregate TDIE to SEM SU', EC.ED_CALC_COMPONENT, 1);
	if v_COMPONENT_ID is null then
		v_COMPONENT_ID := 0; -- indicates to create new
	else
		-- clean-up child tables - re-created below
		delete component_formula_iterator where component_id = v_COMPONENT_ID;
		delete component_formula_input where component_id = v_COMPONENT_ID;
		delete component_formula_variable where component_id = v_COMPONENT_ID;
		delete component_formula_result where component_id = v_COMPONENT_ID;
	end if;
	
	IO.PUT_COMPONENT(
		v_COMPONENT_ID, --o_oid, 
		'Aggregate TDIE to SEM SU', --p_component_name, 
		'Aggregate TDIE to SEM SU', --p_component_alias, 
		'Aggregate TDIE to SEM SU', --p_component_desc, 
		v_COMPONENT_ID, --p_component_id, 
		'Calc.Process', --p_component_entity, 
		null, --p_charge_type, 
		null, --p_rate_structure, 
		'30 Minute', --p_rate_interval, 
		0, --p_is_rebill, 
		0, --p_is_taxed, 
		0, --p_is_custom_charge, 
		0, --p_is_credit_charge, 
		0, --p_is_include_tx_loss, 
		0, --p_is_include_dx_loss, 
		0, --p_template_id, 
		0, --p_market_price_id, 
		0, --p_service_point_id, 
		0, --p_model_id, 
		0, --p_event_id, 
		null, --p_component_reference, 
		0, --p_invoice_group_id, 
		0, --p_invoice_group_order, 
		0, --p_computation_order, 
		null, --p_quantity_unit, 
		null, --p_currency_unit, 
		null, --p_quantity_type, 
		null, --p_external_identifier, 
		'IE T&D', --p_component_category, 
		null, --p_gl_debit_account, 
		null, --p_gl_credit_account, 
		null, --p_firm_non_firm, 
		0, --p_exclude_from_invoice, 
		0, --p_exclude_from_invoice_total, 
		null, --p_imbalance_type, 
		0, --p_accumulation_period, 
		0, --p_base_component_id, 
		0, --p_base_limit_id, 
		null, --p_market_type, 
		null, --p_market_price_type, 
		'First', --p_which_interval, 
		null, --p_lmp_price_calc, 
		0, --p_lmp_include_ext, 
		null, --p_lmp_include_sales, 
		null, --p_charge_when, 
		0, --p_bilaterals_sign, 
		0, --p_lmp_commodity_id, 
		0, --p_lmp_base_commodity_id, 
		0, --p_use_zonal_price, 
		null, --p_alternate_price, 
		null, --p_alternate_price_function, 
		0, --p_exclude_from_billing_export
		0, -- p_IS_DEFAULT_TEMPLATE,
		NULL, -- p_ANCILLARY_SERVICE_ID,
		NULL, -- p_KWH_MULTIPLER
		NULL, -- p_APPLY_RATE_FOR
		NULL -- p_LOSS_ADJ_TYPE
		);

	-- This iterator returns no rows if the given point is not a SEM SU on the given day.
	insert into component_formula_iterator(component_id, sub_component_type, sub_component_id, iterator_name, begin_date, end_date, 
											iterator_query, is_multicolumn, ident_columns, is_inner_loop, comments, row_number, entry_date)
		values (v_component_id, '?', 0, '?', v_begin_date, null,  
'SELECT STRING_COLLECTION(1 /* dummy value */)
FROM
(SELECT DISTINCT 1
 FROM SEM_MP_UNITS
 WHERE POD_ID = ${:pod}
	AND RESOURCE_TYPE = ''SU''
	AND TRUNC(:process_begin_date) BETWEEN
		EFFECTIVE_DATE AND NVL(EXPIRATION_DATE, HIGH_DATE)
)',
			1, 0, 0, 'Do nothing if specified service point''s resource type is not SU for the specified day', 1, sysdate);
			
	-- This input looks for the negative (342) accepted backcast interval schedule amounts for this SEM SU.
	insert into component_formula_input(component_id, sub_component_type, sub_component_id, input_name, begin_date, end_date, 
									function, where_clause, entity_domain_id, entity_type, entity_id, what_field, comments, row_number, 
									view_order, persist_value, entry_date)
		values (v_component_id, '?', 0, 'Interval Export Val', v_begin_date, null,
				'Sum', ', SCHEDULE_GROUP SG WHERE SG.SCHEDULE_GROUP_ID = TBL.SCHEDULE_GROUP_ID AND SG.METER_TYPE = ''Interval''', 
				ec.ED_TRANSACTION, 'R', v_NPG_CALC_REALM_ID, 'AMOUNT', null, 0,
				1, 1, sysdate);
				
	-- This input looks for the positive (341) accepted backcast interval schedule amounts for this SEM SU.
	insert into component_formula_input(component_id, sub_component_type, sub_component_id, input_name, begin_date, end_date, 
								function, where_clause, entity_domain_id, entity_type, entity_id, what_field, comments, row_number, 
								view_order, persist_value, entry_date)
	values (v_component_id, '?', 0, 'Interval Import Val', v_begin_date, null,
			'Sum', ', SCHEDULE_GROUP SG WHERE SG.SCHEDULE_GROUP_ID = TBL.SCHEDULE_GROUP_ID AND SG.METER_TYPE = ''Interval''', 
			ec.ED_TRANSACTION, 'R', v_load_calc_realm_id, 'AMOUNT', null, 0,
			1, 1, sysdate);

	-- This input looks for the accepted backcast period schedule amounts (from 300 messages) for this SEM SU	
	insert into component_formula_input(component_id, sub_component_type, sub_component_id, input_name, begin_date, end_date, 
								function, where_clause, entity_domain_id, entity_type, entity_id, what_field, comments, row_number, 
								view_order, persist_value, entry_date)
	values (v_component_id, '?', 0, 'Period Meter Val', v_begin_date, null,
			'Sum', ', SCHEDULE_GROUP SG WHERE SG.SCHEDULE_GROUP_ID = TBL.SCHEDULE_GROUP_ID AND SG.METER_TYPE = ''Period''', 
			ec.ED_TRANSACTION, 'R', v_load_calc_realm_id, 'AMOUNT', null, 0,
			1, 1, sysdate);
	
	-- Calculate the net demand as net retail load minus net non-participant generation.
	insert into component_formula_variable(component_id, sub_component_type, sub_component_id, variable_name, begin_date, end_date, 
										formula, is_multicolumn, is_plsql, comments, row_number, view_order, persist_value, entry_date)
		values (v_component_id, '?', 0, 'Net Demand', v_begin_date, null,
				'${Period Meter Val} + ${Interval Import Val} + ${Interval Export Val} ', 0, 0, null, 2, 3, 1, sysdate);

	-- This step creates a "target" SEM SU net demand transaction if one is not already present.
	insert into component_formula_variable(component_id, sub_component_type, sub_component_id, variable_name, begin_date, end_date, 
										formula, is_multicolumn, is_plsql, comments, row_number, view_order, persist_value, entry_date)
	values (v_component_id, '?', 0, 'Create Transaction', v_begin_date, null,'? := MM_TDIE_UTIL.GET_SEM_NET_DEMAND_TRANSACTION(
		EI.GET_ENTITY_IDENTIFIER_EXTSYS(EC.ED_SERVICE_POINT, ${:pod}, EC.ES_SEM)
		);',0, 1, null, 3, null, 0, sysdate);

	-- Store the net demand into the appropriate schedule.
	insert into component_formula_result(component_id, sub_component_type, sub_component_id, entity_domain_id, entity_type, entity_id, begin_date, end_date, 
										what_field, formula, comments, entry_date)
		values (v_component_id, '?', 0, ec.ED_TRANSACTION, 'R', v_result_calc_realm_id, v_begin_date, null,
				'AMOUNT', '-(${Net Demand})', 'Negative sign because SEM settlement expects net demand to be negative', sysdate);
				

	--================================================================================================
	-- Create Calculation Process
	--================================================================================================

	--------------------------------------
	-- Create the calculation process
	--------------------------------------
	v_calc_proc_id := EI.GET_ID_FROM_ALIAS('Aggregate TDIE to SEM SU', EC.ED_CALC_PROCESS, 1);
	if v_calc_proc_id is null then
		v_calc_proc_id := 0; -- indicates to create new
	else
		-- clean-up child tables - re-created below
		delete calculation_process_global where calc_process_id = v_calc_proc_id;
		delete calculation_process_step where calc_process_id = v_calc_proc_id;
	end if;

	EM.PUT_CALC_PROCESS(
		v_calc_proc_id, --o_oid
		'Aggregate TDIE to SEM SU',--p_calc_process_name
		'Aggregate TDIE to SEM SU',--p_calc_process_alias
		'Aggregate TDIE to SEM SU',--p_calc_process_desc
		v_calc_proc_id, --p_calc_process_id
		'IE T&D',--p_calc_process_category
		MM_SEM_UTIL.g_TZ, --p_time_zone
		'30 Minute',--p_process_interval
		'First of Month',--p_week_begin
		ec.ED_SERVICE_POINT, --p_context_domain_id
		v_su_sys_realm_id,--p_context_entities_id
		':pod',--p_context_name
		1--p_is_statement_type_specific
		);		

	-- This step will stop the calculations if we are running for an invalid statement type.
	insert into calculation_process_global(calc_process_id, global_name, formula, comments, row_number, persist_value, entry_date)
		values (v_calc_proc_id, 'Check Statement Type',
'case when mm_sem_util.is_sem_shadow_statement_type(:statement_type) = 0 then
	die(''This calculation process can only be run for SEM shadow settlement statement types; Statement type: ''||
			text_util.to_char_entity(:statement_type, -740)||'' is not valid.'')
else 0
end',
			'Verify that we only run for proper SEM statement types', 0, 0, sysdate);

	-- The one and only component for this process.
	em.PUT_CALC_PROCESS_STEP(
		v_calc_proc_id,--p_calc_process_id
		1,--p_step_number
		v_begin_date,--p_begin_date
		null,--p_end_date
		v_component_id,--p_component_id
		null,--p_old_step_number
		null--p_old_begin_date
		);

	--================================================================================================
	-- Create Reactor Procedures
	--================================================================================================

	-- Look up IT_SCHEDULE table ID
	select table_id
	into v_sched_table_id
	from system_table
	where db_table_name = 'IT_SCHEDULE';
	
	--------------------------------------
	-- This reactor procedure "reacts" to changes to TDIE retail load schedules. It runs the calculation
	-- process for affected intervals when input load schedule data is changed.
	--------------------------------------
	v_load_reactor_proc_id := EI.GET_ID_FROM_ALIAS('TDIE to SEM SU: Load Schedules', EC.ED_REACTOR_PROCEDURE, 1);
	if v_load_reactor_proc_id is null then
		v_load_reactor_proc_id := 0; -- indicates to create new
	else
		-- clean-up child tables - re-created below
		delete reactor_procedure_input where reactor_procedure_id = v_load_reactor_proc_id;
		delete reactor_procedure_entity_ref where reactor_procedure_id = v_load_reactor_proc_id;
		delete reactor_procedure_parameter where reactor_procedure_id = v_load_reactor_proc_id;
	end if;

	io.PUT_REACTOR_PROCEDURE(
		v_load_reactor_proc_id,--o_oid
		'Calc:Aggregate TDIE to SEM SU: Load Schedules',--p_reactor_procedure_name
		'TDIE to SEM SU: Load Schedules',--p_reactor_procedure_alias
		'Recalculate SEM Net Demand when input load schedule changes',--p_reactor_procedure_desc
		v_load_reactor_proc_id,--p_reactor_procedure_id
		v_sched_table_id,--p_table_id
		'CALC_ENGINE.CALC_REQUEST',--p_procedure_name
		1,--p_job_thread_id
		null,--p_job_comments
		10,--p_call_order
		'MM_SEM_UTIL.IS_SEM_SHADOW_STATEMENT_TYPE(SCHEDULE_TYPE) = 0',--p_skip_when_formula
		'EDT',--p_time_zone
		0,--p_is_immediate
		1--p_is_enabled
		);
		
	insert into reactor_procedure_input(reactor_procedure_id, entity_domain_id, entity_type, entity_id, begin_date, end_date)
		values (v_load_reactor_proc_id, ec.ED_TRANSACTION, 'R', v_load_sys_realm_id, v_begin_date, null);
	insert into reactor_procedure_entity_ref(reactor_procedure_id, reference_name, entity_domain_id, entity_id, entry_date)
		values (v_load_reactor_proc_id, 'CalcProcessId', ec.ED_CALC_PROCESS, v_calc_proc_id, sysdate);
	insert into reactor_procedure_parameter(reactor_procedure_id, parameter_name, parameter_type, parameter_formula, parameter_order)
		values (v_load_reactor_proc_id, 'P_CALC_PROCESS_ID', 'Key', 'CalcProcessId', 1);
	insert into reactor_procedure_parameter(reactor_procedure_id, parameter_name, parameter_type, parameter_formula, parameter_order)
		values (v_load_reactor_proc_id, 'P_ENTITY_IDS', 'Key', 'NUMBER_COLLECTION(ITJ.GET_POD_ID(TRANSACTION_ID))', 2);
	insert into reactor_procedure_parameter(reactor_procedure_id, parameter_name, parameter_type, parameter_formula, parameter_order)
		values (v_load_reactor_proc_id, 'P_STATEMENT_TYPE_ID', 'Key', 'SCHEDULE_TYPE', 3);
	insert into reactor_procedure_parameter(reactor_procedure_id, parameter_name, parameter_type, parameter_formula, parameter_order)
		values (v_load_reactor_proc_id, 'P_CUT_BEGIN_DATE_TIME', 'Begin Date', 'DATE_UTIL.GET_PROCESS_BEGIN_DATE(DATE_UTIL.GET_INTERVAL_FOR_TRANSACTION(TRANSACTION_ID),''30 Minute'',SCHEDULE_DATE,''EDT'',TRUE,''First of Month'')', 4);
	insert into reactor_procedure_parameter(reactor_procedure_id, parameter_name, parameter_type, parameter_formula, parameter_order)
		values (v_load_reactor_proc_id, 'P_CUT_END_DATE_TIME', 'End Date', 'DATE_UTIL.GET_PROCESS_END_DATE(DATE_UTIL.GET_INTERVAL_FOR_TRANSACTION(TRANSACTION_ID),''30 Minute'',SCHEDULE_DATE,''EDT'',TRUE,''First of Month'')', 5);
	insert into reactor_procedure_parameter(reactor_procedure_id, parameter_name, parameter_type, parameter_formula, parameter_order)
		values (v_load_reactor_proc_id, 'P_AS_OF_DATE', 'Non-Key', 'SYSDATE', 6);

	--------------------------------------
	-- This reactor procedure "reacts" to changes to TDIE non-participant generation schedules. It runs the calculation
	-- process for affected intervals when input load schedule data is changed.
	--------------------------------------
	v_npg_reactor_proc_id := EI.GET_ID_FROM_ALIAS('TDIE to SEM SU: NPG Schedules', EC.ED_REACTOR_PROCEDURE, 1);
	if v_npg_reactor_proc_id is null then
		v_npg_reactor_proc_id := 0; -- indicates to create new
	else
		-- clean-up child tables - re-created below
		delete reactor_procedure_input where reactor_procedure_id = v_npg_reactor_proc_id;
		delete reactor_procedure_entity_ref where reactor_procedure_id = v_npg_reactor_proc_id;
		delete reactor_procedure_parameter where reactor_procedure_id = v_npg_reactor_proc_id;
	end if;

	io.PUT_REACTOR_PROCEDURE(
		v_npg_reactor_proc_id,--o_oid
		'Calc:Aggregate TDIE to SEM SU: NPG Schedules',--p_reactor_procedure_name
		'TDIE to SEM SU: NPG Schedules',--p_reactor_procedure_alias
		'Recalculate SEM Net Demand when input non-participant generation schedule changes',--p_reactor_procedure_desc
		v_npg_reactor_proc_id,--p_reactor_procedure_id
		v_sched_table_id,--p_table_id
		'CALC_ENGINE.CALC_REQUEST',--p_procedure_name
		1,--p_job_thread_id
		null,--p_job_comments
		11,--p_call_order
'MM_TDIE_UTIL.GET_SUPPLY_UNIT_FOR_GENERATOR(
	       ITJ.GET_POD_ID(TRANSACTION_ID), SCHEDULE_DATE)
	IS NULL
AND
MM_SEM_UTIL.IS_SEM_SHADOW_STATEMENT_TYPE(SCHEDULE_TYPE) = 0',--p_skip_when_formula
		'EDT',--p_time_zone
		0,--p_is_immediate
		1--p_is_enabled
		);
		
	insert into reactor_procedure_input(reactor_procedure_id, entity_domain_id, entity_type, entity_id, begin_date, end_date)
		values (v_npg_reactor_proc_id, ec.ED_TRANSACTION, 'R', v_npg_sys_realm_id, v_begin_date, null);
	insert into reactor_procedure_entity_ref(reactor_procedure_id, reference_name, entity_domain_id, entity_id, entry_date)
		values (v_npg_reactor_proc_id, 'CalcProcessId', ec.ED_CALC_PROCESS, v_calc_proc_id, sysdate);
	insert into reactor_procedure_parameter(reactor_procedure_id, parameter_name, parameter_type, parameter_formula, parameter_order)
		values (v_npg_reactor_proc_id, 'P_CALC_PROCESS_ID', 'Key', 'CalcProcessId', 1);
	insert into reactor_procedure_parameter(reactor_procedure_id, parameter_name, parameter_type, parameter_formula, parameter_order)
		values (v_npg_reactor_proc_id, 'P_ENTITY_IDS', 'Key',
'NUMBER_COLLECTION(
	MM_TDIE_UTIL.GET_SUPPLY_UNIT_FOR_GENERATOR(
	       ITJ.GET_POD_ID(TRANSACTION_ID), SCHEDULE_DATE)
	)',
			2);
	insert into reactor_procedure_parameter(reactor_procedure_id, parameter_name, parameter_type, parameter_formula, parameter_order)
		values (v_npg_reactor_proc_id, 'P_STATEMENT_TYPE_ID', 'Key', 'SCHEDULE_TYPE', 3);
	insert into reactor_procedure_parameter(reactor_procedure_id, parameter_name, parameter_type, parameter_formula, parameter_order)
		values (v_npg_reactor_proc_id, 'P_CUT_BEGIN_DATE_TIME', 'Begin Date', 'DATE_UTIL.GET_PROCESS_BEGIN_DATE(DATE_UTIL.GET_INTERVAL_FOR_TRANSACTION(TRANSACTION_ID),''30 Minute'',SCHEDULE_DATE,''EDT'',TRUE,''First of Month'')', 4);
	insert into reactor_procedure_parameter(reactor_procedure_id, parameter_name, parameter_type, parameter_formula, parameter_order)
		values (v_npg_reactor_proc_id, 'P_CUT_END_DATE_TIME', 'End Date', 'DATE_UTIL.GET_PROCESS_END_DATE(DATE_UTIL.GET_INTERVAL_FOR_TRANSACTION(TRANSACTION_ID),''30 Minute'',SCHEDULE_DATE,''EDT'',TRUE,''First of Month'')', 5);
	insert into reactor_procedure_parameter(reactor_procedure_id, parameter_name, parameter_type, parameter_formula, parameter_order)
		values (v_npg_reactor_proc_id, 'P_AS_OF_DATE', 'Non-Key', 'SYSDATE', 6);


	--================================================================================================
	-- Done!

	commit;
	
EXCEPTION
	WHEN OTHERS THEN
		DBMS_OUTPUT.PUT_LINE(UT.GET_FULL_ERRM);
		ROLLBACK to SCRIPT_START;
		RAISE;
END;
/

