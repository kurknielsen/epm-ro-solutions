BEGIN
	INSERT INTO MODEL (MODEL_ID, MODEL_NAME) VALUES (1, 'Electric');
EXCEPTION
	wHEN DUP_VAL_ON_INDEX THEN
		NULL; -- ignore
END;
/

BEGIN
	INSERT INTO MODEL (MODEL_ID, MODEL_NAME) VALUES (2, 'Gas');
EXCEPTION
	wHEN DUP_VAL_ON_INDEX THEN
		NULL; -- ignore
END;
/


BEGIN
	INSERT INTO CALENDAR (CALENDAR_ID, CALENDAR_NAME, CALENDAR_ALIAS, CALENDAR_DESC, ENTRY_DATE) VALUES (1, 'Customer Usage WRF', 'Customer Usage WRF', 'Customer Usage WRF', SYSDATE);
EXCEPTION
	wHEN DUP_VAL_ON_INDEX THEN
		NULL; -- ignore
END;
/

BEGIN
	INSERT INTO PERIOD (PERIOD_ID, PERIOD_NAME, PERIOD_ALIAS, PERIOD_DESC, PERIOD_COLOR, ENTRY_DATE)
	VALUES (2, 'On-Peak Projection', 'On-Peak Projection', 'On-Peak Projection', 255, SYSDATE);
EXCEPTION
	wHEN DUP_VAL_ON_INDEX THEN
		NULL; -- ignore
END;
/


BEGIN
	INSERT INTO PERIOD (PERIOD_ID, PERIOD_NAME, PERIOD_ALIAS, PERIOD_DESC, PERIOD_COLOR, ENTRY_DATE)
	VALUES (3, 'Off-Peak Projection', 'Off-Peak Projection', 'Off-Peak Projection', 16711680, SYSDATE);
EXCEPTION
	wHEN DUP_VAL_ON_INDEX THEN
		NULL; -- ignore
END;
/


BEGIN
	INSERT INTO PERIOD (PERIOD_ID, PERIOD_NAME, PERIOD_ALIAS, PERIOD_DESC, PERIOD_COLOR, ENTRY_DATE)
	VALUES (4, 'All Hours', 'All Hours', 'Used as the PERIOD_ID for Day Type Templates', -16738048, SYSDATE);
EXCEPTION
	wHEN DUP_VAL_ON_INDEX THEN
		NULL; -- ignore
END;
/

BEGIN
	INSERT INTO HOLIDAY_SET ( HOLIDAY_SET_ID, HOLIDAY_SET_NAME, HOLIDAY_SET_ALIAS, HOLIDAY_SET_DESC, ENTRY_DATE)
	VALUES ( 1, 'All Holidays', 'All Holidays', 'This special Holiday Set contains all holidays.', SYSDATE);
EXCEPTION
	WHEN DUP_VAL_ON_INDEX THEN
		NULL; -- IGNORE
END;
/

DECLARE
	v_MESSAGE VARCHAR2(4000);
BEGIN
	INSERT INTO TEMPLATE (TEMPLATE_ID, TEMPLATE_NAME, TEMPLATE_ALIAS, TEMPLATE_DESC, IS_DAY_TYPE, IS_DST_OBSERVANT, ENTRY_DATE)
	VALUES (2, 'Projection', 'Projection', 'Projection', 0, 1, SYSDATE);

	INSERT INTO SEASON_TEMPLATE (TEMPLATE_ID, SEASON_ID, DAY_NAME, BEGIN_INTERVAL, END_INTERVAL, PERIOD_ID, ENTRY_DATE) VALUES (2, 1, 'Mon', '00:00:01', '06:00:00', 3, SYSDATE);
	INSERT INTO SEASON_TEMPLATE (TEMPLATE_ID, SEASON_ID, DAY_NAME, BEGIN_INTERVAL, END_INTERVAL, PERIOD_ID, ENTRY_DATE) VALUES (2, 1, 'Mon', '06:00:01', '22:00:00', 2, SYSDATE);
	INSERT INTO SEASON_TEMPLATE (TEMPLATE_ID, SEASON_ID, DAY_NAME, BEGIN_INTERVAL, END_INTERVAL, PERIOD_ID, ENTRY_DATE) VALUES (2, 1, 'Mon', '22:00:01', '24:00:00', 3, SYSDATE);

	INSERT INTO SEASON_TEMPLATE (TEMPLATE_ID, SEASON_ID, DAY_NAME, BEGIN_INTERVAL, END_INTERVAL, PERIOD_ID, ENTRY_DATE) VALUES (2, 1, 'Tue', '00:00:01', '06:00:00', 3, SYSDATE);
	INSERT INTO SEASON_TEMPLATE (TEMPLATE_ID, SEASON_ID, DAY_NAME, BEGIN_INTERVAL, END_INTERVAL, PERIOD_ID, ENTRY_DATE) VALUES (2, 1, 'Tue', '06:00:01', '22:00:00', 2, SYSDATE);
	INSERT INTO SEASON_TEMPLATE (TEMPLATE_ID, SEASON_ID, DAY_NAME, BEGIN_INTERVAL, END_INTERVAL, PERIOD_ID, ENTRY_DATE) VALUES (2, 1, 'Tue', '22:00:01', '24:00:00', 3, SYSDATE);

	INSERT INTO SEASON_TEMPLATE (TEMPLATE_ID, SEASON_ID, DAY_NAME, BEGIN_INTERVAL, END_INTERVAL, PERIOD_ID, ENTRY_DATE) VALUES (2, 1, 'Wed', '00:00:01', '06:00:00', 3, SYSDATE);
	INSERT INTO SEASON_TEMPLATE (TEMPLATE_ID, SEASON_ID, DAY_NAME, BEGIN_INTERVAL, END_INTERVAL, PERIOD_ID, ENTRY_DATE) VALUES (2, 1, 'Wed', '06:00:01', '22:00:00', 2, SYSDATE);
	INSERT INTO SEASON_TEMPLATE (TEMPLATE_ID, SEASON_ID, DAY_NAME, BEGIN_INTERVAL, END_INTERVAL, PERIOD_ID, ENTRY_DATE) VALUES (2, 1, 'Wed', '22:00:01', '24:00:00', 3, SYSDATE);

	INSERT INTO SEASON_TEMPLATE (TEMPLATE_ID, SEASON_ID, DAY_NAME, BEGIN_INTERVAL, END_INTERVAL, PERIOD_ID, ENTRY_DATE) VALUES (2, 1, 'Thu', '00:00:01', '06:00:00', 3, SYSDATE);
	INSERT INTO SEASON_TEMPLATE (TEMPLATE_ID, SEASON_ID, DAY_NAME, BEGIN_INTERVAL, END_INTERVAL, PERIOD_ID, ENTRY_DATE) VALUES (2, 1, 'Thu', '06:00:01', '22:00:00', 2, SYSDATE);
	INSERT INTO SEASON_TEMPLATE (TEMPLATE_ID, SEASON_ID, DAY_NAME, BEGIN_INTERVAL, END_INTERVAL, PERIOD_ID, ENTRY_DATE) VALUES (2, 1, 'Thu', '22:00:01', '24:00:00', 3, SYSDATE);

	INSERT INTO SEASON_TEMPLATE (TEMPLATE_ID, SEASON_ID, DAY_NAME, BEGIN_INTERVAL, END_INTERVAL, PERIOD_ID, ENTRY_DATE) VALUES (2, 1, 'Fri', '00:00:01', '06:00:00', 3, SYSDATE);
	INSERT INTO SEASON_TEMPLATE (TEMPLATE_ID, SEASON_ID, DAY_NAME, BEGIN_INTERVAL, END_INTERVAL, PERIOD_ID, ENTRY_DATE) VALUES (2, 1, 'Fri', '06:00:01', '22:00:00', 2, SYSDATE);
	INSERT INTO SEASON_TEMPLATE (TEMPLATE_ID, SEASON_ID, DAY_NAME, BEGIN_INTERVAL, END_INTERVAL, PERIOD_ID, ENTRY_DATE) VALUES (2, 1, 'Fri', '22:00:01', '24:00:00', 3, SYSDATE);

	INSERT INTO SEASON_TEMPLATE (TEMPLATE_ID, SEASON_ID, DAY_NAME, BEGIN_INTERVAL, END_INTERVAL, PERIOD_ID, ENTRY_DATE) VALUES (2, 1, 'Sat', '00:00:01', '24:00:00', 3, SYSDATE);
	INSERT INTO SEASON_TEMPLATE (TEMPLATE_ID, SEASON_ID, DAY_NAME, BEGIN_INTERVAL, END_INTERVAL, PERIOD_ID, ENTRY_DATE) VALUES (2, 1, 'Sun', '00:00:01', '24:00:00', 3, SYSDATE);
	INSERT INTO SEASON_TEMPLATE (TEMPLATE_ID, SEASON_ID, DAY_NAME, BEGIN_INTERVAL, END_INTERVAL, PERIOD_ID, ENTRY_DATE) VALUES (2, 1, 'Hol', '00:00:01', '24:00:00', 3, SYSDATE);
	
	EM.VALIDATE_TOU_TEMPLATE(2, v_MESSAGE);
EXCEPTION
	wHEN DUP_VAL_ON_INDEX THEN
		NULL; -- ignore
END;
/

DECLARE
TYPE MON_NAME_TABLE IS TABLE OF VARCHAR(16) INDEX BY BINARY_INTEGER;
TYPE DAY_NAME_TABLE IS TABLE OF CHAR(3) INDEX BY BINARY_INTEGER;
v_DAY_INDEX BINARY_INTEGER;
v_MON_INDEX BINARY_INTEGER;
v_MON_NAME  MON_NAME_TABLE;
v_DAY_NAME  DAY_NAME_TABLE;
v_MONTH_DATE DATE := DATE '1900-01-01';
v_OID NUMBER(9);

	v_MESSAGE VARCHAR2(4000);
BEGIN
	v_MON_NAME(1) := 'January';
	v_MON_NAME(2) := 'February';
	v_MON_NAME(3) := 'March';
	v_MON_NAME(4) := 'April';
	v_MON_NAME(5) := 'May';
	v_MON_NAME(6) := 'June';
	v_MON_NAME(7) := 'July';
	v_MON_NAME(8) := 'August';
	v_MON_NAME(9) := 'September';
	v_MON_NAME(10) := 'October';
	v_MON_NAME(11) := 'November';
	v_MON_NAME(12) := 'December';

	v_DAY_NAME(1) := 'Mon';
	v_DAY_NAME(2) := 'Tue';
	v_DAY_NAME(3) := 'Wed';
	v_DAY_NAME(4) := 'Thu';
	v_DAY_NAME(5) := 'Fri';
	v_DAY_NAME(6) := 'Sat';
	v_DAY_NAME(7) := 'Sun';
	v_DAY_NAME(8) := 'Hol';

	-- create seasons
	FOR v_MON_INDEX IN 1..12 LOOP
		BEGIN
			INSERT INTO SEASON (SEASON_ID, SEASON_NAME, SEASON_ALIAS, SEASON_DESC, BEGIN_DATE, END_DATE, ENTRY_DATE)
			VALUES (v_MON_INDEX + 1, v_MON_NAME(v_MON_INDEX), SUBSTR(v_MON_NAME(v_MON_INDEX),1,3), 'Created by RetailOffice. Do not delete.', v_MONTH_DATE, LAST_DAY(v_MONTH_DATE), SYSDATE);
		EXCEPTION
			wHEN DUP_VAL_ON_INDEX THEN
				NULL; -- ignore
		END;
		v_MONTH_DATE := ADD_MONTHS(v_MONTH_DATE,1);
	END LOOP;

	-- create Monthly template
	BEGIN
		INSERT INTO TEMPLATE (TEMPLATE_ID, TEMPLATE_NAME, TEMPLATE_ALIAS, TEMPLATE_DESC, IS_DAY_TYPE, IS_DST_OBSERVANT, ENTRY_DATE)
		VALUES (3, 'Monthly', 'Monthly', 'Created by RetailOffice.', 1, 0, SYSDATE);
		FOR v_MON_INDEX IN 1..12 LOOP
			FOR v_DAY_INDEX IN 1..8 LOOP
				INSERT INTO TEMPLATE_SEASON_DAY_NAME (TEMPLATE_ID, SEASON_ID, DAY_NAME, ENTRY_DATE)
				VALUES (3, v_MON_INDEX + 1, v_DAY_NAME(v_DAY_INDEX), SYSDATE);
			END LOOP;
		END LOOP;
	EXCEPTION
		wHEN DUP_VAL_ON_INDEX THEN
			NULL; -- ignore
	END;

	-- create Monthly On-Off Peak template
	DECLARE
		v_MESSAGE VARCHAR2(4000);
	BEGIN
		INSERT INTO TEMPLATE (TEMPLATE_ID, TEMPLATE_NAME, TEMPLATE_ALIAS, TEMPLATE_DESC, IS_DAY_TYPE, IS_DST_OBSERVANT, ENTRY_DATE)
		VALUES (4, 'Monthly On-Off Peak', 'Monthly On-Off Peak', 'Created by RetailOffice.', 0, 1, SYSDATE);
		FOR v_MON_INDEX IN 1..12 LOOP
			FOR v_DAY_INDEX IN 1..8 LOOP
				INSERT INTO SEASON_TEMPLATE (TEMPLATE_ID, SEASON_ID, DAY_NAME, BEGIN_INTERVAL, END_INTERVAL, PERIOD_ID, ENTRY_DATE)
				VALUES(4, v_MON_INDEX + 1, v_DAY_NAME(v_DAY_INDEX), '00:00:01', '06:00:00', 3, SYSDATE);

				INSERT INTO SEASON_TEMPLATE (TEMPLATE_ID, SEASON_ID, DAY_NAME, BEGIN_INTERVAL, END_INTERVAL, PERIOD_ID, ENTRY_DATE)
				VALUES(4, v_MON_INDEX + 1, v_DAY_NAME(v_DAY_INDEX), '06:00:01', '22:00:00', 2, SYSDATE);

				INSERT INTO SEASON_TEMPLATE (TEMPLATE_ID, SEASON_ID, DAY_NAME, BEGIN_INTERVAL, END_INTERVAL, PERIOD_ID, ENTRY_DATE)
				VALUES(4, v_MON_INDEX + 1, v_DAY_NAME(v_DAY_INDEX), '22:00:01', '24:00:00', 3, SYSDATE);
			END LOOP;
		END LOOP;
		
		EM.VALIDATE_TOU_TEMPLATE(4, v_MESSAGE);
	EXCEPTION
		wHEN DUP_VAL_ON_INDEX THEN
			NULL; -- ignore
	END;
END;
/

BEGIN
	INSERT INTO CASE_LABEL (CASE_ID, CASE_NAME, CASE_ALIAS, CASE_DESC, CASE_CATEGORY, ENTRY_DATE)
	VALUES (1, 'Base', 'Base', 'Base', 'All', SYSDATE);
EXCEPTION
	wHEN DUP_VAL_ON_INDEX THEN
		NULL; -- ignore
END;
/

BEGIN
	INSERT INTO CASE_LABEL (CASE_ID, CASE_NAME, CASE_ALIAS, CASE_DESC, CASE_CATEGORY, ENTRY_DATE)
	VALUES (2, 'None', 'None', 'None', 'All', SYSDATE);
EXCEPTION
	wHEN DUP_VAL_ON_INDEX THEN
		NULL; -- ignore
END;
/

BEGIN
	INSERT INTO SCENARIO (SCENARIO_ID, SCENARIO_NAME, SCENARIO_ALIAS, SCENARIO_DESC, SCENARIO_CATEGORY, ENTRY_DATE)
	VALUES (1, 'Base', 'Base', 'Base', 'All', SYSDATE);
EXCEPTION
	wHEN DUP_VAL_ON_INDEX THEN
		NULL; -- ignore
END;
/

BEGIN
	INSERT INTO GROWTH_PATTERN(PATTERN_ID, PATTERN_NAME, PATTERN_ALIAS, PATTERN_DESC, JAN_PCT, FEB_PCT, MAR_PCT, APR_PCT, MAY_PCT, JUN_PCT, JUL_PCT, AUG_PCT, SEP_PCT, OCT_PCT, NOV_PCT, DEC_PCT, ENTRY_DATE)
	VALUES (1, 'Year', 'Year', 'Year', 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, SYSDATE);
EXCEPTION
	wHEN DUP_VAL_ON_INDEX THEN
		NULL; -- ignore
END;
/

BEGIN
	INSERT INTO GROWTH_PATTERN(PATTERN_ID, PATTERN_NAME, PATTERN_ALIAS, PATTERN_DESC, JAN_PCT, FEB_PCT, MAR_PCT, APR_PCT, MAY_PCT, JUN_PCT, JUL_PCT, AUG_PCT, SEP_PCT, OCT_PCT, NOV_PCT, DEC_PCT, ENTRY_DATE)
	VALUES (2, 'Month', 'Month', 'Month', 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, SYSDATE);
EXCEPTION
	wHEN DUP_VAL_ON_INDEX THEN
		NULL; -- ignore
END;
/

BEGIN
	INSERT INTO LOAD_FORECAST_SCENARIO (SCENARIO_ID, WEATHER_CASE_ID, AREA_LOAD_CASE_ID, ENROLLMENT_CASE_ID, CALENDAR_CASE_ID, USAGE_FACTOR_CASE_ID, LOSS_FACTOR_CASE_ID, GROWTH_FACTOR_CASE_ID, RUN_MODE, ENTRY_DATE)
	VALUES (1, 1, 1, 1, 1, 1, 1, 1, 0, SYSDATE);
EXCEPTION
	wHEN DUP_VAL_ON_INDEX THEN
		NULL; -- ignore
END;
/

BEGIN
	INSERT INTO STATEMENT_FORECAST_SCENARIO (SCENARIO_ID, LOAD_SCENARIO_ID, PRODUCT_CASE_ID, ENTRY_DATE)
	VALUES (1, 1, 1, SYSDATE);
EXCEPTION
	wHEN DUP_VAL_ON_INDEX THEN
		NULL; -- ignore
END;
/

BEGIN
	INSERT INTO SYSTEM_EVENT(EVENT_ID, EVENT_NAME, EVENT_ALIAS, EVENT_DESC, EVENT_TYPE, EVENT_CATEGORY, ENTRY_DATE)
	VALUES (1, 'Any', 'Any', 'Any', 'System', 'System', SYSDATE);
EXCEPTION
	wHEN DUP_VAL_ON_INDEX THEN
		NULL; -- ignore
END;
/

BEGIN
	INSERT INTO SYSTEM_EVENT(EVENT_ID, EVENT_NAME, EVENT_ALIAS, EVENT_DESC, EVENT_TYPE, EVENT_CATEGORY, ENTRY_DATE)
	VALUES (2, 'None', 'None', 'None', 'System', 'System', SYSDATE);
EXCEPTION
	wHEN DUP_VAL_ON_INDEX THEN
		NULL; -- ignore
END;
/

BEGIN
	INSERT INTO STATEMENT_TYPE(STATEMENT_TYPE_ID, STATEMENT_TYPE_NAME, STATEMENT_TYPE_ALIAS, STATEMENT_TYPE_DESC, STATEMENT_TYPE_ORDER, ENTRY_DATE)
	VALUES (1, 'Forecast', 'Forecast', 'Forecast', 1, SYSDATE);
EXCEPTION
	wHEN DUP_VAL_ON_INDEX THEN
		NULL; -- ignore
END;
/

BEGIN
	INSERT INTO STATEMENT_TYPE(STATEMENT_TYPE_ID, STATEMENT_TYPE_NAME, STATEMENT_TYPE_ALIAS, STATEMENT_TYPE_DESC, STATEMENT_TYPE_ORDER, ENTRY_DATE)
	VALUES (2, 'Preliminary', 'Preliminary', 'Preliminary', 2, SYSDATE);
EXCEPTION
	wHEN DUP_VAL_ON_INDEX THEN
		NULL; -- ignore
END;
/

BEGIN
	INSERT INTO STATEMENT_TYPE(STATEMENT_TYPE_ID, STATEMENT_TYPE_NAME, STATEMENT_TYPE_ALIAS, STATEMENT_TYPE_DESC, STATEMENT_TYPE_ORDER, ENTRY_DATE)
	VALUES (3, 'Final', 'Final', 'Final', 3, SYSDATE);
EXCEPTION
	wHEN DUP_VAL_ON_INDEX THEN
		NULL; -- ignore
END;
/

BEGIN
	INSERT INTO IT_COMMODITY (COMMODITY_ID,COMMODITY_NAME,COMMODITY_ALIAS,COMMODITY_DESC,COMMODITY_TYPE,COMMODITY_UNIT,COMMODITY_UNIT_FORMAT,COMMODITY_PRICE_UNIT,COMMODITY_PRICE_FORMAT,ENTRY_DATE)
	VALUES (1,'Retail Load','Retail Load','Retail Load','Energy','?','?','Dollars','?',SYSDATE);
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        NULL;
END;
/

BEGIN
	INSERT INTO IT_COMMODITY (COMMODITY_ID,COMMODITY_NAME,COMMODITY_ALIAS,COMMODITY_DESC,COMMODITY_TYPE,COMMODITY_UNIT,COMMODITY_UNIT_FORMAT,COMMODITY_PRICE_UNIT,COMMODITY_PRICE_FORMAT,ENTRY_DATE)
	VALUES (2,'Energy','Energy','Energy','Energy','MWH','?','Dollars','?',SYSDATE);
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        NULL;
END;
/

BEGIN
	INSERT INTO IT_COMMODITY (COMMODITY_ID,COMMODITY_NAME,COMMODITY_ALIAS,COMMODITY_DESC,COMMODITY_TYPE,COMMODITY_UNIT,COMMODITY_UNIT_FORMAT,COMMODITY_PRICE_UNIT,COMMODITY_PRICE_FORMAT,ENTRY_DATE)
	VALUES (3,'Capacity','Capacity','Capacity','Capacity','?','?','Dollars','?',SYSDATE);
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        NULL;
END;
/

BEGIN
	INSERT INTO IT_COMMODITY (COMMODITY_ID,COMMODITY_NAME,COMMODITY_ALIAS,COMMODITY_DESC,COMMODITY_TYPE,COMMODITY_UNIT,COMMODITY_UNIT_FORMAT,COMMODITY_PRICE_UNIT,COMMODITY_PRICE_FORMAT,ENTRY_DATE)
	VALUES (4,'Transmission','Transmission','Transmission','Transmission','MW','?','Dollars','?',SYSDATE);
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        NULL;
END;
/

BEGIN
	INSERT INTO IT_COMMODITY (COMMODITY_ID,COMMODITY_NAME,COMMODITY_ALIAS,COMMODITY_DESC,COMMODITY_TYPE,COMMODITY_UNIT,COMMODITY_UNIT_FORMAT,COMMODITY_PRICE_UNIT,COMMODITY_PRICE_FORMAT,ENTRY_DATE)
	VALUES (5,'Transportation','Transportation','Transportation','Transportation','DT','?','Dollars','?',SYSDATE);
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        NULL;
END;
/

BEGIN
	INSERT INTO IT_COMMODITY (COMMODITY_ID,COMMODITY_NAME,COMMODITY_ALIAS,COMMODITY_DESC,COMMODITY_TYPE,COMMODITY_UNIT,COMMODITY_UNIT_FORMAT,COMMODITY_PRICE_UNIT,COMMODITY_PRICE_FORMAT,ENTRY_DATE)
	VALUES (6,'Gas','Gas','Gas','Gas','DT','?','Dollars','?',SYSDATE);
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        UPDATE IT_COMMODITY SET COMMODITY_TYPE='Gas' WHERE COMMODITY_ID = 6;
END;
/

--SETTLEMENT TYPES
BEGIN
	INSERT INTO SETTLEMENT_TYPE(SETTLEMENT_TYPE_ID, SETTLEMENT_TYPE_NAME, SETTLEMENT_TYPE_ALIAS, SETTLEMENT_TYPE_DESC, SETTLEMENT_TYPE_ORDER, SERVICE_CODE, SCENARIO_ID, STATEMENT_TYPE_ID, ENTRY_DATE)
	VALUES (1, 'Preliminary', 'Preliminary', 'Preliminary', 1, 'B', 1, 2, SYSDATE);
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        NULL;
END;
/
BEGIN
	INSERT INTO SETTLEMENT_TYPE(SETTLEMENT_TYPE_ID, SETTLEMENT_TYPE_NAME, SETTLEMENT_TYPE_ALIAS, SETTLEMENT_TYPE_DESC, SETTLEMENT_TYPE_ORDER, SERVICE_CODE, SCENARIO_ID, STATEMENT_TYPE_ID, ENTRY_DATE)
	VALUES (2, 'Final', 'Final', 'Final', 2, 'A', 1, 3, SYSDATE);
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        NULL;
END;
/

-- add the categories if they don't already exist. search by name, and delete any existing ones because that would cause
-- cascading deletes of contacts and addresses (doh!)
DECLARE
v_NUM_ROWS NUMBER;
BEGIN
	SELECT COUNT(*)
	INTO v_NUM_ROWS
	FROM CATEGORY
	WHERE CATEGORY_NAME = 'Invoice Primary';
	IF v_NUM_ROWS = 0 THEN
		INSERT INTO CATEGORY(CATEGORY_ID, CATEGORY_NAME, CATEGORY_ALIAS, CATEGORY_DESC, ENTRY_DATE) VALUES (1, 'Invoice Primary', 'Invoice Primary', 'Invoice Primary', SYSDATE);
	END IF;

	SELECT COUNT(*)
	INTO v_NUM_ROWS
	FROM CATEGORY
	WHERE CATEGORY_NAME = 'Invoice Secondary';
	IF v_NUM_ROWS = 0 THEN
		INSERT INTO CATEGORY(CATEGORY_ID, CATEGORY_NAME, CATEGORY_ALIAS, CATEGORY_DESC, ENTRY_DATE) VALUES (2, 'Invoice Secondary', 'Invoice Secondary', 'Invoice Secondary', SYSDATE);
	END IF;

	SELECT COUNT(*)
	INTO v_NUM_ROWS
	FROM CATEGORY
	WHERE CATEGORY_NAME = 'Billing';
	IF v_NUM_ROWS = 0 THEN
		INSERT INTO CATEGORY(CATEGORY_ID, CATEGORY_NAME, CATEGORY_ALIAS, CATEGORY_DESC, ENTRY_DATE) VALUES (3, 'Billing', 'Billing', 'Billing', SYSDATE);
	END IF;

	SELECT COUNT(*)
	INTO v_NUM_ROWS
	FROM CATEGORY
	WHERE CATEGORY_NAME = 'Payment';
	IF v_NUM_ROWS = 0 THEN
		INSERT INTO CATEGORY(CATEGORY_ID, CATEGORY_NAME, CATEGORY_ALIAS, CATEGORY_DESC, ENTRY_DATE) VALUES (4, 'Payment', 'Payment', 'Payment', SYSDATE);
	END IF;

	SELECT COUNT(*)
	INTO v_NUM_ROWS
	FROM CATEGORY
	WHERE CATEGORY_NAME = 'Locale';
	IF v_NUM_ROWS = 0 THEN
		INSERT INTO CATEGORY(CATEGORY_ID, CATEGORY_NAME, CATEGORY_ALIAS, CATEGORY_DESC, ENTRY_DATE) VALUES (5, 'Locale', 'Locale', 'Locale', SYSDATE);
	END IF;
	
	SELECT COUNT(*)
	INTO v_NUM_ROWS
	FROM CATEGORY
	WHERE CATEGORY_NAME = 'Sales Rep';
	IF v_NUM_ROWS = 0 THEN
		INSERT INTO CATEGORY(CATEGORY_ID, CATEGORY_NAME, CATEGORY_ALIAS, CATEGORY_DESC, ENTRY_DATE) VALUES (6, 'Sales Rep', 'Sales Rep', 'Sales Rep', SYSDATE);
	END IF;
	
	SELECT COUNT(*)
	INTO v_NUM_ROWS
	FROM CATEGORY
	WHERE CATEGORY_NAME = 'Scheduler';
	IF v_NUM_ROWS = 0 THEN
		INSERT INTO CATEGORY(CATEGORY_ID, CATEGORY_NAME, CATEGORY_ALIAS, CATEGORY_DESC, ENTRY_DATE) VALUES (7, 'Scheduler', 'Scheduler', 'Scheduler', SYSDATE);
	END IF;
END;
/

DECLARE
v_COUNT NUMBER;
v_ID NUMBER;
BEGIN
	SELECT COUNT(*) INTO v_COUNT
	FROM SYSTEM_ALERT 
	WHERE ALERT_NAME LIKE 'Certificate Expiration';
	IF v_COUNT = 0 THEN
		IO.PUT_SYSTEM_ALERT(v_ID, 'Certificate Expiration', 'Certificate Expiration', 
				'An external credential certificate will expire within 30 days', 
				null, '?', '?',0,1, 0, 0, 'Certificate Expiration', 0,'?');
		INSERT INTO SYSTEM_ALERT_ROLE
		SELECT v_ID, ROLE_ID, 'TO' 
		FROM APPLICATION_ROLE 
		WHERE ROLE_NAME LIKE 'Administrator';

		INSERT INTO SYSTEM_ALERT_TRIGGER
		SELECT v_ID, 'Other', 0, 0, '*', 1, 'Certificate Expiration', 0
		FROM DUAL;
	END IF;

END;
/