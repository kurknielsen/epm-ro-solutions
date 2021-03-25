update system_object
set object_is_hidden = 0
where parent_object_id = 0
	and object_category = 'Layout'
	and object_is_hidden = 1
	and object_name in
		-- Retail Ops specific layouts should be shown (will be hidden from MarketManager\Common scripts)
		('DATA_MANAGEMENT','FORECASTING','PROFILING','SETTLEMENT','WRF');
