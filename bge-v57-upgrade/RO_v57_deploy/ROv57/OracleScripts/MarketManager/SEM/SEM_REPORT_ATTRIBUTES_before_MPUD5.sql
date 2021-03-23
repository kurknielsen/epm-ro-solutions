-- CVS Revision: $Revision: 1.7 $

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
    
    --------------------------------------------------------------
    -----------------SMO Report attributes----------------------------
    --------------------------------------------------------------
    
    --Creating SYSTEM_DICTIONARY entry for PUB_ActiveMPs_31012007.xml

       -- *** INFO ***: TITLE length is 34 chars.
       PUT_NEW_DICTIONARY_VALUE('application_type', 'MARKET_REPORT', 0, 'MarketExchange', 'SEM','SMO Reports','List of Active Market Participants');
       PUT_NEW_DICTIONARY_VALUE('mode', 'NORMAL', 0, 'MarketExchange', 'SEM','SMO Reports','List of Active Market Participants');
       PUT_NEW_DICTIONARY_VALUE('request_type', 'REPORT', 0, 'MarketExchange', 'SEM','SMO Reports','List of Active Market Participants');
       PUT_NEW_DICTIONARY_VALUE('action', 'DOWNLOAD', 0, 'MarketExchange', 'SEM','SMO Reports','List of Active Market Participants');
       PUT_NEW_DICTIONARY_VALUE('access_class', 'PUB', 0, 'MarketExchange', 'SEM','SMO Reports','List of Active Market Participants');
       PUT_NEW_DICTIONARY_VALUE('file_type', 'XML', 0, 'MarketExchange', 'SEM','SMO Reports','List of Active Market Participants');
       PUT_NEW_DICTIONARY_VALUE('periodicity', 'DAILY', 0, 'MarketExchange', 'SEM','SMO Reports','List of Active Market Participants');
       PUT_NEW_DICTIONARY_VALUE('report_name', 'PUB_ActiveMPs', 0, 'MarketExchange', 'SEM','SMO Reports','List of Active Market Participants');
       PUT_NEW_DICTIONARY_VALUE('file_name', 'PUB_ActiveMPs_31012007.xml', 0, 'MarketExchange', 'SEM','SMO Reports','List of Active Market Participants');
       PUT_NEW_DICTIONARY_VALUE('report_type', 'REGISTRATION', 0, 'MarketExchange', 'SEM','SMO Reports','List of Active Market Participants');
       PUT_NEW_DICTIONARY_VALUE('report_sub_type', 'MP_ACTIVITY', 0, 'MarketExchange', 'SEM','SMO Reports','List of Active Market Participants');
       PUT_NEW_DICTIONARY_VALUE('version_no', '1.0', 0, 'MarketExchange', 'SEM','SMO Reports','List of Active Market Participants');
       PUT_NEW_DICTIONARY_VALUE('multiple_messages', 'false', 0, 'MarketExchange', 'SEM','SMO Reports','List of Active Market Participants');
       
--Creating SYSTEM_DICTIONARY entry for PUB_SupsTermMPs_31012007.xml

       -- *** INFO ***: TITLE length is 49 chars.
       PUT_NEW_DICTIONARY_VALUE('application_type', 'MARKET_REPORT', 0, 'MarketExchange', 'SEM','SMO Reports','List of Suspended/Terminated Market Participants');
       PUT_NEW_DICTIONARY_VALUE('mode', 'NORMAL', 0, 'MarketExchange', 'SEM','SMO Reports','List of Suspended/Terminated Market Participants');
       PUT_NEW_DICTIONARY_VALUE('request_type', 'REPORT', 0, 'MarketExchange', 'SEM','SMO Reports','List of Suspended/Terminated Market Participants');
       PUT_NEW_DICTIONARY_VALUE('action', 'DOWNLOAD', 0, 'MarketExchange', 'SEM','SMO Reports','List of Suspended/Terminated Market Participants');
       PUT_NEW_DICTIONARY_VALUE('access_class', 'PUB', 0, 'MarketExchange', 'SEM','SMO Reports','List of Suspended/Terminated Market Participants');
       PUT_NEW_DICTIONARY_VALUE('file_type', 'XML', 0, 'MarketExchange', 'SEM','SMO Reports','List of Suspended/Terminated Market Participants');
       PUT_NEW_DICTIONARY_VALUE('periodicity', 'DAILY', 0, 'MarketExchange', 'SEM','SMO Reports','List of Suspended/Terminated Market Participants');
       PUT_NEW_DICTIONARY_VALUE('report_name', 'PUB_SuspTermMPs', 0, 'MarketExchange', 'SEM','SMO Reports','List of Suspended/Terminated Market Participants');
       PUT_NEW_DICTIONARY_VALUE('file_name', 'PUB_SupsTermMPs_31012007.xml', 0, 'MarketExchange', 'SEM','SMO Reports','List of Suspended/Terminated Market Participants');
       PUT_NEW_DICTIONARY_VALUE('report_type', 'REGISTRATION', 0, 'MarketExchange', 'SEM','SMO Reports','List of Suspended/Terminated Market Participants');
       PUT_NEW_DICTIONARY_VALUE('report_sub_type', 'MP_ACTIVITY', 0, 'MarketExchange', 'SEM','SMO Reports','List of Suspended/Terminated Market Participants');
       PUT_NEW_DICTIONARY_VALUE('version_no', '1.0', 0, 'MarketExchange', 'SEM','SMO Reports','List of Suspended/Terminated Market Participants');
       PUT_NEW_DICTIONARY_VALUE('multiple_messages', 'false', 0, 'MarketExchange', 'SEM','SMO Reports','List of Suspended/Terminated Market Participants');
       
--Creating SYSTEM_DICTIONARY entry for PUB_A_LoadFcst_15032007.xml

       -- *** INFO ***: TITLE length is 20 chars.
       PUT_NEW_DICTIONARY_VALUE('application_type', 'MARKET_REPORT', 0, 'MarketExchange', 'SEM','SMO Reports','Annual Load Forecast');
       PUT_NEW_DICTIONARY_VALUE('mode', 'NORMAL', 0, 'MarketExchange', 'SEM','SMO Reports','Annual Load Forecast');
       PUT_NEW_DICTIONARY_VALUE('request_type', 'REPORT', 0, 'MarketExchange', 'SEM','SMO Reports','Annual Load Forecast');
       PUT_NEW_DICTIONARY_VALUE('action', 'DOWNLOAD', 0, 'MarketExchange', 'SEM','SMO Reports','Annual Load Forecast');
       PUT_NEW_DICTIONARY_VALUE('access_class', 'PUB', 0, 'MarketExchange', 'SEM','SMO Reports','Annual Load Forecast');
       PUT_NEW_DICTIONARY_VALUE('file_type', 'XML', 0, 'MarketExchange', 'SEM','SMO Reports','Annual Load Forecast');
       PUT_NEW_DICTIONARY_VALUE('periodicity', 'YEARLY', 0, 'MarketExchange', 'SEM','SMO Reports','Annual Load Forecast');
       PUT_NEW_DICTIONARY_VALUE('report_name', 'PUB_A_LoadFcst', 0, 'MarketExchange', 'SEM','SMO Reports','Annual Load Forecast');
       PUT_NEW_DICTIONARY_VALUE('file_name', 'PUB_A_LoadFcst_15032007.xml', 0, 'MarketExchange', 'SEM','SMO Reports','Annual Load Forecast');
       PUT_NEW_DICTIONARY_VALUE('report_type', 'TRANS_SYSTEM', 0, 'MarketExchange', 'SEM','SMO Reports','Annual Load Forecast');
       PUT_NEW_DICTIONARY_VALUE('report_sub_type', 'FORECASTS', 0, 'MarketExchange', 'SEM','SMO Reports','Annual Load Forecast');
       PUT_NEW_DICTIONARY_VALUE('version_no', '1.0', 0, 'MarketExchange', 'SEM','SMO Reports','Annual Load Forecast');
       PUT_NEW_DICTIONARY_VALUE('multiple_messages', 'false', 0, 'MarketExchange', 'SEM','SMO Reports','Annual Load Forecast');
       
--Creating SYSTEM_DICTIONARY entry for PUB_M_LoadFcstAssumptions_15032007.xml

       -- *** INFO ***: TITLE length is 37 chars.
       PUT_NEW_DICTIONARY_VALUE('application_type', 'MARKET_REPORT', 0, 'MarketExchange', 'SEM','SMO Reports','Monthly Load Forecast and Assumptions');
       PUT_NEW_DICTIONARY_VALUE('mode', 'NORMAL', 0, 'MarketExchange', 'SEM','SMO Reports','Monthly Load Forecast and Assumptions');
       PUT_NEW_DICTIONARY_VALUE('request_type', 'REPORT', 0, 'MarketExchange', 'SEM','SMO Reports','Monthly Load Forecast and Assumptions');
       PUT_NEW_DICTIONARY_VALUE('action', 'DOWNLOAD', 0, 'MarketExchange', 'SEM','SMO Reports','Monthly Load Forecast and Assumptions');
       PUT_NEW_DICTIONARY_VALUE('access_class', 'PUB', 0, 'MarketExchange', 'SEM','SMO Reports','Monthly Load Forecast and Assumptions');
       PUT_NEW_DICTIONARY_VALUE('file_type', 'XML', 0, 'MarketExchange', 'SEM','SMO Reports','Monthly Load Forecast and Assumptions');
       PUT_NEW_DICTIONARY_VALUE('periodicity', 'MONTHLY', 0, 'MarketExchange', 'SEM','SMO Reports','Monthly Load Forecast and Assumptions');
       PUT_NEW_DICTIONARY_VALUE('report_name', 'PUB_M_LoadFcstAssumptions', 0, 'MarketExchange', 'SEM','SMO Reports','Monthly Load Forecast and Assumptions');
       PUT_NEW_DICTIONARY_VALUE('file_name', 'PUB_M_LoadFcstAssumptions_15032007.xml', 0, 'MarketExchange', 'SEM','SMO Reports','Monthly Load Forecast and Assumptions');
       PUT_NEW_DICTIONARY_VALUE('report_type', 'TRANS_SYSTEM', 0, 'MarketExchange', 'SEM','SMO Reports','Monthly Load Forecast and Assumptions');
       PUT_NEW_DICTIONARY_VALUE('report_sub_type', 'FORECASTS', 0, 'MarketExchange', 'SEM','SMO Reports','Monthly Load Forecast and Assumptions');
       PUT_NEW_DICTIONARY_VALUE('version_no', '1.0', 0, 'MarketExchange', 'SEM','SMO Reports','Monthly Load Forecast and Assumptions');
       PUT_NEW_DICTIONARY_VALUE('multiple_messages', 'false', 0, 'MarketExchange', 'SEM','SMO Reports','Monthly Load Forecast and Assumptions');
       
--Creating SYSTEM_DICTIONARY entry for PUB_M_SttlClassesUpdates_28022007.xml

       -- *** INFO ***: TITLE length is 37 chars.
       PUT_NEW_DICTIONARY_VALUE('application_type', 'MARKET_REPORT', 0, 'MarketExchange', 'SEM','SMO Reports','Monthly Updates to Settlement Classes');
       PUT_NEW_DICTIONARY_VALUE('mode', 'NORMAL', 0, 'MarketExchange', 'SEM','SMO Reports','Monthly Updates to Settlement Classes');
       PUT_NEW_DICTIONARY_VALUE('request_type', 'REPORT', 0, 'MarketExchange', 'SEM','SMO Reports','Monthly Updates to Settlement Classes');
       PUT_NEW_DICTIONARY_VALUE('action', 'DOWNLOAD', 0, 'MarketExchange', 'SEM','SMO Reports','Monthly Updates to Settlement Classes');
       PUT_NEW_DICTIONARY_VALUE('access_class', 'PUB', 0, 'MarketExchange', 'SEM','SMO Reports','Monthly Updates to Settlement Classes');
       PUT_NEW_DICTIONARY_VALUE('file_type', 'XML', 0, 'MarketExchange', 'SEM','SMO Reports','Monthly Updates to Settlement Classes');
       PUT_NEW_DICTIONARY_VALUE('periodicity', 'MONTHLY', 0, 'MarketExchange', 'SEM','SMO Reports','Monthly Updates to Settlement Classes');
       PUT_NEW_DICTIONARY_VALUE('report_name', 'PUB_M_SttlClassesUpdates', 0, 'MarketExchange', 'SEM','SMO Reports','Monthly Updates to Settlement Classes');
       PUT_NEW_DICTIONARY_VALUE('file_name', 'PUB_M_SttlClassesUpdates_28022007.xml', 0, 'MarketExchange', 'SEM','SMO Reports','Monthly Updates to Settlement Classes');
       PUT_NEW_DICTIONARY_VALUE('report_type', 'REGISTRATION', 0, 'MarketExchange', 'SEM','SMO Reports','Monthly Updates to Settlement Classes');
       PUT_NEW_DICTIONARY_VALUE('report_sub_type', 'MP_ACTIVITY', 0, 'MarketExchange', 'SEM','SMO Reports','Monthly Updates to Settlement Classes');
       PUT_NEW_DICTIONARY_VALUE('version_no', '1.0', 0, 'MarketExchange', 'SEM','SMO Reports','Monthly Updates to Settlement Classes');
       PUT_NEW_DICTIONARY_VALUE('multiple_messages', 'false', 0, 'MarketExchange', 'SEM','SMO Reports','Monthly Updates to Settlement Classes');
       
--Creating SYSTEM_DICTIONARY entry for PUB_M_LossLoadProbabilityFcst_31012007.xml

       -- *** INFO ***: TITLE length is 41 chars.
       PUT_NEW_DICTIONARY_VALUE('application_type', 'MARKET_REPORT', 0, 'MarketExchange', 'SEM','SMO Reports','Monthly Loss of Load Probability Forecast');
       PUT_NEW_DICTIONARY_VALUE('mode', 'NORMAL', 0, 'MarketExchange', 'SEM','SMO Reports','Monthly Loss of Load Probability Forecast');
       PUT_NEW_DICTIONARY_VALUE('request_type', 'REPORT', 0, 'MarketExchange', 'SEM','SMO Reports','Monthly Loss of Load Probability Forecast');
       PUT_NEW_DICTIONARY_VALUE('action', 'DOWNLOAD', 0, 'MarketExchange', 'SEM','SMO Reports','Monthly Loss of Load Probability Forecast');
       PUT_NEW_DICTIONARY_VALUE('access_class', 'PUB', 0, 'MarketExchange', 'SEM','SMO Reports','Monthly Loss of Load Probability Forecast');
       PUT_NEW_DICTIONARY_VALUE('file_type', 'XML', 0, 'MarketExchange', 'SEM','SMO Reports','Monthly Loss of Load Probability Forecast');
       PUT_NEW_DICTIONARY_VALUE('periodicity', 'MONTHLY', 0, 'MarketExchange', 'SEM','SMO Reports','Monthly Loss of Load Probability Forecast');
       PUT_NEW_DICTIONARY_VALUE('report_name', 'PUB_M_LossLoadProbabilityFcst', 0, 'MarketExchange', 'SEM','SMO Reports','Monthly Loss of Load Probability Forecast');
       PUT_NEW_DICTIONARY_VALUE('file_name', 'PUB_M_LossLoadProbabilityFcst_31012007.xml', 0, 'MarketExchange', 'SEM','SMO Reports','Monthly Loss of Load Probability Forecast');
       PUT_NEW_DICTIONARY_VALUE('report_type', 'TRANS_SYSTEM', 0, 'MarketExchange', 'SEM','SMO Reports','Monthly Loss of Load Probability Forecast');
       PUT_NEW_DICTIONARY_VALUE('report_sub_type', 'FORECASTS', 0, 'MarketExchange', 'SEM','SMO Reports','Monthly Loss of Load Probability Forecast');
       PUT_NEW_DICTIONARY_VALUE('version_no', '1.0', 0, 'MarketExchange', 'SEM','SMO Reports','Monthly Loss of Load Probability Forecast');
       PUT_NEW_DICTIONARY_VALUE('multiple_messages', 'false', 0, 'MarketExchange', 'SEM','SMO Reports','Monthly Loss of Load Probability Forecast');
       
--Creating SYSTEM_DICTIONARY entry for PUB_D_IntconnATCData_31012007.xml

       -- *** INFO ***: TITLE length is 29 chars.
       PUT_NEW_DICTIONARY_VALUE('application_type', 'MARKET_REPORT', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Interconnector ATC Data');
       PUT_NEW_DICTIONARY_VALUE('mode', 'NORMAL', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Interconnector ATC Data');
       PUT_NEW_DICTIONARY_VALUE('request_type', 'REPORT', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Interconnector ATC Data');
       PUT_NEW_DICTIONARY_VALUE('action', 'DOWNLOAD', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Interconnector ATC Data');
       PUT_NEW_DICTIONARY_VALUE('access_class', 'PUB', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Interconnector ATC Data');
       PUT_NEW_DICTIONARY_VALUE('file_type', 'XML', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Interconnector ATC Data');
       PUT_NEW_DICTIONARY_VALUE('periodicity', 'DAILY', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Interconnector ATC Data');
       PUT_NEW_DICTIONARY_VALUE('report_name', 'PUB_D_IntconnATCData', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Interconnector ATC Data');
       PUT_NEW_DICTIONARY_VALUE('file_name', 'PUB_D_IntconnATCData_31012007.xml', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Interconnector ATC Data');
       PUT_NEW_DICTIONARY_VALUE('report_type', 'TRANS_SYSTEM', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Interconnector ATC Data');
       PUT_NEW_DICTIONARY_VALUE('report_sub_type', 'INTERCONNECTOR', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Interconnector ATC Data');
       PUT_NEW_DICTIONARY_VALUE('version_no', '1.0', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Interconnector ATC Data');
       PUT_NEW_DICTIONARY_VALUE('multiple_messages', 'false', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Interconnector ATC Data');
       
--Creating SYSTEM_DICTIONARY entry for PUB_D_ExchangeRate_31012007.xml

       -- *** INFO ***: TITLE length is 31 chars.
       PUT_NEW_DICTIONARY_VALUE('application_type', 'MARKET_REPORT', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Trading Day Exchange Rate');
       PUT_NEW_DICTIONARY_VALUE('mode', 'NORMAL', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Trading Day Exchange Rate');
       PUT_NEW_DICTIONARY_VALUE('request_type', 'REPORT', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Trading Day Exchange Rate');
       PUT_NEW_DICTIONARY_VALUE('action', 'DOWNLOAD', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Trading Day Exchange Rate');
       PUT_NEW_DICTIONARY_VALUE('access_class', 'PUB', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Trading Day Exchange Rate');
       PUT_NEW_DICTIONARY_VALUE('file_type', 'XML', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Trading Day Exchange Rate');
       PUT_NEW_DICTIONARY_VALUE('periodicity', 'DAILY', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Trading Day Exchange Rate');
       PUT_NEW_DICTIONARY_VALUE('report_name', 'PUB_D_ExchangeRate', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Trading Day Exchange Rate');
       PUT_NEW_DICTIONARY_VALUE('file_name', 'PUB_D_ExchangeRate_31012007.xml', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Trading Day Exchange Rate');
       PUT_NEW_DICTIONARY_VALUE('report_type', 'MARKET', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Trading Day Exchange Rate');
       PUT_NEW_DICTIONARY_VALUE('report_sub_type', 'MISCELLANEOUS', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Trading Day Exchange Rate');
       PUT_NEW_DICTIONARY_VALUE('version_no', '1.0', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Trading Day Exchange Rate');
       PUT_NEW_DICTIONARY_VALUE('multiple_messages', 'false', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Trading Day Exchange Rate');
       
--Creating SYSTEM_DICTIONARY entry for PUB_D_LoadFcstSummary_12032007.xml

       -- *** INFO ***: TITLE length is 27 chars.
       PUT_NEW_DICTIONARY_VALUE('application_type', 'MARKET_REPORT', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Load Forecast Summary');
       PUT_NEW_DICTIONARY_VALUE('mode', 'NORMAL', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Load Forecast Summary');
       PUT_NEW_DICTIONARY_VALUE('request_type', 'REPORT', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Load Forecast Summary');
       PUT_NEW_DICTIONARY_VALUE('action', 'DOWNLOAD', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Load Forecast Summary');
       PUT_NEW_DICTIONARY_VALUE('access_class', 'PUB', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Load Forecast Summary');
       PUT_NEW_DICTIONARY_VALUE('file_type', 'XML', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Load Forecast Summary');
       PUT_NEW_DICTIONARY_VALUE('periodicity', 'DAILY', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Load Forecast Summary');
       PUT_NEW_DICTIONARY_VALUE('report_name', 'PUB_D_LoadFcstSummary', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Load Forecast Summary');
       PUT_NEW_DICTIONARY_VALUE('file_name', 'PUB_D_LoadFcstSummary_12032007.xml', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Load Forecast Summary');
       PUT_NEW_DICTIONARY_VALUE('report_type', 'TRANS_SYSTEM', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Load Forecast Summary');
       PUT_NEW_DICTIONARY_VALUE('report_sub_type', 'FORECASTS', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Load Forecast Summary');
       PUT_NEW_DICTIONARY_VALUE('version_no', '1.0', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Load Forecast Summary');
       PUT_NEW_DICTIONARY_VALUE('multiple_messages', 'false', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Load Forecast Summary');
       
--Creating SYSTEM_DICTIONARY entry for PUB_D_RollingWindFcstAssumptions_13032007.xml

       -- *** INFO ***: TITLE length is 43 chars.
       PUT_NEW_DICTIONARY_VALUE('application_type', 'MARKET_REPORT', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Rolling Wind Forecast and Assumptions');
       PUT_NEW_DICTIONARY_VALUE('mode', 'NORMAL', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Rolling Wind Forecast and Assumptions');
       PUT_NEW_DICTIONARY_VALUE('request_type', 'REPORT', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Rolling Wind Forecast and Assumptions');
       PUT_NEW_DICTIONARY_VALUE('action', 'DOWNLOAD', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Rolling Wind Forecast and Assumptions');
       PUT_NEW_DICTIONARY_VALUE('access_class', 'PUB', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Rolling Wind Forecast and Assumptions');
       PUT_NEW_DICTIONARY_VALUE('file_type', 'XML', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Rolling Wind Forecast and Assumptions');
       PUT_NEW_DICTIONARY_VALUE('periodicity', 'DAILY', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Rolling Wind Forecast and Assumptions');
       PUT_NEW_DICTIONARY_VALUE('report_name', 'PUB_D_RollingWindFcstAssumptions', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Rolling Wind Forecast and Assumptions');
       PUT_NEW_DICTIONARY_VALUE('file_name', 'PUB_D_RollingWindFcstAssumptions_13032007.xml', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Rolling Wind Forecast and Assumptions');
       PUT_NEW_DICTIONARY_VALUE('report_type', 'TRANS_SYSTEM', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Rolling Wind Forecast and Assumptions');
       PUT_NEW_DICTIONARY_VALUE('report_sub_type', 'FORECASTS', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Rolling Wind Forecast and Assumptions');
       PUT_NEW_DICTIONARY_VALUE('version_no', '1.0', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Rolling Wind Forecast and Assumptions');
       PUT_NEW_DICTIONARY_VALUE('multiple_messages','false', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Rolling Wind Forecast and Assumptions');
       
       
--Creating SYSTEM_DICTIONARY entry for PUB_D_ExAnteMktSchSummary_13032007.xml

       -- *** INFO ***: TITLE length is 37 chars.
       PUT_NEW_DICTIONARY_VALUE('application_type', 'MARKET_REPORT', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Ex-Ante Market Schedule Summary');
       PUT_NEW_DICTIONARY_VALUE('mode', 'NORMAL', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Ex-Ante Market Schedule Summary');
       PUT_NEW_DICTIONARY_VALUE('request_type', 'REPORT', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Ex-Ante Market Schedule Summary');
       PUT_NEW_DICTIONARY_VALUE('action', 'DOWNLOAD', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Ex-Ante Market Schedule Summary');
       PUT_NEW_DICTIONARY_VALUE('access_class', 'PUB', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Ex-Ante Market Schedule Summary');
       PUT_NEW_DICTIONARY_VALUE('file_type', 'XML', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Ex-Ante Market Schedule Summary');
       PUT_NEW_DICTIONARY_VALUE('periodicity', 'DAILY', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Ex-Ante Market Schedule Summary');
       PUT_NEW_DICTIONARY_VALUE('report_name', 'PUB_D_ExAnteMktSchSummary', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Ex-Ante Market Schedule Summary');
       PUT_NEW_DICTIONARY_VALUE('file_name', 'PUB_D_ExAnteMktSchSummary_13032007.xml', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Ex-Ante Market Schedule Summary');
       PUT_NEW_DICTIONARY_VALUE('report_type', 'MARKET', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Ex-Ante Market Schedule Summary');
       PUT_NEW_DICTIONARY_VALUE('report_sub_type', 'DAY_AHEAD', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Ex-Ante Market Schedule Summary');
       PUT_NEW_DICTIONARY_VALUE('version_no', '1.0', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Ex-Ante Market Schedule Summary');
       PUT_NEW_DICTIONARY_VALUE('multiple_messages','false', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Ex-Ante Market Schedule Summary');
       
--Creating SYSTEM_DICTIONARY entry for MP_D_ExAnteMktSchDetail_31012007.xml

       -- *** INFO ***: TITLE length is 36 chars.
       PUT_NEW_DICTIONARY_VALUE('application_type', 'MARKET_REPORT', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Ex-Ante Market Schedule Detail');
       PUT_NEW_DICTIONARY_VALUE('mode', 'NORMAL', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Ex-Ante Market Schedule Detail');
       PUT_NEW_DICTIONARY_VALUE('request_type', 'REPORT', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Ex-Ante Market Schedule Detail');
       PUT_NEW_DICTIONARY_VALUE('action', 'DOWNLOAD', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Ex-Ante Market Schedule Detail');
       PUT_NEW_DICTIONARY_VALUE('access_class', 'MP', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Ex-Ante Market Schedule Detail');
       PUT_NEW_DICTIONARY_VALUE('file_type', 'XML', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Ex-Ante Market Schedule Detail');
       PUT_NEW_DICTIONARY_VALUE('periodicity', 'DAILY', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Ex-Ante Market Schedule Detail');
       PUT_NEW_DICTIONARY_VALUE('report_name', 'MP_D_ExAnteMktSchDetail', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Ex-Ante Market Schedule Detail');
       PUT_NEW_DICTIONARY_VALUE('file_name', 'MP_D_ExAnteMktSchDetail_31012007.xml', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Ex-Ante Market Schedule Detail');
       PUT_NEW_DICTIONARY_VALUE('report_type', 'MARKET', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Ex-Ante Market Schedule Detail');
       PUT_NEW_DICTIONARY_VALUE('report_sub_type', 'DAY_AHEAD', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Ex-Ante Market Schedule Detail');
       PUT_NEW_DICTIONARY_VALUE('version_no', '1.0', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Ex-Ante Market Schedule Detail');
       PUT_NEW_DICTIONARY_VALUE('multiple_messages','false', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Ex-Ante Market Schedule Detail');
       
--Creating SYSTEM_DICTIONARY entry for MP_D_IntconnNominations_31012007.xml

       -- *** INFO ***: TITLE length is 32 chars.
       PUT_NEW_DICTIONARY_VALUE('application_type', 'MARKET_REPORT', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Interconnector Nominations');
       PUT_NEW_DICTIONARY_VALUE('mode', 'NORMAL', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Interconnector Nominations');
       PUT_NEW_DICTIONARY_VALUE('request_type', 'REPORT', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Interconnector Nominations');
       PUT_NEW_DICTIONARY_VALUE('action', 'DOWNLOAD', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Interconnector Nominations');
       PUT_NEW_DICTIONARY_VALUE('access_class', 'MP', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Interconnector Nominations');
       PUT_NEW_DICTIONARY_VALUE('file_type', 'XML', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Interconnector Nominations');
       PUT_NEW_DICTIONARY_VALUE('periodicity', 'DAILY', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Interconnector Nominations');
       PUT_NEW_DICTIONARY_VALUE('report_name', 'MP_D_IntconnNominations', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Interconnector Nominations');
       PUT_NEW_DICTIONARY_VALUE('file_name', 'MP_D_IntconnNominations_31012007.xml', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Interconnector Nominations');
       PUT_NEW_DICTIONARY_VALUE('report_type', 'MARKET', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Interconnector Nominations');
       PUT_NEW_DICTIONARY_VALUE('report_sub_type', 'DAY_AHEAD', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Interconnector Nominations');
       PUT_NEW_DICTIONARY_VALUE('version_no', '1.0', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Interconnector Nominations');
       PUT_NEW_DICTIONARY_VALUE('multiple_messages','false', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Interconnector Nominations');
       
--Creating SYSTEM_DICTIONARY entry for PUB_D_DispatchInstructions_13032007.xml

       -- *** INFO ***: TITLE length is 27 chars.
       PUT_NEW_DICTIONARY_VALUE('application_type', 'MARKET_REPORT', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Dispatch Instructions');
       PUT_NEW_DICTIONARY_VALUE('mode', 'NORMAL', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Dispatch Instructions');
       PUT_NEW_DICTIONARY_VALUE('request_type', 'REPORT', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Dispatch Instructions');
       PUT_NEW_DICTIONARY_VALUE('action', 'DOWNLOAD', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Dispatch Instructions');
       PUT_NEW_DICTIONARY_VALUE('access_class', 'PUB', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Dispatch Instructions');
       PUT_NEW_DICTIONARY_VALUE('file_type', 'XML', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Dispatch Instructions');
       PUT_NEW_DICTIONARY_VALUE('periodicity', 'DAILY', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Dispatch Instructions');
       PUT_NEW_DICTIONARY_VALUE('report_name', 'PUB_D_DispatchInstructions', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Dispatch Instructions');
       PUT_NEW_DICTIONARY_VALUE('file_name', 'PUB_D_DispatchInstructions_13032007.xml', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Dispatch Instructions');
       PUT_NEW_DICTIONARY_VALUE('report_type', 'MARKET', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Dispatch Instructions');
       PUT_NEW_DICTIONARY_VALUE('report_sub_type', 'DAY_AHEAD', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Dispatch Instructions');
       PUT_NEW_DICTIONARY_VALUE('version_no', '1.0', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Dispatch Instructions');
       PUT_NEW_DICTIONARY_VALUE('multiple_messages','false', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Dispatch Instructions');
       
--Creating SYSTEM_DICTIONARY entry for PUB_D_ExPostMktSchSummary_13032007.xml

       -- *** INFO ***: TITLE length is 48 chars.
       PUT_NEW_DICTIONARY_VALUE('application_type', 'MARKET_REPORT', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Indicative Ex-Post Market Schedule Summary');
       PUT_NEW_DICTIONARY_VALUE('mode', 'NORMAL', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Indicative Ex-Post Market Schedule Summary');
       PUT_NEW_DICTIONARY_VALUE('request_type', 'REPORT', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Indicative Ex-Post Market Schedule Summary');
       PUT_NEW_DICTIONARY_VALUE('action', 'DOWNLOAD', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Indicative Ex-Post Market Schedule Summary');
       PUT_NEW_DICTIONARY_VALUE('access_class', 'PUB', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Indicative Ex-Post Market Schedule Summary');
       PUT_NEW_DICTIONARY_VALUE('file_type', 'XML', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Indicative Ex-Post Market Schedule Summary');
       PUT_NEW_DICTIONARY_VALUE('periodicity', 'DAILY', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Indicative Ex-Post Market Schedule Summary');
       PUT_NEW_DICTIONARY_VALUE('report_name', 'PUB_D_ExPostMktSchSummary', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Indicative Ex-Post Market Schedule Summary');
       PUT_NEW_DICTIONARY_VALUE('file_name', 'PUB_D_ExPostMktSchSummary_13032007.xml', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Indicative Ex-Post Market Schedule Summary');
       PUT_NEW_DICTIONARY_VALUE('report_type', 'MARKET', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Indicative Ex-Post Market Schedule Summary');
       PUT_NEW_DICTIONARY_VALUE('report_sub_type', 'DAY_AHEAD', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Indicative Ex-Post Market Schedule Summary');
       PUT_NEW_DICTIONARY_VALUE('version_no', '1.0', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Indicative Ex-Post Market Schedule Summary');
       PUT_NEW_DICTIONARY_VALUE('multiple_messages','false', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Indicative Ex-Post Market Schedule Summary');
       
--Creating SYSTEM_DICTIONARY entry for MP_D_ExPostMktSchDetail_31012007.xml

       -- *** INFO ***: TITLE length is 47 chars.
       PUT_NEW_DICTIONARY_VALUE('application_type', 'MARKET_REPORT', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Indicative Ex-Post Market Schedule Detail');
       PUT_NEW_DICTIONARY_VALUE('mode', 'NORMAL', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Indicative Ex-Post Market Schedule Detail');
       PUT_NEW_DICTIONARY_VALUE('request_type', 'REPORT', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Indicative Ex-Post Market Schedule Detail');
       PUT_NEW_DICTIONARY_VALUE('action', 'DOWNLOAD', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Indicative Ex-Post Market Schedule Detail');
       PUT_NEW_DICTIONARY_VALUE('access_class', 'MP', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Indicative Ex-Post Market Schedule Detail');
       PUT_NEW_DICTIONARY_VALUE('file_type', 'XML', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Indicative Ex-Post Market Schedule Detail');
       PUT_NEW_DICTIONARY_VALUE('periodicity', 'DAILY', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Indicative Ex-Post Market Schedule Detail');
       PUT_NEW_DICTIONARY_VALUE('report_name', 'MP_D_ExPostMktSchDetail', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Indicative Ex-Post Market Schedule Detail');
       PUT_NEW_DICTIONARY_VALUE('file_name', 'MP_D_ExPostMktSchDetail_31012007.xml', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Indicative Ex-Post Market Schedule Detail');
       PUT_NEW_DICTIONARY_VALUE('report_type', 'MARKET', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Indicative Ex-Post Market Schedule Detail');
       PUT_NEW_DICTIONARY_VALUE('report_sub_type', 'DAY_AHEAD', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Indicative Ex-Post Market Schedule Detail');
       PUT_NEW_DICTIONARY_VALUE('version_no', '1.0', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Indicative Ex-Post Market Schedule Detail');
       PUT_NEW_DICTIONARY_VALUE('multiple_messages','false', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Indicative Ex-Post Market Schedule Detail');
       
--Creating SYSTEM_DICTIONARY entry for PUB_D_InitialExPostMktSchSummary_28022007.xml

       -- *** INFO ***: TITLE length is 53 chars.
       PUT_NEW_DICTIONARY_VALUE('application_type', 'MARKET_REPORT', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Initial Ex-Post Market Schedule Summary');
       PUT_NEW_DICTIONARY_VALUE('mode', 'NORMAL', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Initial Ex-Post Market Schedule Summary');
       PUT_NEW_DICTIONARY_VALUE('request_type', 'REPORT', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Initial Ex-Post Market Schedule Summary');
       PUT_NEW_DICTIONARY_VALUE('action', 'DOWNLOAD', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Initial Ex-Post Market Schedule Summary');
       PUT_NEW_DICTIONARY_VALUE('access_class', 'PUB', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Initial Ex-Post Market Schedule Summary');
       PUT_NEW_DICTIONARY_VALUE('file_type', 'XML', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Initial Ex-Post Market Schedule Summary');
       PUT_NEW_DICTIONARY_VALUE('periodicity', 'DAILY', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Initial Ex-Post Market Schedule Summary');
       PUT_NEW_DICTIONARY_VALUE('report_name', 'PUB_D_InitialExPostMktSchSummary', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Initial Ex-Post Market Schedule Summary');
       PUT_NEW_DICTIONARY_VALUE('file_name', 'PUB_D_InitialExPostMktSchSummary_28022007.xml', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Initial Ex-Post Market Schedule Summary');
       PUT_NEW_DICTIONARY_VALUE('report_type', 'MARKET', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Initial Ex-Post Market Schedule Summary');
       PUT_NEW_DICTIONARY_VALUE('report_sub_type', 'DAY_AHEAD', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Initial Ex-Post Market Schedule Summary');
       PUT_NEW_DICTIONARY_VALUE('version_no', '1.0', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Initial Ex-Post Market Schedule Summary');
       PUT_NEW_DICTIONARY_VALUE('multiple_messages','false', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Initial Ex-Post Market Schedule Summary');
       
--Creating SYSTEM_DICTIONARY entry for MP_D_InitialExPostMktSchDetail_07032007.xml

       -- *** INFO ***: TITLE length is 45 chars.
       PUT_NEW_DICTIONARY_VALUE('application_type', 'MARKET_REPORT', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Initial Ex-Post Market Schedule Details');
       PUT_NEW_DICTIONARY_VALUE('mode', 'NORMAL', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Initial Ex-Post Market Schedule Details');
       PUT_NEW_DICTIONARY_VALUE('request_type', 'REPORT', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Initial Ex-Post Market Schedule Details');
       PUT_NEW_DICTIONARY_VALUE('action', 'DOWNLOAD', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Initial Ex-Post Market Schedule Details');
       PUT_NEW_DICTIONARY_VALUE('access_class', 'MP', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Initial Ex-Post Market Schedule Details');
       PUT_NEW_DICTIONARY_VALUE('file_type', 'XML', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Initial Ex-Post Market Schedule Details');
       PUT_NEW_DICTIONARY_VALUE('periodicity', 'DAILY', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Initial Ex-Post Market Schedule Details');
       PUT_NEW_DICTIONARY_VALUE('report_name', 'MP_D_InitialExPostMktSchDetail', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Initial Ex-Post Market Schedule Details');
       PUT_NEW_DICTIONARY_VALUE('file_name', 'MP_D_InitialExPostMktSchDetail_07032007.xml', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Initial Ex-Post Market Schedule Details');
       PUT_NEW_DICTIONARY_VALUE('report_type', 'MARKET', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Initial Ex-Post Market Schedule Details');
       PUT_NEW_DICTIONARY_VALUE('report_sub_type', 'DAY_AHEAD', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Initial Ex-Post Market Schedule Details');
       PUT_NEW_DICTIONARY_VALUE('version_no', '1.0', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Initial Ex-Post Market Schedule Details');
       PUT_NEW_DICTIONARY_VALUE('multiple_messages','false', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Initial Ex-Post Market Schedule Details');
       
--Creating SYSTEM_DICTIONARY entry for PUB_D_MarketPricesAverages_31012007.xml

       -- *** INFO ***: TITLE length is 34 chars.
       PUT_NEW_DICTIONARY_VALUE('application_type', 'MARKET_REPORT', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Market Prices Averages (SMP)');
       PUT_NEW_DICTIONARY_VALUE('mode', 'NORMAL', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Market Prices Averages (SMP)');
       PUT_NEW_DICTIONARY_VALUE('request_type', 'REPORT', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Market Prices Averages (SMP)');
       PUT_NEW_DICTIONARY_VALUE('action', 'DOWNLOAD', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Market Prices Averages (SMP)');
       PUT_NEW_DICTIONARY_VALUE('access_class', 'PUB', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Market Prices Averages (SMP)');
       PUT_NEW_DICTIONARY_VALUE('file_type', 'XML', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Market Prices Averages (SMP)');
       PUT_NEW_DICTIONARY_VALUE('periodicity', 'DAILY', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Market Prices Averages (SMP)');
       PUT_NEW_DICTIONARY_VALUE('report_name', 'PUB_D_MarketPricesAverages', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Market Prices Averages (SMP)');
       PUT_NEW_DICTIONARY_VALUE('file_name', 'PUB_D_MarketPricesAverages_31012007.xml', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Market Prices Averages (SMP)');
       PUT_NEW_DICTIONARY_VALUE('report_type', 'MARKET', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Market Prices Averages (SMP)');
       PUT_NEW_DICTIONARY_VALUE('report_sub_type', 'DAY_AHEAD', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Market Prices Averages (SMP)');
       PUT_NEW_DICTIONARY_VALUE('version_no', '1.0', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Market Prices Averages (SMP)');
       PUT_NEW_DICTIONARY_VALUE('multiple_messages','false', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Market Prices Averages (SMP)');
       
--Creating SYSTEM_DICTIONARY entry for PUB_D_IndicativeMarketPrices_14032007.xml

       -- *** INFO ***: TITLE length is 30 chars.
       PUT_NEW_DICTIONARY_VALUE('application_type', 'MARKET_REPORT', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Indicative Market Prices');
       PUT_NEW_DICTIONARY_VALUE('mode', 'NORMAL', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Indicative Market Prices');
       PUT_NEW_DICTIONARY_VALUE('request_type', 'REPORT', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Indicative Market Prices');
       PUT_NEW_DICTIONARY_VALUE('action', 'DOWNLOAD', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Indicative Market Prices');
       PUT_NEW_DICTIONARY_VALUE('access_class', 'PUB', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Indicative Market Prices');
       PUT_NEW_DICTIONARY_VALUE('file_type', 'XML', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Indicative Market Prices');
       PUT_NEW_DICTIONARY_VALUE('periodicity', 'DAILY', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Indicative Market Prices');
       PUT_NEW_DICTIONARY_VALUE('report_name', 'PUB_D_IndicativeMarketPrices', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Indicative Market Prices');
       PUT_NEW_DICTIONARY_VALUE('file_name', 'PUB_D_IndicativeMarketPrices_14032007.xml', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Indicative Market Prices');
       PUT_NEW_DICTIONARY_VALUE('report_type', 'MARKET', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Indicative Market Prices');
       PUT_NEW_DICTIONARY_VALUE('report_sub_type', 'DAY_AHEAD', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Indicative Market Prices');
       PUT_NEW_DICTIONARY_VALUE('version_no', '1.0', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Indicative Market Prices');
       PUT_NEW_DICTIONARY_VALUE('multiple_messages','false', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Indicative Market Prices');
       
--Creating SYSTEM_DICTIONARY entry for PUB_D_InitialMarketPrices_31012007.xml

       -- *** INFO ***: TITLE length is 35 chars.
       PUT_NEW_DICTIONARY_VALUE('application_type', 'MARKET_REPORT', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Initial Ex-Post Market Prices');
       PUT_NEW_DICTIONARY_VALUE('mode', 'NORMAL', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Initial Ex-Post Market Prices');
       PUT_NEW_DICTIONARY_VALUE('request_type', 'REPORT', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Initial Ex-Post Market Prices');
       PUT_NEW_DICTIONARY_VALUE('action', 'DOWNLOAD', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Initial Ex-Post Market Prices');
       PUT_NEW_DICTIONARY_VALUE('access_class', 'PUB', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Initial Ex-Post Market Prices');
       PUT_NEW_DICTIONARY_VALUE('file_type', 'XML', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Initial Ex-Post Market Prices');
       PUT_NEW_DICTIONARY_VALUE('periodicity', 'DAILY', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Initial Ex-Post Market Prices');
       PUT_NEW_DICTIONARY_VALUE('report_name', 'PUB_D_InitialMarketPrices', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Initial Ex-Post Market Prices');
       PUT_NEW_DICTIONARY_VALUE('file_name', 'PUB_D_InitialMarketPrices_31012007.xml', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Initial Ex-Post Market Prices');
       PUT_NEW_DICTIONARY_VALUE('report_type', 'MARKET', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Initial Ex-Post Market Prices');
       PUT_NEW_DICTIONARY_VALUE('report_sub_type', 'DAY_AHEAD', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Initial Ex-Post Market Prices');
       PUT_NEW_DICTIONARY_VALUE('version_no', '1.0', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Initial Ex-Post Market Prices');
       PUT_NEW_DICTIONARY_VALUE('multiple_messages','false', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Initial Ex-Post Market Prices');
       
--Creating SYSTEM_DICTIONARY entry for PUB_D_MeterDataSummaryD1_01032007.xml

       -- *** INFO ***: TITLE length is 30 chars.
       PUT_NEW_DICTIONARY_VALUE('application_type', 'MARKET_REPORT', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Meter Data Summary (D+1)');
       PUT_NEW_DICTIONARY_VALUE('mode', 'NORMAL', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Meter Data Summary (D+1)');
       PUT_NEW_DICTIONARY_VALUE('request_type', 'REPORT', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Meter Data Summary (D+1)');
       PUT_NEW_DICTIONARY_VALUE('action', 'DOWNLOAD', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Meter Data Summary (D+1)');
       PUT_NEW_DICTIONARY_VALUE('access_class', 'PUB', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Meter Data Summary (D+1)');
       PUT_NEW_DICTIONARY_VALUE('file_type', 'XML', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Meter Data Summary (D+1)');
       PUT_NEW_DICTIONARY_VALUE('periodicity', 'DAILY', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Meter Data Summary (D+1)');
       PUT_NEW_DICTIONARY_VALUE('report_name', 'PUB_D_MeterDataSummaryD1', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Meter Data Summary (D+1)');
       PUT_NEW_DICTIONARY_VALUE('file_name', 'PUB_D_MeterDataSummaryD1_01032007.xml', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Meter Data Summary (D+1)');
       PUT_NEW_DICTIONARY_VALUE('report_type', 'MARKET', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Meter Data Summary (D+1)');
       PUT_NEW_DICTIONARY_VALUE('report_sub_type', 'METERING', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Meter Data Summary (D+1)');
       PUT_NEW_DICTIONARY_VALUE('version_no', '1.0', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Meter Data Summary (D+1)');
       PUT_NEW_DICTIONARY_VALUE('multiple_messages','false', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Meter Data Summary (D+1)');
       
--Creating SYSTEM_DICTIONARY entry for MP_D_MeterDataDetailD1_15032007.xml

       -- *** INFO ***: TITLE length is 29 chars.
       PUT_NEW_DICTIONARY_VALUE('application_type', 'MARKET_REPORT', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Meter Data Detail (D+1)');
       PUT_NEW_DICTIONARY_VALUE('mode', 'NORMAL', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Meter Data Detail (D+1)');
       PUT_NEW_DICTIONARY_VALUE('request_type', 'REPORT', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Meter Data Detail (D+1)');
       PUT_NEW_DICTIONARY_VALUE('action', 'DOWNLOAD', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Meter Data Detail (D+1)');
       PUT_NEW_DICTIONARY_VALUE('access_class', 'MP', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Meter Data Detail (D+1)');
       PUT_NEW_DICTIONARY_VALUE('file_type', 'XML', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Meter Data Detail (D+1)');
       PUT_NEW_DICTIONARY_VALUE('periodicity', 'DAILY', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Meter Data Detail (D+1)');
       PUT_NEW_DICTIONARY_VALUE('report_name', 'MP_D_MeterDataDetailD1', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Meter Data Detail (D+1)');
       PUT_NEW_DICTIONARY_VALUE('file_name', 'MP_D_MeterDataDetailD1_15032007.xml', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Meter Data Detail (D+1)');
       PUT_NEW_DICTIONARY_VALUE('report_type', 'MARKET', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Meter Data Detail (D+1)');
       PUT_NEW_DICTIONARY_VALUE('report_sub_type', 'METERING', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Meter Data Detail (D+1)');
       PUT_NEW_DICTIONARY_VALUE('version_no', '1.0', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Meter Data Detail (D+1)');
       PUT_NEW_DICTIONARY_VALUE('multiple_messages','false', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Meter Data Detail (D+1)');
       
--Creating SYSTEM_DICTIONARY entry for PUB_D_MeterDataSummaryD3_01032007.xml

       -- *** INFO ***: TITLE length is 30 chars.
       PUT_NEW_DICTIONARY_VALUE('application_type', 'MARKET_REPORT', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Meter Data Summary (D+3)');
       PUT_NEW_DICTIONARY_VALUE('mode', 'NORMAL', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Meter Data Summary (D+3)');
       PUT_NEW_DICTIONARY_VALUE('request_type', 'REPORT', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Meter Data Summary (D+3)');
       PUT_NEW_DICTIONARY_VALUE('action', 'DOWNLOAD', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Meter Data Summary (D+3)');
       PUT_NEW_DICTIONARY_VALUE('access_class', 'PUB', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Meter Data Summary (D+3)');
       PUT_NEW_DICTIONARY_VALUE('file_type', 'XML', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Meter Data Summary (D+3)');
       PUT_NEW_DICTIONARY_VALUE('periodicity', 'DAILY', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Meter Data Summary (D+3)');
       PUT_NEW_DICTIONARY_VALUE('report_name', 'PUB_D_MeterDataSummaryD3', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Meter Data Summary (D+3)');
       PUT_NEW_DICTIONARY_VALUE('file_name', 'PUB_D_MeterDataSummaryD3_01032007.xml', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Meter Data Summary (D+3)');
       PUT_NEW_DICTIONARY_VALUE('report_type', 'MARKET', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Meter Data Summary (D+3)');
       PUT_NEW_DICTIONARY_VALUE('report_sub_type', 'METERING', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Meter Data Summary (D+3)');
       PUT_NEW_DICTIONARY_VALUE('version_no', '1.0', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Meter Data Summary (D+3)');
       PUT_NEW_DICTIONARY_VALUE('multiple_messages','false', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Meter Data Summary (D+3)');
       
--Creating SYSTEM_DICTIONARY entry for MP_D_MeterDataDetailD3_15032007.xml

       -- *** INFO ***: TITLE length is 29 chars.
       PUT_NEW_DICTIONARY_VALUE('application_type', 'MARKET_REPORT', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Meter Data Detail (D+3)');
       PUT_NEW_DICTIONARY_VALUE('mode', 'NORMAL', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Meter Data Detail (D+3)');
       PUT_NEW_DICTIONARY_VALUE('request_type', 'REPORT', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Meter Data Detail (D+3)');
       PUT_NEW_DICTIONARY_VALUE('action', 'DOWNLOAD', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Meter Data Detail (D+3)');
       PUT_NEW_DICTIONARY_VALUE('access_class', 'MP', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Meter Data Detail (D+3)');
       PUT_NEW_DICTIONARY_VALUE('file_type', 'XML', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Meter Data Detail (D+3)');
       PUT_NEW_DICTIONARY_VALUE('periodicity', 'DAILY', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Meter Data Detail (D+3)');
       PUT_NEW_DICTIONARY_VALUE('report_name', 'MP_D_MeterDataDetailD3', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Meter Data Detail (D+3)');
       PUT_NEW_DICTIONARY_VALUE('file_name', 'MP_D_MeterDataDetailD3_15032007.xml', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Meter Data Detail (D+3)');
       PUT_NEW_DICTIONARY_VALUE('report_type', 'MARKET', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Meter Data Detail (D+3)');
       PUT_NEW_DICTIONARY_VALUE('report_sub_type', 'METERING', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Meter Data Detail (D+3)');
       PUT_NEW_DICTIONARY_VALUE('version_no', '1.0', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Meter Data Detail (D+3)');
       PUT_NEW_DICTIONARY_VALUE('multiple_messages','false', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Meter Data Detail (D+3)');
       
--Creating SYSTEM_DICTIONARY entry for PUB_D_AdvInfo_31012007.xml

       -- *** INFO ***: TITLE length is 37 chars.
       PUT_NEW_DICTIONARY_VALUE('application_type', 'MARKET_REPORT', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Market Operations Notifications');
       PUT_NEW_DICTIONARY_VALUE('mode', 'NORMAL', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Market Operations Notifications');
       PUT_NEW_DICTIONARY_VALUE('request_type', 'REPORT', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Market Operations Notifications');
       PUT_NEW_DICTIONARY_VALUE('action', 'DOWNLOAD', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Market Operations Notifications');
       PUT_NEW_DICTIONARY_VALUE('access_class', 'PUB', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Market Operations Notifications');
       PUT_NEW_DICTIONARY_VALUE('file_type', 'XML', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Market Operations Notifications');
       PUT_NEW_DICTIONARY_VALUE('periodicity', 'DAILY', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Market Operations Notifications');
       PUT_NEW_DICTIONARY_VALUE('report_name', 'PUB_D_AdvInfo', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Market Operations Notifications');
       PUT_NEW_DICTIONARY_VALUE('file_name', 'PUB_D_AdvInfo_31012007.xml', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Market Operations Notifications');
       PUT_NEW_DICTIONARY_VALUE('report_type', 'APPLICATION', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Market Operations Notifications');
       PUT_NEW_DICTIONARY_VALUE('report_sub_type', 'NOTIFICATIONS', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Market Operations Notifications');
       PUT_NEW_DICTIONARY_VALUE('version_no', '1.0', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Market Operations Notifications');
       PUT_NEW_DICTIONARY_VALUE('multiple_messages','false', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Market Operations Notifications');
       
--Creating SYSTEM_DICTIONARY entry for PUB_D_ActualLoadSummary_13032007.xml

       -- *** INFO ***: TITLE length is 25 chars.
       PUT_NEW_DICTIONARY_VALUE('application_type', 'MARKET_REPORT', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Actual Load Summary');
       PUT_NEW_DICTIONARY_VALUE('mode', 'NORMAL', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Actual Load Summary');
       PUT_NEW_DICTIONARY_VALUE('request_type', 'REPORT', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Actual Load Summary');
       PUT_NEW_DICTIONARY_VALUE('action', 'DOWNLOAD', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Actual Load Summary');
       PUT_NEW_DICTIONARY_VALUE('access_class', 'PUB', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Actual Load Summary');
       PUT_NEW_DICTIONARY_VALUE('file_type', 'XML', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Actual Load Summary');
       PUT_NEW_DICTIONARY_VALUE('periodicity', 'DAILY', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Actual Load Summary');
       PUT_NEW_DICTIONARY_VALUE('report_name', 'PUB_D_ActualLoadSummary', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Actual Load Summary');
       PUT_NEW_DICTIONARY_VALUE('file_name', 'PUB_D_ActualLoadSummary_13032007.xml', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Actual Load Summary');
       PUT_NEW_DICTIONARY_VALUE('report_type', 'MARKET', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Actual Load Summary');
       PUT_NEW_DICTIONARY_VALUE('report_sub_type', 'DAY_AHEAD', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Actual Load Summary');
       PUT_NEW_DICTIONARY_VALUE('version_no', '1.0', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Actual Load Summary');
       PUT_NEW_DICTIONARY_VALUE('multiple_messages','false', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Actual Load Summary');
       
--Creating SYSTEM_DICTIONARY entry for MP_D_AggIntconnUsrNominations_15032007.xml

       -- *** INFO ***: TITLE length is 48 chars.
       PUT_NEW_DICTIONARY_VALUE('application_type', 'MARKET_REPORT', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Aggregated Interconnector User Nominations');
       PUT_NEW_DICTIONARY_VALUE('mode', 'NORMAL', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Aggregated Interconnector User Nominations');
       PUT_NEW_DICTIONARY_VALUE('request_type', 'REPORT', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Aggregated Interconnector User Nominations');
       PUT_NEW_DICTIONARY_VALUE('action', 'DOWNLOAD', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Aggregated Interconnector User Nominations');
       PUT_NEW_DICTIONARY_VALUE('access_class', 'MP', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Aggregated Interconnector User Nominations');
       PUT_NEW_DICTIONARY_VALUE('file_type', 'XML', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Aggregated Interconnector User Nominations');
       PUT_NEW_DICTIONARY_VALUE('periodicity', 'DAILY', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Aggregated Interconnector User Nominations');
       PUT_NEW_DICTIONARY_VALUE('report_name', 'MP_D_AggIntconnUsrNominations', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Aggregated Interconnector User Nominations');
       PUT_NEW_DICTIONARY_VALUE('file_name', 'MP_D_AggIntconnUsrNominations_15032007.xml', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Aggregated Interconnector User Nominations');
       PUT_NEW_DICTIONARY_VALUE('report_type', 'TRANS_SYSTEM', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Aggregated Interconnector User Nominations');
       PUT_NEW_DICTIONARY_VALUE('report_sub_type', 'INTERCONNECTOR', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Aggregated Interconnector User Nominations');
       PUT_NEW_DICTIONARY_VALUE('version_no', '1.0', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Aggregated Interconnector User Nominations');
       PUT_NEW_DICTIONARY_VALUE('multiple_messages','false', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Aggregated Interconnector User Nominations');
       
--Creating SYSTEM_DICTIONARY entry for MP_D_ExAnteIntconnNominations_05022007.xml

       -- *** INFO ***: TITLE length is 40 chars.
       PUT_NEW_DICTIONARY_VALUE('application_type', 'MARKET_REPORT', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Ex-Ante Interconnector Nominations');
       PUT_NEW_DICTIONARY_VALUE('mode', 'NORMAL', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Ex-Ante Interconnector Nominations');
       PUT_NEW_DICTIONARY_VALUE('request_type', 'REPORT', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Ex-Ante Interconnector Nominations');
       PUT_NEW_DICTIONARY_VALUE('action', 'DOWNLOAD', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Ex-Ante Interconnector Nominations');
       PUT_NEW_DICTIONARY_VALUE('access_class', 'MP', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Ex-Ante Interconnector Nominations');
       PUT_NEW_DICTIONARY_VALUE('file_type', 'XML', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Ex-Ante Interconnector Nominations');
       PUT_NEW_DICTIONARY_VALUE('periodicity', 'DAILY', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Ex-Ante Interconnector Nominations');
       PUT_NEW_DICTIONARY_VALUE('report_name', 'MP_D_ExAnteIntconnNominations', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Ex-Ante Interconnector Nominations');
       PUT_NEW_DICTIONARY_VALUE('file_name', 'MP_D_ExAnteIntconnNominations_05022007.xml', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Ex-Ante Interconnector Nominations');
       PUT_NEW_DICTIONARY_VALUE('report_type', 'TRANS_SYSTEM', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Ex-Ante Interconnector Nominations');
       PUT_NEW_DICTIONARY_VALUE('report_sub_type', 'INTERCONNECTOR', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Ex-Ante Interconnector Nominations');
       PUT_NEW_DICTIONARY_VALUE('version_no', '1.0', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Ex-Ante Interconnector Nominations');
       PUT_NEW_DICTIONARY_VALUE('multiple_messages','false', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Ex-Ante Interconnector Nominations');
       
--Creating SYSTEM_DICTIONARY entry for MP_D_ExPostIndIntconnNominations_05022007.xml

       -- *** INFO ***: TITLE length is 51 chars.
       PUT_NEW_DICTIONARY_VALUE('application_type', 'MARKET_REPORT', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Ex-Post Indicative Interconnector Nominations');
       PUT_NEW_DICTIONARY_VALUE('mode', 'NORMAL', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Ex-Post Indicative Interconnector Nominations');
       PUT_NEW_DICTIONARY_VALUE('request_type', 'REPORT', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Ex-Post Indicative Interconnector Nominations');
       PUT_NEW_DICTIONARY_VALUE('action', 'DOWNLOAD', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Ex-Post Indicative Interconnector Nominations');
       PUT_NEW_DICTIONARY_VALUE('access_class', 'MP', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Ex-Post Indicative Interconnector Nominations');
       PUT_NEW_DICTIONARY_VALUE('file_type', 'XML', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Ex-Post Indicative Interconnector Nominations');
       PUT_NEW_DICTIONARY_VALUE('periodicity', 'DAILY', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Ex-Post Indicative Interconnector Nominations');
       PUT_NEW_DICTIONARY_VALUE('report_name', 'MP_D_ExPostIndIntconnNominations', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Ex-Post Indicative Interconnector Nominations');
       PUT_NEW_DICTIONARY_VALUE('file_name', 'MP_D_ExPostIndIntconnNominations_05022007.xml', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Ex-Post Indicative Interconnector Nominations');
       PUT_NEW_DICTIONARY_VALUE('report_type', 'TRANS_SYSTEM', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Ex-Post Indicative Interconnector Nominations');
       PUT_NEW_DICTIONARY_VALUE('report_sub_type', 'INTERCONNECTOR', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Ex-Post Indicative Interconnector Nominations');
       PUT_NEW_DICTIONARY_VALUE('version_no', '1.0', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Ex-Post Indicative Interconnector Nominations');
       PUT_NEW_DICTIONARY_VALUE('multiple_messages','false', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Ex-Post Indicative Interconnector Nominations');
       
--Creating SYSTEM_DICTIONARY entry for MP_D_ExPostInitIntconnNominations_05022007.xml

       -- *** INFO ***: TITLE length is 48 chars.
       PUT_NEW_DICTIONARY_VALUE('application_type', 'MARKET_REPORT', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Ex-Post Initial Interconnector Nominations');
       PUT_NEW_DICTIONARY_VALUE('mode', 'NORMAL', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Ex-Post Initial Interconnector Nominations');
       PUT_NEW_DICTIONARY_VALUE('request_type', 'REPORT', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Ex-Post Initial Interconnector Nominations');
       PUT_NEW_DICTIONARY_VALUE('action', 'DOWNLOAD', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Ex-Post Initial Interconnector Nominations');
       PUT_NEW_DICTIONARY_VALUE('access_class', 'MP', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Ex-Post Initial Interconnector Nominations');
       PUT_NEW_DICTIONARY_VALUE('file_type', 'XML', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Ex-Post Initial Interconnector Nominations');
       PUT_NEW_DICTIONARY_VALUE('periodicity', 'DAILY', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Ex-Post Initial Interconnector Nominations');
       PUT_NEW_DICTIONARY_VALUE('report_name', 'MP_D_ExPostInitIntconnNominations', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Ex-Post Initial Interconnector Nominations');
       PUT_NEW_DICTIONARY_VALUE('file_name', 'MP_D_ExPostInitIntconnNominations_05022007.xml', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Ex-Post Initial Interconnector Nominations');
       PUT_NEW_DICTIONARY_VALUE('report_type', 'TRANS_SYSTEM', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Ex-Post Initial Interconnector Nominations');
       PUT_NEW_DICTIONARY_VALUE('report_sub_type', 'INTERCONNECTOR', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Ex-Post Initial Interconnector Nominations');
       PUT_NEW_DICTIONARY_VALUE('version_no', '1.0', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Ex-Post Initial Interconnector Nominations');
       PUT_NEW_DICTIONARY_VALUE('multiple_messages','false', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Ex-Post Initial Interconnector Nominations');
       
--Creating SYSTEM_DICTIONARY entry for MP_D_IntconnModNominations_05022007.xml

       -- *** INFO ***: TITLE length is 41 chars.
       PUT_NEW_DICTIONARY_VALUE('application_type', 'MARKET_REPORT', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Interconnector Modified Nominations');
       PUT_NEW_DICTIONARY_VALUE('mode', 'NORMAL', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Interconnector Modified Nominations');
       PUT_NEW_DICTIONARY_VALUE('request_type', 'REPORT', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Interconnector Modified Nominations');
       PUT_NEW_DICTIONARY_VALUE('action', 'DOWNLOAD', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Interconnector Modified Nominations');
       PUT_NEW_DICTIONARY_VALUE('access_class', 'MP', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Interconnector Modified Nominations');
       PUT_NEW_DICTIONARY_VALUE('file_type', 'XML', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Interconnector Modified Nominations');
       PUT_NEW_DICTIONARY_VALUE('periodicity', 'DAILY', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Interconnector Modified Nominations');
       PUT_NEW_DICTIONARY_VALUE('report_name', 'MP_D_IntconnModNominations', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Interconnector Modified Nominations');
       PUT_NEW_DICTIONARY_VALUE('file_name', 'MP_D_IntconnModNominations_05022007.xml', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Interconnector Modified Nominations');
       PUT_NEW_DICTIONARY_VALUE('report_type', 'TRANS_SYSTEM', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Interconnector Modified Nominations');
       PUT_NEW_DICTIONARY_VALUE('report_sub_type', 'INTERCONNECTOR', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Interconnector Modified Nominations');
       PUT_NEW_DICTIONARY_VALUE('version_no', '1.0', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Interconnector Modified Nominations');
       PUT_NEW_DICTIONARY_VALUE('multiple_messages','false', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Interconnector Modified Nominations');
       
--Creating SYSTEM_DICTIONARY entry for MP_D_RevIntconnModNominations_05022007.xml

       -- *** INFO ***: TITLE length is 49 chars.
       PUT_NEW_DICTIONARY_VALUE('application_type', 'MARKET_REPORT', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Revised Interconnector Modified Nominations');
       PUT_NEW_DICTIONARY_VALUE('mode', 'NORMAL', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Revised Interconnector Modified Nominations');
       PUT_NEW_DICTIONARY_VALUE('request_type', 'REPORT', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Revised Interconnector Modified Nominations');
       PUT_NEW_DICTIONARY_VALUE('action', 'DOWNLOAD', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Revised Interconnector Modified Nominations');
       PUT_NEW_DICTIONARY_VALUE('access_class', 'MP', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Revised Interconnector Modified Nominations');
       PUT_NEW_DICTIONARY_VALUE('file_type', 'XML', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Revised Interconnector Modified Nominations');
       PUT_NEW_DICTIONARY_VALUE('periodicity', 'DAILY', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Revised Interconnector Modified Nominations');
       PUT_NEW_DICTIONARY_VALUE('report_name', 'MP_D_RevIntconnModNominations', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Revised Interconnector Modified Nominations');
       PUT_NEW_DICTIONARY_VALUE('file_name', 'MP_D_RevIntconnModNominations_05022007.xml', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Revised Interconnector Modified Nominations');
       PUT_NEW_DICTIONARY_VALUE('report_type', 'TRANS_SYSTEM', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Revised Interconnector Modified Nominations');
       PUT_NEW_DICTIONARY_VALUE('report_sub_type', 'INTERCONNECTOR', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Revised Interconnector Modified Nominations');
       PUT_NEW_DICTIONARY_VALUE('version_no', '1.0', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Revised Interconnector Modified Nominations');
       PUT_NEW_DICTIONARY_VALUE('multiple_messages','false', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Revised Interconnector Modified Nominations');
       
--Creating SYSTEM_DICTIONARY entry for PUB_ActiveMPUnits_02022007.xml

       -- *** INFO ***: TITLE length is 44 chars.
       PUT_NEW_DICTIONARY_VALUE('application_type', 'MARKET_REPORT', 0, 'MarketExchange', 'SEM','SMO Reports','List of Active Market Participants and Units');
       PUT_NEW_DICTIONARY_VALUE('mode', 'NORMAL', 0, 'MarketExchange', 'SEM','SMO Reports','List of Active Market Participants and Units');
       PUT_NEW_DICTIONARY_VALUE('request_type', 'REPORT', 0, 'MarketExchange', 'SEM','SMO Reports','List of Active Market Participants and Units');
       PUT_NEW_DICTIONARY_VALUE('action', 'DOWNLOAD', 0, 'MarketExchange', 'SEM','SMO Reports','List of Active Market Participants and Units');
       PUT_NEW_DICTIONARY_VALUE('access_class', 'PUB', 0, 'MarketExchange', 'SEM','SMO Reports','List of Active Market Participants and Units');
       PUT_NEW_DICTIONARY_VALUE('file_type', 'XML', 0, 'MarketExchange', 'SEM','SMO Reports','List of Active Market Participants and Units');
       PUT_NEW_DICTIONARY_VALUE('periodicity', 'DAILY', 0, 'MarketExchange', 'SEM','SMO Reports','List of Active Market Participants and Units');
       PUT_NEW_DICTIONARY_VALUE('report_name', 'PUB_ActiveMPUnits', 0, 'MarketExchange', 'SEM','SMO Reports','List of Active Market Participants and Units');
       PUT_NEW_DICTIONARY_VALUE('file_name', 'PUB_ActiveMPUnits_02022007.xml', 0, 'MarketExchange', 'SEM','SMO Reports','List of Active Market Participants and Units');
       PUT_NEW_DICTIONARY_VALUE('report_type', 'REGISTRATION', 0, 'MarketExchange', 'SEM','SMO Reports','List of Active Market Participants and Units');
       PUT_NEW_DICTIONARY_VALUE('report_sub_type', 'MP_ACTIVITY', 0, 'MarketExchange', 'SEM','SMO Reports','List of Active Market Participants and Units');
       PUT_NEW_DICTIONARY_VALUE('version_no', '1.0', 0, 'MarketExchange', 'SEM','SMO Reports','List of Active Market Participants and Units');
       PUT_NEW_DICTIONARY_VALUE('multiple_messages','false', 0, 'MarketExchange', 'SEM','SMO Reports','List of Active Market Participants and Units');
       
--Creating SYSTEM_DICTIONARY entry for PUB_D_IntconnCapActHoldResults_02022007.xml

       -- *** INFO ***: TITLE length is 45 chars.
       PUT_NEW_DICTIONARY_VALUE('application_type', 'MARKET_REPORT', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Interconnector Capacity Active Holdings');
       PUT_NEW_DICTIONARY_VALUE('mode', 'NORMAL', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Interconnector Capacity Active Holdings');
       PUT_NEW_DICTIONARY_VALUE('request_type', 'REPORT', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Interconnector Capacity Active Holdings');
       PUT_NEW_DICTIONARY_VALUE('action', 'DOWNLOAD', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Interconnector Capacity Active Holdings');
       PUT_NEW_DICTIONARY_VALUE('access_class', 'PUB', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Interconnector Capacity Active Holdings');
       PUT_NEW_DICTIONARY_VALUE('file_type', 'XML', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Interconnector Capacity Active Holdings');
       PUT_NEW_DICTIONARY_VALUE('periodicity', 'DAILY', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Interconnector Capacity Active Holdings');
       PUT_NEW_DICTIONARY_VALUE('report_name', 'PUB_D_IntconnCapActHoldResults', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Interconnector Capacity Active Holdings');
       PUT_NEW_DICTIONARY_VALUE('file_name', 'PUB_D_IntconnCapActHoldResults_02022007.xml', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Interconnector Capacity Active Holdings');
       PUT_NEW_DICTIONARY_VALUE('report_type', 'TRANS_SYSTEM', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Interconnector Capacity Active Holdings');
       PUT_NEW_DICTIONARY_VALUE('report_sub_type', 'INTERCONNECTOR', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Interconnector Capacity Active Holdings');
       PUT_NEW_DICTIONARY_VALUE('version_no', '1.0', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Interconnector Capacity Active Holdings');
       PUT_NEW_DICTIONARY_VALUE('multiple_messages','false', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Interconnector Capacity Active Holdings');
       
--Creating SYSTEM_DICTIONARY entry for PUB_D_IntconnCapHoldResults_02022007.xml

       -- *** INFO ***: TITLE length is 38 chars.
       PUT_NEW_DICTIONARY_VALUE('application_type', 'MARKET_REPORT', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Interconnector Capacity Holdings');
       PUT_NEW_DICTIONARY_VALUE('mode', 'NORMAL', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Interconnector Capacity Holdings');
       PUT_NEW_DICTIONARY_VALUE('request_type', 'REPORT', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Interconnector Capacity Holdings');
       PUT_NEW_DICTIONARY_VALUE('action', 'DOWNLOAD', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Interconnector Capacity Holdings');
       PUT_NEW_DICTIONARY_VALUE('access_class', 'PUB', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Interconnector Capacity Holdings');
       PUT_NEW_DICTIONARY_VALUE('file_type', 'XML', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Interconnector Capacity Holdings');
       PUT_NEW_DICTIONARY_VALUE('periodicity', 'DAILY', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Interconnector Capacity Holdings');
       PUT_NEW_DICTIONARY_VALUE('report_name', 'PUB_D_IntconnCapHoldResults', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Interconnector Capacity Holdings');
       PUT_NEW_DICTIONARY_VALUE('file_name', 'PUB_D_IntconnCapHoldResults_02022007.xml', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Interconnector Capacity Holdings');
       PUT_NEW_DICTIONARY_VALUE('report_type', 'TRANS_SYSTEM', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Interconnector Capacity Holdings');
       PUT_NEW_DICTIONARY_VALUE('report_sub_type', 'INTERCONNECTOR', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Interconnector Capacity Holdings');
       PUT_NEW_DICTIONARY_VALUE('version_no', '1.0', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Interconnector Capacity Holdings');
       PUT_NEW_DICTIONARY_VALUE('multiple_messages','false', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Interconnector Capacity Holdings');
       
--Creating SYSTEM_DICTIONARY entry for PUB_D_LoadFcstAssumptions_14032007.xml

       -- *** INFO ***: TITLE length is 58 chars.
       PUT_NEW_DICTIONARY_VALUE('application_type', 'MARKET_REPORT', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Four Day Rolling Load Forecast and Assumptions (D+4)');
       PUT_NEW_DICTIONARY_VALUE('mode', 'NORMAL', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Four Day Rolling Load Forecast and Assumptions (D+4)');
       PUT_NEW_DICTIONARY_VALUE('request_type', 'REPORT', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Four Day Rolling Load Forecast and Assumptions (D+4)');
       PUT_NEW_DICTIONARY_VALUE('action', 'DOWNLOAD', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Four Day Rolling Load Forecast and Assumptions (D+4)');
       PUT_NEW_DICTIONARY_VALUE('access_class', 'PUB', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Four Day Rolling Load Forecast and Assumptions (D+4)');
       PUT_NEW_DICTIONARY_VALUE('file_type', 'XML', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Four Day Rolling Load Forecast and Assumptions (D+4)');
       PUT_NEW_DICTIONARY_VALUE('periodicity', 'DAILY', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Four Day Rolling Load Forecast and Assumptions (D+4)');
       PUT_NEW_DICTIONARY_VALUE('report_name', 'PUB_D_LoadFcstAssumptions', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Four Day Rolling Load Forecast and Assumptions (D+4)');
       PUT_NEW_DICTIONARY_VALUE('file_name', 'PUB_D_LoadFcstAssumptions_14032007.xml', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Four Day Rolling Load Forecast and Assumptions (D+4)');
       PUT_NEW_DICTIONARY_VALUE('report_type', 'TRANS_SYSTEM', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Four Day Rolling Load Forecast and Assumptions (D+4)');
       PUT_NEW_DICTIONARY_VALUE('report_sub_type', 'FORECASTS', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Four Day Rolling Load Forecast and Assumptions (D+4)');
       PUT_NEW_DICTIONARY_VALUE('version_no', '1.0', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Four Day Rolling Load Forecast and Assumptions (D+4)');
       PUT_NEW_DICTIONARY_VALUE('multiple_messages','false', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Four Day Rolling Load Forecast and Assumptions (D+4)');
       
--Creating SYSTEM_DICTIONARY entry for PUB_D_RevIntconnATCData_02022007.xml

       -- *** INFO ***: TITLE length is 37 chars.
       PUT_NEW_DICTIONARY_VALUE('application_type', 'MARKET_REPORT', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Revised Interconnector ATC Data');
       PUT_NEW_DICTIONARY_VALUE('mode', 'NORMAL', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Revised Interconnector ATC Data');
       PUT_NEW_DICTIONARY_VALUE('request_type', 'REPORT', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Revised Interconnector ATC Data');
       PUT_NEW_DICTIONARY_VALUE('action', 'DOWNLOAD', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Revised Interconnector ATC Data');
       PUT_NEW_DICTIONARY_VALUE('access_class', 'PUB', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Revised Interconnector ATC Data');
       PUT_NEW_DICTIONARY_VALUE('file_type', 'XML', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Revised Interconnector ATC Data');
       PUT_NEW_DICTIONARY_VALUE('periodicity', 'DAILY', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Revised Interconnector ATC Data');
       PUT_NEW_DICTIONARY_VALUE('report_name', 'PUB_D_RevIntconnATCData', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Revised Interconnector ATC Data');
       PUT_NEW_DICTIONARY_VALUE('file_name', 'PUB_D_RevIntconnATCData_02022007.xml', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Revised Interconnector ATC Data');
       PUT_NEW_DICTIONARY_VALUE('report_type', 'TRANS_SYSTEM', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Revised Interconnector ATC Data');
       PUT_NEW_DICTIONARY_VALUE('report_sub_type', 'INTERCONNECTOR', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Revised Interconnector ATC Data');
       PUT_NEW_DICTIONARY_VALUE('version_no', '1.0', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Revised Interconnector ATC Data');
       PUT_NEW_DICTIONARY_VALUE('multiple_messages','false', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Revised Interconnector ATC Data');
       
--Creating SYSTEM_DICTIONARY entry for PUB_D_SystemFrequency_02022007.xml

       -- *** INFO ***: TITLE length is 25 chars.
       PUT_NEW_DICTIONARY_VALUE('application_type', 'MARKET_REPORT', 0, 'MarketExchange', 'SEM','SMO Reports','Daily SO System Frequency');
       PUT_NEW_DICTIONARY_VALUE('mode', 'NORMAL', 0, 'MarketExchange', 'SEM','SMO Reports','Daily SO System Frequency');
       PUT_NEW_DICTIONARY_VALUE('request_type', 'REPORT', 0, 'MarketExchange', 'SEM','SMO Reports','Daily SO System Frequency');
       PUT_NEW_DICTIONARY_VALUE('action', 'DOWNLOAD', 0, 'MarketExchange', 'SEM','SMO Reports','Daily SO System Frequency');
       PUT_NEW_DICTIONARY_VALUE('access_class', 'PUB', 0, 'MarketExchange', 'SEM','SMO Reports','Daily SO System Frequency');
       PUT_NEW_DICTIONARY_VALUE('file_type', 'XML', 0, 'MarketExchange', 'SEM','SMO Reports','Daily SO System Frequency');
       PUT_NEW_DICTIONARY_VALUE('periodicity', 'DAILY', 0, 'MarketExchange', 'SEM','SMO Reports','Daily SO System Frequency');
       PUT_NEW_DICTIONARY_VALUE('report_name', 'PUB_D_SystemFrequency', 0, 'MarketExchange', 'SEM','SMO Reports','Daily SO System Frequency');
       PUT_NEW_DICTIONARY_VALUE('file_name', 'PUB_D_SystemFrequency_02022007.xml', 0, 'MarketExchange', 'SEM','SMO Reports','Daily SO System Frequency');
       PUT_NEW_DICTIONARY_VALUE('report_type', 'TRANS_SYSTEM', 0, 'MarketExchange', 'SEM','SMO Reports','Daily SO System Frequency');
       PUT_NEW_DICTIONARY_VALUE('report_sub_type', 'MISCELLANEOUS', 0, 'MarketExchange', 'SEM','SMO Reports','Daily SO System Frequency');
       PUT_NEW_DICTIONARY_VALUE('version_no', '1.0', 0, 'MarketExchange', 'SEM','SMO Reports','Daily SO System Frequency');
       PUT_NEW_DICTIONARY_VALUE('multiple_messages','false', 0, 'MarketExchange', 'SEM','SMO Reports','Daily SO System Frequency');
       
--Creating SYSTEM_DICTIONARY entry for PUB_IndicativeInterconnFlows_20022007.xml

       -- *** INFO ***: TITLE length is 53 chars.
       PUT_NEW_DICTIONARY_VALUE('application_type', 'MARKET_REPORT', 0, 'MarketExchange', 'SEM','SMO Reports','Indicative Interconnector Flows and Residual Capacity');
       PUT_NEW_DICTIONARY_VALUE('mode', 'NORMAL', 0, 'MarketExchange', 'SEM','SMO Reports','Indicative Interconnector Flows and Residual Capacity');
       PUT_NEW_DICTIONARY_VALUE('request_type', 'REPORT', 0, 'MarketExchange', 'SEM','SMO Reports','Indicative Interconnector Flows and Residual Capacity');
       PUT_NEW_DICTIONARY_VALUE('action', 'DOWNLOAD', 0, 'MarketExchange', 'SEM','SMO Reports','Indicative Interconnector Flows and Residual Capacity');
       PUT_NEW_DICTIONARY_VALUE('access_class', 'PUB', 0, 'MarketExchange', 'SEM','SMO Reports','Indicative Interconnector Flows and Residual Capacity');
       PUT_NEW_DICTIONARY_VALUE('file_type', 'XML', 0, 'MarketExchange', 'SEM','SMO Reports','Indicative Interconnector Flows and Residual Capacity');
       PUT_NEW_DICTIONARY_VALUE('periodicity', 'DAILY', 0, 'MarketExchange', 'SEM','SMO Reports','Indicative Interconnector Flows and Residual Capacity');
       PUT_NEW_DICTIONARY_VALUE('report_name', 'PUB_IndicativeInterconnFlows', 0, 'MarketExchange', 'SEM','SMO Reports','Indicative Interconnector Flows and Residual Capacity');
       PUT_NEW_DICTIONARY_VALUE('file_name', 'PUB_IndicativeInterconnFlows_20022007.xml', 0, 'MarketExchange', 'SEM','SMO Reports','Indicative Interconnector Flows and Residual Capacity');
       PUT_NEW_DICTIONARY_VALUE('report_type', 'TRANS_SYSTEM', 0, 'MarketExchange', 'SEM','SMO Reports','Indicative Interconnector Flows and Residual Capacity');
       PUT_NEW_DICTIONARY_VALUE('report_sub_type', 'INTERCONNECTOR', 0, 'MarketExchange', 'SEM','SMO Reports','Indicative Interconnector Flows and Residual Capacity');
       PUT_NEW_DICTIONARY_VALUE('version_no', '1.0', 0, 'MarketExchange', 'SEM','SMO Reports','Indicative Interconnector Flows and Residual Capacity');
       PUT_NEW_DICTIONARY_VALUE('multiple_messages','false', 0, 'MarketExchange', 'SEM','SMO Reports','Indicative Interconnector Flows and Residual Capacity');
       
--Creating SYSTEM_DICTIONARY entry for PUB_InitialInterconnFlows_20022007.xml

       -- *** INFO ***: TITLE length is 50 chars.
       PUT_NEW_DICTIONARY_VALUE('application_type', 'MARKET_REPORT', 0, 'MarketExchange', 'SEM','SMO Reports','Initial Interconnector Flows and Residual Capacity');
       PUT_NEW_DICTIONARY_VALUE('mode', 'NORMAL', 0, 'MarketExchange', 'SEM','SMO Reports','Initial Interconnector Flows and Residual Capacity');
       PUT_NEW_DICTIONARY_VALUE('request_type', 'REPORT', 0, 'MarketExchange', 'SEM','SMO Reports','Initial Interconnector Flows and Residual Capacity');
       PUT_NEW_DICTIONARY_VALUE('action', 'DOWNLOAD', 0, 'MarketExchange', 'SEM','SMO Reports','Initial Interconnector Flows and Residual Capacity');
       PUT_NEW_DICTIONARY_VALUE('access_class', 'PUB', 0, 'MarketExchange', 'SEM','SMO Reports','Initial Interconnector Flows and Residual Capacity');
       PUT_NEW_DICTIONARY_VALUE('file_type', 'XML', 0, 'MarketExchange', 'SEM','SMO Reports','Initial Interconnector Flows and Residual Capacity');
       PUT_NEW_DICTIONARY_VALUE('periodicity', 'DAILY', 0, 'MarketExchange', 'SEM','SMO Reports','Initial Interconnector Flows and Residual Capacity');
       PUT_NEW_DICTIONARY_VALUE('report_name', 'PUB_InitialInterconnFlows', 0, 'MarketExchange', 'SEM','SMO Reports','Initial Interconnector Flows and Residual Capacity');
       PUT_NEW_DICTIONARY_VALUE('file_name', 'PUB_InitialInterconnFlows_20022007.xml', 0, 'MarketExchange', 'SEM','SMO Reports','Initial Interconnector Flows and Residual Capacity');
       PUT_NEW_DICTIONARY_VALUE('report_type', 'TRANS_SYSTEM', 0, 'MarketExchange', 'SEM','SMO Reports','Initial Interconnector Flows and Residual Capacity');
       PUT_NEW_DICTIONARY_VALUE('report_sub_type', 'INTERCONNECTOR', 0, 'MarketExchange', 'SEM','SMO Reports','Initial Interconnector Flows and Residual Capacity');
       PUT_NEW_DICTIONARY_VALUE('version_no', '1.0', 0, 'MarketExchange', 'SEM','SMO Reports','Initial Interconnector Flows and Residual Capacity');
       PUT_NEW_DICTIONARY_VALUE('multiple_messages','false', 0, 'MarketExchange', 'SEM','SMO Reports','Initial Interconnector Flows and Residual Capacity');
       
--Creating SYSTEM_DICTIONARY entry for Monthly Interconnector Capacity Holding

       PUT_NEW_DICTIONARY_VALUE('application_type', 'MARKET_REPORT', 0, 'MarketExchange', 'SEM','SMO Reports','Monthly Interconnector Capacity Holding');
       PUT_NEW_DICTIONARY_VALUE('mode', 'NORMAL', 0, 'MarketExchange', 'SEM','SMO Reports','Monthly Interconnector Capacity Holding');
       PUT_NEW_DICTIONARY_VALUE('request_type', 'REPORT', 0, 'MarketExchange', 'SEM','SMO Reports','Monthly Interconnector Capacity Holding');
       PUT_NEW_DICTIONARY_VALUE('action', 'DOWNLOAD', 0, 'MarketExchange', 'SEM','SMO Reports','Monthly Interconnector Capacity Holding');
       PUT_NEW_DICTIONARY_VALUE('access_class', 'PUB', 0, 'MarketExchange', 'SEM','SMO Reports','Monthly Interconnector Capacity Holding');
       PUT_NEW_DICTIONARY_VALUE('file_type', 'XML', 0, 'MarketExchange', 'SEM','SMO Reports','Monthly Interconnector Capacity Holding');
       PUT_NEW_DICTIONARY_VALUE('periodicity', 'MONTHLY', 0, 'MarketExchange', 'SEM','SMO Reports','Monthly Interconnector Capacity Holding');
       PUT_NEW_DICTIONARY_VALUE('report_name', 'PUB_M_IntconnCapHoldResults', 0, 'MarketExchange', 'SEM','SMO Reports','Monthly Interconnector Capacity Holding');
       PUT_NEW_DICTIONARY_VALUE('file_name', '', 0, 'MarketExchange', 'SEM','SMO Reports','Monthly Interconnector Capacity Holding');
       PUT_NEW_DICTIONARY_VALUE('report_type', 'TRANS_SYSTEM', 0, 'MarketExchange', 'SEM','SMO Reports','Monthly Interconnector Capacity Holding');
       PUT_NEW_DICTIONARY_VALUE('report_sub_type', 'INTERCONNECTOR', 0, 'MarketExchange', 'SEM','SMO Reports','Monthly Interconnector Capacity Holding');
       PUT_NEW_DICTIONARY_VALUE('version_no', '1.0', 0, 'MarketExchange', 'SEM','SMO Reports','Monthly Interconnector Capacity Holding');
       PUT_NEW_DICTIONARY_VALUE('multiple_messages','false', 0, 'MarketExchange', 'SEM','SMO Reports','Monthly Interconnector Capacity Holding');
       
--Creating SYSTEM_DICTIONARY entry for Daily Jurisdiction Error Supply MW (D+1)

       PUT_NEW_DICTIONARY_VALUE('application_type', 'MARKET_REPORT', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Jurisdiction Error Supply MW (D+1)');
       PUT_NEW_DICTIONARY_VALUE('mode', 'NORMAL', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Jurisdiction Error Supply MW (D+1)');
       PUT_NEW_DICTIONARY_VALUE('request_type', 'REPORT', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Jurisdiction Error Supply MW (D+1)');
       PUT_NEW_DICTIONARY_VALUE('action', 'DOWNLOAD', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Jurisdiction Error Supply MW (D+1)');
       PUT_NEW_DICTIONARY_VALUE('access_class', 'PUB', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Jurisdiction Error Supply MW (D+1)');
       PUT_NEW_DICTIONARY_VALUE('file_type', 'XML', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Jurisdiction Error Supply MW (D+1)');
       PUT_NEW_DICTIONARY_VALUE('periodicity', 'DAILY', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Jurisdiction Error Supply MW (D+1)');
       PUT_NEW_DICTIONARY_VALUE('report_name', 'PUB_D_JurisdictionErrorSupplyD1', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Jurisdiction Error Supply MW (D+1)');
       PUT_NEW_DICTIONARY_VALUE('file_name', '', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Jurisdiction Error Supply MW (D+1)');
       PUT_NEW_DICTIONARY_VALUE('report_type', 'MARKET', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Jurisdiction Error Supply MW (D+1)');
       PUT_NEW_DICTIONARY_VALUE('report_sub_type', 'METERING', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Jurisdiction Error Supply MW (D+1)');
       PUT_NEW_DICTIONARY_VALUE('version_no', '1.0', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Jurisdiction Error Supply MW (D+1)');
       PUT_NEW_DICTIONARY_VALUE('multiple_messages','false', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Jurisdiction Error Supply MW (D+1)');
       
--Creating SYSTEM_DICTIONARY entry for Daily Jurisdiction Error Supply MW (D+4)

       PUT_NEW_DICTIONARY_VALUE('application_type', 'MARKET_REPORT', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Jurisdiction Error Supply MW (D+4)');
       PUT_NEW_DICTIONARY_VALUE('mode', 'NORMAL', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Jurisdiction Error Supply MW (D+4)');
       PUT_NEW_DICTIONARY_VALUE('request_type', 'REPORT', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Jurisdiction Error Supply MW (D+4)');
       PUT_NEW_DICTIONARY_VALUE('action', 'DOWNLOAD', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Jurisdiction Error Supply MW (D+4)');
       PUT_NEW_DICTIONARY_VALUE('access_class', 'PUB', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Jurisdiction Error Supply MW (D+4)');
       PUT_NEW_DICTIONARY_VALUE('file_type', 'XML', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Jurisdiction Error Supply MW (D+4)');
       PUT_NEW_DICTIONARY_VALUE('periodicity', 'DAILY', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Jurisdiction Error Supply MW (D+4)');
       PUT_NEW_DICTIONARY_VALUE('report_name', 'PUB_D_JurisdictionErrorSupplyD4', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Jurisdiction Error Supply MW (D+4)');
       PUT_NEW_DICTIONARY_VALUE('file_name', '', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Jurisdiction Error Supply MW (D+4)');
       PUT_NEW_DICTIONARY_VALUE('report_type', 'MARKET', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Jurisdiction Error Supply MW (D+4)');
       PUT_NEW_DICTIONARY_VALUE('report_sub_type', 'METERING', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Jurisdiction Error Supply MW (D+4)');
       PUT_NEW_DICTIONARY_VALUE('version_no', '1.0', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Jurisdiction Error Supply MW (D+4)');
       PUT_NEW_DICTIONARY_VALUE('multiple_messages','false', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Jurisdiction Error Supply MW (D+4)');   

--Creating SYSTEM_DICTIONARY entry for PUB_ActiveUnits_02022007.xml

       -- *** INFO ***: TITLE length is 44 chars.
       PUT_NEW_DICTIONARY_VALUE('application_type', 'MARKET_REPORT', 0, 'MarketExchange', 'SEM','SMO Reports','List of Active Units');
       PUT_NEW_DICTIONARY_VALUE('mode', 'NORMAL', 0, 'MarketExchange', 'SEM','SMO Reports','List of Active Units');
       PUT_NEW_DICTIONARY_VALUE('request_type', 'REPORT', 0, 'MarketExchange', 'SEM','SMO Reports','List of Active Units');
       PUT_NEW_DICTIONARY_VALUE('action', 'DOWNLOAD', 0, 'MarketExchange', 'SEM','SMO Reports','List of Active Units');
       PUT_NEW_DICTIONARY_VALUE('access_class', 'PUB', 0, 'MarketExchange', 'SEM','SMO Reports','List of Active Units');
       PUT_NEW_DICTIONARY_VALUE('file_type', 'XML', 0, 'MarketExchange', 'SEM','SMO Reports','List of Active Units');
       PUT_NEW_DICTIONARY_VALUE('periodicity', 'DAILY', 0, 'MarketExchange', 'SEM','SMO Reports','List of Active Units');
       PUT_NEW_DICTIONARY_VALUE('report_name', 'PUB_ActiveUnits', 0, 'MarketExchange', 'SEM','SMO Reports','List of Active Units');
       PUT_NEW_DICTIONARY_VALUE('file_name', 'PUB_ActiveUnits.xml', 0, 'MarketExchange', 'SEM','SMO Reports','List of Active Units');
       PUT_NEW_DICTIONARY_VALUE('report_type', 'REGISTRATION', 0, 'MarketExchange', 'SEM','SMO Reports','List of Active Units');
       PUT_NEW_DICTIONARY_VALUE('report_sub_type', 'MP_ACTIVITY', 0, 'MarketExchange', 'SEM','SMO Reports','List of Active Units');
       PUT_NEW_DICTIONARY_VALUE('version_no', '1.0', 0, 'MarketExchange', 'SEM','SMO Reports','List of Active Units');
       PUT_NEW_DICTIONARY_VALUE('multiple_messages','false', 0, 'MarketExchange', 'SEM','SMO Reports','List of Active Units');
       
--Creating SYSTEM_DICTIONARY entry for MP_D_IndicativeActualSchedule

       -- *** INFO ***: TITLE length is 32 chars.
       PUT_NEW_DICTIONARY_VALUE('application_type', 'MARKET_REPORT', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Indicative Actual Schedules');
       PUT_NEW_DICTIONARY_VALUE('mode', 'NORMAL', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Indicative Actual Schedules');
       PUT_NEW_DICTIONARY_VALUE('request_type', 'REPORT', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Indicative Actual Schedules');
       PUT_NEW_DICTIONARY_VALUE('action', 'DOWNLOAD', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Indicative Actual Schedules');
       PUT_NEW_DICTIONARY_VALUE('access_class', 'MP', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Indicative Actual Schedules');
       PUT_NEW_DICTIONARY_VALUE('file_type', 'XML', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Indicative Actual Schedules');
       PUT_NEW_DICTIONARY_VALUE('periodicity', 'DAILY', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Indicative Actual Schedules');
       PUT_NEW_DICTIONARY_VALUE('report_name', 'MP_D_IndicativeActualSchedules', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Indicative Actual Schedules');
       PUT_NEW_DICTIONARY_VALUE('file_name', 'MP_D_IndicativeActualSchedules', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Indicative Actual Schedules');
       PUT_NEW_DICTIONARY_VALUE('report_type', 'MARKET', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Indicative Actual Schedules');
       PUT_NEW_DICTIONARY_VALUE('report_sub_type', 'DAY_AHEAD', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Indicative Actual Schedules');
       PUT_NEW_DICTIONARY_VALUE('version_no', '1.0', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Indicative Actual Schedules');
       PUT_NEW_DICTIONARY_VALUE('multiple_messages','false', 0, 'MarketExchange', 'SEM','SMO Reports','Daily Indicative Actual Schedules');

		-- creating SYSTEM_DICTIONARY entries for all reports, import_procedure and import_param
		PUT_NEW_DICTIONARY_VALUE('import_procedure','IMPORT_AVG_SMP',0,'MarketExchange','SEM','SMO Reports', 'Daily Market Prices Averages (SMP)');
		PUT_NEW_DICTIONARY_VALUE('import_procedure','IMPORT_DAY_EXCHANGE_RATE',0,'MarketExchange','SEM','SMO Reports', 'Daily Trading Day Exchange Rate');
		PUT_NEW_DICTIONARY_VALUE('import_procedure','IMPORT_DISPATCH_INSTR',0,'MarketExchange','SEM','SMO Reports', 'Daily Dispatch Instructions');
		PUT_NEW_DICTIONARY_VALUE('import_procedure','IMPORT_GEN_FORECAST',0,'MarketExchange','SEM','SMO Reports', 'Daily Rolling Wind Forecast and Assumptions');
		PUT_NEW_DICTIONARY_VALUE('import_procedure','IMPORT_IC_AGG_NOMIN',0,'MarketExchange','SEM','SMO Reports', 'Daily Aggregated Interconnector User Nominations');
		PUT_NEW_DICTIONARY_VALUE('import_procedure','IMPORT_IC_CAP_HOLDINGS',0,'MarketExchange','SEM','SMO Reports', 'Daily Interconnector Capacity Active Holdings');
		PUT_NEW_DICTIONARY_VALUE('import_procedure','IMPORT_IC_CAP_HOLDINGS',0,'MarketExchange','SEM','SMO Reports', 'Daily Interconnector Capacity Holdings');
		PUT_NEW_DICTIONARY_VALUE('import_procedure','IMPORT_IC_CAP_HOLDINGS',0,'MarketExchange','SEM','SMO Reports', 'Monthly Interconnector Capacity Holding');
		PUT_NEW_DICTIONARY_VALUE('import_procedure','IMPORT_INACTIVE_MKT_PART',0,'MarketExchange','SEM','SMO Reports', 'List of Suspended/Terminated Market Participants');
		PUT_NEW_DICTIONARY_VALUE('import_procedure','IMPORT_INDIC_ACTUAL_SCHED',0,'MarketExchange','SEM','SMO Reports', 'Daily Indicative Actual Schedules');
		PUT_NEW_DICTIONARY_VALUE('import_procedure','IMPORT_INDIC_SMP',0,'MarketExchange','SEM','SMO Reports', 'Daily Indicative Market Prices');
		PUT_NEW_DICTIONARY_VALUE('import_procedure','IMPORT_INIT_SMP',0,'MarketExchange','SEM','SMO Reports', 'Daily Initial Ex-Post Market Prices');
		PUT_NEW_DICTIONARY_VALUE('import_procedure','IMPORT_JUST_UNITS',0,'MarketExchange','SEM','SMO Reports', 'List of Active Units');
		PUT_NEW_DICTIONARY_VALUE('import_procedure','IMPORT_LOAD_FORECAST',0,'MarketExchange','SEM','SMO Reports', 'Daily Actual Load Summary');
		PUT_NEW_DICTIONARY_VALUE('import_procedure','IMPORT_LOAD_FORECAST',0,'MarketExchange','SEM','SMO Reports', 'Daily Four Day Rolling Load Forecast and Assumptions (D+4)');
		PUT_NEW_DICTIONARY_VALUE('import_procedure','IMPORT_LOAD_FORECAST',0,'MarketExchange','SEM','SMO Reports', 'Daily Jurisdiction Error Supply MW (D+1)');
		PUT_NEW_DICTIONARY_VALUE('import_procedure','IMPORT_LOAD_FORECAST',0,'MarketExchange','SEM','SMO Reports', 'Daily Jurisdiction Error Supply MW (D+4)');
		PUT_NEW_DICTIONARY_VALUE('import_procedure','IMPORT_LOAD_FORECAST',0,'MarketExchange','SEM','SMO Reports', 'Daily Load Forecast Summary');
		PUT_NEW_DICTIONARY_VALUE('import_procedure','IMPORT_LOAD_FORECAST',0,'MarketExchange','SEM','SMO Reports', 'Monthly Load Forecast and Assumptions');
		PUT_NEW_DICTIONARY_VALUE('import_procedure','IMPORT_LOSS_LOAD_PROBAB',0,'MarketExchange','SEM','SMO Reports', 'Monthly Loss of Load Probability Forecast');
		PUT_NEW_DICTIONARY_VALUE('import_procedure','IMPORT_METER_DETAIL',0,'MarketExchange','SEM','SMO Reports', 'Daily Meter Data Detail (D+1)');
		PUT_NEW_DICTIONARY_VALUE('import_procedure','IMPORT_METER_DETAIL',0,'MarketExchange','SEM','SMO Reports', 'Daily Meter Data Detail (D+3)');
		PUT_NEW_DICTIONARY_VALUE('import_procedure','IMPORT_METER_SUMMARY',0,'MarketExchange','SEM','SMO Reports', 'Daily Meter Data Summary (D+1)');
		PUT_NEW_DICTIONARY_VALUE('import_procedure','IMPORT_METER_SUMMARY',0,'MarketExchange','SEM','SMO Reports', 'Daily Meter Data Summary (D+3)');
		PUT_NEW_DICTIONARY_VALUE('import_procedure','IMPORT_MO_NOTIFICATIONS',0,'MarketExchange','SEM','SMO Reports', 'Daily Market Operations Notifications');
		PUT_NEW_DICTIONARY_VALUE('import_procedure','IMPORT_SETTL_CLASS_UPDATE',0,'MarketExchange','SEM','SMO Reports', 'Monthly Updates to Settlement Classes');
		PUT_NEW_DICTIONARY_VALUE('import_procedure','IMPORT_SYSTEM_FREQUENCY',0,'MarketExchange','SEM','SMO Reports', 'Daily SO System Frequency');
		PUT_NEW_DICTIONARY_VALUE('import_procedure','IMPORT_IC_NOMINATIONS',0,'MarketExchange','SEM','SMO Reports', 'Daily Ex-Ante Interconnector Nominations');
		PUT_NEW_DICTIONARY_VALUE('import_procedure','IMPORT_IC_NOMINATIONS',0,'MarketExchange','SEM','SMO Reports', 'Daily Ex-Post Indicative Interconnector Nominations');
		PUT_NEW_DICTIONARY_VALUE('import_procedure','IMPORT_IC_NOMINATIONS',0,'MarketExchange','SEM','SMO Reports', 'Daily Ex-Post Initial Interconnector Nominations');
		PUT_NEW_DICTIONARY_VALUE('import_procedure','IMPORT_IC_NOMINATIONS',0,'MarketExchange','SEM','SMO Reports', 'Daily Interconnector Modified Nominations');
		PUT_NEW_DICTIONARY_VALUE('import_procedure','IMPORT_IC_NOMINATIONS',0,'MarketExchange','SEM','SMO Reports', 'Daily Revised Interconnector Modified Nominations');
		PUT_NEW_DICTIONARY_VALUE('import_procedure','IMPORT_MKT_SCHED_SUMMARY',0,'MarketExchange','SEM','SMO Reports', 'Daily Ex-Ante Market Schedule Summary');
		PUT_NEW_DICTIONARY_VALUE('import_procedure','IMPORT_MKT_SCHED_SUMMARY',0,'MarketExchange','SEM','SMO Reports', 'Daily Indicative Ex-Post Market Schedule Summary');
		PUT_NEW_DICTIONARY_VALUE('import_procedure','IMPORT_MKT_SCHED_SUMMARY',0,'MarketExchange','SEM','SMO Reports', 'Daily Initial Ex-Post Market Schedule Summary');
		PUT_NEW_DICTIONARY_VALUE('import_procedure','IMPORT_MKT_SCHED_DETAIL',0,'MarketExchange','SEM','SMO Reports', 'Daily Ex-Ante Market Schedule Detail');
		PUT_NEW_DICTIONARY_VALUE('import_procedure','IMPORT_MKT_SCHED_DETAIL',0,'MarketExchange','SEM','SMO Reports', 'Daily Indicative Ex-Post Market Schedule Detail');
		PUT_NEW_DICTIONARY_VALUE('import_procedure','IMPORT_MKT_SCHED_DETAIL',0,'MarketExchange','SEM','SMO Reports', 'Daily Initial Ex-Post Market Schedule Details');
		PUT_NEW_DICTIONARY_VALUE('import_procedure','IMPORT_DAILY_ATC',0,'MarketExchange','SEM','SMO Reports', 'Daily Interconnector ATC Data');
		PUT_NEW_DICTIONARY_VALUE('import_procedure','IMPORT_DAILY_ATC',0,'MarketExchange','SEM','SMO Reports', 'Daily Revised Interconnector ATC Data');
		PUT_NEW_DICTIONARY_VALUE('import_procedure','IMPORT_IC_FLOW',0,'MarketExchange','SEM','SMO Reports', 'Indicative Interconnector Flows and Residual Capacity');
		PUT_NEW_DICTIONARY_VALUE('import_procedure','IMPORT_IC_FLOW',0,'MarketExchange','SEM','SMO Reports', 'Initial Interconnector Flows and Residual Capacity');
		PUT_NEW_DICTIONARY_VALUE('import_procedure','IMPORT_MKT_PARTICIPANTS',0,'MarketExchange','SEM','SMO Reports', 'List of Active Market Participants');
		PUT_NEW_DICTIONARY_VALUE('import_procedure','IMPORT_UNITS',0,'MarketExchange','SEM','SMO Reports', 'List of Active Market Participants and Units');
		PUT_NEW_DICTIONARY_VALUE('import_procedure','IMPORT_LOAD_FORECAST',0,'MarketExchange','SEM','SMO Reports', 'Annual Load Forecast');

		PUT_NEW_DICTIONARY_VALUE('import_param','D',0,'MarketExchange','SEM','SMO Reports', 'Daily Interconnector Capacity Holdings');
		PUT_NEW_DICTIONARY_VALUE('import_param','D1',0,'MarketExchange','SEM','SMO Reports', 'Daily Meter Data Detail (D+1)');
		PUT_NEW_DICTIONARY_VALUE('import_param','D1',0,'MarketExchange','SEM','SMO Reports', 'Daily Meter Data Summary (D+1)');
		PUT_NEW_DICTIONARY_VALUE('import_param','D1-ES',0,'MarketExchange','SEM','SMO Reports', 'Daily Jurisdiction Error Supply MW (D+1)');
		PUT_NEW_DICTIONARY_VALUE('import_param','D3',0,'MarketExchange','SEM','SMO Reports', 'Daily Meter Data Detail (D+3)');
		PUT_NEW_DICTIONARY_VALUE('import_param','D3',0,'MarketExchange','SEM','SMO Reports', 'Daily Meter Data Summary (D+3)');
		PUT_NEW_DICTIONARY_VALUE('import_param','D4-ES',0,'MarketExchange','SEM','SMO Reports', 'Daily Jurisdiction Error Supply MW (D+4)');
		PUT_NEW_DICTIONARY_VALUE('import_param','DA',0,'MarketExchange','SEM','SMO Reports', 'Daily Actual Load Summary');
		PUT_NEW_DICTIONARY_VALUE('import_param','DA',0,'MarketExchange','SEM','SMO Reports', 'Daily Interconnector Capacity Active Holdings');
		PUT_NEW_DICTIONARY_VALUE('import_param','DAILY',0,'MarketExchange','SEM','SMO Reports', 'Daily Four Day Rolling Load Forecast and Assumptions (D+4)');
		PUT_NEW_DICTIONARY_VALUE('import_param','DS',0,'MarketExchange','SEM','SMO Reports', 'Daily Load Forecast Summary');
		PUT_NEW_DICTIONARY_VALUE('import_param','M',0,'MarketExchange','SEM','SMO Reports', 'Monthly Interconnector Capacity Holding');
		PUT_NEW_DICTIONARY_VALUE('import_param','MONTHLY',0,'MarketExchange','SEM','SMO Reports', 'Monthly Load Forecast and Assumptions');
		PUT_NEW_DICTIONARY_VALUE('import_param','YEARLY',0,'MarketExchange','SEM','SMO Reports', 'Annual Load Forecast');
		PUT_NEW_DICTIONARY_VALUE('import_param','Ex-Ante',0,'MarketExchange','SEM','SMO Reports', 'Daily Ex-Ante Interconnector Nominations');
		PUT_NEW_DICTIONARY_VALUE('import_param','Ex-Ante',0,'MarketExchange','SEM','SMO Reports', 'Daily Ex-Ante Market Schedule Detail');
		PUT_NEW_DICTIONARY_VALUE('import_param','Ex-Ante',0,'MarketExchange','SEM','SMO Reports', 'Daily Ex-Ante Market Schedule Summary');
		PUT_NEW_DICTIONARY_VALUE('import_param','Indicative Ex-Post',0,'MarketExchange','SEM','SMO Reports', 'Daily Ex-Post Indicative Interconnector Nominations');
		PUT_NEW_DICTIONARY_VALUE('import_param','Initial Ex-Post',0,'MarketExchange','SEM','SMO Reports', 'Daily Ex-Post Initial Interconnector Nominations');
		PUT_NEW_DICTIONARY_VALUE('import_param','Indicative Ex-Post',0,'MarketExchange','SEM','SMO Reports', 'Daily Indicative Ex-Post Market Schedule Detail');
		PUT_NEW_DICTIONARY_VALUE('import_param','Indicative Ex-Post',0,'MarketExchange','SEM','SMO Reports', 'Daily Indicative Ex-Post Market Schedule Summary');
		PUT_NEW_DICTIONARY_VALUE('import_param','Initial Ex-Post',0,'MarketExchange','SEM','SMO Reports', 'Daily Initial Ex-Post Market Schedule Details');
		PUT_NEW_DICTIONARY_VALUE('import_param','Initial Ex-Post',0,'MarketExchange','SEM','SMO Reports', 'Daily Initial Ex-Post Market Schedule Summary');
		PUT_NEW_DICTIONARY_VALUE('import_param','Modified',0,'MarketExchange','SEM','SMO Reports', 'Daily Interconnector Modified Nominations');
		PUT_NEW_DICTIONARY_VALUE('import_param','Revised',0,'MarketExchange','SEM','SMO Reports', 'Daily Revised Interconnector ATC Data');
		PUT_NEW_DICTIONARY_VALUE('import_param','Revised Modified',0,'MarketExchange','SEM','SMO Reports', 'Daily Revised Interconnector Modified Nominations');
		PUT_NEW_DICTIONARY_VALUE('import_param','Indic',0,'MarketExchange','SEM','SMO Reports', 'Indicative Interconnector Flows and Residual Capacity');
		PUT_NEW_DICTIONARY_VALUE('import_param','Init',0,'MarketExchange','SEM','SMO Reports', 'Initial Interconnector Flows and Residual Capacity');
		PUT_NEW_DICTIONARY_VALUE('import_param','None',0,'MarketExchange','SEM','SMO Reports', 'Daily Interconnector ATC Data');
		PUT_NEW_DICTIONARY_VALUE('import_param','',0,'MarketExchange','SEM','SMO Reports', 'Daily Indicative Market Prices');
		PUT_NEW_DICTIONARY_VALUE('import_param','',0,'MarketExchange','SEM','SMO Reports', 'Daily Initial Ex-Post Market Prices');
		PUT_NEW_DICTIONARY_VALUE('import_param','',0,'MarketExchange','SEM','SMO Reports', 'Daily Aggregated Interconnector User Nominations');
		PUT_NEW_DICTIONARY_VALUE('import_param','',0,'MarketExchange','SEM','SMO Reports', 'Daily Dispatch Instructions');
		PUT_NEW_DICTIONARY_VALUE('import_param','',0,'MarketExchange','SEM','SMO Reports', 'Daily Indicative Actual Schedules');
		PUT_NEW_DICTIONARY_VALUE('import_param','',0,'MarketExchange','SEM','SMO Reports', 'Daily Market Operations Notifications');
		PUT_NEW_DICTIONARY_VALUE('import_param','',0,'MarketExchange','SEM','SMO Reports', 'Daily Market Prices Averages (SMP)');
		PUT_NEW_DICTIONARY_VALUE('import_param','',0,'MarketExchange','SEM','SMO Reports', 'Daily Rolling Wind Forecast and Assumptions');
		PUT_NEW_DICTIONARY_VALUE('import_param','',0,'MarketExchange','SEM','SMO Reports', 'Daily SO System Frequency');
		PUT_NEW_DICTIONARY_VALUE('import_param','',0,'MarketExchange','SEM','SMO Reports', 'Daily Trading Day Exchange Rate');
		PUT_NEW_DICTIONARY_VALUE('import_param','',0,'MarketExchange','SEM','SMO Reports', 'List of Active Market Participants');
		PUT_NEW_DICTIONARY_VALUE('import_param','',0,'MarketExchange','SEM','SMO Reports', 'List of Active Market Participants');
		PUT_NEW_DICTIONARY_VALUE('import_param','',0,'MarketExchange','SEM','SMO Reports', 'List of Active Market Participants and Units');
		PUT_NEW_DICTIONARY_VALUE('import_param','',0,'MarketExchange','SEM','SMO Reports', 'List of Active Units');
		PUT_NEW_DICTIONARY_VALUE('import_param','',0,'MarketExchange','SEM','SMO Reports', 'List of Suspended/Terminated Market Participants');
		PUT_NEW_DICTIONARY_VALUE('import_param','',0,'MarketExchange','SEM','SMO Reports', 'Monthly Loss of Load Probability Forecast');
		PUT_NEW_DICTIONARY_VALUE('import_param','',0,'MarketExchange','SEM','SMO Reports', 'Monthly Updates to Settlement Classes');

		-- MP_D_IntconnCapActHoldResults replaces the deprecated PUB_D_IntconnCapActHoldResults in MPUD5
		PUT_NEW_DICTIONARY_VALUE('application_type', 'MARKET_REPORT', 0, 'MarketExchange', 'SEM','SMO Reports','MP_D_IntconnCapActHoldResults');
		PUT_NEW_DICTIONARY_VALUE('mode', 'NORMAL', 0, 'MarketExchange', 'SEM','SMO Reports','MP_D_IntconnCapActHoldResults');
		PUT_NEW_DICTIONARY_VALUE('request_type', 'REPORT', 0, 'MarketExchange', 'SEM','SMO Reports','MP_D_IntconnCapActHoldResults');
		PUT_NEW_DICTIONARY_VALUE('action', 'DOWNLOAD', 0, 'MarketExchange', 'SEM','SMO Reports','MP_D_IntconnCapActHoldResults');
		PUT_NEW_DICTIONARY_VALUE('access_class', 'MP', 0, 'MarketExchange', 'SEM','SMO Reports','MP_D_IntconnCapActHoldResults');
		PUT_NEW_DICTIONARY_VALUE('file_type', 'XML', 0, 'MarketExchange', 'SEM','SMO Reports','MP_D_IntconnCapActHoldResults');
		PUT_NEW_DICTIONARY_VALUE('periodicity', 'DAILY', 0, 'MarketExchange', 'SEM','SMO Reports','MP_D_IntconnCapActHoldResults');
		PUT_NEW_DICTIONARY_VALUE('report_name', 'MP_D_IntconnCapActHoldResults', 0, 'MarketExchange', 'SEM','SMO Reports','MP_D_IntconnCapActHoldResults');
		PUT_NEW_DICTIONARY_VALUE('file_name', 'MP_D_IntconnCapActHoldResults_02022007.xml', 0, 'MarketExchange', 'SEM','SMO Reports','MP_D_IntconnCapActHoldResults');
		PUT_NEW_DICTIONARY_VALUE('report_type', 'TRANS_SYSTEM', 0, 'MarketExchange', 'SEM','SMO Reports','MP_D_IntconnCapActHoldResults');
		PUT_NEW_DICTIONARY_VALUE('report_sub_type', 'INTERCONNECTOR', 0, 'MarketExchange', 'SEM','SMO Reports','MP_D_IntconnCapActHoldResults');
		PUT_NEW_DICTIONARY_VALUE('version_no', '1.0', 0, 'MarketExchange', 'SEM','SMO Reports','MP_D_IntconnCapActHoldResults');
		PUT_NEW_DICTIONARY_VALUE('multiple_messages','false', 0, 'MarketExchange', 'SEM','SMO Reports','MP_D_IntconnCapActHoldResults');
		PUT_NEW_DICTIONARY_VALUE('import_procedure','IMPORT_IC_CAP_HOLDINGS',0,'MarketExchange','SEM','SMO Reports', 'MP_D_IntconnCapActHoldResults');
		PUT_NEW_DICTIONARY_VALUE('import_param','DA',0,'MarketExchange','SEM','SMO Reports', 'MP_D_IntconnCapActHoldResults');


END;
/
-- save changes to database
COMMIT;
