DECLARE
	PROCEDURE PUT_IT_COMMODITY(p_COMMODITY_NAME IN VARCHAR2,
							   p_COMMODITY_ALIAS IN VARCHAR2,
							   p_MARKET_TYPE IN VARCHAR2,
							   p_IS_VIRTUAL IN NUMBER := 0) IS
		o_oid NUMBER(9);
	BEGIN
		BEGIN
			o_OID := EI.GET_ID_FROM_ALIAS(p_COMMODITY_ALIAS, EC.ED_IT_COMMODITY);
			DBMS_OUTPUT.PUT_LINE('Commodity ' || p_COMMODITY_NAME || ' with alias ' || p_COMMODITY_ALIAS || ' already exists.');
		EXCEPTION WHEN MSGCODES.e_ERR_NO_SUCH_ENTRY OR NO_DATA_FOUND THEN
			io.put_it_commodity(o_oid                    => o_oid,
								p_commodity_name         => p_COMMODITY_NAME,
								p_commodity_alias        => p_COMMODITY_ALIAS,
								p_commodity_desc         => p_COMMODITY_NAME,
								p_commodity_id           => 0,
								p_commodity_type         => 'Energy',
								p_commodity_unit         => 'MWH',
								p_commodity_unit_format  => null,
								p_commodity_price_unit   => 'Dollars',
								p_commodity_price_format => null,
								p_is_virtual             => p_IS_VIRTUAL,
								p_market_type            => p_MARKET_TYPE);
		END;
	END PUT_IT_COMMODITY;
BEGIN
	PUT_IT_COMMODITY('DayAhead Energy', 'DA', 'DayAhead');
	PUT_IT_COMMODITY('RealTime Energy', 'RT', 'RealTime');
	PUT_IT_COMMODITY('Virtual Energy', 'VR', 'DayAhead', 1);
END;
/