CREATE OR REPLACE PACKAGE BODY MM_OASIS_RPT IS
--g_DATE_FORMAT    CONSTANT VARCHAR2(20) := 'DD-MON-YY HH24:MI:SS';
g_DATE_HOUR_FORMAT    CONSTANT VARCHAR2(21) := 'DD-MON-YY HH24:MI:SS';
--g_DATE_NON_HOUR_FORMAT    CONSTANT VARCHAR2(21) := 'DD-MON-YY';

FUNCTION WHAT_VERSION RETURN VARCHAR2 IS
BEGIN
    RETURN '$Revision: 1.1 $';
END WHAT_VERSION;
---------------------------------------------------------------------------------------------------
PROCEDURE CREATE_CAP_REQUEST_TXN_RPT
	(
	p_TP_ID IN NUMBER,
	p_CUSTOMER_CODE IN VARCHAR2,
	p_INTERVAL IN VARCHAR2,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_TIME_ZONE IN VARCHAR2,
	p_STATUS OUT NUMBER,
	p_CURSOR OUT SYS_REFCURSOR 
	) AS

	v_RELATED_REF_ATTRIBUTE_ID NUMBER(9);
	v_TS_CLASS_ATTRIBUTE_ID NUMBER(9);
	v_TS_TYPE_ATTRIBUTE_ID NUMBER(9);
	v_TS_PERIOD_ATTRIBUTE_ID NUMBER(9);
	v_TS_WINDOW_ATTRIBUTE_ID NUMBER(9);
	v_TS_SUBCLASS_ATTRIBUTE_ID NUMBER(9);
	v_SELLER_ID NUMBER(9);
	v_PURCHASER_ID NUMBER(9);

BEGIN

	MM_OASIS_UTIL.GET_ID_FOR_ENTITY_ATTRIBUTE(MM_OASIS_UTIL.g_EA_RELATED_REF,v_RELATED_REF_ATTRIBUTE_ID);
	MM_OASIS_UTIL.GET_ID_FOR_ENTITY_ATTRIBUTE(MM_OASIS_UTIL.g_EA_TS_CLASS,v_TS_CLASS_ATTRIBUTE_ID);
	MM_OASIS_UTIL.GET_ID_FOR_ENTITY_ATTRIBUTE(MM_OASIS_UTIL.g_EA_TS_TYPE,v_TS_TYPE_ATTRIBUTE_ID);
	MM_OASIS_UTIL.GET_ID_FOR_ENTITY_ATTRIBUTE(MM_OASIS_UTIL.g_EA_TS_PERIOD,v_TS_PERIOD_ATTRIBUTE_ID);
	MM_OASIS_UTIL.GET_ID_FOR_ENTITY_ATTRIBUTE(MM_OASIS_UTIL.g_EA_TS_WINDOW,v_TS_WINDOW_ATTRIBUTE_ID);
	MM_OASIS_UTIL.GET_ID_FOR_ENTITY_ATTRIBUTE(MM_OASIS_UTIL.g_EA_TS_SUBCLASS,v_TS_SUBCLASS_ATTRIBUTE_ID);

--  Assume the SELLER is always the PROVIDER since we are not supporting RESALES.
--	v_SELLER_ID := MM_OASIS_UTIL.ID_FOR_PSE_IDENT(p_SELLER_CODE, TRUE);
	v_SELLER_ID := MM_OASIS_UTIL.GET_SELLER_ID_FOR_TP(p_TP_ID);
	v_PURCHASER_ID := MM_OASIS_UTIL.ID_FOR_PSE_IDENT(p_CUSTOMER_CODE, TRUE);

	--MM_OASIS_UTIL.GET_ID_FOR_ENTITY_ATTRIBUTE(MM_OASIS_UTIL.g_EA_RELATED_REF, v_RELATED_REF_ATTRIBUTE_ID);
	--HOULRY REPORTS HAVE START_DATE, START_HOUR AND STOP_HOUR
	--NON-HOURLY REPORTS HAVE ONLY START_DATE AND STOP_DATE
	--EVERYTHING ELSE IS THE SAME

-------------------------------------------------------------------------------------
	OPEN p_CURSOR FOR
		SELECT IT.TRANSACTION_ID "TXN_ID",
			MIN(CASE p_INTERVAL WHEN 'HOUR' THEN TO_DATE(SUBSTR(FROM_CUT_AS_HED(ITTS.SCHEDULE_DATE, p_TIME_ZONE),1,10),'YYYY-MM-DD') ELSE TRUNC(ITTS.SCHEDULE_DATE) END) "START_DATE",
			MAX(CASE p_INTERVAL WHEN 'HOUR' THEN TO_DATE(SUBSTR(FROM_CUT_AS_HED(ITTS.SCHEDULE_END_DATE, p_TIME_ZONE),1,10),'YYYY-MM-DD') ELSE TRUNC(ITTS.SCHEDULE_END_DATE) END) "STOP_DATE",
			MIN(CASE p_INTERVAL WHEN 'HOUR' THEN SUBSTR(FROM_CUT_AS_HED(ITTS.SCHEDULE_DATE, p_TIME_ZONE),12,2) ELSE NULL END) "START_HOUR",
			MAX(CASE p_INTERVAL WHEN 'HOUR' THEN SUBSTR(FROM_CUT_AS_HED(ITTS.SCHEDULE_END_DATE, p_TIME_ZONE),12,2) ELSE NULL END) "STOP_HOUR",
			MAX(CASE WHEN ITTS.TRAIT_GROUP_ID = MM_OASIS_UTIL.g_TG_CUST_COMMENTS
					THEN ITTS.TRAIT_VAL ELSE NULL END) "CUSTOMER_COMMENTS",
--				<TSCLASS>:<TSTYPE>:<TSPERIOD>:<TSWINDOW>:<TSSUBCLASS>
			TEA1.ATTRIBUTE_VAL ||':'|| TEA2.ATTRIBUTE_VAL ||':'|| TEA4.ATTRIBUTE_VAL ||':'|| TEA5.ATTRIBUTE_VAL||':'|| TEA6.ATTRIBUTE_VAL "SERVICE_INFORMATION",
			MAX(CASE WHEN ITTS.TRAIT_GROUP_ID = MM_OASIS_UTIL.g_TG_CAP_REQUESTED
					THEN ITTS.TRAIT_VAL ELSE NULL END) "CAPACITY_REQUESTED",
			MAX(CASE WHEN ITTS.TRAIT_GROUP_ID = MM_OASIS_UTIL.g_TG_PRECONFIRMED
					THEN UPPER(ITTS.TRAIT_VAL) ELSE NULL END) "PRECONFIRMED",
			TEA3.ATTRIBUTE_VAL "RELATED_REF",
			CASE IT.TRANSACTION_IDENTIFIER WHEN '?' THEN SUBSTR(IT.TRANSACTION_NAME, INSTR(IT.TRANSACTION_NAME,':',-1) + 1)  ELSE IT.TRANSACTION_IDENTIFIER END "OASIS_IDENTIFIER",
			NVL(SUBSTR(IT.TRANSACTION_ALIAS,1,INSTR(IT.TRANSACTION_ALIAS,'-')-1),IT.TRANSACTION_ALIAS) "DEAL_REF",
			SP1.SERVICE_POINT_NAME "POR",
			SP2.SERVICE_POINT_NAME "POD",
			UPPER(SP3.SERVICE_POINT_NAME) "SOURCE",
			SP4.SERVICE_POINT_NAME "SINK"
		FROM IT_TRAIT_SCHEDULE         ITTS,
			INTERCHANGE_TRANSACTION   IT,
			IT_STATUS				 ITS,
			TEMPORAL_ENTITY_ATTRIBUTE TEA1,
			TEMPORAL_ENTITY_ATTRIBUTE TEA2,
			TEMPORAL_ENTITY_ATTRIBUTE TEA3,
			TEMPORAL_ENTITY_ATTRIBUTE TEA4,
			TEMPORAL_ENTITY_ATTRIBUTE TEA5,
			TEMPORAL_ENTITY_ATTRIBUTE TEA6,
			SERVICE_POINT             SP1,
			SERVICE_POINT             SP2,
			SERVICE_POINT             SP3,
			SERVICE_POINT             SP4
		WHERE ITTS.TRANSACTION_ID = IT.TRANSACTION_ID
			AND IT.TRANSACTION_ID = ITS.TRANSACTION_ID
			AND ITS.TRANSACTION_IS_ACTIVE = 1
			AND IT.BEGIN_DATE <= p_END_DATE
			AND IT.END_DATE >= p_BEGIN_DATE
			AND IT.EXTERNAL_INTERVAL = p_INTERVAL
			AND TEA1.OWNER_ENTITY_ID(+) = IT.TRANSACTION_ID
			AND TEA2.OWNER_ENTITY_ID(+) = IT.TRANSACTION_ID
			AND TEA3.OWNER_ENTITY_ID(+) = IT.TRANSACTION_ID
			AND TEA4.OWNER_ENTITY_ID(+) = IT.TRANSACTION_ID
			AND TEA5.OWNER_ENTITY_ID(+) = IT.TRANSACTION_ID
			AND TEA6.OWNER_ENTITY_ID(+) = IT.TRANSACTION_ID
			AND TEA1.ATTRIBUTE_ID(+) = v_TS_CLASS_ATTRIBUTE_ID
			AND TEA2.ATTRIBUTE_ID(+) = v_TS_TYPE_ATTRIBUTE_ID
			AND TEA3.ATTRIBUTE_ID(+) = v_RELATED_REF_ATTRIBUTE_ID
			AND TEA4.ATTRIBUTE_ID(+) = v_TS_PERIOD_ATTRIBUTE_ID
			AND TEA5.ATTRIBUTE_ID(+) = v_TS_WINDOW_ATTRIBUTE_ID
			AND TEA6.ATTRIBUTE_ID(+) = v_TS_SUBCLASS_ATTRIBUTE_ID
			AND IT.POR_ID = SP1.SERVICE_POINT_ID
			AND IT.POD_ID = SP2.SERVICE_POINT_ID
			AND IT.SOURCE_ID = SP3.SERVICE_POINT_ID
			AND IT.SINK_ID = SP4.SERVICE_POINT_ID
			AND IT.AGREEMENT_TYPE = 'OASIS'
			AND IT.TP_ID = p_TP_ID
			AND IT.PURCHASER_ID = v_PURCHASER_ID
			AND IT.SELLER_ID =v_SELLER_ID
		GROUP BY IT.TRANSACTION_ID, IT.TRANSACTION_NAME,
			TEA1.ATTRIBUTE_VAL,
			TEA2.ATTRIBUTE_VAL,
			TEA3.ATTRIBUTE_VAL,
			TEA4.ATTRIBUTE_VAL,
			TEA5.ATTRIBUTE_VAL,
			TEA6.ATTRIBUTE_VAL,
			IT.TRANSACTION_IDENTIFIER,
			IT.TRANSACTION_ALIAS,
			SP1.SERVICE_POINT_NAME,
			SP2.SERVICE_POINT_NAME,
			SP3.SERVICE_POINT_NAME,
			SP4.SERVICE_POINT_NAME;

END CREATE_CAP_REQUEST_TXN_RPT;
------------------------------------------------------------------------------------------------------------------------
PROCEDURE GET_TP_LIST
	(
	p_STATUS OUT NUMBER,
	p_CURSOR OUT SYS_REFCURSOR 
	) AS
BEGIN
	OPEN p_CURSOR FOR
		SELECT UPPER(TP_NAME), TP_ID, CASE WHEN UPPER(TP_NAME) = 'SWPP' THEN 0 ELSE 1 END "SORT_ORDER"
		FROM TRANSMISSION_PROVIDER
		WHERE TP_ID > 0
		ORDER BY 3,1;

END GET_TP_LIST;
------------------------------------------------------------------------------------------------------------------------
PROCEDURE GET_CUSTOMER_LIST
	(
	p_STATUS OUT NUMBER,
	p_CURSOR OUT SYS_REFCURSOR 
	) AS
BEGIN
	OPEN p_CURSOR FOR
		SELECT UPPER(PSE_NAME),PSE_ID, CASE WHEN UPPER(PSE_NAME) = 'WR' THEN 0 ELSE 1 END "SORT_ORDER"
		FROM PURCHASING_SELLING_ENTITY
		WHERE PSE_ID > 0
			--AND PSE_DUNS_NUMBER <> '?'
		ORDER BY 3,1;

END GET_CUSTOMER_LIST;
------------------------------------------------------------------------------------------------------------------------
PROCEDURE GET_POD_LIST
	(
	p_TP_ID IN NUMBER,
	p_STATUS OUT NUMBER,
	p_CURSOR OUT SYS_REFCURSOR 
	) AS
BEGIN
	OPEN p_CURSOR FOR
		SELECT OASIS_LIST_ITEM, CASE WHEN OASIS_LIST_ITEM = 'WR' THEN 0 ELSE 1 END "SORT ORDER"
		FROM TP_OASIS_LIST_RESULT
		WHERE OASIS_LIST_NAME='POINT_OF_DELIVERY'
			AND TP_ID = p_TP_ID
		ORDER BY 2,1;
END GET_POD_LIST;
-------------------------------------------------------------------------------------------------------------------------
PROCEDURE GET_POR_LIST
	(
	p_TP_ID IN NUMBER,
	p_STATUS OUT NUMBER,
	p_CURSOR OUT SYS_REFCURSOR 
	) AS
BEGIN
	OPEN p_CURSOR FOR
		SELECT OASIS_LIST_ITEM, CASE WHEN OASIS_LIST_ITEM = 'WR' THEN 0 ELSE 1 END "SORT ORDER"
		FROM TP_OASIS_LIST_RESULT
		WHERE OASIS_LIST_NAME='POINT_OF_RECEIPT'
			AND TP_ID = p_TP_ID
		ORDER BY 2,1;
END GET_POR_LIST;
-------------------------------------------------------------------------------------------------------------------------
PROCEDURE GET_SINK_LIST
	(
	p_TP_ID IN NUMBER,
	p_STATUS OUT NUMBER,
	p_CURSOR OUT SYS_REFCURSOR 
	) AS
BEGIN
	OPEN p_CURSOR FOR
		SELECT OASIS_LIST_ITEM FROM
		(
			SELECT OASIS_LIST_ITEM "OASIS_LIST_ITEM", 1 "SORT_ORDER"
			FROM TP_OASIS_LIST_RESULT
			WHERE OASIS_LIST_NAME='POINT_OF_DELIVERY'
				AND TP_ID = p_TP_ID
			UNION ALL
			SELECT 'WR' "OASIS_LIST_ITEM", 0 "SORT_ORDER"
			FROM DUAL
			ORDER BY 2,1
		);
END GET_SINK_LIST;
-------------------------------------------------------------------------------------------------------------------------
PROCEDURE GET_SELLER_LIST
	(
	 p_TP_ID  IN NUMBER,
	 p_STATUS OUT NUMBER,
	 p_CURSOR OUT SYS_REFCURSOR 
	 ) AS

BEGIN
	OPEN p_CURSOR FOR
		SELECT T.OASIS_LIST_ITEM, CASE WHEN T.OASIS_LIST_ITEM = 'SWPP' THEN 0 ELSE 1 END "SORT ORDER"
		  FROM TP_OASIS_LIST_RESULT T
		 WHERE T.TP_ID = p_TP_ID
		   AND T.OASIS_LIST_NAME = 'SELLER_CODE'
		 ORDER BY 2, 1;

END GET_SELLER_LIST;
-------------------------------------------------------------------------------------------------------------------------
PROCEDURE GET_SERVICE_INFO_LIST
	(
	p_TP_ID IN NUMBER,
	p_INTERVAL IN VARCHAR2,
	p_STATUS OUT NUMBER,
	p_CURSOR OUT SYS_REFCURSOR 
	) AS

BEGIN

	--SERVICE INFORMATION HAS THE FOLLOWING FORMAT:
	--OLD---- <INTERVAL>:<TS_CLASS>:<SELLER_CODE>:<TS_TYPE>
	-- <TSCLASS>:<TSTYPE>:<TSPERIOD>:<TSWINDOW>:<TSSUBCLASS>
	OPEN p_CURSOR FOR
	SELECT T.OASIS_LIST_ITEM || ':' || U.OASIS_LIST_ITEM || ':' || V.OASIS_LIST_ITEM || ':' || W.OASIS_LIST_ITEM || ':' || NVL(X.OASIS_LIST_ITEM, ' ')
	   FROM TP_OASIS_LIST_RESULT T,TP_OASIS_LIST_RESULT U,TP_OASIS_LIST_RESULT V,TP_OASIS_LIST_RESULT W,TP_OASIS_LIST_RESULT X
	  WHERE T.TP_ID = p_TP_ID
	  	AND T.OASIS_LIST_NAME='TS_CLASS'
		AND T.IS_APPLICABLE = 1
		AND U.TP_ID = p_TP_ID
		AND U.OASIS_LIST_NAME='TS_TYPE'
		AND U.IS_APPLICABLE = 1
		AND V.TP_ID = p_TP_ID
		AND V.OASIS_LIST_NAME='TS_PERIOD'
		AND V.IS_APPLICABLE = 1
		AND W.TP_ID = p_TP_ID
		AND W.OASIS_LIST_NAME='TS_WINDOW'
		AND W.IS_APPLICABLE = 1
		AND X.TP_ID(+) = p_TP_ID
		AND X.OASIS_LIST_NAME(+)='TS_SUBCLASS'
		AND X.IS_APPLICABLE(+) = 1
	  ORDER BY 1;


END GET_SERVICE_INFO_LIST;
--------------------------------------------------------------------------------------------------------------------------
PROCEDURE CREATE_OASIS_TRANSACTION
	(
	p_TRANSACTION_ID IN NUMBER,
	p_START_DATE IN DATE,
	p_START_HOUR IN VARCHAR2,
	p_STOP_DATE IN DATE,
	p_STOP_HOUR IN VARCHAR2,
	p_CUSTOMER_COMMENTS IN VARCHAR2,
	p_SERVICE_INFORMATION IN VARCHAR2,
	p_CAPACITY_REQUESTED IN VARCHAR2,
	p_PRECONFIRMED IN VARCHAR2,
	p_RELATED_REF IN VARCHAR2,
	p_OASIS_ID IN VARCHAR2,
	p_DEAL_REF IN VARCHAR2,
	p_POR IN VARCHAR2,
	p_POD IN VARCHAR2,
	p_SOURCE IN VARCHAR2,
	p_SINK IN VARCHAR2,
	p_TP_ID IN NUMBER,
	p_INTERVAL IN VARCHAR2,
	p_CUSTOMER_CODE IN VARCHAR2,
	p_TIME_ZONE IN VARCHAR2,
	p_ERROR_MESSAGE OUT VARCHAR2
	) AS


	v_TRANSACTION_NAME INTERCHANGE_TRANSACTION.TRANSACTION_NAME%TYPE;
	v_TRANSACTION_ID INTERCHANGE_TRANSACTION.TRANSACTION_ID%TYPE;
	v_BEGIN_DATE DATE;
	v_END_DATE DATE;
	v_TP_CODE VARCHAR2(4);
	v_DEAL_REFERENCE VARCHAR2(16);
	v_TS_CLASS TEMPORAL_ENTITY_ATTRIBUTE.ATTRIBUTE_VAL%TYPE;
	v_TS_TYPE TEMPORAL_ENTITY_ATTRIBUTE.ATTRIBUTE_VAL%TYPE;
	v_TS_PERIOD TEMPORAL_ENTITY_ATTRIBUTE.ATTRIBUTE_VAL%TYPE;
	v_TS_WINDOW TEMPORAL_ENTITY_ATTRIBUTE.ATTRIBUTE_VAL%TYPE;
	v_TS_SUBCLASS TEMPORAL_ENTITY_ATTRIBUTE.ATTRIBUTE_VAL%TYPE;

	v_TS_CLASS_ATTRIBUTE_ID    NUMBER(9);
	v_TS_TYPE_ATTRIBUTE_ID     NUMBER(9);
	v_RELATED_REF_ATTRIBUTE_ID NUMBER(9);
	v_TS_PERIOD_ATTRIBUTE_ID   NUMBER(9);
	v_TS_WINDOW_ATTRIBUTE_ID   NUMBER(9);
	v_TS_SUBCLASS_ATTRIBUTE_ID   NUMBER(9);
	v_STATUS NUMBER(1);
	v_LOGGER         mm_logger_adapter;

	v_STRING_TABLE GA.STRING_TABLE;
BEGIN

	v_LOGGER := MM_UTIL.GET_LOGGER(EC.ES_SEM, NULL, 'Create OASIS transaction', 'Create OASIS transactions', NULL, NULL);
	MM_UTIL.START_EXCHANGE(FALSE, v_LOGGER);
	
	--CHECK FOR VIOLATIONS.
	v_LOGGER.LOG_INFO('Check for violations (Null Transaction ID or Null Capacity requested');
	IF p_TRANSACTION_ID IS NOT NULL THEN
		p_ERROR_MESSAGE := 'Existing Reservations cannot be updated.';
		v_LOGGER.LOG_ERROR('Existing Reservations cannot be updated.');
		RETURN;
	ELSIF p_CAPACITY_REQUESTED IS NULL OR TO_NUMBER(p_CAPACITY_REQUESTED) <= 0 THEN
		p_ERROR_MESSAGE := 'Capacity Requested must be specified.';
		v_LOGGER.LOG_ERROR('Capacity Requested must be specified.');
		RETURN;
	END IF;

	SELECT TP.TP_NAME INTO v_TP_CODE FROM TRANSMISSION_PROVIDER TP WHERE TP.TP_ID=p_TP_ID;

	--Parse SERVICE_INFORMATION in order to extract values for TS_CLASS and TS_TYPE
	--<TSCLASS>:<TSTYPE>:<TSPERIOD>:<TSWINDOW>:<TSSUBCLASS>
	UT.TOKENS_FROM_STRING(p_SERVICE_INFORMATION, ':', v_STRING_TABLE);
	v_TS_CLASS := v_STRING_TABLE(1);
	v_TS_TYPE := v_STRING_TABLE(2);
	v_TS_PERIOD := v_STRING_TABLE(3);
	v_TS_WINDOW := v_STRING_TABLE(4);
	v_TS_SUBCLASS := v_STRING_TABLE(5);

	--Build a temporary name for the transaction
	v_TRANSACTION_NAME := MM_OASIS_UTIL.BUILD_TXN_NAME(p_TP_ID, p_POR, p_POD, v_TS_TYPE, p_INTERVAL);

	--Calculate START_DATE, STOP_DATE
	IF p_INTERVAL = 'HOUR' THEN
		--Hourly transactions
		v_BEGIN_DATE := TO_CUT(p_START_DATE + TO_NUMBER(p_START_HOUR)/24, p_TIME_ZONE);
		v_END_DATE := TO_CUT(NVL(p_STOP_DATE, p_START_DATE) + TO_NUMBER(p_STOP_HOUR)/24, p_TIME_ZONE);
	ELSE
		--Non-Hourly transactions
		v_BEGIN_DATE := TRUNC(p_START_DATE);
		v_END_DATE := TRUNC(p_STOP_DATE);
	END IF;

	MM_OASIS.CREATE_TXN(p_TRANSACTION_NAME => v_TRANSACTION_NAME,
					    p_TRANSACTION_IDENT =>p_OASIS_ID,
						p_DEAL_REF => v_DEAL_REFERENCE,
						p_SELLER_CODE => v_TP_CODE,
						p_CUSTOMER_CODE => p_CUSTOMER_CODE,
						p_SOURCE =>p_SOURCE,
						p_SINK => p_SINK,
						p_POD => p_POD,
						p_POR => p_POR,
						p_TRANSACTION_INTERVAL => p_INTERVAL,
						p_TP_CODE => v_TP_CODE,
						p_TP_ID => p_TP_ID,
						p_START_DATE => v_BEGIN_DATE,
						p_END_DATE => v_END_DATE,
						p_TRANSACTION_ID => v_TRANSACTION_ID,
						p_LOGGER => v_LOGGER);

	v_STATUS := GA.SUCCESS;

	--Set the status to NEW	for all transactions created through the report
	ITJ.PUT_IT_STATUS(v_TRANSACTION_ID,
					 LOW_DATE,
					 'NEW',
					 1,
					 v_STATUS);

	--Create Entity Attributes
	MM_OASIS_UTIL.GET_ID_FOR_ENTITY_ATTRIBUTE(MM_OASIS_UTIL.g_EA_TS_CLASS,v_TS_CLASS_ATTRIBUTE_ID);
	MM_OASIS_UTIL.GET_ID_FOR_ENTITY_ATTRIBUTE(MM_OASIS_UTIL.g_EA_TS_TYPE, v_TS_TYPE_ATTRIBUTE_ID);
	MM_OASIS_UTIL.GET_ID_FOR_ENTITY_ATTRIBUTE(MM_OASIS_UTIL.g_EA_TS_PERIOD,v_TS_PERIOD_ATTRIBUTE_ID);
	MM_OASIS_UTIL.GET_ID_FOR_ENTITY_ATTRIBUTE(MM_OASIS_UTIL.g_EA_TS_WINDOW,v_TS_WINDOW_ATTRIBUTE_ID);
	MM_OASIS_UTIL.GET_ID_FOR_ENTITY_ATTRIBUTE(MM_OASIS_UTIL.g_EA_RELATED_REF, v_RELATED_REF_ATTRIBUTE_ID);
	MM_OASIS_UTIL.GET_ID_FOR_ENTITY_ATTRIBUTE(MM_OASIS_UTIL.g_EA_TS_SUBCLASS, v_TS_SUBCLASS_ATTRIBUTE_ID);

	IF NOT v_TRANSACTION_ID IS NULL AND NOT v_TS_CLASS IS NULL THEN
		MM_OASIS_UTIL.PUT_ENTITY_ATTRIBUTES (v_TRANSACTION_ID,v_TS_CLASS_ATTRIBUTE_ID,v_TS_CLASS,v_BEGIN_DATE,v_STATUS);
	END IF;

	IF NOT v_TRANSACTION_ID IS NULL AND NOT v_TS_TYPE IS NULL THEN
		MM_OASIS_UTIL.PUT_ENTITY_ATTRIBUTES (v_TRANSACTION_ID,v_TS_TYPE_ATTRIBUTE_ID,v_TS_TYPE,v_BEGIN_DATE,v_STATUS);
	END IF;

	IF NOT v_TRANSACTION_ID IS NULL AND NOT v_TS_PERIOD IS NULL THEN
		MM_OASIS_UTIL.PUT_ENTITY_ATTRIBUTES (v_TRANSACTION_ID,v_TS_PERIOD_ATTRIBUTE_ID,v_TS_PERIOD,v_BEGIN_DATE,v_STATUS);
	END IF;

	IF NOT v_TRANSACTION_ID IS NULL AND NOT v_TS_WINDOW IS NULL THEN
		MM_OASIS_UTIL.PUT_ENTITY_ATTRIBUTES (v_TRANSACTION_ID,v_TS_WINDOW_ATTRIBUTE_ID,v_TS_WINDOW,v_BEGIN_DATE,v_STATUS);
	END IF;

	IF NOT v_TRANSACTION_ID IS NULL AND NOT TRIM(v_TS_SUBCLASS) IS NULL THEN
		MM_OASIS_UTIL.PUT_ENTITY_ATTRIBUTES (v_TRANSACTION_ID,v_TS_SUBCLASS_ATTRIBUTE_ID,v_TS_SUBCLASS,v_BEGIN_DATE,v_STATUS);
	END IF;

	IF NOT v_TRANSACTION_ID IS NULL AND NOT p_RELATED_REF IS NULL THEN
		MM_OASIS_UTIL.PUT_ENTITY_ATTRIBUTES (v_TRANSACTION_ID,v_RELATED_REF_ATTRIBUTE_ID,p_RELATED_REF,v_BEGIN_DATE,v_STATUS);
	END IF;

	--UPDATE TRAITS
	/*IF NOT p_START_HOUR IS NULL AND NOT p_END_HOUR IS NULL THEN
		v_BEGIN_DATE := FROM_CUT_AS_HED(p_START_DATE+TO_NUMBER(p_START_HOUR)/24,p_TIME_ZONE);
		v_END_DATE := FROM_CUT_AS_HED(p_START_DATE+TO_NUMBER(p_END_HOUR)/24,p_TIME_ZONE);
	END IF;*/

	--Capacity Requested
	IF NOT p_CAPACITY_REQUESTED IS NULL THEN
		TG.PUT_IT_TRAIT_SCHEDULE_SPARSE(v_TRANSACTION_ID, GA.INTERNAL_STATE, 0, v_BEGIN_DATE,
						v_END_DATE, MM_OASIS_UTIL.g_TG_CAP_REQUESTED,1, 1,
						p_CAPACITY_REQUESTED, CUT_TIME_ZONE, v_STATUS);
    END IF;

	--Preconfirmed
	IF NOT p_PRECONFIRMED IS NULL THEN
		TG.PUT_IT_TRAIT_SCHEDULE_SPARSE(v_TRANSACTION_ID, GA.INTERNAL_STATE, 0, v_BEGIN_DATE,
						v_END_DATE, MM_OASIS_UTIL.g_TG_PRECONFIRMED,1, 1,
						UPPER(p_PRECONFIRMED), CUT_TIME_ZONE, v_STATUS);
	END IF;

	--Customer Comments
	IF NOT p_CUSTOMER_COMMENTS IS NULL THEN
		TG.PUT_IT_TRAIT_SCHEDULE_SPARSE(v_TRANSACTION_ID, GA.INTERNAL_STATE, 0, v_BEGIN_DATE,
					v_END_DATE, MM_OASIS_UTIL.g_TG_CUST_COMMENTS,1, 1,
					p_CUSTOMER_COMMENTS, CUT_TIME_ZONE, v_STATUS);

	END IF;

	v_STATUS := GA.SUCCESS;
	p_ERROR_MESSAGE := 'OASIS transaction(s) successfully created.';
	MM_UTIL.STOP_EXCHANGE(v_LOGGER, v_STATUS, p_ERROR_MESSAGE, p_ERROR_MESSAGE);
	p_ERROR_MESSAGE := p_ERROR_MESSAGE ||' See event log for details.';
	
END CREATE_OASIS_TRANSACTION;
--------------------------------------------------------------------------------------------------------------------------
PROCEDURE GET_OASIS_LIST
(
    p_BEGIN_DATE IN DATE,
    p_END_DATE   IN DATE,
    p_STATUS     OUT NUMBER,
    p_CURSOR     OUT SYS_REFCURSOR 
) AS
BEGIN

    OPEN p_CURSOR FOR
        SELECT '(' || D.TRANSACTION_STATUS_NAME || ') ' || A.TRANSACTION_NAME "TRANSACTION_NAME",
               A.TRANSACTION_ID
        FROM INTERCHANGE_TRANSACTION   A,
             IT_STATUS                 D,
             PURCHASING_SELLING_ENTITY E
        WHERE A.AGREEMENT_TYPE = 'OASIS'
        AND A.BEGIN_DATE <= p_END_DATE
        AND A.END_DATE >= p_BEGIN_DATE
        AND A.IS_BID_OFFER = 1
        AND D.TRANSACTION_ID = A.TRANSACTION_ID
        AND D.AS_OF_DATE = (SELECT MAX(AS_OF_DATE)
                           FROM IT_STATUS
                           WHERE TRANSACTION_ID = D.TRANSACTION_ID)
        AND E.PSE_ID = A.PURCHASER_ID
        ORDER BY 1;

END GET_OASIS_LIST;

--------------------------------------------------------------------------------------------------------------------------
PROCEDURE GET_OASIS_STATUS_SUMMARY_RPT
(
    p_BEGIN_DATE IN DATE,
    p_END_DATE   IN DATE,
    p_PSE_IDS    IN VARCHAR2,
    p_STATUSES   IN VARCHAR2,
    p_CURSOR     OUT SYS_REFCURSOR
) AS
    v_PSE_IDS  ID_TABLE;
    v_STATUSES STRING_COLLECTION;

    --v_STATUSES VARCHAR2(4000) := ',' || NVL(p_STATUSES,CONSTANTS.ALL_STRING) || ',';
BEGIN

    /*UT.ID_TABLE_FROM_STRING(NVL(p_PSE_IDS,'-1'), ',', v_PSE_IDS);
    OPEN p_CURSOR FOR
        SELECT B.PSE_NAME "PURCHASER_NAME",
            A.TRANSACTION_NAME,
            A.TRANSACTION_ID,
            C.TRANSACTION_STATUS_NAME
        FROM INTERCHANGE_TRANSACTION A, PURCHASING_SELLING_ENTITY B, IT_STATUS C, TABLE(CAST(v_PSE_IDS AS ID_TABLE)) X
        WHERE A.AGREEMENT_TYPE = 'OASIS'
            AND A.BEGIN_DATE <= p_END_DATE
            AND A.END_DATE >= p_BEGIN_DATE
            AND (p_PSE_IDS = CONSTANTS.ALL_ID OR A.PURCHASER_ID = X.ID)
            AND A.PURCHASER_ID = B.PSE_ID
            AND C.TRANSACTION_ID = A.TRANSACTION_ID
            AND (v_STATUSES=','||CONSTANTS.ALL_STRING||',' OR INSTR(v_STATUSES,',' || C.TRANSACTION_STATUS_NAME || ',') > 0)
        ORDER BY 1,2;*/

    IF p_STATUSES IS NOT NULL AND
       INSTR(',' || p_STATUSES || ',', ',' || CONSTANTS.ALL_STRING || ',') = 0 THEN
        UT.STRING_COLLECTION_FROM_STRING(p_STATUSES, ',', v_STATUSES);
    ELSE
        -- if they selected all then that should be the only item in this list
        v_STATUSES := STRING_COLLECTION();
        v_STATUSES.EXTEND;
        v_STATUSES(v_STATUSES.LAST) := CONSTANTS.ALL_STRING;
    END IF;

    IF p_PSE_IDS IS NOT NULL AND
       INSTR(',' || p_PSE_IDS || ',', ',' || CONSTANTS.ALL_ID || ',') = 0 THEN
        UT.ID_TABLE_FROM_STRING(p_PSE_IDS, ',', v_PSE_IDS);
    ELSE
        -- if they selected all then that should be the only item in this list
        v_PSE_IDS := ID_TABLE();
        v_PSE_IDS.EXTEND;
        v_PSE_IDS(v_PSE_IDS.LAST) := ID_TYPE(CONSTANTS.ALL_ID);
    END IF;

    OPEN p_CURSOR FOR
        SELECT B.PSE_NAME AS PURCHASER_NAME,
               A.TRANSACTION_NAME,
               A.TRANSACTION_ID,
               C.TRANSACTION_STATUS_NAME
        FROM INTERCHANGE_TRANSACTION A,
             PURCHASING_SELLING_ENTITY B,
             IT_STATUS C,
             TABLE(CAST(v_PSE_IDS AS ID_TABLE)) X,
             TABLE(CAST(v_STATUSES AS STRING_COLLECTION)) Y
        WHERE A.AGREEMENT_TYPE = 'OASIS'
        AND A.BEGIN_DATE <= p_END_DATE
        AND A.END_DATE >= p_BEGIN_DATE
        AND X.ID IN (CONSTANTS.ALL_ID, A.PURCHASER_ID)
        AND A.PURCHASER_ID = B.PSE_ID
        AND C.TRANSACTION_ID = A.TRANSACTION_ID
        AND C.AS_OF_DATE = CONSTANTS.LOW_DATE
        AND Y.COLUMN_VALUE IN (CONSTANTS.ALL_STRING, C.TRANSACTION_STATUS_NAME)
        ORDER BY 1, 2;

END GET_OASIS_STATUS_SUMMARY_RPT;
----------------------------------------------------------------------
END MM_OASIS_RPT;
/
