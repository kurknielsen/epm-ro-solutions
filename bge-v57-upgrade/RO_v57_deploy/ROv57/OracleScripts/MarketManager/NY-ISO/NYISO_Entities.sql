/*
  Creates bid/offer types, commodities, schedule coordinators, and resource traits
  specific to NYISO.
*/
DECLARE
	scOID       NUMBER;
	id          NUMBER;
	status      NUMBER;
	v_tg		TRANSACTION_TRAIT_GROUP%ROWTYPE;
	v_name		VARCHAR2(32);
	v_STATUS 	NUMBER;
	
	TYPE t_ARRAY IS VARRAY(32) OF VARCHAR2(32);
	commodities      t_array := t_array('DAM Energy', 'HAM Energy');
	marketTypes      t_array := t_array('Day-ahead', 'Real-time');
	bidOfferTypes    t_array := t_array('Normal');

-- jbc, 28.oct.2008: unused
/*
	genTraits  t_array := t_array('Upper Operating Limit=401',
							'Emergency Operating Limit=402',
							'Startup cost=403',
							'Bid Schedule Type ID=404',
							'Self Committed MW 00=405',
							'Self Committed MW 15=406',
							'Self Committed MW 30=407',
							'Self Committed MW 45=408',
							'Fixed Min. Generation MW=409',
							'Fixed Min. Generation Cost=410',
							'Dispatch MW=411',
							'10 min Non-sync Cost=412',
							'10 min Spinning Cost=413',
							'30 min Non-sync Cost=414',
							'30 min Spinning Cost=415',
							'Regulation MW=416',
							'Regulation Cost=417',
                            'Generation Bid ID=418');
*/							
	loadTraits t_array := t_array('Forecast MW=419',
							'Fixed MW=420',
							'Price Cap #1=421', -- MW, $/MW pair
							'Price Cap #2=422', -- MW, $/MW pair
							'Price Cap #3=423', -- MW, $/MW pair
							'Int Type=424',
							'Int Fixed=425', -- MW, $/MW pair
							'Int Cap=426', -- MW, $/MW pair
                            'Load Bid ID=427');
							
-- jbc, 28.oct.2008: unused
/*
	xnTraits t_array := t_array('Bid Energy=428',
							'Sink Price Cap=429',
							'Decremental Value=430',
							'Minimum Runtime=431',
							'HAM Bid Price=432',
							'Transaction Bid ID=433');
*/	
	virTraits t_array := t_array(
							'Price Cap #1=421', -- MW, $/MW pair
							'Price Cap #2=422', -- MW, $/MW pair
							'Price Cap #3=423', -- MW, $/MW pair
                            'Load Bid ID=427');
	traits t_array;
  
BEGIN
    -- add NYISO schedule coordinator
    IO.PUT_SC(o_OID                         => scOID,
                        p_SC_NAME                     => 'NYISO', 
                        p_SC_ALIAS                    => 'NYISO', 
                        p_SC_DESC                     => NULL,
                        p_SC_ID                       => 0,
                        p_SC_NERC_CODE                => NULL,
                        p_SC_DUNS_NUMBER              => NULL,
                        p_SC_STATUS                   => 'Active',
                        p_SC_EXTERNAL_IDENTIFIER      => 'NYISO', 
                        p_SC_SCHEDULE_NAME_PREFIX     => NULL, 
                        p_SC_SCHEDULE_FORMAT          => 'Service Point',
                        p_SC_SCHEDULE_INTERVAL        => 'Hour',
                        p_SC_LOAD_ROUNDING_PREFERENCE => NULL,
                        p_SC_LOSS_ROUNDING_PREFERENCE => NULL,
                        p_SC_CREATE_TX_LOSS_SCHEDULE  => NULL,
                        p_SC_CREATE_DX_LOSS_SCHEDULE  => NULL,
                        p_SC_CREATE_UFE_SCHEDULE      => NULL,
                        p_SC_MARKET_PRICE_ID          => NULL,
                        p_SC_MINIMUM_SCHEDULE_AMT     => NULL);
    
    IF scOID = ga.DUPLICATE_ENTITY THEN
        SELECT SC.SC_ID INTO scOID FROM SC WHERE SC.SC_NAME = 'NYISO'; 
    END IF;

/*
    -- add traits and trait groups
    FOR I IN 1 .. 2 LOOP
        CASE
            WHEN i = 1 THEN
                traits := loadTraits;
            WHEN i = 2 THEN
                traits := virTraits;
            --WHEN i = 3 THEN
            --	traits := xnTraits;
            --WHEN i = 4 THEN
            --	traits := genTraits;
        END CASE;
            
        FOR j IN 1 .. traits.COUNT LOOP
            v_TG.TRAIT_GROUP_ID := TO_NUMBER(SUBSTR(traits(j), instr(traits(j),'=')+1));
            v_NAME := SUBSTR(traits(j), 1, instr(traits(j),'=') - 1);

            v_TG.TRAIT_GROUP_INTERVAL := 'Hour';
            v_TG.SC_ID := scOID;
            v_TG.IS_SERIES := 0;
            v_TG.IS_SPARSE := 0;
            v_TG.IS_STATEMENT_TYPE_SPECIFIC := 0;
            v_TG.DEFAULT_NUMBER_OF_SETS := 0;

            v_TG.TRAIT_GROUP_NAME := 'NYISO ' || v_NAME;
            v_TG.DISPLAY_NAME := 'NYISO';
            v_TG.TRAIT_GROUP_TYPE := 'Detail';
            v_TG.DISPLAY_ORDER := 0;
            v_TG.TRAIT_CATEGORY := '%'; 
            
            
            TG.UPSERT_TRAIT_GROUP(v_TG);
            EM.PUT_TRANSACTION_TRAIT(v_TG.TRAIT_GROUP_ID, 1, 0, CASE WHEN v_NAME LIKE '%Bid ID' THEN 'Bid ID' ELSE v_NAME END,
                    1, 'Number', NULL, NULL, NULL, NULL, v_STATUS);

        END LOOP;
	END LOOP;
*/

	-- add commodities
	FOR i IN 1 .. commodities.COUNT LOOP
		IO.PUT_IT_COMMODITY(o_OID                    => id,
					p_COMMODITY_NAME         => commodities(i),
					p_COMMODITY_ALIAS        => commodities(i),
					p_COMMODITY_DESC         => NULL,
					p_COMMODITY_ID           => 0,
					p_COMMODITY_TYPE         => 'Energy',
					p_COMMODITY_UNIT         => 'MWh',
					p_COMMODITY_UNIT_FORMAT  => NULL,
					p_COMMODITY_PRICE_UNIT   => 'Dollars',
					p_COMMODITY_PRICE_FORMAT => NULL,
					p_IS_VIRTUAL             => 0,
					p_MARKET_TYPE            => marketTypes(i));
	END LOOP;


	COMMIT;
END;
/
