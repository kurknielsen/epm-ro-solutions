DECLARE
	v_ID NUMBER(9);
    c INTEGER;
BEGIN
    
    -- Check if exists
    SELECT COUNT(*)
    INTO c
    FROM IT_COMMODITY T
    WHERE   T.COMMODITY_NAME = 'Power';
    IF c = 0 THEN
	-- Power commodity
	io.put_it_commodity(o_oid                    => v_ID,
						p_commodity_name         => 'Power',
						p_commodity_alias        => 'Power',
						p_commodity_desc         => 'Power',
						p_commodity_id           => 0,
						p_commodity_type         => 'Energy',
						p_commodity_unit         => 'MWH',
						p_commodity_unit_format  => '?',
						p_commodity_price_unit   => '?',
						p_commodity_price_format => '?',
						p_is_virtual             => 0,
						p_market_type            => NULL);
	COMMIT;
    END IF;
END;
/