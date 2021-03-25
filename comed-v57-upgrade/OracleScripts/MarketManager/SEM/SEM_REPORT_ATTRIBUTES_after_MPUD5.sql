

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
		-- new MPUD5 reports
	PUT_NEW_DICTIONARY_VALUE('file_type', 'XML', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_RollingWindFcstAssumptionsJurisdiction');
	PUT_NEW_DICTIONARY_VALUE('file_type', 'XML', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TODStandardUnits');
	PUT_NEW_DICTIONARY_VALUE('file_type', 'XML', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TODDemandSideUnits');
	PUT_NEW_DICTIONARY_VALUE('file_type', 'XML', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TODForecastData');
	PUT_NEW_DICTIONARY_VALUE('file_type', 'XML', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CODStandardGenUnits');
	PUT_NEW_DICTIONARY_VALUE('file_type', 'XML', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CODStandardDemUnits');
	PUT_NEW_DICTIONARY_VALUE('file_type', 'XML', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CODInterconnectorUnits');
	PUT_NEW_DICTIONARY_VALUE('file_type', 'XML', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CommercialOfferDataGenNomProfiles');
	PUT_NEW_DICTIONARY_VALUE('file_type', 'XML', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CommercialOfferDataDemNomProfiles');
	PUT_NEW_DICTIONARY_VALUE('file_type', 'XML', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_DemandControlData');
	PUT_NEW_DICTIONARY_VALUE('file_type', 'XML', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_RevIntconnModNominations');
	PUT_NEW_DICTIONARY_VALUE('file_type', 'XML', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExAnteMktSchDetail');
      
	PUT_NEW_DICTIONARY_VALUE('file_type', 'XML', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExAnteIndicativeOpsScheduleDetails');
	PUT_NEW_DICTIONARY_VALUE('file_type', 'XML', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_GenUnitTechChars');
	PUT_NEW_DICTIONARY_VALUE('file_type', 'XML', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_EnergyLimitedGenUnitTechChars');
	PUT_NEW_DICTIONARY_VALUE('file_type', 'XML', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_InterconnectorTrades');
	PUT_NEW_DICTIONARY_VALUE('file_type', 'XML', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_PriceAffectingMeterData');
	PUT_NEW_DICTIONARY_VALUE('file_type', 'XML', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExPostMktSchDetail');
	PUT_NEW_DICTIONARY_VALUE('file_type', 'XML', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_InitialExPostMktSchDetail');
	PUT_NEW_DICTIONARY_VALUE('file_type', 'XML', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_A_AggLoadFcst');
	PUT_NEW_DICTIONARY_VALUE('file_type', 'XML', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_M_AggLoadFcst');
	PUT_NEW_DICTIONARY_VALUE('file_type', 'XML', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_AggLoadFcst');
	PUT_NEW_DICTIONARY_VALUE('file_type', 'XML', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_WithinDayActualSchedules');

	PUT_NEW_DICTIONARY_VALUE('application_type', 'MARKET_REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_RollingWindFcstAssumptionsJurisdiction');
	PUT_NEW_DICTIONARY_VALUE('application_type', 'MARKET_REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TODStandardUnits');
	PUT_NEW_DICTIONARY_VALUE('application_type', 'MARKET_REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TODDemandSideUnits');
	PUT_NEW_DICTIONARY_VALUE('application_type', 'MARKET_REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TODForecastData');
	PUT_NEW_DICTIONARY_VALUE('application_type', 'MARKET_REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CODStandardGenUnits');
	PUT_NEW_DICTIONARY_VALUE('application_type', 'MARKET_REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CODStandardDemUnits');
	PUT_NEW_DICTIONARY_VALUE('application_type', 'MARKET_REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CODInterconnectorUnits');
	PUT_NEW_DICTIONARY_VALUE('application_type', 'MARKET_REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CommercialOfferDataGenNomProfiles');
	PUT_NEW_DICTIONARY_VALUE('application_type', 'MARKET_REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CommercialOfferDataDemNomProfiles');
	PUT_NEW_DICTIONARY_VALUE('application_type', 'MARKET_REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_DemandControlData');
	PUT_NEW_DICTIONARY_VALUE('application_type', 'MARKET_REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_RevIntconnModNominations');
	PUT_NEW_DICTIONARY_VALUE('application_type', 'MARKET_REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExAnteMktSchDetail');
    
	PUT_NEW_DICTIONARY_VALUE('application_type', 'MARKET_REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExAnteIndicativeOpsScheduleDetails');
	PUT_NEW_DICTIONARY_VALUE('application_type', 'MARKET_REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_GenUnitTechChars');
	PUT_NEW_DICTIONARY_VALUE('application_type', 'MARKET_REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_EnergyLimitedGenUnitTechChars');
	PUT_NEW_DICTIONARY_VALUE('application_type', 'MARKET_REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_InterconnectorTrades');
	PUT_NEW_DICTIONARY_VALUE('application_type', 'MARKET_REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_PriceAffectingMeterData');
	PUT_NEW_DICTIONARY_VALUE('application_type', 'MARKET_REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExPostMktSchDetail');
	PUT_NEW_DICTIONARY_VALUE('application_type', 'MARKET_REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_InitialExPostMktSchDetail');
	PUT_NEW_DICTIONARY_VALUE('application_type', 'MARKET_REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_A_AggLoadFcst');
	PUT_NEW_DICTIONARY_VALUE('application_type', 'MARKET_REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_M_AggLoadFcst');
	PUT_NEW_DICTIONARY_VALUE('application_type', 'MARKET_REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_AggLoadFcst');
	PUT_NEW_DICTIONARY_VALUE('application_type', 'MARKET_REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_WithinDayActualSchedules');

	PUT_NEW_DICTIONARY_VALUE('version_no', '1.0', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_RollingWindFcstAssumptionsJurisdiction');
	PUT_NEW_DICTIONARY_VALUE('version_no', '1.0', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TODStandardUnits');
	PUT_NEW_DICTIONARY_VALUE('version_no', '1.0', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TODDemandSideUnits');
	PUT_NEW_DICTIONARY_VALUE('version_no', '1.0', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TODForecastData');
	PUT_NEW_DICTIONARY_VALUE('version_no', '1.0', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CODStandardGenUnits');
	PUT_NEW_DICTIONARY_VALUE('version_no', '1.0', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CODStandardDemUnits');
	PUT_NEW_DICTIONARY_VALUE('version_no', '1.0', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CODInterconnectorUnits');
	PUT_NEW_DICTIONARY_VALUE('version_no', '1.0', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CommercialOfferDataGenNomProfiles');
	PUT_NEW_DICTIONARY_VALUE('version_no', '1.0', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CommercialOfferDataDemNomProfiles');
	PUT_NEW_DICTIONARY_VALUE('version_no', '1.0', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_DemandControlData');
	PUT_NEW_DICTIONARY_VALUE('version_no', '1.0', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_RevIntconnModNominations');
	PUT_NEW_DICTIONARY_VALUE('version_no', '1.0', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExAnteMktSchDetail');
    
	PUT_NEW_DICTIONARY_VALUE('version_no', '1.0', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExAnteIndicativeOpsScheduleDetails');
	PUT_NEW_DICTIONARY_VALUE('version_no', '1.0', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_GenUnitTechChars');
	PUT_NEW_DICTIONARY_VALUE('version_no', '1.0', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_EnergyLimitedGenUnitTechChars');
	PUT_NEW_DICTIONARY_VALUE('version_no', '1.0', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_InterconnectorTrades');
	PUT_NEW_DICTIONARY_VALUE('version_no', '1.0', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_PriceAffectingMeterData');
	PUT_NEW_DICTIONARY_VALUE('version_no', '1.0', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExPostMktSchDetail');
	PUT_NEW_DICTIONARY_VALUE('version_no', '1.0', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_InitialExPostMktSchDetail');
	PUT_NEW_DICTIONARY_VALUE('version_no', '1.0', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_A_AggLoadFcst');
	PUT_NEW_DICTIONARY_VALUE('version_no', '1.0', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_M_AggLoadFcst');
	PUT_NEW_DICTIONARY_VALUE('version_no', '1.0', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_AggLoadFcst');
	PUT_NEW_DICTIONARY_VALUE('version_no', '1.0', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_WithinDayActualSchedules');

	PUT_NEW_DICTIONARY_VALUE('request_type', 'REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_RollingWindFcstAssumptionsJurisdiction');
	PUT_NEW_DICTIONARY_VALUE('request_type', 'REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TODStandardUnits');
	PUT_NEW_DICTIONARY_VALUE('request_type', 'REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TODDemandSideUnits');
	PUT_NEW_DICTIONARY_VALUE('request_type', 'REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TODForecastData');
	PUT_NEW_DICTIONARY_VALUE('request_type', 'REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CODStandardGenUnits');
	PUT_NEW_DICTIONARY_VALUE('request_type', 'REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CODStandardDemUnits');
	PUT_NEW_DICTIONARY_VALUE('request_type', 'REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CODInterconnectorUnits');
	PUT_NEW_DICTIONARY_VALUE('request_type', 'REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CommercialOfferDataGenNomProfiles');
	PUT_NEW_DICTIONARY_VALUE('request_type', 'REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CommercialOfferDataDemNomProfiles');
	PUT_NEW_DICTIONARY_VALUE('request_type', 'REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_DemandControlData');
	PUT_NEW_DICTIONARY_VALUE('request_type', 'REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_RevIntconnModNominations');
	PUT_NEW_DICTIONARY_VALUE('request_type', 'REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExAnteMktSchDetail');
    
	PUT_NEW_DICTIONARY_VALUE('request_type', 'REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExAnteIndicativeOpsScheduleDetails');
	PUT_NEW_DICTIONARY_VALUE('request_type', 'REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_GenUnitTechChars');
	PUT_NEW_DICTIONARY_VALUE('request_type', 'REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_EnergyLimitedGenUnitTechChars');
	PUT_NEW_DICTIONARY_VALUE('request_type', 'REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_InterconnectorTrades');
	PUT_NEW_DICTIONARY_VALUE('request_type', 'REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_PriceAffectingMeterData');
	PUT_NEW_DICTIONARY_VALUE('request_type', 'REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExPostMktSchDetail');
	PUT_NEW_DICTIONARY_VALUE('request_type', 'REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_InitialExPostMktSchDetail');
	PUT_NEW_DICTIONARY_VALUE('request_type', 'REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_A_AggLoadFcst');
	PUT_NEW_DICTIONARY_VALUE('request_type', 'REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_M_AggLoadFcst');
	PUT_NEW_DICTIONARY_VALUE('request_type', 'REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_AggLoadFcst');
	PUT_NEW_DICTIONARY_VALUE('request_type', 'REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_WithinDayActualSchedules');

	PUT_NEW_DICTIONARY_VALUE('mode', 'NORMAL', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_RollingWindFcstAssumptionsJurisdiction');
	PUT_NEW_DICTIONARY_VALUE('mode', 'NORMAL', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TODStandardUnits');
	PUT_NEW_DICTIONARY_VALUE('mode', 'NORMAL', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TODDemandSideUnits');
	PUT_NEW_DICTIONARY_VALUE('mode', 'NORMAL', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TODForecastData');
	PUT_NEW_DICTIONARY_VALUE('mode', 'NORMAL', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CODStandardGenUnits');
	PUT_NEW_DICTIONARY_VALUE('mode', 'NORMAL', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CODStandardDemUnits');
	PUT_NEW_DICTIONARY_VALUE('mode', 'NORMAL', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CODInterconnectorUnits');
	PUT_NEW_DICTIONARY_VALUE('mode', 'NORMAL', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CommercialOfferDataGenNomProfiles');
	PUT_NEW_DICTIONARY_VALUE('mode', 'NORMAL', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CommercialOfferDataDemNomProfiles');
	PUT_NEW_DICTIONARY_VALUE('mode', 'NORMAL', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_DemandControlData');
	PUT_NEW_DICTIONARY_VALUE('mode', 'NORMAL', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_RevIntconnModNominations');
	PUT_NEW_DICTIONARY_VALUE('mode', 'NORMAL', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExAnteMktSchDetail');
    
	PUT_NEW_DICTIONARY_VALUE('mode', 'NORMAL', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExAnteIndicativeOpsScheduleDetails');
	PUT_NEW_DICTIONARY_VALUE('mode', 'NORMAL', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_GenUnitTechChars');
	PUT_NEW_DICTIONARY_VALUE('mode', 'NORMAL', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_EnergyLimitedGenUnitTechChars');
	PUT_NEW_DICTIONARY_VALUE('mode', 'NORMAL', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_InterconnectorTrades');
	PUT_NEW_DICTIONARY_VALUE('mode', 'NORMAL', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_PriceAffectingMeterData');
	PUT_NEW_DICTIONARY_VALUE('mode', 'NORMAL', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExPostMktSchDetail');
	PUT_NEW_DICTIONARY_VALUE('mode', 'NORMAL', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_InitialExPostMktSchDetail');
	PUT_NEW_DICTIONARY_VALUE('mode', 'NORMAL', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_A_AggLoadFcst');
	PUT_NEW_DICTIONARY_VALUE('mode', 'NORMAL', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_M_AggLoadFcst');
	PUT_NEW_DICTIONARY_VALUE('mode', 'NORMAL', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_AggLoadFcst');
	PUT_NEW_DICTIONARY_VALUE('mode', 'NORMAL', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_WithinDayActualSchedules');

	PUT_NEW_DICTIONARY_VALUE('file_name', '', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_RollingWindFcstAssumptionsJurisdiction');
	PUT_NEW_DICTIONARY_VALUE('file_name', '', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TODStandardUnits');
	PUT_NEW_DICTIONARY_VALUE('file_name', '', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TODDemandSideUnits');
	PUT_NEW_DICTIONARY_VALUE('file_name', '', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TODForecastData');
	PUT_NEW_DICTIONARY_VALUE('file_name', '', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CODStandardGenUnits');
	PUT_NEW_DICTIONARY_VALUE('file_name', '', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CODStandardDemUnits');
	PUT_NEW_DICTIONARY_VALUE('file_name', '', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CODInterconnectorUnits');
	PUT_NEW_DICTIONARY_VALUE('file_name', '', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CommercialOfferDataGenNomProfiles');
	PUT_NEW_DICTIONARY_VALUE('file_name', '', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CommercialOfferDataDemNomProfiles');
	PUT_NEW_DICTIONARY_VALUE('file_name', '', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_DemandControlData');
	PUT_NEW_DICTIONARY_VALUE('file_name', '', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_RevIntconnModNominations');
	PUT_NEW_DICTIONARY_VALUE('file_name', 'PUB_D_ExAnteMktSchDetail.xml', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExAnteMktSchDetail');
  
	PUT_NEW_DICTIONARY_VALUE('file_name', '', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExAnteIndicativeOpsScheduleDetails');
	PUT_NEW_DICTIONARY_VALUE('file_name', '', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_GenUnitTechChars');
	PUT_NEW_DICTIONARY_VALUE('file_name', '', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_EnergyLimitedGenUnitTechChars');
	PUT_NEW_DICTIONARY_VALUE('file_name', '', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_InterconnectorTrades');
	PUT_NEW_DICTIONARY_VALUE('file_name', '', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_PriceAffectingMeterData');
	PUT_NEW_DICTIONARY_VALUE('file_name', '', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExPostMktSchDetail');
	PUT_NEW_DICTIONARY_VALUE('file_name', '', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_InitialExPostMktSchDetail');
	PUT_NEW_DICTIONARY_VALUE('file_name', '', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_A_AggLoadFcst');
	PUT_NEW_DICTIONARY_VALUE('file_name', '', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_M_AggLoadFcst');
	PUT_NEW_DICTIONARY_VALUE('file_name', '', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_AggLoadFcst');
	PUT_NEW_DICTIONARY_VALUE('file_name', '', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_WithinDayActualSchedules');

	PUT_NEW_DICTIONARY_VALUE('action', 'DOWNLOAD', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_RollingWindFcstAssumptionsJurisdiction');
	PUT_NEW_DICTIONARY_VALUE('action', 'DOWNLOAD', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TODStandardUnits');
	PUT_NEW_DICTIONARY_VALUE('action', 'DOWNLOAD', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TODDemandSideUnits');
	PUT_NEW_DICTIONARY_VALUE('action', 'DOWNLOAD', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TODForecastData');
	PUT_NEW_DICTIONARY_VALUE('action', 'DOWNLOAD', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CODStandardGenUnits');
	PUT_NEW_DICTIONARY_VALUE('action', 'DOWNLOAD', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CODStandardDemUnits');
	PUT_NEW_DICTIONARY_VALUE('action', 'DOWNLOAD', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CODInterconnectorUnits');
	PUT_NEW_DICTIONARY_VALUE('action', 'DOWNLOAD', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CommercialOfferDataGenNomProfiles');
	PUT_NEW_DICTIONARY_VALUE('action', 'DOWNLOAD', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CommercialOfferDataDemNomProfiles');
	PUT_NEW_DICTIONARY_VALUE('action', 'DOWNLOAD', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_DemandControlData');
	PUT_NEW_DICTIONARY_VALUE('action', 'DOWNLOAD', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_RevIntconnModNominations');
	PUT_NEW_DICTIONARY_VALUE('action', 'DOWNLOAD', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExAnteMktSchDetail');
 
	PUT_NEW_DICTIONARY_VALUE('action', 'DOWNLOAD', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExAnteIndicativeOpsScheduleDetails');
	PUT_NEW_DICTIONARY_VALUE('action', 'DOWNLOAD', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_GenUnitTechChars');
	PUT_NEW_DICTIONARY_VALUE('action', 'DOWNLOAD', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_EnergyLimitedGenUnitTechChars');
	PUT_NEW_DICTIONARY_VALUE('action', 'DOWNLOAD', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_InterconnectorTrades');
	PUT_NEW_DICTIONARY_VALUE('action', 'DOWNLOAD', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_PriceAffectingMeterData');
	PUT_NEW_DICTIONARY_VALUE('action', 'DOWNLOAD', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExPostMktSchDetail');
	PUT_NEW_DICTIONARY_VALUE('action', 'DOWNLOAD', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_InitialExPostMktSchDetail');
	PUT_NEW_DICTIONARY_VALUE('action', 'DOWNLOAD', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_A_AggLoadFcst');
	PUT_NEW_DICTIONARY_VALUE('action', 'DOWNLOAD', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_M_AggLoadFcst');
	PUT_NEW_DICTIONARY_VALUE('action', 'DOWNLOAD', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_AggLoadFcst');
	PUT_NEW_DICTIONARY_VALUE('action', 'DOWNLOAD', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_WithinDayActualSchedules');

	PUT_NEW_DICTIONARY_VALUE('multiple_messages', 'false', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_RollingWindFcstAssumptionsJurisdiction');
	PUT_NEW_DICTIONARY_VALUE('multiple_messages', 'false', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TODStandardUnits');
	PUT_NEW_DICTIONARY_VALUE('multiple_messages', 'false', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TODDemandSideUnits');
	PUT_NEW_DICTIONARY_VALUE('multiple_messages', 'false', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TODForecastData');
	PUT_NEW_DICTIONARY_VALUE('multiple_messages', 'false', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CODStandardGenUnits');
	PUT_NEW_DICTIONARY_VALUE('multiple_messages', 'false', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CODStandardDemUnits');
	PUT_NEW_DICTIONARY_VALUE('multiple_messages', 'false', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CODInterconnectorUnits');
	PUT_NEW_DICTIONARY_VALUE('multiple_messages', 'false', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CommercialOfferDataGenNomProfiles');
	PUT_NEW_DICTIONARY_VALUE('multiple_messages', 'false', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CommercialOfferDataDemNomProfiles');
	PUT_NEW_DICTIONARY_VALUE('multiple_messages', 'false', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_DemandControlData');
	PUT_NEW_DICTIONARY_VALUE('multiple_messages', 'false', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_RevIntconnModNominations');
	PUT_NEW_DICTIONARY_VALUE('multiple_messages', 'false', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExAnteMktSchDetail');
 
	PUT_NEW_DICTIONARY_VALUE('multiple_messages', 'false', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExAnteIndicativeOpsScheduleDetails');
	PUT_NEW_DICTIONARY_VALUE('multiple_messages', 'false', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_GenUnitTechChars');
	PUT_NEW_DICTIONARY_VALUE('multiple_messages', 'false', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_EnergyLimitedGenUnitTechChars');
	PUT_NEW_DICTIONARY_VALUE('multiple_messages', 'false', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_InterconnectorTrades');
	PUT_NEW_DICTIONARY_VALUE('multiple_messages', 'false', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_PriceAffectingMeterData');
	PUT_NEW_DICTIONARY_VALUE('multiple_messages', 'false', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExPostMktSchDetail');
	PUT_NEW_DICTIONARY_VALUE('multiple_messages', 'false', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_InitialExPostMktSchDetail');
	PUT_NEW_DICTIONARY_VALUE('multiple_messages', 'false', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_A_AggLoadFcst');
	PUT_NEW_DICTIONARY_VALUE('multiple_messages', 'false', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_M_AggLoadFcst');
	PUT_NEW_DICTIONARY_VALUE('multiple_messages', 'false', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_AggLoadFcst');
	PUT_NEW_DICTIONARY_VALUE('multiple_messages', 'false', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_WithinDayActualSchedules');

	PUT_NEW_DICTIONARY_VALUE('periodicity', 'DAILY', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_RollingWindFcstAssumptionsJurisdiction');
	PUT_NEW_DICTIONARY_VALUE('periodicity', 'DAILY', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TODStandardUnits');
	PUT_NEW_DICTIONARY_VALUE('periodicity', 'DAILY', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TODDemandSideUnits');
	PUT_NEW_DICTIONARY_VALUE('periodicity', 'DAILY', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TODForecastData');
	PUT_NEW_DICTIONARY_VALUE('periodicity', 'DAILY', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CODStandardGenUnits');
	PUT_NEW_DICTIONARY_VALUE('periodicity', 'DAILY', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CODStandardDemUnits');
	PUT_NEW_DICTIONARY_VALUE('periodicity', 'DAILY', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CODInterconnectorUnits');
	PUT_NEW_DICTIONARY_VALUE('periodicity', 'DAILY', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CommercialOfferDataGenNomProfiles');
	PUT_NEW_DICTIONARY_VALUE('periodicity', 'DAILY', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CommercialOfferDataDemNomProfiles');
	PUT_NEW_DICTIONARY_VALUE('periodicity', 'DAILY', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_DemandControlData');
	PUT_NEW_DICTIONARY_VALUE('periodicity', 'DAILY', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_RevIntconnModNominations');
	PUT_NEW_DICTIONARY_VALUE('periodicity', 'DAILY', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExAnteMktSchDetail');
 
	PUT_NEW_DICTIONARY_VALUE('periodicity', 'DAILY', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExAnteIndicativeOpsScheduleDetails');
	PUT_NEW_DICTIONARY_VALUE('periodicity', 'DAILY', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_GenUnitTechChars');
	PUT_NEW_DICTIONARY_VALUE('periodicity', 'DAILY', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_EnergyLimitedGenUnitTechChars');
	PUT_NEW_DICTIONARY_VALUE('periodicity', 'DAILY', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_InterconnectorTrades');
	PUT_NEW_DICTIONARY_VALUE('periodicity', 'DAILY', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_PriceAffectingMeterData');
	PUT_NEW_DICTIONARY_VALUE('periodicity', 'DAILY', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExPostMktSchDetail');
	PUT_NEW_DICTIONARY_VALUE('periodicity', 'DAILY', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_InitialExPostMktSchDetail');
	PUT_NEW_DICTIONARY_VALUE('periodicity', 'YEARLY', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_A_AggLoadFcst');
	PUT_NEW_DICTIONARY_VALUE('periodicity', 'MONTHLY', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_M_AggLoadFcst');
	PUT_NEW_DICTIONARY_VALUE('periodicity', 'DAILY', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_AggLoadFcst');
	PUT_NEW_DICTIONARY_VALUE('periodicity', 'DAILY', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_WithinDayActualSchedules');

	PUT_NEW_DICTIONARY_VALUE('access_class', 'PUB', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_RollingWindFcstAssumptionsJurisdiction');
	PUT_NEW_DICTIONARY_VALUE('access_class', 'PUB', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TODStandardUnits');
	PUT_NEW_DICTIONARY_VALUE('access_class', 'PUB', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TODDemandSideUnits');
	PUT_NEW_DICTIONARY_VALUE('access_class', 'PUB', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TODForecastData');
	PUT_NEW_DICTIONARY_VALUE('access_class', 'PUB', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CODStandardGenUnits');
	PUT_NEW_DICTIONARY_VALUE('access_class', 'PUB', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CODStandardDemUnits');
	PUT_NEW_DICTIONARY_VALUE('access_class', 'PUB', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CODInterconnectorUnits');
	PUT_NEW_DICTIONARY_VALUE('access_class', 'PUB', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CommercialOfferDataGenNomProfiles');
	PUT_NEW_DICTIONARY_VALUE('access_class', 'PUB', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CommercialOfferDataDemNomProfiles');
	PUT_NEW_DICTIONARY_VALUE('access_class', 'PUB', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_DemandControlData');
	PUT_NEW_DICTIONARY_VALUE('access_class', 'PUB', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_RevIntconnModNominations');
	PUT_NEW_DICTIONARY_VALUE('access_class', 'PUB', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExAnteMktSchDetail');
 
	PUT_NEW_DICTIONARY_VALUE('access_class', 'PUB', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExAnteIndicativeOpsScheduleDetails');
	PUT_NEW_DICTIONARY_VALUE('access_class', 'PUB', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_GenUnitTechChars');
	PUT_NEW_DICTIONARY_VALUE('access_class', 'PUB', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_EnergyLimitedGenUnitTechChars');
	PUT_NEW_DICTIONARY_VALUE('access_class', 'PUB', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_InterconnectorTrades');
	PUT_NEW_DICTIONARY_VALUE('access_class', 'PUB', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_PriceAffectingMeterData');
	PUT_NEW_DICTIONARY_VALUE('access_class', 'PUB', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExPostMktSchDetail');
	PUT_NEW_DICTIONARY_VALUE('access_class', 'PUB', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_InitialExPostMktSchDetail');
	PUT_NEW_DICTIONARY_VALUE('access_class', 'PUB', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_A_AggLoadFcst');
	PUT_NEW_DICTIONARY_VALUE('access_class', 'PUB', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_M_AggLoadFcst');
	PUT_NEW_DICTIONARY_VALUE('access_class', 'PUB', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_AggLoadFcst');
	PUT_NEW_DICTIONARY_VALUE('access_class', 'MP', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_WithinDayActualSchedules');

	PUT_NEW_DICTIONARY_VALUE('report_name', 'PUB_D_RollingWindFcstAssumptionsJurisdiction', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_RollingWindFcstAssumptionsJurisdiction');
	PUT_NEW_DICTIONARY_VALUE('report_name', 'PUB_D_TODStandardUnits', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TODStandardUnits');
	PUT_NEW_DICTIONARY_VALUE('report_name', 'PUB_D_TODDemandSideUnits', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TODDemandSideUnits');
	PUT_NEW_DICTIONARY_VALUE('report_name', 'PUB_D_TODForecastData', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TODForecastData');
	PUT_NEW_DICTIONARY_VALUE('report_name', 'PUB_D_CODStandardGenUnits', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CODStandardGenUnits');
	PUT_NEW_DICTIONARY_VALUE('report_name', 'PUB_D_CODStandardDemUnits', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CODStandardDemUnits');
	PUT_NEW_DICTIONARY_VALUE('report_name', 'PUB_D_CODInterconnectorUnits', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CODInterconnectorUnits');
	PUT_NEW_DICTIONARY_VALUE('report_name', 'PUB_D_CommercialOfferDataGenNomProfiles', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CommercialOfferDataGenNomProfiles');
	PUT_NEW_DICTIONARY_VALUE('report_name', 'PUB_D_CommercialOfferDataDemNomProfiles', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CommercialOfferDataDemNomProfiles');
	PUT_NEW_DICTIONARY_VALUE('report_name', 'PUB_D_DemandControlData', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_DemandControlData');
	PUT_NEW_DICTIONARY_VALUE('report_name', 'PUB_D_RevIntconnModNominations', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_RevIntconnModNominations');
	PUT_NEW_DICTIONARY_VALUE('report_name', 'PUB_D_ExAnteMktSchDetail', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExAnteMktSchDetail');

	PUT_NEW_DICTIONARY_VALUE('report_name', 'PUB_D_ExAnteIndicativeOpsScheduleDetails', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExAnteIndicativeOpsScheduleDetails');
	PUT_NEW_DICTIONARY_VALUE('report_name', 'PUB_D_GenUnitTechChars', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_GenUnitTechChars');
	PUT_NEW_DICTIONARY_VALUE('report_name', 'PUB_D_EnergyLimitedGenUnitTechChars', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_EnergyLimitedGenUnitTechChars');
	PUT_NEW_DICTIONARY_VALUE('report_name', 'PUB_D_InterconnectorTrades', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_InterconnectorTrades');
	PUT_NEW_DICTIONARY_VALUE('report_name', 'PUB_D_PriceAffectingMeterData', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_PriceAffectingMeterData');
	PUT_NEW_DICTIONARY_VALUE('report_name', 'PUB_D_ExPostMktSchDetail', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExPostMktSchDetail');
	PUT_NEW_DICTIONARY_VALUE('report_name', 'PUB_D_InitialExPostMktSchDetail', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_InitialExPostMktSchDetail');
	PUT_NEW_DICTIONARY_VALUE('report_name', 'PUB_A_AggLoadFcst', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_A_AggLoadFcst');
	PUT_NEW_DICTIONARY_VALUE('report_name', 'PUB_M_AggLoadFcst', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_M_AggLoadFcst');
	PUT_NEW_DICTIONARY_VALUE('report_name', 'PUB_D_AggLoadFcst', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_AggLoadFcst');
	PUT_NEW_DICTIONARY_VALUE('report_name', 'MP_D_WithinDayActualSchedules', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_WithinDayActualSchedules');
	
	PUT_NEW_DICTIONARY_VALUE('import_procedure', 'IMPORT_TECH_OFFER_STD_UNITS', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TODStandardUnits');
	PUT_NEW_DICTIONARY_VALUE('import_procedure', 'IMPORT_TECH_OFFER_STD_UNITS', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TODDemandSideUnits');
	PUT_NEW_DICTIONARY_VALUE('import_procedure', 'IMPORT_TECH_OFFER_FORECAST', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TODForecastData');
	PUT_NEW_DICTIONARY_VALUE('import_procedure', 'IMPORT_COMM_OFFER_STD_UNITS', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CODStandardGenUnits');
	PUT_NEW_DICTIONARY_VALUE('import_procedure', 'IMPORT_COMM_OFFER_STD_UNITS', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CODStandardDemUnits');
	PUT_NEW_DICTIONARY_VALUE('import_procedure', 'IMPORT_COMM_OFFER_IC', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CODInterconnectorUnits');
	PUT_NEW_DICTIONARY_VALUE('import_procedure', 'IMPORT_NOM_PROFILE', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CommercialOfferDataGenNomProfiles');
	PUT_NEW_DICTIONARY_VALUE('import_procedure', 'IMPORT_NOM_PROFILE', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CommercialOfferDataDemNomProfiles');
	PUT_NEW_DICTIONARY_VALUE('import_procedure', 'IMPORT_DEMAND_CTRL_DATA', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_DemandControlData');
	PUT_NEW_DICTIONARY_VALUE('import_procedure', 'IMPORT_MKT_SCHED_DETAIL_PUB', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExAnteMktSchDetail');
    
	PUT_NEW_DICTIONARY_VALUE('import_procedure', 'IMPORT_OPS_SCHED', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExAnteIndicativeOpsScheduleDetails');
	PUT_NEW_DICTIONARY_VALUE('import_procedure', 'IMPORT_EN_LTD_TECH_CHAR', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_EnergyLimitedGenUnitTechChars');
	PUT_NEW_DICTIONARY_VALUE('import_procedure', 'IMPORT_METER_DETAIL_PUB', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_PriceAffectingMeterData');
	PUT_NEW_DICTIONARY_VALUE('import_procedure', 'IMPORT_MKT_SCHED_DETAIL_PUB', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExPostMktSchDetail');
	PUT_NEW_DICTIONARY_VALUE('import_procedure', 'IMPORT_MKT_SCHED_DETAIL_PUB', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_InitialExPostMktSchDetail');
	PUT_NEW_DICTIONARY_VALUE('import_procedure', 'IMPORT_LOAD_FORECAST', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_A_AggLoadFcst');
	PUT_NEW_DICTIONARY_VALUE('import_procedure', 'IMPORT_LOAD_FORECAST', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_M_AggLoadFcst');
	PUT_NEW_DICTIONARY_VALUE('import_procedure', 'IMPORT_LOAD_FORECAST', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_AggLoadFcst');
	PUT_NEW_DICTIONARY_VALUE('import_procedure', 'IMPORT_ACTUAL_SCHEDULES', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_WithinDayActualSchedules');
	PUT_NEW_DICTIONARY_VALUE('import_procedure', 'IMPORT_WIND_FORECAST_BY_JURIS', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_RollingWindFcstAssumptionsJurisdiction');
	PUT_NEW_DICTIONARY_VALUE('import_procedure', 'IMPORT_GEN_UNIT_TECH_CHAR', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_GenUnitTechChars');
	PUT_NEW_DICTIONARY_VALUE('import_procedure', 'IMPORT_SO_TRADES', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_InterconnectorTrades');
	PUT_NEW_DICTIONARY_VALUE('import_procedure', 'IMPORT_IC_NOMINATIONS_PUB', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_RevIntconnModNominations');

	PUT_NEW_DICTIONARY_VALUE('import_param', '', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TODStandardUnits');
	PUT_NEW_DICTIONARY_VALUE('import_param', '', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TODDemandSideUnits');
	PUT_NEW_DICTIONARY_VALUE('import_param', '', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TODForecastData');
	PUT_NEW_DICTIONARY_VALUE('import_param', '', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CODStandardGenUnits');
	PUT_NEW_DICTIONARY_VALUE('import_param', '', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CODStandardDemUnits');
	PUT_NEW_DICTIONARY_VALUE('import_param', '', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CODInterconnectorUnits');
	PUT_NEW_DICTIONARY_VALUE('import_param', '', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CommercialOfferDataGenNomProfiles');
	PUT_NEW_DICTIONARY_VALUE('import_param', '', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CommercialOfferDataDemNomProfiles');
	PUT_NEW_DICTIONARY_VALUE('import_param', '', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_DemandControlData');
	PUT_NEW_DICTIONARY_VALUE('import_param', '', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExAnteMktSchDetail');

	PUT_NEW_DICTIONARY_VALUE('import_param', '', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExAnteIndicativeOpsScheduleDetails');
	PUT_NEW_DICTIONARY_VALUE('import_param', '', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_EnergyLimitedGenUnitTechChars');
	PUT_NEW_DICTIONARY_VALUE('import_param', '', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_PriceAffectingMeterData');
	PUT_NEW_DICTIONARY_VALUE('import_param', '', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExPostMktSchDetail');
	PUT_NEW_DICTIONARY_VALUE('import_param', '', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_InitialExPostMktSchDetail');
	PUT_NEW_DICTIONARY_VALUE('import_param', 'YEARLY', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_A_AggLoadFcst');
	PUT_NEW_DICTIONARY_VALUE('import_param', 'MONTHLY', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_M_AggLoadFcst');
	PUT_NEW_DICTIONARY_VALUE('import_param', 'DAILY', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_AggLoadFcst');
	PUT_NEW_DICTIONARY_VALUE('import_param', '', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_WithinDayActualSchedules');
	PUT_NEW_DICTIONARY_VALUE('import_param', '', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_RollingWindFcstAssumptionsJurisdiction');
	PUT_NEW_DICTIONARY_VALUE('import_param', '', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_GenUnitTechChars');
	PUT_NEW_DICTIONARY_VALUE('import_param', '', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_InterconnectorTrades');
	PUT_NEW_DICTIONARY_VALUE('import_param', '', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_RevIntconnModNominations');

	PUT_NEW_DICTIONARY_VALUE('report_type','MARKET', 0,'MarketExchange','SEM','SMO Reports','PUB_D_TODStandardUnits');
	PUT_NEW_DICTIONARY_VALUE('report_type','MARKET', 0,'MarketExchange','SEM','SMO Reports','PUB_D_TODDemandSideUnits');
	PUT_NEW_DICTIONARY_VALUE('report_type','MARKET', 0,'MarketExchange','SEM','SMO Reports','PUB_D_TODForecastData');
	PUT_NEW_DICTIONARY_VALUE('report_type','MARKET', 0,'MarketExchange','SEM','SMO Reports','PUB_D_CODStandardGenUnits');
	PUT_NEW_DICTIONARY_VALUE('report_type','MARKET', 0,'MarketExchange','SEM','SMO Reports','PUB_D_CODStandardDemUnits');
	PUT_NEW_DICTIONARY_VALUE('report_type','MARKET', 0,'MarketExchange','SEM','SMO Reports','PUB_D_CODInterconnectorUnits');
	PUT_NEW_DICTIONARY_VALUE('report_type','MARKET', 0,'MarketExchange','SEM','SMO Reports','PUB_D_CommercialOfferDataGenNomProfiles');
	PUT_NEW_DICTIONARY_VALUE('report_type','MARKET', 0,'MarketExchange','SEM','SMO Reports','PUB_D_CommercialOfferDataDemNomProfiles');
	PUT_NEW_DICTIONARY_VALUE('report_type','MARKET', 0,'MarketExchange','SEM','SMO Reports','PUB_D_DemandControlData');
	PUT_NEW_DICTIONARY_VALUE('report_type','MARKET', 0,'MarketExchange','SEM','SMO Reports','PUB_D_ExAnteMktSchDetail');
    
	PUT_NEW_DICTIONARY_VALUE('report_type','MARKET', 0,'MarketExchange','SEM','SMO Reports','PUB_D_ExAnteIndicativeOpsScheduleDetails');
	PUT_NEW_DICTIONARY_VALUE('report_type','MARKET', 0,'MarketExchange','SEM','SMO Reports','PUB_D_EnergyLimitedGenUnitTechChars');
	PUT_NEW_DICTIONARY_VALUE('report_type','MARKET', 0,'MarketExchange','SEM','SMO Reports','PUB_D_PriceAffectingMeterData');
	PUT_NEW_DICTIONARY_VALUE('report_type','MARKET', 0,'MarketExchange','SEM','SMO Reports','PUB_D_ExPostMktSchDetail');
	PUT_NEW_DICTIONARY_VALUE('report_type','MARKET', 0,'MarketExchange','SEM','SMO Reports','PUB_D_InitialExPostMktSchDetail');
	PUT_NEW_DICTIONARY_VALUE('report_type','TRANS_SYSTEM', 0,'MarketExchange','SEM','SMO Reports','PUB_A_AggLoadFcst');
	PUT_NEW_DICTIONARY_VALUE('report_type','TRANS_SYSTEM', 0,'MarketExchange','SEM','SMO Reports','PUB_M_AggLoadFcst');
	PUT_NEW_DICTIONARY_VALUE('report_type','TRANS_SYSTEM', 0,'MarketExchange','SEM','SMO Reports','PUB_D_AggLoadFcst');
	PUT_NEW_DICTIONARY_VALUE('report_type','MARKET', 0,'MarketExchange','SEM','SMO Reports','MP_D_WithinDayActualSchedules');
	PUT_NEW_DICTIONARY_VALUE('report_type','TRANS_SYSTEM', 0,'MarketExchange','SEM','SMO Reports','PUB_D_RollingWindFcstAssumptionsJurisdiction');
	PUT_NEW_DICTIONARY_VALUE('report_type','MARKET', 0,'MarketExchange','SEM','SMO Reports','PUB_D_GenUnitTechChars');
	PUT_NEW_DICTIONARY_VALUE('report_type','TRANS_SYSTEM', 0,'MarketExchange','SEM','SMO Reports','PUB_D_InterconnectorTrades');
	PUT_NEW_DICTIONARY_VALUE('report_type','TRANS_SYSTEM', 0,'MarketExchange','SEM','SMO Reports','PUB_D_RevIntconnModNominations');

	PUT_NEW_DICTIONARY_VALUE('report_sub_type','DAY_AHEAD', 0,'MarketExchange','SEM','SMO Reports','PUB_D_TODStandardUnits');
	PUT_NEW_DICTIONARY_VALUE('report_sub_type','DAY_AHEAD', 0,'MarketExchange','SEM','SMO Reports','PUB_D_TODDemandSideUnits');
	PUT_NEW_DICTIONARY_VALUE('report_sub_type','DAY_AHEAD', 0,'MarketExchange','SEM','SMO Reports','PUB_D_TODForecastData');
	PUT_NEW_DICTIONARY_VALUE('report_sub_type','DAY_AHEAD', 0,'MarketExchange','SEM','SMO Reports','PUB_D_CODStandardGenUnits');
	PUT_NEW_DICTIONARY_VALUE('report_sub_type','DAY_AHEAD', 0,'MarketExchange','SEM','SMO Reports','PUB_D_CODStandardDemUnits');
	PUT_NEW_DICTIONARY_VALUE('report_sub_type','DAY_AHEAD', 0,'MarketExchange','SEM','SMO Reports','PUB_D_CODInterconnectorUnits');
	PUT_NEW_DICTIONARY_VALUE('report_sub_type','DAY_AHEAD', 0,'MarketExchange','SEM','SMO Reports','PUB_D_CommercialOfferDataGenNomProfiles');
	PUT_NEW_DICTIONARY_VALUE('report_sub_type','DAY_AHEAD', 0,'MarketExchange','SEM','SMO Reports','PUB_D_CommercialOfferDataDemNomProfiles');
	PUT_NEW_DICTIONARY_VALUE('report_sub_type','DAY_AHEAD', 0,'MarketExchange','SEM','SMO Reports','PUB_D_DemandControlData');
	PUT_NEW_DICTIONARY_VALUE('report_sub_type','DAY_AHEAD', 0,'MarketExchange','SEM','SMO Reports','PUB_D_ExAnteMktSchDetail');

	PUT_NEW_DICTIONARY_VALUE('report_sub_type','DAY_AHEAD', 0,'MarketExchange','SEM','SMO Reports','PUB_D_ExAnteIndicativeOpsScheduleDetails');
	PUT_NEW_DICTIONARY_VALUE('report_sub_type','DAY_AHEAD', 0,'MarketExchange','SEM','SMO Reports','PUB_D_EnergyLimitedGenUnitTechChars');
	PUT_NEW_DICTIONARY_VALUE('report_sub_type','METERING', 0,'MarketExchange','SEM','SMO Reports','PUB_D_PriceAffectingMeterData');
	PUT_NEW_DICTIONARY_VALUE('report_sub_type','DAY_AHEAD', 0,'MarketExchange','SEM','SMO Reports','PUB_D_ExPostMktSchDetail');
	PUT_NEW_DICTIONARY_VALUE('report_sub_type','DAY_AHEAD', 0,'MarketExchange','SEM','SMO Reports','PUB_D_InitialExPostMktSchDetail');
	PUT_NEW_DICTIONARY_VALUE('report_sub_type','FORECASTS', 0,'MarketExchange','SEM','SMO Reports','PUB_A_AggLoadFcst');
	PUT_NEW_DICTIONARY_VALUE('report_sub_type','FORECASTS', 0,'MarketExchange','SEM','SMO Reports','PUB_M_AggLoadFcst');
	PUT_NEW_DICTIONARY_VALUE('report_sub_type','FORECASTS', 0,'MarketExchange','SEM','SMO Reports','PUB_D_AggLoadFcst');
	PUT_NEW_DICTIONARY_VALUE('report_sub_type','DAY_AHEAD', 0,'MarketExchange','SEM','SMO Reports','MP_D_WithinDayActualSchedules');
	PUT_NEW_DICTIONARY_VALUE('report_sub_type','FORECASTS', 0,'MarketExchange','SEM','SMO Reports','PUB_D_RollingWindFcstAssumptionsJurisdiction');
	PUT_NEW_DICTIONARY_VALUE('report_sub_type','DAY_AHEAD', 0,'MarketExchange','SEM','SMO Reports','PUB_D_GenUnitTechChars');
	PUT_NEW_DICTIONARY_VALUE('report_sub_type','INTERCONNECTOR', 0,'MarketExchange','SEM','SMO Reports','PUB_D_InterconnectorTrades');
	PUT_NEW_DICTIONARY_VALUE('report_sub_type','INTERCONNECTOR', 0,'MarketExchange','SEM','SMO Reports','PUB_D_RevIntconnModNominations');
	

	PUT_NEW_DICTIONARY_VALUE('application_type', 'MARKET_REPORT', 0, 'MarketExchange', 'SEM','SMO Reports','MP_D_RevIntconnModNominationsD4');
    PUT_NEW_DICTIONARY_VALUE('mode', 'NORMAL', 0, 'MarketExchange', 'SEM','SMO Reports','MP_D_RevIntconnModNominationsD4');
    PUT_NEW_DICTIONARY_VALUE('request_type', 'REPORT', 0, 'MarketExchange', 'SEM','SMO Reports','MP_D_RevIntconnModNominationsD4');
    PUT_NEW_DICTIONARY_VALUE('action', 'DOWNLOAD', 0, 'MarketExchange', 'SEM','SMO Reports','MP_D_RevIntconnModNominationsD4');
    PUT_NEW_DICTIONARY_VALUE('access_class', 'MP', 0, 'MarketExchange', 'SEM','SMO Reports','MP_D_RevIntconnModNominationsD4');
    PUT_NEW_DICTIONARY_VALUE('file_type', 'XML', 0, 'MarketExchange', 'SEM','SMO Reports','MP_D_RevIntconnModNominationsD4');
    PUT_NEW_DICTIONARY_VALUE('periodicity', 'DAILY', 0, 'MarketExchange', 'SEM','SMO Reports','MP_D_RevIntconnModNominationsD4');
    PUT_NEW_DICTIONARY_VALUE('report_name', 'MP_D_RevIntconnModNominationsD4', 0, 'MarketExchange', 'SEM','SMO Reports','MP_D_RevIntconnModNominationsD4');
    PUT_NEW_DICTIONARY_VALUE('file_name', 'MP_D_RevIntconnModNominations_05022007.xml', 0, 'MarketExchange', 'SEM','SMO Reports','MP_D_RevIntconnModNominationsD4');
    PUT_NEW_DICTIONARY_VALUE('report_type', 'TRANS_SYSTEM', 0, 'MarketExchange', 'SEM','SMO Reports','MP_D_RevIntconnModNominationsD4');
    PUT_NEW_DICTIONARY_VALUE('report_sub_type', 'INTERCONNECTOR', 0, 'MarketExchange', 'SEM','SMO Reports','MP_D_RevIntconnModNominationsD4');
    PUT_NEW_DICTIONARY_VALUE('version_no', '1.0', 0, 'MarketExchange', 'SEM','SMO Reports','MP_D_RevIntconnModNominationsD4');
    PUT_NEW_DICTIONARY_VALUE('multiple_messages','false', 0, 'MarketExchange', 'SEM','SMO Reports','MP_D_RevIntconnModNominationsD4');
    PUT_NEW_DICTIONARY_VALUE('import_param', 'Revised Modified', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_RevIntconnModNominationsD4');
    PUT_NEW_DICTIONARY_VALUE('import_procedure', 'IMPORT_IC_NOMINATIONS', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_RevIntconnModNominationsD4');

	END;
/
-- save changes to database
COMMIT;


