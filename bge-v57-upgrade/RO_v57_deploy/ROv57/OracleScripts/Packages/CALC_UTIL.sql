CREATE OR REPLACE PACKAGE "CALC_UTIL" IS
--Revision $Revision: 1.3 $

  -- Author  : JHUMPHRIES
  -- Created : 7/7/2008 4:17:07 PM
  -- Purpose : Utility functions for use by calculation components
FUNCTION WHAT_VERSION RETURN VARCHAR;

-- Constants for Factor Types

-- This factor type is used for "netting out" losses from a gross value
c_FACTOR_TYPE_LOSS			CONSTANT VARCHAR2(16) := 'Loss';
-- This factor type is used for "grossing up" losses from a net value
c_FACTOR_TYPE_EXPANSION		CONSTANT VARCHAR2(16) := 'Expansion';
-- This factor type retrieves the "native" factor type. When querying the
-- factor for a meter data point, this is based on the factor type of the
-- relationship between the meter data point and the loss factor object.
-- When querying the factor for a loss factor object, this is based on the
-- loss factor's factor type.
c_FACTOR_TYPE_NATIVE		CONSTANT VARCHAR2(16) := '?';

-- Constants for Loss Types

c_LOSS_TYPE_TRANSMISSION	CONSTANT VARCHAR2(16) := 'Transmission';
c_LOSS_TYPE_DISTRIBUTION	CONSTANT VARCHAR2(16) := 'Distribution';
c_LOSS_TYPE_UFE				CONSTANT VARCHAR2(16) := 'UFE';
c_LOSS_TYPE_TRANSFORMER		CONSTANT VARCHAR2(16) := 'Transformer';
-- This special type indicates the product of all of the above types
c_LOSS_TYPE_COMBINED		CONSTANT VARCHAR2(16) := '%';

-- Constants for Model Types

c_MODEL_TYPE_PATTERN		CONSTANT VARCHAR2(16) := 'Pattern';
c_MODEL_TYPE_SCHEDULE		CONSTANT VARCHAR2(16) := 'Schedule';

-- Constants for Form

c_FORM_LOSSES_ONLY			CONSTANT NUMBER(1) := 1;
c_FORM_LOSS_ADJUSTED_ENERGY	CONSTANT NUMBER(1) := 2;

-- Constants for Which Value

c_WHICH_VALUE_METER_VAL		CONSTANT NUMBER(1) := 0;
c_WHICH_VALUE_TRUNCATED_VAL	CONSTANT NUMBER(1) := 1;

-- Special Constant for Measurement Source
c_MEASUREMENT_SRC_PRIMARY	CONSTANT NUMBER(1) := -1;

/**
 * Gets charge amount total for specified billing statement entries.
 * %param p_ENTITY_ID		The PSE_ID for the statement billing entity.
 * %param p_STATEMENT_TYPE	The STATEMENT_TYPE_ID for the statement's type.
 * %param p_BEGIN_DATE		The starting STATEMENT_DATE to be included in total.
 * %param p_END_DATE		The ending STATEMENT_DATE to be included in total.
 * %param p_COMPONENT_ID	The COMPONENT_ID of the charge to be included in total.
 *							Leave unspecified to include all statement charges.
 * %param p_PRODUCT_ID		The PRODUCT_ID of the charges to be included in total.
 *							Leave unspecified to include charges from any product.
 * %param p_STATEMENT_STATE	The state of data to query - internal (default) or external
 * %return	The total charge amount from statement entries matching specified criteria
 */
FUNCTION GET_STATEMENT_CHARGE_AMOUNT
	(
	p_ENTITY_ID	IN NUMBER,
	p_STATEMENT_TYPE IN NUMBER,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_COMPONENT_ID IN NUMBER := CONSTANTS.ALL_ID,
	p_PRODUCT_ID IN NUMBER := CONSTANTS.ALL_ID,
	p_STATEMENT_STATE IN NUMBER := CONSTANTS.INTERNAL_STATE
	) RETURN NUMBER;

/**
 * Gets amount and quantity totals and effective rate for specified billing statement entries.
 * %param p_ENTITY_ID		The PSE_ID for the statement billing entity.
 * %param p_STATEMENT_TYPE	The STATEMENT_TYPE_ID for the statement's type.
 * %param p_BEGIN_DATE		The starting STATEMENT_DATE to be included in total.
 * %param p_END_DATE		The ending STATEMENT_DATE to be included in total.
 * %param p_COMPONENT_ID	The COMPONENT_ID of the charge to be included in total.
 *							Leave unspecified to include all statement charges.
 * %param p_PRODUCT_ID		The PRODUCT_ID of the charges to be included in total.
 *							Leave unspecified to include charges from any product.
 * %param p_STATEMENT_STATE	The state of data to query - internal (default) or external
 * %param p_CHARGE_AMOUNT	Will be set to the total charge amount of matching statement entries
 * %param p_BILL_AMOUNT		Will be set to the total bill amount of matching statement entries
 * %param p_CHARGE_QTY		Will be set to the total charge quantity of matching statement entries
 * %param p_BILL_QTY		Will be set to the total bill quantity of matching statement entries
 * %param p_CHARGE_RATE		Will be set to the effective (weighted average) rate of matching statement entries
 */
PROCEDURE GET_STATEMENT_CHARGE_INFO
	(
	p_ENTITY_ID	IN NUMBER,
	p_STATEMENT_TYPE IN NUMBER,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_COMPONENT_ID IN NUMBER := CONSTANTS.ALL_ID,
	p_PRODUCT_ID IN NUMBER := CONSTANTS.ALL_ID,
	p_STATEMENT_STATE IN NUMBER := CONSTANTS.INTERNAL_STATE,
	p_CHARGE_AMOUNT OUT NUMBER,
	p_BILL_AMOUNT OUT NUMBER,
	p_CHARGE_QTY OUT NUMBER,
	p_BILL_QTY OUT NUMBER,
	p_CHARGE_RATE OUT NUMBER
	);

/**
 * Gets a loss factor value for a given loss factor entity, loss type, and date.
 * %param p_LOSS_FACTOR_ID	The ID of the loss factor object.
 * %param p_LOSS_DATE		The CUT date for which to query the factor value
 * %param p_TIME_ZONE		The local time zone. If a "pattern" model is effective for
 *							specified date, this is used to translate p_LOSS_DATE from
 *							CUT to local time for pattern look-up
 * %param p_LOSS_TYPE		The loss type - use one of the c_LOSS_TYPE_* constants
 * %param p_FACTOR_TYPE		The factor type - use one of the c_FACTOR_TYPE_* constants
 * %param p_FORM			The form of the loss factor value - either a coefficient to
 *							compute losses only (e.g. 0.03) or a coefficient to compute
 *							loss-adjusted energy (e.g. 1.03). Use one of the c_FORM_*
 *							constants.
 * %return	The loss or expansion factor value (based on p_FACTOR_TYPE) for the specified
 * 			loss factor, loss type, and date/time.
 */
FUNCTION GET_LOSS_FACTOR
	(
	p_LOSS_FACTOR_ID IN NUMBER,
	p_LOSS_DATE IN DATE,
	p_TIME_ZONE IN VARCHAR2 := GA.LOCAL_TIME_ZONE,
	p_LOSS_TYPE IN VARCHAR2 := c_LOSS_TYPE_COMBINED,
	p_FACTOR_TYPE IN VARCHAR2 := c_FACTOR_TYPE_LOSS,
	p_FORM IN NUMBER := c_FORM_LOSSES_ONLY
	) RETURN NUMBER;

/**
 * Gets a loss factor value for a given meter data point and hour.
 * %param p_METER_POINT_ID	The ID of the meter data point.
 * %param p_LOSS_DATE		The CUT date for which to query the factor value
 * %param p_TIME_ZONE		The local time zone. If a "pattern" model is effective for
 *							specified date, this is used to translate p_LOSS_DATE from
 *							CUT to local time for pattern look-up. This is also used to
 *							to determine the "current day" of the specified date for
 *							looking up the loss factor assignment
 * %param p_LOSS_TYPE		The loss type - use one of the c_LOSS_TYPE_* constants
 * %param p_FACTOR_TYPE		The factor type - use one of the c_FACTOR_TYPE_* constants
 * %param p_FORM			The form of the loss factor value - either a coefficient to
 *							compute losses only (e.g. 0.03) or a coefficient to compute
 *							loss-adjusted energy (e.g. 1.03). Use one of the c_FORM_*
 *							constants.
 * %return	The loss or expansion factor value (based on p_FACTOR_TYPE) for the specified
 * 			meter point, loss type, and date/time.
 */
FUNCTION GET_METER_LOSS_FACTOR
	(
	p_METER_POINT_ID IN NUMBER,
	p_LOSS_DATE IN DATE,
	p_TIME_ZONE IN VARCHAR2 := GA.LOCAL_TIME_ZONE,
	p_LOSS_TYPE IN VARCHAR2 := c_LOSS_TYPE_COMBINED,
	p_FACTOR_TYPE IN VARCHAR2 := c_FACTOR_TYPE_NATIVE,
	p_FORM IN NUMBER := c_FORM_LOSSES_ONLY
	) RETURN NUMBER;

/**
 * Gets a loss-adjusted value for a given meter data point and hour.
 * %param p_METER_POINT_ID	The ID of the meter data point.
 * %param p_METER_DATE		The CUT date for which to query the loss-adjusted value
 * %param p_TIME_ZONE		The local time zone. If a "pattern" loss model is effective for
 *							specified date, this is used to translate p_METER_DATE from
 *							CUT to local time for pattern look-up. This is also used to
 *							to determine the "current day" of the specified date for
 *							looking up the loss factor assignment
 * %param p_WHICH_VALUE		This indicates what meter point value should be used as the
 *							basis for the energy measurement - use one of the
 *							c_WHICH_VALUE_* constants
 * %param p_MEASUREMENT_SOURCE_ID The ID of the measurement source to use when querying the
 *							meter point's data. You can specify c_MEASUREMENT_SRC_PRIMARY to
 *							indicate that the meter's primary source should be used.
 * %param p_METER_CODE		The code of the meter point's data - Forecast, Prelim, or Actual.
 *							Use one of the CODE_* constants in the CONSTANTS package
 * %return	The loss-adjusted meter or truncated value (based on p_WHICH_VALUE) for the specified
 * 			meter point and date/time.
 */
FUNCTION GET_LOSS_ADJUSTED_METER_PT_VAL
	(
	p_METER_POINT_ID IN NUMBER,
	p_METER_DATE IN DATE,
	p_TIME_ZONE IN VARCHAR2 := GA.LOCAL_TIME_ZONE,
	p_WHICH_VALUE IN NUMBER := c_WHICH_VALUE_METER_VAL,
	p_MEASUREMENT_SOURCE_ID IN NUMBER := c_MEASUREMENT_SRC_PRIMARY,
	p_METER_CODE IN VARCHAR2 := CONSTANTS.CODE_ACTUAL
	) RETURN NUMBER;

/**
 * Gets a loss energy value for a given meter data point and hour.
 * %param p_METER_POINT_ID	The ID of the meter data point.
 * %param p_METER_DATE		The CUT date for which to query the loss-adjusted value
 * %param p_TIME_ZONE		The local time zone. If a "pattern" loss model is effective for
 *							specified date, this is used to translate p_METER_DATE from
 *							CUT to local time for pattern look-up. This is also used to
 *							to determine the "current day" of the specified date for
 *							looking up the loss factor assignment
 * %param p_WHICH_VALUE		This indicates what meter point value should be used as the
 *							basis for the energy measurement - use one of the
 *							c_WHICH_VALUE_* constants
 * %param p_MEASUREMENT_SOURCE_ID The ID of the measurement source to use when querying the
 *							meter point's data. You can specify c_MEASUREMENT_SRC_PRIMARY to
 *							indicate that the meter's primary source should be used.
 * %param p_METER_CODE		The code of the meter point's data - Forecast, Prelim, or Actual.
 *							Use one of the CODE_* constants in the CONSTANTS package
 * %return	The loss energy based on meter or truncated value (based on p_WHICH_VALUE) for the specified
 * 			meter point and date/time.
 */
FUNCTION GET_LOSS_ENERGY_METER_PT_VAL
	(
	p_METER_POINT_ID IN NUMBER,
	p_METER_DATE IN DATE,
	p_TIME_ZONE IN VARCHAR2 := GA.LOCAL_TIME_ZONE,
	p_WHICH_VALUE IN NUMBER := c_WHICH_VALUE_METER_VAL,
	p_MEASUREMENT_SOURCE_ID IN NUMBER := c_MEASUREMENT_SRC_PRIMARY,
	p_METER_CODE IN VARCHAR2 := CONSTANTS.CODE_ACTUAL
	) RETURN NUMBER;

/**
 * Gets a collection of loss factor IDs for a given account, service location, meter, and scenario
 *    on a given date (independent of account model).
 */
FUNCTION GET_SERVICE_LOSS_FACTOR_IDs
       (
       p_SERVICE_DATE IN DATE,
       p_ACCOUNT_ID IN NUMBER,
       p_SERVICE_LOCATION_ID IN NUMBER := CONSTANTS.NOT_ASSIGNED,
       p_METER_ID IN NUMBER := CONSTANTS.NOT_ASSIGNED,
       p_SCENARIO_ID IN NUMBER := GA.BASE_SCENARIO_ID
       ) RETURN NUMBER_COLLECTION;

/**
 * Gets the market price for a given date, price id and price code.
 */
FUNCTION GET_MARKET_PRICE
	(
	p_MARKET_PRICE_ID IN MARKET_PRICE_VALUE.MARKET_PRICE_ID%TYPE,    
    p_PRICE_DATE IN DATE,
    p_PRICE_CODE IN MARKET_PRICE_VALUE.PRICE_CODE%TYPE DEFAULT NULL
	) RETURN NUMBER;

END CALC_UTIL;
 
/
CREATE OR REPLACE PACKAGE BODY "CALC_UTIL" IS
---------------------------------------------------------------------------------------------------
FUNCTION WHAT_VERSION RETURN VARCHAR IS
BEGIN
    RETURN '$Revision: 1.3 $';
END WHAT_VERSION;
---------------------------------------------------------------------------------------------------
FUNCTION GET_STATEMENT_CHARGE_AMOUNT
	(
	p_ENTITY_ID	IN NUMBER,
	p_STATEMENT_TYPE IN NUMBER,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_COMPONENT_ID IN NUMBER := CONSTANTS.ALL_ID,
	p_PRODUCT_ID IN NUMBER := CONSTANTS.ALL_ID,
	p_STATEMENT_STATE IN NUMBER := CONSTANTS.INTERNAL_STATE
	) RETURN NUMBER AS
v_AMT NUMBER;
BEGIN
	SELECT NVL(SUM(CHARGE_AMOUNT),0)
	INTO v_AMT
	FROM BILLING_STATEMENT BS
	WHERE BS.ENTITY_ID = p_ENTITY_ID
		AND (BS.PRODUCT_ID = p_PRODUCT_ID OR p_PRODUCT_ID = CONSTANTS.ALL_ID)
		AND (BS.COMPONENT_ID = p_COMPONENT_ID OR p_COMPONENT_ID = CONSTANTS.ALL_ID)
		AND BS.STATEMENT_TYPE = p_STATEMENT_TYPE
		AND BS.STATEMENT_STATE = p_STATEMENT_STATE
		AND BS.STATEMENT_DATE BETWEEN p_BEGIN_DATE AND p_END_DATE
		AND BS.AS_OF_DATE = CONSTANTS.LOW_DATE;

	RETURN v_AMT;
END GET_STATEMENT_CHARGE_AMOUNT;
---------------------------------------------------------------------------------------------------
PROCEDURE GET_STATEMENT_CHARGE_INFO
	(
	p_ENTITY_ID	IN NUMBER,
	p_STATEMENT_TYPE IN NUMBER,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_COMPONENT_ID IN NUMBER := CONSTANTS.ALL_ID,
	p_PRODUCT_ID IN NUMBER := CONSTANTS.ALL_ID,
	p_STATEMENT_STATE IN NUMBER := CONSTANTS.INTERNAL_STATE,
	p_CHARGE_AMOUNT OUT NUMBER,
	p_BILL_AMOUNT OUT NUMBER,
	p_CHARGE_QTY OUT NUMBER,
	p_BILL_QTY OUT NUMBER,
	p_CHARGE_RATE OUT NUMBER
	) AS
BEGIN

	SELECT NVL(SUM(CHARGE_AMOUNT),0), NVL(SUM(BILL_AMOUNT),0),
			NVL(SUM(CHARGE_QUANTITY),0), NVL(SUM(BILL_QUANTITY),0),
			CASE WHEN NVL(SUM(CHARGE_QUANTITY),0) = 0 THEN AVG(CHARGE_RATE) ELSE NVL(SUM(CHARGE_AMOUNT),0)/NVL(SUM(CHARGE_QUANTITY),0) END
	INTO p_CHARGE_AMOUNT, p_BILL_AMOUNT,
			p_CHARGE_QTY, p_BILL_QTY,
			p_CHARGE_RATE
	FROM BILLING_STATEMENT BS
	WHERE BS.ENTITY_ID = p_ENTITY_ID
		AND (BS.PRODUCT_ID = p_PRODUCT_ID OR p_PRODUCT_ID = CONSTANTS.ALL_ID)
		AND (BS.COMPONENT_ID = p_COMPONENT_ID OR p_COMPONENT_ID = CONSTANTS.ALL_ID)
		AND BS.STATEMENT_TYPE = p_STATEMENT_TYPE
		AND BS.STATEMENT_STATE = p_STATEMENT_STATE
		AND BS.STATEMENT_DATE BETWEEN p_BEGIN_DATE AND p_END_DATE
		AND BS.AS_OF_DATE = CONSTANTS.LOW_DATE;

END GET_STATEMENT_CHARGE_INFO;
---------------------------------------------------------------------------------------------------
FUNCTION GET_LOSS_FACTOR
	(
	p_LOSS_FACTOR_ID IN NUMBER,
	p_LOSS_DATE IN DATE,
	p_TIME_ZONE IN VARCHAR2 := GA.LOCAL_TIME_ZONE,
	p_LOSS_TYPE IN VARCHAR2 := c_LOSS_TYPE_COMBINED,
	p_FACTOR_TYPE IN VARCHAR2 := c_FACTOR_TYPE_LOSS,
	p_FORM IN NUMBER := c_FORM_LOSSES_ONLY
	) RETURN NUMBER AS

TYPE t_LOSS_FACTOR_MODEL IS TABLE OF LOSS_FACTOR_MODEL%ROWTYPE;

v_FACTOR_TYPE		VARCHAR2(16) := NVL(p_FACTOR_TYPE,c_FACTOR_TYPE_LOSS);
v_LOCAL_DATE		DATE;
v_DAY				DATE;
v_LOSS_FACTOR_MODELS t_LOSS_FACTOR_MODEL;
v_TMP				NUMBER;
v_RET				NUMBER := 1;
v_INTERVAL			VARCHAR2(16);
v_PATTERN_INTERVAL	NUMBER;
v_PATTERN_DATE		DATE;
v_IDX				PLS_INTEGER;
BEGIN
	ASSERT(p_LOSS_TYPE <> c_LOSS_TYPE_COMBINED OR p_FACTOR_TYPE <> c_FACTOR_TYPE_NATIVE,
			'If querying for combined loss factor value, factor type (loss vs. expansion) *must* be specified',
			MSGCODES.c_ERR_ARGUMENT);

	-- determine the day for the specified date/time
	v_LOCAL_DATE := FROM_CUT(p_LOSS_DATE, p_TIME_ZONE);
	v_DAY := TRUNC(v_LOCAL_DATE - 1/86400);

	-- determine the active pattern(s)
	SELECT *
	BULK COLLECT INTO v_LOSS_FACTOR_MODELS
	FROM LOSS_FACTOR_MODEL LFM
	WHERE LFM.LOSS_FACTOR_ID = p_LOSS_FACTOR_ID
		AND (LFM.LOSS_TYPE = p_LOSS_TYPE OR p_LOSS_TYPE = c_LOSS_TYPE_COMBINED)
		AND LFM.BEGIN_DATE <= v_DAY
		AND NVL(LFM.END_DATE,CONSTANTS.HIGH_DATE) >= v_DAY;

	IF v_LOSS_FACTOR_MODELS.COUNT = 0 THEN
		RETURN CASE p_FORM
					WHEN c_FORM_LOSSES_ONLY THEN 0
					ELSE 1
					END;
	END IF;

	IF v_FACTOR_TYPE = c_FACTOR_TYPE_NATIVE THEN
		-- get the "native" factor type
		v_FACTOR_TYPE := v_LOSS_FACTOR_MODELS(v_LOSS_FACTOR_MODELS.FIRST).FACTOR_TYPE;
	END IF;

	-- Compute the product of loss/expansion factor values
	v_IDX := v_LOSS_FACTOR_MODELS.FIRST;
	WHILE v_LOSS_FACTOR_MODELS.EXISTS(v_IDX) LOOP

		v_INTERVAL := GET_INTERVAL_ABBREVIATION(v_LOSS_FACTOR_MODELS(v_IDX).INTERVAL);

		-- now query for the specific value
		IF v_LOSS_FACTOR_MODELS(v_IDX).MODEL_TYPE = c_MODEL_TYPE_PATTERN THEN

			IF v_INTERVAL = 'DD' THEN
				-- single daily value
				SELECT NVL(AVG(
							CASE v_FACTOR_TYPE
								WHEN c_FACTOR_TYPE_LOSS THEN 1-LOSS_VAL
								ELSE 1+EXPANSION_VAL
								END
							),0)
				INTO v_TMP
				FROM LOSS_FACTOR_PATTERN
				WHERE PATTERN_ID = v_LOSS_FACTOR_MODELS(v_IDX).PATTERN_ID;
			ELSE
				-- hourly or sub-hourly interval
				v_PATTERN_INTERVAL := TRUNC(v_LOCAL_DATE,'MI') - TRUNC(v_LOCAL_DATE);
				SELECT NVL(AVG(
							CASE v_FACTOR_TYPE
								WHEN c_FACTOR_TYPE_LOSS THEN 1-LOSS_VAL
								ELSE 1+EXPANSION_VAL
								END
							),0)
				INTO v_TMP
				FROM LOSS_FACTOR_PATTERN
				WHERE PATTERN_ID = v_LOSS_FACTOR_MODELS(v_IDX).PATTERN_ID
					AND PATTERN_DATE-TRUNC(PATTERN_DATE) = v_PATTERN_INTERVAL;
			END IF;

		ELSE -- Model Type = c_MODEL_TYPE_SCHEDULE

			v_PATTERN_DATE := DATE_UTIL.HED_TRUNC(p_LOSS_DATE, v_INTERVAL);

			SELECT NVL(AVG(
						CASE v_FACTOR_TYPE
							WHEN c_FACTOR_TYPE_LOSS THEN 1-LOSS_VAL
							ELSE 1+EXPANSION_VAL
							END
						),0)
			INTO v_TMP
			FROM LOSS_FACTOR_PATTERN
			WHERE PATTERN_ID = v_LOSS_FACTOR_MODELS(v_IDX).PATTERN_ID
				AND PATTERN_DATE = v_PATTERN_DATE;

		END IF;

		-- compute product
		v_RET := v_RET * v_TMP;

		v_IDX := v_LOSS_FACTOR_MODELS.NEXT(v_IDX);
	END LOOP;

	-- current factor is for loss-adjusted energy (i.e. total loss factor = 3%? then v_RET = 0.97)
	-- If query is for losses only factor, subtract 1.0
	IF p_FORM =	c_FORM_LOSSES_ONLY THEN
		v_RET := ABS(v_RET - 1);
	END IF;

	-- Done!
	RETURN v_RET;

END GET_LOSS_FACTOR;
---------------------------------------------------------------------------------------------------
FUNCTION GET_METER_LOSS_FACTOR
	(
	p_METER_POINT_ID IN NUMBER,
	p_LOSS_DATE IN DATE,
	p_TIME_ZONE IN VARCHAR2 := GA.LOCAL_TIME_ZONE,
	p_LOSS_TYPE IN VARCHAR2 := c_LOSS_TYPE_COMBINED,
	p_FACTOR_TYPE IN VARCHAR2 := c_FACTOR_TYPE_NATIVE,
	p_FORM IN NUMBER := c_FORM_LOSSES_ONLY
	) RETURN NUMBER AS
v_DAY			DATE;
v_LOSS			TX_SUB_STATION_METER_PT_LOSS%ROWTYPE;
v_FACTOR_TYPE	VARCHAR2(16) := NVL(p_FACTOR_TYPE,c_FACTOR_TYPE_NATIVE);
BEGIN
	-- Determine the loss factor for the specified meter point
	v_DAY := TRUNC(FROM_CUT(p_LOSS_DATE, p_TIME_ZONE) - 1/86400);

	BEGIN
		SELECT *
		INTO v_LOSS
		FROM TX_SUB_STATION_METER_PT_LOSS MPL
		WHERE MPL.METER_POINT_ID = p_METER_POINT_ID
			AND MPL.BEGIN_DATE <= v_DAY
			AND NVL(MPL.END_DATE, CONSTANTS.HIGH_DATE) >= v_DAY;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RETURN 0;
	END;

	-- Now query for the factor's value
	RETURN GET_LOSS_FACTOR(v_LOSS.LOSS_FACTOR_ID, p_LOSS_DATE, p_TIME_ZONE, p_LOSS_TYPE,
						CASE v_FACTOR_TYPE
							WHEN c_FACTOR_TYPE_NATIVE THEN v_LOSS.FACTOR_TYPE
							ELSE v_FACTOR_TYPE
							END,
						p_FORM);

END GET_METER_LOSS_FACTOR;
---------------------------------------------------------------------------------------------------
FUNCTION GET_METER_AND_LOSS_VALS
	(
	p_METER_POINT_ID IN NUMBER,
	p_METER_DATE IN DATE,
	p_TIME_ZONE IN VARCHAR2,
	p_WHICH_VALUE IN NUMBER,
	p_MEASUREMENT_SOURCE_ID IN NUMBER,
	p_METER_CODE IN VARCHAR2,
	p_FORM IN NUMBER
	) RETURN NUMBER AS

v_DAY					DATE;
v_FACTOR_VAL 			NUMBER;
v_AMT		 			NUMBER;
v_MEASUREMENT_SOURCE_ID	MEASUREMENT_SOURCE.MEASUREMENT_SOURCE_ID%TYPE;

BEGIN
	-- Get the loss factor value
	v_FACTOR_VAL := GET_METER_LOSS_FACTOR(p_METER_POINT_ID, p_METER_DATE, p_TIME_ZONE, p_FORM => p_FORM);

	IF p_MEASUREMENT_SOURCE_ID = c_MEASUREMENT_SRC_PRIMARY THEN
		-- query for primary source
		v_DAY := TRUNC(FROM_CUT(p_METER_DATE, p_TIME_ZONE) - 1/86400);

		SELECT MEASUREMENT_SOURCE_ID
		INTO v_MEASUREMENT_SOURCE_ID
		FROM TX_SUB_STATION_METER_PT_SOURCE
		WHERE METER_POINT_ID = p_METER_POINT_ID
			AND IS_PRIMARY = 1
			AND BEGIN_DATE <= v_DAY
			AND NVL(END_DATE, CONSTANTS.HIGH_DATE) >= v_DAY;
	ELSE
		v_MEASUREMENT_SOURCE_ID := p_MEASUREMENT_SOURCE_ID;
	END IF;

	-- Get the meter's value
	SELECT NVL(SUM(CASE p_WHICH_VALUE
					WHEN c_WHICH_VALUE_TRUNCATED_VAL THEN TRUNCATED_VAL
					ELSE METER_VAL
					END), 0)
	INTO v_AMT
	FROM TX_SUB_STATION_METER_PT_VALUE
	WHERE METER_POINT_ID = p_METER_POINT_ID
		AND MEASUREMENT_SOURCE_ID = v_MEASUREMENT_SOURCE_ID
		AND METER_CODE = p_METER_CODE
		AND METER_DATE = p_METER_DATE;

	-- Finito!
	RETURN v_FACTOR_VAL * v_AMT;

END GET_METER_AND_LOSS_VALS;
---------------------------------------------------------------------------------------------------
FUNCTION GET_LOSS_ADJUSTED_METER_PT_VAL
	(
	p_METER_POINT_ID IN NUMBER,
	p_METER_DATE IN DATE,
	p_TIME_ZONE IN VARCHAR2 := GA.LOCAL_TIME_ZONE,
	p_WHICH_VALUE IN NUMBER := c_WHICH_VALUE_METER_VAL,
	p_MEASUREMENT_SOURCE_ID IN NUMBER := c_MEASUREMENT_SRC_PRIMARY,
	p_METER_CODE IN VARCHAR2 := CONSTANTS.CODE_ACTUAL
	) RETURN NUMBER AS
BEGIN
	RETURN GET_METER_AND_LOSS_VALS(p_METER_POINT_ID, p_METER_DATE, p_TIME_ZONE, p_WHICH_VALUE,
								   p_MEASUREMENT_SOURCE_ID, p_METER_CODE, c_FORM_LOSS_ADJUSTED_ENERGY);
END GET_LOSS_ADJUSTED_METER_PT_VAL;
---------------------------------------------------------------------------------------------------
FUNCTION GET_LOSS_ENERGY_METER_PT_VAL
	(
	p_METER_POINT_ID IN NUMBER,
	p_METER_DATE IN DATE,
	p_TIME_ZONE IN VARCHAR2 := GA.LOCAL_TIME_ZONE,
	p_WHICH_VALUE IN NUMBER := c_WHICH_VALUE_METER_VAL,
	p_MEASUREMENT_SOURCE_ID IN NUMBER := c_MEASUREMENT_SRC_PRIMARY,
	p_METER_CODE IN VARCHAR2 := CONSTANTS.CODE_ACTUAL
	) RETURN NUMBER AS
BEGIN
	RETURN GET_METER_AND_LOSS_VALS(p_METER_POINT_ID, p_METER_DATE, p_TIME_ZONE, p_WHICH_VALUE,
								   p_MEASUREMENT_SOURCE_ID, p_METER_CODE, c_FORM_LOSSES_ONLY);
END GET_LOSS_ENERGY_METER_PT_VAL;
---------------------------------------------------------------------------------------------------
FUNCTION GET_SERVICE_LOSS_FACTOR_IDs
       (
       p_SERVICE_DATE IN DATE,
       p_ACCOUNT_ID IN NUMBER,
       p_SERVICE_LOCATION_ID IN NUMBER := CONSTANTS.NOT_ASSIGNED,
       p_METER_ID IN NUMBER := CONSTANTS.NOT_ASSIGNED,
       p_SCENARIO_ID IN NUMBER := GA.BASE_SCENARIO_ID
       ) RETURN NUMBER_COLLECTION IS
v_RET NUMBER_COLLECTION;
BEGIN
       -- Gather loss factor IDs for account/aggregate-model accounts
       SELECT ALF.LOSS_FACTOR_ID
       BULK COLLECT INTO v_RET
       FROM ACCOUNT A,
              SCENARIO S,
              LOAD_FORECAST_SCENARIO LFS,
              ACCOUNT_LOSS_FACTOR ALF
       WHERE A.ACCOUNT_ID = p_ACCOUNT_ID -- Get applicable accounts
              AND UPPER(SUBSTR(A.ACCOUNT_MODEL_OPTION,1,1)) = 'A' -- Account or Aggregate
              AND NVL(p_METER_ID,CONSTANTS.NOT_ASSIGNED) = CONSTANTS.NOT_ASSIGNED -- can't specify meter ID for these
              AND EXISTS (SELECT 1 -- make sure valid service location assigned - make sure it matches specified ID if one was specified
                                  FROM ACCOUNT_SERVICE_LOCATION ASL
                                  WHERE ASL.ACCOUNT_ID = A.ACCOUNT_ID
                                         AND NVL(p_SERVICE_LOCATION_ID,CONSTANTS.NOT_ASSIGNED) IN (ASL.SERVICE_LOCATION_ID, CONSTANTS.NOT_ASSIGNED)
                                         AND p_SERVICE_DATE BETWEEN ASL.BEGIN_DATE AND NVL(ASL.END_DATE, CONSTANTS.HIGH_DATE))
              -- now get loss factor ID for this account and for specified scenario
              AND S.SCENARIO_ID = p_SCENARIO_ID
              AND LFS.SCENARIO_ID = S.SCENARIO_ID
              AND ALF.CASE_ID = LFS.LOSS_FACTOR_CASE_ID
              AND ALF.ACCOUNT_ID = A.ACCOUNT_ID
              AND p_SERVICE_DATE BETWEEN ALF.BEGIN_DATE AND NVL(ALF.END_DATE, CONSTANTS.HIGH_DATE)
       UNION
       -- And gather loss factor IDs for meter-model accounts
       SELECT MLF.LOSS_FACTOR_ID
       --BULK COLLECT INTO v_RET
       FROM ACCOUNT A,
              ACCOUNT_SERVICE_LOCATION ASL,
              SERVICE_LOCATION_METER SLM,
              SCENARIO S,
              LOAD_FORECAST_SCENARIO LFS,
              METER_LOSS_FACTOR MLF
       WHERE A.ACCOUNT_ID = p_ACCOUNT_ID
              AND UPPER(SUBSTR(A.ACCOUNT_MODEL_OPTION,1,1)) = 'M' -- Neter
              AND ASL.ACCOUNT_ID = A.ACCOUNT_ID -- get all applicable service locations
              AND NVL(p_SERVICE_LOCATION_ID,CONSTANTS.NOT_ASSIGNED) IN (ASL.SERVICE_LOCATION_ID, CONSTANTS.NOT_ASSIGNED)
              AND p_SERVICE_DATE BETWEEN ASL.BEGIN_DATE AND NVL(ASL.END_DATE, CONSTANTS.HIGH_DATE)
              AND SLM.SERVICE_LOCATION_ID = ASL.SERVICE_LOCATION_ID -- and get all applicable meters
              AND NVL(p_METER_ID,CONSTANTS.NOT_ASSIGNED) IN (SLM.METER_ID, CONSTANTS.NOT_ASSIGNED)
              AND p_SERVICE_DATE BETWEEN SLM.BEGIN_DATE AND NVL(SLM.END_DATE, CONSTANTS.HIGH_DATE)
              -- now get loss factor ID for this meter and for specified scenario
              AND S.SCENARIO_ID = p_SCENARIO_ID
              AND LFS.SCENARIO_ID = S.SCENARIO_ID
              AND MLF.CASE_ID = LFS.LOSS_FACTOR_CASE_ID
              AND MLF.METER_ID = SLM.METER_ID
              AND p_SERVICE_DATE BETWEEN MLF.BEGIN_DATE AND NVL(MLF.END_DATE, CONSTANTS.HIGH_DATE);

       RETURN v_RET; -- got'em!
END GET_SERVICE_LOSS_FACTOR_IDs;
---------------------------------------------------------------------------------------------------
FUNCTION GET_MARKET_PRICE
	(
	p_MARKET_PRICE_ID IN MARKET_PRICE_VALUE.MARKET_PRICE_ID%TYPE,    
    p_PRICE_DATE IN DATE,
    p_PRICE_CODE IN MARKET_PRICE_VALUE.PRICE_CODE%TYPE DEFAULT NULL
	) RETURN NUMBER AS
    v_VALUE MARKET_PRICE_VALUE.PRICE%TYPE;
BEGIN
    IF p_PRICE_CODE IS NULL THEN 
        SELECT MPV.PRICE
        INTO v_VALUE
        FROM MARKET_PRICE_VALUE MPV
        WHERE MPV.MARKET_PRICE_ID = p_MARKET_PRICE_ID
            AND MPV.PRICE_CODE = (SELECT DECODE(MAX(DECODE(PRICE_CODE,'F',1,'P',2,'A',3)),1,'F',2,'P',3,'A')
                                  FROM MARKET_PRICE_VALUE
                                  WHERE MPV.MARKET_PRICE_ID = p_MARKET_PRICE_ID
                                    AND MPV.PRICE_DATE = p_PRICE_DATE)
            AND MPV.PRICE_DATE = p_PRICE_DATE;
    ELSE
        SELECT MPV.PRICE
        INTO v_VALUE
        FROM MARKET_PRICE_VALUE MPV
        WHERE MPV.MARKET_PRICE_ID = p_MARKET_PRICE_ID
            AND MPV.PRICE_CODE = p_PRICE_CODE
            AND MPV.PRICE_DATE = p_PRICE_DATE;
    END IF;
    
    RETURN v_VALUE;
END GET_MARKET_PRICE;
---------------------------------------------------------------------------------------------------
END CALC_UTIL;
/
