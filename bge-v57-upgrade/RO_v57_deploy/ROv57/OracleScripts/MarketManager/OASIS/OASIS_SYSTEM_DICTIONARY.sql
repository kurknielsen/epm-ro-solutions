SET DEFINE OFF	
	
BEGIN

    PUT_DICTIONARY_VALUE('Log Only', 0, 0, 'MarketExchange', 'OASIS');
    PUT_DICTIONARY_VALUE('Status Notification', '<ALL>', 0, 'MarketExchange', 'OASIS');
    -- The Notification URL should be in the form http://webserver/mexDispatch/mexRecvMsg.asp?category=OasisStatusMessages
    PUT_DICTIONARY_VALUE('Status Notification URL', null, 0, 'MarketExchange', 'OASIS');
    
    -- These should be customized for each customer
    -- The below values were used for Midwest Energy
    PUT_DICTIONARY_VALUE('Query Status', 'WR', 1, 'Market Exchange', 'OASIS', 'Input List', 'Customer');
	PUT_DICTIONARY_VALUE('Query Status', NULL, 1, 'Market Exchange', 'OASIS', 'Input List', 'Status');
    /*PUT_DICTIONARY_VALUE('Query Status - All Confirmed', 'MWE,KCPS,KCPL,KEPC,KMEA,OPPD,OPPM,SECI,SEPC,SPS,SPSM,TNSK,WR,WRGS,MPS,UCU', 1, 'Market Exchange', 'OASIS', 'Input List', 'Customer');
    PUT_DICTIONARY_VALUE('Query Status - All Confirmed', 'CONFIRMED', 1, 'Market Exchange', 'OASIS', 'Input List', 'Status');*/

END;
/

-- save changes to database
COMMIT;
SET DEFINE ON	
