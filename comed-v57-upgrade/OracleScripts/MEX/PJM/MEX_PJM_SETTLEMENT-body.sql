CREATE OR REPLACE PACKAGE BODY MEX_PJM_SETTLEMENT IS
----------------------------------------------------------------------------------------------------
g_DEBUG_EXCHANGES VARCHAR2(8) := 'FALSE';
g_MARGINAL_LOSS_DATE DATE := DATE '2007-06-01';

----------------------------------------------------------------------------------------------------
FUNCTION WHAT_VERSION RETURN VARCHAR2 IS
BEGIN
    RETURN '$Revision: 1.1 $';
END WHAT_VERSION;
---------------------------------------------------------------------------------------------------
PROCEDURE FILL_MEX_QTY_TABLE
	(
    p_LINE IN VARCHAR,
    p_COLS IN OUT PARSE_UTIL.STRING_TABLE,
	p_TABLE IN OUT MEX_QUANTITY_TABLE,
    p_ERROR_MESSAGE OUT VARCHAR2,
   	p_STATUS OUT NUMBER) AS
BEGIN
	p_STATUS := MEX_UTIL.g_SUCCESS;

    p_TABLE := MEX_QUANTITY_TABLE();

    PARSE_UTIL.PARSE_DELIMITED_STRING(p_LINE,',',p_COLS);

    FOR I IN 2..26 LOOP
    	IF p_COLS.EXISTS(I) THEN
    		p_TABLE.EXTEND();
        	p_TABLE(I-1) := MEX_QUANTITY_TYPE(NULL, NULL, I-1, TO_NUMBER(p_COLS(I)));
		END IF;
    END LOOP;

EXCEPTION
    WHEN OTHERS THEN
      p_STATUS := SQLCODE;
      p_ERROR_MESSAGE := 'Error in MEX_PJM_SETTLEMENT.FILL_MEX_QTY_TABLE: ' || SQLERRM;


END FILL_MEX_QTY_TABLE;
----------------------------------------------------------------------------------------------------
-- These routines will parse a CLOB that contains CSV data for a report, and then return the data in
-- object tables.
----------------------------------------------------------------------------------------------------
PROCEDURE PARSE_MONTHLY_STATEMENT
	(
	p_CSV IN CLOB,
	p_RECORDS OUT MEX_PJM_MONTHLY_STATEMENT_TBL,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) AS
v_LINES PARSE_UTIL.BIG_STRING_TABLE_MP;
v_COLS PARSE_UTIL.STRING_TABLE;
v_IDX BINARY_INTEGER;
v_JDX BINARY_INTEGER;
v_ORG_ID VARCHAR2(8);
v_ORG_NAME VARCHAR2(64);
v_BEGIN_DATE DATE;
v_END_DATE DATE;
v_SEPARATOR NUMBER;
v_IS_CREDIT NUMBER(1);
v_IS_TOTAL NUMBER(1);
v_CHG_OR_CRD_LINE NUMBER(1) := 0;

CHARGES_1 CONSTANT VARCHAR2(80) := 'BALANCING SPOT MARKET ENERGY CHARGES';
CREDITS_1 CONSTANT VARCHAR2(80) := 'BALANCING SPOT MARKET ENERGY CREDITS';
CHARGES_2 CONSTANT VARCHAR2(80) := 'PJM SCHEDULING SYSTEM CONTROL AND DISPATCH SERVICE CHARGES';
CREDITS_2 CONSTANT VARCHAR2(80) := 'TRANSMISSION CONGESTION CREDITS';
CHARGES_3 CONSTANT VARCHAR2(80) := 'ALM DEFICIENCY CHARGES';
CREDITS_3 CONSTANT VARCHAR2(80) := 'TRANSMISSION OWNER SCHEDULING SYSTEM CONTROL AND DISPATCH SERVICE CREDITS';
NOMATCH CONSTANT NUMBER(1) := 0;
CHARGE_LINE CONSTANT NUMBER(1) := 1;
CREDIT_LINE CONSTANT NUMBER(1) := 2;

	-- tri-state function:  0=not a charge or credit line, 1=charge, 2=credit
	FUNCTION GET_LINE_TYPE
	(
	p_LINE VARCHAR2
	) RETURN NUMBER AS
		v_RESULT NUMBER(1) := NOMATCH;
	BEGIN
		IF p_LINE = CHARGES_1 OR
		   p_LINE = CHARGES_2 OR
		   p_LINE = CHARGES_3 THEN
			v_RESULT := CHARGE_LINE;
		ELSIF
		   p_LINE = CREDITS_1 OR
		   p_LINE = CREDITS_2 OR
           p_LINE = CREDITS_3 THEN
		    v_RESULT := CREDIT_LINE;
		END IF;
		RETURN v_RESULT;
	END GET_LINE_TYPE;

BEGIN
  p_STATUS := MEX_UTIL.g_SUCCESS;

	PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_CSV,v_LINES);
	v_IDX := v_LINES.FIRST;
	p_RECORDS := MEX_PJM_MONTHLY_STATEMENT_TBL();
	WHILE v_LINES.EXISTS(v_IDX) LOOP
		PARSE_UTIL.TOKENS_FROM_STRING(v_LINES(v_IDX),',',v_COLS);
		IF v_IDX = 1 THEN
			-- first line contains org ID and name
			v_SEPARATOR := INSTR(v_COLS(2),';');
			v_ORG_ID := SUBSTR(v_COLS(2),1,v_SEPARATOR-1);
			v_ORG_NAME := TRIM(SUBSTR(v_COLS(2),v_SEPARATOR+1));
			-- if name contains comma, then TOKENS_FROM_STRING may have broken
			-- name into other columns - so put it back together
			v_JDX := 3;
			WHILE v_COLS.EXISTS(v_JDX) LOOP
				v_ORG_NAME := v_ORG_NAME||', '||TRIM(v_COLS(v_JDX));
				v_JDX := v_COLS.NEXT(v_JDX);
			END LOOP;
		ELSIF v_IDX = 2 THEN
			-- second line contains from-to dates
			v_BEGIN_DATE := TO_DATE(SUBSTR(v_COLS(2),1,10),'MM/DD/YY');
			v_END_DATE := TO_DATE(SUBSTR(v_COLS(2),LENGTH(v_COLS(2))-9,10),'MM/DD/YY');
		ELSE

			-- remaining lines contain charges or credits
			-- determine if this is the total line and whether or not the amount
			-- for this line represents a credit vs. a charge
			IF UPPER(TRIM(v_COLS(1))) = 'TOTAL NET CHARGE:' THEN
				v_IS_TOTAL := 1;
				v_IS_CREDIT := 0;
			ELSIF UPPER(TRIM(v_COLS(1))) = 'TOTAL NET CREDIT:' THEN
				v_IS_TOTAL := 1;
				v_IS_CREDIT := 1;
			ELSE
                v_IS_TOTAL := 0;
				v_CHG_OR_CRD_LINE := GET_LINE_TYPE(UPPER(TRIM(v_COLS(1))));
				-- when v_CHG_OR_CRD_LINE is NOMATCH, no change
                IF v_CHG_OR_CRD_LINE = CHARGE_LINE THEN
                	v_IS_CREDIT := 0;
                ELSIF v_CHG_OR_CRD_LINE = CREDIT_LINE THEN
                	v_IS_CREDIT := 1;
                END IF;
			END IF;

			p_RECORDS.EXTEND();
			p_RECORDS(p_RECORDS.LAST) := MEX_PJM_MONTHLY_STATEMENT(v_ORG_ID,v_ORG_NAME,
									v_BEGIN_DATE,v_END_DATE,v_COLS(1),TO_NUMBER(v_COLS(2)),
									v_IS_CREDIT,v_IS_TOTAL);
		END IF;
		v_IDX := v_LINES.NEXT(v_IDX);
	END LOOP;

  EXCEPTION
    WHEN OTHERS THEN
      p_STATUS := SQLCODE;
      p_MESSAGE := 'Error in MEX_PJM_SETTLEMENT.PARSE_MONTHLY_STATEMENT: ' || SQLERRM;
END PARSE_MONTHLY_STATEMENT;
----------------------------------------------------------------------------------------------------
PROCEDURE UPDATE_TRAIT_VAL
    (
    p_GEN_ID IN VARCHAR2,
    p_DATE IN DATE,
    p_TRAIT_ID IN NUMBER,
    p_TRAIT_VALUE IN NUMBER,
    p_ORG_NAME IN VARCHAR2,
    p_STATUS OUT NUMBER,
    p_MESSAGE OUT VARCHAR2,
    p_ORG_ID IN VARCHAR2 := '0',
    p_TO_CUT IN BOOLEAN := TRUE,
    p_HOUR IN NUMBER := 0
    ) AS
v_TXN_ID NUMBER(9);
v_CONTRACT_ID NUMBER(9);
v_DATE DATE;
BEGIN

    BEGIN
    SELECT C.CONTRACT_ID INTO v_CONTRACT_ID
    FROM INTERCHANGE_CONTRACT C, PURCHASING_SELLING_ENTITY P
    WHERE UPPER(P.PSE_DESC) = UPPER('PJM: '||TRIM(p_ORG_NAME))
    AND C.BILLING_ENTITY_ID = P.PSE_ID;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
        SELECT C.CONTRACT_ID INTO v_CONTRACT_ID
        FROM INTERCHANGE_CONTRACT C, PURCHASING_SELLING_ENTITY P
        WHERE P.PSE_EXTERNAL_IDENTIFIER = 'PJM-' || p_ORG_ID
        AND C.BILLING_ENTITY_ID = P.PSE_ID;
    END;

    SELECT TRANSACTION_ID INTO v_TXN_ID
    FROM PJM_GEN_TXNS_BY_TYPE P
    WHERE P.PJM_Gen_Id = p_GEN_ID
    AND P.CONTRACT_ID = v_CONTRACT_ID
    AND P.PJM_GEN_TXN_TYPE = 'Unit Data';

    IF p_TO_CUT = TRUE THEN
        v_DATE := TO_CUT(p_DATE,'EDT');
    ELSE
        v_DATE := p_DATE;
    END IF;

    IF p_HOUR > 0 THEN
        v_DATE := v_DATE + p_HOUR/24;
    END IF;

    IF p_HOUR <> -1 THEN
        TG.PUT_IT_TRAIT_SCHEDULE(v_TXN_ID, GA.INTERNAL_STATE, 0, v_DATE, p_TRAIT_ID,
                                1, 1, p_TRAIT_VALUE, CUT_TIME_ZONE);
    ELSE
        FOR H IN 1..24 LOOP
            TG.PUT_IT_TRAIT_SCHEDULE(v_TXN_ID, GA.INTERNAL_STATE, 0, v_DATE + H/24, p_TRAIT_ID,
                                1, 1, p_TRAIT_VALUE, CUT_TIME_ZONE);
        END LOOP;

    END IF;
 EXCEPTION
    WHEN OTHERS THEN
      p_STATUS := SQLCODE;
      p_MESSAGE := 'Error in MEX_PJM_SETTLEMENT.UPDATE_TRAIT_VAL: ' || SQLERRM;
END UPDATE_TRAIT_VAL;
----------------------------------------------------------------------------------------------------
PROCEDURE PARSE_SCHEDULE9_10_SUMMARY
	(
	p_CSV IN CLOB,
	p_RECORDS OUT MEX_PJM_SCHED9_10_SUMMARY_TBL,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) AS
v_LINES PARSE_UTIL.BIG_STRING_TABLE_MP;
v_COLS PARSE_UTIL.STRING_TABLE;
v_IDX BINARY_INTEGER;
v_JDX BINARY_INTEGER;
v_ORG_NAME VARCHAR2(64);
v_MONTH DATE;
v_SEPARATOR NUMBER;
BEGIN
  p_STATUS := MEX_UTIL.g_SUCCESS;

	PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_CSV,v_LINES);
	v_IDX := v_LINES.FIRST;
	p_RECORDS := MEX_PJM_SCHED9_10_SUMMARY_TBL();
    IF v_LINES.LAST = v_IDX THEN RETURN; END IF;
	WHILE v_LINES.EXISTS(v_IDX) LOOP
		PARSE_UTIL.PARSE_DELIMITED_STRING(v_LINES(v_IDX),',',v_COLS);
		IF v_IDX = 1 THEN
			-- first line contains org name
			v_SEPARATOR := INSTR(v_COLS(1),':');
			v_ORG_NAME := TRIM(SUBSTR(v_COLS(1),v_SEPARATOR+1));
			-- if name contains comma, then TOKENS_FROM_STRING may have broken
			-- name into other columns - so put it back together
			v_JDX := 2;
			WHILE v_COLS.EXISTS(v_JDX) LOOP
				v_ORG_NAME := v_ORG_NAME||', '||TRIM(v_COLS(v_JDX));
				v_JDX := v_COLS.NEXT(v_JDX);
			END LOOP;
		ELSIF v_IDX = 2 THEN
			-- second line contains date
			v_SEPARATOR := INSTR(v_COLS(1),':');
			v_MONTH := TO_DATE(TRIM(SUBSTR(v_COLS(1),v_SEPARATOR+1)),'MON YY');
		ELSIF v_IDX = 3 THEN
			-- skip 3rd line - it has column headers for data below
			NULL;
		ELSE
			-- remaining lines contain charge determinant data
			p_RECORDS.EXTEND();
			p_RECORDS(p_RECORDS.LAST) := MEX_PJM_SCHEDULE9_10_SUMMARY(v_ORG_NAME,
									v_MONTH,v_COLS(1),v_COLS(2),
									TO_NUMBER(v_COLS(3)),TO_NUMBER(v_COLS(4)),
									TO_NUMBER(v_COLS(5)));
		END IF;
		v_IDX := v_LINES.NEXT(v_IDX);
	END LOOP;
  EXCEPTION
    WHEN OTHERS THEN
      p_STATUS := SQLCODE;
      p_MESSAGE := 'Error in MEX_PJM_SETTLEMENT.PARSE_SCHEDULE9_10_SUMMARY: ' || SQLERRM;
END PARSE_SCHEDULE9_10_SUMMARY;
----------------------------------------------------------------------------------------------------
PROCEDURE PARSE_NITS_SUMMARY
	(
	p_CSV IN CLOB,
	p_RECORDS OUT MEX_PJM_NITS_SUMMARY_TBL,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) AS
v_LINES PARSE_UTIL.BIG_STRING_TABLE_MP;
v_COLS PARSE_UTIL.STRING_TABLE;
v_IDX BINARY_INTEGER;
BEGIN
  p_STATUS := MEX_UTIL.g_SUCCESS;

	PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_CSV,v_LINES);
	v_IDX := v_LINES.FIRST;
	p_RECORDS := MEX_PJM_NITS_SUMMARY_TBL();
	WHILE v_LINES.EXISTS(v_IDX) LOOP
		--PARSE_UTIL.TOKENS_FROM_STRING(v_LINES(v_IDX),',',v_COLS);
		PARSE_UTIL.PARSE_DELIMITED_STRING(v_LINES(v_IDX),',',v_COLS);
		IF v_IDX = 1 THEN
			-- skip 1st line - it has column headers for data below
			NULL;
		ELSE
			-- remaining lines contain charge determinant data
			p_RECORDS.EXTEND();
			p_RECORDS(p_RECORDS.LAST) := MEX_PJM_NITS_SUMMARY(v_COLS(1),v_COLS(3),
											TO_DATE(v_COLS(2),'MM/DD/YY'),v_COLS(4),
											TO_NUMBER(v_COLS(5)),TO_NUMBER(v_COLS(6)),
											TO_NUMBER(v_COLS(7)),TO_NUMBER(v_COLS(8)),
											TO_NUMBER(v_COLS(9)),TO_NUMBER(v_COLS(10)));
		END IF;
		v_IDX := v_LINES.NEXT(v_IDX);
	END LOOP;
  EXCEPTION
    WHEN OTHERS THEN
      p_STATUS := SQLCODE;
      p_MESSAGE := 'Error in MEX_PJM_SETTLEMENT.PARSE_NITS_SUMMARY: ' || SQLERRM;
END PARSE_NITS_SUMMARY;
----------------------------------------------------------------------------------------------------
PROCEDURE PARSE_EXPANSION_COST_SUMMARY
	(
	p_CSV IN CLOB,
	p_RECORDS OUT MEX_PJM_NITS_SUMMARY_TBL,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) AS
v_LINES PARSE_UTIL.BIG_STRING_TABLE_MP;
v_COLS PARSE_UTIL.STRING_TABLE;
v_IDX BINARY_INTEGER;
BEGIN
  p_STATUS := MEX_UTIL.g_SUCCESS;

	PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_CSV,v_LINES);
	v_IDX := v_LINES.FIRST;
	p_RECORDS := MEX_PJM_NITS_SUMMARY_TBL();
	WHILE v_LINES.EXISTS(v_IDX) LOOP
		--PARSE_UTIL.TOKENS_FROM_STRING(v_LINES(v_IDX),',',v_COLS);
		PARSE_UTIL.PARSE_DELIMITED_STRING(v_LINES(v_IDX),',',v_COLS);
		IF v_IDX = 1 THEN
			-- skip 1st line - it has column headers for data below
			NULL;
		ELSE
			-- remaining lines contain charge determinant data
			p_RECORDS.EXTEND();
			p_RECORDS(p_RECORDS.LAST) := MEX_PJM_NITS_SUMMARY(v_COLS(1),NULL,
											TO_DATE(v_COLS(2),'MM/DD/YYYY'),v_COLS(3),
											TO_NUMBER(v_COLS(4)),TO_NUMBER(v_COLS(5)),
											TO_NUMBER(v_COLS(6)),NULL,NULL,NULL);
		END IF;
		v_IDX := v_LINES.NEXT(v_IDX);
	END LOOP;
  EXCEPTION
    WHEN OTHERS THEN
      p_STATUS := SQLCODE;
      p_MESSAGE := 'Error in MEX_PJM_SETTLEMENT.PARSE_EXPANSION_COST_SUMMARY: ' || SQLERRM;
END PARSE_EXPANSION_COST_SUMMARY;
----------------------------------------------------------------------------------------------------
PROCEDURE PARSE_REACTIVE_SERV_SUMMARY
	(
	p_CSV IN CLOB,
	p_RECORDS OUT MEX_PJM_REACTIVE_SERV_SUMM_TBL,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) AS
v_LINES PARSE_UTIL.BIG_STRING_TABLE_MP;
v_COLS PARSE_UTIL.STRING_TABLE;
v_IDX BINARY_INTEGER;
BEGIN
  p_STATUS := MEX_UTIL.g_SUCCESS;

	PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_CSV,v_LINES);
	v_IDX := v_LINES.FIRST;
	p_RECORDS := MEX_PJM_REACTIVE_SERV_SUMM_TBL();
    IF v_LINES.LAST = v_IDX THEN RETURN; END IF;
	WHILE v_LINES.EXISTS(v_IDX) LOOP
		PARSE_UTIL.PARSE_DELIMITED_STRING(v_LINES(v_IDX),',',v_COLS);
		IF INSTR(v_LINES(v_IDX), 'org_id') > 0 THEN
			-- skip the line if it has column headers for data below
			NULL;
		ELSE
			-- remaining lines contain charge determinant data
			p_RECORDS.EXTEND();
			p_RECORDS(p_RECORDS.LAST) := MEX_PJM_REACTIVE_SERV_SUMMARY(v_COLS(1),
                                                                       v_COLS(2),
											                           TO_DATE(v_COLS(3),'MM/DD/YY'),
                                                                       v_COLS(4),
											                           TO_NUMBER(v_COLS(5)),
                                                                       TO_NUMBER(v_COLS(6)),
											                           TO_NUMBER(v_COLS(7)),
                                                                       TO_NUMBER(v_COLS(8)),
											                           TO_NUMBER(v_COLS(9)));
		END IF;
		v_IDX := v_LINES.NEXT(v_IDX);
	END LOOP;
  EXCEPTION
    WHEN OTHERS THEN
      p_STATUS := SQLCODE;
      p_MESSAGE := 'Error in MEX_PJM_SETTLEMENT.PARSE_REACTIVE_SERV_SUMMARY: ' || SQLERRM;
END PARSE_REACTIVE_SERV_SUMMARY;
----------------------------------------------------------------------------------------------------
PROCEDURE PARSE_OPER_RES_SUMMARY
	(
	p_CSV IN CLOB,
	p_RECORDS OUT MEX_PJM_OPER_RES_SUMMARY_TBL,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) AS
v_LINES PARSE_UTIL.BIG_STRING_TABLE_MP;
v_COLS PARSE_UTIL.STRING_TABLE;
v_IDX BINARY_INTEGER;
BEGIN
  p_STATUS := MEX_UTIL.g_SUCCESS;

	PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_CSV,v_LINES);
	v_IDX := v_LINES.FIRST;
	p_RECORDS := MEX_PJM_OPER_RES_SUMMARY_TBL();
	WHILE v_LINES.EXISTS(v_IDX) LOOP
		PARSE_UTIL.TOKENS_FROM_STRING(v_LINES(v_IDX),',',v_COLS);
		IF v_IDX = 1 THEN
			-- skip 1st line - it has column headers for data below
			NULL;
		ELSE
			-- remaining lines contain charge determinant data
			p_RECORDS.EXTEND();
			p_RECORDS(p_RECORDS.LAST) := MEX_PJM_OPER_RES_SUMMARY(v_COLS(1),
											TO_DATE(v_COLS(2),'MM/DD/YY'),
											TO_NUMBER(v_COLS(3)),TO_NUMBER(v_COLS(4)),
											TO_NUMBER(v_COLS(5)),TO_NUMBER(v_COLS(6)),
											TO_NUMBER(v_COLS(7)),TO_NUMBER(v_COLS(8)),
											TO_NUMBER(v_COLS(9)),TO_NUMBER(v_COLS(10)),
											TO_NUMBER(v_COLS(11)),TO_NUMBER(v_COLS(12)),
											TO_NUMBER(v_COLS(13)), TO_NUMBER(v_COLS(14)));
		END IF;
		v_IDX := v_LINES.NEXT(v_IDX);
	END LOOP;
  EXCEPTION
    WHEN OTHERS THEN
      p_STATUS := SQLCODE;
      p_MESSAGE := 'Error in MEX_PJM_SETTLEMENT.PARSE_OPER_RES_SUMMARY: ' || SQLERRM;
END PARSE_OPER_RES_SUMMARY;
----------------------------------------------------------------------------------------------------
PROCEDURE PARSE_OP_RES_LOST_OPP_COST
    (
    p_CSV IN CLOB,
	p_RECORDS OUT MEX_PJM_OP_RES_LOC_TBL,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
    ) AS
v_LINES PARSE_UTIL.BIG_STRING_TABLE_MP;
v_COLS PARSE_UTIL.STRING_TABLE;
v_IDX BINARY_INTEGER;
BEGIN
    p_STATUS := MEX_UTIL.g_SUCCESS;

	PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_CSV,v_LINES);
	v_IDX := v_LINES.FIRST;
	p_RECORDS := MEX_PJM_OP_RES_LOC_TBL();
    IF v_LINES.LAST = v_IDX THEN RETURN; END IF;
    WHILE v_LINES.EXISTS(v_IDX) LOOP
        PARSE_UTIL.TOKENS_FROM_STRING(v_LINES(v_IDX),',',v_COLS);
		IF v_COLS(1) = 'org_id' THEN
			-- skip column headers
			NULL;
		ELSE
            p_RECORDS.EXTEND();
			p_RECORDS(p_RECORDS.LAST) := MEX_PJM_OP_RES_LOC(v_COLS(1),
                                            v_COLS(2), TO_DATE(v_COLS(3),'MM/DD/YYYY'),
											TO_NUMBER(v_COLS(4)), TO_NUMBER(v_COLS(5)),
                                            v_COLS(6), v_COLS(7), v_COLS(8),
                                            TO_NUMBER(v_COLS(9)), TO_NUMBER(v_COLS(10)),
											TO_NUMBER(v_COLS(11)), TO_NUMBER(v_COLS(12)),
											TO_NUMBER(v_COLS(13)), TO_NUMBER(v_COLS(14)),
											TO_NUMBER(v_COLS(15)), TO_NUMBER(v_COLS(16)),
											TO_NUMBER(v_COLS(17)), TO_NUMBER(v_COLS(18)));
            IF NVL(v_COLS(17), 0) <> 0 THEN
                UPDATE_TRAIT_VAL(v_COLS(6), TO_DATE(v_COLS(3),'MM/DD/YYYY') + TO_NUMBER(v_COLS(4))/24,
                                    MM_PJM_UTIL.g_TG_OUT_MWH_REDUCED, v_COLS(17),
                                    v_COLS(2), p_STATUS, p_MESSAGE, v_COLS(1));
            END IF;

        END IF;
        v_IDX := v_LINES.NEXT(v_IDX);
	END LOOP;

EXCEPTION
    WHEN OTHERS THEN
      p_STATUS := SQLCODE;
      p_MESSAGE := 'Error in MEX_PJM_SETTLEMENT.PARSE_OP_RES_LOST_OPP_COST: ' || SQLERRM;
END PARSE_OP_RES_LOST_OPP_COST;
---------------------------------------------------------------------------------------------------
PROCEDURE PARSE_OPER_RES_GEN_CREDITS
	(
	p_CSV IN CLOB,
	p_RECORDS OUT MEX_PJM_OPRES_GEN_CREDITS_TBL,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) AS
v_LINES PARSE_UTIL.BIG_STRING_TABLE_MP;
v_COLS PARSE_UTIL.STRING_TABLE;
v_COLS1 PARSE_UTIL.STRING_TABLE;
v_COLS2 PARSE_UTIL.STRING_TABLE;
v_COLS3 PARSE_UTIL.STRING_TABLE;
v_IDX BINARY_INTEGER;
v_LENGTH BINARY_INTEGER;
v_END BINARY_INTEGER;
v_DATE DATE;
v_ORG_NAME VARCHAR2(64);
v_UNIT_ID VARCHAR2(16);
--v_SCHED_ID VARCHAR2(32);
TYPE ARRAY IS VARRAY(25) OF NUMBER;
DA_LMP ARRAY;
DA_SCHED_MW ARRAY;
DESIRED_MW ARRAY;
RT_LMP ARRAY;
RT_GEN_MW ARRAY;
PJM_DISPATCH ARRAY;
DA_ENERGY_OFFER ARRAY;
DA_NO_LOAD_COST ARRAY;
DA_STARTUP_COST ARRAY;
RT_MW ARRAY;
RT_ENERGY_OFFER ARRAY;
RT_NO_LD_COST ARRAY;
RT_STARTUP_COST ARRAY;
v_SCHED_ID ARRAY;
v_OPRES_GEN_CREDIT PJM_OPRES_GEN_CREDITS_DETAIL%ROWTYPE;
v_LAST_LINE BINARY_INTEGER;
v_SCHED2 BOOLEAN;
v_SCHED3 BOOLEAN;
v_SCHED1_LINE BINARY_INTEGER;
v_SCHED2_LINE BINARY_INTEGER;
v_SCHED3_LINE BINARY_INTEGER;

BEGIN
    p_STATUS := MEX_UTIL.g_SUCCESS;
    v_LENGTH := LENGTH('Daily Operating Reserves Generator Credits Report for');

	PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_CSV,v_LINES);
	v_IDX := v_LINES.FIRST;
	p_RECORDS := MEX_PJM_OPRES_GEN_CREDITS_TBL();
  IF v_LINES.LAST = v_IDX THEN RETURN; END IF;
	WHILE v_LINES.EXISTS(v_IDX) LOOP

		PARSE_UTIL.TOKENS_FROM_STRING(v_LINES(v_IDX),',',v_COLS);
        IF v_COLS.EXISTS(1) THEN
        CASE
        WHEN SUBSTR(v_LINES(v_IDX),1,v_LENGTH) = 'Daily Operating Reserves Generator Credits Report for' THEN
			--parse the date out of the line of text
            v_END := INSTR(v_LINES(v_IDX), 'Created');
			v_DATE := TO_DATE(SUBSTR(v_LINES(v_IDX),v_LENGTH + 1, v_END - (v_LENGTH + 1)),'MM/DD/YYYY');
        WHEN SUBSTR(v_LINES(v_IDX),1,LENGTH('Participant:')) = 'Participant:' THEN
            v_ORG_NAME := SUBSTR(v_LINES(v_IDX),LENGTH('Participant:') + 2,LENGTH(v_LINES(v_IDX)) - LENGTH('Participant:') + 2);
        WHEN TRIM(v_COLS(1)) = 'Unit ID:' OR TRIM(v_COLS(1)) = 'Schedule ID:' THEN
            IF TRIM(v_COLS(1)) = 'Unit ID:' THEN
                v_UNIT_ID := v_COLS(2);
                v_LAST_LINE := 17;
                p_RECORDS.EXTEND();
			    p_RECORDS(p_RECORDS.LAST) := MEX_PJM_OPRES_GEN_CREDITS(v_DATE, v_ORG_NAME,
                                            v_UNIT_ID,
                                            v_COLS(4),  --UNIT_NAME
                                            TO_NUMBER(v_COLS(6)),  --DA_OFFER
                                            TO_NUMBER(v_COLS(8)),  --DA_VALUE
                                            TO_NUMBER(v_COLS(10)), --DA_CREDIT
											TO_NUMBER(v_COLS(12)), --RT_OFFER
                                            TO_NUMBER(v_COLS(14)), --BAL_VALUE
                                            TO_NUMBER(v_COLS(16)), --REG_REV
                                            TO_NUMBER(v_COLS(18)), --SPIN_REV
                                            TO_NUMBER(v_COLS(20)), --v_REACT_SER_REV
                                            TO_NUMBER(v_COLS(22))); --v_BAL_CREDIT
            ELSE
                v_LAST_LINE := 11;
            END IF;
            --now gather the hourly details to store in the table
            DA_LMP := ARRAY();
            DA_SCHED_MW := ARRAY();
            RT_LMP := ARRAY();
            RT_GEN_MW := ARRAY();
            PJM_DISPATCH := ARRAY();
            DA_ENERGY_OFFER := ARRAY();
            DA_NO_LOAD_COST := ARRAY();
            DA_STARTUP_COST := ARRAY();
            DESIRED_MW := ARRAY();
            RT_MW := ARRAY();
            RT_ENERGY_OFFER := ARRAY();
            RT_NO_LD_COST := ARRAY();
            RT_STARTUP_COST := ARRAY();
            FOR J IN 1..v_LAST_LINE LOOP
                IF J = 1 THEN
                    IF v_LAST_LINE = 17 THEN
                        v_IDX := v_LINES.NEXT(v_IDX);
                    END IF;
                ELSE
                    v_IDX := v_LINES.NEXT(v_IDX);
                END IF;
                PARSE_UTIL.TOKENS_FROM_STRING(v_LINES(v_IDX),',',v_COLS);
                CASE
                WHEN TRIM(v_COLS(1)) = 'Day-ahead LMP' THEN
                    FOR K IN 1..25 LOOP
                        IF K < 25 THEN
                            DA_LMP.EXTEND();
                            DA_LMP(K) := TO_NUMBER(v_COLS(K + 1));
                        --check for hr 25? On Fall Back Day 2006, there was NOT another column
                        --ELSIF v_COLS.EXISTS(K+1) THEN
                            --DA_LMP.EXTEND();
                            --DA_LMP(K) := TO_NUMBER(v_COLS(K + 1));
                        END IF;
                    END LOOP;
                WHEN TRIM(v_COLS(1)) = 'Day-ahead Scheduled MWh' THEN
                    FOR K IN 1..25 LOOP
                        IF K < 25 THEN
                            DA_SCHED_MW.EXTEND();
                            DA_SCHED_MW(K) := TO_NUMBER(v_COLS(K + 1));
                        END IF;
                    END LOOP;
                WHEN TRIM(v_COLS(1)) = 'Real-time LMP' THEN
                    FOR K IN 1..25 LOOP
                        IF K < 25 THEN
                            RT_LMP.EXTEND();
                            RT_LMP(K) := TO_NUMBER(v_COLS(K + 1));
                        END IF;
                    END LOOP;
                WHEN TRIM(v_COLS(1)) = 'Real-time Generation MWh' THEN
                    FOR K IN 1..25 LOOP
                        IF K < 25 THEN
                            RT_GEN_MW.EXTEND();
                            RT_GEN_MW(K) := TO_NUMBER(v_COLS(K + 1));
                        END IF;
                    END LOOP;
                WHEN TRIM(v_COLS(1)) = 'Following PJM Dispatch' THEN
                    FOR K IN 1..25 LOOP
                        IF K < 25 THEN
                            PJM_DISPATCH.EXTEND();
                            PJM_DISPATCH(K) := TO_NUMBER(v_COLS(K + 1));
                        END IF;
                    END LOOP;
                WHEN TRIM(v_COLS(1)) = 'Schedule ID:' THEN
                    IF NOT v_SCHED_ID.EXISTS(1) THEN
                        v_SCHED_ID := ARRAY();
                        v_SCHED_ID.EXTEND();
                        v_SCHED_ID(1) := v_COLS(2);
                        v_SCHED1_LINE := v_IDX;
                        v_SCHED2 := FALSE;
                        v_SCHED3 := FALSE;
                    ELSIF NOT v_SCHED_ID.EXISTS(2) THEN
                        v_SCHED_ID.EXTEND();
                        v_SCHED_ID(2) := v_COLS(2);
                        v_SCHED2 := TRUE;
                        v_SCHED2_LINE := v_IDX;
                    ELSE
                        v_SCHED_ID.EXTEND();
                        v_SCHED_ID(3) := v_COLS(2);
                        v_SCHED3 := TRUE;
                        v_SCHED3_LINE := v_IDX;
                    END IF;
                    --v_SCHED_ID := v_COLS(2);
                WHEN TRIM(v_COLS(1)) = 'Day-ahead Energy Offer' THEN
                    FOR K IN 1..25 LOOP
                        IF K < 25 THEN
                            DA_ENERGY_OFFER.EXTEND();
                            DA_ENERGY_OFFER(K) := NVL(TO_NUMBER(v_COLS(K + 1)),0);
                        END IF;
                    END LOOP;
                WHEN TRIM(v_COLS(1)) = 'Day-ahead No-Load Cost' THEN
                    FOR K IN 1..25 LOOP
                        IF K < 25 THEN
                            DA_NO_LOAD_COST.EXTEND();
                            DA_NO_LOAD_COST(K) := NVL(TO_NUMBER(v_COLS(K + 1)),0);
                        END IF;
                    END LOOP;

                WHEN TRIM(v_COLS(1)) = 'Day-ahead Startup Cost' THEN
                    FOR K IN 1..25 LOOP
                        IF K < 25 THEN
                            DA_STARTUP_COST.EXTEND();
                            DA_STARTUP_COST(K) := NVL(TO_NUMBER(v_COLS(K + 1)),0);
                        END IF;
                    END LOOP;
                 WHEN TRIM(v_COLS(1)) = 'Desired MWh' THEN
                    FOR K IN 1..25 LOOP
                        IF K < 25 THEN
                            DESIRED_MW.EXTEND();
                            DESIRED_MW(K) := NVL(TO_NUMBER(v_COLS(K + 1)),0);
                        END IF;
                    END LOOP;
                WHEN TRIM(v_COLS(1)) = 'Real-time MWh Used' THEN
                    FOR K IN 1..25 LOOP
                        IF K < 25 THEN
                            RT_MW.EXTEND();
                            RT_MW(K) := NVL(TO_NUMBER(v_COLS(K + 1)),0);
                        END IF;
                    END LOOP;
                WHEN TRIM(v_COLS(1)) = 'Real-time Energy Offer' THEN
                    FOR K IN 1..25 LOOP
                        IF K < 25 THEN
                            RT_ENERGY_OFFER.EXTEND();
                            RT_ENERGY_OFFER(K) := NVL(TO_NUMBER(v_COLS(K + 1)),0);
                        END IF;
                    END LOOP;
                WHEN TRIM(v_COLS(1)) = 'Real-time No-Load Cost' THEN
                    FOR K IN 1..25 LOOP
                        IF K < 25 THEN
                            RT_NO_LD_COST.EXTEND;
                            RT_NO_LD_COST(K) := NVL(TO_NUMBER(v_COLS(K + 1)),0);
                        END IF;
                    END LOOP;
                WHEN TRIM(v_COLS(1)) = 'Real-time Startup Cost' THEN
                    FOR K IN 1..25 LOOP
                        IF K < 25 THEN
                            RT_STARTUP_COST.EXTEND();
                            RT_STARTUP_COST(K) := NVL(TO_NUMBER(v_COLS(K + 1)),0);
                        END IF;
                    END LOOP;
                ELSE
                    NULL;
                END CASE;
            END LOOP;

            FOR I IN 1..24 LOOP
                v_OPRES_GEN_CREDIT.Generator_Id := v_UNIT_ID;
                v_OPRES_GEN_CREDIT.Statement_State := GA.EXTERNAL_STATE;
                v_OPRES_GEN_CREDIT.Charge_Date := v_DATE + I/24;
                IF v_SCHED2 = FALSE THEN
                    v_OPRES_GEN_CREDIT.Schedule_Id :=  v_SCHED_ID(1);
                ELSIF v_SCHED3 = FALSE THEN
                    v_OPRES_GEN_CREDIT.Schedule_Id :=  v_SCHED_ID(2);
                ELSE
                    v_OPRES_GEN_CREDIT.Schedule_Id :=  v_SCHED_ID(3);
                END IF;
                IF DA_LMP.EXISTS(I) THEN
                    v_OPRES_GEN_CREDIT.Da_Lmp := DA_LMP(I);
                END IF;
                IF DA_SCHED_MW.EXISTS(I) THEN
                    v_OPRES_GEN_CREDIT.Da_Sched_Mw := DA_SCHED_MW(I);
                END IF;
                IF DA_SCHED_MW.EXISTS(I) THEN
                    v_OPRES_GEN_CREDIT.Da_Value := DA_LMP(I) * DA_SCHED_MW(I);
                END IF;
                v_OPRES_GEN_CREDIT.Da_Energy_Offer := DA_ENERGY_OFFER(I);
                v_OPRES_GEN_CREDIT.Da_No_Load_Cost := DA_NO_LOAD_COST(I);
                v_OPRES_GEN_CREDIT.Da_Startup_Cost := DA_STARTUP_COST(I);
                --IF v_OPRES_GEN_CREDIT.Da_Startup_Cost <> 0 THEN
                    UPDATE_TRAIT_VAL(v_UNIT_ID,v_DATE + I/24, MM_PJM_UTIL.g_TG_OUT_DA_STARTUP_CST_APPLY,
                                    DA_STARTUP_COST(I), v_ORG_NAME, p_STATUS, p_MESSAGE);
                --END IF;

                UPDATE_TRAIT_VAL(v_UNIT_ID,v_DATE + I/24, MM_PJM_UTIL.g_TG_OUT_DA_NOLOAD_CST_APPLY,
                                    DA_NO_LOAD_COST(I), v_ORG_NAME, p_STATUS, p_MESSAGE);

                v_OPRES_GEN_CREDIT.Da_Offer := DA_ENERGY_OFFER(I)+DA_NO_LOAD_COST(I)+DA_STARTUP_COST(I);
                --save desired mw in a trait, not in detail table
                IF DESIRED_MW(I) > 0 THEN
                    UPDATE_TRAIT_VAL(v_UNIT_ID,v_DATE + I/24, MM_PJM_UTIL.g_TG_OUT_DESIRED_MWH,
                                    DESIRED_MW(I), v_ORG_NAME, p_STATUS, p_MESSAGE);
                END IF;
                --save Following PJM Dispatch trait value
                IF PJM_DISPATCH.EXISTS(I) THEN
                    UPDATE_TRAIT_VAL(v_UNIT_ID, v_DATE + I/24, MM_PJM_UTIL.g_TG_OUT_FOLLOW_PJM_DISPATCH,
                                    NVL(PJM_DISPATCH(I),0), v_ORG_NAME, p_STATUS, p_MESSAGE);
                END IF;
                IF RT_LMP.EXISTS(I) THEN
                    v_OPRES_GEN_CREDIT.Rt_Lmp := RT_LMP(I);
                END IF;
                IF RT_MW.EXISTS(I) THEN
                    v_OPRES_GEN_CREDIT.Rt_Mw := RT_MW(I);
                END IF;
                IF RT_LMP.EXISTS(I) THEN
                    v_OPRES_GEN_CREDIT.Bal_Energ_Mkt_Val := (RT_MW(I) - DA_SCHED_MW(I)) * RT_LMP(I);
                END IF;
                v_OPRES_GEN_CREDIT.Rt_Energ_Offer := RT_ENERGY_OFFER(I);
                v_OPRES_GEN_CREDIT.Rt_No_Load_Cost := RT_NO_LD_COST(I);
                v_OPRES_GEN_CREDIT.Rt_Startup_Cost := RT_STARTUP_COST(I);
                --IF v_OPRES_GEN_CREDIT.Rt_Startup_Cost <> 0 THEN
                    UPDATE_TRAIT_VAL(v_UNIT_ID,v_DATE + I/24, MM_PJM_UTIL.g_TG_OUT_RT_STARTUP_CST_APPLY,
                                    RT_STARTUP_COST(I), v_ORG_NAME, p_STATUS, p_MESSAGE);
                --END IF;
                --IF v_OPRES_GEN_CREDIT.Rt_No_Load_Cost <> 0 THEN
                    UPDATE_TRAIT_VAL(v_UNIT_ID,v_DATE + I/24, MM_PJM_UTIL.g_TG_OUT_RT_NOLOAD_CST_APPLY,
                                    RT_NO_LD_COST(I), v_ORG_NAME, p_STATUS, p_MESSAGE);
                --END IF;
                v_OPRES_GEN_CREDIT.Rt_Offer := RT_ENERGY_OFFER(I)+RT_NO_LD_COST(I)+RT_STARTUP_COST(I);

                BEGIN
                    DELETE FROM PJM_OPRES_GEN_CREDITS_DETAIL
                    WHERE GENERATOR_ID = v_UNIT_ID
                    AND SCHEDULE_ID = v_OPRES_GEN_CREDIT.Schedule_Id
                    AND CHARGE_DATE = v_DATE + I/24
                    AND STATEMENT_STATE = GA.EXTERNAL_STATE;
                EXCEPTION
                    WHEN NO_DATA_FOUND THEN
                    NULL;
                END;

                INSERT INTO PJM_OPRES_GEN_CREDITS_DETAIL VALUES v_OPRES_GEN_CREDIT;


            END LOOP;
            --save schedule_id in a trait
            IF v_LINES.EXISTS(v_IDX + 2) THEN
                IF SUBSTR(v_LINES(v_IDX + 2),1,8) = 'Unit ID:' THEN
                    IF v_SCHED3 = FALSE AND v_SCHED2 = FALSE THEN
                        --only 1 active schedule for the day
                        UPDATE_TRAIT_VAL(v_UNIT_ID,v_DATE, MM_PJM_UTIL.g_TG_OUT_SCHEDULE_ID,
                               v_SCHED_ID(1), v_ORG_NAME, p_STATUS, p_MESSAGE, 0, FALSE, -1);
                    ELSIF v_SCHED3 = FALSE THEN
                        --2 active schedules for the day
                        FOR H IN 1..24 LOOP
                            PARSE_UTIL.TOKENS_FROM_STRING(v_LINES(v_SCHED1_LINE+8),',',v_COLS1);
                            PARSE_UTIL.TOKENS_FROM_STRING(v_LINES(v_SCHED2_LINE+8),',',v_COLS2);
                            IF NVL(v_COLS2(H+1),0) > 0 THEN
                                UPDATE_TRAIT_VAL(v_UNIT_ID,v_DATE, MM_PJM_UTIL.g_TG_OUT_SCHEDULE_ID,
                                 v_SCHED_ID(2), v_ORG_NAME, p_STATUS, p_MESSAGE, 0, FALSE, H);  --SEND I FOR HOUR
                            ELSE
                                 UPDATE_TRAIT_VAL(v_UNIT_ID,v_DATE, MM_PJM_UTIL.g_TG_OUT_SCHEDULE_ID,
                                 v_SCHED_ID(1), v_ORG_NAME, p_STATUS, p_MESSAGE, 0, FALSE, H);  --SEND I FOR HOUR
                            END IF;
                        END LOOP;

                    ELSE
                        --3 active schedules for the day
                        FOR H IN 1..24 LOOP
                            PARSE_UTIL.TOKENS_FROM_STRING(v_LINES(v_SCHED1_LINE+8),',',v_COLS1);
                            PARSE_UTIL.TOKENS_FROM_STRING(v_LINES(v_SCHED2_LINE+8),',',v_COLS2);
                            PARSE_UTIL.TOKENS_FROM_STRING(v_LINES(v_SCHED3_LINE+8),',',v_COLS3);
                            IF NVL(v_COLS3(H+1),0) > 0 THEN
                                UPDATE_TRAIT_VAL(v_UNIT_ID,v_DATE, MM_PJM_UTIL.g_TG_OUT_SCHEDULE_ID,
                                 v_SCHED_ID(3), v_ORG_NAME, p_STATUS, p_MESSAGE, 0, FALSE, H);  --SEND I FOR HOUR
                            ELSIF NVL(v_COLS2(H+1),0) > 0 THEN
                                UPDATE_TRAIT_VAL(v_UNIT_ID,v_DATE, MM_PJM_UTIL.g_TG_OUT_SCHEDULE_ID,
                                 v_SCHED_ID(2), v_ORG_NAME, p_STATUS, p_MESSAGE, 0, FALSE, H);  --SEND I FOR HOUR
                            ELSE
                                 UPDATE_TRAIT_VAL(v_UNIT_ID,v_DATE, MM_PJM_UTIL.g_TG_OUT_SCHEDULE_ID,
                                 v_SCHED_ID(1), v_ORG_NAME, p_STATUS, p_MESSAGE, 0, FALSE, H);  --SEND I FOR HOUR
                            END IF;
                        END LOOP;
                    END IF;
                    v_SCHED_ID := ARRAY();
                END IF;
            END IF;
		ELSE
		    NULL;
		END CASE;

        END IF;
		v_IDX := v_LINES.NEXT(v_IDX);
	END LOOP;
    --put active schedule(s) for last generator in report
    IF v_SCHED3 = FALSE AND v_SCHED2 = FALSE THEN
        --only 1 active schedule for the day
        UPDATE_TRAIT_VAL(v_UNIT_ID,v_DATE, MM_PJM_UTIL.g_TG_OUT_SCHEDULE_ID,
               v_SCHED_ID(1), v_ORG_NAME, p_STATUS, p_MESSAGE, 0, FALSE, -1);
    ELSIF v_SCHED3 = FALSE THEN
        --2 active schedules for the day
        FOR H IN 1..24 LOOP
            PARSE_UTIL.TOKENS_FROM_STRING(v_LINES(v_SCHED1_LINE+8),',',v_COLS1);
            PARSE_UTIL.TOKENS_FROM_STRING(v_LINES(v_SCHED2_LINE+8),',',v_COLS2);
            IF NVL(v_COLS2(H+1),0) > 0 THEN
                UPDATE_TRAIT_VAL(v_UNIT_ID,v_DATE, MM_PJM_UTIL.g_TG_OUT_SCHEDULE_ID,
                 v_SCHED_ID(2), v_ORG_NAME, p_STATUS, p_MESSAGE, 0, FALSE, H);  --SEND I FOR HOUR
            ELSE
                 UPDATE_TRAIT_VAL(v_UNIT_ID,v_DATE, MM_PJM_UTIL.g_TG_OUT_SCHEDULE_ID,
                 v_SCHED_ID(1), v_ORG_NAME, p_STATUS, p_MESSAGE, 0, FALSE, H);  --SEND I FOR HOUR
            END IF;
        END LOOP;

    ELSE
        --3 active schedules for the day
        FOR H IN 1..24 LOOP
            PARSE_UTIL.TOKENS_FROM_STRING(v_LINES(v_SCHED1_LINE+8),',',v_COLS1);
            PARSE_UTIL.TOKENS_FROM_STRING(v_LINES(v_SCHED2_LINE+8),',',v_COLS2);
            PARSE_UTIL.TOKENS_FROM_STRING(v_LINES(v_SCHED3_LINE+8),',',v_COLS3);
            IF NVL(v_COLS3(H+1),0) > 0 THEN
                UPDATE_TRAIT_VAL(v_UNIT_ID,v_DATE, MM_PJM_UTIL.g_TG_OUT_SCHEDULE_ID,
                 v_SCHED_ID(3), v_ORG_NAME, p_STATUS, p_MESSAGE, 0, FALSE, H);  --SEND I FOR HOUR
            ELSIF NVL(v_COLS2(H+1),0) > 0 THEN
                UPDATE_TRAIT_VAL(v_UNIT_ID,v_DATE, MM_PJM_UTIL.g_TG_OUT_SCHEDULE_ID,
                 v_SCHED_ID(2), v_ORG_NAME, p_STATUS, p_MESSAGE, 0, FALSE, H);  --SEND I FOR HOUR
            ELSE
                 UPDATE_TRAIT_VAL(v_UNIT_ID,v_DATE, MM_PJM_UTIL.g_TG_OUT_SCHEDULE_ID,
                 v_SCHED_ID(1), v_ORG_NAME, p_STATUS, p_MESSAGE, 0, FALSE, H);  --SEND I FOR HOUR
            END IF;
        END LOOP;
    END IF;

    COMMIT;
  EXCEPTION
    WHEN OTHERS THEN
      p_STATUS := SQLCODE;
      p_MESSAGE := 'Error in MEX_PJM_SETTLEMENT.PARSE_OPER_RES_SUMMARY: ' || SQLERRM;
END PARSE_OPER_RES_GEN_CREDITS;
----------------------------------------------------------------------------------------------------
PROCEDURE PARSE_LOSSES_CHARGES
	(
	p_CSV IN CLOB,
	p_RECORDS OUT MEX_PJM_LOSSES_CHARGES_TBL,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) AS
v_LINES PARSE_UTIL.BIG_STRING_TABLE_MP;
v_COLS PARSE_UTIL.STRING_TABLE;
v_IDX BINARY_INTEGER;
BEGIN
  p_STATUS := MEX_UTIL.g_SUCCESS;

	PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_CSV,v_LINES);
	v_IDX := v_LINES.FIRST;
	p_RECORDS := MEX_PJM_LOSSES_CHARGES_TBL();
	WHILE v_LINES.EXISTS(v_IDX) LOOP
		PARSE_UTIL.TOKENS_FROM_STRING(v_LINES(v_IDX),',',v_COLS);
		IF v_IDX = 1 THEN
			-- skip 1st line - it has column headers for data below
			NULL;
		ELSE
			-- remaining lines contain charge determinant data
			p_RECORDS.EXTEND();
			p_RECORDS(p_RECORDS.LAST) := MEX_PJM_LOSSES_CHARGES(v_COLS(1),
											TO_DATE(v_COLS(2),'MM/DD/YY'),
											TO_NUMBER(v_COLS(3)),TO_NUMBER(v_COLS(4)),
											TO_NUMBER(v_COLS(5)),TO_NUMBER(v_COLS(6)),
											TO_NUMBER(v_COLS(7)),TO_NUMBER(v_COLS(8)),
											TO_NUMBER(v_COLS(9)),TO_NUMBER(v_COLS(10)));
		END IF;
		v_IDX := v_LINES.NEXT(v_IDX);
	END LOOP;
  EXCEPTION
    WHEN OTHERS THEN
      p_STATUS := SQLCODE;
      p_MESSAGE := 'Error in MEX_PJM_SETTLEMENT.PARSE_LOSSES_CHARGES: ' || SQLERRM;
END PARSE_LOSSES_CHARGES;
----------------------------------------------------------------------------------------------------
PROCEDURE PARSE_LOSSES_CREDITS
	(
	p_CSV IN CLOB,
	p_RECORDS OUT MEX_PJM_LOSSES_CREDITS_TBL,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) AS
v_LINES PARSE_UTIL.BIG_STRING_TABLE_MP;
v_COLS PARSE_UTIL.STRING_TABLE;
v_IDX BINARY_INTEGER;
BEGIN
  p_STATUS := MEX_UTIL.g_SUCCESS;

	PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_CSV,v_LINES);
	v_IDX := v_LINES.FIRST;
	p_RECORDS := MEX_PJM_LOSSES_CREDITS_TBL();
	WHILE v_LINES.EXISTS(v_IDX) LOOP
		PARSE_UTIL.TOKENS_FROM_STRING(v_LINES(v_IDX),',',v_COLS);
		IF v_IDX = 1 THEN
			-- skip 1st line - it has column headers for data below
			NULL;
		ELSE
			-- remaining lines contain charge determinant data
			p_RECORDS.EXTEND();
			p_RECORDS(p_RECORDS.LAST) := MEX_PJM_LOSSES_CREDITS(v_COLS(1),
											TO_DATE(v_COLS(2),'MM/DD/YY'),
											TO_NUMBER(v_COLS(3)),TO_NUMBER(v_COLS(4)),
											TO_NUMBER(v_COLS(5)),TO_NUMBER(v_COLS(6)),
											TO_NUMBER(v_COLS(7)),TO_NUMBER(v_COLS(8)),
											TO_NUMBER(v_COLS(9)),TO_NUMBER(v_COLS(10)),
											TO_NUMBER(v_COLS(11)),TO_NUMBER(v_COLS(12)));
		END IF;
		v_IDX := v_LINES.NEXT(v_IDX);
	END LOOP;
  EXCEPTION
    WHEN OTHERS THEN
      p_STATUS := SQLCODE;
      p_MESSAGE := 'Error in MEX_PJM_SETTLEMENT.PARSE_LOSSES_CREDITS: ' || SQLERRM;
END PARSE_LOSSES_CREDITS;
----------------------------------------------------------------------------------------------------
PROCEDURE PARSE_TRANS_REVNEUT_CHARGES
	(
	p_CSV IN CLOB,
	p_RECORDS OUT MEX_PJM_TRANS_REVNEUT_CHG_TBL,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) AS
v_LINES PARSE_UTIL.BIG_STRING_TABLE_MP;
v_COLS PARSE_UTIL.STRING_TABLE;
v_IDX BINARY_INTEGER;
v_JDX BINARY_INTEGER;
v_ORG_NAME VARCHAR2(64);
v_MONTH DATE;
v_SEPARATOR NUMBER;
BEGIN
	p_STATUS := MEX_UTIL.g_SUCCESS;
	p_RECORDS := MEX_PJM_TRANS_REVNEUT_CHG_TBL();

	PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_CSV,v_LINES);
    IF v_LINES.COUNT > 1 THEN
	v_IDX := v_LINES.FIRST;

	WHILE v_LINES.EXISTS(v_IDX) LOOP
		PARSE_UTIL.TOKENS_FROM_STRING(v_LINES(v_IDX),',',v_COLS);
		IF v_IDX = 1 THEN
			-- first line contains org name
			v_SEPARATOR := INSTR(v_COLS(1),':');
			v_ORG_NAME := TRIM(SUBSTR(v_COLS(1),v_SEPARATOR+1));
			-- if name contains comma, then TOKENS_FROM_STRING may have broken
			-- name into other columns - so put it back together
			v_JDX := 2;
			WHILE v_COLS.EXISTS(v_JDX) LOOP
				v_ORG_NAME := v_ORG_NAME||', '||TRIM(v_COLS(v_JDX));
				v_JDX := v_COLS.NEXT(v_JDX);
			END LOOP;
		ELSIF v_IDX = 2 THEN
			-- second line contains date
			v_SEPARATOR := INSTR(v_COLS(1),':');
			v_MONTH := TO_DATE(TRIM(SUBSTR(v_COLS(1),v_SEPARATOR+1)),'MON YY');
		ELSIF v_IDX = 3 THEN
			-- skip 3rd line - it has column headers for data below
			NULL;
		ELSE
			-- remaining lines contain charge determinant data
			p_RECORDS.EXTEND();
			p_RECORDS(p_RECORDS.LAST) := MEX_PJM_TRANS_REVNEUT_CHARGES(v_ORG_NAME,
									v_MONTH,v_COLS(1),v_COLS(2),
									TO_NUMBER(v_COLS(3)),TO_NUMBER(v_COLS(4)),
									TO_NUMBER(v_COLS(5)));
		END IF;
		v_IDX := v_LINES.NEXT(v_IDX);
	END LOOP;
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      p_STATUS := SQLCODE;
      p_MESSAGE := 'Error in MEX_PJM_SETTLEMENT.PARSE_TRANS_REVNEUT_CHARGES: ' || SQLERRM;
END PARSE_TRANS_REVNEUT_CHARGES;
----------------------------------------------------------------------------------------------------
PROCEDURE PARSE_MONTHLY_CREDIT_ALLOC
	(
	p_CSV IN CLOB,
	p_RECORDS OUT MEX_PJM_MONTHLY_CRED_ALLOC_TBL,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) AS
v_LINES PARSE_UTIL.BIG_STRING_TABLE_MP;
v_COLS PARSE_UTIL.STRING_TABLE;
v_IDX BINARY_INTEGER;
v_JDX BINARY_INTEGER;
v_ORG_ID VARCHAR2(8);
v_ORG_NAME VARCHAR2(64);
v_MONTH DATE;
BEGIN
  p_STATUS := MEX_UTIL.g_SUCCESS;

	PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_CSV,v_LINES);
	v_IDX := v_LINES.FIRST;
	p_RECORDS := MEX_PJM_MONTHLY_CRED_ALLOC_TBL();
    --if there is only one line there is no data in the report
    IF v_LINES.EXISTS(2) THEN
	WHILE v_LINES.EXISTS(v_IDX) LOOP
		PARSE_UTIL.TOKENS_FROM_STRING(v_LINES(v_IDX),',',v_COLS);
		IF v_IDX = 1 THEN
			-- first line contains month, org ID, and org name
			v_MONTH := TO_DATE(TRIM(v_COLS(1)),'MON YY');
			v_ORG_ID := TRIM(v_COLS(2));
			v_ORG_NAME := TRIM(v_COLS(3));
			-- if name contains comma, then TOKENS_FROM_STRING may have broken
			-- name into other columns - so put it back together
			v_JDX := 4;
			WHILE v_COLS.EXISTS(v_JDX) LOOP
				v_ORG_NAME := v_ORG_NAME||', '||TRIM(v_COLS(v_JDX));
				v_JDX := v_COLS.NEXT(v_JDX);
			END LOOP;
		ELSIF v_IDX = 2 THEN
			-- skip 2nd line - it has column headers for data below
			NULL;
		ELSE
			-- remaining lines contain charge determinant data
			p_RECORDS.EXTEND();
			p_RECORDS(p_RECORDS.LAST) := MEX_PJM_MONTHLY_CREDIT_ALLOC(v_MONTH,
									v_ORG_ID, v_ORG_NAME, TRIM(REPLACE(v_COLS(1),':','')),
									TO_NUMBER(v_COLS(2)),TO_NUMBER(v_COLS(3)),
									TO_NUMBER(v_COLS(6)),TO_NUMBER(v_COLS(7)),
									TO_NUMBER(v_COLS(8)),TO_NUMBER(v_COLS(9)),
									TO_NUMBER(v_COLS(10)),TO_NUMBER(v_COLS(11)));
		END IF;
		v_IDX := v_LINES.NEXT(v_IDX);
	END LOOP;
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      p_STATUS := SQLCODE;
      p_MESSAGE := 'Error in MEX_PJM_SETTLEMENT.PARSE_MONTHLY_CREDIT_ALLOC: ' || SQLERRM;
END PARSE_MONTHLY_CREDIT_ALLOC;
----------------------------------------------------------------------------------------------------
PROCEDURE PARSE_SYNCH_CONDENS_SUMMARY
	(
	p_CSV IN CLOB,
	p_RECORDS OUT MEX_PJM_SYNCH_COND_SUMMARY_TBL,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) AS
v_LINES PARSE_UTIL.BIG_STRING_TABLE_MP;
v_COLS PARSE_UTIL.STRING_TABLE;
v_IDX BINARY_INTEGER;
BEGIN
  p_STATUS := MEX_UTIL.g_SUCCESS;

	PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_CSV,v_LINES);
	v_IDX := v_LINES.FIRST;
	p_RECORDS := MEX_PJM_SYNCH_COND_SUMMARY_TBL();
	WHILE v_LINES.EXISTS(v_IDX) LOOP
		PARSE_UTIL.TOKENS_FROM_STRING(v_LINES(v_IDX),',',v_COLS);
		IF v_IDX = 1 THEN
			-- skip 1st line - it has column headers for data below
			NULL;
		ELSE
			-- remaining lines contain charge determinant data
			p_RECORDS.EXTEND();
			p_RECORDS(p_RECORDS.LAST) := MEX_PJM_SYNCH_CONDENS_SUMMARY(v_COLS(1),
											TO_DATE(v_COLS(2),'MM/DD/YY'),
											TO_NUMBER(v_COLS(3)),TO_NUMBER(v_COLS(4)),
											TO_NUMBER(v_COLS(5)),TO_NUMBER(v_COLS(6)),
											TO_NUMBER(v_COLS(7)),TO_NUMBER(v_COLS(8)),
											TO_NUMBER(v_COLS(9)));
		END IF;
		v_IDX := v_LINES.NEXT(v_IDX);
	END LOOP;
  EXCEPTION
    WHEN OTHERS THEN
      p_STATUS := SQLCODE;
      p_MESSAGE := 'Error in MEX_PJM_SETTLEMENT.PARSE_SYNCH_CONDENS_SUMMARY: ' || SQLERRM;
END PARSE_SYNCH_CONDENS_SUMMARY;
----------------------------------------------------------------------------------------------------
PROCEDURE PARSE_SCHEDULE1A_SUMMARY
	(
	p_CSV IN CLOB,
	p_RECORDS OUT MEX_PJM_SCHEDULE1A_SUMMARY_TBL,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) AS
v_LINES PARSE_UTIL.BIG_STRING_TABLE_MP;
v_COLS PARSE_UTIL.STRING_TABLE;
v_IDX BINARY_INTEGER;
BEGIN
  p_STATUS := MEX_UTIL.g_SUCCESS;

	PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_CSV,v_LINES);
	v_IDX := v_LINES.FIRST;
	p_RECORDS := MEX_PJM_SCHEDULE1A_SUMMARY_TBL();
	WHILE v_LINES.EXISTS(v_IDX) LOOP
		PARSE_UTIL.TOKENS_FROM_STRING(v_LINES(v_IDX),',',v_COLS);
		IF v_IDX = 1 THEN
			-- skip 1st line - it has column headers for data below
			NULL;
		ELSE
			-- remaining lines contain charge determinant data
			p_RECORDS.EXTEND();
			p_RECORDS(p_RECORDS.LAST) := MEX_PJM_SCHEDULE1A_SUMMARY(v_COLS(1),
											TRUNC(TO_DATE(v_COLS(2),'MM/DD/YY'),'MM'),
                                            NULL,
											v_COLS(3),TO_NUMBER(v_COLS(4)),
											TO_NUMBER(v_COLS(5)),TO_NUMBER(v_COLS(6)),
											TO_NUMBER(v_COLS(7)),TO_NUMBER(v_COLS(8)),
											TO_NUMBER(v_COLS(9)),TO_NUMBER(v_COLS(10)),
											TO_NUMBER(v_COLS(11)));
		END IF;
		v_IDX := v_LINES.NEXT(v_IDX);
	END LOOP;
  EXCEPTION
    WHEN OTHERS THEN
      p_STATUS := SQLCODE;
      p_MESSAGE := 'Error in MEX_PJM_SETTLEMENT.PARSE_SCHEDULE1A_SUMMARY: ' || SQLERRM;
END PARSE_SCHEDULE1A_SUMMARY;
----------------------------------------------------------------------------------------------------
PROCEDURE PARSE_REGULATION_SUMMARY
	(
	p_CSV IN CLOB,
	p_RECORDS OUT MEX_PJM_REGULATION_SUMMARY_TBL,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) AS
v_LINES PARSE_UTIL.BIG_STRING_TABLE_MP;
v_COLS PARSE_UTIL.STRING_TABLE;
v_IDX BINARY_INTEGER;
BEGIN
  p_STATUS := MEX_UTIL.g_SUCCESS;

	PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_CSV,v_LINES);
	v_IDX := v_LINES.FIRST;
	p_RECORDS := MEX_PJM_REGULATION_SUMMARY_TBL();
	WHILE v_LINES.EXISTS(v_IDX) LOOP
		PARSE_UTIL.TOKENS_FROM_STRING(v_LINES(v_IDX),',',v_COLS);
		IF v_IDX = 1 THEN
			-- skip 1st line - it has column headers for data below
			NULL;
		ELSE
			-- remaining lines contain charge determinant data
			p_RECORDS.EXTEND();
			p_RECORDS(p_RECORDS.LAST) := MEX_PJM_REGULATION_SUMMARY(v_COLS(1),
											TO_DATE(v_COLS(2),'MM/DD/YY'),
											TO_NUMBER(v_COLS(3)),TO_NUMBER(v_COLS(4)),
											v_COLS(5),TO_NUMBER(v_COLS(6)),
											TO_NUMBER(v_COLS(7)),TO_NUMBER(v_COLS(8)),
											TO_NUMBER(v_COLS(9)),TO_NUMBER(v_COLS(10)),
											TO_NUMBER(v_COLS(11)),TO_NUMBER(v_COLS(12)),
											TO_NUMBER(v_COLS(13)),TO_NUMBER(v_COLS(14)),
											TO_NUMBER(v_COLS(15)),TO_NUMBER(v_COLS(16)),
											TO_NUMBER(v_COLS(17)),TO_NUMBER(v_COLS(18)));
		END IF;
		v_IDX := v_LINES.NEXT(v_IDX);
	END LOOP;
  EXCEPTION
    WHEN OTHERS THEN
      p_STATUS := SQLCODE;
      p_MESSAGE := 'Error in MEX_PJM_SETTLEMENT.PARSE_REGULATION_SUMMARY: ' || SQLERRM;
END PARSE_REGULATION_SUMMARY;
----------------------------------------------------------------------------------------------------
PROCEDURE PARSE_FTR_AUCTION
	(
	p_CSV IN CLOB,
	p_RECORDS OUT MEX_PJM_FTR_AUCTION_TBL,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) AS
v_LINES PARSE_UTIL.BIG_STRING_TABLE_MP;
v_COLS PARSE_UTIL.STRING_TABLE;
v_IDX BINARY_INTEGER;
BEGIN
  p_STATUS := MEX_UTIL.g_SUCCESS;

	PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_CSV,v_LINES);
	v_IDX := v_LINES.FIRST;
	p_RECORDS := MEX_PJM_FTR_AUCTION_TBL();
	WHILE v_LINES.EXISTS(v_IDX) LOOP
		PARSE_UTIL.TOKENS_FROM_STRING(v_LINES(v_IDX),',',v_COLS);
		IF v_IDX = 1 THEN
			-- skip 1st line - it has column headers for data below
			NULL;
		ELSE
			-- remaining lines contain charge determinant data
			p_RECORDS.EXTEND();
			p_RECORDS(p_RECORDS.LAST) := MEX_PJM_FTR_AUCTION(v_COLS(1),
											TRUNC(TO_DATE(v_COLS(2),'MM/DD/YY'),'MM'),
											v_COLS(3),v_COLS(4),
											v_COLS(5),v_COLS(6),
											TO_NUMBER(v_COLS(7)),TO_NUMBER(v_COLS(8)),
											TO_NUMBER(v_COLS(9)),TO_NUMBER(v_COLS(10)),
											TO_NUMBER(v_COLS(11)));
		END IF;
		v_IDX := v_LINES.NEXT(v_IDX);
	END LOOP;
  EXCEPTION
    WHEN OTHERS THEN
      p_STATUS := SQLCODE;
      p_MESSAGE := 'Error in MEX_PJM_SETTLEMENT.PARSE_FTR_AUCTION: ' || SQLERRM;
END PARSE_FTR_AUCTION;
----------------------------------------------------------------------------------------------------
PROCEDURE PARSE_FTR_TARGET_ALLOCATION
	(
	p_CSV IN CLOB,
	p_WORK_ID IN NUMBER,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) AS
v_LINES PARSE_UTIL.BIG_STRING_TABLE_MP;
v_COLS PARSE_UTIL.STRING_TABLE;
v_IDX BINARY_INTEGER;
v_HOUR_IDX BINARY_INTEGER;
v_ROW MEX_PJM_FTR_ALLOC_WORK%ROWTYPE;
v_ROW_HEADER VARCHAR2(128);
v_SINK_LMPS PARSE_UTIL.STRING_TABLE;
v_SOURCE_LMPS PARSE_UTIL.STRING_TABLE;
BEGIN
	p_STATUS := MEX_UTIL.g_SUCCESS;

	PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_CSV,v_LINES);
	v_IDX := v_LINES.FIRST;

	v_ROW.WORK_ID := p_WORK_ID;
	WHILE v_LINES.EXISTS(v_IDX) LOOP
		PARSE_UTIL.TOKENS_FROM_STRING(v_LINES(v_IDX),',',v_COLS);

		v_ROW_HEADER := TRIM(v_COLS(1));
		-- Get the ORG_ID if this is the Participant row.
		IF v_ROW_HEADER = 'Participant:' THEN
			v_ROW.ORG_IDENT := v_COLS(2);
		-- If this is the hour row, just ignore it.
		ELSIF v_ROW_HEADER = 'Hour Ending:' THEN
			NULL;
		-- If this is the date row, get the date, FTR MW, Sink Name, Source Name, and Hedge Type.
		ELSIF v_ROW_HEADER = 'Date:' THEN
			v_ROW.DAY := TO_DATE(v_COLS(2), 'MM/DD/YYYY');
			v_ROW.TRANSACTION_IDENT := REPLACE(v_COLS(4),'''','');
			v_ROW.FTR_MW := v_COLS(6);
			v_ROW.SINK_NAME := v_COLS(8);
			v_ROW.SOURCE_NAME := v_COLS(10);
			v_ROW.HEDGE_TYPE := v_COLS(12);
			v_ROW.ALLOCATION_PCT := v_COLS(14);
		-- If this is the Sink LMP row, then cache it and move on.
		ELSIF v_ROW_HEADER = 'Sink LMP' OR v_ROW_HEADER = 'Sink DA Congestion Price' THEN
			v_SINK_LMPS := v_COLS;
		-- If this is the Source LMP row, then cache it and move on.
		ELSIF v_ROW_HEADER = 'Source LMP' OR v_ROW_HEADER = 'Source DA Congestion Price' THEN
			v_SOURCE_LMPS := v_COLS;
		-- Target Allocation is the final row in the group, so add in the
		-- cached LMPS and Target Allocation for each hour.
		ELSIF v_ROW_HEADER = 'Target Allocation' THEN
			FOR v_HOUR_IDX IN 2 .. 26 LOOP
				IF v_HOUR_IDX < 4 THEN
					v_ROW.HOUR := v_HOUR_IDX - 1;
				ELSIF v_HOUR_IDX = 4 THEN
					IF TRUNC(v_ROW.DAY) = TRUNC(DST_FALL_BACK_DATE(v_ROW.DAY)) THEN
						v_ROW.HOUR := 25;
					ELSE
						v_ROW.HOUR := -1;
					END IF;
				ELSE
					v_ROW.HOUR := v_HOUR_IDX - 2;
				END IF;
				v_ROW.SINK_LMP := v_SINK_LMPS(v_HOUR_IDX);
				v_ROW.SOURCE_LMP := v_SOURCE_LMPS(v_HOUR_IDX);
				v_ROW.TARGET_ALLOCATION := v_COLS(v_HOUR_IDX);

				-- Don't insert a row for the 2_extra row unless this is the 25 hour day.
				IF v_ROW.HOUR > 0 THEN
					INSERT INTO MEX_PJM_FTR_ALLOC_WORK VALUES v_ROW;
				END IF;

			END LOOP;
		END IF;

		v_IDX := v_LINES.NEXT(v_IDX);
	END LOOP;

    COMMIT;


  EXCEPTION
    WHEN OTHERS THEN
      p_STATUS := SQLCODE;
      p_MESSAGE := 'Error in MEX_PJM_SETTLEMENT.PARSE_FTR_TARGET_ALLOCATION: ' || SQLERRM;
END PARSE_FTR_TARGET_ALLOCATION;
----------------------------------------------------------------------------------------------------
PROCEDURE PARSE_BLACK_START_SUMMARY(p_CSV     IN CLOB,
																		p_RECORDS OUT MEX_PJM_BLACKSTART_SUMMARY_TBL,
																		p_STATUS  OUT NUMBER,
																		p_MESSAGE OUT VARCHAR2) AS
	v_LINES PARSE_UTIL.BIG_STRING_TABLE_MP;
	v_COLS  PARSE_UTIL.STRING_TABLE;
	v_IDX   BINARY_INTEGER;
BEGIN
	p_STATUS := MEX_UTIL.g_SUCCESS;

	PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_CSV, v_LINES);

  v_IDX     := v_LINES.FIRST;
	p_RECORDS := MEX_PJM_BLACKSTART_SUMMARY_TBL();

  WHILE v_LINES.EXISTS(v_IDX) LOOP
		PARSE_UTIL.PARSE_DELIMITED_STRING(v_LINES(v_IDX), ',', v_COLS);
		IF v_IDX = 1 THEN
			-- skip 1st line - it has column headers for data below
			NULL;
		ELSE
			-- remaining lines contain charge determinant data
			p_RECORDS.EXTEND();
			p_RECORDS(p_RECORDS.LAST) := MEX_PJM_BLACKSTART_SUMMARY(v_COLS(1),
																											 TRUNC(TO_DATE(v_COLS(2),
																																			'MM/DD/YY'),
																															'MM'), v_COLS(3),
																											 TO_NUMBER(v_COLS(4)),
																											 TO_NUMBER(v_COLS(5)),
																											 v_COLS(6),
																											 TO_NUMBER(v_COLS(7)),
																											 TO_NUMBER(v_COLS(8)),
																											 TO_NUMBER(v_COLS(9)),
																											 TO_NUMBER(v_COLS(10)),
																											 TO_NUMBER(v_COLS(11)));
		END IF;
		v_IDX := v_LINES.NEXT(v_IDX);
	END LOOP;
EXCEPTION
	WHEN OTHERS THEN
		p_STATUS  := SQLCODE;
		p_MESSAGE := 'Error in MEX_PJM_SETTLEMENT.PARSE_BLACK_START_SUMMARY: ' ||
								 SQLERRM;
END PARSE_BLACK_START_SUMMARY;
----------------------------------------------------------------------------------------------------
PROCEDURE PARSE_ARR_SUMMARY(p_CSV     IN CLOB,
														p_RECORDS OUT MEX_PJM_ARR_SUMMARY_TBL,
														p_STATUS  OUT NUMBER,
														p_MESSAGE OUT VARCHAR2) AS
	v_LINES PARSE_UTIL.BIG_STRING_TABLE_MP;
	v_COLS  PARSE_UTIL.STRING_TABLE;
	v_IDX   BINARY_INTEGER;
BEGIN
	p_STATUS := MEX_UTIL.g_SUCCESS;

	PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_CSV, v_LINES);

	v_IDX     := v_LINES.FIRST;
	p_RECORDS := MEX_PJM_ARR_SUMMARY_TBL();

	WHILE v_LINES.EXISTS(v_IDX) LOOP
		PARSE_UTIL.PARSE_DELIMITED_STRING(v_LINES(v_IDX), ',', v_COLS);
		IF v_IDX = 1 THEN
			-- skip 1st line - it has column headers for data below
			NULL;
		ELSE
			-- remaining lines contain charge determinant data
			p_RECORDS.EXTEND();
			p_RECORDS(p_RECORDS.LAST) := MEX_PJM_ARR_SUMMARY(v_COLS(1), v_COLS(2),
																													 TO_DATE(v_COLS(3),
																																		'MM/DD/YY'),
																													 v_COLS(4),
																													 TO_NUMBER(v_COLS(5)),
																													 TO_NUMBER(v_COLS(6)),
																													 TO_NUMBER(v_COLS(7)),
																													 TO_NUMBER(v_COLS(8)),
																													 TO_NUMBER(v_COLS(9)));
		END IF;
		v_IDX := v_LINES.NEXT(v_IDX);
	END LOOP;
EXCEPTION
	WHEN OTHERS THEN
		p_STATUS  := SQLCODE;
		p_MESSAGE := 'Error in MEX_PJM_SETTLEMENT.PARSE_ARR_SUMMARY: ' || SQLERRM;
END PARSE_ARR_SUMMARY;
----------------------------------------------------------------------------------------------------
PROCEDURE PARSE_REACTIVE_SUMMARY(p_CSV     IN CLOB,
																 p_RECORDS OUT MEX_PJM_REACTIVE_SUMMARY_TBL,
																 p_STATUS  OUT NUMBER,
																 p_MESSAGE OUT VARCHAR2) AS
	v_LINES PARSE_UTIL.BIG_STRING_TABLE_MP;
	v_COLS  PARSE_UTIL.STRING_TABLE;
	v_IDX   BINARY_INTEGER;
BEGIN
	p_STATUS := MEX_UTIL.g_SUCCESS;

	PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_CSV, v_LINES);

	v_IDX     := v_LINES.FIRST;
	p_RECORDS := MEX_PJM_REACTIVE_SUMMARY_TBL();
	WHILE v_LINES.EXISTS(v_IDX) LOOP
		PARSE_UTIL.PARSE_DELIMITED_STRING(v_LINES(v_IDX), ',', v_COLS);
		IF v_IDX = 1 THEN
			-- skip 1st line - it has column headers for data below
			NULL;
		ELSE
			-- remaining lines contain charge determinant data
			p_RECORDS.EXTEND();
			p_RECORDS(p_RECORDS.LAST) := MEX_PJM_REACTIVE_SUMMARY(v_COLS(1),
																TRUNC(TO_DATE(v_COLS(2), 'MM/DD/YY'),'MM'),
																		v_COLS(3),
        														TO_NUMBER(v_COLS(4)),
        														TO_NUMBER(v_COLS(5)),
        														TO_NUMBER(v_COLS(6)),
        														TO_NUMBER(v_COLS(7)),
        														TO_NUMBER(v_COLS(8)),
        														TO_NUMBER(v_COLS(9)),
        														TO_NUMBER(v_COLS(10)),
        														TO_NUMBER(v_COLS(11)));
		END IF;
		v_IDX := v_LINES.NEXT(v_IDX);
	END LOOP;
EXCEPTION
	WHEN OTHERS THEN
		p_STATUS  := SQLCODE;
		p_MESSAGE := 'Error in MEX_PJM_SETTLEMENT.PARSE_REACTIVE_SUMMARY: ' ||
								 SQLERRM;
END PARSE_REACTIVE_SUMMARY;
----------------------------------------------------------------------------------------------------
PROCEDURE PARSE_EN_IMB_CRE_SUMMARY(p_CSV     IN CLOB,
																	 p_RECORDS OUT MEX_PJM_EN_IMB_CRE_SUMMARY_TBL,
																	 p_STATUS  OUT NUMBER,
																	 p_MESSAGE OUT VARCHAR2) AS
	v_LINES PARSE_UTIL.BIG_STRING_TABLE_MP;
	v_COLS  PARSE_UTIL.STRING_TABLE;
	v_IDX   BINARY_INTEGER;
BEGIN
	p_STATUS := MEX_UTIL.g_SUCCESS;

	PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_CSV, v_LINES);

	v_IDX     := v_LINES.FIRST;
	p_RECORDS := MEX_PJM_EN_IMB_CRE_SUMMARY_TBL();

	WHILE v_LINES.EXISTS(v_IDX) LOOP
		PARSE_UTIL.PARSE_DELIMITED_STRING(v_LINES(v_IDX), ',', v_COLS);
		IF v_IDX = 1 THEN
			-- skip 1st line - it has column headers for data below
			NULL;
		ELSE
			-- remaining lines contain charge determinant data
			p_RECORDS.EXTEND();
			p_RECORDS(p_RECORDS.LAST) := MEX_PJM_EN_IMB_CRE_SUMMARY(v_COLS(1),
																															TO_DATE(v_COLS(2),
																																			 'MM/DD/YY'),
																															TO_NUMBER(v_COLS(3)),
																															TO_NUMBER(v_COLS(4)),
																															TO_NUMBER(v_COLS(5)));
		END IF;
		v_IDX := v_LINES.NEXT(v_IDX);
	END LOOP;
EXCEPTION
	WHEN OTHERS THEN
		p_STATUS  := SQLCODE;
		p_MESSAGE := 'Error in MEX_PJM_SETTLEMENT.PARSE_EN_IMB_CRE_SUMMARY: ' ||
								 SQLERRM;
END PARSE_EN_IMB_CRE_SUMMARY;
----------------------------------------------------------------------------------------------------
PROCEDURE PARSE_CAP_CRED_SUMMARY(p_CSV     IN CLOB,
																 p_RECORDS OUT MEX_PJM_CAP_CRED_SUMMARY_TBL,
																 p_STATUS  OUT NUMBER,
																 p_MESSAGE OUT VARCHAR2) AS
	v_LINES PARSE_UTIL.BIG_STRING_TABLE_MP;
	v_COLS  PARSE_UTIL.STRING_TABLE;
	v_IDX   BINARY_INTEGER;
BEGIN
	p_STATUS := MEX_UTIL.g_SUCCESS;

	PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_CSV, v_LINES);

	v_IDX     := v_LINES.FIRST;
	p_RECORDS := MEX_PJM_CAP_CRED_SUMMARY_TBL();

	WHILE v_LINES.EXISTS(v_IDX) LOOP
		PARSE_UTIL.PARSE_DELIMITED_STRING(v_LINES(v_IDX), ',', v_COLS);
		IF v_IDX = 1 THEN
			-- skip 1st line - it has column headers for data below
			NULL;
		ELSE
			-- remaining lines contain charge determinant data
			p_RECORDS.EXTEND();
			p_RECORDS(p_RECORDS.LAST) := MEX_PJM_CAP_CRED_SUMMARY(v_COLS(1),
										TO_DATE(v_COLS(2),'MM/DD/YY'),
										v_COLS(3),
										v_COLS(4),
										TO_NUMBER(v_COLS(5)),
										TO_NUMBER(v_COLS(6)),
										v_COLS(7),
										TO_NUMBER(v_COLS(8)),
										TO_NUMBER(v_COLS(9)));
		END IF;
		v_IDX := v_LINES.NEXT(v_IDX);
	END LOOP;
EXCEPTION
	WHEN OTHERS THEN
		p_STATUS  := SQLCODE;
		p_MESSAGE := 'Error in MEX_PJM_SETTLEMENT.PARSE_CAP_CRED_SUMMARY: ' ||
								 SQLERRM;
END PARSE_CAP_CRED_SUMMARY;
----------------------------------------------------------------------------------------------------
PROCEDURE PARSE_SPIN_RES_SUMMARY
	(
	p_CSV     IN CLOB,
	p_RECORDS OUT MEX_PJM_SPIN_RES_SUMMARY_TBL,
	p_STATUS  OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
    ) AS
v_LINES PARSE_UTIL.BIG_STRING_TABLE_MP;
v_COLS  PARSE_UTIL.STRING_TABLE;
v_IDX   BINARY_INTEGER;
BEGIN
	p_STATUS := MEX_UTIL.g_SUCCESS;

	PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_CSV, v_LINES);

	v_IDX     := v_LINES.FIRST;
	p_RECORDS := MEX_PJM_SPIN_RES_SUMMARY_TBL();

	WHILE v_LINES.EXISTS(v_IDX) LOOP
		PARSE_UTIL.PARSE_DELIMITED_STRING(v_LINES(v_IDX), ',', v_COLS);
		IF v_IDX = 1 THEN
			-- skip 1st line - it has column headers for data below
			NULL;
		ELSE
			-- remaining lines contain charge determinant data
			p_RECORDS.EXTEND();
			p_RECORDS(p_RECORDS.LAST) := MEX_PJM_SPIN_RES_SUMMARY(v_COLS(1), v_COLS(2),
					TO_DATE(v_COLS(3),'MM/DD/YY'),
					TO_NUMBER(v_COLS(4)),
					TO_NUMBER(v_COLS(5)),
					v_COLS(6),
					v_COLS(7),
					TO_NUMBER(v_COLS(8)),
					TO_NUMBER(v_COLS(9)),
					TO_NUMBER(v_COLS(10)),
					TO_NUMBER(v_COLS(11)),
					TO_NUMBER(v_COLS(12)),
					TO_NUMBER(v_COLS(13)),
					TO_NUMBER(v_COLS(14)),
					TO_NUMBER(v_COLS(15)),
					TO_NUMBER(v_COLS(16)),
					TO_NUMBER(v_COLS(17)),
					TO_NUMBER(v_COLS(18)),
					TO_NUMBER(v_COLS(19)),
					TO_NUMBER(v_COLS(20)),
					TO_NUMBER(v_COLS(21)),
					TO_NUMBER(v_COLS(22)),
					TO_NUMBER(v_COLS(23)),
					TO_NUMBER(v_COLS(24)),
					TO_NUMBER(v_COLS(25)),
					TO_NUMBER(v_COLS(26)),
					TO_NUMBER(v_COLS(27)),
					TO_NUMBER(v_COLS(28)),
					TO_NUMBER(v_COLS(29)),
					TO_NUMBER(v_COLS(30)),
					TO_NUMBER(v_COLS(31)));
		END IF;
		v_IDX := v_LINES.NEXT(v_IDX);
	END LOOP;
EXCEPTION
	WHEN OTHERS THEN
		p_STATUS  := SQLCODE;
		p_MESSAGE := 'Error in MEX_PJM_SETTLEMENT.PARSE_SPIN_RES_SUMMARY: ' ||
								 SQLERRM;
END PARSE_SPIN_RES_SUMMARY;
----------------------------------------------------------------------------------------------------
PROCEDURE PARSE_FIRM_TRANS_SERV_CHARGES
	(
	p_CSV IN CLOB,
	p_RECORDS OUT MEX_PJM_TRANS_SERV_CHARGES_TBL,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) AS
v_LINES PARSE_UTIL.BIG_STRING_TABLE_MP;
v_COLS PARSE_UTIL.STRING_TABLE;
v_IDX BINARY_INTEGER;
v_ORG_NAME VARCHAR2(64);
v_CHARGE_DATE DATE;
BEGIN
  p_STATUS := MEX_UTIL.g_SUCCESS;

	PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_CSV,v_LINES);
	v_IDX := v_LINES.FIRST;
	p_RECORDS := MEX_PJM_TRANS_SERV_CHARGES_TBL();
	WHILE v_LINES.EXISTS(v_IDX) LOOP
		PARSE_UTIL.PARSE_DELIMITED_STRING(v_LINES(v_IDX),',',v_COLS);
		IF v_IDX = 1 THEN
			v_ORG_NAME := v_COLS(2);
        ELSIF v_IDX = 2 THEN
        	v_CHARGE_DATE := TO_DATE(SUBSTR(v_COLS(1), 7), 'MONTH YYYY');
		ELSIF v_IDX = 3 THEN
        	NULL;
        ELSE
        	-- remaining lines contain charge determinant data
			p_RECORDS.EXTEND();
			p_RECORDS(p_RECORDS.LAST) := MEX_PJM_TRANS_SERV_CHARGES
            								(
                                            v_ORG_NAME,
                                            v_CHARGE_DATE,
            								TO_NUMBER(v_COLS(1)),
                                            TO_NUMBER(v_COLS(2)),
                                            v_COLS(3),
                                            TO_DATE(v_COLS(4),'MM/DD/YY'),
											TO_DATE(v_COLS(5),'MM/DD/YY'),
                                            v_COLS(6),
                                            TO_NUMBER(v_COLS(7)),
                                            TO_NUMBER(v_COLS(8))
                                            );

		END IF;
		v_IDX := v_LINES.NEXT(v_IDX);
	END LOOP;
  EXCEPTION
    WHEN OTHERS THEN
      p_STATUS := SQLCODE;
      p_MESSAGE := 'Error in MEX_PJM_SETTLEMENT.PARSE_FIRM_TRANS_SERV_CHARGES: ' || SQLERRM;
END PARSE_FIRM_TRANS_SERV_CHARGES;
----------------------------------------------------------------------------------------------------
PROCEDURE PARSE_NON_FM_TRANS_SV_CHARGES
	(
	p_CSV IN CLOB,
	p_RECORDS OUT MEX_PJM_NFIRM_TRANS_SV_CHG_TBL,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) AS
v_LINES PARSE_UTIL.BIG_STRING_TABLE_MP;
v_COLS PARSE_UTIL.STRING_TABLE;
v_IDX BINARY_INTEGER;
v_ORG_NAME VARCHAR2(64);
v_DATE VARCHAR2(10);
v_OASISNUM VARCHAR2(16);
v_RATE NUMBER;
v_CONGESFLAG NUMBER;
v_RESCAP MEX_QUANTITY_TABLE;
v_BILLCAP MEX_QUANTITY_TABLE;
v_CONGESAMT MEX_QUANTITY_TABLE;
v_CHARGE MEX_QUANTITY_TABLE;

BEGIN
  p_STATUS := MEX_UTIL.g_SUCCESS;

	PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_CSV,v_LINES);
	v_IDX := v_LINES.FIRST;
	p_RECORDS := MEX_PJM_NFIRM_TRANS_SV_CHG_TBL();
	WHILE v_LINES.EXISTS(v_IDX) LOOP
		PARSE_UTIL.PARSE_DELIMITED_STRING(v_LINES(v_IDX),',',v_COLS);
		IF v_IDX = 1 THEN
			v_ORG_NAME := v_COLS(2);
        ELSIF v_IDX = 2 THEN
        	NULL;

        ELSE

        	v_DATE := v_COLS(2);
            v_OASISNUM := v_COLS(4);
            v_RATE := v_COLS(8);
            IF v_COLS(10) = 'YES' THEN
            	v_CONGESFLAG := 1;
            ELSE
            	v_CONGESFLAG := 0;
            END IF;
            v_IDX := v_LINES.NEXT(v_IDX);
            FILL_MEX_QTY_TABLE(v_LINES(v_IDX), v_COLS, v_RESCAP,p_MESSAGE, p_STATUS);
            v_IDX := v_LINES.NEXT(v_IDX);
            FILL_MEX_QTY_TABLE(v_LINES(v_IDX), v_COLS, v_BILLCAP,p_MESSAGE, p_STATUS);
            v_IDX := v_LINES.NEXT(v_IDX);
            FILL_MEX_QTY_TABLE(v_LINES(v_IDX), v_COLS, v_CONGESAMT,p_MESSAGE, p_STATUS);
            v_IDX := v_LINES.NEXT(v_IDX);
            FILL_MEX_QTY_TABLE(v_LINES(v_IDX), v_COLS, v_CHARGE,p_MESSAGE, p_STATUS);
			p_RECORDS.EXTEND();
			p_RECORDS(p_RECORDS.LAST) := MEX_PJM_NFIRM_TRANS_SV_CHARGES
            								(
                                            v_ORG_NAME,
                                            TO_DATE(v_DATE, 'MM/DD/YYYY'),
            								TO_NUMBER(v_OASISNUM),
                                            v_RESCAP,
                                            v_BILLCAP,
                                            v_CONGESFLAG,
											v_CONGESAMT,
                                            TO_NUMBER(v_RATE),
                                            v_CHARGE
                                            );

		END IF;
		v_IDX := v_LINES.NEXT(v_IDX);
	END LOOP;
  EXCEPTION
    WHEN OTHERS THEN
      p_STATUS := SQLCODE;
      p_MESSAGE := 'Error in MEX_PJM_SETTLEMENT.PARSE_NON_FM_TRANS_SV_CHARGES: ' || SQLERRM;
END PARSE_NON_FM_TRANS_SV_CHARGES;
----------------------------------------------------------------------------------------------------
PROCEDURE PARSE_SCHEDULE1_RECONCILE
	(
	p_CSV IN CLOB,
	p_RECORDS OUT MEX_PJM_SCHEDULE1A_SUMMARY_TBL,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) AS
v_LINES PARSE_UTIL.BIG_STRING_TABLE_MP;
v_COLS PARSE_UTIL.STRING_TABLE;
v_IDX BINARY_INTEGER;
BEGIN
  p_STATUS := MEX_UTIL.g_SUCCESS;

	PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_CSV,v_LINES);
	v_IDX := v_LINES.FIRST;
	p_RECORDS := MEX_PJM_SCHEDULE1A_SUMMARY_TBL();
	WHILE v_LINES.EXISTS(v_IDX) LOOP
		PARSE_UTIL.TOKENS_FROM_STRING(v_LINES(v_IDX),',',v_COLS);
		IF v_IDX = 1 THEN
			-- skip 1st line - it has column headers for data below
			NULL;
		ELSE
			-- remaining lines contain charge determinant data
			p_RECORDS.EXTEND();
			p_RECORDS(p_RECORDS.LAST) := MEX_PJM_SCHEDULE1A_SUMMARY(v_COLS(1),
											TRUNC(TO_DATE(v_COLS(2),'MM/DD/YY'),'MM'),
                                            NULL,
											v_COLS(3),TO_NUMBER(v_COLS(5)),
											TO_NUMBER(v_COLS(4)),NULL,
											TO_NUMBER(v_COLS(6)),NULL,NULL,NULL,NULL);
		END IF;
		v_IDX := v_LINES.NEXT(v_IDX);
	END LOOP;
  EXCEPTION
    WHEN OTHERS THEN
      p_STATUS := SQLCODE;
      p_MESSAGE := 'Error in MEX_PJM_SETTLEMENT.PARSE_SCHEDULE1_RECONCILE: ' || SQLERRM;
END PARSE_SCHEDULE1_RECONCILE;
----------------------------------------------------------------------------------------------------
PROCEDURE PARSE_SCHEDULE1A_RECONCILE
	(
	p_CSV IN CLOB,
	p_RECORDS OUT MEX_PJM_SCHEDULE1A_SUMMARY_TBL,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) AS
v_LINES PARSE_UTIL.BIG_STRING_TABLE_MP;
v_COLS PARSE_UTIL.STRING_TABLE;
v_IDX BINARY_INTEGER;
BEGIN
  p_STATUS := MEX_UTIL.g_SUCCESS;

	PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_CSV,v_LINES);
	v_IDX := v_LINES.FIRST;
	p_RECORDS := MEX_PJM_SCHEDULE1A_SUMMARY_TBL();
	WHILE v_LINES.EXISTS(v_IDX) LOOP
		PARSE_UTIL.TOKENS_FROM_STRING(v_LINES(v_IDX),',',v_COLS);
		IF v_IDX = 1 THEN
			-- skip 1st line - it has column headers for data below
			NULL;
		ELSE
			-- remaining lines contain charge determinant data
			p_RECORDS.EXTEND();
			p_RECORDS(p_RECORDS.LAST) := MEX_PJM_SCHEDULE1A_SUMMARY(v_COLS(1),
											TRUNC(TO_DATE(v_COLS(2),'MM/DD/YY'),'MM'),
                                            v_COLS(3),
											v_COLS(4),TO_NUMBER(v_COLS(6)),
											TO_NUMBER(v_COLS(5)),NULL,
											TO_NUMBER(v_COLS(7)),NULL,NULL,NULL,NULL);
		END IF;
		v_IDX := v_LINES.NEXT(v_IDX);
	END LOOP;
  EXCEPTION
    WHEN OTHERS THEN
      p_STATUS := SQLCODE;
      p_MESSAGE := 'Error in MEX_PJM_SETTLEMENT.PARSE_SCHEDULE1A_RECONCILE: ' || SQLERRM;
END PARSE_SCHEDULE1A_RECONCILE;
----------------------------------------------------------------------------------------------------
PROCEDURE PARSE_ENERGY_CHARGES_RECONCIL
	(
	p_CSV IN CLOB,
	p_RECORDS OUT MEX_PJM_RECONCIL_CHARGES_TBL,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) AS
v_LINES PARSE_UTIL.BIG_STRING_TABLE_MP;
v_COLS PARSE_UTIL.STRING_TABLE;
v_IDX BINARY_INTEGER;
BEGIN
  p_STATUS := MEX_UTIL.g_SUCCESS;

	PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_CSV,v_LINES);
	v_IDX := v_LINES.FIRST;
	p_RECORDS := MEX_PJM_RECONCIL_CHARGES_TBL();
	WHILE v_LINES.EXISTS(v_IDX) LOOP
		PARSE_UTIL.TOKENS_FROM_STRING(v_LINES(v_IDX),',',v_COLS);
		IF v_IDX = 1 THEN
			-- skip 1st line - it has column headers for data below
			NULL;
		ELSE
			-- remaining lines contain charge determinant data
			p_RECORDS.EXTEND();
			p_RECORDS(p_RECORDS.LAST) := MEX_PJM_RECONCIL_CHARGES(v_COLS(1),
											TO_DATE(v_COLS(2),'MM/DD/YYYY'),
                                            TO_NUMBER(v_COLS(3)),
                                            TO_NUMBER(v_COLS(4)),
                                            v_COLS(8),
                                            TO_NUMBER(v_COLS(9)),
                                            TO_NUMBER(v_COLS(7)),
                                            TO_NUMBER(v_COLS(10)));

		END IF;
		v_IDX := v_LINES.NEXT(v_IDX);
	END LOOP;
  EXCEPTION
    WHEN OTHERS THEN
      p_STATUS := SQLCODE;
      p_MESSAGE := 'Error in MEX_PJM_SETTLEMENT.PARSE_ENERGY_CHARGES_RECONCIL: ' || SQLERRM;
END PARSE_ENERGY_CHARGES_RECONCIL;
----------------------------------------------------------------------------------------------------
PROCEDURE PARSE_SPIN_RES_CH_RECONCIL
	(
	p_CSV IN CLOB,
	p_RECORDS OUT MEX_PJM_RECONCIL_CHARGES_TBL,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) AS
v_LINES PARSE_UTIL.BIG_STRING_TABLE_MP;
v_COLS PARSE_UTIL.STRING_TABLE;
v_IDX BINARY_INTEGER;
BEGIN
  p_STATUS := MEX_UTIL.g_SUCCESS;

	PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_CSV,v_LINES);
	v_IDX := v_LINES.FIRST;
	p_RECORDS := MEX_PJM_RECONCIL_CHARGES_TBL();
	WHILE v_LINES.EXISTS(v_IDX) LOOP
		PARSE_UTIL.TOKENS_FROM_STRING(v_LINES(v_IDX),',',v_COLS);
		IF v_IDX = 1 THEN
			-- skip 1st line - it has column headers for data below
			NULL;
		ELSE
			-- remaining lines contain charge determinant data
			p_RECORDS.EXTEND();
			p_RECORDS(p_RECORDS.LAST) := MEX_PJM_RECONCIL_CHARGES(v_COLS(1),
											TO_DATE(v_COLS(2),'MM/DD/YYYY'),
                                            TO_NUMBER(v_COLS(3)),
                                            TO_NUMBER(v_COLS(4)),
                                            v_COLS(7),
                                            TO_NUMBER(v_COLS(9)),
                                            TO_NUMBER(v_COLS(8)),
                                            TO_NUMBER(v_COLS(10)));

		END IF;
		v_IDX := v_LINES.NEXT(v_IDX);
	END LOOP;
  EXCEPTION
    WHEN OTHERS THEN
      p_STATUS := SQLCODE;
      p_MESSAGE := 'Error in MEX_PJM_SETTLEMENT.PARSE_ENERGY_CHARGES_RECONCIL: ' || SQLERRM;
END PARSE_SPIN_RES_CH_RECONCIL;
----------------------------------------------------------------------------------------------------
PROCEDURE PARSE_REG_CHARGES_RECONCIL
	(
	p_CSV IN CLOB,
	p_RECORDS OUT MEX_PJM_RECONCIL_CHARGES_TBL,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) AS
v_LINES PARSE_UTIL.BIG_STRING_TABLE_MP;
v_COLS PARSE_UTIL.STRING_TABLE;
v_IDX BINARY_INTEGER;
BEGIN
  p_STATUS := MEX_UTIL.g_SUCCESS;

	PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_CSV,v_LINES);
	v_IDX := v_LINES.FIRST;
	p_RECORDS := MEX_PJM_RECONCIL_CHARGES_TBL();
	WHILE v_LINES.EXISTS(v_IDX) LOOP
		PARSE_UTIL.TOKENS_FROM_STRING(v_LINES(v_IDX),',',v_COLS);
		IF v_IDX = 1 THEN
			-- skip 1st line - it has column headers for data below
			NULL;
		ELSE
			-- remaining lines contain charge determinant data
			p_RECORDS.EXTEND();
			p_RECORDS(p_RECORDS.LAST) := MEX_PJM_RECONCIL_CHARGES(v_COLS(1),
											TO_DATE(v_COLS(2),'MM/DD/YYYY'),
                                            TO_NUMBER(v_COLS(3)),
                                            TO_NUMBER(v_COLS(4)),
                                            v_COLS(5),
                                            TO_NUMBER(v_COLS(7)),
                                            TO_NUMBER(v_COLS(6)),
                                            TO_NUMBER(v_COLS(8)));

		END IF;
		v_IDX := v_LINES.NEXT(v_IDX);
	END LOOP;
  EXCEPTION
    WHEN OTHERS THEN
      p_STATUS := SQLCODE;
      p_MESSAGE := 'Error in MEX_PJM_SETTLEMENT.PARSE_REG_CHARGES_RECONCIL: ' || SQLERRM;
END PARSE_REG_CHARGES_RECONCIL;
----------------------------------------------------------------------------------------------------
PROCEDURE PARSE_TRANS_LOSS_CR_RECONCIL
	(
	p_CSV IN CLOB,
	p_RECORDS OUT MEX_PJM_RECONCIL_CHARGES_TBL,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) AS
v_LINES PARSE_UTIL.BIG_STRING_TABLE_MP;
v_COLS PARSE_UTIL.STRING_TABLE;
v_IDX BINARY_INTEGER;
BEGIN
  p_STATUS := MEX_UTIL.g_SUCCESS;

	PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_CSV,v_LINES);
	v_IDX := v_LINES.FIRST;
	p_RECORDS := MEX_PJM_RECONCIL_CHARGES_TBL();
	WHILE v_LINES.EXISTS(v_IDX) LOOP
		PARSE_UTIL.TOKENS_FROM_STRING(v_LINES(v_IDX),',',v_COLS);
		IF v_IDX = 1 THEN
			-- skip 1st line - it has column headers for data below
			NULL;
		ELSE
			-- remaining lines contain charge determinant data
			p_RECORDS.EXTEND();
			p_RECORDS(p_RECORDS.LAST) := MEX_PJM_RECONCIL_CHARGES(v_COLS(1),
											TO_DATE(v_COLS(2),'MM/DD/YYYY'),
                                            TO_NUMBER(v_COLS(3)),
                                            TO_NUMBER(v_COLS(4)),
                                            v_COLS(5),
                                            TO_NUMBER(v_COLS(7)),
                                            TO_NUMBER(v_COLS(6)),
                                            TO_NUMBER(v_COLS(8)));

		END IF;
		v_IDX := v_LINES.NEXT(v_IDX);
	END LOOP;
  EXCEPTION
    WHEN OTHERS THEN
      p_STATUS := SQLCODE;
      p_MESSAGE := 'Error in MEX_PJM_SETTLEMENT.PARSE_TRANS_LOSS_CR_RECONCIL: ' || SQLERRM;
END PARSE_TRANS_LOSS_CR_RECONCIL;
----------------------------------------------------------------------------------------------------
-- These routines will fetch the CSV files from PJM for the requested report and dates, and then
-- return the data in object tables.
----------------------------------------------------------------------------------------------------
PROCEDURE FETCH_MONTHLY_STATEMENT
	(
	p_BEGIN_DATE 	IN DATE,
	p_END_DATE 		IN DATE,
    p_LOGGER    	IN  OUT MM_LOGGER_ADAPTER,
    p_CRED	  	 	IN	 MEX_CREDENTIALS,
	p_LOG_ONLY   IN  NUMBER,
	p_RECORDS 		OUT MEX_PJM_MONTHLY_STATEMENT_TBL,
	p_STATUS 		OUT NUMBER,
	p_MESSAGE 		OUT VARCHAR2
	) AS
	v_RESP CLOB := NULL;
	v_PARAMS MEX_Util.Parameter_Map := Mex_Switchboard.c_Empty_Parameter_Map;
BEGIN
	v_PARAMS(MEX_PJM.c_Report_Type) := 'Monthly Summary';
  	v_PARAMS(MEX_PJM.c_DEBUG) := g_DEBUG_EXCHANGES;
    v_PARAMS(MEX_PJM.c_Report_Name) := g_ET_MONTHLY_BILLING_STATEMENT;
  	p_LOGGER.EXCHANGE_NAME := v_PARAMS(MEX_PJM.c_Report_Name);
  	MEX_PJM.RUN_PJM_BROWSERLESS( v_PARAMS,
  								'esched', -- p_REQUEST_APP
			   					p_LOGGER,
								p_CRED,
								p_BEGIN_DATE,
								p_END_DATE,
                    			'download',  -- p_REQUEST_DIR
                    		    v_RESP,
								p_STATUS,
								p_MESSAGE,
								p_LOG_ONLY );
	IF p_STATUS = Mex_Switchboard.c_Status_Success THEN
		PARSE_MONTHLY_STATEMENT(v_RESP,p_RECORDS,p_STATUS,p_MESSAGE);
	END IF;
	IF NOT v_RESP IS NULL THEN
		DBMS_LOB.FREETEMPORARY(v_RESP);
	END IF;

END FETCH_MONTHLY_STATEMENT;
----------------------------------------------------------------------------------------------------
PROCEDURE FETCH_SPOT_SUMMARY
	(
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
    p_LOGGER    	IN  OUT MM_LOGGER_ADAPTER,
    p_CRED	  	 	IN	 MEX_CREDENTIALS,
	p_LOG_ONLY   IN  NUMBER,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) AS
	v_RESP CLOB := NULL;
	v_PARAMS MEX_Util.Parameter_Map := Mex_Switchboard.c_Empty_Parameter_Map;
BEGIN

	v_PARAMS(MEX_PJM.c_Report_Type) := 'Monthly Summary';
  	v_PARAMS(MEX_PJM.c_DEBUG) := g_DEBUG_EXCHANGES;
    v_PARAMS(MEX_PJM.c_Report_Name) := g_ET_SPOT_MKT_ENERGY_SUMMARY;
  	p_LOGGER.EXCHANGE_NAME := v_PARAMS(MEX_PJM.c_Report_Name);
  	MEX_PJM.RUN_PJM_BROWSERLESS( v_PARAMS,
  								'esched', -- p_REQUEST_APP
			   					p_LOGGER,
								p_CRED,
								p_BEGIN_DATE,
								p_END_DATE,
                    			'download',  -- p_REQUEST_DIR
                    		    v_RESP,
								p_STATUS,
								p_MESSAGE, p_LOG_ONLY );
	IF p_STATUS = Mex_Switchboard.c_Status_Success THEN
		PARSE_SPOT_SUMMARY(v_RESP,p_STATUS,p_MESSAGE);
	END IF;
	IF NOT v_RESP IS NULL THEN
	    DBMS_LOB.FREETEMPORARY(v_RESP);
	END IF;
END FETCH_SPOT_SUMMARY;
----------------------------------------------------------------------------------------------------
PROCEDURE FETCH_CONGESTION_SUMMARY
	(
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
    p_LOGGER    	IN  OUT MM_LOGGER_ADAPTER,
    p_CRED	  	 	IN	 MEX_CREDENTIALS,
	p_LOG_ONLY   IN  NUMBER,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) AS
v_RESP CLOB := NULL;
	v_PARAMS MEX_Util.Parameter_Map := Mex_Switchboard.c_Empty_Parameter_Map;
BEGIN

	v_PARAMS(MEX_PJM.c_Report_Type) := 'Monthly Summary';
  	v_PARAMS(MEX_PJM.c_DEBUG) := g_DEBUG_EXCHANGES;
    v_PARAMS(MEX_PJM.c_Report_Name) := g_ET_CONGESTION_SUMMARY;
  	p_LOGGER.EXCHANGE_NAME := v_PARAMS(MEX_PJM.c_Report_Name);
  	MEX_PJM.RUN_PJM_BROWSERLESS( v_PARAMS,
  								'esched', -- p_REQUEST_APP
			   					p_LOGGER,
								p_CRED,
								p_BEGIN_DATE,
								p_END_DATE,
                    			'download',  -- p_REQUEST_DIR
                    		    v_RESP,
								p_STATUS,
								p_MESSAGE, p_LOG_ONLY );
	IF p_STATUS = Mex_Switchboard.c_Status_Success THEN
		PARSE_CONGESTION_SUMMARY(v_RESP,p_STATUS,p_MESSAGE);
	END IF;
	IF NOT v_RESP IS NULL THEN
	    DBMS_LOB.FREETEMPORARY(v_RESP);
	END IF;
END FETCH_CONGESTION_SUMMARY;
----------------------------------------------------------------------------------------------------
PROCEDURE FETCH_SCHEDULE9_10_SUMMARY
	(
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
    p_LOGGER    	IN  OUT MM_LOGGER_ADAPTER,
    p_CRED	  	 	IN	 MEX_CREDENTIALS,
	p_LOG_ONLY   IN  NUMBER,
	p_RECORDS OUT MEX_PJM_SCHED9_10_SUMMARY_TBL,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) AS
v_RESP CLOB := NULL;
	v_PARAMS MEX_Util.Parameter_Map := Mex_Switchboard.c_Empty_Parameter_Map;
BEGIN
	v_PARAMS(MEX_PJM.c_Report_Type) := 'Monthly Summary';
  	v_PARAMS(MEX_PJM.c_DEBUG) := g_DEBUG_EXCHANGES;
    v_PARAMS(MEX_PJM.c_Report_Name) := g_ET_SCHEDULE_9_AND_10_SUMMARY;
  	p_LOGGER.EXCHANGE_NAME := v_PARAMS(MEX_PJM.c_Report_Name);
  	MEX_PJM.RUN_PJM_BROWSERLESS( v_PARAMS,
  								'esched', -- p_REQUEST_APP
			   					p_LOGGER,
								p_CRED,
								p_BEGIN_DATE,
								p_END_DATE,
                    			'download',  -- p_REQUEST_DIR
                    		    v_RESP,
								p_STATUS,
								p_MESSAGE, p_LOG_ONLY );
	IF p_STATUS = Mex_Switchboard.c_Status_Success THEN
		PARSE_SCHEDULE9_10_SUMMARY(v_RESP,p_RECORDS,p_STATUS,p_MESSAGE);
	END IF;
	IF NOT v_RESP IS NULL THEN
	    DBMS_LOB.FREETEMPORARY(v_RESP);
	END IF;
END FETCH_SCHEDULE9_10_SUMMARY;
----------------------------------------------------------------------------------------------------
PROCEDURE FETCH_NITS_SUMMARY
	(
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
    p_LOGGER    	IN  OUT MM_LOGGER_ADAPTER,
    p_CRED	  	 	IN	 MEX_CREDENTIALS,
	p_LOG_ONLY   IN  NUMBER,
	p_RECORDS OUT MEX_PJM_NITS_SUMMARY_TBL,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) AS
v_RESP CLOB := NULL;
	v_PARAMS MEX_Util.Parameter_Map := Mex_Switchboard.c_Empty_Parameter_Map;
BEGIN
	v_PARAMS(MEX_PJM.c_Report_Type) := 'Monthly Summary';
  	v_PARAMS(MEX_PJM.c_DEBUG) := g_DEBUG_EXCHANGES;
    v_PARAMS(MEX_PJM.c_Report_Name) := g_ET_NET_TRANS_SERVICE_SUMMARY;
  	p_LOGGER.EXCHANGE_NAME := v_PARAMS(MEX_PJM.c_Report_Name);
  	MEX_PJM.RUN_PJM_BROWSERLESS( v_PARAMS,
  								'esched', -- p_REQUEST_APP
			   					p_LOGGER,
								p_CRED,
								p_BEGIN_DATE,
								p_END_DATE,
                    			'download',  -- p_REQUEST_DIR
                    		    v_RESP,
								p_STATUS,
								p_MESSAGE, p_LOG_ONLY );
	IF p_STATUS = Mex_Switchboard.c_Status_Success THEN
		PARSE_NITS_SUMMARY(v_RESP,p_RECORDS,p_STATUS,p_MESSAGE);
	END IF;
	IF NOT v_RESP IS NULL THEN
	    DBMS_LOB.FREETEMPORARY(v_RESP);
	END IF;
END FETCH_NITS_SUMMARY;
----------------------------------------------------------------------------------------------------
PROCEDURE FETCH_EXPANSION_COST_SUMMARY
	(
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
    p_LOGGER    	IN  OUT MM_LOGGER_ADAPTER,
    p_CRED	  	 	IN	 MEX_CREDENTIALS,
	p_LOG_ONLY   IN  NUMBER,
	p_RECORDS OUT MEX_PJM_NITS_SUMMARY_TBL,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) AS
v_RESP CLOB := NULL;
	v_PARAMS MEX_Util.Parameter_Map := Mex_Switchboard.c_Empty_Parameter_Map;
BEGIN
	v_PARAMS(MEX_PJM.c_Report_Type) := 'Monthly Summary';
  	v_PARAMS(MEX_PJM.c_DEBUG) := g_DEBUG_EXCHANGES;
    v_PARAMS(MEX_PJM.c_Report_Name) := g_ET_EXP_COST_RECOVERY_CHARGES;
  	p_LOGGER.EXCHANGE_NAME := v_PARAMS(MEX_PJM.c_Report_Name);
  	MEX_PJM.RUN_PJM_BROWSERLESS( v_PARAMS,
  								'esched', -- p_REQUEST_APP
			   					p_LOGGER,
								p_CRED,
								p_BEGIN_DATE,
								p_END_DATE,
                    			'download',  -- p_REQUEST_DIR
                    		    v_RESP,
								p_STATUS,
								p_MESSAGE, p_LOG_ONLY );
	IF p_STATUS = Mex_Switchboard.c_Status_Success THEN
		PARSE_EXPANSION_COST_SUMMARY(v_RESP,p_RECORDS,p_STATUS,p_MESSAGE);
	END IF;
	IF NOT v_RESP IS NULL THEN
	    DBMS_LOB.FREETEMPORARY(v_RESP);
	END IF;
END FETCH_EXPANSION_COST_SUMMARY;
----------------------------------------------------------------------------------------------------
PROCEDURE FETCH_REACTIVE_SERV_SUMMARY
	(
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
    p_LOGGER    	IN  OUT MM_LOGGER_ADAPTER,
    p_CRED	  	 	IN	 MEX_CREDENTIALS,
	p_LOG_ONLY   IN  NUMBER,
	p_RECORDS OUT MEX_PJM_REACTIVE_SERV_SUMM_TBL,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) AS
v_RESP CLOB := NULL;
	v_PARAMS MEX_Util.Parameter_Map := Mex_Switchboard.c_Empty_Parameter_Map;
BEGIN
	v_PARAMS(MEX_PJM.c_Report_Type) := 'Ancillary Services';
  	v_PARAMS(MEX_PJM.c_DEBUG) := g_DEBUG_EXCHANGES;
    v_PARAMS(MEX_PJM.c_Report_Name) := g_ET_REACTIVE_SERVICES_SUMMARY;
  	p_LOGGER.EXCHANGE_NAME := v_PARAMS(MEX_PJM.c_Report_Name);
  	MEX_PJM.RUN_PJM_BROWSERLESS( v_PARAMS,
  								'esched', -- p_REQUEST_APP
			   					p_LOGGER,
								p_CRED,
								p_BEGIN_DATE,
								p_END_DATE,
                    			'download',  -- p_REQUEST_DIR
                    		    v_RESP,
								p_STATUS,
								p_MESSAGE, p_LOG_ONLY );
	IF p_STATUS = Mex_Switchboard.c_Status_Success THEN
		PARSE_REACTIVE_SERV_SUMMARY(v_RESP,p_RECORDS,p_STATUS,p_MESSAGE);
	END IF;
	IF NOT v_RESP IS NULL THEN
	    DBMS_LOB.FREETEMPORARY(v_RESP);
	END IF;
END FETCH_REACTIVE_SERV_SUMMARY;
----------------------------------------------------------------------------------------------------
PROCEDURE FETCH_OPER_RES_SUMMARY
	(
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
    p_LOGGER    	IN  OUT MM_LOGGER_ADAPTER,
    p_CRED	  	 	IN	 MEX_CREDENTIALS,
	p_LOG_ONLY   IN  NUMBER,
	p_RECORDS OUT MEX_PJM_OPER_RES_SUMMARY_TBL,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) AS
v_RESP CLOB := NULL;
	v_PARAMS MEX_Util.Parameter_Map := Mex_Switchboard.c_Empty_Parameter_Map;
BEGIN
	v_PARAMS(MEX_PJM.c_Report_Type) := 'Monthly Summary';
  	v_PARAMS(MEX_PJM.c_DEBUG) := g_DEBUG_EXCHANGES;
    v_PARAMS(MEX_PJM.c_Report_Name) := g_ET_OPER_RESERVES_SUMMARY;
  	p_LOGGER.EXCHANGE_NAME := v_PARAMS(MEX_PJM.c_Report_Name);
  	MEX_PJM.RUN_PJM_BROWSERLESS( v_PARAMS,
  								'esched', -- p_REQUEST_APP
			   					p_LOGGER,
								p_CRED,
								p_BEGIN_DATE,
								p_END_DATE,
                    			'download',  -- p_REQUEST_DIR
                    		    v_RESP,
								p_STATUS,
								p_MESSAGE, p_LOG_ONLY );
	IF p_STATUS = Mex_Switchboard.c_Status_Success THEN
		PARSE_OPER_RES_SUMMARY(v_RESP,p_RECORDS,p_STATUS,p_MESSAGE);
	END IF;
	IF NOT v_RESP IS NULL THEN
	    DBMS_LOB.FREETEMPORARY(v_RESP);
	END IF;
END FETCH_OPER_RES_SUMMARY;
----------------------------------------------------------------------------------------------------
PROCEDURE FETCH_OPER_RES_GEN_CREDITS
	(
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
    p_LOGGER    	IN  OUT MM_LOGGER_ADAPTER,
    p_CRED	  	 	IN	 MEX_CREDENTIALS,
	p_LOG_ONLY   IN  NUMBER,
	p_RECORDS OUT MEX_PJM_OPRES_GEN_CREDITS_TBL,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) AS
v_RESP CLOB := NULL;
	v_PARAMS MEX_Util.Parameter_Map := Mex_Switchboard.c_Empty_Parameter_Map;
BEGIN
	v_PARAMS(MEX_PJM.c_Report_Type) := 'Ancillary Services';
  	v_PARAMS(MEX_PJM.c_DEBUG) := g_DEBUG_EXCHANGES;
    v_PARAMS(MEX_PJM.c_Report_Name) := g_ET_DAILY_OPRES_GEN_CREDITS;
  	p_LOGGER.EXCHANGE_NAME := v_PARAMS(MEX_PJM.c_Report_Name);
  	MEX_PJM.RUN_PJM_BROWSERLESS( v_PARAMS,
  								'esched', -- p_REQUEST_APP
			   					p_LOGGER,
								p_CRED,
								p_BEGIN_DATE,
								p_END_DATE,
                    			'download',  -- p_REQUEST_DIR
                    		    v_RESP,
								p_STATUS,
								p_MESSAGE, p_LOG_ONLY );
	IF p_STATUS = Mex_Switchboard.c_Status_Success THEN
		PARSE_OPER_RES_GEN_CREDITS(v_RESP,p_RECORDS,p_STATUS,p_MESSAGE);
	END IF;
	IF NOT v_RESP IS NULL THEN
	    DBMS_LOB.FREETEMPORARY(v_RESP);
	END IF;
END FETCH_OPER_RES_GEN_CREDITS;
----------------------------------------------------------------------------------------------------
PROCEDURE FETCH_OP_RES_LOST_OPP_COST
	(
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
    p_LOGGER    	IN  OUT MM_LOGGER_ADAPTER,
    p_CRED	  	 	IN	 MEX_CREDENTIALS,
	p_LOG_ONLY   IN  NUMBER,
	p_RECORDS OUT MEX_PJM_OP_RES_LOC_TBL,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) AS
	v_RESP CLOB := NULL;
	v_PARAMS MEX_Util.Parameter_Map := Mex_Switchboard.c_Empty_Parameter_Map;
BEGIN
	v_PARAMS(MEX_PJM.c_Report_Type) := 'Ancillary Services';
  	v_PARAMS(MEX_PJM.c_DEBUG) := g_DEBUG_EXCHANGES;
    v_PARAMS(MEX_PJM.c_Report_Name) := g_ET_DLY_OPRES_LOST_OPP;
  	p_LOGGER.EXCHANGE_NAME := v_PARAMS(MEX_PJM.c_Report_Name);
  	MEX_PJM.RUN_PJM_BROWSERLESS( v_PARAMS,
  								'esched', -- p_REQUEST_APP
			   					p_LOGGER,
								p_CRED,
								p_BEGIN_DATE,
								p_END_DATE,
                    			'download',  -- p_REQUEST_DIR
                    		    v_RESP,
								p_STATUS,
								p_MESSAGE, p_LOG_ONLY );
	IF p_STATUS = Mex_Switchboard.c_Status_Success THEN
		PARSE_OP_RES_LOST_OPP_COST(v_RESP,p_RECORDS,p_STATUS,p_MESSAGE);
	END IF;
	IF NOT v_RESP IS NULL THEN
	    DBMS_LOB.FREETEMPORARY(v_RESP);
	END IF;
END FETCH_OP_RES_LOST_OPP_COST;
----------------------------------------------------------------------------------------------------
PROCEDURE FETCH_LOSSES_CHARGES
	(
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_LOGGER   IN  OUT MM_LOGGER_ADAPTER,
    p_CRED	   IN	 MEX_CREDENTIALS,
	p_LOG_ONLY   IN  NUMBER,
	p_RECORDS OUT MEX_PJM_LOSSES_CHARGES_TBL,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) AS
v_RESP CLOB := NULL;
	v_PARAMS MEX_Util.Parameter_Map := Mex_Switchboard.c_Empty_Parameter_Map;
BEGIN
	v_PARAMS(MEX_PJM.c_Report_Type) := 'Monthly Summary';
  	v_PARAMS(MEX_PJM.c_DEBUG) := g_DEBUG_EXCHANGES;
    v_PARAMS(MEX_PJM.c_Report_Name) := g_ET_LOSSES_CHARGES;
  	p_LOGGER.EXCHANGE_NAME := v_PARAMS(MEX_PJM.c_Report_Name);
  	MEX_PJM.RUN_PJM_BROWSERLESS( v_PARAMS,
  								'esched', -- p_REQUEST_APP
			   					p_LOGGER,
								p_CRED,
								p_BEGIN_DATE,
								p_END_DATE,
                    			'download',  -- p_REQUEST_DIR
                    		    v_RESP,
								p_STATUS,
								p_MESSAGE, p_LOG_ONLY );
	IF p_STATUS = Mex_Switchboard.c_Status_Success THEN
		PARSE_LOSSES_CHARGES(v_RESP,p_RECORDS,p_STATUS,p_MESSAGE);
	END IF;
	IF NOT v_RESP IS NULL THEN
	    DBMS_LOB.FREETEMPORARY(v_RESP);
	END IF;
END FETCH_LOSSES_CHARGES;
----------------------------------------------------------------------------------------------------
PROCEDURE FETCH_LOSSES_CREDITS
	(
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_LOGGER   IN  OUT MM_LOGGER_ADAPTER,
    p_CRED	   IN	 MEX_CREDENTIALS,
	p_LOG_ONLY   IN  NUMBER,
	p_RECORDS OUT MEX_PJM_LOSSES_CREDITS_TBL,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) AS
v_RESP CLOB := NULL;
	v_PARAMS MEX_Util.Parameter_Map := Mex_Switchboard.c_Empty_Parameter_Map;
BEGIN
	v_PARAMS(MEX_PJM.c_Report_Type) := 'Monthly Summary';
  	v_PARAMS(MEX_PJM.c_DEBUG) := g_DEBUG_EXCHANGES;
    v_PARAMS(MEX_PJM.c_Report_Name) := g_ET_LOSSES_CREDITS;
  	p_LOGGER.EXCHANGE_NAME := v_PARAMS(MEX_PJM.c_Report_Name);
  	MEX_PJM.RUN_PJM_BROWSERLESS( v_PARAMS,
  								'esched', -- p_REQUEST_APP
			   					p_LOGGER,
								p_CRED,
								p_BEGIN_DATE,
								p_END_DATE,
                    			'download',  -- p_REQUEST_DIR
                    		    v_RESP,
								p_STATUS,
								p_MESSAGE, p_LOG_ONLY );
	IF p_STATUS = Mex_Switchboard.c_Status_Success THEN
		PARSE_LOSSES_CREDITS(v_RESP,p_RECORDS,p_STATUS,p_MESSAGE);
	END IF;
	IF NOT v_RESP IS NULL THEN
	    DBMS_LOB.FREETEMPORARY(v_RESP);
	END IF;
END FETCH_LOSSES_CREDITS;
----------------------------------------------------------------------------------------------------
PROCEDURE FETCH_TRANS_REVNEUT_CHARGES
	(
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_LOGGER   IN  OUT MM_LOGGER_ADAPTER,
    p_CRED	   IN	 MEX_CREDENTIALS,
	p_LOG_ONLY   IN  NUMBER,
	p_RECORDS OUT MEX_PJM_TRANS_REVNEUT_CHG_TBL,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) AS
v_RESP CLOB := NULL;
	v_PARAMS MEX_Util.Parameter_Map := Mex_Switchboard.c_Empty_Parameter_Map;
BEGIN
	v_PARAMS(MEX_PJM.c_Report_Type) := 'Monthly Summary';
  	v_PARAMS(MEX_PJM.c_DEBUG) := g_DEBUG_EXCHANGES;
    v_PARAMS(MEX_PJM.c_Report_Name) := g_ET_TRANS_REVENUE_NEUTRALITY;
  	p_LOGGER.EXCHANGE_NAME := v_PARAMS(MEX_PJM.c_Report_Name);
  	MEX_PJM.RUN_PJM_BROWSERLESS( v_PARAMS,
  								'esched', -- p_REQUEST_APP
			   					p_LOGGER,
								p_CRED,
								p_BEGIN_DATE,
								p_END_DATE,
                    			'download',  -- p_REQUEST_DIR
                    		    v_RESP,
								p_STATUS,
								p_MESSAGE, p_LOG_ONLY );
	IF p_STATUS = Mex_Switchboard.c_Status_Success THEN
		PARSE_TRANS_REVNEUT_CHARGES(v_RESP,p_RECORDS,p_STATUS,p_MESSAGE);
	END IF;
	IF NOT v_RESP IS NULL THEN
	    DBMS_LOB.FREETEMPORARY(v_RESP);
	END IF;
END FETCH_TRANS_REVNEUT_CHARGES;
----------------------------------------------------------------------------------------------------
PROCEDURE FETCH_MONTHLY_CREDIT_ALLOC
	(
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_LOGGER   IN  OUT MM_LOGGER_ADAPTER,
    p_CRED	   IN	 MEX_CREDENTIALS,
	p_LOG_ONLY   IN  NUMBER,
	p_RECORDS OUT MEX_PJM_MONTHLY_CRED_ALLOC_TBL,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) AS
v_RESP CLOB := NULL;
	v_PARAMS MEX_Util.Parameter_Map := Mex_Switchboard.c_Empty_Parameter_Map;
BEGIN
	v_PARAMS(MEX_PJM.c_Report_Type) := 'Monthly Summary';
  	v_PARAMS(MEX_PJM.c_DEBUG) := g_DEBUG_EXCHANGES;
    v_PARAMS(MEX_PJM.c_Report_Name) := g_ET_MONTHLY_CREDIT_ALLOC;
  	p_LOGGER.EXCHANGE_NAME := v_PARAMS(MEX_PJM.c_Report_Name);
  	MEX_PJM.RUN_PJM_BROWSERLESS( v_PARAMS,
  								'esched', -- p_REQUEST_APP
			   					p_LOGGER,
								p_CRED,
								p_BEGIN_DATE,
								p_END_DATE,
                    			'download',  -- p_REQUEST_DIR
                    		    v_RESP,
								p_STATUS,
								p_MESSAGE, p_LOG_ONLY );
	IF p_STATUS = Mex_Switchboard.c_Status_Success THEN
		PARSE_MONTHLY_CREDIT_ALLOC(v_RESP,p_RECORDS,p_STATUS,p_MESSAGE);
	END IF;
	IF NOT v_RESP IS NULL THEN
	    DBMS_LOB.FREETEMPORARY(v_RESP);
	END IF;
END FETCH_MONTHLY_CREDIT_ALLOC;
----------------------------------------------------------------------------------------------------
PROCEDURE FETCH_SYNCH_CONDENS_SUMMARY
	(
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_LOGGER   IN  OUT MM_LOGGER_ADAPTER,
    p_CRED	   IN	 MEX_CREDENTIALS,
	p_LOG_ONLY   IN  NUMBER,
	p_RECORDS OUT MEX_PJM_SYNCH_COND_SUMMARY_TBL,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) AS
v_RESP CLOB := NULL;
	v_PARAMS MEX_Util.Parameter_Map := Mex_Switchboard.c_Empty_Parameter_Map;
BEGIN
	v_PARAMS(MEX_PJM.c_Report_Type) := 'Monthly Summary';
  	v_PARAMS(MEX_PJM.c_DEBUG) := g_DEBUG_EXCHANGES;
    v_PARAMS(MEX_PJM.c_Report_Name) := g_ET_SYNC_CONDENSING_SUMMARY;
  	p_LOGGER.EXCHANGE_NAME := v_PARAMS(MEX_PJM.c_Report_Name);
  	MEX_PJM.RUN_PJM_BROWSERLESS( v_PARAMS,
  								'esched', -- p_REQUEST_APP
			   					p_LOGGER,
								p_CRED,
								p_BEGIN_DATE,
								p_END_DATE,
                    			'download',  -- p_REQUEST_DIR
                    		    v_RESP,
								p_STATUS,
								p_MESSAGE, p_LOG_ONLY );
	IF p_STATUS = Mex_Switchboard.c_Status_Success THEN
		PARSE_SYNCH_CONDENS_SUMMARY(v_RESP,p_RECORDS,p_STATUS,p_MESSAGE);
	END IF;
	IF NOT v_RESP IS NULL THEN
	    DBMS_LOB.FREETEMPORARY(v_RESP);
	END IF;
END FETCH_SYNCH_CONDENS_SUMMARY;
----------------------------------------------------------------------------------------------------
PROCEDURE FETCH_SCHEDULE1A_SUMMARY
	(
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_LOGGER   IN  OUT MM_LOGGER_ADAPTER,
    p_CRED	   IN	 MEX_CREDENTIALS,
	p_LOG_ONLY   IN  NUMBER,
	p_RECORDS OUT MEX_PJM_SCHEDULE1A_SUMMARY_TBL,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) AS
v_RESP CLOB := NULL;
	v_PARAMS MEX_Util.Parameter_Map := Mex_Switchboard.c_Empty_Parameter_Map;
BEGIN
	v_PARAMS(MEX_PJM.c_Report_Type) := 'Monthly Summary';
  	v_PARAMS(MEX_PJM.c_DEBUG) := g_DEBUG_EXCHANGES;
    v_PARAMS(MEX_PJM.c_Report_Name) := g_ET_SCHEDULE_1A_SUMMARY;
  	p_LOGGER.EXCHANGE_NAME := v_PARAMS(MEX_PJM.c_Report_Name);
  	MEX_PJM.RUN_PJM_BROWSERLESS( v_PARAMS,
  								'esched', -- p_REQUEST_APP
			   					p_LOGGER,
								p_CRED,
								p_BEGIN_DATE,
								p_END_DATE,
                    			'download',  -- p_REQUEST_DIR
                    		    v_RESP,
								p_STATUS,
								p_MESSAGE, p_LOG_ONLY );
	IF p_STATUS = Mex_Switchboard.c_Status_Success THEN
		PARSE_SCHEDULE1A_SUMMARY(v_RESP,p_RECORDS,p_STATUS,p_MESSAGE);
	END IF;
	IF NOT v_RESP IS NULL THEN
	    DBMS_LOB.FREETEMPORARY(v_RESP);
	END IF;
END FETCH_SCHEDULE1A_SUMMARY;
----------------------------------------------------------------------------------------------------
PROCEDURE FETCH_REGULATION_SUMMARY
	(
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_LOGGER   IN  OUT MM_LOGGER_ADAPTER,
    p_CRED	   IN	 MEX_CREDENTIALS,
	p_LOG_ONLY   IN  NUMBER,
	p_RECORDS OUT MEX_PJM_REGULATION_SUMMARY_TBL,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) AS
v_RESP CLOB := NULL;
	v_PARAMS MEX_Util.Parameter_Map := Mex_Switchboard.c_Empty_Parameter_Map;
BEGIN
	v_PARAMS(MEX_PJM.c_Report_Type) := 'Monthly Summary';
  	v_PARAMS(MEX_PJM.c_DEBUG) := g_DEBUG_EXCHANGES;
    v_PARAMS(MEX_PJM.c_Report_Name) := g_ET_REGULATION_SUMMARY;
  	p_LOGGER.EXCHANGE_NAME := v_PARAMS(MEX_PJM.c_Report_Name);
  	MEX_PJM.RUN_PJM_BROWSERLESS( v_PARAMS,
  								'esched', -- p_REQUEST_APP
			   					p_LOGGER,
								p_CRED,
								p_BEGIN_DATE,
								p_END_DATE,
                    			'download',  -- p_REQUEST_DIR
                    		    v_RESP,
								p_STATUS,
								p_MESSAGE, p_LOG_ONLY );
	IF p_STATUS = Mex_Switchboard.c_Status_Success THEN
		PARSE_REGULATION_SUMMARY(v_RESP,p_RECORDS,p_STATUS,p_MESSAGE);
	END IF;
	IF NOT v_RESP IS NULL THEN
	    DBMS_LOB.FREETEMPORARY(v_RESP);
	END IF;
END FETCH_REGULATION_SUMMARY;
----------------------------------------------------------------------------------------------------
PROCEDURE FETCH_FTR_TARGET_ALLOCATION
	(
	p_WORK_ID IN NUMBER,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_LOGGER   IN  OUT MM_LOGGER_ADAPTER,
    p_CRED	   IN	 MEX_CREDENTIALS,
	p_LOG_ONLY   IN  NUMBER,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) AS
v_RESP CLOB := NULL;
	v_PARAMS MEX_Util.Parameter_Map := Mex_Switchboard.c_Empty_Parameter_Map;
BEGIN
	v_PARAMS(MEX_PJM.c_Report_Type) := 'Transmission Congestion';
  	v_PARAMS(MEX_PJM.c_DEBUG) := g_DEBUG_EXCHANGES;
    v_PARAMS(MEX_PJM.c_Report_Name) := g_ET_FTR_TARGET_ALLOCATIONS;
  	p_LOGGER.EXCHANGE_NAME := v_PARAMS(MEX_PJM.c_Report_Name);
  	MEX_PJM.RUN_PJM_BROWSERLESS( v_PARAMS,
  								'esched', -- p_REQUEST_APP
			   					p_LOGGER,
								p_CRED,
								p_BEGIN_DATE,
								p_END_DATE,
                    			'download',  -- p_REQUEST_DIR
                    		    v_RESP,
								p_STATUS,
								p_MESSAGE, p_LOG_ONLY );
	IF p_STATUS = Mex_Switchboard.c_Status_Success THEN
		PARSE_FTR_TARGET_ALLOCATION(v_RESP,p_WORK_ID,p_STATUS,p_MESSAGE);
	END IF;
	IF NOT v_RESP IS NULL THEN
	    DBMS_LOB.FREETEMPORARY(v_RESP);
	END IF;
END FETCH_FTR_TARGET_ALLOCATION;
----------------------------------------------------------------------------------------------------
PROCEDURE FETCH_FTR_AUCTION
	(
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_LOGGER   IN  OUT MM_LOGGER_ADAPTER,
    p_CRED	   IN	 MEX_CREDENTIALS,
	p_LOG_ONLY   IN  NUMBER,
	p_RECORDS OUT MEX_PJM_FTR_AUCTION_TBL,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) AS
v_RESP CLOB := NULL;
	v_PARAMS MEX_Util.Parameter_Map := Mex_Switchboard.c_Empty_Parameter_Map;
BEGIN
	v_PARAMS(MEX_PJM.c_Report_Type) := 'Monthly Summary';
  	v_PARAMS(MEX_PJM.c_DEBUG) := g_DEBUG_EXCHANGES;
    v_PARAMS(MEX_PJM.c_Report_Name) := g_ET_FTR_AUCTION;
  	p_LOGGER.EXCHANGE_NAME := v_PARAMS(MEX_PJM.c_Report_Name);
  	MEX_PJM.RUN_PJM_BROWSERLESS( v_PARAMS,
  								'esched', -- p_REQUEST_APP
			   					p_LOGGER,
								p_CRED,
								p_BEGIN_DATE,
								p_END_DATE,
                    			'download',  -- p_REQUEST_DIR
                    		    v_RESP,
								p_STATUS,
								p_MESSAGE, p_LOG_ONLY );
	IF p_STATUS = Mex_Switchboard.c_Status_Success THEN
		PARSE_FTR_AUCTION(v_RESP,p_RECORDS,p_STATUS,p_MESSAGE);
	END IF;
	IF NOT v_RESP IS NULL THEN
	    DBMS_LOB.FREETEMPORARY(v_RESP);
	END IF;
END FETCH_FTR_AUCTION;
----------------------------------------------------------------------------------------------------
PROCEDURE FETCH_BLACK_START_SUMMARY(p_BEGIN_DATE IN DATE,
									p_END_DATE   IN DATE,
									p_LOGGER   IN  OUT MM_LOGGER_ADAPTER,
    								p_CRED	   IN	 MEX_CREDENTIALS,
									p_LOG_ONLY   IN  NUMBER,
									p_RECORDS    OUT MEX_PJM_BLACKSTART_SUMMARY_TBL,
									p_STATUS     OUT NUMBER,
									p_MESSAGE    OUT VARCHAR2) AS
	v_RESP CLOB := NULL;
		v_PARAMS MEX_Util.Parameter_Map := Mex_Switchboard.c_Empty_Parameter_Map;
BEGIN
	v_PARAMS(MEX_PJM.c_Report_Type) := 'Monthly Summary';
  	v_PARAMS(MEX_PJM.c_DEBUG) := g_DEBUG_EXCHANGES;
    v_PARAMS(MEX_PJM.c_Report_Name) := g_ET_BLACK_START_SUMMARY;
  	p_LOGGER.EXCHANGE_NAME := v_PARAMS(MEX_PJM.c_Report_Name);
  	MEX_PJM.RUN_PJM_BROWSERLESS( v_PARAMS,
  								'esched', -- p_REQUEST_APP
			   					p_LOGGER,
								p_CRED,
								p_BEGIN_DATE,
								p_END_DATE,
                    			'download',  -- p_REQUEST_DIR
                    		    v_RESP,
								p_STATUS,
								p_MESSAGE, p_LOG_ONLY );
	IF p_STATUS = Mex_Switchboard.c_Status_Success THEN
		PARSE_BLACK_START_SUMMARY(v_RESP, p_RECORDS, p_STATUS, p_MESSAGE);
	END IF;
	IF NOT v_RESP IS NULL THEN
		DBMS_LOB.FREETEMPORARY(v_RESP);
	END IF;
END FETCH_BLACK_START_SUMMARY;
----------------------------------------------------------------------------------------------------
PROCEDURE FETCH_ARR_SUMMARY(p_BEGIN_DATE IN DATE,
							p_END_DATE   IN DATE,
							p_LOGGER   	 IN  OUT MM_LOGGER_ADAPTER,
    						p_CRED	   	 IN	 MEX_CREDENTIALS,
							p_LOG_ONLY   IN  NUMBER,
							p_RECORDS    OUT MEX_PJM_ARR_SUMMARY_TBL,
							p_STATUS     OUT NUMBER,
							p_MESSAGE    OUT VARCHAR2) AS
	v_RESP CLOB := NULL;
		v_PARAMS MEX_Util.Parameter_Map := Mex_Switchboard.c_Empty_Parameter_Map;
BEGIN
	v_PARAMS(MEX_PJM.c_Report_Type) := 'Monthly Summary';
  	v_PARAMS(MEX_PJM.c_DEBUG) := g_DEBUG_EXCHANGES;
    v_PARAMS(MEX_PJM.c_Report_Name) := g_ET_ARR_SUMMARY;

  	p_LOGGER.EXCHANGE_NAME := v_PARAMS(MEX_PJM.c_Report_Name);
  	MEX_PJM.RUN_PJM_BROWSERLESS( v_PARAMS,
  								'esched', -- p_REQUEST_APP
			   					p_LOGGER,
								p_CRED,
								p_BEGIN_DATE,
								p_END_DATE,
                    			'download',  -- p_REQUEST_DIR
                    		    v_RESP,
								p_STATUS,
								p_MESSAGE, p_LOG_ONLY );
	IF p_STATUS = Mex_Switchboard.c_Status_Success THEN
		PARSE_ARR_SUMMARY(v_RESP, p_RECORDS, p_STATUS, p_MESSAGE);
	END IF;
	IF NOT v_RESP IS NULL THEN
		DBMS_LOB.FREETEMPORARY(v_RESP);
	END IF;
END FETCH_ARR_SUMMARY;
----------------------------------------------------------------------------------------------------
PROCEDURE FETCH_REACTIVE_SUMMARY(p_BEGIN_DATE IN DATE,
							p_END_DATE   IN DATE,
							p_LOGGER   	 IN  OUT MM_LOGGER_ADAPTER,
    						p_CRED	   	 IN	 MEX_CREDENTIALS,
							p_LOG_ONLY   IN  NUMBER,
							p_RECORDS    OUT MEX_PJM_REACTIVE_SUMMARY_TBL,
							p_STATUS     OUT NUMBER,
							p_MESSAGE    OUT VARCHAR2) AS
	v_RESP CLOB := NULL;
		v_PARAMS MEX_Util.Parameter_Map := Mex_Switchboard.c_Empty_Parameter_Map;
BEGIN
	v_PARAMS(MEX_PJM.c_Report_Type) := 'Monthly Summary';
  	v_PARAMS(MEX_PJM.c_DEBUG) := g_DEBUG_EXCHANGES;
    v_PARAMS(MEX_PJM.c_Report_Name) := g_ET_REACTIVE_SUMMARY;
  	p_LOGGER.EXCHANGE_NAME := v_PARAMS(MEX_PJM.c_Report_Name);
  	MEX_PJM.RUN_PJM_BROWSERLESS( v_PARAMS,
  								'esched', -- p_REQUEST_APP
			   					p_LOGGER,
								p_CRED,
								p_BEGIN_DATE,
								p_END_DATE,
                    			'download',  -- p_REQUEST_DIR
                    		    v_RESP,
								p_STATUS,
								p_MESSAGE, p_LOG_ONLY );
	IF p_STATUS = Mex_Switchboard.c_Status_Success THEN
		PARSE_REACTIVE_SUMMARY(v_RESP, p_RECORDS, p_STATUS, p_MESSAGE);
	END IF;
	IF NOT v_RESP IS NULL THEN
		DBMS_LOB.FREETEMPORARY(v_RESP);
	END IF;
END FETCH_REACTIVE_SUMMARY;
----------------------------------------------------------------------------------------------------
PROCEDURE FETCH_EN_IMB_CRE_SUMMARY(p_BEGIN_DATE IN DATE,
							p_END_DATE   IN DATE,
							p_LOGGER   	 IN  OUT MM_LOGGER_ADAPTER,
    						p_CRED	   	 IN	 MEX_CREDENTIALS,
							p_LOG_ONLY   IN  NUMBER,
							p_RECORDS    OUT MEX_PJM_EN_IMB_CRE_SUMMARY_TBL,
							p_STATUS     OUT NUMBER,
							p_MESSAGE    OUT VARCHAR2) AS
	v_RESP CLOB := NULL;
		v_PARAMS MEX_Util.Parameter_Map := Mex_Switchboard.c_Empty_Parameter_Map;
BEGIN
	v_PARAMS(MEX_PJM.c_Report_Type) := 'Monthly Summary';
  	v_PARAMS(MEX_PJM.c_DEBUG) := g_DEBUG_EXCHANGES;
    v_PARAMS(MEX_PJM.c_Report_Name) := g_ET_ENGY_IMBALANCE_CRED_ALLOC;
	p_LOGGER.EXCHANGE_NAME := v_PARAMS(MEX_PJM.c_Report_Name);
  	MEX_PJM.RUN_PJM_BROWSERLESS( v_PARAMS,
  								'esched', -- p_REQUEST_APP
			   					p_LOGGER,
								p_CRED,
								p_BEGIN_DATE,
								p_END_DATE,
                    			'download',  -- p_REQUEST_DIR
                    		    v_RESP,
								p_STATUS,
								p_MESSAGE, p_LOG_ONLY );
	IF p_STATUS = Mex_Switchboard.c_Status_Success THEN
		PARSE_EN_IMB_CRE_SUMMARY(v_RESP, p_RECORDS, p_STATUS, p_MESSAGE);
	END IF;
	IF NOT v_RESP IS NULL THEN
		DBMS_LOB.FREETEMPORARY(v_RESP);
	END IF;
END FETCH_EN_IMB_CRE_SUMMARY;
----------------------------------------------------------------------------------------------------
PROCEDURE FETCH_CAP_CRED_SUMMARY(p_BEGIN_DATE IN DATE,
							p_END_DATE   IN DATE,
							p_LOGGER   	 IN  OUT MM_LOGGER_ADAPTER,
    						p_CRED	   	 IN	 MEX_CREDENTIALS,
							p_LOG_ONLY   IN  NUMBER,
							p_RECORDS    OUT MEX_PJM_CAP_CRED_SUMMARY_TBL,
							p_STATUS     OUT NUMBER,
							p_MESSAGE    OUT VARCHAR2) AS
	v_RESP CLOB := NULL;
		v_PARAMS MEX_Util.Parameter_Map := Mex_Switchboard.c_Empty_Parameter_Map;
BEGIN
	v_PARAMS(MEX_PJM.c_Report_Type) :='Ancillary Services';
  	v_PARAMS(MEX_PJM.c_DEBUG) := g_DEBUG_EXCHANGES;
    v_PARAMS(MEX_PJM.c_Report_Name) := g_ET_CAP_CREDIT_MARKET_SUMMARY;
  	p_LOGGER.EXCHANGE_NAME := v_PARAMS(MEX_PJM.c_Report_Name);
  	MEX_PJM.RUN_PJM_BROWSERLESS( v_PARAMS,
  								'esched', -- p_REQUEST_APP
			   					p_LOGGER,
								p_CRED,
								p_BEGIN_DATE,
								p_END_DATE,
                    			'download',  -- p_REQUEST_DIR
                    		    v_RESP,
								p_STATUS,
								p_MESSAGE, p_LOG_ONLY );
	IF p_STATUS = Mex_Switchboard.c_Status_Success THEN
		PARSE_CAP_CRED_SUMMARY(v_RESP, p_RECORDS, p_STATUS, p_MESSAGE);
	END IF;
	IF NOT v_RESP IS NULL THEN
		DBMS_LOB.FREETEMPORARY(v_RESP);
	END IF;
END FETCH_CAP_CRED_SUMMARY;
----------------------------------------------------------------------------------------------------
PROCEDURE FETCH_SPIN_RES_SUMMARY(p_BEGIN_DATE IN DATE,
									p_END_DATE   IN DATE,
									p_LOGGER   	 IN  OUT MM_LOGGER_ADAPTER,
    								p_CRED	   	 IN	 MEX_CREDENTIALS,
									p_LOG_ONLY   IN  NUMBER,
                                    p_RECORDS    OUT MEX_PJM_SPIN_RES_SUMMARY_TBL,
                                    p_STATUS     OUT NUMBER,
                                    p_MESSAGE    OUT VARCHAR2) AS
	v_RESP CLOB := NULL;
		v_PARAMS MEX_Util.Parameter_Map := Mex_Switchboard.c_Empty_Parameter_Map;
BEGIN
	v_PARAMS(MEX_PJM.c_Report_Type) :='Ancillary Services';
  	v_PARAMS(MEX_PJM.c_DEBUG) := g_DEBUG_EXCHANGES;
    v_PARAMS(MEX_PJM.c_Report_Name) := g_ET_SYNC_RESERVE_SUMMARY;
  	p_LOGGER.EXCHANGE_NAME := v_PARAMS(MEX_PJM.c_Report_Name);
  	MEX_PJM.RUN_PJM_BROWSERLESS( v_PARAMS,
  								'esched', -- p_REQUEST_APP
			   					p_LOGGER,
								p_CRED,
								p_BEGIN_DATE,
								p_END_DATE,
                    			'download',  -- p_REQUEST_DIR
                    		    v_RESP,
								p_STATUS,
								p_MESSAGE, p_LOG_ONLY );
	IF p_STATUS = Mex_Switchboard.c_Status_Success THEN
		PARSE_SPIN_RES_SUMMARY(v_RESP, p_RECORDS, p_STATUS, p_MESSAGE);
	END IF;
	IF NOT v_RESP IS NULL THEN
		DBMS_LOB.FREETEMPORARY(v_RESP);
	END IF;
END FETCH_SPIN_RES_SUMMARY;
----------------------------------------------------------------------------------------------------
PROCEDURE FETCH_EXPLICIT_CONGESTION(p_BEGIN_DATE IN DATE,
									p_END_DATE   IN DATE,
									p_LOGGER   	 IN  OUT MM_LOGGER_ADAPTER,
    								p_CRED	   	 IN	 MEX_CREDENTIALS,
									p_LOG_ONLY   IN  NUMBER,
									p_STATUS     OUT NUMBER,
									p_MESSAGE    OUT VARCHAR2) AS
	v_RESP CLOB := NULL;
		v_PARAMS MEX_Util.Parameter_Map := Mex_Switchboard.c_Empty_Parameter_Map;
BEGIN
	v_PARAMS(MEX_PJM.c_Report_Type) := 'Transmission Congestion';
  	v_PARAMS(MEX_PJM.c_DEBUG) := g_DEBUG_EXCHANGES;
    v_PARAMS(MEX_PJM.c_Report_Name) := g_ET_EXP_CONGESTION_CHARGES;
  	p_LOGGER.EXCHANGE_NAME := v_PARAMS(MEX_PJM.c_Report_Name);
  	MEX_PJM.RUN_PJM_BROWSERLESS( v_PARAMS,
  								'esched', -- p_REQUEST_APP
			   					p_LOGGER,
								p_CRED,
								p_BEGIN_DATE,
								p_END_DATE,
                    			'download',  -- p_REQUEST_DIR
                    		    v_RESP,
								p_STATUS,
								p_MESSAGE, p_LOG_ONLY );
	IF p_STATUS = Mex_Switchboard.c_Status_Success THEN
		PARSE_EXPLICIT_CONGESTION(v_RESP,p_STATUS, p_MESSAGE);
	END IF;
	IF NOT v_RESP IS NULL THEN
		DBMS_LOB.FREETEMPORARY(v_RESP);
	END IF;
END FETCH_EXPLICIT_CONGESTION;
----------------------------------------------------------------------------------------------------
PROCEDURE FETCH_FIRM_TRANS_SERV_CHARGES
	(
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_LOGGER   	 IN  OUT MM_LOGGER_ADAPTER,
    p_CRED	   	 IN	 MEX_CREDENTIALS,
	p_LOG_ONLY   IN  NUMBER,
	p_RECORDS OUT MEX_PJM_TRANS_SERV_CHARGES_TBL,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) AS
v_RESP CLOB := NULL;
	v_PARAMS MEX_Util.Parameter_Map := Mex_Switchboard.c_Empty_Parameter_Map;
BEGIN
	v_PARAMS(MEX_PJM.c_Report_Type) := 'Transmission Service';
  	v_PARAMS(MEX_PJM.c_DEBUG) := g_DEBUG_EXCHANGES;
    v_PARAMS(MEX_PJM.c_Report_Name) := g_ET_FIRM_TRANS_SERVICE_CHAR;
  	p_LOGGER.EXCHANGE_NAME := v_PARAMS(MEX_PJM.c_Report_Name);
  	MEX_PJM.RUN_PJM_BROWSERLESS( v_PARAMS,
  								'esched', -- p_REQUEST_APP
			   					p_LOGGER,
								p_CRED,
								p_BEGIN_DATE,
								p_END_DATE,
                    			'download',  -- p_REQUEST_DIR
                    		    v_RESP,
								p_STATUS,
								p_MESSAGE, p_LOG_ONLY );
	IF p_STATUS = Mex_Switchboard.c_Status_Success THEN
		PARSE_FIRM_TRANS_SERV_CHARGES(v_RESP,p_RECORDS,p_STATUS,p_MESSAGE);
	END IF;
	IF NOT v_RESP IS NULL THEN
	    DBMS_LOB.FREETEMPORARY(v_RESP);
	END IF;
END FETCH_FIRM_TRANS_SERV_CHARGES;
----------------------------------------------------------------------------------------------------
PROCEDURE FETCH_NON_FM_TRANS_SV_CHARGES
	(
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_LOGGER   	 IN  OUT MM_LOGGER_ADAPTER,
    p_CRED	   	 IN	 MEX_CREDENTIALS,
	p_LOG_ONLY   IN  NUMBER,
	p_RECORDS OUT MEX_PJM_NFIRM_TRANS_SV_CHG_TBL,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) AS
v_RESP CLOB := NULL;
	v_PARAMS MEX_Util.Parameter_Map := Mex_Switchboard.c_Empty_Parameter_Map;
BEGIN
	v_PARAMS(MEX_PJM.c_Report_Type) := 'Transmission Service';
  	v_PARAMS(MEX_PJM.c_DEBUG) := g_DEBUG_EXCHANGES;
    v_PARAMS(MEX_PJM.c_Report_Name) := g_ET_NON_FIRM_TRANS_SER_CHAR;
  	p_LOGGER.EXCHANGE_NAME := v_PARAMS(MEX_PJM.c_Report_Name);
  	MEX_PJM.RUN_PJM_BROWSERLESS( v_PARAMS,
  								'esched', -- p_REQUEST_APP
			   					p_LOGGER,
								p_CRED,
								p_BEGIN_DATE,
								p_END_DATE,
                    			'download',  -- p_REQUEST_DIR
                    		    v_RESP,
								p_STATUS,
								p_MESSAGE, p_LOG_ONLY );
	IF p_STATUS = Mex_Switchboard.c_Status_Success THEN
		PARSE_NON_FM_TRANS_SV_CHARGES(v_RESP,p_RECORDS,p_STATUS,p_MESSAGE);
	END IF;
	IF NOT v_RESP IS NULL THEN
	    DBMS_LOB.FREETEMPORARY(v_RESP);
	END IF;
END FETCH_NON_FM_TRANS_SV_CHARGES;
----------------------------------------------------------------------------------------------------
PROCEDURE FETCH_SCHEDULE1_RECONCILE
	(
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_LOGGER   	 IN  OUT MM_LOGGER_ADAPTER,
    p_CRED	   	 IN	 MEX_CREDENTIALS,
	p_LOG_ONLY   IN  NUMBER,
	p_RECORDS OUT MEX_PJM_SCHEDULE1A_SUMMARY_TBL,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) AS
v_RESP CLOB := NULL;
	v_PARAMS MEX_Util.Parameter_Map := Mex_Switchboard.c_Empty_Parameter_Map;
BEGIN
	v_PARAMS(MEX_PJM.c_Report_Type) := 'Reconciliation';
  	v_PARAMS(MEX_PJM.c_DEBUG) := g_DEBUG_EXCHANGES;
    v_PARAMS(MEX_PJM.c_Report_Name) := g_ET_SCHEDULE_1_CHARGES;
  	p_LOGGER.EXCHANGE_NAME := v_PARAMS(MEX_PJM.c_Report_Name);
  	MEX_PJM.RUN_PJM_BROWSERLESS( v_PARAMS,
  								'esched', -- p_REQUEST_APP
			   					p_LOGGER,
								p_CRED,
								p_BEGIN_DATE,
								p_END_DATE,
                    			'download',  -- p_REQUEST_DIR
                    		    v_RESP,
								p_STATUS,
								p_MESSAGE, p_LOG_ONLY );
	IF p_STATUS = Mex_Switchboard.c_Status_Success THEN
		PARSE_SCHEDULE1_RECONCILE(v_RESP,p_RECORDS,p_STATUS,p_MESSAGE);
	END IF;
	IF NOT v_RESP IS NULL THEN
	    DBMS_LOB.FREETEMPORARY(v_RESP);
	END IF;
END FETCH_SCHEDULE1_RECONCILE;
----------------------------------------------------------------------------------------------------
PROCEDURE FETCH_SCHEDULE1A_RECONCILE
	(
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_LOGGER   	 IN  OUT MM_LOGGER_ADAPTER,
    p_CRED	   	 IN	 MEX_CREDENTIALS,
	p_LOG_ONLY   IN  NUMBER,
	p_RECORDS OUT MEX_PJM_SCHEDULE1A_SUMMARY_TBL,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) AS
v_RESP CLOB := NULL;
	v_PARAMS MEX_Util.Parameter_Map := Mex_Switchboard.c_Empty_Parameter_Map;
BEGIN
	v_PARAMS(MEX_PJM.c_Report_Type) := 'Reconciliation';
  	v_PARAMS(MEX_PJM.c_DEBUG) := g_DEBUG_EXCHANGES;
    v_PARAMS(MEX_PJM.c_Report_Name) := g_ET_SCHEDULE_1A_CHARGES;
  	p_LOGGER.EXCHANGE_NAME := v_PARAMS(MEX_PJM.c_Report_Name);
  	MEX_PJM.RUN_PJM_BROWSERLESS( v_PARAMS,
  								'esched', -- p_REQUEST_APP
			   					p_LOGGER,
								p_CRED,
								p_BEGIN_DATE,
								p_END_DATE,
                    			'download',  -- p_REQUEST_DIR
                    		    v_RESP,
								p_STATUS,
								p_MESSAGE, p_LOG_ONLY );
	IF p_STATUS = Mex_Switchboard.c_Status_Success THEN
		PARSE_SCHEDULE1A_RECONCILE(v_RESP,p_RECORDS,p_STATUS,p_MESSAGE);
	END IF;
	IF NOT v_RESP IS NULL THEN
	    DBMS_LOB.FREETEMPORARY(v_RESP);
	END IF;
END FETCH_SCHEDULE1A_RECONCILE;
----------------------------------------------------------------------------------------------------
PROCEDURE FETCH_ENERGY_CHARGES_RECONCIL
	(
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_LOGGER   	 IN  OUT MM_LOGGER_ADAPTER,
    p_CRED	   	 IN	 MEX_CREDENTIALS,
	p_LOG_ONLY   IN  NUMBER,
	p_RECORDS OUT MEX_PJM_RECONCIL_CHARGES_TBL,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) AS
v_RESP CLOB := NULL;
v_REPORT_NAME VARCHAR2(32);
	v_PARAMS MEX_Util.Parameter_Map := Mex_Switchboard.c_Empty_Parameter_Map;
BEGIN

    IF p_BEGIN_DATE >= g_MARGINAL_LOSS_DATE THEN
        v_REPORT_NAME := 'Energy Congestion Losses Charges';
    ELSE
        v_REPORT_NAME := 'Energy Charges';
    END IF;

	v_PARAMS(MEX_PJM.c_Report_Type) := 'Reconciliation';
  	v_PARAMS(MEX_PJM.c_DEBUG) := g_DEBUG_EXCHANGES;
    v_PARAMS(MEX_PJM.c_Report_Name) := v_REPORT_NAME;
  	p_LOGGER.EXCHANGE_NAME := v_PARAMS(MEX_PJM.c_Report_Name);	
  	MEX_PJM.RUN_PJM_BROWSERLESS( v_PARAMS, 
  								'esched', -- p_REQUEST_APP
			   					p_LOGGER, 
								p_CRED, 
								p_BEGIN_DATE, 
								p_END_DATE, 
                    			'download',  -- p_REQUEST_DIR						
                    		    v_RESP, 
								p_STATUS, 
								p_MESSAGE, p_LOG_ONLY );
	IF p_STATUS = Mex_Switchboard.c_Status_Success THEN
		PARSE_ENERGY_CHARGES_RECONCIL(v_RESP,p_RECORDS,p_STATUS,p_MESSAGE);
	END IF;
	IF NOT v_RESP IS NULL THEN
	    DBMS_LOB.FREETEMPORARY(v_RESP);
	END IF;
END FETCH_ENERGY_CHARGES_RECONCIL;
----------------------------------------------------------------------------------------------------
PROCEDURE FETCH_REG_CHARGES_RECONCIL
	(
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_LOGGER   	 IN  OUT MM_LOGGER_ADAPTER,
    p_CRED	   	 IN	 MEX_CREDENTIALS,
	p_LOG_ONLY   IN  NUMBER,
	p_RECORDS OUT MEX_PJM_RECONCIL_CHARGES_TBL,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) AS
v_RESP CLOB := NULL;
	v_PARAMS MEX_Util.Parameter_Map := Mex_Switchboard.c_Empty_Parameter_Map;
BEGIN
	v_PARAMS(MEX_PJM.c_Report_Type) := 'Reconciliation';
  	v_PARAMS(MEX_PJM.c_DEBUG) := g_DEBUG_EXCHANGES;
    v_PARAMS(MEX_PJM.c_Report_Name) := g_ET_REGULATION_CHARGES;
  	p_LOGGER.EXCHANGE_NAME := v_PARAMS(MEX_PJM.c_Report_Name);
  	MEX_PJM.RUN_PJM_BROWSERLESS( v_PARAMS,
  								'esched', -- p_REQUEST_APP
			   					p_LOGGER,
								p_CRED,
								p_BEGIN_DATE,
								p_END_DATE,
                    			'download',  -- p_REQUEST_DIR
                    		    v_RESP,
								p_STATUS,
								p_MESSAGE, p_LOG_ONLY );
	IF p_STATUS = Mex_Switchboard.c_Status_Success THEN
		PARSE_REG_CHARGES_RECONCIL(v_RESP,p_RECORDS,p_STATUS,p_MESSAGE);
	END IF;
	IF NOT v_RESP IS NULL THEN
	    DBMS_LOB.FREETEMPORARY(v_RESP);
	END IF;
END FETCH_REG_CHARGES_RECONCIL;
----------------------------------------------------------------------------------------------------
PROCEDURE FETCH_SPIN_RES_CH_RECONCIL
	(
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_LOGGER   	 IN  OUT MM_LOGGER_ADAPTER,
    p_CRED	   	 IN	 MEX_CREDENTIALS,
	p_LOG_ONLY   IN  NUMBER,
	p_RECORDS OUT MEX_PJM_RECONCIL_CHARGES_TBL,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) AS
v_RESP CLOB := NULL;
	v_PARAMS MEX_Util.Parameter_Map := Mex_Switchboard.c_Empty_Parameter_Map;
BEGIN
	v_PARAMS(MEX_PJM.c_Report_Type) := 'Reconciliation';
  	v_PARAMS(MEX_PJM.c_DEBUG) := g_DEBUG_EXCHANGES;
    v_PARAMS(MEX_PJM.c_Report_Name) := g_ET_SYNC_RESERVE_CHARGES;
  	p_LOGGER.EXCHANGE_NAME := v_PARAMS(MEX_PJM.c_Report_Name);
  	MEX_PJM.RUN_PJM_BROWSERLESS( v_PARAMS,
  								'esched', -- p_REQUEST_APP
			   					p_LOGGER,
								p_CRED,
								p_BEGIN_DATE,
								p_END_DATE,
                    			'download',  -- p_REQUEST_DIR
                    		    v_RESP,
								p_STATUS,
								p_MESSAGE, p_LOG_ONLY );
	IF p_STATUS = Mex_Switchboard.c_Status_Success THEN
		PARSE_SPIN_RES_CH_RECONCIL(v_RESP,p_RECORDS,p_STATUS,p_MESSAGE);
	END IF;
	IF NOT v_RESP IS NULL THEN
	    DBMS_LOB.FREETEMPORARY(v_RESP);
	END IF;
END FETCH_SPIN_RES_CH_RECONCIL;
----------------------------------------------------------------------------------------------------
PROCEDURE FETCH_TRANS_LOSS_CR_RECONCIL
	(
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_LOGGER   	 IN  OUT MM_LOGGER_ADAPTER,
    p_CRED	   	 IN	 MEX_CREDENTIALS,
	p_LOG_ONLY   IN  NUMBER,
	p_RECORDS OUT MEX_PJM_RECONCIL_CHARGES_TBL,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) AS
v_RESP CLOB := NULL;
	v_PARAMS MEX_Util.Parameter_Map := Mex_Switchboard.c_Empty_Parameter_Map;
BEGIN
	v_PARAMS(MEX_PJM.c_Report_Type) := 'Reconciliation';
  	v_PARAMS(MEX_PJM.c_DEBUG) := g_DEBUG_EXCHANGES;
    v_PARAMS(MEX_PJM.c_Report_Name) := g_ET_TRANS_LOSSES_CREDITS;
  	p_LOGGER.EXCHANGE_NAME := v_PARAMS(MEX_PJM.c_Report_Name);
  	MEX_PJM.RUN_PJM_BROWSERLESS( v_PARAMS,
  								'esched', -- p_REQUEST_APP
			   					p_LOGGER,
								p_CRED,
								p_BEGIN_DATE,
								p_END_DATE,
                    			'download',  -- p_REQUEST_DIR
                    		    v_RESP,
								p_STATUS,
								p_MESSAGE, p_LOG_ONLY );
	IF p_STATUS = Mex_Switchboard.c_Status_Success THEN
		PARSE_TRANS_LOSS_CR_RECONCIL(v_RESP,p_RECORDS,p_STATUS,p_MESSAGE);
	END IF;
	IF NOT v_RESP IS NULL THEN
	    DBMS_LOB.FREETEMPORARY(v_RESP);
	END IF;
END FETCH_TRANS_LOSS_CR_RECONCIL;
---------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
PROCEDURE FETCH_EXPLICIT_LOSS(p_BEGIN_DATE IN DATE,
	p_END_DATE   IN DATE,
	p_LOGGER 	 IN OUT NOCOPY MM_LOGGER_ADAPTER,
	p_CRED		 IN MEX_CREDENTIALS,
	p_LOG_ONLY   IN  NUMBER,
	p_STATUS     OUT NUMBER,
	p_MESSAGE    OUT VARCHAR2) AS
		v_RESP CLOB := NULL;
		v_PARAMS MEX_Util.Parameter_Map := Mex_Switchboard.c_Empty_Parameter_Map;
BEGIN
	v_PARAMS(MEX_PJM.c_Report_Type) := 'Transmission Losses';
  	v_PARAMS(MEX_PJM.c_DEBUG) := g_DEBUG_EXCHANGES;
    v_PARAMS(MEX_PJM.c_Report_Name) := g_ET_EXPLICIT_LOSS_SUMMARY;
  	p_LOGGER.EXCHANGE_NAME := v_PARAMS(MEX_PJM.c_Report_Name);
  	MEX_PJM.RUN_PJM_BROWSERLESS( v_PARAMS,
  								'esched', -- p_REQUEST_APP
			   					p_LOGGER,
								p_CRED,
								p_BEGIN_DATE,
								p_END_DATE,
                    			'download',  -- p_REQUEST_DIR
                    		    v_RESP,
								p_STATUS,
								p_MESSAGE, p_LOG_ONLY );
	IF p_STATUS = Mex_Switchboard.c_Status_Success THEN
		PARSE_EXPLICIT_LOSS(v_RESP, p_STATUS, p_MESSAGE);
	END IF;
	IF NOT v_RESP IS NULL THEN
		DBMS_LOB.FREETEMPORARY(v_RESP);
	END IF;
END FETCH_EXPLICIT_LOSS;
----------------------------------------------------------------------------------------------------
PROCEDURE FETCH_TXN_LOSS_CHARGE(p_BEGIN_DATE IN DATE,
    							p_END_DATE   IN DATE,
								p_LOGGER 	 IN OUT NOCOPY MM_LOGGER_ADAPTER,
								p_CRED		 IN MEX_CREDENTIALS,
								p_LOG_ONLY   IN  NUMBER,
    							p_STATUS     OUT NUMBER,
    							p_MESSAGE    OUT VARCHAR2) AS
	v_RESP CLOB := NULL;
		v_PARAMS MEX_Util.Parameter_Map := Mex_Switchboard.c_Empty_Parameter_Map;
BEGIN
	v_PARAMS(MEX_PJM.c_Report_Type) := 'Transmission Losses';
  	v_PARAMS(MEX_PJM.c_DEBUG) := g_DEBUG_EXCHANGES;
    v_PARAMS(MEX_PJM.c_Report_Name) := g_ET_TRANS_LOSS_CHARGE_SUMMARY;
  	p_LOGGER.EXCHANGE_NAME := v_PARAMS(MEX_PJM.c_Report_Name);
  	MEX_PJM.RUN_PJM_BROWSERLESS( v_PARAMS,
  								'esched', -- p_REQUEST_APP
			   					p_LOGGER,
								p_CRED,
								p_BEGIN_DATE,
								p_END_DATE,
                    			'download',  -- p_REQUEST_DIR
                    		    v_RESP,
								p_STATUS,
								p_MESSAGE, p_LOG_ONLY );
	IF p_STATUS = Mex_Switchboard.c_Status_Success THEN
		PARSE_TXN_LOSS_CHARGE(v_RESP, p_STATUS, p_MESSAGE);
	END IF;
	IF NOT v_RESP IS NULL THEN
		DBMS_LOB.FREETEMPORARY(v_RESP);
	END IF;
END FETCH_TXN_LOSS_CHARGE;
----------------------------------------------------------------------------------------------------
PROCEDURE FETCH_TXN_LOSS_CREDIT(p_BEGIN_DATE IN DATE,
    					p_END_DATE   IN DATE,
						p_LOGGER 	 IN OUT NOCOPY MM_LOGGER_ADAPTER,
						p_CRED		 IN MEX_CREDENTIALS,
						p_LOG_ONLY   IN  NUMBER,
    					p_STATUS     OUT NUMBER,
    					p_MESSAGE    OUT VARCHAR2) AS
	v_RESP CLOB := NULL;
		v_PARAMS MEX_Util.Parameter_Map := Mex_Switchboard.c_Empty_Parameter_Map;
BEGIN
	v_PARAMS(MEX_PJM.c_Report_Type) := 'Transmission Losses';
  	v_PARAMS(MEX_PJM.c_DEBUG) := g_DEBUG_EXCHANGES;
    v_PARAMS(MEX_PJM.c_Report_Name) := g_ET_TRANS_LOSS_CREDIT_SUMMARY;
  	p_LOGGER.EXCHANGE_NAME := v_PARAMS(MEX_PJM.c_Report_Name);
  	MEX_PJM.RUN_PJM_BROWSERLESS( v_PARAMS,
  								'esched', -- p_REQUEST_APP
			   					p_LOGGER,
								p_CRED,
								p_BEGIN_DATE,
								p_END_DATE,
                    			'download',  -- p_REQUEST_DIR
                    		    v_RESP,
								p_STATUS,
								p_MESSAGE, p_LOG_ONLY );
	IF p_STATUS = Mex_Switchboard.c_Status_Success THEN
		PARSE_TXN_LOSS_CREDIT(v_RESP, p_STATUS, p_MESSAGE);
	END IF;
	IF NOT v_RESP IS NULL THEN
		DBMS_LOB.FREETEMPORARY(v_RESP);
	END IF;
END FETCH_TXN_LOSS_CREDIT;
----------------------------------------------------------------------------------------------------
PROCEDURE FETCH_ENERGY_RECON
    (
    p_BEGIN_DATE IN DATE,
    p_END_DATE   IN DATE,
	p_LOGGER 	 IN OUT NOCOPY MM_LOGGER_ADAPTER,
	p_CRED		 IN MEX_CREDENTIALS,
	p_LOG_ONLY   IN  NUMBER,
    p_STATUS     OUT NUMBER,
    p_MESSAGE    OUT VARCHAR2) AS
v_RESP CLOB := NULL;
		v_PARAMS MEX_Util.Parameter_Map := Mex_Switchboard.c_Empty_Parameter_Map;
BEGIN
	v_PARAMS(MEX_PJM.c_Report_Type) := 'Reconciliation';
  	v_PARAMS(MEX_PJM.c_DEBUG) := g_DEBUG_EXCHANGES;
    v_PARAMS(MEX_PJM.c_Report_Name) := g_ET_ENGY_CONG_LOSSES_CHARGES;
  	p_LOGGER.EXCHANGE_NAME := v_PARAMS(MEX_PJM.c_Report_Name);
  	MEX_PJM.RUN_PJM_BROWSERLESS( v_PARAMS,
  								'esched', -- p_REQUEST_APP
			   					p_LOGGER,
								p_CRED,
								p_BEGIN_DATE,
								p_END_DATE,
                    			'download',  -- p_REQUEST_DIR
                    		    v_RESP,
								p_STATUS,
								p_MESSAGE, p_LOG_ONLY );
	IF p_STATUS = Mex_Switchboard.c_Status_Success THEN
		PARSE_ENERGY_RECON(v_RESP, p_STATUS, p_MESSAGE);
	END IF;
	IF NOT v_RESP IS NULL THEN
		DBMS_LOB.FREETEMPORARY(v_RESP);
	END IF;
END FETCH_ENERGY_RECON;
----------------------------------------------------------------------------------------------------
PROCEDURE FETCH_INADV_INTERCHG_CHARGE(p_BEGIN_DATE IN DATE,
    						p_END_DATE   IN DATE,
							p_LOGGER 	 IN OUT NOCOPY MM_LOGGER_ADAPTER,
							p_CRED		 IN MEX_CREDENTIALS,
							p_LOG_ONLY   IN  NUMBER,
    						p_STATUS     OUT NUMBER,
    						p_MESSAGE    OUT VARCHAR2) AS
	v_RESP CLOB := NULL;
		v_PARAMS MEX_Util.Parameter_Map := Mex_Switchboard.c_Empty_Parameter_Map;
BEGIN
	v_PARAMS(MEX_PJM.c_Report_Type) := 'Interchange';
  	v_PARAMS(MEX_PJM.c_DEBUG) := g_DEBUG_EXCHANGES;
    v_PARAMS(MEX_PJM.c_Report_Name) := g_ET_INADVERT_INTER_SUMMARY;
  	p_LOGGER.EXCHANGE_NAME := v_PARAMS(MEX_PJM.c_Report_Name);
  	MEX_PJM.RUN_PJM_BROWSERLESS( v_PARAMS,
  								'esched', -- p_REQUEST_APP
			   					p_LOGGER,
								p_CRED,
								p_BEGIN_DATE,
								p_END_DATE,
                    			'download',  -- p_REQUEST_DIR
                    		    v_RESP,
								p_STATUS,
								p_MESSAGE, p_LOG_ONLY );
	IF p_STATUS = Mex_Switchboard.c_Status_Success THEN
-- NEED TO FIX THIS REQUEST
		PARSE_INADV_INTERCHG_CHARGE(v_RESP, p_STATUS, p_MESSAGE);
	END IF;
	IF NOT v_RESP IS NULL THEN
		DBMS_LOB.FREETEMPORARY(v_RESP);
	END IF;
END FETCH_INADV_INTERCHG_CHARGE;
----------------------------------------------------------------------------------------------------
PROCEDURE FETCH_EDC_INADV_ALLOCS(p_BEGIN_DATE IN DATE,
    p_END_DATE   IN DATE,
	p_LOGGER 	 IN OUT NOCOPY MM_LOGGER_ADAPTER,
	p_CRED		 IN MEX_CREDENTIALS,
	p_LOG_ONLY   IN  NUMBER,
    p_STATUS     OUT NUMBER,
    p_MESSAGE    OUT VARCHAR2) AS
	v_RESP CLOB := NULL;
		v_PARAMS MEX_Util.Parameter_Map := Mex_Switchboard.c_Empty_Parameter_Map;
BEGIN
	v_PARAMS(MEX_PJM.c_Report_Type) := 'Interchange';
  	v_PARAMS(MEX_PJM.c_DEBUG) := g_DEBUG_EXCHANGES;
    v_PARAMS(MEX_PJM.c_Report_Name) := g_ET_EDC_INADVERT_ALLOCATIONS;
  	p_LOGGER.EXCHANGE_NAME := v_PARAMS(MEX_PJM.c_Report_Name);
  	MEX_PJM.RUN_PJM_BROWSERLESS( v_PARAMS,
  								'esched', -- p_REQUEST_APP
			   					p_LOGGER,
								p_CRED,
								p_BEGIN_DATE,
								p_END_DATE,
                    			'download',  -- p_REQUEST_DIR
                    		    v_RESP,
								p_STATUS,
								p_MESSAGE, p_LOG_ONLY );
	IF p_STATUS = Mex_Switchboard.c_Status_Success THEN
-- NEED TO FIX THIS REQUEST
		PARSE_EDC_INADV_ALLOCS(v_RESP, p_STATUS, p_MESSAGE);
	END IF;
	IF NOT v_RESP IS NULL THEN
		DBMS_LOB.FREETEMPORARY(v_RESP);
	END IF;
END FETCH_EDC_INADV_ALLOCS;
----------------------------------------------------------------------------------------------------
--not used
PROCEDURE FETCH_LOAD_ESCHED_WWO_LOSSES(p_BEGIN_DATE IN DATE,
    							p_END_DATE   IN DATE,
								p_LOGGER 	 IN OUT NOCOPY MM_LOGGER_ADAPTER,
								p_CRED		 IN MEX_CREDENTIALS,
								p_LOG_ONLY   IN  NUMBER,
    							p_STATUS     OUT NUMBER,
    							p_MESSAGE    OUT VARCHAR2) AS
	v_RESP CLOB := NULL;
		v_PARAMS MEX_Util.Parameter_Map := Mex_Switchboard.c_Empty_Parameter_Map;
BEGIN
	v_PARAMS(MEX_PJM.c_Report_Type) := 'Interchange';
  	v_PARAMS(MEX_PJM.c_DEBUG) := g_DEBUG_EXCHANGES;
    v_PARAMS(MEX_PJM.c_Report_Name) := g_ET_LOAD_ESCHED_W_O_LOSSES;
  	p_LOGGER.EXCHANGE_NAME := v_PARAMS(MEX_PJM.c_Report_Name);
  	MEX_PJM.RUN_PJM_BROWSERLESS( v_PARAMS,
  								'esched', -- p_REQUEST_APP
			   					p_LOGGER,
								p_CRED,
								p_BEGIN_DATE,
								p_END_DATE,
                    			'download',  -- p_REQUEST_DIR
                    		    v_RESP,
								p_STATUS,
								p_MESSAGE, p_LOG_ONLY );
	IF p_STATUS = Mex_Switchboard.c_Status_Success THEN
		PARSE_LOAD_ESCHED_WWO_LOSSES(v_RESP, p_STATUS, p_MESSAGE);
	END IF;
	IF NOT v_RESP IS NULL THEN
		DBMS_LOB.FREETEMPORARY(v_RESP);
	END IF;
END FETCH_LOAD_ESCHED_WWO_LOSSES;
----------------------------------------------------------------------------------------------------
PROCEDURE FETCH_EDC_HRLY_DERATION(p_BEGIN_DATE IN DATE,
    p_END_DATE   IN DATE,
	p_LOGGER 	 IN OUT NOCOPY MM_LOGGER_ADAPTER,
	p_CRED		 IN MEX_CREDENTIALS,
	p_LOG_ONLY   IN  NUMBER,
    p_STATUS     OUT NUMBER,
    p_MESSAGE    OUT VARCHAR2) AS
	v_RESP CLOB := NULL;
		v_PARAMS MEX_Util.Parameter_Map := Mex_Switchboard.c_Empty_Parameter_Map;
BEGIN
	v_PARAMS(MEX_PJM.c_Report_Type) := 'Transmission Losses';
  	v_PARAMS(MEX_PJM.c_DEBUG) := g_DEBUG_EXCHANGES;
    v_PARAMS(MEX_PJM.c_Report_Name) := g_ET_EDC_HOUR_LOSS_DERATION;
  	p_LOGGER.EXCHANGE_NAME := v_PARAMS(MEX_PJM.c_Report_Name);
  	MEX_PJM.RUN_PJM_BROWSERLESS( v_PARAMS,
  								'esched', -- p_REQUEST_APP
			   					p_LOGGER,
								p_CRED,
								p_BEGIN_DATE,
								p_END_DATE,
                    			'download',  -- p_REQUEST_DIR
                    		    v_RESP,
								p_STATUS,
								p_MESSAGE, p_LOG_ONLY );
	IF p_STATUS = Mex_Switchboard.c_Status_Success THEN
		PARSE_EDC_HRLY_DERATION(v_RESP, p_STATUS, p_MESSAGE);
	END IF;
	IF NOT v_RESP IS NULL THEN
		DBMS_LOB.FREETEMPORARY(v_RESP);
	END IF;
END FETCH_EDC_HRLY_DERATION;
----------------------------------------------------------------------------------------------------
PROCEDURE FETCH_LR_MNTHLY_SUMMARY(p_BEGIN_DATE IN DATE,
    p_END_DATE   IN DATE,
 	p_LOGGER 	 IN OUT NOCOPY MM_LOGGER_ADAPTER,
	p_CRED		 IN MEX_CREDENTIALS,
	p_LOG_ONLY   IN  NUMBER,
    p_STATUS     OUT NUMBER,
    p_MESSAGE    OUT VARCHAR2) AS
	v_RESP CLOB := NULL;
		v_PARAMS MEX_Util.Parameter_Map := Mex_Switchboard.c_Empty_Parameter_Map;
BEGIN
	v_PARAMS(MEX_PJM.c_Report_Type) := 'Monthly Summary';
  	v_PARAMS(MEX_PJM.c_DEBUG) := g_DEBUG_EXCHANGES;
    v_PARAMS(MEX_PJM.c_Report_Name) := g_ET_LOAD_RESP_MONTHLY_SUMMARY;
  	p_LOGGER.EXCHANGE_NAME := v_PARAMS(MEX_PJM.c_Report_Name);
  	MEX_PJM.RUN_PJM_BROWSERLESS( v_PARAMS,
  								'esched', -- p_REQUEST_APP
			   					p_LOGGER,
								p_CRED,
								p_BEGIN_DATE,
								p_END_DATE,
                    			'download',  -- p_REQUEST_DIR
                    		    v_RESP,
								p_STATUS,
								p_MESSAGE, p_LOG_ONLY );
	IF p_STATUS = Mex_Switchboard.c_Status_Success THEN
		PARSE_LR_MNTHLY_SUMMARY(v_RESP, p_STATUS, p_MESSAGE);
	END IF;
	IF NOT v_RESP IS NULL THEN
		DBMS_LOB.FREETEMPORARY(v_RESP);
	END IF;
END FETCH_LR_MNTHLY_SUMMARY;
----------------------------------------------------------------------------------------------------
PROCEDURE FETCH_MTR_CORR_CHARGE_SUMM(p_BEGIN_DATE IN DATE,
    p_END_DATE   IN DATE,
	p_LOGGER 	 IN OUT NOCOPY MM_LOGGER_ADAPTER,
	p_CRED		 IN MEX_CREDENTIALS,
	p_LOG_ONLY   IN  NUMBER,
    p_STATUS     OUT NUMBER,
    p_MESSAGE    OUT VARCHAR2) AS
	v_RESP CLOB := NULL;
		v_PARAMS MEX_Util.Parameter_Map := Mex_Switchboard.c_Empty_Parameter_Map;
BEGIN
	v_PARAMS(MEX_PJM.c_Report_Type) := 'Monthly Summary';
  	v_PARAMS(MEX_PJM.c_DEBUG) := g_DEBUG_EXCHANGES;
    v_PARAMS(MEX_PJM.c_Report_Name) := g_ET_METER_CORR_CHARGE_SUMMARY;
  	p_LOGGER.EXCHANGE_NAME := v_PARAMS(MEX_PJM.c_Report_Name);
  	MEX_PJM.RUN_PJM_BROWSERLESS( v_PARAMS,
  								'esched', -- p_REQUEST_APP
			   					p_LOGGER,
								p_CRED,
								p_BEGIN_DATE,
								p_END_DATE,
                    			'download',  -- p_REQUEST_DIR
                    		    v_RESP,
								p_STATUS,
								p_MESSAGE, p_LOG_ONLY );
	IF p_STATUS = Mex_Switchboard.c_Status_Success THEN
		PARSE_MTR_CORR_CHARGE_SUMM(v_RESP, p_STATUS, p_MESSAGE);
	END IF;
	IF NOT v_RESP IS NULL THEN
		DBMS_LOB.FREETEMPORARY(v_RESP);
	END IF;
END FETCH_MTR_CORR_CHARGE_SUMM;
----------------------------------------------------------------------------------------------------
PROCEDURE FETCH_MTR_ALLOC_CHARGE_SUMM(p_BEGIN_DATE IN DATE,
    p_END_DATE   IN DATE,
	p_LOGGER 	 IN OUT NOCOPY MM_LOGGER_ADAPTER,
	p_CRED		 IN MEX_CREDENTIALS,
	p_LOG_ONLY   IN  NUMBER,
    p_STATUS     OUT NUMBER,
    p_MESSAGE    OUT VARCHAR2) AS
	v_RESP CLOB := NULL;
		v_PARAMS MEX_Util.Parameter_Map := Mex_Switchboard.c_Empty_Parameter_Map;
BEGIN
	v_PARAMS(MEX_PJM.c_Report_Type) := 'Monthly Summary';
  	v_PARAMS(MEX_PJM.c_DEBUG) := g_DEBUG_EXCHANGES;
    v_PARAMS(MEX_PJM.c_Report_Name) := G_ET_METER_CORR_ALLOC_CHARGE;
  	p_LOGGER.EXCHANGE_NAME := v_PARAMS(MEX_PJM.c_Report_Name);
  	MEX_PJM.RUN_PJM_BROWSERLESS( v_PARAMS,
  								'esched', -- p_REQUEST_APP
			   					p_LOGGER,
								p_CRED,
								p_BEGIN_DATE,
								p_END_DATE,
                    			'download',  -- p_REQUEST_DIR
                    		    v_RESP,
								p_STATUS,
								p_MESSAGE, p_LOG_ONLY );
	IF p_STATUS = Mex_Switchboard.c_Status_Success THEN
		PARSE_MTR_ALLOC_CHARGE_SUMM(v_RESP, p_STATUS, p_MESSAGE);
	END IF;
	IF NOT v_RESP IS NULL THEN
		DBMS_LOB.FREETEMPORARY(v_RESP);
	END IF;
END FETCH_MTR_ALLOC_CHARGE_SUMM;
----------------------------------------------------------------------------------------------------
PROCEDURE PARSE_SPOT_SUMMARY
	(
	p_CSV IN CLOB,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) AS
v_LINES PARSE_UTIL.BIG_STRING_TABLE_MP;
v_COLS PARSE_UTIL.STRING_TABLE;
v_IDX BINARY_INTEGER;
v_day DATE;
v_DATE DATE;
v_hour NUMBER(2);
v_dst NUMBER(1);
v_cut_date DATE;

BEGIN
    p_STATUS := MEX_UTIL.g_SUCCESS;

	PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_CSV,v_LINES);
	v_IDX := v_LINES.FIRST;
    IF v_LINES.LAST = v_IDX THEN
        p_STATUS := 1;
        RETURN;
    END IF;
	WHILE v_LINES.EXISTS(v_IDX) LOOP
		PARSE_UTIL.TOKENS_FROM_STRING(v_LINES(v_IDX),',',v_COLS);
		IF v_IDX = 1 THEN
			-- skip 1st line - it has column headers for data below
			NULL;
		ELSE
            v_DAY := TO_DATE(v_COLS(2),'MM/DD/YY');
            v_HOUR := TO_NUMBER(v_COLS(3));
            v_DST := TO_NUMBER(v_COLS(4));

            IF v_DST = 1 THEN
             v_cut_date := DATE_TIME_AS_CUT(TO_CHAR(v_DAY, 'YYYY-MM-DD'), v_HOUR || ':00', g_TZ_DST);
            ELSE
             v_cut_date := DATE_TIME_AS_CUT(TO_CHAR(v_DAY, 'YYYY-MM-DD'), v_HOUR || ':00', g_TZ_NODST);
            END IF;
			-- remaining lines contain charge determinant data
            INSERT INTO PJM_SPOT_MARKET_ENERGY_SUMMARY VALUES (v_COLS(1), v_DAY, v_HOUR, v_DST, v_CUT_DATE,
            TO_NUMBER(v_COLS(5)), TO_NUMBER(v_COLS(6)), TO_NUMBER(v_COLS(7)), TO_NUMBER(v_COLS(8)),
            TO_NUMBER(v_COLS(9)), TO_NUMBER(v_COLS(10)), TO_NUMBER(v_COLS(11)));

            -- fill spot mkt table with report data for FERC 668
            v_DATE := TO_DATE(v_COLS(2),'MM/DD/YY') + TO_NUMBER(v_COLS(3))/24;
            IF NVL(TO_NUMBER(v_COLS(4)),0) = 1 THEN
                -- we're in the duplicate hour (fall back)
        		v_DATE := TO_CUT_WITH_OPTIONS(v_DATE + 1/86400, 'EDT', 'B');
        	ELSE
        		v_DATE := TO_CUT_WITH_OPTIONS(v_DATE, 'EDT', 'B');
        	END IF;

          --for Ferc 668 report
            UPDATE PJM_SPOT_MKT_SUMMARY
			   SET DAY                   = TO_DATE(v_COLS(2), 'MM/DD/YY'),
				   HOUR                  = TO_NUMBER(v_COLS(3)),
				   DST_FLAG              = TO_NUMBER(v_COLS(4)),
				   DA_NET_INTERCHANGE    = NVL(TO_NUMBER(v_COLS(5)),0),
				   DA_SPOT_PURCHASE      = NULL,
				   DA_LOAD_WEIGHTED_LMP  = NVL(TO_NUMBER(v_COLS(6)),0),
				   DA_CHARGE             = NVL(TO_NUMBER(v_COLS(7)),0),
				   DA_SPOT_SALE          = NULL,
				   DA_GEN_WEIGHTED_LMP   = NULL,
				   DA_CREDIT             = NULL,
				   RT_NET_INTERCHANGE    = NVL(TO_NUMBER(v_COLS(8)),0),
				   BAL_SPOT_PURCHASE_DEV = NVL(TO_NUMBER(v_COLS(9)),0),
				   BAL_LOAD_WEIGHTED_LMP = NVL(TO_NUMBER(v_COLS(10)),0),
				   BAL_CHARGE            = NVL(TO_NUMBER(v_COLS(11)),0),
				   BAL_SPOT_SALE_DEV     = NULL,
				   BAL_GEN_WEIGHTED_LMP  = NULL,
				   BAL_CREDIT            = NULL
			 WHERE ORG_ID = v_COLS(1)
			   AND CUT_DATE = v_DATE;

			IF SQL%NOTFOUND THEN
				INSERT INTO PJM_SPOT_MKT_SUMMARY
				VALUES (V_COLS(1),
						TO_DATE(V_COLS(2),'MM/DD/YY'),
						TO_NUMBER(V_COLS(3)),NVL(TO_NUMBER(V_COLS(4)),0),
						NVL(TO_NUMBER(V_COLS(5)),0),NULL,
						NVL(TO_NUMBER(V_COLS(6)),0),NVL(TO_NUMBER(V_COLS(7)),0),
						NULL, NULL, NULL,
						NVL(TO_NUMBER(V_COLS(8)),0),NVL(TO_NUMBER(V_COLS(9)),0),
						NVL(TO_NUMBER(V_COLS(10)),0),NVL(TO_NUMBER(V_COLS(11)),0),
						NULL, NULL, NULL, v_DATE);
			END IF;

        END IF;
		v_IDX := v_LINES.NEXT(v_IDX);
    END LOOP;

    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
      p_STATUS := SQLCODE;
      p_MESSAGE := 'Error in MEX_PJM_ESCHED_ML.PARSE_SPOT_SUMMARY: ' || SQLERRM;
END PARSE_SPOT_SUMMARY;
----------------------------------------------------------------------------------------------------
PROCEDURE PARSE_CONGESTION_SUMMARY
	(
	p_CSV IN CLOB,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) AS
v_LINES PARSE_UTIL.BIG_STRING_TABLE_MP;
v_COLS PARSE_UTIL.STRING_TABLE;
v_IDX BINARY_INTEGER;

  v_day DATE;
  v_hour NUMBER(2);
  v_dst NUMBER(1);
  v_cut_date DATE;

BEGIN
    p_STATUS := MEX_UTIL.g_SUCCESS;

	PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_CSV,v_LINES);
	v_IDX := v_LINES.FIRST;
    IF v_LINES.LAST = v_IDX THEN
        p_STATUS := 1;
        RETURN;
    END IF;
	WHILE v_LINES.EXISTS(v_IDX) LOOP
		PARSE_UTIL.TOKENS_FROM_STRING(v_LINES(v_IDX),',',v_COLS);
		IF v_IDX = 1 THEN
			-- skip 1st line - it has column headers for data below
			NULL;
		ELSE
      v_DAY := TO_DATE(v_COLS(2),'MM/DD/YY');
      v_HOUR := TO_NUMBER(v_COLS(3));
      v_DST := TO_NUMBER(v_COLS(4));

      IF v_DST = 1 THEN
         v_cut_date := DATE_TIME_AS_CUT(TO_CHAR(v_DAY, 'YYYY-MM-DD'), v_HOUR || ':00', g_TZ_DST);
      ELSE
         v_cut_date := DATE_TIME_AS_CUT(TO_CHAR(v_DAY, 'YYYY-MM-DD'), v_HOUR || ':00', g_TZ_NODST);
      END IF;

      INSERT INTO PJM_CONGESTION_SUMMARY VALUES (v_COLS(1), v_DAY, v_HOUR, v_DST, v_CUT_DATE,
             TO_NUMBER(v_COLS(5)), TO_NUMBER(v_COLS(6)), TO_NUMBER(v_COLS(7)), TO_NUMBER(v_COLS(8)),
             TO_NUMBER(v_COLS(9)), TO_NUMBER(v_COLS(10)), TO_NUMBER(v_COLS(11)), TO_NUMBER(v_COLS(12)),
             TO_NUMBER(v_COLS(13)), TO_NUMBER(v_COLS(14)), TO_NUMBER(v_COLS(15)), TO_NUMBER(v_COLS(16)),
             TO_NUMBER(v_COLS(17)), TO_NUMBER(v_COLS(18)), TO_NUMBER(v_COLS(19)), TO_NUMBER(v_COLS(20)));

		END IF;
		v_IDX := v_LINES.NEXT(v_IDX);
	END LOOP;

  COMMIT;

  EXCEPTION
    WHEN OTHERS THEN
      p_STATUS := SQLCODE;
      p_MESSAGE := 'Error in MEX_PJM_ESCHED_ML.PARSE_CONGESTION_SUMMARY: ' || SQLERRM;
END PARSE_CONGESTION_SUMMARY;
----------------------------------------------------------------------------------------------------
PROCEDURE PARSE_EXPLICIT_CONGESTION(p_CSV     IN CLOB,
																 p_STATUS  OUT NUMBER,
																 p_MESSAGE OUT VARCHAR2) AS
	v_LINES PARSE_UTIL.BIG_STRING_TABLE_MP;
	v_COLS  PARSE_UTIL.STRING_TABLE;
	v_IDX   BINARY_INTEGER;

  v_day DATE;
  v_hour NUMBER(2);
  v_dst NUMBER(1);
  v_cut_date DATE;
BEGIN
	p_STATUS := MEX_UTIL.g_SUCCESS;

	PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_CSV, v_LINES);
	v_IDX     := v_LINES.FIRST;
    IF v_LINES.LAST = v_IDX THEN
        p_STATUS := 1;
        RETURN;
    END IF;

	WHILE v_LINES.EXISTS(v_IDX) LOOP
		PARSE_UTIL.PARSE_DELIMITED_STRING(v_LINES(v_IDX), ',', v_COLS);
		IF v_IDX = 1 THEN
			-- skip 1st line - it has column headers for data below
			NULL;
		ELSE
      v_DAY := TO_DATE(v_COLS(2),'MM/DD/YY');
      v_HOUR := TO_NUMBER(v_COLS(3));
      v_DST := TO_NUMBER(v_COLS(4));

      IF v_DST = 1 THEN
         v_cut_date := DATE_TIME_AS_CUT(TO_CHAR(v_DAY, 'YYYY-MM-DD'), v_HOUR || ':00', g_TZ_DST);
      ELSE
         v_cut_date := DATE_TIME_AS_CUT(TO_CHAR(v_DAY, 'YYYY-MM-DD'), v_HOUR || ':00', g_TZ_NODST);
      END IF;

      INSERT INTO PJM_EXPLICIT_CONG_CHARGES VALUES (
             v_COLS(1),
             v_DAY,
             v_HOUR,
             v_DST,
             v_CUT_DATE,
             v_COLS(5),
             v_COLS(6),
             v_COLS(7),
             v_COLS(8),
             v_COLS(9),
             v_COLS(10),
             v_COLS(11),
             TO_NUMBER(v_COLS(12)),
             TO_NUMBER(v_COLS(13)),
             TO_NUMBER(v_COLS(14)),
             TO_NUMBER(v_COLS(15)),
             TO_NUMBER(v_COLS(16)),
             TO_NUMBER(v_COLS(17)),
             TO_NUMBER(v_COLS(18)),
             TO_NUMBER(v_COLS(19)),
             TO_NUMBER(v_COLS(20)));

		END IF;
		v_IDX := v_LINES.NEXT(v_IDX);
	END LOOP;

  COMMIT;
EXCEPTION
	WHEN OTHERS THEN
		p_STATUS  := SQLCODE;
		p_MESSAGE := 'Error in MEX_PJM_ESCHED_ML.PARSE_EXPLICIT_CONGESTION: ' ||
								 SQLERRM;
END PARSE_EXPLICIT_CONGESTION;
----------------------------------------------------------------------------------------------------
PROCEDURE PARSE_TXN_LOSS_CHARGE
	(
	p_CSV IN CLOB,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) AS
v_LINES PARSE_UTIL.BIG_STRING_TABLE_MP;
v_COLS PARSE_UTIL.STRING_TABLE;
v_IDX BINARY_INTEGER;

  v_day DATE;
  v_hour NUMBER(2);
  v_dst NUMBER(1);
  v_cut_date DATE;

BEGIN
  p_STATUS := MEX_UTIL.g_SUCCESS;

	PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_CSV,v_LINES);
	v_IDX := v_LINES.FIRST;
    IF v_LINES.LAST = v_IDX THEN
        p_STATUS := 1;
        RETURN;
    END IF;
	WHILE v_LINES.EXISTS(v_IDX) LOOP
		PARSE_UTIL.TOKENS_FROM_STRING(v_LINES(v_IDX),',',v_COLS);
		IF v_IDX = 1 THEN
			-- skip 1st line - it has column headers for data below
			NULL;
		ELSIF TRIM(v_COLS(1)) = 'org_id' THEN
            -- repeating headers throughout file
            NULL;

        ELSE

      v_DAY := TO_DATE(v_COLS(2),'MM/DD/YY');
      v_HOUR := TO_NUMBER(v_COLS(3));
      v_DST := TO_NUMBER(v_COLS(4));

      IF v_DST = 1 THEN
         v_cut_date := DATE_TIME_AS_CUT(TO_CHAR(v_DAY, 'YYYY-MM-DD'), v_HOUR || ':00', g_TZ_DST);
      ELSE
         v_cut_date := DATE_TIME_AS_CUT(TO_CHAR(v_DAY, 'YYYY-MM-DD'), v_HOUR || ':00', g_TZ_NODST);
      END IF;

      INSERT INTO PJM_TXN_LOSS_CHARGE_SUMMARY VALUES
             (v_COLS(1),
             v_DAY,
             v_HOUR,
             v_DST,
             v_CUT_DATE,
             TO_NUMBER(v_COLS(5)),
             TO_NUMBER(v_COLS(6)),
             TO_NUMBER(v_COLS(7)),
             TO_NUMBER(v_COLS(8)),
             TO_NUMBER(v_COLS(9)),
             TO_NUMBER(v_COLS(10)),
             TO_NUMBER(v_COLS(11)),
             TO_NUMBER(v_COLS(12)),
             TO_NUMBER(v_COLS(13)),
             TO_NUMBER(v_COLS(14)),
             TO_NUMBER(v_COLS(15)),
             TO_NUMBER(v_COLS(16)));

		END IF;
		v_IDX := v_LINES.NEXT(v_IDX);
	END LOOP;

  COMMIT;

  EXCEPTION
    WHEN OTHERS THEN
      p_STATUS := SQLCODE;
      p_MESSAGE := 'Error in MEX_PJM_ESCHED_ML.PARSE_TXN_LOSS_SUMM: ' || SQLERRM;
END PARSE_TXN_LOSS_CHARGE;
----------------------------------------------------------------------------------------------------
PROCEDURE PARSE_EXPLICIT_LOSS(p_CSV     IN CLOB,
																 p_STATUS  OUT NUMBER,
																 p_MESSAGE OUT VARCHAR2) AS
	v_LINES PARSE_UTIL.BIG_STRING_TABLE_MP;
	v_COLS  PARSE_UTIL.STRING_TABLE;
	v_IDX   BINARY_INTEGER;

  v_day DATE;
  v_hour NUMBER(2);
  v_dst NUMBER(1);
  v_cut_date DATE;
BEGIN
	p_STATUS := MEX_UTIL.g_SUCCESS;

	PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_CSV, v_LINES);

	v_IDX     := v_LINES.FIRST;
    IF v_LINES.LAST = v_IDX THEN
        p_STATUS := 1;
        RETURN;
    END IF;

	WHILE v_LINES.EXISTS(v_IDX) LOOP
		PARSE_UTIL.PARSE_DELIMITED_STRING(v_LINES(v_IDX), ',', v_COLS);
		IF v_IDX = 1 THEN
			-- skip 1st line - it has column headers for data below
			NULL;
		ELSIF TRIM(v_COLS(1)) = 'org_id' THEN
            -- repeating headers throughout file
            NULL;
        ELSE
      v_DAY := TO_DATE(v_COLS(2),'MM/DD/YY');
      v_HOUR := TO_NUMBER(v_COLS(3));
      v_DST := TO_NUMBER(v_COLS(4));

      IF v_DST = 1 THEN
         v_cut_date := DATE_TIME_AS_CUT(TO_CHAR(v_DAY, 'YYYY-MM-DD'), v_HOUR || ':00', g_TZ_DST);
      ELSE
         v_cut_date := DATE_TIME_AS_CUT(TO_CHAR(v_DAY, 'YYYY-MM-DD'), v_HOUR || ':00', g_TZ_NODST);
      END IF;

      INSERT INTO PJM_EXPLICIT_LOSS_CHARGES VALUES (
             v_COLS(1),
             v_DAY,
             v_HOUR,
             v_DST,
             v_CUT_DATE,
             v_COLS(5),
             v_COLS(6),
             v_COLS(7),
             v_COLS(8),
             v_COLS(9),
             v_COLS(10),
             v_COLS(11),
             TO_NUMBER(v_COLS(12)),
             TO_NUMBER(v_COLS(13)),
             TO_NUMBER(v_COLS(14)),
             TO_NUMBER(v_COLS(15)),
             TO_NUMBER(v_COLS(16)),
             TO_NUMBER(v_COLS(17)),
             TO_NUMBER(v_COLS(18)),
             TO_NUMBER(v_COLS(19)),
             TO_NUMBER(v_COLS(20)));

		END IF;
		v_IDX := v_LINES.NEXT(v_IDX);
	END LOOP;

  COMMIT;
EXCEPTION
	WHEN OTHERS THEN
		p_STATUS  := SQLCODE;
		p_MESSAGE := 'Error in MEX_PJM_ESCHED_ML.PARSE_EXPLICIT_LOSS: ' ||
								 SQLERRM;
END PARSE_EXPLICIT_LOSS;
----------------------------------------------------------------------------------------------------
PROCEDURE PARSE_TXN_LOSS_CREDIT
	(
	p_CSV IN CLOB,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) AS
v_LINES PARSE_UTIL.BIG_STRING_TABLE_MP;
v_COLS PARSE_UTIL.STRING_TABLE;
v_IDX BINARY_INTEGER;

  v_day DATE;
  v_hour NUMBER(2);
  v_dst NUMBER(1);
  v_cut_date DATE;

BEGIN
  p_STATUS := MEX_UTIL.g_SUCCESS;

	PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_CSV,v_LINES);
	v_IDX := v_LINES.FIRST;
    IF v_LINES.LAST = v_IDX THEN
        p_STATUS := 1;
        RETURN;
    END IF;
	WHILE v_LINES.EXISTS(v_IDX) LOOP
		PARSE_UTIL.TOKENS_FROM_STRING(v_LINES(v_IDX),',',v_COLS);
		IF v_IDX = 1 THEN
			-- skip 1st line - it has column headers for data below
			NULL;
		ELSIF TRIM(v_COLS(1)) = 'org_id' THEN
            -- repeating headers throughout file
            NULL;
        ELSE
      v_DAY := TO_DATE(v_COLS(2),'MM/DD/YY');
      v_HOUR := TO_NUMBER(v_COLS(3));
      v_DST := TO_NUMBER(v_COLS(4));

      IF v_DST = 1 THEN
         v_cut_date := DATE_TIME_AS_CUT(TO_CHAR(v_DAY, 'YYYY-MM-DD'), v_HOUR || ':00', g_TZ_DST);
      ELSE
         v_cut_date := DATE_TIME_AS_CUT(TO_CHAR(v_DAY, 'YYYY-MM-DD'), v_HOUR || ':00', g_TZ_NODST);
      END IF;

      INSERT INTO PJM_TXN_LOSS_CREDIT_SUMMARY VALUES
             (v_COLS(1),
             v_DAY,
             v_HOUR,
             v_DST,
             v_CUT_DATE,
             TO_NUMBER(v_COLS(5)),
             TO_NUMBER(v_COLS(6)),
             TO_NUMBER(v_COLS(7)),
             TO_NUMBER(v_COLS(8)),
             TO_NUMBER(v_COLS(9)));

		END IF;
		v_IDX := v_LINES.NEXT(v_IDX);
	END LOOP;

  COMMIT;

  EXCEPTION
    WHEN OTHERS THEN
      p_STATUS := SQLCODE;
      p_MESSAGE := 'Error in MEX_PJM_ESCHED_ML.PARSE_TXN_LOSS_SUMM: ' || SQLERRM;
END PARSE_TXN_LOSS_CREDIT;
----------------------------------------------------------------------------------------------------
PROCEDURE PARSE_ENERGY_RECON
	(
	p_CSV IN CLOB,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) AS
v_LINES PARSE_UTIL.BIG_STRING_TABLE_MP;
v_COLS PARSE_UTIL.STRING_TABLE;
v_IDX BINARY_INTEGER;

  v_day DATE;
  v_hour NUMBER(2);
  v_dst NUMBER(1);
  v_cut_date DATE;

BEGIN
  p_STATUS := MEX_UTIL.g_SUCCESS;

	PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_CSV,v_LINES);
	v_IDX := v_LINES.FIRST;
    IF v_LINES.LAST = v_IDX THEN
        p_STATUS := 1;
        RETURN;
    END IF;
	WHILE v_LINES.EXISTS(v_IDX) LOOP
		PARSE_UTIL.TOKENS_FROM_STRING(v_LINES(v_IDX),',',v_COLS);
		IF v_IDX = 1 THEN
			-- skip 1st line - it has column headers for data below
			NULL;
		ELSE
      v_DAY := TO_DATE(v_COLS(2),'MM/DD/YY');
      v_HOUR := TO_NUMBER(v_COLS(3));
      v_DST := TO_NUMBER(v_COLS(4));

      IF v_DST = 1 THEN
         v_cut_date := DATE_TIME_AS_CUT(TO_CHAR(v_DAY, 'YYYY-MM-DD'), v_HOUR || ':00', g_TZ_DST);
      ELSE
         v_cut_date := DATE_TIME_AS_CUT(TO_CHAR(v_DAY, 'YYYY-MM-DD'), v_HOUR || ':00', g_TZ_NODST);
      END IF;

      INSERT INTO PJM_ENG_CONG_LOSSES_CHRGS_RCN VALUES
             (v_COLS(1),
             v_DAY,
             v_HOUR,
             v_DST,
             v_CUT_DATE,
             v_COLS(5),
             v_COLS(6),
             TO_NUMBER(v_COLS(7)),
             v_COLS(8),
             TO_NUMBER(v_COLS(9)),
             TO_NUMBER(v_COLS(10)),
             TO_NUMBER(v_COLS(11)),
             TO_NUMBER(v_COLS(12)),
             TO_NUMBER(v_COLS(13)),
             TO_NUMBER(v_COLS(14)));

		END IF;
		v_IDX := v_LINES.NEXT(v_IDX);
	END LOOP;

  COMMIT;

  EXCEPTION
    WHEN OTHERS THEN
      p_STATUS := SQLCODE;
      p_MESSAGE := 'Error in MEX_PJM_ESCHED_ML.PARSE_ENERGY_RECON: ' || SQLERRM;
END PARSE_ENERGY_RECON;
----------------------------------------------------------------------------------------------------
PROCEDURE PARSE_INADV_INTERCHG_CHARGE
	(
	p_CSV IN CLOB,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) AS
v_LINES PARSE_UTIL.BIG_STRING_TABLE_MP;
v_COLS PARSE_UTIL.STRING_TABLE;
v_IDX BINARY_INTEGER;

  v_day DATE;
  v_hour NUMBER(2);
  v_dst NUMBER(1);
  v_cut_date DATE;

BEGIN
  p_STATUS := MEX_UTIL.g_SUCCESS;

	PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_CSV,v_LINES);
	v_IDX := v_LINES.FIRST;
    IF v_LINES.LAST = v_IDX THEN
        p_STATUS := 1;
        RETURN;
    END IF;
	WHILE v_LINES.EXISTS(v_IDX) LOOP
		PARSE_UTIL.TOKENS_FROM_STRING(v_LINES(v_IDX),',',v_COLS);
		IF v_IDX = 1 THEN
			-- skip 1st line - it has column headers for data below
			NULL;
		ELSE
      v_DAY := TO_DATE(v_COLS(2),'MM/DD/YY');
      v_HOUR := TO_NUMBER(v_COLS(3));
      v_DST := TO_NUMBER(v_COLS(4));

      IF v_DST = 1 THEN
         v_cut_date := DATE_TIME_AS_CUT(TO_CHAR(v_DAY, 'YYYY-MM-DD'), v_HOUR || ':00', g_TZ_DST);
      ELSE
         v_cut_date := DATE_TIME_AS_CUT(TO_CHAR(v_DAY, 'YYYY-MM-DD'), v_HOUR || ':00', g_TZ_NODST);
      END IF;

      INSERT INTO PJM_INADV_INTERCHG_CHARGE_SUM VALUES
             (v_COLS(1),
             v_DAY,
             v_HOUR,
             v_DST,
             v_CUT_DATE,
             TO_NUMBER(v_COLS(5)),
             TO_NUMBER(v_COLS(6)),
             TO_NUMBER(v_COLS(7)),
             TO_NUMBER(v_COLS(8)),
             TO_NUMBER(v_COLS(9)),
             TO_NUMBER(v_COLS(10)),
             TO_NUMBER(v_COLS(11)),
             TO_NUMBER(v_COLS(12)),
             TO_NUMBER(v_COLS(13)));

		END IF;
		v_IDX := v_LINES.NEXT(v_IDX);
	END LOOP;

  COMMIT;

  EXCEPTION
    WHEN OTHERS THEN
      p_STATUS := SQLCODE;
      p_MESSAGE := 'Error in MEX_PJM_ESCHED_ML.PARSE_INADV_INTERCHG_CHARGE: ' || SQLERRM;
END PARSE_INADV_INTERCHG_CHARGE;
----------------------------------------------------------------------------------------------------
PROCEDURE PARSE_EDC_INADV_ALLOCS
	(
	p_CSV IN CLOB,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) AS
v_LINES PARSE_UTIL.BIG_STRING_TABLE_MP;
v_COLS PARSE_UTIL.STRING_TABLE;
v_IDX BINARY_INTEGER;

  v_day DATE;
  v_hour NUMBER(2);
  v_dst NUMBER(1);
  v_cut_date DATE;

BEGIN
  p_STATUS := MEX_UTIL.g_SUCCESS;

	PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_CSV,v_LINES);
	v_IDX := v_LINES.FIRST;
	WHILE v_LINES.EXISTS(v_IDX) LOOP
		PARSE_UTIL.TOKENS_FROM_STRING(v_LINES(v_IDX),',',v_COLS);
		IF v_IDX = 1 THEN
			-- skip 1st line - it has column headers for data below
			NULL;
		ELSE
      v_DAY := TO_DATE(v_COLS(2),'MM/DD/YY');
      v_HOUR := TO_NUMBER(v_COLS(3));
      v_DST := TO_NUMBER(v_COLS(4));

      IF v_DST = 1 THEN
         v_cut_date := DATE_TIME_AS_CUT(TO_CHAR(v_DAY, 'YYYY-MM-DD'), v_HOUR || ':00', g_TZ_DST);
      ELSE
         v_cut_date := DATE_TIME_AS_CUT(TO_CHAR(v_DAY, 'YYYY-MM-DD'), v_HOUR || ':00', g_TZ_NODST);
      END IF;

      INSERT INTO PJM_EDC_INADVRT_ALLOCATIONS VALUES
             (v_COLS(1),
             v_DAY,
             v_HOUR,
             v_DST,
             v_CUT_DATE,
             TO_NUMBER(v_COLS(5)),
             TO_NUMBER(v_COLS(6)),
             TO_NUMBER(v_COLS(7)),
             TO_NUMBER(v_COLS(8)));

		END IF;
		v_IDX := v_LINES.NEXT(v_IDX);
	END LOOP;

  COMMIT;

  EXCEPTION
    WHEN OTHERS THEN
      p_STATUS := SQLCODE;
      p_MESSAGE := 'Error in MEX_PJM_ESCHED_ML.PARSE_EDC_INADV_ALLOCS: ' || SQLERRM;
END PARSE_EDC_INADV_ALLOCS;
----------------------------------------------------------------------------------------------------
PROCEDURE PARSE_LOAD_ESCHED_WWO_LOSSES
	(
	p_CSV IN CLOB,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) AS
v_LINES PARSE_UTIL.BIG_STRING_TABLE_MP;
v_COLS PARSE_UTIL.STRING_TABLE;
v_IDX BINARY_INTEGER;

  v_HR24 NUMBER(10,6) := NULL; -- DON'T INCLUDE HR 24 FOR 'SPRING-AHEAD'
  v_HR25 NUMBER(10,6) := NULL; -- DO INCLUDE HR 25 FOR 'FALL-BACK'
  v_TOTAL NUMBER(16, 6) := NULL;

  v_POS1 NUMBER(9);
  v_POS2 NUMBER(9);

  v_DATE_STR VARCHAR2(24);
  v_DATE DATE;

BEGIN
    p_STATUS := MEX_UTIL.g_SUCCESS;

	PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_CSV,v_LINES);
	v_IDX := v_LINES.FIRST;
	WHILE v_LINES.EXISTS(v_IDX) LOOP
		PARSE_UTIL.TOKENS_FROM_STRING(v_LINES(v_IDX),',',v_COLS);
		IF v_IDX = 1 OR v_IDX = 3 THEN
			-- skip 1st line - it has column headers for data below
			NULL;
    ELSIF v_IDX = 2 THEN
       v_POS1 := INSTR(UPPER(v_LINES(v_IDX)), 'FOR') + 4;
       v_POS2 := INSTR(UPPER(v_LINES(v_IDX)), ' ', v_POS1);

       v_DATE_STR := SUBSTR(v_LINES(v_IDX), v_POS1, v_POS2-v_POS1);
       v_DATE := TO_DATE(v_DATE_STR,'MM\DD\YYYY');
		ELSE

       IF v_COLS.EXISTS(1) AND v_COLS.EXISTS(2) AND v_COLS(1) IS NOT NULL AND v_COLS(2) IS NOT NULL THEN

         IF DST_SPRING_AHEAD_DATE(v_DATE) = v_DATE THEN
            v_HR25 := TO_NUMBER(v_COLS(30));
            v_TOTAL := TO_NUMBER(v_COLS(31));
         ELSE
            v_TOTAL := TO_NUMBER(v_COLS(30));
         END IF;

         v_HR24 := TO_NUMBER(v_COLS(29));

        INSERT INTO PJM_LOAD_ESCHED_WITH_WO_LOSSES VALUES
               (v_COLS(1),
               v_COLS(2),
               v_COLS(3),
               v_COLS(4),
               v_COLS(5),
               v_DATE,
               TO_NUMBER(v_COLS(6)),
               TO_NUMBER(v_COLS(7)),
               TO_NUMBER(v_COLS(8)),
               TO_NUMBER(v_COLS(9)),
               TO_NUMBER(v_COLS(10)),
               TO_NUMBER(v_COLS(11)),
               TO_NUMBER(v_COLS(12)),
               TO_NUMBER(v_COLS(13)),
               TO_NUMBER(v_COLS(14)),
               TO_NUMBER(v_COLS(15)),
               TO_NUMBER(v_COLS(16)),
               TO_NUMBER(v_COLS(17)),
               TO_NUMBER(v_COLS(18)),
               TO_NUMBER(v_COLS(19)),
               TO_NUMBER(v_COLS(20)),
               TO_NUMBER(v_COLS(21)),
               TO_NUMBER(v_COLS(22)),
               TO_NUMBER(v_COLS(23)),
               TO_NUMBER(v_COLS(24)),
               TO_NUMBER(v_COLS(25)),
               TO_NUMBER(v_COLS(26)),
               TO_NUMBER(v_COLS(27)),
               TO_NUMBER(v_COLS(28)),
               v_HR24,
               v_HR25,
               v_TOTAL);
          END IF;

		END IF;
		v_IDX := v_LINES.NEXT(v_IDX);
	END LOOP;

    COMMIT;

  EXCEPTION
    WHEN OTHERS THEN
      p_STATUS := SQLCODE;
      p_MESSAGE := 'Error in MEX_PJM_ESCHED_ML.PARSE_LOAD_ESCHED_WWO_LOSSES: ' || SQLERRM;
END PARSE_LOAD_ESCHED_WWO_LOSSES;
----------------------------------------------------------------------------------------------------
PROCEDURE PARSE_EDC_HRLY_DERATION
	(
	p_CSV IN CLOB,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) AS
v_LINES PARSE_UTIL.BIG_STRING_TABLE_MP;
v_COLS PARSE_UTIL.STRING_TABLE;
v_IDX BINARY_INTEGER;

  v_day DATE;
  v_hour NUMBER(2);
  v_dst NUMBER(1);
  v_cut_date DATE;

BEGIN
  p_STATUS := MEX_UTIL.g_SUCCESS;

	PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_CSV,v_LINES);
	v_IDX := v_LINES.FIRST;
	WHILE v_LINES.EXISTS(v_IDX) LOOP
		PARSE_UTIL.TOKENS_FROM_STRING(v_LINES(v_IDX),',',v_COLS);
		IF v_IDX = 1 THEN
			-- skip 1st line - it has column headers for data below
			NULL;
		ELSE
      v_DAY := TO_DATE(v_COLS(1),'MM/DD/YY');
      v_HOUR := TO_NUMBER(v_COLS(2));
      v_DST := TO_NUMBER(v_COLS(3));

      IF v_DST = 1 THEN
         v_cut_date := DATE_TIME_AS_CUT(TO_CHAR(v_DAY, 'YYYY-MM-DD'), v_HOUR || ':00', g_TZ_DST);
      ELSE
         v_cut_date := DATE_TIME_AS_CUT(TO_CHAR(v_DAY, 'YYYY-MM-DD'), v_HOUR || ':00', g_TZ_NODST);
      END IF;

      INSERT INTO PJM_EDC_HRLY_LOSS_DER_FACTOR VALUES
             (
             v_DAY,
             v_HOUR,
             v_DST,
             v_CUT_DATE,
             v_COLS(4),
             TO_NUMBER(v_COLS(5)));

		END IF;
		v_IDX := v_LINES.NEXT(v_IDX);
	END LOOP;

  COMMIT;

  EXCEPTION
    WHEN OTHERS THEN
      p_STATUS := SQLCODE;
      p_MESSAGE := 'Error in MEX_PJM_ESCHED_ML.PARSE_EDC_HRLY_DERATION: ' || SQLERRM;
END PARSE_EDC_HRLY_DERATION;
----------------------------------------------------------------------------------------------------
PROCEDURE PARSE_LR_MNTHLY_SUMMARY
	(
	p_CSV IN CLOB,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) AS
v_LINES PARSE_UTIL.BIG_STRING_TABLE_MP;
v_COLS PARSE_UTIL.STRING_TABLE;
v_IDX BINARY_INTEGER;

  v_day DATE;
  v_hour NUMBER(2);
  v_dst NUMBER(1);
  v_cut_date DATE;

BEGIN
  p_STATUS := MEX_UTIL.g_SUCCESS;

	PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_CSV,v_LINES);
	v_IDX := v_LINES.FIRST;
	WHILE v_LINES.EXISTS(v_IDX) LOOP
		PARSE_UTIL.TOKENS_FROM_STRING(v_LINES(v_IDX),',',v_COLS);
		IF v_IDX = 1 THEN
			-- skip 1st line - it has column headers for data below
			NULL;
		ELSE
      v_DAY := TO_DATE(v_COLS(5),'MM/DD/YY');
      v_HOUR := TO_NUMBER(v_COLS(6));
      v_DST := TO_NUMBER(v_COLS(7));

      IF v_DST = 1 THEN
         v_cut_date := DATE_TIME_AS_CUT(TO_CHAR(v_DAY, 'YYYY-MM-DD'), v_HOUR || ':00', g_TZ_DST);
      ELSE
         v_cut_date := DATE_TIME_AS_CUT(TO_CHAR(v_DAY, 'YYYY-MM-DD'), v_HOUR || ':00', g_TZ_NODST);
      END IF;

      INSERT INTO PJM_LOAD_RESP_MONTHLY_SUMM VALUES
             (
             v_COLS(1),
             v_COLS(2),
             v_COLS(3),
             v_COLS(4),
             v_DAY,
             v_HOUR,
             v_DST,
             v_CUT_DATE,
             TO_NUMBER(v_COLS(8)),
             TO_NUMBER(v_COLS(9)),
             TO_NUMBER(v_COLS(10)),
             TO_NUMBER(v_COLS(11)),
             TO_NUMBER(v_COLS(12)),
             TO_NUMBER(v_COLS(13)),
             TO_NUMBER(v_COLS(14)),
             TO_NUMBER(v_COLS(15)),
             TO_NUMBER(v_COLS(16)),
             TO_NUMBER(v_COLS(17)),
             TO_NUMBER(v_COLS(18)),
             TO_NUMBER(v_COLS(19)),
             TO_NUMBER(v_COLS(20)),
             TO_NUMBER(v_COLS(21)));

		END IF;
		v_IDX := v_LINES.NEXT(v_IDX);
	END LOOP;

  COMMIT;

  EXCEPTION
    WHEN OTHERS THEN
      p_STATUS := SQLCODE;
      p_MESSAGE := 'Error in MEX_PJM_ESCHED_ML.PARSE_LR_MNTHLY_SUMMARY: ' || SQLERRM;
END PARSE_LR_MNTHLY_SUMMARY;
----------------------------------------------------------------------------------------------------
PROCEDURE PARSE_MTR_CORR_CHARGE_SUMM
	(
	p_CSV IN CLOB,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) AS
v_LINES PARSE_UTIL.BIG_STRING_TABLE_MP;
v_COLS PARSE_UTIL.STRING_TABLE;
v_IDX BINARY_INTEGER;

BEGIN
  p_STATUS := MEX_UTIL.g_SUCCESS;

	PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_CSV,v_LINES);
	v_IDX := v_LINES.FIRST;
	WHILE v_LINES.EXISTS(v_IDX) LOOP
		PARSE_UTIL.TOKENS_FROM_STRING(v_LINES(v_IDX),',',v_COLS);
		IF v_IDX = 1 THEN
			-- skip 1st line - it has column headers for data below
			NULL;
		ELSE

      INSERT INTO PJM_METER_CORR_CHARGE_SUMMARY VALUES
             (
             v_COLS(1),
             TRUNC(TO_DATE(v_COLS(2),'MM/DD/YY'),'MM'),
             TRUNC(TO_DATE(v_COLS(3),'MM/DD/YY'),'YY'),
             v_COLS(4),
             TO_NUMBER(v_COLS(5)),
             TO_NUMBER(v_COLS(6)),
             TO_NUMBER(v_COLS(7)),
             TO_NUMBER(v_COLS(8)));

		END IF;
		v_IDX := v_LINES.NEXT(v_IDX);
	END LOOP;

  COMMIT;

  EXCEPTION
    WHEN OTHERS THEN
      p_STATUS := SQLCODE;
      p_MESSAGE := 'Error in MEX_PJM_ESCHED_ML.PARSE_MTR_CORR_CHARGE_SUMM: ' || SQLERRM;
END PARSE_MTR_CORR_CHARGE_SUMM;
----------------------------------------------------------------------------------------------------
PROCEDURE PARSE_MTR_ALLOC_CHARGE_SUMM
	(
	p_CSV IN CLOB,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) AS
v_LINES PARSE_UTIL.BIG_STRING_TABLE_MP;
v_COLS PARSE_UTIL.STRING_TABLE;
v_IDX BINARY_INTEGER;

BEGIN
  p_STATUS := MEX_UTIL.g_SUCCESS;

	PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_CSV,v_LINES);
	v_IDX := v_LINES.FIRST;
	WHILE v_LINES.EXISTS(v_IDX) LOOP
		PARSE_UTIL.TOKENS_FROM_STRING(v_LINES(v_IDX),',',v_COLS);
		IF v_IDX = 1 THEN
			-- skip 1st line - it has column headers for data below
			NULL;
		ELSE

      INSERT INTO PJM_METER_CORR_ALLC_CHRG_SUMM VALUES
             (
             v_COLS(1),
             TRUNC(TO_DATE(v_COLS(2),'MM/DD/YY'),'MM'),
             TRUNC(TO_DATE(v_COLS(3),'MM/DD/YY'),'YY'),
             v_COLS(4),
             TO_NUMBER(v_COLS(5)),
             TO_NUMBER(v_COLS(6)),
             TO_NUMBER(v_COLS(7)),
             TO_NUMBER(v_COLS(8)),
             TO_NUMBER(v_COLS(9)),
             TO_NUMBER(v_COLS(10)));

		END IF;
		v_IDX := v_LINES.NEXT(v_IDX);
	END LOOP;

  EXCEPTION
    WHEN OTHERS THEN
      p_STATUS := SQLCODE;
      p_MESSAGE := 'Error in MEX_PJM_ESCHED_ML.PARSE_MTR_ALLOC_CHARGE_SUMM: ' || SQLERRM;
END PARSE_MTR_ALLOC_CHARGE_SUMM;
----------------------------------------------------------------------------------------------------
PROCEDURE PARSE_SCHED1A_CHARGES
	(
	p_CSV IN CLOB,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) AS
v_LINES PARSE_UTIL.BIG_STRING_TABLE_MP;
v_COLS PARSE_UTIL.STRING_TABLE;
v_IDX BINARY_INTEGER;

BEGIN
  p_STATUS := MEX_UTIL.g_SUCCESS;

	PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_CSV,v_LINES);
	v_IDX := v_LINES.FIRST;
	WHILE v_LINES.EXISTS(v_IDX) LOOP
		PARSE_UTIL.TOKENS_FROM_STRING(v_LINES(v_IDX),',',v_COLS);
		IF v_IDX = 1 THEN
			-- skip 1st line - it has column headers for data below
			NULL;
		ELSE

      INSERT INTO PJM_SCHEDULE_1A_CHARGES VALUES
             (
             v_COLS(1),
             TRUNC(TO_DATE(v_COLS(2),'MM/DD/YY'),'MM'),
             v_COLS(3),
             TO_NUMBER(v_COLS(4)),
             TO_NUMBER(v_COLS(5)),
             TO_NUMBER(v_COLS(6)),
             TO_NUMBER(v_COLS(7)),
             TO_NUMBER(v_COLS(8)),
             TO_NUMBER(v_COLS(9)),
             TO_NUMBER(v_COLS(10)),
             TO_NUMBER(v_COLS(11)));

		END IF;
		v_IDX := v_LINES.NEXT(v_IDX);
	END LOOP;

  COMMIT;

  EXCEPTION
    WHEN OTHERS THEN
      p_STATUS := SQLCODE;
      p_MESSAGE := 'Error in MEX_PJM_ESCHED_ML.PARSE_SCHED1A_CHARGES: ' || SQLERRM;
END PARSE_SCHED1A_CHARGES;

END MEX_PJM_SETTLEMENT;
/
