CREATE OR REPLACE PACKAGE SEM_REPORTS IS

  -- Author  : LDUMITRIU
  -- Created : 05/14/2007 12:48:04
  -- $Revision: 1.30 $

   TYPE REF_CURSOR IS REF CURSOR;
   c_COMMA  CONSTANT CHAR(1) := ',';
   c_EXT_ID_TYPE_CODE_PARTICIPANT CONSTANT EXTERNAL_SYSTEM_IDENTIFIER.IDENTIFIER_TYPE%TYPE := 'Code Participant';

 ----------------------------------------------------------------------------*/
 FUNCTION WHAT_VERSION RETURN VARCHAR;
 -----------------------------------------------------------------------------
   PROCEDURE INTERCONNECTOR_DETAILS
    (p_BEGIN_DATE                IN DATE,
     p_END_DATE                  IN DATE,
     p_TIME_ZONE                 IN VARCHAR2,
     p_POD_ID        			 IN VARCHAR2,
  	 p_PSE_ID 					 IN VARCHAR2,
	 p_RUN_TYPE					 IN VARCHAR2,
	 p_SHOW_ATC					 IN NUMBER,
	 p_SHOW_REV_ATC				 IN NUMBER,
	 p_SHOW_INDIC				 IN NUMBER,
	 p_SHOW_INIT				 IN NUMBER,
	 p_SHOW_NOMS				 IN NUMBER,
     p_STATUS                    OUT NUMBER,
     p_CURSOR                    IN OUT REF_CURSOR);
---------------------------------------
   PROCEDURE INTERCONNECTOR_NET_ACTUALS
    (p_BEGIN_DATE IN DATE,
    p_END_DATE    IN DATE,
    p_TIME_ZONE   IN VARCHAR2,
    p_PSE_ID      IN VARCHAR2,
    p_POD_ID      IN VARCHAR2,
    p_RUN_TYPE	  IN VARCHAR2,
    p_GATE_WINDOW IN VARCHAR2,
    p_STATUS      OUT NUMBER,
    p_CURSOR      IN OUT REF_CURSOR);
---------------------------------------
   PROCEDURE TRANS_ADJ_LOSS_FACTORS
    (p_MODEL_ID                  IN NUMBER,
     p_BEGIN_DATE                IN DATE,
     p_END_DATE                  IN DATE,
     p_TIME_ZONE                 IN VARCHAR2,
     p_PSE_ID                 IN VARCHAR2,
     p_SERVICE_POINT_ID        IN VARCHAR2,
     p_STATUS                    OUT NUMBER,
     p_CURSOR                    IN OUT REF_CURSOR);
---------------------------------------
   PROCEDURE DISPATCH_INSTR
    (p_REPORT_TYPE               IN VARCHAR2,
     p_BEGIN_DATE                IN DATE,
     p_END_DATE                  IN DATE,
     p_TIME_ZONE                 IN VARCHAR2,
     p_PSE_ID                    IN VARCHAR2,
     p_SERVICE_POINT_ID          IN VARCHAR2,
     p_STATUS                    OUT NUMBER,
     p_CURSOR                    IN OUT REF_CURSOR);
---------------------------------------
   PROCEDURE METER_DATA_SUMMARY
    (
     p_BEGIN_DATE                IN DATE,
     p_END_DATE                  IN DATE,
     p_TIME_ZONE                 IN VARCHAR2,
	 p_PERIODICITY				  IN VARCHAR2,
     p_STATUS                    OUT NUMBER,
     p_CURSOR                    IN OUT REF_CURSOR);
---------------------------------------
   PROCEDURE METER_DATA_DETAIL
    (
     p_BEGIN_DATE                IN DATE,
     p_END_DATE                  IN DATE,
     p_TIME_ZONE                 IN VARCHAR2,
	 p_PERIODICITY				  IN VARCHAR2,
	 p_POD_ID					 IN VARCHAR2,
     p_STATUS                    OUT NUMBER,
     p_CURSOR                    IN OUT REF_CURSOR);
---------------------------------------
   PROCEDURE OUTAGE_SCHEDULES
    (p_BEGIN_DATE                IN DATE,
     p_END_DATE                  IN DATE,
     p_TIME_ZONE                 IN VARCHAR2,
     p_REPORT_SOURCE             IN VARCHAR2,
     p_POD_ID        IN VARCHAR2,
     p_STATUS                    OUT NUMBER,
     p_CURSOR                    IN OUT REF_CURSOR)    ;
---------------------------------------
   PROCEDURE INTERCONNECTOR_CAP_HOLDINGS
    (p_BEGIN_DATE                IN DATE,
     p_END_DATE                  IN DATE,
     p_TIME_ZONE                 IN VARCHAR2,
     p_PSE_ID                  IN VARCHAR2,
     p_POD_ID					IN VARCHAR2,
	 p_PERIODICITY				IN VARCHAR2,
     p_STATUS                    OUT NUMBER,
     p_CURSOR                    IN OUT REF_CURSOR);
---------------------------------------
   PROCEDURE LOAD_FORECAST_ASSUMPTIONS
    (p_BEGIN_DATE                IN DATE,
     p_END_DATE                  IN DATE,
     p_TIME_ZONE                 IN VARCHAR2,
     p_JURISDICTIONS             IN VARCHAR2,
     p_PERIODICITY               IN VARCHAR2,
     p_STATUS                    OUT NUMBER,
     p_CURSOR                    IN OUT REF_CURSOR);
---------------------------------------
   PROCEDURE LOAD_FORECAST_SUMMARY
    (p_BEGIN_DATE                IN DATE,
     p_END_DATE                  IN DATE,
     p_TIME_ZONE                 IN VARCHAR2,
     p_JURISDICTIONS             IN VARCHAR2,
     p_STATUS                    OUT NUMBER,
     p_CURSOR                    IN OUT REF_CURSOR);
---------------------------------------
   PROCEDURE ACTUAL_LOAD_SUMMARY
    (p_BEGIN_DATE                IN DATE,
     p_END_DATE                  IN DATE,
     p_TIME_ZONE                 IN VARCHAR2,
     p_JURISDICTIONS             IN VARCHAR2,
     p_RUN_TYPE               IN VARCHAR2,
     p_STATUS                    OUT NUMBER,
     p_CURSOR                    IN OUT REF_CURSOR);
---------------------------------------
   PROCEDURE LOAD_ERROR_SUPPLY
    (p_BEGIN_DATE                IN DATE,
     p_END_DATE                  IN DATE,
     p_TIME_ZONE                 IN VARCHAR2,
     p_JURISDICTIONS             IN VARCHAR2,
     p_PERIODICITY               IN VARCHAR2,
     p_STATUS                    OUT NUMBER,
     p_CURSOR                    IN OUT REF_CURSOR);
---------------------------------------
   PROCEDURE WIND_GEN_FORECAST_BY_JURIS
    (p_BEGIN_DATE                IN DATE,
     p_END_DATE                  IN DATE,
     p_TIME_ZONE                 IN VARCHAR2,
     p_JURISDICTIONS             IN VARCHAR2,
     p_DAY_TYPE                  IN VARCHAR2,
     p_CURSOR                    IN OUT REF_CURSOR);
---------------------------------------
  PROCEDURE WIND_GEN_FORECAST
    (p_BEGIN_DATE                IN DATE,
     p_END_DATE                  IN DATE,
     p_TIME_ZONE                 IN VARCHAR2,
     p_JURISDICTIONS             IN VARCHAR2,
     p_PARTICIPANTS              IN VARCHAR2,
     p_DAY_TYPE                  IN VARCHAR2,         -- RSA -- 04/20/2007 -- (D+1)-(D+4) fix
     p_STATUS                    OUT NUMBER,
     p_CURSOR                    IN OUT REF_CURSOR);
---------------------------------------
  PROCEDURE NONWIND_GEN_FORECAST
    (p_BEGIN_DATE                IN DATE,
     p_END_DATE                  IN DATE,
     p_TIME_ZONE                 IN VARCHAR2,
     p_JURISDICTIONS             IN VARCHAR2,
     p_STATUS                    OUT NUMBER,
     p_CURSOR                    IN OUT REF_CURSOR);
---------------------------------------
   PROCEDURE LOSS_LOAD_PROB_FORECAST
    (p_MODEL_ID                  IN NUMBER,
     p_BEGIN_DATE                IN DATE,
     p_END_DATE                  IN DATE,
     p_TIME_ZONE                 IN VARCHAR2,
	 p_PERIODICITY               IN VARCHAR2,
     p_STATUS                    OUT NUMBER,
     p_CURSOR                    IN OUT REF_CURSOR);
---------------------------------------
   PROCEDURE INTERCONNECTOR_ERR_UNIT_BAL
    (p_MODEL_ID                  IN NUMBER,
     p_BEGIN_DATE                IN DATE,
     p_END_DATE                  IN DATE,
     p_TIME_ZONE                 IN VARCHAR2,
     p_SERVICE_POINT_NAME        IN VARCHAR2,
     p_STATUS                    OUT NUMBER,
     p_CURSOR                    IN OUT REF_CURSOR);
---------------------------------------
	PROCEDURE GET_INACTIVE_PSEs
	(
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	--p_REQ_TYPE IN VARCHAR2,
	p_STATUS OUT NUMBER,
	p_CURSOR OUT REF_CURSOR
	);
---------------------------------------
  PROCEDURE GET_MSP_CANCELLATIONS
  	(
    p_BEGIN_DATE IN DATE,
    p_END_DATE IN DATE,
    p_CURSOR IN OUT REF_CURSOR
     );
---------------------------------------
	PROCEDURE GET_PIR_REPORT
	(
	p_ENTITY_ID IN NUMBER,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_TIME_ZONE IN VARCHAR2,
	p_STATEMENT_TYPE IN NUMBER,
	p_RESOURCE_NAME IN VARCHAR2,
	p_VARIABLE_TYPE IN VARCHAR2,
	p_STATUS OUT NUMBER,
	p_CURSOR OUT REF_CURSOR
	);
---------------------------------------
	PROCEDURE GET_RAR_REPORT
	(
	p_ENTITY_ID IN NUMBER,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_TIME_ZONE IN VARCHAR2,
	p_STATEMENT_TYPE IN NUMBER,
	p_COUNTERPARTY_ID IN NUMBER,
	p_AGREEMENT_NAME IN VARCHAR2,
	p_STATUS OUT NUMBER,
	p_CURSOR OUT REF_CURSOR
	);
---------------------------------------
PROCEDURE SEM_STTL_ENTITY_LIST
    (
    p_CURSOR IN OUT GA.REFCURSOR
    );
---------------------------------------
PROCEDURE SEM_INVOICE_ATTRIBUTES
	(
	p_ENTITY_ID IN NUMBER,
	p_INVOICE_DATE IN VARCHAR2,
	p_STATEMENT_TYPE IN NUMBER,
	p_AS_OF_DATE IN DATE,
	p_CURSOR OUT GA.REFCURSOR
	);
---------------------------------------
PROCEDURE SEM_INVOICE_JOB_INFORMATION
	(
	p_ENTITY_ID IN NUMBER,
	p_INVOICE_DATE IN VARCHAR2,
	p_STATEMENT_TYPE IN NUMBER,
	p_AS_OF_DATE IN DATE,
    p_CURSOR OUT GA.REFCURSOR
	);
---------------------------------------
PROCEDURE SEM_INVOICE_TAX_TOTALS
	(
    p_ENTITY_ID IN NUMBER,
    p_INVOICE_DATE IN VARCHAR2,
    p_STATEMENT_TYPE IN NUMBER,
    p_AS_OF_DATE IN DATE,
    p_CURSOR OUT GA.REFCURSOR
	);
---------------------------------------
PROCEDURE SEM_INVOICE_LINE_ITEMS
	(
    p_ENTITY_ID IN NUMBER,
	p_INVOICE_DATE IN VARCHAR2,
	p_STATEMENT_TYPE IN NUMBER,
	p_AS_OF_DATE IN DATE,
    p_INVOICE_NUMBER_LBL OUT VARCHAR2,
    p_INVOICE_DATE_LBL OUT VARCHAR2,
    p_DUE_DATE_LBL OUT VARCHAR2,
    p_INVOICE_AMOUNT_LBL OUT VARCHAR2,
    p_UNIT_LBL OUT VARCHAR2,
    p_MARKET_NAME_LBL OUT VARCHAR2,
    p_BILL_PERIOD_NAME_LBL OUT VARCHAR2,
    p_RECEIVER_NAME_LBL OUT VARCHAR2,
    p_RECEIVER_ID_LBL OUT VARCHAR2,
    p_CURSOR OUT GA.REFCURSOR
	);
---------------------------------------
	PROCEDURE GET_SEM_SCHEDULES
	(
	p_TRANSACTION_ID IN NUMBER,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_TIME_ZONE IN VARCHAR2,
	p_STATUS OUT NUMBER,
	p_CURSOR OUT REF_CURSOR
	);
---------------------------------------
	PROCEDURE GET_EXANTE_IND_OP_SCHED
	(
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_TIME_ZONE IN VARCHAR2,
	p_RESOURCE_ID IN VARCHAR2,
	p_PSE_ID IN VARCHAR2,
	p_STATUS OUT NUMBER,
	p_CURSOR IN OUT REF_CURSOR
	);
---------------------------------------
PROCEDURE GET_PRCE_AFF_MTRD_DATA
	(
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_TIME_ZONE IN VARCHAR2,
	p_RESOURCE_ID IN VARCHAR2,
	p_RESOURCE_TYPE IN VARCHAR2,
	p_PSE_ID IN VARCHAR2,
	p_STATUS OUT NUMBER,
	p_CURSOR IN OUT REF_CURSOR
	);
---------------------------------------
PROCEDURE GET_MKT_SCHED_DETAIL
	(
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_TIME_ZONE IN VARCHAR2,
	p_RESOURCE_ID IN VARCHAR2,
	p_RESOURCE_TYPE IN VARCHAR2,
	p_SCHEDULE_ID IN VARCHAR2,
    p_GATE_WINDOW_ID IN VARCHAR2,
    p_PSE_ID IN VARCHAR2,
	p_STATUS OUT NUMBER,
	p_CURSOR IN OUT REF_CURSOR
	);
---------------------------------------
PROCEDURE GET_TECH_CHAR_EN_LTD
	(
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_TIME_ZONE IN VARCHAR2,
	p_RESOURCE_ID IN VARCHAR2,
	p_RESOURCE_TYPE IN VARCHAR2,
	p_PSE_ID IN VARCHAR2,
	p_STATUS OUT NUMBER,
	p_CURSOR IN OUT REF_CURSOR
	);
---------------------------------------
	PROCEDURE SYSTEM_FREQUENCY
  (
      p_BEGIN_DATE IN DATE,
      p_END_DATE   IN DATE,
      p_TIME_ZONE  IN VARCHAR2,
      p_PSE_ID     IN VARCHAR2,
      p_STATUS     OUT NUMBER,
      p_CURSOR     IN OUT REF_CURSOR
  );
-----------------------------------------
   FUNCTION GET_PERIODICITY_VALS
   		(
		p_PERIODICITY IN VARCHAR2,
		p_DELIMITER IN VARCHAR2 := c_COMMA
		) RETURN STRING_COLLECTION;
---------------------------------------
   PROCEDURE PUT_RO_REPORT_FILTERS
    (p_STRING_VAL                IN RO_REPORT_FILTERS.STRING_VAL%TYPE,
     p_FILTER_TYPE               IN RO_REPORT_FILTERS.FILTER_TYPE%TYPE,
     p_DELIMITER                 IN CHAR DEFAULT ',',
     p_TRUNCATE_TABLE            IN BOOLEAN DEFAULT TRUE);
---------------------------------------
  PROCEDURE SERVICE_POINT_NAME
    (p_PSE_IDs                  IN VARCHAR2,
     p_BEGIN_DATE                IN DATE,
     p_END_DATE                  IN DATE,
     p_TIME_ZONE                 IN VARCHAR2,
     p_STATUS                    OUT NUMBER,
     p_CURSOR                    OUT REF_CURSOR);
---------------------------------------
  PROCEDURE POD_NAMES_DISP
    (p_PSE_IDs                  IN VARCHAR2,
     p_BEGIN_DATE                IN DATE,
     p_END_DATE                  IN DATE,
     p_TIME_ZONE                 IN VARCHAR2,
     p_STATUS                    OUT NUMBER,
     p_CURSOR                    OUT REF_CURSOR);
---------------------------------------
  PROCEDURE PSE_NAME
    (p_JURISDICTIONS             IN VARCHAR2,
     p_BEGIN_DATE                IN DATE,
     p_END_DATE                  IN DATE,
     p_TIME_ZONE                 IN VARCHAR2,
     p_STATUS                    OUT NUMBER,
     p_CURSOR                    OUT REF_CURSOR);
---------------------------------------
  PROCEDURE PSE_NAMES_TLAF
    (p_BEGIN_DATE                IN DATE,
     p_END_DATE                  IN DATE,
     p_TIME_ZONE                 IN VARCHAR2,
     p_STATUS                    OUT NUMBER,
     p_CURSOR                    OUT REF_CURSOR);
---------------------------------------
  PROCEDURE PSE_NAMES_IC
    (p_BEGIN_DATE                IN DATE,
     p_END_DATE                  IN DATE,
     p_TIME_ZONE                 IN VARCHAR2,
	 p_POD_ID					IN VARCHAR2,
     p_STATUS                    OUT NUMBER,
     p_CURSOR                    OUT REF_CURSOR);
---------------------------------------
  PROCEDURE PSE_NAMES_ICNA
    (p_BEGIN_DATE                IN DATE,
     p_END_DATE                  IN DATE,
     p_TIME_ZONE                 IN VARCHAR2,
	 p_POD_ID					IN VARCHAR2,
     p_STATUS                    OUT NUMBER,
     p_CURSOR                    OUT REF_CURSOR);
---------------------------------------
  PROCEDURE PSE_NAMES_DISP
    (p_BEGIN_DATE                IN DATE,
     p_END_DATE                  IN DATE,
     p_TIME_ZONE                 IN VARCHAR2,
     p_STATUS                    OUT NUMBER,
     p_CURSOR                    OUT REF_CURSOR);
---------------------------------------
	PROCEDURE PSE_NAMES_FREQUENCY
    (p_BEGIN_DATE                IN DATE,
     p_END_DATE                  IN DATE,
     p_TIME_ZONE                 IN VARCHAR2,
     p_STATUS                    OUT NUMBER,
     p_CURSOR                    OUT REF_CURSOR);
---------------------------------------
 PROCEDURE PSE_NAMES_SETTL
  (p_STATUS OUT NUMBER,
   p_CURSOR OUT REF_CURSOR);
----------------------------------------
  PROCEDURE POD_NAMES_METER
    (p_BEGIN_DATE                IN DATE,
     p_END_DATE                  IN DATE,
     p_TIME_ZONE                 IN VARCHAR2,
	 p_JURISDICTIONS			 IN VARCHAR2,
	 p_RESOURCE_TYPE			 IN VARCHAR2,
     p_STATUS                    OUT NUMBER,
     p_CURSOR                    OUT REF_CURSOR);
---------------------------------------
  PROCEDURE POD_NAMES_OUTAGES
    (p_REPORT_SOURCE				IN VARCHAR2,
	p_BEGIN_DATE                IN DATE,
     p_END_DATE                  IN DATE,
     p_TIME_ZONE                 IN VARCHAR2,
     p_STATUS                    OUT NUMBER,
     p_CURSOR                    OUT REF_CURSOR);
---------------------------------------
  PROCEDURE OUTAGE_RPT_SOURCES
    (p_STATUS                    OUT NUMBER,
     p_CURSOR                    OUT REF_CURSOR);
---------------------------------------
  PROCEDURE IC_NAMES
    (p_STATUS                    OUT NUMBER,
     p_CURSOR                    OUT REF_CURSOR);
---------------------------------------
  PROCEDURE RAR_COUNTERPARTY_IDs
  	(
	p_ENTITY_ID IN NUMBER,
	p_STATUS OUT NUMBER,
	p_CURSOR OUT REF_CURSOR
	);
---------------------------------------
  PROCEDURE RAR_AGREEMENT_NAMES
  	(
	p_ENTITY_ID IN NUMBER,
	p_COUNTERPARTY_ID IN NUMBER,
	p_STATUS OUT NUMBER,
	p_CURSOR OUT REF_CURSOR
	);
---------------------------------------
  PROCEDURE PIR_RESOURCE_NAMES
  	(
	p_ENTITY_ID IN NUMBER,
	p_STATUS OUT NUMBER,
	p_CURSOR OUT REF_CURSOR
	);
---------------------------------------
  PROCEDURE PIR_VARIABLE_TYPES
  	(
	p_STATUS OUT NUMBER,
	p_CURSOR OUT REF_CURSOR
	);
---------------------------------------
 PROCEDURE GET_SYSTEM_LABEL_VALUES
	(
	p_MODEL_ID IN NUMBER,
	p_MODULE IN VARCHAR,
	p_KEY1 IN VARCHAR,
	p_KEY2 IN VARCHAR,
	p_KEY3 IN VARCHAR,
	p_STATUS OUT NUMBER,
	p_CURSOR IN OUT REF_CURSOR
	);
----------------------------------------
PROCEDURE SETTL_CLASS_UPDATE
(
    p_PSE_ID IN VARCHAR2,
    p_STATUS OUT NUMBER,
    p_CURSOR IN OUT REF_CURSOR
);
--------------------------------------
PROCEDURE ACTIVE_MP_UNITS
(
    p_PSE_ID IN VARCHAR2,
    p_STATUS OUT NUMBER,
    p_CURSOR IN OUT REF_CURSOR
);
-----------------------------------------
PROCEDURE GET_TECH_OFFER_CHAR_RPT
(
p_BEGIN_DATE DATE,
p_END_DATE DATE,
p_TIME_ZONE IN VARCHAR2,
p_RESOURCE_ID IN VARCHAR2,
p_RESOURCE_TYPE IN VARCHAR2,
p_RUN_TYPE_ID   IN VARCHAR2,
p_FUEL_TYPE IN VARCHAR2,
p_UNDER_TEST IN VARCHAR2,
p_STATUS OUT NUMBER,
p_CURSOR OUT REF_CURSOR
);
--------------------------------------
PROCEDURE GET_TECH_OFFER_FORECAST_RPT
(
p_BEGIN_DATE DATE,
p_END_DATE DATE,
p_TIME_ZONE IN VARCHAR2,
p_GATE_WINDOWS IN VARCHAR2,
p_RESOURCE_ID IN VARCHAR2,
p_RESOURCE_TYPE IN VARCHAR2,
p_UNDER_TEST IN VARCHAR2,
p_ATTRIBUTE IN VARCHAR2,
p_STATUS OUT NUMBER,
p_CURSOR OUT REF_CURSOR
);
--------------------------------------
PROCEDURE GET_CO_GEN_DSU_RPT
(
p_BEGIN_DATE DATE,
p_END_DATE DATE,
p_TIME_ZONE IN VARCHAR2,
p_RESOURCE_ID IN VARCHAR2,
p_RESOURCE_TYPE IN VARCHAR2,
p_SCHEDULE_ID   IN VARCHAR2,
p_FUEL_TYPE IN VARCHAR2,
p_UNDER_TEST IN VARCHAR2,
p_STATUS OUT NUMBER,
p_CURSOR OUT REF_CURSOR
);
--------------------------------------
PROCEDURE GET_CO_IC_DATA_RPT
(
p_BEGIN_DATE DATE,
p_END_DATE DATE,
p_TIME_ZONE IN VARCHAR2,
p_PSE_ID IN VARCHAR2,
p_RESOURCE_TYPE IN VARCHAR2,
p_GATE_WINDOW IN VARCHAR2,
p_STATUS OUT NUMBER,
p_CURSOR OUT REF_CURSOR
);
--------------------------------------
PROCEDURE GET_CO_NOM_PROFILE_RPT
(
p_BEGIN_DATE DATE,
p_END_DATE DATE,
p_TIME_ZONE IN VARCHAR2,
p_RESOURCE_ID IN VARCHAR2,
p_RESOURCE_TYPE IN VARCHAR2,
p_RUN_TYPE IN VARCHAR2,
p_UNDER_TEST IN VARCHAR2,
p_ATTRIBUTE IN VARCHAR2,
p_STATUS OUT NUMBER,
p_CURSOR OUT REF_CURSOR
);
--------------------------------------
PROCEDURE GET_WITHIN_DAY_ACTUAL_SCHED
(
p_BEGIN_DATE IN DATE,
p_END_DATE IN DATE,
p_TIME_ZONE IN VARCHAR2,
p_RESOURCE_ID IN VARCHAR2,
p_RESOURCE_TYPE IN VARCHAR2,
p_SCHEDULE_ID IN VARCHAR2,
p_STATUS OUT NUMBER,
p_CURSOR IN OUT REF_CURSOR
);
--------------------------------------
PROCEDURE GET_SO_TRADES
(
p_BEGIN_DATE IN DATE,
p_END_DATE IN DATE,
p_TIME_ZONE IN VARCHAR2,
p_RESOURCE_ID IN VARCHAR2,
p_CURSOR IN OUT REF_CURSOR
);
--------------------------------------
PROCEDURE GET_TECH_CHAR_GEN
(
p_SHOW_RESOURCES_ACROSS IN NUMBER,
p_BEGIN_DATE DATE,
p_END_DATE DATE,
p_TIME_ZONE IN VARCHAR2,
p_PSE_ID IN VARCHAR2,
p_RESOURCE_ID IN VARCHAR2,
p_RESOURCE_TYPE IN VARCHAR2,
p_ATTRIBUTE IN VARCHAR2,
p_CURSOR OUT REF_CURSOR
);
--------------------------------------
PROCEDURE GET_IC_NOMINATIONS
	(
	p_BEGIN_DATE DATE,
	p_END_DATE DATE,
	p_TIME_ZONE IN VARCHAR2,
	p_PSE_ID IN VARCHAR2,
	p_RESOURCE_ID IN VARCHAR2,
	p_RUN_TYPE IN VARCHAR2,
	p_GATE_WINDOW IN VARCHAR2,
	p_CURSOR OUT REF_CURSOR
	);
--------------------------------------	
PROCEDURE GET_IC_OFFER_CAPACITY
	(
		p_BEGIN_DATE                IN DATE,
		p_END_DATE                  IN DATE,
		p_TIME_ZONE                 IN VARCHAR2,
		p_RESOURCE_ID 				IN VARCHAR2,
		p_GATE_WINDOW 				IN VARCHAR2,
		p_CURSOR                    IN OUT REF_CURSOR
	);	
--------------------------------------
PROCEDURE GP_SETTLEMENT_REPORT(p_BEGIN_DATE IN DATE,
							   p_END_DATE IN DATE,
							   p_TIME_ZONE IN VARCHAR2,
							   p_INTERVAL IN VARCHAR2,
							   p_STATEMENT_TYPE IN NUMBER,
							   p_REPORT_TYPE IN VARCHAR2,
							   p_MARKET IN VARCHAR2,
							   p_JURISDICTION IN VARCHAR2,
							   p_VARIABLE_TYPE IN VARCHAR2,
							   p_RESOURCE_NAME IN VARCHAR2,
							   p_CURSOR IN OUT REF_CURSOR);
-----------------------------------------
PROCEDURE GET_DOWNLOAD_GROUPS
(
    p_CURSOR OUT REF_CURSOR
);
------------------------------------------------
PROCEDURE DEL_DOWNLOAD_GROUP(p_GROUP_NAME IN VARCHAR2, p_ERROR_MESSAGE OUT VARCHAR2);
------------------------------------------------
PROCEDURE PUT_DOWNLOAD_GROUP
(
	p_GROUP_NAME IN VARCHAR2,
	p_MARKET_TYPE IN VARCHAR2,
	p_REPORT_TYPE IN VARCHAR2,
	p_STATEMENT_TYPE_ID IN NUMBER,
	p_EXTERNAL_ACCOUNT_NAME IN VARCHAR2,
	p_PIR_STATEMENT_TYPE_EXTID IN VARCHAR2,
	p_INCLUDE_IN_DL IN NUMBER,
	p_ERROR_MESSAGE OUT VARCHAR2
);
------------------------------------------------
PROCEDURE GET_SEM_PSE_SERVICE_POINT
    (
    p_SERVICE_POINT_ID IN NUMBER,
    p_STATUS           OUT NUMBER,
    p_CURSOR           IN OUT REF_CURSOR
    );

PROCEDURE PUT_SEM_PSE_SERVICE_POINT
	(
    p_SERVICE_POINT_ID IN NUMBER,
    p_PSE_ID           IN NUMBER,
	p_BEGIN_DATE       IN DATE,
	p_END_DATE         IN DATE,
	p_OLD_PSE_ID       IN NUMBER,
	p_OLD_BEGIN_DATE   IN DATE,
    p_STATUS           OUT NUMBER
	);

PROCEDURE DEL_SEM_PSE_SERVICE_POINT
	(
    p_SERVICE_POINT_ID      IN NUMBER,
    p_PSE_ID      IN NUMBER,
	p_BEGIN_DATE  IN DATE,
    p_STATUS      OUT NUMBER
	);

PROCEDURE PIR_VARIABLES(p_CURSOR OUT REF_CURSOR);

PROCEDURE GET_SEM_MARKET_RESULTS
    (
	p_BEGIN_DATE           IN DATE,
	p_END_DATE             IN DATE,
	p_TIME_ZONE            IN VARCHAR2,
	p_REPORT_DATE_RANGE_BY IN VARCHAR2,
	p_RUN_TYPES		       IN VARCHAR2,
	p_SHOW_EURO		       IN NUMBER DEFAULT 1,
	p_SHOW_GBP		       IN NUMBER DEFAULT 1,
	p_STATUS               OUT NUMBER,
	p_CURSOR               OUT REF_CURSOR
    );

PROCEDURE CANCELLED_SRA_RPT
(
    p_BEGIN_DATE IN DATE,
    p_END_DATE IN DATE,
	p_TIME_ZONE IN VARCHAR2,
    p_ENTITY_GROUP_ID IN NUMBER,
    p_SRA_TYPE IN VARCHAR2, -- '<ALL>','Energy','Capacity'
	p_CURSOR IN OUT REF_CURSOR
);

PROCEDURE CANCELLED_SRA_CP_LIST
(
    p_CURSOR IN OUT REF_CURSOR
);

END SEM_REPORTS;
/
