CREATE OR REPLACE PACKAGE BODY MM_SEM_PIR_IMPORT IS

----------------------------------------------------------------------------
FUNCTION GET_INTERCONNECTOR_NAME RETURN VARCHAR2 IS
    v_SERV_PT      SERVICE_POINT.SERVICE_POINT_ID%TYPE;
    v_SERV_PT_NAME SERVICE_POINT.SERVICE_POINT_NAME%TYPE;
BEGIN
    SELECT OWNER_ENTITY_ID
    INTO v_SERV_PT
    FROM TEMPORAL_ENTITY_ATTRIBUTE
    WHERE ATTRIBUTE_ID = (SELECT ATTRIBUTE_ID
                          FROM ENTITY_ATTRIBUTE
                          WHERE ENTITY_DOMAIN_ID =
                                (SELECT ENTITY_DOMAIN_ID
                                 FROM ENTITY_DOMAIN
                                 WHERE ENTITY_DOMAIN_NAME = 'Service Point')
                          AND ATTRIBUTE_NAME = 'Resource Type')
    AND ATTRIBUTE_VAL = 'I';
    v_SERV_PT_NAME := EI.GET_ENTITY_NAME(EC.ED_SERVICE_POINT, v_SERV_PT);

    RETURN v_SERV_PT_NAME;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN v_SERV_PT_NAME;
END GET_INTERCONNECTOR_NAME;
----------------------------------------------------------------------------
FUNCTION GET_MKT_SCHED_TXN_TYPE
(
    p_RESOURCE_NAME IN VARCHAR2,
    p_DATE          IN DATE,
	p_LOGGER IN OUT NOCOPY MM_LOGGER_ADAPTER
) RETURN VARCHAR2 IS

    v_SERVICE_POINT_ID NUMBER;
    v_RO_RESOURCE_TYPE TEMPORAL_ENTITY_ATTRIBUTE.ATTRIBUTE_VAL%TYPE;
BEGIN
    SELECT SERVICE_POINT_ID
    INTO v_SERVICE_POINT_ID
    FROM SERVICE_POINT
    WHERE SERVICE_POINT_NAME = p_RESOURCE_NAME;

	v_RO_RESOURCE_TYPE := RO.GET_ENTITY_ATTRIBUTE('Resource Type', EC.ED_SERVICE_POINT, v_SERVICE_POINT_ID, TRUNC(p_DATE));

	IF v_RO_RESOURCE_TYPE IS NOT NULL THEN
        IF UPPER(v_RO_RESOURCE_TYPE) IN ('PPMG', 'PPTG','VPMG', 'VPTG', 'APTG') THEN
            RETURN 'Generation';
        ELSIF UPPER(v_RO_RESOURCE_TYPE) IN ('DU', 'SU') THEN
            RETURN 'Load';
		ELSE
			p_LOGGER.LOG_ERROR('The Resource Type ' || v_RO_RESOURCE_TYPE || ' for ' || p_RESOURCE_NAME
			|| ' unit does not match the expected value for a Market Schedule transaction.');
        	RETURN NULL;
		END IF;
	ELSE
		--if no entity attribute associated with the service point then
		--figure out from the name
		p_LOGGER.LOG_ERROR('No Resource Type Entity Attribute associated with: ' || p_RESOURCE_NAME || ' for date ' || to_char(p_DATE, 'YYYY-MM-DD HH24:MI'));
		IF UPPER(SUBSTR(p_RESOURCE_NAME,1,2)) = 'GU' THEN --service points with GU_xxxx name
			RETURN 'Generation';
		ELSIF INSTR(p_RESOURCE_NAME,'SU') > 0 THEN ---service points with SU_xxxx or DSU_xxxx name
			RETURN 'Load';
		ELSE
			p_LOGGER.LOG_ERROR('Incorrect service point name ' || p_RESOURCE_NAME
			||  ' for a Market Schedule transaction.');
        	RETURN NULL;
		END IF;
	END IF;

END GET_MKT_SCHED_TXN_TYPE;
-----------------------------------------------------------------------------
FUNCTION GET_STATEMENT_TYPE(p_PIR_STATEMENT_ID IN STATEMENT_TYPE.STATEMENT_TYPE_ID%TYPE)
    RETURN NUMBER IS

	-- 2-apr-2008, jbc:
	-- updated this function to support creation of SMO resettlement statement types. Also
	-- added external identifier for User Nominations, since we need that for Moyle transactions
	-- to show up correctly in the schedule tree.
    v_NEW_STATEMENT_NAME        STATEMENT_TYPE.STATEMENT_TYPE_NAME%TYPE;
    v_NEW_STATEMENT_EXT_IDENT_NAME        STATEMENT_TYPE.STATEMENT_TYPE_NAME%TYPE;
	v_PIR_STATEMENT_NAME		STATEMENT_TYPE.STATEMENT_TYPE_NAME%TYPE;
    v_IDs                       NUMBER_COLLECTION;
    v_STATEMENT_TYPE_ORDER      STATEMENT_TYPE.STATEMENT_TYPE_ORDER%TYPE;
    v_STATEMENT_TYPE_ID         STATEMENT_TYPE.STATEMENT_TYPE_ID%TYPE := 0;

BEGIN

	--look up the statement type - this will be something like F, P, or F(1)
    v_PIR_STATEMENT_NAME := EI.GET_ENTITY_IDENTIFIER_EXTSYS(EC.ED_STATEMENT_TYPE,
                                                            p_PIR_STATEMENT_ID,
                                                            EC.ES_SEM,
                                                            MM_SEM_UTIL.g_STATEMENT_TYPE_SETTLEMENT);

	-- add 'SMO' to the name, and see if we can find it
	v_NEW_STATEMENT_EXT_IDENT_NAME := 'SMO ' || v_PIR_STATEMENT_NAME;
    v_IDs := EI.GET_IDs_FROM_IDENTIFIER_EXTSYS(v_NEW_STATEMENT_EXT_IDENT_NAME,
                                               EC.ED_STATEMENT_TYPE,
                                               EC.ES_SEM,
                                               MM_SEM_UTIL.g_STATEMENT_TYPE_SETTLEMENT);

    IF v_IDs.COUNT = 0 THEN
		-- increment the current maximum statement order and use that for the new type
		-- 27.apr-2009, jbc: we are going to assume that SMO P and F have already been created,
		-- so we're going to make this revision be the same "distance" from SMO F as this
		-- revision is from F (this is similar to what we do in MM_SEM_UTIL.DETERMINE_STATEMENT_TYPE)
		SELECT S.STATEMENT_TYPE_ORDER + TO_NUMBER(REGEXP_SUBSTR(v_PIR_STATEMENT_NAME, '[0-9]+'))
		INTO   v_STATEMENT_TYPE_ORDER
		FROM   STATEMENT_TYPE S, EXTERNAL_SYSTEM_IDENTIFIER E
		WHERE  E.ENTITY_ID = S.STATEMENT_TYPE_ID
			   AND E.IDENTIFIER_TYPE = MM_SEM_UTIL.g_STATEMENT_TYPE_SETTLEMENT
			   AND E.EXTERNAL_IDENTIFIER = 'SMO F';

		v_NEW_STATEMENT_NAME := 'SMO ' || EI.GET_ENTITY_NAME(EC.ED_STATEMENT_TYPE, p_PIR_STATEMENT_ID);
        -- Create Statement type
        IO.PUT_STATEMENT_TYPE(v_STATEMENT_TYPE_ID,
                              v_NEW_STATEMENT_NAME,
                              v_NEW_STATEMENT_NAME,
                              v_NEW_STATEMENT_NAME,
                              0,
                              v_STATEMENT_TYPE_ORDER);

        IF v_STATEMENT_TYPE_ID < 0 THEN
            RAISE_APPLICATION_ERROR(-20000,
                                    'Failed to create statement type for code ''' ||
                                    v_NEW_STATEMENT_NAME || ''' (status = ' ||
                                    v_STATEMENT_TYPE_ID || ')');
        ELSE
			-- Add external identifier
			EI.PUT_EXTERNAL_SYSTEM_IDENTIFIER(EC.ES_SEM,
											  EC.ED_STATEMENT_TYPE,
											  v_STATEMENT_TYPE_ID,
											  v_NEW_STATEMENT_EXT_IDENT_NAME,
											  MM_SEM_UTIL.g_STATEMENT_TYPE_SETTLEMENT);

			--add an additional external identifier, 'Market Schedules'
			--in order to make visible the associated schedules in Schedule Tree tab
			EI.PUT_EXTERNAL_SYSTEM_IDENTIFIER(EC.ES_SEM,
											  EC.ED_STATEMENT_TYPE,
											  v_STATEMENT_TYPE_ID,
											  v_NEW_STATEMENT_NAME,
											  MM_SEM_UTIL.g_STATEMENT_TYPE_MKT_SCHED);

			-- nomination transactions in the schedule tree look at the User Nominations identifier type
			EI.PUT_EXTERNAL_SYSTEM_IDENTIFIER(EC.ES_SEM,
											  EC.ED_STATEMENT_TYPE,
											  v_STATEMENT_TYPE_ID,
											  v_NEW_STATEMENT_NAME,
											  MM_SEM_UTIL.g_STATEMENT_TYPE_USER_NOMS);

			RETURN v_STATEMENT_TYPE_ID;
		END IF;
    ELSE
        RETURN v_IDs(v_IDs.FIRST);
    END IF;


END GET_STATEMENT_TYPE;
----------------------------------------------------------------------------
PROCEDURE PUT_DETAIL_PIR(
   p_STATEMENT_ID   IN SEM_MP_STATEMENT.STATEMENT_ID%TYPE,
   p_STATEMENT_TYPE IN SEM_MP_STATEMENT.STATEMENT_TYPE%TYPE,
   p_ENTITY_ID      IN SEM_MP_STATEMENT.ENTITY_ID%TYPE,
   p_LOGGER         IN OUT NOCOPY MM_LOGGER_ADAPTER)
IS

    TYPE ARRAY IS VARRAY(16) OF VARCHAR2(100);
    v_PIR_VARIABLES ARRAY := ARRAY('MG, Metered Generation',
                                   'MGIU, Metered Generation',
                                   'MGIUG, Metered Generation',
                                   'MD, Metered Demand',
                                   'NDLF, Net Demand',
                                   'NDLFESU, Loss Adjusted Net Demand ESU',
                                   'MSQ, Market Schedule Quantity',
                                   'MSQIU, Market Schedule Quantity',
                                   'MSQIUG, Market Schedule Quantity',
                                   'DQ, Dispatch Quantity',
                                   'DQIU, Dispatch Quantity',
                                   'DQIUG, Dispatch Quantity',
                                   'NIJ, Net Inter-jurisdictional Import',
                                   'EA, Eligible Availability',
                                   'EAIU, Eligible Availability',
								   'EAIUG, Eligible Availability');

    CURSOR c_PIR_DETAIL(v_VARIABLE_TYPE IN VARCHAR2) IS
      SELECT *
        FROM SEM_MP_INFO
       WHERE STATEMENT_ID = p_STATEMENT_ID
         AND VARIABLE_TYPE = v_VARIABLE_TYPE
       ORDER BY CHARGE_DATE;

    v_TRANSACTION_TYPE INTERCHANGE_TRANSACTION.TRANSACTION_TYPE%TYPE;
    v_COMMODITY_NAME   IT_COMMODITY.COMMODITY_NAME%TYPE;
    v_SERV_PT_NAME     SERVICE_POINT.SERVICE_POINT_NAME%TYPE;
    v_TXN_ID           INTERCHANGE_TRANSACTION.TRANSACTION_ID%TYPE;
    v_TXN_NAME         INTERCHANGE_TRANSACTION.TRANSACTION_NAME%TYPE;
    v_TXN_IDENT        INTERCHANGE_TRANSACTION.TRANSACTION_IDENTIFIER%TYPE;
    v_VAR_SHORT_NAME   VARCHAR2(15);
    v_VAR_DESCRIPTION  VARCHAR2(64);
    v_STATEMENT_TYPE   STATEMENT_TYPE.STATEMENT_TYPE_ID%TYPE;
    v_STATUS           NUMBER;
    v_MARKET           SEM_SETTLEMENT_ENTITY.MARKET_NAME%TYPE := NULL;
    v_AGREEMENT_TYPE   INTERCHANGE_TRANSACTION.TRANSACTION_TYPE%TYPE;

  PROCEDURE GET_DEFAULT_TXN_IDENT
    (
    p_VAR_SHORT_NAME IN VARCHAR2,
    p_VAR_DESCRIPTION IN VARCHAR2,
    p_SERV_PT_NAME IN VARCHAR2,
    p_AGREEMENT_TYPE IN VARCHAR2,
    p_TXN_NAME OUT VARCHAR2,
    p_TXN_IDENT OUT VARCHAR2
    ) AS
  BEGIN
    p_TXN_NAME  := 'SEM:' || p_VAR_DESCRIPTION || ':' ||  p_SERV_PT_NAME
                   || CASE WHEN p_AGREEMENT_TYPE IS NULL THEN '' ELSE ':' || p_AGREEMENT_TYPE END;
    p_TXN_IDENT := p_VAR_SHORT_NAME || ':' || p_SERV_PT_NAME
                   || CASE WHEN p_AGREEMENT_TYPE IS NULL THEN '' ELSE ':' || p_AGREEMENT_TYPE END;
  END;
BEGIN

  p_LOGGER.EXCHANGE_NAME := 'Process Statement ID: ' || p_STATEMENT_ID ||
  ', having Statement Type of: ' || p_STATEMENT_TYPE;

  --look up the statement_type for 'SMO Indicative' / 'SMO Initial'
  v_STATEMENT_TYPE := GET_STATEMENT_TYPE(p_STATEMENT_TYPE);

  -- Look up the market for based on the statement being processed.
  BEGIN

    SELECT SSE.MARKET_NAME
      INTO v_MARKET
      FROM SEM_SETTLEMENT_ENTITY SSE
     WHERE SSE.SETTLEMENT_PSE_ID = p_ENTITY_ID;

    EXCEPTION
      WHEN no_data_found THEN
         -- default to NULL
         v_MARKET := NULL;
  END;

    FOR I IN v_PIR_VARIABLES.FIRST .. v_PIR_VARIABLES.LAST LOOP
        v_VAR_SHORT_NAME  := SUBSTR(v_PIR_VARIABLES(I),1, INSTR(v_PIR_VARIABLES(I), ',') - 1);
        v_VAR_DESCRIPTION := SUBSTR(v_PIR_VARIABLES(I), INSTR(v_PIR_VARIABLES(I), ',') + 1);

    FOR v_PIR_DETAIL IN c_PIR_DETAIL(v_VAR_SHORT_NAME) LOOP
            v_AGREEMENT_TYPE := NULL;
      --Define the transaction for each PIR determinant
            IF v_VAR_SHORT_NAME = 'MG' THEN
                v_TRANSACTION_TYPE := MM_SEM_UTIL.c_TXN_TYPE_GENERATION;
                v_COMMODITY_NAME   := MM_SEM_UTIL.c_COMMODITY_POWER;
                v_SERV_PT_NAME     := v_PIR_DETAIL.RESOURCE_NAME;
                GET_DEFAULT_TXN_IDENT(v_VAR_SHORT_NAME,v_VAR_DESCRIPTION,v_SERV_PT_NAME,NULL,v_TXN_NAME,v_TXN_IDENT);
            ELSIF v_VAR_SHORT_NAME = 'MGIU' THEN
                v_TRANSACTION_TYPE := MM_SEM_UTIL.c_TXN_TYPE_GENERATION;
                v_COMMODITY_NAME   := MM_SEM_UTIL.c_COMMODITY_POWER;
                MM_SEM_UTIL.GET_GATE_INTERCONNECT(MM_SEM_UTIL.g_INTERCONNECT_I_NIMOYLE, v_AGREEMENT_TYPE,v_SERV_PT_NAME);
                GET_DEFAULT_TXN_IDENT(v_VAR_SHORT_NAME,v_VAR_DESCRIPTION,v_SERV_PT_NAME,NULL,v_TXN_NAME,v_TXN_IDENT);
            ELSIF v_VAR_SHORT_NAME = 'MGIUG' THEN
                v_TRANSACTION_TYPE := MM_SEM_UTIL.c_TXN_TYPE_GENERATION;
                v_COMMODITY_NAME   := MM_SEM_UTIL.c_COMMODITY_POWER;
                MM_SEM_UTIL.GET_GATE_INTERCONNECT(v_PIR_DETAIL.CONTRACT, v_AGREEMENT_TYPE,v_SERV_PT_NAME);
                GET_DEFAULT_TXN_IDENT(v_VAR_SHORT_NAME,v_VAR_DESCRIPTION,v_SERV_PT_NAME,v_AGREEMENT_TYPE,v_TXN_NAME,v_TXN_IDENT);
            ELSIF v_VAR_SHORT_NAME = 'MD' THEN
                v_TRANSACTION_TYPE := 'Load';
                v_COMMODITY_NAME   := MM_SEM_UTIL.c_COMMODITY_POWER;
                v_SERV_PT_NAME     := v_PIR_DETAIL.RESOURCE_NAME;
                GET_DEFAULT_TXN_IDENT(v_VAR_SHORT_NAME,v_VAR_DESCRIPTION,v_SERV_PT_NAME,NULL,v_TXN_NAME,v_TXN_IDENT);
            ELSIF v_VAR_SHORT_NAME IN ('NDLF', 'NDLFESU') THEN
              v_TRANSACTION_TYPE := 'Net Demand'||CASE v_MARKET
                                                         WHEN 'CA' THEN
                                                            ' CA'
                                                         WHEN 'MO' THEN
                                                            ' VMOC'
                                                         ELSE
                                                            NULL
                                                      END;
            	v_COMMODITY_NAME   := MM_SEM_UTIL.c_COMMODITY_ENERGY;
            	v_SERV_PT_NAME     := v_PIR_DETAIL.RESOURCE_NAME;
            	v_TXN_NAME := 'SEM:' || v_TRANSACTION_TYPE || ':' || v_SERV_PT_NAME;
              v_TXN_IDENT := v_VAR_SHORT_NAME||CASE v_MARKET
                                                           WHEN 'CA' THEN
                                                              '_CA'
                                                           WHEN 'MO' THEN
                                                              '_VMOC'
                                                           ELSE
                                                              NULL
                                                        END;
				v_TXN_IDENT := v_TXN_IDENT || ':' || v_SERV_PT_NAME;
            ELSIF v_VAR_SHORT_NAME = 'MSQ' THEN
            	v_SERV_PT_NAME := v_PIR_DETAIL.RESOURCE_NAME;
				--These are Generation or Load type transactions
            	v_TRANSACTION_TYPE := GET_MKT_SCHED_TXN_TYPE(v_SERV_PT_NAME, v_PIR_DETAIL.CHARGE_DATE,p_LOGGER)
                                        || CASE v_MARKET WHEN 'CA' THEN ' ' || 'CA' ELSE NULL END;
            	IF v_TRANSACTION_TYPE IS NULL THEN
            		p_LOGGER.LOG_ERROR('Failed to determine a transaction type for ('||v_VAR_SHORT_NAME ||', Resource Name:' || v_SERV_PT_NAME
            		||', Statement ID: '||p_STATEMENT_ID||', Statement type: '||p_STATEMENT_TYPE);
            	END IF;
            	v_COMMODITY_NAME   := MM_SEM_UTIL.c_COMMODITY_ENERGY;
            	v_TXN_NAME  := v_SERV_PT_NAME || ':Market Schedule' || CASE v_MARKET WHEN 'CA' THEN ' ' || 'CA' ELSE NULL END;
            	v_TXN_IDENT := NVL(v_VAR_SHORT_NAME || CASE v_MARKET WHEN 'CA' THEN '_CA' ELSE NULL END, 'Invalid txn. type') || ':' || v_SERV_PT_NAME;
				-- [BZ 30941] for MSQ, set the agreement type that will be used to lookup on the transaction to be EA
				v_AGREEMENT_TYPE := MM_SEM_UTIL.g_EXTID_MKT_SCHED_EA_ABR;
            ELSIF v_VAR_SHORT_NAME = 'MSQIU' THEN
            	v_TRANSACTION_TYPE := MM_SEM_UTIL.c_TXN_TYPE_NOMINATION || CASE v_MARKET WHEN 'CA' THEN ' ' || 'CA' ELSE NULL END;
            	v_COMMODITY_NAME   := MM_SEM_UTIL.c_COMMODITY_ENERGY;
            	MM_SEM_UTIL.GET_GATE_INTERCONNECT(MM_SEM_UTIL.g_INTERCONNECT_I_NIMOYLE, v_AGREEMENT_TYPE,v_SERV_PT_NAME);
            	v_TXN_NAME := v_SERV_PT_NAME||  ':Interconnector User Nomination' || CASE v_MARKET WHEN 'CA' THEN ' ' || 'CA' ELSE NULL END;
            	v_TXN_IDENT := NVL(v_VAR_SHORT_NAME || CASE v_MARKET WHEN 'CA' THEN '_CA' ELSE NULL END, 'Invalid txn. type') || ':' || v_SERV_PT_NAME;
            ELSIF v_VAR_SHORT_NAME = 'MSQIUG' THEN
            	v_TRANSACTION_TYPE := MM_SEM_UTIL.c_TXN_TYPE_NOMINATION || CASE v_MARKET WHEN 'CA' THEN ' ' || 'CA' ELSE NULL END;
            	v_COMMODITY_NAME   := MM_SEM_UTIL.c_COMMODITY_ENERGY;
            	MM_SEM_UTIL.GET_GATE_INTERCONNECT(v_PIR_DETAIL.CONTRACT, v_AGREEMENT_TYPE,v_SERV_PT_NAME);
            	v_TXN_NAME := v_SERV_PT_NAME||  ':Interconnector User Nomination' || CASE v_MARKET WHEN 'CA' THEN ' ' || 'CA' ELSE NULL END
                            || CASE WHEN v_AGREEMENT_TYPE IS NULL THEN '' ELSE ':' || v_AGREEMENT_TYPE END;
            	v_TXN_IDENT := NVL(v_VAR_SHORT_NAME || CASE v_MARKET WHEN 'CA' THEN '_CA' ELSE NULL END, 'Invalid txn. type') || ':' || v_SERV_PT_NAME
                            || CASE WHEN v_AGREEMENT_TYPE IS NULL THEN '' ELSE ':' || v_AGREEMENT_TYPE END;
            ELSIF v_VAR_SHORT_NAME = 'DQ' THEN
            	v_TRANSACTION_TYPE := MM_SEM_UTIL.c_TXN_TYPE_DISPATCH_INSTR;
            	v_COMMODITY_NAME   := MM_SEM_UTIL.c_COMMODITY_POWER;
            	v_SERV_PT_NAME     := v_PIR_DETAIL.RESOURCE_NAME;
            	GET_DEFAULT_TXN_IDENT(v_VAR_SHORT_NAME,v_VAR_DESCRIPTION,v_SERV_PT_NAME,NULL,v_TXN_NAME,v_TXN_IDENT);
            ELSIF v_VAR_SHORT_NAME = 'DQIU' THEN
            	v_TRANSACTION_TYPE := MM_SEM_UTIL.c_TXN_TYPE_DISPATCH_INSTR;
            	v_COMMODITY_NAME   := MM_SEM_UTIL.c_COMMODITY_POWER;
            	MM_SEM_UTIL.GET_GATE_INTERCONNECT(MM_SEM_UTIL.g_INTERCONNECT_I_NIMOYLE, v_AGREEMENT_TYPE,v_SERV_PT_NAME);
            	GET_DEFAULT_TXN_IDENT(v_VAR_SHORT_NAME,v_VAR_DESCRIPTION,v_SERV_PT_NAME,NULL,v_TXN_NAME,v_TXN_IDENT);
            ELSIF v_VAR_SHORT_NAME = 'DQIUG' THEN
            	v_TRANSACTION_TYPE := MM_SEM_UTIL.c_TXN_TYPE_DISPATCH_INSTR;
            	v_COMMODITY_NAME   := MM_SEM_UTIL.c_COMMODITY_POWER;
            	MM_SEM_UTIL.GET_GATE_INTERCONNECT(v_PIR_DETAIL.CONTRACT, v_AGREEMENT_TYPE,v_SERV_PT_NAME);
            	GET_DEFAULT_TXN_IDENT(v_VAR_SHORT_NAME,v_VAR_DESCRIPTION,v_SERV_PT_NAME,v_AGREEMENT_TYPE,v_TXN_NAME,v_TXN_IDENT);
            ELSIF v_VAR_SHORT_NAME = 'EA' THEN
            	v_TRANSACTION_TYPE := MM_SEM_UTIL.c_TXN_TYPE_ELIGIBLE_AVAIL;
            	v_COMMODITY_NAME   := MM_SEM_UTIL.c_COMMODITY_CAPACITY;
            	v_SERV_PT_NAME     := v_PIR_DETAIL.RESOURCE_NAME;
            	GET_DEFAULT_TXN_IDENT(v_VAR_SHORT_NAME,v_VAR_DESCRIPTION,v_SERV_PT_NAME,NULL,v_TXN_NAME,v_TXN_IDENT);
            ELSIF v_VAR_SHORT_NAME = 'EAIU' THEN
            	v_TRANSACTION_TYPE := MM_SEM_UTIL.c_TXN_TYPE_ELIGIBLE_AVAIL;
            	v_COMMODITY_NAME   := MM_SEM_UTIL.c_COMMODITY_CAPACITY;
            	MM_SEM_UTIL.GET_GATE_INTERCONNECT(MM_SEM_UTIL.g_INTERCONNECT_I_NIMOYLE, v_AGREEMENT_TYPE,v_SERV_PT_NAME);
            	GET_DEFAULT_TXN_IDENT(v_VAR_SHORT_NAME,v_VAR_DESCRIPTION,v_SERV_PT_NAME,NULL,v_TXN_NAME,v_TXN_IDENT);
            ELSIF v_VAR_SHORT_NAME = 'EAIUG' THEN
            	v_TRANSACTION_TYPE := MM_SEM_UTIL.c_TXN_TYPE_ELIGIBLE_AVAIL;
            	v_COMMODITY_NAME   := MM_SEM_UTIL.c_COMMODITY_CAPACITY;
            	MM_SEM_UTIL.GET_GATE_INTERCONNECT(v_PIR_DETAIL.CONTRACT, v_AGREEMENT_TYPE,v_SERV_PT_NAME);
            	GET_DEFAULT_TXN_IDENT(v_VAR_SHORT_NAME,v_VAR_DESCRIPTION,v_SERV_PT_NAME,v_AGREEMENT_TYPE,v_TXN_NAME,v_TXN_IDENT);
            ELSIF v_VAR_SHORT_NAME = 'NIJ' THEN
            	v_TRANSACTION_TYPE := 'NIJI';
            	v_COMMODITY_NAME   := MM_SEM_UTIL.c_COMMODITY_POWER;
            	--PIR does not provide resource name for NIJ variable
            	v_SERV_PT_NAME := CASE v_PIR_DETAIL.VARIABLE_NAME
            							WHEN 'NIJ_NI' THEN 'SU_500051'
            							ELSE 'SU_400040'
            					   END;
            	GET_DEFAULT_TXN_IDENT(v_VAR_SHORT_NAME,v_VAR_DESCRIPTION,v_SERV_PT_NAME,NULL,v_TXN_NAME,v_TXN_IDENT);
            END IF;

            v_TXN_ID := MM_SEM_UTIL.GET_TRANSACTION_ID(v_TRANSACTION_TYPE, v_SERV_PT_NAME, v_COMMODITY_NAME, v_AGREEMENT_TYPE);
            IF v_TXN_ID IS NULL THEN
				v_TXN_ID := MM_SEM_UTIL.GET_TRANSACTION_ID(p_TRANSACTION_TYPE    => v_TRANSACTION_TYPE,
														   p_RESOURCE_NAME       => v_SERV_PT_NAME,
														   p_CREATE_IF_NOT_FOUND => TRUE,
														   p_AGREEMENT_TYPE      => v_AGREEMENT_TYPE,
														   p_TRANSACTION_NAME    => v_TXN_NAME,
														   p_EXTERNAL_IDENTIFIER => v_TXN_IDENT,
														   p_ACCOUNT_NAME        => '%',
														   p_COMMODITY           => v_COMMODITY_NAME,
														   p_IS_BID_OFFER        => 0);
            END IF;

            IF v_TXN_ID <= 0 THEN
                p_LOGGER.LOG_ERROR('Failed to determine Transaction ID for ('||v_VAR_SHORT_NAME ||', '||v_VAR_DESCRIPTION||', Statement ID: '||p_STATEMENT_ID||', Statement type: '||p_STATEMENT_TYPE);
            ELSE
                ITJ.PUT_IT_SCHEDULE(p_TRANSACTION_ID => v_TXN_ID,
                                p_SCHEDULE_TYPE  => v_STATEMENT_TYPE,
                                p_SCHEDULE_STATE => GA.INTERNAL_STATE,
                                p_SCHEDULE_DATE  => v_PIR_DETAIL.CHARGE_DATE,
                                p_AS_OF_DATE     => LOW_DATE,
                                p_AMOUNT         => v_PIR_DETAIL.VALUE,
                                p_PRICE          => NULL,
                                p_STATUS         => v_STATUS);

            END IF;
        END LOOP; --FOR v_PIR_DETAIL IN c_PIR_DETAIL(v_VAR_SHORT_NAME) LOOP

    END LOOP; -- FOR I IN v_PIR_VARIABLES.FIRST .. v_PIR_VARIABLES.LAST LOOP

EXCEPTION
	WHEN OTHERS THEN
		p_LOGGER.LOG_ERROR('Error importing PIR determinant: '|| v_VAR_SHORT_NAME ||', Statement ID: '||p_STATEMENT_ID||', Statement type: '||p_STATEMENT_TYPE || ', ' || MM_SEM_UTIL.ERROR_STACKTRACE);

END PUT_DETAIL_PIR;

----------------------------------------------------------------------------
--import PIR data to internal transactions
PROCEDURE IMPORT_PIR(
   p_BEGIN_DATE IN DATE,
   p_END_DATE   IN DATE,
   p_LOG_TYPE   IN NUMBER,
   p_TRACE_ON   IN NUMBER,
   p_STATUS     OUT NUMBER,
   p_MESSAGE    OUT VARCHAR2)
IS

   CURSOR c_STATEMENT_RECS IS
      SELECT STATEMENT_ID,
             STATEMENT_TYPE,
             ENTITY_ID
        FROM SEM_MP_STATEMENT
       WHERE STATEMENT_DATE BETWEEN p_BEGIN_DATE AND p_END_DATE;

   v_LOGGER         MM_LOGGER_ADAPTER;
   v_DUMMY          VARCHAR2(512);

BEGIN
   v_LOGGER := MM_UTIL.GET_LOGGER(EC.ES_SEM,
                                  NULL,
                                  'Copy PIR data to int txns',
                                  'Copy PIR data to int txns',
                                  p_LOG_TYPE,
                                  p_TRACE_ON);
   MM_UTIL.START_EXCHANGE(FALSE, v_LOGGER);

   --Loop through all statement IDs for specified date range
   FOR v_STATEMENT_REC IN c_STATEMENT_RECS LOOP

      --for each statement id, extract all the records in the SEM_MP_INFO
      --and copy the data into appropiate transaction schedules
      PUT_DETAIL_PIR(v_STATEMENT_REC.STATEMENT_ID,
                     v_STATEMENT_REC.STATEMENT_TYPE,
                     v_STATEMENT_REC.ENTITY_ID,
                     v_LOGGER);
   END LOOP;

   P_STATUS  := GA.SUCCESS;
   P_MESSAGE := 'Copy PIR data to transactions complete.';
   MM_UTIL.STOP_EXCHANGE(V_LOGGER, P_STATUS, P_MESSAGE, P_MESSAGE);
   P_MESSAGE := P_MESSAGE || ' See event log for details.';

EXCEPTION
   WHEN OTHERS THEN
      P_STATUS  := SQLCODE;
      P_MESSAGE := MM_SEM_UTIL.ERROR_STACKTRACE;
      MM_UTIL.STOP_EXCHANGE(V_LOGGER, P_STATUS, P_MESSAGE, V_DUMMY);

END IMPORT_PIR;
-------------------------------------------------------------------------------
FUNCTION WHAT_VERSION RETURN VARCHAR IS
BEGIN
    RETURN '$Revision: 1.5 $';
END WHAT_VERSION;

--------------------------------------------------------------------------------
END MM_SEM_PIR_IMPORT;
/
