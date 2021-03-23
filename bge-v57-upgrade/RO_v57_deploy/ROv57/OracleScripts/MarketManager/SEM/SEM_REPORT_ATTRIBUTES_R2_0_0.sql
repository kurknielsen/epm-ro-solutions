/********************
	Update system dictionary with new file_name attribute values for SEM reports. Each report is under Global | MarketExchange.
********************/
DECLARE
    ------------------------------
    PROCEDURE PUT_DICTIONARY_VALUE
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
        	UPDATE SYSTEM_DICTIONARY
        		SET VALUE = p_VALUE
		   	WHERE MODEL_ID = p_MODEL_ID
    			AND UPPER(MODULE) = UPPER(p_MODULE)
    			AND UPPER(KEY1) = UPPER(p_KEY1)
    	   		AND UPPER(KEY2) = UPPER(p_KEY2)
    			AND UPPER(KEY3) = UPPER(p_KEY3)
    			AND UPPER(SETTING_NAME) = UPPER(p_SETTING_NAME);
		ELSE --Match Case
        	UPDATE SYSTEM_DICTIONARY
        		SET VALUE = p_VALUE
		   	WHERE MODEL_ID = p_MODEL_ID
    			AND MODULE = p_MODULE
    			AND KEY1 = p_KEY1
    	   		AND KEY2 = p_KEY2
    			AND KEY3 = p_KEY3
    			AND SETTING_NAME = p_SETTING_NAME;
		END IF;

	IF SQL%NOTFOUND THEN
		INSERT INTO SYSTEM_DICTIONARY (
			MODEL_ID, MODULE, KEY1, KEY2, KEY3, SETTING_NAME, VALUE)
		VALUES (
			p_MODEL_ID, p_MODULE, p_KEY1, p_KEY2, p_KEY3, p_SETTING_NAME, p_VALUE);
	END IF;
    
    END PUT_DICTIONARY_VALUE;
    ------------------------------
BEGIN

--The system dictionary updates and additions that is needed to support the import of current PUB_D_ExAnteMktSchDetail and the three flavors/gates(EA, EA2, WD1)
	PUT_DICTIONARY_VALUE('file_name', 'PUB_D_ExAnteMktSchDetail.xml', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExAnteMktSchDetail');

	PUT_DICTIONARY_VALUE('file_type', 'XML', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExAnteMktSchDetail_EA');
	PUT_DICTIONARY_VALUE('file_type', 'XML', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExAnteMktSchDetail_EA2');
	PUT_DICTIONARY_VALUE('file_type', 'XML', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExAnteMktSchDetail_WD1');
		
	PUT_DICTIONARY_VALUE('application_type', 'MARKET_REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExAnteMktSchDetail_EA');
	PUT_DICTIONARY_VALUE('application_type', 'MARKET_REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExAnteMktSchDetail_EA2');
	PUT_DICTIONARY_VALUE('application_type', 'MARKET_REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExAnteMktSchDetail_WD1');
		
	PUT_DICTIONARY_VALUE('version_no', '1.0', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExAnteMktSchDetail_EA');
	PUT_DICTIONARY_VALUE('version_no', '1.0', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExAnteMktSchDetail_EA2');
	PUT_DICTIONARY_VALUE('version_no', '1.0', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExAnteMktSchDetail_WD1');
		
	PUT_DICTIONARY_VALUE('request_type', 'REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExAnteMktSchDetail_EA');
	PUT_DICTIONARY_VALUE('request_type', 'REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExAnteMktSchDetail_EA2');
	PUT_DICTIONARY_VALUE('request_type', 'REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExAnteMktSchDetail_WD1');
		
	PUT_DICTIONARY_VALUE('mode', 'NORMAL', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExAnteMktSchDetail_EA');
	PUT_DICTIONARY_VALUE('mode', 'NORMAL', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExAnteMktSchDetail_EA2');
	PUT_DICTIONARY_VALUE('mode', 'NORMAL', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExAnteMktSchDetail_WD1');

	PUT_DICTIONARY_VALUE('file_name', 'PUB_D_ExAnteMktSchDetail_EA.xml', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExAnteMktSchDetail_EA');
	PUT_DICTIONARY_VALUE('file_name', 'PUB_D_ExAnteMktSchDetail_EA2.xml', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExAnteMktSchDetail_EA2');
	PUT_DICTIONARY_VALUE('file_name', 'PUB_D_ExAnteMktSchDetail_WD1.xml', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExAnteMktSchDetail_WD1');

	PUT_DICTIONARY_VALUE('action', 'DOWNLOAD', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExAnteMktSchDetail_EA');
	PUT_DICTIONARY_VALUE('action', 'DOWNLOAD', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExAnteMktSchDetail_EA2');
	PUT_DICTIONARY_VALUE('action', 'DOWNLOAD', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExAnteMktSchDetail_WD1');

	PUT_DICTIONARY_VALUE('multiple_messages', 'false', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExAnteMktSchDetail_EA');
	PUT_DICTIONARY_VALUE('multiple_messages', 'false', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExAnteMktSchDetail_EA2');
	PUT_DICTIONARY_VALUE('multiple_messages', 'false', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExAnteMktSchDetail_WD1');
		
	PUT_DICTIONARY_VALUE('periodicity', 'DAILY', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExAnteMktSchDetail_EA');
	PUT_DICTIONARY_VALUE('periodicity', 'DAILY', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExAnteMktSchDetail_EA2');
	PUT_DICTIONARY_VALUE('periodicity', 'DAILY', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExAnteMktSchDetail_WD1');

	PUT_DICTIONARY_VALUE('access_class', 'PUB', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExAnteMktSchDetail_EA');
	PUT_DICTIONARY_VALUE('access_class', 'PUB', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExAnteMktSchDetail_EA2');
	PUT_DICTIONARY_VALUE('access_class', 'PUB', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExAnteMktSchDetail_WD1');

	PUT_DICTIONARY_VALUE('report_name', 'PUB_D_ExAnteMktSchDetail', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExAnteMktSchDetail_EA');
	PUT_DICTIONARY_VALUE('report_name', 'PUB_D_ExAnteMktSchDetail', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExAnteMktSchDetail_EA2');
	PUT_DICTIONARY_VALUE('report_name', 'PUB_D_ExAnteMktSchDetail', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExAnteMktSchDetail_WD1');

	PUT_DICTIONARY_VALUE('import_procedure', 'IMPORT_MKT_SCHED_DETAIL_PUB', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExAnteMktSchDetail_EA');
	PUT_DICTIONARY_VALUE('import_procedure', 'IMPORT_MKT_SCHED_DETAIL_PUB', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExAnteMktSchDetail_EA2');
	PUT_DICTIONARY_VALUE('import_procedure', 'IMPORT_MKT_SCHED_DETAIL_PUB', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExAnteMktSchDetail_WD1');
		
	PUT_DICTIONARY_VALUE('import_param', '', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExAnteMktSchDetail_EA');
	PUT_DICTIONARY_VALUE('import_param', '', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExAnteMktSchDetail_EA2');
	PUT_DICTIONARY_VALUE('import_param', '', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExAnteMktSchDetail_WD1');

	PUT_DICTIONARY_VALUE('report_type','MARKET', 0,'MarketExchange','SEM','SMO Reports','PUB_D_ExAnteMktSchDetail_EA');
	PUT_DICTIONARY_VALUE('report_type','MARKET', 0,'MarketExchange','SEM','SMO Reports','PUB_D_ExAnteMktSchDetail_EA2');
	PUT_DICTIONARY_VALUE('report_type','MARKET', 0,'MarketExchange','SEM','SMO Reports','PUB_D_ExAnteMktSchDetail_WD1');

	PUT_DICTIONARY_VALUE('report_sub_type','DAY_AHEAD', 0,'MarketExchange','SEM','SMO Reports','PUB_D_ExAnteMktSchDetail_EA');
	PUT_DICTIONARY_VALUE('report_sub_type','DAY_AHEAD', 0,'MarketExchange','SEM','SMO Reports','PUB_D_ExAnteMktSchDetail_EA2');
	PUT_DICTIONARY_VALUE('report_sub_type','DAY_AHEAD', 0,'MarketExchange','SEM','SMO Reports','PUB_D_ExAnteMktSchDetail_WD1');

	--The system dictionary updates that is needed to support the update of value of the file_name attribute for all existing SMO Reports
	PUT_DICTIONARY_VALUE('file_name', 'MP_D_InitialExPostMktSchDetail.xml', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'Daily Initial Ex-Post Market Schedule Details');
	PUT_DICTIONARY_VALUE('file_name', 'PUB_D_MarketPricesAverages.xml', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'Daily Market Prices Averages (SMP)');
	PUT_DICTIONARY_VALUE('file_name', 'PUB_D_IndicativeMarketPrices.xml', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'Daily Indicative Market Prices');
	PUT_DICTIONARY_VALUE('file_name', 'PUB_D_InitialMarketPrices.xml', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'Daily Initial Ex-Post Market Prices');
	PUT_DICTIONARY_VALUE('file_name', 'PUB_D_MeterDataSummaryD1.xml', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'Daily Meter Data Summary (D+1)');
	PUT_DICTIONARY_VALUE('file_name', 'MP_D_ExAnteIntconnNominations.xml', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'Daily Ex-Ante Interconnector Nominations');
	PUT_DICTIONARY_VALUE('file_name', 'MP_D_ExPostIndIntconnNominations.xml', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'Daily Ex-Post Indicative Interconnector Nominations');
	PUT_DICTIONARY_VALUE('file_name', 'MP_D_ExPostInitIntconnNominations.xml', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'Daily Ex-Post Initial Interconnector Nominations');
	PUT_DICTIONARY_VALUE('file_name', 'MP_D_IntconnModNominations.xml', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'Daily Interconnector Modified Nominations');
	PUT_DICTIONARY_VALUE('file_name', 'MP_D_RevIntconnModNominations.xml', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'Daily Revised Interconnector Modified Nominations');
	PUT_DICTIONARY_VALUE('file_name', 'PUB_ActiveMPUnits.xml', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'List of Active Market Participants and Units');
	PUT_DICTIONARY_VALUE('file_name', 'PUB_D_IntconnCapActHoldResults.xml', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'Daily Interconnector Capacity Active Holdings');
	PUT_DICTIONARY_VALUE('file_name', 'PUB_D_IntconnCapHoldResults.xml', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'Daily Interconnector Capacity Holdings');
	PUT_DICTIONARY_VALUE('file_name', 'PUB_D_LoadFcstAssumptions.xml', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'Daily Four Day Rolling Load Forecast and Assumptions (D+4)');
	PUT_DICTIONARY_VALUE('file_name', 'PUB_D_RevIntconnATCData.xml', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'Daily Revised Interconnector ATC Data');
	PUT_DICTIONARY_VALUE('file_name', 'PUB_D_SystemFrequency.xml', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'Daily SO System Frequency');
	PUT_DICTIONARY_VALUE('file_name', 'PUB_IndicativeInterconnFlows.xml', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'Indicative Interconnector Flows and Residual Capacity');
	PUT_DICTIONARY_VALUE('file_name', 'PUB_InitialInterconnFlows.xml', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'Initial Interconnector Flows and Residual Capacity');
	PUT_DICTIONARY_VALUE('file_name', 'PUB_M_IntconnCapHoldResults.xml', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'Monthly Interconnector Capacity Holding');
	PUT_DICTIONARY_VALUE('file_name', 'PUB_D_JurisdictionErrorSupplyD1.xml', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'Daily Jurisdiction Error Supply MW (D+1)');
	PUT_DICTIONARY_VALUE('file_name', 'PUB_D_JurisdictionErrorSupplyD4.xml', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'Daily Jurisdiction Error Supply MW (D+4)');
	PUT_DICTIONARY_VALUE('file_name', 'MP_D_MeterDataDetailD1.xml', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'Daily Meter Data Detail (D+1)');
	PUT_DICTIONARY_VALUE('file_name', 'PUB_D_MeterDataSummaryD3.xml', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'Daily Meter Data Summary (D+3)');
	PUT_DICTIONARY_VALUE('file_name', 'MP_D_MeterDataDetailD3.xml', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'Daily Meter Data Detail (D+3)');
	PUT_DICTIONARY_VALUE('file_name', 'PUB_D_AdvInfo.xml', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'Daily Market Operations Notifications');
	PUT_DICTIONARY_VALUE('file_name', 'PUB_D_ActualLoadSummary.xml', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'Daily Actual Load Summary');
	PUT_DICTIONARY_VALUE('file_name', 'MP_D_AggIntconnUsrNominations.xml', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'Daily Aggregated Interconnector User Nominations');
	PUT_DICTIONARY_VALUE('file_name', 'PUB_ActiveMPs.xml', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'List of Active Market Participants');
	PUT_DICTIONARY_VALUE('file_name', 'PUB_SuspTermMPs.xml', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'List of Suspended/Terminated Market Participants');
	PUT_DICTIONARY_VALUE('file_name', 'PUB_A_LoadFcst.xml', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'Annual Load Forecast');
	PUT_DICTIONARY_VALUE('file_name', 'PUB_M_LoadFcstAssumptions.xml', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'Monthly Load Forecast and Assumptions');
	PUT_DICTIONARY_VALUE('file_name', 'PUB_M_SttlClassesUpdates.xml', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'Monthly Updates to Settlement Classes');
	PUT_DICTIONARY_VALUE('file_name', 'PUB_M_LossLoadProbabilityFcst.xml', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'Monthly Loss of Load Probability Forecast');
	PUT_DICTIONARY_VALUE('file_name', 'PUB_D_IntconnATCData.xml', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'Daily Interconnector ATC Data');
	PUT_DICTIONARY_VALUE('file_name', 'PUB_D_ExchangeRate.xml', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'Daily Trading Day Exchange Rate');
	PUT_DICTIONARY_VALUE('file_name', 'PUB_D_LoadFcstSummary.xml', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'Daily Load Forecast Summary');
	PUT_DICTIONARY_VALUE('file_name', 'PUB_D_RollingWindFcstAssumptions.xml', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'Daily Rolling Wind Forecast and Assumptions');
	PUT_DICTIONARY_VALUE('file_name', 'PUB_D_ExAnteMktSchSummary.xml', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'Daily Ex-Ante Market Schedule Summary');
	PUT_DICTIONARY_VALUE('file_name', 'MP_D_ExAnteMktSchDetail.xml', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'Daily Ex-Ante Market Schedule Detail');
	PUT_DICTIONARY_VALUE('file_name', 'MP_D_IntconnNominations.xml', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'Daily Interconnector Nominations');
	PUT_DICTIONARY_VALUE('file_name', 'PUB_D_DispatchInstructions.xml', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'Daily Dispatch Instructions');	
	PUT_DICTIONARY_VALUE('file_name', 'PUB_D_ExPostMktSchSummary.xml', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'Daily Indicative Ex-Post Market Schedule Summary');
	PUT_DICTIONARY_VALUE('file_name', 'MP_D_ExPostMktSchDetail.xml', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'Daily Indicative Ex-Post Market Schedule Detail');
	PUT_DICTIONARY_VALUE('file_name', 'PUB_D_InitialExPostMktSchSummary.xml', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'Daily Initial Ex-Post Market Schedule Summary');
	PUT_DICTIONARY_VALUE('file_name', 'PUB_D_RollingWindFcstAssumptionsJurisdiction.xml', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_RollingWindFcstAssumptionsJurisdiction');
	PUT_DICTIONARY_VALUE('file_name', 'PUB_D_TODStandardUnits.xml', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TODStandardUnits');
	PUT_DICTIONARY_VALUE('file_name', 'PUB_D_TODDemandSideUnits.xml', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TODDemandSideUnits');
	PUT_DICTIONARY_VALUE('file_name', 'PUB_D_TODForecastData.xml', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TODForecastData');
	PUT_DICTIONARY_VALUE('file_name', 'PUB_D_CODStandardGenUnits.xml', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CODStandardGenUnits');
	PUT_DICTIONARY_VALUE('file_name', 'PUB_D_CODStandardDemUnits.xml', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CODStandardDemUnits');
	PUT_DICTIONARY_VALUE('file_name', 'PUB_D_CODInterconnectorUnits.xml', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CODInterconnectorUnits');
	PUT_DICTIONARY_VALUE('file_name', 'PUB_D_CommercialOfferDataGenNomProfiles.xml', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CommercialOfferDataGenNomProfiles');
	PUT_DICTIONARY_VALUE('file_name', 'PUB_D_CommercialOfferDataDemNomProfiles.xml', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CommercialOfferDataDemNomProfiles');
	PUT_DICTIONARY_VALUE('file_name', 'PUB_D_DemandControlData.xml', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_DemandControlData');
	PUT_DICTIONARY_VALUE('file_name', 'PUB_D_RevIntconnModNominations.xml', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_RevIntconnModNominations');
	PUT_DICTIONARY_VALUE('file_name', 'PUB_D_ExAnteIndicativeOpsScheduleDetails.xml', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExAnteIndicativeOpsScheduleDetails');
	PUT_DICTIONARY_VALUE('file_name', 'PUB_D_GenUnitTechChars.xml', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_GenUnitTechChars');
	PUT_DICTIONARY_VALUE('file_name', 'PUB_D_EnergyLimitedGenUnitTechChars.xml', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_EnergyLimitedGenUnitTechChars');
	PUT_DICTIONARY_VALUE('file_name', 'PUB_D_InterconnectorTrades.xml', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_InterconnectorTrades');
	PUT_DICTIONARY_VALUE('file_name', 'PUB_D_PriceAffectingMeterData.xml', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_PriceAffectingMeterData');
	PUT_DICTIONARY_VALUE('file_name', 'PUB_D_ExPostMktSchDetail.xml', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExPostMktSchDetail');
	PUT_DICTIONARY_VALUE('file_name', 'PUB_D_InitialExPostMktSchDetail.xml', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_InitialExPostMktSchDetail');
	PUT_DICTIONARY_VALUE('file_name', 'PUB_A_AggLoadFcst.xml', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_A_AggLoadFcst');
	PUT_DICTIONARY_VALUE('file_name', 'PUB_M_AggLoadFcst.xml', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_M_AggLoadFcst');
	PUT_DICTIONARY_VALUE('file_name', 'PUB_D_AggLoadFcst.xml', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_AggLoadFcst');
	PUT_DICTIONARY_VALUE('file_name', 'MP_D_WithinDayActualSchedules.xml', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_WithinDayActualSchedules');
	PUT_DICTIONARY_VALUE('file_name', 'MP_D_RevIntconnModNominationsD4.xml', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_RevIntconnModNominationsD4');
	PUT_DICTIONARY_VALUE('file_name', 'PUB_ActiveUnits.xml', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'List of Active Units');
	PUT_DICTIONARY_VALUE('file_name', 'MP_D_IndicativeActualSchedules.xml', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'Daily Indicative Actual Schedules');
	PUT_DICTIONARY_VALUE('file_name', 'MP_D_IntconnCapActHoldResults.xml', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_IntconnCapActHoldResults');
	PUT_DICTIONARY_VALUE('file_name', 'PUB_D_EPInitShadowPrices.xml', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_EPInitShadowPrices');
	PUT_DICTIONARY_VALUE('file_name', 'PUB_D_EAShadowPrices.xml', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_EAShadowPrices');
	PUT_DICTIONARY_VALUE('file_name', 'PUB_D_EPIndShadowPrices.xml', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_EPIndShadowPrices');
	PUT_DICTIONARY_VALUE('file_name', 'PUB_D_JurisdictionErrorSupplyD15.xml', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_JurisdictionErrorSupplyD15');
	PUT_DICTIONARY_VALUE('file_name', 'PUB_D_ResidualErrorVolumeD15.xml', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ResidualErrorVolumeD15');
	PUT_DICTIONARY_VALUE('file_name', 'PUB_D_EPLossOfLoadProbability.xml', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_EPLossOfLoadProbability');
	PUT_DICTIONARY_VALUE('file_name', 'PUB_D_ExPostInitActLoadSummary.xml', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExPostInitActLoadSummary');
	
	
	--Update the report name for the 'List of Suspended/Terminated Market Participants' SMO report
	PUT_DICTIONARY_VALUE('report_name', 'PUB_SuspTermMPs', 0, 'MarketExchange', 'SEM','SMO Reports','List of Suspended/Terminated Market Participants');
	
	-------------- PUB_D_DispatchInstructionsD3 ------------------
	PUT_DICTIONARY_VALUE('file_name', 'PUB_D_DispatchInstructionsD3.xml', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_DispatchInstructionsD3');
	PUT_DICTIONARY_VALUE('application_type', 'MARKET_REPORT', 0, 'MarketExchange', 'SEM','SMO Reports','PUB_D_DispatchInstructionsD3');
	PUT_DICTIONARY_VALUE('mode', 'NORMAL', 0, 'MarketExchange', 'SEM','SMO Reports','PUB_D_DispatchInstructionsD3');
	PUT_DICTIONARY_VALUE('request_type', 'REPORT', 0, 'MarketExchange', 'SEM','SMO Reports','PUB_D_DispatchInstructionsD3');
	PUT_DICTIONARY_VALUE('action', 'DOWNLOAD', 0, 'MarketExchange', 'SEM','SMO Reports','PUB_D_DispatchInstructionsD3');
	PUT_DICTIONARY_VALUE('access_class', 'PUB', 0, 'MarketExchange', 'SEM','SMO Reports','PUB_D_DispatchInstructionsD3');
	PUT_DICTIONARY_VALUE('file_type', 'XML', 0, 'MarketExchange', 'SEM','SMO Reports','PUB_D_DispatchInstructionsD3');
	PUT_DICTIONARY_VALUE('import_procedure','IMPORT_DISPATCH_INSTR',0,'MarketExchange','SEM','SMO Reports', 'PUB_D_DispatchInstructionsD3');
	PUT_DICTIONARY_VALUE('import_param','',0,'MarketExchange','SEM','SMO Reports', 'PUB_D_DispatchInstructionsD3');
	PUT_DICTIONARY_VALUE('periodicity', 'DAILY', 0, 'MarketExchange', 'SEM','SMO Reports','PUB_D_DispatchInstructionsD3');
	PUT_DICTIONARY_VALUE('report_name', 'PUB_D_DispatchInstructionsD3', 0, 'MarketExchange', 'SEM','SMO Reports','PUB_D_DispatchInstructionsD3');
	PUT_DICTIONARY_VALUE('report_type', 'MARKET', 0, 'MarketExchange', 'SEM','SMO Reports','PUB_D_DispatchInstructionsD3');
	PUT_DICTIONARY_VALUE('report_sub_type', 'DAY_AHEAD', 0, 'MarketExchange', 'SEM','SMO Reports','PUB_D_DispatchInstructionsD3');
	PUT_DICTIONARY_VALUE('version_no', '1.0', 0, 'MarketExchange', 'SEM','SMO Reports','PUB_D_DispatchInstructionsD3');
	PUT_DICTIONARY_VALUE('multiple_messages','false', 0, 'MarketExchange', 'SEM','SMO Reports','PUB_D_DispatchInstructionsD3');


  -- EA, EA2, WD1 report settings based on existing reports:
  --------------  MP_D_AggIntconnUsrNominations_EA  --------------
  PUT_DICTIONARY_VALUE('access_class', 'MP', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_AggIntconnUsrNominations_EA');
  PUT_DICTIONARY_VALUE('action', 'DOWNLOAD', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_AggIntconnUsrNominations_EA');
  PUT_DICTIONARY_VALUE('application_type', 'MARKET_REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_AggIntconnUsrNominations_EA');
  PUT_DICTIONARY_VALUE('file_name', 'MP_D_AggIntconnUsrNominations_EA.xml', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_AggIntconnUsrNominations_EA');
  PUT_DICTIONARY_VALUE('file_type', 'XML', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_AggIntconnUsrNominations_EA');
  PUT_DICTIONARY_VALUE('import_param', '', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_AggIntconnUsrNominations_EA');
  PUT_DICTIONARY_VALUE('import_procedure', 'IMPORT_IC_AGG_NOMIN', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_AggIntconnUsrNominations_EA');
  PUT_DICTIONARY_VALUE('mode', 'NORMAL', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_AggIntconnUsrNominations_EA');
  PUT_DICTIONARY_VALUE('multiple_messages', 'false', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_AggIntconnUsrNominations_EA');
  PUT_DICTIONARY_VALUE('periodicity', 'DAILY', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_AggIntconnUsrNominations_EA');
  PUT_DICTIONARY_VALUE('report_name', 'MP_D_AggIntconnUsrNominations', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_AggIntconnUsrNominations_EA');
  PUT_DICTIONARY_VALUE('report_sub_type', 'INTERCONNECTOR', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_AggIntconnUsrNominations_EA');
  PUT_DICTIONARY_VALUE('report_type', 'TRANS_SYSTEM', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_AggIntconnUsrNominations_EA');
  PUT_DICTIONARY_VALUE('request_type', 'REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_AggIntconnUsrNominations_EA');
  PUT_DICTIONARY_VALUE('version_no', '1.0', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_AggIntconnUsrNominations_EA');
   
  --------------  MP_D_AggIntconnUsrNominations_EA2  --------------
  PUT_DICTIONARY_VALUE('access_class', 'MP', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_AggIntconnUsrNominations_EA2');
  PUT_DICTIONARY_VALUE('action', 'DOWNLOAD', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_AggIntconnUsrNominations_EA2');
  PUT_DICTIONARY_VALUE('application_type', 'MARKET_REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_AggIntconnUsrNominations_EA2');
  PUT_DICTIONARY_VALUE('file_name', 'MP_D_AggIntconnUsrNominations_EA2.xml', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_AggIntconnUsrNominations_EA2');
  PUT_DICTIONARY_VALUE('file_type', 'XML', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_AggIntconnUsrNominations_EA2');
  PUT_DICTIONARY_VALUE('import_param', '', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_AggIntconnUsrNominations_EA2');
  PUT_DICTIONARY_VALUE('import_procedure', 'IMPORT_IC_AGG_NOMIN', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_AggIntconnUsrNominations_EA2');
  PUT_DICTIONARY_VALUE('mode', 'NORMAL', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_AggIntconnUsrNominations_EA2');
  PUT_DICTIONARY_VALUE('multiple_messages', 'false', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_AggIntconnUsrNominations_EA2');
  PUT_DICTIONARY_VALUE('periodicity', 'DAILY', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_AggIntconnUsrNominations_EA2');
  PUT_DICTIONARY_VALUE('report_name', 'MP_D_AggIntconnUsrNominations', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_AggIntconnUsrNominations_EA2');
  PUT_DICTIONARY_VALUE('report_sub_type', 'INTERCONNECTOR', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_AggIntconnUsrNominations_EA2');
  PUT_DICTIONARY_VALUE('report_type', 'TRANS_SYSTEM', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_AggIntconnUsrNominations_EA2');
  PUT_DICTIONARY_VALUE('request_type', 'REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_AggIntconnUsrNominations_EA2');
  PUT_DICTIONARY_VALUE('version_no', '1.0', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_AggIntconnUsrNominations_EA2');
   
  --------------  MP_D_AggIntconnUsrNominations_WD1  --------------
  PUT_DICTIONARY_VALUE('access_class', 'MP', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_AggIntconnUsrNominations_WD1');
  PUT_DICTIONARY_VALUE('action', 'DOWNLOAD', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_AggIntconnUsrNominations_WD1');
  PUT_DICTIONARY_VALUE('application_type', 'MARKET_REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_AggIntconnUsrNominations_WD1');
  PUT_DICTIONARY_VALUE('file_name', 'MP_D_AggIntconnUsrNominations_WD1.xml', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_AggIntconnUsrNominations_WD1');
  PUT_DICTIONARY_VALUE('file_type', 'XML', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_AggIntconnUsrNominations_WD1');
  PUT_DICTIONARY_VALUE('import_param', '', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_AggIntconnUsrNominations_WD1');
  PUT_DICTIONARY_VALUE('import_procedure', 'IMPORT_IC_AGG_NOMIN', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_AggIntconnUsrNominations_WD1');
  PUT_DICTIONARY_VALUE('mode', 'NORMAL', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_AggIntconnUsrNominations_WD1');
  PUT_DICTIONARY_VALUE('multiple_messages', 'false', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_AggIntconnUsrNominations_WD1');
  PUT_DICTIONARY_VALUE('periodicity', 'DAILY', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_AggIntconnUsrNominations_WD1');
  PUT_DICTIONARY_VALUE('report_name', 'MP_D_AggIntconnUsrNominations', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_AggIntconnUsrNominations_WD1');
  PUT_DICTIONARY_VALUE('report_sub_type', 'INTERCONNECTOR', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_AggIntconnUsrNominations_WD1');
  PUT_DICTIONARY_VALUE('report_type', 'TRANS_SYSTEM', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_AggIntconnUsrNominations_WD1');
  PUT_DICTIONARY_VALUE('request_type', 'REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_AggIntconnUsrNominations_WD1');
  PUT_DICTIONARY_VALUE('version_no', '1.0', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_AggIntconnUsrNominations_WD1');
   
  --------------  MP_D_ExAnteIntconnNominations_EA  --------------
  PUT_DICTIONARY_VALUE('access_class', 'MP', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_ExAnteIntconnNominations_EA');
  PUT_DICTIONARY_VALUE('action', 'DOWNLOAD', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_ExAnteIntconnNominations_EA');
  PUT_DICTIONARY_VALUE('application_type', 'MARKET_REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_ExAnteIntconnNominations_EA');
  PUT_DICTIONARY_VALUE('file_name', 'MP_D_ExAnteIntconnNominations_EA.xml', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_ExAnteIntconnNominations_EA');
  PUT_DICTIONARY_VALUE('file_type', 'XML', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_ExAnteIntconnNominations_EA');
  PUT_DICTIONARY_VALUE('import_param', 'Ex-Ante', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_ExAnteIntconnNominations_EA');
  PUT_DICTIONARY_VALUE('import_procedure', 'IMPORT_IC_NOMINATIONS', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_ExAnteIntconnNominations_EA');
  PUT_DICTIONARY_VALUE('mode', 'NORMAL', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_ExAnteIntconnNominations_EA');
  PUT_DICTIONARY_VALUE('multiple_messages', 'false', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_ExAnteIntconnNominations_EA');
  PUT_DICTIONARY_VALUE('periodicity', 'DAILY', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_ExAnteIntconnNominations_EA');
  PUT_DICTIONARY_VALUE('report_name', 'MP_D_ExAnteIntconnNominations', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_ExAnteIntconnNominations_EA');
  PUT_DICTIONARY_VALUE('report_sub_type', 'INTERCONNECTOR', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_ExAnteIntconnNominations_EA');
  PUT_DICTIONARY_VALUE('report_type', 'TRANS_SYSTEM', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_ExAnteIntconnNominations_EA');
  PUT_DICTIONARY_VALUE('request_type', 'REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_ExAnteIntconnNominations_EA');
  PUT_DICTIONARY_VALUE('version_no', '1.0', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_ExAnteIntconnNominations_EA');
   
  --------------  MP_D_ExAnteIntconnNominations_EA2  --------------
  PUT_DICTIONARY_VALUE('access_class', 'MP', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_ExAnteIntconnNominations_EA2');
  PUT_DICTIONARY_VALUE('action', 'DOWNLOAD', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_ExAnteIntconnNominations_EA2');
  PUT_DICTIONARY_VALUE('application_type', 'MARKET_REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_ExAnteIntconnNominations_EA2');
  PUT_DICTIONARY_VALUE('file_name', 'MP_D_ExAnteIntconnNominations_EA2.xml', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_ExAnteIntconnNominations_EA2');
  PUT_DICTIONARY_VALUE('file_type', 'XML', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_ExAnteIntconnNominations_EA2');
  PUT_DICTIONARY_VALUE('import_param', 'Ex-Ante EA2', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_ExAnteIntconnNominations_EA2');
  PUT_DICTIONARY_VALUE('import_procedure', 'IMPORT_IC_NOMINATIONS', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_ExAnteIntconnNominations_EA2');
  PUT_DICTIONARY_VALUE('mode', 'NORMAL', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_ExAnteIntconnNominations_EA2');
  PUT_DICTIONARY_VALUE('multiple_messages', 'false', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_ExAnteIntconnNominations_EA2');
  PUT_DICTIONARY_VALUE('periodicity', 'DAILY', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_ExAnteIntconnNominations_EA2');
  PUT_DICTIONARY_VALUE('report_name', 'MP_D_ExAnteIntconnNominations', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_ExAnteIntconnNominations_EA2');
  PUT_DICTIONARY_VALUE('report_sub_type', 'INTERCONNECTOR', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_ExAnteIntconnNominations_EA2');
  PUT_DICTIONARY_VALUE('report_type', 'TRANS_SYSTEM', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_ExAnteIntconnNominations_EA2');
  PUT_DICTIONARY_VALUE('request_type', 'REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_ExAnteIntconnNominations_EA2');
  PUT_DICTIONARY_VALUE('version_no', '1.0', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_ExAnteIntconnNominations_EA2');
   
  --------------  MP_D_ExAnteIntconnNominations_WD1  --------------
  PUT_DICTIONARY_VALUE('access_class', 'MP', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_ExAnteIntconnNominations_WD1');
  PUT_DICTIONARY_VALUE('action', 'DOWNLOAD', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_ExAnteIntconnNominations_WD1');
  PUT_DICTIONARY_VALUE('application_type', 'MARKET_REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_ExAnteIntconnNominations_WD1');
  PUT_DICTIONARY_VALUE('file_name', 'MP_D_ExAnteIntconnNominations_WD1.xml', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_ExAnteIntconnNominations_WD1');
  PUT_DICTIONARY_VALUE('file_type', 'XML', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_ExAnteIntconnNominations_WD1');
  PUT_DICTIONARY_VALUE('import_param', 'Ex-Ante WD1', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_ExAnteIntconnNominations_WD1');
  PUT_DICTIONARY_VALUE('import_procedure', 'IMPORT_IC_NOMINATIONS', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_ExAnteIntconnNominations_WD1');
  PUT_DICTIONARY_VALUE('mode', 'NORMAL', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_ExAnteIntconnNominations_WD1');
  PUT_DICTIONARY_VALUE('multiple_messages', 'false', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_ExAnteIntconnNominations_WD1');
  PUT_DICTIONARY_VALUE('periodicity', 'DAILY', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_ExAnteIntconnNominations_WD1');
  PUT_DICTIONARY_VALUE('report_name', 'MP_D_ExAnteIntconnNominations', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_ExAnteIntconnNominations_WD1');
  PUT_DICTIONARY_VALUE('report_sub_type', 'INTERCONNECTOR', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_ExAnteIntconnNominations_WD1');
  PUT_DICTIONARY_VALUE('report_type', 'TRANS_SYSTEM', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_ExAnteIntconnNominations_WD1');
  PUT_DICTIONARY_VALUE('request_type', 'REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_ExAnteIntconnNominations_WD1');
  PUT_DICTIONARY_VALUE('version_no', '1.0', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_ExAnteIntconnNominations_WD1'); 
  
  --------------  MP_D_ExPostIndIntconnNominations_EP1  --------------
  PUT_DICTIONARY_VALUE('access_class', 'MP', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_ExPostIndIntconnNominations_EP1');
  PUT_DICTIONARY_VALUE('action', 'DOWNLOAD', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_ExPostIndIntconnNominations_EP1');
  PUT_DICTIONARY_VALUE('application_type', 'MARKET_REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_ExPostIndIntconnNominations_EP1');
  PUT_DICTIONARY_VALUE('file_name', 'MP_D_ExPostIndIntconnNominations_EP1.xml', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_ExPostIndIntconnNominations_EP1');
  PUT_DICTIONARY_VALUE('file_type', 'XML', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_ExPostIndIntconnNominations_EP1');
  PUT_DICTIONARY_VALUE('import_param', 'Indicative Ex-Post', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_ExPostIndIntconnNominations_EP1');
  PUT_DICTIONARY_VALUE('import_procedure', 'IMPORT_IC_NOMINATIONS', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_ExPostIndIntconnNominations_EP1');
  PUT_DICTIONARY_VALUE('mode', 'NORMAL', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_ExPostIndIntconnNominations_EP1');
  PUT_DICTIONARY_VALUE('multiple_messages', 'false', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_ExPostIndIntconnNominations_EP1');
  PUT_DICTIONARY_VALUE('periodicity', 'DAILY', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_ExPostIndIntconnNominations_EP1');
  PUT_DICTIONARY_VALUE('report_name', 'MP_D_ExAnteIntconnNominations', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_ExPostIndIntconnNominations_EP1');
  PUT_DICTIONARY_VALUE('report_sub_type', 'INTERCONNECTOR', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_ExPostIndIntconnNominations_EP1');
  PUT_DICTIONARY_VALUE('report_type', 'TRANS_SYSTEM', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_ExPostIndIntconnNominations_EP1');
  PUT_DICTIONARY_VALUE('request_type', 'REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_ExPostIndIntconnNominations_EP1');
  PUT_DICTIONARY_VALUE('version_no', '1.0', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_ExPostIndIntconnNominations_EP1');

  --------------  MP_D_ExPostInitIntconnNominations_EP2  --------------
  PUT_DICTIONARY_VALUE('access_class', 'MP', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_ExPostInitIntconnNominations_EP2');
  PUT_DICTIONARY_VALUE('action', 'DOWNLOAD', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_ExPostInitIntconnNominations_EP2');
  PUT_DICTIONARY_VALUE('application_type', 'MARKET_REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_ExPostInitIntconnNominations_EP2');
  PUT_DICTIONARY_VALUE('file_name', 'MP_D_ExPostInitIntconnNominations_EP2.xml', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_ExPostInitIntconnNominations_EP2');
  PUT_DICTIONARY_VALUE('file_type', 'XML', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_ExPostInitIntconnNominations_EP2');
  PUT_DICTIONARY_VALUE('import_param', 'Initial Ex-Post', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_ExPostInitIntconnNominations_EP2');
  PUT_DICTIONARY_VALUE('import_procedure', 'IMPORT_IC_NOMINATIONS', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_ExPostInitIntconnNominations_EP2');
  PUT_DICTIONARY_VALUE('mode', 'NORMAL', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_ExPostInitIntconnNominations_EP2');
  PUT_DICTIONARY_VALUE('multiple_messages', 'false', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_ExPostInitIntconnNominations_EP2');
  PUT_DICTIONARY_VALUE('periodicity', 'DAILY', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_ExPostInitIntconnNominations_EP2');
  PUT_DICTIONARY_VALUE('report_name', 'MP_D_ExAnteIntconnNominations', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_ExPostInitIntconnNominations_EP2');
  PUT_DICTIONARY_VALUE('report_sub_type', 'INTERCONNECTOR', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_ExPostInitIntconnNominations_EP2');
  PUT_DICTIONARY_VALUE('report_type', 'TRANS_SYSTEM', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_ExPostInitIntconnNominations_EP2');
  PUT_DICTIONARY_VALUE('request_type', 'REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_ExPostInitIntconnNominations_EP2');
  PUT_DICTIONARY_VALUE('version_no', '1.0', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_ExPostInitIntconnNominations_EP2');

  --------------  MP_D_ExAnteMktSchDetail_EA  --------------
  PUT_DICTIONARY_VALUE('access_class', 'MP', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_ExAnteMktSchDetail_EA');
  PUT_DICTIONARY_VALUE('action', 'DOWNLOAD', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_ExAnteMktSchDetail_EA');
  PUT_DICTIONARY_VALUE('application_type', 'MARKET_REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_ExAnteMktSchDetail_EA');
  PUT_DICTIONARY_VALUE('file_name', 'MP_D_ExAnteMktSchDetail_EA.xml', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_ExAnteMktSchDetail_EA');
  PUT_DICTIONARY_VALUE('file_type', 'XML', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_ExAnteMktSchDetail_EA');
  PUT_DICTIONARY_VALUE('import_param', 'Ex-Ante', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_ExAnteMktSchDetail_EA');
  PUT_DICTIONARY_VALUE('import_procedure', 'IMPORT_MKT_SCHED_DETAIL', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_ExAnteMktSchDetail_EA');
  PUT_DICTIONARY_VALUE('mode', 'NORMAL', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_ExAnteMktSchDetail_EA');
  PUT_DICTIONARY_VALUE('multiple_messages', 'false', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_ExAnteMktSchDetail_EA');
  PUT_DICTIONARY_VALUE('periodicity', 'DAILY', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_ExAnteMktSchDetail_EA');
  PUT_DICTIONARY_VALUE('report_name', 'MP_D_ExAnteMktSchDetail', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_ExAnteMktSchDetail_EA');
  PUT_DICTIONARY_VALUE('report_sub_type', 'DAY_AHEAD', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_ExAnteMktSchDetail_EA');
  PUT_DICTIONARY_VALUE('report_type', 'MARKET', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_ExAnteMktSchDetail_EA');
  PUT_DICTIONARY_VALUE('request_type', 'REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_ExAnteMktSchDetail_EA');
  PUT_DICTIONARY_VALUE('version_no', '1.0', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_ExAnteMktSchDetail_EA');
   
  --------------  MP_D_ExAnteMktSchDetail_EA2  --------------
  PUT_DICTIONARY_VALUE('access_class', 'MP', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_ExAnteMktSchDetail_EA2');
  PUT_DICTIONARY_VALUE('action', 'DOWNLOAD', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_ExAnteMktSchDetail_EA2');
  PUT_DICTIONARY_VALUE('application_type', 'MARKET_REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_ExAnteMktSchDetail_EA2');
  PUT_DICTIONARY_VALUE('file_name', 'MP_D_ExAnteMktSchDetail_EA2.xml', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_ExAnteMktSchDetail_EA2');
  PUT_DICTIONARY_VALUE('file_type', 'XML', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_ExAnteMktSchDetail_EA2');
  PUT_DICTIONARY_VALUE('import_param', 'EA2', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_ExAnteMktSchDetail_EA2');
  PUT_DICTIONARY_VALUE('import_procedure', 'IMPORT_MKT_SCHED_DETAIL', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_ExAnteMktSchDetail_EA2');
  PUT_DICTIONARY_VALUE('mode', 'NORMAL', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_ExAnteMktSchDetail_EA2');
  PUT_DICTIONARY_VALUE('multiple_messages', 'false', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_ExAnteMktSchDetail_EA2');
  PUT_DICTIONARY_VALUE('periodicity', 'DAILY', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_ExAnteMktSchDetail_EA2');
  PUT_DICTIONARY_VALUE('report_name', 'MP_D_ExAnteMktSchDetail', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_ExAnteMktSchDetail_EA2');
  PUT_DICTIONARY_VALUE('report_sub_type', 'DAY_AHEAD', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_ExAnteMktSchDetail_EA2');
  PUT_DICTIONARY_VALUE('report_type', 'MARKET', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_ExAnteMktSchDetail_EA2');
  PUT_DICTIONARY_VALUE('request_type', 'REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_ExAnteMktSchDetail_EA2');
  PUT_DICTIONARY_VALUE('version_no', '1.0', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_ExAnteMktSchDetail_EA2');
   
  --------------  MP_D_ExAnteMktSchDetail_WD1  --------------
  PUT_DICTIONARY_VALUE('access_class', 'MP', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_ExAnteMktSchDetail_WD1');
  PUT_DICTIONARY_VALUE('action', 'DOWNLOAD', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_ExAnteMktSchDetail_WD1');
  PUT_DICTIONARY_VALUE('application_type', 'MARKET_REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_ExAnteMktSchDetail_WD1');
  PUT_DICTIONARY_VALUE('file_name', 'MP_D_ExAnteMktSchDetail_WD1.xml', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_ExAnteMktSchDetail_WD1');
  PUT_DICTIONARY_VALUE('file_type', 'XML', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_ExAnteMktSchDetail_WD1');
  PUT_DICTIONARY_VALUE('import_param', 'WD1', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_ExAnteMktSchDetail_WD1');
  PUT_DICTIONARY_VALUE('import_procedure', 'IMPORT_MKT_SCHED_DETAIL', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_ExAnteMktSchDetail_WD1');
  PUT_DICTIONARY_VALUE('mode', 'NORMAL', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_ExAnteMktSchDetail_WD1');
  PUT_DICTIONARY_VALUE('multiple_messages', 'false', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_ExAnteMktSchDetail_WD1');
  PUT_DICTIONARY_VALUE('periodicity', 'DAILY', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_ExAnteMktSchDetail_WD1');
  PUT_DICTIONARY_VALUE('report_name', 'MP_D_ExAnteMktSchDetail', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_ExAnteMktSchDetail_WD1');
  PUT_DICTIONARY_VALUE('report_sub_type', 'DAY_AHEAD', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_ExAnteMktSchDetail_WD1');
  PUT_DICTIONARY_VALUE('report_type', 'MARKET', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_ExAnteMktSchDetail_WD1');
  PUT_DICTIONARY_VALUE('request_type', 'REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_ExAnteMktSchDetail_WD1');
  PUT_DICTIONARY_VALUE('version_no', '1.0', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_ExAnteMktSchDetail_WD1');

  --------------  PUB_D_CODInterconnectorUnits_EA  --------------
  PUT_DICTIONARY_VALUE('access_class', 'PUB', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CODInterconnectorUnits_EA');
  PUT_DICTIONARY_VALUE('action', 'DOWNLOAD', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CODInterconnectorUnits_EA');
  PUT_DICTIONARY_VALUE('application_type', 'MARKET_REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CODInterconnectorUnits_EA');
  PUT_DICTIONARY_VALUE('file_name', 'PUB_D_CODInterconnectorUnits_EA.xml', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CODInterconnectorUnits_EA');
  PUT_DICTIONARY_VALUE('file_type', 'XML', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CODInterconnectorUnits_EA');
  PUT_DICTIONARY_VALUE('import_param', '', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CODInterconnectorUnits_EA');
  PUT_DICTIONARY_VALUE('import_procedure', 'IMPORT_COMM_OFFER_IC', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CODInterconnectorUnits_EA');
  PUT_DICTIONARY_VALUE('mode', 'NORMAL', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CODInterconnectorUnits_EA');
  PUT_DICTIONARY_VALUE('multiple_messages', 'false', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CODInterconnectorUnits_EA');
  PUT_DICTIONARY_VALUE('periodicity', 'DAILY', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CODInterconnectorUnits_EA');
  PUT_DICTIONARY_VALUE('report_name', 'PUB_D_CODInterconnectorUnits', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CODInterconnectorUnits_EA');
  PUT_DICTIONARY_VALUE('report_sub_type', 'DAY_AHEAD', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CODInterconnectorUnits_EA');
  PUT_DICTIONARY_VALUE('report_type', 'MARKET', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CODInterconnectorUnits_EA');
  PUT_DICTIONARY_VALUE('request_type', 'REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CODInterconnectorUnits_EA');
  PUT_DICTIONARY_VALUE('version_no', '1.0', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CODInterconnectorUnits_EA');
   
  --------------  PUB_D_CODInterconnectorUnits_EA2  --------------
  PUT_DICTIONARY_VALUE('access_class', 'PUB', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CODInterconnectorUnits_EA2');
  PUT_DICTIONARY_VALUE('action', 'DOWNLOAD', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CODInterconnectorUnits_EA2');
  PUT_DICTIONARY_VALUE('application_type', 'MARKET_REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CODInterconnectorUnits_EA2');
  PUT_DICTIONARY_VALUE('file_name', 'PUB_D_CODInterconnectorUnits_EA2.xml', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CODInterconnectorUnits_EA2');
  PUT_DICTIONARY_VALUE('file_type', 'XML', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CODInterconnectorUnits_EA2');
  PUT_DICTIONARY_VALUE('import_param', '', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CODInterconnectorUnits_EA2');
  PUT_DICTIONARY_VALUE('import_procedure', 'IMPORT_COMM_OFFER_IC', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CODInterconnectorUnits_EA2');
  PUT_DICTIONARY_VALUE('mode', 'NORMAL', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CODInterconnectorUnits_EA2');
  PUT_DICTIONARY_VALUE('multiple_messages', 'false', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CODInterconnectorUnits_EA2');
  PUT_DICTIONARY_VALUE('periodicity', 'DAILY', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CODInterconnectorUnits_EA2');
  PUT_DICTIONARY_VALUE('report_name', 'PUB_D_CODInterconnectorUnits', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CODInterconnectorUnits_EA2');
  PUT_DICTIONARY_VALUE('report_sub_type', 'DAY_AHEAD', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CODInterconnectorUnits_EA2');
  PUT_DICTIONARY_VALUE('report_type', 'MARKET', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CODInterconnectorUnits_EA2');
  PUT_DICTIONARY_VALUE('request_type', 'REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CODInterconnectorUnits_EA2');
  PUT_DICTIONARY_VALUE('version_no', '1.0', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CODInterconnectorUnits_EA2');
   
  --------------  PUB_D_CODInterconnectorUnits_WD1  --------------
  PUT_DICTIONARY_VALUE('access_class', 'PUB', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CODInterconnectorUnits_WD1');
  PUT_DICTIONARY_VALUE('action', 'DOWNLOAD', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CODInterconnectorUnits_WD1');
  PUT_DICTIONARY_VALUE('application_type', 'MARKET_REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CODInterconnectorUnits_WD1');
  PUT_DICTIONARY_VALUE('file_name', 'PUB_D_CODInterconnectorUnits_WD1.xml', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CODInterconnectorUnits_WD1');
  PUT_DICTIONARY_VALUE('file_type', 'XML', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CODInterconnectorUnits_WD1');
  PUT_DICTIONARY_VALUE('import_param', '', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CODInterconnectorUnits_WD1');
  PUT_DICTIONARY_VALUE('import_procedure', 'IMPORT_COMM_OFFER_IC', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CODInterconnectorUnits_WD1');
  PUT_DICTIONARY_VALUE('mode', 'NORMAL', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CODInterconnectorUnits_WD1');
  PUT_DICTIONARY_VALUE('multiple_messages', 'false', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CODInterconnectorUnits_WD1');
  PUT_DICTIONARY_VALUE('periodicity', 'DAILY', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CODInterconnectorUnits_WD1');
  PUT_DICTIONARY_VALUE('report_name', 'PUB_D_CODInterconnectorUnits', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CODInterconnectorUnits_WD1');
  PUT_DICTIONARY_VALUE('report_sub_type', 'DAY_AHEAD', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CODInterconnectorUnits_WD1');
  PUT_DICTIONARY_VALUE('report_type', 'MARKET', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CODInterconnectorUnits_WD1');
  PUT_DICTIONARY_VALUE('request_type', 'REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CODInterconnectorUnits_WD1');
  PUT_DICTIONARY_VALUE('version_no', '1.0', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CODInterconnectorUnits_WD1');
   
  --------------  PUB_D_CODStandardDemUnits_EA  --------------
  PUT_DICTIONARY_VALUE('access_class', 'PUB', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CODStandardDemUnits_EA');
  PUT_DICTIONARY_VALUE('action', 'DOWNLOAD', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CODStandardDemUnits_EA');
  PUT_DICTIONARY_VALUE('application_type', 'MARKET_REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CODStandardDemUnits_EA');
  PUT_DICTIONARY_VALUE('file_name', 'PUB_D_CODStandardDemUnits_EA.xml', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CODStandardDemUnits_EA');
  PUT_DICTIONARY_VALUE('file_type', 'XML', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CODStandardDemUnits_EA');
  PUT_DICTIONARY_VALUE('import_param', '', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CODStandardDemUnits_EA');
  PUT_DICTIONARY_VALUE('import_procedure', 'IMPORT_COMM_OFFER_STD_UNITS', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CODStandardDemUnits_EA');
  PUT_DICTIONARY_VALUE('mode', 'NORMAL', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CODStandardDemUnits_EA');
  PUT_DICTIONARY_VALUE('multiple_messages', 'false', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CODStandardDemUnits_EA');
  PUT_DICTIONARY_VALUE('periodicity', 'DAILY', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CODStandardDemUnits_EA');
  PUT_DICTIONARY_VALUE('report_name', 'PUB_D_CODStandardDemUnits', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CODStandardDemUnits_EA');
  PUT_DICTIONARY_VALUE('report_sub_type', 'DAY_AHEAD', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CODStandardDemUnits_EA');
  PUT_DICTIONARY_VALUE('report_type', 'MARKET', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CODStandardDemUnits_EA');
  PUT_DICTIONARY_VALUE('request_type', 'REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CODStandardDemUnits_EA');
  PUT_DICTIONARY_VALUE('version_no', '1.0', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CODStandardDemUnits_EA');
   
  --------------  PUB_D_CODStandardDemUnits_EA2  --------------
  PUT_DICTIONARY_VALUE('access_class', 'PUB', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CODStandardDemUnits_EA2');
  PUT_DICTIONARY_VALUE('action', 'DOWNLOAD', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CODStandardDemUnits_EA2');
  PUT_DICTIONARY_VALUE('application_type', 'MARKET_REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CODStandardDemUnits_EA2');
  PUT_DICTIONARY_VALUE('file_name', 'PUB_D_CODStandardDemUnits_EA2.xml', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CODStandardDemUnits_EA2');
  PUT_DICTIONARY_VALUE('file_type', 'XML', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CODStandardDemUnits_EA2');
  PUT_DICTIONARY_VALUE('import_param', '', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CODStandardDemUnits_EA2');
  PUT_DICTIONARY_VALUE('import_procedure', 'IMPORT_COMM_OFFER_STD_UNITS', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CODStandardDemUnits_EA2');
  PUT_DICTIONARY_VALUE('mode', 'NORMAL', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CODStandardDemUnits_EA2');
  PUT_DICTIONARY_VALUE('multiple_messages', 'false', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CODStandardDemUnits_EA2');
  PUT_DICTIONARY_VALUE('periodicity', 'DAILY', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CODStandardDemUnits_EA2');
  PUT_DICTIONARY_VALUE('report_name', 'PUB_D_CODStandardDemUnits', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CODStandardDemUnits_EA2');
  PUT_DICTIONARY_VALUE('report_sub_type', 'DAY_AHEAD', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CODStandardDemUnits_EA2');
  PUT_DICTIONARY_VALUE('report_type', 'MARKET', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CODStandardDemUnits_EA2');
  PUT_DICTIONARY_VALUE('request_type', 'REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CODStandardDemUnits_EA2');
  PUT_DICTIONARY_VALUE('version_no', '1.0', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CODStandardDemUnits_EA2');
   
  --------------  PUB_D_CODStandardDemUnits_WD1  --------------
  PUT_DICTIONARY_VALUE('access_class', 'PUB', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CODStandardDemUnits_WD1');
  PUT_DICTIONARY_VALUE('action', 'DOWNLOAD', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CODStandardDemUnits_WD1');
  PUT_DICTIONARY_VALUE('application_type', 'MARKET_REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CODStandardDemUnits_WD1');
  PUT_DICTIONARY_VALUE('file_name', 'PUB_D_CODStandardDemUnits_WD1.xml', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CODStandardDemUnits_WD1');
  PUT_DICTIONARY_VALUE('file_type', 'XML', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CODStandardDemUnits_WD1');
  PUT_DICTIONARY_VALUE('import_param', '', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CODStandardDemUnits_WD1');
  PUT_DICTIONARY_VALUE('import_procedure', 'IMPORT_COMM_OFFER_STD_UNITS', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CODStandardDemUnits_WD1');
  PUT_DICTIONARY_VALUE('mode', 'NORMAL', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CODStandardDemUnits_WD1');
  PUT_DICTIONARY_VALUE('multiple_messages', 'false', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CODStandardDemUnits_WD1');
  PUT_DICTIONARY_VALUE('periodicity', 'DAILY', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CODStandardDemUnits_WD1');
  PUT_DICTIONARY_VALUE('report_name', 'PUB_D_CODStandardDemUnits', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CODStandardDemUnits_WD1');
  PUT_DICTIONARY_VALUE('report_sub_type', 'DAY_AHEAD', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CODStandardDemUnits_WD1');
  PUT_DICTIONARY_VALUE('report_type', 'MARKET', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CODStandardDemUnits_WD1');
  PUT_DICTIONARY_VALUE('request_type', 'REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CODStandardDemUnits_WD1');
  PUT_DICTIONARY_VALUE('version_no', '1.0', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CODStandardDemUnits_WD1');
   
  --------------  PUB_D_CODStandardGenUnits_EA  --------------
  PUT_DICTIONARY_VALUE('access_class', 'PUB', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CODStandardGenUnits_EA');
  PUT_DICTIONARY_VALUE('action', 'DOWNLOAD', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CODStandardGenUnits_EA');
  PUT_DICTIONARY_VALUE('application_type', 'MARKET_REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CODStandardGenUnits_EA');
  PUT_DICTIONARY_VALUE('file_name', 'PUB_D_CODStandardGenUnits_EA.xml', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CODStandardGenUnits_EA');
  PUT_DICTIONARY_VALUE('file_type', 'XML', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CODStandardGenUnits_EA');
  PUT_DICTIONARY_VALUE('import_param', '', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CODStandardGenUnits_EA');
  PUT_DICTIONARY_VALUE('import_procedure', 'IMPORT_COMM_OFFER_STD_UNITS', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CODStandardGenUnits_EA');
  PUT_DICTIONARY_VALUE('mode', 'NORMAL', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CODStandardGenUnits_EA');
  PUT_DICTIONARY_VALUE('multiple_messages', 'false', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CODStandardGenUnits_EA');
  PUT_DICTIONARY_VALUE('periodicity', 'DAILY', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CODStandardGenUnits_EA');
  PUT_DICTIONARY_VALUE('report_name', 'PUB_D_CODStandardGenUnits', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CODStandardGenUnits_EA');
  PUT_DICTIONARY_VALUE('report_sub_type', 'DAY_AHEAD', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CODStandardGenUnits_EA');
  PUT_DICTIONARY_VALUE('report_type', 'MARKET', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CODStandardGenUnits_EA');
  PUT_DICTIONARY_VALUE('request_type', 'REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CODStandardGenUnits_EA');
  PUT_DICTIONARY_VALUE('version_no', '1.0', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CODStandardGenUnits_EA');
   
  --------------  PUB_D_CODStandardGenUnits_EA2  --------------
  PUT_DICTIONARY_VALUE('access_class', 'PUB', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CODStandardGenUnits_EA2');
  PUT_DICTIONARY_VALUE('action', 'DOWNLOAD', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CODStandardGenUnits_EA2');
  PUT_DICTIONARY_VALUE('application_type', 'MARKET_REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CODStandardGenUnits_EA2');
  PUT_DICTIONARY_VALUE('file_name', 'PUB_D_CODStandardGenUnits_EA2.xml', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CODStandardGenUnits_EA2');
  PUT_DICTIONARY_VALUE('file_type', 'XML', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CODStandardGenUnits_EA2');
  PUT_DICTIONARY_VALUE('import_param', '', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CODStandardGenUnits_EA2');
  PUT_DICTIONARY_VALUE('import_procedure', 'IMPORT_COMM_OFFER_STD_UNITS', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CODStandardGenUnits_EA2');
  PUT_DICTIONARY_VALUE('mode', 'NORMAL', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CODStandardGenUnits_EA2');
  PUT_DICTIONARY_VALUE('multiple_messages', 'false', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CODStandardGenUnits_EA2');
  PUT_DICTIONARY_VALUE('periodicity', 'DAILY', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CODStandardGenUnits_EA2');
  PUT_DICTIONARY_VALUE('report_name', 'PUB_D_CODStandardGenUnits', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CODStandardGenUnits_EA2');
  PUT_DICTIONARY_VALUE('report_sub_type', 'DAY_AHEAD', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CODStandardGenUnits_EA2');
  PUT_DICTIONARY_VALUE('report_type', 'MARKET', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CODStandardGenUnits_EA2');
  PUT_DICTIONARY_VALUE('request_type', 'REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CODStandardGenUnits_EA2');
  PUT_DICTIONARY_VALUE('version_no', '1.0', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CODStandardGenUnits_EA2');
   
  --------------  PUB_D_CODStandardGenUnits_WD1  --------------
  PUT_DICTIONARY_VALUE('access_class', 'PUB', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CODStandardGenUnits_WD1');
  PUT_DICTIONARY_VALUE('action', 'DOWNLOAD', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CODStandardGenUnits_WD1');
  PUT_DICTIONARY_VALUE('application_type', 'MARKET_REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CODStandardGenUnits_WD1');
  PUT_DICTIONARY_VALUE('file_name', 'PUB_D_CODStandardGenUnits_WD1.xml', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CODStandardGenUnits_WD1');
  PUT_DICTIONARY_VALUE('file_type', 'XML', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CODStandardGenUnits_WD1');
  PUT_DICTIONARY_VALUE('import_param', '', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CODStandardGenUnits_WD1');
  PUT_DICTIONARY_VALUE('import_procedure', 'IMPORT_COMM_OFFER_STD_UNITS', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CODStandardGenUnits_WD1');
  PUT_DICTIONARY_VALUE('mode', 'NORMAL', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CODStandardGenUnits_WD1');
  PUT_DICTIONARY_VALUE('multiple_messages', 'false', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CODStandardGenUnits_WD1');
  PUT_DICTIONARY_VALUE('periodicity', 'DAILY', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CODStandardGenUnits_WD1');
  PUT_DICTIONARY_VALUE('report_name', 'PUB_D_CODStandardGenUnits', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CODStandardGenUnits_WD1');
  PUT_DICTIONARY_VALUE('report_sub_type', 'DAY_AHEAD', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CODStandardGenUnits_WD1');
  PUT_DICTIONARY_VALUE('report_type', 'MARKET', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CODStandardGenUnits_WD1');
  PUT_DICTIONARY_VALUE('request_type', 'REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CODStandardGenUnits_WD1');
  PUT_DICTIONARY_VALUE('version_no', '1.0', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CODStandardGenUnits_WD1');
   
  --------------  PUB_D_CommercialOfferDataDemNomProfiles_EA  --------------
  PUT_DICTIONARY_VALUE('access_class', 'PUB', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CommercialOfferDataDemNomProfiles_EA');
  PUT_DICTIONARY_VALUE('action', 'DOWNLOAD', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CommercialOfferDataDemNomProfiles_EA');
  PUT_DICTIONARY_VALUE('application_type', 'MARKET_REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CommercialOfferDataDemNomProfiles_EA');
  PUT_DICTIONARY_VALUE('file_name', 'PUB_D_CommercialOfferDataDemNomProfiles_EA.xml', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CommercialOfferDataDemNomProfiles_EA');
  PUT_DICTIONARY_VALUE('file_type', 'XML', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CommercialOfferDataDemNomProfiles_EA');
  PUT_DICTIONARY_VALUE('import_param', '', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CommercialOfferDataDemNomProfiles_EA');
  PUT_DICTIONARY_VALUE('import_procedure', 'IMPORT_NOM_PROFILE', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CommercialOfferDataDemNomProfiles_EA');
  PUT_DICTIONARY_VALUE('mode', 'NORMAL', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CommercialOfferDataDemNomProfiles_EA');
  PUT_DICTIONARY_VALUE('multiple_messages', 'false', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CommercialOfferDataDemNomProfiles_EA');
  PUT_DICTIONARY_VALUE('periodicity', 'DAILY', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CommercialOfferDataDemNomProfiles_EA');
  PUT_DICTIONARY_VALUE('report_name', 'PUB_D_CommercialOfferDataDemNomProfiles', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CommercialOfferDataDemNomProfiles_EA');
  PUT_DICTIONARY_VALUE('report_sub_type', 'DAY_AHEAD', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CommercialOfferDataDemNomProfiles_EA');
  PUT_DICTIONARY_VALUE('report_type', 'MARKET', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CommercialOfferDataDemNomProfiles_EA');
  PUT_DICTIONARY_VALUE('request_type', 'REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CommercialOfferDataDemNomProfiles_EA');
  PUT_DICTIONARY_VALUE('version_no', '1.0', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CommercialOfferDataDemNomProfiles_EA');
   
  --------------  PUB_D_CommercialOfferDataDemNomProfiles_EA2  --------------
  PUT_DICTIONARY_VALUE('access_class', 'PUB', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CommercialOfferDataDemNomProfiles_EA2');
  PUT_DICTIONARY_VALUE('action', 'DOWNLOAD', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CommercialOfferDataDemNomProfiles_EA2');
  PUT_DICTIONARY_VALUE('application_type', 'MARKET_REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CommercialOfferDataDemNomProfiles_EA2');
  PUT_DICTIONARY_VALUE('file_name', 'PUB_D_CommercialOfferDataDemNomProfiles_EA2.xml', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CommercialOfferDataDemNomProfiles_EA2');
  PUT_DICTIONARY_VALUE('file_type', 'XML', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CommercialOfferDataDemNomProfiles_EA2');
  PUT_DICTIONARY_VALUE('import_param', '', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CommercialOfferDataDemNomProfiles_EA2');
  PUT_DICTIONARY_VALUE('import_procedure', 'IMPORT_NOM_PROFILE', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CommercialOfferDataDemNomProfiles_EA2');
  PUT_DICTIONARY_VALUE('mode', 'NORMAL', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CommercialOfferDataDemNomProfiles_EA2');
  PUT_DICTIONARY_VALUE('multiple_messages', 'false', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CommercialOfferDataDemNomProfiles_EA2');
  PUT_DICTIONARY_VALUE('periodicity', 'DAILY', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CommercialOfferDataDemNomProfiles_EA2');
  PUT_DICTIONARY_VALUE('report_name', 'PUB_D_CommercialOfferDataDemNomProfiles', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CommercialOfferDataDemNomProfiles_EA2');
  PUT_DICTIONARY_VALUE('report_sub_type', 'DAY_AHEAD', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CommercialOfferDataDemNomProfiles_EA2');
  PUT_DICTIONARY_VALUE('report_type', 'MARKET', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CommercialOfferDataDemNomProfiles_EA2');
  PUT_DICTIONARY_VALUE('request_type', 'REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CommercialOfferDataDemNomProfiles_EA2');
  PUT_DICTIONARY_VALUE('version_no', '1.0', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CommercialOfferDataDemNomProfiles_EA2');
   
  --------------  PUB_D_CommercialOfferDataDemNomProfiles_WD1  --------------
  PUT_DICTIONARY_VALUE('access_class', 'PUB', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CommercialOfferDataDemNomProfiles_WD1');
  PUT_DICTIONARY_VALUE('action', 'DOWNLOAD', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CommercialOfferDataDemNomProfiles_WD1');
  PUT_DICTIONARY_VALUE('application_type', 'MARKET_REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CommercialOfferDataDemNomProfiles_WD1');
  PUT_DICTIONARY_VALUE('file_name', 'PUB_D_CommercialOfferDataDemNomProfiles_WD1.xml', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CommercialOfferDataDemNomProfiles_WD1');
  PUT_DICTIONARY_VALUE('file_type', 'XML', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CommercialOfferDataDemNomProfiles_WD1');
  PUT_DICTIONARY_VALUE('import_param', '', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CommercialOfferDataDemNomProfiles_WD1');
  PUT_DICTIONARY_VALUE('import_procedure', 'IMPORT_NOM_PROFILE', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CommercialOfferDataDemNomProfiles_WD1');
  PUT_DICTIONARY_VALUE('mode', 'NORMAL', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CommercialOfferDataDemNomProfiles_WD1');
  PUT_DICTIONARY_VALUE('multiple_messages', 'false', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CommercialOfferDataDemNomProfiles_WD1');
  PUT_DICTIONARY_VALUE('periodicity', 'DAILY', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CommercialOfferDataDemNomProfiles_WD1');
  PUT_DICTIONARY_VALUE('report_name', 'PUB_D_CommercialOfferDataDemNomProfiles', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CommercialOfferDataDemNomProfiles_WD1');
  PUT_DICTIONARY_VALUE('report_sub_type', 'DAY_AHEAD', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CommercialOfferDataDemNomProfiles_WD1');
  PUT_DICTIONARY_VALUE('report_type', 'MARKET', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CommercialOfferDataDemNomProfiles_WD1');
  PUT_DICTIONARY_VALUE('request_type', 'REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CommercialOfferDataDemNomProfiles_WD1');
  PUT_DICTIONARY_VALUE('version_no', '1.0', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CommercialOfferDataDemNomProfiles_WD1');
   
  --------------  PUB_D_CommercialOfferDataGenNomProfiles_EA  --------------
  PUT_DICTIONARY_VALUE('access_class', 'PUB', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CommercialOfferDataGenNomProfiles_EA');
  PUT_DICTIONARY_VALUE('action', 'DOWNLOAD', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CommercialOfferDataGenNomProfiles_EA');
  PUT_DICTIONARY_VALUE('application_type', 'MARKET_REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CommercialOfferDataGenNomProfiles_EA');
  PUT_DICTIONARY_VALUE('file_name', 'PUB_D_CommercialOfferDataGenNomProfiles_EA.xml', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CommercialOfferDataGenNomProfiles_EA');
  PUT_DICTIONARY_VALUE('file_type', 'XML', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CommercialOfferDataGenNomProfiles_EA');
  PUT_DICTIONARY_VALUE('import_param', '', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CommercialOfferDataGenNomProfiles_EA');
  PUT_DICTIONARY_VALUE('import_procedure', 'IMPORT_NOM_PROFILE', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CommercialOfferDataGenNomProfiles_EA');
  PUT_DICTIONARY_VALUE('mode', 'NORMAL', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CommercialOfferDataGenNomProfiles_EA');
  PUT_DICTIONARY_VALUE('multiple_messages', 'false', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CommercialOfferDataGenNomProfiles_EA');
  PUT_DICTIONARY_VALUE('periodicity', 'DAILY', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CommercialOfferDataGenNomProfiles_EA');
  PUT_DICTIONARY_VALUE('report_name', 'PUB_D_CommercialOfferDataGenNomProfiles', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CommercialOfferDataGenNomProfiles_EA');
  PUT_DICTIONARY_VALUE('report_sub_type', 'DAY_AHEAD', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CommercialOfferDataGenNomProfiles_EA');
  PUT_DICTIONARY_VALUE('report_type', 'MARKET', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CommercialOfferDataGenNomProfiles_EA');
  PUT_DICTIONARY_VALUE('request_type', 'REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CommercialOfferDataGenNomProfiles_EA');
  PUT_DICTIONARY_VALUE('version_no', '1.0', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CommercialOfferDataGenNomProfiles_EA');
   
  --------------  PUB_D_CommercialOfferDataGenNomProfiles_EA2  --------------
  PUT_DICTIONARY_VALUE('access_class', 'PUB', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CommercialOfferDataGenNomProfiles_EA2');
  PUT_DICTIONARY_VALUE('action', 'DOWNLOAD', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CommercialOfferDataGenNomProfiles_EA2');
  PUT_DICTIONARY_VALUE('application_type', 'MARKET_REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CommercialOfferDataGenNomProfiles_EA2');
  PUT_DICTIONARY_VALUE('file_name', 'PUB_D_CommercialOfferDataGenNomProfiles_EA2.xml', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CommercialOfferDataGenNomProfiles_EA2');
  PUT_DICTIONARY_VALUE('file_type', 'XML', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CommercialOfferDataGenNomProfiles_EA2');
  PUT_DICTIONARY_VALUE('import_param', '', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CommercialOfferDataGenNomProfiles_EA2');
  PUT_DICTIONARY_VALUE('import_procedure', 'IMPORT_NOM_PROFILE', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CommercialOfferDataGenNomProfiles_EA2');
  PUT_DICTIONARY_VALUE('mode', 'NORMAL', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CommercialOfferDataGenNomProfiles_EA2');
  PUT_DICTIONARY_VALUE('multiple_messages', 'false', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CommercialOfferDataGenNomProfiles_EA2');
  PUT_DICTIONARY_VALUE('periodicity', 'DAILY', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CommercialOfferDataGenNomProfiles_EA2');
  PUT_DICTIONARY_VALUE('report_name', 'PUB_D_CommercialOfferDataGenNomProfiles', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CommercialOfferDataGenNomProfiles_EA2');
  PUT_DICTIONARY_VALUE('report_sub_type', 'DAY_AHEAD', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CommercialOfferDataGenNomProfiles_EA2');
  PUT_DICTIONARY_VALUE('report_type', 'MARKET', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CommercialOfferDataGenNomProfiles_EA2');
  PUT_DICTIONARY_VALUE('request_type', 'REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CommercialOfferDataGenNomProfiles_EA2');
  PUT_DICTIONARY_VALUE('version_no', '1.0', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CommercialOfferDataGenNomProfiles_EA2');
   
  --------------  PUB_D_CommercialOfferDataGenNomProfiles_WD1  --------------
  PUT_DICTIONARY_VALUE('access_class', 'PUB', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CommercialOfferDataGenNomProfiles_WD1');
  PUT_DICTIONARY_VALUE('action', 'DOWNLOAD', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CommercialOfferDataGenNomProfiles_WD1');
  PUT_DICTIONARY_VALUE('application_type', 'MARKET_REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CommercialOfferDataGenNomProfiles_WD1');
  PUT_DICTIONARY_VALUE('file_name', 'PUB_D_CommercialOfferDataGenNomProfiles_WD1.xml', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CommercialOfferDataGenNomProfiles_WD1');
  PUT_DICTIONARY_VALUE('file_type', 'XML', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CommercialOfferDataGenNomProfiles_WD1');
  PUT_DICTIONARY_VALUE('import_param', '', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CommercialOfferDataGenNomProfiles_WD1');
  PUT_DICTIONARY_VALUE('import_procedure', 'IMPORT_NOM_PROFILE', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CommercialOfferDataGenNomProfiles_WD1');
  PUT_DICTIONARY_VALUE('mode', 'NORMAL', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CommercialOfferDataGenNomProfiles_WD1');
  PUT_DICTIONARY_VALUE('multiple_messages', 'false', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CommercialOfferDataGenNomProfiles_WD1');
  PUT_DICTIONARY_VALUE('periodicity', 'DAILY', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CommercialOfferDataGenNomProfiles_WD1');
  PUT_DICTIONARY_VALUE('report_name', 'PUB_D_CommercialOfferDataGenNomProfiles', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CommercialOfferDataGenNomProfiles_WD1');
  PUT_DICTIONARY_VALUE('report_sub_type', 'DAY_AHEAD', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CommercialOfferDataGenNomProfiles_WD1');
  PUT_DICTIONARY_VALUE('report_type', 'MARKET', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CommercialOfferDataGenNomProfiles_WD1');
  PUT_DICTIONARY_VALUE('request_type', 'REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CommercialOfferDataGenNomProfiles_WD1');
  PUT_DICTIONARY_VALUE('version_no', '1.0', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_CommercialOfferDataGenNomProfiles_WD1');
   
  --------------  PUB_D_EAShadowPrices_EA  --------------
  PUT_DICTIONARY_VALUE('access_class', 'PUB', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_EAShadowPrices_EA');
  PUT_DICTIONARY_VALUE('action', 'DOWNLOAD', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_EAShadowPrices_EA');
  PUT_DICTIONARY_VALUE('application_type', 'MARKET_REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_EAShadowPrices_EA');
  PUT_DICTIONARY_VALUE('file_name', 'PUB_D_EAShadowPrices_EA.xml', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_EAShadowPrices_EA');
  PUT_DICTIONARY_VALUE('file_type', 'XML', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_EAShadowPrices_EA');
  PUT_DICTIONARY_VALUE('import_param', 'PUB_D_EAShadowPrices', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_EAShadowPrices_EA');
  PUT_DICTIONARY_VALUE('import_procedure', 'IMPORT_SHADOW_SMP', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_EAShadowPrices_EA');
  PUT_DICTIONARY_VALUE('mode', 'NORMAL', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_EAShadowPrices_EA');
  PUT_DICTIONARY_VALUE('multiple_messages', 'false', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_EAShadowPrices_EA');
  PUT_DICTIONARY_VALUE('periodicity', 'DAILY', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_EAShadowPrices_EA');
  PUT_DICTIONARY_VALUE('report_name', 'PUB_D_EAShadowPrices', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_EAShadowPrices_EA');
  PUT_DICTIONARY_VALUE('report_sub_type', 'DAY_AHEAD', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_EAShadowPrices_EA');
  PUT_DICTIONARY_VALUE('report_type', 'MARKET', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_EAShadowPrices_EA');
  PUT_DICTIONARY_VALUE('request_type', 'REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_EAShadowPrices_EA');
  PUT_DICTIONARY_VALUE('version_no', '1.0', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_EAShadowPrices_EA');
   
  --------------  PUB_D_EAShadowPrices_EA2  --------------
  PUT_DICTIONARY_VALUE('access_class', 'PUB', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_EAShadowPrices_EA2');
  PUT_DICTIONARY_VALUE('action', 'DOWNLOAD', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_EAShadowPrices_EA2');
  PUT_DICTIONARY_VALUE('application_type', 'MARKET_REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_EAShadowPrices_EA2');
  PUT_DICTIONARY_VALUE('file_name', 'PUB_D_EAShadowPrices_EA2.xml', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_EAShadowPrices_EA2');
  PUT_DICTIONARY_VALUE('file_type', 'XML', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_EAShadowPrices_EA2');
  PUT_DICTIONARY_VALUE('import_param', 'PUB_D_EAShadowPrices', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_EAShadowPrices_EA2');
  PUT_DICTIONARY_VALUE('import_procedure', 'IMPORT_SHADOW_SMP', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_EAShadowPrices_EA2');
  PUT_DICTIONARY_VALUE('mode', 'NORMAL', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_EAShadowPrices_EA2');
  PUT_DICTIONARY_VALUE('multiple_messages', 'false', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_EAShadowPrices_EA2');
  PUT_DICTIONARY_VALUE('periodicity', 'DAILY', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_EAShadowPrices_EA2');
  PUT_DICTIONARY_VALUE('report_name', 'PUB_D_EAShadowPrices', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_EAShadowPrices_EA2');
  PUT_DICTIONARY_VALUE('report_sub_type', 'DAY_AHEAD', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_EAShadowPrices_EA2');
  PUT_DICTIONARY_VALUE('report_type', 'MARKET', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_EAShadowPrices_EA2');
  PUT_DICTIONARY_VALUE('request_type', 'REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_EAShadowPrices_EA2');
  PUT_DICTIONARY_VALUE('version_no', '1.0', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_EAShadowPrices_EA2');
   
  --------------  PUB_D_EAShadowPrices_WD1  --------------
  PUT_DICTIONARY_VALUE('access_class', 'PUB', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_EAShadowPrices_WD1');
  PUT_DICTIONARY_VALUE('action', 'DOWNLOAD', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_EAShadowPrices_WD1');
  PUT_DICTIONARY_VALUE('application_type', 'MARKET_REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_EAShadowPrices_WD1');
  PUT_DICTIONARY_VALUE('file_name', 'PUB_D_EAShadowPrices_WD1.xml', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_EAShadowPrices_WD1');
  PUT_DICTIONARY_VALUE('file_type', 'XML', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_EAShadowPrices_WD1');
  PUT_DICTIONARY_VALUE('import_param', 'PUB_D_EAShadowPrices', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_EAShadowPrices_WD1');
  PUT_DICTIONARY_VALUE('import_procedure', 'IMPORT_SHADOW_SMP', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_EAShadowPrices_WD1');
  PUT_DICTIONARY_VALUE('mode', 'NORMAL', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_EAShadowPrices_WD1');
  PUT_DICTIONARY_VALUE('multiple_messages', 'false', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_EAShadowPrices_WD1');
  PUT_DICTIONARY_VALUE('periodicity', 'DAILY', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_EAShadowPrices_WD1');
  PUT_DICTIONARY_VALUE('report_name', 'PUB_D_EAShadowPrices', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_EAShadowPrices_WD1');
  PUT_DICTIONARY_VALUE('report_sub_type', 'DAY_AHEAD', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_EAShadowPrices_WD1');
  PUT_DICTIONARY_VALUE('report_type', 'MARKET', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_EAShadowPrices_WD1');
  PUT_DICTIONARY_VALUE('request_type', 'REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_EAShadowPrices_WD1');
  PUT_DICTIONARY_VALUE('version_no', '1.0', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_EAShadowPrices_WD1');
   
  --------------  PUB_D_ExAnteMktSchSummary_EA  --------------
  PUT_DICTIONARY_VALUE('access_class', 'PUB', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExAnteMktSchSummary_EA');
  PUT_DICTIONARY_VALUE('action', 'DOWNLOAD', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExAnteMktSchSummary_EA');
  PUT_DICTIONARY_VALUE('application_type', 'MARKET_REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExAnteMktSchSummary_EA');
  PUT_DICTIONARY_VALUE('file_name', 'PUB_D_ExAnteMktSchSummary_EA.xml', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExAnteMktSchSummary_EA');
  PUT_DICTIONARY_VALUE('file_type', 'XML', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExAnteMktSchSummary_EA');
  PUT_DICTIONARY_VALUE('import_param', 'Ex-Ante', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExAnteMktSchSummary_EA');
  PUT_DICTIONARY_VALUE('import_procedure', 'IMPORT_MKT_SCHED_SUMMARY', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExAnteMktSchSummary_EA');
  PUT_DICTIONARY_VALUE('mode', 'NORMAL', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExAnteMktSchSummary_EA');
  PUT_DICTIONARY_VALUE('multiple_messages', 'false', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExAnteMktSchSummary_EA');
  PUT_DICTIONARY_VALUE('periodicity', 'DAILY', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExAnteMktSchSummary_EA');
  PUT_DICTIONARY_VALUE('report_name', 'PUB_D_ExAnteMktSchSummary', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExAnteMktSchSummary_EA');
  PUT_DICTIONARY_VALUE('report_sub_type', 'DAY_AHEAD', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExAnteMktSchSummary_EA');
  PUT_DICTIONARY_VALUE('report_type', 'MARKET', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExAnteMktSchSummary_EA');
  PUT_DICTIONARY_VALUE('request_type', 'REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExAnteMktSchSummary_EA');
  PUT_DICTIONARY_VALUE('version_no', '1.0', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExAnteMktSchSummary_EA');
   
  --------------  PUB_D_ExAnteMktSchSummary_EA2  --------------
  PUT_DICTIONARY_VALUE('access_class', 'PUB', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExAnteMktSchSummary_EA2');
  PUT_DICTIONARY_VALUE('action', 'DOWNLOAD', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExAnteMktSchSummary_EA2');
  PUT_DICTIONARY_VALUE('application_type', 'MARKET_REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExAnteMktSchSummary_EA2');
  PUT_DICTIONARY_VALUE('file_name', 'PUB_D_ExAnteMktSchSummary_EA2.xml', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExAnteMktSchSummary_EA2');
  PUT_DICTIONARY_VALUE('file_type', 'XML', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExAnteMktSchSummary_EA2');
  PUT_DICTIONARY_VALUE('import_param', 'Ex-Ante', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExAnteMktSchSummary_EA2');
  PUT_DICTIONARY_VALUE('import_procedure', 'IMPORT_MKT_SCHED_SUMMARY', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExAnteMktSchSummary_EA2');
  PUT_DICTIONARY_VALUE('mode', 'NORMAL', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExAnteMktSchSummary_EA2');
  PUT_DICTIONARY_VALUE('multiple_messages', 'false', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExAnteMktSchSummary_EA2');
  PUT_DICTIONARY_VALUE('periodicity', 'DAILY', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExAnteMktSchSummary_EA2');
  PUT_DICTIONARY_VALUE('report_name', 'PUB_D_ExAnteMktSchSummary', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExAnteMktSchSummary_EA2');
  PUT_DICTIONARY_VALUE('report_sub_type', 'DAY_AHEAD', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExAnteMktSchSummary_EA2');
  PUT_DICTIONARY_VALUE('report_type', 'MARKET', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExAnteMktSchSummary_EA2');
  PUT_DICTIONARY_VALUE('request_type', 'REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExAnteMktSchSummary_EA2');
  PUT_DICTIONARY_VALUE('version_no', '1.0', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExAnteMktSchSummary_EA2');
   
  --------------  PUB_D_ExAnteMktSchSummary_WD1  --------------
  PUT_DICTIONARY_VALUE('access_class', 'PUB', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExAnteMktSchSummary_WD1');
  PUT_DICTIONARY_VALUE('action', 'DOWNLOAD', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExAnteMktSchSummary_WD1');
  PUT_DICTIONARY_VALUE('application_type', 'MARKET_REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExAnteMktSchSummary_WD1');
  PUT_DICTIONARY_VALUE('file_name', 'PUB_D_ExAnteMktSchSummary_WD1.xml', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExAnteMktSchSummary_WD1');
  PUT_DICTIONARY_VALUE('file_type', 'XML', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExAnteMktSchSummary_WD1');
  PUT_DICTIONARY_VALUE('import_param', 'Ex-Ante', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExAnteMktSchSummary_WD1');
  PUT_DICTIONARY_VALUE('import_procedure', 'IMPORT_MKT_SCHED_SUMMARY', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExAnteMktSchSummary_WD1');
  PUT_DICTIONARY_VALUE('mode', 'NORMAL', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExAnteMktSchSummary_WD1');
  PUT_DICTIONARY_VALUE('multiple_messages', 'false', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExAnteMktSchSummary_WD1');
  PUT_DICTIONARY_VALUE('periodicity', 'DAILY', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExAnteMktSchSummary_WD1');
  PUT_DICTIONARY_VALUE('report_name', 'PUB_D_ExAnteMktSchSummary', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExAnteMktSchSummary_WD1');
  PUT_DICTIONARY_VALUE('report_sub_type', 'DAY_AHEAD', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExAnteMktSchSummary_WD1');
  PUT_DICTIONARY_VALUE('report_type', 'MARKET', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExAnteMktSchSummary_WD1');
  PUT_DICTIONARY_VALUE('request_type', 'REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExAnteMktSchSummary_WD1');
  PUT_DICTIONARY_VALUE('version_no', '1.0', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExAnteMktSchSummary_WD1');
   
  --------------  PUB_D_TODDemandSideUnits_EA  --------------
  PUT_DICTIONARY_VALUE('access_class', 'PUB', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TODDemandSideUnits_EA');
  PUT_DICTIONARY_VALUE('action', 'DOWNLOAD', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TODDemandSideUnits_EA');
  PUT_DICTIONARY_VALUE('application_type', 'MARKET_REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TODDemandSideUnits_EA');
  PUT_DICTIONARY_VALUE('file_name', 'PUB_D_TODDemandSideUnits_EA.xml', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TODDemandSideUnits_EA');
  PUT_DICTIONARY_VALUE('file_type', 'XML', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TODDemandSideUnits_EA');
  PUT_DICTIONARY_VALUE('import_param', '', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TODDemandSideUnits_EA');
  PUT_DICTIONARY_VALUE('import_procedure', 'IMPORT_TECH_OFFER_STD_UNITS', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TODDemandSideUnits_EA');
  PUT_DICTIONARY_VALUE('mode', 'NORMAL', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TODDemandSideUnits_EA');
  PUT_DICTIONARY_VALUE('multiple_messages', 'false', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TODDemandSideUnits_EA');
  PUT_DICTIONARY_VALUE('periodicity', 'DAILY', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TODDemandSideUnits_EA');
  PUT_DICTIONARY_VALUE('report_name', 'PUB_D_TODDemandSideUnits', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TODDemandSideUnits_EA');
  PUT_DICTIONARY_VALUE('report_sub_type', 'DAY_AHEAD', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TODDemandSideUnits_EA');
  PUT_DICTIONARY_VALUE('report_type', 'MARKET', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TODDemandSideUnits_EA');
  PUT_DICTIONARY_VALUE('request_type', 'REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TODDemandSideUnits_EA');
  PUT_DICTIONARY_VALUE('version_no', '1.0', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TODDemandSideUnits_EA');
   
  --------------  PUB_D_TODDemandSideUnits_EA2  --------------
  PUT_DICTIONARY_VALUE('access_class', 'PUB', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TODDemandSideUnits_EA2');
  PUT_DICTIONARY_VALUE('action', 'DOWNLOAD', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TODDemandSideUnits_EA2');
  PUT_DICTIONARY_VALUE('application_type', 'MARKET_REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TODDemandSideUnits_EA2');
  PUT_DICTIONARY_VALUE('file_name', 'PUB_D_TODDemandSideUnits_EA2.xml', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TODDemandSideUnits_EA2');
  PUT_DICTIONARY_VALUE('file_type', 'XML', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TODDemandSideUnits_EA2');
  PUT_DICTIONARY_VALUE('import_param', '', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TODDemandSideUnits_EA2');
  PUT_DICTIONARY_VALUE('import_procedure', 'IMPORT_TECH_OFFER_STD_UNITS', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TODDemandSideUnits_EA2');
  PUT_DICTIONARY_VALUE('mode', 'NORMAL', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TODDemandSideUnits_EA2');
  PUT_DICTIONARY_VALUE('multiple_messages', 'false', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TODDemandSideUnits_EA2');
  PUT_DICTIONARY_VALUE('periodicity', 'DAILY', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TODDemandSideUnits_EA2');
  PUT_DICTIONARY_VALUE('report_name', 'PUB_D_TODDemandSideUnits', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TODDemandSideUnits_EA2');
  PUT_DICTIONARY_VALUE('report_sub_type', 'DAY_AHEAD', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TODDemandSideUnits_EA2');
  PUT_DICTIONARY_VALUE('report_type', 'MARKET', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TODDemandSideUnits_EA2');
  PUT_DICTIONARY_VALUE('request_type', 'REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TODDemandSideUnits_EA2');
  PUT_DICTIONARY_VALUE('version_no', '1.0', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TODDemandSideUnits_EA2');
   
  --------------  PUB_D_TODDemandSideUnits_WD1  --------------
  PUT_DICTIONARY_VALUE('access_class', 'PUB', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TODDemandSideUnits_WD1');
  PUT_DICTIONARY_VALUE('action', 'DOWNLOAD', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TODDemandSideUnits_WD1');
  PUT_DICTIONARY_VALUE('application_type', 'MARKET_REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TODDemandSideUnits_WD1');
  PUT_DICTIONARY_VALUE('file_name', 'PUB_D_TODDemandSideUnits_WD1.xml', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TODDemandSideUnits_WD1');
  PUT_DICTIONARY_VALUE('file_type', 'XML', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TODDemandSideUnits_WD1');
  PUT_DICTIONARY_VALUE('import_param', '', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TODDemandSideUnits_WD1');
  PUT_DICTIONARY_VALUE('import_procedure', 'IMPORT_TECH_OFFER_STD_UNITS', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TODDemandSideUnits_WD1');
  PUT_DICTIONARY_VALUE('mode', 'NORMAL', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TODDemandSideUnits_WD1');
  PUT_DICTIONARY_VALUE('multiple_messages', 'false', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TODDemandSideUnits_WD1');
  PUT_DICTIONARY_VALUE('periodicity', 'DAILY', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TODDemandSideUnits_WD1');
  PUT_DICTIONARY_VALUE('report_name', 'PUB_D_TODDemandSideUnits', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TODDemandSideUnits_WD1');
  PUT_DICTIONARY_VALUE('report_sub_type', 'DAY_AHEAD', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TODDemandSideUnits_WD1');
  PUT_DICTIONARY_VALUE('report_type', 'MARKET', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TODDemandSideUnits_WD1');
  PUT_DICTIONARY_VALUE('request_type', 'REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TODDemandSideUnits_WD1');
  PUT_DICTIONARY_VALUE('version_no', '1.0', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TODDemandSideUnits_WD1');
   
  --------------  PUB_D_TODForecastData_EA  --------------
  PUT_DICTIONARY_VALUE('access_class', 'PUB', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TODForecastData_EA');
  PUT_DICTIONARY_VALUE('action', 'DOWNLOAD', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TODForecastData_EA');
  PUT_DICTIONARY_VALUE('application_type', 'MARKET_REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TODForecastData_EA');
  PUT_DICTIONARY_VALUE('file_name', 'PUB_D_TODForecastData_EA.xml', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TODForecastData_EA');
  PUT_DICTIONARY_VALUE('file_type', 'XML', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TODForecastData_EA');
  PUT_DICTIONARY_VALUE('import_param', '', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TODForecastData_EA');
  PUT_DICTIONARY_VALUE('import_procedure', 'IMPORT_TECH_OFFER_FORECAST', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TODForecastData_EA');
  PUT_DICTIONARY_VALUE('mode', 'NORMAL', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TODForecastData_EA');
  PUT_DICTIONARY_VALUE('multiple_messages', 'false', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TODForecastData_EA');
  PUT_DICTIONARY_VALUE('periodicity', 'DAILY', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TODForecastData_EA');
  PUT_DICTIONARY_VALUE('report_name', 'PUB_D_TODForecastData', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TODForecastData_EA');
  PUT_DICTIONARY_VALUE('report_sub_type', 'DAY_AHEAD', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TODForecastData_EA');
  PUT_DICTIONARY_VALUE('report_type', 'MARKET', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TODForecastData_EA');
  PUT_DICTIONARY_VALUE('request_type', 'REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TODForecastData_EA');
  PUT_DICTIONARY_VALUE('version_no', '1.0', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TODForecastData_EA');
   
  --------------  PUB_D_TODForecastData_EA2  --------------
  PUT_DICTIONARY_VALUE('access_class', 'PUB', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TODForecastData_EA2');
  PUT_DICTIONARY_VALUE('action', 'DOWNLOAD', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TODForecastData_EA2');
  PUT_DICTIONARY_VALUE('application_type', 'MARKET_REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TODForecastData_EA2');
  PUT_DICTIONARY_VALUE('file_name', 'PUB_D_TODForecastData_EA2.xml', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TODForecastData_EA2');
  PUT_DICTIONARY_VALUE('file_type', 'XML', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TODForecastData_EA2');
  PUT_DICTIONARY_VALUE('import_param', '', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TODForecastData_EA2');
  PUT_DICTIONARY_VALUE('import_procedure', 'IMPORT_TECH_OFFER_FORECAST', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TODForecastData_EA2');
  PUT_DICTIONARY_VALUE('mode', 'NORMAL', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TODForecastData_EA2');
  PUT_DICTIONARY_VALUE('multiple_messages', 'false', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TODForecastData_EA2');
  PUT_DICTIONARY_VALUE('periodicity', 'DAILY', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TODForecastData_EA2');
  PUT_DICTIONARY_VALUE('report_name', 'PUB_D_TODForecastData', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TODForecastData_EA2');
  PUT_DICTIONARY_VALUE('report_sub_type', 'DAY_AHEAD', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TODForecastData_EA2');
  PUT_DICTIONARY_VALUE('report_type', 'MARKET', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TODForecastData_EA2');
  PUT_DICTIONARY_VALUE('request_type', 'REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TODForecastData_EA2');
  PUT_DICTIONARY_VALUE('version_no', '1.0', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TODForecastData_EA2');
   
  --------------  PUB_D_TODForecastData_WD1  --------------
  PUT_DICTIONARY_VALUE('access_class', 'PUB', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TODForecastData_WD1');
  PUT_DICTIONARY_VALUE('action', 'DOWNLOAD', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TODForecastData_WD1');
  PUT_DICTIONARY_VALUE('application_type', 'MARKET_REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TODForecastData_WD1');
  PUT_DICTIONARY_VALUE('file_name', 'PUB_D_TODForecastData_WD1.xml', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TODForecastData_WD1');
  PUT_DICTIONARY_VALUE('file_type', 'XML', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TODForecastData_WD1');
  PUT_DICTIONARY_VALUE('import_param', '', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TODForecastData_WD1');
  PUT_DICTIONARY_VALUE('import_procedure', 'IMPORT_TECH_OFFER_FORECAST', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TODForecastData_WD1');
  PUT_DICTIONARY_VALUE('mode', 'NORMAL', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TODForecastData_WD1');
  PUT_DICTIONARY_VALUE('multiple_messages', 'false', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TODForecastData_WD1');
  PUT_DICTIONARY_VALUE('periodicity', 'DAILY', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TODForecastData_WD1');
  PUT_DICTIONARY_VALUE('report_name', 'PUB_D_TODForecastData', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TODForecastData_WD1');
  PUT_DICTIONARY_VALUE('report_sub_type', 'DAY_AHEAD', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TODForecastData_WD1');
  PUT_DICTIONARY_VALUE('report_type', 'MARKET', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TODForecastData_WD1');
  PUT_DICTIONARY_VALUE('request_type', 'REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TODForecastData_WD1');
  PUT_DICTIONARY_VALUE('version_no', '1.0', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TODForecastData_WD1');
   
  --------------  PUB_D_TODStandardUnits_EA  --------------
  PUT_DICTIONARY_VALUE('access_class', 'PUB', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TODStandardUnits_EA');
  PUT_DICTIONARY_VALUE('action', 'DOWNLOAD', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TODStandardUnits_EA');
  PUT_DICTIONARY_VALUE('application_type', 'MARKET_REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TODStandardUnits_EA');
  PUT_DICTIONARY_VALUE('file_name', 'PUB_D_TODStandardUnits_EA.xml', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TODStandardUnits_EA');
  PUT_DICTIONARY_VALUE('file_type', 'XML', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TODStandardUnits_EA');
  PUT_DICTIONARY_VALUE('import_param', '', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TODStandardUnits_EA');
  PUT_DICTIONARY_VALUE('import_procedure', 'IMPORT_TECH_OFFER_STD_UNITS', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TODStandardUnits_EA');
  PUT_DICTIONARY_VALUE('mode', 'NORMAL', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TODStandardUnits_EA');
  PUT_DICTIONARY_VALUE('multiple_messages', 'false', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TODStandardUnits_EA');
  PUT_DICTIONARY_VALUE('periodicity', 'DAILY', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TODStandardUnits_EA');
  PUT_DICTIONARY_VALUE('report_name', 'PUB_D_TODStandardUnits', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TODStandardUnits_EA');
  PUT_DICTIONARY_VALUE('report_sub_type', 'DAY_AHEAD', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TODStandardUnits_EA');
  PUT_DICTIONARY_VALUE('report_type', 'MARKET', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TODStandardUnits_EA');
  PUT_DICTIONARY_VALUE('request_type', 'REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TODStandardUnits_EA');
  PUT_DICTIONARY_VALUE('version_no', '1.0', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TODStandardUnits_EA');
   
  --------------  PUB_D_TODStandardUnits_EA2  --------------
  PUT_DICTIONARY_VALUE('access_class', 'PUB', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TODStandardUnits_EA2');
  PUT_DICTIONARY_VALUE('action', 'DOWNLOAD', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TODStandardUnits_EA2');
  PUT_DICTIONARY_VALUE('application_type', 'MARKET_REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TODStandardUnits_EA2');
  PUT_DICTIONARY_VALUE('file_name', 'PUB_D_TODStandardUnits_EA2.xml', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TODStandardUnits_EA2');
  PUT_DICTIONARY_VALUE('file_type', 'XML', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TODStandardUnits_EA2');
  PUT_DICTIONARY_VALUE('import_param', '', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TODStandardUnits_EA2');
  PUT_DICTIONARY_VALUE('import_procedure', 'IMPORT_TECH_OFFER_STD_UNITS', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TODStandardUnits_EA2');
  PUT_DICTIONARY_VALUE('mode', 'NORMAL', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TODStandardUnits_EA2');
  PUT_DICTIONARY_VALUE('multiple_messages', 'false', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TODStandardUnits_EA2');
  PUT_DICTIONARY_VALUE('periodicity', 'DAILY', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TODStandardUnits_EA2');
  PUT_DICTIONARY_VALUE('report_name', 'PUB_D_TODStandardUnits', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TODStandardUnits_EA2');
  PUT_DICTIONARY_VALUE('report_sub_type', 'DAY_AHEAD', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TODStandardUnits_EA2');
  PUT_DICTIONARY_VALUE('report_type', 'MARKET', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TODStandardUnits_EA2');
  PUT_DICTIONARY_VALUE('request_type', 'REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TODStandardUnits_EA2');
  PUT_DICTIONARY_VALUE('version_no', '1.0', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TODStandardUnits_EA2');
   
  --------------  PUB_D_TODStandardUnits_WD1  --------------
  PUT_DICTIONARY_VALUE('access_class', 'PUB', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TODStandardUnits_WD1');
  PUT_DICTIONARY_VALUE('action', 'DOWNLOAD', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TODStandardUnits_WD1');
  PUT_DICTIONARY_VALUE('application_type', 'MARKET_REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TODStandardUnits_WD1');
  PUT_DICTIONARY_VALUE('file_name', 'PUB_D_TODStandardUnits_WD1.xml', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TODStandardUnits_WD1');
  PUT_DICTIONARY_VALUE('file_type', 'XML', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TODStandardUnits_WD1');
  PUT_DICTIONARY_VALUE('import_param', '', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TODStandardUnits_WD1');
  PUT_DICTIONARY_VALUE('import_procedure', 'IMPORT_TECH_OFFER_STD_UNITS', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TODStandardUnits_WD1');
  PUT_DICTIONARY_VALUE('mode', 'NORMAL', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TODStandardUnits_WD1');
  PUT_DICTIONARY_VALUE('multiple_messages', 'false', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TODStandardUnits_WD1');
  PUT_DICTIONARY_VALUE('periodicity', 'DAILY', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TODStandardUnits_WD1');
  PUT_DICTIONARY_VALUE('report_name', 'PUB_D_TODStandardUnits', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TODStandardUnits_WD1');
  PUT_DICTIONARY_VALUE('report_sub_type', 'DAY_AHEAD', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TODStandardUnits_WD1');
  PUT_DICTIONARY_VALUE('report_type', 'MARKET', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TODStandardUnits_WD1');
  PUT_DICTIONARY_VALUE('request_type', 'REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TODStandardUnits_WD1');
  PUT_DICTIONARY_VALUE('version_no', '1.0', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TODStandardUnits_WD1');
    
  -- EA, EA2, WD1 settings for new IDT reports
  
  --------------  PUB_D_ExAnteMktResults_EA  --------------
  PUT_DICTIONARY_VALUE('access_class', 'PUB', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExAnteMktResults_EA');
  PUT_DICTIONARY_VALUE('action', 'DOWNLOAD', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExAnteMktResults_EA');
  PUT_DICTIONARY_VALUE('application_type', 'MARKET_REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExAnteMktResults_EA');
  PUT_DICTIONARY_VALUE('file_name', 'PUB_D_ExAnteMktResults_EA.xml', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExAnteMktResults_EA');
  PUT_DICTIONARY_VALUE('file_type', 'XML', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExAnteMktResults_EA');
  PUT_DICTIONARY_VALUE('import_param', '', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExAnteMktResults_EA');
  PUT_DICTIONARY_VALUE('import_procedure', 'IMPORT_MARKET_RESULTS', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExAnteMktResults_EA');
  PUT_DICTIONARY_VALUE('mode', 'NORMAL', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExAnteMktResults_EA');
  PUT_DICTIONARY_VALUE('multiple_messages', 'false', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExAnteMktResults_EA');
  PUT_DICTIONARY_VALUE('periodicity', 'DAILY', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExAnteMktResults_EA');
  PUT_DICTIONARY_VALUE('report_name', 'PUB_D_ExAnteMktResults', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExAnteMktResults_EA');
  PUT_DICTIONARY_VALUE('report_sub_type', 'DAY_AHEAD', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExAnteMktResults_EA');
  PUT_DICTIONARY_VALUE('report_type', 'MARKET', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExAnteMktResults_EA');
  PUT_DICTIONARY_VALUE('request_type', 'REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExAnteMktResults_EA');
  PUT_DICTIONARY_VALUE('version_no', '1.0', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExAnteMktResults_EA');
   
  --------------  PUB_D_ExAnteMktResults_EA2  --------------
  PUT_DICTIONARY_VALUE('access_class', 'PUB', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExAnteMktResults_EA2');
  PUT_DICTIONARY_VALUE('action', 'DOWNLOAD', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExAnteMktResults_EA2');
  PUT_DICTIONARY_VALUE('application_type', 'MARKET_REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExAnteMktResults_EA2');
  PUT_DICTIONARY_VALUE('file_name', 'PUB_D_ExAnteMktResults_EA2.xml', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExAnteMktResults_EA2');
  PUT_DICTIONARY_VALUE('file_type', 'XML', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExAnteMktResults_EA2');
  PUT_DICTIONARY_VALUE('import_param', '', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExAnteMktResults_EA2');
  PUT_DICTIONARY_VALUE('import_procedure', 'IMPORT_MARKET_RESULTS', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExAnteMktResults_EA2');
  PUT_DICTIONARY_VALUE('mode', 'NORMAL', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExAnteMktResults_EA2');
  PUT_DICTIONARY_VALUE('multiple_messages', 'false', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExAnteMktResults_EA2');
  PUT_DICTIONARY_VALUE('periodicity', 'DAILY', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExAnteMktResults_EA2');
  PUT_DICTIONARY_VALUE('report_name', 'PUB_D_ExAnteMktResults', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExAnteMktResults_EA2');
  PUT_DICTIONARY_VALUE('report_sub_type', 'DAY_AHEAD', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExAnteMktResults_EA2');
  PUT_DICTIONARY_VALUE('report_type', 'MARKET', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExAnteMktResults_EA2');
  PUT_DICTIONARY_VALUE('request_type', 'REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExAnteMktResults_EA2');
  PUT_DICTIONARY_VALUE('version_no', '1.0', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExAnteMktResults_EA2');
   
  --------------  PUB_D_ExAnteMktResults_WD1  --------------
  PUT_DICTIONARY_VALUE('access_class', 'PUB', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExAnteMktResults_WD1');
  PUT_DICTIONARY_VALUE('action', 'DOWNLOAD', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExAnteMktResults_WD1');
  PUT_DICTIONARY_VALUE('application_type', 'MARKET_REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExAnteMktResults_WD1');
  PUT_DICTIONARY_VALUE('file_name', 'PUB_D_ExAnteMktResults_WD1.xml', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExAnteMktResults_WD1');
  PUT_DICTIONARY_VALUE('file_type', 'XML', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExAnteMktResults_WD1');
  PUT_DICTIONARY_VALUE('import_param', '', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExAnteMktResults_WD1');
  PUT_DICTIONARY_VALUE('import_procedure', 'IMPORT_MARKET_RESULTS', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExAnteMktResults_WD1');
  PUT_DICTIONARY_VALUE('mode', 'NORMAL', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExAnteMktResults_WD1');
  PUT_DICTIONARY_VALUE('multiple_messages', 'false', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExAnteMktResults_WD1');
  PUT_DICTIONARY_VALUE('periodicity', 'DAILY', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExAnteMktResults_WD1');
  PUT_DICTIONARY_VALUE('report_name', 'PUB_D_ExAnteMktResults', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExAnteMktResults_WD1');
  PUT_DICTIONARY_VALUE('report_sub_type', 'DAY_AHEAD', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExAnteMktResults_WD1');
  PUT_DICTIONARY_VALUE('report_type', 'MARKET', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExAnteMktResults_WD1');
  PUT_DICTIONARY_VALUE('request_type', 'REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExAnteMktResults_WD1');
  PUT_DICTIONARY_VALUE('version_no', '1.0', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExAnteMktResults_WD1');


	
  --------------  MP_D_AvailCreditCover_EA  --------------
  PUT_DICTIONARY_VALUE('access_class', 'MP', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_AvailCreditCover_EA');
  PUT_DICTIONARY_VALUE('action', 'DOWNLOAD', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_AvailCreditCover_EA');
  PUT_DICTIONARY_VALUE('application_type', 'MARKET_REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_AvailCreditCover_EA');
  PUT_DICTIONARY_VALUE('file_name', 'MP_D_AvailCreditCover_EA.xml', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_AvailCreditCover_EA');
  PUT_DICTIONARY_VALUE('file_type', 'XML', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_AvailCreditCover_EA');
  PUT_DICTIONARY_VALUE('import_param', '', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_AvailCreditCover_EA');
  PUT_DICTIONARY_VALUE('import_procedure', 'IMPORT_AVAILABLE_CREDIT_COVER', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_AvailCreditCover_EA');
  PUT_DICTIONARY_VALUE('mode', 'NORMAL', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_AvailCreditCover_EA');
  PUT_DICTIONARY_VALUE('multiple_messages', 'false', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_AvailCreditCover_EA');
  PUT_DICTIONARY_VALUE('periodicity', 'DAILY', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_AvailCreditCover_EA');
  PUT_DICTIONARY_VALUE('report_name', 'MP_D_AvailCreditCover', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_AvailCreditCover_EA');
  PUT_DICTIONARY_VALUE('report_sub_type', 'DAY_AHEAD', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_AvailCreditCover_EA');
  PUT_DICTIONARY_VALUE('report_type', 'MARKET', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_AvailCreditCover_EA');
  PUT_DICTIONARY_VALUE('request_type', 'REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_AvailCreditCover_EA');
  PUT_DICTIONARY_VALUE('version_no', '1.0', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_AvailCreditCover_EA');
   
  --------------  MP_D_AvailCreditCover_EA2  --------------
  PUT_DICTIONARY_VALUE('access_class', 'MP', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_AvailCreditCover_EA2');
  PUT_DICTIONARY_VALUE('action', 'DOWNLOAD', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_AvailCreditCover_EA2');
  PUT_DICTIONARY_VALUE('application_type', 'MARKET_REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_AvailCreditCover_EA2');
  PUT_DICTIONARY_VALUE('file_name', 'MP_D_AvailCreditCover_EA2.xml', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_AvailCreditCover_EA2');
  PUT_DICTIONARY_VALUE('file_type', 'XML', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_AvailCreditCover_EA2');
  PUT_DICTIONARY_VALUE('import_param', '', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_AvailCreditCover_EA2');
  PUT_DICTIONARY_VALUE('import_procedure', 'IMPORT_AVAILABLE_CREDIT_COVER', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_AvailCreditCover_EA2');
  PUT_DICTIONARY_VALUE('mode', 'NORMAL', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_AvailCreditCover_EA2');
  PUT_DICTIONARY_VALUE('multiple_messages', 'false', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_AvailCreditCover_EA2');
  PUT_DICTIONARY_VALUE('periodicity', 'DAILY', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_AvailCreditCover_EA2');
  PUT_DICTIONARY_VALUE('report_name', 'MP_D_AvailCreditCover', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_AvailCreditCover_EA2');
  PUT_DICTIONARY_VALUE('report_sub_type', 'DAY_AHEAD', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_AvailCreditCover_EA2');
  PUT_DICTIONARY_VALUE('report_type', 'MARKET', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_AvailCreditCover_EA2');
  PUT_DICTIONARY_VALUE('request_type', 'REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_AvailCreditCover_EA2');
  PUT_DICTIONARY_VALUE('version_no', '1.0', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_AvailCreditCover_EA2');
   
  --------------  MP_D_AvailCreditCover_WD1  --------------
  PUT_DICTIONARY_VALUE('access_class', 'MP', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_AvailCreditCover_WD1');
  PUT_DICTIONARY_VALUE('action', 'DOWNLOAD', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_AvailCreditCover_WD1');
  PUT_DICTIONARY_VALUE('application_type', 'MARKET_REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_AvailCreditCover_WD1');
  PUT_DICTIONARY_VALUE('file_name', 'MP_D_AvailCreditCover_WD1.xml', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_AvailCreditCover_WD1');
  PUT_DICTIONARY_VALUE('file_type', 'XML', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_AvailCreditCover_WD1');
  PUT_DICTIONARY_VALUE('import_param', '', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_AvailCreditCover_WD1');
  PUT_DICTIONARY_VALUE('import_procedure', 'IMPORT_AVAILABLE_CREDIT_COVER', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_AvailCreditCover_WD1');
  PUT_DICTIONARY_VALUE('mode', 'NORMAL', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_AvailCreditCover_WD1');
  PUT_DICTIONARY_VALUE('multiple_messages', 'false', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_AvailCreditCover_WD1');
  PUT_DICTIONARY_VALUE('periodicity', 'DAILY', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_AvailCreditCover_WD1');
  PUT_DICTIONARY_VALUE('report_name', 'MP_D_AvailCreditCover', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_AvailCreditCover_WD1');
  PUT_DICTIONARY_VALUE('report_sub_type', 'DAY_AHEAD', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_AvailCreditCover_WD1');
  PUT_DICTIONARY_VALUE('report_type', 'MARKET', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_AvailCreditCover_WD1');
  PUT_DICTIONARY_VALUE('request_type', 'REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_AvailCreditCover_WD1');
  PUT_DICTIONARY_VALUE('version_no', '1.0', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_AvailCreditCover_WD1');
  
   --------------  MP_D_AvailCreditCover_EP1  --------------
  PUT_DICTIONARY_VALUE('access_class', 'MP', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_AvailCreditCover_EP1');
  PUT_DICTIONARY_VALUE('action', 'DOWNLOAD', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_AvailCreditCover_EP1');
  PUT_DICTIONARY_VALUE('application_type', 'MARKET_REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_AvailCreditCover_EP1');
  PUT_DICTIONARY_VALUE('file_name', 'MP_D_AvailCreditCover_EP1.xml', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_AvailCreditCover_EP1');
  PUT_DICTIONARY_VALUE('file_type', 'XML', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_AvailCreditCover_EP1');
  PUT_DICTIONARY_VALUE('import_param', '', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_AvailCreditCover_EP1');
  PUT_DICTIONARY_VALUE('import_procedure', 'IMPORT_AVAILABLE_CREDIT_COVER', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_AvailCreditCover_EP1');
  PUT_DICTIONARY_VALUE('mode', 'NORMAL', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_AvailCreditCover_EP1');
  PUT_DICTIONARY_VALUE('multiple_messages', 'false', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_AvailCreditCover_EP1');
  PUT_DICTIONARY_VALUE('periodicity', 'DAILY', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_AvailCreditCover_EP1');
  PUT_DICTIONARY_VALUE('report_name', 'MP_D_AvailCreditCover', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_AvailCreditCover_EP1');
  PUT_DICTIONARY_VALUE('report_sub_type', 'DAY_AHEAD', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_AvailCreditCover_EP1');
  PUT_DICTIONARY_VALUE('report_type', 'MARKET', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_AvailCreditCover_EP1');
  PUT_DICTIONARY_VALUE('request_type', 'REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_AvailCreditCover_EP1');
  PUT_DICTIONARY_VALUE('version_no', '1.0', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_AvailCreditCover_EP1');
  
    --------------  MP_D_AvailCreditCover_EP2  --------------
  PUT_DICTIONARY_VALUE('access_class', 'MP', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_AvailCreditCover_EP2');
  PUT_DICTIONARY_VALUE('action', 'DOWNLOAD', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_AvailCreditCover_EP2');
  PUT_DICTIONARY_VALUE('application_type', 'MARKET_REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_AvailCreditCover_EP2');
  PUT_DICTIONARY_VALUE('file_name', 'MP_D_AvailCreditCover_EP2.xml', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_AvailCreditCover_EP2');
  PUT_DICTIONARY_VALUE('file_type', 'XML', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_AvailCreditCover_EP2');
  PUT_DICTIONARY_VALUE('import_param', '', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_AvailCreditCover_EP2');
  PUT_DICTIONARY_VALUE('import_procedure', 'IMPORT_AVAILABLE_CREDIT_COVER', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_AvailCreditCover_EP2');
  PUT_DICTIONARY_VALUE('mode', 'NORMAL', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_AvailCreditCover_EP2');
  PUT_DICTIONARY_VALUE('multiple_messages', 'false', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_AvailCreditCover_EP2');
  PUT_DICTIONARY_VALUE('periodicity', 'DAILY', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_AvailCreditCover_EP2');
  PUT_DICTIONARY_VALUE('report_name', 'MP_D_AvailCreditCover', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_AvailCreditCover_EP2');
  PUT_DICTIONARY_VALUE('report_sub_type', 'DAY_AHEAD', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_AvailCreditCover_EP2');
  PUT_DICTIONARY_VALUE('report_type', 'MARKET', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_AvailCreditCover_EP2');
  PUT_DICTIONARY_VALUE('request_type', 'REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_AvailCreditCover_EP2');
  PUT_DICTIONARY_VALUE('version_no', '1.0', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_AvailCreditCover_EP2');
    
  --------------  MP_D_ExcludedBids_EA  --------------
  PUT_DICTIONARY_VALUE('access_class', 'MP', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_ExcludedBids_EA');
  PUT_DICTIONARY_VALUE('action', 'DOWNLOAD', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_ExcludedBids_EA');
  PUT_DICTIONARY_VALUE('application_type', 'MARKET_REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_ExcludedBids_EA');
  PUT_DICTIONARY_VALUE('file_name', 'MP_D_ExcludedBids_EA.xml', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_ExcludedBids_EA');
  PUT_DICTIONARY_VALUE('file_type', 'XML', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_ExcludedBids_EA');
  PUT_DICTIONARY_VALUE('import_param', '', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_ExcludedBids_EA');
  PUT_DICTIONARY_VALUE('import_procedure', 'IMPORT_EXCLUDED_BIDS', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_ExcludedBids_EA');
  PUT_DICTIONARY_VALUE('mode', 'NORMAL', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_ExcludedBids_EA');
  PUT_DICTIONARY_VALUE('multiple_messages', 'false', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_ExcludedBids_EA');
  PUT_DICTIONARY_VALUE('periodicity', 'DAILY', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_ExcludedBids_EA');
  PUT_DICTIONARY_VALUE('report_name', 'MP_D_ExcludedBids', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_ExcludedBids_EA');
  PUT_DICTIONARY_VALUE('report_sub_type', 'DAY_AHEAD', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_ExcludedBids_EA');
  PUT_DICTIONARY_VALUE('report_type', 'MARKET', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_ExcludedBids_EA');
  PUT_DICTIONARY_VALUE('request_type', 'REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_ExcludedBids_EA');
  PUT_DICTIONARY_VALUE('version_no', '1.0', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_ExcludedBids_EA');
   
  --------------  MP_D_ExcludedBids_EA2  --------------
  PUT_DICTIONARY_VALUE('access_class', 'MP', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_ExcludedBids_EA2');
  PUT_DICTIONARY_VALUE('action', 'DOWNLOAD', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_ExcludedBids_EA2');
  PUT_DICTIONARY_VALUE('application_type', 'MARKET_REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_ExcludedBids_EA2');
  PUT_DICTIONARY_VALUE('file_name', 'MP_D_ExcludedBids_EA2.xml', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_ExcludedBids_EA2');
  PUT_DICTIONARY_VALUE('file_type', 'XML', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_ExcludedBids_EA2');
  PUT_DICTIONARY_VALUE('import_param', '', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_ExcludedBids_EA2');
  PUT_DICTIONARY_VALUE('import_procedure', 'IMPORT_EXCLUDED_BIDS', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_ExcludedBids_EA2');
  PUT_DICTIONARY_VALUE('mode', 'NORMAL', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_ExcludedBids_EA2');
  PUT_DICTIONARY_VALUE('multiple_messages', 'false', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_ExcludedBids_EA2');
  PUT_DICTIONARY_VALUE('periodicity', 'DAILY', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_ExcludedBids_EA2');
  PUT_DICTIONARY_VALUE('report_name', 'MP_D_ExcludedBids', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_ExcludedBids_EA2');
  PUT_DICTIONARY_VALUE('report_sub_type', 'DAY_AHEAD', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_ExcludedBids_EA2');
  PUT_DICTIONARY_VALUE('report_type', 'MARKET', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_ExcludedBids_EA2');
  PUT_DICTIONARY_VALUE('request_type', 'REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_ExcludedBids_EA2');
  PUT_DICTIONARY_VALUE('version_no', '1.0', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_ExcludedBids_EA2');
   
  --------------  MP_D_ExcludedBids_WD1  --------------
  PUT_DICTIONARY_VALUE('access_class', 'MP', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_ExcludedBids_WD1');
  PUT_DICTIONARY_VALUE('action', 'DOWNLOAD', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_ExcludedBids_WD1');
  PUT_DICTIONARY_VALUE('application_type', 'MARKET_REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_ExcludedBids_WD1');
  PUT_DICTIONARY_VALUE('file_name', 'MP_D_ExcludedBids_WD1.xml', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_ExcludedBids_WD1');
  PUT_DICTIONARY_VALUE('file_type', 'XML', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_ExcludedBids_WD1');
  PUT_DICTIONARY_VALUE('import_param', '', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_ExcludedBids_WD1');
  PUT_DICTIONARY_VALUE('import_procedure', 'IMPORT_EXCLUDED_BIDS', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_ExcludedBids_WD1');
  PUT_DICTIONARY_VALUE('mode', 'NORMAL', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_ExcludedBids_WD1');
  PUT_DICTIONARY_VALUE('multiple_messages', 'false', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_ExcludedBids_WD1');
  PUT_DICTIONARY_VALUE('periodicity', 'DAILY', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_ExcludedBids_WD1');
  PUT_DICTIONARY_VALUE('report_name', 'MP_D_ExcludedBids', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_ExcludedBids_WD1');
  PUT_DICTIONARY_VALUE('report_sub_type', 'DAY_AHEAD', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_ExcludedBids_WD1');
  PUT_DICTIONARY_VALUE('report_type', 'MARKET', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_ExcludedBids_WD1');
  PUT_DICTIONARY_VALUE('request_type', 'REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_ExcludedBids_WD1');
  PUT_DICTIONARY_VALUE('version_no', '1.0', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'MP_D_ExcludedBids_WD1');
    
  -- additional new reports  
  --------------  PUB_D_AggRollingWindFcst  --------------
  PUT_DICTIONARY_VALUE('access_class', 'PUB', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_AggRollingWindFcst');
  PUT_DICTIONARY_VALUE('action', 'DOWNLOAD', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_AggRollingWindFcst');
  PUT_DICTIONARY_VALUE('application_type', 'MARKET_REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_AggRollingWindFcst');
  PUT_DICTIONARY_VALUE('file_name', 'PUB_D_AggRollingWindFcst.xml', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_AggRollingWindFcst');
  PUT_DICTIONARY_VALUE('file_type', 'XML', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_AggRollingWindFcst');
  PUT_DICTIONARY_VALUE('import_param', '', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_AggRollingWindFcst');
  PUT_DICTIONARY_VALUE('import_procedure', 'IMPORT_WIND_GEN_AGG', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_AggRollingWindFcst');
  PUT_DICTIONARY_VALUE('mode', 'NORMAL', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_AggRollingWindFcst');
  PUT_DICTIONARY_VALUE('multiple_messages', 'false', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_AggRollingWindFcst');
  PUT_DICTIONARY_VALUE('periodicity', 'DAILY', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_AggRollingWindFcst');
  PUT_DICTIONARY_VALUE('report_name', 'PUB_D_AggRollingWindFcst', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_AggRollingWindFcst');
  PUT_DICTIONARY_VALUE('report_sub_type', 'FORECASTS', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_AggRollingWindFcst');
  PUT_DICTIONARY_VALUE('report_type', 'TRANS_SYSTEM', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_AggRollingWindFcst');
  PUT_DICTIONARY_VALUE('request_type', 'REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_AggRollingWindFcst');
  PUT_DICTIONARY_VALUE('version_no', '1.0', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_AggRollingWindFcst');
 
 --------------  PUB_D_ExPostIndMktResults  --------------
  PUT_DICTIONARY_VALUE('access_class', 'PUB', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExPostIndMktResults');
  PUT_DICTIONARY_VALUE('action', 'DOWNLOAD', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExPostIndMktResults');
  PUT_DICTIONARY_VALUE('application_type', 'MARKET_REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExPostIndMktResults');
  PUT_DICTIONARY_VALUE('file_name', 'PUB_D_ExPostIndMktResults.xml', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExPostIndMktResults');
  PUT_DICTIONARY_VALUE('file_type', 'XML', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExPostIndMktResults');
  PUT_DICTIONARY_VALUE('import_param', '', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExPostIndMktResults');
  PUT_DICTIONARY_VALUE('import_procedure', 'IMPORT_MARKET_RESULTS', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExPostIndMktResults');
  PUT_DICTIONARY_VALUE('mode', 'NORMAL', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExPostIndMktResults');
  PUT_DICTIONARY_VALUE('multiple_messages', 'false', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExPostIndMktResults');
  PUT_DICTIONARY_VALUE('periodicity', 'DAILY', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExPostIndMktResults');
  PUT_DICTIONARY_VALUE('report_name', 'PUB_D_ExPostIndMktResults', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExPostIndMktResults');
  PUT_DICTIONARY_VALUE('report_sub_type', 'DAY_AHEAD', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExPostIndMktResults');
  PUT_DICTIONARY_VALUE('report_type', 'MARKET', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExPostIndMktResults');
  PUT_DICTIONARY_VALUE('request_type', 'REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExPostIndMktResults');
  PUT_DICTIONARY_VALUE('version_no', '1.0', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExPostIndMktResults');
  
  --------------  PUB_D_ExPostInitMktResults  --------------
  PUT_DICTIONARY_VALUE('access_class', 'PUB', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExPostInitMktResults');
  PUT_DICTIONARY_VALUE('action', 'DOWNLOAD', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExPostInitMktResults');
  PUT_DICTIONARY_VALUE('application_type', 'MARKET_REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExPostInitMktResults');
  PUT_DICTIONARY_VALUE('file_name', 'PUB_D_ExPostInitMktResults.xml', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExPostInitMktResults');
  PUT_DICTIONARY_VALUE('file_type', 'XML', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExPostInitMktResults');
  PUT_DICTIONARY_VALUE('import_param', '', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExPostInitMktResults');
  PUT_DICTIONARY_VALUE('import_procedure', 'IMPORT_MARKET_RESULTS', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExPostInitMktResults');
  PUT_DICTIONARY_VALUE('mode', 'NORMAL', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExPostInitMktResults');
  PUT_DICTIONARY_VALUE('multiple_messages', 'false', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExPostInitMktResults');
  PUT_DICTIONARY_VALUE('periodicity', 'DAILY', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExPostInitMktResults');
  PUT_DICTIONARY_VALUE('report_name', 'PUB_D_ExPostInitMktResults', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExPostInitMktResults');
  PUT_DICTIONARY_VALUE('report_sub_type', 'DAY_AHEAD', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExPostInitMktResults');
  PUT_DICTIONARY_VALUE('report_type', 'MARKET', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExPostInitMktResults');
  PUT_DICTIONARY_VALUE('request_type', 'REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExPostInitMktResults');
  PUT_DICTIONARY_VALUE('version_no', '1.0', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_ExPostInitMktResults');
  
  --------------  PUB_D_KPI_GateInfo  --------------
  PUT_DICTIONARY_VALUE('access_class', 'PUB', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_KPI_GateInfo');
  PUT_DICTIONARY_VALUE('action', 'DOWNLOAD', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_KPI_GateInfo');
  PUT_DICTIONARY_VALUE('application_type', 'MARKET_REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_KPI_GateInfo');
  PUT_DICTIONARY_VALUE('file_name', 'PUB_D_KPI_GateInfo.xml', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_KPI_GateInfo');
  PUT_DICTIONARY_VALUE('file_type', 'XML', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_KPI_GateInfo');
  PUT_DICTIONARY_VALUE('import_param', '', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_KPI_GateInfo');
  PUT_DICTIONARY_VALUE('import_procedure', 'KPI_GATE_INFO', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_KPI_GateInfo');
  PUT_DICTIONARY_VALUE('mode', 'NORMAL', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_KPI_GateInfo');
  PUT_DICTIONARY_VALUE('multiple_messages', 'false', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_KPI_GateInfo');
  PUT_DICTIONARY_VALUE('periodicity', 'DAILY', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_KPI_GateInfo');
  PUT_DICTIONARY_VALUE('report_name', 'PUB_D_KPI_GateInfo', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_KPI_GateInfo');
  PUT_DICTIONARY_VALUE('report_sub_type', 'DAY_AHEAD', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_KPI_GateInfo');
  PUT_DICTIONARY_VALUE('report_type', 'MARKET', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_KPI_GateInfo');
  PUT_DICTIONARY_VALUE('request_type', 'REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_KPI_GateInfo');
  PUT_DICTIONARY_VALUE('version_no', '1.0', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_KPI_GateInfo');
  
  --------------  PUB_D_KPI_Schedules  --------------
  PUT_DICTIONARY_VALUE('access_class', 'PUB', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_KPI_Schedules');
  PUT_DICTIONARY_VALUE('action', 'DOWNLOAD', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_KPI_Schedules');
  PUT_DICTIONARY_VALUE('application_type', 'MARKET_REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_KPI_Schedules');
  PUT_DICTIONARY_VALUE('file_name', 'PUB_D_KPI_Schedules.xml', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_KPI_Schedules');
  PUT_DICTIONARY_VALUE('file_type', 'XML', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_KPI_Schedules');
  PUT_DICTIONARY_VALUE('import_param', '', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_KPI_Schedules');
  PUT_DICTIONARY_VALUE('import_procedure', 'IMPORT_KPI_SCHEDULES', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_KPI_Schedules');
  PUT_DICTIONARY_VALUE('mode', 'NORMAL', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_KPI_Schedules');
  PUT_DICTIONARY_VALUE('multiple_messages', 'false', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_KPI_Schedules');
  PUT_DICTIONARY_VALUE('periodicity', 'DAILY', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_KPI_Schedules');
  PUT_DICTIONARY_VALUE('report_name', 'PUB_D_KPI_Schedules', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_KPI_Schedules');
  PUT_DICTIONARY_VALUE('report_sub_type', 'DAY_AHEAD', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_KPI_Schedules');
  PUT_DICTIONARY_VALUE('report_type', 'MARKET', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_KPI_Schedules');
  PUT_DICTIONARY_VALUE('request_type', 'REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_KPI_Schedules');
  PUT_DICTIONARY_VALUE('version_no', '1.0', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_KPI_Schedules');
  
  --------------  PUB_D_TOD_UnitData  --------------
  PUT_DICTIONARY_VALUE('access_class', 'PUB', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TOD_UnitData');
  PUT_DICTIONARY_VALUE('action', 'DOWNLOAD', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TOD_UnitData');
  PUT_DICTIONARY_VALUE('application_type', 'MARKET_REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TOD_UnitData');
  PUT_DICTIONARY_VALUE('file_name', 'PUB_D_TOD_UnitData.xml', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TOD_UnitData');
  PUT_DICTIONARY_VALUE('file_type', 'XML', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TOD_UnitData');
  PUT_DICTIONARY_VALUE('import_param', '', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TOD_UnitData');
  PUT_DICTIONARY_VALUE('import_procedure', 'IMPORT_TECH_OFFER_UNIT_DATA', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TOD_UnitData');
  PUT_DICTIONARY_VALUE('mode', 'NORMAL', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TOD_UnitData');
  PUT_DICTIONARY_VALUE('multiple_messages', 'false', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TOD_UnitData');
  PUT_DICTIONARY_VALUE('periodicity', 'DAILY', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TOD_UnitData');
  PUT_DICTIONARY_VALUE('report_name', 'PUB_D_TOD_UnitData', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TOD_UnitData');
  PUT_DICTIONARY_VALUE('report_sub_type', 'DAY_AHEAD', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TOD_UnitData');
  PUT_DICTIONARY_VALUE('report_type', 'MARKET', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TOD_UnitData');
  PUT_DICTIONARY_VALUE('request_type', 'REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TOD_UnitData');
  PUT_DICTIONARY_VALUE('version_no', '1.0', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_TOD_UnitData');
  
  --------------  PUB_MSP_Cancel  --------------
  PUT_DICTIONARY_VALUE('access_class', 'PUB', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_MSP_Cancel');
  PUT_DICTIONARY_VALUE('action', 'DOWNLOAD', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_MSP_Cancel');
  PUT_DICTIONARY_VALUE('application_type', 'MARKET_REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_MSP_Cancel');
  PUT_DICTIONARY_VALUE('file_name', 'PUB_MSP_Cancel.xml', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_MSP_Cancel');
  PUT_DICTIONARY_VALUE('file_type', 'XML', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_MSP_Cancel');
  PUT_DICTIONARY_VALUE('import_param', '', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_MSP_Cancel');
  PUT_DICTIONARY_VALUE('import_procedure', 'IMPORT_MSP_CANCEL', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_MSP_Cancel');
  PUT_DICTIONARY_VALUE('mode', 'NORMAL', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_MSP_Cancel');
  PUT_DICTIONARY_VALUE('multiple_messages', 'false', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_MSP_Cancel');
  PUT_DICTIONARY_VALUE('periodicity', 'DAILY', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_MSP_Cancel');
  PUT_DICTIONARY_VALUE('report_name', 'PUB_MSP_Cancel', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_MSP_Cancel');
  PUT_DICTIONARY_VALUE('report_sub_type', 'DAY_AHEAD', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_MSP_Cancel');
  PUT_DICTIONARY_VALUE('report_type', 'MARKET', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_MSP_Cancel');
  PUT_DICTIONARY_VALUE('request_type', 'REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_MSP_Cancel');
  PUT_DICTIONARY_VALUE('version_no', '1.0', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_MSP_Cancel');

  --------------  PUB_D_IntconnNetActual  --------------
  PUT_DICTIONARY_VALUE('access_class', 'PUB', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_IntconnNetActual');
  PUT_DICTIONARY_VALUE('action', 'DOWNLOAD', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_IntconnNetActual');
  PUT_DICTIONARY_VALUE('application_type', 'MARKET_REPORT', 0, 'MarketExchange', 'SEM','SMO Reports','PUB_D_IntconnNetActual');
  PUT_DICTIONARY_VALUE('file_name', 'PUB_D_IntconnNetActual.xml', 0, 'MarketExchange', 'SEM','SMO Reports','PUB_D_IntconnNetActual');
  PUT_DICTIONARY_VALUE('file_type', 'XML', 0, 'MarketExchange', 'SEM','SMO Reports','PUB_D_IntconnNetActual');
  PUT_DICTIONARY_VALUE('import_param', '', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_IntconnNetActual');
  PUT_DICTIONARY_VALUE('import_procedure', 'IMPORT_IC_NET_ACTUAL', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_IntconnNetActual');
  PUT_DICTIONARY_VALUE('mode', 'NORMAL', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_IntconnNetActual');
  PUT_DICTIONARY_VALUE('multiple_messages', 'false', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_IntconnNetActual');
  PUT_DICTIONARY_VALUE('periodicity', 'DAILY', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_IntconnNetActual');
  PUT_DICTIONARY_VALUE('report_name', 'PUB_D_IntconnNetActual', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_IntconnNetActual');
  PUT_DICTIONARY_VALUE('report_sub_type', 'DAY_AHEAD', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_IntconnNetActual');
  PUT_DICTIONARY_VALUE('report_type', 'MARKET', 0, 'MarketExchange', 'SEM','SMO Reports','PUB_D_IntconnNetActual');
  PUT_DICTIONARY_VALUE('report_sub_type', 'DAY_AHEAD', 0, 'MarketExchange', 'SEM','SMO Reports','PUB_D_IntconnNetActual');
  PUT_DICTIONARY_VALUE('version_no', '1.0', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_IntconnNetActual');
  
    --------------  PUB_D_IntconnOfferCapacity_EA  --------------
  PUT_DICTIONARY_VALUE('access_class', 'PUB', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_IntconnOfferCapacity_EA');
  PUT_DICTIONARY_VALUE('action', 'DOWNLOAD', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_IntconnOfferCapacity_EA');
  PUT_DICTIONARY_VALUE('application_type', 'MARKET_REPORT', 0, 'MarketExchange', 'SEM','SMO Reports','PUB_D_IntconnOfferCapacity_EA');
  PUT_DICTIONARY_VALUE('file_name', 'PUB_D_IntconnOfferCapacity_EA.xml', 0, 'MarketExchange', 'SEM','SMO Reports','PUB_D_IntconnOfferCapacity_EA');
  PUT_DICTIONARY_VALUE('file_type', 'XML', 0, 'MarketExchange', 'SEM','SMO Reports','PUB_D_IntconnOfferCapacity_EA');
  PUT_DICTIONARY_VALUE('import_param', '', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_IntconnOfferCapacity_EA');
  PUT_DICTIONARY_VALUE('import_procedure', 'IMPORT_IC_OFFER_CAPACITY', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_IntconnOfferCapacity_EA');
  PUT_DICTIONARY_VALUE('mode', 'NORMAL', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_IntconnOfferCapacity_EA');
  PUT_DICTIONARY_VALUE('multiple_messages', 'false', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_IntconnOfferCapacity_EA');
  PUT_DICTIONARY_VALUE('periodicity', 'DAILY', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_IntconnOfferCapacity_EA');
  PUT_DICTIONARY_VALUE('report_name', 'PUB_D_IntconnOfferCapacity', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_IntconnOfferCapacity_EA');
  PUT_DICTIONARY_VALUE('report_sub_type', 'INTERCONNECTOR', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_IntconnOfferCapacity_EA');
  PUT_DICTIONARY_VALUE('report_type', 'TRANS_SYSTEM', 0, 'MarketExchange', 'SEM','SMO Reports','PUB_D_IntconnOfferCapacity_EA');
  PUT_DICTIONARY_VALUE('request_type', 'REPORT', 0, 'MarketExchange', 'SEM','SMO Reports','PUB_D_IntconnOfferCapacity_EA');
  PUT_DICTIONARY_VALUE('version_no', '1.0', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_IntconnOfferCapacity_EA');
  
    --------------  PUB_D_IntconnOfferCapacity_EA2  --------------
  PUT_DICTIONARY_VALUE('access_class', 'PUB', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_IntconnOfferCapacity_EA2');
  PUT_DICTIONARY_VALUE('action', 'DOWNLOAD', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_IntconnOfferCapacity_EA2');
  PUT_DICTIONARY_VALUE('application_type', 'MARKET_REPORT', 0, 'MarketExchange', 'SEM','SMO Reports','PUB_D_IntconnOfferCapacity_EA2');
  PUT_DICTIONARY_VALUE('file_name', 'PUB_D_IntconnOfferCapacity_EA2.xml', 0, 'MarketExchange', 'SEM','SMO Reports','PUB_D_IntconnOfferCapacity_EA2');
  PUT_DICTIONARY_VALUE('file_type', 'XML', 0, 'MarketExchange', 'SEM','SMO Reports','PUB_D_IntconnOfferCapacity_EA2');
  PUT_DICTIONARY_VALUE('import_param', '', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_IntconnOfferCapacity_EA2');
  PUT_DICTIONARY_VALUE('import_procedure', 'IMPORT_IC_OFFER_CAPACITY', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_IntconnOfferCapacity_EA2');
  PUT_DICTIONARY_VALUE('mode', 'NORMAL', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_IntconnOfferCapacity_EA2');
  PUT_DICTIONARY_VALUE('multiple_messages', 'false', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_IntconnOfferCapacity_EA2');
  PUT_DICTIONARY_VALUE('periodicity', 'DAILY', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_IntconnOfferCapacity_EA2');
  PUT_DICTIONARY_VALUE('report_name', 'PUB_D_IntconnOfferCapacity', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_IntconnOfferCapacity_EA2');
  PUT_DICTIONARY_VALUE('report_sub_type', 'INTERCONNECTOR', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_IntconnOfferCapacity_EA2');
  PUT_DICTIONARY_VALUE('report_type', 'TRANS_SYSTEM', 0, 'MarketExchange', 'SEM','SMO Reports','PUB_D_IntconnOfferCapacity_EA2');
  PUT_DICTIONARY_VALUE('request_type', 'REPORT', 0, 'MarketExchange', 'SEM','SMO Reports','PUB_D_IntconnOfferCapacity_EA2');
  PUT_DICTIONARY_VALUE('version_no', '1.0', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_D_IntconnOfferCapacity_EA2');

   --------------  PUB_A_TransLossAdjustmentFactors  --------------
  PUT_DICTIONARY_VALUE('access_class', 'PUB', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_A_TransLossAdjustmentFactors');
  PUT_DICTIONARY_VALUE('action', 'DOWNLOAD', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_A_TransLossAdjustmentFactors');
  PUT_DICTIONARY_VALUE('application_type', 'MARKET_REPORT', 0, 'MarketExchange', 'SEM','SMO Reports','PUB_A_TransLossAdjustmentFactors');
  PUT_DICTIONARY_VALUE('file_name', 'PUB_A_TransLossAdjustmentFactors_MM.csv.zip', 0, 'MarketExchange', 'SEM','SMO Reports','PUB_A_TransLossAdjustmentFactors');
  PUT_DICTIONARY_VALUE('file_type', 'CSV', 0, 'MarketExchange', 'SEM','SMO Reports','PUB_A_TransLossAdjustmentFactors');
  PUT_DICTIONARY_VALUE('import_param', '', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_A_TransLossAdjustmentFactors');
  PUT_DICTIONARY_VALUE('import_procedure', 'IMPORT_TLAF_REPORT_CLOB', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_A_TransLossAdjustmentFactors');
  PUT_DICTIONARY_VALUE('mode', 'NORMAL', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_A_TransLossAdjustmentFactors');
  PUT_DICTIONARY_VALUE('multiple_messages', 'false', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_A_TransLossAdjustmentFactors');
  PUT_DICTIONARY_VALUE('periodicity', 'YEARLY', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_A_TransLossAdjustmentFactors');
  PUT_DICTIONARY_VALUE('report_name', 'PUB_A_TransLossAdjustmentFactors', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_A_TransLossAdjustmentFactors');
  PUT_DICTIONARY_VALUE('report_sub_type', 'MISCELLANEOUS', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_A_TransLossAdjustmentFactors');
  PUT_DICTIONARY_VALUE('report_type', 'TRANS_SYSTEM', 0, 'MarketExchange', 'SEM','SMO Reports','PUB_A_TransLossAdjustmentFactors');
  PUT_DICTIONARY_VALUE('request_type', 'REPORT', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_A_TransLossAdjustmentFactors');
  PUT_DICTIONARY_VALUE('version_no', '1.0', 0, 'MarketExchange', 'SEM', 'SMO Reports', 'PUB_A_TransLossAdjustmentFactors');
END;

/
-- save changes to database
COMMIT;
