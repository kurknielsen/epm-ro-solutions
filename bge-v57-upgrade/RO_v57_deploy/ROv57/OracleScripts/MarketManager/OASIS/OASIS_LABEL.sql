SET DEFINE OFF	
	
	------------------------------------
	/*PROCEDURE INSERT_DATA_EXCHANGE_ACTION
		(
		p_ACTION_TYPE IN VARCHAR2,
		p_ACTION_NAME IN VARCHAR2,
		p_IS_IMPORT IN BOOLEAN
		) AS
	v_NAME SYSTEM_ACTION.ACTION_NAME%TYPE;
	v_DISPLAY_NAME VARCHAR2(256);
	v_IMPORT_TYPE VARCHAR2(256);
	v_EXCHANGE_TYPE VARCHAR2(256);
	v_ID NUMBER;
	BEGIN
		v_DISPLAY_NAME := 'OASIS: '||p_ACTION_NAME;
		v_NAME := 'Sched:OASIS: '||p_ACTION_NAME;

		IF p_IS_IMPORT THEN
			v_IMPORT_TYPE := 'File';
			v_EXCHANGE_TYPE := NULL;
		ELSE
			IF p_ACTION_TYPE = 'Bid Offer' THEN
				v_EXCHANGE_TYPE := 'XS.BID_OFFER_SUBMIT';
			ELSE
				v_EXCHANGE_TYPE := 'Exchange';
			END IF;
			v_IMPORT_TYPE := NULL;
		END IF;

		v_ID := ID.ID_FOR_SYSTEM_ACTION(v_NAME);
		IF v_ID < 0 THEN v_ID := 0; END IF;
		IO.PUT_SYSTEM_ACTION(v_ID, v_NAME, SUBSTR(v_NAME,1,32), v_DISPLAY_NAME, v_ID, NULL, 'Scheduling', p_ACTION_TYPE,
					v_DISPLAY_NAME, v_IMPORT_TYPE, NULL, v_EXCHANGE_TYPE, NULL);
		EM.PUT_SYSTEM_ACTION_ROLE(v_ID, v_ADMIN_ID, 1, 0, 0, v_ID);
	END INSERT_DATA_EXCHANGE_ACTION;*/
	------------------------------------
BEGIN

    PUT_DICTIONARY_VALUE('Log Only', 0, 1, 'Market Exchange', 'OASIS');
    PUT_DICTIONARY_VALUE('Status Notification', '<ALL>', 1, 'Market Exchange', 'OASIS');
    -- The Notification URL should be in the form http://webserver/mexDispatch/mexRecvMsg.asp?category=OasisStatusMessages
    PUT_DICTIONARY_VALUE('Status Notification URL', null, 1, 'Market Exchange', 'OASIS');
    
    -- These should be customized for the customer
    /*PUT_DICTIONARY_VALUE('Query Status', 'MIDW', 1, 'Market Exchange', 'OASIS', 'Input List', 'Customer');
	PUT_DICTIONARY_VALUE('Query Status', NULL, 1, 'Market Exchange', 'OASIS', 'Input List', 'Status');
    PUT_DICTIONARY_VALUE('Query Status - All Confirmed', 'MWE,KCPS,KCPL,KEPC,KMEA,OPPD,OPPM,SECI,SEPC,SPS,SPSM,TNSK,WR,WRGS,MPS,UCU', 1, 'Market Exchange', 'OASIS', 'Input List', 'Customer');
    PUT_DICTIONARY_VALUE('Query Status - All Confirmed', 'CONFIRMED', 1, 'Market Exchange', 'OASIS', 'Input List', 'Status');*/

	
	/*--SUBMITS
	INSERT_DATA_EXCHANGE_ACTION('Bid Offer', 'Submit Purchase Request', FALSE);
	INSERT_DATA_EXCHANGE_ACTION('Bid Offer', 'Confirm Purchase', FALSE);
	INSERT_DATA_EXCHANGE_ACTION('Bid Offer', 'Withdraw Purchase', FALSE);
	

	--QUERIES
	INSERT_DATA_EXCHANGE_ACTION('Data Exchange', 'Query Status', FALSE);
	INSERT_DATA_EXCHANGE_ACTION('Data Exchange', 'Query List', FALSE);
    INSERT_DATA_EXCHANGE_ACTION('Data Exchange', 'Download TSIN Data', FALSE);*/


	--IMPORTS
--These were never actually implemented, and are not really needed.
--	INSERT_DATA_EXCHANGE_ACTION('Data Exchange', 'File Import: Status', TRUE);
--	INSERT_DATA_EXCHANGE_ACTION('Data Exchange', 'File Import: List', TRUE);

END;
/

-- save changes to database
COMMIT;
SET DEFINE ON	
