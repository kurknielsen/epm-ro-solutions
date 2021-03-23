
/********************
	Update system dictionary with parameters for retrieving SEM reports. Each report is under Global | MarketExchange.
********************/
DECLARE
    ------------------------------
    PROCEDURE PUT_NEW_DICTIONARY_VALUE
    (
    p_SETTING_NAME IN VARCHAR2,
    p_VALUE IN VARCHAR2,
    p_MODEL_ID IN NUMBER := 0,
    p_MODULE IN VARCHAR2 := '?',
    p_KEY1 IN VARCHAR2 := '?',
    p_KEY2 IN VARCHAR2 := '?',
    p_KEY3 IN VARCHAR2 := '?',
    p_MATCH_CASE IN NUMBER := 1
    ) AS 
    
        v_TEST NUMBER := 0;
    
    BEGIN
    
        IF p_MATCH_CASE = 0 THEN
            SELECT COUNT(1)
            INTO v_TEST
            FROM SYSTEM_DICTIONARY
            WHERE MODEL_ID = p_MODEL_ID
                AND UPPER(MODULE) = UPPER(p_MODULE)
                AND UPPER(KEY1) = UPPER(p_KEY1)
                   AND UPPER(KEY2) = UPPER(p_KEY2)
                AND UPPER(KEY3) = UPPER(p_KEY3)
                AND UPPER(SETTING_NAME) = UPPER(p_SETTING_NAME);
        ELSE
            SELECT COUNT(1)
            INTO v_TEST
            FROM SYSTEM_DICTIONARY
            WHERE MODEL_ID = p_MODEL_ID
                AND MODULE = p_MODULE
                AND KEY1 = p_KEY1
                   AND KEY2 = p_KEY2
                AND KEY3 = p_KEY3
                AND SETTING_NAME = p_SETTING_NAME;
        END IF;
        
        -- ONLY PUT DICTIONARY VALUES IF THERE ISN'T AN EXISTING VALUE
        IF v_TEST <= 0 THEN
            PUT_DICTIONARY_VALUE(p_SETTING_NAME, p_VALUE, p_MODEL_ID, p_MODULE, p_KEY1, p_KEY2, p_KEY3, p_MATCH_CASE);
        END IF;
    
    END PUT_NEW_DICTIONARY_VALUE;
    ------------------------------
    
BEGIN
-- Ignore &'s in data; otherwise it will assume word after & is a substitution variable and prompt for a value	
		-- new MPUD6 reports

	PUT_NEW_DICTIONARY_VALUE('file_type', 'XML', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_EPInitShadowPrices');
	PUT_NEW_DICTIONARY_VALUE('file_type', 'XML', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_EAShadowPrices');
	PUT_NEW_DICTIONARY_VALUE('file_type', 'XML', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_EPIndShadowPrices');
	PUT_NEW_DICTIONARY_VALUE('file_type', 'XML', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_JurisdictionErrorSupplyD15');
	PUT_NEW_DICTIONARY_VALUE('file_type', 'XML', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ResidualErrorVolumeD15');
	PUT_NEW_DICTIONARY_VALUE('file_type', 'XML', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_EPLossOfLoadProbability');
	PUT_NEW_DICTIONARY_VALUE('file_type', 'XML', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExPostInitActLoadSummary');


	PUT_NEW_DICTIONARY_VALUE('application_type', 'MARKET_REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_EPInitShadowPrices');
	PUT_NEW_DICTIONARY_VALUE('application_type', 'MARKET_REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_EAShadowPrices');
	PUT_NEW_DICTIONARY_VALUE('application_type', 'MARKET_REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_EPIndShadowPrices');
	PUT_NEW_DICTIONARY_VALUE('application_type', 'MARKET_REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_JurisdictionErrorSupplyD15');
	PUT_NEW_DICTIONARY_VALUE('application_type', 'MARKET_REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ResidualErrorVolumeD15');
	PUT_NEW_DICTIONARY_VALUE('application_type', 'MARKET_REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_EPLossOfLoadProbability');
	PUT_NEW_DICTIONARY_VALUE('application_type', 'MARKET_REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExPostInitActLoadSummary');

	PUT_NEW_DICTIONARY_VALUE('version_no', '1.0', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_EPInitShadowPrices');
	PUT_NEW_DICTIONARY_VALUE('version_no', '1.0', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_EAShadowPrices');
	PUT_NEW_DICTIONARY_VALUE('version_no', '1.0', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_EPIndShadowPrices');
	PUT_NEW_DICTIONARY_VALUE('version_no', '1.0', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_JurisdictionErrorSupplyD15');
	PUT_NEW_DICTIONARY_VALUE('version_no', '1.0', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ResidualErrorVolumeD15');
	PUT_NEW_DICTIONARY_VALUE('version_no', '1.0', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_EPLossOfLoadProbability');
	PUT_NEW_DICTIONARY_VALUE('version_no', '1.0', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExPostInitActLoadSummary');

	PUT_NEW_DICTIONARY_VALUE('request_type', 'REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_EPInitShadowPrices');
	PUT_NEW_DICTIONARY_VALUE('request_type', 'REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_EAShadowPrices');
	PUT_NEW_DICTIONARY_VALUE('request_type', 'REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_EPIndShadowPrices');
	PUT_NEW_DICTIONARY_VALUE('request_type', 'REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_JurisdictionErrorSupplyD15');
	PUT_NEW_DICTIONARY_VALUE('request_type', 'REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ResidualErrorVolumeD15');
	PUT_NEW_DICTIONARY_VALUE('request_type', 'REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_EPLossOfLoadProbability');
	PUT_NEW_DICTIONARY_VALUE('request_type', 'REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExPostInitActLoadSummary');


	PUT_NEW_DICTIONARY_VALUE('mode', 'NORMAL', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_EPInitShadowPrices');
	PUT_NEW_DICTIONARY_VALUE('mode', 'NORMAL', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_EAShadowPrices');
	PUT_NEW_DICTIONARY_VALUE('mode', 'NORMAL', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_EPIndShadowPrices');
	PUT_NEW_DICTIONARY_VALUE('mode', 'NORMAL', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_JurisdictionErrorSupplyD15');
	PUT_NEW_DICTIONARY_VALUE('mode', 'NORMAL', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ResidualErrorVolumeD15');
	PUT_NEW_DICTIONARY_VALUE('mode', 'NORMAL', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_EPLossOfLoadProbability');
	PUT_NEW_DICTIONARY_VALUE('mode', 'NORMAL', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExPostInitActLoadSummary');


	PUT_NEW_DICTIONARY_VALUE('file_name', '', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_EPInitShadowPrices');
	PUT_NEW_DICTIONARY_VALUE('file_name', '', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_EAShadowPrices');
	PUT_NEW_DICTIONARY_VALUE('file_name', '', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_EPIndShadowPrices');
	PUT_NEW_DICTIONARY_VALUE('file_name', '', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_JurisdictionErrorSupplyD15');
	PUT_NEW_DICTIONARY_VALUE('file_name', '', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ResidualErrorVolumeD15');
	PUT_NEW_DICTIONARY_VALUE('file_name', '', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_EPLossOfLoadProbability');
	PUT_NEW_DICTIONARY_VALUE('file_name', '', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExPostInitActLoadSummary');


	PUT_NEW_DICTIONARY_VALUE('action', 'DOWNLOAD', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_EPInitShadowPrices');
	PUT_NEW_DICTIONARY_VALUE('action', 'DOWNLOAD', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_EAShadowPrices');
	PUT_NEW_DICTIONARY_VALUE('action', 'DOWNLOAD', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_EPIndShadowPrices');
	PUT_NEW_DICTIONARY_VALUE('action', 'DOWNLOAD', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_JurisdictionErrorSupplyD15');
	PUT_NEW_DICTIONARY_VALUE('action', 'DOWNLOAD', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ResidualErrorVolumeD15');
	PUT_NEW_DICTIONARY_VALUE('action', 'DOWNLOAD', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_EPLossOfLoadProbability');
	PUT_NEW_DICTIONARY_VALUE('action', 'DOWNLOAD', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExPostInitActLoadSummary');


	PUT_NEW_DICTIONARY_VALUE('multiple_messages', 'false', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_EPInitShadowPrices');
	PUT_NEW_DICTIONARY_VALUE('multiple_messages', 'false', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_EAShadowPrices');
	PUT_NEW_DICTIONARY_VALUE('multiple_messages', 'false', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_EPIndShadowPrices');
	PUT_NEW_DICTIONARY_VALUE('multiple_messages', 'false', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_JurisdictionErrorSupplyD15');  
	PUT_NEW_DICTIONARY_VALUE('multiple_messages', 'false', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ResidualErrorVolumeD15'); 
	PUT_NEW_DICTIONARY_VALUE('multiple_messages', 'false', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_EPLossOfLoadProbability');
	PUT_NEW_DICTIONARY_VALUE('multiple_messages', 'false', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExPostInitActLoadSummary');

	PUT_NEW_DICTIONARY_VALUE('periodicity', 'DAILY', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_EPInitShadowPrices');
	PUT_NEW_DICTIONARY_VALUE('periodicity', 'DAILY', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_EAShadowPrices');
	PUT_NEW_DICTIONARY_VALUE('periodicity', 'DAILY', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_EPIndShadowPrices');
	PUT_NEW_DICTIONARY_VALUE('periodicity', 'DAILY', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_JurisdictionErrorSupplyD15');
	PUT_NEW_DICTIONARY_VALUE('periodicity', 'DAILY', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ResidualErrorVolumeD15');
	PUT_NEW_DICTIONARY_VALUE('periodicity', 'DAILY', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_EPLossOfLoadProbability');
	PUT_NEW_DICTIONARY_VALUE('periodicity', 'DAILY', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExPostInitActLoadSummary');

	PUT_NEW_DICTIONARY_VALUE('access_class', 'PUB', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_EPInitShadowPrices');
	PUT_NEW_DICTIONARY_VALUE('access_class', 'PUB', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_EAShadowPrices');
	PUT_NEW_DICTIONARY_VALUE('access_class', 'PUB', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_EPIndShadowPrices');
	PUT_NEW_DICTIONARY_VALUE('access_class', 'PUB', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_JurisdictionErrorSupplyD15');
	PUT_NEW_DICTIONARY_VALUE('access_class', 'PUB', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ResidualErrorVolumeD15');
	PUT_NEW_DICTIONARY_VALUE('access_class', 'PUB', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_EPLossOfLoadProbability');
	PUT_NEW_DICTIONARY_VALUE('access_class', 'PUB', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExPostInitActLoadSummary');


	PUT_NEW_DICTIONARY_VALUE('report_name', 'PUB_D_EPInitShadowPrices', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_EPInitShadowPrices');
	PUT_NEW_DICTIONARY_VALUE('report_name', 'PUB_D_EAShadowPrices', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_EAShadowPrices');
	PUT_NEW_DICTIONARY_VALUE('report_name', 'PUB_D_EPIndShadowPrices', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_EPIndShadowPrices');
	PUT_NEW_DICTIONARY_VALUE('report_name', 'PUB_D_JurisdictionErrorSupplyD15', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_JurisdictionErrorSupplyD15');
	PUT_NEW_DICTIONARY_VALUE('report_name', 'PUB_D_ResidualErrorVolumeD15', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ResidualErrorVolumeD15');
	PUT_NEW_DICTIONARY_VALUE('report_name', 'PUB_D_EPLossOfLoadProbability', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_EPLossOfLoadProbability');
	PUT_NEW_DICTIONARY_VALUE('report_name', 'PUB_D_ExPostInitActLoadSummary', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExPostInitActLoadSummary');
	

	PUT_NEW_DICTIONARY_VALUE('import_procedure', 'IMPORT_SHADOW_SMP', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_EPInitShadowPrices');
	PUT_NEW_DICTIONARY_VALUE('import_procedure', 'IMPORT_SHADOW_SMP', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_EAShadowPrices');
	PUT_NEW_DICTIONARY_VALUE('import_procedure', 'IMPORT_SHADOW_SMP', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_EPIndShadowPrices');
	PUT_NEW_DICTIONARY_VALUE('import_procedure', 'IMPORT_LOAD_FORECAST', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_JurisdictionErrorSupplyD15');
	PUT_NEW_DICTIONARY_VALUE('import_procedure', 'IMPORT_LOAD_FORECAST', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ResidualErrorVolumeD15');
	PUT_NEW_DICTIONARY_VALUE('import_procedure', 'IMPORT_LOSS_LOAD_PROBAB', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_EPLossOfLoadProbability');
	PUT_NEW_DICTIONARY_VALUE('import_procedure', 'IMPORT_LOAD_FORECAST', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExPostInitActLoadSummary');


	PUT_NEW_DICTIONARY_VALUE('import_param', 'PUB_D_EPInitShadowPrices', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_EPInitShadowPrices');
	PUT_NEW_DICTIONARY_VALUE('import_param', 'PUB_D_EAShadowPrices', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_EAShadowPrices');
	PUT_NEW_DICTIONARY_VALUE('import_param', 'PUB_D_EPIndShadowPrices', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_EPIndShadowPrices');
	PUT_NEW_DICTIONARY_VALUE('import_param', 'D15-ES',0,'MarketExchange','SEM','SMO Reports', 'PUB_D_JurisdictionErrorSupplyD15');
	PUT_NEW_DICTIONARY_VALUE('import_param', 'D15-ES',0,'MarketExchange','SEM','SMO Reports', 'PUB_D_ResidualErrorVolumeD15');
	PUT_NEW_DICTIONARY_VALUE('import_param', '',0,'MarketExchange','SEM','SMO Reports', 'PUB_D_EPLossOfLoadProbability');
	PUT_NEW_DICTIONARY_VALUE('import_param', 'DA',0,'MarketExchange','SEM','SMO Reports', 'PUB_D_ExPostInitActLoadSummary');


	PUT_NEW_DICTIONARY_VALUE('report_type','MARKET', 0,'MarketExchange','SEM','SMO Reports','PUB_D_EPInitShadowPrices');
	PUT_NEW_DICTIONARY_VALUE('report_type','MARKET', 0,'MarketExchange','SEM','SMO Reports','PUB_D_EAShadowPrices');
	PUT_NEW_DICTIONARY_VALUE('report_type','MARKET', 0,'MarketExchange','SEM','SMO Reports','PUB_D_EPIndShadowPrices');
	PUT_NEW_DICTIONARY_VALUE('report_type','MARKET', 0,'MarketExchange','SEM','SMO Reports','PUB_D_JurisdictionErrorSupplyD15');
	PUT_NEW_DICTIONARY_VALUE('report_type','MARKET', 0,'MarketExchange','SEM','SMO Reports','PUB_D_ResidualErrorVolumeD15');
	PUT_NEW_DICTIONARY_VALUE('report_type','TRANS_SYSTEM', 0,'MarketExchange','SEM','SMO Reports','PUB_D_EPLossOfLoadProbability');
	PUT_NEW_DICTIONARY_VALUE('report_type','MARKET', 0,'MarketExchange','SEM','SMO Reports','PUB_D_ExPostInitActLoadSummary');

	PUT_NEW_DICTIONARY_VALUE('report_sub_type','DAY_AHEAD', 0,'MarketExchange','SEM','SMO Reports','PUB_D_EPInitShadowPrices');
	PUT_NEW_DICTIONARY_VALUE('report_sub_type','DAY_AHEAD', 0,'MarketExchange','SEM','SMO Reports','PUB_D_EAShadowPrices');
	PUT_NEW_DICTIONARY_VALUE('report_sub_type','DAY_AHEAD', 0,'MarketExchange','SEM','SMO Reports','PUB_D_EPIndShadowPrices');
	PUT_NEW_DICTIONARY_VALUE('report_sub_type','METERING', 0,'MarketExchange','SEM','SMO Reports','PUB_D_JurisdictionErrorSupplyD15');
	PUT_NEW_DICTIONARY_VALUE('report_sub_type','METERING', 0,'MarketExchange','SEM','SMO Reports','PUB_D_ResidualErrorVolumeD15');
	PUT_NEW_DICTIONARY_VALUE('report_sub_type','FORECASTS', 0,'MarketExchange','SEM','SMO Reports','PUB_D_EPLossOfLoadProbability');
	PUT_NEW_DICTIONARY_VALUE('report_sub_type','DAY_AHEAD', 0,'MarketExchange','SEM','SMO Reports','PUB_D_ExPostInitActLoadSummary');

	END;
/
-- save changes to database
COMMIT;


