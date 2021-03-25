CREATE OR REPLACE PACKAGE BODY MEX_PJM_SETTLEMENT_MSRS IS
----------------------------------------------------------------------------------------------------
g_DEBUG_EXCHANGES VARCHAR2(8) := 'FALSE';
g_GMT_HR_END_FORMAT CONSTANT VARCHAR2(16) := 'MM/DD/YYYY HH24';
g_SHORT_DATE_FORMAT CONSTANT VARCHAR2(10) := 'MM/DD/YYYY';
g_REPORT_END_LINE CONSTANT VARCHAR2(16) := 'End of Report';
g_MSRS_REPORT_VERSION VARCHAR(2);
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
    p_CSV     IN CLOB,
    p_RECORDS OUT MEX_PJM_MONTHLY_STMNT_MSRS_TBL,
    p_STATUS  OUT NUMBER,
    p_MESSAGE OUT VARCHAR2
) AS

v_LINES PARSE_UTIL.BIG_STRING_TABLE_MP;
v_COLS PARSE_UTIL.STRING_TABLE;
    v_IDX        BINARY_INTEGER;
    v_JDX        BINARY_INTEGER;
    v_START_COL  BINARY_INTEGER;
    v_ORG_ID     VARCHAR2(8);
    v_ORG_NAME   VARCHAR2(64);
    v_BEGIN_DATE DATE;
    v_END_DATE   DATE;
    v_IS_CREDIT  NUMBER(1);
    v_IS_TOTAL   NUMBER(1);
    v_LINE_ITEM_NAME VARCHAR2(256);
    v_ADJ_DATE DATE;
	v_LINE_ITEMS_START_LINE_NUM NUMBER(9) := 1000; -- if we ever have more than 1000 lines in the header, we're in trouble

BEGIN
    p_STATUS := MEX_UTIL.g_SUCCESS;

    PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_CSV,v_LINES);
    v_IDX     := v_LINES.FIRST;
    p_RECORDS := MEX_PJM_MONTHLY_STMNT_MSRS_TBL();
	
	v_IS_CREDIT := 1; -- assume we're dealing with credit line items unless we see otherwise 
	
    WHILE v_LINES.EXISTS(v_IDX) LOOP
		-- skip empty lines, the Sample File Note or
		-- the 'End of Report' line  located at the end of the file
        IF v_LINES(v_IDX) IS NOT NULL
		   AND INSTR(v_LINES(v_IDX),'Sample File Note') = 0 THEN
            PARSE_UTIL.TOKENS_FROM_STRING(v_LINES(v_IDX), ',', v_COLS);
            IF v_COLS(1) = g_REPORT_END_LINE THEN
                EXIT;
            ELSIF v_IDX = 2 THEN
                -- first line contains customer account
                v_ORG_NAME := TRIM(v_COLS(2));
                -- if name contains comma, then TOKENS_FROM_STRING may have broken
                -- name into other columns - so put it back together
                v_JDX := 3;
                WHILE v_COLS.EXISTS(v_JDX) LOOP
					IF v_COLS(v_JDX) IS NOT NULL THEN
                    	v_ORG_NAME := v_ORG_NAME || ', ' || TRIM(v_COLS(v_JDX));
					END IF;
					v_JDX := v_COLS.NEXT(v_JDX);
                END LOOP;

            ELSIF v_IDX = 4 THEN
            -- org_id now on line 4
                v_ORG_ID    := TRIM(v_COLS(2));

            ELSIF v_IDX = 6 THEN
                --begin date now on line 6
                v_BEGIN_DATE := TO_DATE(TRIM(v_COLS(2)), g_SHORT_DATE_FORMAT);

            ELSIF v_IDX = 7 THEN
                ---end date now on line 7
                v_END_DATE := TO_DATE(TRIM(v_COLS(2)), g_SHORT_DATE_FORMAT);

			ELSIF UPPER(TRIM(v_COLS(1))) = 'CHARGES' THEN
                --treat line items as charges until/unless we hit a CREDITS section
                v_IS_CREDIT := 0;
				-- the next line will start the actual line items on the statement
				v_LINE_ITEMS_START_LINE_NUM := v_IDX + 1;

			-- if we ever have more than 1000 lines in the header we're in trouble
			ELSIF v_IDX >= v_LINE_ITEMS_START_LINE_NUM THEN
				IF UPPER(TRIM(v_COLS(1))) = 'CREDITS' THEN
					v_IS_CREDIT := 1;

				ELSE
					-- determine if this is the Net Total line
					IF UPPER(TRIM(v_COLS(3))) = 'NET TOTAL' THEN
                    	v_IS_TOTAL := 1;
                	ELSE
                    	v_IS_TOTAL := 0;
                	END IF;

                    IF v_COLS(4) IS NOT NULL AND v_COLS(2) IS NULL THEN
                        --billing line item name has a comma in it; this is not an adjustment line item
                        v_LINE_ITEM_NAME := v_COLS(3) || ', ' || TRIM(v_COLS(4));
                        v_START_COL := 6;
                        v_ADJ_DATE := NULL;
                    ELSE
                        v_LINE_ITEM_NAME := v_COLS(3);
                        v_START_COL := 5;
                        v_ADJ_DATE := NULL;
                    END IF;

                    IF v_COLS(2) = 'A' THEN
                    BEGIN
                        v_ADJ_DATE := TO_DATE(v_COLS(4), 'MM/DD/YYYY');
                        v_LINE_ITEM_NAME := v_COLS(3);
                        v_START_COL := 5;
                    EXCEPTION
                        WHEN OTHERS THEN
                            --billing line item name has a comma in it; this is an adjustment line item
                            v_LINE_ITEM_NAME := v_COLS(3) || ', ' || TRIM(v_COLS(4));
                            v_START_COL := 6;
                            v_ADJ_DATE := TO_DATE(v_COLS(5), 'MM/DD/YYYY');
                    END;
                    END IF;



					--skip 'Total Charges' / 'Total Credits' lines
                	IF UPPER(TRIM(v_COLS(3))) NOT IN ('TOTAL CHARGES', 'TOTAL CREDITS') THEN
                    	p_RECORDS.EXTEND();
                    	p_RECORDS(p_RECORDS.LAST) := MEX_PJM_MONTHLY_STMNT_MSRS(ORG_ID => v_ORG_ID,
																			ORG_NAME => v_ORG_NAME,
																			BEGIN_DATE => v_BEGIN_DATE,
																			END_DATE => v_END_DATE,
																			CHARGE_ID => NVL(TO_NUMBER(v_COLS(1)), 0),
																			IS_ADJUSTMENT => CASE WHEN UPPER(v_COLS(2)) = 'A' THEN 1 ELSE 0 END,
																			LINE_ITEM_NAME => v_LINE_ITEM_NAME,
																			BILL_PERIOD_START => v_ADJ_DATE,
																			LINE_ITEM_AMOUNT => NVL(TO_NUMBER(v_COLS(v_START_COL)), 0),
																			IS_CREDIT => v_IS_CREDIT,
																			IS_TOTAL => v_IS_TOTAL);
                	END IF;

					IF  UPPER(TRIM(v_COLS(3))) = 'TOTAL CREDITS' THEN
						-- we don't do any processing of this line or anything after, so we can go ahead and jump out here.
						-- this handles changes introduced with weekly billing (go-live expected in June 2009)
						EXIT;
					END IF;
				END IF;
        	END IF;
		END IF;
        v_IDX := v_LINES.NEXT(v_IDX);
    END LOOP;

EXCEPTION
    WHEN OTHERS THEN
        p_STATUS  := SQLCODE;
        p_MESSAGE := 'Error in MEX_PJM_SETTLEMENT_MSRS.PARSE_MONTHLY_STATEMENT: ' ||
                     SQLERRM;
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
-----------------------------------------------------------------------------------------------------
PROCEDURE PARSE_SPOT_SUMMARY
(
    p_CSV     IN CLOB,
    p_STATUS  OUT NUMBER,
    p_MESSAGE OUT VARCHAR2
) AS
    v_LINES    PARSE_UTIL.BIG_STRING_TABLE_MP;
    v_COLS     PARSE_UTIL.STRING_TABLE;
    v_IDX      BINARY_INTEGER;
    v_CUT_DATE DATE;

BEGIN
    p_STATUS := MEX_UTIL.g_SUCCESS;

    PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_CSV, v_LINES);
    v_IDX := v_LINES.FIRST;
    IF v_LINES.LAST = v_IDX THEN
        p_STATUS := 1;
        RETURN;
    END IF;
    WHILE v_LINES.EXISTS(v_IDX) AND INSTR(v_LINES(v_IDX),g_REPORT_END_LINE) = 0 LOOP
		-- skip first 5 rows (header info), empty lines and the 'End of Report' line
        IF v_LINES(v_IDX) IS NOT NULL AND v_IDX > 5 THEN
        	PARSE_UTIL.TOKENS_FROM_STRING(v_LINES(v_IDX), ',', v_COLS);

            v_CUT_DATE := NEW_TIME(TO_DATE(v_COLS(4),g_GMT_HR_END_FORMAT), 'GMT', 'EST');

            -- remaining lines contain charge determinant data
            INSERT INTO PJM_SPOT_MARKET_ENERGY_SUMMARY
            VALUES
                (v_COLS(1),
                 NULL,
                 NULL,
                 NULL,
                 v_CUT_DATE,
                 TO_NUMBER(v_COLS(5)),
                 TO_NUMBER(v_COLS(6)),
                 TO_NUMBER(v_COLS(7)),
                 TO_NUMBER(v_COLS(8)),
                 TO_NUMBER(v_COLS(9)),
                 TO_NUMBER(v_COLS(10)),
                 TO_NUMBER(v_COLS(11)));

            -- fill spot mkt table with report data for FERC 668
            UPDATE PJM_SPOT_MKT_SUMMARY
            SET DA_NET_INTERCHANGE    = NVL(TO_NUMBER(v_COLS(5)), 0),
                DA_SPOT_PURCHASE      = NULL,
                DA_LOAD_WEIGHTED_LMP  = NVL(TO_NUMBER(v_COLS(6)), 0),
                DA_CHARGE             = NVL(TO_NUMBER(v_COLS(7)), 0),
                DA_SPOT_SALE          = NULL,
                DA_GEN_WEIGHTED_LMP   = NULL,
                DA_CREDIT             = NULL,
                RT_NET_INTERCHANGE    = NVL(TO_NUMBER(v_COLS(8)), 0),
                BAL_SPOT_PURCHASE_DEV = NVL(TO_NUMBER(v_COLS(9)), 0),
                BAL_LOAD_WEIGHTED_LMP = NVL(TO_NUMBER(v_COLS(10)), 0),
                BAL_CHARGE            = NVL(TO_NUMBER(v_COLS(11)), 0),
                BAL_SPOT_SALE_DEV     = NULL,
                BAL_GEN_WEIGHTED_LMP  = NULL,
                BAL_CREDIT            = NULL
            WHERE ORG_ID = v_COLS(1)
            AND CUT_DATE = v_CUT_DATE;

            IF SQL%NOTFOUND THEN
                INSERT INTO PJM_SPOT_MKT_SUMMARY
                VALUES
                    (V_COLS(1),
                     NULL,
                     NULL,
                     NULL,
                     NVL(TO_NUMBER(V_COLS(5)), 0),
                     NULL,
                     NVL(TO_NUMBER(V_COLS(6)), 0),
                     NVL(TO_NUMBER(V_COLS(7)), 0),
                     NULL,
                     NULL,
                     NULL,
                     NVL(TO_NUMBER(V_COLS(8)), 0),
                     NVL(TO_NUMBER(V_COLS(9)), 0),
                     NVL(TO_NUMBER(V_COLS(10)), 0),
                     NVL(TO_NUMBER(V_COLS(11)), 0),
                     NULL,
                     NULL,
                     NULL,
                     v_CUT_DATE);
            END IF;

        END IF;
        v_IDX := v_LINES.NEXT(v_IDX);
    END LOOP;

    COMMIT;

  EXCEPTION
    WHEN OTHERS THEN
      p_STATUS := SQLCODE;
      p_MESSAGE := 'Error in MEX_PJM_SETTLEMENT_MSRS.PARSE_SPOT_SUMMARY: ' || SQLERRM;
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

v_CUT_DATE 	DATE;
v_ORG_ID    PJM_CONGESTION_SUMMARY.ORG_NID%TYPE;

BEGIN
    p_STATUS := MEX_UTIL.g_SUCCESS;

	PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_CSV,v_LINES);
	v_IDX := v_LINES.FIRST;
    IF v_LINES.LAST = v_IDX THEN
        p_STATUS := 1;
        RETURN;
    END IF;

	WHILE v_LINES.EXISTS(v_IDX) AND INSTR(v_LINES(v_IDX),g_REPORT_END_LINE) = 0 LOOP
		-- skip first 5 rows (header info), empty lines and the 'End of Report' line
        IF v_LINES(v_IDX) IS NOT NULL AND v_IDX > 5 THEN
			PARSE_UTIL.TOKENS_FROM_STRING(v_LINES(v_IDX),',',v_COLS);

			v_ORG_ID := v_COLS(1);

            v_CUT_DATE := NEW_TIME(TO_DATE(v_COLS(4),g_GMT_HR_END_FORMAT), 'GMT', 'EST');

			--just update the following fields from PJM_CONGESTION_SUMMARY table
			UPDATE PJM_CONGESTION_SUMMARY
			    SET DAY_AHEAD_CONG_WD_CHARGE = NVL(TO_NUMBER(v_COLS(6)),0),
			       DAY_AHEAD_CONG_INJ_CREDIT = NVL(TO_NUMBER(v_COLS(8)),0),
				   DAY_AHEAD_IMP_CONG_CHARGE = NVL(TO_NUMBER(v_COLS(9)),0),
				   DAY_AHEAD_EXP_CONG_CHARGE = NVL(TO_NUMBER(v_COLS(10)),0),
				   BALANCING_CONG_WD_CHARGE = NVL(TO_NUMBER(v_COLS(12)),0),
				   BALANCING_CONG_INJ_CREDIT = NVL(TO_NUMBER(v_COLS(14)),0),
				   BALANCING_IMP_CONG_CHARGE = NVL(TO_NUMBER(v_COLS(15)),0),
				   BALANCING_EXP_CONG_CHARGE = NVL(TO_NUMBER(v_COLS(16)),0)
			 WHERE ORG_NID = v_ORG_ID
			   AND CUT_DATE = v_CUT_DATE;

			IF SQL%NOTFOUND THEN
            	--Try insert into PJM_CONGESTION_SUMMARY
            	INSERT INTO PJM_CONGESTION_SUMMARY
                   (ORG_NID,
					CUT_DATE,
					DAY_AHEAD_CONG_WD_CHARGE,
					DAY_AHEAD_CONG_INJ_CREDIT,
					DAY_AHEAD_IMP_CONG_CHARGE,
					DAY_AHEAD_EXP_CONG_CHARGE,
					BALANCING_CONG_WD_CHARGE,
					BALANCING_CONG_INJ_CREDIT,
					BALANCING_IMP_CONG_CHARGE,
					BALANCING_EXP_CONG_CHARGE)
            	VALUES
                	(v_ORG_ID,
					v_CUT_DATE,
					NVL(TO_NUMBER(v_COLS(6)),0),
					NVL(TO_NUMBER(v_COLS(8)),0),
					NVL(TO_NUMBER(v_COLS(9)),0),
					NVL(TO_NUMBER(v_COLS(10)),0),
					NVL(TO_NUMBER(v_COLS(12)),0),
					NVL(TO_NUMBER(v_COLS(14)),0),
					NVL(TO_NUMBER(v_COLS(15)),0),
					NVL(TO_NUMBER(v_COLS(16)),0));
        	END IF;

		END IF;
		v_IDX := v_LINES.NEXT(v_IDX);
	END LOOP;

  COMMIT;

  EXCEPTION
    WHEN OTHERS THEN
      p_STATUS := SQLCODE;
      p_MESSAGE := 'Error in MEX_PJM_SETTLEMENT_MSRS.PARSE_CONGESTION_SUMMARY: ' || SQLERRM;
END PARSE_CONGESTION_SUMMARY;
----------------------------------------------------------------------------------------------------
PROCEDURE PARSE_CONG_LOSS_LOAD_RECONCIL
(
    p_CSV     IN CLOB,
    p_STATUS  OUT NUMBER,
    p_MESSAGE OUT VARCHAR2
) AS
    v_LINES    PARSE_UTIL.BIG_STRING_TABLE_MP;
    v_COLS     PARSE_UTIL.STRING_TABLE;
    v_IDX      BINARY_INTEGER;
    v_CUT_DATE DATE;

BEGIN
    p_STATUS := MEX_UTIL.g_SUCCESS;

    PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_CSV, v_LINES);
    v_IDX := v_LINES.FIRST;
    IF v_LINES.LAST = v_IDX THEN
        p_STATUS := 1;
        RETURN;
    END IF;
    WHILE v_LINES.EXISTS(v_IDX) AND INSTR(v_LINES(v_IDX),g_REPORT_END_LINE) = 0 LOOP
		-- skip first 5 rows (header info), empty lines and the 'End of Report' line
        IF v_LINES(v_IDX) IS NOT NULL AND v_IDX > 5 THEN
        	PARSE_UTIL.PARSE_DELIMITED_STRING(v_LINES(v_IDX), ',', v_COLS);

            v_CUT_DATE := NEW_TIME(TO_DATE(v_COLS(5),g_GMT_HR_END_FORMAT), 'GMT', 'EST');

            -- remaining lines contain charge determinant data
            INSERT INTO PJM_CONG_LOSS_CHRGS_RCN
            VALUES
                (v_COLS(1),
                 TO_DATE(v_COLS(3),'Month, YYYY'),
                 v_CUT_DATE,
                 TO_NUMBER(v_COLS(6)),
                 TO_NUMBER(v_COLS(9)),
                 TO_NUMBER(v_COLS(12)),
                 TO_NUMBER(v_COLS(13)),
                 TO_NUMBER(v_COLS(14)),
                 TO_NUMBER(v_COLS(15)));

        END IF;
        v_IDX := v_LINES.NEXT(v_IDX);
    END LOOP;
    COMMIT;
  EXCEPTION
    WHEN OTHERS THEN
      p_STATUS := SQLCODE;
      p_MESSAGE := 'Error in MEX_PJM_SETTLEMENT_MSRS.PARSE_CONG_LOSS_LOAD_RECONCIL: ' || SQLERRM;
END PARSE_CONG_LOSS_LOAD_RECONCIL;
----------------------------------------------------------------------------------------------------
PROCEDURE PARSE_SCHEDULE9_10_SUMMARY
	(
	p_CSV IN CLOB,
	p_RECORDS OUT MEX_PJM_SCHED9_10_SUM_TBL_MSRS,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) AS
v_LINES PARSE_UTIL.BIG_STRING_TABLE_MP;
v_COLS PARSE_UTIL.STRING_TABLE;
v_IDX BINARY_INTEGER;
v_RATE_QTY_TBL PRICE_QUANTITY_SUMMARY_TABLE;
v_HOUR BINARY_INTEGER;
v_DATE DATE;
BEGIN
  p_STATUS := MEX_UTIL.g_SUCCESS;

	PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_CSV,v_LINES);
	v_IDX := v_LINES.FIRST;
	p_RECORDS := MEX_PJM_SCHED9_10_SUM_TBL_MSRS();
    IF v_LINES.LAST = v_IDX THEN RETURN; END IF;
	WHILE v_LINES.EXISTS(v_IDX) AND INSTR(v_LINES(v_IDX),g_REPORT_END_LINE) = 0 LOOP
		 --skip first 5 lines (header info)
         IF v_LINES(v_IDX) IS NOT NULL AND v_IDX > 5 THEN
		    PARSE_UTIL.PARSE_DELIMITED_STRING(v_LINES(v_IDX),',',v_COLS);
            v_RATE_QTY_TBL := PRICE_QUANTITY_SUMMARY_TABLE();
		    FOR I IN 9 .. 33 LOOP
                IF I IN (9, 10) THEN
                    --hours 1 and 2
                    v_HOUR := I - 8;
                ELSIF I = 11 THEN
                    --second HE 2 column
                    IF TRUNC(v_DATE) =
                       TRUNC(DST_FALL_BACK_DATE(v_DATE)) THEN
                        v_HOUR := 25;
                    ELSE
                        v_HOUR := NULL; --ignore col 11 for the rest of the year
                    END IF;
                ELSE
                    --hours 3 to 24
                    v_HOUR := I - 9;
                END IF;

                IF v_HOUR IS NOT NULL THEN
                    IF v_HOUR = 25 THEN
                        v_DATE := TO_CUT_WITH_OPTIONS(TO_DATE(v_COLS(3), g_SHORT_DATE_FORMAT) + 2/24 + 1/86400,
                                                        MM_PJM_UTIL.g_PJM_TIME_ZONE,
                                                        MM_PJM_UTIL.g_DST_SPRING_AHEAD_OPTION);
                    ELSE
                        v_DATE := TO_CUT_WITH_OPTIONS(TO_DATE(v_COLS(3), g_SHORT_DATE_FORMAT) + v_HOUR/24,
                                                        MM_PJM_UTIL.g_PJM_TIME_ZONE,
                                                        MM_PJM_UTIL.g_DST_SPRING_AHEAD_OPTION);
                    END IF;


                    v_RATE_QTY_TBL.EXTEND();
                    v_RATE_QTY_TBL(v_RATE_QTY_TBL.LAST) := PRICE_QUANTITY_SUMMARY_TYPE(TO_NUMBER(v_COLS(6)),
                                                                                                    v_DATE,
                                                                                                    TO_NUMBER(v_COLS(I)));

                END IF;

		    END LOOP;

        -- remaining lines contain charge determinant data
            IF v_HOUR IS NOT NULL THEN
                p_RECORDS.EXTEND();
                p_RECORDS(p_RECORDS.LAST) := MEX_PJM_SCHEDULE9_10_SUMM_MSRS(v_COLS(1),
            					        v_COLS(2), TO_DATE(v_COLS(3), g_SHORT_DATE_FORMAT),
                                        v_COLS(4), v_COLS(5),
            					        TO_NUMBER(v_COLS(6)),TO_NUMBER(v_COLS(7)),
            					        TO_NUMBER(v_COLS(8)), v_RATE_QTY_TBL);
            END IF;
        END IF;
		v_IDX := v_LINES.NEXT(v_IDX);
	END LOOP;
  EXCEPTION
    WHEN OTHERS THEN
      p_STATUS := SQLCODE;
      p_MESSAGE := 'Error in MEX_PJM_SETTLEMENT_MSRS.PARSE_SCHEDULE9_10_SUMMARY: ' || SQLERRM;
END PARSE_SCHEDULE9_10_SUMMARY;
----------------------------------------------------------------------------------------------------
PROCEDURE PARSE_NITS_CREDIT_SUMMARY
(
    p_CSV     IN CLOB,
    p_RECORDS OUT MEX_PJM_NITS_SUMMARY_TBL,
    p_STATUS  OUT NUMBER,
    p_MESSAGE OUT VARCHAR2
) AS
    v_LINES PARSE_UTIL.BIG_STRING_TABLE_MP;
    v_COLS  PARSE_UTIL.STRING_TABLE;
    v_IDX   BINARY_INTEGER;
BEGIN
    p_STATUS  := MEX_UTIL.g_SUCCESS;
    p_RECORDS := MEX_PJM_NITS_SUMMARY_TBL();
    PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_CSV, v_LINES);

    v_IDX := v_LINES.FIRST;
    IF v_LINES.LAST = v_IDX THEN
        p_STATUS := 1;
        RETURN;
    END IF;

    WHILE v_LINES.EXISTS(v_IDX) AND INSTR(v_LINES(v_IDX),g_REPORT_END_LINE) = 0 LOOP
		-- skip first 5 rows (header info), empty lines and the 'End of Report' line
        IF v_LINES(v_IDX) IS NOT NULL AND v_IDX > 5 THEN
	        PARSE_UTIL.TOKENS_FROM_STRING(v_LINES(v_IDX), ',', v_COLS);
            p_RECORDS.EXTEND();
            p_RECORDS(p_RECORDS.LAST) := MEX_PJM_NITS_SUMMARY(ORG_ID            => v_COLS(1),
                                                              ORG_NAME          => v_COLS(2),
                                                              DAY               => TO_DATE(v_COLS(3), g_SHORT_DATE_FORMAT),
                                                              ZONE              => v_COLS(4),
                                                              PEAK_LOAD         => NULL,
                                                              NETWORK_RATE      => NULL,
                                                              CHARGE            => NULL,
                                                              TOTAL_REVENUES    => NVL(TO_NUMBER(v_COLS(5)),0),
                                                              REVENUE_REQ_SHARE => NVL(TO_NUMBER(v_COLS(6)),0),
                                                              CREDIT            => NVL(TO_NUMBER(v_COLS(8)),0));
        END IF;
        v_IDX := v_LINES.NEXT(v_IDX);
    END LOOP;
EXCEPTION
    WHEN OTHERS THEN
        p_STATUS  := SQLCODE;
        p_MESSAGE := 'Error in MEX_PJM_SETTLEMENT_MSRS.PARSE_NITS_CREDIT_SUMMARY: ' || SQLERRM;
END PARSE_NITS_CREDIT_SUMMARY;
----------------------------------------------------------------------------------------------------
PROCEDURE PARSE_NITS_CHARGE_SUMMARY
(
    p_CSV     IN CLOB,
    p_RECORDS OUT MEX_PJM_NITS_SUMMARY_TBL,
    p_STATUS  OUT NUMBER,
    p_MESSAGE OUT VARCHAR2
) AS
    v_LINES PARSE_UTIL.BIG_STRING_TABLE_MP;
    v_COLS  PARSE_UTIL.STRING_TABLE;
    v_IDX   BINARY_INTEGER;
BEGIN
    p_STATUS  := MEX_UTIL.g_SUCCESS;
    p_RECORDS := MEX_PJM_NITS_SUMMARY_TBL();
    PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_CSV, v_LINES);

    v_IDX := v_LINES.FIRST;
    IF v_LINES.LAST = v_IDX THEN
        p_STATUS := 1;
        RETURN;
    END IF;

    WHILE v_LINES.EXISTS(v_IDX) AND INSTR(v_LINES(v_IDX),g_REPORT_END_LINE) = 0 LOOP
		-- skip first 5 rows (header info), empty lines and the 'End of Report' line
        IF v_LINES(v_IDX) IS NOT NULL AND v_IDX > 5 THEN
        	PARSE_UTIL.TOKENS_FROM_STRING(v_LINES(v_IDX), ',', v_COLS);
            p_RECORDS.EXTEND();
            p_RECORDS(p_RECORDS.LAST) := MEX_PJM_NITS_SUMMARY(ORG_ID            => v_COLS(1),
                                                              ORG_NAME          => v_COLS(2),
                                                              DAY               => TO_DATE(v_COLS(3), g_SHORT_DATE_FORMAT),
                                                              ZONE              => v_COLS(4),
                                                              PEAK_LOAD         => NVL(TO_NUMBER(v_COLS(5)),0),
                                                              NETWORK_RATE      => NVL(TO_NUMBER(v_COLS(6)),0),
                                                              CHARGE            => NVL(TO_NUMBER(v_COLS(8)),0),
                                                              TOTAL_REVENUES    => NULL,
                                                              REVENUE_REQ_SHARE => NULL,
                                                              CREDIT            => NULL);
        END IF;
        v_IDX := v_LINES.NEXT(v_IDX);
    END LOOP;
EXCEPTION
    WHEN OTHERS THEN
        p_STATUS  := SQLCODE;
        p_MESSAGE := 'Error in MEX_PJM_SETTLEMENT_MSRS.PARSE_NITS_CHARGE_SUMMARY: ' || SQLERRM;
END PARSE_NITS_CHARGE_SUMMARY;
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
	WHILE v_LINES.EXISTS(v_IDX) AND INSTR(v_LINES(v_IDX),g_REPORT_END_LINE) = 0 LOOP
	    -- skip first 5 rows (header info), empty lines and the 'End of Report' line
        IF v_LINES(v_IDX) IS NOT NULL AND v_IDX > 5 THEN
		    PARSE_UTIL.PARSE_DELIMITED_STRING(v_LINES(v_IDX),',',v_COLS);

			-- remaining lines contain charge determinant data
			p_RECORDS.EXTEND();
			p_RECORDS(p_RECORDS.LAST) := MEX_PJM_NITS_SUMMARY(
                                            v_COLS(1), v_COLS(2),
											TO_DATE(v_COLS(3), g_SHORT_DATE_FORMAT),
                                            v_COLS(4), TO_NUMBER(v_COLS(5)),
											TO_NUMBER(v_COLS(6)),
                                            TO_NUMBER(v_COLS(7)),
                                            NULL,NULL,NULL);
		END IF;
		v_IDX := v_LINES.NEXT(v_IDX);
	END LOOP;
  EXCEPTION
    WHEN OTHERS THEN
      p_STATUS := SQLCODE;
      p_MESSAGE := 'Error in MEX_PJM_SETTLEMENT_MSRS.PARSE_EXPANSION_COST_SUMMARY: ' || SQLERRM;
END PARSE_EXPANSION_COST_SUMMARY;
----------------------------------------------------------------------------------------------------
PROCEDURE PARSE_RAMAPO_PAR_SUMMARY
	(
	p_CSV IN CLOB,
	p_RECORDS OUT MEX_PJM_RAMAPO_PAR_SUMMARY_TBL,
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
	p_RECORDS := MEX_PJM_RAMAPO_PAR_SUMMARY_TBL();
	WHILE v_LINES.EXISTS(v_IDX) AND INSTR(v_LINES(v_IDX),g_REPORT_END_LINE) = 0 LOOP
	    -- skip first 5 rows (header info), empty lines and the 'End of Report' line
        IF v_LINES(v_IDX) IS NOT NULL AND v_IDX > 5 THEN
		    PARSE_UTIL.PARSE_DELIMITED_STRING(v_LINES(v_IDX),',',v_COLS);

			-- remaining lines contain charge determinant data
			p_RECORDS.EXTEND();
			p_RECORDS(p_RECORDS.LAST) := MEX_PJM_RAMAPO_PAR_SUMMARY(
                                            v_COLS(1),
                                            TRUNC(TO_DATE(v_COLS(3),'Month, YYYY'), 'MM'),
                                            TO_NUMBER(v_COLS(4)),
                                            TO_NUMBER(v_COLS(5)),
											TO_NUMBER(v_COLS(6)),
                                            TO_NUMBER(v_COLS(7)));
        END IF;
		v_IDX := v_LINES.NEXT(v_IDX);
	END LOOP;
  EXCEPTION
    WHEN OTHERS THEN
      p_STATUS := SQLCODE;
      p_MESSAGE := 'Error in MEX_PJM_SETTLEMENT_MSRS.PARSE_RAMAPO_PAR_SUMMARY: ' || SQLERRM;
END PARSE_RAMAPO_PAR_SUMMARY;
----------------------------------------------------------------------------------------------------
PROCEDURE PARSE_RTO_STARTUP_COST_SUMMARY
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
	WHILE v_LINES.EXISTS(v_IDX) AND INSTR(v_LINES(v_IDX),g_REPORT_END_LINE) = 0 LOOP
	    -- skip first 5 rows (header info), empty lines and the 'End of Report' line
        IF v_LINES(v_IDX) IS NOT NULL AND v_IDX > 5 THEN
		    PARSE_UTIL.PARSE_DELIMITED_STRING(v_LINES(v_IDX),',',v_COLS);

			-- remaining lines contain charge determinant data
			p_RECORDS.EXTEND();
			p_RECORDS(p_RECORDS.LAST) := MEX_PJM_NITS_SUMMARY(
                                            v_COLS(1), v_COLS(2),
											TO_DATE(v_COLS(3), g_SHORT_DATE_FORMAT),
                                            v_COLS(4), TO_NUMBER(v_COLS(5)),
											TO_NUMBER(v_COLS(6)),
                                            TO_NUMBER(v_COLS(7)),
                                            NULL,NULL,NULL);
		END IF;
		v_IDX := v_LINES.NEXT(v_IDX);
	END LOOP;
  EXCEPTION
    WHEN OTHERS THEN
      p_STATUS := SQLCODE;
      p_MESSAGE := 'Error in MEX_PJM_SETTLEMENT_MSRS.PARSE_RTO_STARTUP_COST_SUMMARY: ' || SQLERRM;
END PARSE_RTO_STARTUP_COST_SUMMARY;
----------------------------------------------------------------------------------------------------
PROCEDURE PARSE_DEFICIENCY_CREDIT_SUMM
	(
	p_CSV IN CLOB,
	p_RECORDS OUT MEX_PJM_DEFICIENCY_CR_SUMM_TBL,
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
	p_RECORDS := MEX_PJM_DEFICIENCY_CR_SUMM_TBL();
	WHILE v_LINES.EXISTS(v_IDX) AND INSTR(v_LINES(v_IDX),g_REPORT_END_LINE) = 0 LOOP
	    -- skip first 5 rows (header info), empty lines and the 'End of Report' line
        IF v_LINES(v_IDX) IS NOT NULL AND v_IDX > 5 THEN
		    PARSE_UTIL.PARSE_DELIMITED_STRING(v_LINES(v_IDX),',',v_COLS);

			-- remaining lines contain charge determinant data
			p_RECORDS.EXTEND();
			p_RECORDS(p_RECORDS.LAST) := MEX_PJM_DEFICIENCY_CREDIT_SUMM(
                                            v_COLS(1), v_COLS(2),
											TO_DATE(v_COLS(3), g_SHORT_DATE_FORMAT),
                                            TO_NUMBER(v_COLS(4)), TO_NUMBER(v_COLS(5)),
											TO_NUMBER(v_COLS(6)), TO_NUMBER(v_COLS(7)),
                                            TO_NUMBER(v_COLS(8)), TO_NUMBER(v_COLS(9)),
                                            TO_NUMBER(v_COLS(10)), TO_NUMBER(v_COLS(11)),
                                            TO_NUMBER(v_COLS(12)), TO_NUMBER(v_COLS(13))
                                            );
		END IF;
		v_IDX := v_LINES.NEXT(v_IDX);
	END LOOP;
  EXCEPTION
    WHEN OTHERS THEN
      p_STATUS := SQLCODE;
      p_MESSAGE := 'Error in MEX_PJM_SETTLEMENT_MSRS.PARSE_DEFICIENCY_CREDIT_SUMM: ' || SQLERRM;
END PARSE_DEFICIENCY_CREDIT_SUMM;
----------------------------------------------------------------------------------------------------
PROCEDURE PARSE_OP_RES_FOR_LD_RESP
	(
	p_CSV IN CLOB,
	p_RECORDS OUT MEX_PJM_OP_RES_FOR_LD_RESP_TBL,
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
	p_RECORDS := MEX_PJM_OP_RES_FOR_LD_RESP_TBL();
	WHILE v_LINES.EXISTS(v_IDX) AND INSTR(v_LINES(v_IDX),g_REPORT_END_LINE) = 0 LOOP
	    -- skip first 5 rows (header info), empty lines and the 'End of Report' line
        IF v_LINES(v_IDX) IS NOT NULL AND v_IDX > 5 THEN
		    PARSE_UTIL.PARSE_DELIMITED_STRING(v_LINES(v_IDX),',',v_COLS);

			-- remaining lines contain charge determinant data
			p_RECORDS.EXTEND();
			p_RECORDS(p_RECORDS.LAST) := MEX_PJM_OP_RES_FOR_LD_RESP_SUM(
                                            v_COLS(1), v_COLS(2),
                                            TO_DATE(v_COLS(3), 'Month, YYYY'),
											TO_DATE(v_COLS(4), g_SHORT_DATE_FORMAT),
                                            TO_NUMBER(v_COLS(5)), TO_NUMBER(v_COLS(6)),
											TO_NUMBER(v_COLS(7)), TO_NUMBER(v_COLS(8)),
                                            TO_NUMBER(v_COLS(9))
                                            );
		END IF;
		v_IDX := v_LINES.NEXT(v_IDX);
	END LOOP;
  EXCEPTION
    WHEN OTHERS THEN
      p_STATUS := SQLCODE;
      p_MESSAGE := 'Error in MEX_PJM_SETTLEMENT_MSRS.PARSE_OP_RES_FOR_LD_RESP: ' || SQLERRM;
END PARSE_OP_RES_FOR_LD_RESP;
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
	WHILE v_LINES.EXISTS(v_IDX) AND INSTR(v_LINES(v_IDX),g_REPORT_END_LINE) = 0 LOOP
		PARSE_UTIL.PARSE_DELIMITED_STRING(v_LINES(v_IDX),',',v_COLS);
		IF v_LINES(v_IDX) IS NOT NULL AND v_IDX > 5 THEN
			-- remaining lines contain charge determinant data
			p_RECORDS.EXTEND();
			p_RECORDS(p_RECORDS.LAST) := MEX_PJM_REACTIVE_SERV_SUMMARY(v_COLS(1),
                                                                       v_COLS(2),
											                           TO_DATE(v_COLS(3),g_SHORT_DATE_FORMAT),
                                                                       v_COLS(4),
                                                                       NULL,
											                           TO_NUMBER(v_COLS(5)),
                                                                       TO_NUMBER(v_COLS(6)),
											                           TO_NUMBER(v_COLS(7)),
                                                                       TO_NUMBER(v_COLS(8)));
		END IF;
		v_IDX := v_LINES.NEXT(v_IDX);
	END LOOP;
  EXCEPTION
    WHEN OTHERS THEN
      p_STATUS := SQLCODE;
      p_MESSAGE := 'Error in MEX_PJM_SETTLEMENT_MSRS.PARSE_REACTIVE_SERV_SUMMARY: ' || SQLERRM;
END PARSE_REACTIVE_SERV_SUMMARY;
----------------------------------------------------------------------------------------------------
PROCEDURE PARSE_OPER_RES_CHG_SUMMARY_NEW
(
    p_CSV     IN CLOB,
    p_RECORDS OUT MEX_PJM_OPER_RES_SUMM_MSRS_TBL,
    p_STATUS  OUT NUMBER,
    p_MESSAGE OUT VARCHAR2
) AS
    v_LINES PARSE_UTIL.BIG_STRING_TABLE_MP;
    v_COLS  PARSE_UTIL.STRING_TABLE;
    v_IDX   BINARY_INTEGER;
	v_DA_LOAD_PLUS_EXPORTS NUMBER;

BEGIN
    p_STATUS := MEX_UTIL.g_SUCCESS;

	PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_CSV, v_LINES);
    p_RECORDS := MEX_PJM_OPER_RES_SUMM_MSRS_TBL();

    v_IDX := v_LINES.FIRST;
    IF v_LINES.LAST = v_IDX THEN
        p_STATUS := 1;
        RETURN;
    END IF;

	--this is the new format of the Operating Reserve Charge Sumamry starting December 01, 2008
	WHILE v_LINES.EXISTS(v_IDX) AND INSTR(v_LINES(v_IDX),g_REPORT_END_LINE) = 0 LOOP
		-- skip first 5 rows (header info), empty lines and the 'End of Report' line
		IF v_LINES(v_IDX) IS NOT NULL AND  v_IDX > 5 THEN
			PARSE_UTIL.TOKENS_FROM_STRING(v_LINES(v_IDX), ',', v_COLS);
			v_DA_LOAD_PLUS_EXPORTS := NVL(TO_NUMBER(v_COLS(5)),0) + NVL(TO_NUMBER(v_COLS(6)),0);
			p_RECORDS.EXTEND();
			p_RECORDS(p_RECORDS.LAST) := MEX_PJM_OPER_RES_SUMM_MSRS(ORG_ID              => v_COLS(1),
																  DAY                        => TO_DATE(v_COLS(3),g_SHORT_DATE_FORMAT),
																  TOTAL_DA_CREDITS           => NVL(TO_NUMBER(v_COLS(4)),0),
																  DA_LOAD_PLUS_EXPORTS       => v_DA_LOAD_PLUS_EXPORTS,
																  TOTAL_DA_LOAD_PLUS_EXPORTS => NVL(TO_NUMBER(v_COLS(7)),0),
																  DA_CHARGE                  => NVL(TO_NUMBER(v_COLS(8)),0),
																  BAL_RELIABILITY_CHARGE     => NVL(TO_NUMBER(v_COLS(9)),0),
																  BAL_DEVIATION_CHARGE       => NVL(TO_NUMBER(v_COLS(10)),0),
																  BAL_CHARGE                 => NVL(TO_NUMBER(v_COLS(11)),0));

		END IF;
		v_IDX := v_LINES.NEXT(v_IDX);
	END LOOP;

    EXCEPTION
WHEN
OTHERS    THEN p_STATUS := SQLCODE;
p_MESSAGE := 'Error in MEX_PJM_SETTLEMENT_MSRS.PARSE_OPER_RES_SUMMARY_NEW: ' ||
             SQLERRM;
END PARSE_OPER_RES_CHG_SUMMARY_NEW;
----------------------------------------------------------------------------------------------------
PROCEDURE PARSE_OPER_RES_CHG_SUMMARY
(
    p_CSV     IN CLOB,
    p_RECORDS OUT MEX_PJM_OPER_RES_SUMMARY_TBL,
    p_STATUS  OUT NUMBER,
    p_MESSAGE OUT VARCHAR2
) AS
    v_LINES PARSE_UTIL.BIG_STRING_TABLE_MP;
    v_COLS  PARSE_UTIL.STRING_TABLE;
    v_IDX   BINARY_INTEGER;
	v_DA_LOAD_PLUS_EXPORTS NUMBER;
BEGIN
    p_STATUS := MEX_UTIL.g_SUCCESS;

    PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_CSV, v_LINES);
    p_RECORDS := MEX_PJM_OPER_RES_SUMMARY_TBL();

    v_IDX := v_LINES.FIRST;
    IF v_LINES.LAST = v_IDX THEN
        p_STATUS := 1;
        RETURN;
    END IF;

    WHILE v_LINES.EXISTS(v_IDX) AND INSTR(v_LINES(v_IDX),g_REPORT_END_LINE) = 0 LOOP
        -- skip first 5 rows (header info), empty lines and the 'End of Report' line
        IF v_LINES(v_IDX) IS NOT NULL AND  v_IDX > 5 THEN
            PARSE_UTIL.TOKENS_FROM_STRING(v_LINES(v_IDX), ',', v_COLS);
			v_DA_LOAD_PLUS_EXPORTS := NVL(TO_NUMBER(v_COLS(5)),0) + NVL(TO_NUMBER(v_COLS(6)),0);
            p_RECORDS.EXTEND();
            p_RECORDS(p_RECORDS.LAST) := MEX_PJM_OPER_RES_SUMMARY(ORG_ID                     => v_COLS(1),
                                                                  DAY                        => TO_DATE(v_COLS(3),g_SHORT_DATE_FORMAT),
                                                                  DA_CREDIT                  => NULL,
                                                                  BAL_CREDIT                 => NULL,
                                                                  TOTAL_DA_CREDITS           => NVL(TO_NUMBER(v_COLS(4)),0),
                                                                  TOTAL_BAL_CREDITS          => NVL(TO_NUMBER(v_COLS(9)),0),
                                                                  DA_LOAD_PLUS_EXPORTS       => v_DA_LOAD_PLUS_EXPORTS,
                                                                  TOTAL_DA_LOAD_PLUS_EXPORTS => NVL(TO_NUMBER(v_COLS(7)),0),
                                                                  GENERATION_DEVIATION       => NVL(TO_NUMBER(v_COLS(10)),0),
                                                                  INJECTION_DEVIATION        => NVL(TO_NUMBER(v_COLS(11)),0),
                                                                  WITHDRAWAL_DEVIATION       => NVL(TO_NUMBER(v_COLS(12)),0),
                                                                  TOTAL_DEVIATION            => NVL(TO_NUMBER(v_COLS(13)),0),
                                                                  DA_CHARGE                  => NVL(TO_NUMBER(v_COLS(8)),0),
                                                                  BAL_CHARGE                 => NVL(TO_NUMBER(v_COLS(14)),0));

             END IF;
            v_IDX := v_LINES.NEXT(v_IDX);
        END LOOP;

    EXCEPTION
WHEN
OTHERS    THEN p_STATUS := SQLCODE;
p_MESSAGE := 'Error in MEX_PJM_SETTLEMENT_MSRS.PARSE_OPER_RES_SUMMARY: ' ||
             SQLERRM;
END PARSE_OPER_RES_CHG_SUMMARY;
----------------------------------------------------------------------------------------------------
PROCEDURE PARSE_OP_RES_LOST_OPP_COST
(
    p_CSV     IN CLOB,
    p_RECORDS OUT MEX_PJM_OP_RES_LOC_MSRS_TBL,
    p_STATUS  OUT NUMBER,
    p_MESSAGE OUT VARCHAR2
) AS
    v_LINES    PARSE_UTIL.BIG_STRING_TABLE_MP;
    v_COLS     PARSE_UTIL.STRING_TABLE;
    v_IDX      BINARY_INTEGER;
    v_CUT_DATE DATE;

BEGIN
    p_STATUS := MEX_UTIL.g_SUCCESS;

    PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_CSV, v_LINES);
    v_IDX     := v_LINES.FIRST;
    p_RECORDS := MEX_PJM_OP_RES_LOC_MSRS_TBL();
    IF v_LINES.LAST = v_IDX THEN RETURN; END IF;

    WHILE v_LINES.EXISTS(v_IDX) AND INSTR(v_LINES(v_IDX),g_REPORT_END_LINE) = 0 LOOP
        -- skip first 5 rows (header info), empty lines and the 'End of Report' line
        IF v_LINES(v_IDX) IS NOT NULL AND v_IDX > 5 THEN
            PARSE_UTIL.TOKENS_FROM_STRING(v_LINES(v_IDX), ',', v_COLS);

            v_CUT_DATE := NEW_TIME(TO_DATE(v_COLS(4),g_GMT_HR_END_FORMAT), 'GMT', 'EST');

            p_RECORDS.EXTEND();
            p_RECORDS(p_RECORDS.LAST) := MEX_PJM_OP_RES_LOC_MSRS(ORG_ID           => v_COLS(1),
                                                                 ORG_NAME         => v_COLS(2),
                                                                 CUT_DATE         => v_CUT_DATE,
                                                                 UNIT_ID          => v_COLS(5),
                                                                 UNIT_NAME        => v_COLS(6),
                                                                 SCHED_ID         => v_COLS(8),
                                                                 OWNER_SHARE      => NVL(TO_NUMBER(v_COLS(7)),0),
                                                                 DA_MW            => NVL(TO_NUMBER(v_COLS(9)),0),
                                                                 OFFER_DA_MW      => NVL(TO_NUMBER(v_COLS(10)),0),
                                                                 DA_LMP           => NVL(TO_NUMBER(v_COLS(11)),0),
                                                                 RT_MW            => NVL(TO_NUMBER(v_COLS(12)),0),
                                                                 OFFER_RT_MW      => NVL(TO_NUMBER(v_COLS(13)),0),
                                                                 RT_LMP           => NVL(TO_NUMBER(v_COLS(14)),0),
                                                                 RT_DESIRED_MW    => NVL(TO_NUMBER(v_COLS(15)),0),
                                                                 REG_MWH_ADJ      => NVL(TO_NUMBER(v_COLS(16)),0),
                                                                 SYNC_RES_MWH_ADJ => NVL(TO_NUMBER(v_COLS(17)),0),
                                                                 MWH_REDUCED      => NVL(TO_NUMBER(v_COLS(19)),0),
                                                                 LOC_CREDIT       => NVL(TO_NUMBER(v_COLS(20)),0));

            IF NVL(v_COLS(18), 0) <> 0 THEN
                UPDATE_TRAIT_VAL(v_COLS(6),
                                 v_CUT_DATE,
                                 MM_PJM_UTIL.g_TG_OUT_MWH_REDUCED,
                                 v_COLS(18),
                                 v_COLS(2),
                                 p_STATUS,
                                 p_MESSAGE,
                                 v_COLS(1));
            END IF;

        END IF;
        v_IDX := v_LINES.NEXT(v_IDX);
    END LOOP;

EXCEPTION
    WHEN OTHERS THEN
        p_STATUS  := SQLCODE;
        p_MESSAGE := 'Error in MEX_PJM_SETTLEMENT_MSRS.PARSE_OP_RES_LOST_OPP_COST: ' || SQLERRM;
END PARSE_OP_RES_LOST_OPP_COST;
---------------------------------------------------------------------------------------------------
PROCEDURE PARSE_REG_OPER_RES_CHG_SUMMARY
(
    p_CSV     IN CLOB,
    p_RECORDS OUT MEX_PJM_REG_OPER_RES_SUMM_TBL,
    p_STATUS  OUT NUMBER,
    p_MESSAGE OUT VARCHAR2
) AS
    v_LINES    PARSE_UTIL.BIG_STRING_TABLE_MP;
    v_COLS     PARSE_UTIL.STRING_TABLE;
    v_IDX      BINARY_INTEGER;    

BEGIN
    p_STATUS := MEX_UTIL.g_SUCCESS;

    PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_CSV, v_LINES);
    v_IDX     := v_LINES.FIRST;
    p_RECORDS := MEX_PJM_REG_OPER_RES_SUMM_TBL();
    IF v_LINES.LAST = v_IDX THEN RETURN; END IF;

    WHILE v_LINES.EXISTS(v_IDX) AND INSTR(v_LINES(v_IDX),g_REPORT_END_LINE) = 0 LOOP
        -- skip first 5 rows (header info), empty lines and the 'End of Report' line
        IF v_LINES(v_IDX) IS NOT NULL AND v_IDX > 5 THEN
            PARSE_UTIL.TOKENS_FROM_STRING(v_LINES(v_IDX), ',', v_COLS);

            p_RECORDS.EXTEND();
            p_RECORDS(p_RECORDS.LAST) := MEX_PJM_REG_OPER_RES_SUMM(ORG_ID         => v_COLS(1),
                                                                 ORG_NAME         => v_COLS(2),
                                                                 OPER_DAY         => TO_DATE(v_COLS(3), g_SHORT_DATE_FORMAT),
                                                                 RTO_BAL_RELIABILITY_CHG    => NVL(TO_NUMBER(v_COLS(7)),0),
                                                                 EAST_BAL_RELIABILITY_CHG   => NVL(TO_NUMBER(v_COLS(11)),0),
                                                                 WEST_BAL_RELIABILITY_CHG   => NVL(TO_NUMBER(v_COLS(15)),0),
                                                                 RTO_BAL_DEVIATIONS_CHG     => NVL(TO_NUMBER(v_COLS(19)),0),
                                                                 EAST_BAL_DEVIATIONS_CHG    => NVL(TO_NUMBER(v_COLS(23)),0),
                                                                 WEST_BAL_DEVIATIONS_CHG    => NVL(TO_NUMBER(v_COLS(27)),0));                                                               

      
        END IF;
        v_IDX := v_LINES.NEXT(v_IDX);
    END LOOP;

EXCEPTION
    WHEN OTHERS THEN
        p_STATUS  := SQLCODE;
        p_MESSAGE := 'Error in MEX_PJM_SETTLEMENT_MSRS.PPARSE_REG_OPER_RES_CHG_SUMMARY: ' || SQLERRM;
END PARSE_REG_OPER_RES_CHG_SUMMARY;
---------------------------------------------------------------------------------------------------
PROCEDURE PARSE_OP_RES_GEN_CR_DETAILS
	(
	p_CSV IN CLOB,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) AS
v_LINES 		PARSE_UTIL.BIG_STRING_TABLE_MP;
v_COLS 			PARSE_UTIL.STRING_TABLE;
v_IDX 			BINARY_INTEGER;
v_ROW 			PJM_OPRES_GEN_CREDITS%ROWTYPE;
v_ORG_ID 		PJM_OPRES_GEN_CREDITS.ORG_ID%TYPE;
v_UNIT_ID 		PJM_OPRES_GEN_CREDITS.UNIT_ID%TYPE;
v_PREV_UNIT_ID 	NUMBER := 0;
v_DATE 			DATE;

BEGIN
	p_STATUS := MEX_UTIL.g_SUCCESS;

	PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_CSV,v_LINES);
	v_IDX := v_LINES.FIRST;

	WHILE v_LINES.EXISTS(v_IDX) AND INSTR(v_LINES(v_IDX),g_REPORT_END_LINE) = 0 LOOP
		PARSE_UTIL.TOKENS_FROM_STRING(v_LINES(v_IDX),',',v_COLS);
		IF v_IDX > 5 THEN

			IF v_PREV_UNIT_ID <> v_COLS(4) THEN
				v_ORG_ID := v_COLS(1);
				v_UNIT_ID := v_COLS(4);
				v_PREV_UNIT_ID := v_UNIT_ID;
				v_DATE := TO_DATE(v_COLS(3), g_SHORT_DATE_FORMAT);

                BEGIN
                    SELECT * INTO v_ROW
                      FROM PJM_OPRES_GEN_CREDITS
                     WHERE ORG_ID = v_ORG_ID
                       AND UNIT_ID = v_UNIT_ID
                       AND DAY = v_DATE;
                EXCEPTION
                    WHEN NO_DATA_FOUND THEN
                        INSERT INTO PJM_OPRES_GEN_CREDITS
                            (DAY, ORG_ID, UNIT_ID)
                        VALUES
                            (v_DATE, v_ORG_ID, v_UNIT_ID);
                END;

		  		v_ROW.ORG_NAME := v_COLS(2);
				v_ROW.UNIT_NAME := v_COLS(5);
				v_ROW.OWNERSHIP_SHARE := TO_NUMBER(v_COLS(6));
			END IF;

			IF UPPER(v_COLS(7)) = 'DA ENERGY OFFER ($)' THEN
				v_ROW.DA_OFFER := 	NVL(TO_NUMBER(v_COLS(33)), 0);
			ELSIF UPPER(v_COLS(7)) = 'DA VALUE ($)' THEN
				v_ROW.DA_VALUE := NVL(TO_NUMBER(v_COLS(33)), 0);
			ELSIF UPPER(v_COLS(7)) = 'RT ENERGY OFFER ($)' THEN
				v_ROW.RT_OFFER := NVL(TO_NUMBER(v_COLS(33)), 0);
			ELSIF UPPER(v_COLS(7)) = 'BAL VALUE ($)' THEN
				v_ROW.BAL_VALUE := NVL(TO_NUMBER(v_COLS(33)), 0);
			ELSIF UPPER(v_COLS(7)) = 'OPERATING RESERVE OFFSETTING REG REVENUE ($)' THEN
				v_ROW.REGULATION_REVENUE := NVL(TO_NUMBER(v_COLS(33)), 0);
			ELSIF UPPER(v_COLS(7)) = 'OPERATING RESERVE OFFSETTING SYNCH RESERVE REVENUE ($)' THEN
				v_ROW.SPIN_RES_REVENUE := NVL(TO_NUMBER(v_COLS(33)), 0);
			ELSIF UPPER(v_COLS(7)) = 'OPERATING RESERVE OFFSETTING REACTIVE SERVICES REVENUE ($)' THEN
				v_ROW.REACT_SERV_REVENUE := NVL(TO_NUMBER(v_COLS(33)), 0);

            UPDATE PJM_OPRES_GEN_CREDITS
            SET DA_OFFER = v_ROW.Da_Offer,
                DA_VALUE = v_ROW.DA_VALUE,
                RT_OFFER = v_ROW.RT_OFFER,
                BAL_VALUE = v_ROW.BAL_VALUE,
                REGULATION_REVENUE = v_ROW.REGULATION_REVENUE,
                SPIN_RES_REVENUE = v_ROW.SPIN_RES_REVENUE,
                REACT_SERV_REVENUE = v_ROW.REACT_SERV_REVENUE
            WHERE DAY = v_DATE
            AND ORG_ID = v_ORG_ID
            AND UNIT_ID = v_UNIT_ID;
			END IF;
		END IF;

		v_IDX := v_LINES.NEXT(v_IDX);
	END LOOP;

    COMMIT;
  EXCEPTION
    WHEN OTHERS THEN
      p_STATUS := SQLCODE;
      p_MESSAGE := 'Error in MEX_PJM_SETTLEMENT_MSRS.PARSE_OP_RES_GEN_CR_DETAILS: ' || SQLERRM;
END PARSE_OP_RES_GEN_CR_DETAILS;
----------------------------------------------------------------------------------------------------
PROCEDURE PARSE_GENERATOR_CREDIT_SUMMARY
(
    p_CSV     IN CLOB,
    p_STATUS  OUT NUMBER,
    p_MESSAGE OUT VARCHAR2
) AS
    v_LINES   PARSE_UTIL.BIG_STRING_TABLE_MP;
    v_COLS    PARSE_UTIL.STRING_TABLE;
    v_ORG_ID  PJM_OPRES_GEN_CREDITS.ORG_ID%TYPE;
    v_UNIT_ID PJM_OPRES_GEN_CREDITS.UNIT_ID%TYPE;
    v_DATE    DATE;
	v_IDX 	  NUMBER;

BEGIN
    p_STATUS  := MEX_UTIL.g_SUCCESS;
    PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_CSV, v_LINES);

    v_IDX := v_LINES.FIRST;
    IF v_LINES.LAST = v_IDX THEN
        p_STATUS := 1;
        RETURN;
    END IF;

    WHILE v_LINES.EXISTS(v_IDX) AND INSTR(v_LINES(v_IDX),g_REPORT_END_LINE) = 0 LOOP
        -- skip first 5 rows (header info), empty lines and the 'End of Report' line
        IF v_LINES(v_IDX) IS NOT NULL AND v_IDX > 5 THEN
            PARSE_UTIL.TOKENS_FROM_STRING(v_LINES(v_IDX), ',', v_COLS);

            v_ORG_ID := v_COLS(1);
            v_DATE   := TO_DATE(v_COLS(3), g_SHORT_DATE_FORMAT);
            v_UNIT_ID   := v_COLS(4);
            -- remaining lines contain charge determinant data
            UPDATE PJM_OPRES_GEN_CREDITS
            SET ORG_NAME   = v_COLS(2),
                UNIT_NAME  = v_COLS(5),
                DA_CREDIT  = NVL(TO_NUMBER(v_COLS(7)), 0),
                BAL_CREDIT = NVL(TO_NUMBER(v_COLS(8)), 0)
            WHERE ORG_ID = v_ORG_ID
            AND DAY = v_DATE
            AND UNIT_ID = v_UNIT_ID;


            IF SQL%NOTFOUND THEN
                INSERT INTO PJM_OPRES_GEN_CREDITS
                    (DAY,
                     ORG_ID,
                     ORG_NAME,
                     UNIT_ID,
                     UNIT_NAME,
                     DA_CREDIT,
                     BAL_CREDIT)
                VALUES
                    (v_DATE,
                     v_ORG_ID,
                     v_COLS(2),
                     v_UNIT_ID,
                     v_COLS(5),
                     NVL(TO_NUMBER(V_COLS(7)), 0),
                     NVL(TO_NUMBER(V_COLS(8)), 0));
            END IF;
        END IF;
        v_IDX := v_LINES.NEXT(v_IDX);
    END LOOP;

    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
        p_STATUS  := SQLCODE;
        p_MESSAGE := 'Error in MEX_PJM_SETTLEMENT_MSRS.PARSE_GENERATOR_CREDIT_SUMMARY: ' || SQLERRM;
END PARSE_GENERATOR_CREDIT_SUMMARY;
----------------------------------------------------------------------------------------------------
PROCEDURE PARSE_NITS_OFFSET_SUMMARY
(
    p_CSV     IN CLOB,
    p_RECORDS OUT MEX_PJM_TRANS_OFFSET_CHG_TBL,
    p_STATUS  OUT NUMBER,
    p_MESSAGE OUT VARCHAR2
) AS
    v_LINES     PARSE_UTIL.BIG_STRING_TABLE_MP;
    v_COLS      PARSE_UTIL.STRING_TABLE;
    v_IDX       BINARY_INTEGER;

BEGIN
    p_STATUS  := MEX_UTIL.g_SUCCESS;
    p_RECORDS := MEX_PJM_TRANS_OFFSET_CHG_TBL();
    PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_CSV, v_LINES);

    v_IDX := v_LINES.FIRST;
    IF v_LINES.LAST = v_IDX THEN
        p_STATUS := 1;
        RETURN;
    END IF;

    WHILE v_LINES.EXISTS(v_IDX) AND INSTR(v_LINES(v_IDX),g_REPORT_END_LINE) = 0 LOOP
		-- skip first 5 rows (header info), empty lines and the 'End of Report' line
        IF v_LINES(v_IDX) IS NOT NULL AND v_IDX > 5 THEN
        	PARSE_UTIL.TOKENS_FROM_STRING(v_LINES(v_IDX), ',', v_COLS);

            p_RECORDS.EXTEND();
            p_RECORDS(p_RECORDS.LAST) := MEX_PJM_TRANS_OFFSET_CHARGES(ORG_ID                  => NVL(TO_NUMBER(v_COLS(1)),0),
                                                                      ORG_NAME                => v_COLS(2),
                                                                      DAY                     => TO_DATE(v_COLS(3),g_SHORT_DATE_FORMAT),
                                                                      ZONE                    => v_COLS(4),
                                                                      RETAIL_PEAK_LOAD        => NVL(TO_NUMBER(v_COLS(5)),0),
                                                                      RETAIL_OFFSET_RATE      => NVL(TO_NUMBER(v_COLS(6)),0),
                                                                      RETAIL_OFFSET_CHARGE    => NVL(TO_NUMBER(v_COLS(7)),0),
                                                                      WHOLESALE_PEAK_LOAD     => NVL(TO_NUMBER(v_COLS(8)),0),
                                                                      WHOLESALE_OFFSET_RATE   => NVL(TO_NUMBER(v_COLS(9)),0),
                                                                      WHOLESALE_OFFSET_CHARGE => NVL(TO_NUMBER(v_COLS(10)),0));
        END IF;
        v_IDX := v_LINES.NEXT(v_IDX);
    END LOOP;

EXCEPTION
    WHEN OTHERS THEN
        p_STATUS  := SQLCODE;
        p_MESSAGE := 'Error in MEX_PJM_SETTLEMENT_MSRS.PARSE_NITS_OFFSET_SUMMARY: ' || SQLERRM;
END PARSE_NITS_OFFSET_SUMMARY;
----------------------------------------------------------------------------------------------------
PROCEDURE PARSE_SYNCH_CONDENS_SUMMARY
(
    p_CSV     IN CLOB,
    p_RECORDS OUT MEX_PJM_SYNCH_CONDENS_MSRS_TBL,
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
    p_RECORDS := MEX_PJM_SYNCH_CONDENS_MSRS_TBL();

    WHILE v_LINES.EXISTS(v_IDX) AND INSTR(v_LINES(v_IDX),g_REPORT_END_LINE) = 0 LOOP
        IF v_LINES(v_IDX) IS NOT NULL AND v_IDX > 5 THEN
            PARSE_UTIL.TOKENS_FROM_STRING(v_LINES(v_IDX), ',', v_COLS);

            -- remaining lines contain charge determinant data
            p_RECORDS.EXTEND();
            p_RECORDS(p_RECORDS.LAST) := MEX_PJM_SYNCH_CONDENS_MSRS(ORG_ID               => v_COLS(1),
                                                                    DAY                  => TO_DATE(v_COLS(3),g_SHORT_DATE_FORMAT),
                                                                    PJM_TOTAL_COND_CR    => NVL(TO_NUMBER(v_COLS(4)),0),
                                                                    RT_LOAD              => NVL(TO_NUMBER(v_COLS(5)),0),
                                                                    RT_EXPORTS           => NVL(TO_NUMBER(v_COLS(6)),0),
                                                                    PJM_RT_LOAD_PLUS_EXP => NVL(TO_NUMBER(v_COLS(7)),0),
                                                                    CHARGE               => NVL(TO_NUMBER(v_COLS(8)),0));
        END IF;
        v_IDX := v_LINES.NEXT(v_IDX);
    END LOOP;
EXCEPTION
    WHEN OTHERS THEN
        p_STATUS  := SQLCODE;
        p_MESSAGE := 'Error in MEX_PJM_SETTLEMENT_MSRS.PARSE_SYNCH_CONDENS_SUMMARY: ' || SQLERRM;
END PARSE_SYNCH_CONDENS_SUMMARY;
----------------------------------------------------------------------------------------------------
PROCEDURE PARSE_TOSSCD_SUMMARY
	(
	p_CSV IN CLOB,
	p_RECORDS OUT MEX_PJM_TOSSCD_SUMMARY_TBL,
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
	p_RECORDS := MEX_PJM_TOSSCD_SUMMARY_TBL();
	WHILE v_LINES.EXISTS(v_IDX) AND INSTR(v_LINES(v_IDX),g_REPORT_END_LINE) = 0 LOOP
		PARSE_UTIL.TOKENS_FROM_STRING(v_LINES(v_IDX),',',v_COLS);
		IF v_LINES(v_IDX) IS NOT NULL AND v_IDX > 5 THEN
			-- remaining lines contain charge determinant data
			p_RECORDS.EXTEND();
			p_RECORDS(p_RECORDS.LAST) := MEX_PJM_TOSSCD_SUMMARY(v_COLS(1),
											TO_DATE(v_COLS(3),g_SHORT_DATE_FORMAT),
                                            v_COLS(4), TO_NUMBER(v_COLS(5)),
											TO_NUMBER(v_COLS(6)),
											TO_NUMBER(v_COLS(7)),TO_NUMBER(v_COLS(8)));
		END IF;
		v_IDX := v_LINES.NEXT(v_IDX);
	END LOOP;
  EXCEPTION
    WHEN OTHERS THEN
      p_STATUS := SQLCODE;
      p_MESSAGE := 'Error in MEX_PJM_SETTLEMENT_MSRS.PARSE_TOSSCD_SUMMARY: ' || SQLERRM;
END PARSE_TOSSCD_SUMMARY;
----------------------------------------------------------------------------------------------------
PROCEDURE PARSE_REGULATION_SUMMARY
(
    p_CSV     IN CLOB,
    p_RECORDS OUT MEX_PJM_REGL_SUMMARY_MSRS_TBL,
    p_STATUS  OUT NUMBER,
    p_MESSAGE OUT VARCHAR2
) AS
    v_LINES    PARSE_UTIL.BIG_STRING_TABLE_MP;
    v_COLS     PARSE_UTIL.STRING_TABLE;
    v_IDX      BINARY_INTEGER;
    v_CUT_DATE DATE;

BEGIN
    p_STATUS := MEX_UTIL.g_SUCCESS;

    PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_CSV, v_LINES);
    v_IDX := v_LINES.FIRST;
    IF v_LINES.LAST = v_IDX THEN
        p_STATUS := 1;
        RETURN;
    END IF;

    p_RECORDS := MEX_PJM_REGL_SUMMARY_MSRS_TBL();
    WHILE v_LINES.EXISTS(v_IDX) AND INSTR(v_LINES(v_IDX),g_REPORT_END_LINE) = 0 LOOP
        -- skip first 5 rows (header info), empty lines and the 'End of Report' line
        IF v_LINES(v_IDX) IS NOT NULL AND v_IDX > 5 THEN
            PARSE_UTIL.TOKENS_FROM_STRING(v_LINES(v_IDX), ',', v_COLS);

           v_CUT_DATE := NEW_TIME(TO_DATE(v_COLS(4),g_GMT_HR_END_FORMAT), 'GMT', 'EST');
            -- remaining lines contain charge determinant data
            p_RECORDS.EXTEND();
            p_RECORDS(p_RECORDS.LAST) := MEX_PJM_REGL_SUMMARY_MSRS(ORG_ID                     => v_COLS(1),
                                                                   CUT_DATE                   => v_CUT_DATE,
                                                                   TOTAL_ASSIGNED_REG         => NVL(TO_NUMBER(v_COLS(5)),0),
                                                                   RT_LOAD                    => NVL(TO_NUMBER(v_COLS(6)),0),
                                                                   TOTAL_PJM_RT_LOAD          => NVL(TO_NUMBER(v_COLS(7)),0),
                                                                   REGULATION_OBLIGATION      => NVL(TO_NUMBER(v_COLS(8)),0),
                                                                   BILATERAL_REG_SALES        => NVL(TO_NUMBER(v_COLS(9)),0),
                                                                   BILATERAL_REG_PURCHASES    => NVL(TO_NUMBER(v_COLS(10)),0),
                                                                   ADJUSTED_REG_OBLIGATION    => NVL(TO_NUMBER(v_COLS(11)),0),
                                                                   REGULATION_CLEARING_PRICE  => NVL(TO_NUMBER(v_COLS(12)),0),
                                                                   CHARGE                     => NVL(TO_NUMBER(v_COLS(13)),0),
                                                                   PJM_ASSIGNED_REG           => NVL(TO_NUMBER(v_COLS(14)),0),
                                                                   SELF_SCHEDULED_REG         => NVL(TO_NUMBER(v_COLS(15)),0),
                                                                   REG_PURCHASES              => NVL(TO_NUMBER(v_COLS(16)),0),
                                                                   TOTAL_SYSTEM_REG_PURCHASES => NVL(TO_NUMBER(v_COLS(17)),0),
                                                                   PJM_REG_LOST_OPP_CREDIT    => NVL(TO_NUMBER(v_COLS(18)),0),
                                                                   OPPORTUNITY_COST_CHARGE    => NVL(TO_NUMBER(v_COLS(19)),0),
                                                                   CREDIT                     => NVL(TO_NUMBER(v_COLS(20)),0),
                                                                   OPPORTUNITY_COST_CREDIT    => NVL(TO_NUMBER(v_COLS(21)),0));
        END IF;
        v_IDX := v_LINES.NEXT(v_IDX);
    END LOOP;
EXCEPTION
    WHEN OTHERS THEN
        p_STATUS  := SQLCODE;
        p_MESSAGE := 'Error in MEX_PJM_SETTLEMENT_MSRS.PARSE_REGULATION_SUMMARY: ' || SQLERRM;
END PARSE_REGULATION_SUMMARY;
----------------------------------------------------------------------------------------------------
PROCEDURE PARSE_REGULATION_CREDITS
    (
    p_CSV     IN CLOB,
    p_RECORDS OUT MEX_PJM_REGULATION_CREDIT_TBL,
    p_STATUS  OUT NUMBER,
    p_MESSAGE OUT VARCHAR2
    ) AS
    v_LINES    PARSE_UTIL.BIG_STRING_TABLE_MP;
    v_COLS     PARSE_UTIL.STRING_TABLE;
    v_IDX      BINARY_INTEGER;
    v_CUT_DATE DATE;

BEGIN
    p_STATUS := MEX_UTIL.g_SUCCESS;

    PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_CSV, v_LINES);
    v_IDX := v_LINES.FIRST;
    IF v_LINES.LAST = v_IDX THEN
        p_STATUS := 1;
        RETURN;
    END IF;

    p_RECORDS := MEX_PJM_REGULATION_CREDIT_TBL();
    WHILE v_LINES.EXISTS(v_IDX) AND INSTR(v_LINES(v_IDX),g_REPORT_END_LINE) = 0 LOOP
        -- skip first 5 rows (header info), empty lines and the 'End of Report' line
        IF v_LINES(v_IDX) IS NOT NULL AND v_IDX > 5 THEN
            PARSE_UTIL.TOKENS_FROM_STRING(v_LINES(v_IDX), ',', v_COLS);

            v_CUT_DATE := NEW_TIME(TO_DATE(v_COLS(4),g_GMT_HR_END_FORMAT), 'GMT', 'EST');
            -- remaining lines contain charge determinant data
            p_RECORDS.EXTEND();
            p_RECORDS(p_RECORDS.LAST) :=  MEX_PJM_REGULATION_CREDIT(ORG_ID               => v_COLS(1),
                                                                   ORG_NAME             => v_COLS(2),
                                                                   CUT_DATE             => v_CUT_DATE,
                                                                   UNIT_ID              => v_COLS(5),
                                                                   UNIT_NAME            => v_COLS(6),
                                                                   UNIT_OWN_SHARE       => NVL(TO_NUMBER(v_COLS(7)),0),
                                                                   PJM_ASSIGNED_REG     => NVL(TO_NUMBER(v_COLS(8)),0),
                                                                   SELF_SCHED_REG       => NVL(TO_NUMBER(v_COLS(9)),0),
                                                                   RMCP                 => NVL(TO_NUMBER(v_COLS(10)),0),
                                                                   RMCP_CREDIT          => NVL(TO_NUMBER(v_COLS(11)),0),
                                                                   BIAS_FACTOR          => NVL(TO_NUMBER(v_COLS(12)),0),
                                                                   RT_LMP_DESIRED_MWH   => NVL(TO_NUMBER(v_COLS(13)),0),
                                                                   RT_GEN_LMP           => NVL(TO_NUMBER(v_COLS(14)),0),
                                                                   HYDRO_SPILL_INDICATOR    => v_COLS(15),
                                                                   REG_OFFER_PRICE      => NVL(TO_NUMBER(v_COLS(16)),0),
                                                                   REG_OFFER_AMOUNT     => NVL(TO_NUMBER(v_COLS(17)),0),
                                                                   REG_LOC              => NVL(TO_NUMBER(v_COLS(18)),0),
                                                                   REG_LOC_CREDIT       => NVL(TO_NUMBER(v_COLS(19)),0));
        END IF;
        v_IDX := v_LINES.NEXT(v_IDX);
    END LOOP;
EXCEPTION
    WHEN OTHERS THEN
        p_STATUS  := SQLCODE;
        p_MESSAGE := 'Error in MEX_PJM_SETTLEMENT_MSRS.PARSE_REGULATION_CREDITS: ' || SQLERRM;
END PARSE_REGULATION_CREDITS;
----------------------------------------------------------------------------------------------------
PROCEDURE PARSE_FTR_AUCTION
	(
	p_CSV IN CLOB,
	p_RECORDS OUT MEX_PJM_FTR_AUCTION_TBL_MSRS,
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
	p_RECORDS := MEX_PJM_FTR_AUCTION_TBL_MSRS();
	WHILE v_LINES.EXISTS(v_IDX) AND INSTR(v_LINES(v_IDX),g_REPORT_END_LINE) = 0 LOOP
		PARSE_UTIL.TOKENS_FROM_STRING(v_LINES(v_IDX),',',v_COLS);
		IF v_LINES(v_IDX) IS NOT NULL AND v_IDX > 5 THEN
			-- remaining lines contain charge determinant data
			p_RECORDS.EXTEND();
			p_RECORDS(p_RECORDS.LAST) := MEX_PJM_FTR_AUCTION_MSRS(v_COLS(1),
											TO_DATE(v_COLS(3),g_SHORT_DATE_FORMAT),
											v_COLS(7),v_COLS(8),
											v_COLS(10),v_COLS(11),
											TO_NUMBER(v_COLS(12)),TO_NUMBER(v_COLS(13)),
											TO_NUMBER(v_COLS(14)),TO_NUMBER(v_COLS(15)));
		END IF;
		v_IDX := v_LINES.NEXT(v_IDX);
	END LOOP;
  EXCEPTION
    WHEN OTHERS THEN
      p_STATUS := SQLCODE;
      p_MESSAGE := 'Error in MEX_PJM_SETTLEMENT_MSRS.PARSE_FTR_AUCTION: ' || SQLERRM;
END PARSE_FTR_AUCTION;
----------------------------------------------------------------------------------------------------
PROCEDURE PARSE_FTR_TARGET_CREDITS
	(
	p_CSV IN CLOB,
	p_WORK_ID IN NUMBER,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) AS
v_LINES PARSE_UTIL.BIG_STRING_TABLE_MP;
v_COLS PARSE_UTIL.STRING_TABLE;
v_IDX BINARY_INTEGER;

v_ROW MEX_PJM_FTR_ALLOC_WORK%ROWTYPE;
v_SINK_LMPS PARSE_UTIL.STRING_TABLE;
v_SOURCE_LMPS PARSE_UTIL.STRING_TABLE;
v_TRANSACTION_DATE DATE;
v_PREV_TXN_ID NUMBER := 0;
v_CUT_DATE DATE;

	--calculate the CUT_DATE
	FUNCTION GET_CUT_DATE (p_TRANSACTION_DATE IN DATE, p_COL_IDX IN NUMBER) RETURN DATE IS
		v_HOUR NUMBER;
		v_DATE DATE;

	BEGIN
		v_DATE := p_TRANSACTION_DATE;
		--CALCULATE THE HOUR
        IF p_COL_IDX =13 THEN--HOUR 1
        	v_HOUR := p_COL_IDX - 12;

		ELSIF p_COL_IDX = 14 THEN --FIRST HE 02 (CHEDK FOR SPRING AHEAD DATE)
			IF TRUNC(v_DATE) = TRUNC(DST_SPRING_AHEAD_DATE(v_DATE)) THEN
				v_HOUR := p_COL_IDX - 11; --HOUR 3
			ELSE
				v_HOUR := p_COL_IDX - 12; --HOUR 2
			END IF;

		ELSIF p_COL_IDX = 15 THEN --SECOND HE 02* (NON-ZERO ON DST FALL BACK)
        	IF TRUNC(p_TRANSACTION_DATE) = TRUNC(DST_FALL_BACK_DATE(p_TRANSACTION_DATE)) THEN
        		v_HOUR := 25;
        	ELSE
        	 	v_DATE := NULL; --IGNORE SECOND HE 02
        	END IF;

		ELSIF p_COL_IDX = 16 THEN --HE 03 (SKIP IF SPRING AHEAD DATE)
			IF TRUNC(v_DATE) = TRUNC(DST_SPRING_AHEAD_DATE(v_DATE)) THEN
				v_DATE := NULL; -- skip 3rd hour
			ELSE
				v_HOUR := p_COL_IDX - 13;
			END IF;

		ELSE --HOURS 4 TO 24
        	v_HOUR := p_COL_IDX - 13;
        END IF;

        --CALCULATE THE CUT_DATE
        IF v_DATE IS NOT NULL THEN
            IF v_HOUR = 25 THEN
                -- 25th hour represents the second hour-two
                v_DATE := v_DATE + 2 / 24 + (1 / (24 * 60 * 60));
            ELSE
                v_DATE := v_DATE + v_HOUR / 24;
            END IF;

            v_DATE := TO_CUT(v_DATE, MM_PJM_UTIL.g_PJM_TIME_ZONE);
        END IF;

		RETURN v_DATE;
	END GET_CUT_DATE;
    -----------------------------------------------

BEGIN
	p_STATUS := MEX_UTIL.g_SUCCESS;

	PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_CSV,v_LINES);
	v_IDX := v_LINES.FIRST;

	v_ROW.WORK_ID := p_WORK_ID;
	WHILE v_LINES.EXISTS(v_IDX) AND INSTR(v_LINES(v_IDX),g_REPORT_END_LINE) = 0 LOOP
		PARSE_UTIL.TOKENS_FROM_STRING(v_LINES(v_IDX),',',v_COLS);

		IF v_IDX > 5 THEN
			IF v_PREV_TXN_ID <> v_COLS(4) THEN
				v_ROW.ORG_IDENT := v_COLS(1);
				v_TRANSACTION_DATE := TO_DATE(v_COLS(3), g_SHORT_DATE_FORMAT);
				v_ROW.TRANSACTION_IDENT := v_COLS(4);
				v_PREV_TXN_ID := v_ROW.TRANSACTION_IDENT;
				v_ROW.FTR_MW := TO_NUMBER(v_COLS(5));
				v_ROW.SINK_NAME := v_COLS(6);
				v_ROW.SINK_PNODE_ID := TO_NUMBER(v_COLS(7));
				v_ROW.SOURCE_NAME := v_COLS(8);
				v_ROW.SOURCE_PNODE_ID := TO_NUMBER(v_COLS(9));
				v_ROW.HEDGE_TYPE := v_COLS(10);
				v_ROW.ALLOCATION_PCT := TO_NUMBER(v_COLS(11));
			END IF;

			IF UPPER(v_COLS(12)) = 'SINK DA CONGESTION PRICE ($/MWH)' THEN
				v_SINK_LMPS := v_COLS;
			ELSIF UPPER(v_COLS(12)) = 'SOURCE DA CONGESTION PRICE ($/MWH)' THEN
				v_SOURCE_LMPS := v_COLS;
			ELSIF UPPER(v_COLS(12)) = 'TARGET CREDIT ($)' THEN

				FOR I IN 13 .. 37 LOOP
					--Calculate the cut_date
					v_CUT_DATE := GET_CUT_DATE (v_TRANSACTION_DATE, I);
					IF v_CUT_DATE IS NOT NULL THEN
						v_ROW.CUT_DATE := v_CUT_DATE;
						v_ROW.SINK_LMP := TO_NUMBER(v_SINK_LMPS(I));
						v_ROW.SOURCE_LMP := TO_NUMBER(v_SOURCE_LMPS(I));
						v_ROW.Target_Allocation := TO_NUMBER(v_COLS(I));

						INSERT INTO MEX_PJM_FTR_ALLOC_WORK VALUES v_ROW;
					END IF;
				END LOOP; --END LOOP OVER HOURS
			END IF;

		END IF;

		v_IDX := v_LINES.NEXT(v_IDX);
	END LOOP;

    COMMIT;


  EXCEPTION
    WHEN OTHERS THEN
      p_STATUS := SQLCODE;
      p_MESSAGE := 'Error in MEX_PJM_SETTLEMENT_MSRS.PARSE_FTR_TARGET_CREDITS: ' || SQLERRM;
END PARSE_FTR_TARGET_CREDITS;
----------------------------------------------------------------------------------------------------
PROCEDURE PARSE_BLACK_START_SUMMARY
    (
    p_CSV     IN CLOB,
    p_RECORDS OUT MEX_PJM_BLACKSTART_SUMMARY_TBL,
    p_STATUS  OUT NUMBER,
    p_MESSAGE OUT VARCHAR2
    ) AS
v_LINES PARSE_UTIL.BIG_STRING_TABLE_MP;
v_COLS  PARSE_UTIL.STRING_TABLE;
v_IDX   BINARY_INTEGER;
BEGIN
	p_STATUS := MEX_UTIL.g_SUCCESS;

	PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_CSV, v_LINES);

    v_IDX := v_LINES.FIRST;
	p_RECORDS := MEX_PJM_BLACKSTART_SUMMARY_TBL();

    WHILE v_LINES.EXISTS(v_IDX) AND INSTR(v_LINES(v_IDX),g_REPORT_END_LINE) = 0 LOOP
		PARSE_UTIL.PARSE_DELIMITED_STRING(v_LINES(v_IDX), ',', v_COLS);
		IF v_LINES(v_IDX) IS NOT NULL AND v_IDX > 5 THEN
		    -- remaining lines contain charge determinant data
			p_RECORDS.EXTEND();
			p_RECORDS(p_RECORDS.LAST) := MEX_PJM_BLACKSTART_SUMMARY(v_COLS(1),
											 TRUNC(TO_DATE(v_COLS(3),'Month, YYYY'), 'MM'),
                                             v_COLS(4),
											 TO_NUMBER(v_COLS(5)),
											 TO_NUMBER(v_COLS(7)),
											 TO_NUMBER(v_COLS(9)),
											 TO_NUMBER(v_COLS(10)),
											 TO_NUMBER(v_COLS(8)),
											 TO_NUMBER(v_COLS(11)),
											 TO_NUMBER(v_COLS(12)),
											 NULL);
        END IF;
		v_IDX := v_LINES.NEXT(v_IDX);
	END LOOP;
EXCEPTION
	WHEN OTHERS THEN
		p_STATUS  := SQLCODE;
		p_MESSAGE := 'Error in MEX_PJM_SETTLEMENT_MSRS.PARSE_BLACK_START_SUMMARY: ' ||
								 SQLERRM;
END PARSE_BLACK_START_SUMMARY;
----------------------------------------------------------------------------------------------------
PROCEDURE PARSE_ARR_SUMMARY
    (
    p_CSV IN CLOB,
    p_RECORDS OUT MEX_PJM_ARR_SUMMARY_TBL_MSRS,
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
	p_RECORDS := MEX_PJM_ARR_SUMMARY_TBL_MSRS();

	WHILE v_LINES.EXISTS(v_IDX) AND INSTR(v_LINES(v_IDX),g_REPORT_END_LINE) = 0 LOOP
		PARSE_UTIL.PARSE_DELIMITED_STRING(v_LINES(v_IDX), ',', v_COLS);
		IF v_LINES(v_IDX) IS NOT NULL AND v_IDX > 5 THEN
			-- remaining lines contain charge determinant data
			p_RECORDS.EXTEND();
			p_RECORDS(p_RECORDS.LAST) := MEX_PJM_ARR_SUMMARY_MSRS(v_COLS(1),
                                     v_COLS(2),
									 TO_DATE(v_COLS(3), g_SHORT_DATE_FORMAT),
									 TO_NUMBER(v_COLS(4)),
									 v_COLS(6),
									 v_COLS(7),
									 v_COLS(8),
									 TO_NUMBER(v_COLS(9)),
									 TO_NUMBER(v_COLS(10)),
                                     TO_NUMBER(v_COLS(11)),
                                     TO_NUMBER(v_COLS(12)),
                                     TO_NUMBER(v_COLS(13)));
		END IF;
		v_IDX := v_LINES.NEXT(v_IDX);
	END LOOP;
EXCEPTION
	WHEN OTHERS THEN
		p_STATUS  := SQLCODE;
		p_MESSAGE := 'Error in MEX_PJM_SETTLEMENT_MSRS.PARSE_ARR_SUMMARY: ' || SQLERRM;
END PARSE_ARR_SUMMARY;
----------------------------------------------------------------------------------------------------
PROCEDURE PARSE_REACTIVE_SUMMARY
    (
    p_CSV     IN CLOB,
    p_RECORDS OUT MEX_PJM_REACTIVE_SUMMARY_TBL,
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
	p_RECORDS := MEX_PJM_REACTIVE_SUMMARY_TBL();
	WHILE v_LINES.EXISTS(v_IDX) AND INSTR(v_LINES(v_IDX),g_REPORT_END_LINE) = 0 LOOP
		PARSE_UTIL.PARSE_DELIMITED_STRING(v_LINES(v_IDX), ',', v_COLS);
		IF v_LINES(v_IDX) IS NOT NULL AND v_IDX > 5 THEN
			-- remaining lines contain charge determinant data
			p_RECORDS.EXTEND();
			p_RECORDS(p_RECORDS.LAST) := MEX_PJM_REACTIVE_SUMMARY(v_COLS(1),
																TRUNC(TO_DATE(v_COLS(3), 'Month,YYYY'),'MM'),
																v_COLS(4),
        														TO_NUMBER(v_COLS(5)),
        														TO_NUMBER(v_COLS(7)),
        														TO_NUMBER(v_COLS(9)),
        														TO_NUMBER(v_COLS(10)),
        														TO_NUMBER(v_COLS(8)),
        														TO_NUMBER(v_COLS(11)),
        														TO_NUMBER(v_COLS(12)),
                                                                NULL);
		END IF;
		v_IDX := v_LINES.NEXT(v_IDX);
	END LOOP;
EXCEPTION
	WHEN OTHERS THEN
		p_STATUS  := SQLCODE;
		p_MESSAGE := 'Error in MEX_PJM_SETTLEMENT_MSRS.PARSE_REACTIVE_SUMMARY: ' ||
								 SQLERRM;
END PARSE_REACTIVE_SUMMARY;
----------------------------------------------------------------------------------------------------
PROCEDURE PARSE_EN_IMB_CRE_SUMMARY
    (
    p_CSV     IN CLOB,
    p_RECORDS OUT MEX_PJM_EN_IMB_CR_SUM_TBL_MSRS,
    p_STATUS  OUT NUMBER,
    p_MESSAGE OUT VARCHAR2
    ) AS
v_LINES PARSE_UTIL.BIG_STRING_TABLE_MP;
v_COLS  PARSE_UTIL.STRING_TABLE;
v_IDX   BINARY_INTEGER;
v_CUT_DATE DATE;

BEGIN
	p_STATUS := MEX_UTIL.g_SUCCESS;

	PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_CSV, v_LINES);

	v_IDX     := v_LINES.FIRST;
	p_RECORDS := MEX_PJM_EN_IMB_CR_SUM_TBL_MSRS();

	WHILE v_LINES.EXISTS(v_IDX) AND INSTR(v_LINES(v_IDX),g_REPORT_END_LINE) = 0 LOOP
		PARSE_UTIL.PARSE_DELIMITED_STRING(v_LINES(v_IDX), ',', v_COLS);
		IF v_LINES(v_IDX) IS NOT NULL AND v_IDX > 5 THEN
            v_CUT_DATE := NEW_TIME(TO_DATE(v_COLS(4),g_GMT_HR_END_FORMAT), 'GMT', 'EST');
			-- remaining lines contain charge determinant data
			p_RECORDS.EXTEND();
			p_RECORDS(p_RECORDS.LAST) := MEX_PJM_EN_IMB_CRED_SUMM_MSRS(v_COLS(1),
															v_CUT_DATE,
															TO_NUMBER(v_COLS(5)));
		END IF;
		v_IDX := v_LINES.NEXT(v_IDX);
	END LOOP;
EXCEPTION
	WHEN OTHERS THEN
		p_STATUS  := SQLCODE;
		p_MESSAGE := 'Error in MEX_PJM_SETTLEMENT_MSRS.PARSE_EN_IMB_CRE_SUMMARY: ' ||
								 SQLERRM;
END PARSE_EN_IMB_CRE_SUMMARY;
----------------------------------------------------------------------------------------------------
PROCEDURE PARSE_SYNC_RES_T1_CHG_SUMMARY
(
    p_CSV     IN CLOB,
    p_STATUS  OUT NUMBER,
    p_MESSAGE OUT VARCHAR2
) AS
    v_LINES    PARSE_UTIL.BIG_STRING_TABLE_MP;
    v_COLS     PARSE_UTIL.STRING_TABLE;
    v_IDX      BINARY_INTEGER;
    v_CUT_DATE DATE;
    v_ORG_ID   PJM_SYNC_RESERVE_SUMMARY.ORG_ID%TYPE;

BEGIN
    p_STATUS := MEX_UTIL.g_SUCCESS;
    PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_CSV, v_LINES);

    v_IDX := v_LINES.FIRST;
    IF v_LINES.LAST = v_IDX THEN
        p_STATUS := 1;
        RETURN;
    END IF;

    WHILE v_LINES.EXISTS(v_IDX) AND INSTR(v_LINES(v_IDX),g_REPORT_END_LINE) = 0 LOOP
		-- skip first 5 rows (header info), empty lines and the 'End of Report' line
        IF v_LINES(v_IDX) IS NOT NULL AND v_IDX > 5 THEN
        	PARSE_UTIL.TOKENS_FROM_STRING(v_LINES(v_IDX), ',', v_COLS);

            v_CUT_DATE := NEW_TIME(TO_DATE(v_COLS(4),g_GMT_HR_END_FORMAT), 'GMT', 'EST');

            v_ORG_ID   := v_COLS(1);
            -- remaining lines contain charge determinant data
            UPDATE PJM_SYNC_RESERVE_SUMMARY
            SET SUBZONE                     = v_COLS(6),
                MEMBER_TIER1_ALLOC_TO_OBLIG = v_COLS(10),
                TOTAL_TIER1_ALLOC_TO_OBLIG  = v_COLS(11),
                TIER1_CHARGE                = v_COLS(12)
            WHERE ORG_ID = v_ORG_ID
              AND CUT_DATE = v_CUT_DATE
        	  AND SPINNING_RESERVE_ZONE = v_COLS(5);

			IF SQL%NOTFOUND THEN
                INSERT INTO PJM_SYNC_RESERVE_SUMMARY
				FIELDS (ORG_ID, ORG_NAME, CUT_DATE, SPINNING_RESERVE_ZONE, SUBZONE,
				        MEMBER_TIER1_ALLOC_TO_OBLIG, TOTAL_TIER1_ALLOC_TO_OBLIG, TIER1_CHARGE
						)
                VALUES
                    (v_ORG_ID, v_COLS(2), v_CUT_DATE, v_COLS(5), v_COLS(6),
                     NVL(TO_NUMBER(V_COLS(10)), 0), NVL(TO_NUMBER(V_COLS(11)), 0), NVL(TO_NUMBER(V_COLS(12)), 0)
                     );
            END IF;
        END IF;
        v_IDX := v_LINES.NEXT(v_IDX);
    END LOOP;
EXCEPTION
    WHEN OTHERS THEN
        p_STATUS  := SQLCODE;
        p_MESSAGE := 'Error in MEX_PJM_SETTLEMENT_MSRS.PARSE_SYNC_RES_T1_CHG_SUMMARY: ' ||
                     SQLERRM;
END PARSE_SYNC_RES_T1_CHG_SUMMARY;
----------------------------------------------------------------------------------------------------
PROCEDURE PARSE_SYNC_RES_T2_CHG_SUMMARY
(
    p_CSV     IN CLOB,
    p_STATUS  OUT NUMBER,
    p_MESSAGE OUT VARCHAR2
) AS
    v_LINES    PARSE_UTIL.BIG_STRING_TABLE_MP;
    v_COLS     PARSE_UTIL.STRING_TABLE;
    v_IDX      BINARY_INTEGER;
    v_CUT_DATE DATE;
    v_ORG_ID   PJM_SYNC_RESERVE_SUMMARY.ORG_ID%TYPE;

BEGIN
    p_STATUS := MEX_UTIL.g_SUCCESS;
    PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_CSV, v_LINES);

    v_IDX := v_LINES.FIRST;
    IF v_LINES.LAST = v_IDX THEN
        p_STATUS := 1;
        RETURN;
    END IF;

    WHILE v_LINES.EXISTS(v_IDX) AND INSTR(v_LINES(v_IDX),g_REPORT_END_LINE) = 0 LOOP
		-- skip first 5 rows (header info), empty lines and the 'End of Report' line
        IF v_LINES(v_IDX) IS NOT NULL AND v_IDX > 5 THEN
        	PARSE_UTIL.TOKENS_FROM_STRING(v_LINES(v_IDX), ',', v_COLS);

            v_CUT_DATE := NEW_TIME(TO_DATE(v_COLS(4),g_GMT_HR_END_FORMAT), 'GMT', 'EST');

            v_ORG_ID   := v_COLS(1);
            -- remaining lines contain charge determinant data
            UPDATE PJM_SYNC_RESERVE_SUMMARY
            SET SUBZONE                  = v_COLS(6),
                SRMCP                    = NVL(TO_NUMBER(v_COLS(8)), 0),
                PJM_TOTAL_SPIN_PURCHASES = NVL(TO_NUMBER(v_COLS(11)), 0),
                OPP_COST_CHARGE_CLEARED  = NVL(TO_NUMBER(v_COLS(13)), 0),
                TIER1_LOST               = NVL(TO_NUMBER(v_COLS(15)), 0),
                TOTAL_TIER1_LOST         = NVL(TO_NUMBER(v_COLS(16)), 0),
                OPP_COST_CHARGE_ADDED    = NVL(TO_NUMBER(v_COLS(17)), 0),
                SRMCP_CHARGE             = NVL(TO_NUMBER(v_COLS(9)), 0)
            WHERE ORG_ID = v_ORG_ID
              AND CUT_DATE = v_CUT_DATE
              AND SPINNING_RESERVE_ZONE = v_COLS(5);

            IF SQL%NOTFOUND THEN
                INSERT INTO PJM_SYNC_RESERVE_SUMMARY
				FIELDS (ORG_ID, ORG_NAME, CUT_DATE, SPINNING_RESERVE_ZONE, SUBZONE, SRMCP,
				       PJM_TOTAL_SPIN_PURCHASES, OPP_COST_CHARGE_CLEARED, TIER1_LOST,
					   TOTAL_TIER1_LOST, OPP_COST_CHARGE_ADDED, SRMCP_CHARGE
				        )
                VALUES
                    (v_ORG_ID, v_COLS(2), v_CUT_DATE, v_COLS(5), v_COLS(6),  NVL(TO_NUMBER(v_COLS(8)), 0),
                     NVL(TO_NUMBER(v_COLS(11)), 0),NVL(TO_NUMBER(v_COLS(13)), 0), NVL(TO_NUMBER(v_COLS(15)), 0),
                     NVL(TO_NUMBER(v_COLS(16)), 0), NVL(TO_NUMBER(v_COLS(17)), 0), NVL(TO_NUMBER(v_COLS(9)), 0)
					 );
            END IF;
        END IF;
        v_IDX := v_LINES.NEXT(v_IDX);
    END LOOP;
EXCEPTION
    WHEN OTHERS THEN
        p_STATUS  := SQLCODE;
        p_MESSAGE := 'Error in MEX_PJM_SETTLEMENT_MSRS.PARSE_SYNC_RES_T2_CHG_SUMMARY: ' || SQLERRM;
END PARSE_SYNC_RES_T2_CHG_SUMMARY;
----------------------------------------------------------------------------------------------------
PROCEDURE PARSE_SYNC_RES_OBL
(
    p_CSV     IN CLOB,
    p_STATUS  OUT NUMBER,
    p_MESSAGE OUT VARCHAR2
) AS
    v_LINES    PARSE_UTIL.BIG_STRING_TABLE_MP;
    v_COLS     PARSE_UTIL.STRING_TABLE;
    v_IDX      BINARY_INTEGER;
    v_CUT_DATE DATE;
    v_ORG_ID   PJM_SYNC_RESERVE_SUMMARY.ORG_ID%TYPE;

BEGIN
    p_STATUS := MEX_UTIL.g_SUCCESS;
    PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_CSV, v_LINES);

    v_IDX := v_LINES.FIRST;
    IF v_LINES.LAST = v_IDX THEN
        p_STATUS := 1;
        RETURN;
    END IF;

    WHILE v_LINES.EXISTS(v_IDX) AND INSTR(v_LINES(v_IDX),g_REPORT_END_LINE) = 0 LOOP
		-- skip first 5 rows (header info), empty lines and the 'End of Report' line
        IF v_LINES(v_IDX) IS NOT NULL AND v_IDX > 5 THEN
        	PARSE_UTIL.TOKENS_FROM_STRING(v_LINES(v_IDX), ',', v_COLS);

            v_CUT_DATE := NEW_TIME(TO_DATE(v_COLS(4),g_GMT_HR_END_FORMAT), 'GMT', 'EST');

            v_ORG_ID   := v_COLS(1);
            -- remaining lines contain charge determinant data
            UPDATE PJM_SYNC_RESERVE_SUMMARY
            SET SUBZONE                  = v_COLS(6),
                SUBZONE_LOAD             = NVL(TO_NUMBER(V_COLS(8)), 0),
                TOTAL_SUBZONE_LOAD       = NVL(TO_NUMBER(V_COLS(9)), 0),
                SPIN_OBLIGATION          = NVL(TO_NUMBER(V_COLS(11)), 0),
                TIER1_ESTIMATE_MWH       = NVL(TO_NUMBER(V_COLS(15)), 0),
                BILATERAL_SPIN_PURCHASES = NVL(TO_NUMBER(V_COLS(13)), 0),
                BILATERAL_SPIN_SALES     = NVL(TO_NUMBER(V_COLS(12)), 0),
                ADJUSTED_OBLIGATION      = NVL(TO_NUMBER(V_COLS(14)), 0),
                TIER2_SELF_ASSIGNED_MWH  = NVL(TO_NUMBER(V_COLS(22)), 0),
                TIER2_SHORTFALL          = NVL(TO_NUMBER(V_COLS(10)), 0)
            WHERE ORG_ID = v_ORG_ID
              AND CUT_DATE = v_CUT_DATE
              AND SPINNING_RESERVE_ZONE = v_COLS(5);

            IF SQL%NOTFOUND THEN
                INSERT INTO PJM_SYNC_RESERVE_SUMMARY
				FIELDS (ORG_ID, ORG_NAME, CUT_DATE, SPINNING_RESERVE_ZONE, SUBZONE, SUBZONE_LOAD, TOTAL_SUBZONE_LOAD,
				        SPIN_OBLIGATION, TIER1_ESTIMATE_MWH, BILATERAL_SPIN_PURCHASES, BILATERAL_SPIN_SALES,
				        ADJUSTED_OBLIGATION, TIER2_SELF_ASSIGNED_MWH, TIER2_SHORTFALL
				       )
                VALUES
                    (v_ORG_ID, v_COLS(2), v_CUT_DATE, v_COLS(5), v_COLS(6), NVL(TO_NUMBER(V_COLS(8)), 0), NVL(TO_NUMBER(V_COLS(9)), 0),
                     NVL(TO_NUMBER(V_COLS(11)), 0), NVL(TO_NUMBER(V_COLS(15)), 0),NVL(TO_NUMBER(V_COLS(13)), 0), NVL(TO_NUMBER(V_COLS(12)), 0),
					 NVL(TO_NUMBER(V_COLS(14)), 0), NVL(TO_NUMBER(V_COLS(22)), 0), NVL(TO_NUMBER(V_COLS(10)), 0));
            END IF;
        END IF;
        v_IDX := v_LINES.NEXT(v_IDX);
    END LOOP;


EXCEPTION
    WHEN OTHERS THEN
        p_STATUS  := SQLCODE;
        p_MESSAGE := 'Error in MEX_PJM_SETTLEMENT_MSRS.PARSE_SYNC_RES_OBL: ' ||
                     SQLERRM;
END PARSE_SYNC_RES_OBL;
----------------------------------------------------------------------------------------------------
PROCEDURE PARSE_EXPLICIT_CONGESTION
(
    p_CSV     IN CLOB,
    p_STATUS  OUT NUMBER,
    p_MESSAGE OUT VARCHAR2
) AS
    v_LINES PARSE_UTIL.BIG_STRING_TABLE_MP;
    v_COLS  PARSE_UTIL.STRING_TABLE;
    v_IDX   BINARY_INTEGER;
    v_CUT_DATE DATE;

BEGIN
    p_STATUS := MEX_UTIL.g_SUCCESS;

    PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_CSV, v_LINES);
    v_IDX := v_LINES.FIRST;
    IF v_LINES.LAST = v_IDX THEN
        p_STATUS := 1;
        RETURN;
    END IF;

    WHILE v_LINES.EXISTS(v_IDX) AND INSTR(v_LINES(v_IDX),g_REPORT_END_LINE) = 0 LOOP
		-- skip first 5 rows (header info), empty lines and the 'End of Report' line
        IF v_LINES(v_IDX) IS NOT NULL AND v_IDX > 5 THEN
        	PARSE_UTIL.PARSE_DELIMITED_STRING(v_LINES(v_IDX), ',', v_COLS);

             --perform NEW TIME on the GMT column
            v_CUT_DATE := NEW_TIME(TO_DATE(v_COLS(4), g_GMT_HR_END_FORMAT),'GMT', 'EST');

            INSERT INTO PJM_EXPLICIT_CONG_CHARGES
				(ORG_NID,
				CUT_DATE,
				ENERGY_ID,
				NERC_TAG,
				OASIS_ID,
				BUYER,
				SELLER,
				SINK_NAME,
				SOURCE_NAME,
				DA_TRANSACTION_MWH,
				DA_SINK_CONG_PRICE,
				DA_SOURCE_CONG_PRICE,
				DA_EXP_CONG_CHARGE,
				RT_TRANSACTION_MWH,
				BAL_DEV_MWH,
				RT_SINK_CONG_PRICE,
				RT_SOURCE_CONG_PRICE,
				BAL_EXP_CONG_CHARGE)
            VALUES
                (v_COLS(1),
                 v_CUT_DATE,
                 v_COLS(5),
                 v_COLS(6),
                 v_COLS(7),
                 v_COLS(8),
                 v_COLS(9),
                 v_COLS(10),
                 v_COLS(12),
                 TO_NUMBER(v_COLS(14)),
                 TO_NUMBER(v_COLS(15)),
                 TO_NUMBER(v_COLS(16)),
                 TO_NUMBER(v_COLS(17)),
                 TO_NUMBER(v_COLS(18)),
                 TO_NUMBER(v_COLS(19)),
                 TO_NUMBER(v_COLS(20)),
                 TO_NUMBER(v_COLS(21)),
                 TO_NUMBER(v_COLS(22)));

        END IF;
        v_IDX := v_LINES.NEXT(v_IDX);
    END LOOP;

    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        p_STATUS  := SQLCODE;
        p_MESSAGE := 'Error in MEX_PJM_SETTLEMENT_MSRS.PARSE_EXPLICIT_CONGESTION: ' || SQLERRM;
END PARSE_EXPLICIT_CONGESTION;
----------------------------------------------------------------------------------------------------
PROCEDURE PARSE_FIRM_TRANS_SERV_CHARGES
	(
	p_CSV IN CLOB,
	p_RECORDS OUT MEX_PJM_TRAN_SERV_CHG_TBL_MSRS,
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
	p_RECORDS := MEX_PJM_TRAN_SERV_CHG_TBL_MSRS();
	WHILE v_LINES.EXISTS(v_IDX) AND INSTR(v_LINES(v_IDX),g_REPORT_END_LINE) = 0 LOOP
		IF v_LINES(v_IDX) IS NOT NULL AND v_IDX > 5 THEN
            PARSE_UTIL.PARSE_DELIMITED_STRING(v_LINES(v_IDX),',',v_COLS);
        	-- remaining lines contain charge determinant data
			p_RECORDS.EXTEND();
			p_RECORDS(p_RECORDS.LAST) := MEX_PJM_TRANS_SERV_CHG_MSRS
            								(
                                            v_COLS(1), v_COLS(2),
                                            TO_DATE(v_COLS(3), g_SHORT_DATE_FORMAT),
            								TO_NUMBER(v_COLS(4)),
                                            TO_NUMBER(v_COLS(11)),
                                            v_COLS(5),
                                            TO_DATE(v_COLS(6),g_SHORT_DATE_FORMAT),
											TO_DATE(v_COLS(7),g_SHORT_DATE_FORMAT),
                                            v_COLS(8),
                                            v_COLS(9),
                                            TO_NUMBER(v_COLS(10)),
                                            TO_NUMBER(v_COLS(12))
                                            );

		END IF;
		v_IDX := v_LINES.NEXT(v_IDX);
	END LOOP;
  EXCEPTION
    WHEN OTHERS THEN
      p_STATUS := SQLCODE;
      p_MESSAGE := 'Error in MEX_PJM_SETTLEMENT_MSRS.PARSE_FIRM_TRANS_SERV_CHARGES: ' || SQLERRM;
END PARSE_FIRM_TRANS_SERV_CHARGES;
----------------------------------------------------------------------------------------------------
PROCEDURE PARSE_EDC_INADVERT_ALLOC_SUMM
	(
	p_CSV IN CLOB,
	p_RECORDS OUT MEX_PJM_INADVRT_ALLOC_TBL_MSRS,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) AS
v_LINES PARSE_UTIL.BIG_STRING_TABLE_MP;
v_COLS PARSE_UTIL.STRING_TABLE;
v_IDX BINARY_INTEGER;
v_CUT_DATE DATE;

BEGIN
    p_STATUS := MEX_UTIL.g_SUCCESS;

	PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_CSV,v_LINES);
	v_IDX := v_LINES.FIRST;
	p_RECORDS := MEX_PJM_INADVRT_ALLOC_TBL_MSRS();
	WHILE v_LINES.EXISTS(v_IDX) AND INSTR(v_LINES(v_IDX),g_REPORT_END_LINE) = 0 LOOP
		IF v_LINES(v_IDX) IS NOT NULL AND v_IDX > 5 THEN
            PARSE_UTIL.PARSE_DELIMITED_STRING(v_LINES(v_IDX),',',v_COLS);

            v_CUT_DATE := NEW_TIME(TO_DATE(v_COLS(4),g_GMT_HR_END_FORMAT), 'GMT', 'EST');

        	-- remaining lines contain charge determinant data
			p_RECORDS.EXTEND();
			p_RECORDS(p_RECORDS.LAST) := MEX_PJM_INADVRT_ALLC_TYPE_MSRS
            								(
                                            v_COLS(1),
                                            v_CUT_DATE,
            								TO_NUMBER(v_COLS(5)),
                                            TO_NUMBER(v_COLS(6)),
                                            TO_NUMBER(v_COLS(7)),
                                            TO_NUMBER(v_COLS(8))
                                            );

		END IF;
		v_IDX := v_LINES.NEXT(v_IDX);
	END LOOP;
  EXCEPTION
    WHEN OTHERS THEN
      p_STATUS := SQLCODE;
      p_MESSAGE := 'Error in MEX_PJM_SETTLEMENT_MSRS.PARSE_EDC_INADVERT_ALLOC_SUMM: ' || SQLERRM;
END PARSE_EDC_INADVERT_ALLOC_SUMM;
----------------------------------------------------------------------------------------------------
PROCEDURE PARSE_METER_CORRECT_CHG_SUMM
	(
	p_CSV IN CLOB,
	p_RECORDS OUT MEX_PJM_MTR_CORRCT_SUM_TABLE,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) AS
v_LINES PARSE_UTIL.BIG_STRING_TABLE_MP;
v_COLS PARSE_UTIL.STRING_TABLE;
v_IDX BINARY_INTEGER;
v_MONTH NUMBER(2);
v_YEAR NUMBER(4);
BEGIN
    p_STATUS := MEX_UTIL.g_SUCCESS;

	PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_CSV,v_LINES);
	v_IDX := v_LINES.FIRST;
	p_RECORDS := MEX_PJM_MTR_CORRCT_SUM_TABLE();
	WHILE v_LINES.EXISTS(v_IDX) AND INSTR(v_LINES(v_IDX),g_REPORT_END_LINE) = 0 LOOP
		IF v_LINES(v_IDX) IS NOT NULL AND v_IDX > 5 THEN
            PARSE_UTIL.PARSE_DELIMITED_STRING(v_LINES(v_IDX),',',v_COLS);
            v_MONTH := TO_NUMBER(TO_CHAR(TO_DATE(v_COLS(3),'Month,YYYY'),'MM'));
            v_YEAR := TO_NUMBER(TO_CHAR(TO_DATE(v_COLS(3),'Month,YYYY'),'YYYY'));
        	-- remaining lines contain charge determinant data
			p_RECORDS.EXTEND();
			p_RECORDS(p_RECORDS.LAST) := MEX_PJM_MTR_CORRCT_SUM_TYPE
            								(
                                            v_COLS(1),
                                            v_MONTH,
                                            v_YEAR,
                                            v_COLS(4),
            								TO_NUMBER(v_COLS(5)),
                                            TO_NUMBER(v_COLS(6)),
                                            TO_NUMBER(v_COLS(7)),
                                            TO_NUMBER(v_COLS(8))
                                            );

		END IF;
		v_IDX := v_LINES.NEXT(v_IDX);
	END LOOP;
  EXCEPTION
    WHEN OTHERS THEN
      p_STATUS := SQLCODE;
      p_MESSAGE := 'Error in MEX_PJM_SETTLEMENT_MSRS.PARSE_METER_CORRECT_CHG_SUMM: ' || SQLERRM;
END PARSE_METER_CORRECT_CHG_SUMM;
----------------------------------------------------------------------------------------------------
PROCEDURE PARSE_METER_CORRECT_ALLOC_SUMM
	(
	p_CSV IN CLOB,
	p_RECORDS OUT MEX_PJM_MTR_CORRCT_ALLOC_TABLE,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) AS
v_LINES PARSE_UTIL.BIG_STRING_TABLE_MP;
v_COLS PARSE_UTIL.STRING_TABLE;
v_IDX BINARY_INTEGER;
v_MONTH NUMBER(2);
v_YEAR NUMBER(4);
BEGIN
    p_STATUS := MEX_UTIL.g_SUCCESS;

	PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_CSV,v_LINES);
	v_IDX := v_LINES.FIRST;
	p_RECORDS := MEX_PJM_MTR_CORRCT_ALLOC_TABLE();
	WHILE v_LINES.EXISTS(v_IDX) AND INSTR(v_LINES(v_IDX),g_REPORT_END_LINE) = 0 LOOP
		IF v_LINES(v_IDX) IS NOT NULL AND v_IDX > 5 THEN
            PARSE_UTIL.PARSE_DELIMITED_STRING(v_LINES(v_IDX),',',v_COLS);
            v_MONTH := TO_NUMBER(TO_CHAR(TO_DATE(v_COLS(3),'Month,YYYY'),'MM'));
            v_YEAR := TO_NUMBER(TO_CHAR(TO_DATE(v_COLS(3),'Month,YYYY'),'YYYY'));
        	-- remaining lines contain charge determinant data
			p_RECORDS.EXTEND();
			p_RECORDS(p_RECORDS.LAST) := MEX_PJM_MTR_CORRCT_ALLOC_TYPE
            								(
                                            v_COLS(1),
                                            v_MONTH,
                                            v_YEAR,
                                            v_COLS(4),
            								TO_NUMBER(v_COLS(5)),
                                            TO_NUMBER(v_COLS(6)),
                                            TO_NUMBER(v_COLS(7)),
                                            TO_NUMBER(v_COLS(8)),
                                            TO_NUMBER(v_COLS(9)),
                                            TO_NUMBER(v_COLS(10)),
                                            TO_NUMBER(v_COLS(11))
                                            );

		END IF;
		v_IDX := v_LINES.NEXT(v_IDX);
	END LOOP;
  EXCEPTION
    WHEN OTHERS THEN
      p_STATUS := SQLCODE;
      p_MESSAGE := 'Error in MEX_PJM_SETTLEMENT_MSRS.PARSE_METER_CORRECT_ALLOC_SUMM: ' || SQLERRM;
END PARSE_METER_CORRECT_ALLOC_SUMM;
----------------------------------------------------------------------------------------------------
PROCEDURE PARSE_NON_FM_TRANS_SV_CHARGES
	(
	p_CSV IN CLOB,
	p_RECORDS OUT MEX_PJM_NFIRM_TRAN_CH_TBL_MSRS,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) AS
v_LINES PARSE_UTIL.BIG_STRING_TABLE_MP;
v_COLS PARSE_UTIL.STRING_TABLE;
v_IDX BINARY_INTEGER;
v_ORG_ID VARCHAR2(64);
v_DATE DATE;
v_CUT_DATE DATE;
v_OASISNUM VARCHAR2(16);
v_RATE PRICE_QUANTITY_SUMMARY_TABLE;
v_RESCAP PRICE_QUANTITY_SUMMARY_TABLE;
v_BILLCAP PRICE_QUANTITY_SUMMARY_TABLE;
v_CONGESADJ PRICE_QUANTITY_SUMMARY_TABLE;
v_CHARGE PRICE_QUANTITY_SUMMARY_TABLE;
v_HOUR BINARY_INTEGER;

BEGIN
    p_STATUS := MEX_UTIL.g_SUCCESS;

	PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_CSV,v_LINES);
	v_IDX := v_LINES.FIRST;
	p_RECORDS := MEX_PJM_NFIRM_TRAN_CH_TBL_MSRS();

    v_RATE := PRICE_QUANTITY_SUMMARY_TABLE();
    v_RESCAP := PRICE_QUANTITY_SUMMARY_TABLE();
    v_BILLCAP := PRICE_QUANTITY_SUMMARY_TABLE();
    v_CONGESADJ := PRICE_QUANTITY_SUMMARY_TABLE();
    v_CHARGE := PRICE_QUANTITY_SUMMARY_TABLE();
	WHILE v_LINES.EXISTS(v_IDX) AND INSTR(v_LINES(v_IDX),g_REPORT_END_LINE) = 0 LOOP
        --skip first 5 lines (header info)
         IF v_LINES(v_IDX) IS NOT NULL AND v_IDX > 5 THEN
		    PARSE_UTIL.PARSE_DELIMITED_STRING(v_LINES(v_IDX),',',v_COLS);

            v_ORG_ID := v_COLS(1);
        	v_DATE := TO_DATE(v_COLS(3), g_SHORT_DATE_FORMAT);
            v_OASISNUM := v_COLS(4);

            FOR I IN 10 .. 34 LOOP
                --calculate the hour of the day
                IF I IN (10, 11) THEN
                    --hours 1 and 2
                    v_HOUR := I - 9;
                ELSIF I = 12 THEN
                    --second HE 2 column
                    IF TRUNC(v_DATE) =
                       TRUNC(DST_FALL_BACK_DATE(v_DATE)) THEN
                        v_HOUR := 25;
                    ELSE
                        v_HOUR := NULL; --ignore col 12 for the rest of the year
                    END IF;
                ELSE
                    --hours 3 to 24
                    v_HOUR := I - 10;
                END IF;

                IF v_HOUR IS NOT NULL THEN
                    IF v_HOUR = 25 THEN
                        v_CUT_DATE := TO_CUT_WITH_OPTIONS(TO_DATE(v_COLS(3), g_SHORT_DATE_FORMAT) + 2/24 + 1/86400,
                                                    MM_PJM_UTIL.g_PJM_TIME_ZONE,
                                                    MM_PJM_UTIL.g_DST_SPRING_AHEAD_OPTION);
                    ELSE
                        v_CUT_DATE := TO_CUT_WITH_OPTIONS(TO_DATE(v_COLS(3), g_SHORT_DATE_FORMAT) + v_HOUR/24,
                                                    MM_PJM_UTIL.g_PJM_TIME_ZONE,
                                                    MM_PJM_UTIL.g_DST_SPRING_AHEAD_OPTION);
                    END IF;


                    IF v_COLS(9) LIKE 'Hourly Non-Firm PTP Rate%' THEN
                        v_RATE.EXTEND();
                        v_RATE(v_RATE.LAST) := PRICE_QUANTITY_SUMMARY_TYPE(v_COLS(I), v_CUT_DATE, NULL);
                    END IF;

                    IF v_COLS(9) LIKE 'Reservation Capacity%' THEN
                        v_RESCAP.EXTEND();
                        v_RESCAP(v_RESCAP.LAST) := PRICE_QUANTITY_SUMMARY_TYPE(NULL, v_CUT_DATE, v_COLS(I));
                    END IF;

                    IF v_COLS(9) LIKE 'Billable Capacity%' THEN
                        v_BILLCAP.EXTEND();
                        v_BILLCAP(v_BILLCAP.LAST) := PRICE_QUANTITY_SUMMARY_TYPE(NULL, v_CUT_DATE, v_COLS(I));
                    END IF;

                    IF v_COLS(9) LIKE 'Congestion Adjustment%' THEN
                        v_CONGESADJ.EXTEND();
                        v_CONGESADJ(v_CONGESADJ.LAST) := PRICE_QUANTITY_SUMMARY_TYPE(NULL, v_CUT_DATE, v_COLS(I));
                    END IF;

                    IF v_COLS(9) LIKE 'Non-Firm PTP Transmission Service Charge%' THEN
                        v_CHARGE.EXTEND();
                        v_CHARGE(v_CHARGE.LAST) := PRICE_QUANTITY_SUMMARY_TYPE(NULL, v_CUT_DATE, v_COLS(I));
                    END IF;
                END IF;

            END LOOP;

            IF v_COLS(9) LIKE 'Non-Firm PTP Transmission Service Charge%' THEN
                IF v_HOUR IS NOT NULL THEN
                    --at the end of this set of data for the oasis id
    			    p_RECORDS.EXTEND();
    			    p_RECORDS(p_RECORDS.LAST) := MEX_PJM_NFIRM_TRANS_SV_CH_MSRS
                								(
                                                v_ORG_ID,
                                                v_DATE,
                								v_OASISNUM,
                                                v_RESCAP,
                                                v_BILLCAP,
    											v_CONGESADJ,
                                                v_RATE,
                                                v_CHARGE
                                                );
                END IF;
            END IF;

        END IF;
		v_IDX := v_LINES.NEXT(v_IDX);
    END LOOP;
EXCEPTION
    WHEN OTHERS THEN
      p_STATUS := SQLCODE;
      p_MESSAGE := 'Error in MEX_PJM_SETTLEMENT_MSRS.PARSE_NON_FM_TRANS_SV_CHARGES: ' || SQLERRM;
END PARSE_NON_FM_TRANS_SV_CHARGES;
----------------------------------------------------------------------------------------------------
PROCEDURE PARSE_NON_FM_TRANS_SV_CREDITS
    (
    p_CSV     IN CLOB,
    p_RECORDS OUT MEX_PJM_NON_FIRM_TRAN_CRED_TBL,
    p_STATUS  OUT NUMBER,
    p_MESSAGE OUT VARCHAR2
    ) AS
    v_LINES PARSE_UTIL.BIG_STRING_TABLE_MP;
    v_COLS  PARSE_UTIL.STRING_TABLE;
    v_IDX   BINARY_INTEGER;
BEGIN
    p_STATUS  := MEX_UTIL.g_SUCCESS;
    p_RECORDS := MEX_PJM_NON_FIRM_TRAN_CRED_TBL();
    PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_CSV, v_LINES);

    v_IDX := v_LINES.FIRST;

    WHILE v_LINES.EXISTS(v_IDX) AND INSTR(v_LINES(v_IDX),g_REPORT_END_LINE) = 0 LOOP
		-- skip first 5 rows (header info), empty lines and the 'End of Report' line
        IF v_LINES(v_IDX) IS NOT NULL AND v_IDX > 5 THEN
	        PARSE_UTIL.PARSE_DELIMITED_STRING(v_LINES(v_IDX), ',', v_COLS);
            p_RECORDS.EXTEND();
            p_RECORDS(p_RECORDS.LAST) := MEX_PJM_NON_FIRM_TRANS_CREDIT(ORG_ID   => v_COLS(1),
                                                              ORG_NAME          => v_COLS(2),
                                                              MONTH             => TRUNC(TO_DATE(v_COLS(3),'Month, YYYY'), 'MM'),
                                                              TOTAL_PJM_NON_FIRM_CHARGE => NVL(TO_NUMBER(v_COLS(4)),0),
                                                              NETWK_FIRM_DMD_CHG => NVL(TO_NUMBER(v_COLS(5)),0),
                                                              TOTAL_NETWK_FIRM_DMD_CHG  => NVL(TO_NUMBER(v_COLS(6)),0),
                                                              NON_FIRM_CREDIT   => NVL(TO_NUMBER(v_COLS(7)),0));
        END IF;
        v_IDX := v_LINES.NEXT(v_IDX);
    END LOOP;
EXCEPTION
    WHEN OTHERS THEN
        p_STATUS  := SQLCODE;
        p_MESSAGE := 'Error in MEX_PJM_SETTLEMENT_MSRS.PARSE_NON_FM_TRANS_SV_CREDITS: ' || SQLERRM;
END PARSE_NON_FM_TRANS_SV_CREDITS;
----------------------------------------------------------------------------------------------------
PROCEDURE PARSE_SCHED_9_10_RECON
	(
	p_CSV IN CLOB,
	p_RECORDS OUT MEX_PJM_SCHED_9_10_RECON_TBL,
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
	p_RECORDS := MEX_PJM_SCHED_9_10_RECON_TBL();
    WHILE v_LINES.EXISTS(v_IDX) AND INSTR(v_LINES(v_IDX),g_REPORT_END_LINE) = 0 LOOP
    -- skip first 5 rows (header info), empty lines and the 'End of Report' line
        IF v_LINES(v_IDX) IS NOT NULL AND v_IDX > 5 THEN
            PARSE_UTIL.TOKENS_FROM_STRING(v_LINES(v_IDX), ',', v_COLS);
			-- remaining lines contain charge determinant data
			p_RECORDS.EXTEND();
			p_RECORDS(p_RECORDS.LAST) := MEX_PJM_SCHED_9_10_RECON(v_COLS(1),
											TO_DATE(v_COLS(3),'Month, YYYY'),
                                            TO_DATE(v_COLS(4),g_SHORT_DATE_FORMAT),
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
											TO_NUMBER(v_COLS(16)),
                                            TO_NUMBER(v_COLS(17)),
											TO_NUMBER(v_COLS(18)),
                                            TO_NUMBER(v_COLS(19)),
											TO_NUMBER(v_COLS(20)),
											TO_NUMBER(v_COLS(21)),
                                            TO_NUMBER(v_COLS(22)),
											TO_NUMBER(v_COLS(23)));

		END IF;
		v_IDX := v_LINES.NEXT(v_IDX);
	END LOOP;
  EXCEPTION
    WHEN OTHERS THEN
      p_STATUS := SQLCODE;
      p_MESSAGE := 'Error in MEX_PJM_SETTLEMENT_MSRS.PARSE_SCHED_9_10_RECON: ' || SQLERRM;
END PARSE_SCHED_9_10_RECON;
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

    WHILE v_LINES.EXISTS(v_IDX) AND INSTR(v_LINES(v_IDX),g_REPORT_END_LINE) = 0 LOOP
    -- skip first 5 rows (header info), empty lines and the 'End of Report' line
        IF v_LINES(v_IDX) IS NOT NULL AND v_IDX > 5 THEN
            PARSE_UTIL.TOKENS_FROM_STRING(v_LINES(v_IDX), ',', v_COLS);
  		    p_RECORDS.EXTEND();
			p_RECORDS(p_RECORDS.LAST) := MEX_PJM_SCHEDULE1A_SUMMARY(v_COLS(1),
											TO_DATE(v_COLS(3), g_SHORT_DATE_FORMAT),
                                            NULL,
											v_COLS(5),
                                            TO_NUMBER(v_COLS(7)),
											TO_NUMBER(v_COLS(6)),
                                            NULL,
											TO_NUMBER(v_COLS(8)),NULL,NULL,NULL,NULL);
		END IF;
		v_IDX := v_LINES.NEXT(v_IDX);
	END LOOP;
EXCEPTION
    WHEN OTHERS THEN
      p_STATUS := SQLCODE;
      p_MESSAGE := 'Error in MEX_PJM_SETTLEMENT_MSRS.PARSE_SCHEDULE1A_RECONCILE: ' || SQLERRM;
END PARSE_SCHEDULE1A_RECONCILE;
----------------------------------------------------------------------------------------------------
PROCEDURE PARSE_ENERGY_CHARGES_RECONCIL
(
    p_CSV     IN CLOB,
    p_STATUS  OUT NUMBER,
    p_MESSAGE OUT VARCHAR2
) AS
    v_LINES    PARSE_UTIL.BIG_STRING_TABLE_MP;
    v_COLS     PARSE_UTIL.STRING_TABLE;
    v_IDX      BINARY_INTEGER;
    v_CUT_DATE DATE;

BEGIN
    p_STATUS := MEX_UTIL.g_SUCCESS;

    PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_CSV, v_LINES);
    v_IDX := v_LINES.FIRST;
    IF v_LINES.LAST = v_IDX THEN
        p_STATUS := 1;
        RETURN;
    END IF;
    WHILE v_LINES.EXISTS(v_IDX) AND INSTR(v_LINES(v_IDX),g_REPORT_END_LINE) = 0 LOOP
		-- skip first 5 rows (header info), empty lines and the 'End of Report' line
        IF v_LINES(v_IDX) IS NOT NULL AND v_IDX > 5 THEN
        	PARSE_UTIL.PARSE_DELIMITED_STRING(v_LINES(v_IDX), ',', v_COLS);

            v_CUT_DATE := NEW_TIME(TO_DATE(v_COLS(5),g_GMT_HR_END_FORMAT), 'GMT', 'EST');

            -- remaining lines contain charge determinant data
            INSERT INTO PJM_ENG_INADVERT_CHRGS_RCN
            VALUES
                (v_COLS(1),
                 TO_DATE(v_COLS(3),'Month, YYYY'),
                 v_CUT_DATE,
                 v_COLS(6),
                 TO_NUMBER(v_COLS(7)),
                 TO_NUMBER(v_COLS(8)),
                 TO_NUMBER(v_COLS(9)),
                 TO_NUMBER(v_COLS(10)),
                 TO_NUMBER(v_COLS(11)),
                 TO_NUMBER(v_COLS(12)),
                 TO_NUMBER(v_COLS(13)),
                 TO_NUMBER(v_COLS(14)),
                 TO_NUMBER(v_COLS(15)));

        END IF;
        v_IDX := v_LINES.NEXT(v_IDX);
    END LOOP;
    COMMIT;
  EXCEPTION
    WHEN OTHERS THEN
      p_STATUS := SQLCODE;
      p_MESSAGE := 'Error in MEX_PJM_SETTLEMENT_MSRS.PARSE_ENERGY_CHARGES_RECONCIL: ' || SQLERRM;
END PARSE_ENERGY_CHARGES_RECONCIL;
----------------------------------------------------------------------------------------------------
PROCEDURE PARSE_SYNC_RES_CH_RECONCIL
	(
	p_CSV IN CLOB,
	p_RECORDS OUT MEX_PJM_RECON_CHRGS_MSRS_TBL,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) AS
v_LINES PARSE_UTIL.BIG_STRING_TABLE_MP;
v_COLS PARSE_UTIL.STRING_TABLE;
v_IDX BINARY_INTEGER;
v_CUT_DATE DATE;

BEGIN
  p_STATUS := MEX_UTIL.g_SUCCESS;

	PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_CSV,v_LINES);
	v_IDX := v_LINES.FIRST;
	p_RECORDS := MEX_PJM_RECON_CHRGS_MSRS_TBL();
  WHILE v_LINES.EXISTS(v_IDX) AND INSTR(v_LINES(v_IDX),g_REPORT_END_LINE) = 0 LOOP
  -- skip first 5 rows (header info), empty lines and the 'End of Report' line
    IF v_LINES(v_IDX) IS NOT NULL AND v_IDX > 5 THEN
      PARSE_UTIL.PARSE_DELIMITED_STRING(v_LINES(v_IDX), ',', v_COLS);
			-- remaining lines contain charge determinant data

      v_CUT_DATE := NEW_TIME(TO_DATE(v_COLS(5),g_GMT_HR_END_FORMAT), 'GMT', 'EST');

			p_RECORDS.EXTEND();
			p_RECORDS(p_RECORDS.LAST) := MEX_PJM_RECON_CHRGS_MSRS(v_COLS(1),
											TO_DATE(v_COLS(3),'Month,YYYY'),
                                              v_CUT_DATE,
                                              v_COLS(6),
                                              TO_NUMBER(v_COLS(8)),
                                              TO_NUMBER(v_COLS(9)),
                                              TO_NUMBER(v_COLS(10)));
		END IF;
		v_IDX := v_LINES.NEXT(v_IDX);
	END LOOP;
  EXCEPTION
    WHEN OTHERS THEN
      p_STATUS := SQLCODE;
      p_MESSAGE := 'Error in MEX_PJM_SETTLEMENT_MSRS.PARSE_SPIN_RES_CH_RECONCIL: ' || SQLERRM;
END PARSE_SYNC_RES_CH_RECONCIL;
----------------------------------------------------------------------------------------------------
PROCEDURE PARSE_REG_CHARGES_RECONCIL
	(
	p_CSV IN CLOB,
	p_RECORDS OUT MEX_PJM_RECON_CHRGS_MSRS_TBL,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) AS
v_LINES PARSE_UTIL.BIG_STRING_TABLE_MP;
v_COLS PARSE_UTIL.STRING_TABLE;
v_IDX BINARY_INTEGER;
v_CUT_DATE DATE;

BEGIN
    p_STATUS := MEX_UTIL.g_SUCCESS;

	PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_CSV,v_LINES);
	v_IDX := v_LINES.FIRST;
	p_RECORDS := MEX_PJM_RECON_CHRGS_MSRS_TBL();
    WHILE v_LINES.EXISTS(v_IDX) AND INSTR(v_LINES(v_IDX),g_REPORT_END_LINE) = 0 LOOP
    -- skip first 5 rows (header info), empty lines and the 'End of Report' line
        IF v_LINES(v_IDX) IS NOT NULL AND v_IDX > 5 THEN
			-- remaining lines contain charge determinant data
     	    PARSE_UTIL.PARSE_DELIMITED_STRING(v_LINES(v_IDX), ',', v_COLS);

            v_CUT_DATE := NEW_TIME(TO_DATE(v_COLS(5),g_GMT_HR_END_FORMAT), 'GMT', 'EST');

			p_RECORDS.EXTEND();
			p_RECORDS(p_RECORDS.LAST) := MEX_PJM_RECON_CHRGS_MSRS(v_COLS(1),
                                                TO_DATE(v_COLS(3),'Month, YYYY'),
                                                v_CUT_DATE,
                                                NULL,
                                                TO_NUMBER(v_COLS(6)),
                                                TO_NUMBER(v_COLS(7)),
                                                TO_NUMBER(v_COLS(8)));

		END IF;
		v_IDX := v_LINES.NEXT(v_IDX);
	END LOOP;
  EXCEPTION
    WHEN OTHERS THEN
      p_STATUS := SQLCODE;
      p_MESSAGE := 'Error in MEX_PJM_SETTLEMENT_MSRS.PARSE_REG_CHARGES_RECONCIL: ' || SQLERRM;
END PARSE_REG_CHARGES_RECONCIL;
----------------------------------------------------------------------------------------------------
PROCEDURE PARSE_SYNC_CONDENSE_RECONCIL
	(
	p_CSV IN CLOB,
	p_RECORDS OUT MEX_PJM_RECON_CHRGS_MSRS_TBL,
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
	p_RECORDS := MEX_PJM_RECON_CHRGS_MSRS_TBL();
    WHILE v_LINES.EXISTS(v_IDX) AND INSTR(v_LINES(v_IDX),g_REPORT_END_LINE) = 0 LOOP
    -- skip first 5 rows (header info), empty lines and the 'End of Report' line
        IF v_LINES(v_IDX) IS NOT NULL AND v_IDX > 5 THEN
			-- remaining lines contain charge determinant data
     	    PARSE_UTIL.PARSE_DELIMITED_STRING(v_LINES(v_IDX), ',', v_COLS);

			p_RECORDS.EXTEND();
			p_RECORDS(p_RECORDS.LAST) := MEX_PJM_RECON_CHRGS_MSRS(v_COLS(1),
                                                TO_DATE(v_COLS(3),'Month, YYYY'),
                                                TO_DATE(v_COLS(4), g_SHORT_DATE_FORMAT),
                                                NULL,
                                                TO_NUMBER(v_COLS(5)),
                                                TO_NUMBER(v_COLS(6)),
                                                TO_NUMBER(v_COLS(7)));

		END IF;
		v_IDX := v_LINES.NEXT(v_IDX);
	END LOOP;
  EXCEPTION
    WHEN OTHERS THEN
      p_STATUS := SQLCODE;
      p_MESSAGE := 'Error in MEX_PJM_SETTLEMENT_MSRS.PARSE_SYNC_CONDENSE_RECONCIL: ' || SQLERRM;
END PARSE_SYNC_CONDENSE_RECONCIL;
----------------------------------------------------------------------------------------------------
PROCEDURE PARSE_REACT_SERVICES_RECONCIL
	(
	p_CSV IN CLOB,
	p_RECORDS OUT MEX_PJM_RECON_CHRGS_MSRS_TBL,
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
	p_RECORDS := MEX_PJM_RECON_CHRGS_MSRS_TBL();
    WHILE v_LINES.EXISTS(v_IDX) AND INSTR(v_LINES(v_IDX),g_REPORT_END_LINE) = 0 LOOP
    -- skip first 5 rows (header info), empty lines and the 'End of Report' line
        IF v_LINES(v_IDX) IS NOT NULL AND v_IDX > 5 THEN
			-- remaining lines contain charge determinant data
     	    PARSE_UTIL.PARSE_DELIMITED_STRING(v_LINES(v_IDX), ',', v_COLS);

			p_RECORDS.EXTEND();
			p_RECORDS(p_RECORDS.LAST) := MEX_PJM_RECON_CHRGS_MSRS(v_COLS(1),
                                                TO_DATE(v_COLS(3),'Month, YYYY'),
                                                TO_DATE(v_COLS(4), g_SHORT_DATE_FORMAT),
                                                v_COLS(5),
                                                TO_NUMBER(v_COLS(6)),
                                                TO_NUMBER(v_COLS(7)),
                                                TO_NUMBER(v_COLS(8)));

		END IF;
		v_IDX := v_LINES.NEXT(v_IDX);
	END LOOP;
  EXCEPTION
    WHEN OTHERS THEN
      p_STATUS := SQLCODE;
      p_MESSAGE := 'Error in MEX_PJM_SETTLEMENT_MSRS.PARSE_REACT_SERVICES_RECONCIL: ' || SQLERRM;
END PARSE_REACT_SERVICES_RECONCIL;
----------------------------------------------------------------------------------------------------
PROCEDURE PARSE_TRANS_LOSS_CR_RECONCIL
	(
	p_CSV IN CLOB,
	p_RECORDS OUT MEX_PJM_RECON_CHRGS_MSRS_TBL,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) AS
v_LINES PARSE_UTIL.BIG_STRING_TABLE_MP;
v_COLS PARSE_UTIL.STRING_TABLE;
v_IDX BINARY_INTEGER;
v_CUT_DATE DATE;

BEGIN
    p_STATUS := MEX_UTIL.g_SUCCESS;

	PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_CSV,v_LINES);
	v_IDX := v_LINES.FIRST;
	p_RECORDS := MEX_PJM_RECON_CHRGS_MSRS_TBL();
    WHILE v_LINES.EXISTS(v_IDX) AND INSTR(v_LINES(v_IDX),g_REPORT_END_LINE) = 0 LOOP
    -- skip first 5 rows (header info), empty lines and the 'End of Report' line
        IF v_LINES(v_IDX) IS NOT NULL AND v_IDX > 5 THEN
            PARSE_UTIL.PARSE_DELIMITED_STRING(v_LINES(v_IDX), ',', v_COLS);
			-- remaining lines contain charge determinant data
            v_CUT_DATE := NEW_TIME(TO_DATE(v_COLS(5),g_GMT_HR_END_FORMAT), 'GMT', 'EST');

			p_RECORDS.EXTEND();
			p_RECORDS(p_RECORDS.LAST) := MEX_PJM_RECON_CHRGS_MSRS(v_COLS(1),
											TO_DATE(v_COLS(3),'Month,YYYY'),
                                              v_CUT_DATE,
                                              NULL,
                                              TO_NUMBER(v_COLS(6)),
                                              TO_NUMBER(v_COLS(7)),
                                              TO_NUMBER(v_COLS(8)));

		END IF;
		v_IDX := v_LINES.NEXT(v_IDX);
	END LOOP;
EXCEPTION
    WHEN OTHERS THEN
      p_STATUS := SQLCODE;
      p_MESSAGE := 'Error in MEX_PJM_SETTLEMENT_MSRS.PARSE_TRANS_LOSS_CR_RECONCIL: ' || SQLERRM;
END PARSE_TRANS_LOSS_CR_RECONCIL;
----------------------------------------------------------------------------------------------------
PROCEDURE PARSE_HR_TRANS_CONG_CR
	(
	p_CSV IN CLOB,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) AS

v_LINES		PARSE_UTIL.BIG_STRING_TABLE_MP;
v_COLS		PARSE_UTIL.STRING_TABLE;
v_IDX		BINARY_INTEGER;
v_CUT_DATE 	DATE;
v_ORG_ID    PJM_CONGESTION_SUMMARY.ORG_NID%TYPE;

BEGIN
	p_STATUS := MEX_UTIL.g_SUCCESS;

	PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_CSV,v_LINES);

	v_IDX := v_LINES.FIRST;
	IF v_LINES.LAST = v_IDX THEN
        p_STATUS := 1;
        RETURN;
    END IF;

	WHILE v_LINES.EXISTS(v_IDX) AND INSTR(v_LINES(v_IDX),g_REPORT_END_LINE) = 0 LOOP
		-- skip first 5 rows (header info), empty lines and the 'End of Report' line
        IF v_LINES(v_IDX) IS NOT NULL AND v_IDX > 5 THEN
			PARSE_UTIL.TOKENS_FROM_STRING(v_LINES(v_IDX),',',v_COLS);

			v_ORG_ID := v_COLS(1);

            v_CUT_DATE := NEW_TIME(TO_DATE(v_COLS(4),g_GMT_HR_END_FORMAT), 'GMT', 'EST');

			--just update the following fields
			UPDATE PJM_CONGESTION_SUMMARY
			   SET FTR_TARGET_ALLOCATION = NVL(TO_NUMBER(v_COLS(7)),0),
			       FTR_CONG_CREDIT = NVL(TO_NUMBER(v_COLS(8)),0),
				   CREDIT_FOR_MONTHLY_EXCESS = NVL(TO_NUMBER(v_COLS(9)),0),
				   CREDIT_FROM_UTS = NULL
			 WHERE ORG_NID = v_ORG_ID
			   AND CUT_DATE = v_CUT_DATE;

			IF SQL%NOTFOUND THEN
            	--Try insert into PJM_CONGESTION_SUMMARY table
            	INSERT INTO PJM_CONGESTION_SUMMARY
                	(ORG_NID, CUT_DATE, FTR_TARGET_ALLOCATION, FTR_CONG_CREDIT, CREDIT_FOR_MONTHLY_EXCESS)
            	VALUES
                	(v_ORG_ID,v_CUT_DATE,NVL(TO_NUMBER(v_COLS(7)),0),NVL(TO_NUMBER(v_COLS(8)),0),NVL(TO_NUMBER(v_COLS(9)),0));
        	END IF;

		END IF;
		v_IDX := v_LINES.NEXT(v_IDX);
	END LOOP;

  EXCEPTION
    WHEN OTHERS THEN
      p_STATUS := SQLCODE;
      p_MESSAGE := 'Error in MEX_PJM_SETTLEMENT_MSRS.PARSE_HR_TRANS_CONG_CR: ' || SQLERRM;

END PARSE_HR_TRANS_CONG_CR;
----------------------------------------------------------------------------------------------------
PROCEDURE PARSE_IMPL_CONG_LOSS_CH
	(
	p_CSV IN CLOB,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) AS

v_LINES		PARSE_UTIL.BIG_STRING_TABLE_MP;
v_COLS		PARSE_UTIL.STRING_TABLE;
v_IDX		BINARY_INTEGER;
v_CUT_DATE 	DATE;
v_ORG_ID    PJM_CONGESTION_SUMMARY.ORG_NID%TYPE;

BEGIN
	p_STATUS := MEX_UTIL.g_SUCCESS;

	PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_CSV,v_LINES);

	v_IDX := v_LINES.FIRST;
	IF v_LINES.LAST = v_IDX THEN
        p_STATUS := 1;
        RETURN;
    END IF;

	WHILE v_LINES.EXISTS(v_IDX) AND INSTR(v_LINES(v_IDX),g_REPORT_END_LINE) = 0 LOOP
		-- skip first 5 rows (header info), empty lines and the 'End of Report' line
        IF v_LINES(v_IDX) IS NOT NULL AND v_IDX > 5 THEN
			PARSE_UTIL.TOKENS_FROM_STRING(v_LINES(v_IDX),',',v_COLS);

			v_ORG_ID := v_COLS(1);

            v_CUT_DATE := NEW_TIME(TO_DATE(v_COLS(4),g_GMT_HR_END_FORMAT), 'GMT', 'EST');

			--just update the following fields from PJM_CONGESTION_SUMMARY table
			UPDATE PJM_CONGESTION_SUMMARY
			   SET DAY_AHEAD_CONG_WD_MWH = NVL(TO_NUMBER(v_COLS(8)),0),
			       DAY_AHEAD_CONG_INJ_MWH = NVL(TO_NUMBER(v_COLS(9)),0),
				   BALANCING_CONG_WD_DEV_MWH = NVL(TO_NUMBER(v_COLS(15)),0),
				   BALANCING_CONG_INJ_DEV_MWH = NVL(TO_NUMBER(v_COLS(17)),0)
			 WHERE ORG_NID = v_ORG_ID
			   AND CUT_DATE = v_CUT_DATE;

			IF SQL%NOTFOUND THEN
            	--Try insert into PJM_CONGESTION_SUMMARY
            	INSERT INTO PJM_CONGESTION_SUMMARY
                	(ORG_NID, CUT_DATE, DAY_AHEAD_CONG_WD_MWH, DAY_AHEAD_CONG_INJ_MWH, BALANCING_CONG_WD_DEV_MWH,BALANCING_CONG_INJ_DEV_MWH)
            	VALUES
                	(v_ORG_ID,v_CUT_DATE,NVL(TO_NUMBER(v_COLS(8)),0),NVL(TO_NUMBER(v_COLS(9)),0),NVL(TO_NUMBER(v_COLS(15)),0),NVL(TO_NUMBER(v_COLS(17)),0));
        	END IF;

			--just update the following fields from PJM_TXN_LOSS_CHARGE_SUMMARY table
			UPDATE PJM_TXN_LOSS_CHARGE_SUMMARY
			   SET DAY_AHEAD_LOSS_WD_MWH = NVL(TO_NUMBER(v_COLS(11)),0),
			       DAY_AHEAD_LOSS_INJ_MWH = NVL(TO_NUMBER(v_COLS(12)),0),
				   BALANCING_LOSS_WD_DEV_MWH = NVL(TO_NUMBER(v_COLS(20)),0),
				   BALANCING_LOSS_INJ_DEV_MWH = NVL(TO_NUMBER(v_COLS(22)),0)
			 WHERE ORG_NID = v_ORG_ID
			   AND CUT_DATE = v_CUT_DATE;

			 IF SQL%NOTFOUND THEN
            	--Try insert into PJM_TXN_LOSS_CHARGE_SUMMARY
            	INSERT INTO PJM_TXN_LOSS_CHARGE_SUMMARY
                	(ORG_NID, CUT_DATE, DAY_AHEAD_LOSS_WD_MWH, DAY_AHEAD_LOSS_INJ_MWH, BALANCING_LOSS_WD_DEV_MWH,BALANCING_LOSS_INJ_DEV_MWH)
            	VALUES
                	(v_ORG_ID,v_CUT_DATE,NVL(TO_NUMBER(v_COLS(11)),0),NVL(TO_NUMBER(v_COLS(12)),0),NVL(TO_NUMBER(v_COLS(20)),0),NVL(TO_NUMBER(v_COLS(22)),0));
        	END IF;

		END IF;
		v_IDX := v_LINES.NEXT(v_IDX);
	END LOOP;

  EXCEPTION
    WHEN OTHERS THEN
      p_STATUS := SQLCODE;
      p_MESSAGE := 'Error in MEX_PJM_SETTLEMENT_MSRS.PARSE_IMPL_CONG_LOSS_CH: ' || SQLERRM;

END PARSE_IMPL_CONG_LOSS_CH;
----------------------------------------------------------------------------------------------------
PROCEDURE PARSE_TRANS_LOSS_CHARGE
(
    p_CSV     IN CLOB,
    p_STATUS  OUT NUMBER,
    p_MESSAGE OUT VARCHAR2
) AS
    v_LINES    PARSE_UTIL.BIG_STRING_TABLE_MP;
    v_COLS     PARSE_UTIL.STRING_TABLE;
    v_IDX      BINARY_INTEGER;
    v_CUT_DATE DATE;
    v_ORG_ID   PJM_TXN_LOSS_CHARGE_SUMMARY.ORG_NID%TYPE;

BEGIN
    p_STATUS := MEX_UTIL.g_SUCCESS;

    PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_CSV, v_LINES);
    v_IDX := v_LINES.FIRST;
    IF v_LINES.LAST = v_IDX THEN
        p_STATUS := 1;
        RETURN;
    END IF;

    WHILE v_LINES.EXISTS(v_IDX) AND INSTR(v_LINES(v_IDX),g_REPORT_END_LINE) = 0 LOOP
        -- skip first 5 rows (header info), empty lines and the 'End of Report' line
        IF v_LINES(v_IDX) IS NOT NULL AND v_IDX > 5 THEN
            PARSE_UTIL.TOKENS_FROM_STRING(v_LINES(v_IDX), ',', v_COLS);

            v_ORG_ID   := v_COLS(1);

            v_CUT_DATE := NEW_TIME(TO_DATE(v_COLS(4),g_GMT_HR_END_FORMAT), 'GMT', 'EST');
            --update the following fields from PJM_TXN_LOSS_CHARGE_SUMMARY table
            UPDATE PJM_TXN_LOSS_CHARGE_SUMMARY
            SET DAY_AHEAD_LOSS_WD_CHARGE  = NVL(TO_NUMBER(v_COLS(6)), 0),
                DAY_AHEAD_LOSS_INJ_CREDIT = NVL(TO_NUMBER(v_COLS(8)), 0),
                DAY_AHEAD_IMP_LOSS_CHARGE = NVL(TO_NUMBER(v_COLS(9)), 0),
                DAY_AHEAD_EXP_LOSS_CHARGE = NVL(TO_NUMBER(v_COLS(10)), 0),
                BALANCING_LOSS_WD_CHARGE  = NVL(TO_NUMBER(v_COLS(12)), 0),
                BALANCING_LOSS_INJ_CREDIT = NVL(TO_NUMBER(v_COLS(14)), 0),
                BALANCING_IMP_LOSS_CHARGE = NVL(TO_NUMBER(v_COLS(15)), 0),
                BALANCING_EXP_LOSS_CHARGE = NVL(TO_NUMBER(v_COLS(16)), 0)
            WHERE ORG_NID = v_ORG_ID
            AND CUT_DATE = v_CUT_DATE;

            IF SQL%NOTFOUND THEN
                --Try insert into PJM_TXN_LOSS_CHARGE_SUMMARY
                INSERT INTO PJM_TXN_LOSS_CHARGE_SUMMARY
                    (ORG_NID,
                     CUT_DATE,
					 DAY_AHEAD_LOSS_WD_CHARGE,
					 DAY_AHEAD_LOSS_INJ_CREDIT,
					 DAY_AHEAD_IMP_LOSS_CHARGE,
					 DAY_AHEAD_EXP_LOSS_CHARGE,
					 BALANCING_LOSS_WD_CHARGE,
					 BALANCING_LOSS_INJ_CREDIT,
					 BALANCING_IMP_LOSS_CHARGE,
					 BALANCING_EXP_LOSS_CHARGE)
                VALUES
                    (v_ORG_ID,
                     v_CUT_DATE,
                     NVL(TO_NUMBER(v_COLS(6)), 0),
                     NVL(TO_NUMBER(v_COLS(8)), 0),
					 NVL(TO_NUMBER(v_COLS(9)), 0),
					 NVL(TO_NUMBER(v_COLS(10)), 0),
					 NVL(TO_NUMBER(v_COLS(12)), 0),
					 NVL(TO_NUMBER(v_COLS(14)), 0),
					 NVL(TO_NUMBER(v_COLS(15)), 0),
					 NVL(TO_NUMBER(v_COLS(16)), 0));
            END IF;
        END IF;
        v_IDX := v_LINES.NEXT(v_IDX);
    END LOOP;

    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
        p_STATUS  := SQLCODE;
        p_MESSAGE := 'Error in MEX_PJM_SETTLEMENT_MSRS.PARSE_TRANS_LOSS_CHARGE: ' ||
                     SQLERRM;
END PARSE_TRANS_LOSS_CHARGE;
----------------------------------------------------------------------------------------------------
PROCEDURE PARSE_TRANS_LOSS_CREDIT
(
    p_CSV     IN CLOB,
    p_STATUS  OUT NUMBER,
    p_MESSAGE OUT VARCHAR2
) AS
    v_LINES    PARSE_UTIL.BIG_STRING_TABLE_MP;
    v_COLS     PARSE_UTIL.STRING_TABLE;
    v_IDX      BINARY_INTEGER;
    v_CUT_DATE DATE;
    v_ORG_ID   PJM_TXN_LOSS_CHARGE_SUMMARY.ORG_NID%TYPE;

BEGIN
    p_STATUS := MEX_UTIL.g_SUCCESS;

    PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_CSV, v_LINES);
    v_IDX := v_LINES.FIRST;
    IF v_LINES.LAST = v_IDX THEN
        p_STATUS := 1;
        RETURN;
    END IF;

    WHILE v_LINES.EXISTS(v_IDX) AND INSTR(v_LINES(v_IDX),g_REPORT_END_LINE) = 0 LOOP
        -- skip first 5 rows (header info), empty lines and the 'End of Report' line
        IF v_LINES(v_IDX) IS NOT NULL AND v_IDX > 5 THEN
            PARSE_UTIL.TOKENS_FROM_STRING(v_LINES(v_IDX), ',', v_COLS);

            v_ORG_ID   := v_COLS(1);

            v_CUT_DATE := NEW_TIME(TO_DATE(v_COLS(4),g_GMT_HR_END_FORMAT), 'GMT', 'EST');

            --update the following fields from PJM_TXN_LOSS_CREDIT_SUMMARY table
            UPDATE PJM_TXN_LOSS_CREDIT_SUMMARY
            SET TOTAL_PJM_LOSS_REVENUES = NVL(TO_NUMBER(v_COLS(5)), 0),
			    REAL_TIME_LOAD = NVL(TO_NUMBER(v_COLS(6)), 0),
				REAL_TIME_EXPORTS = NVL(TO_NUMBER(v_COLS(7)), 0),
				TOTAL_PJM_RT_LD_PLUS_EXPORTS = NVL(TO_NUMBER(v_COLS(8)), 0),
				TRANSMISSION_LOSS_CREDIT = NVL(TO_NUMBER(v_COLS(9)), 0)
			WHERE ORG_NID = v_ORG_ID
            AND CUT_DATE = v_CUT_DATE;

            IF SQL%NOTFOUND THEN
                --Try insert into PJM_TXN_LOSS_CREDIT_SUMMARY
                INSERT INTO PJM_TXN_LOSS_CREDIT_SUMMARY
                    (ORG_NID,
                     CUT_DATE,
					 TOTAL_PJM_LOSS_REVENUES,
					 REAL_TIME_LOAD,
					 REAL_TIME_EXPORTS,
					 TOTAL_PJM_RT_LD_PLUS_EXPORTS,
					 TRANSMISSION_LOSS_CREDIT)
                VALUES
                    (v_ORG_ID,
                     v_CUT_DATE,
                     NVL(TO_NUMBER(v_COLS(5)), 0),
                     NVL(TO_NUMBER(v_COLS(6)), 0),
                     NVL(TO_NUMBER(v_COLS(7)), 0),
                     NVL(TO_NUMBER(v_COLS(8)), 0),
					 NVL(TO_NUMBER(v_COLS(9)), 0));
            END IF;
        END IF;
        v_IDX := v_LINES.NEXT(v_IDX);
    END LOOP;

    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
        p_STATUS  := SQLCODE;
        p_MESSAGE := 'Error in MEX_PJM_SETTLEMENT_MSRS.PARSE_TRANS_LOSS_CREDIT: ' ||
                     SQLERRM;
END PARSE_TRANS_LOSS_CREDIT;
----------------------------------------------------------------------------------------------------
PROCEDURE PARSE_EXPLICIT_LOSS
(
    p_CSV     IN CLOB,
    p_STATUS  OUT NUMBER,
    p_MESSAGE OUT VARCHAR2
) AS
    v_LINES    PARSE_UTIL.BIG_STRING_TABLE_MP;
    v_COLS     PARSE_UTIL.STRING_TABLE;
    v_IDX      BINARY_INTEGER;
    v_CUT_DATE DATE;

BEGIN
    p_STATUS := MEX_UTIL.g_SUCCESS;

    PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_CSV, v_LINES);

    v_IDX := v_LINES.FIRST;
    IF v_LINES.LAST = v_IDX THEN
        p_STATUS := 1;
        RETURN;
    END IF;

    WHILE v_LINES.EXISTS(v_IDX) AND INSTR(v_LINES(v_IDX),g_REPORT_END_LINE) = 0 LOOP
        IF v_LINES(v_IDX) IS NOT NULL AND v_IDX > 5 THEN

            PARSE_UTIL.PARSE_DELIMITED_STRING(v_LINES(v_IDX), ',', v_COLS);

            v_CUT_DATE := NEW_TIME(TO_DATE(v_COLS(4),g_GMT_HR_END_FORMAT), 'GMT', 'EST');

			--insert data into PJM_EXPLICIT_LOSS_CHARGES table
            INSERT INTO PJM_EXPLICIT_LOSS_CHARGES
            VALUES
                (v_COLS(1),
				NULL,
				NULL,
				NULL,
                 v_CUT_DATE,
                 v_COLS(5),
                 v_COLS(6),
                 v_COLS(7),
                 v_COLS(8),
                 v_COLS(9),
                 v_COLS(10),
                 v_COLS(12),
                 TO_NUMBER(v_COLS(14)),
                 TO_NUMBER(v_COLS(15)),
                 TO_NUMBER(v_COLS(16)),
                 TO_NUMBER(v_COLS(17)),
                 TO_NUMBER(v_COLS(18)),
                 TO_NUMBER(v_COLS(19)),
                 TO_NUMBER(v_COLS(20)),
                 TO_NUMBER(v_COLS(21)),
                 TO_NUMBER(v_COLS(22)));

        END IF;
        v_IDX := v_LINES.NEXT(v_IDX);
    END LOOP;

    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        p_STATUS  := SQLCODE;
        p_MESSAGE := 'Error in MEX_PJM_SETTLEMENT_MSRS.PARSE_EXPLICIT_LOSS: ' || SQLERRM;
END PARSE_EXPLICIT_LOSS;
---------------------------------------------------------------------------------------------------
PROCEDURE PARSE_MONTH_TO_DATE_BILL
(
    p_CSV     IN CLOB,
    p_RECORDS OUT MEX_PJM_MONTH_TO_DATE_BILL_TBL,
    p_STATUS  OUT NUMBER,
    p_MESSAGE OUT VARCHAR2
) AS
v_LINES PARSE_UTIL.BIG_STRING_TABLE_MP;
v_COLS  PARSE_UTIL.STRING_TABLE;
v_IDX   BINARY_INTEGER;
v_ORG_NAME VARCHAR2(64);
v_START_DATE DATE;
v_DATE DATE;
v_IS_CREDIT BINARY_INTEGER := 0;
v_CHG_QTY_SCHED PRICE_QUANTITY_SUMMARY_TABLE;
v_START_COL BINARY_INTEGER;
v_LINE_ITEM_NAME VARCHAR2(256);
v_ADJ_DATE DATE;
BEGIN
    p_STATUS := MEX_UTIL.g_SUCCESS;

	PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_CSV,v_LINES);
	v_IDX := v_LINES.FIRST;
	p_RECORDS := MEX_PJM_MONTH_TO_DATE_BILL_TBL();
	WHILE v_LINES.EXISTS(v_IDX) LOOP
		PARSE_UTIL.TOKENS_FROM_STRING(v_LINES(v_IDX),',',v_COLS);
		IF v_IDX = 1 OR v_IDX = 4 THEN
        	-- skip
			NULL;
        ELSIF v_IDX = 2 THEN
            v_ORG_NAME := TRIM(v_COLS(2));
                -- if name contains comma, then TOKENS_FROM_STRING may have broken
                -- name into other columns - so put it back together
            IF v_COLS.EXISTS(3) THEN
                IF v_COLS(3) IS NOT NULL THEN
                    IF TRIM(v_COLS(3)) <> 'Report Creation Timestamp (EPT):' THEN
                    	v_ORG_NAME := v_ORG_NAME || ', ' || TRIM(v_COLS(3));
                        IF v_COLS.EXISTS(4) THEN
                            IF TRIM(v_COLS(4)) <> 'Report Creation Timestamp (EPT):' THEN
                    	        v_ORG_NAME := v_ORG_NAME || ', ' || TRIM(v_COLS(4));
                                IF TRIM(v_COLS(5)) <> 'Report Creation Timestamp (EPT):' THEN
                    	            v_ORG_NAME := v_ORG_NAME || ', ' || TRIM(v_COLS(5));
					            END IF;
                            END IF;
                         END IF;
					END IF;
                END IF;
            END IF;
        ELSIF v_IDX = 3 THEN
            v_START_DATE := TO_DATE(v_COLS(2), 'MM/DD/YYYY');
            v_DATE := v_START_DATE;
        ELSIF NOT v_COLS.EXISTS(1) THEN
            NULL;
        ELSIF v_COLS(1) IS NULL THEN
            NULL;
        ELSIF v_COLS(1) = 'Total Charges' THEN
            NULL;
        ELSIF v_COLS(1) = 'Total Credits' THEN
			-- we don't do any processing of this line or anything after, so we can go ahead and jump out here.
			-- this handles changes introduced with weekly billing (go-live expected in June 2009)
			EXIT;
        ELSIF v_COLS(1) = 'NET TOTAL' THEN
            NULL;
        ELSIF v_COLS(1) = 'CREDITS' THEN
            v_IS_CREDIT := 1;
        ELSIF v_COLS(1) = g_REPORT_END_LINE THEN
            EXIT;
		ELSE
            v_CHG_QTY_SCHED := PRICE_QUANTITY_SUMMARY_TABLE();
            IF v_COLS(4) IS NOT NULL AND v_COLS(2) IS NULL THEN
                --billing line item name has a comma in it; this is not an adjustment line item
                v_LINE_ITEM_NAME := v_COLS(3) || ', ' || TRIM(v_COLS(4));
                v_START_COL := 7;
                v_ADJ_DATE := NULL;
            ELSE
                v_LINE_ITEM_NAME := v_COLS(3);
                v_START_COL := 6;
                v_ADJ_DATE := NULL;
            END IF;
            IF v_COLS(2) = 'A' THEN
                BEGIN
                    v_ADJ_DATE := TO_DATE(v_COLS(4), 'MM/DD/YYYY');
                    v_LINE_ITEM_NAME := v_COLS(3);
                    v_START_COL := 6;
                EXCEPTION
                    WHEN OTHERS THEN
                        --billing line item name has a comma in it; this is an adjustment line item
                        v_LINE_ITEM_NAME := v_COLS(3) || ', ' || TRIM(v_COLS(4));
                        v_START_COL := 7;
                        v_ADJ_DATE := TO_DATE(v_COLS(5), 'MM/DD/YYYY');
                END;
            END IF;

            FOR I IN v_START_COL .. v_COLS.COUNT LOOP
                IF v_COLS(I) IS NOT NULL THEN
                    v_CHG_QTY_SCHED.EXTEND();
                    IF UPPER(v_COLS(2)) = 'A' THEN
                        v_CHG_QTY_SCHED(v_CHG_QTY_SCHED.LAST) := PRICE_QUANTITY_SUMMARY_TYPE(
                                                                NULL,
                                                                v_START_DATE,
                                                                TO_NUMBER(v_COLS(v_START_COL - 1)));
                    ELSE
                        v_CHG_QTY_SCHED(v_CHG_QTY_SCHED.LAST) := PRICE_QUANTITY_SUMMARY_TYPE(
                                                                NULL,
                                                                v_DATE,
                                                                TO_NUMBER(v_COLS(I)));
                    END IF;
                END IF;
                v_DATE := v_DATE + 1;
            END LOOP;

			p_RECORDS.EXTEND();
			p_RECORDS(p_RECORDS.LAST) := MEX_PJM_MONTH_TO_DATE_BILL_OBJ(
                                            v_ORG_NAME, v_START_DATE,
											TO_NUMBER(v_COLS(1)),
                                            CASE WHEN UPPER(v_COLS(2)) = 'A' THEN 1 ELSE 0 END,
                                            v_LINE_ITEM_NAME,
                                            v_ADJ_DATE,
                                            TO_NUMBER(v_COLS(v_START_COL - 1)), v_IS_CREDIT, v_CHG_QTY_SCHED);

		END IF;
		v_IDX := v_LINES.NEXT(v_IDX);
        v_DATE := v_START_DATE;
	END LOOP;

    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        p_STATUS  := SQLCODE;
        p_MESSAGE := 'Error in MEX_PJM_SETTLEMENT_MSRS.PARSE_MONTH_TO_DATE_BILL: ' || SQLERRM;
END PARSE_MONTH_TO_DATE_BILL;
----------------------------------------------------------------------------------------------------
PROCEDURE PARSE_LOC_RELIABILITY_SUMMARY
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
	WHILE v_LINES.EXISTS(v_IDX) AND INSTR(v_LINES(v_IDX),g_REPORT_END_LINE) = 0 LOOP
        IF v_LINES(v_IDX) IS NOT NULL AND v_IDX > 5 THEN
		    PARSE_UTIL.TOKENS_FROM_STRING(v_LINES(v_IDX),',',v_COLS);
			-- remaining lines contain charge determinant data
			p_RECORDS.EXTEND();
			p_RECORDS(p_RECORDS.LAST) := MEX_PJM_RECONCIL_CHARGES(v_COLS(1),
											TO_DATE(v_COLS(3),'MM/DD/YYYY'),
											NULL, NULL, v_COLS(4), TO_NUMBER(v_COLS(6)),
											TO_NUMBER(v_COLS(5)),TO_NUMBER(v_COLS(7)));
		END IF;
		v_IDX := v_LINES.NEXT(v_IDX);
	END LOOP;
  EXCEPTION
    WHEN OTHERS THEN
      p_STATUS := SQLCODE;
      p_MESSAGE := 'Error in MEX_PJM_SETTLEMENT_MSRS.PARSE_LOC_RELIABILITY_SUMMARY: ' || SQLERRM;
END PARSE_LOC_RELIABILITY_SUMMARY;
-----------------------------------------------------------------------------------------------
PROCEDURE PARSE_LOAD_RESPONSE_SUMMARY
	(
	p_CSV IN CLOB,
	p_RECORDS OUT MEX_PJM_LOAD_RESPONSE_SUMM_TBL,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) AS
v_LINES PARSE_UTIL.BIG_STRING_TABLE_MP;
v_COLS PARSE_UTIL.STRING_TABLE;
v_IDX BINARY_INTEGER;
v_CUT_DATE DATE;

BEGIN
    p_STATUS := MEX_UTIL.g_SUCCESS;

	PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_CSV,v_LINES);
	v_IDX := v_LINES.FIRST;
	p_RECORDS := MEX_PJM_LOAD_RESPONSE_SUMM_TBL();
	WHILE v_LINES.EXISTS(v_IDX) AND INSTR(v_LINES(v_IDX),g_REPORT_END_LINE) = 0 LOOP
        IF v_LINES(v_IDX) IS NOT NULL AND v_IDX > 5 THEN
            PARSE_UTIL.TOKENS_FROM_STRING(v_LINES(v_IDX),',',v_COLS);

            v_CUT_DATE := NEW_TIME(TO_DATE(v_COLS(5),g_GMT_HR_END_FORMAT), 'GMT', 'EST');
			-- remaining lines contain charge determinant data
			p_RECORDS.EXTEND();
			p_RECORDS(p_RECORDS.LAST) := MEX_PJM_LOAD_RESPONSE_SUMMARY(
                                            v_COLS(1),
                                            v_CUT_DATE,
                                            TO_NUMBER(v_COLS(6)),
                                            v_COLS(7),
                                            v_COLS(8),
                                            v_COLS(9),
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
                                            TO_NUMBER(v_COLS(23)));

		END IF;
		v_IDX := v_LINES.NEXT(v_IDX);
	END LOOP;
  EXCEPTION
    WHEN OTHERS THEN
      p_STATUS := SQLCODE;
      p_MESSAGE := 'Error in MEX_PJM_SETTLEMENT_MSRS.PARSE_LOAD_RESPONSE_SUMMARY: ' || SQLERRM;
END PARSE_LOAD_RESPONSE_SUMMARY;
-----------------------------------------------------------------------------------------------
PROCEDURE PARSE_RPM_AUCTION_SUMMARY
	(
	p_CSV IN CLOB,
	p_RECORDS OUT MEX_PJM_RPM_AUCTION_TBL,
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
	p_RECORDS := MEX_PJM_RPM_AUCTION_TBL();
	WHILE v_LINES.EXISTS(v_IDX) AND INSTR(v_LINES(v_IDX),g_REPORT_END_LINE) = 0 LOOP
        IF v_LINES(v_IDX) IS NOT NULL AND v_IDX > 5 THEN
		    PARSE_UTIL.TOKENS_FROM_STRING(v_LINES(v_IDX),',',v_COLS);
			-- remaining lines contain charge determinant data
			p_RECORDS.EXTEND();
			p_RECORDS(p_RECORDS.LAST) := MEX_PJM_RPM_AUCTION(v_COLS(1),
											TO_DATE(v_COLS(3),'MM/DD/YYYY'),
											v_COLS(4), v_COLS(5), v_COLS(6), TO_NUMBER(v_COLS(8)),
											TO_NUMBER(v_COLS(9)),TO_NUMBER(v_COLS(10)),
                                            TO_NUMBER(v_COLS(11)));
        END IF;
		v_IDX := v_LINES.NEXT(v_IDX);
	END LOOP;
  EXCEPTION
    WHEN OTHERS THEN
      p_STATUS := SQLCODE;
      p_MESSAGE := 'Error in MEX_PJM_SETTLEMENT.PARSE_RPM_AUCTION_SUMMARY: ' || SQLERRM;
END PARSE_RPM_AUCTION_SUMMARY;
-----------------------------------------------------------------------------------------------
PROCEDURE PARSE_INADV_INTERCHG_SUMMARY
	(
	p_CSV IN CLOB,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) AS
v_LINES PARSE_UTIL.BIG_STRING_TABLE_MP;
v_COLS PARSE_UTIL.STRING_TABLE;
v_IDX BINARY_INTEGER;
v_CUT_DATE DATE;

BEGIN
    p_STATUS := MEX_UTIL.g_SUCCESS;

	PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_CSV,v_LINES);
	v_IDX := v_LINES.FIRST;
	WHILE v_LINES.EXISTS(v_IDX) AND INSTR(v_LINES(v_IDX),g_REPORT_END_LINE) = 0 LOOP
		PARSE_UTIL.TOKENS_FROM_STRING(v_LINES(v_IDX),',',v_COLS);
		IF v_LINES(v_IDX) IS NOT NULL AND v_IDX > 5 THEN

            v_CUT_DATE := NEW_TIME(TO_DATE(v_COLS(4), g_GMT_HR_END_FORMAT),'GMT', 'EST');

            INSERT INTO PJM_INADV_INTERCHG_CHARGE_SUM VALUES
                 (v_COLS(1),
                 NULL,
                 NULL,
                 NULL,
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
      p_MESSAGE := 'Error in MEX_PJM_SETTLEMENT_MSRS.PARSE_INADV_INTERCHG_SUMMARY: ' || SQLERRM;
END PARSE_INADV_INTERCHG_SUMMARY;
----------------------------------------------------------------------------------------------------
PROCEDURE PARSE_CAP_TRANSFER_CREDITS
    (
    p_CSV     IN CLOB,
    p_RECORDS OUT MEX_PJM_CAP_TRANSFER_RIGHT_TBL,
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
    p_RECORDS := MEX_PJM_CAP_TRANSFER_RIGHT_TBL();
    WHILE v_LINES.EXISTS(v_IDX) AND INSTR(v_LINES(v_IDX),g_REPORT_END_LINE) = 0 LOOP
        IF v_LINES(v_IDX) IS NOT NULL AND v_IDX > 5 THEN
            PARSE_UTIL.TOKENS_FROM_STRING(v_LINES(v_IDX), ',', v_COLS);
            -- remaining lines contain charge determinant data
            p_RECORDS.EXTEND();
            p_RECORDS(p_RECORDS.LAST) := MEX_PJM_CAP_TRANSFER_RIGHTS(ORG_ID                 => v_COLS(1),
                                                                  ORG_NAME                  => v_COLS(2),
                                                                  OPER_DAY                  => TO_DATE(v_COLS(3),g_SHORT_DATE_FORMAT),
                                                                  ZONE                      => v_COLS(4),
                                                                  CapTransferRightMW        => NVL(TO_NUMBER(v_COLS(5)),0),
                                                                  UCAPObligation            => NVL(TO_NUMBER(v_COLS(6)),0),
                                                                  TotalZoneObligation       => NVL(TO_NUMBER(v_COLS(7)),0),
                                                                  TradedCTRMW               => NVL(TO_NUMBER(v_COLS(8)),0),
                                                                  ZonalCTRRate              => NVL(TO_NUMBER(v_COLS(9)),0),
                                                                  CREDIT                    => NVL(TO_NUMBER(v_COLS(10)),0));
        END IF;
        v_IDX := v_LINES.NEXT(v_IDX);
    END LOOP;
EXCEPTION
    WHEN OTHERS THEN
        p_STATUS  := SQLCODE;
        p_MESSAGE := 'Error in MEX_PJM_SETTLEMENT.PARSE_CAP_TRANSFER_CREDITS: ' ||SQLERRM;
END PARSE_CAP_TRANSFER_CREDITS;
----------------------------------------------------------------------------------------------------
PROCEDURE PARSE_GEN_CREDIT_PORTFOLIO
(
    p_CSV     IN CLOB,
    p_RECORDS OUT MEX_PJM_GEN_PORTFO_CREDIT_TBL,
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
    p_RECORDS := MEX_PJM_GEN_PORTFO_CREDIT_TBL();
    WHILE v_LINES.EXISTS(v_IDX) AND INSTR(v_LINES(v_IDX),g_REPORT_END_LINE) = 0 LOOP
        IF v_LINES(v_IDX) IS NOT NULL AND v_IDX > 5 THEN
            PARSE_UTIL.TOKENS_FROM_STRING(v_LINES(v_IDX), ',', v_COLS);
            -- remaining lines contain charge determinant data
            p_RECORDS.EXTEND();
            p_RECORDS(p_RECORDS.LAST) := MEX_PJM_GEN_PORTFO_CREDIT(ORG_ID                         => v_COLS(1),
                                                                  DAY                            => TO_DATE(v_COLS(3),g_SHORT_DATE_FORMAT),
                                                                  DA_OP_RES_GEN_CREDIT           => NVL(TO_NUMBER(v_COLS(4)),0),
                                                                  DA_OP_RES_TXN_CREDIT           => NVL(TO_NUMBER(v_COLS(4)),0),
                                                                  BAL_OP_RES_GEN_CREDIT          => NVL(TO_NUMBER(v_COLS(4)),0),
                                                                  BAL_OP_RES_STARTUP_CANCEL_CRED => NVL(TO_NUMBER(v_COLS(4)),0),
                                                                  BAL_OP_RES_LOC                 => NVL(TO_NUMBER(v_COLS(4)),0),
                                                                  BAL_OP_RES_TXN_CREDIT          => NVL(TO_NUMBER(v_COLS(4)),0));
        END IF;
        v_IDX := v_LINES.NEXT(v_IDX);
    END LOOP;
EXCEPTION
    WHEN OTHERS THEN
        p_STATUS  := SQLCODE;
        p_MESSAGE := 'Error in MEX_PJM_SETTLEMENT.PARSE_RPM_AUCTION_SUMMARY: ' ||SQLERRM;
END PARSE_GEN_CREDIT_PORTFOLIO;
-----------------------------------------------------------------------------------------------
-- These routines will fetch the CSV files from PJM for the requested report and dates, and then
-- return the data in object tables.
----------------------------------------------------------------------------------------------------
PROCEDURE FETCH_MONTHLY_STATEMENT
    (
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_LOGGER   IN  OUT MM_LOGGER_ADAPTER,
    p_CRED	   IN	 MEX_CREDENTIALS,
	p_LOG_ONLY   IN  NUMBER,
	p_RECORDS OUT MEX_PJM_MONTHLY_STMNT_MSRS_TBL,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) AS

v_RESP CLOB := NULL;
v_PARAMS MEX_Util.Parameter_Map := Mex_Switchboard.c_Empty_Parameter_Map;
BEGIN
    v_PARAMS(MEX_PJM.c_Format) := 'c';
  	v_PARAMS(MEX_PJM.c_DEBUG) := g_DEBUG_EXCHANGES;
    v_PARAMS(MEX_PJM.c_Report) := g_ET_MONTHLY_BILLING_STATEMENT;
  	p_LOGGER.EXCHANGE_NAME := v_PARAMS(MEX_PJM.c_Report);
    v_PARAMS(MEX_PJM.c_Version) := g_MSRS_REPORT_VERSION;
  	MEX_PJM.RUN_PJM_BROWSERLESS( v_PARAMS,
  								'msrs', -- p_REQUEST_APP
			   					p_LOGGER,
								p_CRED,
								p_BEGIN_DATE,
								p_END_DATE,
                    			'download',  -- p_REQUEST_DIR
                    		    v_RESP,
								p_STATUS,
								p_MESSAGE, p_LOG_ONLY );
	IF p_STATUS = Mex_Switchboard.c_Status_Success THEN
		PARSE_MONTHLY_STATEMENT(v_RESP,p_RECORDS,p_STATUS,p_MESSAGE);
	END IF;
	IF NOT v_RESP IS NULL THEN
	    DBMS_LOB.FREETEMPORARY(v_RESP);
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
	p_LOGGER   IN  OUT MM_LOGGER_ADAPTER,
    p_CRED	   IN	 MEX_CREDENTIALS,
	p_LOG_ONLY   IN  NUMBER,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) AS
v_RESP CLOB := NULL;
v_PARAMS MEX_Util.Parameter_Map := Mex_Switchboard.c_Empty_Parameter_Map;
BEGIN
    v_PARAMS(MEX_PJM.c_Format) := 'c';
  	v_PARAMS(MEX_PJM.c_DEBUG) := g_DEBUG_EXCHANGES;
    v_PARAMS(MEX_PJM.c_Report) := g_ET_SPOT_MKT_ENERGY_SUMMARY;
    v_PARAMS(MEX_PJM.c_Version) := g_MSRS_REPORT_VERSION;
  	p_LOGGER.EXCHANGE_NAME := v_PARAMS(MEX_PJM.c_Report);
  	MEX_PJM.RUN_PJM_BROWSERLESS( v_PARAMS,
  								'msrs', -- p_REQUEST_APP
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
	p_LOGGER   IN  OUT MM_LOGGER_ADAPTER,
    p_CRED	   IN	 MEX_CREDENTIALS,
	p_LOG_ONLY   IN  NUMBER,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) AS
v_RESP CLOB := NULL;
v_PARAMS MEX_Util.Parameter_Map := Mex_Switchboard.c_Empty_Parameter_Map;
BEGIN
    v_PARAMS(MEX_PJM.c_Format) := 'c';
  	v_PARAMS(MEX_PJM.c_DEBUG) := g_DEBUG_EXCHANGES;
    v_PARAMS(MEX_PJM.c_Report) := g_ET_CONGESTION_SUMMARY;
    v_PARAMS(MEX_PJM.c_Version) := g_MSRS_REPORT_VERSION;
  	p_LOGGER.EXCHANGE_NAME := v_PARAMS(MEX_PJM.c_Report);
  	MEX_PJM.RUN_PJM_BROWSERLESS( v_PARAMS,
  								'msrs', -- p_REQUEST_APP
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
PROCEDURE FETCH_CONG_LOSS_LOAD_RECONCIL
    (
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
    v_PARAMS(MEX_PJM.c_Format) := 'c';
  	v_PARAMS(MEX_PJM.c_DEBUG) := g_DEBUG_EXCHANGES;
    v_PARAMS(MEX_PJM.c_Report) := g_ET_CONGES_LOSS_LOAD_RECON;
    v_PARAMS(MEX_PJM.c_Version) := g_MSRS_REPORT_VERSION;
  	p_LOGGER.EXCHANGE_NAME := v_PARAMS(MEX_PJM.c_Report);
  	MEX_PJM.RUN_PJM_BROWSERLESS( v_PARAMS,
  								'msrs', -- p_REQUEST_APP
			   					p_LOGGER,
								p_CRED,
								p_BEGIN_DATE,
								p_END_DATE,
                    			'download',  -- p_REQUEST_DIR
                    		    v_RESP,
								p_STATUS,
								p_MESSAGE, p_LOG_ONLY );
	IF p_STATUS = Mex_Switchboard.c_Status_Success THEN
		PARSE_CONG_LOSS_LOAD_RECONCIL(v_RESP,p_STATUS,p_MESSAGE);
	END IF;
	IF NOT v_RESP IS NULL THEN
	    DBMS_LOB.FREETEMPORARY(v_RESP);
	END IF;
END FETCH_CONG_LOSS_LOAD_RECONCIL;
----------------------------------------------------------------------------------------------------
PROCEDURE FETCH_SCHEDULE9_10_SUMMARY
	(
    p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_LOGGER   IN  OUT MM_LOGGER_ADAPTER,
    p_CRED	   IN	 MEX_CREDENTIALS,
	p_LOG_ONLY   IN  NUMBER,
	p_RECORDS OUT MEX_PJM_SCHED9_10_SUM_TBL_MSRS,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) AS
v_RESP CLOB := NULL;
v_PARAMS MEX_Util.Parameter_Map := Mex_Switchboard.c_Empty_Parameter_Map;
BEGIN
    v_PARAMS(MEX_PJM.c_Format) := 'c';
  	v_PARAMS(MEX_PJM.c_DEBUG) := g_DEBUG_EXCHANGES;
    v_PARAMS(MEX_PJM.c_Report) := g_ET_SCHEDULE_9_AND_10_SUMMARY;
    v_PARAMS(MEX_PJM.c_Version) := g_MSRS_REPORT_VERSION;
  	p_LOGGER.EXCHANGE_NAME := v_PARAMS(MEX_PJM.c_Report);
  	MEX_PJM.RUN_PJM_BROWSERLESS( v_PARAMS,
  								'msrs', -- p_REQUEST_APP
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
PROCEDURE FETCH_NITS_CREDIT_SUMMARY
	(
    p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_LOGGER   IN  OUT MM_LOGGER_ADAPTER,
    p_CRED	   IN	 MEX_CREDENTIALS,
	p_LOG_ONLY   IN  NUMBER,
	p_RECORDS OUT MEX_PJM_NITS_SUMMARY_TBL,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) AS
v_RESP CLOB := NULL;
v_PARAMS MEX_Util.Parameter_Map := Mex_Switchboard.c_Empty_Parameter_Map;
BEGIN
    v_PARAMS(MEX_PJM.c_Format) := 'c';
  	v_PARAMS(MEX_PJM.c_DEBUG) := g_DEBUG_EXCHANGES;
    v_PARAMS(MEX_PJM.c_Report) := g_ET_NET_TRANS_SERV_CRED_SUMM;
    v_PARAMS(MEX_PJM.c_Version) := g_MSRS_REPORT_VERSION;
  	p_LOGGER.EXCHANGE_NAME := v_PARAMS(MEX_PJM.c_Report);
  	MEX_PJM.RUN_PJM_BROWSERLESS( v_PARAMS,
  								'msrs', -- p_REQUEST_APP
			   					p_LOGGER,
								p_CRED,
								p_BEGIN_DATE,
								p_END_DATE,
                    			'download',  -- p_REQUEST_DIR
                    		    v_RESP,
								p_STATUS,
								p_MESSAGE, p_LOG_ONLY );
	IF p_STATUS = Mex_Switchboard.c_Status_Success THEN
		PARSE_NITS_CREDIT_SUMMARY(v_RESP,p_RECORDS,p_STATUS,p_MESSAGE);
	END IF;
	IF NOT v_RESP IS NULL THEN
	    DBMS_LOB.FREETEMPORARY(v_RESP);
	END IF;
END FETCH_NITS_CREDIT_SUMMARY;
----------------------------------------------------------------------------------------------------
PROCEDURE FETCH_NITS_CHARGE_SUMMARY
	(
    p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_LOGGER   IN  OUT MM_LOGGER_ADAPTER,
    p_CRED	   IN	 MEX_CREDENTIALS,
	p_LOG_ONLY   IN  NUMBER,
	p_RECORDS OUT MEX_PJM_NITS_SUMMARY_TBL,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) AS
v_RESP CLOB := NULL;
v_PARAMS MEX_Util.Parameter_Map := Mex_Switchboard.c_Empty_Parameter_Map;
BEGIN
    v_PARAMS(MEX_PJM.c_Format) := 'c';
  	v_PARAMS(MEX_PJM.c_DEBUG) := g_DEBUG_EXCHANGES;
    v_PARAMS(MEX_PJM.c_Report) := g_ET_NET_TRANS_SERV_CHG_SUMM;
    v_PARAMS(MEX_PJM.c_Version) := g_MSRS_REPORT_VERSION;
  	p_LOGGER.EXCHANGE_NAME := v_PARAMS(MEX_PJM.c_Report);
  	MEX_PJM.RUN_PJM_BROWSERLESS( v_PARAMS,
  								'msrs', -- p_REQUEST_APP
			   					p_LOGGER,
								p_CRED,
								p_BEGIN_DATE,
								p_END_DATE,
                    			'download',  -- p_REQUEST_DIR
                    		    v_RESP,
								p_STATUS,
								p_MESSAGE, p_LOG_ONLY );
	IF p_STATUS = Mex_Switchboard.c_Status_Success THEN
		PARSE_NITS_CHARGE_SUMMARY(v_RESP,p_RECORDS,p_STATUS,p_MESSAGE);
	END IF;
	IF NOT v_RESP IS NULL THEN
	    DBMS_LOB.FREETEMPORARY(v_RESP);
	END IF;
END FETCH_NITS_CHARGE_SUMMARY;
----------------------------------------------------------------------------------------------------
PROCEDURE FETCH_EXPANSION_COST_SUMMARY
	(
    p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_LOGGER   IN  OUT MM_LOGGER_ADAPTER,
    p_CRED	   IN	 MEX_CREDENTIALS,
	p_LOG_ONLY   IN  NUMBER,
	p_RECORDS OUT MEX_PJM_NITS_SUMMARY_TBL,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) AS
v_RESP CLOB := NULL;
v_PARAMS MEX_Util.Parameter_Map := Mex_Switchboard.c_Empty_Parameter_Map;
BEGIN
    v_PARAMS(MEX_PJM.c_Format) := 'c';
  	v_PARAMS(MEX_PJM.c_DEBUG) := g_DEBUG_EXCHANGES;
    v_PARAMS(MEX_PJM.c_Report) := g_ET_EXP_COST_RECOVERY_CHARGES;
    v_PARAMS(MEX_PJM.c_Version) := g_MSRS_REPORT_VERSION;
  	p_LOGGER.EXCHANGE_NAME := v_PARAMS(MEX_PJM.c_Report);
  	MEX_PJM.RUN_PJM_BROWSERLESS( v_PARAMS,
  								'msrs', -- p_REQUEST_APP
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
PROCEDURE FETCH_RTO_STARTUP_COST_SUMMARY
	(
    p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_LOGGER   IN  OUT MM_LOGGER_ADAPTER,
    p_CRED	   IN	 MEX_CREDENTIALS,
	p_LOG_ONLY   IN  NUMBER,
	p_RECORDS OUT MEX_PJM_NITS_SUMMARY_TBL,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) AS
v_RESP CLOB := NULL;
v_PARAMS MEX_Util.Parameter_Map := Mex_Switchboard.c_Empty_Parameter_Map;
BEGIN
    v_PARAMS(MEX_PJM.c_Format) := 'c';
  	v_PARAMS(MEX_PJM.c_DEBUG) := g_DEBUG_EXCHANGES;
    v_PARAMS(MEX_PJM.c_Report) := g_ET_RTO_COST_RECOVERY_CHARGES;
    v_PARAMS(MEX_PJM.c_Version) := g_MSRS_REPORT_VERSION;
  	p_LOGGER.EXCHANGE_NAME := v_PARAMS(MEX_PJM.c_Report);
  	MEX_PJM.RUN_PJM_BROWSERLESS( v_PARAMS,
  								'msrs', -- p_REQUEST_APP
			   					p_LOGGER,
								p_CRED,
								p_BEGIN_DATE,
								p_END_DATE,
                    			'download',  -- p_REQUEST_DIR
                    		    v_RESP,
								p_STATUS,
								p_MESSAGE, p_LOG_ONLY );
	IF p_STATUS = Mex_Switchboard.c_Status_Success THEN
		PARSE_RTO_STARTUP_COST_SUMMARY(v_RESP,p_RECORDS,p_STATUS,p_MESSAGE);
	END IF;
	IF NOT v_RESP IS NULL THEN
	    DBMS_LOB.FREETEMPORARY(v_RESP);
	END IF;
END FETCH_RTO_STARTUP_COST_SUMMARY;
----------------------------------------------------------------------------------------------------
PROCEDURE FETCH_REACTIVE_SERV_SUMMARY
	(
    p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_LOGGER   IN  OUT MM_LOGGER_ADAPTER,
    p_CRED	   IN	 MEX_CREDENTIALS,
	p_LOG_ONLY   IN  NUMBER,
	p_RECORDS OUT MEX_PJM_REACTIVE_SERV_SUMM_TBL,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) AS
v_RESP CLOB := NULL;
v_PARAMS MEX_Util.Parameter_Map := Mex_Switchboard.c_Empty_Parameter_Map;
BEGIN
    v_PARAMS(MEX_PJM.c_Format) := 'c';
  	v_PARAMS(MEX_PJM.c_DEBUG) := g_DEBUG_EXCHANGES;
    v_PARAMS(MEX_PJM.c_Report) := g_ET_REACTIVE_SERVICES_SUMMARY;
    v_PARAMS(MEX_PJM.c_Version) := g_MSRS_REPORT_VERSION;
  	p_LOGGER.EXCHANGE_NAME := v_PARAMS(MEX_PJM.c_Report);
  	MEX_PJM.RUN_PJM_BROWSERLESS( v_PARAMS,
  								'msrs', -- p_REQUEST_APP
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
PROCEDURE FETCH_OPER_RES_CHG_SUMMARY
	(
    p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_LOGGER   IN  OUT MM_LOGGER_ADAPTER,
    p_CRED	   IN	 MEX_CREDENTIALS,
	p_LOG_ONLY   IN  NUMBER,
	p_RECORDS OUT MEX_PJM_OPER_RES_SUMMARY_TBL,
	p_RECORDS_NEW OUT MEX_PJM_OPER_RES_SUMM_MSRS_TBL,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) AS
v_RESP CLOB := NULL;
v_PARAMS MEX_Util.Parameter_Map := Mex_Switchboard.c_Empty_Parameter_Map;
BEGIN
    v_PARAMS(MEX_PJM.c_Format) := 'c';
  	v_PARAMS(MEX_PJM.c_DEBUG) := g_DEBUG_EXCHANGES;
    v_PARAMS(MEX_PJM.c_Report) := g_ET_OPER_RESERVES_SUMMARY;
    v_PARAMS(MEX_PJM.c_Version) := g_MSRS_REPORT_VERSION;
  	p_LOGGER.EXCHANGE_NAME := v_PARAMS(MEX_PJM.c_Report);
  	MEX_PJM.RUN_PJM_BROWSERLESS( v_PARAMS,
  								'msrs', -- p_REQUEST_APP
			   					p_LOGGER,
								p_CRED,
								p_BEGIN_DATE,
								p_END_DATE,
                    			'download',  -- p_REQUEST_DIR
                    		    v_RESP,
								p_STATUS,
								p_MESSAGE, p_LOG_ONLY );
	IF p_STATUS = Mex_Switchboard.c_Status_Success THEN
		--new format starting December 1, 2008
		IF p_BEGIN_DATE >= MM_PJM_UTIL.g_PJM_OP_RES_GO_LIVE THEN
			PARSE_OPER_RES_CHG_SUMMARY_NEW(v_RESP,p_RECORDS_NEW,p_STATUS,p_MESSAGE);
		ELSE
			PARSE_OPER_RES_CHG_SUMMARY(v_RESP,p_RECORDS,p_STATUS,p_MESSAGE);
		END IF;
	END IF;
	IF NOT v_RESP IS NULL THEN
	    DBMS_LOB.FREETEMPORARY(v_RESP);
	END IF;
END FETCH_OPER_RES_CHG_SUMMARY;
----------------------------------------------------------------------------------------------------
PROCEDURE FETCH_REG_OPER_RES_CHG_SUMMARY
	(
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_LOGGER   IN  OUT MM_LOGGER_ADAPTER,
    p_CRED	   IN	 MEX_CREDENTIALS,
	p_LOG_ONLY   IN  NUMBER,
	p_RECORDS OUT MEX_PJM_REG_OPER_RES_SUMM_TBL,	
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) AS
v_RESP CLOB := NULL;
v_PARAMS MEX_Util.Parameter_Map := Mex_Switchboard.c_Empty_Parameter_Map;
BEGIN
    v_PARAMS(MEX_PJM.c_Format) := 'c';
  	v_PARAMS(MEX_PJM.c_DEBUG) := g_DEBUG_EXCHANGES;
    v_PARAMS(MEX_PJM.c_Report) := g_ET_REG_OPER_RES_CHG_SUMMARY;
    v_PARAMS(MEX_PJM.c_Version) := g_MSRS_REPORT_VERSION;
  	p_LOGGER.EXCHANGE_NAME := v_PARAMS(MEX_PJM.c_Report);
  	MEX_PJM.RUN_PJM_BROWSERLESS( v_PARAMS,
  								'msrs', -- p_REQUEST_APP
			   					p_LOGGER,
								p_CRED,
								p_BEGIN_DATE,
								p_END_DATE,
                    			'download',  -- p_REQUEST_DIR
                    		    v_RESP,
								p_STATUS,
								p_MESSAGE, p_LOG_ONLY );
	IF p_STATUS >= 0 THEN	
        PARSE_REG_OPER_RES_CHG_SUMMARY(v_RESP,p_RECORDS,p_STATUS,p_MESSAGE);	
	END IF;
	IF NOT v_RESP IS NULL THEN
	    DBMS_LOB.FREETEMPORARY(v_RESP);
	END IF;
END FETCH_REG_OPER_RES_CHG_SUMMARY;
----------------------------------------------------------------------------------------------------
PROCEDURE FETCH_OP_RES_GEN_CR_DETAILS
	(
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
    v_PARAMS(MEX_PJM.c_Format) := 'c';
  	v_PARAMS(MEX_PJM.c_DEBUG) := g_DEBUG_EXCHANGES;
    v_PARAMS(MEX_PJM.c_Report) := g_ET_OPER_RESERVE_GEN_CRED_DET;
    v_PARAMS(MEX_PJM.c_Version) := g_MSRS_REPORT_VERSION;
  	p_LOGGER.EXCHANGE_NAME := v_PARAMS(MEX_PJM.c_Report);
  	MEX_PJM.RUN_PJM_BROWSERLESS( v_PARAMS,
  								'msrs', -- p_REQUEST_APP
			   					p_LOGGER,
								p_CRED,
								p_BEGIN_DATE,
								p_END_DATE,
                    			'download',  -- p_REQUEST_DIR
                    		    v_RESP,
								p_STATUS,
								p_MESSAGE, p_LOG_ONLY );
	IF p_STATUS = Mex_Switchboard.c_Status_Success THEN
		PARSE_OP_RES_GEN_CR_DETAILS(v_RESP,p_STATUS,p_MESSAGE);
	END IF;
	IF NOT v_RESP IS NULL THEN
	    DBMS_LOB.FREETEMPORARY(v_RESP);
	END IF;
END FETCH_OP_RES_GEN_CR_DETAILS;
----------------------------------------------------------------------------------------------------
PROCEDURE FETCH_GENERATOR_CREDIT_SUMMARY
	(
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_LOGGER IN OUT MM_LOGGER_ADAPTER,
    p_CRED IN MEX_CREDENTIALS,
	p_LOG_ONLY IN  NUMBER,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) AS
v_RESP CLOB := NULL;
v_PARAMS MEX_Util.Parameter_Map := Mex_Switchboard.c_Empty_Parameter_Map;
BEGIN
    v_PARAMS(MEX_PJM.c_Format) := 'c';
  	v_PARAMS(MEX_PJM.c_DEBUG) := g_DEBUG_EXCHANGES;
    v_PARAMS(MEX_PJM.c_Report) := g_ET_GENERATOR_CREDIT_SUMMARY;
    v_PARAMS(MEX_PJM.c_Version) := g_MSRS_REPORT_VERSION;
  	p_LOGGER.EXCHANGE_NAME := v_PARAMS(MEX_PJM.c_Report);
  	MEX_PJM.RUN_PJM_BROWSERLESS( v_PARAMS,
  								'msrs', -- p_REQUEST_APP
			   					p_LOGGER,
								p_CRED,
								p_BEGIN_DATE,
								p_END_DATE,
                    			'download',  -- p_REQUEST_DIR
                    		    v_RESP,
								p_STATUS,
								p_MESSAGE, p_LOG_ONLY );
	IF p_STATUS = Mex_Switchboard.c_Status_Success THEN
		PARSE_GENERATOR_CREDIT_SUMMARY(v_RESP,p_STATUS,p_MESSAGE);
	END IF;
	IF NOT v_RESP IS NULL THEN
	    DBMS_LOB.FREETEMPORARY(v_RESP);
	END IF;
END FETCH_GENERATOR_CREDIT_SUMMARY;
----------------------------------------------------------------------------------------------------
PROCEDURE FETCH_OP_RES_LOST_OPP_COST
	(
    p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_LOGGER   IN  OUT MM_LOGGER_ADAPTER,
    p_CRED	   IN	 MEX_CREDENTIALS,
	p_LOG_ONLY   IN  NUMBER,
	p_RECORDS OUT MEX_PJM_OP_RES_LOC_MSRS_TBL,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) AS
v_RESP CLOB := NULL;
v_PARAMS MEX_Util.Parameter_Map := Mex_Switchboard.c_Empty_Parameter_Map;
BEGIN
    v_PARAMS(MEX_PJM.c_Format) := 'c';
  	v_PARAMS(MEX_PJM.c_DEBUG) := g_DEBUG_EXCHANGES;
    v_PARAMS(MEX_PJM.c_Report) := g_ET_OPRES_LOST_OPP_CREDITS;
    v_PARAMS(MEX_PJM.c_Version) := g_MSRS_REPORT_VERSION;
  	p_LOGGER.EXCHANGE_NAME := v_PARAMS(MEX_PJM.c_Report);
  	MEX_PJM.RUN_PJM_BROWSERLESS( v_PARAMS,
  								'msrs', -- p_REQUEST_APP
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
PROCEDURE FETCH_NITS_OFFSET_SUMMARY
	(
    p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_LOGGER   IN  OUT MM_LOGGER_ADAPTER,
    p_CRED	   IN	 MEX_CREDENTIALS,
	p_LOG_ONLY   IN  NUMBER,
	p_RECORDS OUT MEX_PJM_TRANS_OFFSET_CHG_TBL,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) AS
v_RESP CLOB := NULL;
v_PARAMS MEX_Util.Parameter_Map := Mex_Switchboard.c_Empty_Parameter_Map;
BEGIN
    v_PARAMS(MEX_PJM.c_Format) := 'c';
  	v_PARAMS(MEX_PJM.c_DEBUG) := g_DEBUG_EXCHANGES;
    v_PARAMS(MEX_PJM.c_Report) := g_ET_NET_TRANS_OFFSET_CHG_SUMM;
    v_PARAMS(MEX_PJM.c_Version) := g_MSRS_REPORT_VERSION;
  	p_LOGGER.EXCHANGE_NAME := v_PARAMS(MEX_PJM.c_Report);
  	MEX_PJM.RUN_PJM_BROWSERLESS( v_PARAMS,
  								'msrs', -- p_REQUEST_APP
			   					p_LOGGER,
								p_CRED,
								p_BEGIN_DATE,
								p_END_DATE,
                    			'download',  -- p_REQUEST_DIR
                    		    v_RESP,
								p_STATUS,
								p_MESSAGE, p_LOG_ONLY );
	IF p_STATUS = Mex_Switchboard.c_Status_Success THEN
		PARSE_NITS_OFFSET_SUMMARY(v_RESP,p_RECORDS,p_STATUS,p_MESSAGE);
	END IF;
	IF NOT v_RESP IS NULL THEN
	    DBMS_LOB.FREETEMPORARY(v_RESP);
	END IF;
END FETCH_NITS_OFFSET_SUMMARY;
----------------------------------------------------------------------------------------------------
PROCEDURE FETCH_SYNCH_CONDENS_SUMMARY
    (
    p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_LOGGER   IN  OUT MM_LOGGER_ADAPTER,
    p_CRED	   IN	 MEX_CREDENTIALS,
	p_LOG_ONLY   IN  NUMBER,
	p_RECORDS OUT MEX_PJM_SYNCH_CONDENS_MSRS_TBL,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) AS
v_RESP CLOB := NULL;
v_PARAMS MEX_Util.Parameter_Map := Mex_Switchboard.c_Empty_Parameter_Map;
BEGIN
    v_PARAMS(MEX_PJM.c_Format) := 'c';
  	v_PARAMS(MEX_PJM.c_DEBUG) := g_DEBUG_EXCHANGES;
    v_PARAMS(MEX_PJM.c_Report) := g_ET_SYNC_CONDENSING_SUMMARY;
    v_PARAMS(MEX_PJM.c_Version) := g_MSRS_REPORT_VERSION;
  	p_LOGGER.EXCHANGE_NAME := v_PARAMS(MEX_PJM.c_Report);
  	MEX_PJM.RUN_PJM_BROWSERLESS( v_PARAMS,
  								'msrs', -- p_REQUEST_APP
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
PROCEDURE FETCH_TOSSCD_SUMMARY
   (
    p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_LOGGER   IN  OUT MM_LOGGER_ADAPTER,
    p_CRED	   IN	 MEX_CREDENTIALS,
	p_LOG_ONLY   IN  NUMBER,
	p_RECORDS OUT MEX_PJM_TOSSCD_SUMMARY_TBL,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) AS
v_RESP CLOB := NULL;
v_PARAMS MEX_Util.Parameter_Map := Mex_Switchboard.c_Empty_Parameter_Map;
BEGIN
    v_PARAMS(MEX_PJM.c_Format) := 'c';
  	v_PARAMS(MEX_PJM.c_DEBUG) := g_DEBUG_EXCHANGES;
    v_PARAMS(MEX_PJM.c_Report) := g_ET_SCHED_1A_CHARGE_SUMMARY;
    v_PARAMS(MEX_PJM.c_Version) := g_MSRS_REPORT_VERSION;
  	p_LOGGER.EXCHANGE_NAME := v_PARAMS(MEX_PJM.c_Report);
  	MEX_PJM.RUN_PJM_BROWSERLESS( v_PARAMS,
  								'msrs', -- p_REQUEST_APP
			   					p_LOGGER,
								p_CRED,
								p_BEGIN_DATE,
								p_END_DATE,
                    			'download',  -- p_REQUEST_DIR
                    		    v_RESP,
								p_STATUS,
								p_MESSAGE, p_LOG_ONLY );
    IF p_STATUS = Mex_Switchboard.c_Status_Success THEN
		PARSE_TOSSCD_SUMMARY(v_RESP,p_RECORDS,p_STATUS,p_MESSAGE);
	END IF;
	IF NOT v_RESP IS NULL THEN
	    DBMS_LOB.FREETEMPORARY(v_RESP);
	END IF;
END FETCH_TOSSCD_SUMMARY;
----------------------------------------------------------------------------------------------------
PROCEDURE FETCH_REGULATION_SUMMARY
   (
    p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_LOGGER   IN  OUT MM_LOGGER_ADAPTER,
    p_CRED	   IN	 MEX_CREDENTIALS,
	p_LOG_ONLY   IN  NUMBER,
	p_RECORDS OUT MEX_PJM_REGL_SUMMARY_MSRS_TBL,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) AS
v_RESP CLOB := NULL;
v_PARAMS MEX_Util.Parameter_Map := Mex_Switchboard.c_Empty_Parameter_Map;
BEGIN
    v_PARAMS(MEX_PJM.c_Format) := 'c';
  	v_PARAMS(MEX_PJM.c_DEBUG) := g_DEBUG_EXCHANGES;
    v_PARAMS(MEX_PJM.c_Report) := g_ET_REGULATION_SUMMARY;
    v_PARAMS(MEX_PJM.c_Version) := g_MSRS_REPORT_VERSION;
  	p_LOGGER.EXCHANGE_NAME := v_PARAMS(MEX_PJM.c_Report);
  	MEX_PJM.RUN_PJM_BROWSERLESS( v_PARAMS,
  								'msrs', -- p_REQUEST_APP
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
PROCEDURE FETCH_REGULATION_CREDITS
    (
    p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_LOGGER   IN  OUT MM_LOGGER_ADAPTER,
    p_CRED	   IN	 MEX_CREDENTIALS,
	p_LOG_ONLY   IN  NUMBER,
	p_RECORDS OUT MEX_PJM_REGULATION_CREDIT_TBL,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) AS
v_RESP CLOB := NULL;
v_PARAMS MEX_Util.Parameter_Map := Mex_Switchboard.c_Empty_Parameter_Map;
BEGIN
    v_PARAMS(MEX_PJM.c_Format) := 'c';
  	v_PARAMS(MEX_PJM.c_DEBUG) := g_DEBUG_EXCHANGES;
    v_PARAMS(MEX_PJM.c_Report) := g_ET_REGULATION_CRED_SUMMARY;
    v_PARAMS(MEX_PJM.c_Version) := g_MSRS_REPORT_VERSION;
  	p_LOGGER.EXCHANGE_NAME := v_PARAMS(MEX_PJM.c_Report);
  	MEX_PJM.RUN_PJM_BROWSERLESS( v_PARAMS,
  								'msrs', -- p_REQUEST_APP
			   					p_LOGGER,
								p_CRED,
								p_BEGIN_DATE,
								p_END_DATE,
                    			'download',  -- p_REQUEST_DIR
                    		    v_RESP,
								p_STATUS,
								p_MESSAGE, p_LOG_ONLY );
    IF p_STATUS = Mex_Switchboard.c_Status_Success THEN
		PARSE_REGULATION_CREDITS(v_RESP,p_RECORDS,p_STATUS,p_MESSAGE);
	END IF;
	IF NOT v_RESP IS NULL THEN
	    DBMS_LOB.FREETEMPORARY(v_RESP);
	END IF;
END FETCH_REGULATION_CREDITS;
----------------------------------------------------------------------------------------------------
PROCEDURE FETCH_FTR_TARGET_CREDITS
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
    v_PARAMS(MEX_PJM.c_Format) := 'c';
  	v_PARAMS(MEX_PJM.c_DEBUG) := g_DEBUG_EXCHANGES;
    v_PARAMS(MEX_PJM.c_Report) := g_ET_FTR_TARGET_CREDITS;
    v_PARAMS(MEX_PJM.c_Version) := g_MSRS_REPORT_VERSION;
  	p_LOGGER.EXCHANGE_NAME := v_PARAMS(MEX_PJM.c_Report);
  	MEX_PJM.RUN_PJM_BROWSERLESS( v_PARAMS,
  								'msrs', -- p_REQUEST_APP
			   					p_LOGGER,
								p_CRED,
								p_BEGIN_DATE,
								p_END_DATE,
                    			'download',  -- p_REQUEST_DIR
                    		    v_RESP,
								p_STATUS,
								p_MESSAGE, p_LOG_ONLY );
	IF p_STATUS = Mex_Switchboard.c_Status_Success THEN
		PARSE_FTR_TARGET_CREDITS(v_RESP,p_WORK_ID,p_STATUS,p_MESSAGE);
	END IF;
	IF NOT v_RESP IS NULL THEN
	    DBMS_LOB.FREETEMPORARY(v_RESP);
	END IF;
END FETCH_FTR_TARGET_CREDITS;
----------------------------------------------------------------------------------------------------
PROCEDURE FETCH_FTR_AUCTION
    (
    p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_LOGGER   IN  OUT MM_LOGGER_ADAPTER,
    p_CRED	   IN	 MEX_CREDENTIALS,
	p_LOG_ONLY   IN  NUMBER,
	p_RECORDS OUT MEX_PJM_FTR_AUCTION_TBL_MSRS,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) AS
v_RESP CLOB := NULL;
v_PARAMS MEX_Util.Parameter_Map := Mex_Switchboard.c_Empty_Parameter_Map;
BEGIN
    v_PARAMS(MEX_PJM.c_Format) := 'c';
  	v_PARAMS(MEX_PJM.c_DEBUG) := g_DEBUG_EXCHANGES;
    v_PARAMS(MEX_PJM.c_Report) := g_ET_FTR_AUCTION_SUMMARY;
    v_PARAMS(MEX_PJM.c_Version) := g_MSRS_REPORT_VERSION;
  	p_LOGGER.EXCHANGE_NAME := v_PARAMS(MEX_PJM.c_Report);
  	MEX_PJM.RUN_PJM_BROWSERLESS( v_PARAMS,
  								'msrs', -- p_REQUEST_APP
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
PROCEDURE FETCH_BLACK_START_SUMMARY
    (
    p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_LOGGER   IN  OUT MM_LOGGER_ADAPTER,
    p_CRED	   IN	 MEX_CREDENTIALS,
	p_LOG_ONLY   IN  NUMBER,
	p_RECORDS OUT MEX_PJM_BLACKSTART_SUMMARY_TBL,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) AS
v_RESP CLOB := NULL;
v_PARAMS MEX_Util.Parameter_Map := Mex_Switchboard.c_Empty_Parameter_Map;
BEGIN
    v_PARAMS(MEX_PJM.c_Format) := 'c';
  	v_PARAMS(MEX_PJM.c_DEBUG) := g_DEBUG_EXCHANGES;
    v_PARAMS(MEX_PJM.c_Report) := g_ET_BLACK_START_SUMMARY;
    v_PARAMS(MEX_PJM.c_Version) := g_MSRS_REPORT_VERSION;
  	p_LOGGER.EXCHANGE_NAME := v_PARAMS(MEX_PJM.c_Report);
  	MEX_PJM.RUN_PJM_BROWSERLESS( v_PARAMS,
  								'msrs', -- p_REQUEST_APP
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
PROCEDURE FETCH_EDC_INADVERT_ALLOC_SUMM
    (
    p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_LOGGER   IN  OUT MM_LOGGER_ADAPTER,
    p_CRED	   IN	 MEX_CREDENTIALS,
	p_LOG_ONLY   IN  NUMBER,
	p_RECORDS OUT MEX_PJM_INADVRT_ALLOC_TBL_MSRS,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) AS
v_RESP CLOB := NULL;
v_PARAMS MEX_Util.Parameter_Map := Mex_Switchboard.c_Empty_Parameter_Map;
BEGIN
    v_PARAMS(MEX_PJM.c_Format) := 'c';
  	v_PARAMS(MEX_PJM.c_DEBUG) := g_DEBUG_EXCHANGES;
    v_PARAMS(MEX_PJM.c_Report) := g_ET_EDC_INADVERT_ALLOC;
    v_PARAMS(MEX_PJM.c_Version) := g_MSRS_REPORT_VERSION;
  	p_LOGGER.EXCHANGE_NAME := v_PARAMS(MEX_PJM.c_Report);
  	MEX_PJM.RUN_PJM_BROWSERLESS( v_PARAMS,
  								'msrs', -- p_REQUEST_APP
			   					p_LOGGER,
								p_CRED,
								p_BEGIN_DATE,
								p_END_DATE,
                    			'download',  -- p_REQUEST_DIR
                    		    v_RESP,
								p_STATUS,
								p_MESSAGE, p_LOG_ONLY );
	IF p_STATUS = Mex_Switchboard.c_Status_Success THEN
		PARSE_EDC_INADVERT_ALLOC_SUMM(v_RESP, p_RECORDS, p_STATUS, p_MESSAGE);
	END IF;
	IF NOT v_RESP IS NULL THEN
		DBMS_LOB.FREETEMPORARY(v_RESP);
	END IF;
END FETCH_EDC_INADVERT_ALLOC_SUMM;
----------------------------------------------------------------------------------------------------
PROCEDURE FETCH_METER_CORRECT_CHG_SUMM
   (
    p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_LOGGER   IN  OUT MM_LOGGER_ADAPTER,
    p_CRED	   IN	 MEX_CREDENTIALS,
	p_LOG_ONLY   IN  NUMBER,
	p_RECORDS OUT MEX_PJM_MTR_CORRCT_SUM_TABLE,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) AS
v_RESP CLOB := NULL;
v_PARAMS MEX_Util.Parameter_Map := Mex_Switchboard.c_Empty_Parameter_Map;
BEGIN
    v_PARAMS(MEX_PJM.c_Format) := 'c';
  	v_PARAMS(MEX_PJM.c_DEBUG) := g_DEBUG_EXCHANGES;
    v_PARAMS(MEX_PJM.c_Report) := g_ET_METER_CORRECTION_SUMMARY;
    v_PARAMS(MEX_PJM.c_Version) := g_MSRS_REPORT_VERSION;
  	p_LOGGER.EXCHANGE_NAME := v_PARAMS(MEX_PJM.c_Report);
  	MEX_PJM.RUN_PJM_BROWSERLESS( v_PARAMS,
  								'msrs', -- p_REQUEST_APP
			   					p_LOGGER,
								p_CRED,
								p_BEGIN_DATE,
								p_END_DATE,
                    			'download',  -- p_REQUEST_DIR
                    		    v_RESP,
								p_STATUS,
								p_MESSAGE, p_LOG_ONLY );
	IF p_STATUS = Mex_Switchboard.c_Status_Success THEN
		PARSE_METER_CORRECT_CHG_SUMM(v_RESP, p_RECORDS, p_STATUS, p_MESSAGE);
	END IF;
	IF NOT v_RESP IS NULL THEN
		DBMS_LOB.FREETEMPORARY(v_RESP);
	END IF;
END FETCH_METER_CORRECT_CHG_SUMM;
----------------------------------------------------------------------------------------------------
PROCEDURE FETCH_LOAD_RESPONSE_SUMMARY
 (
    p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_LOGGER   IN  OUT MM_LOGGER_ADAPTER,
    p_CRED	   IN	 MEX_CREDENTIALS,
	p_LOG_ONLY   IN  NUMBER,
	p_RECORDS OUT MEX_PJM_LOAD_RESPONSE_SUMM_TBL,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) AS
v_RESP CLOB := NULL;
v_PARAMS MEX_Util.Parameter_Map := Mex_Switchboard.c_Empty_Parameter_Map;
BEGIN
    v_PARAMS(MEX_PJM.c_Format) := 'c';
  	v_PARAMS(MEX_PJM.c_DEBUG) := g_DEBUG_EXCHANGES;
    v_PARAMS(MEX_PJM.c_Report) := g_ET_LOAD_RESPONSE_SUMMARY;
    v_PARAMS(MEX_PJM.c_Version) := g_MSRS_REPORT_VERSION;
  	p_LOGGER.EXCHANGE_NAME := v_PARAMS(MEX_PJM.c_Report);
  	MEX_PJM.RUN_PJM_BROWSERLESS( v_PARAMS,
  								'msrs', -- p_REQUEST_APP
			   					p_LOGGER,
								p_CRED,
								p_BEGIN_DATE,
								p_END_DATE,
                    			'download',  -- p_REQUEST_DIR
                    		    v_RESP,
								p_STATUS,
								p_MESSAGE, p_LOG_ONLY );
	IF p_STATUS = Mex_Switchboard.c_Status_Success THEN
		PARSE_LOAD_RESPONSE_SUMMARY(v_RESP, p_RECORDS, p_STATUS, p_MESSAGE);
	END IF;
	IF NOT v_RESP IS NULL THEN
		DBMS_LOB.FREETEMPORARY(v_RESP);
	END IF;
END FETCH_LOAD_RESPONSE_SUMMARY;
----------------------------------------------------------------------------------------------------
PROCEDURE FETCH_METER_CORRECT_ALLOC_SUMM
 (
    p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_LOGGER   IN  OUT MM_LOGGER_ADAPTER,
    p_CRED	   IN	 MEX_CREDENTIALS,
	p_LOG_ONLY   IN  NUMBER,
	p_RECORDS OUT MEX_PJM_MTR_CORRCT_ALLOC_TABLE,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) AS
v_RESP CLOB := NULL;
v_PARAMS MEX_Util.Parameter_Map := Mex_Switchboard.c_Empty_Parameter_Map;
BEGIN
    v_PARAMS(MEX_PJM.c_Format) := 'c';
  	v_PARAMS(MEX_PJM.c_DEBUG) := g_DEBUG_EXCHANGES;
    v_PARAMS(MEX_PJM.c_Report) := g_ET_METER_CORRECT_ALLOC_SUMM;
    v_PARAMS(MEX_PJM.c_Version) := g_MSRS_REPORT_VERSION;
  	p_LOGGER.EXCHANGE_NAME := v_PARAMS(MEX_PJM.c_Report);
  	MEX_PJM.RUN_PJM_BROWSERLESS( v_PARAMS,
  								'msrs', -- p_REQUEST_APP
			   					p_LOGGER,
								p_CRED,
								p_BEGIN_DATE,
								p_END_DATE,
                    			'download',  -- p_REQUEST_DIR
                    		    v_RESP,
								p_STATUS,
								p_MESSAGE, p_LOG_ONLY );
	IF p_STATUS = Mex_Switchboard.c_Status_Success THEN
		PARSE_METER_CORRECT_ALLOC_SUMM(v_RESP, p_RECORDS, p_STATUS, p_MESSAGE);
	END IF;
	IF NOT v_RESP IS NULL THEN
		DBMS_LOB.FREETEMPORARY(v_RESP);
	END IF;
END FETCH_METER_CORRECT_ALLOC_SUMM;
----------------------------------------------------------------------------------------------------
PROCEDURE FETCH_ARR_SUMMARY
    (
    p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_LOGGER   IN  OUT MM_LOGGER_ADAPTER,
    p_CRED	   IN	 MEX_CREDENTIALS,
	p_LOG_ONLY   IN  NUMBER,
	p_RECORDS OUT MEX_PJM_ARR_SUMMARY_TBL_MSRS,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) AS
v_RESP CLOB := NULL;
v_PARAMS MEX_Util.Parameter_Map := Mex_Switchboard.c_Empty_Parameter_Map;
BEGIN
    v_PARAMS(MEX_PJM.c_Format) := 'c';
  	v_PARAMS(MEX_PJM.c_DEBUG) := g_DEBUG_EXCHANGES;
    v_PARAMS(MEX_PJM.c_Report) := g_ET_ARR_TARGET_CREDITS;
    v_PARAMS(MEX_PJM.c_Version) := g_MSRS_REPORT_VERSION;
  	p_LOGGER.EXCHANGE_NAME := v_PARAMS(MEX_PJM.c_Report);
  	MEX_PJM.RUN_PJM_BROWSERLESS( v_PARAMS,
  								'msrs', -- p_REQUEST_APP
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
PROCEDURE FETCH_INADV_INTERCHG_SUMMARY
	(
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
    v_PARAMS(MEX_PJM.c_Format) := 'c';
  	v_PARAMS(MEX_PJM.c_DEBUG) := g_DEBUG_EXCHANGES;
    v_PARAMS(MEX_PJM.c_Report) := g_ET_INADVERTENT_INTERCHANGE;
    v_PARAMS(MEX_PJM.c_Version) := g_MSRS_REPORT_VERSION;
  	p_LOGGER.EXCHANGE_NAME := v_PARAMS(MEX_PJM.c_Report);
  	MEX_PJM.RUN_PJM_BROWSERLESS( v_PARAMS,
  								'msrs', -- p_REQUEST_APP
			   					p_LOGGER,
								p_CRED,
								p_BEGIN_DATE,
								p_END_DATE,
                    			'download',  -- p_REQUEST_DIR
                    		    v_RESP,
								p_STATUS,
								p_MESSAGE, p_LOG_ONLY );
	IF p_STATUS = Mex_Switchboard.c_Status_Success THEN
		PARSE_INADV_INTERCHG_SUMMARY(v_RESP, p_STATUS, p_MESSAGE);
	END IF;
	IF NOT v_RESP IS NULL THEN
		DBMS_LOB.FREETEMPORARY(v_RESP);
	END IF;
END FETCH_INADV_INTERCHG_SUMMARY;
----------------------------------------------------------------------------------------------------
PROCEDURE FETCH_REACTIVE_SUMMARY
    (
    p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_LOGGER   IN  OUT MM_LOGGER_ADAPTER,
    p_CRED	   IN	 MEX_CREDENTIALS,
	p_LOG_ONLY   IN  NUMBER,
	p_RECORDS OUT MEX_PJM_REACTIVE_SUMMARY_TBL,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) AS
v_RESP CLOB := NULL;
v_PARAMS MEX_Util.Parameter_Map := Mex_Switchboard.c_Empty_Parameter_Map;
BEGIN
    v_PARAMS(MEX_PJM.c_Format) := 'c';
  	v_PARAMS(MEX_PJM.c_DEBUG) := g_DEBUG_EXCHANGES;
    v_PARAMS(MEX_PJM.c_Report) := g_ET_REACTIVE_CHARGE_SUMMARY;
    v_PARAMS(MEX_PJM.c_Version) := g_MSRS_REPORT_VERSION;
  	p_LOGGER.EXCHANGE_NAME := v_PARAMS(MEX_PJM.c_Report);
  	MEX_PJM.RUN_PJM_BROWSERLESS( v_PARAMS,
  								'msrs', -- p_REQUEST_APP
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
PROCEDURE FETCH_EN_IMB_CRE_SUMMARY
    (
    p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_LOGGER   IN  OUT MM_LOGGER_ADAPTER,
    p_CRED	   IN	 MEX_CREDENTIALS,
	p_LOG_ONLY   IN  NUMBER,
	p_RECORDS OUT MEX_PJM_EN_IMB_CR_SUM_TBL_MSRS,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) AS
v_RESP CLOB := NULL;
v_PARAMS MEX_Util.Parameter_Map := Mex_Switchboard.c_Empty_Parameter_Map;
BEGIN
    v_PARAMS(MEX_PJM.c_Format) := 'c';
  	v_PARAMS(MEX_PJM.c_DEBUG) := g_DEBUG_EXCHANGES;
    v_PARAMS(MEX_PJM.c_Report) := g_ET_ENERGY_IMBAL_CRED_ALLOC;
    v_PARAMS(MEX_PJM.c_Version) := g_MSRS_REPORT_VERSION;
  	p_LOGGER.EXCHANGE_NAME := v_PARAMS(MEX_PJM.c_Report);
  	MEX_PJM.RUN_PJM_BROWSERLESS( v_PARAMS,
  								'msrs', -- p_REQUEST_APP
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
PROCEDURE FETCH_RAMAPO_PAR_SUMMARY
    (
    p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_LOGGER   IN  OUT MM_LOGGER_ADAPTER,
    p_CRED	   IN	 MEX_CREDENTIALS,
	p_LOG_ONLY   IN  NUMBER,
	p_RECORDS OUT MEX_PJM_RAMAPO_PAR_SUMMARY_TBL,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) AS
v_RESP CLOB := NULL;
v_PARAMS MEX_Util.Parameter_Map := Mex_Switchboard.c_Empty_Parameter_Map;
BEGIN
    v_PARAMS(MEX_PJM.c_Format) := 'c';
  	v_PARAMS(MEX_PJM.c_DEBUG) := g_DEBUG_EXCHANGES;
    v_PARAMS(MEX_PJM.c_Report) := g_ET_RAMAPO_PAR_CHG_SUMMARY;
    v_PARAMS(MEX_PJM.c_Version) := g_MSRS_REPORT_VERSION;
  	p_LOGGER.EXCHANGE_NAME := v_PARAMS(MEX_PJM.c_Report);
  	MEX_PJM.RUN_PJM_BROWSERLESS( v_PARAMS,
  								'msrs', -- p_REQUEST_APP
			   					p_LOGGER,
								p_CRED,
								p_BEGIN_DATE,
								p_END_DATE,
                    			'download',  -- p_REQUEST_DIR
                    		    v_RESP,
								p_STATUS,
								p_MESSAGE, p_LOG_ONLY );
	IF p_STATUS = Mex_Switchboard.c_Status_Success THEN
		PARSE_RAMAPO_PAR_SUMMARY(v_RESP, p_RECORDS, p_STATUS, p_MESSAGE);
	END IF;
	IF NOT v_RESP IS NULL THEN
		DBMS_LOB.FREETEMPORARY(v_RESP);
	END IF;
END FETCH_RAMAPO_PAR_SUMMARY;
----------------------------------------------------------------------------------------------------
PROCEDURE FETCH_SYNC_RES_T1_CHG_SUMMARY
	(
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
    v_PARAMS(MEX_PJM.c_Format) := 'c';
  	v_PARAMS(MEX_PJM.c_DEBUG) := g_DEBUG_EXCHANGES;
    v_PARAMS(MEX_PJM.c_Report) := g_ET_SYNC_RESERVE_TIER1_CHARGE;
    v_PARAMS(MEX_PJM.c_Version) := g_MSRS_REPORT_VERSION;
  	p_LOGGER.EXCHANGE_NAME := v_PARAMS(MEX_PJM.c_Report);
  	MEX_PJM.RUN_PJM_BROWSERLESS( v_PARAMS,
  								'msrs', -- p_REQUEST_APP
			   					p_LOGGER,
								p_CRED,
								p_BEGIN_DATE,
								p_END_DATE,
                    			'download',  -- p_REQUEST_DIR
                    		    v_RESP,
								p_STATUS,
								p_MESSAGE, p_LOG_ONLY );
	IF p_STATUS = Mex_Switchboard.c_Status_Success THEN
		PARSE_SYNC_RES_T1_CHG_SUMMARY(v_RESP, p_STATUS, p_MESSAGE);
	END IF;
	IF NOT v_RESP IS NULL THEN
		DBMS_LOB.FREETEMPORARY(v_RESP);
	END IF;
END FETCH_SYNC_RES_T1_CHG_SUMMARY;
----------------------------------------------------------------------------------------------------
PROCEDURE FETCH_SYNC_RES_T2_CHG_SUMMARY
	(
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
    v_PARAMS(MEX_PJM.c_Format) := 'c';
  	v_PARAMS(MEX_PJM.c_DEBUG) := g_DEBUG_EXCHANGES;
    v_PARAMS(MEX_PJM.c_Report) := g_ET_SYNC_RESERVE_TIER2_CHARGE;
    v_PARAMS(MEX_PJM.c_Version) := g_MSRS_REPORT_VERSION;
  	p_LOGGER.EXCHANGE_NAME := v_PARAMS(MEX_PJM.c_Report);
  	MEX_PJM.RUN_PJM_BROWSERLESS( v_PARAMS,
  								'msrs', -- p_REQUEST_APP
			   					p_LOGGER,
								p_CRED,
								p_BEGIN_DATE,
								p_END_DATE,
                    			'download',  -- p_REQUEST_DIR
                    		    v_RESP,
								p_STATUS,
								p_MESSAGE, p_LOG_ONLY );
	IF p_STATUS = Mex_Switchboard.c_Status_Success THEN
		PARSE_SYNC_RES_T2_CHG_SUMMARY(v_RESP, p_STATUS, p_MESSAGE);
	END IF;
	IF NOT v_RESP IS NULL THEN
		DBMS_LOB.FREETEMPORARY(v_RESP);
	END IF;
END FETCH_SYNC_RES_T2_CHG_SUMMARY;
----------------------------------------------------------------------------------------------------
PROCEDURE FETCH_SYNC_RES_OBL
	(
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
    v_PARAMS(MEX_PJM.c_Format) := 'c';
  	v_PARAMS(MEX_PJM.c_DEBUG) := g_DEBUG_EXCHANGES;
    v_PARAMS(MEX_PJM.c_Report) := g_ET_SYNC_RESERVE_OBLIG_DETAIL;
    v_PARAMS(MEX_PJM.c_Version) := g_MSRS_REPORT_VERSION;
  	p_LOGGER.EXCHANGE_NAME := v_PARAMS(MEX_PJM.c_Report);
  	MEX_PJM.RUN_PJM_BROWSERLESS( v_PARAMS,
  								'msrs', -- p_REQUEST_APP
			   					p_LOGGER,
								p_CRED,
								p_BEGIN_DATE,
								p_END_DATE,
                    			'download',  -- p_REQUEST_DIR
                    		    v_RESP,
								p_STATUS,
								p_MESSAGE, p_LOG_ONLY );
	IF p_STATUS = Mex_Switchboard.c_Status_Success THEN
		PARSE_SYNC_RES_OBL(v_RESP, p_STATUS, p_MESSAGE);
	END IF;
	IF NOT v_RESP IS NULL THEN
		DBMS_LOB.FREETEMPORARY(v_RESP);
	END IF;
END FETCH_SYNC_RES_OBL;
----------------------------------------------------------------------------------------------------
PROCEDURE FETCH_EXPLICIT_CONGESTION
	(
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
    v_PARAMS(MEX_PJM.c_Format) := 'c';
  	v_PARAMS(MEX_PJM.c_DEBUG) := g_DEBUG_EXCHANGES;
    v_PARAMS(MEX_PJM.c_Report) := g_ET_EXPLICIT_CONGESTION_SUMM;
    v_PARAMS(MEX_PJM.c_Version) := g_MSRS_REPORT_VERSION;
  	p_LOGGER.EXCHANGE_NAME := v_PARAMS(MEX_PJM.c_Report);
  	MEX_PJM.RUN_PJM_BROWSERLESS( v_PARAMS,
  								'msrs', -- p_REQUEST_APP
			   					p_LOGGER,
								p_CRED,
								p_BEGIN_DATE,
								p_END_DATE,
                    			'download',  -- p_REQUEST_DIR
                    		    v_RESP,
								p_STATUS,
								p_MESSAGE, p_LOG_ONLY );
	IF p_STATUS = Mex_Switchboard.c_Status_Success THEN
        PARSE_EXPLICIT_CONGESTION(v_RESP, p_STATUS, p_MESSAGE);
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
	p_LOGGER   IN  OUT MM_LOGGER_ADAPTER,
    p_CRED	   IN	 MEX_CREDENTIALS,
	p_LOG_ONLY   IN  NUMBER,
	p_RECORDS OUT MEX_PJM_TRAN_SERV_CHG_TBL_MSRS,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) AS
v_RESP CLOB := NULL;
v_PARAMS MEX_Util.Parameter_Map := Mex_Switchboard.c_Empty_Parameter_Map;
BEGIN
    v_PARAMS(MEX_PJM.c_Format) := 'c';
  	v_PARAMS(MEX_PJM.c_DEBUG) := g_DEBUG_EXCHANGES;
    v_PARAMS(MEX_PJM.c_Report) := g_ET_FIRM_TRANSMISSION_SERVICE;
    v_PARAMS(MEX_PJM.c_Version) := g_MSRS_REPORT_VERSION;
  	p_LOGGER.EXCHANGE_NAME := v_PARAMS(MEX_PJM.c_Report);
  	MEX_PJM.RUN_PJM_BROWSERLESS( v_PARAMS,
  								'msrs', -- p_REQUEST_APP
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
	p_LOGGER   IN  OUT MM_LOGGER_ADAPTER,
    p_CRED	   IN	 MEX_CREDENTIALS,
	p_LOG_ONLY   IN  NUMBER,
	p_RECORDS OUT MEX_PJM_NFIRM_TRAN_CH_TBL_MSRS,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) AS
v_RESP CLOB := NULL;
v_PARAMS MEX_Util.Parameter_Map := Mex_Switchboard.c_Empty_Parameter_Map;
BEGIN
    v_PARAMS(MEX_PJM.c_Format) := 'c';
  	v_PARAMS(MEX_PJM.c_DEBUG) := g_DEBUG_EXCHANGES;
    v_PARAMS(MEX_PJM.c_Report) := g_ET_NONFIRM_TRANSMISSION_SERV;
    v_PARAMS(MEX_PJM.c_Version) := g_MSRS_REPORT_VERSION;
  	p_LOGGER.EXCHANGE_NAME := v_PARAMS(MEX_PJM.c_Report);
  	MEX_PJM.RUN_PJM_BROWSERLESS( v_PARAMS,
  								'msrs', -- p_REQUEST_APP
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
PROCEDURE FETCH_NON_FM_TRANS_SV_CREDITS
    (
    p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_LOGGER   IN  OUT MM_LOGGER_ADAPTER,
    p_CRED	   IN	 MEX_CREDENTIALS,
	p_LOG_ONLY   IN  NUMBER,
	p_RECORDS OUT MEX_PJM_NON_FIRM_TRAN_CRED_TBL,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) AS
v_RESP CLOB := NULL;
v_PARAMS MEX_Util.Parameter_Map := Mex_Switchboard.c_Empty_Parameter_Map;
BEGIN
    v_PARAMS(MEX_PJM.c_Format) := 'c';
  	v_PARAMS(MEX_PJM.c_DEBUG) := g_DEBUG_EXCHANGES;
    v_PARAMS(MEX_PJM.c_Report) := g_ET_NONFIRM_TRANS_SERV_CRED;
    v_PARAMS(MEX_PJM.c_Version) := g_MSRS_REPORT_VERSION;
  	p_LOGGER.EXCHANGE_NAME := v_PARAMS(MEX_PJM.c_Report);
  	MEX_PJM.RUN_PJM_BROWSERLESS( v_PARAMS,
  								'msrs', -- p_REQUEST_APP
			   					p_LOGGER,
								p_CRED,
								p_BEGIN_DATE,
								p_END_DATE,
                    			'download',  -- p_REQUEST_DIR
                    		    v_RESP,
								p_STATUS,
								p_MESSAGE, p_LOG_ONLY );
	IF p_STATUS = Mex_Switchboard.c_Status_Success THEN
		PARSE_NON_FM_TRANS_SV_CREDITS(v_RESP,p_RECORDS,p_STATUS,p_MESSAGE);
	END IF;
	IF NOT v_RESP IS NULL THEN
	    DBMS_LOB.FREETEMPORARY(v_RESP);
	END IF;
END FETCH_NON_FM_TRANS_SV_CREDITS;
----------------------------------------------------------------------------------------------------
PROCEDURE FETCH_SCHED_9_10_RECON
    (
    p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_LOGGER   IN  OUT MM_LOGGER_ADAPTER,
    p_CRED	   IN	 MEX_CREDENTIALS,
	p_LOG_ONLY   IN  NUMBER,
	p_RECORDS OUT MEX_PJM_SCHED_9_10_RECON_TBL,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) AS
v_RESP CLOB := NULL;
v_PARAMS MEX_Util.Parameter_Map := Mex_Switchboard.c_Empty_Parameter_Map;
BEGIN
    v_PARAMS(MEX_PJM.c_Format) := 'c';
  	v_PARAMS(MEX_PJM.c_DEBUG) := g_DEBUG_EXCHANGES;
    v_PARAMS(MEX_PJM.c_Report) := g_ET_SCHED_9_10_LOAD_RECON;
    v_PARAMS(MEX_PJM.c_Version) := g_MSRS_REPORT_VERSION;
  	p_LOGGER.EXCHANGE_NAME := v_PARAMS(MEX_PJM.c_Report);
  	MEX_PJM.RUN_PJM_BROWSERLESS( v_PARAMS,
  								'msrs', -- p_REQUEST_APP
			   					p_LOGGER,
								p_CRED,
								p_BEGIN_DATE,
								p_END_DATE,
                    			'download',  -- p_REQUEST_DIR
                    		    v_RESP,
								p_STATUS,
								p_MESSAGE, p_LOG_ONLY );
	IF p_STATUS = Mex_Switchboard.c_Status_Success THEN
		PARSE_SCHED_9_10_RECON(v_RESP,p_RECORDS,p_STATUS,p_MESSAGE);
	END IF;
	IF NOT v_RESP IS NULL THEN
	    DBMS_LOB.FREETEMPORARY(v_RESP);
	END IF;
END FETCH_SCHED_9_10_RECON;
----------------------------------------------------------------------------------------------------
PROCEDURE FETCH_SCHEDULE1A_RECONCILE
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
    v_PARAMS(MEX_PJM.c_Format) := 'c';
  	v_PARAMS(MEX_PJM.c_DEBUG) := g_DEBUG_EXCHANGES;
    v_PARAMS(MEX_PJM.c_Report) := g_ET_SCHED_1A_LOAD_RECON;
    v_PARAMS(MEX_PJM.c_Version) := g_MSRS_REPORT_VERSION;
  	p_LOGGER.EXCHANGE_NAME := v_PARAMS(MEX_PJM.c_Report);
  	MEX_PJM.RUN_PJM_BROWSERLESS( v_PARAMS,
  								'msrs', -- p_REQUEST_APP
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
	p_LOGGER   IN  OUT MM_LOGGER_ADAPTER,
    p_CRED	   IN	 MEX_CREDENTIALS,
	p_LOG_ONLY   IN  NUMBER,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) AS
v_RESP CLOB := NULL;
v_PARAMS MEX_Util.Parameter_Map := Mex_Switchboard.c_Empty_Parameter_Map;
BEGIN
    v_PARAMS(MEX_PJM.c_Format) := 'c';
  	v_PARAMS(MEX_PJM.c_DEBUG) := g_DEBUG_EXCHANGES;
    v_PARAMS(MEX_PJM.c_Report) := g_ET_ENERGY_INADVERT_LD_RECON;
    v_PARAMS(MEX_PJM.c_Version) := g_MSRS_REPORT_VERSION;
  	p_LOGGER.EXCHANGE_NAME := v_PARAMS(MEX_PJM.c_Report);
  	MEX_PJM.RUN_PJM_BROWSERLESS( v_PARAMS,
  								'msrs', -- p_REQUEST_APP
			   					p_LOGGER,
								p_CRED,
								p_BEGIN_DATE,
								p_END_DATE,
                    			'download',  -- p_REQUEST_DIR
                    		    v_RESP,
								p_STATUS,
								p_MESSAGE, p_LOG_ONLY );
	IF p_STATUS = Mex_Switchboard.c_Status_Success THEN
		PARSE_ENERGY_CHARGES_RECONCIL(v_RESP,p_STATUS,p_MESSAGE);
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
	p_LOGGER   IN  OUT MM_LOGGER_ADAPTER,
    p_CRED	   IN	 MEX_CREDENTIALS,
	p_LOG_ONLY   IN  NUMBER,
	p_RECORDS OUT MEX_PJM_RECON_CHRGS_MSRS_TBL,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) AS
v_RESP CLOB := NULL;
v_PARAMS MEX_Util.Parameter_Map := Mex_Switchboard.c_Empty_Parameter_Map;
BEGIN
    v_PARAMS(MEX_PJM.c_Format) := 'c';
  	v_PARAMS(MEX_PJM.c_DEBUG) := g_DEBUG_EXCHANGES;
    v_PARAMS(MEX_PJM.c_Report) := g_ET_REGULATION_LOAD_RECON;
    v_PARAMS(MEX_PJM.c_Version) := g_MSRS_REPORT_VERSION;
  	p_LOGGER.EXCHANGE_NAME := v_PARAMS(MEX_PJM.c_Report);
  	MEX_PJM.RUN_PJM_BROWSERLESS( v_PARAMS,
  								'msrs', -- p_REQUEST_APP
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
PROCEDURE FETCH_SYNC_CONDENSE_RECONCIL
    (
    p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_LOGGER   IN  OUT MM_LOGGER_ADAPTER,
    p_CRED	   IN	 MEX_CREDENTIALS,
	p_LOG_ONLY   IN  NUMBER,
	p_RECORDS OUT MEX_PJM_RECON_CHRGS_MSRS_TBL,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) AS
v_RESP CLOB := NULL;
v_PARAMS MEX_Util.Parameter_Map := Mex_Switchboard.c_Empty_Parameter_Map;
BEGIN
    v_PARAMS(MEX_PJM.c_Format) := 'c';
  	v_PARAMS(MEX_PJM.c_DEBUG) := g_DEBUG_EXCHANGES;
    v_PARAMS(MEX_PJM.c_Report) := g_ET_SYNCH_CONDENS_LOAD_RECON;
    v_PARAMS(MEX_PJM.c_Version) := g_MSRS_REPORT_VERSION;
  	p_LOGGER.EXCHANGE_NAME := v_PARAMS(MEX_PJM.c_Report);
  	MEX_PJM.RUN_PJM_BROWSERLESS( v_PARAMS,
  								'msrs', -- p_REQUEST_APP
			   					p_LOGGER,
								p_CRED,
								p_BEGIN_DATE,
								p_END_DATE,
                    			'download',  -- p_REQUEST_DIR
                    		    v_RESP,
								p_STATUS,
								p_MESSAGE, p_LOG_ONLY );
	IF p_STATUS = Mex_Switchboard.c_Status_Success THEN
		PARSE_SYNC_CONDENSE_RECONCIL(v_RESP,p_RECORDS,p_STATUS,p_MESSAGE);
	END IF;
	IF NOT v_RESP IS NULL THEN
	    DBMS_LOB.FREETEMPORARY(v_RESP);
	END IF;
END FETCH_SYNC_CONDENSE_RECONCIL;
----------------------------------------------------------------------------------------------------
PROCEDURE FETCH_REACT_SERVICES_RECONCIL
    (
    p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_LOGGER   IN  OUT MM_LOGGER_ADAPTER,
    p_CRED	   IN	 MEX_CREDENTIALS,
	p_LOG_ONLY   IN  NUMBER,
	p_RECORDS OUT MEX_PJM_RECON_CHRGS_MSRS_TBL,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) AS
v_RESP CLOB := NULL;
v_PARAMS MEX_Util.Parameter_Map := Mex_Switchboard.c_Empty_Parameter_Map;
BEGIN
    v_PARAMS(MEX_PJM.c_Format) := 'c';
  	v_PARAMS(MEX_PJM.c_DEBUG) := g_DEBUG_EXCHANGES;
    v_PARAMS(MEX_PJM.c_Report) := g_ET_REACTIVE_SERV_LOAD_RECON;
    v_PARAMS(MEX_PJM.c_Version) := g_MSRS_REPORT_VERSION;
  	p_LOGGER.EXCHANGE_NAME := v_PARAMS(MEX_PJM.c_Report);
  	MEX_PJM.RUN_PJM_BROWSERLESS(v_PARAMS,
  								'msrs', -- p_REQUEST_APP
			   					p_LOGGER,
								p_CRED,
								p_BEGIN_DATE,
								p_END_DATE,
                    			'download',  -- p_REQUEST_DIR
                    		    v_RESP,
								p_STATUS,
								p_MESSAGE, p_LOG_ONLY );
	IF p_STATUS = Mex_Switchboard.c_Status_Success THEN
		PARSE_REACT_SERVICES_RECONCIL(v_RESP,p_RECORDS,p_STATUS,p_MESSAGE);
	END IF;
	IF NOT v_RESP IS NULL THEN
	    DBMS_LOB.FREETEMPORARY(v_RESP);
	END IF;
END FETCH_REACT_SERVICES_RECONCIL;
----------------------------------------------------------------------------------------------------
PROCEDURE FETCH_SYNC_RES_CH_RECONCIL
    (
    p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_LOGGER   IN  OUT MM_LOGGER_ADAPTER,
    p_CRED	   IN	 MEX_CREDENTIALS,
	p_LOG_ONLY   IN  NUMBER,
	p_RECORDS OUT MEX_PJM_RECON_CHRGS_MSRS_TBL,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) AS
v_RESP CLOB := NULL;
v_PARAMS MEX_Util.Parameter_Map := Mex_Switchboard.c_Empty_Parameter_Map;
BEGIN
    v_PARAMS(MEX_PJM.c_Format) := 'c';
  	v_PARAMS(MEX_PJM.c_DEBUG) := g_DEBUG_EXCHANGES;
    v_PARAMS(MEX_PJM.c_Report) := g_ET_SYNCH_RESERVE_LOAD_RECON;
    v_PARAMS(MEX_PJM.c_Version) := g_MSRS_REPORT_VERSION;
  	p_LOGGER.EXCHANGE_NAME := v_PARAMS(MEX_PJM.c_Report);
  	MEX_PJM.RUN_PJM_BROWSERLESS( v_PARAMS,
  								'msrs', -- p_REQUEST_APP
			   					p_LOGGER,
								p_CRED,
								p_BEGIN_DATE,
								p_END_DATE,
                    			'download',  -- p_REQUEST_DIR
                    		    v_RESP,
								p_STATUS,
								p_MESSAGE, p_LOG_ONLY );
	IF p_STATUS = Mex_Switchboard.c_Status_Success THEN
		PARSE_SYNC_RES_CH_RECONCIL(v_RESP,p_RECORDS,p_STATUS,p_MESSAGE);
	END IF;
	IF NOT v_RESP IS NULL THEN
	    DBMS_LOB.FREETEMPORARY(v_RESP);
	END IF;
END FETCH_SYNC_RES_CH_RECONCIL;
----------------------------------------------------------------------------------------------------
PROCEDURE FETCH_TRANS_LOSS_CR_RECONCIL
    (
    p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_LOGGER   IN  OUT MM_LOGGER_ADAPTER,
    p_CRED	   IN	 MEX_CREDENTIALS,
	p_LOG_ONLY   IN  NUMBER,
	p_RECORDS OUT MEX_PJM_RECON_CHRGS_MSRS_TBL,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) AS
v_RESP CLOB := NULL;
v_PARAMS MEX_Util.Parameter_Map := Mex_Switchboard.c_Empty_Parameter_Map;
BEGIN
    v_PARAMS(MEX_PJM.c_Format) := 'c';
  	v_PARAMS(MEX_PJM.c_DEBUG) := g_DEBUG_EXCHANGES;
    v_PARAMS(MEX_PJM.c_Report) := g_ET_TRANS_LOSS_CREDIT_RECON;
    v_PARAMS(MEX_PJM.c_Version) := g_MSRS_REPORT_VERSION;
  	p_LOGGER.EXCHANGE_NAME := v_PARAMS(MEX_PJM.c_Report);
  	MEX_PJM.RUN_PJM_BROWSERLESS( v_PARAMS,
  								'msrs', -- p_REQUEST_APP
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
----------------------------------------------------------------------------------------------------
PROCEDURE FETCH_HR_TRANS_CONG_CR
	(
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
    v_PARAMS(MEX_PJM.c_Format) := 'c';
  	v_PARAMS(MEX_PJM.c_DEBUG) := g_DEBUG_EXCHANGES;
    v_PARAMS(MEX_PJM.c_Report) := g_ET_HR_TRANSMISSION_CONG_CRED;
    v_PARAMS(MEX_PJM.c_Version) := g_MSRS_REPORT_VERSION;
  	p_LOGGER.EXCHANGE_NAME := v_PARAMS(MEX_PJM.c_Report);
  	MEX_PJM.RUN_PJM_BROWSERLESS( v_PARAMS,
  								'msrs', -- p_REQUEST_APP
			   					p_LOGGER,
								p_CRED,
								p_BEGIN_DATE,
								p_END_DATE,
                    			'download',  -- p_REQUEST_DIR
                    		    v_RESP,
								p_STATUS,
								p_MESSAGE, p_LOG_ONLY );
	IF p_STATUS = Mex_Switchboard.c_Status_Success THEN        PARSE_HR_TRANS_CONG_CR(v_RESP, p_STATUS, p_MESSAGE);
    END IF;

    IF NOT v_RESP IS NULL THEN
        DBMS_LOB.FREETEMPORARY(v_RESP);
    END IF;

END FETCH_HR_TRANS_CONG_CR;
--g_ET_HR_TRANSMISSION_CONG_CRED
----------------------------------------------------------------------------------------------------
PROCEDURE FETCH_IMPL_CONG_LOSS_CH
	(
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
    v_PARAMS(MEX_PJM.c_Format) := 'c';
  	v_PARAMS(MEX_PJM.c_DEBUG) := g_DEBUG_EXCHANGES;
    v_PARAMS(MEX_PJM.c_Report) := g_ET_IMPLICIT_CONG_AND_LOSS;
    v_PARAMS(MEX_PJM.c_Version) := g_MSRS_REPORT_VERSION;
  	p_LOGGER.EXCHANGE_NAME := v_PARAMS(MEX_PJM.c_Report);
  	MEX_PJM.RUN_PJM_BROWSERLESS( v_PARAMS,
  								'msrs', -- p_REQUEST_APP
			   					p_LOGGER,
								p_CRED,
								p_BEGIN_DATE,
								p_END_DATE,
                    			'download',  -- p_REQUEST_DIR
                    		    v_RESP,
								p_STATUS,
								p_MESSAGE, p_LOG_ONLY );
	IF p_STATUS = Mex_Switchboard.c_Status_Success THEN
        PARSE_IMPL_CONG_LOSS_CH(v_RESP, p_STATUS, p_MESSAGE);
    END IF;

    IF NOT v_RESP IS NULL THEN
        DBMS_LOB.FREETEMPORARY(v_RESP);
    END IF;

END FETCH_IMPL_CONG_LOSS_CH;
----------------------------------------------------------------------------------------------------
PROCEDURE FETCH_TRANS_LOSS_CHARGE
	(
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
    v_PARAMS(MEX_PJM.c_Format) := 'c';
  	v_PARAMS(MEX_PJM.c_DEBUG) := g_DEBUG_EXCHANGES;
    v_PARAMS(MEX_PJM.c_Report) := g_ET_TRANSMISSION_LOSS_CHARGES;
    v_PARAMS(MEX_PJM.c_Version) := g_MSRS_REPORT_VERSION;
  	p_LOGGER.EXCHANGE_NAME := v_PARAMS(MEX_PJM.c_Report);
  	MEX_PJM.RUN_PJM_BROWSERLESS( v_PARAMS,
  								'msrs', -- p_REQUEST_APP
			   					p_LOGGER,
								p_CRED,
								p_BEGIN_DATE,
								p_END_DATE,
                    			'download',  -- p_REQUEST_DIR
                    		    v_RESP,
								p_STATUS,
								p_MESSAGE, p_LOG_ONLY );
	IF p_STATUS = Mex_Switchboard.c_Status_Success THEN
        PARSE_TRANS_LOSS_CHARGE(v_RESP, p_STATUS, p_MESSAGE);
    END IF;
    IF NOT v_RESP IS NULL THEN
        DBMS_LOB.FREETEMPORARY(v_RESP);
    END IF;
END FETCH_TRANS_LOSS_CHARGE;
-------------------------------------------------------------------------------------------------------
PROCEDURE FETCH_TRANS_LOSS_CREDIT
	(
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
    v_PARAMS(MEX_PJM.c_Format) := 'c';
  	v_PARAMS(MEX_PJM.c_DEBUG) := g_DEBUG_EXCHANGES;
    v_PARAMS(MEX_PJM.c_Report) := g_ET_TRANSMISSION_LOSS_CREDITS;
    v_PARAMS(MEX_PJM.c_Version) := g_MSRS_REPORT_VERSION;
  	p_LOGGER.EXCHANGE_NAME := v_PARAMS(MEX_PJM.c_Report);
  	MEX_PJM.RUN_PJM_BROWSERLESS( v_PARAMS,
  								'msrs', -- p_REQUEST_APP
			   					p_LOGGER,
								p_CRED,
								p_BEGIN_DATE,
								p_END_DATE,
                    			'download',  -- p_REQUEST_DIR
                    		    v_RESP,
								p_STATUS,
								p_MESSAGE, p_LOG_ONLY );
	IF p_STATUS = Mex_Switchboard.c_Status_Success THEN
        PARSE_TRANS_LOSS_CREDIT(v_RESP, p_STATUS, p_MESSAGE);
    END IF;
    IF NOT v_RESP IS NULL THEN
        DBMS_LOB.FREETEMPORARY(v_RESP);
    END IF;
END FETCH_TRANS_LOSS_CREDIT;
-------------------------------------------------------------------------------------------------------
PROCEDURE FETCH_EXPLICIT_LOSS
	(
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
    v_PARAMS(MEX_PJM.c_Format) := 'c';
  	v_PARAMS(MEX_PJM.c_DEBUG) := g_DEBUG_EXCHANGES;
    v_PARAMS(MEX_PJM.c_Report) := g_ET_EXPLICIT_LOSS_CHARGES;
    v_PARAMS(MEX_PJM.c_Version) := g_MSRS_REPORT_VERSION;
  	p_LOGGER.EXCHANGE_NAME := v_PARAMS(MEX_PJM.c_Report);
  	MEX_PJM.RUN_PJM_BROWSERLESS( v_PARAMS,
  								'msrs', -- p_REQUEST_APP
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
PROCEDURE FETCH_MONTH_TO_DATE_BILL
    (
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_LOGGER   IN  OUT MM_LOGGER_ADAPTER,
    p_CRED	   IN	 MEX_CREDENTIALS,
	p_LOG_ONLY   IN  NUMBER,
	p_RECORDS OUT MEX_PJM_MONTH_TO_DATE_BILL_TBL,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) AS

v_RESP CLOB := NULL;
v_PARAMS MEX_Util.Parameter_Map := Mex_Switchboard.c_Empty_Parameter_Map;
BEGIN
    v_PARAMS(MEX_PJM.c_Format) := 'c';
  	v_PARAMS(MEX_PJM.c_DEBUG) := g_DEBUG_EXCHANGES;
    v_PARAMS(MEX_PJM.c_Report) := g_ET_MONTH_TO_DATE_BILL;
    v_PARAMS(MEX_PJM.c_Version) := g_MSRS_REPORT_VERSION;
  	p_LOGGER.EXCHANGE_NAME := v_PARAMS(MEX_PJM.c_Report);
  	MEX_PJM.RUN_PJM_BROWSERLESS( v_PARAMS,
  								'msrs', -- p_REQUEST_APP
			   					p_LOGGER,
								p_CRED,
								p_BEGIN_DATE,
								p_END_DATE,
                    			'download',  -- p_REQUEST_DIR
                    		    v_RESP,
								p_STATUS,
								p_MESSAGE, p_LOG_ONLY );
	IF p_STATUS = Mex_Switchboard.c_Status_Success THEN
		PARSE_MONTH_TO_DATE_BILL(v_RESP, p_RECORDS, p_STATUS, p_MESSAGE);
	END IF;
	IF NOT v_RESP IS NULL THEN
		DBMS_LOB.FREETEMPORARY(v_RESP);
	END IF;
END FETCH_MONTH_TO_DATE_BILL;
-----------------------------------------------------------------------------------------
PROCEDURE FETCH_LOC_RELIABILITY_SUMMARY
    (
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_LOGGER   IN  OUT MM_LOGGER_ADAPTER,
    p_CRED	   IN	 MEX_CREDENTIALS,
	p_LOG_ONLY   IN  NUMBER,
	p_RECORDS OUT MEX_PJM_RECONCIL_CHARGES_TBL,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) AS

v_RESP CLOB := NULL;
v_PARAMS MEX_Util.Parameter_Map := Mex_Switchboard.c_Empty_Parameter_Map;
BEGIN
    v_PARAMS(MEX_PJM.c_Format) := 'c';
  	v_PARAMS(MEX_PJM.c_DEBUG) := g_DEBUG_EXCHANGES;
    v_PARAMS(MEX_PJM.c_Report) := g_ET_LOC_RELIABILITY_SUMM;
    v_PARAMS(MEX_PJM.c_Version) := g_MSRS_REPORT_VERSION;
  	p_LOGGER.EXCHANGE_NAME := v_PARAMS(MEX_PJM.c_Report);
  	MEX_PJM.RUN_PJM_BROWSERLESS( v_PARAMS,
  								'msrs', -- p_REQUEST_APP
			   					p_LOGGER,
								p_CRED,
								p_BEGIN_DATE,
								p_END_DATE,
                    			'download',  -- p_REQUEST_DIR
                    		    v_RESP,
								p_STATUS,
								p_MESSAGE, p_LOG_ONLY );
	IF p_STATUS = Mex_Switchboard.c_Status_Success THEN
		PARSE_LOC_RELIABILITY_SUMMARY(v_RESP, p_RECORDS, p_STATUS, p_MESSAGE);
	END IF;
	IF NOT v_RESP IS NULL THEN
		DBMS_LOB.FREETEMPORARY(v_RESP);
	END IF;
END FETCH_LOC_RELIABILITY_SUMMARY;
-----------------------------------------------------------------------------------------
PROCEDURE FETCH_RPM_AUCTION_SUMMARY
    (
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_LOGGER   IN  OUT MM_LOGGER_ADAPTER,
    p_CRED	   IN	 MEX_CREDENTIALS,
	p_LOG_ONLY   IN  NUMBER,
	p_RECORDS OUT MEX_PJM_RPM_AUCTION_TBL,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) AS

v_RESP CLOB := NULL;
v_PARAMS MEX_Util.Parameter_Map := Mex_Switchboard.c_Empty_Parameter_Map;
BEGIN
    v_PARAMS(MEX_PJM.c_Format) := 'c';
  	v_PARAMS(MEX_PJM.c_DEBUG) := g_DEBUG_EXCHANGES;
    v_PARAMS(MEX_PJM.c_Report) := g_ET_RPM_AUCTION_SUMMARY;
    v_PARAMS(MEX_PJM.c_Version) := g_MSRS_REPORT_VERSION;
  	p_LOGGER.EXCHANGE_NAME := v_PARAMS(MEX_PJM.c_Report);
  	MEX_PJM.RUN_PJM_BROWSERLESS( v_PARAMS,
  								'msrs', -- p_REQUEST_APP
			   					p_LOGGER,
								p_CRED,
								p_BEGIN_DATE,
								p_END_DATE,
                    			'download',  -- p_REQUEST_DIR
                    		    v_RESP,
								p_STATUS,
								p_MESSAGE, p_LOG_ONLY );
	IF p_STATUS = Mex_Switchboard.c_Status_Success THEN
		PARSE_RPM_AUCTION_SUMMARY(v_RESP, p_RECORDS, p_STATUS, p_MESSAGE);
	END IF;
	IF NOT v_RESP IS NULL THEN
		DBMS_LOB.FREETEMPORARY(v_RESP);
	END IF;
END FETCH_RPM_AUCTION_SUMMARY;
-----------------------------------------------------------------------------------------
PROCEDURE FETCH_CAP_TRANSFER_CREDITS
    (
    p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_LOGGER   IN  OUT MM_LOGGER_ADAPTER,
    p_CRED	   IN	 MEX_CREDENTIALS,
	p_LOG_ONLY   IN  NUMBER,
	p_RECORDS OUT MEX_PJM_CAP_TRANSFER_RIGHT_TBL,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
    ) AS

v_RESP CLOB := NULL ;
v_PARAMS MEX_Util.Parameter_Map := Mex_Switchboard.c_Empty_Parameter_Map;
BEGIN
    v_PARAMS(MEX_PJM.c_Format) := 'c';
  	v_PARAMS(MEX_PJM.c_DEBUG) := g_DEBUG_EXCHANGES;
    v_PARAMS(MEX_PJM.c_Report) := g_ET_CAP_TRANSFER_CREDITS;
    v_PARAMS(MEX_PJM.c_Version) := g_MSRS_REPORT_VERSION;
  	p_LOGGER.EXCHANGE_NAME := v_PARAMS(MEX_PJM.c_Report);
  	MEX_PJM.RUN_PJM_BROWSERLESS( v_PARAMS,
  								'msrs', -- p_REQUEST_APP
			   					p_LOGGER,
								p_CRED,
								p_BEGIN_DATE,
								p_END_DATE,
                    			'download',  -- p_REQUEST_DIR
                    		    v_RESP,
								p_STATUS,
								p_MESSAGE, p_LOG_ONLY );
	IF p_STATUS = Mex_Switchboard.c_Status_Success THEN
		PARSE_CAP_TRANSFER_CREDITS(v_RESP, p_RECORDS, p_STATUS, p_MESSAGE);
	END IF;
	IF NOT v_RESP IS NULL THEN
		DBMS_LOB.FREETEMPORARY(v_RESP);
	END IF;
END FETCH_CAP_TRANSFER_CREDITS;
-----------------------------------------------------------------------------------------
PROCEDURE FETCH_DEFICIENCY_CREDIT_SUMM
    (
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_LOGGER   IN  OUT MM_LOGGER_ADAPTER,
    p_CRED	   IN	 MEX_CREDENTIALS,
	p_LOG_ONLY   IN  NUMBER,
	p_RECORDS OUT MEX_PJM_DEFICIENCY_CR_SUMM_TBL,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) AS

v_RESP CLOB := NULL;
v_PARAMS MEX_Util.Parameter_Map := Mex_Switchboard.c_Empty_Parameter_Map;
BEGIN
    v_PARAMS(MEX_PJM.c_Format) := 'c';
  	v_PARAMS(MEX_PJM.c_DEBUG) := g_DEBUG_EXCHANGES;
    v_PARAMS(MEX_PJM.c_Report) := g_ET_DEFICIENCY_CREDIT_SUMMARY;
    v_PARAMS(MEX_PJM.c_Version) := g_MSRS_REPORT_VERSION;
  	p_LOGGER.EXCHANGE_NAME := v_PARAMS(MEX_PJM.c_Report);
  	MEX_PJM.RUN_PJM_BROWSERLESS( v_PARAMS,
  								'msrs', -- p_REQUEST_APP
			   					p_LOGGER,
								p_CRED,
								p_BEGIN_DATE,
								p_END_DATE,
                    			'download',  -- p_REQUEST_DIR
                    		    v_RESP,
								p_STATUS,
								p_MESSAGE, p_LOG_ONLY );
	IF p_STATUS = Mex_Switchboard.c_Status_Success THEN
		PARSE_DEFICIENCY_CREDIT_SUMM(v_RESP, p_RECORDS, p_STATUS, p_MESSAGE);
	END IF;
	IF NOT v_RESP IS NULL THEN
		DBMS_LOB.FREETEMPORARY(v_RESP);
	END IF;
END FETCH_DEFICIENCY_CREDIT_SUMM;
-----------------------------------------------------------------------------------------
PROCEDURE FETCH_OP_RES_FOR_LD_RESP
    (
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_LOGGER   IN  OUT MM_LOGGER_ADAPTER,
    p_CRED	   IN	 MEX_CREDENTIALS,
	p_LOG_ONLY   IN  NUMBER,
	p_RECORDS OUT MEX_PJM_OP_RES_FOR_LD_RESP_TBL,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) AS

v_RESP CLOB := NULL;
v_PARAMS MEX_Util.Parameter_Map := Mex_Switchboard.c_Empty_Parameter_Map;
BEGIN
    v_PARAMS(MEX_PJM.c_Format) := 'c';
  	v_PARAMS(MEX_PJM.c_DEBUG) := g_DEBUG_EXCHANGES;
    v_PARAMS(MEX_PJM.c_Report) := g_ET_OPRES_LOAD_RESP_CHARGE;
    v_PARAMS(MEX_PJM.c_Version) := g_MSRS_REPORT_VERSION;
  	p_LOGGER.EXCHANGE_NAME := v_PARAMS(MEX_PJM.c_Report);
  	MEX_PJM.RUN_PJM_BROWSERLESS( v_PARAMS,
  								'msrs', -- p_REQUEST_APP
			   					p_LOGGER,
								p_CRED,
								p_BEGIN_DATE,
								p_END_DATE,
                    			'download',  -- p_REQUEST_DIR
                    		    v_RESP,
								p_STATUS,
								p_MESSAGE, p_LOG_ONLY );
	IF p_STATUS = Mex_Switchboard.c_Status_Success THEN
		PARSE_OP_RES_FOR_LD_RESP(v_RESP, p_RECORDS, p_STATUS, p_MESSAGE);
	END IF;
	IF NOT v_RESP IS NULL THEN
		DBMS_LOB.FREETEMPORARY(v_RESP);
	END IF;
END FETCH_OP_RES_FOR_LD_RESP;
-----------------------------------------------------------------------------------------
PROCEDURE FETCH_GEN_CREDIT_PORTFOLIO
    (
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_LOGGER   IN  OUT MM_LOGGER_ADAPTER,
    p_CRED	   IN	 MEX_CREDENTIALS,
	p_LOG_ONLY   IN  NUMBER,
	p_RECORDS OUT MEX_PJM_GEN_PORTFO_CREDIT_TBL,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) AS

v_RESP CLOB := NULL;
v_PARAMS MEX_Util.Parameter_Map := Mex_Switchboard.c_Empty_Parameter_Map;
BEGIN
    v_PARAMS(MEX_PJM.c_Format) := 'c';
  	v_PARAMS(MEX_PJM.c_DEBUG) := g_DEBUG_EXCHANGES;
    v_PARAMS(MEX_PJM.c_Report) := g_ET_GENERATOR_CRED_PORTFOLIO;
    v_PARAMS(MEX_PJM.c_Version) := g_MSRS_REPORT_VERSION;
  	p_LOGGER.EXCHANGE_NAME := v_PARAMS(MEX_PJM.c_Report);
  	MEX_PJM.RUN_PJM_BROWSERLESS( v_PARAMS,
  								'msrs', -- p_REQUEST_APP
			   					p_LOGGER,
								p_CRED,
								p_BEGIN_DATE,
								p_END_DATE,
                    			'download',  -- p_REQUEST_DIR
                    		    v_RESP,
								p_STATUS,
								p_MESSAGE, p_LOG_ONLY );
	IF p_STATUS = Mex_Switchboard.c_Status_Success THEN
		PARSE_GEN_CREDIT_PORTFOLIO(v_RESP, p_RECORDS, p_STATUS, p_MESSAGE);
	END IF;
	IF NOT v_RESP IS NULL THEN
		DBMS_LOB.FREETEMPORARY(v_RESP);
	END IF;
END FETCH_GEN_CREDIT_PORTFOLIO;
------------------------------------------------------------------------------------------
BEGIN
	-- get the MSRS report version from system settings
	CASE UPPER(NVL(GET_DICTIONARY_VALUE('MSRS Report Version', 0, 'MarketExchange', 'PJM','?','?'), '?'))
	WHEN 'ORIGINAL' THEN
            g_MSRS_REPORT_VERSION := 'o';
	WHEN 'LATEST BILLED' THEN
        g_MSRS_REPORT_VERSION := 'b';
	ELSE
        --default to Latest Version (l)
        g_MSRS_REPORT_VERSION := 'l';
    END CASE;
END MEX_PJM_SETTLEMENT_MSRS;
/
