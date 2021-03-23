CREATE OR REPLACE TYPE BODY POD_DETERMINANT_ACCESSOR IS
-------------------------------------------------------------------------------
OVERRIDING MEMBER PROCEDURE GET_PEAK_DETERMINANT
	(
	p_INTERVAL IN VARCHAR2,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_UOM IN VARCHAR2 := NULL,
	p_TEMPLATE_ID IN NUMBER := NULL,
	p_PERIOD_ID IN NUMBER := NULL,
	p_LOSS_ADJ_TYPE IN NUMBER := NULL,
	p_INTEGRATION_INTERVAL IN VARCHAR2 := NULL,
	p_RETURN_VALUE OUT NUMBER,
	p_RETURN_STATUS OUT PLS_INTEGER
	) IS
BEGIN
	RETAIL_DETERMINANTS.GET_PEAK_DETERMINANT
							(
							SELF,
							p_INTERVAL,
							p_BEGIN_DATE,
							p_END_DATE,
							NVL(p_UOM, GA.DEF_SCHED_UNIT_OF_MEASUREMENT),
							p_TEMPLATE_ID,
							p_PERIOD_ID,
							p_LOSS_ADJ_TYPE,
							p_INTEGRATION_INTERVAL,
							p_RETURN_VALUE,
							p_RETURN_STATUS
							);
END GET_PEAK_DETERMINANT;
-------------------------------------------------------------------------------
OVERRIDING MEMBER PROCEDURE GET_SUM_DETERMINANTS
	(
	p_INTERVAL IN VARCHAR2,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_UOM IN VARCHAR2 := NULL,
	p_TEMPLATE_ID IN NUMBER := NULL,
	p_PERIOD_ID IN NUMBER := NULL,
	p_LOSS_ADJ_TYPE IN NUMBER := NULL,
	p_INTERVAL_MINIMUM_QTY IN NUMBER := NULL,
	p_OPERATION_CODE IN VARCHAR2 := NULL,
	p_RETURN_VALUE OUT NUMBER,
	p_RETURN_STATUS OUT PLS_INTEGER
	) IS
BEGIN
	RETAIL_DETERMINANTS.GET_SUM_DETERMINANTS
							(
							SELF,
							p_INTERVAL,
							p_BEGIN_DATE,
							p_END_DATE,
							NVL(p_UOM, GA.DEF_SCHED_UNIT_OF_MEASUREMENT),
							p_TEMPLATE_ID,
							p_PERIOD_ID,
							p_LOSS_ADJ_TYPE,
              				NULL,
							p_RETURN_VALUE,
							p_RETURN_STATUS
							);
END GET_SUM_DETERMINANTS;
-------------------------------------------------------------------------------
OVERRIDING MEMBER FUNCTION GET_FORMULA_CONTEXTS RETURN MAP_ENTRY_TABLE IS
v_RET MAP_ENTRY_TABLE := MAP_ENTRY_TABLE();
BEGIN
	v_RET.EXTEND;
	v_RET(v_RET.LAST) := MAP_ENTRY(':service_point', UT.GET_LITERAL_FOR_NUMBER(SELF.SERVICE_POINT_ID));
	v_RET.EXTEND;
	v_RET(v_RET.LAST) := MAP_ENTRY(':pse', UT.GET_LITERAL_FOR_NUMBER(SELF.PSE_ID));
	v_RET.EXTEND;
	v_RET(v_RET.LAST) := MAP_ENTRY(':meter_type', UT.GET_LITERAL_FOR_STRING(SELF.METER_TYPE));
	v_RET.EXTEND;
	v_RET(v_RET.LAST) := MAP_ENTRY(':statement_type', UT.GET_LITERAL_FOR_NUMBER(SELF.STATEMENT_TYPE_ID));
	v_RET.EXTEND;
	v_RET(v_RET.LAST) := MAP_ENTRY(':time_zone', UT.GET_LITERAL_FOR_STRING(SELF.TIME_ZONE));
	v_RET.EXTEND;
	v_RET(v_RET.LAST) := MAP_ENTRY(':transactions', UT.GET_LITERAL_FOR_NUMBER_COLL(SELF.TRANSACTION_IDs));
	
	RETURN v_RET;
END GET_FORMULA_CONTEXTS;
-------------------------------------------------------------------------------
MEMBER FUNCTION GET_ACTIVE_TRANSACTIONS
	(
	p_BEGIN_DATE	IN DATE,
	p_END_DATE		IN DATE
	) RETURN NUMBER_COLLECTION IS
BEGIN
	RETURN RETAIL_DETERMINANTS.GET_ACTIVE_TRANSACTIONS(SELF, p_BEGIN_DATE, p_END_DATE);
END GET_ACTIVE_TRANSACTIONS;
-------------------------------------------------------------------------------
CONSTRUCTOR FUNCTION POD_DETERMINANT_ACCESSOR
	(
	p_SERVICE_POINT_ID	IN NUMBER,
	p_PSE_ID			IN NUMBER,
	p_METER_TYPE		IN VARCHAR2,
	p_STATEMENT_TYPE_ID	IN NUMBER,
	p_TIME_ZONE			IN VARCHAR2
	) RETURN SELF AS RESULT IS
BEGIN
	ASSERT(p_SERVICE_POINT_ID IS NOT NULL, 'Service Point ID must be specified', MSGCODES.c_ERR_ARGUMENT);
	ASSERT(p_PSE_ID IS NOT NULL, 'PSE ID must be specified', MSGCODES.c_ERR_ARGUMENT);
	ASSERT(p_STATEMENT_TYPE_ID IS NOT NULL, 'Statement Type ID must be specified', MSGCODES.c_ERR_ARGUMENT);
	ASSERT(p_METER_TYPE IS NULL OR p_METER_TYPE IN ('Period','Interval','Either'), 'Meter Type specified ('||p_METER_TYPE||') is invalid', MSGCODES.c_ERR_ARGUMENT);
	
	IF LOGS.IS_DEBUG_ENABLED THEN
		LOGS.LOG_DEBUG('POD Accessor: SERVICE_POINT_ID = '||p_SERVICE_POINT_ID||', PSE_ID = '||p_PSE_ID||', METER_TYPE = '||p_METER_TYPE||
						', STATEMENT_TYPE_ID = '||p_STATEMENT_TYPE_ID||', TIME_ZONE = '||p_TIME_ZONE);
	END IF;

	-- Initialize member fields
	SELF.SERVICE_POINT_ID := p_SERVICE_POINT_ID;
	SELF.PSE_ID := p_PSE_ID;
	SELF.METER_TYPE := NVL(p_METER_TYPE, 'Either');
	SELF.STATEMENT_TYPE_ID := p_STATEMENT_TYPE_ID;
	
	SELF.TIME_ZONE := NVL(p_TIME_ZONE, GA.LOCAL_TIME_ZONE);
	
	-- Gather interchange transactions
	SELECT T.TRANSACTION_ID
	BULK COLLECT INTO SELF.TRANSACTION_IDs
	FROM INTERCHANGE_TRANSACTION T,
		IT_COMMODITY C,
		SCHEDULE_GROUP SG,
		IT_STATUS ITS
	WHERE T.POD_ID = SELF.SERVICE_POINT_ID
		AND T.PSE_ID = SELF.PSE_ID
		AND T.TRANSACTION_TYPE = 'Load'
		AND C.COMMODITY_ID = T.COMMODITY_ID
		AND C.COMMODITY_ALIAS = 'Retail Load'
		AND SG.SCHEDULE_GROUP_ID(+) = T.SCHEDULE_GROUP_ID
		AND (SG.METER_TYPE = SELF.METER_TYPE OR SELF.METER_TYPE = 'Either')
		AND ITS.TRANSACTION_ID = T.TRANSACTION_ID
		AND ITS.AS_OF_DATE = CONSTANTS.LOW_DATE -- no support for versioning
		AND ITS.TRANSACTION_IS_ACTIVE = 1;

	IF LOGS.IS_DEBUG_ENABLED THEN
		LOGS.LOG_DEBUG('POD Accessor has '||SELF.TRANSACTION_IDs.COUNT||' Transaction IDs');
		IF LOGS.IS_DEBUG_DETAIL_ENABLED THEN
			LOGS.LOG_DEBUG_DETAIL('   Transaction IDs: '||TEXT_UTIL.TO_CHAR_NUMBER_LIST(SELF.TRANSACTION_IDs));
		END IF;
	END IF;
		
	-- Done!
	RETURN;
		
END POD_DETERMINANT_ACCESSOR;
-------------------------------------------------------------------------------
OVERRIDING MEMBER PROCEDURE GET_AVERAGE_INTERVAL_COUNT
(
	p_INVOICE_LINE_BEGIN_DATE 	IN DATE,
	p_INVOICE_LINE_END_DATE 	IN DATE,
	p_UOM 						IN VARCHAR2 := NULL,
	p_QUALITY_CODE 				IN VARCHAR2 := NULL,
	p_STATUS_CODE 				IN VARCHAR2 := NULL,
	p_DATE_RANGE_INTERVAL		IN VARCHAR2 := NULL,
	p_RETURN_VALUE 				OUT NUMBER,
	p_RETURN_STATUS 			OUT PLS_INTEGER
) IS
BEGIN
	-- THIS METHOD IS NOT VALID FOR THE POD_DETERMINANT_ACCESSOR, THROW
    -- AN EXCEPTION
    ERRS.RAISE(MSGCODES.c_ERR_UNSUPPORTED_OPERATION);
END GET_AVERAGE_INTERVAL_COUNT;
-------------------------------------------------------------------------------
END;
/