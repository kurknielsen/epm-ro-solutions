DECLARE
	PROCEDURE PUT_ANC_SVC_COMMODITY(p_COMMODITY_NAME IN VARCHAR2) IS
		o_oid NUMBER(9);
	BEGIN
		io.put_it_commodity(o_oid                    => o_oid,
							p_commodity_name         => p_COMMODITY_NAME,
							p_commodity_alias        => p_COMMODITY_NAME,
							p_commodity_desc         => p_COMMODITY_NAME,
							p_commodity_id           => 0,
							p_commodity_type         => 'Energy',
							p_commodity_unit         => 'MWH',
							p_commodity_unit_format  => null,
							p_commodity_price_unit   => 'Dollars',
							p_commodity_price_format => null,
							p_is_virtual             => 0,
							p_market_type            => 'DayAhead');
	EXCEPTION WHEN OTHERS THEN 
        NULL;
	END PUT_ANC_SVC_COMMODITY;
BEGIN
	PUT_ANC_SVC_COMMODITY('Spinning Reserve');
	PUT_ANC_SVC_COMMODITY('Regulation');
	commit;
END;
/

