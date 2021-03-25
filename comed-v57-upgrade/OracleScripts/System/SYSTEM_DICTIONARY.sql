	-- Uncomment the following line if you wish to completely eliminate previous entries and start from scratch w/ delivered entries
	-- DELETE SYSTEM_DICTIONARY;

DECLARE
	PROCEDURE INSERT_SYSTEM_DICTIONARY
		(
		p_SETTING_NAME IN VARCHAR2,
		p_VALUE IN VARCHAR2,
		p_MODEL_ID IN NUMBER := 0,
		p_MODULE IN VARCHAR2 := '?',
		p_KEY1 IN VARCHAR2 := '?',
		p_KEY2 IN VARCHAR2 := '?',
		p_KEY3 IN VARCHAR2 := '?'
		) AS
	--USED IN INITIAL POPULATION VIA SCRIPT
	BEGIN
	    INSERT INTO SYSTEM_DICTIONARY( MODEL_ID, MODULE, KEY1, KEY2, KEY3, SETTING_NAME, VALUE ) VALUES (p_MODEL_ID, p_MODULE, p_KEY1, p_KEY2, p_KEY3, p_SETTING_NAME, p_VALUE);
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN	NULL;
			WHEN OTHERS THEN	RAISE;
	END INSERT_SYSTEM_DICTIONARY;
BEGIN

	INSERT_SYSTEM_DICTIONARY('FORECASTING_Export_ColHeader_PECO', '0'); 
	INSERT_SYSTEM_DICTIONARY('DELIMITER_TAB', '	'); 
	INSERT_SYSTEM_DICTIONARY('DELIMITER_COMMA', ','); 
	INSERT_SYSTEM_DICTIONARY('DELIMITER_TILDE', '~'); 
	INSERT_SYSTEM_DICTIONARY('DELIMITER_PIPE', '|'); 
	INSERT_SYSTEM_DICTIONARY('DELIMITER_SEMICOLON', ';'); 
	INSERT_SYSTEM_DICTIONARY('DELIMITER_CARET', '^'); 
	INSERT_SYSTEM_DICTIONARY('TX_LOAD_Ancillary_Service_Id', '2'); 
	INSERT_SYSTEM_DICTIONARY('ICAP_Ancillary_Service_Id', '1'); 
	INSERT_SYSTEM_DICTIONARY('Detail Rate ', '$/KWH', 1, 'System', 'Unit'); 
	INSERT_SYSTEM_DICTIONARY('Summary Rate', '$/MWH', 1, 'System', 'Unit'); 
	INSERT_SYSTEM_DICTIONARY('Detail Energy', 'KWH', 1, 'System', 'Unit'); 
	INSERT_SYSTEM_DICTIONARY('Summary Energy', 'MWH', 1, 'System', 'Unit'); 
	INSERT_SYSTEM_DICTIONARY('Interval', 'Hour', 1, 'Forecasting', 'Preferred'); 
	INSERT_SYSTEM_DICTIONARY('Show_Calculate_Supplier_Imbalance', '1'); 
	INSERT_SYSTEM_DICTIONARY('Show_Calculate_Market_Price_Basis', '1'); 
	INSERT_SYSTEM_DICTIONARY('TYPE_OF_POWER', 'Electric', 0, 'SYSTEM'); 
	INSERT_SYSTEM_DICTIONARY('Electric', 'Power', 0, 'Export', 'Default_Units'); 
	INSERT_SYSTEM_DICTIONARY('PECO', '0', 0, 'Export', 'ColHeader'); 
	INSERT_SYSTEM_DICTIONARY('TAB', '	', 0, 'Export', 'DELIMITER'); 
	INSERT_SYSTEM_DICTIONARY('COMMA', ',', 0, 'Export', 'DELIMITER'); 
	INSERT_SYSTEM_DICTIONARY('TILDE', '~', 0, 'Export', 'DELIMITER'); 
	INSERT_SYSTEM_DICTIONARY('PIPE', '|', 0, 'Export', 'DELIMITER'); 
	INSERT_SYSTEM_DICTIONARY('SEMICOLON', ';', 0, 'Export', 'DELIMITER'); 
	INSERT_SYSTEM_DICTIONARY('CARET', '^', 0, 'Export', 'DELIMITER'); 
	INSERT_SYSTEM_DICTIONARY('Load Segmentation Output', '?', 0, 'Export');
	INSERT_SYSTEM_DICTIONARY('Begin_Hour', '7', 0, 'On_Peak'); 
	INSERT_SYSTEM_DICTIONARY('End_Hour', '22', 0, 'On_Peak'); 
	INSERT_SYSTEM_DICTIONARY('Detail Rate', '$/Therm', 2, 'System', 'Unit'); 
	INSERT_SYSTEM_DICTIONARY('Summary Rate', '$/DT', 2, 'System', 'Unit'); 
	INSERT_SYSTEM_DICTIONARY('Detail Energy', 'Therm', 2, 'System', 'Unit'); 
	INSERT_SYSTEM_DICTIONARY('Summary Energy', 'DT', 2, 'System', 'Unit'); 
	INSERT_SYSTEM_DICTIONARY('Interval', 'Day', 2, 'Forecasting', 'Preferred'); 
	INSERT_SYSTEM_DICTIONARY('Service Location and Meter', '0', 0, 'Account Import', 'Replace Dates'); 
	INSERT_SYSTEM_DICTIONARY('Show External Identifier', '0', 0, 'Forecasting', 'Non-Aggregate Enrollment'); 
	INSERT_SYSTEM_DICTIONARY('Show External Identifier', '0', 0, 'Settlement', 'Metered Usage'); 
	INSERT_SYSTEM_DICTIONARY('Show External Identifier', '0', 0, 'Forecasting', 'Validation'); 
	INSERT_SYSTEM_DICTIONARY('Forecasting', 'Update ERCOT Profiles', 1, 'DATA EXCHANGE');
	INSERT_SYSTEM_DICTIONARY('ERCOT UOM', '1', 1);
	INSERT_SYSTEM_DICTIONARY('INTERNAL_UPDATE', 'TRUE', 0, 'Gas Delivery'); 
	INSERT_SYSTEM_DICTIONARY('MARKET_PRICE_BASIS_PRICE', 'TRUE', 0, 'Settlement'); 
	INSERT_SYSTEM_DICTIONARY('LDC_PERSPECTIVE', 'TRUE', 0, 'Gas Delivery');
	INSERT_SYSTEM_DICTIONARY('Forecast', 'F', 0, 'Position and Billing', 'Consumption Code');
	INSERT_SYSTEM_DICTIONARY('Preliminary', 'P', 0, 'Position and Billing', 'Consumption Code');
	INSERT_SYSTEM_DICTIONARY('Final', 'A', 0, 'Position and Billing', 'Consumption Code');
	-- Scheduling Module: Scheduler Tree Configuration: 'A' - Transaction Type, Commodity Type, Receipt Point Type, Transaction Name; 'B' - Transaction Type, Commodity Name, Scheduling Coordinator Name, Transaction Name
	INSERT_SYSTEM_DICTIONARY('Exclude Zero Schedules', '0', 0, 'Scheduling','Accept Into Schedules');
	INSERT_SYSTEM_DICTIONARY('Exclude UFE Values', '0', 0, 'Scheduling','Accept Into Schedules');
	INSERT_SYSTEM_DICTIONARY('Hierarchy', 'A', 1, 'Scheduling', 'Scheduler Tree');
	INSERT_SYSTEM_DICTIONARY('Show External Option', '0', 1, 'Scheduling', 'Scheduler Tree');
	INSERT_SYSTEM_DICTIONARY('ExternalBalanceAll', '0', 1, 'Scheduling', 'Load Balancing');
	INSERT_SYSTEM_DICTIONARY('Allow All Zeroes', '0', 1, 'Scheduling', 'PJM Export');
	INSERT_SYSTEM_DICTIONARY('Use External ID', '0', 1, 'Scheduling', 'PJM Export');
	-- Profiling Module: Show Option UseDatabaseRegression
	INSERT_SYSTEM_DICTIONARY('UseDatabaseRegression', '0', 0, 'Profiling', 'ShowOption'); 
	-- Profiling Module: Show Option LoadResearchRollupInterval
	INSERT_SYSTEM_DICTIONARY('LoadResearchRollupInterval', '0', 0, 'Profiling', 'ShowOption'); 
	-- Profiling Module, Reports tab: Show Optional Parameter text box
	INSERT_SYSTEM_DICTIONARY('ReportsOptionalParameter', '1', 0, 'Profiling', 'ShowOption');
	-- Profiling Module, Batch tab: Allow Meter Modeled WRFs
	INSERT_SYSTEM_DICTIONARY('AllowMeterModeledWRFs', '0', 0, 'Profiling', 'Batch'); 
	-- Profiling Module, Summary tab: 
	INSERT_SYSTEM_DICTIONARY('ShowUsageWRFs', '0', 0, 'Profiling', 'Summary');
	-- Profiling Module, Usage Factors tab: 
	INSERT_SYSTEM_DICTIONARY('Minimum_Days', '7', 0, 'Profiling_Usage', 'Billing_Period');
	INSERT_SYSTEM_DICTIONARY('Maximum_Days', '67', 0, 'Profiling_Usage', 'Billing_Period');
	INSERT_SYSTEM_DICTIONARY('Minimum_Points', '5', 0, 'Profiling_Usage', 'Account Usage WRF');
	-- Profiling Module, LoadResearch tab:
	INSERT_SYSTEM_DICTIONARY('QueryResultSetMembersOnly', '1', 0, 'Profiling', 'LoadResearch'); 
	INSERT_SYSTEM_DICTIONARY('SaveZeroWeightInResultSet', '1', 0, 'Profiling', 'LoadResearch'); 
	-- Profiling module, WRF parameters
	INSERT_SYSTEM_DICTIONARY('Automatic Calendar Assignment', '1', 0, 'Profiling', 'WRF');
	INSERT_SYSTEM_DICTIONARY('Breakpoint Source', 'FCM', 0, 'Profiling', 'WRF');
	INSERT_SYSTEM_DICTIONARY('Breakpoints for WRF Import', '50', 0, 'Profiling', 'WRF');

	INSERT_SYSTEM_DICTIONARY('Min Segments', '2', 0, 'Profiling', 'WRF', 'FCM');
	INSERT_SYSTEM_DICTIONARY('Max Segments', '5', 0, 'Profiling', 'WRF', 'FCM');
	INSERT_SYSTEM_DICTIONARY('m', '3', 0, 'Profiling', 'WRF', 'FCM');
	INSERT_SYSTEM_DICTIONARY('Termination Threshold', '0.01', 0, 'Profiling', 'WRF', 'FCM');
	INSERT_SYSTEM_DICTIONARY('Max Iterations', '30', 0, 'Profiling', 'WRF', 'FCM');
	-- Profiling module, general
	INSERT_SYSTEM_DICTIONARY('Enable Usage Factor Termination', '1', 0, 'Profiling', 'General');

	-- Billing Tab: Default Invoice Titles
	INSERT_SYSTEM_DICTIONARY('Title', 'Electric Service - Monthly Invoice', 1, 'Billing', 'Invoice'); 
	INSERT_SYSTEM_DICTIONARY('Title', 'Gas Service - Monthly Invoice', 2, 'Billing', 'Invoice'); 
	-- Billing Tab: Date Format on Invoices
	INSERT_SYSTEM_DICTIONARY('Date Format', 'YYYY/MM/DD', 0, 'Billing', 'Invoice'); 
	-- Billing Tab: Location for Temporary Invoice RPT files
	INSERT_SYSTEM_DICTIONARY('Temp File Location', '%APPPATH%', 0, 'Billing', 'Invoice');
	INSERT_SYSTEM_DICTIONARY('Default Display Amount', 'CHARGE', 0, 'Billing', 'Invoice');
	INSERT_SYSTEM_DICTIONARY('Category Preference', 'Product', 0, 'Billing', 'Invoice');
	INSERT_SYSTEM_DICTIONARY('E-mail Grouping', 'By Entity', 0, 'Billing', 'Invoice');
	INSERT_SYSTEM_DICTIONARY('E-mail Subject', '${ENTITY}: ${STATEMENT} Invoice for ${BEGIN:dd-mon-yyyy} to ${END:dd-mon-yyyy}', 0, 'Billing', 'Invoice');
	-- The setting name will be the OS USERNAME - if no from address is found for current OS USERNAME, then do a LIKE
	-- This default entry of '%' will then be picked up as default sender address
	INSERT_SYSTEM_DICTIONARY('%', 'Change Before Sending E-mails! <someone@somewhere.com>', 0, 'Billing', 'Invoice', 'E-mail Sender');
	INSERT_SYSTEM_DICTIONARY('Batch Export Invoice Name', '${entity_name}/${statement_type}-${begin_date}-Invoice.${ext}', 0, 'Billing', 'Invoice');
	INSERT_SYSTEM_DICTIONARY('Batch Export Attachment Name', '${entity_name}/${statement_type}-${begin_date}-Attachment${number}.${ext}', 0, 'Billing', 'Invoice');
	-- Billing Tab: Export Report has two special options
	INSERT_SYSTEM_DICTIONARY('Use Invoice For Summary', '0', 0, 'Billing Export', 'Options'); 
	INSERT_SYSTEM_DICTIONARY('Exclude Details', '0', 0, 'Billing Export', 'Options');
	-- Billing Tab: Export Report has special formatting of Transmission charges - the following entries control how they are listed
	INSERT_SYSTEM_DICTIONARY('None', 'Transmission', 0, 'Billing Export', 'Tx Service Type Title'); 
	INSERT_SYSTEM_DICTIONARY('Schedule 1', 'Ancillary 1', 0, 'Billing Export', 'Tx Service Type Title');
	INSERT_SYSTEM_DICTIONARY('Schedule 2', 'Ancillary 2', 0, 'Billing Export', 'Tx Service Type Title');
	INSERT_SYSTEM_DICTIONARY('Schedule 3', 'Ancillary 3', 0, 'Billing Export', 'Tx Service Type Title');
	INSERT_SYSTEM_DICTIONARY('Schedule 4', 'Ancillary 4', 0, 'Billing Export', 'Tx Service Type Title');
	INSERT_SYSTEM_DICTIONARY('Schedule 5', 'Ancillary 5', 0, 'Billing Export', 'Tx Service Type Title');
	INSERT_SYSTEM_DICTIONARY('Schedule 6', 'Ancillary 6', 0, 'Billing Export', 'Tx Service Type Title');
	INSERT_SYSTEM_DICTIONARY('None', 'Trans', 0, 'Billing Export', 'Tx Service Type Label'); 
	INSERT_SYSTEM_DICTIONARY('Schedule 1', 'AS1', 0, 'Billing Export', 'Tx Service Type Label');
	INSERT_SYSTEM_DICTIONARY('Schedule 2', 'AS2', 0, 'Billing Export', 'Tx Service Type Label');
	INSERT_SYSTEM_DICTIONARY('Schedule 3', 'AS3', 0, 'Billing Export', 'Tx Service Type Label');
	INSERT_SYSTEM_DICTIONARY('Schedule 4', 'AS4', 0, 'Billing Export', 'Tx Service Type Label');
	INSERT_SYSTEM_DICTIONARY('Schedule 5', 'AS5', 0, 'Billing Export', 'Tx Service Type Label');
	INSERT_SYSTEM_DICTIONARY('Schedule 6', 'AS6', 0, 'Billing Export', 'Tx Service Type Label');
	-- temp file location of RPT files for Crystal Reports
	INSERT_SYSTEM_DICTIONARY('Temp File Location', '%APPPATH%', 0, 'System', 'Reports');
	INSERT_SYSTEM_DICTIONARY('Find Threshold', '-1', 0, 'System', 'Account');
	INSERT_SYSTEM_DICTIONARY('OpenBrowserCommand', 'rundll32 url.dll,FileProtocolHandler {0}', 0, 'System', 'Commands');
	INSERT_SYSTEM_DICTIONARY('DELETE_EXTERNAL_FORECAST', '0', 0, 'Forecasting'); 
	INSERT_SYSTEM_DICTIONARY('Auto-Commit', '0', 0, 'Entity Manager');
	INSERT_SYSTEM_DICTIONARY('Use Java', 'TRUE', 0, 'Entity Manager');
	INSERT_SYSTEM_DICTIONARY('Referencing Entities Threshold', '5', 0, 'Entity Manager');
	
	INSERT_SYSTEM_DICTIONARY('CUSTOMER', '1', 0, 'Entity Manager', 'Show Find in Tree'); 
	INSERT_SYSTEM_DICTIONARY('INTERCHANGE_CONTRACT', '0', 0, 'Entity Manager', 'Show Find in Tree'); 
	INSERT_SYSTEM_DICTIONARY('RESOURCE_RAMP', '0', 0, 'Entity Manager', 'Show Find in Tree'); 
	INSERT_SYSTEM_DICTIONARY('RESOURCE_CURVE', '0', 0, 'Entity Manager', 'Show Find in Tree'); 
	INSERT_SYSTEM_DICTIONARY('RESOURCE_TRAIT', '0', 0, 'Entity Manager', 'Show Find in Tree'); 
	INSERT_SYSTEM_DICTIONARY('RESOURCE_CASE', '0', 0, 'Entity Manager', 'Show Find in Tree'); 
	INSERT_SYSTEM_DICTIONARY('RESOURCE', '0', 0, 'Entity Manager', 'Show Find in Tree');
	INSERT_SYSTEM_DICTIONARY('ACCOUNT', '0', 0, 'Entity Manager', 'Show Find in Tree');
	INSERT_SYSTEM_DICTIONARY('SERVICE_LOCATION', '0', 0, 'Entity Manager', 'Show Find in Tree');
	INSERT_SYSTEM_DICTIONARY('METER', '0', 0, 'Entity Manager', 'Show Find in Tree');
	INSERT_SYSTEM_DICTIONARY('DER', '0', 0, 'Entity Manager', 'Show Find in Tree');
	INSERT_SYSTEM_DICTIONARY('SERVICE_ZONE', '0', 0, 'Entity Manager', 'Show Find in Tree');
	INSERT_SYSTEM_DICTIONARY('SUB_STATION', '0', 0, 'Entity Manager', 'Show Find in Tree');
	INSERT_SYSTEM_DICTIONARY('SUB_STATION_METER', '0', 0, 'Entity Manager', 'Show Find in Tree');
	INSERT_SYSTEM_DICTIONARY('SUB_STATION_METER_POINT', '0', 0, 'Entity Manager', 'Show Find in Tree');
	INSERT_SYSTEM_DICTIONARY('FEEDER', '0', 0, 'Entity Manager', 'Show Find in Tree');
	INSERT_SYSTEM_DICTIONARY('FEEDER_SEGMENT', '0', 0, 'Entity Manager', 'Show Find in Tree');
	INSERT_SYSTEM_DICTIONARY('Calc on Import', 'N', 0, 'Usage Import', 'Usage Factors'); 
	INSERT_SYSTEM_DICTIONARY('Seasonal', 'N', 0, 'Usage Import', 'Usage Factors'); 
	INSERT_SYSTEM_DICTIONARY('Use Metered Usage?', 'N', 0, 'Usage Import', 'Usage Factors'); 
	INSERT_SYSTEM_DICTIONARY('Years to apply', '1', 0, 'Usage Import', 'Usage Factors'); 
	-- setting for whether or not to show new Contract Selection dialog for using contract as template for new transactions
	INSERT_SYSTEM_DICTIONARY('ShowContractTemplateDialog', '1', 1, 'Scheduling', 'Transaction'); 
	-- ALL MODULES- Default Module Labels
	INSERT_SYSTEM_DICTIONARY('Profiling', 'Profiling', 0, 'Toolbar', 'Label'); 
	INSERT_SYSTEM_DICTIONARY('Forecasting', 'Electric Forecasting', 1, 'Toolbar', 'Label'); 
	INSERT_SYSTEM_DICTIONARY('Forecasting', 'Gas Forecasting', 2, 'Toolbar', 'Label'); 
	INSERT_SYSTEM_DICTIONARY('SCHEDULING', 'Scheduling', 0, 'Toolbar', 'Label'); 
    INSERT_SYSTEM_DICTIONARY('SCHEDULING', 'Electric Scheduling', 1, 'Toolbar', 'Label'); 
    INSERT_SYSTEM_DICTIONARY('SCHEDULING', 'Gas Scheduling', 2, 'Toolbar', 'Label'); 
	INSERT_SYSTEM_DICTIONARY('Settlement', 'Electric Settlement', 1, 'Toolbar', 'Label'); 
	INSERT_SYSTEM_DICTIONARY('Settlement', 'Gas Settlement', 2, 'Toolbar', 'Label'); 
	INSERT_SYSTEM_DICTIONARY('Gas Delivery', 'Gas Delivery', 0, 'Toolbar', 'Label'); 
	INSERT_SYSTEM_DICTIONARY('Billing', 'Electric Position and Billing', 1, 'Toolbar', 'Label'); 
	INSERT_SYSTEM_DICTIONARY('Billing', 'Gas Position and Billing', 2, 'Toolbar', 'Label'); 
	INSERT_SYSTEM_DICTIONARY('Data Setup', 'Data Management', 0, 'Toolbar', 'Label'); 
	INSERT_SYSTEM_DICTIONARY('Quote Management', 'Electric Quote', 1, 'Toolbar', 'Label'); 
	INSERT_SYSTEM_DICTIONARY('Quote Management', 'Gas Quote', 2, 'Toolbar', 'Label');
	INSERT_SYSTEM_DICTIONARY('TrimLeadingCharacters', '0123456789 .', 0, 'Credit Manager');
	INSERT_SYSTEM_DICTIONARY('Use External Identifier', '0', 0, 'Account Import', 'Account');
	-- flags to determine whether or not to show Update ERCOT Profile menu option - default to 0 (off)
	INSERT_SYSTEM_DICTIONARY('Show Option: Update ERCOT Profiles','0',0,'Forecasting','Options');
	INSERT_SYSTEM_DICTIONARY('Show Option: Update ERCOT Profiles','0',0,'Settlement','Options');
	-- SMTP info for sending e-mail from database
	INSERT_SYSTEM_DICTIONARY('Server Host','localhost',0,'System','SMTP');
	INSERT_SYSTEM_DICTIONARY('Server Port','25',0,'System','SMTP');
	INSERT_SYSTEM_DICTIONARY('Client Domain','somewhere.com',0,'System','SMTP');

	--Fri June 10, 2005 03:27:08. - sb - Magnolia changes to make autorefresh and graphs system settings
	INSERT_SYSTEM_DICTIONARY('Auto Refresh Reports','0',0,'System','Reports');
	INSERT_SYSTEM_DICTIONARY('Show Comparison Graph (Bids And Offers)','1',1,'Scheduling','Bids And Offers');
	INSERT_SYSTEM_DICTIONARY('Show Price/Quantity Graph (Bids And Offers)','1',1,'Scheduling','Bids And Offers');
	INSERT_SYSTEM_DICTIONARY('Show Success Dialog on Fill','1',1,'Scheduling','Bids And Offers');
	INSERT_SYSTEM_DICTIONARY('Show Traits Graph (Bids And Offers)','1',1,'Scheduling','Bids And Offers');

	INSERT_SYSTEM_DICTIONARY('AllowTransactionDoubleClick','1',1,'Scheduling');
	INSERT_SYSTEM_DICTIONARY('Use Alias In Grid','0',0,'Product','Market Prices');
        INSERT_SYSTEM_DICTIONARY('Hierarchy', 'A', 0, 'Product', 'Market Prices');

	--These settings dictate how column prefixes map to other tables- for instance how should the column
	--named POD_ID on table MARKET_PRICE map to another table (in lieu of foreign keys)
	-- No KEY3 means global mapping (that prefix regardless of owner table), otherwise KEY3 indicates
	-- the owner table (MARKET_PRICE in the above example)
	INSERT_SYSTEM_DICTIONARY('POD', 'SERVICE_POINT', 0, 'System', 'System Realm', 'Domain Aliases');
	INSERT_SYSTEM_DICTIONARY('POR', 'SERVICE_POINT', 0, 'System', 'System Realm', 'Domain Aliases');
	INSERT_SYSTEM_DICTIONARY('SOURCE', 'SERVICE_POINT', 0, 'System', 'System Realm', 'Domain Aliases');
	INSERT_SYSTEM_DICTIONARY('SINK', 'SERVICE_POINT', 0, 'System', 'System Realm', 'Domain Aliases');
	INSERT_SYSTEM_DICTIONARY('ZOD', 'SERVICE_ZONE', 0, 'System', 'System Realm', 'Domain Aliases');
	INSERT_SYSTEM_DICTIONARY('ZOR', 'SERVICE_ZONE', 0, 'System', 'System Realm', 'Domain Aliases');
	INSERT_SYSTEM_DICTIONARY('COMMODITY', 'IT_COMMODITY', 0, 'System', 'System Realm', 'Domain Aliases');
	INSERT_SYSTEM_DICTIONARY('PURCHASER', 'PSE', 0, 'System', 'System Realm', 'Domain Aliases');
	INSERT_SYSTEM_DICTIONARY('SELLER', 'PSE', 0, 'System', 'System Realm', 'Domain Aliases');
	INSERT_SYSTEM_DICTIONARY('TRAIT_GROUP', 'TRANSACTION_TRAIT_GROUP', 0, 'System', 'System Realm', 'Domain Aliases');
	INSERT_SYSTEM_DICTIONARY('TX_SERVICE_TYPE','SERVICE_TYPE',0,'System','System Realm','Domain Aliases');
	INSERT_SYSTEM_DICTIONARY('BASE_COMPONENT','COMPONENT',0,'System','System Realm','Domain Aliases');
	INSERT_SYSTEM_DICTIONARY('BASE_LIMIT','CONTRACT_LIMIT',0,'System','System Realm','Domain Aliases');
	INSERT_SYSTEM_DICTIONARY('LMP_COMMODITY','IT_COMMODITY',0,'System','System Realm','Domain Aliases');
	INSERT_SYSTEM_DICTIONARY('BASE_LMP_COMMODITY','IT_COMMODITY',0,'System','System Realm','Domain Aliases');
	INSERT_SYSTEM_DICTIONARY('LMP_BASE_COMMODITY','IT_COMMODITY',0,'System','System Realm','Domain Aliases');
	INSERT_SYSTEM_DICTIONARY('RESOURCE','SUPPLY_RESOURCE',0,'System','System Realm','Domain Aliases');
	INSERT_SYSTEM_DICTIONARY('STATION','WEATHER_STATION',0,'System','System Realm','Domain Aliases');
	INSERT_SYSTEM_DICTIONARY('ORIGIN','SERVICE_POINT',0,'System','System Realm','Domain Aliases');
	INSERT_SYSTEM_DICTIONARY('DESTINATION','SERVICE_POINT',0,'System','System Realm','Domain Aliases');
	INSERT_SYSTEM_DICTIONARY('COMPOSITE_PARAMETER','WEATHER_PARAMETER',0,'System','System Realm','Domain Aliases');
	INSERT_SYSTEM_DICTIONARY('COMPOSITE_STATION','WEATHER_STATION',0,'System','System Realm','Domain Aliases');
	INSERT_SYSTEM_DICTIONARY('COMPOSITE_MARKET_PRICE','MARKET_PRICE',0,'System','System Realm','Domain Aliases');
	INSERT_SYSTEM_DICTIONARY('COMPOSITE_COMPONENT','COMPONENT',0,'System','System Realm','Domain Aliases');
	INSERT_SYSTEM_DICTIONARY('PROFILE_LIBRARY', 'LOAD_PROFILE_LIBRARY', 0, 'System', 'System Realm', 'Domain Aliases');

	INSERT_SYSTEM_DICTIONARY('BILLING_ENTITY', 'PSE', 0, 'System', 'System Realm', 'Domain Aliases', 'INTERCHANGE_CONTRACT');
	INSERT_SYSTEM_DICTIONARY('CONTRACT', 'INTERCHANGE_CONTRACT', 0, 'System', 'System Realm', 'Domain Aliases', 'INTERCHANGE_CONTRACT');
	INSERT_SYSTEM_DICTIONARY('CONTRACT', 'INTERCHANGE_CONTRACT', 0, 'System', 'System Realm', 'Domain Aliases', 'INTERCHANGE_TRANSACTION');

	INSERT_SYSTEM_DICTIONARY('PARAMETER_1','WEATHER_PARAMETER',0,'System','System Realm','Domain Aliases', 'HEAT_RATE_CURVE');
	INSERT_SYSTEM_DICTIONARY('PARAMETER_2','WEATHER_PARAMETER',0,'System','System Realm','Domain Aliases', 'HEAT_RATE_CURVE');
	INSERT_SYSTEM_DICTIONARY('PARAMETER_3','WEATHER_PARAMETER',0,'System','System Realm','Domain Aliases', 'HEAT_RATE_CURVE');

	INSERT_SYSTEM_DICTIONARY('EDC_SYSTEM_LOAD', 'SYSTEM_LOAD', 0, 'System', 'System Realm', 'Domain Aliases', 'ENERGY_DISTRIBUTION_COMPANY');
	INSERT_SYSTEM_DICTIONARY('EDC_MARKET_PRICE', 'MARKET_PRICE', 0, 'System', 'System Realm', 'Domain Aliases', 'ENERGY_DISTRIBUTION_COMPANY');
	INSERT_SYSTEM_DICTIONARY('EDC_HOLIDAY_SET', 'HOLIDAY_SET', 0, 'System', 'System Realm', 'Domain Aliases', 'ENERGY_DISTRIBUTION_COMPANY');
	INSERT_SYSTEM_DICTIONARY('EDC_SC', 'SC', 0, 'System', 'System Realm', 'Domain Aliases', 'ENERGY_DISTRIBUTION_COMPANY');

	INSERT_SYSTEM_DICTIONARY('TX_TRANSACTION','EXTERNAL_TRANSACTION',0,'System','System Realm','Domain Aliases', 'INTERCHANGE_TRANSACTION_EXT');
	INSERT_SYSTEM_DICTIONARY('LINK_TRANSACTION','EXTERNAL_TRANSACTION',0,'System','System Realm','Domain Aliases', 'INTERCHANGE_TRANSACTION_EXT');

	INSERT_SYSTEM_DICTIONARY('TX_TRANSACTION','TRANSACTION',0,'System','System Realm','Domain Aliases', 'INTERCHANGE_TRANSACTION');
	INSERT_SYSTEM_DICTIONARY('LINK_TRANSACTION','TRANSACTION',0,'System','System Realm','Domain Aliases', 'INTERCHANGE_TRANSACTION');

	INSERT_SYSTEM_DICTIONARY('PARENT_GEOGRAPHY', 'GEOGRAPHY', 0, 'System', 'System Realm', 'Domain Aliases', 'GEOGRAPHY');

	INSERT_SYSTEM_DICTIONARY('PROFILE_STATION', 'WEATHER_STATION', 0, 'System', 'System Realm', 'Domain Aliases', 'LOAD_PROFILE');
	INSERT_SYSTEM_DICTIONARY('PROFILE_TEMPLATE', 'TEMPLATE', 0, 'System', 'System Realm', 'Domain Aliases', 'LOAD_PROFILE');
	INSERT_SYSTEM_DICTIONARY('PROFILE_SOURCE', 'SERVICE_POINT', 0, 'System', 'System Realm', 'Domain Aliases', 'LOAD_PROFILE');

	INSERT_SYSTEM_DICTIONARY('SC_MARKET_PRICE', 'MARKET_PRICE', 0, 'System', 'System Realm', 'Domain Aliases', 'SCHEDULE_COORDINATOR');

	INSERT_SYSTEM_DICTIONARY('EVENT','DR_EVENT',0,'System','System Realm','Domain Aliases', 'DR_EVENT');
	INSERT_SYSTEM_DICTIONARY('EVENT','SYSTEM_EVENT',0,'System','System Realm','Domain Aliases', 'COMPONENT');
	INSERT_SYSTEM_DICTIONARY('EVENT','SYSTEM_EVENT',0,'System','System Realm','Domain Aliases', 'SYSTEM_EVENT');

	-- Settings for Metered Usage Find Dialog 
	INSERT_SYSTEM_DICTIONARY('Find Threshold', '-1', 0, 'System', 'Metered Usage');
	INSERT_SYSTEM_DICTIONARY('Max Find Limit', '1000', 0, 'System', 'Metered Usage');

    -- New settings for MightyGrid sorting
    INSERT_SYSTEM_DICTIONARY('Allow 3rd Toggle Option to Reset Sort','TRUE',0,'System','Grids');
    INSERT_SYSTEM_DICTIONARY('Allow Multi Column Sort','TRUE',0,'System','Grids');
    INSERT_SYSTEM_DICTIONARY('Reverse Multi Column Sort Priority','TRUE',0,'System','Grids');
    INSERT_SYSTEM_DICTIONARY('Allow Sort After Edit','FALSE',0,'System','Grids');
	
	-- New setting for MightyGrid copy
	INSERT_SYSTEM_DICTIONARY('Copy Headers On Select','TRUE',0,'System','Grids');
    
    -- New settings for Window Management
    INSERT_SYSTEM_DICTIONARY('Common.EntityManager','FALSE',0,'System','Dialogs','Modality Settings');
    INSERT_SYSTEM_DICTIONARY('Common.DataExchange','TRUE',0,'System','Dialogs','Modality Settings');
    INSERT_SYSTEM_DICTIONARY('Common.SystemSettings','TRUE',0,'System','Dialogs','Modality Settings');
    INSERT_SYSTEM_DICTIONARY('LOGS','FALSE',0,'System','Dialogs','Modality Settings');
    INSERT_SYSTEM_DICTIONARY('BACKGROUND_JOBS','FALSE',0,'System','Dialogs','Modality Settings');
    INSERT_SYSTEM_DICTIONARY('PRODUCTS_AND_RATES','FALSE',0,'System','Dialogs','Modality Settings');
    
    -- New settings for System Views
    INSERT_SYSTEM_DICTIONARY('Refresh On Activate', 'FALSE',0,'System','System Views');

     --- Settings for remote notifications
    INSERT_SYSTEM_DICTIONARY('Alert Email Prefix', '[Ventyx Alert]', 0, 'System', 'Alerts', '?', '?');
    INSERT_SYSTEM_DICTIONARY('E-mail Sender', 'someone@something.com', 0, 'System', 'Alerts', '?', '?');

    -- Settings for security - how many minutes can elapse before re-querying current user's roles?
    INSERT_SYSTEM_DICTIONARY('RoleStalenessLimit','5',0,'System','security');

    -- Settings for MM.START_IMPORT
    INSERT_SYSTEM_DICTIONARY('Full Access For File Imports', '0', 0, 'MarketExchange');

    -- URL for Market Exchange
    INSERT_SYSTEM_DICTIONARY('URL', 'http://app-server/mex/Switchboard/invoke', 0, 'MarketExchange');

	-- Calculation Process Behavior
	INSERT_SYSTEM_DICTIONARY('Serialize Calculations', 'Y', 0, 'Calculation Process', 'Settings'); 
	INSERT_SYSTEM_DICTIONARY('Default Commit Frequency', 'AUTO', 0, 'Calculation Process', 'Settings');

	-- Formula Charge Behavior (both billing fml charges and calculation process components)
	INSERT_SYSTEM_DICTIONARY('CancelOnNullInput', 'N', 0, 'Calculation Process', 'Settings', 'Errors');
	INSERT_SYSTEM_DICTIONARY('CancelOnFormulaError', 'Y', 0, 'Calculation Process', 'Settings', 'Errors');
	INSERT_SYSTEM_DICTIONARY('CancelOnMissingOutput', 'Y', 0, 'Calculation Process', 'Settings', 'Errors');
	INSERT_SYSTEM_DICTIONARY('CancelOnTooManyOutputs', 'Y', 0, 'Calculation Process', 'Settings', 'Errors');
	INSERT_SYSTEM_DICTIONARY('CancelOnOutputIntervalMismatch', 'Y', 0, 'Calculation Process', 'Settings', 'Errors');
	
	-- Default Duration (in days) before an Alert expires.
	INSERT_SYSTEM_DICTIONARY('Default Duration', '7', 0, 'System', 'Alerts');
	
	-- Process Log Behavior
	INSERT_SYSTEM_DICTIONARY('Keep Event Detail', 'Y', 0, 'System', 'Logging');
	INSERT_SYSTEM_DICTIONARY('Persist Trace', 'N', 0, 'System', 'Logging');
	INSERT_SYSTEM_DICTIONARY('Maximum Trace Size', '4194304', 0, 'System', 'Logging');

	-- GA settings
	INSERT_SYSTEM_DICTIONARY('Local Time Zone','EDT', 0, 'System', 'GA Settings', 'General');
	INSERT_SYSTEM_DICTIONARY('CUT Time Zone','EST', 0, 'System', 'GA Settings', 'General');
	INSERT_SYSTEM_DICTIONARY('Gas Unit of Measurement','thm', 0, 'System', 'GA Settings', 'General');
	INSERT_SYSTEM_DICTIONARY('Electric Unit of Measurement','kwh', 0, 'System', 'GA Settings', 'General');
	INSERT_SYSTEM_DICTIONARY('Gas Unit of Measurement - Schedules','Dth', 0, 'System', 'GA Settings', 'General');
	INSERT_SYSTEM_DICTIONARY('Electric Unit of Measurement - Schedules','Mwh', 0, 'System', 'GA Settings', 'General');
	INSERT_SYSTEM_DICTIONARY('Customer Usage WRF Min.Points', '5', 0, 'System', 'GA Settings', 'Profiling');
	INSERT_SYSTEM_DICTIONARY('Wind Chill Temp.Threshold', '0', 0, 'System', 'GA Settings', 'Profiling');
	INSERT_SYSTEM_DICTIONARY('DST Spring-Ahead Option', 'A', 0, 'System', 'GA Settings', 'General');
	INSERT_SYSTEM_DICTIONARY('DST Fall-Back Option', 'A', 0, 'System', 'GA Settings', 'General');
	INSERT_SYSTEM_DICTIONARY('Single Service Point ID', '0', 0, 'System', 'GA Settings', 'Forecast/Settlement');
	INSERT_SYSTEM_DICTIONARY('Aggregate Billed Usage Option', 'ENR', 0, 'System', 'GA Settings', 'Forecast/Settlement');
	INSERT_SYSTEM_DICTIONARY('Default Model', '1', 0, 'System', 'GA Settings', 'General');
	INSERT_SYSTEM_DICTIONARY('Invoice Line Item Option', '2', 0, 'System', 'GA Settings', 'Billing');
	INSERT_SYSTEM_DICTIONARY('Cast Commit Threshold', '6', 0, 'System', 'GA Settings', 'Forecast/Settlement');
	INSERT_SYSTEM_DICTIONARY('Enforce Unique Names', 'TRUE', 0, 'System', 'GA Settings', 'General');
	INSERT_SYSTEM_DICTIONARY('Use Load Profile Standard Day', 'TRUE', 0, 'System', 'GA Settings', 'Profiling');
	INSERT_SYSTEM_DICTIONARY('Usage Factor Per Unit Option', 'TRUE', 0, 'System', 'GA Settings', 'Forecast/Settlement');
	INSERT_SYSTEM_DICTIONARY('Use Interval Usage in Backcast', 'TRUE', 0, 'System', 'GA Settings', 'Forecast/Settlement');
	INSERT_SYSTEM_DICTIONARY('Enable External Meter Access', 'FALSE', 0, 'System', 'GA Settings', 'Forecast/Settlement');
	INSERT_SYSTEM_DICTIONARY('Enable Non-Production Profile Message', 'TRUE', 0, 'System', 'GA Settings', 'Forecast/Settlement');
	INSERT_SYSTEM_DICTIONARY('Enforce Production Profile Use', 'TRUE', 0, 'System', 'GA Settings', 'Forecast/Settlement');
	INSERT_SYSTEM_DICTIONARY('Enable Supply Schedule Types', 'TRUE', 0, 'System', 'GA Settings', 'Scheduling');
	INSERT_SYSTEM_DICTIONARY('Apply Prior Bill Charges', 'TRUE', 0, 'System', 'GA Settings', 'Billing');
	INSERT_SYSTEM_DICTIONARY('Enable ESP-Pool Assignment', 'TRUE', 0, 'System', 'GA Settings', 'Forecast/Settlement');
	INSERT_SYSTEM_DICTIONARY('Enable PSE-ESP Assignment', 'TRUE', 0, 'System', 'GA Settings', 'Forecast/Settlement');
	INSERT_SYSTEM_DICTIONARY('Enable Backcast Adj.Schedules', 'FALSE', 0, 'System', 'GA Settings', 'Forecast/Settlement');
	INSERT_SYSTEM_DICTIONARY('Enable System UFE Load Check', 'FALSE', 0, 'System', 'GA Settings', 'Forecast/Settlement');
	INSERT_SYSTEM_DICTIONARY('Enable Wind-Chill Temp.Check', 'FALSE', 0, 'System', 'GA Settings', 'Profiling');
	INSERT_SYSTEM_DICTIONARY('Enable Zero Minimum Schedule', 'FALSE', 0, 'System', 'GA Settings', 'Forecast/Settlement');
	INSERT_SYSTEM_DICTIONARY('Enable Non-Agg.UFE Settlement', 'TRUE', 0, 'System', 'GA Settings', 'Forecast/Settlement');
	INSERT_SYSTEM_DICTIONARY('Enable Agg.Post-ESP Assignment', 'FALSE', 0, 'System', 'GA Settings', 'Forecast/Settlement');
	INSERT_SYSTEM_DICTIONARY('Enable Service Retention', 'TRUE', 0, 'System', 'GA Settings', 'Forecast/Settlement');
	INSERT_SYSTEM_DICTIONARY('Enable RTM Process Mode', 'FALSE', 0, 'System', 'GA Settings', 'Forecast/Settlement');
	INSERT_SYSTEM_DICTIONARY('Enable Customer Model', 'FALSE', 0, 'System', 'GA Settings', 'Customer');
	INSERT_SYSTEM_DICTIONARY('Enable Customer Cast', 'FALSE', 0, 'System', 'GA Settings', 'Customer');
	INSERT_SYSTEM_DICTIONARY('Enable Load Schedule Delete', 'TRUE', 0, 'System', 'GA Settings', 'Forecast/Settlement');
	INSERT_SYSTEM_DICTIONARY('Enable Sched.Group Assignment', 'TRUE', 0, 'System', 'GA Settings', 'Forecast/Settlement');
	INSERT_SYSTEM_DICTIONARY('Enable Single Service Point', 'FALSE', 0, 'System', 'GA Settings', 'Forecast/Settlement');
	INSERT_SYSTEM_DICTIONARY('Enable Weather Index Save Calcs', 'TRUE', 0, 'System', 'GA Settings', 'Profiling');
	INSERT_SYSTEM_DICTIONARY('Enable Zero-Fill Agg.Enrollment ', 'TRUE', 0, 'System', 'GA Settings', 'Forecast/Settlement');
	INSERT_SYSTEM_DICTIONARY('Enable Consumption End Date', 'TRUE', 0, 'System', 'GA Settings', 'Forecast/Settlement');
	INSERT_SYSTEM_DICTIONARY('Enable Schedule Gross Up', 'FALSE', 0, 'System', 'GA Settings', 'Forecast/Settlement');
	INSERT_SYSTEM_DICTIONARY('Enable Reverse Sign Invoices', 'FALSE', 0, 'System', 'GA Settings', 'Billing');
	INSERT_SYSTEM_DICTIONARY('Enable Actual Losses Recalc.', 'FALSE', 0, 'System', 'GA Settings', 'Forecast/Settlement');
	INSERT_SYSTEM_DICTIONARY('Enable Aggregate Pool Model', 'FALSE', 0, 'System', 'GA Settings', 'Forecast/Settlement');
	INSERT_SYSTEM_DICTIONARY('Enable Calendar Triggers', 'TRUE', 0, 'System', 'GA Settings', 'Profiling');
	INSERT_SYSTEM_DICTIONARY('Version Area Load', 'FALSE', 0, 'System', 'GA Settings', 'Version');
	INSERT_SYSTEM_DICTIONARY('Version Profile', 'FALSE', 0, 'System', 'GA Settings', 'Version');
	INSERT_SYSTEM_DICTIONARY('Version Forecast', 'FALSE', 0, 'System', 'GA Settings', 'Version');
	INSERT_SYSTEM_DICTIONARY('Version Backcast', 'FALSE', 0, 'System', 'GA Settings', 'Version');
	INSERT_SYSTEM_DICTIONARY('Version Actual', 'FALSE', 0, 'System', 'GA Settings', 'Version');
	INSERT_SYSTEM_DICTIONARY('Version Schedule', 'FALSE', 0, 'System', 'GA Settings', 'Version');
	INSERT_SYSTEM_DICTIONARY('Version Statement', 'FALSE', 0, 'System', 'GA Settings', 'Version');
	INSERT_SYSTEM_DICTIONARY('Version Market Price', 'FALSE', 0, 'System', 'GA Settings', 'Version');
	INSERT_SYSTEM_DICTIONARY('Version Aggregate Account Service', 'FALSE', 0, 'System', 'GA Settings', 'Version');
	INSERT_SYSTEM_DICTIONARY('Version Aggregate Ancillary Service', 'FALSE', 0, 'System', 'GA Settings', 'Version');
	INSERT_SYSTEM_DICTIONARY('Version Shadow Settlement', 'FALSE', 0, 'System', 'GA Settings', 'Version');
	INSERT_SYSTEM_DICTIONARY('Version Consumption', 'FALSE', 0, 'System', 'GA Settings', 'Version');
	INSERT_SYSTEM_DICTIONARY('Version Customer Usage WRF', 'FALSE', 0, 'System', 'GA Settings', 'Version');
	INSERT_SYSTEM_DICTIONARY('Enable Run-Time Profile Cache', 'TRUE', 0, 'System', 'GA Settings', 'Forecast/Settlement');
	INSERT_SYSTEM_DICTIONARY('Enable Is Wholesale Lookup', 'TRUE', 0, 'System', 'GA Settings', 'Forecast/Settlement');
	INSERT_SYSTEM_DICTIONARY('Enable Holidays', 'TRUE', 0, 'System', 'GA Settings', 'General');
	INSERT_SYSTEM_DICTIONARY('Enable Cast Cache Flush', 'TRUE', 0, 'System', 'GA Settings', 'Forecast/Settlement');
	INSERT_SYSTEM_DICTIONARY('Cast Cache Flush Threshold', '10000', 0, 'System', 'GA Settings', 'Forecast/Settlement');
	INSERT_SYSTEM_DICTIONARY('Enable External Cast Delete', 'FALSE', 0, 'System', 'GA Settings', 'Forecast/Settlement');
	INSERT_SYSTEM_DICTIONARY('Store Customer Service Load Forecast', 'FALSE', 0, 'System', 'GA Settings', 'Customer');
	INSERT_SYSTEM_DICTIONARY('Store Customer Service Load Backcast', 'TRUE', 0, 'System', 'GA Settings', 'Customer');
	INSERT_SYSTEM_DICTIONARY('Enable Reset UFE Participation', 'TRUE', 0, 'System', 'GA Settings', 'Forecast/Settlement');
	INSERT_SYSTEM_DICTIONARY('Enable Constant EDC Loss Factor', 'FALSE', 0, 'System', 'GA Settings', 'Forecast/Settlement');
	INSERT_SYSTEM_DICTIONARY('Constant EDC Loss Factor Value', 'EDC', 0, 'System', 'GA Settings', 'Forecast/Settlement');
	INSERT_SYSTEM_DICTIONARY('Direct-Oracle-Login Mode', 'FALSE', 0, 'System', 'GA Settings', 'Security');
	INSERT_SYSTEM_DICTIONARY('Log Events for Logon/Logoff', 'TRUE', 0, 'System', 'GA Settings', 'Security');
	INSERT_SYSTEM_DICTIONARY('Enable Summary Only Mode', 'FALSE', 0, 'System', 'GA Settings', 'Forecast/Settlement');
	INSERT_SYSTEM_DICTIONARY('Retail Determinant Date Threshold', '0', 0, 'System', 'GA Settings', 'Financial Settlement');	
	INSERT_SYSTEM_DICTIONARY('External Proxy Day Data', 'FALSE', 0, 'System', 'GA Settings', 'Forecast/Settlement');
	INSERT_SYSTEM_DICTIONARY('CSB Is Subdaily', 'FALSE', 0, 'System', 'GA Settings', 'General');
	INSERT_SYSTEM_DICTIONARY('MDR Backend', 'FALSE', 0, 'System', 'GA Settings', 'General');
	
	-- Date/Time formats used by TEXT_UTIL API
	INSERT_SYSTEM_DICTIONARY('Date Format', 'YYYY-MM-DD', 0, 'System', 'Logging');
	INSERT_SYSTEM_DICTIONARY('Time Format', 'YYYY-MM-DD HH24:MI:SS', 0, 'System', 'Logging');
	INSERT_SYSTEM_DICTIONARY('Timestamp Format', 'YYYY-MM-DD HH24:MI:SSXFF', 0, 'System', 'Logging');
	INSERT_SYSTEM_DICTIONARY('Timestamp with Time Zone Format', 'YYYY-MM-DD HH24:MI:SSXFF TZR', 0, 'System', 'Logging');
	
	-- Settings that control whether or not the user can edit existing transactions or fill schedules from transaction blotter reports, and other Scheduling settings
	INSERT_SYSTEM_DICTIONARY('Can Edit Existing Rows', 'Yes', 1, 'Scheduling', 'Transactions', 'TRANSACTIONS_BLOTTER_REPORT');
	INSERT_SYSTEM_DICTIONARY('Can Fill Existing Rows', 'Yes', 1, 'Scheduling', 'Transactions', 'TRANSACTIONS_BLOTTER_REPORT');
	INSERT_SYSTEM_DICTIONARY('Include External', '0', 1, 'Scheduling', 'Scheduler');

	-- Settings related to running Background Jobs
	INSERT_SYSTEM_DICTIONARY('Queued Jobs Warning Threshold', '1', 0, 'System', 'Background Jobs', 'Dialogs');
	INSERT_SYSTEM_DICTIONARY('Show Warning Before Queuing Job', '0', 0, 'System', 'Background Jobs', 'Dialogs');
	INSERT_SYSTEM_DICTIONARY('Show Message After Queuing Job', '1', 0, 'System', 'Background Jobs', 'Dialogs');
	INSERT_SYSTEM_DICTIONARY('Days Old', '31', 0, 'System', 'Background Jobs', 'Lob Staging Cleanup');

	-- Settings related to the Reactor
	INSERT_SYSTEM_DICTIONARY('Num Seconds to Wait for Lock', NULL, 0, 'System', 'Reactor');
	INSERT_SYSTEM_DICTIONARY('Continue on Lock Timeout', '0', 0, 'System', 'Reactor');
	INSERT_SYSTEM_DICTIONARY('Disable Lockdown', '0', 0, 'System', 'Reactor');
	
	-- Event retention policy - Default behavior
	INSERT_SYSTEM_DICTIONARY('Event Retention Policy', '0', 0, 'System', 'Audit Trail');
	INSERT_SYSTEM_DICTIONARY('Fatal', '0', 0, 'System', 'Logging', 'Event Retention Policy', '%');
	INSERT_SYSTEM_DICTIONARY('Error', '0', 0, 'System', 'Logging', 'Event Retention Policy', '%');
	INSERT_SYSTEM_DICTIONARY('Warning', '0', 0, 'System', 'Logging', 'Event Retention Policy', '%');
	INSERT_SYSTEM_DICTIONARY('Notice', '0', 0, 'System', 'Logging', 'Event Retention Policy', '%');
	INSERT_SYSTEM_DICTIONARY('Info', '14', 0, 'System', 'Logging', 'Event Retention Policy', '%');
	INSERT_SYSTEM_DICTIONARY('More Info', '14', 0, 'System', 'Logging', 'Event Retention Policy', '%');
	INSERT_SYSTEM_DICTIONARY('All Info', '14', 0, 'System', 'Logging', 'Event Retention Policy', '%');
	INSERT_SYSTEM_DICTIONARY('Debug', '7', 0, 'System', 'Logging', 'Event Retention Policy', '%');
	INSERT_SYSTEM_DICTIONARY('More Debug', '3', 0, 'System', 'Logging', 'Event Retention Policy', '%');
	INSERT_SYSTEM_DICTIONARY('Max Debug', '3', 0, 'System', 'Logging', 'Event Retention Policy', '%');

	-- Data Locking
	INSERT_SYSTEM_DICTIONARY('Data Locked Behavior', 'Error', 0, 'Scheduling', 'Schedule Fill');
	INSERT_SYSTEM_DICTIONARY('Data Locked Behavior', 'Error', 0, 'Calculation Process', 'Settings');
	INSERT_SYSTEM_DICTIONARY('SCHEDULE_STATE', '1,2', 0, 'System', 'Data Locking', 'Column Enumeration');
	INSERT_SYSTEM_DICTIONARY('STATEMENT_STATE', '1,2', 0, 'System', 'Data Locking', 'Column Enumeration');
	INSERT_SYSTEM_DICTIONARY('PRICE_CODE', '''F'',''P'',''A''', 0, 'System', 'Data Locking', 'Column Enumeration');
	INSERT_SYSTEM_DICTIONARY('METER_CODE', '''F'',''P'',''A''', 0, 'System', 'Data Locking', 'Column Enumeration');
	INSERT_SYSTEM_DICTIONARY('CONTEXT_ENTITY_ID', '#select column_value from table(cast(calc_engine.get_entity_ids_for_process(${ENTITY_ID}, ${BEGIN_DATE}, ${END_DATE}) as number_collection))', 0, 'System', 'Data Locking', 'Column Enumeration', 'CALCULATION_RUN');

	-- Data Import 
	INSERT_SYSTEM_DICTIONARY('Date Format', 'MM/DD/YYYY', 0, 'Data Import');
	INSERT_SYSTEM_DICTIONARY('Load Settlement Profile', '1', 0, 'Data Import', 'Import Interval Usage Data');
	INSERT_SYSTEM_DICTIONARY('Calendar Profile Begin Date', '2000-01-01', 0, 'Data Import', 'Import Profile');
	INSERT_SYSTEM_DICTIONARY('Calendar Profile End Date', '<None>', 0, 'Data Import', 'Import Profile');
	INSERT_SYSTEM_DICTIONARY('Profile Status', 'Production', 0, 'Data Import', 'Import Profile');

	-- Account Sync
	INSERT_SYSTEM_DICTIONARY('Delete String', '<>', 0, 'Data Import', 'Account Sync');

	-- Configurable Row Limits
	INSERT_SYSTEM_DICTIONARY('Default Row Limit', '100000', 0, 'System');

	-- Demand Response Running Rate Window
	INSERT_SYSTEM_DICTIONARY('Num Events for Running Rate', '30', 0, 'Load Management', 'Demand Response');
	
	-- DER Capacity Forecasting and DERAD
	INSERT_SYSTEM_DICTIONARY('Disable Parallel Excecution', 'N', 0, 'DER Capacity Forecast');
	INSERT_SYSTEM_DICTIONARY('Load Shape Result Days', '0', 0, 'DER Capacity Forecast', 'Periodic Commit');
	INSERT_SYSTEM_DICTIONARY('Loss Factor Result Days', '0', 0, 'DER Capacity Forecast', 'Periodic Commit');
	INSERT_SYSTEM_DICTIONARY('Hits Remaining Result Days', '0', 0, 'DER Capacity Forecast', 'Periodic Commit');
	INSERT_SYSTEM_DICTIONARY('DER Daily Result Records', '0', 0, 'DER Capacity Forecast', 'Periodic Commit');
	INSERT_SYSTEM_DICTIONARY('External Forecast as MW', 'Y', 0, 'Load Management', 'Demand Response');
	INSERT_SYSTEM_DICTIONARY('External Results as MW', 'Y', 0, 'Load Management', 'Demand Response');
	INSERT_SYSTEM_DICTIONARY('Event Schedule as MW', 'Y', 0, 'Load Management', 'Demand Response');
	
	-- Entity Identifier. The valid values could be 'Name', 'Alias', 'External Identifier' or the External System
	INSERT_SYSTEM_DICTIONARY('Entity Identifier', 'Name', 0, 'Load Management', 'Demand Response', 'Event Dispatch Message');
	INSERT_SYSTEM_DICTIONARY('Use OpenADR Payload', 'TRUE', 0, 'Load Management', 'Demand Response', 'Event Dispatch Message');
	INSERT_SYSTEM_DICTIONARY('End Point URL', 'https://<hostname>(:port)/(prefix)/OpenADR2/Simple/2.0b/<service>', 0, 'Load Management', 'Demand Response', 'Event Dispatch Message');
	
	-- Sched Management Integration
	INSERT_SYSTEM_DICTIONARY('Import VPP External to Schedule', 'TRUE', 0, 'Load Management', 'Demand Response');
	
	-- OpenADR poll
	INSERT_SYSTEM_DICTIONARY('OpenADR Poll URL', 'https://<hostname>(:port)/(prefix)/OpenADR2/Simple/2.0b/oadrPoll', 0, 'Load Management', 'Demand Response');

	-- System-Date-Time population parameters
	INSERT_SYSTEM_DICTIONARY('Fiscal Year End', '09/30', 0, 'System', 'System-Date-Time');
	INSERT_SYSTEM_DICTIONARY('Custom Format - Time', 'HH24:MI', 0, 'System', 'System-Date-Time');
	INSERT_SYSTEM_DICTIONARY('Custom Format - Date', 'MM/DD/YYYY', 0, 'System', 'System-Date-Time');
	INSERT_SYSTEM_DICTIONARY('Custom Format - Weekend', ' WE ', 0, 'System', 'System-Date-Time');
	INSERT_SYSTEM_DICTIONARY('Custom Format - Weekday', ' WD ', 0, 'System', 'System-Date-Time');
	INSERT_SYSTEM_DICTIONARY('Minimum Interval', 'MI15', 0, 'System', 'System-Date-Time');
	
	-- System uses PSE's schedule configuration when accepting schedules
	INSERT_SYSTEM_DICTIONARY('Use PSE for Schedule Config', 'FALSE', 0, 'Load Management');
	
	-- System accepts non-incumbent entity load
	INSERT_SYSTEM_DICTIONARY('Accept Non-Incumbent Entity Load', 'FALSE', 0, 'Load Management');

	-- system messaging
	INSERT_SYSTEM_DICTIONARY('Disable Message Notifications', 'FALSE', 0, 'System', 'Messaging');
	INSERT_SYSTEM_DICTIONARY('Poll Rate', '3', 0, 'System', 'Messaging');

	-- Controls the window for which SEASON_DATES is filled
	INSERT_SYSTEM_DICTIONARY('Past Window', '10', 0, 'Entity Manager', 'Season', 'Fill Season Dates');
	INSERT_SYSTEM_DICTIONARY('Future Window', '30', 0, 'Entity Manager', 'Season', 'Fill Season Dates');

	INSERT_SYSTEM_DICTIONARY('Database Temporary Report Directory', 'c:\temp\', 0, 'System', 'Crystal Reports');
	
	INSERT_SYSTEM_DICTIONARY('txt', 'text/plain', 0, 'System', 'MIME Types');
	INSERT_SYSTEM_DICTIONARY('xml', 'text/xml', 0, 'System', 'MIME Types');
	INSERT_SYSTEM_DICTIONARY('csv', 'text/csv', 0, 'System', 'MIME Types');
	INSERT_SYSTEM_DICTIONARY('binary', 'application/octet', 0, 'System', 'MIME Types');
	INSERT_SYSTEM_DICTIONARY('pdf', 'application/pdf', 0, 'System', 'MIME Types');
	INSERT_SYSTEM_DICTIONARY('doc', 'application/msword', 0, 'System', 'MIME Types');
	INSERT_SYSTEM_DICTIONARY('xls', 'application/vnd.ms-excel', 0, 'System', 'MIME Types');
	INSERT_SYSTEM_DICTIONARY('rtf', 'application/rtf', 0, 'System', 'MIME Types');
	INSERT_SYSTEM_DICTIONARY('gif', 'image/gif', 0, 'System', 'MIME Types');
	INSERT_SYSTEM_DICTIONARY('jpeg', 'image/jpeg', 0, 'System', 'MIME Types');
	INSERT_SYSTEM_DICTIONARY('png', 'image/png', 0, 'System', 'MIME Types');
	INSERT_SYSTEM_DICTIONARY('zip', 'application/zip', 0, 'System', 'MIME Types');
	INSERT_SYSTEM_DICTIONARY('html', 'text/html', 0, 'System', 'MIME Types');
	INSERT_SYSTEM_DICTIONARY('htm', 'text/html', 0, 'System', 'MIME Types');
	INSERT_SYSTEM_DICTIONARY('jpg', 'image/jpeg', 0, 'System', 'MIME Types');

	-- Controls the Window for which DST_TYPE and SYSTEM_DAY_INFO are filled
	INSERT_SYSTEM_DICTIONARY('Past Window', '30', 0, 'System', 'Fill DST Type');
	INSERT_SYSTEM_DICTIONARY('Future Window', '30', 0, 'System', 'Fill DST Type');

	INSERT_SYSTEM_DICTIONARY('Past Window', '10', 0, 'System', 'Fill System Day Info');
	INSERT_SYSTEM_DICTIONARY('Future Window', '20', 0, 'System', 'Fill System Day Info');
		
	-- Default Average Usage Factor 
	INSERT_SYSTEM_DICTIONARY('Default Average Usage Factor', '1.0', 0, 'Load Management');

	-- Account Sync
	-- Usage Factor Periods
	INSERT_SYSTEM_DICTIONARY('Period 1', '[PERIOD 1 ALIAS]', 0, 'Load Management', 'Account Sync', 'Usage Factor Periods', '[TOU Template Alias]');
	INSERT_SYSTEM_DICTIONARY('Period 2', '[PERIOD 2 ALIAS]', 0, 'Load Management', 'Account Sync', 'Usage Factor Periods', '[TOU Template Alias]');
	INSERT_SYSTEM_DICTIONARY('Period 3', '[PERIOD 3 ALIAS]', 0, 'Load Management', 'Account Sync', 'Usage Factor Periods', '[TOU Template Alias]');
	INSERT_SYSTEM_DICTIONARY('Period 4', '[PERIOD 4 ALIAS]', 0, 'Load Management', 'Account Sync', 'Usage Factor Periods', '[TOU Template Alias]');
	INSERT_SYSTEM_DICTIONARY('Period 5', '[PERIOD 5 ALIAS]', 0, 'Load Management', 'Account Sync', 'Usage Factor Periods', '[TOU Template Alias]');

	INSERT_SYSTEM_DICTIONARY('Category 1', '[Account Group Category]', 0, 'Load Management', 'Account Sync', 'Account Group Categories');
	INSERT_SYSTEM_DICTIONARY('Category 2', '[Account Group Category]', 0, 'Load Management', 'Account Sync', 'Account Group Categories');
	INSERT_SYSTEM_DICTIONARY('Category 3', '[Account Group Category]', 0, 'Load Management', 'Account Sync', 'Account Group Categories');
	INSERT_SYSTEM_DICTIONARY('Category 4', '[Account Group Category]', 0, 'Load Management', 'Account Sync', 'Account Group Categories');
	INSERT_SYSTEM_DICTIONARY('Category 5', '[Account Group Category]', 0, 'Load Management', 'Account Sync', 'Account Group Categories');
	
	-- Account Ancillary Services
	INSERT_SYSTEM_DICTIONARY('Ancillary Service 1', '[ANCILLARY SERVICE 1 ALIAS]', 0, 'Load Management', 'Account Sync', 'Account Ancillary Services');
	INSERT_SYSTEM_DICTIONARY('Ancillary Service 2', '[ANCILLARY SERVICE 2 ALIAS]', 0, 'Load Management', 'Account Sync', 'Account Ancillary Services');
	INSERT_SYSTEM_DICTIONARY('Ancillary Service 3', '[ANCILLARY SERVICE 2 ALIAS]', 0, 'Load Management', 'Account Sync', 'Account Ancillary Services');
	INSERT_SYSTEM_DICTIONARY('Ancillary Service 4', '[ANCILLARY SERVICE 3 ALIAS]', 0, 'Load Management', 'Account Sync', 'Account Ancillary Services');
	INSERT_SYSTEM_DICTIONARY('Ancillary Service 5', '[ANCILLARY SERVICE 5 ALIAS]', 0, 'Load Management', 'Account Sync', 'Account Ancillary Services');
	
	-- Meter Ancillary Services
	INSERT_SYSTEM_DICTIONARY('Ancillary Service 1', '[ANCILLARY SERVICE 1 ALIAS]', 0, 'Load Management', 'Account Sync', 'Meter Ancillary Services');
	INSERT_SYSTEM_DICTIONARY('Ancillary Service 2', '[ANCILLARY SERVICE 2 ALIAS]', 0, 'Load Management', 'Account Sync', 'Meter Ancillary Services');
	INSERT_SYSTEM_DICTIONARY('Ancillary Service 3', '[ANCILLARY SERVICE 2 ALIAS]', 0, 'Load Management', 'Account Sync', 'Meter Ancillary Services');
	INSERT_SYSTEM_DICTIONARY('Ancillary Service 4', '[ANCILLARY SERVICE 3 ALIAS]', 0, 'Load Management', 'Account Sync', 'Meter Ancillary Services');
	INSERT_SYSTEM_DICTIONARY('Ancillary Service 5', '[ANCILLARY SERVICE 5 ALIAS]', 0, 'Load Management', 'Account Sync', 'Meter Ancillary Services');
	
	-- Entity Group Categories
	INSERT_SYSTEM_DICTIONARY('Category 1', '[ENTITY GROUP 1 ALIAS]', 0, 'Load Management', 'Account Sync', 'Entity Group Categories');
	INSERT_SYSTEM_DICTIONARY('Category 2', '[ENTITY GROUP 2 ALIAS]', 0, 'Load Management', 'Account Sync', 'Entity Group Categories');
	INSERT_SYSTEM_DICTIONARY('Category 3', '[ENTITY GROUP 3 ALIAS]', 0, 'Load Management', 'Account Sync', 'Entity Group Categories');
	INSERT_SYSTEM_DICTIONARY('Category 4', '[ENTITY GROUP 4 ALIAS]', 0, 'Load Management', 'Account Sync', 'Entity Group Categories');
	INSERT_SYSTEM_DICTIONARY('Category 5', '[ENTITY GROUP 5 ALIAS]', 0, 'Load Management', 'Account Sync', 'Entity Group Categories');

	-- Custom Attributes
	INSERT_SYSTEM_DICTIONARY('Attribute 1', '[ATTRIBUTE 1]', 0, 'Load Management', 'Account Sync', 'Custom Attributes');
	INSERT_SYSTEM_DICTIONARY('Attribute 2', '[ATTRIBUTE 2]', 0, 'Load Management', 'Account Sync', 'Custom Attributes');
	INSERT_SYSTEM_DICTIONARY('Attribute 3', '[ATTRIBUTE 3]', 0, 'Load Management', 'Account Sync', 'Custom Attributes');
	INSERT_SYSTEM_DICTIONARY('Attribute 4', '[ATTRIBUTE 4]', 0, 'Load Management', 'Account Sync', 'Custom Attributes');
	INSERT_SYSTEM_DICTIONARY('Attribute 5', '[ATTRIBUTE 5]', 0, 'Load Management', 'Account Sync', 'Custom Attributes');
	INSERT_SYSTEM_DICTIONARY('Attribute 6', '[ATTRIBUTE 6]', 0, 'Load Management', 'Account Sync', 'Custom Attributes');
	INSERT_SYSTEM_DICTIONARY('Attribute 7', '[ATTRIBUTE 7]', 0, 'Load Management', 'Account Sync', 'Custom Attributes');
	INSERT_SYSTEM_DICTIONARY('Attribute 8', '[ATTRIBUTE 8]', 0, 'Load Management', 'Account Sync', 'Custom Attributes');
	INSERT_SYSTEM_DICTIONARY('Attribute 9', '[ATTRIBUTE 9]', 0, 'Load Management', 'Account Sync', 'Custom Attributes');
	INSERT_SYSTEM_DICTIONARY('Attribute 10', '[ATTRIBUTE 10]', 0, 'Load Management', 'Account Sync', 'Custom Attributes');
	
	-- Usage Factor Processing
	INSERT_SYSTEM_DICTIONARY('Calculate Usage Factors on Consumption Import', 'Y', 0, 'Load Management', 'Usage Factors');
	INSERT_SYSTEM_DICTIONARY('Calculated Usage Factor Horizon', '10', 0, 'Load Management', 'Usage Factors');
	INSERT_SYSTEM_DICTIONARY('Skip Usage Factors without Current History', '0', 0, 'Load Management', 'Usage Factors');
	INSERT_SYSTEM_DICTIONARY('Usage Factor Calc Commit Every N Rows', '0', 0, 'Load Management', 'Usage Factors');
	
	-- Dispute Management
	INSERT_SYSTEM_DICTIONARY('Generate Duplicate Disputes', 'Y', 0, 'Financial Settlements', 'Dispute Management');
	INSERT_SYSTEM_DICTIONARY('Generate Out of Tolerance Disputes', 'Y', 0, 'Financial Settlements', 'Dispute Management');
	
		
COMMIT;
END;
/
