-- CVS Revision: $Revision: 1.14 $
DECLARE
	v_USER_ROLE_ID  NUMBER(9);
    v_PUSER_ROLE_ID NUMBER (9);
    v_STATUS        NUMBER;
	------------------------------------
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
	BEGIN
        
	    INSERT INTO SYSTEM_LABEL ( MODEL_ID, MODULE, KEY1, KEY2, KEY3, POSITION, VALUE, CODE, IS_DEFAULT, IS_HIDDEN ) 
                           VALUES (p_MODEL_ID, p_MODULE, p_KEY1, p_KEY2, p_KEY3, p_POSITION, p_VALUE, p_CODE, p_IS_DEFAULT, p_IS_HIDDEN);
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN	NULL;
			WHEN OTHERS THEN	RAISE;
	END INSERT_SYSTEM_LABEL;
    --------------------------------------------

	
BEGIN

    --SYSTEM_LABEL - Transaction Types
    INSERT_SYSTEM_LABEL(1,'Scheduling', 'TransactionDialog', 'Combo Lists', 'Transaction Type', 11, 'Nomination', NULL, 0, NULL);
    INSERT_SYSTEM_LABEL(1,'Scheduling', 'TransactionDialog', 'Combo Lists', 'Transaction Type', 12, 'Dispatch Instr.', NULL, 0, NULL);
    INSERT_SYSTEM_LABEL(1,'Scheduling', 'TransactionDialog', 'Combo Lists', 'Transaction Type', 13, 'Net Demand', NULL, 0, NULL);
    INSERT_SYSTEM_LABEL(1,'Scheduling', 'TransactionDialog', 'Combo Lists', 'Transaction Type', 14, 'Eligible Avail.', NULL, 0, NULL);
    INSERT_SYSTEM_LABEL(1,'Scheduling', 'TransactionDialog', 'Combo Lists', 'Transaction Type', 15, 'Market Results', NULL, 0, NULL);
    INSERT_SYSTEM_LABEL(1,'Scheduling', 'TransactionDialog', 'Combo Lists', 'Transaction Type', 16, 'SRA', NULL, 0, NULL);
	  INSERT_SYSTEM_LABEL(1,'Scheduling', 'TransactionDialog', 'Combo Lists', 'Transaction Type', 17, 'VAT Schedule', NULL, 0, NULL);
	  INSERT_SYSTEM_LABEL(1,'Scheduling', 'TransactionDialog', 'Combo Lists', 'Transaction Type', 18, 'Net Demand CA', NULL, 0, NULL);
	  INSERT_SYSTEM_LABEL(1,'Scheduling', 'TransactionDialog', 'Combo Lists', 'Transaction Type', 19, 'Net Demand VMOC', NULL, 0, NULL);
	  INSERT_SYSTEM_LABEL(1,'Scheduling', 'TransactionDialog', 'Combo Lists', 'Transaction Type', 20, 'Traded Exposure', NULL, 0, NULL);
    
    --charge components included in Energy Currency Conversion Charges
    INSERT_SYSTEM_LABEL(0,'MarketExchange', 'SEM', 'Settlement', 'Energy Currency Conversion Charges', 1, 'CONPEX', NULL, 0, NULL);
    INSERT_SYSTEM_LABEL(0,'MarketExchange', 'SEM', 'Settlement', 'Energy Currency Conversion Charges', 2, 'CONPIUEX', NULL, 0, NULL);
    INSERT_SYSTEM_LABEL(0,'MarketExchange', 'SEM', 'Settlement', 'Energy Currency Conversion Charges', 3, 'ENPEX', NULL, 0, NULL);
    INSERT_SYSTEM_LABEL(0,'MarketExchange', 'SEM', 'Settlement', 'Energy Currency Conversion Charges', 4, 'ENPIUEX', NULL, 0, NULL);
    INSERT_SYSTEM_LABEL(0,'MarketExchange', 'SEM', 'Settlement', 'Energy Currency Conversion Charges', 5, 'MWPEX', NULL, 0, NULL);
    INSERT_SYSTEM_LABEL(0,'MarketExchange', 'SEM', 'Settlement', 'Energy Currency Conversion Charges', 6, 'MWPIUEX', NULL, 0, NULL);
    INSERT_SYSTEM_LABEL(0,'MarketExchange', 'SEM', 'Settlement', 'Energy Currency Conversion Charges', 7, 'UNIMPEX', NULL, 0, NULL);
    INSERT_SYSTEM_LABEL(0,'MarketExchange', 'SEM', 'Settlement', 'Energy Currency Conversion Charges', 8, 'ENCEX', NULL, 0, NULL);
    INSERT_SYSTEM_LABEL(0,'MarketExchange', 'SEM', 'Settlement', 'Energy Currency Conversion Charges', 9, 'ENCJEX', NULL, 0, NULL);
    INSERT_SYSTEM_LABEL(0,'MarketExchange', 'SEM', 'Settlement', 'Energy Currency Conversion Charges', 10, 'IMPCEX', NULL, 0, NULL);
    INSERT_SYSTEM_LABEL(0,'MarketExchange', 'SEM', 'Settlement', 'Energy Currency Conversion Charges', 11, 'IMPCJEX', NULL, 0, NULL);
  
    --charge components included in Capacity Currency Conversion Charges
    INSERT_SYSTEM_LABEL(0,'MarketExchange', 'SEM', 'Settlement', 'Capacity Currency Conversion Charges', 1, 'CPEX', NULL, 0, NULL);
    INSERT_SYSTEM_LABEL(0,'MarketExchange', 'SEM', 'Settlement', 'Capacity Currency Conversion Charges', 2, 'CPIUEX', NULL, 0, NULL);
    INSERT_SYSTEM_LABEL(0,'MarketExchange', 'SEM', 'Settlement', 'Capacity Currency Conversion Charges', 3, 'CCEX', NULL, 0, NULL);
    INSERT_SYSTEM_LABEL(0,'MarketExchange', 'SEM', 'Settlement', 'Capacity Currency Conversion Charges', 4, 'CCJEX', NULL, 0, NULL);
    
    --System Label for CFD Products
    INSERT_SYSTEM_LABEL(0,'MarketExchange', 'SEM', 'CFD Product', 'DC', 1, 'Baseload', NULL, 0, NULL);
    INSERT_SYSTEM_LABEL(0,'MarketExchange', 'SEM', 'CFD Product', 'DC', 2, 'Mid-merit', NULL, 0, NULL);
    INSERT_SYSTEM_LABEL(0,'MarketExchange', 'SEM', 'CFD Product', 'DC', 3, 'Peak', NULL, 0, NULL);
    
    INSERT_SYSTEM_LABEL(0,'MarketExchange', 'SEM', 'CFD Product', 'NDC', 1, 'Baseload', NULL, 0, NULL);
    INSERT_SYSTEM_LABEL(0,'MarketExchange', 'SEM', 'CFD Product', 'NDC', 2, 'Mid-merit Type 1', NULL, 0, NULL);
    INSERT_SYSTEM_LABEL(0,'MarketExchange', 'SEM', 'CFD Product', 'NDC', 3, 'Mid-merit Type 2', NULL, 0, NULL);
    INSERT_SYSTEM_LABEL(0,'MarketExchange', 'SEM', 'CFD Product', 'NDC', 4, 'Peak', NULL, 0, NULL);
		
		--System Label for CFD Jurisdiction
		INSERT_SYSTEM_LABEL(0,'MarketExchange', 'SEM', 'CFD Jurisdiction', '?', 1, 'ROI', NULL, 0, NULL);
		INSERT_SYSTEM_LABEL(0,'MarketExchange', 'SEM', 'CFD Jurisdiction', '?', 2, 'NI', NULL, 0, NULL);
       
	-- System Label for Fuel Types (reference MPUD 5.3 p166; items 70.5)
	INSERT_SYSTEM_LABEL(0, 'MarketExchange', 'SEM', 'Fuel Type', '?', 1, 'OIL', NULL, 0, NULL);
	INSERT_SYSTEM_LABEL(0, 'MarketExchange', 'SEM', 'Fuel Type', '?', 2, 'GAS', NULL, 0, NULL);
	INSERT_SYSTEM_LABEL(0, 'MarketExchange', 'SEM', 'Fuel Type', '?', 3, 'COAL', NULL, 0, NULL);
	INSERT_SYSTEM_LABEL(0, 'MarketExchange', 'SEM', 'Fuel Type', '?', 4, 'MULTI', NULL, 0, NULL);
	INSERT_SYSTEM_LABEL(0, 'MarketExchange', 'SEM', 'Fuel Type', '?', 5, 'WIND', NULL, 0, NULL);
	INSERT_SYSTEM_LABEL(0, 'MarketExchange', 'SEM', 'Fuel Type', '?', 6, 'HYDRO', NULL, 0, NULL);
	INSERT_SYSTEM_LABEL(0, 'MarketExchange', 'SEM', 'Fuel Type', '?', 7, 'BIO', NULL, 0, NULL);
	INSERT_SYSTEM_LABEL(0, 'MarketExchange', 'SEM', 'Fuel Type', '?', 8, 'CHP', NULL, 0, NULL);
	INSERT_SYSTEM_LABEL(0, 'MarketExchange', 'SEM', 'Fuel Type', '?', 9, 'PUMP', NULL, 0, NULL);
	INSERT_SYSTEM_LABEL(0, 'MarketExchange', 'SEM', 'Fuel Type', '?', 10, 'PEAT', NULL, 0, NULL);
	INSERT_SYSTEM_LABEL(0, 'MarketExchange', 'SEM', 'Fuel Type', '?', 11, 'DISTL', NULL, 0, NULL);
	INSERT_SYSTEM_LABEL(0, 'MarketExchange', 'SEM', 'Fuel Type', '?', 12, 'NUCLR', NULL, 0, NULL);
	INSERT_SYSTEM_LABEL(0, 'MarketExchange', 'SEM', 'Fuel Type', '?', 13, 'NA', NULL, 0, NULL);
	
	--System Labels for Settlement Validation Components
	INSERT_SYSTEM_LABEL(0,'MarketExchange', 'SEM', 'Settlement', 'Comparison Components', 1, 'ENCEX', NULL, 0, NULL);
	INSERT_SYSTEM_LABEL(0,'MarketExchange', 'SEM', 'Settlement', 'Comparison Components', 2, 'CCEX', NULL, 0, NULL);
	INSERT_SYSTEM_LABEL(0,'MarketExchange', 'SEM', 'Settlement', 'Comparison Components', 3, 'IMPCEX', NULL, 0, NULL);
	INSERT_SYSTEM_LABEL(0,'MarketExchange', 'SEM', 'Settlement', 'Comparison Components', 4, 'VMOC_EX', NULL, 0, NULL);
    
    -- System Label for mapping SEM settlement report types to names for download group reporting and processing
    INSERT_SYSTEM_LABEL(0, 'MarketExchange', 'SEM', 'Settlement', 'Reports Map', 1, 'PIR', 'PIR', 0, NULL);
    INSERT_SYSTEM_LABEL(0, 'MarketExchange', 'SEM', 'Settlement', 'Reports Map', 2, 'Statement', 'STMNT', 0, NULL);
    INSERT_SYSTEM_LABEL(0, 'MarketExchange', 'SEM', 'Settlement', 'Reports Map', 3, 'Invoice', 'INV', 0, NULL);
    INSERT_SYSTEM_LABEL(0, 'MarketExchange', 'SEM', 'Settlement', 'Reports Map', 4, 'Reallocation Agreement', 'RAR', 0, NULL);
    INSERT_SYSTEM_LABEL(0, 'MarketExchange', 'SEM', 'Settlement', 'Reports Map', 5, 'Credit Cover', 'CCR', 0, NULL);
    INSERT_SYSTEM_LABEL(0, 'MarketExchange', 'SEM', 'Settlement', 'Reports Map', 6, 'Market Financials', 'MFR', 0, NULL);
    INSERT_SYSTEM_LABEL(0, 'MarketExchange', 'SEM', 'Settlement', 'Reports Map', 7, 'Market Information', 'MIR', 0, NULL);
    INSERT_SYSTEM_LABEL(0, 'MarketExchange', 'SEM', 'Settlement', 'Reports Map', 8, 'Meter Generation', 'MGR', 0, NULL);

    INSERT_SYSTEM_LABEL(0, 'MarketExchange', 'SEM', 'Offer Management', 'Generator COD', 1, 'SEM Startup Costs', '1', 0, 0);
    INSERT_SYSTEM_LABEL(0, 'MarketExchange', 'SEM', 'Offer Management', 'Generator COD', 2, 'SEM No Load Cost', '1', 0, 0);
    INSERT_SYSTEM_LABEL(0, 'MarketExchange', 'SEM', 'Offer Management', 'Generator COD', 3, 'Offer Curve', '10', 0, 0);
    INSERT_SYSTEM_LABEL(0, 'MarketExchange', 'SEM', 'Offer Management', 'Generator COD', 4, 'SEM Under Test', '1', 0, 0);
    INSERT_SYSTEM_LABEL(0, 'MarketExchange', 'SEM', 'Offer Management', 'Generator COD', 5, 'SEM External Identifier', '1', 0, 0);
    INSERT_SYSTEM_LABEL(0, 'MarketExchange', 'SEM', 'Offer Management', 'Generator COD', 6, 'SEM SEM Transaction ID', '1', 0, 0);

    INSERT_SYSTEM_LABEL(0, 'MarketExchange', 'SEM', 'Offer Management', 'Interconnector COD Daily', 1, 'SEM External Identifier', '1', 0, 0);
    INSERT_SYSTEM_LABEL(0, 'MarketExchange', 'SEM', 'Offer Management', 'Interconnector COD Daily', 2, 'SEM SEM Transaction ID', '1', 0, 0);
    INSERT_SYSTEM_LABEL(0, 'MarketExchange', 'SEM', 'Offer Management', 'Interconnector COD', 1, 'SEM Max Capacity', '1', 0, 0);
    INSERT_SYSTEM_LABEL(0, 'MarketExchange', 'SEM', 'Offer Management', 'Interconnector COD', 2, 'Offer Curve', '3', 0, 0);
END;
/

COMMIT;


