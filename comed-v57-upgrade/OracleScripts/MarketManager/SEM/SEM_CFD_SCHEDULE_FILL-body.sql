CREATE OR REPLACE PACKAGE BODY SEM_CFD_SCHEDULE_FILL IS
	----------------------------------------------------------------------------------------------------
	FUNCTION WHAT_VERSION RETURN VARCHAR IS
	BEGIN
		RETURN '$Revision: 1.1 $';
	END WHAT_VERSION;
	----------------------------------------------------------------------------------------------------
	PROCEDURE NULL_CURSOR
		(
		p_CURSOR IN OUT REF_CURSOR
		) AS

	BEGIN

		OPEN p_CURSOR FOR
			SELECT NULL FROM DUAL;

	END NULL_CURSOR;
	----------------------------------------------------------------------------------------------------
	PROCEDURE PUT_IT_SCHEDULE_TO_WORK
		(
		p_WORK_ID IN NUMBER,
		p_WORK_SEQ IN NUMBER,
		p_TRANSACTION_ID IN NUMBER,
		p_WORK_DATE IN DATE,
		p_AMOUNT IN NUMBER,
		p_PRICE IN NUMBER,
		p_AMOUNT2 IN NUMBER DEFAULT NULL
		) AS
	v_AMOUNT VARCHAR2(16);
	v_PRICE VARCHAR2(16);
	v_AMOUNT2 VARCHAR2(16);
	BEGIN
		v_AMOUNT := SUBSTR(TO_CHAR(NVL(p_AMOUNT,0),'999999999D999'),1,14);
		v_PRICE := SUBSTR(TO_CHAR(NVL(p_PRICE,0),'999999999D999'),1,14);
		IF p_AMOUNT2 IS NULL THEN
			v_AMOUNT2 := NULL;
		ELSE
			v_AMOUNT2 := SUBSTR(TO_CHAR(NVL(p_AMOUNT2,0),'999999999D999'),1,14);
		END IF;
		UT.POST_RTO_WORK(p_WORK_ID, p_WORK_SEQ, p_TRANSACTION_ID, p_WORK_DATE, v_AMOUNT||v_PRICE||v_AMOUNT2);
	END PUT_IT_SCHEDULE_TO_WORK;
	----------------------------------------------------------------------------------------------------
	PROCEDURE SCHEDULE_FILL
		(
		p_TRANSACTION_ID IN NUMBER,
		p_BEGIN_DATE IN DATE,
		p_END_DATE IN DATE,
		p_AS_OF_DATE IN DATE,
		p_TIME_ZONE IN VARCHAR,
		p_AMOUNT IN VARCHAR,
		p_PRICE IN VARCHAR,
		p_TEMPLATE IN VARCHAR,
		p_BEGIN_INTERVAL IN NUMBER,
		p_END_INTERVAL IN NUMBER,
		p_INCLUDE_HOLIDAYS IN NUMBER,
		p_SCHEDULE_TYPE IN NUMBER,
		p_STATUS OUT NUMBER,
		p_TO_WORK IN NUMBER := 0,
		p_WORK_ID IN NUMBER := 0,
		p_USE_INTERVAL IN VARCHAR2 := NULL,
		p_AMOUNT2 IN NUMBER := NULL
		) AS

	v_SCHEDULE_DATE DATE;
	v_SCHEDULE_END_DATE DATE;
	v_DAY CHAR(3);
	v_INTV NUMBER;
	v_BEGIN_DATE DATE;
	v_END_DATE DATE;
	v_TIME_ZONE VARCHAR(3);
	v_ANY_DAY BOOLEAN;
	v_WEEK_DAY BOOLEAN;
	v_WEEK_END BOOLEAN;
	v_MON BOOLEAN;
	v_TUE BOOLEAN;
	v_WED BOOLEAN;
	v_THU BOOLEAN;
	v_FRI BOOLEAN;
	v_SAT BOOLEAN;
	v_SUN BOOLEAN;
	v_ALL BOOLEAN;
	v_ON BOOLEAN;
	v_OFF BOOLEAN;
	v_DELETE BOOLEAN;
	v_YES CHAR(1) := '1';
	v_COUNT NUMBER;
	v_AMOUNT NUMBER;
	v_PRICE NUMBER;
	v_NEW_AMOUNT NUMBER;
	v_NEW_PRICE NUMBER;
	v_DAY_SCHEDULE BOOLEAN;
	v_DATE DATE;
	v_INTERVAL VARCHAR(16);
	v_INCLUDE_DAY BOOLEAN;
	v_TRANSACTION_TYPE INTERCHANGE_TRANSACTION.TRANSACTION_TYPE%TYPE;
	v_CONTRACT_ID NUMBER;
	v_SCHEDULE_TYPE NUMBER(9);
	v_EDC_ID NUMBER(9);
	v_AUDIT_TYPE NUMBER;
	

	BEGIN

		IF NOT CAN_WRITE(ITJ.g_MODULE_NAME) THEN
			ERRS.RAISE_NO_WRITE_MODULE(ITJ.g_MODULE_NAME);
		END IF;

		IF NOT SD.GET_ENTITY_IS_ALLOWED(SD.g_ACTION_TXN_UPDATE, p_TRANSACTION_ID) THEN
			--RAISE ITJ.INSUFFICIENT_PRIVILEGES;
			ERRS.RAISE_NO_PRIVILEGE_ACTION(SD.g_ACTION_TXN_UPDATE, p_TRANSACTION_ID);
		END IF;

		IF LOGS.IS_DEBUG_ENABLED THEN
			LOGS.LOG_DEBUG('TRANSACTION_ID=' || TO_CHAR(p_TRANSACTION_ID));
			LOGS.LOG_DEBUG('BEGIN_DATE=' || UT.TRACE_DATE(p_BEGIN_DATE));
			LOGS.LOG_DEBUG('END_DATE=' || UT.TRACE_DATE(p_END_DATE));
			LOGS.LOG_DEBUG('TIME_ZONE=' || p_TIME_ZONE);
			LOGS.LOG_DEBUG('AMOUNT=' || p_AMOUNT);
			LOGS.LOG_DEBUG('PRICE=' || p_PRICE);
			LOGS.LOG_DEBUG('TEMPLATE=' || p_TEMPLATE);
			LOGS.LOG_DEBUG('BEGIN_INTERVAL=' || TO_CHAR(p_BEGIN_INTERVAL));
			LOGS.LOG_DEBUG('END_INTERVAL=' || TO_CHAR(p_END_INTERVAL));
			LOGS.LOG_DEBUG('INCLUDE_HOLIDAYS=' || TO_CHAR(p_INCLUDE_HOLIDAYS));
		END IF;
		

		IF NVL(p_TO_WORK, 0) = 0 THEN -- no need to audit entries to work table
			SELECT DECODE(NVL(MODEL_VALUE_AT_KEY(0,'Audit Trail','Scheduling','ScheduleFillBehavior',0),'0'),'1',1,'2',2,0)
			INTO v_AUDIT_TYPE
			FROM DUAL;
		ELSE
			v_AUDIT_TYPE := 0;
		END IF;

		SELECT BEGIN_DATE,END_DATE,UPPER(TRIM(TRANSACTION_INTERVAL)),TRANSACTION_TYPE,CONTRACT_ID
		INTO v_BEGIN_DATE, v_END_DATE, v_INTERVAL, v_TRANSACTION_TYPE, v_CONTRACT_ID
		FROM INTERCHANGE_TRANSACTION
		WHERE TRANSACTION_ID = p_TRANSACTION_ID;
		-- can only specify an interval when putting schedule to RTO_WORK - not to IT_SCHEDULE
		IF NVL(LENGTH(p_USE_INTERVAL),0) > 0 AND p_TO_WORK = 1 THEN
			v_INTERVAL := UPPER(p_USE_INTERVAL);
		END IF;
		IF NVL(LENGTH(v_INTERVAL),0) = 0 THEN
			p_STATUS := -1;
			RETURN;
		END IF;
		p_STATUS := 0;
		IF p_BEGIN_DATE > v_END_DATE OR p_END_DATE < v_BEGIN_DATE THEN
			p_STATUS := -4;
			RETURN;
		END IF;
		v_AMOUNT := LTRIM(RTRIM(p_AMOUNT));
		v_PRICE := LTRIM(RTRIM(p_PRICE));
		v_TIME_ZONE := LTRIM(RTRIM(p_TIME_ZONE));
		v_SCHEDULE_DATE := TRUNC(GREATEST(p_BEGIN_DATE,v_BEGIN_DATE));
		v_SCHEDULE_END_DATE := TRUNC(LEAST(p_END_DATE,v_END_DATE)) + 1;
		SELECT NVL(EDC_ID,0) INTO v_EDC_ID FROM INTERCHANGE_TRANSACTION WHERE TRANSACTION_ID = p_TRANSACTION_ID;

		IF GA.ENABLE_SUPPLY_SCHEDULE_TYPES THEN
			v_SCHEDULE_TYPE := p_SCHEDULE_TYPE;
		ELSE
			-- 'Retail Load' and 'Load' Schedules get types, others (supply schedules) get zero
			SELECT DECODE(UPPER(SUBSTR(v_TRANSACTION_TYPE,1,2)),'RE',p_SCHEDULE_TYPE,'LO',p_SCHEDULE_TYPE,0) INTO v_SCHEDULE_TYPE FROM DUAL;
		END IF;

		IF v_INTERVAL IN ('DAY','WEEK','MONTH','QUARTER','YEAR') THEN
			v_DAY_SCHEDULE := TRUE;
			IF v_INTERVAL = 'MONTH' THEN
				v_SCHEDULE_DATE := ADD_SECONDS_TO_DATE(TRUNC(v_SCHEDULE_DATE,'MONTH'), 1);
			ELSIF v_INTERVAL = 'QUARTER' THEN
				v_SCHEDULE_DATE := ADD_SECONDS_TO_DATE(TRUNC(v_SCHEDULE_DATE,'Q'), 1);
			ELSIF v_INTERVAL = 'YEAR' THEN
				v_SCHEDULE_DATE := ADD_SECONDS_TO_DATE(TRUNC(v_SCHEDULE_DATE,'YEAR'), 1);
			ELSIF v_INTERVAL = 'WEEK' THEN
				v_SCHEDULE_DATE := ADD_SECONDS_TO_DATE(TRUNC(v_SCHEDULE_DATE,'DY'), 1);
			ELSE
				v_SCHEDULE_DATE := ADD_SECONDS_TO_DATE(TRUNC(v_SCHEDULE_DATE), 1);
			END IF;
		ELSE
			v_DAY_SCHEDULE := FALSE;
			v_SCHEDULE_DATE := ADVANCE_DATE(v_SCHEDULE_DATE, v_INTERVAL);
			v_SCHEDULE_DATE := TO_CUT(v_SCHEDULE_DATE, v_TIME_ZONE);
			v_SCHEDULE_END_DATE := TO_CUT(v_SCHEDULE_END_DATE, v_TIME_ZONE);
		END IF;
	-- Decode the VB template
		v_ANY_DAY := SUBSTR(p_TEMPLATE,1,1) = v_YES;
		v_WEEK_DAY := SUBSTR(p_TEMPLATE,2,1) = v_YES;
		v_WEEK_END := SUBSTR(p_TEMPLATE,3,1) = v_YES;
		v_MON := SUBSTR(p_TEMPLATE,4,1) = v_YES;
		v_TUE := SUBSTR(p_TEMPLATE,5,1) = v_YES;
		v_WED := SUBSTR(p_TEMPLATE,6,1) = v_YES;
		v_THU := SUBSTR(p_TEMPLATE,7,1) = v_YES;
		v_FRI := SUBSTR(p_TEMPLATE,8,1) = v_YES;
		v_SAT := SUBSTR(p_TEMPLATE,9,1) = v_YES;
		v_SUN := SUBSTR(p_TEMPLATE,10,1) = v_YES;
		v_ALL := SUBSTR(p_TEMPLATE,11,1) = v_YES;
		v_ON := SUBSTR(p_TEMPLATE,12,1) = v_YES;
		v_OFF := SUBSTR(p_TEMPLATE,13,1) = v_YES;
		v_DELETE := SUBSTR(p_TEMPLATE,14,1) = v_YES;

		-- initial audit stuff
		IF v_AUDIT_TYPE > 0 THEN
			DECLARE
				v_VALS VARCHAR2(128);
				v_DAYS VARCHAR2(64) := '';
			BEGIN
				v_VALS := TO_CHAR(p_BEGIN_DATE,'YYYY-MM-DD')||' - '||TO_CHAR(p_END_DATE,'YYYY-MM-DD')||', ';
				IF v_ALL THEN
					v_VALS := v_VALS||'All Hours '||p_TIME_ZONE||', ';
				ELSE
					v_VALS := v_VALS||'Intervals '||p_BEGIN_INTERVAL||' to '||p_END_INTERVAL||' '||p_TIME_ZONE||' ';
					IF v_ON THEN
						v_VALS := v_VALS||'On, ';
					ELSE -- v_OFF
						v_VALS := v_VALS||'Off, ';
					END IF;
				END IF;
				IF v_ANY_DAY THEN v_DAYS := v_DAYS||'-Any'; END IF;
				IF v_WEEK_DAY THEN v_DAYS := v_DAYS||'-WD'; END IF;
				IF v_WEEK_END THEN v_DAYS := v_DAYS||'-WE'; END IF;
				IF v_MON THEN v_DAYS := v_DAYS||'-Mon'; END IF;
				IF v_TUE THEN v_DAYS := v_DAYS||'-Tue'; END IF;
				IF v_WED THEN v_DAYS := v_DAYS||'-Wed'; END IF;
				IF v_THU THEN v_DAYS := v_DAYS||'-Thu'; END IF;
				IF v_FRI THEN v_DAYS := v_DAYS||'-Fri'; END IF;
				IF v_SAT THEN v_DAYS := v_DAYS||'-Sat'; END IF;
				IF v_SUN THEN v_DAYS := v_DAYS||'-Sun'; END IF;
				IF p_INCLUDE_HOLIDAYS <> 0 THEN v_DAYS := v_DAYS||'-Hol'; END IF;
				v_VALS := v_VALS||SUBSTR(v_DAYS,2)||', Values: '||p_AMOUNT||', '||p_PRICE;

			END;
		END IF;

	-- Delete any existing records if the option is specified.
		IF v_DELETE AND NVL(p_TO_WORK, 0) = 0 THEN
			DELETE IT_SCHEDULE
			WHERE TRANSACTION_ID = p_TRANSACTION_ID
				AND SCHEDULE_TYPE = p_SCHEDULE_TYPE
				AND SCHEDULE_STATE = GA.INTERNAL_STATE
				AND SCHEDULE_DATE BETWEEN v_SCHEDULE_DATE AND v_SCHEDULE_END_DATE;
		END IF;
		v_COUNT := 0;
	-- Loop over the intervals of the specified time period.
		WHILE v_SCHEDULE_DATE <= v_SCHEDULE_END_DATE LOOP
			v_NEW_AMOUNT := NULL;
			v_NEW_PRICE := NULL;

			IF v_DAY_SCHEDULE THEN
				v_DATE := v_SCHEDULE_DATE;
			ELSE
				v_DATE := FROM_CUT(v_SCHEDULE_DATE, v_TIME_ZONE);
			END IF;

			v_DAY := SUBSTR(TO_CHAR(v_DATE-1/86400, 'DAY'), 1, 3);
			-- Get the interval ranging from 1 to 48
			v_INTV := CEIL((v_DATE-TRUNC(v_DATE))*24*2);
			IF v_INTV = 0 THEN
			   v_INTV := 48;
			END IF;

	-- Determine if the schedule date is a holiday and whether to include.
			v_INCLUDE_DAY := TRUE;
			IF p_INCLUDE_HOLIDAYS = 0 AND IS_HOLIDAY(TRUNC(v_DATE-1/86400), v_EDC_ID) THEN
				v_INCLUDE_DAY := FALSE;
			END IF;

			IF v_DAY_SCHEDULE THEN
				IF v_INTERVAL = 'DAY' THEN
					IF v_INCLUDE_DAY AND (v_ANY_DAY
						OR (v_WEEK_DAY AND v_DAY IN ('MON','TUE','WED','THU','FRI'))
						OR (v_WEEK_END AND v_DAY IN ('SAT','SUN'))
						OR (v_MON AND v_DAY = 'MON')
						OR (v_TUE AND v_DAY = 'TUE')
						OR (v_WED AND v_DAY = 'WED')
						OR (v_THU AND v_DAY = 'THU')
						OR (v_FRI AND v_DAY = 'FRI')
						OR (v_SAT AND v_DAY = 'SAT')
						OR (v_SUN AND v_DAY = 'SUN')) THEN
							v_NEW_AMOUNT := v_AMOUNT;
							v_NEW_PRICE := v_PRICE;
					END IF;
				ELSE
					v_NEW_AMOUNT := v_AMOUNT;
					v_NEW_PRICE := v_PRICE;
				END IF;
			ELSIF v_INCLUDE_DAY AND (v_ANY_DAY
				OR (v_WEEK_DAY AND v_DAY IN ('MON','TUE','WED','THU','FRI'))
				OR (v_WEEK_END AND v_DAY IN ('SAT','SUN'))
				OR (v_MON AND v_DAY = 'MON')
				OR (v_TUE AND v_DAY = 'TUE')
				OR (v_WED AND v_DAY = 'WED')
				OR (v_THU AND v_DAY = 'THU')
				OR (v_FRI AND v_DAY = 'FRI')
				OR (v_SAT AND v_DAY = 'SAT')
				OR (v_SUN AND v_DAY = 'SUN')) THEN
					IF v_ALL
						OR (v_ON AND v_INTV BETWEEN p_BEGIN_INTERVAL AND p_END_INTERVAL)
						OR (v_OFF AND v_INTV NOT BETWEEN p_BEGIN_INTERVAL AND p_END_INTERVAL) THEN
							v_NEW_AMOUNT := v_AMOUNT;
							v_NEW_PRICE := v_PRICE;
					END IF;
			END IF;

	-- Update an existing schedule or insert a new schedule.
			IF NOT (v_NEW_AMOUNT IS NULL AND v_NEW_PRICE IS NULL) THEN
				IF p_TO_WORK = 1 THEN
					PUT_IT_SCHEDULE_TO_WORK(p_WORK_ID, v_COUNT, p_TRANSACTION_ID, v_SCHEDULE_DATE, v_NEW_AMOUNT, v_NEW_PRICE, p_AMOUNT2);
				ELSE
					ITJ.PUT_IT_SCHEDULE(p_TRANSACTION_ID, v_SCHEDULE_TYPE, v_SCHEDULE_DATE, p_AS_OF_DATE, v_NEW_AMOUNT, v_NEW_PRICE, p_STATUS);
				END IF;
			END IF;
			v_SCHEDULE_DATE := ADVANCE_DATE(v_SCHEDULE_DATE, v_INTERVAL);
		END LOOP;

		
		-- update storage schedule if necessary
		IF v_TRANSACTION_TYPE IN ('Injection','Withdrawal') AND v_INTERVAL = 'DAY' THEN
			ITJ.CALC_STORAGE_SCHEDULE(p_BEGIN_DATE, p_SCHEDULE_TYPE, LOW_DATE, v_CONTRACT_ID);
		END IF;

		EXCEPTION
			WHEN OTHERS THEN
				p_STATUS := SQLCODE;

	END SCHEDULE_FILL;
	----------------------------------------------------------------------------------------------------
	PROCEDURE PUT_SCHEDULE_TEMPLATE
		(
		p_TEMPLATE_NAME IN VARCHAR,
		p_START_HOUR_NUM IN NUMBER,
		p_STOP_HOUR_NUM IN NUMBER,
		p_START_INTERVAL_NUM IN NUMBER,
		p_STOP_INTERVAL_NUM IN NUMBER,
		p_MON IN VARCHAR2,
		p_TUE IN VARCHAR2,
		p_WED IN VARCHAR2,
		p_THU IN VARCHAR2,
		p_FRI IN VARCHAR2,
		p_SAT IN VARCHAR2,
		p_SUN IN VARCHAR2,
		p_INTERIOR_PERIOD IN NUMBER,
		p_INCLUDE_HOLIDAYS IN NUMBER,
		p_TEMPLATE_ORDER IN NUMBER,
		p_OLD_TEMPLATE_NAME IN VARCHAR,
		p_STATUS OUT NUMBER
		) AS

	v_START_INTERVAL_END NUMBER(2);
	v_STOP_INTERVAL_END NUMBER(2);
	v_DAY_OF_WEEK VARCHAR2(7);

	BEGIN

		IF NOT CAN_WRITE(ITJ.g_MODULE_NAME) THEN
			RAISE INSUFFICIENT_PRIVILEGES;
		END IF;

		p_STATUS := GA.SUCCESS;

		v_START_INTERVAL_END := (p_START_HOUR_NUM -1)*2+p_START_INTERVAL_NUM;
		v_STOP_INTERVAL_END := (p_STOP_HOUR_NUM -1)*2+p_STOP_INTERVAL_NUM;

		v_DAY_OF_WEEK := NVL(p_MON, '0') ||
						NVL(p_TUE, '0') ||
						NVL(p_WED, '0') ||
						NVL(p_THU, '0') ||
						NVL(p_FRI, '0') ||
						NVL(p_SAT, '0') ||
						NVL(p_SUN, '0');

		-- Try to update an existing record
		UPDATE SEM_SCHEDULE_TEMPLATE SET
			TEMPLATE_NAME = LTRIM(RTRIM(p_TEMPLATE_NAME)),
			START_INTERVAL_END = v_START_INTERVAL_END,
			STOP_INTERVAL_END = v_STOP_INTERVAL_END,
			INTERIOR_PERIOD = NVL(p_INTERIOR_PERIOD,0),
			DAY_OF_WEEK = LTRIM(RTRIM(NVL(v_DAY_OF_WEEK,'0000000'))),
			INCLUDE_HOLIDAYS = NVL(p_INCLUDE_HOLIDAYS,0),
			TEMPLATE_ORDER = NVL(p_TEMPLATE_ORDER,999)
		WHERE TEMPLATE_NAME = LTRIM(RTRIM(p_OLD_TEMPLATE_NAME));

	-- If the previous update did not find a match, then insert a new record.
	IF SQL%NOTFOUND THEN
		INSERT INTO SEM_SCHEDULE_TEMPLATE (
			TEMPLATE_NAME,
			START_INTERVAL_END,
			STOP_INTERVAL_END,
			INTERIOR_PERIOD,
			DAY_OF_WEEK,
			INCLUDE_HOLIDAYS,
			TEMPLATE_ORDER)
		VALUES (
			LTRIM(RTRIM(p_TEMPLATE_NAME)),
			v_START_INTERVAL_END,
			v_STOP_INTERVAL_END,
			NVL(p_INTERIOR_PERIOD,0),
			LTRIM(RTRIM(NVL(v_DAY_OF_WEEK,'0000000'))),
			NVL(p_INCLUDE_HOLIDAYS,0),
			NVL(p_TEMPLATE_ORDER,999));
	END IF;

		EXCEPTION
			WHEN OTHERS THEN
				p_STATUS := SQLCODE;

	END PUT_SCHEDULE_TEMPLATE;
	----------------------------------------------------------------------------------------------------
	PROCEDURE GET_SCHEDULE_TEMPLATES
		(
		p_STATUS OUT NUMBER,
		p_CURSOR IN OUT REF_CURSOR
		) AS
		-- Answer the a list of all the schedule templates and their attributes.
	BEGIN

		p_STATUS := GA.SUCCESS;

		OPEN p_CURSOR FOR
			SELECT TEMPLATE_NAME,
				CEIL(NVL(START_INTERVAL_END, 0)/2) AS START_HOUR_NUM,
				CEIL(NVL(STOP_INTERVAL_END,0)/2) AS STOP_HOUR_NUM,
				START_INTERVAL_END - ((CEIL(NVL(START_INTERVAL_END, 0)/2) - 1)*2) AS START_INTERVAL_NUM,
				STOP_INTERVAL_END - ((CEIL(NVL(STOP_INTERVAL_END, 0)/2) - 1)*2) AS STOP_INTERVAL_NUM,
				SUBSTR(DAY_OF_WEEK,1,1) AS Mon,
				SUBSTR(DAY_OF_WEEK,2,1) AS Tue,
				SUBSTR(DAY_OF_WEEK,3,1) AS Wed,
				SUBSTR(DAY_OF_WEEK,4,1) AS Thu,
				SUBSTR(DAY_OF_WEEK,5,1) AS Fri,
				SUBSTR(DAY_OF_WEEK,6,1) AS Sat,
				SUBSTR(DAY_OF_WEEK,7,1) AS Sun,
				INCLUDE_HOLIDAYS,
				INTERIOR_PERIOD,
				TEMPLATE_ORDER
			FROM SEM_SCHEDULE_TEMPLATE
			ORDER BY TEMPLATE_ORDER, TEMPLATE_NAME;

	EXCEPTION
		WHEN INSUFFICIENT_PRIVILEGES THEN
			p_STATUS := GA.INSUFFICIENT_PRIVILEGES;
		WHEN OTHERS THEN
			p_STATUS := SQLCODE;

	END GET_SCHEDULE_TEMPLATES;
----------------------------------------------------------------------------------------------------
	PROCEDURE DELETE_SCHEDULE_TEMPLATE
	(
		p_TEMPLATE_NAME IN VARCHAR,
		p_STATUS OUT NUMBER
	)
	IS

	BEGIN
		p_STATUS := GA.SUCCESS;

		DELETE FROM SEM_SCHEDULE_TEMPLATE
		WHERE UPPER(TEMPLATE_NAME) = UPPER(p_TEMPLATE_NAME);

	END;
----------------------------------------------------------------------------------------------------
END SEM_CFD_SCHEDULE_FILL;
/
