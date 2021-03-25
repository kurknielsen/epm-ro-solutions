SET DEFINE OFF	
	--Ignore &'s in data; otherwise it will assume word after & is a substitution variable and prompt for a value	
	-- Uncomment the following line if you wish to completely eliminate previous entries and start from scratch w/ delivered entries
	--DELETE SYSTEM_LABEL; 
DECLARE
	PROCEDURE INSERT_SYSTEM_LABEL
		(
		p_MODEL_ID IN NUMBER,
		p_MODULE IN VARCHAR,
		p_KEY1 IN VARCHAR,
		p_KEY2 IN VARCHAR,
		p_KEY3 IN VARCHAR,
		p_POSITION IN NUMBER,
		p_VALUE IN VARCHAR,
		p_CODE IN VARCHAR,
		p_IS_DEFAULT IN NUMBER,
		p_IS_HIDDEN IN NUMBER
		) AS
	v_POSITION NUMBER;
	v_COUNT NUMBER;
	BEGIN
	    SELECT COUNT(VALUE)
	    INTO v_COUNT
	    FROM SYSTEM_LABEL
	    WHERE MODEL_ID = p_MODEL_ID
		AND MODULE = p_MODULE
		AND KEY1 = p_KEY1
		AND KEY2 = p_KEY2
		AND KEY3 = p_KEY3
		AND VALUE = p_VALUE;

	    -- already have that value in table, so we can safely skip it
	    IF v_COUNT > 0 THEN RETURN; END IF;

	    -- determine proper position that won't collide w/ existing entry
	    SELECT NVL(MAX(POSITION),-1)+1
	    INTO v_POSITION
	    FROM SYSTEM_LABEL
	    WHERE MODEL_ID = p_MODEL_ID
		AND MODULE = p_MODULE
		AND KEY1 = p_KEY1
		AND KEY2 = p_KEY2
		AND KEY3 = p_KEY3;

	    INSERT INTO SYSTEM_LABEL ( MODEL_ID, MODULE, KEY1, KEY2, KEY3, POSITION, VALUE, CODE, IS_DEFAULT, IS_HIDDEN ) VALUES (p_MODEL_ID, p_MODULE, p_KEY1, p_KEY2, p_KEY3, v_POSITION, p_VALUE, p_CODE, p_IS_DEFAULT, p_IS_HIDDEN);
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN	NULL;
			WHEN OTHERS THEN	RAISE;
	END INSERT_SYSTEM_LABEL;
BEGIN

	INSERT_SYSTEM_LABEL(0, 'Export', 'Type', '?', '?', 0, 'Forecast', NULL,  1, NULL);
	INSERT_SYSTEM_LABEL(0, 'Export', 'Type', '?', '?', 1, 'Backcast', NULL,  NULL, NULL); 
	INSERT_SYSTEM_LABEL(0, 'Export', 'Type', '?', '?', 2, 'Usage', NULL,  NULL, NULL); 
	INSERT_SYSTEM_LABEL(0, 'Export', 'Format', 'Forecast', '?', 0, 'PPL', NULL,  0, NULL); 
	INSERT_SYSTEM_LABEL(0, 'Export', 'Format', 'Forecast', '?', 1, 'PECO', NULL,  1, NULL); 
	INSERT_SYSTEM_LABEL(0, 'Export', 'Format', 'Forecast', '?', 4, 'PJM eCapacity', NULL,  NULL, NULL);  
	INSERT_SYSTEM_LABEL(0, 'Export', 'Format', 'Forecast', '?', 5, 'PJM eCapacity-XML', NULL,  NULL, NULL);  
	INSERT_SYSTEM_LABEL(0, 'Export', 'Delimiter', 'PECO', '?', 0, 'TAB', NULL,  1, 0); 
	INSERT_SYSTEM_LABEL(0, 'Export', 'Delimiter', 'PPL', '?', 0, 'TILDE', NULL,  1, 0); 
	INSERT_SYSTEM_LABEL(0, 'Export', 'Delimiter', 'PJM eCapacity', '?', 0, 'TAB', NULL,  NULL, NULL);
	INSERT_SYSTEM_LABEL(0, 'Export', 'Delimiter', 'PJM eCapacity-XML', '?', 0, 'TAB', NULL,  NULL, NULL);
	INSERT_SYSTEM_LABEL(0, 'Export', 'Interval', '?', '?', 0, 'Hour', NULL,  1, NULL);
	INSERT_SYSTEM_LABEL(0, 'Export', 'Interval', '?', '?', 1, 'Day', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(0, 'Export', 'Interval', '?', '?', 2, 'Week', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(0, 'Export', 'Interval', '?', '?', 3, 'Month', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(0, 'Export', 'Interval', '?', '?', 4, 'Quarter', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(0, 'Export', 'Interval', '?', '?', 5, 'Year', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(0, 'Export', 'System', 'Unit', 'FROM_SYSTEM_DICTIONARY', 0, 'Summary Energy', NULL,  1, NULL); 
	INSERT_SYSTEM_LABEL(0, 'Export', 'System', 'Unit', 'FROM_SYSTEM_DICTIONARY', 1, 'Detail Energy', NULL,  0, NULL); 
	INSERT_SYSTEM_LABEL(0, 'Quote', 'Position', 'Results', 'Selection', 0, 'Load and Supply', NULL,  1, NULL);
	INSERT_SYSTEM_LABEL(0, 'Quote', 'Position', 'Results', 'Selection', 1, 'Financial', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(0, 'Quote', 'Position', 'Results', 'Selection', 2, 'Spot', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(0, 'Quote', 'Position', 'Results', 'Selection', 3, 'Mark to Market', NULL,  0, 1);
	INSERT_SYSTEM_LABEL(0, 'Quote', 'Position', 'Results', 'Selection', 4, 'Risk', NULL,  0, 1);
	INSERT_SYSTEM_LABEL(0, 'Quote', 'Pricing', 'Results', 'Selection', 0, 'Revenue and Cost', NULL,  1, NULL);
	INSERT_SYSTEM_LABEL(0, 'Quote', 'Pricing', 'Results', 'Selection', 1, 'Per Unit Revenue and Cost', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(0, 'Quote', 'Pricing', 'Results', 'Selection', 2, 'Seasonal Per Unit Rates', NULL,  0, NULL);
	--Market Type (Real-Time vs. Day-Ahead)
	INSERT_SYSTEM_LABEL(0, 'Product', 'Component', 'Combo List', 'Market Type', 0, 'Real-Time', NULL,  1, NULL);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Component', 'Combo List', 'Market Type', 1, 'Day-Ahead', NULL,  0, NULL);
	--Market Price Type
	INSERT_SYSTEM_LABEL(0, 'Product', 'Component', 'Combo List', 'Market Price Type', 0, 'Locational Marginal Price', NULL,  1, NULL);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Component', 'Combo List', 'Market Price Type', 1, 'Marginal Congestion Component', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Component', 'Combo List', 'Market Price Type', 2, 'Marginal Loss Component', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Component', 'Combo List', 'Market Price Type', 3, 'Standard Offer Supply', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Component', 'Combo List', 'Market Price Type', 4, 'Defaulted Supply', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Component', 'Combo List', 'Market Price Type', 5, 'Over Supply', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Component', 'Combo List', 'Market Price Type', 6, 'Under Supply', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Component', 'Combo List', 'Market Price Type', 7, 'Backup Generation', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Component', 'Combo List', 'Market Price Type', 8, 'Composite', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Component', 'Combo List', 'Market Price Type', 9, 'Composite-OSF', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Component', 'Combo List', 'Market Price Type', 10, 'User Defined', NULL,  0, NULL);
	--Products and Rates Component Quantity
	INSERT_SYSTEM_LABEL(0, 'Product', 'Component', 'Combo List', 'Quantity Unit', 0, ' ', NULL,  1, NULL);
	INSERT_SYSTEM_LABEL(1, 'Product', 'Component', 'Combo List', 'Quantity Unit', 1, 'Kwh', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(1, 'Product', 'Component', 'Combo List', 'Quantity Unit', 2, 'Mwh', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(1, 'Product', 'Component', 'Combo List', 'Quantity Unit', 3, 'Kw', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(1, 'Product', 'Component', 'Combo List', 'Quantity Unit', 4, 'Mw', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(2, 'Product', 'Component', 'Combo List', 'Quantity Unit', 5, 'Dth', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(2, 'Product', 'Component', 'Combo List', 'Quantity Unit', 6, 'Therm', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(2, 'Product', 'Component', 'Combo List', 'Quantity Unit', 7, 'Mcf', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(2, 'Product', 'Component', 'Combo List', 'Quantity Unit', 8, 'Ccf', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(2, 'Product', 'Component', 'Combo List', 'Quantity Unit', 9, 'Ton', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(2, 'Product', 'Component', 'Combo List', 'Quantity Unit', 10, 'GJ', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(2, 'Product', 'Component', 'Combo List', 'Quantity Unit', 11, 'm3', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(1, 'Product', 'Component', 'Combo List', 'Quantity Unit', 12, 'Kva', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(1, 'Product', 'Component', 'Combo List', 'Quantity Unit', 13, 'Kvar', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(1, 'Product', 'Component', 'Combo List', 'Quantity Unit', 14, 'Kvarh', NULL,  0, NULL);

	--Products and Rates Component Currency
	INSERT_SYSTEM_LABEL(0, 'Product', 'Component', 'Combo List', 'Currency', 0, 'USD', NULL,  1, NULL);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Component', 'Combo List', 'Currency', 1, 'CD', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Component', 'Combo List', 'Currency', 2, 'EUR', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Component', 'Combo List', 'Currency', 3, 'GBP', NULL,  0, NULL);

	-- Products and Rates - 'Canned Where Clause' drop-down for Billing Formula Components
	INSERT_SYSTEM_LABEL(0, 'Product', 'Component', 'Combo List', 'Canned Where Clauses', 0, 'where tbl.contract_id = :contract', NULL,  0, NULL);
	--Billing - Dispute Status (for color-coding)
	INSERT_SYSTEM_LABEL(0, 'Billing', 'Status', 'Values', '?', 0, 'Pending', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(0, 'Billing', 'Status', 'Values', '?', 1, 'Submitted', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(0, 'Billing', 'Status', 'Values', '?', 2, 'Resolved', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(0, 'Billing', 'Status', 'Values', '?', 3, 'Rejected', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(0, 'Billing', 'Status', 'Values', '?', 4, 'Cancelled', NULL,  0, NULL);
	--Scheduling, Bids and Offers - Status (for color-coding)
	INSERT_SYSTEM_LABEL(1, 'Scheduling', 'Bids And Offers', 'Status', 'Colors', 0, 'Pending', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(1, 'Scheduling', 'Bids And Offers', 'Status', 'Colors', 1, 'Submitted', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(1, 'Scheduling', 'Bids And Offers', 'Status', 'Colors', 2, 'Accepted', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(1, 'Scheduling', 'Bids And Offers', 'Status', 'Colors', 3, 'Rejected', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(1, 'Scheduling', 'Bids And Offers', 'Status', 'Colors', 4, 'Changed', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(1, 'Scheduling', 'Bids And Offers', 'Status', 'Colors', 5, 'Cancelled', NULL,  0, NULL);
	--Scheduling Transaction Types
	INSERT_SYSTEM_LABEL(1, 'Scheduling', 'TransactionDialog', 'Combo Lists', 'Transaction Type', 0, 'Load', '1 ', 0, 0); 
	INSERT_SYSTEM_LABEL(1, 'Scheduling', 'TransactionDialog', 'Combo Lists', 'Transaction Type', 1, 'Generation', '10', 0, 0); 
	INSERT_SYSTEM_LABEL(1, 'Scheduling', 'TransactionDialog', 'Combo Lists', 'Transaction Type', 2, 'Purchase', '2 ', 1, 0); 
	INSERT_SYSTEM_LABEL(1, 'Scheduling', 'TransactionDialog', 'Combo Lists', 'Transaction Type', 3, 'Sale', '3 ', 0, 0); 
	INSERT_SYSTEM_LABEL(1, 'Scheduling', 'TransactionDialog', 'Combo Lists', 'Transaction Type', 4, 'Pass-Thru', '11', 0, 0); 
	INSERT_SYSTEM_LABEL(1, 'Scheduling', 'TransactionDialog', 'Combo Lists', 'Transaction Type', 5, 'Injection', '4 ', 0, 0); 
	INSERT_SYSTEM_LABEL(1, 'Scheduling', 'TransactionDialog', 'Combo Lists', 'Transaction Type', 6, 'Withdrawal', '5 ', 0, 0); 
	INSERT_SYSTEM_LABEL(1, 'Scheduling', 'TransactionDialog', 'Combo Lists', 'Transaction Type', 7, 'Exchange', '6 ', 0, 0); 
	INSERT_SYSTEM_LABEL(1, 'Scheduling', 'TransactionDialog', 'Combo Lists', 'Transaction Type', 8, 'Adjustment', '7 ', 0, 0); 
	INSERT_SYSTEM_LABEL(1, 'Scheduling', 'TransactionDialog', 'Combo Lists', 'Transaction Type', 9, 'Delivery', '8 ', 0, 0); 
	INSERT_SYSTEM_LABEL(1, 'Scheduling', 'TransactionDialog', 'Combo Lists', 'Transaction Type', 10, 'Dictated', '9 ', 0, 0); 
	INSERT_SYSTEM_LABEL(1, 'Scheduling', 'TransactionDialog', 'Combo Lists', 'Transaction Type', 11, 'Env.Signal', '11 ', 0, 0);
	INSERT_SYSTEM_LABEL(1, 'Scheduling', 'TransactionDialog', 'Combo Lists', 'Transaction Type', 12, 'Zonal Emission Rate', '12 ', 0, 0);

	--Fields available for customizing transaction tree
	INSERT_SYSTEM_LABEL(1, 'Scheduling', 'Scheduler Tree', 'Hierarchy Fields', '?', 0, 'Schedule Coordinator', '0', 0, NULL);
	INSERT_SYSTEM_LABEL(1, 'Scheduling', 'Scheduler Tree', 'Hierarchy Fields', '?', 1, 'Transaction Type', '1', 0, NULL);
	INSERT_SYSTEM_LABEL(1, 'Scheduling', 'Scheduler Tree', 'Hierarchy Fields', '?', 2, '    Transaction Category', '2', 0, NULL);
	INSERT_SYSTEM_LABEL(1, 'Scheduling', 'Scheduler Tree', 'Hierarchy Fields', '?', 3, 'Commodity', '3', 0, NULL);
	INSERT_SYSTEM_LABEL(1, 'Scheduling', 'Scheduler Tree', 'Hierarchy Fields', '?', 4, '    Commodity Type', '4', 0, NULL);
	INSERT_SYSTEM_LABEL(1, 'Scheduling', 'Scheduler Tree', 'Hierarchy Fields', '?', 5, 'Point of Delivery', '5', 0, NULL);
	INSERT_SYSTEM_LABEL(1, 'Scheduling', 'Scheduler Tree', 'Hierarchy Fields', '?', 6, '    POD Type', '6', 0, NULL);
	INSERT_SYSTEM_LABEL(1, 'Scheduling', 'Scheduler Tree', 'Hierarchy Fields', '?', 7, 'Point of Receipt', '7', 0, NULL);
	INSERT_SYSTEM_LABEL(1, 'Scheduling', 'Scheduler Tree', 'Hierarchy Fields', '?', 8, '    POR Type', '8', 0, NULL);
	INSERT_SYSTEM_LABEL(1, 'Scheduling', 'Scheduler Tree', 'Hierarchy Fields', '?', 9, 'Zone of Delivery', '9', 0, NULL);
	INSERT_SYSTEM_LABEL(1, 'Scheduling', 'Scheduler Tree', 'Hierarchy Fields', '?', 10, 'Zone of Receipt', 'A', 0, NULL);
	INSERT_SYSTEM_LABEL(1, 'Scheduling', 'Scheduler Tree', 'Hierarchy Fields', '?', 11, 'Source', 'B', 0, NULL);
	INSERT_SYSTEM_LABEL(1, 'Scheduling', 'Scheduler Tree', 'Hierarchy Fields', '?', 12, 'Sink', 'C', 0, NULL);
	INSERT_SYSTEM_LABEL(1, 'Scheduling', 'Scheduler Tree', 'Hierarchy Fields', '?', 13, 'Schedule Group', 'D', 0, NULL);
	INSERT_SYSTEM_LABEL(1, 'Scheduling', 'Scheduler Tree', 'Hierarchy Fields', '?', 14, 'Resource', 'E', 0, NULL);
	INSERT_SYSTEM_LABEL(1, 'Scheduling', 'Scheduler Tree', 'Hierarchy Fields', '?', 15, '    Resource Group', 'F', 0, NULL);
	INSERT_SYSTEM_LABEL(1, 'Scheduling', 'Scheduler Tree', 'Hierarchy Fields', '?', 16, 'Contract', 'G', 0, NULL);
	INSERT_SYSTEM_LABEL(1, 'Scheduling', 'Scheduler Tree', 'Hierarchy Fields', '?', 17, '    Billing-Entity', 'H', 0, NULL);
	INSERT_SYSTEM_LABEL(1, 'Scheduling', 'Scheduler Tree', 'Hierarchy Fields', '?', 18, '    TP Contract Name', 'I', 0, NULL);
	INSERT_SYSTEM_LABEL(1, 'Scheduling', 'Scheduler Tree', 'Hierarchy Fields', '?', 19, '    TP Contract Number', 'J', 0, NULL);
	INSERT_SYSTEM_LABEL(1, 'Scheduling', 'Scheduler Tree', 'Hierarchy Fields', '?', 20, 'Purchaser', 'K', 0, NULL);
	INSERT_SYSTEM_LABEL(1, 'Scheduling', 'Scheduler Tree', 'Hierarchy Fields', '?', 21, 'Seller', 'L', 0, NULL);
	INSERT_SYSTEM_LABEL(1, 'Scheduling', 'Scheduler Tree', 'Hierarchy Fields', '?', 22, 'Scheduler', 'M', 0, NULL);
	INSERT_SYSTEM_LABEL(1, 'Scheduling', 'Scheduler Tree', 'Hierarchy Fields', '?', 23, 'Agreement Type', 'N', 0, NULL);
	INSERT_SYSTEM_LABEL(1, 'Scheduling', 'Scheduler Tree', 'Hierarchy Fields', '?', 24, 'Approval Type', 'O', 0, NULL);
	INSERT_SYSTEM_LABEL(1, 'Scheduling', 'Scheduler Tree', 'Hierarchy Fields', '?', 25, 'External Identifier', 'P', 0, NULL);
	INSERT_SYSTEM_LABEL(1, 'Scheduling', 'Scheduler Tree', 'Hierarchy Fields', '?', 26, 'Is Firm', 'Q', 0, NULL);
	INSERT_SYSTEM_LABEL(1, 'Scheduling', 'Scheduler Tree', 'Hierarchy Fields', '?', 27, 'Is Import/Export', 'R', 0, NULL);
	INSERT_SYSTEM_LABEL(1, 'Scheduling', 'Scheduler Tree', 'Hierarchy Fields', '?', 28, 'Interval', 'S', 0, NULL);
	-- Drop-Down list for Financial Forecast Summary Types
	INSERT_SYSTEM_LABEL(0, 'Forecasting', 'Financial', 'Combo Lists', 'Summary Type', 0, 'EDC', NULL, 0, 0); 
	INSERT_SYSTEM_LABEL(0, 'Forecasting', 'Financial', 'Combo Lists', 'Summary Type', 1, 'ESP', NULL, 0, 0); 
	INSERT_SYSTEM_LABEL(0, 'Forecasting', 'Financial', 'Combo Lists', 'Summary Type', 2, 'Component', NULL, 0, 0); 
	INSERT_SYSTEM_LABEL(0, 'Forecasting', 'Financial', 'Combo Lists', 'Summary Type', 3, 'Invoice Group', NULL, 0, 0); 
	INSERT_SYSTEM_LABEL(0, 'Forecasting', 'Financial', 'Combo Lists', 'Summary Type', 4, 'Pool', NULL, 0, 0); 
	INSERT_SYSTEM_LABEL(0, 'Forecasting', 'Financial', 'Combo Lists', 'Summary Type', 5, 'Product', NULL, 0, 0); 
	INSERT_SYSTEM_LABEL(0, 'Forecasting', 'Financial', 'Combo Lists', 'Summary Type', 6, 'PSE', NULL, 0, 0);
	-- Drop-Down list for Scenario Comparison Items
	INSERT_SYSTEM_LABEL(0, 'Forecasting', 'ScenarioComparison', 'Combo Lists', 'ItemToCompare', 0, 'Load', NULL, 0, 0); 
	INSERT_SYSTEM_LABEL(0, 'Forecasting', 'ScenarioComparison', 'Combo Lists', 'ItemToCompare', 1, 'Revenue', NULL, 0, 0); 
	INSERT_SYSTEM_LABEL(0, 'Forecasting', 'ScenarioComparison', 'Combo Lists', 'ItemToCompare', 2, 'Cost', NULL, 0, 0); 
	INSERT_SYSTEM_LABEL(0, 'Forecasting', 'ScenarioComparison', 'Combo Lists', 'ItemToCompare', 3, 'Net Income', NULL, 0, 0); 
	-- Combo list for Profiling Usage Type
	INSERT_SYSTEM_LABEL(0, 'Profiling', 'Usage', 'Combo List', 'Usage Type', 0, 'Customer', NULL, 1, 0); 
	INSERT_SYSTEM_LABEL(0, 'Profiling', 'Usage', 'Combo List', 'Usage Type', 1, 'Account', NULL, 0, 0);  
	INSERT_SYSTEM_LABEL(0, 'Profiling', 'LoadResearch', 'Combo List', 'Rollup Interval', 0, 'Hour', 'HH', 1, 0); 
	INSERT_SYSTEM_LABEL(0, 'Profiling', 'LoadResearch', 'Combo List', 'Rollup Interval', 1, 'Day', 'DD', 0, 0);  
	--Billing - invoice status options
	INSERT_SYSTEM_LABEL(0, 'Billing', 'Invoice', 'Status', '?', 0, 'Invoiced', NULL, 1, 0); 
	INSERT_SYSTEM_LABEL(0, 'Billing', 'Invoice', 'Status', '?', 1, 'Invoiced - Sent', NULL, 0, 0); 
	INSERT_SYSTEM_LABEL(0, 'Billing', 'Invoice', 'Status', '?', 2, 'Voided', NULL, 0, 0); 
	INSERT_SYSTEM_LABEL(0, 'Billing', 'Invoice', 'Status', '?', 3, 'Voided - Sent', NULL, 0, 0); 
	INSERT_SYSTEM_LABEL(0, 'Billing', 'Invoice', 'Status', '?', 4, 'Closed', NULL, 0, 0);
	-- Profiling Reports Tab - Combo list placeholder for Report Names
	INSERT_SYSTEM_LABEL(0, 'Profiling', 'Reports', 'Report Name', '?', 0, 'Replace with rpt name and unhide', NULL, 0, 1); 
	-- Forecasting Reports Tab - Combo list placeholder for Report Names
	INSERT_SYSTEM_LABEL(0, 'Forecasting', 'Reports', 'Report Name', '?', 0, 'Replace with rpt name and unhide', NULL, 0, 1); 
	-- Settlement Reports Tab - Combo list placeholder for Report Names
	INSERT_SYSTEM_LABEL(0, 'Settlement', 'Reports', 'Report Name', '?', 0, 'Replace with rpt name and unhide', NULL, 0, 1);
	-- Quote Reports Tab - Combo list placeholder for Report Names
	INSERT_SYSTEM_LABEL(0, 'Quote', 'Reports', 'Report Name', '?', 0, 'Replace with rpt name and unhide', NULL, 0, 1); 
	--Fields available for customizing market prices tree
	INSERT_SYSTEM_LABEL(0, 'Product', 'Market Prices', 'Market Price Tree', 'Hierarchy Fields', 0, 'Energy Distribution Company', '0', 0, NULL);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Market Prices', 'Market Price Tree', 'Hierarchy Fields', 1, 'Schedule Coordinator', '1', 0, NULL);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Market Prices', 'Market Price Tree', 'Hierarchy Fields', 2, 'Market Price Type', '2', 0, NULL);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Market Prices', 'Market Price Tree', 'Hierarchy Fields', 3, 'Market Type', '3', 0, NULL);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Market Prices', 'Market Price Tree', 'Hierarchy Fields', 4, 'Service Point Type', '4', 0, NULL);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Market Prices', 'Market Price Tree', 'Hierarchy Fields', 5, 'Service Point', '5', 0, NULL);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Market Prices', 'Market Price Tree', 'Hierarchy Fields', 6, '    Service Zone', '6', 0, NULL);
	--List of Geography Types
	INSERT_SYSTEM_LABEL(0, 'Product', 'Geography', 'Geography Types', '?', 0, 'Country', NULL, 0, NULL);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Geography', 'Geography Types', '?', 1, 'State/Province', NULL, 0, NULL);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Geography', 'Geography Types', '?', 2, 'County', NULL, 0, NULL);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Geography', 'Geography Types', '?', 3, 'City', NULL, 0, NULL);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Geography', 'Geography Types', '?', 4, 'Postal Code', NULL, 0, NULL);

	--Products and Rates Component Entity Types
	INSERT_SYSTEM_LABEL(1, 'Product', 'Component', 'Combo List', 'Entity Type', 0, 'Account', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(1, 'Product', 'Component', 'Combo List', 'Entity Type', 1, 'PSE', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(2, 'Product', 'Component', 'Combo List', 'Entity Type', 2, 'Account', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(2, 'Product', 'Component', 'Combo List', 'Entity Type', 3, 'PSE', NULL,  0, NULL);

	--Products and Rates Component Rate Structures
	INSERT_SYSTEM_LABEL(0, 'Product', 'Component Rate Structure', 'Account', '?', 0, 'Block', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Component Rate Structure', 'Account', '?', 1, 'Combination', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Component Rate Structure', 'Account', '?', 2, 'Composite', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Component Rate Structure', 'Account', '?', 3, 'Flat', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Component Rate Structure', 'Account', '?', 4, 'Formula', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Component Rate Structure', 'Account', '?', 5, 'Imbalance', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Component Rate Structure', 'Account', '?', 6, 'Market', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Component Rate Structure', 'Account', '?', 7, 'Tiered', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Component Rate Structure', 'Account', '?', 8, 'Time of Use', NULL,  0, NULL);

	INSERT_SYSTEM_LABEL(0, 'Product', 'Component Rate Structure', 'PSE', '?', 0, 'Block', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Component Rate Structure', 'PSE', '?', 1, 'Coincident Peak Share', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Component Rate Structure', 'PSE', '?', 2, 'Combination', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Component Rate Structure', 'PSE', '?', 3, 'Conversion', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Component Rate Structure', 'PSE', '?', 4, 'Entity Attribute', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Component Rate Structure', 'PSE', '?', 5, 'External', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Component Rate Structure', 'PSE', '?', 6, 'Flat', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Component Rate Structure', 'PSE', '?', 7, 'Formula', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Component Rate Structure', 'PSE', '?', 8, 'Imbalance', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Component Rate Structure', 'PSE', '?', 9, 'Internal', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Component Rate Structure', 'PSE', '?', 10, 'LMP', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Component Rate Structure', 'PSE', '?', 11, 'Market', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Component Rate Structure', 'PSE', '?', 12, 'Tiered', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Component Rate Structure', 'PSE', '?', 13, 'Time of Use', NULL,  0, NULL);

	--Products and Rates Component Imbalance Types
	INSERT_SYSTEM_LABEL(0, 'Product', 'Component Imbalance Type', 'Account', '?', 0, 'Swing', NULL,  0, NULL);

	INSERT_SYSTEM_LABEL(0, 'Product', 'Component Imbalance Type', 'PSE', '?', 0, 'Accumulated', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Component Imbalance Type', 'PSE', '?', 1, 'Generation', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Component Imbalance Type', 'PSE', '?', 2, 'Net Retail', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Component Imbalance Type', 'PSE', '?', 3, 'Service Point', NULL,  0, NULL);

	--Products and Rates Component Charge Types
	INSERT_SYSTEM_LABEL(0, 'Product', 'Component Charge Type', 'PSE', 'Block', 0, 'Capacity', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Component Charge Type', 'PSE', 'Block', 1, 'Energy', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Component Charge Type', 'PSE', 'Block', 2, 'Gas', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Component Charge Type', 'PSE', 'Block', 3, 'Tax', NULL,  0, NULL);

	INSERT_SYSTEM_LABEL(0, 'Product', 'Component Charge Type', 'PSE', 'Conversion', 0, 'Conversion', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Component Charge Type', 'PSE', 'Conversion', 1, 'Peak Demand', NULL,  0, NULL);

	INSERT_SYSTEM_LABEL(0, 'Product', 'Component Charge Type', 'PSE', 'Flat', 0, 'Capacity', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Component Charge Type', 'PSE', 'Flat', 1, 'Energy', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Component Charge Type', 'PSE', 'Flat', 2, 'Gas', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Component Charge Type', 'PSE', 'Flat', 3, 'Peak Demand', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Component Charge Type', 'PSE', 'Flat', 4, 'Service', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Component Charge Type', 'PSE', 'Flat', 5, 'Tax', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Component Charge Type', 'PSE', 'Flat', 6, 'Transmission', NULL,  0, NULL);

	INSERT_SYSTEM_LABEL(0, 'Product', 'Component Charge Type', 'PSE', 'Internal', 0, 'Capacity', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Component Charge Type', 'PSE', 'Internal', 1, 'Energy', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Component Charge Type', 'PSE', 'Internal', 2, 'Gas', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Component Charge Type', 'PSE', 'Internal', 3, 'FTR Auction', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Component Charge Type', 'PSE', 'Internal', 4, 'Pipeline Commodity', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Component Charge Type', 'PSE', 'Internal', 5, 'Pipeline Fuel', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Component Charge Type', 'PSE', 'Internal', 6, 'Transmission', NULL,  0, NULL);

	INSERT_SYSTEM_LABEL(0, 'Product', 'Component Charge Type', 'PSE', 'LMP', 0, 'Bilaterals', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Component Charge Type', 'PSE', 'LMP', 1, 'Commodity', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Component Charge Type', 'PSE', 'LMP', 2, 'Energy', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Component Charge Type', 'PSE', 'LMP', 3, 'Exports/Imports', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Component Charge Type', 'PSE', 'LMP', 4, 'FTR Allocation', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Component Charge Type', 'PSE', 'LMP', 5, 'Virtual Energy', NULL,  0, NULL);

	INSERT_SYSTEM_LABEL(0, 'Product', 'Component Charge Type', 'PSE', 'Market', 0, 'Capacity', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Component Charge Type', 'PSE', 'Market', 1, 'Energy', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Component Charge Type', 'PSE', 'Market', 2, 'Gas', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Component Charge Type', 'PSE', 'Market', 3, 'Op Profit', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Component Charge Type', 'PSE', 'Market', 4, 'Tax', NULL,  0, NULL);

	INSERT_SYSTEM_LABEL(0, 'Product', 'Component Charge Type', 'PSE', 'Tiered', 0, 'Capacity', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Component Charge Type', 'PSE', 'Tiered', 1, 'Energy', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Component Charge Type', 'PSE', 'Tiered', 2, 'Gas', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Component Charge Type', 'PSE', 'Tiered', 3, 'Tax', NULL,  0, NULL);

	INSERT_SYSTEM_LABEL(0, 'Product', 'Component Charge Type', 'PSE', 'Time of Use', 0, 'Capacity', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Component Charge Type', 'PSE', 'Time of Use', 1, 'Energy', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Component Charge Type', 'PSE', 'Time of Use', 2, 'Gas', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Component Charge Type', 'PSE', 'Time of Use', 3, 'Transmission', NULL,  0, NULL);

	INSERT_SYSTEM_LABEL(0, 'Product', 'Component Charge Type', 'Account', 'Imbalance', 0, 'Commodity', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Component Charge Type', 'Account', 'Imbalance', 1, 'Consumption', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Component Charge Type', 'Account', 'Imbalance', 2, 'Distribution', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Component Charge Type', 'Account', 'Imbalance', 3, 'Energy', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Component Charge Type', 'Account', 'Imbalance', 4, 'Transmission', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Component Charge Type', 'Account', 'Imbalance', 5, 'Transportation', NULL,  0, NULL);

	INSERT_SYSTEM_LABEL(0, 'Product', 'Component Charge Type', 'Account', 'Flat', 0, 'Capacity', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Component Charge Type', 'Account', 'Flat', 1, 'Commodity', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Component Charge Type', 'Account', 'Flat', 2, 'Consumption', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Component Charge Type', 'Account', 'Flat', 3, 'Distribution', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Component Charge Type', 'Account', 'Flat', 4, 'Energy', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Component Charge Type', 'Account', 'Flat', 5, 'Excess Capacity Surcharge', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Component Charge Type', 'Account', 'Flat', 6, 'Manual Line Item', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Component Charge Type', 'Account', 'Flat', 7, 'Peak Demand', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(1, 'Product', 'Component Charge Type', 'Account', 'Flat', 8, 'Power Factor', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Component Charge Type', 'Account', 'Flat', 9, 'Service', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Component Charge Type', 'Account', 'Flat', 10, 'Tax', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Component Charge Type', 'Account', 'Flat', 11, 'Transmission', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Component Charge Type', 'Account', 'Flat', 12, 'Transportation', NULL,  0, NULL);
	
	INSERT_SYSTEM_LABEL(0, 'Product', 'Component Charge Type', 'Account', 'Block', 0, 'Capacity', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Component Charge Type', 'Account', 'Block', 1, 'Commodity', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Component Charge Type', 'Account', 'Block', 2, 'Consumption', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Component Charge Type', 'Account', 'Block', 3, 'Demand Hours', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Component Charge Type', 'Account', 'Block', 4, 'Distribution', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Component Charge Type', 'Account', 'Block', 5, 'Energy', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Component Charge Type', 'Account', 'Block', 6, 'Excess Capacity Surcharge', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Component Charge Type', 'Account', 'Block', 7, 'Peak Demand', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Component Charge Type', 'Account', 'Block', 8, 'Power Factor', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Component Charge Type', 'Account', 'Block', 9, 'Transmission', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Component Charge Type', 'Account', 'Block', 10, 'Transportation', NULL,  0, NULL);

	INSERT_SYSTEM_LABEL(0, 'Product', 'Component Charge Type', 'Account', 'Tiered', 0, 'Capacity', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Component Charge Type', 'Account', 'Tiered', 1, 'Commodity', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Component Charge Type', 'Account', 'Tiered', 2, 'Consumption', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Component Charge Type', 'Account', 'Tiered', 3, 'Demand Hours', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Component Charge Type', 'Account', 'Tiered', 4, 'Distribution', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Component Charge Type', 'Account', 'Tiered', 5, 'Energy', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Component Charge Type', 'Account', 'Tiered', 6, 'Excess Capacity Surcharge', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Component Charge Type', 'Account', 'Tiered', 7, 'Peak Demand', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Component Charge Type', 'Account', 'Tiered', 8, 'Power Factor', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Component Charge Type', 'Account', 'Tiered', 9, 'Transmission', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Component Charge Type', 'Account', 'Tiered', 10, 'Transportation', NULL,  0, NULL);

	INSERT_SYSTEM_LABEL(0, 'Product', 'Component Charge Type', 'Account', 'Composite', 0, 'Capacity', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Component Charge Type', 'Account', 'Composite', 1, 'Commodity', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Component Charge Type', 'Account', 'Composite', 2, 'Consumption', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Component Charge Type', 'Account', 'Composite', 3, 'Demand Hours', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Component Charge Type', 'Account', 'Composite', 4, 'Distribution', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Component Charge Type', 'Account', 'Composite', 5, 'Energy', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Component Charge Type', 'Account', 'Composite', 6, 'Excess Capacity Surcharge', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Component Charge Type', 'Account', 'Composite', 7, 'Peak Demand', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Component Charge Type', 'Account', 'Composite', 8, 'Power Factor', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Component Charge Type', 'Account', 'Composite', 9, 'Transmission', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Component Charge Type', 'Account', 'Composite', 10, 'Transportation', NULL,  0, NULL);

	INSERT_SYSTEM_LABEL(0, 'Product', 'Component Charge Type', 'Account', 'Market', 0, 'Capacity', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Component Charge Type', 'Account', 'Market', 1, 'Commodity', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Component Charge Type', 'Account', 'Market', 2, 'Consumption', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Component Charge Type', 'Account', 'Market', 3, 'Distribution', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Component Charge Type', 'Account', 'Market', 4, 'Energy', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Component Charge Type', 'Account', 'Market', 5, 'Excess Capacity Surcharge', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Component Charge Type', 'Account', 'Market', 6, 'Peak Demand', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Component Charge Type', 'Account', 'Market', 7, 'Power Factor', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Component Charge Type', 'Account', 'Market', 8, 'Transmission', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Component Charge Type', 'Account', 'Market', 9, 'Transportation', NULL,  0, NULL);

	INSERT_SYSTEM_LABEL(0, 'Product', 'Component Charge Type', 'Account', 'Time of Use', 0, 'Capacity', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Component Charge Type', 'Account', 'Time of Use', 1, 'Commodity', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Component Charge Type', 'Account', 'Time of Use', 2, 'Consumption', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Component Charge Type', 'Account', 'Time of Use', 3, 'Distribution', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Component Charge Type', 'Account', 'Time of Use', 4, 'Energy', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Component Charge Type', 'Account', 'Time of Use', 5, 'Excess Capacity Surcharge', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Component Charge Type', 'Account', 'Time of Use', 6, 'Peak Demand', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Component Charge Type', 'Account', 'Time of Use', 7, 'Power Factor', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Component Charge Type', 'Account', 'Time of Use', 8, 'Transmission', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Component Charge Type', 'Account', 'Time of Use', 9, 'Transportation', NULL,  0, NULL);

	--TOU Template Day Names
	INSERT_SYSTEM_LABEL(0, 'Entity Manager', 'TOU Template', 'Template Definition', 'Day Names', 0, 'Mon', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(0, 'Entity Manager', 'TOU Template', 'Template Definition', 'Day Names', 1, 'Tue', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(0, 'Entity Manager', 'TOU Template', 'Template Definition', 'Day Names', 2, 'Wed', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(0, 'Entity Manager', 'TOU Template', 'Template Definition', 'Day Names', 3, 'Thu', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(0, 'Entity Manager', 'TOU Template', 'Template Definition', 'Day Names', 4, 'Fri', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(0, 'Entity Manager', 'TOU Template', 'Template Definition', 'Day Names', 5, 'Sat', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(0, 'Entity Manager', 'TOU Template', 'Template Definition', 'Day Names', 6, 'Sun', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(0, 'Entity Manager', 'TOU Template', 'Template Definition', 'Day Names', 7, 'Hol', NULL,  0, NULL);
	--Service Point node types
	INSERT_SYSTEM_LABEL(0, 'Entity Manager', 'Service Point', 'Node Type', '?', 0, 'Point', NULL,  1, NULL);
	INSERT_SYSTEM_LABEL(0, 'Entity Manager', 'Service Point', 'Node Type', '?', 1, 'Aggregate', NULL,  1, NULL);
	INSERT_SYSTEM_LABEL(0, 'Entity Manager', 'Service Point', 'Node Type', '?', 2, 'Bus', NULL,  1, NULL);
	INSERT_SYSTEM_LABEL(0, 'Entity Manager', 'Service Point', 'Node Type', '?', 3, 'Generator', NULL,  1, NULL);
	INSERT_SYSTEM_LABEL(0, 'Entity Manager', 'Service Point', 'Node Type', '?', 4, 'Hub', NULL,  1, NULL);
	INSERT_SYSTEM_LABEL(0, 'Entity Manager', 'Service Point', 'Node Type', '?', 5, 'Interface', NULL,  1, NULL);
	INSERT_SYSTEM_LABEL(0, 'Entity Manager', 'Service Point', 'Node Type', '?', 6, 'Zone', NULL,  1, NULL);
	INSERT_SYSTEM_LABEL(0, 'Entity Manager', 'Service Point', 'Node Type', '?', 7, '500', NULL,  1, NULL);
	INSERT_SYSTEM_LABEL(0, 'Entity Manager', 'Service Point', 'Node Type', 'Pipeline', 0, 'Point', NULL,  1, NULL);
	INSERT_SYSTEM_LABEL(0, 'Entity Manager', 'Service Point', 'Node Type', 'Pipeline', 1, 'City Gate', NULL,  1, NULL);

	--System Action Defaults
        INSERT_SYSTEM_LABEL(0, 'Entity Manager', 'Configuration', 'System Action', 'Module', 0, 'Profiling', NULL,  0, NULL);
        INSERT_SYSTEM_LABEL(0, 'Entity Manager', 'Configuration', 'System Action', 'Module', 1, 'Forecasting', NULL,  0, NULL);
        INSERT_SYSTEM_LABEL(0, 'Entity Manager', 'Configuration', 'System Action', 'Module', 2, 'Scheduling', NULL,  0, NULL);
        INSERT_SYSTEM_LABEL(0, 'Entity Manager', 'Configuration', 'System Action', 'Module', 3, 'Settlement', NULL,  0, NULL);
        INSERT_SYSTEM_LABEL(0, 'Entity Manager', 'Configuration', 'System Action', 'Module', 4, 'Scheduling', NULL,  0, NULL);
        INSERT_SYSTEM_LABEL(0, 'Entity Manager', 'Configuration', 'System Action', 'Module', 5, 'Data Setup', NULL,  0, NULL);
        INSERT_SYSTEM_LABEL(0, 'Entity Manager', 'Configuration', 'System Action', 'Module', 6, 'Data Management', NULL,  0, NULL);
        INSERT_SYSTEM_LABEL(0, 'Entity Manager', 'Configuration', 'System Action', 'Module', 7, 'Quote Management', NULL,  0, NULL);
        INSERT_SYSTEM_LABEL(0, 'Entity Manager', 'Configuration', 'System Action', 'Module', 8, 'Billing', NULL,  0, NULL);
	
	INSERT_SYSTEM_LABEL(0, 'Entity Manager', 'Configuration', 'System Action', 'Action Type', 0, 'Select', NULL,  1, NULL);
	INSERT_SYSTEM_LABEL(0, 'Entity Manager', 'Configuration', 'System Action', 'Action Type', 1, 'Create', NULL,  1, NULL);
	INSERT_SYSTEM_LABEL(0, 'Entity Manager', 'Configuration', 'System Action', 'Action Type', 2, 'Update', NULL,  1, NULL);
	INSERT_SYSTEM_LABEL(0, 'Entity Manager', 'Configuration', 'System Action', 'Action Type', 3, 'Delete', NULL,  1, NULL);
	INSERT_SYSTEM_LABEL(0, 'Entity Manager', 'Configuration', 'System Action', 'Action Type', 4, 'Admin', NULL,  1, NULL);

	-- Phone Number types for Contacts
        INSERT_SYSTEM_LABEL(0, 'Entity Manager', 'Contact', 'Phone Types', '?', 0, 'Work', NULL,  0, NULL);
        INSERT_SYSTEM_LABEL(0, 'Entity Manager', 'Contact', 'Phone Types', '?', 1, 'Cell', NULL,  0, NULL);
        INSERT_SYSTEM_LABEL(0, 'Entity Manager', 'Contact', 'Phone Types', '?', 2, 'Pager', NULL,  0, NULL);
        INSERT_SYSTEM_LABEL(0, 'Entity Manager', 'Contact', 'Phone Types', '?', 3, 'Fax', NULL,  0, NULL);
        INSERT_SYSTEM_LABEL(0, 'Entity Manager', 'Contact', 'Phone Types', '?', 4, 'Home', NULL,  0, NULL);
    
    --Billing Interval Values
    INSERT_SYSTEM_LABEL(0, 'Billing', 'Interval', 'Values', '?', 0, 'Day', NULL,  0, 0);
    INSERT_SYSTEM_LABEL(0, 'Billing', 'Interval', 'Values', '?', 1, 'Week', NULL,  0, 0);
    INSERT_SYSTEM_LABEL(0, 'Billing', 'Interval', 'Values', '?', 2, 'Month', NULL,  0, 0);
    INSERT_SYSTEM_LABEL(0, 'Billing', 'Interval', 'Values', '?', 3, 'Quarter', NULL,  0, 0);
    INSERT_SYSTEM_LABEL(0, 'Billing', 'Interval', 'Values', '?', 4, 'Year', NULL,  0, 0);
    
    --Billing Line Item Types - Used in the Line Item Edit Dialog
    INSERT_SYSTEM_LABEL(0, 'Billing', 'User Line Item Type', 'Values', '?', 0, 'Payment', 'P',  0, 0);
    INSERT_SYSTEM_LABEL(0, 'Billing', 'User Line Item Type', 'Values', '?', 1, 'Finance Charge', 'F',  0, 0);
    INSERT_SYSTEM_LABEL(0, 'Billing', 'User Line Item Type', 'Values', '?', 2, 'Adjustment', 'A',  0, 0);
    INSERT_SYSTEM_LABEL(0, 'Billing', 'User Line Item Type', 'Values', '?', 3, 'Balance', 'B',  0, 0);
    INSERT_SYSTEM_LABEL(0, 'Billing', 'User Line Item Type', 'Values', '?', 4, 'Miscellaneous', 'M',  0, 0);
    INSERT_SYSTEM_LABEL(0, 'Billing', 'User Line Item Type', 'Values', '?', 5, 'Manual Line Item Tax', 'X',  0, 0);
    
    INSERT_SYSTEM_LABEL(0, 'Billing', 'Line Item Type', 'Values', '?', 6, 'Current', 'C',  0, 0);
    INSERT_SYSTEM_LABEL(0, 'Billing', 'Line Item Type', 'Values', '?', 7, 'Tax', 'T',  0, 0);
    
    --System Object Privilege Values
    INSERT_SYSTEM_LABEL(0, 'System', 'Privileges', 'Values', '?', 0, 'None', '0',  1, 0);
    INSERT_SYSTEM_LABEL(0, 'System', 'Privileges', 'Values', '?', 3, 'View', '3',  0, 0);
    INSERT_SYSTEM_LABEL(0, 'System', 'Privileges', 'Values', '?', 6, 'Edit', '6',  0, 0);
    INSERT_SYSTEM_LABEL(0, 'System', 'Privileges', 'Values', '?', 9, 'Full Control', '9',  0, 0);

    INSERT_SYSTEM_LABEL(1, 'Scheduling', 'Transactions', 'Supply Transaction Types', '?', 0, 'Purchase', '', 0, 0);
    INSERT_SYSTEM_LABEL(1, 'Scheduling', 'Transactions', 'Supply Transaction Types', '?', 1, 'Generation', '', 0, 0);
    INSERT_SYSTEM_LABEL(1, 'Scheduling', 'Transactions', 'Supply Transaction Types', '?', 2, 'Withdrawal', '', 0, 0);
    INSERT_SYSTEM_LABEL(1, 'Scheduling', 'Transactions', 'Supply Transaction Types', '?', 3, 'Adjustment', '', 0, 0);
    INSERT_SYSTEM_LABEL(1, 'Scheduling', 'Transactions', 'Supply Transaction Types', '?', 4, 'Exchange', '', 0, 0);

	-- Entity Manager - 'Canned Where Clauses' for calculation process components
	INSERT_SYSTEM_LABEL(0, 'Calculation Process', 'Combo Lists', 'Canned Where Clauses', '?', 0, '<type in a where clause>', NULL,  0, NULL);
	-- Entity Manager - Function drop-down for all Formula Components
	INSERT_SYSTEM_LABEL(0, 'Calculation Process', 'Combo Lists', 'Formula Functions', '?', 0, 'Select', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(0, 'Calculation Process', 'Combo Lists', 'Formula Functions', '?', 1, 'Sum', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(0, 'Calculation Process', 'Combo Lists', 'Formula Functions', '?', 2, 'Min', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(0, 'Calculation Process', 'Combo Lists', 'Formula Functions', '?', 3, 'Max', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(0, 'Calculation Process', 'Combo Lists', 'Formula Functions', '?', 4, 'Average', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(0, 'Calculation Process', 'Combo Lists', 'Formula Functions', '?', 5, 'NZ-Min', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(0, 'Calculation Process', 'Combo Lists', 'Formula Functions', '?', 6, 'NZ-Average', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(0, 'Calculation Process', 'Combo Lists', 'Formula Functions', '?', 7, 'Choose', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(0, 'Calculation Process', 'Combo Lists', 'Formula Functions', '?', 8, 'Spread', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(0, 'Calculation Process', 'Combo Lists', 'Formula Functions', '?', 9, 'YTD Sum', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(0, 'Calculation Process', 'Combo Lists', 'Formula Functions', '?', 10, 'YTD Average', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(0, 'Calculation Process', 'Combo Lists', 'Formula Functions', '?', 11, 'YTD-Inc Sum', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(0, 'Calculation Process', 'Combo Lists', 'Formula Functions', '?', 12, 'YTD-Inc Average', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(0, 'Calculation Process', 'Combo Lists', 'Formula Functions', '?', 13, 'MTD Sum', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(0, 'Calculation Process', 'Combo Lists', 'Formula Functions', '?', 14, 'MTD Average', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(0, 'Calculation Process', 'Combo Lists', 'Formula Functions', '?', 15, 'MTD-Inc Sum', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(0, 'Calculation Process', 'Combo Lists', 'Formula Functions', '?', 16, 'MTD-Inc Average', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(0, 'Calculation Process', 'Combo Lists', 'Formula Functions', '?', 17, 'Annual Sum', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(0, 'Calculation Process', 'Combo Lists', 'Formula Functions', '?', 18, 'Annual Average', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(0, 'Calculation Process', 'Combo Lists', 'Formula Functions', '?', 19, 'Annual-Inc Sum', NULL,  0, NULL);
	INSERT_SYSTEM_LABEL(0, 'Calculation Process', 'Combo Lists', 'Formula Functions', '?', 20, 'Annual-Inc Average', NULL,  0, NULL);
    

    -- Skip Excluded Objects in Configuration Export
    INSERT_SYSTEM_LABEL(0, 'System', 'Configuration Export', 'Excluded Objects', 'Module', 0, 'Transaction Traits', '', 0, 0);
    INSERT_SYSTEM_LABEL(0, 'System', 'Configuration Export', 'Excluded Objects', 'Data Exchange', 0, 'Configuration Export: Product Development Use Only', '', 0, 0);
	-- Product Script Types
	INSERT_SYSTEM_LABEL(0, 'System', 'Configuration Export', 'Product Script Types', '?', 1, 'Core', NULL, 0, NULL);
	INSERT_SYSTEM_LABEL(0, 'System', 'Configuration Export', 'Product Script Types', '?', 1, 'SEM', NULL, 0, NULL);
	INSERT_SYSTEM_LABEL(0, 'System', 'Configuration Export', 'Product Script Types', '?', 1, 'TDIE', NULL, 0, NULL);
	
	-- Process Log System Labels
	INSERT_SYSTEM_LABEL(0, 'System', 'Logging', 'Log Levels', 'Values', 1, 'Fatal', '999', 0, 0);
	INSERT_SYSTEM_LABEL(0, 'System', 'Logging', 'Log Levels', 'Values', 2, 'Error', '900', 0, 0);
	INSERT_SYSTEM_LABEL(0, 'System', 'Logging', 'Log Levels', 'Values', 3, 'Warning', '800', 0, 0);
	INSERT_SYSTEM_LABEL(0, 'System', 'Logging', 'Log Levels', 'Values', 4, 'Notice', '700', 0, 0);
	INSERT_SYSTEM_LABEL(0, 'System', 'Logging', 'Log Levels', 'Values', 5, 'Info', '600', 1, 0);
	INSERT_SYSTEM_LABEL(0, 'System', 'Logging', 'Log Levels', 'Values', 6, 'More Info', '500', 0, 0);
	INSERT_SYSTEM_LABEL(0, 'System', 'Logging', 'Log Levels', 'Values', 7, 'All Info', '400', 0, 0);
	INSERT_SYSTEM_LABEL(0, 'System', 'Logging', 'Log Levels', 'Values', 8, 'Debug', '300', 0, 0);
	INSERT_SYSTEM_LABEL(0, 'System', 'Logging', 'Log Levels', 'Values', 9, 'More Debug', '200', 0, 0);
	INSERT_SYSTEM_LABEL(0, 'System', 'Logging', 'Log Levels', 'Values', 10, 'Max Debug', '100', 0, 0);
	
	-- System Alert Trigger Labels
	INSERT_SYSTEM_LABEL(0, 'System', 'Alerts', 'Trigger Types', 'Values', 1, 'Exception', '', 0, 0);
	INSERT_SYSTEM_LABEL(0, 'System', 'Alerts', 'Trigger Types', 'Values', 2, 'Process Completion', '', 0, 0);
	INSERT_SYSTEM_LABEL(0, 'System', 'Alerts', 'Trigger Types', 'Values', 3, 'Other', '', 0, 0);

	-- Loss Factor Loss Type Labels
	INSERT_SYSTEM_LABEL(0,'Entity Manager','Loss Factor','Loss Type','?',1,'Transmission',NULL,0,0);
	INSERT_SYSTEM_LABEL(0,'Entity Manager','Loss Factor','Loss Type','?',2,'Distribution',NULL,0,0);
	INSERT_SYSTEM_LABEL(0,'Entity Manager','Loss Factor','Loss Type','?',3,'Transformer',NULL,0,0);
	INSERT_SYSTEM_LABEL(0,'Entity Manager','Loss Factor','Loss Type','?',4,'UFE',NULL,0,0);

	-- Loss Factor Interval Lables
	INSERT_SYSTEM_LABEL(0,'Entity Manager','Loss Factor','Interval','Schedule',1,'Hour',NULL,0,0);
	INSERT_SYSTEM_LABEL(0,'Entity Manager','Loss Factor','Interval','Schedule',2,'30 Minute',NULL,0,0);
	INSERT_SYSTEM_LABEL(0,'Entity Manager','Loss Factor','Interval','Schedule',3,'15 Minute',NULL,0,0);
	INSERT_SYSTEM_LABEL(0,'Entity Manager','Loss Factor','Interval','Schedule',4,'10 Minute',NULL,0,0);
	INSERT_SYSTEM_LABEL(0,'Entity Manager','Loss Factor','Interval','Schedule',5,'5 Minute',NULL,0,0);

	INSERT_SYSTEM_LABEL(0,'Entity Manager','Loss Factor','Interval','Pattern',1,'Day',NULL,0,0);
	INSERT_SYSTEM_LABEL(0,'Entity Manager','Loss Factor','Interval','Pattern',2,'Hour',NULL,0,0);
	INSERT_SYSTEM_LABEL(0,'Entity Manager','Loss Factor','Interval','Pattern',3,'30 Minute',NULL,0,0);
	INSERT_SYSTEM_LABEL(0,'Entity Manager','Loss Factor','Interval','Pattern',4,'15 Minute',NULL,0,0);

	-- Entity Notes
	INSERT_SYSTEM_LABEL(0,'Entity Manager','Entity Note Types','?','?',1,'Default',NULL,0,0);

	-- Data Import Delimiters
	INSERT_SYSTEM_LABEL(0,'Data Import','Delimiters','?','?',1,'Semicolon',';',0,0);
	INSERT_SYSTEM_LABEL(0,'Data Import','Delimiters','?','?',1,'Comma',',',0,0);
	INSERT_SYSTEM_LABEL(0,'Data Import','Delimiters','?','?',1,'Pipe','|',0,0);
	INSERT_SYSTEM_LABEL(0,'Data Import','Delimiters','?','?',1,'Tab',CHR(9),0,0);

	-- Meter Units
	INSERT_SYSTEM_LABEL(0,'Entity Manager','Meter Units','?','?',1,'KWH',NULL,0,0);
	INSERT_SYSTEM_LABEL(0,'Entity Manager','Meter Units','?','?',2,'KW',NULL,0,0);
	INSERT_SYSTEM_LABEL(0,'Entity Manager','Meter Units','?','?',3,'KVAR',NULL,0,0);
	INSERT_SYSTEM_LABEL(0,'Entity Manager','Meter Units','?','?',4,'MWH',NULL,0,0);
	INSERT_SYSTEM_LABEL(0,'Entity Manager','Meter Units','?','?',5,'MW',NULL,0,0);
	INSERT_SYSTEM_LABEL(0,'Entity Manager','Meter Units','?','?',6,'MVAR',NULL,0,0);
	INSERT_SYSTEM_LABEL(0,'Entity Manager','Meter Units','?','?',7,'THERM',NULL,0,0);
	INSERT_SYSTEM_LABEL(0,'Entity Manager','Meter Units','?','?',8,'J',NULL,0,0);
	INSERT_SYSTEM_LABEL(0,'Entity Manager','Meter Units','?','?',9,'CCF',NULL,0,0);
	INSERT_SYSTEM_LABEL(0,'Entity Manager','Meter Units','?','?',10,'CBM',NULL,0,0);
	INSERT_SYSTEM_LABEL(0,'Entity Manager','Meter Units','?','?',11,'THM',NULL,0,0);
	INSERT_SYSTEM_LABEL(0,'Entity Manager','Meter Units','?','?',12,'DTH',NULL,0,0);
	INSERT_SYSTEM_LABEL(0,'Entity Manager','Meter Units','?','?',13,'BTU',NULL,0,0);

	-- Meter Channel Units
	INSERT_SYSTEM_LABEL(0,'Entity Manager','Meter Channel','Unit','?',1,'KWH',NULL,0,0);
	INSERT_SYSTEM_LABEL(0,'Entity Manager','Meter Channel','Unit','?',2,'KW',NULL,0,0);
	INSERT_SYSTEM_LABEL(0,'Entity Manager','Meter Channel','Unit','?',3,'KVAR',NULL,0,0);
	
	-- Meter Channel Intervals
	INSERT_SYSTEM_LABEL(0,'Entity Manager','Meter Channel','Interval','?',1,'15 Minute',NULL,0,0);
	INSERT_SYSTEM_LABEL(0,'Entity Manager','Meter Channel','Interval','?',2,'30 Minute',NULL,0,0);
	INSERT_SYSTEM_LABEL(0,'Entity Manager','Meter Channel','Interval','?',3,'Hour',NULL,0,0);

	-- Contract Assignment Entity Domains
	INSERT_SYSTEM_LABEL(0,'Load Management','Contracts','Assignable Domains','?',1,'Account',NULL,0,0);
	INSERT_SYSTEM_LABEL(0,'Load Management','Contracts','Assignable Domains','?',1,'Meter',NULL,0,0);
	INSERT_SYSTEM_LABEL(0,'Load Management','Contracts','Assignable Domains','?',1,'Customer',NULL,0,0);

	-- DR Events Status
	INSERT_SYSTEM_LABEL(0,'Load Management','Demand Response','Event Status','?',1,'New',NULL,0,0);
	INSERT_SYSTEM_LABEL(0,'Load Management','Demand Response','Event Status','?',2,'Submitted',NULL,0,0);
	INSERT_SYSTEM_LABEL(0,'Load Management','Demand Response','Event Status','?',3,'Confirmed',NULL,0,0);
	INSERT_SYSTEM_LABEL(0,'Load Management','Demand Response','Event Status','?',4,'Started',NULL,0,0);
	INSERT_SYSTEM_LABEL(0,'Load Management','Demand Response','Event Status','?',5,'Ended',NULL,0,0);
	INSERT_SYSTEM_LABEL(0,'Load Management','Demand Response','Event Status','?',6,'Canceled',NULL,0,0);
	INSERT_SYSTEM_LABEL(0,'Load Management','Demand Response','Event Status','?',7,'System Override',NULL,0,0);
	INSERT_SYSTEM_LABEL(0,'Load Management','Demand Response','Event Status','?',8,'Resumed',NULL,0,0);
	INSERT_SYSTEM_LABEL(0,'Load Management','Demand Response','Event Status','?',9,'Completed',NULL,0,0);

	-- DR Event Type
	INSERT_SYSTEM_LABEL(0,'Load Management','Demand Response','Event Type','?',1,'Economic',NULL,0,0);
	INSERT_SYSTEM_LABEL(0,'Load Management','Demand Response','Event Type','?',2,'Reliability',NULL,0,0);
	
	-- DR Environmental Signal Txn
	INSERT_SYSTEM_LABEL(0,'Load Management','Demand Response','Environmental Signal Transaction','?',0,'Zonal Emission Rate',NULL,1,0);

	-- Distributed Generation Functions
	INSERT_SYSTEM_LABEL(0, 'Load Management', 'Distributed Energy Resource', 'Function', '?', 1, 'Demand Response', NULL, 0, 0);
	INSERT_SYSTEM_LABEL(0, 'Load Management', 'Distributed Energy Resource', 'Function', '?', 2, 'Distributed Generation', NULL, 0, 0);
	INSERT_SYSTEM_LABEL(0, 'Load Management', 'Distributed Energy Resource', 'Function', '?', 3, 'Distributed Storage', NULL, 0, 0);

	-- DER Status
	INSERT_SYSTEM_LABEL(0, 'Load Management', 'Distributed Energy Resource', 'Operating Status', '?', 1, 'Unavailable', NULL, 0, 0);

	-- Demand Response Categories
	INSERT_SYSTEM_LABEL(0, 'Load Management', 'Distributed Energy Resource', 'Demand Response', '?', 1, 'DLC HVAC', NULL, 0, 0);
	INSERT_SYSTEM_LABEL(0, 'Load Management', 'Distributed Energy Resource', 'Demand Response', '?', 2, 'DLC Water Heater', NULL, 0, 0);
	INSERT_SYSTEM_LABEL(0, 'Load Management', 'Distributed Energy Resource', 'Demand Response', '?', 3, 'DLC Pool Pump', NULL, 0, 0);
	INSERT_SYSTEM_LABEL(0, 'Load Management', 'Distributed Energy Resource', 'Demand Response', '?', 4, 'Programmable Thermostat', NULL, 0, 0);
	INSERT_SYSTEM_LABEL(0, 'Load Management', 'Distributed Energy Resource', 'Demand Response', '?', 5, 'Other', NULL, 0, 0);

	-- Distributed Generation Categories
	INSERT_SYSTEM_LABEL(0, 'Load Management', 'Distributed Energy Resource', 'Distributed Generation', '?', 1, 'PV', NULL, 0, 0);
	INSERT_SYSTEM_LABEL(0, 'Load Management', 'Distributed Energy Resource', 'Distributed Generation', '?', 2, 'Wind', NULL, 0, 0);
	INSERT_SYSTEM_LABEL(0, 'Load Management', 'Distributed Energy Resource', 'Distributed Generation', '?', 3, 'PHEV', NULL, 0, 0);
	INSERT_SYSTEM_LABEL(0, 'Load Management', 'Distributed Energy Resource', 'Distributed Generation', '?', 5, 'Micro-Turbine', NULL, 0, 0);
	INSERT_SYSTEM_LABEL(0, 'Load Management', 'Distributed Energy Resource', 'Distributed Generation', '?', 6, 'Diesel', NULL, 0, 0);
	INSERT_SYSTEM_LABEL(0, 'Load Management', 'Distributed Energy Resource', 'Distributed Generation', '?', 7, 'Other', NULL, 0, 0);
	
	-- Distributed Storage Categories
	INSERT_SYSTEM_LABEL(0, 'Load Management', 'Distributed Energy Resource', 'Distributed Storage', '?', 1, 'Battery', NULL, 0, 0);
	INSERT_SYSTEM_LABEL(0, 'Load Management', 'Distributed Energy Resource', 'Distributed Storage', '?', 2, 'Other', NULL, 0, 0);
	
	-- System Object Tree - Allowed Child Objects
	INSERT_SYSTEM_LABEL(0, 'System', 'System Objects', 'Allowed Child Objects', 'Action', 0, 'Action', '', 0, 0);
	INSERT_SYSTEM_LABEL(0, 'System', 'System Objects', 'Allowed Child Objects', 'All', 0, 'Action', '', 0, 0);
	INSERT_SYSTEM_LABEL(0, 'System', 'System Objects', 'Allowed Child Objects', 'All', 1, 'Chart', '', 0, 0);
	INSERT_SYSTEM_LABEL(0, 'System', 'System Objects', 'Allowed Child Objects', 'All', 2, 'Column', '', 0, 0);
	INSERT_SYSTEM_LABEL(0, 'System', 'System Objects', 'Allowed Child Objects', 'All', 3, 'Data Exchange', '', 0, 0);
	INSERT_SYSTEM_LABEL(0, 'System', 'System Objects', 'Allowed Child Objects', 'All', 4, 'Grid', '', 0, 0);
	INSERT_SYSTEM_LABEL(0, 'System', 'System Objects', 'Allowed Child Objects', 'All', 5, 'IO Field', '', 0, 0);
	INSERT_SYSTEM_LABEL(0, 'System', 'System Objects', 'Allowed Child Objects', 'All', 6, 'IO SubTab', '', 0, 0);
	INSERT_SYSTEM_LABEL(0, 'System', 'System Objects', 'Allowed Child Objects', 'All', 7, 'IO Table', '', 0, 0);
	INSERT_SYSTEM_LABEL(0, 'System', 'System Objects', 'Allowed Child Objects', 'All', 8, 'Label', '', 0, 0);
	INSERT_SYSTEM_LABEL(0, 'System', 'System Objects', 'Allowed Child Objects', 'All', 9, 'Layout', '', 0, 0);
	INSERT_SYSTEM_LABEL(0, 'System', 'System Objects', 'Allowed Child Objects', 'All', 10, 'Report', '', 0, 0);
	INSERT_SYSTEM_LABEL(0, 'System', 'System Objects', 'Allowed Child Objects', 'All', 11, 'Report Filter', '', 0, 0);
	INSERT_SYSTEM_LABEL(0, 'System', 'System Objects', 'Allowed Child Objects', 'All', 12, 'System View', '', 0, 0);
	INSERT_SYSTEM_LABEL(0, 'System', 'System Objects', 'Allowed Child Objects', 'All', 13, 'Tree', '', 0, 0);
	INSERT_SYSTEM_LABEL(0, 'System', 'System Objects', 'Allowed Child Objects', 'All', 14, 'Tree Column', '', 0, 0);
	INSERT_SYSTEM_LABEL(0, 'System', 'System Objects', 'Allowed Child Objects', 'Data Exchange', 0, 'Action', '', 0, 0);
	INSERT_SYSTEM_LABEL(0, 'System', 'System Objects', 'Allowed Child Objects', 'Grid', 0, 'Action', '', 0, 0);
	INSERT_SYSTEM_LABEL(0, 'System', 'System Objects', 'Allowed Child Objects', 'Grid', 1, 'Column', '', 0, 0);
	INSERT_SYSTEM_LABEL(0, 'System', 'System Objects', 'Allowed Child Objects', 'Grid', 2, 'Label', '', 0, 0);
	INSERT_SYSTEM_LABEL(0, 'System', 'System Objects', 'Allowed Child Objects', 'IO Table', 0, 'Action', '', 0, 0);
	INSERT_SYSTEM_LABEL(0, 'System', 'System Objects', 'Allowed Child Objects', 'IO Table', 1, 'IO Field', '', 0, 0);
	INSERT_SYSTEM_LABEL(0, 'System', 'System Objects', 'Allowed Child Objects', 'IO Table', 2, 'IO SubTab', '', 0, 0);
	INSERT_SYSTEM_LABEL(0, 'System', 'System Objects', 'Allowed Child Objects', 'IO SubTab', 0, 'Grid', '', 0, 0);
	INSERT_SYSTEM_LABEL(0, 'System', 'System Objects', 'Allowed Child Objects', 'Layout', 0, 'Layout', '', 0, 0);
	INSERT_SYSTEM_LABEL(0, 'System', 'System Objects', 'Allowed Child Objects', 'Module', 0, 'System View', '', 0, 0);
	INSERT_SYSTEM_LABEL(0, 'System', 'System Objects', 'Allowed Child Objects', 'Module', 1, 'Data Exchange', '', 0, 0);
	INSERT_SYSTEM_LABEL(0, 'System', 'System Objects', 'Allowed Child Objects', 'Report', 0, 'Action', '', 0, 0);
	INSERT_SYSTEM_LABEL(0, 'System', 'System Objects', 'Allowed Child Objects', 'Report', 1, 'Chart', '', 0, 0);
	INSERT_SYSTEM_LABEL(0, 'System', 'System Objects', 'Allowed Child Objects', 'Report', 2, 'Grid', '', 0, 0);
	INSERT_SYSTEM_LABEL(0, 'System', 'System Objects', 'Allowed Child Objects', 'Report', 3, 'IO Table', '', 0, 0);
	INSERT_SYSTEM_LABEL(0, 'System', 'System Objects', 'Allowed Child Objects', 'Report', 4, 'Report Filter', '', 0, 0);
	INSERT_SYSTEM_LABEL(0, 'System', 'System Objects', 'Allowed Child Objects', 'Report Filter', 0, 'Action', '', 0, 0);
	INSERT_SYSTEM_LABEL(0, 'System', 'System Objects', 'Allowed Child Objects', 'Report Filter', 1, 'Tree', '', 0, 0);
	INSERT_SYSTEM_LABEL(0, 'System', 'System Objects', 'Allowed Child Objects', 'ReportRepository', 0, 'Report', '', 0, 0);
	INSERT_SYSTEM_LABEL(0, 'System', 'System Objects', 'Allowed Child Objects', 'System', 0, 'Layout', '', 0, 0);
	INSERT_SYSTEM_LABEL(0, 'System', 'System Objects', 'Allowed Child Objects', 'System', 1, 'Module', '', 0, 0);
	INSERT_SYSTEM_LABEL(0, 'System', 'System Objects', 'Allowed Child Objects', 'System View', 0, 'Report', '', 0, 0);
	INSERT_SYSTEM_LABEL(0, 'System', 'System Objects', 'Allowed Child Objects', 'System View', 1, 'Action', '', 0, 0);
	INSERT_SYSTEM_LABEL(0, 'System', 'System Objects', 'Allowed Child Objects', 'Tree', 0, 'Tree', '', 0, 0);
	INSERT_SYSTEM_LABEL(0, 'System', 'System Objects', 'Allowed Child Objects', 'Tree', 1, 'Tree Column', '', 0, 0);
	
	-- Customer Types
	INSERT_SYSTEM_LABEL(0, 'Product', 'Smart Grid Programs', 'Customer Types', '?', 1, 'Residential', NULL,  0, 0);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Smart Grid Programs', 'Customer Types', '?', 2, 'Commercial', NULL,  0, 0);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Smart Grid Programs', 'Customer Types', '?', 3, 'Industrial', NULL,  0, 0);

	-- Execution Types
	INSERT_SYSTEM_LABEL(0, 'Product', 'Smart Grid Programs', 'Execution Types', '?', 1, 'Reliability', NULL,  0, 0);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Smart Grid Programs', 'Execution Types', '?', 2, 'Economic', NULL,  0, 0);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Smart Grid Programs', 'Execution Types', '?', 3, 'Environmental', NULL,  0, 0);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Smart Grid Programs', 'Execution Types', '?', 4, 'Generation', NULL,  0, 0);
	
	-- Execution Period
	INSERT_SYSTEM_LABEL(0, 'Product', 'Smart Grid Programs', 'Execution Period', '?', 1, 'Annual', NULL,  0, 0);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Smart Grid Programs', 'Execution Period', '?', 2, 'Monthly', NULL,  0, 0);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Smart Grid Programs', 'Execution Period', '?', 3, 'Weekly', NULL,  0, 0);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Smart Grid Programs', 'Execution Period', '?', 4, 'Daily', NULL,  0, 0);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Smart Grid Programs', 'Execution Period', '?', 5, 'Hourly', NULL,  0, 0);
	
	
	-- Maximum Duration
	INSERT_SYSTEM_LABEL(0, 'Product', 'Smart Grid Programs', 'Maximum Duration', '?', 1, '0', NULL,  0, 0);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Smart Grid Programs', 'Maximum Duration', '?', 2, '5', NULL,  0, 0);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Smart Grid Programs', 'Maximum Duration', '?', 3, '10', NULL,  0, 0);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Smart Grid Programs', 'Maximum Duration', '?', 4, '15', NULL,  0, 0);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Smart Grid Programs', 'Maximum Duration', '?', 5, '20', NULL,  0, 0);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Smart Grid Programs', 'Maximum Duration', '?', 6, '30', NULL,  0, 0);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Smart Grid Programs', 'Maximum Duration', '?', 7, '60', NULL,  0, 0);
	
	-- Minimum Off Time
	INSERT_SYSTEM_LABEL(0, 'Product', 'Smart Grid Programs', 'Minimum Off Time', '?', 1, '0', NULL,  0, 0);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Smart Grid Programs', 'Minimum Off Time', '?', 2, '5', NULL,  0, 0);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Smart Grid Programs', 'Minimum Off Time', '?', 3, '10', NULL,  0, 0);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Smart Grid Programs', 'Minimum Off Time', '?', 4, '15', NULL,  0, 0);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Smart Grid Programs', 'Minimum Off Time', '?', 5, '20', NULL,  0, 0);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Smart Grid Programs', 'Minimum Off Time', '?', 6, '30', NULL,  0, 0);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Smart Grid Programs', 'Minimum Off Time', '?', 7, '60', NULL,  0, 0);
	
	
	-- Degree Increase
	INSERT_SYSTEM_LABEL(0, 'Product', 'Smart Grid Programs', 'Operating Constraint', 'Degree Increase', 1, '0', NULL,  0, 0);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Smart Grid Programs', 'Operating Constraint', 'Degree Increase', 2, '1', NULL,  0, 0);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Smart Grid Programs', 'Operating Constraint', 'Degree Increase', 3, '2', NULL,  0, 0);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Smart Grid Programs', 'Operating Constraint', 'Degree Increase', 4, '3', NULL,  0, 0);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Smart Grid Programs', 'Operating Constraint', 'Degree Increase', 5, '4', NULL,  0, 0);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Smart Grid Programs', 'Operating Constraint', 'Degree Increase', 6, '5', NULL,  0, 0);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Smart Grid Programs', 'Operating Constraint', 'Degree Increase', 7, '6', NULL,  0, 0);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Smart Grid Programs', 'Operating Constraint', 'Degree Increase', 8, '7', NULL,  0, 0);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Smart Grid Programs', 'Operating Constraint', 'Degree Increase', 9, '8', NULL,  0, 0);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Smart Grid Programs', 'Operating Constraint', 'Degree Increase', 10, '9', NULL,  0, 0);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Smart Grid Programs', 'Operating Constraint', 'Degree Increase', 11, '10', NULL,  0, 0);
	
	-- Degree Decrease
	INSERT_SYSTEM_LABEL(0, 'Product', 'Smart Grid Programs', 'Operating Constraint', 'Degree Decrease', 1, '-10', NULL,  0, 0);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Smart Grid Programs', 'Operating Constraint', 'Degree Decrease', 2, '-9', NULL,  0, 0);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Smart Grid Programs', 'Operating Constraint', 'Degree Decrease', 3, '-8', NULL,  0, 0);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Smart Grid Programs', 'Operating Constraint', 'Degree Decrease', 4, '-7', NULL,  0, 0);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Smart Grid Programs', 'Operating Constraint', 'Degree Decrease', 5, '-6', NULL,  0, 0);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Smart Grid Programs', 'Operating Constraint', 'Degree Decrease', 6, '-5', NULL,  0, 0);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Smart Grid Programs', 'Operating Constraint', 'Degree Decrease', 7, '-4', NULL,  0, 0);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Smart Grid Programs', 'Operating Constraint', 'Degree Decrease', 8, '-3', NULL,  0, 0);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Smart Grid Programs', 'Operating Constraint', 'Degree Decrease', 9, '-2', NULL,  0, 0);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Smart Grid Programs', 'Operating Constraint', 'Degree Decrease', 10, '-1', NULL,  0, 0);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Smart Grid Programs', 'Operating Constraint', 'Degree Decrease', 11, '0', NULL,  0, 0);
	
	-- Opt Out/Override Period
	INSERT_SYSTEM_LABEL(0, 'Product', 'Smart Grid Programs', 'Opt Out/Override Period', '?', 1, 'Annual', NULL,  0, 0);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Smart Grid Programs', 'Opt Out/Override Period', '?', 2, 'Monthly', NULL,  0, 0);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Smart Grid Programs', 'Opt Out/Override Period', '?', 3, 'Daily', NULL,  0, 0);
	
	-- Payment Period
	INSERT_SYSTEM_LABEL(0, 'Product', 'Smart Grid Programs', 'Payment Period', '?', 1, 'One-Time Fixed', NULL,  0, 0);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Smart Grid Programs', 'Payment Period', '?', 2, 'Annual', NULL,  0, 0);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Smart Grid Programs', 'Payment Period', '?', 3, 'Monthly', NULL,  0, 0);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Smart Grid Programs', 'Payment Period', '?', 4, 'Daily', NULL,  0, 0);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Smart Grid Programs', 'Payment Period', '?', 5, 'Per Event', NULL,  0, 0);	
	INSERT_SYSTEM_LABEL(0, 'Product', 'Smart Grid Programs', 'Payment Period', '?', 6, 'Per Event Interval', NULL,  0, 0);
		
	-- Required Equipment
	INSERT_SYSTEM_LABEL(0, 'Product', 'Smart Grid Programs', 'Required Equipment', '?', 1, 'Smart Meter', NULL,  0, 0);
	-- Environmental Signal Type
	INSERT_SYSTEM_LABEL(0, 'Product', 'Smart Grid Programs', 'Signal Type', '?', 1, 'Renewable Percentage', NULL,  0, 0);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Smart Grid Programs', 'Signal Type', '?', 2, 'CO2 lbs/mwh', NULL,  0, 0);
	
	-- Renewable Percentage Signals
	INSERT_SYSTEM_LABEL(0, 'Product', 'Smart Grid Programs', 'Signal Type', 'Renewable Percentage', 1, 'High', NULL,  0, 0);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Smart Grid Programs', 'Signal Type', 'Renewable Percentage', 2, 'Medium', NULL,  0, 0);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Smart Grid Programs', 'Signal Type', 'Renewable Percentage', 3, 'Low', NULL,  0, 0);
	
	-- CO2 lbs/mwh Signals
	INSERT_SYSTEM_LABEL(0, 'Product', 'Smart Grid Programs', 'Signal Type', 'CO2 lbs/mwh', 1, 'High', NULL,  0, 0);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Smart Grid Programs', 'Signal Type', 'CO2 lbs/mwh', 2, 'Medium', NULL,  0, 0);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Smart Grid Programs', 'Signal Type', 'CO2 lbs/mwh', 3, 'Low', NULL,  0, 0);

	-- Program Interval
	INSERT_SYSTEM_LABEL(0, 'Product', 'Smart Grid Programs', 'Interval', '?', 1, '15 Minute', NULL,  0, 0);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Smart Grid Programs', 'Interval', '?', 2, '30 Minute', NULL,  0, 0);
	INSERT_SYSTEM_LABEL(0, 'Product', 'Smart Grid Programs', 'Interval', '?', 3, 'Hour', NULL,  0, 0);

	-- Tables/constraints to ignore when generating new/missing indexes for foreign keys
	INSERT_SYSTEM_LABEL(0, 'System', 'Tools', 'Foreign Keys', 'Ignore Constraints', 1, 'FK_IT_ASSGN_SCHD_STMNT_TYPE', NULL,  0, 0);
	INSERT_SYSTEM_LABEL(0, 'System', 'Tools', 'Foreign Keys', 'Ignore Constraints', 2, 'FK_IT_SCHEDULE_LOCK_SUMMARY_ST', NULL,  0, 0);
	INSERT_SYSTEM_LABEL(0, 'System', 'Tools', 'Foreign Keys', 'Ignore Constraints', 3, 'FK_IT_SCHEDULE_STMENT_TYPE', NULL,  0, 0);
	INSERT_SYSTEM_LABEL(0, 'System', 'Tools', 'Foreign Keys', 'Ignore Constraints', 4, 'FK_IT_TRAIT_SCHD_LK_S_ST_TYPE', NULL,  0, 0);
	INSERT_SYSTEM_LABEL(0, 'System', 'Tools', 'Foreign Keys', 'Ignore Constraints', 5, 'FK_IT_TRAIT_SCHED_LK_S_TRAIT', NULL,  0, 0);
	INSERT_SYSTEM_LABEL(0, 'System', 'Tools', 'Foreign Keys', 'Ignore Constraints', 6, 'FK_IT_TRAIT_SCHD_STMT_TYPE', NULL,  0, 0);
	INSERT_SYSTEM_LABEL(0, 'System', 'Tools', 'Foreign Keys', 'Ignore Constraints', 7, 'FK_IT_TRAIT_SCHED_TRAIT', NULL,  0, 0);
	INSERT_SYSTEM_LABEL(0, 'System', 'Tools', 'Foreign Keys', 'Ignore Constraints', 8, 'FK_TX_SUB_STATION_MTR_PT_VAL_S', NULL,  0, 0);
	INSERT_SYSTEM_LABEL(0, 'System', 'Tools', 'Foreign Keys', 'Ignore Constraints', 9, 'FK_TX_SUB_STATION_MTR_VAL_L_MS', NULL,  0, 0);

	-- Tables/Columns to ignore when generating IO package - usually foreign key references to domains which
	-- include a 'Not Assigned' entity are auto-set to zero (instead of null). This section lists exceptions for
	-- references which should remain null
	INSERT_SYSTEM_LABEL(0, 'Entity Manager', 'Ignore Not Assigned', 'CALCULATION_PROCESS', '?', 1, 'CONTEXT_REALM_ID', NULL,  0, 0);
	INSERT_SYSTEM_LABEL(0, 'Entity Manager', 'Ignore Not Assigned', 'CALCULATION_PROCESS', '?', 2, 'CONTEXT_GROUP_ID', NULL,  0, 0);

	INSERT_SYSTEM_LABEL(0, 'Entity Manager', 'Ignore Not Assigned', 'ENTITY_GROUP', '?', 1, 'PARENT_GROUP_ID', NULL,  0, 0);

	INSERT_SYSTEM_LABEL(0, 'Entity Manager', 'Ignore Not Assigned', 'PROXY_DAY_METHOD', '?', 1, 'STATION_ID', NULL,  0, 0);
	INSERT_SYSTEM_LABEL(0, 'Entity Manager', 'Ignore Not Assigned', 'PROXY_DAY_METHOD', '?', 2, 'PARAMETER_ID', NULL,  0, 0);
	INSERT_SYSTEM_LABEL(0, 'Entity Manager', 'Ignore Not Assigned', 'PROXY_DAY_METHOD', '?', 3, 'SYSTEM_LOAD_ID', NULL,  0, 0);

	INSERT_SYSTEM_LABEL(0, 'Entity Manager', 'Ignore Not Assigned', 'TX_SUB_STATION_METER_POINT', '?', 1, 'RETAIL_METER_ID', NULL,  0, 0);
	INSERT_SYSTEM_LABEL(0, 'Entity Manager', 'Ignore Not Assigned', 'TX_SUB_STATION_METER_POINT', '?', 1, 'SUB_STATION_METER_ID', NULL,  0, 0);

	INSERT_SYSTEM_LABEL(0, 'System', 'Reporting Intervals', '?', '?', 1, '15 Minute', NULL,  0, 0);
	INSERT_SYSTEM_LABEL(0, 'System', 'Reporting Intervals', '?', '?', 2, '30 Minute', NULL,  0, 0);
	INSERT_SYSTEM_LABEL(0, 'System', 'Reporting Intervals', '?', '?', 3, 'Hour', NULL,  0, 0);
	INSERT_SYSTEM_LABEL(0, 'System', 'Reporting Intervals', '?', '?', 4, 'Day', NULL,  0, 0);
	INSERT_SYSTEM_LABEL(0, 'System', 'Reporting Intervals', '?', '?', 5, 'Week', NULL,  0, 0);
	INSERT_SYSTEM_LABEL(0, 'System', 'Reporting Intervals', '?', '?', 6, 'Month', NULL,  0, 0);
	INSERT_SYSTEM_LABEL(0, 'System', 'Reporting Intervals', '?', '?', 7, 'Quarter', NULL,  0, 0);
	INSERT_SYSTEM_LABEL(0, 'System', 'Reporting Intervals', '?', '?', 8, 'Year', NULL,  0, 0);
	
	---------------------
	-- Dispute Management
	---------------------
	-- Dispute Status
	INSERT_SYSTEM_LABEL(0, 'Financial Settlements', 'Dispute Management', 'Dispute Status', '?', 1, 'Open', NULL, 1, 0);
	INSERT_SYSTEM_LABEL(0, 'Financial Settlements', 'Dispute Management', 'Dispute Status', '?', 2, 'Closed', NULL, 0, 0);
	INSERT_SYSTEM_LABEL(0, 'Financial Settlements', 'Dispute Management', 'Dispute Status', '?', 3, 'Withdrawn', NULL, 0, 0);
	-- Process Status	
	INSERT_SYSTEM_LABEL(0, 'Financial Settlements', 'Dispute Management', 'Process Status', '?', 1, 'New', NULL, 1, 0);
	-- Dispute Category	
	INSERT_SYSTEM_LABEL(0, 'Financial Settlements', 'Dispute Management', 'Dispute Category', '?', 1, 'Manual', NULL, 0, 0);
	
COMMIT;
END;
/

prompt Credit_Manager.sql
@@Credit_Manager.sql
SET DEFINE ON	
	--Reset
