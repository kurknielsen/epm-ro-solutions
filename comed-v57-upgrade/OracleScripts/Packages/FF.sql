CREATE OR REPLACE PACKAGE FF AS
--Revision $Revision: 1.6 $

-- Financial Forecast package.

FUNCTION WHAT_VERSION RETURN VARCHAR;

PROCEDURE SERVICE_POSITION_REQUEST_SCEN
	(
	p_CALLING_MODULE IN VARCHAR,
	p_MODEL_ID IN NUMBER,
	p_POSITION_TYPE IN NUMBER,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_INPUT_AS_OF_DATE IN DATE,
	p_OUTPUT_AS_OF_DATE IN DATE,
	p_TRACE_ON IN NUMBER,
    p_SCENARIO_ID IN NUMBER,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR
	);

g_LOW_DATE DATE := LOW_DATE;
g_LOCAL_TIME_ZONE CHAR(3) := LOCAL_TIME_ZONE;

g_DOMAIN_NAME VARCHAR(16):= 'Billing';

g_NOT_ASSIGNED  NUMBER(1) := 0;
g_MODEL_ID NUMBER(1) := 2; -- Gas Model.
g_CALLING_MODULE VARCHAR(32);

END FF;
/
CREATE OR REPLACE PACKAGE BODY FF AS
---------------------------------------------------------------------------------------------------
FUNCTION WHAT_VERSION RETURN VARCHAR IS
BEGIN
    RETURN '$Revision: 1.6 $';
END WHAT_VERSION;
----------------------------------------------------------------------------------------------------
FUNCTION GET_COMPONENT
	(
	p_COMPONENT_ID IN NUMBER
	) RETURN COMPONENT%ROWTYPE IS

v_COMPONENT COMPONENT%ROWTYPE;

BEGIN

    SELECT *
	INTO v_COMPONENT
	FROM COMPONENT
	WHERE COMPONENT_ID = p_COMPONENT_ID;

	RETURN v_COMPONENT;

	EXCEPTION
	    WHEN NO_DATA_FOUND THEN
		    RETURN NULL;

END GET_COMPONENT;
---------------------------------------------------------------------------------------------------
PROCEDURE GET_SERVICE_CONTRACT_LIMITS
	(
	p_SERVICE_COMPONENT IN SERVICE_COMPONENT_TYPE,
	p_DETERMINANTS IN OUT NOCOPY DETERMINANT_TABLE
	) AS

v_INDEX BINARY_INTEGER;
v_ELASPSED PLS_INTEGER := DBMS_UTILITY.GET_TIME;

BEGIN

	IF NOT p_SERVICE_COMPONENT.CUSTOMER_ID = g_NOT_ASSIGNED THEN
		SELECT DETERMINANT_TYPE(g_NOT_ASSIGNED, GREATEST(D.BEGIN_DATE, p_SERVICE_COMPONENT.END_DATE), LEAST(NVL(D.END_DATE, p_SERVICE_COMPONENT.END_DATE), p_SERVICE_COMPONENT.END_DATE), NULL, D.LIMIT_QUANTITY, D.LIMIT_QUANTITY, NULL, NULL, p_SERVICE_COMPONENT.ACCOUNT_SERVICE_ID, NULL, p_SERVICE_COMPONENT.CUSTOMER_ID)
		BULK COLLECT INTO p_DETERMINANTS
		FROM ACCOUNT_SERVICE A, AGGREGATE_ACCOUNT_CUSTOMER B, CONTRACT_ASSIGNMENT C, CONTRACT_LIMIT_QUANTITY D
		WHERE A.ACCOUNT_SERVICE_ID = p_SERVICE_COMPONENT.ACCOUNT_SERVICE_ID
			AND B.AGGREGATE_ID = A.AGGREGATE_ID
			AND B.CUSTOMER_ID = p_SERVICE_COMPONENT.CUSTOMER_ID
			AND B.BEGIN_DATE <= p_SERVICE_COMPONENT.END_DATE
			AND NVL(B.END_DATE, p_SERVICE_COMPONENT.END_DATE) >= p_SERVICE_COMPONENT.BEGIN_DATE
			AND C.CONTRACT_ID = D.CONTRACT_ID
			AND C.ENTITY_DOMAIN_ID = -560
			AND C.OWNER_ENTITY_ID = B.CUSTOMER_ID
			AND C.BEGIN_DATE <= p_SERVICE_COMPONENT.END_DATE
			AND NVL(C.END_DATE, p_SERVICE_COMPONENT.END_DATE) >= p_SERVICE_COMPONENT.BEGIN_DATE
			AND D.LIMIT_ID = (SELECT BASE_LIMIT_ID FROM COMPONENT WHERE COMPONENT_ID = p_SERVICE_COMPONENT.COMPONENT_ID)
			AND D.BEGIN_DATE <= p_SERVICE_COMPONENT.END_DATE
			AND NVL(D.END_DATE, p_SERVICE_COMPONENT.END_DATE) >= p_SERVICE_COMPONENT.BEGIN_DATE;
	ELSE
		SELECT DETERMINANT_TYPE(g_NOT_ASSIGNED, GREATEST(C.BEGIN_DATE, p_SERVICE_COMPONENT.END_DATE), LEAST(NVL(C.END_DATE, p_SERVICE_COMPONENT.END_DATE), p_SERVICE_COMPONENT.END_DATE), NULL, C.LIMIT_QUANTITY, C.LIMIT_QUANTITY, NULL, NULL, p_SERVICE_COMPONENT.ACCOUNT_SERVICE_ID, NULL, p_SERVICE_COMPONENT.CUSTOMER_ID)
		BULK COLLECT INTO p_DETERMINANTS
		FROM ACCOUNT_SERVICE A, CONTRACT_ASSIGNMENT B, CONTRACT_LIMIT_QUANTITY C
		WHERE A.ACCOUNT_SERVICE_ID = p_SERVICE_COMPONENT.ACCOUNT_SERVICE_ID
			AND B.CONTRACT_ID = C.CONTRACT_ID
			AND B.ENTITY_DOMAIN_ID IN (-170, -190)
			AND B.OWNER_ENTITY_ID IN (A.ACCOUNT_ID, A.METER_ID)
			AND B.BEGIN_DATE <= p_SERVICE_COMPONENT.END_DATE
			AND NVL(B.END_DATE, p_SERVICE_COMPONENT.END_DATE) >= p_SERVICE_COMPONENT.BEGIN_DATE
			AND C.LIMIT_ID = (SELECT BASE_LIMIT_ID FROM COMPONENT WHERE COMPONENT_ID = p_SERVICE_COMPONENT.COMPONENT_ID)
			AND C.BEGIN_DATE <= p_SERVICE_COMPONENT.END_DATE
			AND NVL(C.END_DATE, p_SERVICE_COMPONENT.END_DATE) >= p_SERVICE_COMPONENT.BEGIN_DATE;
	END IF;

	v_INDEX := p_DETERMINANTS.FIRST;
	WHILE v_INDEX <= p_DETERMINANTS.LAST LOOP
		p_DETERMINANTS(v_INDEX).COERCE_TO_MONTH;
		v_INDEX := p_DETERMINANTS.NEXT(v_INDEX);
	END LOOP;

	CU.TRACE_DETERMINANTS('SERVICE CONTRACT LIMIT DETERMINANTS', p_DETERMINANTS);

	IF LOGS.IS_DEBUG_ENABLED THEN
		LOGS.LOG_DEBUG('GET_SERVICE_CONTRACT_LIMITS TIME= ' || TO_CHAR(DBMS_UTILITY.GET_TIME - v_ELASPSED) || ', COUNT=' || p_DETERMINANTS.COUNT);
	END IF;

END GET_SERVICE_CONTRACT_LIMITS;
---------------------------------------------------------------------------------------------------
PROCEDURE PUT_SERVICE_POSITION_CHARGE
	(
	p_SERVICE_POSITION_CHARGE IN SERVICE_POSITION_CHARGE%ROWTYPE
	) AS

BEGIN

	IF LOGS.IS_DEBUG_DETAIL_ENABLED THEN
		LOGS.LOG_DEBUG_DETAIL(TO_CHAR(p_SERVICE_POSITION_CHARGE.SERVICE_ID) || ',' ||
			p_SERVICE_POSITION_CHARGE.POSITION_TYPE || ',' ||
			TEXT_UTIL.TO_CHAR_DATE(p_SERVICE_POSITION_CHARGE.CHARGE_DATE) || ',' ||
			p_SERVICE_POSITION_CHARGE.PRODUCT_TYPE || ',' ||
			TO_CHAR(p_SERVICE_POSITION_CHARGE.CUSTOMER_ID) || ',' ||
			TO_CHAR(p_SERVICE_POSITION_CHARGE.PRODUCT_ID) || ',' ||
			TO_CHAR(p_SERVICE_POSITION_CHARGE.COMPONENT_ID) || ',' ||
			TO_CHAR(p_SERVICE_POSITION_CHARGE.PERIOD_ID) || ',' ||
			TO_CHAR(p_SERVICE_POSITION_CHARGE.BAND_NUMBER) || ',' ||
			TO_CHAR(p_SERVICE_POSITION_CHARGE.CHARGE_QUANTITY) || ',' ||
			TO_CHAR(p_SERVICE_POSITION_CHARGE.CHARGE_RATE) || ',' ||
			TO_CHAR(p_SERVICE_POSITION_CHARGE.CHARGE_AMOUNT) || ',' ||
			TO_CHAR(p_SERVICE_POSITION_CHARGE.IS_DETERMINANT));
	END IF;

    UPDATE SERVICE_POSITION_CHARGE SET
		CHARGE_QUANTITY = p_SERVICE_POSITION_CHARGE.CHARGE_QUANTITY,
		CHARGE_RATE = p_SERVICE_POSITION_CHARGE.CHARGE_RATE,
		CHARGE_AMOUNT = p_SERVICE_POSITION_CHARGE.CHARGE_AMOUNT,
		IS_DETERMINANT = p_SERVICE_POSITION_CHARGE.IS_DETERMINANT
	WHERE SERVICE_ID = p_SERVICE_POSITION_CHARGE.SERVICE_ID
		AND POSITION_TYPE = p_SERVICE_POSITION_CHARGE.POSITION_TYPE
		AND CHARGE_DATE = p_SERVICE_POSITION_CHARGE.CHARGE_DATE
		AND PRODUCT_TYPE = p_SERVICE_POSITION_CHARGE.PRODUCT_TYPE
		AND CUSTOMER_ID = p_SERVICE_POSITION_CHARGE.CUSTOMER_ID
		AND PRODUCT_ID = p_SERVICE_POSITION_CHARGE.PRODUCT_ID
		AND COMPONENT_ID = p_SERVICE_POSITION_CHARGE.COMPONENT_ID
        AND PERIOD_ID = p_SERVICE_POSITION_CHARGE.PERIOD_ID
		AND BAND_NUMBER = p_SERVICE_POSITION_CHARGE.BAND_NUMBER;

	IF SQL%NOTFOUND THEN
		INSERT INTO SERVICE_POSITION_CHARGE (
			SERVICE_ID,
			POSITION_TYPE,
			CHARGE_DATE,
			PRODUCT_TYPE,
			CUSTOMER_ID,
			PRODUCT_ID,
			COMPONENT_ID,
            PERIOD_ID,
			BAND_NUMBER,
			CHARGE_QUANTITY,
			CHARGE_RATE,
			CHARGE_AMOUNT,
			IS_DETERMINANT)
		VALUES (
			p_SERVICE_POSITION_CHARGE.SERVICE_ID,
			p_SERVICE_POSITION_CHARGE.POSITION_TYPE,
			p_SERVICE_POSITION_CHARGE.CHARGE_DATE,
			p_SERVICE_POSITION_CHARGE.PRODUCT_TYPE,
			p_SERVICE_POSITION_CHARGE.CUSTOMER_ID,
			p_SERVICE_POSITION_CHARGE.PRODUCT_ID,
			p_SERVICE_POSITION_CHARGE.COMPONENT_ID,
            p_SERVICE_POSITION_CHARGE.PERIOD_ID,
			p_SERVICE_POSITION_CHARGE.BAND_NUMBER,
			p_SERVICE_POSITION_CHARGE.CHARGE_QUANTITY,
			p_SERVICE_POSITION_CHARGE.CHARGE_RATE,
			p_SERVICE_POSITION_CHARGE.CHARGE_AMOUNT,
			p_SERVICE_POSITION_CHARGE.IS_DETERMINANT);
	END IF;

END PUT_SERVICE_POSITION_CHARGE;
---------------------------------------------------------------------------------------------------
PROCEDURE PUT_SERVICE_POSITION_CHARGES
	(
	p_SCENARIO_ID IN NUMBER,
	p_POSITION_TYPE IN NUMBER,
	p_SERVICE_COMPONENT IN SERVICE_COMPONENT_TYPE,
	p_AS_OF_DATE IN DATE,
	p_CHARGE_COMPONENTS IN CHARGE_COMPONENT_TABLE
	) AS

v_INDEX BINARY_INTEGER;
v_PROVIDER_SERVICE_ID NUMBER(9);
v_SERVICE_DELIVERY_ID NUMBER(9);
v_SERVICE_POSITION_CHARGE SERVICE_POSITION_CHARGE%ROWTYPE;
v_ELASPSED PLS_INTEGER := DBMS_UTILITY.GET_TIME;

BEGIN

	IF LOGS.IS_DEBUG_DETAIL_ENABLED THEN
		LOGS.LOG_DEBUG_DETAIL('PUT_SERVICE_POSITION_CHARGES');
		LOGS.LOG_DEBUG_DETAIL('<service id>,<position type>,<position date>,<product type>,<customer id>,<product id>,<component id>,<quantity>,<rate>,<amount>');
	END IF;

	v_SERVICE_POSITION_CHARGE.POSITION_TYPE := p_POSITION_TYPE;
	v_SERVICE_POSITION_CHARGE.PRODUCT_TYPE := p_SERVICE_COMPONENT.PRODUCT_TYPE;
	v_SERVICE_POSITION_CHARGE.CUSTOMER_ID := p_SERVICE_COMPONENT.CUSTOMER_ID;

	v_INDEX := p_CHARGE_COMPONENTS.FIRST;
	WHILE v_INDEX <= p_CHARGE_COMPONENTS.LAST LOOP
		IF p_CHARGE_COMPONENTS(v_INDEX).RATE <> 0 THEN
			v_PROVIDER_SERVICE_ID := CS.GET_PROVIDER_SERVICE_ID(p_SERVICE_COMPONENT.ACCOUNT_SERVICE_ID, p_CHARGE_COMPONENTS(v_INDEX).BEGIN_DATE);
			v_SERVICE_DELIVERY_ID := CS.GET_SERVICE_DELIVERY_ID(p_SERVICE_COMPONENT.ACCOUNT_SERVICE_ID, v_PROVIDER_SERVICE_ID, p_CHARGE_COMPONENTS(v_INDEX).BEGIN_DATE);
			v_SERVICE_POSITION_CHARGE.SERVICE_ID := CS.GET_SERVICE_ID(g_MODEL_ID, p_SCENARIO_ID, p_AS_OF_DATE, v_PROVIDER_SERVICE_ID, p_SERVICE_COMPONENT.ACCOUNT_SERVICE_ID, v_SERVICE_DELIVERY_ID);
			v_SERVICE_POSITION_CHARGE.CHARGE_DATE := NVL(p_CHARGE_COMPONENTS(v_INDEX).BILL_CYCLE_MONTH, p_CHARGE_COMPONENTS(v_INDEX).BEGIN_DATE);
			v_SERVICE_POSITION_CHARGE.PRODUCT_ID := p_CHARGE_COMPONENTS(v_INDEX).PRODUCT_ID;
			v_SERVICE_POSITION_CHARGE.COMPONENT_ID := p_CHARGE_COMPONENTS(v_INDEX).COMPONENT_ID;
            v_SERVICE_POSITION_CHARGE.PERIOD_ID := NVL(p_CHARGE_COMPONENTS(v_INDEX).PERIOD_ID, g_NOT_ASSIGNED);
            v_SERVICE_POSITION_CHARGE.BAND_NUMBER := NVL(p_CHARGE_COMPONENTS(v_INDEX).BAND_NUMBER, g_NOT_ASSIGNED);
			v_SERVICE_POSITION_CHARGE.CHARGE_QUANTITY := p_CHARGE_COMPONENTS(v_INDEX).QUANTITY;
			v_SERVICE_POSITION_CHARGE.CHARGE_RATE := p_CHARGE_COMPONENTS(v_INDEX).RATE;
			v_SERVICE_POSITION_CHARGE.CHARGE_AMOUNT := p_CHARGE_COMPONENTS(v_INDEX).AMOUNT;
			SELECT DECODE(p_CHARGE_COMPONENTS(v_INDEX).CHARGE_TYPE,'C',1,'E',1,'P',1,'D',1,0) INTO v_SERVICE_POSITION_CHARGE.IS_DETERMINANT FROM DUAL;
			PUT_SERVICE_POSITION_CHARGE(v_SERVICE_POSITION_CHARGE);
		END IF;
		v_INDEX := p_CHARGE_COMPONENTS.NEXT(v_INDEX);
	END LOOP;

	IF LOGS.IS_DEBUG_ENABLED THEN
		LOGS.LOG_DEBUG('PUT_SERVICE_POSITION_CHARGES TIME= ' || TO_CHAR(DBMS_UTILITY.GET_TIME - v_ELASPSED));
	END IF;

END PUT_SERVICE_POSITION_CHARGES;
---------------------------------------------------------------------------------------------------
PROCEDURE GET_SERVICE_CONSUMPTION
	(
	p_CONSUMPTION_CODE IN CHAR,
	p_SERVICE_COMPONENT IN SERVICE_COMPONENT_TYPE,
	p_AS_OF_DATE IN DATE,
    p_SCENARIO_ID IN NUMBER,
	p_DETERMINANTS IN OUT NOCOPY DETERMINANT_TABLE
	) AS

v_INDEX BINARY_INTEGER;
v_ELASPSED PLS_INTEGER := DBMS_UTILITY.GET_TIME;

BEGIN

	IF GA.VERSION_CONSUMPTION THEN
		SELECT DETERMINANT_TYPE(g_NOT_ASSIGNED, B.BEGIN_DATE, B.END_DATE, B.BILL_CYCLE_MONTH, B.BILLED_USAGE, B.BILLED_USAGE, B.METERS_READ, B.BILL_CODE, A.ACCOUNT_SERVICE_ID, B.CONSUMPTION_ID, g_NOT_ASSIGNED)
		BULK COLLECT INTO p_DETERMINANTS
		FROM SERVICE A, SERVICE_CONSUMPTION B
		WHERE A.MODEL_ID = g_MODEL_ID
			AND A.SCENARIO_ID = p_SCENARIO_ID
			AND A.AS_OF_DATE =
				(SELECT MAX(AS_OF_DATE)
				FROM SERVICE
				WHERE MODEL_ID = A.MODEL_ID
					AND SCENARIO_ID = A.SCENARIO_ID
					AND AS_OF_DATE <= p_AS_OF_DATE
					AND PROVIDER_SERVICE_ID = A.PROVIDER_SERVICE_ID
					AND ACCOUNT_SERVICE_ID = A.ACCOUNT_SERVICE_ID)
			AND A.PROVIDER_SERVICE_ID = A.PROVIDER_SERVICE_ID
			AND A.ACCOUNT_SERVICE_ID = p_SERVICE_COMPONENT.ACCOUNT_SERVICE_ID
			AND B.SERVICE_ID = A.SERVICE_ID
			AND B.BEGIN_DATE <= p_SERVICE_COMPONENT.END_DATE
			AND B.END_DATE BETWEEN p_SERVICE_COMPONENT.BEGIN_DATE AND p_SERVICE_COMPONENT.END_DATE
			AND B.BILL_CODE = B.BILL_CODE
			AND B.CONSUMPTION_CODE = p_CONSUMPTION_CODE
			AND B.IGNORE_CONSUMPTION = 0
			AND B.UNIT_OF_MEASUREMENT = GA.DEFAULT_UNIT_OF_MEASUREMENT;
	ELSE
		SELECT DETERMINANT_TYPE(g_NOT_ASSIGNED, B.BEGIN_DATE, B.END_DATE, B.BILL_CYCLE_MONTH, B.BILLED_USAGE, B.BILLED_USAGE, B.METERS_READ, B.BILL_CODE, A.ACCOUNT_SERVICE_ID, B.CONSUMPTION_ID, g_NOT_ASSIGNED)
		BULK COLLECT INTO p_DETERMINANTS
		FROM SERVICE A, SERVICE_CONSUMPTION B
		WHERE A.MODEL_ID = g_MODEL_ID
			AND A.SCENARIO_ID = p_SCENARIO_ID
			AND A.AS_OF_DATE = g_LOW_DATE
			AND A.PROVIDER_SERVICE_ID = A.PROVIDER_SERVICE_ID
			AND A.ACCOUNT_SERVICE_ID = p_SERVICE_COMPONENT.ACCOUNT_SERVICE_ID
			AND B.SERVICE_ID = A.SERVICE_ID
			AND B.BEGIN_DATE <= p_SERVICE_COMPONENT.END_DATE
			AND B.END_DATE BETWEEN p_SERVICE_COMPONENT.BEGIN_DATE AND p_SERVICE_COMPONENT.END_DATE
			AND B.BILL_CODE = B.BILL_CODE
			AND B.CONSUMPTION_CODE = p_CONSUMPTION_CODE
			AND B.IGNORE_CONSUMPTION = g_NOT_ASSIGNED
			AND B.UNIT_OF_MEASUREMENT = GA.DEFAULT_UNIT_OF_MEASUREMENT;
	END IF;

	v_INDEX := p_DETERMINANTS.FIRST;
	WHILE v_INDEX <= p_DETERMINANTS.LAST LOOP
		p_DETERMINANTS(v_INDEX).COERCE_TO_MONTH;
		v_INDEX := p_DETERMINANTS.NEXT(v_INDEX);
	END LOOP;

	IF LOGS.IS_DEBUG_ENABLED THEN
		LOGS.LOG_DEBUG('GET_SERVICE_CONSUMPTION TIME= ' || TO_CHAR(DBMS_UTILITY.GET_TIME - v_ELASPSED) || ', COUNT=' || p_DETERMINANTS.COUNT);
	END IF;

END GET_SERVICE_CONSUMPTION;
---------------------------------------------------------------------------------------------------
PROCEDURE GET_CUSTOMER_CONSUMPTION
	(
	p_CONSUMPTION_CODE IN CHAR,
	p_SERVICE_COMPONENT IN SERVICE_COMPONENT_TYPE,
	p_DETERMINANTS IN OUT NOCOPY DETERMINANT_TABLE
	) AS

v_INDEX BINARY_INTEGER;
v_ELASPSED PLS_INTEGER := DBMS_UTILITY.GET_TIME;

BEGIN

	SELECT DETERMINANT_TYPE(g_NOT_ASSIGNED, C.BEGIN_DATE, C.END_DATE, C.BILL_CYCLE_MONTH, C.BILLED_USAGE, C.BILLED_USAGE, C.METERS_READ, C.BILL_CODE, A.ACCOUNT_SERVICE_ID, C.CONSUMPTION_ID, C.CUSTOMER_ID)
	BULK COLLECT INTO p_DETERMINANTS
	FROM ACCOUNT_SERVICE A, AGGREGATE_ACCOUNT_CUSTOMER B, CUSTOMER_CONSUMPTION C
	WHERE B.AGGREGATE_ID = A.AGGREGATE_ID
		AND B.CUSTOMER_ID = p_SERVICE_COMPONENT.CUSTOMER_ID
		AND B.BEGIN_DATE <= p_SERVICE_COMPONENT.END_DATE
		AND NVL(B.END_DATE, p_SERVICE_COMPONENT.END_DATE) >= p_SERVICE_COMPONENT.BEGIN_DATE
		AND C.CUSTOMER_ID = B.CUSTOMER_ID
		AND C.BEGIN_DATE <= p_SERVICE_COMPONENT.END_DATE
		AND C.END_DATE BETWEEN p_SERVICE_COMPONENT.BEGIN_DATE AND p_SERVICE_COMPONENT.END_DATE
		AND C.BILL_CODE = C.BILL_CODE
		AND C.CONSUMPTION_CODE = p_CONSUMPTION_CODE
		AND C.IGNORE_CONSUMPTION = g_NOT_ASSIGNED;

	v_INDEX := p_DETERMINANTS.FIRST;
	WHILE v_INDEX <= p_DETERMINANTS.LAST LOOP
		p_DETERMINANTS(v_INDEX).COERCE_TO_MONTH;
		v_INDEX := p_DETERMINANTS.NEXT(v_INDEX);
	END LOOP;

	IF LOGS.IS_DEBUG_ENABLED THEN
		LOGS.LOG_DEBUG('GET_CUSTOMER_CONSUMPTION TIME= ' || TO_CHAR(DBMS_UTILITY.GET_TIME - v_ELASPSED) || ', COUNT=' || p_DETERMINANTS.COUNT);
	END IF;

END GET_CUSTOMER_CONSUMPTION;
---------------------------------------------------------------------------------------------------
PROCEDURE GET_SERVICE_LOAD
	(
    p_BEGIN_DATE IN DATE,
    p_END_DATE IN DATE,
	p_SERVICE_CODE IN CHAR,
	p_SERVICE_COMPONENT IN SERVICE_COMPONENT_TYPE,
	p_AS_OF_DATE IN DATE,
    p_SCENARIO_ID IN NUMBER,
	p_DETERMINANTS IN OUT NOCOPY DETERMINANT_TABLE
	) AS

v_BILL_CYCLE_MONTH DATE;
v_IS_VERSIONED BOOLEAN := (GA.VERSION_FORECAST AND p_SERVICE_CODE = GA.FORECAST_SERVICE) OR (GA.VERSION_BACKCAST AND p_SERVICE_CODE = GA.BACKCAST_SERVICE) OR (GA.VERSION_ACTUAL AND p_SERVICE_CODE = GA.ACTUAL_SERVICE);
v_ELASPSED PLS_INTEGER := DBMS_UTILITY.GET_TIME;
v_WEEKEND_DAYS NUMBER(4) := 1; --MULTIPLIER FOR NUMBER OF WEEKEND DAYS IN DATE RANGE FOR SCENARIOS
v_WEEKDAY_DAYS NUMBER(4) := 1; --MULTIPLIER FOR NUMBER OF WEEKDAY DAYS IN DATE RANGE FOR SCENARIOS
BEGIN

	IF GA.ENABLE_CONSUMPTION_END_DATE THEN
		v_BILL_CYCLE_MONTH := TRUNC(p_END_DATE, 'MONTH');
	ELSE
		v_BILL_CYCLE_MONTH := TRUNC(p_BEGIN_DATE, 'MONTH');
	END IF;

	IF NOT p_SCENARIO_ID = GA.BASE_SCENARIO_ID THEN
		NUM_DAY_TYPES_IN_MONTH(p_SERVICE_COMPONENT.BEGIN_DATE,v_WEEKDAY_DAYS,v_WEEKEND_DAYS);
		IF LOGS.IS_DEBUG_ENABLED THEN
			LOGS.LOG_DEBUG('WEEKDAY_DAYS=' || TO_CHAR(v_WEEKDAY_DAYS));
			LOGS.LOG_DEBUG('WEEKEND_DAYS=' || TO_CHAR(v_WEEKEND_DAYS));
		END IF;
	END IF;

	IF v_IS_VERSIONED THEN
		SELECT DETERMINANT_TYPE(g_NOT_ASSIGNED, B.LOAD_DATE, B.LOAD_DATE, v_BILL_CYCLE_MONTH,
			SUM(DECODE(B.LOAD_CODE,GA.WEEK_DAY,v_WEEKDAY_DAYS,GA.WEEK_END,v_WEEKEND_DAYS,1) * (B.LOAD_VAL + B.TX_LOSS_VAL + B.DX_LOSS_VAL + B.UE_LOSS_VAL)),
			SUM(DECODE(B.LOAD_CODE,GA.WEEK_DAY,v_WEEKDAY_DAYS,GA.WEEK_END,v_WEEKEND_DAYS,1) * (B.LOAD_VAL + B.TX_LOSS_VAL + B.DX_LOSS_VAL + B.UE_LOSS_VAL)),
			g_NOT_ASSIGNED, 'B', A.ACCOUNT_SERVICE_ID, g_NOT_ASSIGNED, g_NOT_ASSIGNED)
		BULK COLLECT INTO p_DETERMINANTS
		FROM SERVICE A, SERVICE_LOAD B
		WHERE A.MODEL_ID = g_MODEL_ID
			AND A.SCENARIO_ID = p_SCENARIO_ID
			AND A.AS_OF_DATE =
				(SELECT MAX(AS_OF_DATE)
				FROM SERVICE
				WHERE MODEL_ID = A.MODEL_ID
					AND SCENARIO_ID = A.SCENARIO_ID
					AND AS_OF_DATE <= p_AS_OF_DATE
					AND PROVIDER_SERVICE_ID = A.PROVIDER_SERVICE_ID
					AND ACCOUNT_SERVICE_ID = A.ACCOUNT_SERVICE_ID)
			AND A.PROVIDER_SERVICE_ID = A.PROVIDER_SERVICE_ID
			AND A.ACCOUNT_SERVICE_ID = p_SERVICE_COMPONENT.ACCOUNT_SERVICE_ID
			AND B.SERVICE_ID = A.SERVICE_ID
			AND B.SERVICE_CODE = p_SERVICE_CODE
			AND B.LOAD_DATE BETWEEN p_BEGIN_DATE AND p_END_DATE
			AND B.LOAD_CODE IN (GA.STANDARD, GA.WEEK_DAY, GA.WEEK_END)
		GROUP BY A.ACCOUNT_SERVICE_ID, B.LOAD_DATE;
	ELSE
		SELECT DETERMINANT_TYPE(g_NOT_ASSIGNED, B.LOAD_DATE, B.LOAD_DATE, v_BILL_CYCLE_MONTH,
			SUM(DECODE(B.LOAD_CODE,GA.WEEK_DAY,v_WEEKDAY_DAYS,GA.WEEK_END,v_WEEKEND_DAYS,1) * (B.LOAD_VAL + B.TX_LOSS_VAL + B.DX_LOSS_VAL + B.UE_LOSS_VAL)),
			SUM(DECODE(B.LOAD_CODE,GA.WEEK_DAY,v_WEEKDAY_DAYS,GA.WEEK_END,v_WEEKEND_DAYS,1) * (B.LOAD_VAL + B.TX_LOSS_VAL + B.DX_LOSS_VAL + B.UE_LOSS_VAL)),
			g_NOT_ASSIGNED, 'B', A.ACCOUNT_SERVICE_ID, g_NOT_ASSIGNED, g_NOT_ASSIGNED)
		BULK COLLECT INTO p_DETERMINANTS
		FROM SERVICE A, SERVICE_LOAD B
		WHERE A.MODEL_ID = g_MODEL_ID
			AND A.SCENARIO_ID = p_SCENARIO_ID
			AND A.AS_OF_DATE = g_LOW_DATE
			AND A.PROVIDER_SERVICE_ID = A.PROVIDER_SERVICE_ID
			AND A.ACCOUNT_SERVICE_ID = p_SERVICE_COMPONENT.ACCOUNT_SERVICE_ID
			AND B.SERVICE_ID = A.SERVICE_ID
			AND B.SERVICE_CODE = p_SERVICE_CODE
			AND B.LOAD_DATE BETWEEN p_BEGIN_DATE AND p_END_DATE
			AND B.LOAD_CODE IN (GA.STANDARD, GA.WEEK_DAY, GA.WEEK_END)
		GROUP BY A.ACCOUNT_SERVICE_ID, B.LOAD_DATE;
	END IF;

	IF LOGS.IS_DEBUG_ENABLED THEN
		LOGS.LOG_DEBUG('GET_SERVICE_LOAD TIME= ' || TO_CHAR(DBMS_UTILITY.GET_TIME - v_ELASPSED) || ', COUNT=' || p_DETERMINANTS.COUNT);
	END IF;

END GET_SERVICE_LOAD;
---------------------------------------------------------------------------------------------------
PROCEDURE GET_CUSTOMER_SERVICE_LOAD
	(
    p_BEGIN_DATE IN DATE,
    p_END_DATE IN DATE,
	p_SERVICE_CODE IN CHAR,
	p_SERVICE_COMPONENT IN SERVICE_COMPONENT_TYPE,
	p_AS_OF_DATE IN DATE,
    p_SCENARIO_ID IN NUMBER,
	p_DETERMINANTS IN OUT NOCOPY DETERMINANT_TABLE
	) AS

v_BILL_CYCLE_MONTH DATE;
v_IS_VERSIONED BOOLEAN := (GA.VERSION_FORECAST AND p_SERVICE_CODE = GA.FORECAST_SERVICE) OR (GA.VERSION_BACKCAST AND p_SERVICE_CODE = GA.BACKCAST_SERVICE) OR (GA.VERSION_ACTUAL AND p_SERVICE_CODE = GA.ACTUAL_SERVICE);
v_ELASPSED PLS_INTEGER := DBMS_UTILITY.GET_TIME;

BEGIN

	IF GA.ENABLE_CONSUMPTION_END_DATE THEN
		v_BILL_CYCLE_MONTH := TRUNC(p_END_DATE, 'MONTH');
	ELSE
		v_BILL_CYCLE_MONTH := TRUNC(p_BEGIN_DATE, 'MONTH');
	END IF;

	IF v_IS_VERSIONED THEN
		SELECT DETERMINANT_TYPE(g_NOT_ASSIGNED, B.LOAD_DATE, B.LOAD_DATE, v_BILL_CYCLE_MONTH, SUM(B.LOAD_VAL + B.TX_LOSS_VAL + B.DX_LOSS_VAL + B.UE_LOSS_VAL), SUM(B.LOAD_VAL + B.TX_LOSS_VAL + B.DX_LOSS_VAL + B.UE_LOSS_VAL), g_NOT_ASSIGNED, 'B', A.ACCOUNT_SERVICE_ID, g_NOT_ASSIGNED, B.CUSTOMER_ID)
		BULK COLLECT INTO p_DETERMINANTS
		FROM SERVICE A, CUSTOMER_SERVICE_LOAD B
		WHERE A.MODEL_ID = g_MODEL_ID
			AND A.SCENARIO_ID = p_SCENARIO_ID
			AND A.AS_OF_DATE =
				(SELECT MAX(AS_OF_DATE)
				FROM SERVICE
				WHERE MODEL_ID = A.MODEL_ID
					AND SCENARIO_ID = A.SCENARIO_ID
					AND AS_OF_DATE <= p_AS_OF_DATE
					AND PROVIDER_SERVICE_ID = A.PROVIDER_SERVICE_ID
					AND ACCOUNT_SERVICE_ID = A.ACCOUNT_SERVICE_ID)
			AND A.PROVIDER_SERVICE_ID = A.PROVIDER_SERVICE_ID
			AND A.ACCOUNT_SERVICE_ID = p_SERVICE_COMPONENT.ACCOUNT_SERVICE_ID
			AND B.SERVICE_ID = A.SERVICE_ID
			AND B.SERVICE_CODE = p_SERVICE_CODE
			AND B.LOAD_DATE BETWEEN p_BEGIN_DATE AND p_END_DATE
			AND B.LOAD_CODE = GA.STANDARD
			GROUP BY A.ACCOUNT_SERVICE_ID, B.CUSTOMER_ID, B.LOAD_DATE;
	ELSE
		SELECT DETERMINANT_TYPE(g_NOT_ASSIGNED, B.LOAD_DATE, B.LOAD_DATE, v_BILL_CYCLE_MONTH, SUM(B.LOAD_VAL + B.TX_LOSS_VAL + B.DX_LOSS_VAL + B.UE_LOSS_VAL), SUM(B.LOAD_VAL + B.TX_LOSS_VAL + B.DX_LOSS_VAL + B.UE_LOSS_VAL), g_NOT_ASSIGNED, 'B', A.ACCOUNT_SERVICE_ID, g_NOT_ASSIGNED, B.CUSTOMER_ID)
		BULK COLLECT INTO p_DETERMINANTS
		FROM SERVICE A, CUSTOMER_SERVICE_LOAD B
		WHERE A.MODEL_ID = g_MODEL_ID
			AND A.SCENARIO_ID = p_SCENARIO_ID
			AND A.AS_OF_DATE = g_LOW_DATE
			AND A.PROVIDER_SERVICE_ID = A.PROVIDER_SERVICE_ID
			AND A.ACCOUNT_SERVICE_ID = p_SERVICE_COMPONENT.ACCOUNT_SERVICE_ID
			AND B.SERVICE_ID = A.SERVICE_ID
			AND B.CUSTOMER_ID = p_SERVICE_COMPONENT.CUSTOMER_ID
			AND B.SERVICE_CODE = p_SERVICE_CODE
			AND B.LOAD_DATE BETWEEN p_BEGIN_DATE AND p_END_DATE
			AND B.LOAD_CODE = GA.STANDARD
			GROUP BY A.ACCOUNT_SERVICE_ID, B.CUSTOMER_ID, B.LOAD_DATE;
	END IF;

	IF LOGS.IS_DEBUG_ENABLED THEN
		LOGS.LOG_DEBUG('GET_CUSTOMER_SERVICE_LOAD TIME= ' || TO_CHAR(DBMS_UTILITY.GET_TIME - v_ELASPSED) || ', COUNT=' || p_DETERMINANTS.COUNT);
	END IF;

END GET_CUSTOMER_SERVICE_LOAD;
---------------------------------------------------------------------------------------------------
PROCEDURE GET_SERVICE_DETERMINANTS
	(
    p_BEGIN_DATE IN DATE,
    p_END_DATE IN DATE,
	p_SERVICE_CODE IN CHAR,
	p_CONSUMPTION_CODE IN CHAR,
	p_SERVICE_COMPONENT IN SERVICE_COMPONENT_TYPE,
	p_AS_OF_DATE IN DATE,
	p_DETERMINANTS IN OUT NOCOPY DETERMINANT_TABLE,
    p_SCENARIO_ID IN NUMBER := GA.BASE_SCENARIO_ID
	) AS

v_ELASPSED PLS_INTEGER := DBMS_UTILITY.GET_TIME;

BEGIN

	IF LOGS.IS_DEBUG_DETAIL_ENABLED THEN
		LOGS.LOG_DEBUG_DETAIL('GET_SERVICE_DETERMINANTS');
		LOGS.LOG_DEBUG_DETAIL('ACCOUNT_SERVICE_ID=' || TO_CHAR(p_SERVICE_COMPONENT.ACCOUNT_SERVICE_ID));
		LOGS.LOG_DEBUG_DETAIL('CUSTOMER_ID=' || TO_CHAR(p_SERVICE_COMPONENT.CUSTOMER_ID));
		LOGS.LOG_DEBUG_DETAIL('BEGIN_DATE=' || TEXT_UTIL.TO_CHAR_DATE(p_SERVICE_COMPONENT.BEGIN_DATE));
		LOGS.LOG_DEBUG_DETAIL('END_DATE=' || TEXT_UTIL.TO_CHAR_DATE(p_SERVICE_COMPONENT.END_DATE));
		LOGS.LOG_DEBUG_DETAIL('SCENARIO_ID=' || TO_CHAR(p_SCENARIO_ID));
	END IF;

	IF p_SERVICE_CODE IS NOT NULL THEN
		IF p_SERVICE_COMPONENT.CUSTOMER_ID <> g_NOT_ASSIGNED THEN
			GET_CUSTOMER_SERVICE_LOAD(p_BEGIN_DATE, p_END_DATE, p_SERVICE_CODE, p_SERVICE_COMPONENT, p_AS_OF_DATE, p_SCENARIO_ID, p_DETERMINANTS);
		ELSE
			GET_SERVICE_LOAD(p_BEGIN_DATE, p_END_DATE, p_SERVICE_CODE, p_SERVICE_COMPONENT, p_AS_OF_DATE, p_SCENARIO_ID, p_DETERMINANTS);
		END IF;
	ELSIF p_CONSUMPTION_CODE IS NOT NULL THEN
		IF p_SERVICE_COMPONENT.CUSTOMER_ID <> g_NOT_ASSIGNED THEN
			GET_CUSTOMER_CONSUMPTION(p_CONSUMPTION_CODE, p_SERVICE_COMPONENT, p_DETERMINANTS);
		ELSE
			GET_SERVICE_CONSUMPTION(p_CONSUMPTION_CODE, p_SERVICE_COMPONENT, p_AS_OF_DATE, p_SCENARIO_ID, p_DETERMINANTS);
		END IF;
	END IF;

	IF LOGS.IS_DEBUG_ENABLED THEN
		LOGS.LOG_DEBUG('GET_SERVICE_DETERMINANTS TIME= ' || TO_CHAR(DBMS_UTILITY.GET_TIME - v_ELASPSED) || ', COUNT=' || p_DETERMINANTS.COUNT);
	END IF;

	CU.TRACE_DETERMINANTS('SERVICE DETERMINANTS', p_DETERMINANTS);

END GET_SERVICE_DETERMINANTS;
---------------------------------------------------------------------------------------------------
PROCEDURE GET_SERVICE_COMPONENTS
	(
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_SERVICE_COMPONENT IN OUT NOCOPY SERVICE_COMPONENT_TABLE
	) AS

v_INDEX BINARY_INTEGER;
v_ELASPSED PLS_INTEGER := DBMS_UTILITY.GET_TIME;
v_USE_CUSTOMER_MODEL INTEGER;

BEGIN

	IF GA.ENABLE_CUSTOMER_MODEL AND GA.ENABLE_CUSTOMER_CAST THEN
    	v_USE_CUSTOMER_MODEL := 1;
    ELSE
    	v_USE_CUSTOMER_MODEL := 0;
    END IF;

	SELECT SERVICE_COMPONENT_TYPE(A.ACCOUNT_SERVICE_ID, A.CUSTOMER_ID, A.PRODUCT_TYPE, A.BEGIN_DATE, A.END_DATE, A.PRODUCT_ID, A.COMPONENT_ID)
	BULK COLLECT INTO p_SERVICE_COMPONENT
	FROM
		(SELECT DISTINCT A.ACCOUNT_SERVICE_ID, D.CUSTOMER_ID, D.PRODUCT_TYPE,
			GREATEST(p_BEGIN_DATE, GREATEST(B.BEGIN_DATE, GREATEST(C.BEGIN_DATE, GREATEST(D.BEGIN_DATE)))) "BEGIN_DATE",
			LEAST(p_END_DATE, LEAST(NVL(B.END_DATE, p_END_DATE), LEAST(NVL(C.END_DATE, p_END_DATE), LEAST(NVL(D.END_DATE, p_END_DATE))))) "END_DATE",
			E.PRODUCT_ID, E.COMPONENT_ID
		FROM ACCOUNT_SERVICE A, AGGREGATE_ACCOUNT_CUSTOMER B, ACCOUNT_STATUS C, ACCOUNT_STATUS_NAME STATUS_NAME, CUSTOMER_PRODUCT D, PRODUCT_COMPONENT E
		WHERE v_USE_CUSTOMER_MODEL = 1
        	AND B.AGGREGATE_ID = A.AGGREGATE_ID
			AND B.BEGIN_DATE <= p_END_DATE AND NVL(B.END_DATE, p_END_DATE) >= p_BEGIN_DATE
			AND C.ACCOUNT_ID = A.ACCOUNT_ID
			AND C.BEGIN_DATE <= p_END_DATE AND NVL(C.END_DATE, p_END_DATE) >= p_BEGIN_DATE
			AND STATUS_NAME.STATUS_NAME = C.STATUS_NAME
			AND STATUS_NAME.IS_ACTIVE = 1
			AND D.CUSTOMER_ID = B.CUSTOMER_ID
			AND D.PRODUCT_TYPE IN ('R','C')
			AND D.BEGIN_DATE <= p_END_DATE AND NVL(D.END_DATE, p_END_DATE) >= p_BEGIN_DATE
			AND E.PRODUCT_ID = D.PRODUCT_ID
			AND E.BEGIN_DATE <= p_END_DATE AND NVL(E.END_DATE, p_END_DATE) >= p_BEGIN_DATE
		UNION ALL SELECT DISTINCT A.ACCOUNT_SERVICE_ID, g_NOT_ASSIGNED "CUSTOMER_ID", B.PRODUCT_TYPE,
			GREATEST(p_BEGIN_DATE, GREATEST(B.BEGIN_DATE, GREATEST(C.BEGIN_DATE, GREATEST(D.BEGIN_DATE)))) "BEGIN_DATE",
			LEAST(p_END_DATE, LEAST(NVL(B.END_DATE, p_END_DATE), LEAST(NVL(C.END_DATE, p_END_DATE), LEAST(NVL(D.END_DATE, p_END_DATE))))) "END_DATE",
			D.PRODUCT_ID, D.COMPONENT_ID
		FROM ACCOUNT_SERVICE A, ACCOUNT_PRODUCT B, ACCOUNT_STATUS C, ACCOUNT_STATUS_NAME STATUS_NAME, PRODUCT_COMPONENT D
		WHERE A.METER_ID = g_NOT_ASSIGNED
        	AND (A.AGGREGATE_ID = g_NOT_ASSIGNED OR v_USE_CUSTOMER_MODEL = 0)
			AND B.CASE_ID = GA.BASE_CASE_ID
			AND B.ACCOUNT_ID = A.ACCOUNT_ID
			AND B.PRODUCT_TYPE IN ('R','C')
			AND B.BEGIN_DATE <= p_END_DATE AND NVL(B.END_DATE, p_END_DATE) >= p_BEGIN_DATE
			AND C.ACCOUNT_ID = A.ACCOUNT_ID
			AND C.BEGIN_DATE <= p_END_DATE AND NVL(C.END_DATE, p_END_DATE) >= p_BEGIN_DATE
			AND STATUS_NAME.STATUS_NAME = C.STATUS_NAME
			AND STATUS_NAME.IS_ACTIVE = 1
			AND D.PRODUCT_ID = B.PRODUCT_ID
			AND D.BEGIN_DATE <= p_END_DATE AND NVL(D.END_DATE, p_END_DATE) >= p_BEGIN_DATE
		UNION ALL SELECT DISTINCT A.ACCOUNT_SERVICE_ID, g_NOT_ASSIGNED "CUSTOMER_ID", B.PRODUCT_TYPE,
			GREATEST(p_BEGIN_DATE, GREATEST(B.BEGIN_DATE, GREATEST(C.BEGIN_DATE, GREATEST(D.BEGIN_DATE)))) "BEGIN_DATE",
			LEAST(p_END_DATE, LEAST(NVL(B.END_DATE, p_END_DATE), LEAST(NVL(C.END_DATE, p_END_DATE), LEAST(NVL(D.END_DATE, p_END_DATE))))) "END_DATE",
			D.PRODUCT_ID, D.COMPONENT_ID
		FROM ACCOUNT_SERVICE A, METER_PRODUCT B, ACCOUNT_STATUS C, ACCOUNT_STATUS_NAME STATUS_NAME, PRODUCT_COMPONENT D
		WHERE NOT A.METER_ID = g_NOT_ASSIGNED
			AND B.CASE_ID = GA.BASE_CASE_ID
			AND B.METER_ID = A.METER_ID
			AND B.PRODUCT_TYPE IN ('R','C')
			AND B.BEGIN_DATE <= p_END_DATE AND NVL(B.END_DATE, p_END_DATE) >= p_BEGIN_DATE
			AND C.ACCOUNT_ID = A.ACCOUNT_ID
			AND C.BEGIN_DATE <= p_END_DATE AND NVL(C.END_DATE, p_END_DATE) >= p_BEGIN_DATE
			AND STATUS_NAME.STATUS_NAME = C.STATUS_NAME
			AND STATUS_NAME.IS_ACTIVE = 1
			AND D.PRODUCT_ID = B.PRODUCT_ID
			AND D.BEGIN_DATE <= p_END_DATE AND NVL(D.END_DATE, p_END_DATE) >= p_BEGIN_DATE) A
		ORDER BY ACCOUNT_SERVICE_ID, CUSTOMER_ID, PRODUCT_TYPE, BEGIN_DATE, END_DATE, PRODUCT_ID, COMPONENT_ID;

	IF LOGS.IS_DEBUG_ENABLED THEN
		LOGS.LOG_DEBUG('GET_SERVICE_COMPONENTS ELAPSED TIME=' || TO_CHAR(DBMS_UTILITY.GET_TIME - v_ELASPSED) || ', COUNT= ' || TO_CHAR(p_SERVICE_COMPONENT.COUNT));
	END IF;

	IF LOGS.IS_DEBUG_DETAIL_ENABLED AND p_SERVICE_COMPONENT.COUNT > 0 THEN
		v_INDEX := p_SERVICE_COMPONENT.FIRST;
		LOGS.LOG_DEBUG_DETAIL('<account service id>,<customer id>,<product type>,<begin date>,<end date>,<product id>,<component id>');
		WHILE v_INDEX <= p_SERVICE_COMPONENT.LAST LOOP
			LOGS.LOG_DEBUG_DETAIL(TO_CHAR(p_SERVICE_COMPONENT(v_INDEX).ACCOUNT_SERVICE_ID) || ',' || TO_CHAR(p_SERVICE_COMPONENT(v_INDEX).CUSTOMER_ID) || ',' || p_SERVICE_COMPONENT(v_INDEX).PRODUCT_TYPE || ',' || TEXT_UTIL.TO_CHAR_DATE(p_SERVICE_COMPONENT(v_INDEX).BEGIN_DATE) || ',' || TEXT_UTIL.TO_CHAR_DATE(p_SERVICE_COMPONENT(v_INDEX).END_DATE) || ',' || TO_CHAR(p_SERVICE_COMPONENT(v_INDEX).PRODUCT_ID) || ',' || TO_CHAR(p_SERVICE_COMPONENT(v_INDEX).COMPONENT_ID));
			v_INDEX := p_SERVICE_COMPONENT.NEXT(v_INDEX);
		END LOOP;
	END IF;

END GET_SERVICE_COMPONENTS;
---------------------------------------------------------------------------------------------------
PROCEDURE ASSIGN_PLAN_TO_DETERMINANTS
	(
	p_PLAN_DETERMINANTS IN DETERMINANT_TABLE,
	p_DETERMINANTS IN OUT NOCOPY DETERMINANT_TABLE
	) AS

v_PLAN_INDEX BINARY_INTEGER;
v_INDEX BINARY_INTEGER;
v_ELASPSED PLS_INTEGER := DBMS_UTILITY.GET_TIME;

BEGIN

	IF LOGS.IS_DEBUG_DETAIL_ENABLED THEN
		LOGS.LOG_DEBUG_DETAIL('ASSIGN_PLAN_TO_DETERMINANTS');
		LOGS.LOG_DEBUG_DETAIL('PLAN_DETERMINANTS COUNT= ' || TO_CHAR(p_PLAN_DETERMINANTS.COUNT));
		LOGS.LOG_DEBUG_DETAIL('DETERMINANTS COUNT= ' || TO_CHAR(p_DETERMINANTS.COUNT));
		LOGS.LOG_DEBUG_DETAIL('<account service id>,<begin>,<end>,<actual>,<plan>');
	END IF;

	v_INDEX := p_DETERMINANTS.FIRST;
	WHILE v_INDEX <= p_DETERMINANTS.LAST LOOP
		v_PLAN_INDEX := p_PLAN_DETERMINANTS.FIRST;
		WHILE v_PLAN_INDEX <= p_PLAN_DETERMINANTS.LAST LOOP
			IF p_DETERMINANTS(v_INDEX).EQUAL(p_PLAN_DETERMINANTS(v_PLAN_INDEX)) THEN
				p_DETERMINANTS(v_INDEX).PLAN(p_PLAN_DETERMINANTS(v_PLAN_INDEX).PLAN);
				EXIT;
			END IF;
			v_PLAN_INDEX := p_PLAN_DETERMINANTS.NEXT(v_PLAN_INDEX);
		END LOOP;
		IF LOGS.IS_DEBUG_DETAIL_ENABLED THEN
			LOGS.LOG_DEBUG_DETAIL(TO_CHAR(p_DETERMINANTS(v_INDEX).ACCOUNT_SERVICE_ID) || ',' || TO_CHAR(p_DETERMINANTS(v_INDEX).BEGIN_DATE) || ',' || TO_CHAR(p_DETERMINANTS(v_INDEX).END_DATE) || ',' || TO_CHAR(p_DETERMINANTS(v_INDEX).ACTUAL) || ',' || TO_CHAR(p_DETERMINANTS(v_INDEX).PLAN));
		END IF;
		v_INDEX := p_DETERMINANTS.NEXT(v_INDEX);
	END LOOP;

	IF LOGS.IS_DEBUG_ENABLED THEN
		LOGS.LOG_DEBUG('ASSIGN_PLAN_TO_DETERMINANTS TIME= ' || TO_CHAR(DBMS_UTILITY.GET_TIME - v_ELASPSED));
	END IF;

END ASSIGN_PLAN_TO_DETERMINANTS;
---------------------------------------------------------------------------------------------------
PROCEDURE SERVICE_POSITION_REQUEST_SCEN
	(
	p_CALLING_MODULE IN VARCHAR,
	p_MODEL_ID IN NUMBER,
	p_POSITION_TYPE IN NUMBER,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_INPUT_AS_OF_DATE IN DATE,
	p_OUTPUT_AS_OF_DATE IN DATE,
	p_TRACE_ON IN NUMBER,
    p_SCENARIO_ID IN NUMBER,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR
	) AS

v_INDEX BINARY_INTEGER;
v_BEGIN_DATE DATE;
v_END_DATE DATE;
v_DAILY_BEGIN_DATE DATE;
v_DAILY_END_DATE DATE;
v_INPUT_AS_OF_DATE DATE := CORRECTED_AS_OF_DATE(p_INPUT_AS_OF_DATE, 'STATEMENT');
v_OUTPUT_AS_OF_DATE DATE := LOW_DATE;
v_POSITION_TYPE VARCHAR(16);
v_SERVICE_CODE CHAR(1);
v_CONSUMPTION_CODE CHAR(1);
v_COMPONENT COMPONENT%ROWTYPE;
v_DETERMINANTS DETERMINANT_TABLE := DETERMINANT_TABLE();
v_PLAN_DETERMINANTS DETERMINANT_TABLE := DETERMINANT_TABLE();
v_CHARGE_COMPONENTS CHARGE_COMPONENT_TABLE := CHARGE_COMPONENT_TABLE();
v_SERVICE_COMPONENTS SERVICE_COMPONENT_TABLE := SERVICE_COMPONENT_TABLE();
v_LAST_SERVICE_COMPONENT SERVICE_COMPONENT_TYPE;
v_ELASPSED PLS_INTEGER := DBMS_UTILITY.GET_TIME;
v_RANGE_IDX PLS_INTEGER;

BEGIN

	IF NOT CAN_WRITE(p_CALLING_MODULE) THEN
		ERRS.RAISE_NO_WRITE_MODULE(p_CALLING_MODULE);
	END IF;

	p_STATUS := GA.SUCCESS;
	p_MESSAGE := 'OK.';
	g_CALLING_MODULE := p_CALLING_MODULE;
	g_MODEL_ID := p_MODEL_ID;
	IF g_MODEL_ID = 0 THEN g_MODEL_ID := GA.DEFAULT_MODEL; END IF;

	v_LAST_SERVICE_COMPONENT := SERVICE_COMPONENT_TYPE(999999999, 999999999, NULL, NULL, NULL, NULL, NULL);

	SELECT DECODE(p_POSITION_TYPE, '1', 'Forecast', '2', 'Preliminary', '3', 'Final', 'Forecast') INTO v_POSITION_TYPE FROM DUAL;
	v_DAILY_BEGIN_DATE := TRUNC(p_BEGIN_DATE,'MONTH');
	v_DAILY_END_DATE := TRUNC(LAST_DAY(p_END_DATE));

    v_CONSUMPTION_CODE := NULL;
    v_INPUT_AS_OF_DATE := LOW_DATE;
    SELECT DECODE(p_POSITION_TYPE, '1', GA.FORECAST_SERVICE, '2', GA.BACKCAST_SERVICE, GA.ACTUAL_SERVICE) INTO v_SERVICE_CODE FROM DUAL;

	IF LOGS.IS_DEBUG_ENABLED THEN
		LOGS.LOG_DEBUG('SERVICE_POSITION_REQUEST');
		LOGS.LOG_DEBUG('CALLING_MODULE=' || p_CALLING_MODULE);
		LOGS.LOG_DEBUG('MODEL_ID=' || TO_CHAR(p_MODEL_ID));
		LOGS.LOG_DEBUG('POSITION_TYPE=' || TO_CHAR(p_POSITION_TYPE) || ', CODE=' || v_POSITION_TYPE);
		LOGS.LOG_DEBUG('BEGIN_DATE=' || TEXT_UTIL.TO_CHAR_DATE(v_DAILY_BEGIN_DATE));
		LOGS.LOG_DEBUG('END_DATE=' || TEXT_UTIL.TO_CHAR_DATE(v_DAILY_END_DATE));
		LOGS.LOG_DEBUG('INPUT_AS_OF_DATE=' || TEXT_UTIL.TO_CHAR_DATE(v_INPUT_AS_OF_DATE));
		LOGS.LOG_DEBUG('OUTPUT_AS_OF_DATE=' || TEXT_UTIL.TO_CHAR_DATE(v_OUTPUT_AS_OF_DATE));
		LOGS.LOG_DEBUG('CONSUMPTION_CODE=' || v_CONSUMPTION_CODE);
		LOGS.LOG_DEBUG('SERVICE_CODE=' || v_SERVICE_CODE);
		LOGS.LOG_DEBUG('SCENARIO_ID=' || TO_CHAR(p_SCENARIO_ID));
	END IF;

	DELETE SERVICE_POSITION_CHARGE
	WHERE SERVICE_ID IN (SELECT DISTINCT SERVICE_ID FROM SERVICE WHERE SCENARIO_ID = p_SCENARIO_ID)
		AND POSITION_TYPE = p_POSITION_TYPE
		AND CHARGE_DATE BETWEEN v_DAILY_BEGIN_DATE AND v_DAILY_END_DATE
		AND PRODUCT_TYPE IN ('C','R');

	GET_SERVICE_COMPONENTS(v_DAILY_BEGIN_DATE, v_DAILY_END_DATE, v_SERVICE_COMPONENTS);

	v_RANGE_IDX := LOGS.PUSH_PROGRESS_RANGE(v_SERVICE_COMPONENTS.COUNT);

	v_INDEX := v_SERVICE_COMPONENTS.FIRST;
	WHILE v_INDEX <= v_SERVICE_COMPONENTS.LAST LOOP
		IF NOT (v_LAST_SERVICE_COMPONENT.ACCOUNT_SERVICE_ID = v_SERVICE_COMPONENTS(v_INDEX).ACCOUNT_SERVICE_ID AND v_LAST_SERVICE_COMPONENT.CUSTOMER_ID = v_SERVICE_COMPONENTS(v_INDEX).CUSTOMER_ID) THEN
			UT.CUT_DATE_RANGE(p_MODEL_ID, v_SERVICE_COMPONENTS(v_INDEX).BEGIN_DATE, v_SERVICE_COMPONENTS(v_INDEX).END_DATE, g_LOCAL_TIME_ZONE, v_BEGIN_DATE, v_END_DATE);
 			GET_SERVICE_DETERMINANTS(v_BEGIN_DATE, v_END_DATE, v_SERVICE_CODE, v_CONSUMPTION_CODE, v_SERVICE_COMPONENTS(v_INDEX), v_INPUT_AS_OF_DATE, v_DETERMINANTS, p_SCENARIO_ID);
 		END IF;
		IF v_DETERMINANTS.COUNT > 0 THEN
			IF CU.COMPONENT_IS_SWING_COMPONENT(v_SERVICE_COMPONENTS(v_INDEX).COMPONENT_ID, v_SERVICE_COMPONENTS(v_INDEX).BEGIN_DATE) THEN
				GET_SERVICE_CONTRACT_LIMITS(v_SERVICE_COMPONENTS(v_INDEX), v_PLAN_DETERMINANTS);
				ASSIGN_PLAN_TO_DETERMINANTS(v_PLAN_DETERMINANTS, v_DETERMINANTS);
			END IF;
			v_COMPONENT := GET_COMPONENT(v_SERVICE_COMPONENTS(v_INDEX).COMPONENT_ID);
			CU.APPLY_PRODUCT_COMPONENT(v_SERVICE_COMPONENTS(v_INDEX).PRODUCT_ID, v_COMPONENT, v_DETERMINANTS, v_SERVICE_COMPONENTS(v_INDEX).BEGIN_DATE, LEAST(v_SERVICE_COMPONENTS(v_INDEX).END_DATE, v_DAILY_END_DATE), 1, 1, g_NOT_ASSIGNED, LOGS.IS_DEBUG_ENABLED, v_CHARGE_COMPONENTS, TRUE, v_CONSUMPTION_CODE IS NULL);
			PUT_SERVICE_POSITION_CHARGES(p_SCENARIO_ID, p_POSITION_TYPE, v_SERVICE_COMPONENTS(v_INDEX), v_OUTPUT_AS_OF_DATE, v_CHARGE_COMPONENTS);
		END IF;
		v_LAST_SERVICE_COMPONENT := v_SERVICE_COMPONENTS(v_INDEX);
		v_INDEX := v_SERVICE_COMPONENTS.NEXT(v_INDEX);
		LOGS.INCREMENT_PROCESS_PROGRESS(p_RANGE_INDEX => v_RANGE_IDX);
	END LOOP;

	LOGS.POP_PROGRESS_RANGE(v_RANGE_IDX);

	LOGS.LOG_DEBUG('SERVICE_POSITION_REQUEST ELAPSED TIME=' || TO_CHAR(DBMS_UTILITY.GET_TIME - v_ELASPSED));

END SERVICE_POSITION_REQUEST_SCEN;
---------------------------------------------------------------------------------------------------
END FF;
/
