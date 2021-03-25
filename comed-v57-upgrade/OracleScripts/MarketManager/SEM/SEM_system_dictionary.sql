-- CVS Revision: $Revision: 1.17 $
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
-- Uncomment the following two lines if you wish to completely eliminate previous entries and start from scratch w/ delivered entries
-- DELETE FROM SYSTEM_DICTIONARY WHERE MODULE = 'MarketExchange' ;
	
-- PUT_DICTIONARY_VALUE('URL','http://app-server/mex/Switchboard/invoke',0,'MarketExchange');
    	
    -------------------------------------------------------------
    -----------------Test Mode-------------------------------
    --------------------------------------------------------------
    ---set the environment to be in test mode
    PUT_NEW_DICTIONARY_VALUE('Test Mode', '1', 0, 'MarketExchange', 'SEM');
    
    
    --------------------------------------------------------------
    -----------------Commercial Offers----------------------------
    --------------------------------------------------------------
    PUT_NEW_DICTIONARY_VALUE('AUTOMATED_APPROVAL_GEN_OFFER', '1', 0, 'MarketExchange', 'SEM','Commercial Offers');
    PUT_NEW_DICTIONARY_VALUE('AUTOMATED_APPROVAL_NOM_OFFER', '1', 0, 'MarketExchange', 'SEM','Commercial Offers');
    PUT_NEW_DICTIONARY_VALUE('AUTOMATED_APPROVAL_LOAD_OFFER', '1', 0, 'MarketExchange', 'SEM','Commercial Offers');
    
    
    
    --------------------------------------------------------------
    -----------------Offer Resource-------------------------------
    --------------------------------------------------------------
    PUT_NEW_DICTIONARY_VALUE('PPMG', 'PRED_PR_MAKER_GEN', 0, 'MarketExchange', 'SEM','Offer Resource');
    PUT_NEW_DICTIONARY_VALUE('PPTG', 'PRED_PR_TAKER_GEN', 0, 'MarketExchange', 'SEM','Offer Resource');
    PUT_NEW_DICTIONARY_VALUE('VPMG', 'VAR_PR_MAKER_GEN', 0, 'MarketExchange', 'SEM','Offer Resource');
    PUT_NEW_DICTIONARY_VALUE('VPTG', 'VAR_PR_TAKER_GEN', 0, 'MarketExchange', 'SEM','Offer Resource');
    PUT_NEW_DICTIONARY_VALUE('I', 'INTERCONNECTOR', 0, 'MarketExchange', 'SEM','Offer Resource');
    PUT_NEW_DICTIONARY_VALUE('SU', 'SUPPLY_UNIT', 0, 'MarketExchange', 'SEM','Offer Resource');
    PUT_NEW_DICTIONARY_VALUE('DU', 'PR_MAKER_DEMAND_UNIT', 0, 'MarketExchange', 'SEM','Offer Resource');
    PUT_NEW_DICTIONARY_VALUE('APTG', 'AUTO_PR_TAKER_GEN', 0, 'MarketExchange', 'SEM','Offer Resource');
    
    -------------------------------
    ---- Currency Mapping
    -------------------------------
    PUT_NEW_DICTIONARY_VALUE('EURO', 'EUR', 0, 'MarketExchange', 'SEM','Settlement','Currency Map');

    --------------------------
    -- Invoice Market Names --
    --------------------------
    PUT_NEW_DICTIONARY_VALUE('Energy Market', 'EN', 0, 'MarketExchange', 'SEM','Settlement','Invoice Markets');
    PUT_NEW_DICTIONARY_VALUE('Capacity Market', 'CA', 0, 'MarketExchange', 'SEM','Settlement','Invoice Markets');
    PUT_NEW_DICTIONARY_VALUE('Fixed Market Operator Charge', 'FMO', 0, 'MarketExchange', 'SEM','Settlement','Invoice Markets');
    PUT_NEW_DICTIONARY_VALUE('Variable Market Operator Charge', 'MO', 0, 'MarketExchange', 'SEM','Settlement','Invoice Markets');
    
    --------------------------
    -- Invoice Sign Convention --
    --------------------------
    PUT_DICTIONARY_VALUE('Enable Reverse Sign Invoices','TRUE',0,'System','GA Settings', 'Billing');

    --------------------------
    -- MPUD5 start date    
    --------------------------
	PUT_NEW_DICTIONARY_VALUE('MPUD5 Start','2007-12-14',0,'MarketExchange','SEM');
    
    -------------------------------------------------
    -- By default Ex-Ante SMP should populate "standard" SMP with F price type
    -------------------------------------------------
    PUT_NEW_DICTIONARY_VALUE('UseExAnteSMPForInternalSMP', '1', 0, 'MarketExchange', 'SEM');
    
    --------------------------
    -- By default PIR used for internal data    
    --------------------------
	PUT_NEW_DICTIONARY_VALUE('CPDP-Capacity Payments Demand Price','1',0,'MarketExchange','SEM', 'UsePIRForInternal');
	PUT_NEW_DICTIONARY_VALUE('CPGP-Capacity Payments Generation Price','1',0,'MarketExchange','SEM', 'UsePIRForInternal');
	PUT_NEW_DICTIONARY_VALUE('ECGP-Ex-Post Capacity Payments Generation Price','1',0,'MarketExchange','SEM', 'UsePIRForInternal');
	PUT_NEW_DICTIONARY_VALUE('FCGP-Fixed Capacity Payments Generation Price','1',0,'MarketExchange','SEM', 'UsePIRForInternal');
	PUT_NEW_DICTIONARY_VALUE('VCPGP-Variable Capacity Payments Generation Price','1',0,'MarketExchange','SEM', 'UsePIRForInternal');
	PUT_NEW_DICTIONARY_VALUE('DQ-Dispatch Quantity','1',0,'MarketExchange','SEM', 'UsePIRForInternal');
	PUT_NEW_DICTIONARY_VALUE('DQIU-Dispatch Quantity','1',0,'MarketExchange','SEM', 'UsePIRForInternal');
	PUT_NEW_DICTIONARY_VALUE('NDLFESU-Loss Adjusted Net Demand ESU','1',0,'MarketExchange','SEM', 'UsePIRForInternal');
	PUT_NEW_DICTIONARY_VALUE('EA-Eligible Availability','1',0,'MarketExchange','SEM', 'UsePIRForInternal');
	PUT_NEW_DICTIONARY_VALUE('MSQ-Market Schedule','1',0,'MarketExchange','SEM', 'UsePIRForInternal');
    
    --------------------------
    -- TLAF Day/Night Start    
    --------------------------
    PUT_NEW_DICTIONARY_VALUE('SEM_DAY_START', '7',0, 'MarketExchange', 'SEM', 'Loss Factor');
    PUT_NEW_DICTIONARY_VALUE('SEM_DAY_END', '22',0, 'MarketExchange', 'SEM', 'Loss Factor');
    
    --------------------------
    -- Cross Border VAT start date    
    --------------------------
    PUT_NEW_DICTIONARY_VALUE('Cross Border VAT Start Date','2010-10-29',0,'MarketExchange','SEM','Settlement');
    
    --------------------------
     -- Mapping Invoice Charge Id to Component
     --------------------------
    PUT_NEW_DICTIONARY_VALUE('CCEX_Z', 'CCEX', 0,'MarketExchange','SEM','Settlement','Invoice Charge ID to Component Map');
    PUT_NEW_DICTIONARY_VALUE('CCEX_N', 'CCEX', 0,'MarketExchange','SEM','Settlement','Invoice Charge ID to Component Map');
    PUT_NEW_DICTIONARY_VALUE('CCJEX_Z', 'CCJEX', 0,'MarketExchange','SEM','Settlement','Invoice Charge ID to Component Map');
    PUT_NEW_DICTIONARY_VALUE('CCJEX_N', 'CCJEX', 0,'MarketExchange','SEM','Settlement','Invoice Charge ID to Component Map');
    PUT_NEW_DICTIONARY_VALUE('CONPEX_Z', 'CONPEX', 0,'MarketExchange','SEM','Settlement','Invoice Charge ID to Component Map');
    PUT_NEW_DICTIONARY_VALUE('CONPEX_N', 'CONPEX', 0,'MarketExchange','SEM','Settlement','Invoice Charge ID to Component Map');
    PUT_NEW_DICTIONARY_VALUE('CONPIUEX_Z', 'CONPIUEX', 0,'MarketExchange','SEM','Settlement','Invoice Charge ID to Component Map');
    PUT_NEW_DICTIONARY_VALUE('CONPIUEX_N', 'CONPIUEX', 0,'MarketExchange','SEM','Settlement','Invoice Charge ID to Component Map');
    PUT_NEW_DICTIONARY_VALUE('CPEX_Z', 'CPEX', 0,'MarketExchange','SEM','Settlement','Invoice Charge ID to Component Map');
    PUT_NEW_DICTIONARY_VALUE('CPEX_N', 'CPEX', 0,'MarketExchange','SEM','Settlement','Invoice Charge ID to Component Map');
    PUT_NEW_DICTIONARY_VALUE('CPIUEX_Z', 'CPIUEX', 0,'MarketExchange','SEM','Settlement','Invoice Charge ID to Component Map');
    PUT_NEW_DICTIONARY_VALUE('CPIUEX_N', 'CPIUEX', 0,'MarketExchange','SEM','Settlement','Invoice Charge ID to Component Map');
    PUT_NEW_DICTIONARY_VALUE('ENCEX_Z', 'ENCEX', 0,'MarketExchange','SEM','Settlement','Invoice Charge ID to Component Map');
    PUT_NEW_DICTIONARY_VALUE('ENCEX_N', 'ENCEX', 0,'MarketExchange','SEM','Settlement','Invoice Charge ID to Component Map');
    PUT_NEW_DICTIONARY_VALUE('ENCJEX_Z', 'ENCJEX', 0,'MarketExchange','SEM','Settlement','Invoice Charge ID to Component Map');
    PUT_NEW_DICTIONARY_VALUE('ENCJEX_N', 'ENCJEX', 0,'MarketExchange','SEM','Settlement','Invoice Charge ID to Component Map');
    PUT_NEW_DICTIONARY_VALUE('ENPEX_Z', 'ENPEX', 0,'MarketExchange','SEM','Settlement','Invoice Charge ID to Component Map');
    PUT_NEW_DICTIONARY_VALUE('ENPEX_N', 'ENPEX', 0,'MarketExchange','SEM','Settlement','Invoice Charge ID to Component Map');
    PUT_NEW_DICTIONARY_VALUE('ENPIUEX_Z', 'ENPIUEX', 0,'MarketExchange','SEM','Settlement','Invoice Charge ID to Component Map');
    PUT_NEW_DICTIONARY_VALUE('ENPIUEX_N', 'ENPIUEX', 0,'MarketExchange','SEM','Settlement','Invoice Charge ID to Component Map');
    PUT_NEW_DICTIONARY_VALUE('IMPCEX_Z', 'IMPCEX', 0,'MarketExchange','SEM','Settlement','Invoice Charge ID to Component Map');
    PUT_NEW_DICTIONARY_VALUE('IMPCEX_N', 'IMPCEX', 0,'MarketExchange','SEM','Settlement','Invoice Charge ID to Component Map');
    PUT_NEW_DICTIONARY_VALUE('IMPCJEX_Z', 'IMPCJEX', 0,'MarketExchange','SEM','Settlement','Invoice Charge ID to Component Map');
    PUT_NEW_DICTIONARY_VALUE('IMPCJEX_N', 'IMPCJEX', 0,'MarketExchange','SEM','Settlement','Invoice Charge ID to Component Map');
    PUT_NEW_DICTIONARY_VALUE('MWPEX_Z', 'MWPEX', 0,'MarketExchange','SEM','Settlement','Invoice Charge ID to Component Map');
    PUT_NEW_DICTIONARY_VALUE('MWPEX_N', 'MWPEX', 0,'MarketExchange','SEM','Settlement','Invoice Charge ID to Component Map');
    PUT_NEW_DICTIONARY_VALUE('MWPIUEX_Z', 'MWPIUEX', 0,'MarketExchange','SEM','Settlement','Invoice Charge ID to Component Map');
    PUT_NEW_DICTIONARY_VALUE('MWPIUEX_N', 'MWPIUEX', 0,'MarketExchange','SEM','Settlement','Invoice Charge ID to Component Map');
    PUT_NEW_DICTIONARY_VALUE('TCHAREX_Z', 'TCHAREX', 0,'MarketExchange','SEM','Settlement','Invoice Charge ID to Component Map');
    PUT_NEW_DICTIONARY_VALUE('TCHAREX_N', 'TCHAREX', 0,'MarketExchange','SEM','Settlement','Invoice Charge ID to Component Map');
    PUT_NEW_DICTIONARY_VALUE('UIAE-EX_W', 'UIAE-EX', 0,'MarketExchange','SEM','Settlement','Invoice Charge ID to Component Map');
    PUT_NEW_DICTIONARY_VALUE('UIAE-EX_Z', 'UIAE-EX', 0,'MarketExchange','SEM','Settlement','Invoice Charge ID to Component Map');
    PUT_NEW_DICTIONARY_VALUE('UIAE-EX_EU', 'UIAE-EX', 0,'MarketExchange','SEM','Settlement','Invoice Charge ID to Component Map');
    PUT_NEW_DICTIONARY_VALUE('UIAE-EX_NEU', 'UIAE-EX', 0,'MarketExchange','SEM','Settlement','Invoice Charge ID to Component Map');
    PUT_NEW_DICTIONARY_VALUE('UIAE-EX_N', 'UIAE-EX', 0,'MarketExchange','SEM','Settlement','Invoice Charge ID to Component Map');
    PUT_NEW_DICTIONARY_VALUE('UIAIUGE-EX_W', 'UIAIUGE-EX', 0,'MarketExchange','SEM','Settlement','Invoice Charge ID to Component Map');
    PUT_NEW_DICTIONARY_VALUE('UIAIUGE-EX_Z', 'UIAIUGE-EX', 0,'MarketExchange','SEM','Settlement','Invoice Charge ID to Component Map');
    PUT_NEW_DICTIONARY_VALUE('UIAIUGE-EX_EU', 'UIAIUGE-EX', 0,'MarketExchange','SEM','Settlement','Invoice Charge ID to Component Map');
    PUT_NEW_DICTIONARY_VALUE('UIAIUGE-EX_NEU', 'UIAIUGE-EX', 0,'MarketExchange','SEM','Settlement','Invoice Charge ID to Component Map');
    PUT_NEW_DICTIONARY_VALUE('UIAIUGE-EX_N', 'UIAIUGE-EX', 0,'MarketExchange','SEM','Settlement','Invoice Charge ID to Component Map');
    PUT_NEW_DICTIONARY_VALUE('UIAC-EX_W', 'UIAC-EX', 0,'MarketExchange','SEM','Settlement','Invoice Charge ID to Component Map');
    PUT_NEW_DICTIONARY_VALUE('UIAC-EX_Z', 'UIAC-EX', 0,'MarketExchange','SEM','Settlement','Invoice Charge ID to Component Map');
    PUT_NEW_DICTIONARY_VALUE('UIAC-EX_EU', 'UIAC-EX', 0,'MarketExchange','SEM','Settlement','Invoice Charge ID to Component Map');
    PUT_NEW_DICTIONARY_VALUE('UIAC-EX_NEU', 'UIAC-EX', 0,'MarketExchange','SEM','Settlement','Invoice Charge ID to Component Map');
    PUT_NEW_DICTIONARY_VALUE('UIAC-EX_N', 'UIAC-EX', 0,'MarketExchange','SEM','Settlement','Invoice Charge ID to Component Map');
    PUT_NEW_DICTIONARY_VALUE('UIAIUGC-EX_W', 'UIAIUGC-EX', 0,'MarketExchange','SEM','Settlement','Invoice Charge ID to Component Map');
    PUT_NEW_DICTIONARY_VALUE('UIAIUGC-EX_Z', 'UIAIUGC-EX', 0,'MarketExchange','SEM','Settlement','Invoice Charge ID to Component Map');
    PUT_NEW_DICTIONARY_VALUE('UIAIUGC-EX_EU', 'UIAIUGC-EX', 0,'MarketExchange','SEM','Settlement','Invoice Charge ID to Component Map');
    PUT_NEW_DICTIONARY_VALUE('UIAIUGC-EX_NEU', 'UIAIUGC-EX', 0,'MarketExchange','SEM','Settlement','Invoice Charge ID to Component Map');
    PUT_NEW_DICTIONARY_VALUE('UIAIUGC-EX_N', 'UIAIUGC-EX', 0,'MarketExchange','SEM','Settlement','Invoice Charge ID to Component Map');
    PUT_NEW_DICTIONARY_VALUE('UNIMPEX_Z', 'UNIMPEX', 0,'MarketExchange','SEM','Settlement','Invoice Charge ID to Component Map');
    PUT_NEW_DICTIONARY_VALUE('UNIMPEX_N', 'UNIMPEX', 0,'MarketExchange','SEM','Settlement','Invoice Charge ID to Component Map');
    PUT_NEW_DICTIONARY_VALUE('VMOCJ_EX_Z', 'VMOCJ_EX', 0,'MarketExchange','SEM','Settlement','Invoice Charge ID to Component Map');
    PUT_NEW_DICTIONARY_VALUE('VMOCJ_EX_N', 'VMOCJ_EX', 0,'MarketExchange','SEM','Settlement','Invoice Charge ID to Component Map');
    PUT_NEW_DICTIONARY_VALUE('VMOC_EX_Z', 'VMOC_EX', 0,'MarketExchange','SEM','Settlement','Invoice Charge ID to Component Map');
    PUT_NEW_DICTIONARY_VALUE('VMOC_EX_N', 'VMOC_EX', 0,'MarketExchange','SEM','Settlement','Invoice Charge ID to Component Map');

	-- from sample invoice with MPUD 8.0 (retained "just in case")

    PUT_NEW_DICTIONARY_VALUE('CC_PCPEX_SU_Z', 'CC_PCPEX', 0,'MarketExchange','SEM','Settlement','Invoice Charge ID to Component Map');
    PUT_NEW_DICTIONARY_VALUE('CC_PCPEX_SU_N', 'CC_PCPEX', 0,'MarketExchange','SEM','Settlement','Invoice Charge ID to Component Map');
    PUT_NEW_DICTIONARY_VALUE('CC_PCPEX_GU_Z', 'CC_PCPEX', 0,'MarketExchange','SEM','Settlement','Invoice Charge ID to Component Map');
    PUT_NEW_DICTIONARY_VALUE('CC_PCPEX_GU_N', 'CC_PCPEX', 0,'MarketExchange','SEM','Settlement','Invoice Charge ID to Component Map');
    PUT_NEW_DICTIONARY_VALUE('CC_PCPEX_I_Z', 'CC_PCPEX', 0,'MarketExchange','SEM','Settlement','Invoice Charge ID to Component Map');
    PUT_NEW_DICTIONARY_VALUE('CC_PCPEX_I_N', 'CC_PCPEX', 0,'MarketExchange','SEM','Settlement','Invoice Charge ID to Component Map');
    PUT_NEW_DICTIONARY_VALUE('CC_PENEX_SU_Z', 'CC_PENEX', 0,'MarketExchange','SEM','Settlement','Invoice Charge ID to Component Map');
    PUT_NEW_DICTIONARY_VALUE('CC_PENEX_SU_N', 'CC_PENEX', 0,'MarketExchange','SEM','Settlement','Invoice Charge ID to Component Map');
    PUT_NEW_DICTIONARY_VALUE('CC_PENEX_GU_Z', 'CC_PENEX', 0,'MarketExchange','SEM','Settlement','Invoice Charge ID to Component Map');
    PUT_NEW_DICTIONARY_VALUE('CC_PENEX_GU_N', 'CC_PENEX', 0,'MarketExchange','SEM','Settlement','Invoice Charge ID to Component Map');
    PUT_NEW_DICTIONARY_VALUE('CC_PENEX_I_Z', 'CC_PENEX', 0,'MarketExchange','SEM','Settlement','Invoice Charge ID to Component Map');
    PUT_NEW_DICTIONARY_VALUE('CC_PENEX_I_N', 'CC_PENEX', 0,'MarketExchange','SEM','Settlement','Invoice Charge ID to Component Map');

	-- updates from MPUD 8.3 with new charge IDs for currency conversion charges
    PUT_NEW_DICTIONARY_VALUE('CC_IUCPPEX_N', 'CC_IUCPPEX', 0,'MarketExchange','SEM','Settlement','Invoice Charge ID to Component Map');
    PUT_NEW_DICTIONARY_VALUE('CC_IUCPPEX_Z', 'CC_IUCPPEX', 0,'MarketExchange','SEM','Settlement','Invoice Charge ID to Component Map');
    PUT_NEW_DICTIONARY_VALUE('CC_UCPPEX_N', 'CC_UCPPEX', 0,'MarketExchange','SEM','Settlement','Invoice Charge ID to Component Map');
    PUT_NEW_DICTIONARY_VALUE('CC_UCPPEX_Z', 'CC_UCPPEX', 0,'MarketExchange','SEM','Settlement','Invoice Charge ID to Component Map');
    PUT_NEW_DICTIONARY_VALUE('CC_UCPCEX_N', 'CC_UCPCEX', 0,'MarketExchange','SEM','Settlement','Invoice Charge ID to Component Map');
    PUT_NEW_DICTIONARY_VALUE('CC_UCPCEX_Z', 'CC_UCPCEX', 0,'MarketExchange','SEM','Settlement','Invoice Charge ID to Component Map');
    PUT_NEW_DICTIONARY_VALUE('CC_IUENPEX_N', 'CC_IUENPEX', 0,'MarketExchange','SEM','Settlement','Invoice Charge ID to Component Map');
    PUT_NEW_DICTIONARY_VALUE('CC_IUENPEX_Z', 'CC_IUENPEX', 0,'MarketExchange','SEM','Settlement','Invoice Charge ID to Component Map');
    PUT_NEW_DICTIONARY_VALUE('CC_UENPEX_N', 'CC_UENPEX', 0,'MarketExchange','SEM','Settlement','Invoice Charge ID to Component Map');
    PUT_NEW_DICTIONARY_VALUE('CC_UENPEX_Z', 'CC_UENPEX', 0,'MarketExchange','SEM','Settlement','Invoice Charge ID to Component Map');
    PUT_NEW_DICTIONARY_VALUE('CC_UENCEX_N', 'CC_UENCEX', 0,'MarketExchange','SEM','Settlement','Invoice Charge ID to Component Map');
    PUT_NEW_DICTIONARY_VALUE('CC_UENCEX_Z', 'CC_UENCEX', 0,'MarketExchange','SEM','Settlement','Invoice Charge ID to Component Map');
	
	-- updates for SEM 2.2 with new charge IDs for currency conversion charges
    PUT_NEW_DICTIONARY_VALUE('ENCEX_W', 'ENCEX', 0,'MarketExchange','SEM','Settlement','Invoice Charge ID to Component Map');
    PUT_NEW_DICTIONARY_VALUE('ENCEX_EU', 'ENCEX', 0,'MarketExchange','SEM','Settlement','Invoice Charge ID to Component Map');
    PUT_NEW_DICTIONARY_VALUE('ENCEX_NEU', 'ENCEX', 0,'MarketExchange','SEM','Settlement','Invoice Charge ID to Component Map');
    PUT_NEW_DICTIONARY_VALUE('IMPCEX_W', 'IMPCEX', 0,'MarketExchange','SEM','Settlement','Invoice Charge ID to Component Map');
    PUT_NEW_DICTIONARY_VALUE('IMPCEX_EU', 'IMPCEX', 0,'MarketExchange','SEM','Settlement','Invoice Charge ID to Component Map');
    PUT_NEW_DICTIONARY_VALUE('IMPCEX_NEU', 'IMPCEX', 0,'MarketExchange','SEM','Settlement','Invoice Charge ID to Component Map');
	PUT_NEW_DICTIONARY_VALUE('CCEX_W', 'CCEX', 0,'MarketExchange','SEM','Settlement','Invoice Charge ID to Component Map');
    PUT_NEW_DICTIONARY_VALUE('CCEX_EU', 'CCEX', 0,'MarketExchange','SEM','Settlement','Invoice Charge ID to Component Map');
    PUT_NEW_DICTIONARY_VALUE('CCEX_NEU', 'CCEX', 0,'MarketExchange','SEM','Settlement','Invoice Charge ID to Component Map');
	
	-- updates for SEM 2.2 with new charge IDs for currency cost components
	PUT_NEW_DICTIONARY_VALUE('CC_UENCEX_W', 'CC_UENCEX', 0,'MarketExchange','SEM','Settlement','Invoice Charge ID to Component Map');
    PUT_NEW_DICTIONARY_VALUE('CC_UENCEX_EU', 'CC_UENCEX', 0,'MarketExchange','SEM','Settlement','Invoice Charge ID to Component Map');
    PUT_NEW_DICTIONARY_VALUE('CC_UENCEX_NEU', 'CC_UENCEX', 0,'MarketExchange','SEM','Settlement','Invoice Charge ID to Component Map');
    PUT_NEW_DICTIONARY_VALUE('CC_UCPCEX_W', 'CC_UCPCEX', 0,'MarketExchange','SEM','Settlement','Invoice Charge ID to Component Map');
    PUT_NEW_DICTIONARY_VALUE('CC_UCPCEX_EU', 'CC_UCPCEX', 0,'MarketExchange','SEM','Settlement','Invoice Charge ID to Component Map');
    PUT_NEW_DICTIONARY_VALUE('CC_UCPCEX_NEU', 'CC_UCPCEX', 0,'MarketExchange','SEM','Settlement','Invoice Charge ID to Component Map');
	
	-- updates for IDT Trading Credit-Cover
	PUT_NEW_DICTIONARY_VALUE('IDT_BEGIN_TIME', '06:30', 0, 'MarketExchange', 'SEM', 'Intra Day Trading', 'EA');
	PUT_NEW_DICTIONARY_VALUE('IDT_END_TIME', '06:00', 0, 'MarketExchange', 'SEM', 'Intra Day Trading', 'EA');
	PUT_NEW_DICTIONARY_VALUE('IDT_DATE_OFFSET', '1', 0, 'MarketExchange', 'SEM', 'Intra Day Trading', 'EA');
	PUT_NEW_DICTIONARY_VALUE('IDT_BEGIN_TIME', '06:30', 0, 'MarketExchange', 'SEM', 'Intra Day Trading', 'EA2');
	PUT_NEW_DICTIONARY_VALUE('IDT_END_TIME', '06:00', 0, 'MarketExchange', 'SEM', 'Intra Day Trading', 'EA2');
	PUT_NEW_DICTIONARY_VALUE('IDT_DATE_OFFSET', '1', 0, 'MarketExchange', 'SEM', 'Intra Day Trading', 'EA2');
	PUT_NEW_DICTIONARY_VALUE('IDT_BEGIN_TIME', '06:30', 0, 'MarketExchange', 'SEM', 'Intra Day Trading', 'WD1');
	PUT_NEW_DICTIONARY_VALUE('IDT_END_TIME', '06:00', 0, 'MarketExchange', 'SEM', 'Intra Day Trading', 'WD1');
	PUT_NEW_DICTIONARY_VALUE('IDT_DATE_OFFSET', '0', 0, 'MarketExchange', 'SEM', 'Intra Day Trading', 'WD1');
	PUT_NEW_DICTIONARY_VALUE('IDT_BEGIN_TIME', '06:30', 0, 'MarketExchange', 'SEM', 'Intra Day Trading', 'EP1');
	PUT_NEW_DICTIONARY_VALUE('IDT_END_TIME', '06:00', 0, 'MarketExchange', 'SEM', 'Intra Day Trading', 'EP1');
	PUT_NEW_DICTIONARY_VALUE('IDT_DATE_OFFSET', '-2', 0, 'MarketExchange', 'SEM', 'Intra Day Trading', 'EP1');
	PUT_NEW_DICTIONARY_VALUE('IDT_BEGIN_TIME', '06:30', 0, 'MarketExchange', 'SEM', 'Intra Day Trading', 'EP2');
	PUT_NEW_DICTIONARY_VALUE('IDT_END_TIME', '06:00', 0, 'MarketExchange', 'SEM', 'Intra Day Trading', 'EP2');
	PUT_NEW_DICTIONARY_VALUE('IDT_DATE_OFFSET', '-5', 0, 'MarketExchange', 'SEM', 'Intra Day Trading', 'EP2');
	
	--------------------------
    -- SEM R2.2 Cutover Date    
    --------------------------
    PUT_NEW_DICTIONARY_VALUE('SEM R2.2 Cutover Date','2013-05-01',0,'MarketExchange','SEM','Settlement');

END;
/
-- save changes to database
COMMIT;
