CREATE OR REPLACE PACKAGE LOSS_FACTOR_UI IS
-- $Revision: 1.4 $

FUNCTION WHAT_VERSION RETURN VARCHAR2;

PROCEDURE GET_DAILY_LOSS_FACTORS
	(
	p_LOSS_FACTOR_ID IN NUMBER_COLLECTION,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_CURSOR OUT GA.REFCURSOR
	);

PROCEDURE PUT_DAILY_LOSS_FACTOR
	(
	p_LOSS_FACTOR_ID IN NUMBER,
	p_OLD_LOSS_FACTOR_ID IN NUMBER,
	p_LOSS_TYPE IN VARCHAR2,
	p_OLD_LOSS_TYPE IN VARCHAR2,
	p_MODEL_BEGIN_DATE IN DATE,
	p_OLD_MODEL_BEGIN_DATE IN DATE,
	p_MODEL_END_DATE IN DATE,
	p_FACTOR_TYPE IN VARCHAR2,
	p_PATTERN_ID IN NUMBER,
	p_VALUE IN NUMBER
	);

PROCEDURE GET_INTERVAL_LOSS_FACTORS
	(
	p_LOSS_FACTOR_ID IN NUMBER_COLLECTION,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_CURSOR OUT GA.REFCURSOR
	);

PROCEDURE SCHEDULE_FILL
	(
	p_PATTERN_ID IN NUMBER,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_TIME_ZONE IN VARCHAR,
	p_FACTOR_VALUE IN VARCHAR2,
	p_TEMPLATE IN VARCHAR,
	p_BEGIN_HOUR IN NUMBER,
	p_END_HOUR IN NUMBER,
	p_INCLUDE_HOLIDAYS IN NUMBER
	);


END LOSS_FACTOR_UI;
/
CREATE OR REPLACE PACKAGE BODY LOSS_FACTOR_UI IS
----------------------------------------------------------------------------------------------------
FUNCTION WHAT_VERSION RETURN VARCHAR2 IS
BEGIN
    RETURN '$Revision: 1.4 $';
END WHAT_VERSION;
---------------------------------------------------------------------------------------------------
PROCEDURE GET_DAILY_LOSS_FACTORS
	(
	p_LOSS_FACTOR_ID NUMBER_COLLECTION,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_CURSOR OUT GA.REFCURSOR
	) AS

	BEGIN

	OPEN p_CURSOR FOR
	SELECT LF.LOSS_FACTOR_ID, MODEL.LOSS_TYPE,
		MODEL.BEGIN_DATE AS MODEL_BEGIN_DATE, MODEL.PATTERN_ID, MODEL.FACTOR_TYPE,
		MODEL.END_DATE AS MODEL_END_DATE, CASE MODEL.FACTOR_TYPE
											WHEN CONSTANTS.LOSS_FACTOR_EXPANSION
											THEN PAT.EXPANSION_VAL
											ELSE PAT.LOSS_VAL
											END AS VALUE
	FROM LOSS_FACTOR LF,
		LOSS_FACTOR_MODEL MODEL,
		LOSS_FACTOR_PATTERN PAT,
		TABLE(CAST(p_LOSS_FACTOR_ID AS NUMBER_COLLECTION)) IDS
	WHERE LF.LOSS_FACTOR_ID = IDS.COLUMN_VALUE
		AND MODEL.LOSS_FACTOR_ID = LF.LOSS_FACTOR_ID
		AND MODEL.BEGIN_DATE <= p_END_DATE
		AND NVL(MODEL.END_DATE, CONSTANTS.HIGH_DATE) >= p_BEGIN_DATE
		AND MODEL.MODEL_TYPE = CONSTANTS.LOSS_FACTOR_MODEL_PATTERN
		AND MODEL.INTERVAL = CONSTANTS.INTERVAL_DAY
		AND PAT.PATTERN_ID (+) = MODEL.PATTERN_ID
	ORDER BY LF.LOSS_FACTOR_ID, MODEL.LOSS_TYPE, MODEL.BEGIN_DATE;

END GET_DAILY_LOSS_FACTORS;
----------------------------------------------------------------------------------------------------
PROCEDURE PUT_DAILY_LOSS_FACTOR
	(
	p_LOSS_FACTOR_ID IN NUMBER,
	p_OLD_LOSS_FACTOR_ID IN NUMBER,
	p_LOSS_TYPE IN VARCHAR2,
	p_OLD_LOSS_TYPE IN VARCHAR2,
	p_MODEL_BEGIN_DATE IN DATE,
	p_OLD_MODEL_BEGIN_DATE IN DATE,
	p_MODEL_END_DATE IN DATE,
	p_FACTOR_TYPE IN VARCHAR2,
	p_PATTERN_ID IN NUMBER,
	p_VALUE IN NUMBER
	) AS

BEGIN

	-- WE DON'T ALLOW USERS TO CHANGE THE LOSS FACTOR TO WHICH A MODEL BELONGS
	-- THEY CAN CLONE A MODEL AND CHANGE THE LOSS FACTOR THAT WAY
	ASSERT(NVL(p_OLD_LOSS_FACTOR_ID, p_LOSS_FACTOR_ID) = p_LOSS_FACTOR_ID,
		'You cannot assign an existing loss factor model to a different loss factor.',
		MSGCODES.c_ERR_ARGUMENT);

	EM.PUT_LOSS_FACTOR_MODEL(p_LOSS_FACTOR_ID, p_LOSS_TYPE, p_OLD_LOSS_TYPE, p_MODEL_BEGIN_DATE,
							p_OLD_MODEL_BEGIN_DATE, p_MODEL_END_DATE, p_FACTOR_TYPE,
							CONSTANTS.LOSS_FACTOR_MODEL_PATTERN,
							CONSTANTS.INTERVAL_DAY, p_PATTERN_ID, p_VALUE);

END PUT_DAILY_LOSS_FACTOR;
----------------------------------------------------------------------------------------------------
PROCEDURE GET_INTERVAL_LOSS_FACTORS
	(
	p_LOSS_FACTOR_ID IN NUMBER_COLLECTION,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_CURSOR OUT GA.REFCURSOR
	) AS

BEGIN
	OPEN p_CURSOR FOR
	SELECT LF.LOSS_FACTOR_ID, MODEL.LOSS_TYPE,
		MODEL.BEGIN_DATE AS MODEL_BEGIN_DATE, MODEL.END_DATE AS MODEL_END_DATE,
		MODEL.PATTERN_ID, MODEL.FACTOR_TYPE, MODEL.MODEL_TYPE, MODEL.INTERVAL
	FROM LOSS_FACTOR LF,
		LOSS_FACTOR_MODEL MODEL,
		TABLE(CAST(p_LOSS_FACTOR_ID AS NUMBER_COLLECTION)) IDS
	WHERE LF.LOSS_FACTOR_ID = IDS.COLUMN_VALUE
		AND MODEL.LOSS_FACTOR_ID = LF.LOSS_FACTOR_ID
		AND MODEL.BEGIN_DATE <= p_END_DATE
		AND NVL(MODEL.END_DATE, CONSTANTS.HIGH_DATE) >= p_BEGIN_DATE
		AND (MODEL.MODEL_TYPE <> CONSTANTS.LOSS_FACTOR_MODEL_PATTERN
			OR MODEL.INTERVAL <> CONSTANTS.INTERVAL_DAY)
	ORDER BY LF.LOSS_FACTOR_ID, MODEL.LOSS_TYPE, MODEL.BEGIN_DATE;

END GET_INTERVAL_LOSS_FACTORS;
----------------------------------------------------------------------------------------------------
PROCEDURE SCHEDULE_FILL
	(
	p_PATTERN_ID IN NUMBER,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_TIME_ZONE IN VARCHAR,
	p_FACTOR_VALUE IN VARCHAR2,
	p_TEMPLATE IN VARCHAR,
	p_BEGIN_HOUR IN NUMBER,
	p_END_HOUR IN NUMBER,
	p_INCLUDE_HOLIDAYS IN NUMBER
	) AS

	v_MODEL_BEGIN DATE;
	v_MODEL_END DATE;
	v_INTERVAL VARCHAR2(32);
	v_MODEL_FACTOR_TYPE VARCHAR2(32);
	v_MODEL_MODEL_TYPE VARCHAR2(32);
	v_FACTOR_ID NUMBER(9);

	v_FACTOR_VAL NUMBER := LTRIM(RTRIM(p_FACTOR_VALUE));

	v_BEGIN_DATE DATE;
	v_END_DATE DATE;

	v_DELETE CHAR := SUBSTR(p_TEMPLATE, 14, 1);

	v_DELETE_BEGIN DATE;
	v_DELETE_END DATE;

BEGIN

	SELECT MODEL.BEGIN_DATE, MODEL.END_DATE, MODEL.INTERVAL, MODEL.FACTOR_TYPE, MODEL.MODEL_TYPE, MODEL.LOSS_FACTOR_ID
	INTO v_MODEL_BEGIN, v_MODEL_END, v_INTERVAL, v_MODEL_FACTOR_TYPE, v_MODEL_MODEL_TYPE, v_FACTOR_ID
	FROM LOSS_FACTOR_MODEL MODEL
	WHERE MODEL.PATTERN_ID = p_PATTERN_ID;

	SD.VERIFY_ENTITY_IS_ALLOWED(SD.g_ACTION_UPDATE_ENT, v_FACTOR_ID, EC.ED_LOSS_FACTOR);

	IF p_BEGIN_DATE > NVL(v_MODEL_END, CONSTANTS.HIGH_DATE) OR p_END_DATE < v_MODEL_BEGIN THEN
		ERRS.RAISE_BAD_ARGUMENT('BEGIN_DATE/END_DATE',p_BEGIN_DATE || '/' || p_END_DATE,
								'The date range specified is invalid for the given loss factor model.');
	END IF;

	v_BEGIN_DATE := GREATEST(v_MODEL_BEGIN, p_BEGIN_DATE);
	v_END_DATE := LEAST(NVL(v_MODEL_END,CONSTANTS.HIGH_DATE), p_END_DATE);

	v_DELETE := SUBSTR(p_TEMPLATE,14,1);

	IF v_DELETE = '1' THEN
		UT.CUT_DATE_RANGE(GA.ELECTRIC_MODEL, v_BEGIN_DATE, v_END_DATE, p_TIME_ZONE,
			v_DELETE_BEGIN, v_DELETE_END);

		DELETE FROM LOSS_FACTOR_PATTERN PAT
		WHERE PAT.PATTERN_ID = p_PATTERN_ID
			AND PAT.PATTERN_DATE BETWEEN v_DELETE_BEGIN AND v_DELETE_END;
	END IF;

	FOR FILL_DATE IN (SELECT * FROM TABLE(CAST(SP.GET_SCHEDULE_DATES(v_BEGIN_DATE,
														v_END_DATE,
														p_TIME_ZONE,
														p_TEMPLATE,
														p_BEGIN_HOUR,
														p_END_HOUR,
														p_INCLUDE_HOLIDAYS,
														v_INTERVAL, 0) AS DATE_COLLECTION)))
	LOOP
		UPDATE LOSS_FACTOR_PATTERN PAT SET
			EXPANSION_VAL = CASE v_MODEL_FACTOR_TYPE
								WHEN CONSTANTS.LOSS_FACTOR_EXPANSION THEN v_FACTOR_VAL
								ELSE NULL END,
			LOSS_VAL = CASE v_MODEL_FACTOR_TYPE
							WHEN CONSTANTS.LOSS_FACTOR_LOSS THEN v_FACTOR_VAL
							ELSE NULL END
		WHERE PAT.PATTERN_ID = p_PATTERN_ID
			AND PAT.PATTERN_DATE = FILL_DATE.COLUMN_VALUE;

		IF SQL%NOTFOUND THEN
			INSERT INTO LOSS_FACTOR_PATTERN(PATTERN_ID, PATTERN_DATE, EXPANSION_VAL, LOSS_VAL)
			VALUES( p_PATTERN_ID, FILL_DATE.COLUMN_VALUE,
					CASE v_MODEL_FACTOR_TYPE
						WHEN CONSTANTS.LOSS_FACTOR_EXPANSION THEN v_FACTOR_VAL
						ELSE NULL END,
					CASE v_MODEL_FACTOR_TYPE
						WHEN CONSTANTS.LOSS_FACTOR_LOSS THEN v_FACTOR_VAL
						ELSE NULL END );
		END IF;
	END LOOP;

END SCHEDULE_FILL;
----------------------------------------------------------------------------------------------------
END LOSS_FACTOR_UI;
/
