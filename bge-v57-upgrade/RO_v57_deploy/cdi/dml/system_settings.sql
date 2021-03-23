DECLARE
c_CDI_MODULE           CONSTANT VARCHAR2(32)  := 'Client Data Interface';
c_SYSTEM               CONSTANT VARCHAR2(32)  := 'System';
c_DATA_IMPORT          CONSTANT VARCHAR2(32)  := 'Data Import';
c_REPORTING            CONSTANT VARCHAR2(32)  := 'Reporting';
c_SETTLEMENT           CONSTANT VARCHAR2(32)  := 'Settlement';
c_SCHEDULING           CONSTANT VARCHAR2(32)  := 'Scheduling';
c_MARKET_EXCHANGE      CONSTANT VARCHAR2(32)  := 'MarketExchange';
c_GA_SETTINGS          CONSTANT VARCHAR2(32)  := 'GA Settings';
BEGIN
   SECURITY_CONTROLS.SET_CURRENT_USER(SECURITY_CONTROLS.c_SUSER_SYSTEM);
-- Usage: RO_ADMIN.PUT_DICTIONARY_VALUE(p_SETTING_NAME,p_VALUE,p_MODEL_ID,p_MODULE,p_KEY1,p_KEY2,p_KEY3);
   DELETE SYSTEM_DICTIONARY WHERE MODEL_ID = GA.GLOBAL_MODEL AND MODULE = c_CDI_MODULE;
-- Staging Table Date Control --
   PUT_DICTIONARY_VALUE('Sync Forward Days', '55', GA.GLOBAL_MODEL, c_CDI_MODULE, c_DATA_IMPORT, 'Account Sync');
   PUT_DICTIONARY_VALUE('Sync Backward Days', '3', GA.GLOBAL_MODEL, c_CDI_MODULE, c_DATA_IMPORT, 'Account Sync');
-- Staging Table Date Control --
   PUT_DICTIONARY_VALUE('Account Proxy Day Method', 'BGE Default Method', GA.GLOBAL_MODEL, c_CDI_MODULE, c_DATA_IMPORT, 'Account Sync');
-- Interval Usage Interface --
   PUT_DICTIONARY_VALUE('Log Level', 'INFO', GA.GLOBAL_MODEL, c_CDI_MODULE, c_DATA_IMPORT, 'Interval Usage');
-- PJM Capacity Exchange Interface --
   PUT_DICTIONARY_VALUE('Company Name', 'BG', GA.GLOBAL_MODEL, c_MARKET_EXCHANGE, 'PJM');
   PUT_DICTIONARY_VALUE('Days Before Begin Date', '0', GA.GLOBAL_MODEL, c_SCHEDULING, 'PJM Contract');
   PUT_DICTIONARY_VALUE('Days After End Date',    '0', GA.GLOBAL_MODEL, c_SCHEDULING, 'PJM Contract');
-- PJM InSchedule Exchange Interface --
   PUT_DICTIONARY_VALUE('Reconciliation Delta Mode', 'Y', GA.GLOBAL_MODEL, c_MARKET_EXCHANGE, 'PJM', 'InSchedule');
   PUT_DICTIONARY_VALUE('Enable Floor To Zero',      'N', GA.GLOBAL_MODEL, c_MARKET_EXCHANGE, 'PJM', 'InSchedule');
   PUT_DICTIONARY_VALUE('Roll-Up By Contract',       'Y', GA.GLOBAL_MODEL, c_MARKET_EXCHANGE, 'PJM', 'InSchedule');
   PUT_DICTIONARY_VALUE('Transmission Loss Factor',  '?', GA.GLOBAL_MODEL, c_MARKET_EXCHANGE, 'PJM', 'InSchedule');
-- GA Settings --
   PUT_DICTIONARY_VALUE('DST Spring-Ahead Option',           'B', GA.GLOBAL_MODEL, c_SYSTEM, c_GA_SETTINGS, 'General');
   PUT_DICTIONARY_VALUE('Electric Unit of Measurement',    'KWH', GA.GLOBAL_MODEL, c_SYSTEM, c_GA_SETTINGS, 'General');
   PUT_DICTIONARY_VALUE('Enable Agg.Post-ESP Assignment', 'TRUE', GA.GLOBAL_MODEL, c_SYSTEM, c_GA_SETTINGS, 'Forecast/Settlement');
-- eMail Settings --
   PUT_DICTIONARY_VALUE('Server Host',   '?', GA.GLOBAL_MODEL, c_SYSTEM, 'SMTP');
   PUT_DICTIONARY_VALUE('Server Port',   '?', GA.GLOBAL_MODEL, c_SYSTEM, 'SMTP');
   PUT_DICTIONARY_VALUE('Client Domain', '?', GA.GLOBAL_MODEL, c_SYSTEM, 'SMTP');
-- PLC/NSPL Increment/Decrement Settings --
   PUT_DICTIONARY_VALUE('INC_MW', '5000', GA.GLOBAL_MODEL, c_SETTLEMENT, 'INC_DEC');
   PUT_DICTIONARY_VALUE('DEC_MW', '3000', GA.GLOBAL_MODEL, c_SETTLEMENT, 'INC_DEC');
-- Updates To Existing System Dictionary Entries --
   UPDATE SYSTEM_DICTIONARY SET VALUE = 'rundll32 url.dll,FileProtocolHandler {0}' WHERE SETTING_NAME = 'OpenBrowserCommand';
   COMMIT;
END;
/
