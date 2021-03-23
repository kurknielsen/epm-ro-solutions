CREATE OR REPLACE PACKAGE PM AS
--Revision $Revision: 1.30 $

-- PREMISE METER PACKAGE.

FUNCTION WHAT_VERSION RETURN VARCHAR;


PROCEDURE PUT_SERVICE_LOCATION_MRSP
	(
	p_SERVICE_LOCATION_ID IN NUMBER,
	p_MRSP_ID IN NUMBER,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_MRSP_ACCOUNT_NUMBER IN VARCHAR,
	p_METER_READ_CYCLE IN VARCHAR,
	p_OLD_MRSP_ID IN NUMBER,
	p_OLD_BEGIN_DATE IN DATE,
	p_STATUS OUT NUMBER
	);

PROCEDURE PUT_SERVICE_LOCATION_METER
	(
	p_SERVICE_LOCATION_ID IN NUMBER,
	p_METER_ID IN NUMBER,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_IS_ESTIMATED_END_DATE IN NUMBER,
	p_EDC_IDENTIFIER IN VARCHAR,
	p_ESP_IDENTIFIER IN VARCHAR,
	p_NEXT_ACTION_DATE IN DATE,
	p_EDC_RATE_CLASS IN VARCHAR,
	p_OLD_BEGIN_DATE IN DATE,
	p_STATUS OUT NUMBER
	);

PROCEDURE METER_PRODUCTS
	(
	p_METER_ID IN NUMBER,
	p_STATUS OUT NUMBER,
	p_CURSOR IN OUT GA.REFCURSOR
	);

PROCEDURE PUT_METER_PRODUCT
	(
	p_CASE_ID IN NUMBER,
	p_METER_ID IN NUMBER,
	p_PRODUCT_ID IN NUMBER,
	p_PRODUCT_TYPE IN CHAR,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_OLD_CASE_ID IN NUMBER,
	p_OLD_PRODUCT_ID IN NUMBER,
	p_OLD_PRODUCT_TYPE IN CHAR,
	p_OLD_BEGIN_DATE IN DATE,
	p_STATUS OUT NUMBER
	);

PROCEDURE METER_CALENDARS
	(
	p_METER_ID IN NUMBER,
	p_STATUS OUT NUMBER,
	p_CURSOR IN OUT GA.REFCURSOR
	);

PROCEDURE PUT_METER_CALENDAR
	(
	p_CASE_ID IN NUMBER,
	p_METER_ID IN NUMBER,
	p_CALENDAR_ID IN NUMBER,
	p_CALENDAR_TYPE IN VARCHAR,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_OLD_CASE_ID IN NUMBER,
	p_OLD_CALENDAR_ID IN NUMBER,
	p_OLD_CALENDAR_TYPE IN VARCHAR,
	p_OLD_BEGIN_DATE IN DATE,
	p_STATUS OUT NUMBER
	);

PROCEDURE METER_USAGE_FACTORS
	(
	p_METER_ID IN NUMBER,
	p_STATUS OUT NUMBER,
	p_CURSOR IN OUT GA.REFCURSOR
	);

PROCEDURE PUT_METER_USAGE_FACTOR
	(
	p_CASE_ID IN NUMBER,
	p_METER_ID IN NUMBER,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_FACTOR_VAL IN NUMBER,
	p_OLD_CASE_ID IN NUMBER,
	p_OLD_BEGIN_DATE IN DATE,
	p_STATUS OUT NUMBER
	);

PROCEDURE METER_LOSS_FACTORS
	(
	p_METER_ID IN NUMBER,
	p_STATUS OUT NUMBER,
	p_CURSOR IN OUT GA.REFCURSOR
	);

PROCEDURE PUT_METER_LOSS_FACTOR
	(
	p_CASE_ID IN NUMBER,
	p_METER_ID IN NUMBER,
	p_LOSS_FACTOR_ID IN NUMBER,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_OLD_CASE_ID IN NUMBER,
	p_OLD_LOSS_FACTOR_ID IN NUMBER,
	p_OLD_BEGIN_DATE IN DATE,
	p_STATUS OUT NUMBER
	);

PROCEDURE PUT_METER_ANCILLARY_SERVICE
	(
	p_METER_ID IN NUMBER,
	p_ANCILLARY_SERVICE_ID IN NUMBER,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_SERVICE_VAL IN NUMBER,
	p_OLD_ANCILLARY_SERVICE_ID IN NUMBER,
	p_OLD_BEGIN_DATE IN DATE,
	p_STATUS OUT NUMBER
	);

PROCEDURE GET_SERVICE_LOCATION_MRSP_ID
	(
	p_SERVICE_LOCATION_ID IN NUMBER,
	p_MRSP_ID OUT NUMBER
	);

PROCEDURE PUT_METER_SCHEDULE_GROUP
	(
	p_METER_ID IN NUMBER,
	p_SCHEDULE_GROUP_ID IN NUMBER,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_OLD_SCHEDULE_GROUP_ID IN NUMBER,
	p_OLD_BEGIN_DATE IN DATE,
	p_STATUS OUT NUMBER
	);

PROCEDURE METER_GROWTHS
	(
	p_METER_ID IN NUMBER,
	p_STATUS OUT NUMBER,
	p_CURSOR IN OUT GA.REFCURSOR
	);

PROCEDURE PUT_METER_GROWTH
	(
	p_CASE_ID IN NUMBER,
	p_METER_ID IN NUMBER,
	p_PATTERN_ID IN NUMBER,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_GROWTH_PCT IN NUMBER,
	p_OLD_CASE_ID IN NUMBER,
	p_OLD_BEGIN_DATE IN DATE,
	p_STATUS OUT NUMBER
	);

PROCEDURE METER_BILL_CYCLES
	(
	p_METER_ID IN NUMBER,
	p_STATUS OUT NUMBER,
	p_CURSOR IN OUT GA.REFCURSOR
	);

PROCEDURE PUT_METER_BILL_CYCLE
	(
	p_METER_ID IN NUMBER,
	p_BILL_CYCLE_ID IN NUMBER,
	p_BILL_CYCLE_ENTITY IN VARCHAR,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_OLD_BILL_CYCLE_ID IN NUMBER,
	p_OLD_BILL_CYCLE_ENTITY IN VARCHAR,
	p_OLD_BEGIN_DATE IN DATE,
	p_STATUS OUT NUMBER
	);

PROCEDURE METER_BILL_PARTIES
	(
	p_METER_ID IN NUMBER,
	p_STATUS OUT NUMBER,
	p_CURSOR IN OUT GA.REFCURSOR
	);

PROCEDURE PUT_METER_BILL_PARTY
	(
	p_METER_ID IN NUMBER,
	p_BILL_PARTY_ID IN NUMBER,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_OLD_BILL_PARTY_ID IN NUMBER,
	p_OLD_BEGIN_DATE IN DATE,
	p_STATUS OUT NUMBER
	);

g_DOMAIN_NAME VARCHAR(16) := 'Data Setup';

END PM;
/
CREATE OR REPLACE PACKAGE BODY PM AS
---------------------------------------------------------------------------------------------------
FUNCTION WHAT_VERSION RETURN VARCHAR IS
BEGIN
    RETURN '$Revision: 1.30 $';
END WHAT_VERSION;
----------------------------------------------------------------------------------------------------
PROCEDURE PUT_SERVICE_LOCATION_MRSP
	(
	p_SERVICE_LOCATION_ID IN NUMBER,
	p_MRSP_ID IN NUMBER,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_MRSP_ACCOUNT_NUMBER IN VARCHAR,
	p_METER_READ_CYCLE IN VARCHAR,
	p_OLD_MRSP_ID IN NUMBER,
	p_OLD_BEGIN_DATE IN DATE,
	p_STATUS OUT NUMBER
	)
	AS

CURSOR c_SERVICE_LOCATION_MRSP IS
	SELECT *
	FROM SERVICE_LOCATION_MRSP
	WHERE SERVICE_LOCATION_ID = p_SERVICE_LOCATION_ID
		AND MRSP_ID = p_MRSP_ID
	ORDER BY BEGIN_DATE DESC;

v_SERVICE_LOCATION_MRSP SERVICE_LOCATION_MRSP%ROWTYPE;
v_END_DATE DATE;
v_INITIAL BOOLEAN;

BEGIN

	IF NOT CAN_WRITE(g_DOMAIN_NAME) THEN
		ERRS.RAISE_NO_WRITE_MODULE(g_DOMAIN_NAME);
	END IF;

	p_STATUS := GA.SUCCESS;
	v_END_DATE := NULL_DATE(p_END_DATE);

-- UPDATE THE CURRENT SERVICE LOCATION MRSP ASSIGNMENT IF ONE EXISTS

	UPDATE SERVICE_LOCATION_MRSP SET
		BEGIN_DATE = TRUNC(p_BEGIN_DATE),
		END_DATE = TRUNC(v_END_DATE),
		MRSP_ACCOUNT_NUMBER = NVL(p_MRSP_ACCOUNT_NUMBER,GA.UNDEFINED_ATTRIBUTE),
		METER_READ_CYCLE = NVL(p_METER_READ_CYCLE,GA.UNDEFINED_ATTRIBUTE),
		MRSP_ID = p_MRSP_ID,
		ENTRY_DATE = SYSDATE
	WHERE SERVICE_LOCATION_ID = p_SERVICE_LOCATION_ID
		AND MRSP_ID = p_OLD_MRSP_ID
		AND BEGIN_DATE = TRUNC(p_OLD_BEGIN_DATE);

-- NO ASSIGNMENT UPDATE FOR THIS ACCOUNT AND MRSP COMBINATION SO INSERT A NEW ASSIGNMENT

	IF SQL%NOTFOUND THEN
		INSERT INTO SERVICE_LOCATION_MRSP
			(
			SERVICE_LOCATION_ID,
			MRSP_ID,
			BEGIN_DATE,
			END_DATE,
			MRSP_ACCOUNT_NUMBER,
			METER_READ_CYCLE,
			ENTRY_DATE
			)
		VALUES
			(
			p_SERVICE_LOCATION_ID,
			p_MRSP_ID,
			TRUNC(p_BEGIN_DATE),
			TRUNC(v_END_DATE),
			NVL(p_MRSP_ACCOUNT_NUMBER,GA.UNDEFINED_ATTRIBUTE),
			NVL(p_METER_READ_CYCLE,GA.UNDEFINED_ATTRIBUTE),
			SYSDATE
			);
	END IF;

	OPEN c_SERVICE_LOCATION_MRSP;
	v_INITIAL := TRUE;
	LOOP
		FETCH c_SERVICE_LOCATION_MRSP INTO v_SERVICE_LOCATION_MRSP;
		EXIT WHEN c_SERVICE_LOCATION_MRSP%NOTFOUND;
		IF v_INITIAL THEN
			v_END_DATE := v_SERVICE_LOCATION_MRSP.END_DATE;
			v_INITIAL := FALSE;
		END IF;
		UPDATE SERVICE_LOCATION_MRSP
		SET END_DATE = GREATEST(v_END_DATE, v_SERVICE_LOCATION_MRSP.BEGIN_DATE)
		WHERE SERVICE_LOCATION_ID = v_SERVICE_LOCATION_MRSP.SERVICE_LOCATION_ID
			AND MRSP_ID = v_SERVICE_LOCATION_MRSP.MRSP_ID
			AND BEGIN_DATE = v_SERVICE_LOCATION_MRSP.BEGIN_DATE;
		v_END_DATE := v_SERVICE_LOCATION_MRSP.BEGIN_DATE - 1;
	END LOOP;
	CLOSE c_SERVICE_LOCATION_MRSP;


END PUT_SERVICE_LOCATION_MRSP;
----------------------------------------------------------------------------------------------------
PROCEDURE PUT_SERVICE_LOCATION_METER
	(
	p_SERVICE_LOCATION_ID IN NUMBER,
	p_METER_ID IN NUMBER,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_IS_ESTIMATED_END_DATE IN NUMBER,
	p_EDC_IDENTIFIER IN VARCHAR,
	p_ESP_IDENTIFIER IN VARCHAR,
	p_NEXT_ACTION_DATE IN DATE,
	p_EDC_RATE_CLASS IN VARCHAR,
	p_OLD_BEGIN_DATE IN DATE,
	p_STATUS OUT NUMBER
	)
	AS

CURSOR c_SERVICE_LOCATION_METER IS
	SELECT *
	FROM SERVICE_LOCATION_METER
	WHERE SERVICE_LOCATION_ID = p_SERVICE_LOCATION_ID
		AND METER_ID = p_METER_ID
	ORDER BY BEGIN_DATE DESC;

v_SERVICE_LOCATION_METER SERVICE_LOCATION_METER%ROWTYPE;
v_END_DATE DATE;
v_NEXT_ACTION_DATE DATE;
v_INITIAL BOOLEAN;

BEGIN

	IF NOT CAN_WRITE(g_DOMAIN_NAME) THEN
		ERRS.RAISE_NO_WRITE_MODULE(g_DOMAIN_NAME);
	END IF;

	p_STATUS := GA.SUCCESS;
	v_END_DATE := NULL_DATE(p_END_DATE);
	v_NEXT_ACTION_DATE := NULL_DATE(p_NEXT_ACTION_DATE);

-- UPDATE THE CURRENT SERVICE LOCATION AND METER ASSIGNMENT IF ONE EXISTS

	UPDATE SERVICE_LOCATION_METER SET
		BEGIN_DATE = TRUNC(p_BEGIN_DATE),
		END_DATE = TRUNC(v_END_DATE),
		IS_ESTIMATED_END_DATE = NVL(p_IS_ESTIMATED_END_DATE,0),
		EDC_IDENTIFIER = NVL(p_EDC_IDENTIFIER,GA.UNDEFINED_ATTRIBUTE),
		ESP_IDENTIFIER = NVL(p_ESP_IDENTIFIER,GA.UNDEFINED_ATTRIBUTE),
		NEXT_ACTION_DATE = v_NEXT_ACTION_DATE,
		EDC_RATE_CLASS = NVL(p_EDC_RATE_CLASS,GA.UNDEFINED_ATTRIBUTE),
		ENTRY_DATE = SYSDATE
	WHERE SERVICE_LOCATION_ID = p_SERVICE_LOCATION_ID
		AND METER_ID = p_METER_ID
		AND BEGIN_DATE = TRUNC(p_OLD_BEGIN_DATE);

-- NO ASSIGNMENT UPDATE FOR THIS SERVICE LOCATION AND METER COMBINATION SO INSERT A NEW ASSIGNMENT

	IF SQL%NOTFOUND THEN
		INSERT INTO SERVICE_LOCATION_METER (
			SERVICE_LOCATION_ID,
			METER_ID,
			BEGIN_DATE,
			END_DATE,
			IS_ESTIMATED_END_DATE,
			EDC_IDENTIFIER,
			ESP_IDENTIFIER,
			NEXT_ACTION_DATE,
			EDC_RATE_CLASS,
			ENTRY_DATE)
		VALUES (
			p_SERVICE_LOCATION_ID,
			p_METER_ID,
			TRUNC(p_BEGIN_DATE),
			TRUNC(v_END_DATE),
			NVL(p_IS_ESTIMATED_END_DATE,0),
			NVL(p_EDC_IDENTIFIER,GA.UNDEFINED_ATTRIBUTE),
			NVL(p_ESP_IDENTIFIER,GA.UNDEFINED_ATTRIBUTE),
			v_NEXT_ACTION_DATE,
			NVL(p_EDC_RATE_CLASS,GA.UNDEFINED_ATTRIBUTE),
			SYSDATE
			);
	END IF;

	OPEN c_SERVICE_LOCATION_METER;
	v_INITIAL := TRUE;
	LOOP
		FETCH c_SERVICE_LOCATION_METER INTO v_SERVICE_LOCATION_METER;
		EXIT WHEN c_SERVICE_LOCATION_METER%NOTFOUND;
		IF v_INITIAL THEN
			v_END_DATE := v_SERVICE_LOCATION_METER.END_DATE;
			v_INITIAL := FALSE;
		END IF;
		UPDATE SERVICE_LOCATION_METER
		SET END_DATE = GREATEST(v_END_DATE, v_SERVICE_LOCATION_METER.BEGIN_DATE)
		WHERE SERVICE_LOCATION_ID = v_SERVICE_LOCATION_METER.SERVICE_LOCATION_ID
			AND METER_ID = v_SERVICE_LOCATION_METER.METER_ID
			AND BEGIN_DATE = v_SERVICE_LOCATION_METER.BEGIN_DATE;
		v_END_DATE := v_SERVICE_LOCATION_METER.BEGIN_DATE - 1;
	END LOOP;
	CLOSE c_SERVICE_LOCATION_METER;


END PUT_SERVICE_LOCATION_METER;
----------------------------------------------------------------------------------------------------
PROCEDURE METER_PRODUCTS
	(
	p_METER_ID IN NUMBER,
	p_STATUS OUT NUMBER,
	p_CURSOR IN OUT GA.REFCURSOR
	) AS


BEGIN

	IF NOT CAN_READ(g_DOMAIN_NAME) THEN
		ERRS.RAISE_NO_READ_MODULE(g_DOMAIN_NAME);
	END IF;

	p_STATUS := GA.SUCCESS;

   OPEN p_CURSOR FOR
		SELECT B.CASE_NAME,
			 A.CASE_ID,
			 A.BEGIN_DATE,
			 A.END_DATE,
			 A.PRODUCT_TYPE,
			 A.PRODUCT_ID,
			 C.PRODUCT_NAME,
			 A.ENTRY_DATE
		FROM METER_PRODUCT A, CASE_LABEL B, PRODUCT C
		WHERE A.METER_ID = p_METER_ID
			AND B.CASE_ID = A.CASE_ID
			AND C.PRODUCT_ID = A.PRODUCT_ID
		ORDER BY 1;


END METER_PRODUCTS;
---------------------------------------------------------------------------------------------------
PROCEDURE PUT_METER_PRODUCT
	(
	p_CASE_ID IN NUMBER,
	p_METER_ID IN NUMBER,
	p_PRODUCT_ID IN NUMBER,
	p_PRODUCT_TYPE IN CHAR,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_OLD_CASE_ID IN NUMBER,
	p_OLD_PRODUCT_ID IN NUMBER,
	p_OLD_PRODUCT_TYPE IN CHAR,
	p_OLD_BEGIN_DATE IN DATE,
	p_STATUS OUT NUMBER
	)
	AS

CURSOR c_METER_PRODUCT IS
	SELECT *
	FROM METER_PRODUCT
	WHERE METER_ID = p_METER_ID
		AND PRODUCT_ID = p_PRODUCT_ID
		AND PRODUCT_TYPE = p_PRODUCT_TYPE
		AND CASE_ID = p_CASE_ID
	ORDER BY BEGIN_DATE DESC;

v_METER_PRODUCT METER_PRODUCT%ROWTYPE;
v_END_DATE DATE;
v_INITIAL BOOLEAN;

BEGIN

	IF NOT CAN_WRITE(g_DOMAIN_NAME) THEN
		ERRS.RAISE_NO_WRITE_MODULE(g_DOMAIN_NAME);
	END IF;

	p_STATUS := GA.SUCCESS;
	v_END_DATE := NULL_DATE(p_END_DATE);

-- UPDATE THE CURRENT METER PRODUCT ASSIGNMENT IF ONE EXISTS

	UPDATE METER_PRODUCT SET
		CASE_ID = p_CASE_ID,
		BEGIN_DATE = TRUNC(p_BEGIN_DATE),
		END_DATE = TRUNC(v_END_DATE),
		PRODUCT_ID = p_PRODUCT_ID,
		PRODUCT_TYPE = NVL(p_PRODUCT_TYPE,GA.UNDEFINED_ATTRIBUTE),
		ENTRY_DATE = SYSDATE
	WHERE METER_ID = p_METER_ID
		AND CASE_ID = p_OLD_CASE_ID
		AND PRODUCT_ID = p_OLD_PRODUCT_ID
		AND PRODUCT_TYPE = p_OLD_PRODUCT_TYPE
		AND BEGIN_DATE = TRUNC(p_OLD_BEGIN_DATE);

-- NO ASSIGNMENT UPDATE FOR THIS METER AND PRODUCT COMBINATION SO INSERT A NEW ASSIGNMENT

	IF SQL%NOTFOUND THEN
		INSERT INTO METER_PRODUCT
			(
			CASE_ID,
			METER_ID,
			PRODUCT_ID,
			PRODUCT_TYPE,
			BEGIN_DATE,
			END_DATE,
			ENTRY_DATE
			)
		VALUES
			(
			p_CASE_ID,
			p_METER_ID,
			p_PRODUCT_ID,
			NVL(p_PRODUCT_TYPE,GA.UNDEFINED_ATTRIBUTE),
			TRUNC(p_BEGIN_DATE),
			TRUNC(v_END_DATE),
			SYSDATE
			);
	END IF;

	OPEN c_METER_PRODUCT;
	v_INITIAL := TRUE;
	LOOP
		FETCH c_METER_PRODUCT INTO v_METER_PRODUCT;
		EXIT WHEN c_METER_PRODUCT%NOTFOUND;
		IF v_INITIAL THEN
			v_END_DATE := v_METER_PRODUCT.END_DATE;
			v_INITIAL := FALSE;
		END IF;
		UPDATE METER_PRODUCT
		SET END_DATE = GREATEST(v_END_DATE, v_METER_PRODUCT.BEGIN_DATE)
		WHERE METER_ID = v_METER_PRODUCT.METER_ID
			AND PRODUCT_ID = v_METER_PRODUCT.PRODUCT_ID
			AND PRODUCT_TYPE = v_METER_PRODUCT.PRODUCT_TYPE
			AND CASE_ID = v_METER_PRODUCT.CASE_ID
			AND BEGIN_DATE = v_METER_PRODUCT.BEGIN_DATE;
		v_END_DATE := v_METER_PRODUCT.BEGIN_DATE - 1;
	END LOOP;
	CLOSE c_METER_PRODUCT;


END PUT_METER_PRODUCT;
----------------------------------------------------------------------------------------------------
PROCEDURE METER_CALENDARS
	(
	p_METER_ID IN NUMBER,
	p_STATUS OUT NUMBER,
	p_CURSOR IN OUT GA.REFCURSOR
	) AS


BEGIN

	IF NOT CAN_READ(g_DOMAIN_NAME) THEN
		ERRS.RAISE_NO_READ_MODULE(g_DOMAIN_NAME);
	END IF;

	p_STATUS := GA.SUCCESS;

   OPEN p_CURSOR FOR
		SELECT B.CASE_NAME,
			 A.CASE_ID,
			 A.BEGIN_DATE,
			 A.END_DATE,
			 A.CALENDAR_TYPE,
			 A.CALENDAR_ID,
			 C.CALENDAR_NAME,
			 A.ENTRY_DATE
		FROM METER_CALENDAR A, CASE_LABEL B, CALENDAR C
		WHERE A.METER_ID = p_METER_ID
			AND B.CASE_ID = A.CASE_ID
			AND C.CALENDAR_ID = A.CALENDAR_ID
		ORDER BY 1;


END METER_CALENDARS;
---------------------------------------------------------------------------------------------------
-- NOTE: p_OLD_CALENDAR_ID is not used - it remains for possible backwards compatibility with VB code "just in case"
PROCEDURE PUT_METER_CALENDAR
	(
	p_CASE_ID IN NUMBER,
	p_METER_ID IN NUMBER,
	p_CALENDAR_ID IN NUMBER,
	p_CALENDAR_TYPE IN VARCHAR,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_OLD_CASE_ID IN NUMBER,
	p_OLD_CALENDAR_ID IN NUMBER,
	p_OLD_CALENDAR_TYPE IN VARCHAR,
	p_OLD_BEGIN_DATE IN DATE,
	p_STATUS OUT NUMBER
	)
	AS

CURSOR c_METER_CALENDAR IS
	SELECT *
	FROM METER_CALENDAR
	WHERE METER_ID = p_METER_ID
		AND CALENDAR_TYPE = LTRIM(RTRIM(p_CALENDAR_TYPE))
		AND CASE_ID = p_CASE_ID
	ORDER BY BEGIN_DATE DESC;

v_METER_CALENDAR METER_CALENDAR%ROWTYPE;
v_END_DATE DATE;
v_INITIAL BOOLEAN;

BEGIN

	IF NOT CAN_WRITE(g_DOMAIN_NAME) THEN
		ERRS.RAISE_NO_WRITE_MODULE(g_DOMAIN_NAME);
	END IF;

	p_STATUS := GA.SUCCESS;
	v_END_DATE := NULL_DATE(p_END_DATE);

-- UPDATE THE CURRENT METER CALENDAR ASSIGNMENT IF ONE EXISTS

	UPDATE METER_CALENDAR SET
		CASE_ID = p_CASE_ID,
		CALENDAR_ID = p_CALENDAR_ID,
		CALENDAR_TYPE = LTRIM(RTRIM(p_CALENDAR_TYPE)),
		BEGIN_DATE = TRUNC(p_BEGIN_DATE),
		END_DATE = TRUNC(v_END_DATE),
		ENTRY_DATE = SYSDATE
	WHERE METER_ID = p_METER_ID
		AND CASE_ID = p_OLD_CASE_ID
		AND CALENDAR_TYPE = LTRIM(RTRIM(p_OLD_CALENDAR_TYPE))
		AND BEGIN_DATE = TRUNC(p_OLD_BEGIN_DATE);

-- NO ASSIGNMENT UPDATE FOR THIS METER AND CALENDAR COMBINATION SO INSERT A NEW ASSIGNMENT

	IF SQL%NOTFOUND THEN
		INSERT INTO METER_CALENDAR
			(
			CASE_ID,
			METER_ID,
			CALENDAR_ID,
			CALENDAR_TYPE,
			BEGIN_DATE,
			END_DATE,
			ENTRY_DATE
			)
		VALUES
			(
			p_CASE_ID,
			p_METER_ID,
			p_CALENDAR_ID,
			LTRIM(RTRIM(p_CALENDAR_TYPE)),
			TRUNC(p_BEGIN_DATE),
			TRUNC(v_END_DATE),
			SYSDATE
			);
	END IF;

	OPEN c_METER_CALENDAR;
	v_INITIAL := TRUE;
	LOOP
		FETCH c_METER_CALENDAR INTO v_METER_CALENDAR;
		EXIT WHEN c_METER_CALENDAR%NOTFOUND;
		IF v_INITIAL THEN
			v_END_DATE := v_METER_CALENDAR.END_DATE;
			v_INITIAL := FALSE;
		END IF;
		UPDATE METER_CALENDAR
		SET END_DATE = GREATEST(v_END_DATE, v_METER_CALENDAR.BEGIN_DATE)
		WHERE METER_ID = v_METER_CALENDAR.METER_ID
			AND CASE_ID = v_METER_CALENDAR.CASE_ID
			AND CALENDAR_TYPE = v_METER_CALENDAR.CALENDAR_TYPE
			AND BEGIN_DATE = v_METER_CALENDAR.BEGIN_DATE;
		v_END_DATE := v_METER_CALENDAR.BEGIN_DATE - 1;
	END LOOP;
	CLOSE c_METER_CALENDAR;


END PUT_METER_CALENDAR;
----------------------------------------------------------------------------------------------------
PROCEDURE METER_USAGE_FACTORS
	(
	p_METER_ID IN NUMBER,
	p_STATUS OUT NUMBER,
	p_CURSOR IN OUT GA.REFCURSOR
	) AS


BEGIN

	IF NOT CAN_READ(g_DOMAIN_NAME) THEN
		ERRS.RAISE_NO_READ_MODULE(g_DOMAIN_NAME);
	END IF;

	p_STATUS := GA.SUCCESS;

   OPEN p_CURSOR FOR
		SELECT B.CASE_NAME,
			 A.CASE_ID,
			 A.BEGIN_DATE,
			 A.END_DATE,
			 A.FACTOR_VAL,
			 A.ENTRY_DATE
		FROM METER_USAGE_FACTOR A, CASE_LABEL B
		WHERE A.METER_ID = p_METER_ID
			AND B.CASE_ID = A.CASE_ID
		ORDER BY 1;


END METER_USAGE_FACTORS;
---------------------------------------------------------------------------------------------------
PROCEDURE PUT_METER_USAGE_FACTOR
	(
	p_CASE_ID IN NUMBER,
	p_METER_ID IN NUMBER,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_FACTOR_VAL IN NUMBER,
	p_OLD_CASE_ID IN NUMBER,
	p_OLD_BEGIN_DATE IN DATE,
	p_STATUS OUT NUMBER
	)
	AS

CURSOR c_METER_USAGE_FACTOR IS
	SELECT *
	FROM METER_USAGE_FACTOR
	WHERE METER_ID = p_METER_ID
		AND CASE_ID = p_CASE_ID
	ORDER BY BEGIN_DATE DESC;

v_METER_USAGE_FACTOR METER_USAGE_FACTOR%ROWTYPE;
v_END_DATE DATE;
v_INITIAL BOOLEAN;

BEGIN

	IF NOT CAN_WRITE(g_DOMAIN_NAME) THEN
		ERRS.RAISE_NO_WRITE_MODULE(g_DOMAIN_NAME);
	END IF;

	p_STATUS := GA.SUCCESS;
	v_END_DATE := NULL_DATE(p_END_DATE);

-- UPDATE THE CURRENT METER USAGE_FACTOR ASSIGNMENT IF ONE EXISTS

	UPDATE METER_USAGE_FACTOR SET
		CASE_ID = p_CASE_ID,
		FACTOR_VAL = p_FACTOR_VAL,
		BEGIN_DATE = TRUNC(p_BEGIN_DATE),
		END_DATE = TRUNC(v_END_DATE),
		ENTRY_DATE = SYSDATE
	WHERE METER_ID = p_METER_ID
		AND CASE_ID = p_OLD_CASE_ID
		AND BEGIN_DATE = TRUNC(p_OLD_BEGIN_DATE);

-- NO ASSIGNMENT UPDATE FOR THIS METER AND USAGE_FACTOR COMBINATION SO INSERT A NEW ASSIGNMENT

	IF SQL%NOTFOUND THEN
		INSERT INTO METER_USAGE_FACTOR
			(
			CASE_ID,
			METER_ID,
			BEGIN_DATE,
			END_DATE,
			FACTOR_VAL,
			ENTRY_DATE
			)
		VALUES
			(
			p_CASE_ID,
			p_METER_ID,
			TRUNC(p_BEGIN_DATE),
			TRUNC(v_END_DATE),
			p_FACTOR_VAL,
			SYSDATE
			);
	END IF;

	OPEN c_METER_USAGE_FACTOR;
	v_INITIAL := TRUE;
	LOOP
		FETCH c_METER_USAGE_FACTOR INTO v_METER_USAGE_FACTOR;
		EXIT WHEN c_METER_USAGE_FACTOR%NOTFOUND;
		IF v_INITIAL THEN
			v_END_DATE := v_METER_USAGE_FACTOR.END_DATE;
			v_INITIAL := FALSE;
		END IF;
		UPDATE METER_USAGE_FACTOR
		SET END_DATE = GREATEST(v_END_DATE, v_METER_USAGE_FACTOR.BEGIN_DATE)
		WHERE METER_ID = v_METER_USAGE_FACTOR.METER_ID
			AND CASE_ID = v_METER_USAGE_FACTOR.CASE_ID
			AND BEGIN_DATE = v_METER_USAGE_FACTOR.BEGIN_DATE;
		v_END_DATE := v_METER_USAGE_FACTOR.BEGIN_DATE - 1;
	END LOOP;
	CLOSE c_METER_USAGE_FACTOR;


END PUT_METER_USAGE_FACTOR;
----------------------------------------------------------------------------------------------------
PROCEDURE METER_LOSS_FACTORS
	(
	p_METER_ID IN NUMBER,
	p_STATUS OUT NUMBER,
	p_CURSOR IN OUT GA.REFCURSOR
	) AS


BEGIN

	IF NOT CAN_READ(g_DOMAIN_NAME) THEN
		ERRS.RAISE_NO_READ_MODULE(g_DOMAIN_NAME);
	END IF;

	p_STATUS := GA.SUCCESS;

   OPEN p_CURSOR FOR
		SELECT B.CASE_NAME,
			 A.CASE_ID,
			 A.BEGIN_DATE,
			 A.END_DATE,
			 A.LOSS_FACTOR_ID,
			 C.LOSS_FACTOR_NAME,
			 A.ENTRY_DATE
		FROM METER_LOSS_FACTOR A, CASE_LABEL B, LOSS_FACTOR C
		WHERE A.METER_ID = p_METER_ID
			AND B.CASE_ID = A.CASE_ID
			AND C.LOSS_FACTOR_ID = A.LOSS_FACTOR_ID
		ORDER BY 1;


END METER_LOSS_FACTORS;
---------------------------------------------------------------------------------------------------
PROCEDURE PUT_METER_LOSS_FACTOR
	(
	p_CASE_ID IN NUMBER,
	p_METER_ID IN NUMBER,
	p_LOSS_FACTOR_ID IN NUMBER,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_OLD_CASE_ID IN NUMBER,
	p_OLD_LOSS_FACTOR_ID IN NUMBER,
	p_OLD_BEGIN_DATE IN DATE,
	p_STATUS OUT NUMBER
	)
	AS

CURSOR c_METER_LOSS_FACTOR IS
	SELECT *
	FROM METER_LOSS_FACTOR
	WHERE METER_ID = p_METER_ID
		AND CASE_ID = p_CASE_ID
		AND LOSS_FACTOR_ID = p_LOSS_FACTOR_ID
	ORDER BY BEGIN_DATE DESC;

v_METER_LOSS_FACTOR METER_LOSS_FACTOR%ROWTYPE;
v_END_DATE DATE;
v_INITIAL BOOLEAN;

BEGIN

	IF NOT CAN_WRITE(g_DOMAIN_NAME) THEN
		ERRS.RAISE_NO_WRITE_MODULE(g_DOMAIN_NAME);
	END IF;

	p_STATUS := GA.SUCCESS;
	v_END_DATE := NULL_DATE(p_END_DATE);

-- UPDATE THE CURRENT METER LOSS_FACTOR ASSIGNMENT IF ONE EXISTS

	UPDATE METER_LOSS_FACTOR SET
		CASE_ID = p_CASE_ID,
		LOSS_FACTOR_ID = p_LOSS_FACTOR_ID,
		BEGIN_DATE = TRUNC(p_BEGIN_DATE),
		END_DATE = TRUNC(v_END_DATE),
		ENTRY_DATE = SYSDATE
	WHERE METER_ID = p_METER_ID
		AND CASE_ID = p_OLD_CASE_ID
		AND LOSS_FACTOR_ID = p_OLD_LOSS_FACTOR_ID
		AND BEGIN_DATE = TRUNC(p_OLD_BEGIN_DATE);

-- NO ASSIGNMENT UPDATE FOR THIS METER AND LOSS_FACTOR COMBINATION SO INSERT A NEW ASSIGNMENT

	IF SQL%NOTFOUND THEN
		INSERT INTO METER_LOSS_FACTOR
			(
			CASE_ID,
			METER_ID,
			LOSS_FACTOR_ID,
			BEGIN_DATE,
			END_DATE,
			ENTRY_DATE
			)
		VALUES
			(
			p_CASE_ID,
			p_METER_ID,
			p_LOSS_FACTOR_ID,
			TRUNC(p_BEGIN_DATE),
			TRUNC(v_END_DATE),
			SYSDATE
			);
	END IF;

	OPEN c_METER_LOSS_FACTOR;
	v_INITIAL := TRUE;
	LOOP
		FETCH c_METER_LOSS_FACTOR INTO v_METER_LOSS_FACTOR;
		EXIT WHEN c_METER_LOSS_FACTOR%NOTFOUND;
		IF v_INITIAL THEN
			v_END_DATE := v_METER_LOSS_FACTOR.END_DATE;
			v_INITIAL := FALSE;
		END IF;
		UPDATE METER_LOSS_FACTOR
		SET END_DATE = GREATEST(v_END_DATE, v_METER_LOSS_FACTOR.BEGIN_DATE)
		WHERE METER_ID = v_METER_LOSS_FACTOR.METER_ID
			AND CASE_ID = v_METER_LOSS_FACTOR.CASE_ID
			AND LOSS_FACTOR_ID = v_METER_LOSS_FACTOR.LOSS_FACTOR_ID
			AND BEGIN_DATE = v_METER_LOSS_FACTOR.BEGIN_DATE;
		v_END_DATE := v_METER_LOSS_FACTOR.BEGIN_DATE - 1;
	END LOOP;
	CLOSE c_METER_LOSS_FACTOR;


END PUT_METER_LOSS_FACTOR;
---------------------------------------------------------------------------------------------------
PROCEDURE PUT_METER_ANCILLARY_SERVICE
	(
	p_METER_ID IN NUMBER,
	p_ANCILLARY_SERVICE_ID IN NUMBER,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_SERVICE_VAL IN NUMBER,
	p_OLD_ANCILLARY_SERVICE_ID IN NUMBER,
	p_OLD_BEGIN_DATE IN DATE,
	p_STATUS OUT NUMBER
	)
	AS

CURSOR c_METER_ANCILLARY_SERVICE IS
	SELECT *
	FROM METER_ANCILLARY_SERVICE
	WHERE METER_ID = p_METER_ID
		AND ANCILLARY_SERVICE_ID = p_ANCILLARY_SERVICE_ID
	ORDER BY BEGIN_DATE DESC;

v_METER_ANCILLARY_SERVICE METER_ANCILLARY_SERVICE%ROWTYPE;
v_END_DATE DATE;
v_INITIAL BOOLEAN;

BEGIN

	IF NOT CAN_WRITE(g_DOMAIN_NAME) THEN
		ERRS.RAISE_NO_WRITE_MODULE(g_DOMAIN_NAME);
	END IF;

	p_STATUS := GA.SUCCESS;
	v_END_DATE := NULL_DATE(p_END_DATE);

-- UPDATE THE CURRENT METER ANCILLARY_SERVICE ASSIGNMENT IF ONE EXISTS

	UPDATE METER_ANCILLARY_SERVICE SET
		BEGIN_DATE = TRUNC(p_BEGIN_DATE),
		END_DATE = TRUNC(v_END_DATE),
		ANCILLARY_SERVICE_ID = p_ANCILLARY_SERVICE_ID,
		SERVICE_VAL = p_SERVICE_VAL,
		ENTRY_DATE = SYSDATE
	WHERE METER_ID = p_METER_ID
		AND ANCILLARY_SERVICE_ID = p_OLD_ANCILLARY_SERVICE_ID
		AND BEGIN_DATE = TRUNC(p_OLD_BEGIN_DATE);

-- NO ASSIGNMENT UPDATE FOR THIS METER AND ANCILLARY_SERVICE COMBINATION SO INSERT A NEW ASSIGNMENT

	IF SQL%NOTFOUND THEN
		INSERT INTO METER_ANCILLARY_SERVICE
			(
			METER_ID,
			ANCILLARY_SERVICE_ID,
			BEGIN_DATE,
			END_DATE,
			SERVICE_VAL,
			ENTRY_DATE
			)
		VALUES
			(
			p_METER_ID,
			p_ANCILLARY_SERVICE_ID,
			TRUNC(p_BEGIN_DATE),
			TRUNC(v_END_DATE),
			NVL(p_SERVICE_VAL,0),
			SYSDATE
			);
	END IF;

	OPEN c_METER_ANCILLARY_SERVICE;
	v_INITIAL := TRUE;
	LOOP
		FETCH c_METER_ANCILLARY_SERVICE INTO v_METER_ANCILLARY_SERVICE;
		EXIT WHEN c_METER_ANCILLARY_SERVICE%NOTFOUND;
		IF v_INITIAL THEN
			v_END_DATE := v_METER_ANCILLARY_SERVICE.END_DATE;
			v_INITIAL := FALSE;
		END IF;
		UPDATE METER_ANCILLARY_SERVICE
		SET END_DATE = GREATEST(v_END_DATE, v_METER_ANCILLARY_SERVICE.BEGIN_DATE)
		WHERE METER_ID = v_METER_ANCILLARY_SERVICE.METER_ID
			AND ANCILLARY_SERVICE_ID = v_METER_ANCILLARY_SERVICE.ANCILLARY_SERVICE_ID
			AND BEGIN_DATE = v_METER_ANCILLARY_SERVICE.BEGIN_DATE;
		v_END_DATE := v_METER_ANCILLARY_SERVICE.BEGIN_DATE - 1;
	END LOOP;
	CLOSE c_METER_ANCILLARY_SERVICE;

END PUT_METER_ANCILLARY_SERVICE;

---------------------------------------------------------------------------------------------------

PROCEDURE GET_SERVICE_LOCATION_MRSP_ID
	(
	p_SERVICE_LOCATION_ID IN NUMBER,
	p_MRSP_ID OUT NUMBER
	) AS

v_MRSP_ID NUMBER;

BEGIN

	IF NOT CAN_READ(g_DOMAIN_NAME) THEN
		ERRS.RAISE_NO_READ_MODULE(g_DOMAIN_NAME);
	END IF;

	BEGIN
		SELECT MRSP_ID
		INTO v_MRSP_ID
		FROM SERVICE_LOCATION_MRSP
		WHERE (SERVICE_LOCATION_ID = p_SERVICE_LOCATION_ID)
			AND ( (SYSDATE BETWEEN BEGIN_DATE AND END_DATE)
			OR (SYSDATE >= BEGIN_DATE AND NVL(END_DATE,TO_DATE('31-DEC-9999','DD-MON-YYYY')) = TO_DATE('31-DEC-9999','DD-MON-YYYY')));
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			ERRS.LOG_AND_CONTINUE(p_LOG_LEVEL => LOGS.c_LEVEL_DEBUG);
			v_MRSP_ID := 0;
	END;

	p_MRSP_ID := v_MRSP_ID;

END GET_SERVICE_LOCATION_MRSP_ID;
----------------------------------------------------------------------------------------------------
PROCEDURE PUT_METER_SCHEDULE_GROUP
	(
	p_METER_ID IN NUMBER,
	p_SCHEDULE_GROUP_ID IN NUMBER,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_OLD_SCHEDULE_GROUP_ID IN NUMBER,
	p_OLD_BEGIN_DATE IN DATE,
	p_STATUS OUT NUMBER
	)
	AS

CURSOR c_METER_SCHEDULE_GROUP IS
	SELECT *
	FROM METER_SCHEDULE_GROUP
	WHERE METER_ID = p_METER_ID
	ORDER BY BEGIN_DATE DESC;

v_METER_SCHEDULE_GROUP METER_SCHEDULE_GROUP%ROWTYPE;
v_END_DATE DATE;
v_INITIAL BOOLEAN;

BEGIN

	IF NOT CAN_WRITE(g_DOMAIN_NAME) THEN
		ERRS.RAISE_NO_WRITE_MODULE(g_DOMAIN_NAME);
	END IF;

	p_STATUS := GA.SUCCESS;
	v_END_DATE := NULL_DATE(p_END_DATE);

-- UPDATE THE CURRENT METER SCHEDULE_GROUP ASSIGNMENT IF ONE EXISTS

	UPDATE METER_SCHEDULE_GROUP SET
		BEGIN_DATE = TRUNC(p_BEGIN_DATE),
		END_DATE = TRUNC(v_END_DATE),
		SCHEDULE_GROUP_ID = p_SCHEDULE_GROUP_ID,
		ENTRY_DATE = SYSDATE
	WHERE METER_ID = p_METER_ID
		AND SCHEDULE_GROUP_ID = p_OLD_SCHEDULE_GROUP_ID
		AND BEGIN_DATE = TRUNC(p_OLD_BEGIN_DATE);

-- NO ASSIGNMENT UPDATE FOR THIS METER AND SCHEDULE_GROUP COMBINATION SO INSERT A NEW ASSIGNMENT

	IF SQL%NOTFOUND THEN
		INSERT INTO METER_SCHEDULE_GROUP
			(
			METER_ID,
			SCHEDULE_GROUP_ID,
			BEGIN_DATE,
			END_DATE,
			ENTRY_DATE
			)
		VALUES
			(
			p_METER_ID,
			p_SCHEDULE_GROUP_ID,
			TRUNC(p_BEGIN_DATE),
			TRUNC(v_END_DATE),
			SYSDATE
			);
	END IF;

	OPEN c_METER_SCHEDULE_GROUP;
	v_INITIAL := TRUE;
	LOOP
		FETCH c_METER_SCHEDULE_GROUP INTO v_METER_SCHEDULE_GROUP;
		EXIT WHEN c_METER_SCHEDULE_GROUP%NOTFOUND;
		IF v_INITIAL THEN
			v_END_DATE := v_METER_SCHEDULE_GROUP.END_DATE;
			v_INITIAL := FALSE;
		END IF;
		UPDATE METER_SCHEDULE_GROUP
		SET END_DATE = GREATEST(v_END_DATE, v_METER_SCHEDULE_GROUP.BEGIN_DATE)
		WHERE METER_ID = v_METER_SCHEDULE_GROUP.METER_ID
			AND SCHEDULE_GROUP_ID = v_METER_SCHEDULE_GROUP.SCHEDULE_GROUP_ID
			AND BEGIN_DATE = v_METER_SCHEDULE_GROUP.BEGIN_DATE;
		v_END_DATE := v_METER_SCHEDULE_GROUP.BEGIN_DATE - 1;
	END LOOP;
	CLOSE c_METER_SCHEDULE_GROUP;

END PUT_METER_SCHEDULE_GROUP;
----------------------------------------------------------------------------------------------------
PROCEDURE METER_GROWTHS
	(
	p_METER_ID IN NUMBER,
	p_STATUS OUT NUMBER,
	p_CURSOR IN OUT GA.REFCURSOR
	) AS

-- Answer the CASE LABELS for the given CATEGORY

BEGIN

	IF NOT CAN_READ(g_DOMAIN_NAME) THEN
		ERRS.RAISE_NO_READ_MODULE(g_DOMAIN_NAME);
	END IF;

	p_STATUS := GA.SUCCESS;

	OPEN p_CURSOR FOR
	   SELECT B.CASE_NAME, A.CASE_ID, A.BEGIN_DATE, A.END_DATE, C.PATTERN_NAME, A.PATTERN_ID, A.GROWTH_PCT, A.ENTRY_DATE
		FROM METER_GROWTH A, CASE_LABEL B, GROWTH_PATTERN C
		WHERE A.METER_ID = p_METER_ID
			AND B.CASE_ID = A.CASE_ID
			AND C.PATTERN_ID = A.PATTERN_ID
		ORDER BY 1;

END METER_GROWTHS;
---------------------------------------------------------------------------------------------------
PROCEDURE PUT_METER_GROWTH
	(
	p_CASE_ID IN NUMBER,
	p_METER_ID IN NUMBER,
	p_PATTERN_ID IN NUMBER,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_GROWTH_PCT IN NUMBER,
	p_OLD_CASE_ID IN NUMBER,
	p_OLD_BEGIN_DATE IN DATE,
	p_STATUS OUT NUMBER
	)
	AS

CURSOR c_METER_GROWTH IS
	SELECT *
	FROM METER_GROWTH
	WHERE METER_ID = p_METER_ID
			AND CASE_ID = p_CASE_ID
	ORDER BY BEGIN_DATE DESC;

v_METER_GROWTH METER_GROWTH%ROWTYPE;
v_END_DATE DATE;
v_INITIAL BOOLEAN;

BEGIN

	IF NOT CAN_WRITE(g_DOMAIN_NAME) THEN
		ERRS.RAISE_NO_WRITE_MODULE(g_DOMAIN_NAME);
	END IF;

	p_STATUS := GA.SUCCESS;
	v_END_DATE := NULL_DATE(p_END_DATE);

-- UPDATE THE CURRENT METER GROWTH ASSIGNMENT IF ONE EXISTS

	UPDATE METER_GROWTH SET
		BEGIN_DATE = TRUNC(p_BEGIN_DATE),
		END_DATE = TRUNC(v_END_DATE),
		CASE_ID = p_CASE_ID,
		PATTERN_ID = p_PATTERN_ID,
		GROWTH_PCT = p_GROWTH_PCT,
		ENTRY_DATE = SYSDATE
	WHERE METER_ID = p_METER_ID
		AND CASE_ID = p_OLD_CASE_ID
		AND BEGIN_DATE = TRUNC(p_OLD_BEGIN_DATE);

-- NO ASSIGNMENT UPDATE FOR THIS METER AND GROWTH COMBINATION SO INSERT A NEW ASSIGNMENT

	IF SQL%NOTFOUND THEN
		INSERT INTO METER_GROWTH
			(
			CASE_ID,
			METER_ID,
			PATTERN_ID,
			BEGIN_DATE,
			END_DATE,
			GROWTH_PCT,
			ENTRY_DATE
			)
		VALUES
			(
			p_CASE_ID,
			p_METER_ID,
			p_PATTERN_ID,
			TRUNC(p_BEGIN_DATE),
			TRUNC(v_END_DATE),
			NVL(p_GROWTH_PCT,0),
			SYSDATE
			);
	END IF;

	OPEN c_METER_GROWTH;
	v_INITIAL := TRUE;
	LOOP
		FETCH c_METER_GROWTH INTO v_METER_GROWTH;
		EXIT WHEN c_METER_GROWTH%NOTFOUND;
		IF v_INITIAL THEN
			v_END_DATE := v_METER_GROWTH.END_DATE;
			v_INITIAL := FALSE;
		END IF;
		UPDATE METER_GROWTH
		SET END_DATE = GREATEST(v_END_DATE, v_METER_GROWTH.BEGIN_DATE)
		WHERE METER_ID = v_METER_GROWTH.METER_ID
			AND CASE_ID = v_METER_GROWTH.CASE_ID
			AND BEGIN_DATE = v_METER_GROWTH.BEGIN_DATE;
		v_END_DATE := v_METER_GROWTH.BEGIN_DATE - 1;
	END LOOP;
	CLOSE c_METER_GROWTH;

END PUT_METER_GROWTH;
---------------------------------------------------------------------------------------------------
PROCEDURE METER_BILL_CYCLES
	(
	p_METER_ID IN NUMBER,
	p_STATUS OUT NUMBER,
	p_CURSOR IN OUT GA.REFCURSOR
	) AS


BEGIN

	IF NOT CAN_READ(g_DOMAIN_NAME) THEN
		ERRS.RAISE_NO_READ_MODULE(g_DOMAIN_NAME);
	END IF;

	p_STATUS := GA.SUCCESS;

   OPEN p_CURSOR FOR
		SELECT A.BEGIN_DATE,
			 A.END_DATE,
			 A.BILL_CYCLE_ENTITY,
			 A.BILL_CYCLE_ID,
			 C.BILL_CYCLE_NAME,
			 A.ENTRY_DATE
		FROM METER_BILL_CYCLE A, BILL_CYCLE C
		WHERE A.METER_ID = p_METER_ID
			AND C.BILL_CYCLE_ID = A.BILL_CYCLE_ID
		ORDER BY 1;

END METER_BILL_CYCLES;
---------------------------------------------------------------------------------------------------
PROCEDURE PUT_METER_BILL_CYCLE
	(
	p_METER_ID IN NUMBER,
	p_BILL_CYCLE_ID IN NUMBER,
	p_BILL_CYCLE_ENTITY IN VARCHAR,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_OLD_BILL_CYCLE_ID IN NUMBER,
	p_OLD_BILL_CYCLE_ENTITY IN VARCHAR,
	p_OLD_BEGIN_DATE IN DATE,
	p_STATUS OUT NUMBER
	)
	AS

CURSOR c_METER_BILL_CYCLE IS
	SELECT *
	FROM METER_BILL_CYCLE
	WHERE METER_ID = p_METER_ID
		AND BILL_CYCLE_ENTITY = p_BILL_CYCLE_ENTITY
	ORDER BY BEGIN_DATE DESC;

v_METER_BILL_CYCLE METER_BILL_CYCLE%ROWTYPE;
v_END_DATE DATE;
v_INITIAL BOOLEAN;

BEGIN

	IF NOT CAN_WRITE(g_DOMAIN_NAME) THEN
		ERRS.RAISE_NO_WRITE_MODULE(g_DOMAIN_NAME);
	END IF;

	p_STATUS := GA.SUCCESS;
	v_END_DATE := NULL_DATE(p_END_DATE);

-- UPDATE THE CURRENT METER BILL_CYCLE ASSIGNMENT IF ONE EXISTS

	UPDATE METER_BILL_CYCLE SET
		BEGIN_DATE = TRUNC(p_BEGIN_DATE),
		END_DATE = TRUNC(v_END_DATE),
		BILL_CYCLE_ID = p_BILL_CYCLE_ID,
		BILL_CYCLE_ENTITY = NVL(p_BILL_CYCLE_ENTITY,0),
		ENTRY_DATE = SYSDATE
	WHERE METER_ID = p_METER_ID
		AND BILL_CYCLE_ID = p_OLD_BILL_CYCLE_ID
		AND BILL_CYCLE_ENTITY = p_OLD_BILL_CYCLE_ENTITY
		AND BEGIN_DATE = TRUNC(p_OLD_BEGIN_DATE);

-- NO ASSIGNMENT UPDATE FOR THIS METER AND BILL_CYCLE COMBINATION SO INSERT A NEW ASSIGNMENT

	IF SQL%NOTFOUND THEN
		INSERT INTO METER_BILL_CYCLE
			(
			METER_ID,
			BILL_CYCLE_ID,
			BILL_CYCLE_ENTITY,
			BEGIN_DATE,
			END_DATE,
			ENTRY_DATE
			)
		VALUES
			(
			p_METER_ID,
			p_BILL_CYCLE_ID,
			NVL(p_BILL_CYCLE_ENTITY,0),
			TRUNC(p_BEGIN_DATE),
			TRUNC(v_END_DATE),
			SYSDATE
			);
	END IF;

	OPEN c_METER_BILL_CYCLE;
	v_INITIAL := TRUE;
	LOOP
		FETCH c_METER_BILL_CYCLE INTO v_METER_BILL_CYCLE;
		EXIT WHEN c_METER_BILL_CYCLE%NOTFOUND;
		IF v_INITIAL THEN
			v_END_DATE := v_METER_BILL_CYCLE.END_DATE;
			v_INITIAL := FALSE;
		END IF;
		UPDATE METER_BILL_CYCLE
		SET END_DATE = GREATEST(v_END_DATE, v_METER_BILL_CYCLE.BEGIN_DATE)
		WHERE METER_ID = v_METER_BILL_CYCLE.METER_ID
			AND BILL_CYCLE_ID = v_METER_BILL_CYCLE.BILL_CYCLE_ID
			AND BILL_CYCLE_ENTITY = v_METER_BILL_CYCLE.BILL_CYCLE_ENTITY
			AND BEGIN_DATE = v_METER_BILL_CYCLE.BEGIN_DATE;
		v_END_DATE := v_METER_BILL_CYCLE.BEGIN_DATE - 1;
	END LOOP;
	CLOSE c_METER_BILL_CYCLE;

END PUT_METER_BILL_CYCLE;
----------------------------------------------------------------------------------------------------

PROCEDURE METER_BILL_PARTIES
	(
	p_METER_ID IN NUMBER,
	p_STATUS OUT NUMBER,
	p_CURSOR IN OUT GA.REFCURSOR
	) AS


BEGIN

	IF NOT CAN_READ(g_DOMAIN_NAME) THEN
		ERRS.RAISE_NO_READ_MODULE(g_DOMAIN_NAME);
	END IF;

	p_STATUS := GA.SUCCESS;

   OPEN p_CURSOR FOR
		SELECT A.BEGIN_DATE,
			 A.END_DATE,
			 A.BILL_PARTY_ID,
			 C.BILL_PARTY_NAME,
			 A.ENTRY_DATE
		FROM METER_BILL_PARTY A, BILL_PARTY C
		WHERE A.METER_ID = p_METER_ID
			AND C.BILL_PARTY_ID = A.BILL_PARTY_ID
		ORDER BY 1;

END METER_BILL_PARTIES;
---------------------------------------------------------------------------------------------------
PROCEDURE PUT_METER_BILL_PARTY
	(
	p_METER_ID IN NUMBER,
	p_BILL_PARTY_ID IN NUMBER,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_OLD_BILL_PARTY_ID IN NUMBER,
	p_OLD_BEGIN_DATE IN DATE,
	p_STATUS OUT NUMBER
	)
	AS

CURSOR c_METER_BILL_PARTY IS
	SELECT *
	FROM METER_BILL_PARTY
	WHERE METER_ID = p_METER_ID
	ORDER BY BEGIN_DATE DESC;

v_METER_BILL_PARTY METER_BILL_PARTY%ROWTYPE;
v_END_DATE DATE;
v_INITIAL BOOLEAN;

BEGIN

	IF NOT CAN_WRITE(g_DOMAIN_NAME) THEN
		ERRS.RAISE_NO_WRITE_MODULE(g_DOMAIN_NAME);
	END IF;

	p_STATUS := GA.SUCCESS;
	v_END_DATE := NULL_DATE(p_END_DATE);

-- UPDATE THE CURRENT METER BILL_PARTY ASSIGNMENT IF ONE EXISTS

	UPDATE METER_BILL_PARTY SET
		BEGIN_DATE = TRUNC(p_BEGIN_DATE),
		END_DATE = TRUNC(v_END_DATE),
		BILL_PARTY_ID = p_BILL_PARTY_ID,
		ENTRY_DATE = SYSDATE
	WHERE METER_ID = p_METER_ID
		AND BILL_PARTY_ID = p_OLD_BILL_PARTY_ID
		AND BEGIN_DATE = TRUNC(p_OLD_BEGIN_DATE);

-- NO ASSIGNMENT UPDATE FOR THIS METER AND BILL_PARTY COMBINATION SO INSERT A NEW ASSIGNMENT

	IF SQL%NOTFOUND THEN
		INSERT INTO METER_BILL_PARTY
			(
			METER_ID,
			BILL_PARTY_ID,
			BEGIN_DATE,
			END_DATE,
			ENTRY_DATE
			)
		VALUES
			(
			p_METER_ID,
			p_BILL_PARTY_ID,
			TRUNC(p_BEGIN_DATE),
			TRUNC(v_END_DATE),
			SYSDATE
			);
	END IF;

	OPEN c_METER_BILL_PARTY;
	v_INITIAL := TRUE;
	LOOP
		FETCH c_METER_BILL_PARTY INTO v_METER_BILL_PARTY;
		EXIT WHEN c_METER_BILL_PARTY%NOTFOUND;
		IF v_INITIAL THEN
			v_END_DATE := v_METER_BILL_PARTY.END_DATE;
			v_INITIAL := FALSE;
		END IF;
		UPDATE METER_BILL_PARTY
		SET END_DATE = GREATEST(v_END_DATE, v_METER_BILL_PARTY.BEGIN_DATE)
		WHERE METER_ID = v_METER_BILL_PARTY.METER_ID
			AND BILL_PARTY_ID = v_METER_BILL_PARTY.BILL_PARTY_ID
			AND BEGIN_DATE = v_METER_BILL_PARTY.BEGIN_DATE;
		v_END_DATE := v_METER_BILL_PARTY.BEGIN_DATE - 1;
	END LOOP;
	CLOSE c_METER_BILL_PARTY;

END PUT_METER_BILL_PARTY;
----------------------------------------------------------------------------------------------------
END PM;
/
