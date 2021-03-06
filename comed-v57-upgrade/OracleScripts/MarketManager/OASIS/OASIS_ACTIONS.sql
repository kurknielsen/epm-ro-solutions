
SET DEFINE OFF	

-- Ignore &'s in data; otherwise it will assume word after & is a substitution variable and prompt for a value	
-- Uncomment the following line if you wish to completely eliminate previous entries and start from scratch w/ delivered entries

DECLARE
	v_USER_ROLE_ID NUMBER(9);
	v_PUSER_ROLE_ID NUMBER (9);
	v_STATUS NUMBER;
	
	TYPE MARKET_T IS RECORD (
		MARKET_NAME VARCHAR2(10), 
		PACKAGE_NAME VARCHAR2(32), 
		HAS_EXCHANGE_LIST_PROC NUMBER(1),
		HAS_SUBMIT_LIST_PROC NUMBER(1)
		);
	
	c_OASIS MARKET_T;
		
	--Action Types
	c_DE CONSTANT VARCHAR2(20) := 'Data Exchange';
	c_BO CONSTANT VARCHAR2(20) := 'Bid Offer';
------------------------------------
	PROCEDURE INIT_MARKET
		(
		p_MARKET IN OUT MARKET_T,
		p_MARKET_NAME IN VARCHAR2,
		p_PACKAGE_NAME IN VARCHAR2,
		p_HAS_EXCHANGE_LIST_PROC IN NUMBER,
		p_HAS_SUBMIT_LIST_PROC IN NUMBER
		) AS
	BEGIN
		p_MARKET.MARKET_NAME := p_MARKET_NAME;
		p_MARKET.PACKAGE_NAME := p_PACKAGE_NAME;
		p_MARKET.HAS_EXCHANGE_LIST_PROC := p_HAS_EXCHANGE_LIST_PROC;
		p_MARKET.HAS_SUBMIT_LIST_PROC := p_HAS_SUBMIT_LIST_PROC;
	END INIT_MARKET;
------------------------------------
	PROCEDURE PUT_ACTION
		(
		p_MARKET IN MARKET_T,
		p_EXCHANGE_CATEGORY IN VARCHAR2,
		p_EXCHANGE_NAME IN VARCHAR2,
		p_DISABLE_ACTION IN BOOLEAN := FALSE,
		p_OVERRIDE_EXCHANGE_TYPE IN VARCHAR2 := NULL
		) AS

		v_ACTION_NAME   SYSTEM_ACTION.ACTION_NAME%TYPE;
		v_DISPLAY_NAME  SYSTEM_ACTION.DISPLAY_NAME%TYPE;
		v_MKT           VARCHAR2(10);
		v_ACTION_TYPE   VARCHAR2(32);
		v_MAIN_PROC     VARCHAR2(256);
		v_IMPORT_TYPE   SYSTEM_ACTION.IMPORT_TYPE%TYPE;
		v_EXCHANGE_TYPE SYSTEM_ACTION.EXCHANGE_TYPE%TYPE;
		v_ID            NUMBER;
		v_ACTION_ALREADY_EXISTED BOOLEAN := TRUE;
        v_LIST_PROC VARCHAR2(100) := NULL;
		
	
	 BEGIN
	 	--Set the Name and Display Name for the Action       
        v_ACTION_NAME := 'Sched:' || CASE WHEN p_MARKET.MARKET_NAME IS NULL THEN '' ELSE p_MARKET.MARKET_NAME || ':' END || p_EXCHANGE_NAME;
		v_DISPLAY_NAME := CASE WHEN p_MARKET.MARKET_NAME IS NULL THEN '' ELSE p_MARKET.MARKET_NAME || ': ' END || p_EXCHANGE_NAME ;
		
		--Set the Action Type to Data Exchange dialog.
		v_ACTION_TYPE := p_EXCHANGE_CATEGORY;

		--Set up the main Stored Procedure.
        v_MAIN_PROC := p_MARKET.PACKAGE_NAME || '.' || CASE p_EXCHANGE_CATEGORY
				WHEN c_DE THEN 'MARKET_EXCHANGE'
				WHEN c_BO THEN 'MARKET_SUBMIT'
				END || ';EXCHANGE_TYPE="' || p_EXCHANGE_NAME || '"';
		
        v_IMPORT_TYPE := NULL;
        v_EXCHANGE_TYPE := v_MAIN_PROC;
        
        IF p_EXCHANGE_CATEGORY = c_BO THEN
            v_LIST_PROC := CASE WHEN p_MARKET.HAS_SUBMIT_LIST_PROC= 1 THEN
						p_MARKET.PACKAGE_NAME || '.' || 'MARKET_SUBMIT_TRANSACTION_LIST' || ';EXCHANGE_TYPE="' || p_EXCHANGE_NAME || '"'
					    ELSE NULL END;
        ELSE
			v_LIST_PROC := CASE WHEN p_MARKET.HAS_EXCHANGE_LIST_PROC = 1 THEN 
						p_MARKET.PACKAGE_NAME || '.' || 'MARKET_EXCHANGE_ENTITY_LIST' || ';EXCHANGE_TYPE="' || p_EXCHANGE_NAME || '"'
					ELSE NULL END;
        END IF;
        
		--Get the ID for the Action, and set a flag to remember whether it already existed.
		v_ID := ID.ID_FOR_SYSTEM_ACTION(v_ACTION_NAME);
		IF v_ID <= 0 THEN
			v_ACTION_ALREADY_EXISTED := FALSE;
			v_ID := 0;
		ELSE
			v_ACTION_ALREADY_EXISTED := TRUE;
		END IF;
				
		--Insert/Update the System Action.
		IO.PUT_SYSTEM_ACTION(v_ID,	-- o_OID
			v_ACTION_NAME,      -- p_ACTION_NAME
			NULL,               -- p_ACTION_ALIAS
			v_ACTION_NAME,      -- p_ACTION_DESC
			v_ID,               -- p_ACTION_ID
			0,                  -- p_ENTITY_DOMAIN_ID
			'Scheduling',       -- p_MODULE
			v_ACTION_TYPE,      -- p_ACTION_TYPE
			v_DISPLAY_NAME,     -- p_DISPLAY_NAME
			v_IMPORT_TYPE,      -- p_IMPORT_TYPE
			NULL,               -- p_EXPORT_TYPE
			v_EXCHANGE_TYPE,    -- p_EXCHANGE_TYPE
			NULL,               -- p_IMPORT_FILE
			NULL,               -- p_EXPORT_FILE
			NULL,               -- p_WARNING_PROC
			v_LIST_PROC);       -- p_ENTITY_LIST
			
		IF v_ID < 0 THEN
			ROLLBACK;
			RAISE_APPLICATION_ERROR(-20010, 'Failed to create action ' || v_ACTION_NAME || ' with status = ' || v_ID);
		END IF;

		--Add the 'User' and 'Power-User' roles to it if it did not already exist.
		--If it did already exist, we want to leave the roles alone.
		IF NOT v_ACTION_ALREADY_EXISTED AND NOT p_DISABLE_ACTION THEN
			EM.PUT_SYSTEM_ACTION_ROLE(v_ID, v_USER_ROLE_ID, 1, 0, 0, 0, 0, v_STATUS);
			EM.PUT_SYSTEM_ACTION_ROLE(v_ID, v_PUSER_ROLE_ID, 1, 0, 0, 0, 0, v_STATUS);
		END IF;
				
	END PUT_ACTION;

BEGIN

    -- Bootstrap the current user role so that the all the data scripts succeed
    SECURITY_CONTROLS.SET_CURRENT_ROLES(ID_TABLE(ID_TYPE(SECURITY_CONTROLS.g_SUPER_USER_ROLE_ID)));


	--Initialize OASIS Market and Package names
	INIT_MARKET(c_OASIS, 'OASIS', 'MM_OASIS', 1, 1);
	
	SELECT ROLE_ID INTO v_USER_ROLE_ID FROM APPLICATION_ROLE WHERE ROLE_NAME = 'User';
	SELECT ROLE_ID INTO v_PUSER_ROLE_ID FROM APPLICATION_ROLE WHERE ROLE_NAME = 'Power-User';

	--QUERIES
	PUT_ACTION(c_OASIS, c_DE, MM_OASIS.g_ACTION_QUE_LIST);
    PUT_ACTION(c_OASIS, c_DE, MM_OASIS.g_ACTION_QUE_TRANSSTATUS);
    
    --SUBMITS
    PUT_ACTION(c_OASIS, c_BO, MM_OASIS.g_ACTION_SUB_TRANSREQUEST);
    PUT_ACTION(c_OASIS, c_BO, MM_OASIS.g_ACTION_SUB_TRANSCUST_CONF);
    PUT_ACTION(c_OASIS, c_BO, MM_OASIS.g_ACTION_SUB_TRANSCUST_WITH);

	
END;
/

-- save changes to database
COMMIT;
SET DEFINE ON	
--Reset
