DECLARE
	v_SC_ID NUMBER(9);
begin
	BEGIN
		v_SC_ID := EI.GET_ID_FROM_NAME('PJM', EC.ED_SC);
	EXCEPTION
		WHEN MSGCODES.e_ERR_NO_SUCH_ENTRY OR NO_DATA_FOUND THEN
			io.put_sc(o_oid                         => v_SC_ID,
					  p_sc_name                     => 'PJM',
					  p_sc_alias                    => 'PJM',
					  p_sc_desc                     => 'PJM',
					  p_sc_id                       => 0,
					  p_sc_nerc_code                => NULL,
					  p_sc_duns_number              => NULL,
					  p_sc_status                   => 'Active',
					  p_sc_external_identifier      => NULL,
					  p_sc_schedule_name_prefix     => 'PJM',
					  p_sc_schedule_format          => 'Service Point',
					  p_sc_schedule_interval        => 'Hour',
					  p_sc_load_rounding_preference => 'None',
					  p_sc_loss_rounding_preference => 'None',
					  p_sc_create_tx_loss_schedule  => 0,
					  p_sc_create_dx_loss_schedule  => 0,
					  p_sc_create_ufe_schedule      => 0,
					  p_sc_market_price_id          => 0,
					  p_sc_minimum_schedule_amt     => 0);
	END;
	EI.PUT_EXTERNAL_SYSTEM_IDENTIFIER(EC.ES_PJM, EC.ED_SC, V_SC_ID, 'PJM');

	COMMIT;
end;
/