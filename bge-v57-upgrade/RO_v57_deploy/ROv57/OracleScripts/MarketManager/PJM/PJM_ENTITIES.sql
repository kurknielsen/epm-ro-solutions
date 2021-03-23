DECLARE
	TYPE t_ARRAY IS VARRAY(100) OF VARCHAR2(255);
	l_OID NUMBER;
	i     NUMBER;

	-- format is mkt price name, mkt price desc, mkt price interval. 
	l_MARKET_PRICES t_ARRAY := t_ARRAY('MAAC Monthly Expense',
																		 'MAAC Monthly Expense', 'Month',
																		 'PJM Trans Mkt Exp Load Chg Rate',
																		 'PJM Transitional Market Expansion charge rate for transmission customers based on their network load (excluding CE control zone) and exports, including wheel-throughs. Targeted to end April 2005.',
																		 'Month', 'PJM Trans Mkt Exp Gen Chg Rate',
																		 'PJM Transitional Market Expansion charge rate for transmission customers based on their network load (excluding CE control zone) and exports, including wheel-throughs. Targeted to end April 2005.',
																		 'Month', 'PJM Exp Int Gen Charge Rate',
																		 'PJM Expansion Integration charge rate for providers of generation and imports, including wheel-throughs. Transition period for charges ends in November 2004.',
																		 'Month', 'PJM Exp Int Load Charge Rate',
																		 'PJM Expansion Integration charge rate for transmission customers based on their network load and exports, including wheel-throughs. Transition period for charges ends in November 2004.',
																		 'Month', 'PJM Market Support Charge Rate',
																		 'PJM Market Support Charge Rate', 'Year',
																		 'PJM eMKT BO Pair Submit Rate',
																		 'PJM eMKT Bid-Offer Pair Submit Rate',
																		 'Year', 'PJM Reg & Freq Resp Admin Rate',
																		 'PJM Regulation and Frequency Response Administration Charge Rate',
																		 'Year', 'PJM Cap Res & Oblig Mgmt Rate',
																		 'PJM capacity resource and obligation management rate',
																		 'Year', 'PJM FERC Ann Chg Recovery Rate',
																		 'PJM FERC annual charge recovery rate',
																		 'Year', 'PJM Control Area Admin Rate',
																		 'PJM Control Area Administration monthly rate',
																		 'Month', 'PJM DA Oper Res Total Cost',
																		 'PJM Day-ahead Operating Reserves Total Cost',
																		 'Month', 'PJM Bal Oper Res Total Cost',
																		 'PJM Balancing Operating Reserves Total Cost',
																		 'Month', 'PJM Synch Condensing Total Cost',
																		 'PJM Synch Condensing Total Cost', 'Month',
																		 'PJM Reactive Services Total Cost',
																		 'PJM Synch Condensing Total Cost', 'Month');

	l_PSES t_ARRAY := t_ARRAY('AEMN', 'CALLC', 'CINSI', 'COMED', 'CPSI', 'Dynegy',
														'EMMTNI', 'EPME', 'EXGNCE', 'JARON', 'MAEM', 'Morgan',
														'NEV', 'PJM', 'Select');
	-- format is name, type, is_export, is_bid/offer, commodity name
	l_TRANSACTIONS t_ARRAY := t_ARRAY(
					'PJM System Load', 'Load', '0', '0', 'System Load',
					'PJM Day-ahead Decrement Bids','Load', '0', '1', 'Virtual Energy',
					'PJM Day-ahead Exports', 'Sale', '1', '0', 'Not Assigned',
					'PJM Day-ahead Increment Bids', 'Generation', '0', '1', 'Virtual Energy');

	PROCEDURE PUT_COMMODITY(p_NAME        IN VARCHAR2,
													p_VIRTUAL     IN BOOLEAN,
													p_MARKET_TYPE IN VARCHAR2) IS
		l_OID     NUMBER;
		l_VIRTUAL IT_COMMODITY.IS_VIRTUAL%TYPE;
	BEGIN
		IF p_VIRTUAL = TRUE THEN
			l_VIRTUAL := 1;
		ELSE
			l_VIRTUAL := 0;
		END IF;
		IO.PUT_IT_COMMODITY(l_OID, p_NAME, p_NAME, p_NAME, 0, 'Energy', 'MWH', NULL,
												NULL, NULL, l_VIRTUAL, p_MARKET_TYPE);
	END PUT_COMMODITY;

	PROCEDURE PUT_MARKET_PRICE(p_NAME     IN VARCHAR2,
														 p_DESC     IN VARCHAR2,
														 p_INTERVAL IN VARCHAR2,
														 p_SC_ID    IN NUMBER) IS
		l_OID NUMBER;
	BEGIN
		IO.PUT_MARKET_PRICE(o_OID => l_OID, p_MARKET_PRICE_NAME => p_NAME,
												p_MARKET_PRICE_ALIAS => p_NAME,
												p_MARKET_PRICE_DESC => p_DESC, p_MARKET_PRICE_ID => 0,
												p_MARKET_PRICE_TYPE => '?',
												p_MARKET_PRICE_INTERVAL => p_INTERVAL,
												p_MARKET_TYPE => '?', p_SERVICE_POINT_TYPE => 'Point',
												p_SC_ID => p_SC_ID, p_EXTERNAL_IDENTIFIER => NULL,
												p_EDC_ID => 0, p_POD_ID => 0);
	END PUT_MARKET_PRICE;

	PROCEDURE PUT_PSE(p_PSE_NAME IN VARCHAR2) IS
		l_OID               NUMBER;
		l_IS_BILLING_ENTITY PSE.IS_BILLING_ENTITY%TYPE := 0;
		l_INVOICE_LINE_ITEM PSE.INVOICE_LINE_ITEM_OPTION%TYPE := 'By Product-Component';
	BEGIN
		IF p_PSE_NAME = 'PJM' THEN
			l_IS_BILLING_ENTITY := 1;
			l_INVOICE_LINE_ITEM := 'PJM Category';
		END IF;
	
		IO.PUT_PSE(o_OID => l_OID, p_PSE_NAME => p_PSE_NAME, p_PSE_ALIAS => '?',
							 p_PSE_DESC => '?', p_PSE_ID => 0, p_PSE_NERC_CODE => '?',
							 p_PSE_STATUS => 'Active', p_PSE_DUNS_NUMBER => '?',
							 p_PSE_BANK => '?', p_PSE_ACH_NUMBER => '?', p_PSE_TYPE => 'IPP',
							 p_PSE_EXTERNAL_IDENTIFIER => '?', p_PSE_IS_RETAIL_AGGREGATOR => 0,
							 p_PSE_IS_BACKUP_GENERATION => 0, p_PSE_EXCLUDE_LOAD_SCHEDULE => 0,
							 p_IS_BILLING_ENTITY => l_IS_BILLING_ENTITY,
							 p_TIME_ZONE => LOCAL_TIME_ZONE, p_STATEMENT_INTERVAL => 'Month',
							 p_INVOICE_INTERVAL => 'Month', p_WEEK_BEGIN => 'First of Month',
							 p_INVOICE_LINE_ITEM_OPTION => l_INVOICE_LINE_ITEM);
	END PUT_PSE;

	PROCEDURE ADD_INTERCHANGE_TRANSACTION(p_NAME           IN VARCHAR2,
																				p_TYPE           IN VARCHAR2,
																				p_IS_EXPORT      IN NUMBER,
																				p_IS_BID_OFFER   IN NUMBER,
																				p_COMMODITY_NAME IN VARCHAR2) IS
		l_OID          NUMBER;
		l_COMMODITY_ID NUMBER;
		l_SC_ID        NUMBER;
	BEGIN
		SELECT C.COMMODITY_ID
			INTO l_COMMODITY_ID
			FROM IT_COMMODITY C
		 WHERE UPPER(C.COMMODITY_NAME) = UPPER(p_COMMODITY_NAME);
		SELECT SC.SC_ID INTO l_SC_ID FROM SC WHERE SC.SC_NAME = 'PJM';
	
		IO.PUT_TRANSACTION(o_OID => l_OID, p_TRANSACTION_NAME => p_NAME,
											 p_TRANSACTION_ALIAS => p_NAME, p_TRANSACTION_DESC => '?',
											 p_TRANSACTION_ID => 0, p_TRANSACTION_TYPE => p_TYPE,
											 p_TRANSACTION_CODE => '?',
											 p_TRANSACTION_IDENTIFIER => '?', p_IS_FIRM => 0,
											 p_IS_IMPORT_SCHEDULE => 0,
											 p_IS_EXPORT_SCHEDULE => p_IS_EXPORT,
											 p_IS_BALANCE_TRANSACTION => 0,
											 p_IS_BID_OFFER => p_IS_BID_OFFER,
											 p_IS_EXCLUDE_FROM_POSITION => 0, p_IS_IMPORT_EXPORT => 0,
											 p_TRANSACTION_INTERVAL => 'Hour',
											 p_EXTERNAL_INTERVAL => '?', p_ETAG_CODE => '?',
											 p_BEGIN_DATE => TO_DATE('01/01/2003', 'MM/DD/YYYY'),
											 p_END_DATE => TO_DATE('12/31/2010', 'MM/DD/YYYY'),
											 p_PURCHASER_ID => 0, p_SELLER_ID => 0, p_CONTRACT_ID => 0,
											 p_SC_ID => l_SC_ID, p_POR_ID => 0, p_POD_ID => 0,
											 p_SCHEDULER_ID => 0, p_COMMODITY_ID => l_COMMODITY_ID,
											 p_SERVICE_TYPE_ID => 0, p_TX_TRANSACTION_ID => 0,
											 p_PATH_ID => 0, p_LINK_TRANSACTION_ID => 0, p_EDC_ID => 0,
											 p_PSE_ID => 0, p_ESP_ID => 0, p_POOL_ID => 0,
											 p_SCHEDULE_GROUP_ID => 0, p_MARKET_PRICE_ID => 0,
											 p_ZOR_ID => 0, p_ZOD_ID => 0, p_SOURCE_ID => 0,
											 p_SINK_ID => 0, p_RESOURCE_ID => 0,
											 p_AGREEMENT_TYPE => '?', p_APPROVAL_TYPE => '?',
											 p_LOSS_OPTION => '?', p_TRAIT_CATEGORY => 0,
											 p_MODEL_ID => 1,
											 p_TP_ID => 0
											 );
	END ADD_INTERCHANGE_TRANSACTION;

BEGIN
	-- add PJM as a schedule coordinator
	IO.PUT_SC(l_OID, 'PJM', 'PJM', 'PJM', 0, NULL, NULL, 'Active', NULL, 'PJM',
						'Service Point', 'Hour', 'None', 'None', 0, 0, 0, NULL, NULL);

	-- add the commodities
	PUT_COMMODITY('Virtual Energy', TRUE, 'DayAhead');
	PUT_COMMODITY('DayAhead Energy', FALSE, 'DayAhead');
	PUT_COMMODITY('RealTime Energy', FALSE, 'RealTime');
	PUT_COMMODITY('System Load', FALSE, 'RealTime');

	-- add the market prices
	i := 1;
	LOOP
		PUT_MARKET_PRICE(l_MARKET_PRICES(i), l_MARKET_PRICES(i + 1),
										 l_MARKET_PRICES(i + 2), l_OID);
		i := i + 3;
		EXIT WHEN i > l_MARKET_PRICES.COUNT;
	END LOOP;

	-- add the PSEs
	FOR i IN 1 .. l_PSES.COUNT LOOP
		PUT_PSE(l_PSES(i));
	END LOOP;

	COMMIT;

	-- add the PJM transactions (format of array is name, type, is_export, 
	-- is_bid/offer, commodity name)
	i := 1;
	LOOP
		ADD_INTERCHANGE_TRANSACTION(l_TRANSACTIONS(i), l_TRANSACTIONS(i + 1),
																l_TRANSACTIONS(i + 2), l_TRANSACTIONS(i + 3),
																l_TRANSACTIONS(i + 4));
		i := i + 5;
		EXIT WHEN i > l_TRANSACTIONS.COUNT;
	END LOOP;

	COMMIT;
END;
/