CREATE OR REPLACE PACKAGE BODY MM_PJM_SHADOW_BILL IS

	TYPE REF_CURSOR IS REF CURSOR;

	g_PJM_SC_ID sc.sc_id%TYPE;
	g_ON_PEAK_BEGIN NUMBER(2) := 7;
	g_ON_PEAK_END NUMBER(2) := 23;
    g_MARGINAL_LOSS_DATE DATE := DATE '2007-06-01';

---------------------------------------------------------------------------------------------------
FUNCTION WHAT_VERSION RETURN VARCHAR2 IS
BEGIN
    RETURN '$Revision: 1.1 $';
END WHAT_VERSION;
---------------------------------------------------------------------------------------------------
	/*******************************************************************************
    Returns the number of bid-offer pairs submitted during the month given.
    Called by the Market Support Charge charge component.
  *******************************************************************************/
FUNCTION GET_BID_OFFER_PAIRS(p_CONTRACT_ID IN NUMBER,
							 p_CUT_BEGIN_DATE IN DATE,
							 p_CUT_END_DATE IN DATE) RETURN NUMBER IS
	l_PAIRS_COUNT NUMBER;
BEGIN
	SELECT COUNT(BO_SET.SET_NUMBER)
	INTO l_PAIRS_COUNT
	FROM BID_OFFER_SET BO_SET
	WHERE BO_SET.SCHEDULE_DATE BETWEEN p_CUT_BEGIN_DATE AND p_CUT_END_DATE
	AND BO_SET.SCHEDULE_STATE = GA.INTERNAL_STATE
	AND BO_SET.TRANSACTION_ID IN
		  (SELECT TRANSACTION_ID
		   FROM INTERCHANGE_TRANSACTION
		   WHERE CONTRACT_ID = p_CONTRACT_ID
		   AND IS_BID_OFFER = 1
		   AND TRANSACTION_TYPE IN ('Generation', 'Load')
		   AND COMMODITY_ID IN
				 (SELECT COMMODITY_ID FROM IT_COMMODITY WHERE UPPER(COMMODITY_ALIAS) IN ('DA', 'VR')));

	RETURN NVL(l_PAIRS_COUNT, 0);
END GET_BID_OFFER_PAIRS;
--------------------------------------------------------------------------------------------------------------------
FUNCTION FOLLOWING_PJM_DISPATCH
    (
    p_DATE IN DATE,
    p_GEN_ID IN VARCHAR2,
    p_CONTRACT_ID IN NUMBER
    ) RETURN NUMBER IS
v_UNIT_TXN_ID NUMBER(9);
v_TRAIT_ID NUMBER(3) := MM_PJM_UTIL.g_TG_OUT_FOLLOW_PJM_DISPATCH;
v_TRAIT_VAL NUMBER(1) := 0;
BEGIN
    BEGIN
        SELECT P.TRANSACTION_ID INTO v_UNIT_TXN_ID
        FROM PJM_GEN_TXNS_BY_TYPE P
        WHERE P.PJM_Gen_Id = p_GEN_ID
        AND p.CONTRACT_ID = p_CONTRACT_ID
        AND P.PJM_GEN_TXN_TYPE = 'Unit Data';

        SELECT I.TRAIT_VAL INTO v_TRAIT_VAL
        FROM IT_TRAIT_SCHEDULE I
        WHERE I.SCHEDULE_DATE = p_DATE
        AND I.TRANSACTION_ID = v_UNIT_TXN_ID
        AND I.TRAIT_GROUP_ID = v_TRAIT_ID;

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            v_TRAIT_VAL := 0;
    END;

    RETURN NVL(v_TRAIT_VAL,0);

END FOLLOWING_PJM_DISPATCH;
-------------------------------------------------------------------------------------------------------------------
FUNCTION GET_DA_GEN_BEFORE_OWN_PERCENT
    (
    p_TXN_ID IN NUMBER,
    p_SCHED_DATE IN DATE
    ) RETURN NUMBER IS
v_DA_GEN NUMBER;
v_MKT_RESULT_TRAIT NUMBER := MM_PJM_UTIL.g_TG_OUT_ACTUAL_GEN_MKT_RESULT;
BEGIN
--assumption: unit data transaction_id passed in
    SELECT SUM(I.TRAIT_VAL) INTO v_DA_GEN
    FROM IT_TRAIT_SCHEDULE I
    WHERE I.TRANSACTION_ID = p_TXN_ID
    AND I.SCHEDULE_STATE = GA.INTERNAL_STATE
		AND I.TRAIT_GROUP_ID = v_MKT_RESULT_TRAIT
		AND I.SCHEDULE_DATE = p_SCHED_DATE;

    RETURN NVL(TO_NUMBER(v_DA_GEN),0);
EXCEPTION
	WHEN NO_DATA_FOUND THEN
		RETURN 0;
END GET_DA_GEN_BEFORE_OWN_PERCENT;
--------------------------------------------------------------------------------------------------------
FUNCTION USE_RT_SALES
    (
    p_CONTRACT IN NUMBER
    ) RETURN NUMBER IS
v_VAL BINARY_INTEGER;
BEGIN
    BEGIN
         SELECT T.ATTRIBUTE_VAL INTO v_VAL
        FROM TEMPORAL_ENTITY_ATTRIBUTE T
        WHERE T.ATTRIBUTE_ID =
            (SELECT E.ATTRIBUTE_ID
            FROM ENTITY_ATTRIBUTE E
            WHERE E.ATTRIBUTE_NAME = 'UseRTSales')
        AND T.OWNER_ENTITY_ID =
            (SELECT PSE_ID
            FROM PURCHASING_SELLING_ENTITY P, INTERCHANGE_CONTRACT I
            WHERE I.CONTRACT_ID = p_CONTRACT AND P.PSE_ID = I.BILLING_ENTITY_ID);
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            v_VAL := 0;
    END;

    RETURN NVL(v_VAL, 0);
END USE_RT_SALES;
--------------------------------------------------------------------------------------------------
FUNCTION GET_RECONCILIATION_LAG
    (
    p_CONTRACT IN NUMBER
    ) RETURN NUMBER IS
v_VAL BINARY_INTEGER;
BEGIN
    BEGIN
        SELECT T.ATTRIBUTE_VAL INTO v_VAL
        FROM TEMPORAL_ENTITY_ATTRIBUTE T
        WHERE T.ATTRIBUTE_ID = (SELECT E.ATTRIBUTE_ID FROM ENTITY_ATTRIBUTE E WHERE E.ATTRIBUTE_NAME = 'ReconciliationLag')
        AND T.OWNER_ENTITY_ID = (SELECT PSE_ID FROM PURCHASING_SELLING_ENTITY P, INTERCHANGE_CONTRACT I
        WHERE I.CONTRACT_ID = P_CONTRACT AND P.PSE_ID = I.BILLING_ENTITY_ID);
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            v_VAL := 0;
    END;

    RETURN NVL(v_VAL, 0);
END GET_RECONCILIATION_LAG;
--------------------------------------------------------------------------------------------------
FUNCTION GET_ZONE
    (
    p_CONTRACT IN NUMBER
    ) RETURN VARCHAR2 IS
v_VAL TEMPORAL_ENTITY_ATTRIBUTE.ATTRIBUTE_VAL%TYPE;
BEGIN
    BEGIN
        SELECT T.ATTRIBUTE_VAL INTO v_VAL
        FROM TEMPORAL_ENTITY_ATTRIBUTE T
        WHERE T.ATTRIBUTE_ID = (SELECT E.ATTRIBUTE_ID FROM ENTITY_ATTRIBUTE E WHERE E.ATTRIBUTE_NAME = 'Zone')
        AND T.OWNER_ENTITY_ID = (SELECT PSE_ID FROM PURCHASING_SELLING_ENTITY P, INTERCHANGE_CONTRACT I
        WHERE I.CONTRACT_ID = P_CONTRACT AND P.PSE_ID = I.BILLING_ENTITY_ID);
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            NULL;
    END;

    RETURN v_VAL;
END GET_ZONE;
--------------------------------------------------------------------------------------------------
FUNCTION IS_POOL_SCHEDULED
    (
    p_DATE IN DATE,
    p_GEN_ID IN VARCHAR2,
    p_CONTRACT_ID IN NUMBER
    ) RETURN NUMBER IS
v_TRANSACTION_ID_UNIT NUMBER(9);
v_COMMIT_STATUS VARCHAR2(16);
BEGIN
--if this gets used, add statement_type to the query for commit_status
    BEGIN
        SELECT TRANSACTION_ID INTO v_TRANSACTION_ID_UNIT
        FROM PJM_GEN_TXNS_BY_TYPE p
        WHERE p.PJM_Gen_Id = p_GEN_ID
        AND p.CONTRACT_ID = p_CONTRACT_ID
        AND p.PJM_GEN_TXN_TYPE = 'Unit Data';

        SELECT P.COMMIT_STATUS INTO v_COMMIT_STATUS
        FROM PJM_GEN_SCHED_STATUS P
        WHERE P.TRANSACTION_ID = v_TRANSACTION_ID_UNIT
        AND P.SCHEDULE_DATE = p_DATE;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            v_COMMIT_STATUS := 'Economic';
    END;
    --counting unavailable as pool scheduled
    IF UPPER(v_COMMIT_STATUS) <> 'MUSTRUN' THEN
        RETURN 1;
    ELSE RETURN 0;
    END IF;

END IS_POOL_SCHEDULED;
---------------------------------------------------------------------------------------------------------------------
FUNCTION IS_REGULATION_HOUR
    (
    p_DATE IN DATE,
    p_GEN_ID IN VARCHAR2,
    p_SCHEDULE_TYPE IN NUMBER,
    p_CONTRACT_ID IN NUMBER
    ) RETURN NUMBER IS
v_REG_TXN_ID NUMBER(9);
v_REG_MW NUMBER := 0;
BEGIN

     BEGIN
        SELECT P.TRANSACTION_ID INTO v_REG_TXN_ID
        FROM PJM_GEN_TXNS_BY_TYPE P
        WHERE P.PJM_Gen_Id = p_GEN_ID
        AND P.PJM_GEN_TXN_TYPE = 'Regulation'
        AND P.CONTRACT_ID = p_CONTRACT_ID;

        SELECT AMOUNT INTO v_REG_MW
        FROM IT_SCHEDULE I
        WHERE SCHEDULE_DATE = p_DATE
        AND I.SCHEDULE_TYPE = p_SCHEDULE_TYPE
        AND I.SCHEDULE_STATE = GA.INTERNAL_STATE
        AND I.TRANSACTION_ID = v_REG_TXN_ID;

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            v_REG_MW := 0;
    END;

    RETURN NVL(v_REG_MW, 0);

END IS_REGULATION_HOUR;
---------------------------------------------------------------------------------------------------------------------
FUNCTION IS_SPIN_RESERVE_HOUR
    (
    p_DATE IN DATE,
    p_GEN_ID IN VARCHAR2,
    p_SCHEDULE_TYPE IN NUMBER,
    p_CONTRACT_ID IN NUMBER
    ) RETURN NUMBER IS
v_SR_MW NUMBER := 0;
BEGIN

     BEGIN

        SELECT SUM(AMOUNT) INTO v_SR_MW
        FROM IT_SCHEDULE I
        WHERE SCHEDULE_DATE = p_DATE
        AND I.SCHEDULE_TYPE = p_SCHEDULE_TYPE
        AND I.SCHEDULE_STATE = GA.INTERNAL_STATE
        AND I.TRANSACTION_ID IN
					(SELECT TRANSACTION_ID FROM PJM_GEN_TXNS_BY_TYPE WHERE PJM_GEN_TXN_TYPE = 'Spinning Reserve'
						AND CONTRACT_ID = p_CONTRACT_ID AND PJM_Gen_Id = p_GEN_ID);

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            v_SR_MW := 0;
    END;

    RETURN NVL(v_SR_MW, 0);

END IS_SPIN_RESERVE_HOUR;
-------------------------------------------------------------------------------------------------------------------
FUNCTION GET_ECON_MIN
    (
    p_GEN_ID IN VARCHAR2,
    p_DATE IN DATE,
    p_CONTRACT_ID IN NUMBER
    ) RETURN NUMBER IS
v_ECON_MIN_ID NUMBER(3) := MM_PJM_UTIL.g_TG_UPD_ECON_MIN;
v_UNIT_TXN_ID NUMBER(9);
v_ECON_MIN NUMBER;
BEGIN
    BEGIN
        SELECT P.TRANSACTION_ID INTO v_UNIT_TXN_ID
        FROM PJM_GEN_TXNS_BY_TYPE P
        WHERE P.PJM_Gen_Id = p_GEN_ID
        AND P.PJM_GEN_TXN_TYPE = 'Unit Data'
        AND P.CONTRACT_ID = p_CONTRACT_ID;

        SELECT T.TRAIT_VAL INTO v_ECON_MIN
        FROM IT_TRAIT_SCHEDULE T
        WHERE T.SCHEDULE_DATE = p_DATE
        AND T.TRANSACTION_ID = v_UNIT_TXN_ID
        AND T.TRAIT_GROUP_ID = v_ECON_MIN_ID
				AND T.SCHEDULE_STATE = 1;

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            v_ECON_MIN := 0;
    END;

    RETURN v_ECON_MIN;
END GET_ECON_MIN;
-----------------------------------------------------------------------------------------------------------
FUNCTION GET_ECON_MAX
    (
    p_GEN_ID IN VARCHAR2,
    p_DATE IN DATE,
    p_CONTRACT_ID IN NUMBER
    ) RETURN NUMBER IS
v_ECON_MAX_ID NUMBER(3) := MM_PJM_UTIL.g_TG_UPD_ECON_MAX;
v_UNIT_TXN_ID NUMBER(9);
v_ECON_MAX NUMBER;
BEGIN
    BEGIN
        SELECT P.TRANSACTION_ID INTO v_UNIT_TXN_ID
        FROM PJM_GEN_TXNS_BY_TYPE P
        WHERE P.PJM_Gen_Id = p_GEN_ID
        AND P.PJM_GEN_TXN_TYPE = 'Unit Data'
        AND P.CONTRACT_ID = p_CONTRACT_ID;

        SELECT T.TRAIT_VAL INTO v_ECON_MAX
        FROM IT_TRAIT_SCHEDULE T
        WHERE T.SCHEDULE_DATE = p_DATE
        AND T.TRANSACTION_ID = v_UNIT_TXN_ID
        AND T.TRAIT_GROUP_ID = v_ECON_MAX_ID
				AND T.SCHEDULE_STATE = 1;

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            v_ECON_MAX := 0;
    END;

    RETURN v_ECON_MAX;
END GET_ECON_MAX;
-----------------------------------------------------------------------------------------------------------
FUNCTION GET_DESIRED_MW
     (
    p_GEN_ID IN VARCHAR2,
    p_DATE IN DATE,
    p_CONTRACT_ID IN NUMBER
    ) RETURN NUMBER IS
v_DESIRED_MW_ID NUMBER(3) := MM_PJM_UTIL.g_TG_OUT_DESIRED_MWH;
v_UNIT_TXN_ID NUMBER(9);
v_DESIRED_MW NUMBER;
BEGIN
    BEGIN
        SELECT P.TRANSACTION_ID INTO v_UNIT_TXN_ID
        FROM PJM_GEN_TXNS_BY_TYPE P
        WHERE P.PJM_Gen_Id = p_GEN_ID
        AND P.PJM_GEN_TXN_TYPE = 'Unit Data'
        AND P.CONTRACT_ID = p_CONTRACT_ID;

        SELECT I.TRAIT_VAL INTO v_DESIRED_MW
        FROM IT_TRAIT_SCHEDULE I
        WHERE I.TRANSACTION_ID = v_UNIT_TXN_ID
        AND I.SCHEDULE_DATE = p_DATE
        AND I.TRAIT_GROUP_ID = v_DESIRED_MW_ID;

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            v_DESIRED_MW := -1;
    END;

    RETURN v_DESIRED_MW;
END GET_DESIRED_MW;
-----------------------------------------------------------------------------------------------------------------------
FUNCTION GET_DA_SCHED_MW
    (
    p_CONTRACT_ID IN NUMBER,
    p_GEN_ID IN VARCHAR2,
    p_SCHEDULE_TYPE IN NUMBER,
    p_DATE IN DATE
    ) RETURN NUMBER IS
v_SCHED_MW NUMBER;
BEGIN
    BEGIN
        SELECT NVL(ITS.AMOUNT,0) INTO v_SCHED_MW
        FROM INTERCHANGE_TRANSACTION IT, IT_SCHEDULE ITS
        WHERE IT.TRANSACTION_TYPE = 'Generation'
        AND IT.COMMODITY_ID =
				--	case when p_gen_id = '99020402' then
					--	(SELECT COMMODITY_ID FROM IT_COMMODITY WHERE COMMODITY_NAME = 'Virtual Energy')
				--	else
						(SELECT COMMODITY_ID FROM IT_COMMODITY WHERE COMMODITY_NAME = 'DayAhead Energy')
				--	end
        AND IT.CONTRACT_ID = p_CONTRACT_ID
        AND IT.TRANSACTION_IDENTIFIER = p_GEN_ID
        --AND IT.POD_ID = v_SERVICE_PT_ID
        AND ITS.TRANSACTION_ID = IT.TRANSACTION_ID
        AND ITS.SCHEDULE_STATE = GA.INTERNAL_STATE
        AND ITS.SCHEDULE_TYPE = p_SCHEDULE_TYPE
        AND ITS.SCHEDULE_DATE = p_DATE
        AND ITS.AMOUNT <> 0;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            v_SCHED_MW := 0;
     END;

     RETURN NVL(v_SCHED_MW, 0);
END GET_DA_SCHED_MW;
-----------------------------------------------------------------------------------------
FUNCTION GET_RT_MW
    (
    p_CONTRACT_ID IN NUMBER,
    p_GEN_ID IN NUMBER,
    p_SCHEDULE_TYPE IN NUMBER,
    p_DATE IN DATE
    ) RETURN NUMBER IS
v_RT_MW NUMBER;
BEGIN
--if this gets used, add statement_type to the query for commit_status
     BEGIN
            SELECT SUM(ITS.AMOUNT) INTO v_RT_MW
            FROM IT_SCHEDULE ITS, INTERCHANGE_TRANSACTION T
            WHERE T.TRANSACTION_TYPE = 'Generation'
            AND T.CONTRACT_ID = p_CONTRACT_ID
            AND T.COMMODITY_ID IN (SELECT COMMODITY_ID FROM IT_COMMODITY WHERE COMMODITY_NAME = 'RealTime Energy')
            AND T.RESOURCE_ID = (SELECT OWNER_ENTITY_ID FROM TEMPORAL_ENTITY_ATTRIBUTE WHERE
                ATTRIBUTE_NAME = 'PJM_PNODEID' AND ATTRIBUTE_VAL = TO_CHAR(p_GEN_ID))
            AND T.TRANSACTION_ID = ITS.TRANSACTION_ID
            AND ITS.SCHEDULE_DATE = p_DATE
            AND ITS.SCHEDULE_STATE = GA.INTERNAL_STATE
            AND ITS.SCHEDULE_TYPE = p_SCHEDULE_TYPE;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            v_RT_MW := 0;
    END;
    RETURN v_RT_MW;
END GET_RT_MW;
--------------------------------------------------------------------------------------------
FUNCTION GET_ACTIVE_SCHEDULE
    (
    v_UNIT_TXN_ID IN NUMBER,
    p_DATE IN DATE
    ) RETURN NUMBER IS
v_ACTIVE_SCHED VARCHAR2(16);
v_ACT_SCHED NUMBER(3);
v_ACTIVE_SCHED_TRAIT NUMBER(3) := MM_PJM_UTIL.g_TG_MR_ACTIVE_SCHEDULE;
BEGIN
    BEGIN
          SELECT TRAIT_VAL INTO v_ACTIVE_SCHED
          FROM IT_TRAIT_SCHEDULE
          WHERE TRANSACTION_ID = v_UNIT_TXN_ID
          AND TRAIT_GROUP_ID = v_ACTIVE_SCHED_TRAIT
          AND SCHEDULE_DATE = p_DATE
          AND SCHEDULE_STATE = GA.INTERNAL_STATE;
          v_ACT_SCHED := TO_NUMBER(v_ACTIVE_SCHED);

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
                BEGIN
                    SELECT DISTINCT TRAIT_VAL INTO v_ACTIVE_SCHED
                    FROM IT_TRAIT_SCHEDULE
                    WHERE TRANSACTION_ID = v_UNIT_TXN_ID
                    AND TRAIT_GROUP_ID = v_ACTIVE_SCHED_TRAIT
                    AND TRUNC(SCHEDULE_DATE, 'DD') = TRUNC(p_DATE, 'DD')
                    AND SCHEDULE_STATE = GA.INTERNAL_STATE;
                    v_ACT_SCHED := TO_NUMBER(v_ACTIVE_SCHED);

                EXCEPTION
                    WHEN NO_DATA_FOUND THEN
                        NULL;
                END;
    END;

    RETURN v_ACT_SCHED;

END GET_ACTIVE_SCHEDULE;
---------------------------------------------------------------------------------------------
FUNCTION GET_RT_LMP
    (
    p_GEN_ID IN VARCHAR2,
    p_DATE IN DATE
    ) RETURN NUMBER IS
v_LMP_VALUE NUMBER;
v_SERVICE_PT_ID NUMBER;
BEGIN
    SELECT SR.SERVICE_POINT_ID INTO v_SERVICE_PT_ID
    FROM SUPPLY_RESOURCE SR, TEMPORAL_ENTITY_ATTRIBUTE T
    WHERE T.ATTRIBUTE_NAME = 'PJM_PNODEID'
    AND T.ATTRIBUTE_VAL = p_GEN_ID
    AND T.OWNER_ENTITY_ID = SR.RESOURCE_ID;

    SELECT NVL(MV.PRICE,0) INTO v_LMP_VALUE
    FROM MARKET_PRICE M, MARKET_PRICE_VALUE MV
    WHERE M.MARKET_PRICE_TYPE = 'Locational Marginal Price'
    AND M.MARKET_TYPE = 'RealTime'
    AND M.POD_ID = v_SERVICE_PT_ID
    AND MV.PRICE_CODE = 'A'
    AND MV.MARKET_PRICE_ID = M.MARKET_PRICE_ID
    AND MV.PRICE_DATE = p_DATE;

    RETURN v_LMP_VALUE;

END GET_RT_LMP;
------------------------------------------------------------------------------------------------
	/*******************************************************************************
    Returns the number of FTR bid hours for either obligation bids or option
    bids. FTR bids are transactions having the is bid/offer flag set to true,
    a commodity of Transmission, and an agreement type of either FTR Option
    (for option bids) or FTR Obligation (for obligation bids).
    Called by the FTR Admin Charge charge component. Only get Annual Auctions
    and the current month auctions; ignore Auctions such as 'Pt to Pt FTR'
  *******************************************************************************/
	FUNCTION FTR_BID_HOURS(p_CUT_BEGIN_DATE          IN DATE,
							p_CUT_END_DATE IN DATE,
                            p_CONTRACT_ID   IN NUMBER,
                            p_IS_OBLIGATION IN NUMBER) RETURN NUMBER IS
		l_BID_HOURS      NUMBER;
		l_AGREEMENT_TYPE INTERCHANGE_TRANSACTION.AGREEMENT_TYPE%TYPE;
    v_MONTH VARCHAR2(8);
    v_YEAR VARCHAR2(8);
		v_BEGIN_DATE DATE;
		v_END_DATE DATE;
	BEGIN
		--if statement interval day, end date passed in not correct
		UT.CUT_DATE_RANGE(FIRST_DAY(p_CUT_BEGIN_DATE), LAST_DAY(FIRST_DAY(p_CUT_BEGIN_DATE)),
		MM_PJM_UTIL.g_PJM_TIME_ZONE, v_BEGIN_DATE, v_END_DATE);
		IF p_IS_OBLIGATION = 1 THEN
			l_AGREEMENT_TYPE := 'FTR%Obligation';	-- we need the % for '24H' that's in there sometimes
		ELSE
			l_AGREEMENT_TYPE := 'FTR Option';
		END IF;

        v_MONTH := TO_CHAR(p_CUT_BEGIN_DATE, 'MON');
        v_YEAR :=  TO_CHAR(p_CUT_BEGIN_DATE, 'YYYY');

		SELECT COUNT(ITS.TRANSACTION_ID)
			INTO l_BID_HOURS
			FROM IT_SCHEDULE ITS, INTERCHANGE_TRANSACTION ITX,
                 TEMPORAL_ENTITY_ATTRIBUTE T
		 WHERE ITX.CONTRACT_ID = p_CONTRACT_ID
			 AND ITX.COMMODITY_ID =
					 (SELECT ITC.COMMODITY_ID
							FROM IT_COMMODITY ITC
						 WHERE ITC.COMMODITY_NAME = 'Transmission')
			 AND ITX.AGREEMENT_TYPE LIKE l_AGREEMENT_TYPE
			 AND ITS.TRANSACTION_ID = ITX.TRANSACTION_ID
             AND (UPPER(T.ATTRIBUTE_VAL) LIKE '%ANNUAL AUCTION'
             OR UPPER(T.ATTRIBUTE_VAL) LIKE v_MONTH || ' ' || v_YEAR || '%')
             --AND (UPPER(ITX.TRANSACTION_DESC) LIKE '%ANNUAL AUCTION'
             --OR UPPER(ITX.TRANSACTION_DESC) LIKE v_MONTH || ' ' || v_YEAR || '%')
             AND T.OWNER_ENTITY_ID = ITX.TRANSACTION_ID
             AND T.ATTRIBUTE_ID = (SELECT ATTRIBUTE_ID FROM ENTITY_ATTRIBUTE WHERE ATTRIBUTE_NAME = 'Auction_Name')
			 AND ITS.SCHEDULE_STATE = GA.INTERNAL_STATE
			 AND ITS.SCHEDULE_DATE BETWEEN p_CUT_BEGIN_DATE AND v_END_DATE;


 		RETURN NVL(l_BID_HOURS, 0);
	END FTR_BID_HOURS;

	/*******************************************************************************
    Returns the number of hours FTRs are in effect during the given month. FTR
    Holders are defined by transactions having a commodity of Transmission,
    a type of Purchase, and an Agreement Type of either FTR Option or FTR
    Obligation. Called by the FTR Admin Charge charge component.
  *******************************************************************************/
	FUNCTION FTR_HOLDER_MW_HOURS(p_CUT_BEGIN_DATE IN DATE, p_CUT_END_DATE IN DATE, p_CONTRACT_ID IN NUMBER)
		RETURN NUMBER IS
		l_MW_HOURS NUMBER;
		v_BEGIN_DATE DATE;
		v_END_DATE DATE;
	BEGIN
		--if statement interval day, end date passed in not correct
		UT.CUT_DATE_RANGE(FIRST_DAY(p_CUT_BEGIN_DATE), LAST_DAY(FIRST_DAY(p_CUT_BEGIN_DATE)),
		MM_PJM_UTIL.g_PJM_TIME_ZONE, v_BEGIN_DATE, v_END_DATE);
		SELECT SUM(ITS.AMOUNT)
			INTO l_MW_HOURS
			FROM IT_SCHEDULE ITS, INTERCHANGE_TRANSACTION ITX
		 WHERE ITX.CONTRACT_ID = p_CONTRACT_ID
			 AND ITX.COMMODITY_ID =
					 (SELECT ITC.COMMODITY_ID
							FROM IT_COMMODITY ITC
						 WHERE ITC.COMMODITY_NAME = 'Transmission')
			 AND ITX.TRANSACTION_TYPE = 'Purchase'
			 AND ITX.AGREEMENT_TYPE LIKE 'FTR%'
			 AND ITS.TRANSACTION_ID = ITX.TRANSACTION_ID
			 AND ITS.SCHEDULE_STATE = 1
			 AND ITS.SCHEDULE_DATE BETWEEN p_CUT_BEGIN_DATE AND v_END_DATE;
		RETURN NVL(l_MW_HOURS, 0);
	END FTR_HOLDER_MW_HOURS;

	/*******************************************************************************
    For a given billing date, contract ID, delivery interval, and whether or not
    the charges are related to firm or non-firm transmission, return the total
    service charge. We collect all transactions belonging to the given contract,
    then for each transaction, look up the applicable point-to-point rate, and
    multiply by the sum of all the IT_SCHEDULE amounts for this transaction.

    The applicable rate depends on the service zone defined for the transaction's
    POD, if the transaction is firm or non-firm, and the interval of the
    transaction. The rates are stored as custom attributes on service zones for
    PJM, as defined in Schedule 7 (firm) and Schedule 8 (non-firm) of the PJM
    Open Access Transmission Tariff document.
  *******************************************************************************/
	FUNCTION P2P_TRANSMISSION_CHARGE(p_DATE                 IN DATE,
																	 p_CONTRACT_ID          IN NUMBER,
																	 p_IS_FIRM              IN NUMBER,
																	 p_TRANSACTION_INTERVAL IN VARCHAR2)
		RETURN NUMBER IS

		l_RATE_INTERVAL     VARCHAR2(16);
		l_SERVICE_ZONE_RATE TEMPORAL_ENTITY_ATTRIBUTE.ATTRIBUTE_VAL%TYPE;
		l_TOTAL_CHARGE      NUMBER := 0;
		l_TOTAL_TRANS_MW    NUMBER := 0;
		c_XNS               REF_CURSOR;
		l_POD_ID            INTERCHANGE_TRANSACTION.POR_ID%TYPE;
		l_XN_ID             INTERCHANGE_TRANSACTION.TRANSACTION_ID%TYPE;
	BEGIN

		l_RATE_INTERVAL := CASE UPPER(p_TRANSACTION_INTERVAL) WHEN 'YEAR' THEN 'Yearly' WHEN 'MONTH' THEN 'Monthly' WHEN 'WEEK' THEN 'Weekly' WHEN 'DAY' THEN 'Daily' ELSE '' END;

		IF p_IS_FIRM = 0 THEN
			-- non-firm
			OPEN c_XNS FOR
				SELECT IX.TRANSACTION_ID, IX.POD_ID
					FROM INTERCHANGE_TRANSACTION IX
				 WHERE IX.CONTRACT_ID = p_CONTRACT_ID
					 AND IX.IS_FIRM = p_IS_FIRM
					 AND UPPER(IX.TRANSACTION_TYPE) = 'TRANSMISSION';
		ELSE
			-- firm
			OPEN c_XNS FOR
				SELECT IX.TRANSACTION_ID, IX.POD_ID
					FROM INTERCHANGE_TRANSACTION IX
				 WHERE IX.CONTRACT_ID = p_CONTRACT_ID
					 AND IX.IS_FIRM = p_IS_FIRM
					 AND IX.TRANSACTION_INTERVAL = p_TRANSACTION_INTERVAL
					 AND UPPER(IX.TRANSACTION_TYPE) = 'LOAD';
		END IF;

		LOOP
			FETCH c_XNS
				INTO l_XN_ID, l_POD_ID;
			EXIT WHEN c_XNS%NOTFOUND;

      IF c_XNS%ROWCOUNT > 0 THEN
  			-- get the rate value based on the service zone for this
  			-- transaction's POD and interval
  			SELECT TEA.ATTRIBUTE_VAL
  				INTO l_SERVICE_ZONE_RATE
  				FROM TEMPORAL_ENTITY_ATTRIBUTE TEA
  			 WHERE UPPER(TEA.ATTRIBUTE_NAME) = UPPER('Firm P2P ' || l_RATE_INTERVAL)
  				 AND TEA.OWNER_ENTITY_ID =
  						 (SELECT SZ.SERVICE_ZONE_ID
  								FROM SERVICE_ZONE SZ
  							 WHERE SZ.SERVICE_ZONE_ID =
  										 (SELECT SP.SERVICE_ZONE_ID
  												FROM SERVICE_POINT SP
  											 WHERE SP.SERVICE_POINT_ID = l_POD_ID));

  			-- now that I've got the entity attribute value, get the IT_SCHEDULE values
  			-- (sum over the billing interval)
  			SELECT SUM(ITS.AMOUNT)
  				INTO l_TOTAL_TRANS_MW
  				FROM IT_SCHEDULE ITS
  			 WHERE ITS.TRANSACTION_ID = l_XN_ID
  				 AND ITS.SCHEDULE_DATE BETWEEN DATE_UTIL.BEGIN_DATE_FOR_INTERVAL(p_DATE, p_TRANSACTION_INTERVAL)
				 							AND DATE_UTIL.END_DATE_FOR_INTERVAL(DATE_UTIL.BEGIN_DATE_FOR_INTERVAL(p_DATE, p_TRANSACTION_INTERVAL), p_TRANSACTION_INTERVAL);

  			l_TOTAL_CHARGE := l_TOTAL_CHARGE +
  												(l_TOTAL_TRANS_MW * l_SERVICE_ZONE_RATE);
		  END IF;
    END LOOP;

		RETURN l_TOTAL_CHARGE;
	END P2P_TRANSMISSION_CHARGE;

	/*********************************************************************************
    For the given billing interval, returns the Displatch Variation (absolute
    difference between actual and scheduled MWh) for use in calculating the Balancing
    Operating Reserves Charges.

    If the difference between actual and scheduled generation is less than 5%, then
    the function returns zero (see Operating Agreement Accounting, Charges for
    Operating Reserves).
  *********************************************************************************/
	FUNCTION DISPATCH_VARIATION(p_DATE IN DATE, p_CONTRACT_ID IN NUMBER)
		RETURN NUMBER IS
		p_VARIATION     IT_SCHEDULE.AMOUNT%TYPE := 0;
		p_ACTUAL_MWH    IT_SCHEDULE.AMOUNT%TYPE;
		p_SCHEDULED_MWH IT_SCHEDULE.AMOUNT%TYPE;
	BEGIN
		-- day-ahead (scheduled) MWh
		SELECT SUM(ITS.AMOUNT)
			INTO p_SCHEDULED_MWH
			FROM IT_SCHEDULE ITS, INTERCHANGE_TRANSACTION ITX, IT_COMMODITY ITC
		 WHERE ITS.TRANSACTION_ID = ITX.TRANSACTION_ID
			 AND ITX.CONTRACT_ID = p_CONTRACT_ID
			 AND ITX.TRANSACTION_TYPE = 'Generation'
			 AND ITC.COMMODITY_NAME = MM_PJM_UTIL.g_COMM_DA_ENERGY
			 AND ITX.COMMODITY_ID = ITC.COMMODITY_ID
			 and ITS.SCHEDULE_TYPE = 1
			 AND ITS.SCHEDULE_DATE = p_DATE;
			  --AND ITS.SCHEDULE_DATE BETWEEN
					 --PC.BEGIN_DATE_FOR_INTERVAL(p_DATE, ITX.TRANSACTION_INTERVAL) AND
					 --PC.END_DATE_FOR_INTERVAL(p_DATE, ITX.TRANSACTION_INTERVAL);

		-- real-time (actual) MWh
		SELECT SUM(ITS.AMOUNT)
			INTO p_ACTUAL_MWH
			FROM IT_SCHEDULE ITS, INTERCHANGE_TRANSACTION ITX, IT_COMMODITY ITC
		 WHERE ITS.TRANSACTION_ID = ITX.TRANSACTION_ID
			 AND ITX.CONTRACT_ID = p_CONTRACT_ID
			 AND ITX.TRANSACTION_TYPE = 'Generation'
			 AND ITC.COMMODITY_NAME = MM_PJM_UTIL.g_COMM_RT_ENERGY
			 AND ITX.COMMODITY_ID = ITC.COMMODITY_ID
			 AND ITS.SCHEDULE_TYPE = 1
			 AND ITS.SCHEDULE_DATE = p_DATE
			 --AND ITS.SCHEDULE_DATE BETWEEN
					 --PC.BEGIN_DATE_FOR_INTERVAL(p_DATE, ITX.TRANSACTION_INTERVAL) AND
					 --PC.END_DATE_FOR_INTERVAL(p_DATE, ITX.TRANSACTION_INTERVAL)
            --cgn added
            AND ITS.AMOUNT > 0;

		IF p_SCHEDULED_MWH = 0 THEN
			-- we don't expect this case, but it's here
			p_VARIATION := 0;
		ELSE
			IF ABS(p_ACTUAL_MWH - p_SCHEDULED_MWH) / p_SCHEDULED_MWH <= 0.05 THEN
				-- within 5% threshold; no penalty
				p_VARIATION := 0;
			ELSE
				p_VARIATION := ABS(p_ACTUAL_MWH - p_SCHEDULED_MWH);
			END IF;
		END IF;
		RETURN NVL(p_VARIATION, 0);
	END DISPATCH_VARIATION;
---------------------------------------------------------------------------------------------
FUNCTION GET_OWNERSHIP_PERCENTAGE(p_PJM_GEN_ID IN VARCHAR2,
																	p_CONTRACT   IN INTERCHANGE_CONTRACT.CONTRACT_ID%TYPE,
																	p_DATE       IN DATE) RETURN NUMBER IS
	--v_RESOURCE_ID          SUPPLY_RESOURCE.RESOURCE_ID%TYPE;
	v_PNODEID_ATTRIBUTE_ID ENTITY_ATTRIBUTE.ATTRIBUTE_ID%TYPE;
	v_OWNERSHIP_PERCENTAGE NUMBER := 1.0;
BEGIN
	ID.ID_FOR_ENTITY_ATTRIBUTE('PJM_PNODEID', EC.ED_SUPPLY_RESOURCE, 'String', FALSE, v_PNODEID_ATTRIBUTE_ID);

	BEGIN
		SELECT OWNERSHIP_PERCENT / 100.0
			INTO v_OWNERSHIP_PERCENTAGE
			FROM PJM_SERVICE_POINT_OWNERSHIP PSO
		 WHERE CONTRACT_ID = p_CONTRACT
			 AND p_DATE BETWEEN NVL(BEGIN_DATE, DATE '1900-01-01') AND NVL(END_DATE, DATE '9999-12-31')
			 AND SERVICE_POINT_ID =
					 (SELECT SERVICE_POINT_ID
							FROM TEMPORAL_ENTITY_ATTRIBUTE TEA, SUPPLY_RESOURCE R
						 WHERE R.RESOURCE_ID = TEA.OWNER_ENTITY_ID
							 AND TEA.ATTRIBUTE_ID = v_PNODEID_ATTRIBUTE_ID
							 AND TEA.ATTRIBUTE_VAL = p_PJM_GEN_ID);
	EXCEPTION
		WHEN OTHERS THEN
			v_OWNERSHIP_PERCENTAGE := 1.0;
	END;

	RETURN v_OWNERSHIP_PERCENTAGE;
END GET_OWNERSHIP_PERCENTAGE;
---------------------------------------------------------------------------------------------
FUNCTION GET_DISPATCH_VARIATION
    (
    p_DATE IN DATE,
    p_CONTRACT IN NUMBER,
    p_SCHEDULE_TYPE IN NUMBER
    ) RETURN NUMBER IS
--get list of generators as cursor
CURSOR c_GENERATORS IS
    SELECT DISTINCT T.ATTRIBUTE_VAL GenId
    FROM TEMPORAL_ENTITY_ATTRIBUTE T, INTERCHANGE_TRANSACTION I
		WHERE I.CONTRACT_ID = p_CONTRACT
		AND I.COMMODITY_ID IN
			(SELECT COMMODITY_ID FROM IT_COMMODITY
				WHERE COMMODITY_NAME IN ('DayAhead Energy', 'RealTime Energy'))
		AND UPPER(T.ATTRIBUTE_NAME) = 'PJM_PNODEID'
		AND I.RESOURCE_ID = T.OWNER_ENTITY_ID;

TYPE BO_QTY_MAP IS TABLE OF NUMBER(10,3) INDEX BY BINARY_INTEGER;
TYPE BO_PRICE_MAP IS TABLE OF NUMBER(10,3) INDEX BY BINARY_INTEGER;
--v_DATE DATE;
--v_INTERVAL_BEGIN_DATE DATE;
--v_INTERVAL_END_DATE DATE;
v_DISPATCH_VAR NUMBER := 0;
v_DIFF NUMBER;
v_DA_SCHED NUMBER;
v_RT_MW NUMBER;
v_DESIRED_MW NUMBER;
v_UNIT_TXN_ID NUMBER(9);
v_TRANSACTION_ID_SCHED NUMBER(9);
v_COUNT NUMBER(2);
v_Q1 NUMBER;
v_P1 NUMBER;
v_RT_LMP NUMBER;
v_ACTIVE_SCHED NUMBER(3);
v_BO_QTY_MAP BO_QTY_MAP;
v_BO_PRICE_MAP BO_PRICE_MAP;
--v_IDX BINARY_INTEGER := 1;

--v_TOTAL_DISPATCH_VAR NUMBER := 0;
v_OWNERSHIP_PERCENTAGE NUMBER;

BEGIN
--v_TOTAL_DISPATCH_VAR := 0;
        FOR v_GENERATOR IN c_GENERATORS LOOP

						v_OWNERSHIP_PERCENTAGE := GET_OWNERSHIP_PERCENTAGE(v_GENERATOR.Genid, p_CONTRACT, p_DATE);

            v_DA_SCHED := GET_DA_SCHED_MW(p_CONTRACT, v_GENERATOR.Genid, p_SCHEDULE_TYPE, p_DATE);
            v_RT_MW := GET_RT_MW(p_CONTRACT, v_GENERATOR.Genid, p_SCHEDULE_TYPE, p_DATE);
            IF v_DA_SCHED <= 0 AND v_RT_MW < 0 THEN
							v_DA_SCHED := 0;
							v_RT_MW := 0;
						END IF;
            --IF v_RT_MW < 0 THEN v_RT_MW := 0; END IF;
            IF v_DA_SCHED = 0 AND v_RT_MW = 0 THEN
                v_DISPATCH_VAR := v_DISPATCH_VAR + 0;
            ELSIF FOLLOWING_PJM_DISPATCH(p_DATE, v_GENERATOR.Genid, p_CONTRACT) = 1 THEN
                v_DISPATCH_VAR := v_DISPATCH_VAR + 0;
            ELSIF IS_REGULATION_HOUR(p_DATE, v_GENERATOR.Genid, p_SCHEDULE_TYPE, p_CONTRACT) > 0 THEN
                v_DISPATCH_VAR := v_DISPATCH_VAR + 0;
					--	ELSIF IS_SPIN_RESERVE_HOUR(p_DATE, v_GENERATOR.Genid, p_SCHEDULE_TYPE, p_CONTRACT) > 0
						--			AND v_RT_MW < v_DA_SCHED THEN
              --  v_DISPATCH_VAR := v_DISPATCH_VAR + 0;
           /* ELSIF IS_POOL_SCHEDULED(v_DATE, v_GENERATOR.Genid, p_CONTRACT) = 1 THEN
            v_DIFF := ABS(v_RT_MW - v_DA_SCHED);
                IF v_DA_SCHED <> 0 THEN
                    IF ABS(v_DIFF / v_DA_SCHED) > 0.05 THEN
                        IF v_DIFF >= 5 THEN
                            v_DISPATCH_VAR := v_DISPATCH_VAR + v_DIFF;
                        END IF;
                    END IF;
                ELSE
                    IF v_DIFF >= 5 THEN
                        v_DISPATCH_VAR := v_DISPATCH_VAR + v_DIFF;
                    END IF;
                END IF;              */
            ELSIF GET_ECON_MAX(v_GENERATOR.Genid, p_DATE, p_CONTRACT) = GET_ECON_MIN(v_GENERATOR.Genid, p_DATE, p_CONTRACT) THEN
                v_DIFF := ABS(v_RT_MW - v_DA_SCHED);
                IF v_DA_SCHED <> 0 THEN
                    IF ROUND(ABS(v_DIFF / v_DA_SCHED),3) >= 0.05 THEN
                        IF v_DIFF >= 5 THEN
                            v_DISPATCH_VAR := v_DISPATCH_VAR + v_DIFF;
                        END IF;
                    END IF;
                ELSE
                    IF v_DIFF >= 5 THEN
                        v_DISPATCH_VAR := v_DISPATCH_VAR + v_DIFF;
                    END IF;
                END IF;
            ELSE --ECON_MIN <> ECON_MAX
								-- 28-MAR-2007, JBC: need to adjust by ownership
                v_DESIRED_MW := GET_DESIRED_MW(v_GENERATOR.Genid, p_DATE, p_CONTRACT) * v_OWNERSHIP_PERCENTAGE;
                IF v_DESIRED_MW > 0 THEN
                    v_DIFF := ABS(v_RT_MW - v_DESIRED_MW);
                    IF ROUND(ABS((v_RT_MW - v_DESIRED_MW) / v_DESIRED_MW),3) >= 0.10 THEN
                    	IF ABS(v_DIFF) >= 5 THEN
                      	v_DISPATCH_VAR := v_DISPATCH_VAR + v_DIFF;
                      END IF;
                    END IF;
               	ELSIF v_DESIRED_MW = 0 THEN --if desired is 0, deviation is 0
									v_DISPATCH_VAR := v_DISPATCH_VAR + 0;

                ELSE --desired mw must be 'calculated'

                	v_ACTIVE_SCHED := GET_ACTIVE_SCHEDULE(v_UNIT_TXN_ID, p_DATE);
                  --get Schedule txn id so we can get schedule offer
                    IF v_ACTIVE_SCHED IS NULL THEN
						BEGIN
                            SELECT TRANSACTION_ID INTO v_TRANSACTION_ID_SCHED
                            FROM PJM_GEN_TXNS_BY_TYPE p
                            WHERE P.CONTRACT_ID = p_CONTRACT
                            AND P.PJM_Gen_Id = v_GENERATOR.Genid
                            AND P.PJM_GEN_TXN_TYPE = 'Schedule'
                            AND p.AGREEMENT_TYPE LIKE '9%';
						EXCEPTION
					        WHEN TOO_MANY_ROWS THEN
							BEGIN
								SELECT TRANSACTION_ID INTO v_TRANSACTION_ID_SCHED
                        		FROM PJM_GEN_TXNS_BY_TYPE p
                        		WHERE P.CONTRACT_ID = p_CONTRACT
                        		AND P.PJM_Gen_Id = v_GENERATOR.Genid
                        		AND P.PJM_GEN_TXN_TYPE = 'Schedule'
                        		AND p.AGREEMENT_TYPE LIKE '9%'
								AND P.TRANSACTION_ALIAS = 'price';
							EXCEPTION
							    WHEN NO_DATA_FOUND THEN
								    NULL;
								END;
							END;

                    ELSE
						BEGIN
                            SELECT TRANSACTION_ID INTO v_TRANSACTION_ID_SCHED
                            FROM PJM_GEN_TXNS_BY_TYPE p
                            WHERE P.CONTRACT_ID = p_CONTRACT
                            AND P.PJM_Gen_Id = v_GENERATOR.Genid
                            AND P.PJM_GEN_TXN_TYPE = 'Schedule'
                            AND p.AGREEMENT_TYPE = TO_CHAR(v_ACTIVE_SCHED);
						EXCEPTION
                            WHEN NO_DATA_FOUND THEN
                                NULL;
					    END;
                    END IF;

                  IF v_TRANSACTION_ID_SCHED IS NOT NULL THEN
                      SELECT COUNT(SET_NUMBER) INTO v_COUNT
											FROM BID_OFFER_SET B
                      WHERE B.TRANSACTION_ID = v_TRANSACTION_ID_SCHED
											AND B.SCHEDULE_STATE = GA.INTERNAL_STATE
											AND TRUNC(B.SCHEDULE_DATE, 'DD') = TRUNC(p_DATE, 'DD');

                      FOR I IN 1..v_COUNT LOOP
                          SELECT QUANTITY, PRICE
                          INTO v_Q1, v_P1
                          FROM BID_OFFER_SET
                          WHERE TRANSACTION_ID = v_TRANSACTION_ID_SCHED
                          AND SET_NUMBER = I
													AND SCHEDULE_STATE = GA.INTERNAL_STATE
                          AND TRUNC(SCHEDULE_DATE, 'DD') = TRUNC(p_DATE, 'DD');

                          v_BO_PRICE_MAP(I) := v_P1;
                          v_BO_QTY_MAP(I) := v_Q1;
                     	END LOOP;

                      IF v_COUNT = 0 THEN --no sched offer, desired mw is 0, deviation is 0
													v_DISPATCH_VAR := v_DISPATCH_VAR + 0;
											ELSIF v_COUNT = 1 THEN
                          v_DESIRED_MW := v_BO_QTY_MAP(1) * v_OWNERSHIP_PERCENTAGE;
                          v_DIFF := ABS(v_RT_MW - v_DESIRED_MW);
                          IF v_DESIRED_MW > 0 THEN
                          	IF ROUND(ABS(v_DIFF / v_DESIRED_MW),3) > 0.10 THEN
                            	IF v_DIFF >= 5 THEN
                              	v_DISPATCH_VAR := v_DISPATCH_VAR + v_DIFF;
                              END IF;
                           	END IF;
                        	ELSE --if desired is 0, deviation is 0
                          	v_DISPATCH_VAR := v_DISPATCH_VAR + 0;
                          END IF;
                      ELSE -- v_COUNT > 1 THEN
                            --substitute RT LMP for Dispatch rate since we don't yet have access to those
                            v_RT_LMP := GET_RT_LMP(v_GENERATOR.Genid, p_DATE);
                            IF v_RT_LMP < v_BO_PRICE_MAP(1) THEN
                               v_DESIRED_MW := GET_ECON_MIN(v_GENERATOR.Genid, p_DATE, p_CONTRACT) * v_OWNERSHIP_PERCENTAGE;
                               v_DIFF := ABS(v_RT_MW - v_DESIRED_MW);
                               IF v_DESIRED_MW > 0 THEN
                                    IF ROUND(ABS(v_DIFF / v_DESIRED_MW),3) > 0.10 THEN
                                        IF v_DIFF >= 5 THEN
                                            v_DISPATCH_VAR := v_DISPATCH_VAR + v_DIFF;
                                        END IF;
                                    END IF;
                             	ELSE --if desired is 0, deviation is 0
                          			v_DISPATCH_VAR := v_DISPATCH_VAR + 0;
                             	END IF;
                            ELSIF v_RT_LMP > v_BO_PRICE_MAP(v_COUNT) THEN
                                v_DESIRED_MW := GET_ECON_MAX(v_GENERATOR.Genid, p_DATE, p_CONTRACT) * v_OWNERSHIP_PERCENTAGE;
                                v_DIFF := ABS(v_RT_MW - v_DESIRED_MW);
                                IF v_DESIRED_MW > 0 THEN
                                    IF ROUND(ABS(v_DIFF / v_DESIRED_MW),3) > 0.10 THEN
                                        IF v_DIFF >= 5 THEN
                                            v_DISPATCH_VAR := v_DISPATCH_VAR + v_DIFF;
                                        END IF;
                                    END IF;
                                ELSE --if desired is 0, deviation is 0
                          				v_DISPATCH_VAR := v_DISPATCH_VAR + 0;
                                END IF;
                            ELSE
                                FOR I IN 1..v_COUNT LOOP
                                    IF v_BO_QTY_MAP(I) > v_RT_MW THEN
                                        IF v_BO_PRICE_MAP(I) > v_RT_LMP THEN
                                            IF I > 1 THEN
                                                v_DESIRED_MW := v_BO_QTY_MAP(I-1) * v_OWNERSHIP_PERCENTAGE;
                                            ELSE
                                                v_DESIRED_MW := v_BO_QTY_MAP(I) * v_OWNERSHIP_PERCENTAGE;
                                            END IF;
                                        ELSE
                                            v_DESIRED_MW := v_BO_QTY_MAP(I) * v_OWNERSHIP_PERCENTAGE;
                                        END IF;
                                        EXIT;
                                    END IF;
                                END LOOP;
                                v_DIFF := ABS(v_RT_MW - v_DESIRED_MW);
                                IF v_DESIRED_MW > 0 THEN
                                    IF ROUND(ABS(v_DIFF / v_DESIRED_MW),3) > 0.10 THEN
                                        IF v_DIFF >= 5 THEN
                                            v_DISPATCH_VAR := v_DISPATCH_VAR + v_DIFF;
                                        END IF;
                                    END IF;
                                ELSE --if desired is 0, deviation is 0
                          				v_DISPATCH_VAR := v_DISPATCH_VAR + 0;
                               END IF;
                            END IF;
										END IF;
								ELSE
									v_DISPATCH_VAR := v_DISPATCH_VAR + 0;
                END IF;
            END IF;
					END IF;

					-- 27-mar-2007: need to apply any ownership percentage
					--v_DISPATCH_VAR := NVL(v_DISPATCH_VAR, 0) * GET_OWNERSHIP_PERCENTAGE(v_GENERATOR.Genid, p_CONTRACT, p_DATE);

        END LOOP;
        --v_DATE := v_DATE + 1/24;
        --v_IDX := v_IDX + 1;
   -- END LOOP;

    RETURN v_DISPATCH_VAR;

END GET_DISPATCH_VARIATION;
--------------------------------------------------------------------------------------------
	/*********************************************************************************
    Returns the total Network Integration Transmission Service (NITS) charge
    for all zones in PJM. The NITS charge is based on the daily peak load contribution
    in each zone, times the annual NITS rate, divided by 365. The charge definition
    is taken from the OATT Manual, p. 28.
  *********************************************************************************/
	FUNCTION NITS_CHARGES(p_DATE IN DATE, p_CONTRACT_ID IN NUMBER) RETURN NUMBER IS
		l_DATE         DATE;
		l_START_DATE   DATE := TRUNC(p_DATE, 'MM');
		l_END_DATE     DATE := ADD_MONTHS(l_START_DATE, 1);
		l_TOTAL_CHARGE NUMBER;
		l_DAILY_CHARGE NUMBER;
		CURSOR l_ZONES_CURSOR IS
			SELECT SZ.SERVICE_ZONE_ID
				FROM SERVICE_ZONE            SZ,
						 SERVICE_POINT           SP,
						 SUPPLY_RESOURCE         SR,
						 INTERCHANGE_TRANSACTION ITX
			 WHERE ITX.CONTRACT_ID = p_CONTRACT_ID
				 AND ITX.SC_ID = g_PJM_SC_ID
				 AND ITX.RESOURCE_ID = SR.RESOURCE_ID
				 AND SR.SERVICE_POINT_ID = SP.SERVICE_POINT_ID
				 AND SP.SERVICE_ZONE_ID = SZ.SERVICE_ZONE_ID;
	BEGIN
		-- loop over each zone
		FOR l_ZONE_RECORD IN l_ZONES_CURSOR LOOP
			-- loop over each day in month and get peak load contribution in this zone
			l_DATE := l_START_DATE;
			WHILE l_DATE BETWEEN l_START_DATE AND l_END_DATE LOOP
				SELECT SUM(MAX(ITS.AMOUNT) * TEA.ATTRIBUTE_VAL / 365) AS NITS_CHARGES
					INTO l_DAILY_CHARGE
					FROM IT_SCHEDULE               ITS,
							 INTERCHANGE_TRANSACTION   ITX,
							 SERVICE_POINT             SP,
							 SERVICE_ZONE              SZ,
							 TEMPORAL_ENTITY_ATTRIBUTE TEA
				 WHERE ITS.TRANSACTION_ID = ITX.TRANSACTION_ID
					 AND ITX.TRANSACTION_TYPE = 'Load'
					 AND ITX.RESOURCE_ID = SP.SERVICE_POINT_ID
					 AND SP.SERVICE_ZONE_ID = SZ.SERVICE_ZONE_ID
					 AND ITX.CONTRACT_ID = p_CONTRACT_ID
					 AND SZ.SERVICE_ZONE_ID = l_ZONE_RECORD.SERVICE_ZONE_ID
					 AND ITS.SCHEDULE_DATE BETWEEN l_DATE AND l_DATE + 1
					 AND TEA.OWNER_ENTITY_ID = SZ.SERVICE_ZONE_ID
					 AND TEA.BEGIN_DATE <= l_DATE
					 AND (TEA.END_DATE >= l_DATE + 1 OR TEA.END_DATE IS NULL)
					 AND TEA.ATTRIBUTE_ID =
							 (SELECT EA.ATTRIBUTE_ID
									FROM ENTITY_ATTRIBUTE EA
								 WHERE EA.ATTRIBUTE_NAME = 'NITS Rate')
				 GROUP BY TEA.ATTRIBUTE_VAL;
				l_TOTAL_CHARGE := l_TOTAL_CHARGE + l_DAILY_CHARGE;
				l_DATE         := l_DATE + 1;
			END LOOP;
		END LOOP;

		RETURN NVL(l_TOTAL_CHARGE, 0);
	END NITS_CHARGES;

/*********************************************************************************
    Returns the Daily Peak Demand for a particular zone in PJM - which is used for billing
	Network Integration Transmission Service (NITS) charges. The charge definition
    is taken from the OATT Manual, p. 28.
  *********************************************************************************/
	FUNCTION NITS_PEAK_DEMAND(p_DATE IN DATE, p_STATEMENT_TYPE IN NUMBER, p_CONTRACT_ID IN NUMBER, p_ZONE IN VARCHAR2) RETURN NUMBER IS
	v_BEGIN_DATE DATE;
	v_END_DATE DATE;
	v_RET NUMBER;
	v_ZONE_ID NUMBER;
	BEGIN
		UT.CUT_DATE_RANGE(p_DATE,p_DATE,'EDT',v_BEGIN_DATE,v_END_DATE);

		SELECT SERVICE_ZONE_ID
		INTO v_ZONE_ID
		FROM SERVICE_ZONE
		WHERE (UPPER(SERVICE_ZONE_ALIAS) = UPPER(p_ZONE)
				OR UPPER(SERVICE_ZONE_ALIAS) = UPPER(p_ZONE)||' ZONE')
			AND ROWNUM = 1;

		SELECT MAX(AMOUNT)
		INTO v_RET
		FROM (SELECT SUM(AMOUNT) "AMOUNT",
					SCHEDULE_DATE
				FROM IT_SCHEDULE A,
					INTERCHANGE_TRANSACTION B,
					IT_COMMODITY C
				WHERE B.CONTRACT_ID = p_CONTRACT_ID
					AND B.BEGIN_DATE <= p_DATE
					AND B.END_DATE >= p_DATE
					AND B.TRANSACTION_TYPE = 'Load'
					AND B.ZOD_ID = v_ZONE_ID
					AND C.COMMODITY_ID = B.COMMODITY_ID
					AND C.COMMODITY_TYPE = 'Energy'
					AND C.MARKET_TYPE = MM_PJM_UTIL.g_REALTIME
					AND A.TRANSACTION_ID = B.TRANSACTION_ID
					AND A.SCHEDULE_TYPE = p_STATEMENT_TYPE
					AND A.SCHEDULE_STATE = 1
					AND A.SCHEDULE_DATE BETWEEN v_BEGIN_DATE AND v_END_DATE
					AND A.AS_OF_DATE = (SELECT MAX(AS_OF_DATE)
										FROM IT_SCHEDULE
										WHERE TRANSACTION_ID = A.TRANSACTION_ID
											AND SCHEDULE_TYPE = A.SCHEDULE_TYPE
											AND SCHEDULE_STATE = A.SCHEDULE_STATE
											AND SCHEDULE_DATE = A.SCHEDULE_DATE
											AND AS_OF_DATE <= SYSDATE)
				GROUP BY SCHEDULE_DATE);
		RETURN NVL(v_RET,0);
	EXCEPTION
		WHEN OTHERS THEN
			RETURN 0;
	END NITS_PEAK_DEMAND;

	/*********************************************************************************
		Returns the SUM of the daily peaks for the month.
      ************************************************************************/

FUNCTION SUM_PEAK_DEMAND
(
p_CUT_BEGIN_DATE IN DATE,
p_CUT_END_DATE IN DATE,
p_STATEMENT_TYPE IN NUMBER,
p_CONTRACT_ID IN NUMBER,
p_ZONE IN VARCHAR2
) RETURN NUMBER IS

v_END_DATE DATE;
v_ZONE_ID NUMBER;
v_DATE DATE;
v_TOTAL NUMBER := 0;

CURSOR c_DAILY_MAX(v_DATE IN DATE, v_END_DATE IN DATE, v_CONTRACT IN NUMBER, v_ZONE IN NUMBER,
	v_STATEMENT_TYPE IN NUMBER ) IS
    SELECT MAX(A.AMOUNT) "PEAK"
    FROM 	IT_SCHEDULE A,
    INTERCHANGE_TRANSACTION B,
    IT_COMMODITY C
    WHERE B.CONTRACT_ID = p_CONTRACT_ID
    AND B.TRANSACTION_TYPE = 'Load'
                AND b.POD_ID = v_ZONE
    AND C.COMMODITY_ID = B.COMMODITY_ID
    AND C.COMMODITY_TYPE = 'Energy'
    AND C.MARKET_TYPE = MM_PJM_UTIL.g_REALTIME
    AND A.TRANSACTION_ID = B.TRANSACTION_ID
    AND A.SCHEDULE_TYPE = v_STATEMENT_TYPE
    AND A.SCHEDULE_STATE = ga.INTERNAL_STATE
    AND A.SCHEDULE_DATE BETWEEN v_DATE AND v_END_DATE
    AND A.AS_OF_DATE = (SELECT MAX(AS_OF_DATE)
    		FROM IT_SCHEDULE
    		WHERE TRANSACTION_ID = A.TRANSACTION_ID
    			AND SCHEDULE_TYPE = A.SCHEDULE_TYPE
    			AND SCHEDULE_STATE = A.SCHEDULE_STATE
    			AND SCHEDULE_DATE = A.SCHEDULE_DATE
    			AND AS_OF_DATE <= SYSDATE);

BEGIN

    SELECT SERVICE_POINT_ID
    INTO v_ZONE_ID
    FROM SERVICE_POINT S, PJM_EMKT_PNODES P
    WHERE S.EXTERNAL_IDENTIFIER = TO_CHAR(P.PNODEID)
    AND p.NODETYPE = 'Zone'
    AND S.SERVICE_POINT_ALIAS = p_ZONE;

	v_DATE := p_CUT_BEGIN_DATE;
    WHILE v_DATE < p_CUT_END_DATE LOOP
  		FOR v_DAILY_MAX IN c_DAILY_MAX(v_DATE,v_DATE+1,p_CONTRACT_ID,v_ZONE_ID,p_STATEMENT_TYPE) LOOP
    		IF v_DAILY_MAX.PEAK IS NOT NULL THEN
        		v_TOTAL := v_TOTAL + v_DAILY_MAX.PEAK;
          	END IF;
            v_DATE := v_DATE + 1;
    	END LOOP;
    END LOOP;

	RETURN v_TOTAL;

EXCEPTION
	WHEN OTHERS THEN
    	RETURN 0;
END SUM_PEAK_DEMAND;

	/*********************************************************************************
		Returns the SUM of the daily peak IMPORTS for the month for PJM
        zone (Looks for transactions where the POD is of type Interface.)
	************************************************************************/

FUNCTION SUM_PEAK_IMPORTS_PJM
(
p_CUT_BEGIN_DATE IN DATE,
p_CUT_END_DATE IN DATE,
p_STATEMENT_TYPE IN NUMBER,
p_CONTRACT_ID IN NUMBER
) RETURN NUMBER IS

v_END_DATE DATE;
v_DATE DATE;
v_TOTAL NUMBER := 0;

CURSOR c_DAILY_MAX(v_DATE IN DATE, v_END_DATE IN DATE, v_CONTRACT IN NUMBER,
	v_STATEMENT_TYPE IN NUMBER ) IS
    SELECT MAX(A.AMOUNT) "PEAK"
    FROM 	IT_SCHEDULE A,
    INTERCHANGE_TRANSACTION B,
    IT_COMMODITY C,
    PJM_EMKT_PNODES P,
    SERVICE_POINT S
    WHERE B.CONTRACT_ID = p_CONTRACT_ID
    AND B.TRANSACTION_TYPE = 'Purchase'
    AND B.POD_ID = S.SERVICE_POINT_ID
    AND S.EXTERNAL_IDENTIFIER = TO_CHAR(P.PNODEID)
    AND P.NODETYPE = 'Interface'
    AND B.IS_IMPORT_EXPORT = 1
    AND C.COMMODITY_ID = B.COMMODITY_ID
    AND C.COMMODITY_TYPE = 'Energy'
    AND C.MARKET_TYPE = MM_PJM_UTIL.g_REALTIME
    AND A.TRANSACTION_ID = B.TRANSACTION_ID
    AND A.SCHEDULE_TYPE = v_STATEMENT_TYPE
    AND A.SCHEDULE_STATE = ga.INTERNAL_STATE
    AND A.SCHEDULE_DATE BETWEEN v_DATE AND v_END_DATE
    AND A.AS_OF_DATE = (SELECT MAX(AS_OF_DATE)
    		FROM IT_SCHEDULE
    		WHERE TRANSACTION_ID = A.TRANSACTION_ID
    			AND SCHEDULE_TYPE = A.SCHEDULE_TYPE
    			AND SCHEDULE_STATE = A.SCHEDULE_STATE
    			AND SCHEDULE_DATE = A.SCHEDULE_DATE
    			AND AS_OF_DATE <= SYSDATE);

BEGIN


   v_DATE := p_CUT_BEGIN_DATE;

    WHILE v_DATE < p_CUT_END_DATE LOOP
  		FOR v_DAILY_MAX IN c_DAILY_MAX(v_DATE,v_DATE+1,p_CONTRACT_ID,p_STATEMENT_TYPE) LOOP
    		IF v_DAILY_MAX.PEAK IS NOT NULL THEN
        		v_TOTAL := v_TOTAL + v_DAILY_MAX.PEAK;
          	END IF;
            v_DATE := v_DATE + 1;
    	END LOOP;
    END LOOP;

	RETURN v_TOTAL;

EXCEPTION
	WHEN OTHERS THEN
    	RETURN 0;
END SUM_PEAK_IMPORTS_PJM;

	/*********************************************************************************
		Returns the SUM of the daily peak IMPORTS for the month, for the specified zone.
	************************************************************************/

FUNCTION SUM_PEAK_IMPORTS
(
p_CUT_BEGIN_DATE IN DATE,
p_CUT_END_DATE IN DATE,
p_STATEMENT_TYPE IN NUMBER,
p_CONTRACT_ID IN NUMBER,
p_ZONE IN VARCHAR2
) RETURN NUMBER IS

v_END_DATE DATE;
v_ZONE_ID NUMBER;
v_DATE DATE;
v_TOTAL NUMBER := 0;

CURSOR c_DAILY_MAX(v_DATE IN DATE, v_END_DATE IN DATE, v_CONTRACT IN NUMBER, v_ZONE IN NUMBER,
	v_STATEMENT_TYPE IN NUMBER ) IS
    SELECT MAX(A.AMOUNT) "PEAK"
    FROM 	IT_SCHEDULE A,
    INTERCHANGE_TRANSACTION B,
    IT_COMMODITY C
    WHERE B.CONTRACT_ID = p_CONTRACT_ID
    AND B.TRANSACTION_TYPE = 'Purchase'
    AND B.POD_ID = v_ZONE  --use pod_id as zone due to how AMP transactions are
    AND B.IS_IMPORT_EXPORT = 1
    AND C.COMMODITY_ID = B.COMMODITY_ID
    AND C.COMMODITY_TYPE = 'Energy'
    AND C.MARKET_TYPE = MM_PJM_UTIL.g_REALTIME
    AND A.TRANSACTION_ID = B.TRANSACTION_ID
    AND A.SCHEDULE_TYPE = v_STATEMENT_TYPE
    AND A.SCHEDULE_STATE = ga.INTERNAL_STATE
    AND A.SCHEDULE_DATE BETWEEN v_DATE AND v_END_DATE
    AND A.AS_OF_DATE = (SELECT MAX(AS_OF_DATE)
    		FROM IT_SCHEDULE
    		WHERE TRANSACTION_ID = A.TRANSACTION_ID
    			AND SCHEDULE_TYPE = A.SCHEDULE_TYPE
    			AND SCHEDULE_STATE = A.SCHEDULE_STATE
    			AND SCHEDULE_DATE = A.SCHEDULE_DATE
    			AND AS_OF_DATE <= SYSDATE);

BEGIN

    SELECT SERVICE_POINT_ID
    INTO v_ZONE_ID
    FROM SERVICE_POINT S, PJM_EMKT_PNODES P
    WHERE S.EXTERNAL_IDENTIFIER = TO_CHAR(P.PNODEID)
    AND p.NODETYPE = 'Zone'
    AND S.SERVICE_POINT_ALIAS = p_ZONE;

    v_DATE := p_CUT_BEGIN_DATE;

    WHILE v_DATE < p_CUT_END_DATE LOOP
  		FOR v_DAILY_MAX IN c_DAILY_MAX(v_DATE,v_DATE+1,p_CONTRACT_ID,v_ZONE_ID,p_STATEMENT_TYPE) LOOP
    		IF v_DAILY_MAX.PEAK IS NOT NULL THEN
        		v_TOTAL := v_TOTAL + v_DAILY_MAX.PEAK;
          	END IF;
            v_DATE := v_DATE + 1;
    	END LOOP;
    END LOOP;

	RETURN v_TOTAL;

EXCEPTION
	WHEN OTHERS THEN
    	RETURN 0;
END SUM_PEAK_IMPORTS;

  	/*********************************************************************************
		Returns the AVERAGE of the daily peaks for the month. used by daily charge,
        explain
      ************************************************************************/
FUNCTION AVG_MONTHLY_PEAK_DEMAND
	(
    p_CUT_DATE IN DATE,
    p_STATEMENT_TYPE IN NUMBER,
    p_CONTRACT_ID IN NUMBER,
    p_ZONE IN VARCHAR2
    ) RETURN NUMBER IS

v_END_DATE DATE;
v_ZONE_ID NUMBER;
v_DATE DATE;
v_TOTAL NUMBER := 0;
v_COUNT NUMBER := 0 ;
v_AVERAGE NUMBER :=0;


CURSOR c_DAILY_MAX(v_DATE IN DATE, v_END_DATE IN DATE, v_CONTRACT IN NUMBER, v_ZONE IN NUMBER,
	v_STATEMENT_TYPE IN NUMBER ) IS
    SELECT MAX(A.AMOUNT) "PEAK"
    FROM 	IT_SCHEDULE A,
    INTERCHANGE_TRANSACTION B,
    IT_COMMODITY C
    WHERE B.CONTRACT_ID = p_CONTRACT_ID
    AND B.TRANSACTION_TYPE = 'Load'
                AND b.POD_ID = v_ZONE
    AND C.COMMODITY_ID = B.COMMODITY_ID
    AND C.COMMODITY_TYPE = 'Energy'
    AND C.MARKET_TYPE = MM_PJM_UTIL.g_REALTIME
    AND A.TRANSACTION_ID = B.TRANSACTION_ID
    AND A.SCHEDULE_TYPE = v_STATEMENT_TYPE
    AND A.SCHEDULE_STATE = ga.INTERNAL_STATE
    AND TRUNC(A.SCHEDULE_DATE) BETWEEN v_DATE AND v_END_DATE
    AND A.AS_OF_DATE = (SELECT MAX(AS_OF_DATE)
    		FROM IT_SCHEDULE
    		WHERE TRANSACTION_ID = A.TRANSACTION_ID
    			AND SCHEDULE_TYPE = A.SCHEDULE_TYPE
    			AND SCHEDULE_STATE = A.SCHEDULE_STATE
    			AND SCHEDULE_DATE = A.SCHEDULE_DATE
    			AND AS_OF_DATE <= SYSDATE);


BEGIN

    SELECT SERVICE_POINT_ID
    INTO v_ZONE_ID
    FROM SERVICE_POINT S, PJM_EMKT_PNODES P
    WHERE S.EXTERNAL_IDENTIFIER = TO_CHAR(P.PNODEID)
    AND p.NODETYPE = 'Zone'
    AND S.SERVICE_POINT_ALIAS = p_ZONE;

    v_DATE := TRUNC(p_CUT_DATE, 'MM');

    WHILE v_DATE < TRUNC(p_CUT_DATE, 'MM') + NUMTOYMINTERVAL(1, 'MONTH') LOOP
  		FOR v_DAILY_MAX IN c_DAILY_MAX(v_DATE,v_DATE,p_CONTRACT_ID,v_ZONE_ID,p_STATEMENT_TYPE) LOOP
    		IF v_DAILY_MAX.PEAK IS NOT NULL THEN
        		v_TOTAL := v_TOTAL + v_DAILY_MAX.PEAK;
            	v_COUNT := v_COUNT + 1;
          	END IF;
            v_DATE := v_DATE +1;
    	END LOOP;
    END LOOP;

    IF v_COUNT > 0 THEN
    	v_AVERAGE := v_TOTAL/v_COUNT;
    END IF;

	RETURN v_AVERAGE;

EXCEPTION
	WHEN OTHERS THEN
    	RETURN 0;

END AVG_MONTHLY_PEAK_DEMAND;
---------------------------------------------------------------------------------------
	/*********************************************************************************
		Returns the SUM of the daily AVERAGE Point-to-Point Energy Reservations
         for the month.
	************************************************************************/
FUNCTION AVG_P2P_ENERGY_RESV
	(
	p_CUT_BEGIN_DATE IN DATE,
	p_CUT_END_DATE IN DATE,
	p_STATEMENT_TYPE IN NUMBER,
	p_CONTRACT_ID IN NUMBER,
	p_ZONE IN VARCHAR2
	) RETURN NUMBER IS

v_END_DATE DATE;
v_ZONE_ID NUMBER;
v_DATE DATE;
v_TOTAL NUMBER := 0;

CURSOR c_DAILY_MAX(v_DATE IN DATE, v_END_DATE IN DATE, v_CONTRACT IN NUMBER, v_ZONE IN NUMBER,
	v_STATEMENT_TYPE IN NUMBER ) IS
    SELECT AVG(A.AMOUNT) "AVG"
    FROM IT_SCHEDULE A,
    INTERCHANGE_TRANSACTION B,
    IT_COMMODITY C
    WHERE B.CONTRACT_ID = p_CONTRACT_ID
    AND B.TRANSACTION_TYPE IN ('Purchase','Sale')
    AND B.POD_ID = v_ZONE  --use pod_id as zone due to how AMP transactions are
    AND C.COMMODITY_ID = B.COMMODITY_ID
    AND C.COMMODITY_NAME = 'Transmission'
    AND B.AGREEMENT_TYPE = 'Oasis'
    AND A.TRANSACTION_ID = B.TRANSACTION_ID
    AND A.SCHEDULE_TYPE = v_STATEMENT_TYPE
    AND A.SCHEDULE_STATE = ga.INTERNAL_STATE
    AND A.SCHEDULE_DATE BETWEEN v_DATE AND v_END_DATE
    AND A.AS_OF_DATE = (SELECT MAX(AS_OF_DATE)
    		FROM IT_SCHEDULE
    		WHERE TRANSACTION_ID = A.TRANSACTION_ID
    			AND SCHEDULE_TYPE = A.SCHEDULE_TYPE
    			AND SCHEDULE_STATE = A.SCHEDULE_STATE
    			AND SCHEDULE_DATE = A.SCHEDULE_DATE
    			AND AS_OF_DATE <= SYSDATE);

BEGIN

    SELECT SERVICE_POINT_ID
    INTO v_ZONE_ID
    FROM SERVICE_POINT S, PJM_EMKT_PNODES P
    WHERE S.EXTERNAL_IDENTIFIER = TO_CHAR(P.PNODEID)
    AND p.NODETYPE = 'Zone'
    AND S.SERVICE_POINT_ALIAS = p_ZONE;

   	v_DATE := p_CUT_BEGIN_DATE;

    WHILE v_DATE < p_CUT_END_DATE LOOP
  		FOR v_DAILY_MAX IN c_DAILY_MAX(v_DATE,v_DATE+1,p_CONTRACT_ID,v_ZONE_ID,p_STATEMENT_TYPE) LOOP
    		IF v_DAILY_MAX.AVG IS NOT NULL THEN
        		v_TOTAL := v_TOTAL + v_DAILY_MAX.AVG;
          	END IF;
            v_DATE := v_DATE + 1;
    	END LOOP;
    END LOOP;

	RETURN v_TOTAL;

EXCEPTION
	WHEN OTHERS THEN
    	RETURN 0;

END AVG_P2P_ENERGY_RESV;
---------------------------------------------------------------------------------------
	/*********************************************************************************
		Returns the SUM of the daily AVERAGE Point-to-Point Energy Reservations
         for the month where the POD is the border of PJM. Looks for transactions
         where the POD is of type Interface.
	************************************************************************/
FUNCTION AVG_P2P_ENERGY_RESV_PJM
	(
	p_CUT_BEGIN_DATE IN DATE,
	p_CUT_END_DATE IN DATE,
	p_STATEMENT_TYPE IN NUMBER,
	p_CONTRACT_ID IN NUMBER
	) RETURN NUMBER IS

v_END_DATE DATE;
v_DATE DATE;
v_TOTAL NUMBER := 0;

CURSOR c_DAILY_MAX(v_DATE IN DATE, v_END_DATE IN DATE, v_CONTRACT IN NUMBER,
	v_STATEMENT_TYPE IN NUMBER ) IS
    SELECT AVG(AMOUNT) "AVG"
    FROM IT_SCHEDULE A,
    INTERCHANGE_TRANSACTION B,
    IT_COMMODITY C,
    PJM_EMKT_PNODES P,
    SERVICE_POINT S
    WHERE B.CONTRACT_ID = p_CONTRACT_ID
    AND B.TRANSACTION_TYPE IN ('Purchase','Sale')
    AND B.POD_ID = S.SERVICE_POINT_ID
    AND S.EXTERNAL_IDENTIFIER = TO_CHAR(P.PNODEID)
    AND P.NODETYPE = 'Interface'
    AND C.COMMODITY_ID = B.COMMODITY_ID
    AND C.COMMODITY_NAME = 'Transmission'
    AND B.AGREEMENT_TYPE = 'Oasis'
    AND A.TRANSACTION_ID = B.TRANSACTION_ID
    AND A.SCHEDULE_TYPE = v_STATEMENT_TYPE
    AND A.SCHEDULE_STATE = ga.INTERNAL_STATE
    AND A.SCHEDULE_DATE BETWEEN v_DATE AND v_END_DATE
    AND A.AS_OF_DATE = (SELECT MAX(AS_OF_DATE)
    		FROM IT_SCHEDULE
    		WHERE TRANSACTION_ID = A.TRANSACTION_ID
    			AND SCHEDULE_TYPE = A.SCHEDULE_TYPE
    			AND SCHEDULE_STATE = A.SCHEDULE_STATE
    			AND SCHEDULE_DATE = A.SCHEDULE_DATE
    			AND AS_OF_DATE <= SYSDATE);

BEGIN

    v_DATE := p_CUT_BEGIN_DATE;

    WHILE v_DATE < p_CUT_END_DATE LOOP
  		FOR v_DAILY_MAX IN c_DAILY_MAX(v_DATE,v_DATE+1,p_CONTRACT_ID,p_STATEMENT_TYPE) LOOP
    		IF v_DAILY_MAX.AVG IS NOT NULL THEN
        		v_TOTAL := v_TOTAL + v_DAILY_MAX.AVG;
          	END IF;
            v_DATE := v_DATE + 1;
    	END LOOP;
    END LOOP;

	RETURN v_TOTAL;

EXCEPTION
	WHEN OTHERS THEN
    	RETURN 0;

END AVG_P2P_ENERGY_RESV_PJM;
---------------------------------------------------------------------------------------
FUNCTION POINT_TO_POINT_USAGE
	(
	p_CUT_BEGIN_DATE IN DATE,
    p_CUT_END_DATE IN DATE,
    p_STATEMENT_TYPE IN NUMBER,
    p_CONTRACT_ID IN NUMBER
    ) RETURN NUMBER IS

v_RET NUMBER := 0;

BEGIN

    SELECT SUM(A.AMOUNT)
    INTO v_RET
    FROM IT_SCHEDULE A,
    INTERCHANGE_TRANSACTION B,
    IT_COMMODITY C
    WHERE B.CONTRACT_ID = p_CONTRACT_ID
    AND B.TRANSACTION_TYPE = 'Purchase'
    AND B.AGREEMENT_TYPE NOT LIKE 'FTR%'
    AND C.COMMODITY_ID = B.COMMODITY_ID
    AND C.COMMODITY_TYPE = 'Transmission'
    AND A.TRANSACTION_ID = B.TRANSACTION_ID
    AND A.SCHEDULE_TYPE = p_STATEMENT_TYPE
    AND A.SCHEDULE_STATE = 1
    AND A.SCHEDULE_DATE BETWEEN p_CUT_BEGIN_DATE AND p_CUT_END_DATE
    AND A.AS_OF_DATE = (SELECT MAX(AS_OF_DATE)
    		FROM IT_SCHEDULE
    		WHERE TRANSACTION_ID = A.TRANSACTION_ID
    			AND SCHEDULE_TYPE = A.SCHEDULE_TYPE
    			AND SCHEDULE_STATE = A.SCHEDULE_STATE
    			AND SCHEDULE_DATE = A.SCHEDULE_DATE
    			AND AS_OF_DATE <= SYSDATE);

	RETURN NVL(v_RET,0);

EXCEPTION
	WHEN OTHERS THEN
    	RETURN 0;

END POINT_TO_POINT_USAGE;

	/*********************************************************************************
    Returns the Monthly Demand for a particular zone in PJM - which is used for billing
	Transmission Owner SSC&D charges.
	*********************************************************************************/
FUNCTION TOCC_DEMAND
	(
    p_CUT_BEGIN_DATE IN DATE,
    p_CUT_END_DATE IN DATE,
	p_STATEMENT_TYPE IN NUMBER,
	p_CONTRACT_ID IN NUMBER,
	p_ZONE IN VARCHAR2,
    p_TXN_TYPE IN VARCHAR2
	) RETURN NUMBER IS

    v_RET NUMBER;
    v_ZONE_ID NUMBER;
v_USE_SALES BINARY_INTEGER;
v_TXN_TYPE VARCHAR2(8);

BEGIN
    v_USE_SALES := USE_RT_SALES(p_CONTRACT_ID);

    IF v_USE_SALES = 1 AND p_TXN_TYPE = 'Load' THEN
        v_TXN_TYPE := 'Sale';
    ELSE
        v_TXN_TYPE := p_TXN_TYPE;
   END IF;

	SELECT SERVICE_POINT_ID
	INTO v_ZONE_ID
	FROM SERVICE_POINT S, PJM_EMKT_PNODES P
	WHERE S.EXTERNAL_IDENTIFIER = TO_CHAR(P.PNODEID)
	AND p.NODETYPE = 'Zone'
	AND S.SERVICE_POINT_ALIAS = p_ZONE;

	SELECT SUM(AMOUNT)
	INTO v_RET
	FROM IT_SCHEDULE A,
			INTERCHANGE_TRANSACTION B,
			IT_COMMODITY C
	WHERE B.CONTRACT_ID = p_CONTRACT_ID
	AND B.TRANSACTION_TYPE = v_TXN_TYPE
	--AND B.ZOD_ID = v_ZONE_ID
	AND B.POD_ID = v_ZONE_ID
	AND C.COMMODITY_ID = B.COMMODITY_ID
	AND C.COMMODITY_TYPE = 'Energy'
	AND C.MARKET_TYPE = MM_PJM_UTIL.g_REALTIME
	AND A.TRANSACTION_ID = B.TRANSACTION_ID
	AND A.SCHEDULE_TYPE = p_STATEMENT_TYPE
	AND A.SCHEDULE_STATE = 1
	AND A.SCHEDULE_DATE BETWEEN p_CUT_BEGIN_DATE
    AND p_CUT_END_DATE
	AND A.AS_OF_DATE = (SELECT MAX(AS_OF_DATE)
						FROM IT_SCHEDULE
						WHERE TRANSACTION_ID = A.TRANSACTION_ID
						AND SCHEDULE_TYPE = A.SCHEDULE_TYPE
						AND SCHEDULE_STATE = A.SCHEDULE_STATE
						AND SCHEDULE_DATE = A.SCHEDULE_DATE
						AND AS_OF_DATE <= SYSDATE);
	RETURN NVL(v_RET,0);
EXCEPTION
	WHEN OTHERS THEN
		RETURN 0;
END TOCC_DEMAND;

	/*********************************************************************************
    Returns the RT Load for MAAC zones for the given contract.
	*********************************************************************************/

FUNCTION RT_LOAD_FOR_MAAC
	(
    p_CUT_BEGIN_DATE IN DATE,
    p_CUT_END_DATE IN DATE,
	p_STATEMENT_TYPE IN NUMBER,
	p_CONTRACT_ID IN NUMBER
	) RETURN NUMBER IS

    v_SUM NUMBER := 0;
    v_TOTAL NUMBER := 0;

CURSOR c_ZONES IS
	SELECT DISTINCT S.SERVICE_POINT_ID "ZONE"
	FROM INTERCHANGE_TRANSACTION I, SERVICE_POINT S, PJM_EMKT_PNODES P
	WHERE I.TRANSACTION_TYPE = 'Load'
	AND I.COMMODITY_ID = (SELECT COMMODITY_ID FROM IT_COMMODITY WHERE UPPER(COMMODITY_NAME) = 'REALTIME ENERGY')
	AND I.CONTRACT_ID = p_CONTRACT_ID AND I.POD_ID = S.SERVICE_POINT_ID
	AND S.EXTERNAL_IDENTIFIER = P.PNODEID AND UPPER(P.NODETYPE) = 'ZONE';


BEGIN

	FOR v_ZONE IN c_ZONES LOOP

    	SELECT SUM(AMOUNT)
        INTO v_SUM
    	FROM IT_SCHEDULE A,
    			INTERCHANGE_TRANSACTION B,
    			IT_COMMODITY C
    	WHERE B.CONTRACT_ID = p_CONTRACT_ID
    	AND B.TRANSACTION_TYPE = 'Load'
    	AND B.POD_ID = v_ZONE.ZONE
        -- only consider MAAC Control Zones
        AND v_ZONE.ZONE IN (SELECT SERVICE_POINT_ID FROM SERVICE_POINT
    				WHERE SERVICE_POINT_ALIAS IN('PENELEC', 'PPL',
    				'ME','JCPL','PSEG','AEC','PECO','BGE','DPL',
    				'PEPCO', 'RE'))
    	AND C.COMMODITY_ID = B.COMMODITY_ID
    	AND C.COMMODITY_TYPE = 'Energy'
    	AND C.MARKET_TYPE = MM_PJM_UTIL.g_REALTIME
    	AND A.TRANSACTION_ID = B.TRANSACTION_ID
    	AND A.SCHEDULE_TYPE = p_STATEMENT_TYPE
    	AND A.SCHEDULE_STATE = 1
    	AND A.SCHEDULE_DATE BETWEEN p_CUT_BEGIN_DATE
        AND p_CUT_END_DATE
    	AND A.AS_OF_DATE = (SELECT MAX(AS_OF_DATE)
    						FROM IT_SCHEDULE
    						WHERE TRANSACTION_ID = A.TRANSACTION_ID
    						AND SCHEDULE_TYPE = A.SCHEDULE_TYPE
    						AND SCHEDULE_STATE = A.SCHEDULE_STATE
    						AND SCHEDULE_DATE = A.SCHEDULE_DATE
    						AND AS_OF_DATE <= SYSDATE);

		v_TOTAL := v_TOTAL +  NVL(v_SUM,0);
    END LOOP;

	RETURN NVL(v_TOTAL,0);
EXCEPTION
	WHEN OTHERS THEN
		RETURN 0;
END RT_LOAD_FOR_MAAC;

	/*********************************************************************************
    Returns the Daily Demand for a particular area in PJM - which is used for billing
	Synchronous Condensing charges. The charge definition
    is taken from the Operating Agreement Accounting p.38
	*********************************************************************************/
	FUNCTION SYNC_CONDENS_DEMAND(p_DATE IN DATE, p_STATEMENT_TYPE IN NUMBER, p_CONTRACT_ID IN NUMBER, p_AREA IN VARCHAR2) RETURN NUMBER IS
	v_BEGIN_DATE DATE;
	v_END_DATE DATE;
	v_RET NUMBER;
	BEGIN
		UT.CUT_DATE_RANGE(p_DATE,p_DATE,'EDT',v_BEGIN_DATE,v_END_DATE);

		SELECT SUM(AMOUNT)
		INTO v_RET
		FROM IT_SCHEDULE A,
			INTERCHANGE_TRANSACTION B,
			IT_COMMODITY C
		WHERE B.CONTRACT_ID = p_CONTRACT_ID
			AND B.BEGIN_DATE <= p_DATE
			AND B.END_DATE >= p_DATE
			AND B.TRANSACTION_TYPE = 'Load'
			AND B.POD_ID IN (SELECT SERVICE_POINT_ID FROM SERVICE_POINT
							WHERE SERVICE_AREA_ID = (SELECT SERVICE_AREA_ID FROM SERVICE_AREA
													WHERE (UPPER(SERVICE_AREA_ALIAS) = UPPER(p_AREA)
														OR UPPER(SERVICE_AREA_ALIAS) = UPPER(p_AREA)||' AREA')
														AND ROWNUM = 1))
			AND C.COMMODITY_ID = B.COMMODITY_ID
			AND C.COMMODITY_TYPE = 'Energy'
			AND C.MARKET_TYPE = MM_PJM_UTIL.g_REALTIME
			AND A.TRANSACTION_ID = B.TRANSACTION_ID
			AND A.SCHEDULE_TYPE = p_STATEMENT_TYPE
			AND A.SCHEDULE_STATE = 1
			AND A.SCHEDULE_DATE BETWEEN v_BEGIN_DATE AND v_END_DATE
			AND A.AS_OF_DATE = (SELECT MAX(AS_OF_DATE)
								FROM IT_SCHEDULE
								WHERE TRANSACTION_ID = A.TRANSACTION_ID
									AND SCHEDULE_TYPE = A.SCHEDULE_TYPE
									AND SCHEDULE_STATE = A.SCHEDULE_STATE
									AND SCHEDULE_DATE = A.SCHEDULE_DATE
									AND AS_OF_DATE <= SYSDATE);
		RETURN NVL(v_RET,0);
	EXCEPTION
		WHEN OTHERS THEN
			RETURN 0;
	END SYNC_CONDENS_DEMAND;

	/*********************************************************************************
    Returns the credit amount for Black Start Service, which is 1/12th of the annual
    black start revenue requirement of each generator (this will typically be zero).
    The credit definition is taken from the OATT Manual, p. 41, and from the OATT,
    p 284-285 (242-243 in the TOC).
  *********************************************************************************/
	FUNCTION BLACK_START_CREDITS(p_DATE IN DATE, p_CONTRACT_ID IN NUMBER)
		RETURN NUMBER IS
		l_BLACK_START_CREDITS NUMBER;
	BEGIN
		SELECT SUM(TEA.ATTRIBUTE_VAL / 12) AS BLACK_START_CREDITS
			INTO l_BLACK_START_CREDITS
			FROM INTERCHANGE_TRANSACTION   ITX,
					 SUPPLY_RESOURCE           SR,
					 TEMPORAL_ENTITY_ATTRIBUTE TEA
		 WHERE ITX.CONTRACT_ID = p_CONTRACT_ID
			 AND TEA.OWNER_ENTITY_ID = SR.RESOURCE_ID
			 AND TEA.BEGIN_DATE <= TRUNC(p_DATE, 'MM')
			 AND (TEA.END_DATE >= TRUNC(p_DATE, 'MM') + 1 OR TEA.END_DATE IS NULL)
			 AND TEA.ATTRIBUTE_ID =
					 (SELECT EA.ATTRIBUTE_ID
							FROM ENTITY_ATTRIBUTE EA
						 WHERE EA.ATTRIBUTE_NAME = 'BlackStartAnnualRevReq')
		 GROUP BY TEA.ATTRIBUTE_VAL;
		RETURN l_BLACK_START_CREDITS;
	END BLACK_START_CREDITS;

	/*********************************************************************************
    Returns the number of hours for any FTR obligation bid submitted to any
    FTR auction. Used in the calculation of the FTR Admin Charge component.
  *********************************************************************************/
	FUNCTION FTR_BID_HOURS(p_DATE IN DATE, p_CONTRACT_ID IN NUMBER) RETURN NUMBER IS
		l_BID_HOURS NUMBER;
	BEGIN
		SELECT COUNT(BO_STATUS.SUBMIT_STATUS)
			INTO l_BID_HOURS
			FROM BID_OFFER_STATUS BO_STATUS, INTERCHANGE_TRANSACTION ITX
		 WHERE BO_STATUS.SUBMIT_DATE >= TRUNC(p_DATE, 'MONTH')
			 AND BO_STATUS.SUBMIT_DATE < ADD_MONTHS(TRUNC(p_DATE, 'MONTH'), 1)
			 AND BO_STATUS.SUBMIT_STATUS IS NOT NULL
			 AND BO_STATUS.SUBMIT_STATUS != 'Pending'
			 AND BO_STATUS.TRANSACTION_ID = ITX.TRANSACTION_ID
			 AND ITX.CONTRACT_ID = p_CONTRACT_ID
			 AND ITX.TRANSACTION_TYPE = 'Purchase'
			 AND ITX.COMMODITY_ID =
					 (SELECT ITC.COMMODITY_ID
							FROM IT_COMMODITY ITC
						 WHERE ITC.COMMODITY_NAME = 'Transmission');

		RETURN l_BID_HOURS;
	END FTR_BID_HOURS;

	/*********************************************************************************
    Returns the FTR auction charges or credits for the current month. FTR transactions
    have a commodity of Transmission, a transaction type of Purchase (for charges)
    or Sale (for credits), and an Agreement Type of FTR Obligation or FTR Option.

    For either credits or charges, the amount is simply the product of the
    transaction's amount and price.
  *********************************************************************************/
	FUNCTION GET_FTR_CHARGES(p_DATE         IN DATE,
													 p_CONTRACT_ID  IN NUMBER,
													 p_CALC_CHARGES IN BOOLEAN) RETURN NUMBER IS
		l_DATE             DATE := TRUNC(p_DATE, 'MM');
		l_TOTAL_CHARGE     NUMBER;
		l_TRANSACTION_TYPE INTERCHANGE_TRANSACTION.TRANSACTION_TYPE%TYPE;
	BEGIN
		IF p_CALC_CHARGES = TRUE THEN
			l_TRANSACTION_TYPE := 'Purchase';
		ELSE
			l_TRANSACTION_TYPE := 'Sale';
		END IF;

		SELECT SUM(ITS.AMOUNT * ITS.PRICE)
			INTO l_TOTAL_CHARGE
			FROM IT_SCHEDULE ITS, INTERCHANGE_TRANSACTION ITX, IT_STATUS
		 WHERE ITX.CONTRACT_ID = p_CONTRACT_ID
			 AND ITS.TRANSACTION_ID = ITX.TRANSACTION_ID
			 AND ITS.TRANSACTION_ID = IT_STATUS.TRANSACTION_ID
			 AND IT_STATUS.TRANSACTION_IS_ACTIVE = 1
			 AND ITX.TRANSACTION_TYPE = l_TRANSACTION_TYPE
			 AND ITX.AGREEMENT_TYPE LIKE 'FTR%'
			 AND ITS.SCHEDULE_DATE BETWEEN l_DATE AND ADD_MONTHS(l_DATE, 1);
		RETURN l_TOTAL_CHARGE;
	END GET_FTR_CHARGES;

	FUNCTION FTR_AUCTION_CHARGES(p_DATE IN DATE, p_CONTRACT_ID IN NUMBER)
		RETURN NUMBER IS
	BEGIN
		RETURN GET_FTR_CHARGES(p_DATE, p_CONTRACT_ID, TRUE);
	END FTR_AUCTION_CHARGES;

	FUNCTION FTR_AUCTION_CREDITS(p_DATE IN DATE, p_CONTRACT_ID IN NUMBER)
		RETURN NUMBER IS
	BEGIN
		RETURN GET_FTR_CHARGES(p_DATE, p_CONTRACT_ID, FALSE);
	END FTR_AUCTION_CREDITS;
---------------------------------------------------------------------------------------------------------
FUNCTION GET_FTR_TRAIT
	(
	p_TRANSACTION_ID IN NUMBER,
	p_ATTRIBUTE IN VARCHAR2,
    p_DATE IN DATE := LOW_DATE
	) RETURN NUMBER IS
v_RET NUMBER;
BEGIN
	IF p_DATE <> LOW_DATE THEN
    	BEGIN
            SELECT ATTRIBUTE_VAL
            INTO v_RET
            FROM temporal_entity_attribute
        	WHERE OWNER_ENTITY_ID = p_TRANSACTION_ID
        	AND ATTRIBUTE_ID =
        	(SELECT ATTRIBUTE_ID FROM ENTITY_ATTRIBUTE
        	WHERE ATTRIBUTE_NAME = p_ATTRIBUTE)
            AND BEGIN_DATE = TRUNC(p_DATE);
    	EXCEPTION
    		WHEN NO_DATA_FOUND THEN
        		v_RET := 0;
    	END;
    ELSE
    	BEGIN
            SELECT ATTRIBUTE_VAL
            INTO v_RET
            FROM temporal_entity_attribute
        	WHERE OWNER_ENTITY_ID = p_TRANSACTION_ID
        	AND ATTRIBUTE_ID =
        	(SELECT ATTRIBUTE_ID FROM ENTITY_ATTRIBUTE
        	WHERE ATTRIBUTE_NAME = p_ATTRIBUTE);
    	EXCEPTION
    		WHEN NO_DATA_FOUND THEN
        		v_RET := 0;
    	END;
    END IF;

    RETURN v_RET;
END GET_FTR_TRAIT;
------------------------------------------------------------------------------------

	/*********************************************************************************
    Returns the amount of self-scheduled regulation in this hour. Self-scheduled
    regulation is defined as the offer amount in transactions of type Generation
    for commodity Regulation, where the trait value of the IsSelfScheduled resource
    trait is True (or 1, in this case).

    Used to determine the Regulation Credit amount for self-scheduled regulation.
  *********************************************************************************/
	FUNCTION RegulationAmountOffered(pContractID      IN NUMBER,
																	 pDate            IN DATE,
																	 pIsSelfScheduled IN NUMBER) RETURN NUMBER IS
		lAmtOffered NUMBER(9);
	BEGIN
		-- translation of decode: if we're looking for pool-scheduled quantity, then
		-- don't modify the quantity. If we are looking for self-scheduled, then
		-- use the value of the resource trait in that hour.
		SELECT SUM(BOS.QUANTITY *
							 decode(pIsSelfScheduled, 0, 1, NVL(BOT.TRAIT_VAL, 0)))
			INTO lAmtOffered
			FROM BID_OFFER_SET BOS,
					 INTERCHANGE_TRANSACTION ITX,
					 BID_OFFER_TRAIT BOT,
					 BID_OFFER_STATUS BO_STATUS
		 WHERE BOS.TRANSACTION_ID = ITX.TRANSACTION_ID
			 AND BOT.TRANSACTION_ID = ITX.TRANSACTION_ID
			 AND BOT.RESOURCE_TRAIT_ID = MM_PJM_UTIL.g_TG_IS_SELF_SCHEDULED
			 AND BOS.SET_NUMBER = 1
			 AND BOS.SCHEDULE_DATE = pDate
			 AND BO_STATUS.TRANSACTION_ID = ITX.TRANSACTION_ID
			 AND BO_STATUS.SCHEDULE_DATE = pDate
			 AND BO_STATUS.MARKET_STATUS = 'Accepted'
			 AND ITX.TRANSACTION_TYPE = 'Generation'
			 AND ITX.CONTRACT_ID = pContractID
			 AND ITX.SC_ID = g_PJM_SC_ID
			 AND ITX.COMMODITY_ID =
					 (SELECT C.COMMODITY_ID
							FROM IT_COMMODITY C
						 WHERE C.COMMODITY_NAME = 'Regulation');
		RETURN NVL(lAmtOffered, 0);
	END RegulationAmountOffered;

	/*********************************************************************************
    Returns the amount of regulation provided in this hour at the direction of PJM.

    Used to determine the Regulation Credit amount for pool-scheduled regulation.
  *********************************************************************************/
	FUNCTION RegulationScheduleAmount(pContractID      IN NUMBER,
																	 pDate            IN DATE) RETURN NUMBER IS
		lScheduleAmount NUMBER(9);
	BEGIN
		SELECT SUM(ITS.AMOUNT)
			INTO lScheduleAmount
			FROM INTERCHANGE_TRANSACTION ITX,
           IT_SCHEDULE ITS,
					 BID_OFFER_TRAIT BOT,
					 BID_OFFER_STATUS BO_STATUS
		 WHERE BOT.TRANSACTION_ID = ITX.TRANSACTION_ID
			 AND BOT.RESOURCE_TRAIT_ID = MM_PJM_UTIL.g_TG_IS_SELF_SCHEDULED
			 AND BOT.TRAIT_VAL = '0'
			 AND BO_STATUS.TRANSACTION_ID = ITX.TRANSACTION_ID
			 AND BO_STATUS.SCHEDULE_DATE = pDate
			 AND BO_STATUS.MARKET_STATUS = 'Accepted'
       AND ITS.TRANSACTION_ID = ITX.TRANSACTION_ID
       AND ITS.SCHEDULE_DATE = pDate
       AND ITS.SCHEDULE_STATE = 1
			 AND ITX.TRANSACTION_TYPE = 'Generation'
			 AND ITX.CONTRACT_ID = pContractID
			 AND ITX.SC_ID = g_PJM_SC_ID
			 AND ITX.COMMODITY_ID =
					 (SELECT C.COMMODITY_ID
							FROM IT_COMMODITY C
						 WHERE C.COMMODITY_NAME = 'Regulation');
		RETURN NVL(lScheduleAmount, 0);
	END RegulationScheduleAmount;

	/*********************************************************************************
    Returns the lost opportunity cost credit due to generator owners when the
    generator must increase or decrease its output to provide regulation. This cost
    is the offered price times the difference between the offered quantity and the
    actual regulation signal.

    Used to determine the Regulation Credit amount for pool-scheduled regulation.
  *********************************************************************************/
	FUNCTION LostOpportunityCost(pContractID IN NUMBER, pDate IN DATE)
		RETURN NUMBER IS
		lLostOppCost NUMBER(9);
	BEGIN
		SELECT ABS(BOS.QUANTITY - ITS.AMOUNT) * BOS.PRICE
			INTO lLostOppCost
			FROM BID_OFFER_SET BOS,
					 INTERCHANGE_TRANSACTION ITX,
           	         IT_SCHEDULE ITS,
					 BID_OFFER_TRAIT BOT,
					 BID_OFFER_STATUS BO_STATUS
		 WHERE BOS.TRANSACTION_ID = ITX.TRANSACTION_ID
			 AND BOT.TRANSACTION_ID = ITX.TRANSACTION_ID
			 AND BOT.RESOURCE_TRAIT_ID = MM_PJM_UTIL.g_TG_IS_SELF_SCHEDULED
			 AND BOT.TRAIT_VAL = '0'
			 AND BOS.SET_NUMBER = 1
			 AND BOS.SCHEDULE_DATE = pDate
			 AND BO_STATUS.TRANSACTION_ID = ITX.TRANSACTION_ID
			 AND BO_STATUS.SCHEDULE_DATE = pDate
			 AND BO_STATUS.MARKET_STATUS = 'Accepted'
       AND ITS.TRANSACTION_ID = ITX.TRANSACTION_ID
       AND ITS.SCHEDULE_DATE = pDate
       AND ITS.SCHEDULE_STATE = 1
			 AND ITX.TRANSACTION_TYPE = 'Generation'
			 AND ITX.CONTRACT_ID = pContractID
			 AND ITX.SC_ID = g_PJM_SC_ID
			 AND ITX.COMMODITY_ID =
					 (SELECT C.COMMODITY_ID
							FROM IT_COMMODITY C
						 WHERE C.COMMODITY_NAME = 'Regulation');
		RETURN NVL(lLostOppCost, 0);
	END LostOpportunityCost;
/*********************************************************************************/
FUNCTION GET_FIRM_P2P_RATE
	(
    p_OASIS_NUMBER VARCHAR2,
    p_CONTRACT_ID NUMBER,
    p_DATE DATE
    ) RETURN NUMBER IS

v_MKT_PRICE_ID NUMBER;
v_RET NUMBER;
v_DATE DATE;
BEGIN
	v_DATE := TRUNC(p_DATE,'DD');

	BEGIN
        SELECT MARKET_PRICE_ID
        INTO v_MKT_PRICE_ID
        FROM INTERCHANGE_TRANSACTION
        WHERE TRANSACTION_IDENTIFIER = p_OASIS_NUMBER
        AND CONTRACT_ID = p_CONTRACT_ID;
	EXCEPTION
    	WHEN NO_DATA_FOUND THEN
    	NULL;
    -- LOOK FOR THE MKT PRICE ANOTHER WAY
    END;

    BEGIN
        SELECT PRICE
        INTO v_RET
        FROM MARKET_PRICE_VALUE
        WHERE PRICE_DATE = v_DATE
        AND MARKET_PRICE_ID = v_MKT_PRICE_ID;
    EXCEPTION
    	WHEN NO_DATA_FOUND THEN
    		v_RET :=0;
    -- LOOK FOR THE MKT PRICE ANOTHER WAY
    END;

    RETURN v_RET;

END GET_FIRM_P2P_RATE;
/*********************************************************************************/
-- Get specified Mkt Price for 2 months prior. TO/PJM SSCD Reconciliation Charges
-- for current month use rate/quantities for 2 months prior.

FUNCTION GET_PRIOR_RATE
	(
    p_DATE IN DATE,
    p_NAME IN VARCHAR2,
    p_CONTRACT IN NUMBER,
    p_ZONE_NAME IN VARCHAR2 := NULL
    ) RETURN NUMBER IS

v_DATE DATE;
v_RET NUMBER := 0;
v_MKT_PRICE_ID NUMBER(9);
v_ZOD_ID NUMBER(9);
v_RECONCIL_LAG BINARY_INTEGER;
BEGIN
	v_RECONCIL_LAG := GET_RECONCILIATION_LAG(p_CONTRACT);
    IF v_RECONCIL_LAG <> 0 THEN
        v_DATE := TRUNC(p_DATE, 'MM') - NUMTOYMINTERVAL(v_RECONCIL_LAG, 'MONTH');

    	IF p_ZONE_NAME IS NULL THEN
            BEGIN
                SELECT MARKET_PRICE_ID
                INTO v_MKT_PRICE_ID
                FROM MARKET_PRICE
                WHERE MARKET_PRICE_ALIAS = p_NAME;
        	EXCEPTION
            	WHEN NO_DATA_FOUND THEN
            	v_RET := 0;
            END;
        ELSE
        	BEGIN
            	SELECT SERVICE_ZONE_ID
            	INTO v_ZOD_ID
            	FROM SERVICE_ZONE
            	WHERE SERVICE_ZONE_NAME = p_ZONE_NAME;

                SELECT MARKET_PRICE_ID
                INTO v_MKT_PRICE_ID
                FROM MARKET_PRICE
                WHERE MARKET_PRICE_ALIAS LIKE p_NAME
                AND ZOD_ID = v_ZOD_ID;
        	EXCEPTION
            	WHEN NO_DATA_FOUND THEN
            	v_RET := 0;
            END;

        END IF;

        BEGIN
            SELECT PRICE
            INTO v_RET
            FROM MARKET_PRICE_VALUE
            WHERE PRICE_DATE = v_DATE
            AND MARKET_PRICE_ID = v_MKT_PRICE_ID;
        EXCEPTION
        	WHEN NO_DATA_FOUND THEN
        		v_RET := 0;

        END;
    END IF;
    RETURN v_RET;

END GET_PRIOR_RATE;
/*********************************************************************************/
  FUNCTION ZONAL_PEAK_USE
  (
  p_CHARGE_DATE IN DATE,
  p_STATEMENT_TYPE IN NUMBER,
  p_CONTRACT_ID IN NUMBER
  ) RETURN NUMBER IS
--NEED ZONE
v_RET NUMBER;
BEGIN
	SELECT SUM(AMOUNT)
	INTO v_RET
	FROM INTERCHANGE_TRANSACTION A,
		IT_STATUS B,
		IT_COMMODITY C,
		IT_SCHEDULE D
	WHERE A.CONTRACT_ID = p_CONTRACT_ID
    --AND A.AGREEMENT_TYPE IN ('FTR Obligation', 'FTR Option')
		AND B.TRANSACTION_ID = A.TRANSACTION_ID
		AND B.AS_OF_DATE = (SELECT MAX(AS_OF_DATE) FROM IT_STATUS
							WHERE TRANSACTION_ID = B.TRANSACTION_ID)
		AND B.TRANSACTION_IS_ACTIVE = 1
		AND C.COMMODITY_ID = A.COMMODITY_ID
		AND UPPER(C.COMMODITY_ALIAS) = 'TRANSMISSION'
		AND D.TRANSACTION_ID = A.TRANSACTION_ID
		AND D.SCHEDULE_STATE = 1
		AND D.SCHEDULE_TYPE = p_STATEMENT_TYPE
		AND D.SCHEDULE_DATE = p_CHARGE_DATE
		AND D.AS_OF_DATE = (SELECT MAX(AS_OF_DATE) FROM IT_SCHEDULE
							WHERE TRANSACTION_ID = D.TRANSACTION_ID
								AND SCHEDULE_STATE = D.SCHEDULE_STATE
								AND SCHEDULE_TYPE = D.SCHEDULE_TYPE
								AND SCHEDULE_DATE = D.SCHEDULE_DATE
								AND AS_OF_DATE <= SYSDATE);
	RETURN NVL(v_RET,0);
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    RETURN 0;
END ZONAL_PEAK_USE;
----------------------------------------------------------------------------------------------------------------
FUNCTION GET_HOURLY_SPOT_RECONCIL_AMT
	(
    p_RECONCIL_DATE IN DATE,
    p_TXN_IDENTIFIER IN VARCHAR2,
    p_SCHEDULE_TYPE IN NUMBER,
    p_CONTRACT_ID IN NUMBER,
    p_MKT_PRICE_TYPE IN VARCHAR2
    ) RETURN NUMBER IS

v_COMMODITY_ID IT_COMMODITY.COMMODITY_ID%TYPE;
v_AMOUNT NUMBER := 0;


CURSOR p_RECONCIL(V_COMMODITY_ID IN NUMBER) IS

    SELECT D.AMOUNT "RECONCILMW", MV.PRICE "LMP"
    FROM INTERCHANGE_TRANSACTION B,
         IT_SCHEDULE D,
         MARKET_PRICE M,
         MARKET_PRICE_VALUE MV
    WHERE B.TRANSACTION_IDENTIFIER = 'PJM-RECON: ' || p_TXN_IDENTIFIER
    AND B.COMMODITY_ID = v_COMMODITY_ID
    AND B.TRANSACTION_TYPE = 'ReconciledMW'
    AND B.CONTRACT_ID = p_CONTRACT_ID
    AND D.TRANSACTION_ID = B.TRANSACTION_ID
    AND D.SCHEDULE_DATE = p_RECONCIL_DATE
    AND D.SCHEDULE_STATE = MM_PJM_UTIL.g_INTERNAL_STATE
    AND D.SCHEDULE_TYPE = p_SCHEDULE_TYPE
    AND M.MARKET_PRICE_TYPE = p_MKT_PRICE_TYPE
    AND m.MARKET_TYPE = MM_PJM_UTIL.g_REALTIME
    AND m.POD_ID = CASE WHEN p_MKT_PRICE_TYPE = 'Energy Component' THEN m.POD_ID ELSE b.POD_ID END
    AND mv.MARKET_PRICE_ID = m.MARKET_PRICE_ID
    AND mv.PRICE_DATE = D.SCHEDULE_DATE
    AND MV.PRICE_CODE = 'A';

BEGIN

	ID.ID_FOR_COMMODITY('RealTime Energy',FALSE, v_COMMODITY_ID);

    FOR v_RECONCIL IN p_RECONCIL(v_COMMODITY_ID) LOOP

		IF v_RECONCIL.RECONCILMW = 0 OR v_RECONCIL.RECONCILMW IS NULL THEN
        	v_AMOUNT := 0;
        ELSE
        	v_AMOUNT :=v_RECONCIL.RECONCILMW * v_RECONCIL.LMP;
        END IF;

     END LOOP;

     --INSERT INTO TABLE DATE, CONTRACT#, V_AMOUNT, LMP

     RETURN v_AMOUNT;

END GET_HOURLY_SPOT_RECONCIL_AMT;
------------------------------------------------------------------------------------
FUNCTION GET_SPOT_RECONCIL_AMT
	(
    p_DATE IN DATE,
    p_TXN_IDENTIFIER IN VARCHAR2,
    p_SCHEDULE_TYPE IN NUMBER,
    p_CONTRACT_ID IN NUMBER,
    p_MKT_PRICE_TYPE IN VARCHAR2
    ) RETURN NUMBER IS

v_FIRST_DATE DATE;
v_LAST_DATE DATE;
v_DATE DATE;
v_RECONCIL_AMT NUMBER := 0;
v_HOURLY_AMT NUMBER;
v_RECONCIL_LAG BINARY_INTEGER;
v_MKT_PRICE_TYPE VARCHAR2(32);
v_CUT_FROM DATE;
v_CUT_TO DATE;

BEGIN
	v_RECONCIL_LAG := GET_RECONCILIATION_LAG(p_CONTRACT_ID);
    v_MKT_PRICE_TYPE := p_MKT_PRICE_TYPE;
	IF v_RECONCIL_LAG <> 0 THEN
        v_FIRST_DATE := TRUNC(p_DATE, 'MM') - NUMTOYMINTERVAL(v_RECONCIL_LAG, 'MONTH');
    	v_LAST_DATE := LAST_DAY(v_FIRST_DATE);
        IF v_FIRST_DATE < g_MARGINAL_LOSS_DATE THEN
            IF p_MKT_PRICE_TYPE = 'Energy Component' THEN
                v_MKT_PRICE_TYPE := 'Locational Marginal Price';
            END IF;
        END IF;

        UT.CUT_DAY_INTERVAL_RANGE(GA.ELECTRIC_MODEL,
                                      v_FIRST_date,
                                      v_LAST_DATE,
                                      MM_PJM_UTIL.g_PJM_TIME_ZONE,
                                      60,
                                      v_CUT_FROM,
                                      v_CUT_TO);
        v_DATE := v_CUT_FROM;

         WHILE v_DATE <= v_CUT_TO LOOP
        	v_HOURLY_AMT := GET_HOURLY_SPOT_RECONCIL_AMT(v_DATE, p_TXN_IDENTIFIER, p_SCHEDULE_TYPE, p_CONTRACT_ID, v_MKT_PRICE_TYPE);
            v_RECONCIL_AMT := v_RECONCIL_AMT + v_HOURLY_AMT;
        	v_DATE := v_DATE + 1/24;

        END LOOP;
    END IF;

    RETURN v_RECONCIL_AMT;

END GET_SPOT_RECONCIL_AMT;
------------------------------------------------------------------------------------
FUNCTION GET_HOURLY_RECONCIL_AMT
	(
    p_DATE IN DATE,
    p_SCHEDULE_TYPE IN NUMBER,
    p_ZONE IN VARCHAR2,
    p_NAME IN VARCHAR2,
    p_CONTRACT_ID IN NUMBER
    ) RETURN NUMBER IS

v_COMMODITY_ID IT_COMMODITY.COMMODITY_ID%TYPE;
v_AMOUNT NUMBER := 0;
v_NAME VARCHAR2(16);

CURSOR p_RECONCIL(v_DATE IN DATE, v_TYPE IN NUMBER,
					v_COMMODITY_ID IN NUMBER,
                    v_ZONE IN VARCHAR2, v_NAME IN VARCHAR2,
                    v_CONTRACT_ID IN NUMBER) IS
    SELECT SUM(C.AMOUNT)"RECONCILMW", MV.PRICE "RATE"
    FROM INTERCHANGE_TRANSACTION A,
         IT_SCHEDULE C,
         MARKET_PRICE M,
         MARKET_PRICE_VALUE MV
    WHERE A.COMMODITY_ID = v_COMMODITY_ID
    AND A.TRANSACTION_TYPE = 'ReconciledMW'
    AND A.CONTRACT_ID = v_CONTRACT_ID
    AND A.TRANSACTION_IDENTIFIER LIKE 'PJM-RECON:%'
    AND C.TRANSACTION_ID = A.TRANSACTION_ID
    AND C.SCHEDULE_DATE = v_DATE
    AND C.SCHEDULE_STATE = MM_PJM_UTIL.g_INTERNAL_STATE
    AND C.SCHEDULE_TYPE = v_TYPE
    AND M.MARKET_PRICE_NAME LIKE 'PJM ' || v_NAME || ' Reconciliation Rate%'
    AND M.MARKET_PRICE_TYPE = 'Market Clearing Price'
    AND M.ZOD_ID = (SELECT SERVICE_ZONE_ID FROM SERVICE_ZONE WHERE SERVICE_ZONE_NAME = v_ZONE)
    AND MV.MARKET_PRICE_ID = M.MARKET_PRICE_ID
    AND MV.PRICE_CODE = 'A'
    AND MV.PRICE_DATE = C.SCHEDULE_DATE
    GROUP BY MV.PRICE;

BEGIN

	ID.ID_FOR_COMMODITY('RealTime Energy',FALSE, v_COMMODITY_ID);

    FOR v_RECONCIL IN p_RECONCIL(p_DATE, p_SCHEDULE_TYPE,
    								v_COMMODITY_ID, p_ZONE,
                                    p_NAME, p_CONTRACT_ID) LOOP

		IF v_RECONCIL.RECONCILMW = 0 OR v_RECONCIL.RECONCILMW IS NULL THEN
        	v_AMOUNT := 0;
        ELSE
        	v_AMOUNT := v_RECONCIL.RECONCILMW * v_RECONCIL.RATE;
        END IF;

     END LOOP;

     --INSERT INTO TABLE DATE, CONTRACT#, V_AMOUNT, LMP

     RETURN v_AMOUNT;

END GET_HOURLY_RECONCIL_AMT;
------------------------------------------------------------------------------------
FUNCTION GET_RECONCIL_AMT
	(
    p_DATE IN DATE,
    p_SCHEDULE_TYPE IN NUMBER,
    p_ZONE IN VARCHAR2,
    p_NAME IN VARCHAR2,
    p_CONTRACT_ID IN NUMBER
    ) RETURN NUMBER IS

v_FIRST_DATE DATE;
v_LAST_DATE DATE;
v_BEGIN_DATE DATE;
v_END_DATE DATE;
v_DATE DATE;
v_RECONCIL_AMT NUMBER := 0;
v_HOURLY_AMT NUMBER;
v_RECONCIL_LAG BINARY_INTEGER;

BEGIN

    v_RECONCIL_LAG := GET_RECONCILIATION_LAG(p_CONTRACT_ID);
    IF v_RECONCIL_LAG <> 0 THEN
        v_FIRST_DATE := TRUNC(p_DATE, 'MM') - NUMTOYMINTERVAL(v_RECONCIL_LAG, 'MONTH');
    	v_LAST_DATE := LAST_DAY(v_FIRST_DATE);

        UT.CUT_DATE_RANGE(v_FIRST_DATE, v_LAST_DATE, MM_PJM_UTIL.g_PJM_TIME_ZONE, v_BEGIN_DATE, v_END_DATE);
    	v_BEGIN_DATE := TO_CUT(TRUNC(v_FIRST_DATE) + 1/24,MM_PJM_UTIL.g_PJM_TIME_ZONE);

        v_DATE := v_BEGIN_DATE;

        WHILE v_DATE <= v_END_DATE LOOP

        	v_HOURLY_AMT := GET_HOURLY_RECONCIL_AMT(v_DATE, p_SCHEDULE_TYPE,
            										p_ZONE, p_NAME,
                                                     p_CONTRACT_ID);
            v_RECONCIL_AMT := v_RECONCIL_AMT + v_HOURLY_AMT;
        	v_DATE := v_DATE + 1/24;

        END LOOP;
    END IF;

    RETURN v_RECONCIL_AMT;

END GET_RECONCIL_AMT;
------------------------------------------------------------------------------------

/*********************************************************************************/
-- Get the difference between Forecast and Actual RT Load for two months
-- prior. Used for PJM & TO SSCD Reconciliation Charges.

FUNCTION GET_RECONCILIATION_MWH
	(
    p_CONTRACT IN NUMBER,
    p_BEGIN_DATE IN DATE,
    p_SCHEDULE_TYPE IN NUMBER
    --p_ZONE IN VARCHAR2
    ) RETURN NUMBER IS

v_BEGIN_DATE DATE;
v_END_DATE DATE;
v_COMMODITY_ID IT_COMMODITY.COMMODITY_ID%TYPE;
v_AMOUNT NUMBER := 0;
v_INTERVAL_BEGIN_DATE DATE;
v_INTERVAL_END_DATE DATE;
v_RECONCIL_LAG BINARY_INTEGER;

CURSOR p_RECONCIL(v_BEGIN_DATE IN DATE, v_END_DATE IN DATE,
					v_TYPE IN NUMBER, v_COMMODITY_ID IN NUMBER,
                    v_CONTRACT_ID IN NUMBER)
										--v_ZONE IN VARCHAR2)
										IS
    SELECT SUM(C.AMOUNT) "RECONCILMW"
    FROM INTERCHANGE_TRANSACTION A,
         IT_SCHEDULE C
    WHERE A.CONTRACT_ID = v_CONTRACT_ID
    AND A.COMMODITY_ID = v_COMMODITY_ID
    AND A.TRANSACTION_TYPE = 'ReconciledMW'
    AND A.TRANSACTION_IDENTIFIER LIKE 'PJM-RECON:%'
   -- AND A.POD_ID = (SELECT SERVICE_POINT_ID FROM SERVICE_POINT
    		--			WHERE SERVICE_POINT_ALIAS = v_ZONE)
    AND C.TRANSACTION_ID = A.TRANSACTION_ID
    AND C.SCHEDULE_DATE BETWEEN v_BEGIN_DATE AND v_END_DATE
    AND C.SCHEDULE_STATE = MM_PJM_UTIL.g_INTERNAL_STATE
    AND C.SCHEDULE_TYPE = v_TYPE;



BEGIN
	-- get the 1st of the month, 2 months prior for begin date. Add one
    -- month to get the end date.
    v_RECONCIL_LAG := GET_RECONCILIATION_LAG(p_CONTRACT);
	IF v_RECONCIL_LAG <> 0 THEN
        v_BEGIN_DATE := TRUNC(p_BEGIN_DATE, 'MM') - NUMTOYMINTERVAL(v_RECONCIL_LAG, 'MONTH');
    	v_END_DATE := LAST_DAY(v_BEGIN_DATE);

        UT.CUT_DAY_INTERVAL_RANGE(GA.ELECTRIC_MODEL,
                                      v_BEGIN_DATE,
                                      v_END_DATE,
                                      MM_PJM_UTIL.g_PJM_TIME_ZONE,
                                      60,
                                      v_INTERVAL_BEGIN_DATE,
                                      v_INTERVAL_END_DATE);

        ID.ID_FOR_COMMODITY('RealTime Energy',FALSE, v_COMMODITY_ID);

       	FOR v_RECONCIL IN p_RECONCIL(v_INTERVAL_BEGIN_DATE, v_INTERVAL_END_DATE, p_SCHEDULE_TYPE,
        				v_COMMODITY_ID, p_CONTRACT) --, p_ZONE)
								LOOP

    	    v_AMOUNT := NVL(v_RECONCIL.RECONCILMW,0);

        END LOOP;
    END IF;

    RETURN v_AMOUNT;

END GET_RECONCILIATION_MWH;
/*********************************************************************************/
-- Return loss factor dependent upon if current hour is on or off-peak.
-- Used for PJM Transmission Loss Charges.
FUNCTION GET_LOSS_FACTOR
	(
    p_DATE IN DATE
    ) RETURN NUMBER IS
v_IS_PEAK NUMBER(1);
v_NERC_SET_ID NUMBER(9);
BEGIN

    BEGIN
		SELECT HOLIDAY_SET_ID INTO v_NERC_SET_ID
		FROM HOLIDAY_SET WHERE HOLIDAY_SET_NAME = 'NERC';
		EXCEPTION
			WHEN OTHERS THEN
				v_NERC_SET_ID := 0;
	END;

    IF (TO_CHAR(p_DATE, 'HH24') >= g_ON_PEAK_BEGIN AND
    	TO_CHAR(p_DATE, 'HH24') <= g_ON_PEAK_END)
		AND (NOT TO_CHAR(p_DATE, 'DY') IN ('SAT', 'SUN'))
		AND (IS_HOLIDAY_FOR_SET(TRUNC(p_DATE, 'DD'), v_NERC_SET_ID) = 0) THEN
        v_IS_PEAK := 1;
    ELSE
    	v_IS_PEAK := 0;
    END IF;

	IF v_IS_PEAK = 1 THEN
    	RETURN .03;
    ELSE
    	RETURN .025;
    END IF;

END GET_LOSS_FACTOR;
/*********************************************************************************/
FUNCTION GET_PRICE
	(
	p_EXTERNAL_ID IN VARCHAR2,
	p_PRICE_DATE IN DATE
	) RETURN NUMBER IS
v_RET NUMBER;
BEGIN
	SELECT NVL(AVG(B.PRICE),0)
	INTO v_RET
	FROM MARKET_PRICE A,
		MARKET_PRICE_VALUE B
	WHERE EXTERNAL_IDENTIFIER = p_EXTERNAL_ID
		AND B.MARKET_PRICE_ID = A.MARKET_PRICE_ID
		AND B.PRICE_DATE = p_PRICE_DATE
        AND PRICE_CODE =
        	(SELECT DECODE(MAX(DECODE(PRICE_CODE,'F',1,'P',2,'A',3)),1,'F',2,'P',3,'A')
        	FROM MARKET_PRICE_VALUE
            WHERE MARKET_PRICE_ID = B.MARKET_PRICE_ID
            	AND PRICE_CODE IN ('F','P','A')
                AND PRICE_DATE = B.PRICE_DATE)
		AND AS_OF_DATE =
			(SELECT MAX(AS_OF_DATE)
			FROM MARKET_PRICE_VALUE
			WHERE MARKET_PRICE_ID = B.MARKET_PRICE_ID
				AND PRICE_CODE = B.PRICE_CODE
				AND PRICE_DATE = B.PRICE_DATE
				AND AS_OF_DATE <= SYSDATE);

	RETURN v_RET;
END GET_PRICE;
------------------------------------------------------------------------------------
FUNCTION GET_SCHEDULE
	(
	p_EXTERNAL_ID IN VARCHAR2,
	p_SCHEDULE_TYPE IN NUMBER,
	p_SCHEDULE_DATE IN DATE,
	p_CONTRACT_ID IN NUMBER := 0
	) RETURN NUMBER IS
v_RET NUMBER;
BEGIN
	SELECT NVL(SUM(B.AMOUNT),0)
	INTO v_RET
	FROM INTERCHANGE_TRANSACTION A,
		IT_SCHEDULE B
	WHERE TRANSACTION_IDENTIFIER = p_EXTERNAL_ID
		AND p_CONTRACT_ID IN (0, A.CONTRACT_ID)
		AND B.TRANSACTION_ID = A.TRANSACTION_ID
		AND B.SCHEDULE_TYPE = p_SCHEDULE_TYPE
		AND B.SCHEDULE_STATE = 1 --internal
		AND B.SCHEDULE_DATE = p_SCHEDULE_DATE
		AND AS_OF_DATE =
			(SELECT MAX(AS_OF_DATE)
			FROM IT_SCHEDULE
			WHERE TRANSACTION_ID = B.TRANSACTION_ID
				AND SCHEDULE_TYPE = B.SCHEDULE_TYPE
				AND SCHEDULE_STATE = B.SCHEDULE_STATE
				AND SCHEDULE_DATE = B.SCHEDULE_DATE
				AND AS_OF_DATE <= SYSDATE);

	RETURN NVL(v_RET, 0);
END GET_SCHEDULE;
------------------------------------------------------------------------------------
FUNCTION GET_SCHEDULE_AMOUNT
	(
	p_TRANS_TYPE IN VARCHAR2,
  p_COMMODITY IN VARCHAR2,
	p_SCHEDULE_TYPE IN NUMBER,
	p_SCHEDULE_DATE IN DATE,
	p_CONTRACT_ID IN NUMBER,
  p_INTERVAL IN VARCHAR2
	) RETURN NUMBER IS
v_RET NUMBER;
v_BEGIN_DATE DATE;
v_END_DATE DATE;
BEGIN

  IF p_INTERVAL = 'Month' THEN
    v_BEGIN_DATE := FIRST_DAY(TRUNC(p_SCHEDULE_DATE,'MM'));
    v_END_DATE := LAST_DAy(TRUNC(p_SCHEDULE_DATE,'MM')) + 1;
    SELECT NVL(SUM(B.AMOUNT),0)
	    INTO v_RET
	  FROM INTERCHANGE_TRANSACTION A,
		IT_SCHEDULE B,
    IT_COMMODITY IC
	  WHERE TRANSACTION_TYPE = p_TRANS_TYPE
		AND A.CONTRACT_ID = p_CONTRACT_ID 
    AND IC.COMMODITY_NAME = p_COMMODITY
    AND A.COMMODITY_ID = IC.COMMODITY_ID
		AND B.TRANSACTION_ID = A.TRANSACTION_ID
		AND B.SCHEDULE_TYPE = p_SCHEDULE_TYPE
		AND B.SCHEDULE_STATE = 1 --internal
		AND B.SCHEDULE_DATE BETWEEN v_BEGIN_DATE AND v_END_DATE
		AND AS_OF_DATE =
			(SELECT MAX(AS_OF_DATE)
			FROM IT_SCHEDULE
			WHERE TRANSACTION_ID = B.TRANSACTION_ID
				AND SCHEDULE_TYPE = B.SCHEDULE_TYPE
				AND SCHEDULE_STATE = B.SCHEDULE_STATE
				AND SCHEDULE_DATE = B.SCHEDULE_DATE
				AND AS_OF_DATE <= SYSDATE);

  ELSE
  


	SELECT NVL(SUM(B.AMOUNT),0)
	INTO v_RET
	FROM INTERCHANGE_TRANSACTION A,
		IT_SCHEDULE B,
    IT_COMMODITY IC
	WHERE TRANSACTION_TYPE = p_TRANS_TYPE
		AND A.CONTRACT_ID = p_CONTRACT_ID 
    AND IC.COMMODITY_NAME = p_COMMODITY
    AND A.COMMODITY_ID = IC.COMMODITY_ID
		AND B.TRANSACTION_ID = A.TRANSACTION_ID
		AND B.SCHEDULE_TYPE = p_SCHEDULE_TYPE
		AND B.SCHEDULE_STATE = 1 --internal
		AND B.SCHEDULE_DATE = p_SCHEDULE_DATE
		AND AS_OF_DATE =
			(SELECT MAX(AS_OF_DATE)
			FROM IT_SCHEDULE
			WHERE TRANSACTION_ID = B.TRANSACTION_ID
				AND SCHEDULE_TYPE = B.SCHEDULE_TYPE
				AND SCHEDULE_STATE = B.SCHEDULE_STATE
				AND SCHEDULE_DATE = B.SCHEDULE_DATE
				AND AS_OF_DATE <= SYSDATE);
        
  END IF;        

	RETURN NVL(v_RET,0);
END GET_SCHEDULE_AMOUNT;
------------------------------------------------------------------------------------
FUNCTION GET_LSR_LOAD
	(
	p_SCHEDULE_TYPE IN NUMBER,
	p_SCHEDULE_DATE IN DATE,
	p_CONTRACT_ID IN NUMBER
	) RETURN NUMBER IS
v_RET NUMBER;
BEGIN
	SELECT GREATEST(NVL(SUM(CASE WHEN ABS(SUPPLY_AMOUNT) > ABS(LOAD_AMOUNT) AND SIGN(SUPPLY_AMOUNT) = -SIGN(LOAD_AMOUNT) THEN
							0
						ELSE
							LOAD_AMOUNT - SUPPLY_AMOUNT
						END), 0), 0)
	INTO v_RET
	FROM (SELECT CASE WHEN A.AGREEMENT_TYPE = 'WHL LD RESP' THEN PURCHASER_ID ELSE SELLER_ID END PURCHASER_ID,
				CASE WHEN A.AGREEMENT_TYPE = 'WHL LD RESP' THEN SELLER_ID ELSE PURCHASER_ID END SELLER_ID,
				MAX(CASE WHEN A.AGREEMENT_TYPE = 'WHL LD RESP' THEN 1 ELSE 0 END) INCLUDES_LOAD,
				SUM(CASE WHEN A.AGREEMENT_TYPE = 'WHL LD RESP' THEN B.AMOUNT ELSE 0 END) LOAD_AMOUNT,
				SUM(CASE WHEN A.AGREEMENT_TYPE = 'WHL LD RESP' THEN 0 ELSE B.AMOUNT END) SUPPLY_AMOUNT
        	FROM INTERCHANGE_TRANSACTION A,
        		IT_SCHEDULE B,
        		IT_COMMODITY C
        	WHERE A.CONTRACT_ID = p_CONTRACT_ID
        		AND A.TRANSACTION_TYPE IN ('Purchase','Sale')
        		AND C.COMMODITY_ID = A.COMMODITY_ID
				AND C.COMMODITY_TYPE = 'Energy'
				AND C.MARKET_TYPE = 'RealTime'
        		AND B.TRANSACTION_ID = A.TRANSACTION_ID
        		AND B.SCHEDULE_TYPE = p_SCHEDULE_TYPE
        		AND B.SCHEDULE_STATE = 1 --internal
        		AND B.SCHEDULE_DATE = p_SCHEDULE_DATE
        		AND AS_OF_DATE =
        			(SELECT MAX(AS_OF_DATE)
        			FROM IT_SCHEDULE
        			WHERE TRANSACTION_ID = B.TRANSACTION_ID
        				AND SCHEDULE_TYPE = B.SCHEDULE_TYPE
        				AND SCHEDULE_STATE = B.SCHEDULE_STATE
        				AND SCHEDULE_DATE = B.SCHEDULE_DATE
        				AND AS_OF_DATE <= SYSDATE)
			GROUP BY CASE WHEN A.AGREEMENT_TYPE = 'WHL LD RESP' THEN PURCHASER_ID ELSE SELLER_ID END,
				CASE WHEN A.AGREEMENT_TYPE = 'WHL LD RESP' THEN SELLER_ID ELSE PURCHASER_ID END)
	WHERE INCLUDES_LOAD = 1;

	RETURN v_RET;
END GET_LSR_LOAD;
------------------------------------------------------------------------------------
PROCEDURE UPDATE_OP_RES_DETAIL
    (
    p_ACTION IN VARCHAR2,
    p_REC PJM_OPRES_GEN_CREDITS_DETAIL%ROWTYPE,
    p_DATE IN DATE,
    p_GEN_ID IN VARCHAR2,
    p_LMP IN NUMBER,
    p_SCHED_MW IN NUMBER,
    p_DA_VALUE IN NUMBER,
    p_DA_ENG_OFFER IN NUMBER,
    p_NO_LOAD_COST IN NUMBER,
    p_DA_STARTUP_COST IN NUMBER,
    p_DA_OFFER IN NUMBER,
    p_RT_LMP IN NUMBER := NULL,
    p_RT_MW IN NUMBER := NULL,
    p_BAL_VALUE IN NUMBER := NULL,
    p_RT_ENERG_OFF IN NUMBER := NULL,
    p_RT_NO_LOAD_CST IN NUMBER := NULL,
    p_RT_STARTUP_CST IN NUMBER := NULL,
    p_RT_OFFER IN NUMBER := NULL
    ) IS
PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
    IF p_ACTION = 'Insert' THEN
        INSERT INTO PJM_OPRES_GEN_CREDITS_DETAIL VALUES p_REC;
    ELSIF p_ACTION = 'Update DAValue' THEN
        UPDATE PJM_OPRES_GEN_CREDITS_DETAIL
        SET DA_LMP = p_LMP,
            DA_SCHED_MW = p_SCHED_MW,
            DA_VALUE = p_DA_VALUE
        WHERE GENERATOR_ID = p_GEN_ID
        AND CHARGE_DATE = p_DATE
        AND STATEMENT_STATE = GA.INTERNAL_STATE;
    ELSIF p_ACTION = 'Update DAOffer' THEN
        UPDATE PJM_OPRES_GEN_CREDITS_DETAIL
            SET Da_Energy_Offer = p_DA_ENG_OFFER,
                Da_No_Load_Cost = p_NO_LOAD_COST,
                Da_Startup_Cost = p_DA_STARTUP_COST,
                Da_Offer = p_DA_OFFER
            WHERE GENERATOR_ID = p_GEN_ID
            AND CHARGE_DATE = p_DATE
            AND STATEMENT_STATE = GA.INTERNAL_STATE;
    ELSIF p_ACTION = 'Update BalValue' THEN
        UPDATE PJM_OPRES_GEN_CREDITS_DETAIL
            SET RT_LMP = p_RT_LMP,
                RT_MW = p_RT_MW,
                BAL_ENERG_MKT_VAL = p_BAL_VALUE
            WHERE GENERATOR_ID = p_GEN_ID
            AND CHARGE_DATE = p_DATE
            AND STATEMENT_STATE = GA.INTERNAL_STATE;
    ELSE --p_ACTION = 'Update BalOffer'
        UPDATE PJM_OPRES_GEN_CREDITS_DETAIL
            SET RT_ENERG_OFFER  = p_RT_ENERG_OFF,
                RT_NO_LOAD_COST = p_RT_NO_LOAD_CST,
                RT_STARTUP_COST = p_RT_STARTUP_CST,
                RT_OFFER = p_RT_OFFER
            WHERE GENERATOR_ID = p_GEN_ID
            AND CHARGE_DATE = p_DATE
            AND STATEMENT_STATE = GA.INTERNAL_STATE;

    END IF;
    COMMIT;
END UPDATE_OP_RES_DETAIL;
-----------------------------------------------------------------------------------------------------
--used in DayAhead Operating Reserves Credits
FUNCTION GET_DA_OFFER_AMOUNT
    (
    p_GEN_ID IN VARCHAR2,
    p_DATE IN DATE,
    p_CONTRACT_ID IN NUMBER,
    p_SCHEDULE_TYPE IN NUMBER,
	p_OWN_PERCENT IN NUMBER
    ) RETURN NUMBER IS
--TYPE BO_QTY_MAP IS TABLE OF NUMBER(10) INDEX BY BINARY_INTEGER;
--TYPE BO_PRICE_MAP IS TABLE OF NUMBER(10) INDEX BY BINARY_INTEGER;
--v_BO_QTY_MAP BO_QTY_MAP;
--v_BO_PRICE_MAP BO_PRICE_MAP;
v_DA_NO_LOAD_COST NUMBER := 0;
v_DA_STARTUP_COST NUMBER := 0;
v_DA_ENERGY_OFFER NUMBER := 0;
v_DA_OFFER_AMOUNT NUMBER := 0;
v_COMMIT_STATUS VARCHAR(16);
v_DEF_STARTUP NUMBER(3) := MM_PJM_UTIL.g_TG_DEF_DEFAULT_STARTUP_COST; --574
v_NO_LOAD NUMBER(1) := MM_PJM_UTIL.g_TI_DEF_DSC_NOLOADCOST; --3
v_STARTUP_CST_APPLY NUMBER(3) := MM_PJM_UTIL.g_TG_OUT_DA_STARTUP_CST_APPLY; --576
v_NOLOAD_CST_APPLY NUMBER(3) := MM_PJM_UTIL.g_TG_OUT_DA_NOLOAD_CST_APPLY; --582
v_ACTIVE_SCHED_ID NUMBER(3) := MM_PJM_UTIL.g_TG_OUT_SCHEDULE_ID; --580
--v_COMMIT_STATUS_ID NUMBER(3) := MM_PJM_UTIL.g_TG_UPD_COMMIT_STATUS; --565
v_TRANSACTION_ID_UNIT NUMBER(9);
v_TRANSACTION_ID_SCHED NUMBER(9);
v_DA_MW NUMBER;
v_ACTIVE_SCHED NUMBER(3) := 0;
v_ACT_SCHED VARCHAR2(16);
v_COUNT BINARY_INTEGER;
v_P1 NUMBER;
v_P2 NUMBER;
v_P3 NUMBER;
v_P4 NUMBER;
v_P5 NUMBER;
v_P6 NUMBER;
v_P7 NUMBER;
v_P8 NUMBER;
v_P9 NUMBER;
v_P10 NUMBER;
v_Q1 NUMBER;
v_Q2 NUMBER;
v_Q3 NUMBER;
v_Q4 NUMBER;
v_Q5 NUMBER;
v_Q6 NUMBER;
v_Q7 NUMBER;
v_Q8 NUMBER;
v_Q9 NUMBER;
v_Q10 NUMBER;
v_REC PJM_OPRES_GEN_CREDITS_DETAIL%ROWTYPE;
v_UPDATE BOOLEAN := TRUE;
v_GEN_ID VARCHAR2(16);
v_TRAIT_ID NUMBER(3) := MM_PJM_UTIL.g_TG_UPD_COMMIT_STATUS;
BEGIN

    -- query for commit status; if commit status for current day/hour is not Economic then
    -- there is no DA Op Reserves Credit
    SELECT TRANSACTION_ID INTO v_TRANSACTION_ID_UNIT
    FROM PJM_GEN_TXNS_BY_TYPE p
    WHERE p.PJM_Gen_Id = p_GEN_ID
    AND p.CONTRACT_ID = p_CONTRACT_ID
    AND p.PJM_GEN_TXN_TYPE = 'Unit Data';

    SELECT T.TRAIT_VAL INTO v_COMMIT_STATUS
    FROM IT_TRAIT_SCHEDULE T
    WHERE T.TRANSACTION_ID = v_TRANSACTION_ID_UNIT
    AND T.SCHEDULE_STATE = GA.INTERNAL_STATE
    AND T.TRAIT_GROUP_ID = v_TRAIT_ID
    AND T.SCHEDULE_DATE = p_DATE;

    BEGIN
        SELECT TRAIT_VAL INTO v_ACT_SCHED
        FROM IT_TRAIT_SCHEDULE
        WHERE TRANSACTION_ID = v_TRANSACTION_ID_UNIT
        AND TRAIT_GROUP_ID = v_ACTIVE_SCHED_ID
        AND SCHEDULE_DATE = p_DATE;
        v_ACTIVE_SCHED := TO_NUMBER(SUBSTR(v_ACT_SCHED,
                                            LENGTH(v_ACT_SCHED) - 1, LENGTH(v_ACT_SCHED)));
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            v_ACT_SCHED := 'NotFound';
    END;

      --Economic, Unavailable calculate the credit
	IF v_ACT_SCHED <> 'NotFound' AND v_COMMIT_STATUS <> 'MustRun' THEN

        --da no load cost; first attempt to get value from op gen credits rpt
		BEGIN
		    SELECT TRAIT_VAL INTO v_DA_NO_LOAD_COST
            FROM IT_TRAIT_SCHEDULE ITS
            WHERE ITS.TRANSACTION_ID = v_TRANSACTION_ID_UNIT
            AND ITS.TRAIT_GROUP_ID = v_NOLOAD_CST_APPLY
            AND ITS.TRAIT_INDEX = 1
            AND ITS.SET_NUMBER = 1
            AND ITS.SCHEDULE_DATE = p_DATE;
        EXCEPTION
		    WHEN NO_DATA_FOUND THEN
			    SELECT DISTINCT TRAIT_VAL INTO v_DA_NO_LOAD_COST
        		FROM IT_TRAIT_SCHEDULE ITS WHERE
        		ITS.TRANSACTION_ID = v_TRANSACTION_ID_UNIT
				AND ITS.SCHEDULE_DATE =
							CASE WHEN p_DATE = TRUNC(p_DATE,'DD')
							THEN TRUNC(p_DATE - 1, 'DD') + 1/86400
							ELSE TRUNC(p_DATE, 'DD') + 1/86400
							END
				AND ITS.TRAIT_GROUP_ID = v_DEF_STARTUP
       			AND ITS.TRAIT_INDEX = v_NO_LOAD
        		AND ITS.SET_NUMBER =  --Period 1 apr - oct, Period 2 sep - mar
        		(CASE WHEN TO_NUMBER(TO_CHAR(p_DATE,'MM')) BETWEEN 4 AND 9 THEN 1 ELSE 2 END)
						AND ITS.SCHEDULE_STATE = 2;
        END;

		IF p_OWN_PERCENT < 1 THEN
		    v_DA_MW := GET_DA_GEN_BEFORE_OWN_PERCENT(v_TRANSACTION_ID_UNIT, p_DATE);
		ELSE
        --search for scheduled mw for this day/hour; if there are none,
        -- then no da credit for this hour
            BEGIN
                SELECT AMOUNT INTO v_DA_MW
                FROM IT_SCHEDULE
                WHERE TRANSACTION_ID = v_TRANSACTION_ID_UNIT
                AND SCHEDULE_DATE = p_DATE
                AND SCHEDULE_STATE = GA.INTERNAL_STATE
                AND SCHEDULE_TYPE = p_SCHEDULE_TYPE;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    v_DA_ENERGY_OFFER := -1;
            END;
        END IF;

        --query for da energy offer
        IF v_DA_ENERGY_OFFER <> -1 THEN
            IF v_DA_MW IS NULL OR v_DA_MW = 0 THEN
                v_DA_OFFER_AMOUNT := 0;
            ELSE
                --get Schedule Transaction Id
                SELECT TRANSACTION_ID INTO v_TRANSACTION_ID_SCHED
                FROM PJM_GEN_TXNS_BY_TYPE p
                WHERE P.CONTRACT_ID = p_CONTRACT_ID
                AND P.PJM_Gen_Id = p_GEN_ID
                AND P.PJM_GEN_TXN_TYPE = 'Schedule'
                AND p.AGREEMENT_TYPE = TO_CHAR(v_ACTIVE_SCHED);

                SELECT COUNT(SET_NUMBER) INTO v_COUNT
								FROM BID_OFFER_SET B
                WHERE B.TRANSACTION_ID = v_TRANSACTION_ID_SCHED
								AND B.SCHEDULE_STATE = GA.INTERNAL_STATE
								AND TRUNC(B.SCHEDULE_DATE, 'DD') = CASE WHEN p_DATE = TRUNC(p_DATE,'DD') THEN TRUNC(p_DATE - 1, 'DD')
																										ELSE TRUNC(p_DATE, 'DD') END;

         /*       FOR I IN 1..v_COUNT LOOP
                    SELECT QUANTITY, PRICE
                    INTO v_Q1, v_P1
                    FROM BID_OFFER_SET
                    WHERE TRANSACTION_ID = v_TRANSACTION_ID_SCHED
                    AND SET_NUMBER = I
                    AND TRUNC(SCHEDULE_DATE, 'DD') = TRUNC(p_DATE, 'DD');

                    v_BO_PRICE_MAP(I) := v_P1;
                    v_BO_QTY_MAP(I) := v_Q1;
                END LOOP;   */

                IF v_COUNT >=1 THEN
                    SELECT QUANTITY, PRICE
                    INTO v_Q1, v_P1
                    FROM BID_OFFER_SET
                    WHERE TRANSACTION_ID = v_TRANSACTION_ID_SCHED
										AND SCHEDULE_STATE = GA.INTERNAL_STATE
                    AND SET_NUMBER = 1
										AND TRUNC(SCHEDULE_DATE, 'DD') = CASE WHEN p_DATE = TRUNC(p_DATE,'DD') THEN TRUNC(p_DATE - 1, 'DD')
																										ELSE TRUNC(p_DATE, 'DD') END;
                END IF;

                IF v_COUNT >=2 THEN
                    SELECT QUANTITY, PRICE
                    INTO v_Q2, v_P2
                    FROM BID_OFFER_SET
                    WHERE TRANSACTION_ID = v_TRANSACTION_ID_SCHED
										AND SCHEDULE_STATE = GA.INTERNAL_STATE
                    AND SET_NUMBER = 2
										AND TRUNC(SCHEDULE_DATE, 'DD') = CASE WHEN p_DATE = TRUNC(p_DATE,'DD') THEN TRUNC(p_DATE - 1, 'DD')
																										ELSE TRUNC(p_DATE, 'DD') END;
                 END IF;

                 IF v_COUNT >=3 THEN
                    SELECT QUANTITY, PRICE
                    INTO v_Q3, v_P3
                    FROM BID_OFFER_SET
                    WHERE TRANSACTION_ID = v_TRANSACTION_ID_SCHED
										AND SCHEDULE_STATE = GA.INTERNAL_STATE
                    AND SET_NUMBER = 3
										AND TRUNC(SCHEDULE_DATE, 'DD') = CASE WHEN p_DATE = TRUNC(p_DATE,'DD') THEN TRUNC(p_DATE - 1, 'DD')
																										ELSE TRUNC(p_DATE, 'DD') END;
                 END IF;

                 IF v_COUNT >=4 THEN
                    SELECT QUANTITY, PRICE
                    INTO v_Q4, v_P4
                    FROM BID_OFFER_SET
                    WHERE TRANSACTION_ID = v_TRANSACTION_ID_SCHED
										AND SCHEDULE_STATE = GA.INTERNAL_STATE
                    AND SET_NUMBER = 4
										AND TRUNC(SCHEDULE_DATE, 'DD') = CASE WHEN p_DATE = TRUNC(p_DATE,'DD') THEN TRUNC(p_DATE - 1, 'DD')
																										ELSE TRUNC(p_DATE, 'DD') END;
                 END IF;

                 IF v_COUNT >=5 THEN
                    SELECT QUANTITY, PRICE
                    INTO v_Q5, v_P5
                    FROM BID_OFFER_SET
                    WHERE TRANSACTION_ID = v_TRANSACTION_ID_SCHED
										AND SCHEDULE_STATE = GA.INTERNAL_STATE
                    AND SET_NUMBER = 5
										AND TRUNC(SCHEDULE_DATE, 'DD') = CASE WHEN p_DATE = TRUNC(p_DATE,'DD') THEN TRUNC(p_DATE - 1, 'DD')
																										ELSE TRUNC(p_DATE, 'DD') END;
                 END IF;

                 IF v_COUNT >=6 THEN
                    SELECT QUANTITY, PRICE
                    INTO v_Q6, v_P6
                    FROM BID_OFFER_SET
                    WHERE TRANSACTION_ID = v_TRANSACTION_ID_SCHED
										AND SCHEDULE_STATE = GA.INTERNAL_STATE
                    AND SET_NUMBER = 6
										AND TRUNC(SCHEDULE_DATE, 'DD') = CASE WHEN p_DATE = TRUNC(p_DATE,'DD') THEN TRUNC(p_DATE - 1, 'DD')
																										ELSE TRUNC(p_DATE, 'DD')END;
                 END IF;

                 IF v_COUNT >=7 THEN
                    SELECT QUANTITY, PRICE
                    INTO v_Q7, v_P7
                    FROM BID_OFFER_SET
                    WHERE TRANSACTION_ID = v_TRANSACTION_ID_SCHED
										AND SCHEDULE_STATE = GA.INTERNAL_STATE
                    AND SET_NUMBER = 7
										AND TRUNC(SCHEDULE_DATE, 'DD') = CASE WHEN p_DATE = TRUNC(p_DATE,'DD') THEN TRUNC(p_DATE - 1, 'DD')
																										ELSE TRUNC(p_DATE, 'DD') END;
                 END IF;

                 IF v_COUNT >=8 THEN
                    SELECT QUANTITY, PRICE
                    INTO v_Q8, v_P8
                    FROM BID_OFFER_SET
                    WHERE TRANSACTION_ID = v_TRANSACTION_ID_SCHED
										AND SCHEDULE_STATE = GA.INTERNAL_STATE
                    AND SET_NUMBER = 8
										AND TRUNC(SCHEDULE_DATE, 'DD') = CASE WHEN p_DATE = TRUNC(p_DATE,'DD') THEN TRUNC(p_DATE - 1, 'DD')
																										ELSE TRUNC(p_DATE, 'DD') END;
                 END IF;

                 IF v_COUNT >=9 THEN
                    SELECT QUANTITY, PRICE
                    INTO v_Q9, v_P9
                    FROM BID_OFFER_SET
                    WHERE TRANSACTION_ID = v_TRANSACTION_ID_SCHED
										AND SCHEDULE_STATE = GA.INTERNAL_STATE
                    AND SET_NUMBER = 9
										AND TRUNC(SCHEDULE_DATE, 'DD') = CASE WHEN p_DATE = TRUNC(p_DATE,'DD') THEN TRUNC(p_DATE - 1, 'DD')
																										ELSE TRUNC(p_DATE, 'DD') END;
                 END IF;

                 IF v_COUNT >=10 THEN
                    SELECT QUANTITY, PRICE
                    INTO v_Q10, v_P10
                    FROM BID_OFFER_SET
                    WHERE TRANSACTION_ID = v_TRANSACTION_ID_SCHED
										AND SCHEDULE_STATE = GA.INTERNAL_STATE
                    AND SET_NUMBER = 10
										AND TRUNC(SCHEDULE_DATE, 'DD') = CASE WHEN p_DATE = TRUNC(p_DATE,'DD') THEN TRUNC(p_DATE - 1, 'DD')
																										ELSE TRUNC(p_DATE, 'DD') END;
                 END IF;

                v_DA_ENERGY_OFFER := 0;
                IF v_DA_MW <= v_Q1 THEN
                    v_DA_ENERGY_OFFER := v_DA_MW * v_P1;
                ELSIF v_Q2 IS NULL THEN
                    v_DA_ENERGY_OFFER := (v_Q1 * v_P1) + ((v_DA_MW - v_Q1) * v_P1);
                ELSIF v_DA_MW <= v_Q2 THEN
                    v_DA_ENERGY_OFFER := (v_Q1 * v_P1) + ((v_DA_MW - v_Q1) * v_P2);
                ELSIF v_Q3 IS NULL THEN
                    v_DA_ENERGY_OFFER := (v_Q1 * v_P1) + ((v_Q2-v_Q1) * v_P2) + ((v_DA_MW - v_Q2) * v_P2);
                ELSIF v_DA_MW <= v_Q3 THEN
                    v_DA_ENERGY_OFFER := (v_Q1 * v_P1) + ((v_Q2-v_Q1) * v_P2) + ((v_DA_MW - v_Q2) * v_P3);
                ELSIF v_Q4 IS NULL THEN
                    v_DA_ENERGY_OFFER := (v_Q1 * v_P1) + ((v_Q2-v_Q1) * v_P2) + ((v_DA_MW - v_Q2) * v_P3);
                ELSIF v_DA_MW <= v_Q4 THEN
                    v_DA_ENERGY_OFFER := (v_Q1 * v_P1) + ((v_Q2-v_Q1) * v_P2) + ((v_Q3- v_Q2) * v_P3) + ((v_DA_MW - v_Q3) * v_P4);
                ELSIF v_Q5 IS NULL THEN
                    v_DA_ENERGY_OFFER := (v_Q1 * v_P1) + ((v_Q2-v_Q1) * v_P2) + ((v_Q3- v_Q2) * v_P3) + ((v_Q4 - v_Q3) * v_P4)+ ((v_DA_MW - v_Q4) * v_P4);
                ELSIF v_DA_MW <= v_Q5 THEN
                    v_DA_ENERGY_OFFER := (v_Q1 * v_P1) + ((v_Q2-v_Q1) * v_P2) + ((v_Q3- v_Q2) * v_P3) + ((v_Q4 - v_Q3) * v_P4)+ ((v_DA_MW - v_Q4) * v_P5);
                ELSIF v_Q6 IS NULL THEN
                    v_DA_ENERGY_OFFER := (v_Q1 * v_P1) + ((v_Q2-v_Q1) * v_P2) + ((v_Q3- v_Q2) * v_P3) + ((v_Q4 - v_Q3) * v_P4)+ ((v_Q5 - v_Q4) * v_P5) + ((v_DA_MW - v_Q5) * v_P5);
                ELSIF v_DA_MW <= v_Q6 THEN
                    v_DA_ENERGY_OFFER := (v_Q1 * v_P1) + ((v_Q2-v_Q1) * v_P2) + ((v_Q3- v_Q2) * v_P3) + ((v_Q4 - v_Q3) * v_P4)+ ((v_Q5 - v_Q4) * v_P5) + ((v_DA_MW - v_Q5) * v_P6);
                ELSIF v_Q7 IS NULL THEN
                    v_DA_ENERGY_OFFER := (v_Q1 * v_P1) + ((v_Q2-v_Q1) * v_P2) + ((v_Q3- v_Q2) * v_P3) + ((v_Q4 - v_Q3) * v_P4)+ ((v_Q5 - v_Q4) * v_P5) + ((V_Q6 - v_Q5) * v_P6)+ ((v_DA_MW - v_Q6) * v_P6);
                ELSIF v_DA_MW <= v_Q7 THEN
                    v_DA_ENERGY_OFFER := (v_Q1 * v_P1) + ((v_Q2-v_Q1) * v_P2) + ((v_Q3- v_Q2) * v_P3) + ((v_Q4 - v_Q3) * v_P4)+ ((v_Q5 - v_Q4) * v_P5) + ((V_Q6 - v_Q5) * v_P6)+ ((v_DA_MW - v_Q6) * v_P7);
                ELSIF v_Q8 IS NULL THEN
                v_DA_ENERGY_OFFER := (v_Q1 * v_P1) + ((v_Q2-v_Q1) * v_P2) + ((v_Q3- v_Q2) * v_P3) + ((v_Q4 - v_Q3) * v_P4)+
                ((v_Q5 - v_Q4) * v_P5) + ((V_Q6 - v_Q5) * v_P6)+ ((V_Q7 - v_Q6) * v_P7)+ ((v_DA_MW - v_Q7) * v_P7);
                ELSIF v_DA_MW <= v_Q8 THEN
                v_DA_ENERGY_OFFER := (v_Q1 * v_P1) + ((v_Q2-v_Q1) * v_P2) + ((v_Q3- v_Q2) * v_P3) + ((v_Q4 - v_Q3) * v_P4)+
                ((v_Q5 - v_Q4) * v_P5) + ((V_Q6 - v_Q5) * v_P6)+ ((V_Q7 - v_Q6) * v_P7)+ ((v_DA_MW - v_Q7) * v_P8);
                 ELSIF v_DA_MW <= v_Q9 THEN
                v_DA_ENERGY_OFFER := (v_Q1 * v_P1) + ((v_Q2-v_Q1) * v_P2) + ((v_Q3- v_Q2) * v_P3) + ((v_Q4 - v_Q3) * v_P4)+
                ((v_Q5 - v_Q4) * v_P5) + ((V_Q6 - v_Q5) * v_P6)+ ((V_Q7 - v_Q6) * v_P7)+ ((V_Q8 - v_Q7) * v_P8)+((v_DA_MW - v_Q8) * v_P9);
                ELSIF v_Q9 IS NULL THEN
                v_DA_ENERGY_OFFER := (v_Q1 * v_P1) + ((v_Q2-v_Q1) * v_P2) + ((v_Q3- v_Q2) * v_P3) + ((v_Q4 - v_Q3) * v_P4)+
                ((v_Q5 - v_Q4) * v_P5) + ((V_Q6 - v_Q5) * v_P6)+ ((V_Q7 - v_Q6) * v_P7)+ ((V_Q8 - v_Q7) * v_P8)+((v_DA_MW - v_Q8) * v_P8);
                ELSIF v_Q10 IS NULL THEN
                 v_DA_ENERGY_OFFER := (v_Q1 * v_P1) + ((v_Q2-v_Q1) * v_P2) + ((v_Q3- v_Q2) * v_P3) + ((v_Q4 - v_Q3) * v_P4)+
                ((v_Q5 - v_Q4) * v_P5) + ((V_Q6 - v_Q5) * v_P6)+ ((V_Q7 - v_Q6) * v_P7)+ ((V_Q8 - v_Q7) * v_P8)+ ((V_Q9 - v_Q8) * v_P9)+ ((v_DA_MW - v_Q9) * v_P9);
                ELSIF v_DA_MW <= v_Q10 THEN
                 v_DA_ENERGY_OFFER := (v_Q1 * v_P1) + ((v_Q2-v_Q1) * v_P2) + ((v_Q3- v_Q2) * v_P3) + ((v_Q4 - v_Q3) * v_P4)+
                ((v_Q5 - v_Q4) * v_P5) + ((V_Q6 - v_Q5) * v_P6)+ ((V_Q7 - v_Q6) * v_P7)+ ((V_Q8 - v_Q7) * v_P8)+ ((V_Q9 - v_Q8) * v_P9)+ ((v_DA_MW - v_Q9) * v_P10);
                ELSE
                   v_DA_ENERGY_OFFER := 0;
                END IF;

                --query for da_startup_cost
                --if the prior hour mw were 0 then apply the startup cost
              /*  BEGIN
                    SELECT AMOUNT INTO v_DA_MW FROM IT_SCHEDULE
                    WHERE TRANSACTION_ID = v_TRANSACTION_ID_UNIT
                    AND SCHEDULE_DATE = p_DATE - 1/24
                    AND SCHEDULE_STATE = GA.INTERNAL_STATE
                    AND SCHEDULE_TYPE = p_SCHEDULE_TYPE;
                EXCEPTION
                    WHEN NO_DATA_FOUND THEN
                        v_DA_MW := 0;
                END;*/

                 --IF v_DA_MW IS NULL OR v_DA_MW = 0 THEN
                BEGIN
                    SELECT TRAIT_VAL INTO v_DA_STARTUP_COST
                    FROM IT_TRAIT_SCHEDULE ITS
                    WHERE ITS.TRANSACTION_ID = v_TRANSACTION_ID_UNIT
                    AND ITS.TRAIT_GROUP_ID = v_STARTUP_CST_APPLY
                    AND ITS.TRAIT_INDEX = 1
                    AND ITS.SET_NUMBER = 1
                    AND ITS.SCHEDULE_DATE = p_DATE;
                EXCEPTION
                    WHEN NO_DATA_FOUND THEN
                        v_DA_STARTUP_COST := 0;
                END;
                --ELSE
                    --v_DA_STARTUP_COST := 0;
                --END IF;

                v_DA_OFFER_AMOUNT := v_DA_ENERGY_OFFER + v_DA_NO_LOAD_COST + v_DA_STARTUP_COST;

            END IF;
        ELSE
            v_DA_OFFER_AMOUNT := 0;
        END IF;

    ELSE
         v_DA_OFFER_AMOUNT := -1;
    END IF;

    --put the hourly detail into the PJM_OPRES_GEN_CREDITS table
    IF v_DA_OFFER_AMOUNT > 0 THEN
        BEGIN
            SELECT GENERATOR_ID INTO v_GEN_ID
            FROM PJM_OPRES_GEN_CREDITS_DETAIL
            WHERE GENERATOR_ID = p_GEN_ID
            AND CHARGE_DATE = p_DATE
            AND STATEMENT_STATE = GA.INTERNAL_STATE;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
            v_REC.GENERATOR_ID := p_GEN_ID;
            v_REC.STATEMENT_STATE := GA.INTERNAL_STATE;
            v_REC.CHARGE_DATE := p_DATE;
            v_REC.SCHEDULE_ID := p_GEN_ID;
            v_REC.Da_Energy_Offer := v_DA_ENERGY_OFFER;
            v_REC.Da_No_Load_Cost := v_DA_NO_LOAD_COST;
            v_REC.Da_Startup_Cost := v_DA_STARTUP_COST;
            v_REC.Da_Offer := v_DA_OFFER_AMOUNT;

            UPDATE_OP_RES_DETAIL('Insert', v_REC, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
            v_UPDATE := FALSE;
        END;

        IF v_UPDATE = TRUE THEN
            UPDATE_OP_RES_DETAIL('Update DAOffer', NULL, p_DATE, p_GEN_ID, NULL, NULL,
                            NULL, v_DA_ENERGY_OFFER, v_DA_NO_LOAD_COST, v_DA_STARTUP_COST, v_DA_OFFER_AMOUNT);
        END IF;
    END IF;
    RETURN v_DA_OFFER_AMOUNT;
END GET_DA_OFFER_AMOUNT;
---------------------------------------------------------------------------------------
--used in DayAhead Operating Reserves Credits
FUNCTION GET_DA_MKT_VALUE
    (
    p_GEN_ID IN VARCHAR2,
    p_DATE IN DATE,
    p_CONTRACT_ID IN NUMBER,
    p_SCHEDULE_TYPE IN NUMBER,
		p_OWN_PERCENT IN NUMBER
    ) RETURN NUMBER IS
v_SERVICE_PT_ID NUMBER(9);
v_LMP_VALUE NUMBER;
v_DA_MKT_VALUE NUMBER := 0;
v_SCHED_MW NUMBER;
v_GEN_ID VARCHAR2(16);
v_UPDATE BOOLEAN := TRUE;
v_REC PJM_OPRES_GEN_CREDITS_DETAIL%ROWTYPE;
v_TRANSACTION_ID_UNIT NUMBER;
BEGIN

    SELECT TRANSACTION_ID INTO v_TRANSACTION_ID_UNIT
    FROM PJM_GEN_TXNS_BY_TYPE p
    WHERE p.PJM_Gen_Id = p_GEN_ID
    AND p.CONTRACT_ID = p_CONTRACT_ID
    AND p.PJM_GEN_TXN_TYPE = 'Unit Data';

		SELECT SR.SERVICE_POINT_ID INTO v_SERVICE_PT_ID
    FROM SUPPLY_RESOURCE SR, TEMPORAL_ENTITY_ATTRIBUTE T
    WHERE T.ATTRIBUTE_NAME = 'PJM_PNODEID'
    AND T.ATTRIBUTE_VAL = p_GEN_ID
    AND T.OWNER_ENTITY_ID = SR.RESOURCE_ID;

    SELECT NVL(MV.PRICE,0) INTO v_LMP_VALUE
    FROM MARKET_PRICE M, MARKET_PRICE_VALUE MV
    WHERE M.MARKET_PRICE_TYPE = 'Locational Marginal Price'
    AND M.MARKET_TYPE = 'DayAhead'
    AND M.POD_ID = v_SERVICE_PT_ID
    AND MV.PRICE_CODE = 'A'
    AND MV.MARKET_PRICE_ID = M.MARKET_PRICE_ID
    AND MV.PRICE_DATE = p_DATE;

		IF p_OWN_PERCENT < 1 THEN
				v_SCHED_MW := GET_DA_GEN_BEFORE_OWN_PERCENT(v_TRANSACTION_ID_UNIT, p_DATE);
		ELSE
    	BEGIN
        SELECT NVL(AMOUNT,0) INTO v_SCHED_MW
        FROM IT_SCHEDULE
        WHERE TRANSACTION_ID = v_TRANSACTION_ID_UNIT
        AND SCHEDULE_DATE = p_DATE
        AND SCHEDULE_STATE = GA.INTERNAL_STATE
        AND SCHEDULE_TYPE = p_SCHEDULE_TYPE;
        /*SELECT NVL(ITS.AMOUNT,0) INTO v_SCHED_MW
        FROM INTERCHANGE_TRANSACTION IT, IT_SCHEDULE ITS
        WHERE IT.TRANSACTION_TYPE = 'Generation'
        AND IT.COMMODITY_ID = (SELECT COMMODITY_ID FROM IT_COMMODITY WHERE COMMODITY_NAME = 'DayAhead Energy')
        AND IT.CONTRACT_ID = P_CONTRACT_ID
        AND IT.TRANSACTION_IDENTIFIER = p_GEN_ID
        AND IT.POD_ID = v_SERVICE_PT_ID
        AND ITS.TRANSACTION_ID = IT.TRANSACTION_ID
        AND ITS.SCHEDULE_STATE = GA.INTERNAL_STATE
        AND ITS.SCHEDULE_TYPE = p_SCHEDULE_TYPE
        AND ITS.SCHEDULE_DATE = p_DATE
        AND ITS.AMOUNT <> 0;*/
    	EXCEPTION
        WHEN NO_DATA_FOUND THEN
            v_SCHED_MW := 0;
    	END;
		END IF;

    v_DA_MKT_VALUE := v_LMP_VALUE * v_SCHED_MW;

    --put the hourly detail into the PJM_OPRES_GEN_CREDITS table
    BEGIN
        SELECT GENERATOR_ID INTO v_GEN_ID
        FROM PJM_OPRES_GEN_CREDITS_DETAIL
        WHERE GENERATOR_ID = p_GEN_ID
        AND CHARGE_DATE = p_DATE
        AND STATEMENT_STATE = GA.INTERNAL_STATE;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
        v_REC.GENERATOR_ID := p_GEN_ID;
        v_REC.STATEMENT_STATE := GA.INTERNAL_STATE;
        v_REC.CHARGE_DATE := p_DATE;
        v_REC.SCHEDULE_ID := p_GEN_ID;
        v_REC.DA_LMP := v_LMP_VALUE;
        v_REC.DA_SCHED_MW := v_SCHED_MW;
        v_REC.DA_VALUE := v_LMP_VALUE * v_SCHED_MW;

        UPDATE_OP_RES_DETAIL('Insert', v_REC, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
        v_UPDATE := FALSE;
    END;

    IF v_UPDATE = TRUE THEN
        UPDATE_OP_RES_DETAIL('Update DAValue', NULL, p_DATE, p_GEN_ID, v_LMP_VALUE, v_SCHED_MW,
                            v_DA_MKT_VALUE, NULL, NULL, NULL, NULL);
    END IF;

    RETURN NVL(v_DA_MKT_VALUE,0);

END GET_DA_MKT_VALUE;
---------------------------------------------------------------------------------------
--used in Balancing Operating Reserves Credits
FUNCTION GET_RT_OFFER_AMOUNT
    (
    p_GEN_ID IN VARCHAR2,
    p_DATE IN DATE,
    p_CONTRACT_ID IN NUMBER,
    p_SCHEDULE_TYPE IN NUMBER,
    p_TXN_ID_UNIT IN NUMBER,
		p_OWN_PERCENT IN NUMBER
    ) RETURN NUMBER IS
v_RT_NO_LOAD_COST NUMBER := 0;
v_RT_STARTUP_COST NUMBER := 0;
v_BAL_ENERGY_OFFER NUMBER := 0;
v_RT_OFFER_AMOUNT NUMBER := 0;
v_STARTUP_CST_APPLY NUMBER(3) := MM_PJM_UTIL.g_TG_OUT_RT_STARTUP_CST_APPLY; --577
v_NOLOAD_CST_APPLY NUMBER(3) := MM_PJM_UTIL.g_TG_OUT_RT_NOLOAD_CST_APPLY; --578
v_DESIRED_MW_ID NUMBER(3) := MM_PJM_UTIL.g_TG_OUT_DESIRED_MWH; --579
v_ACTIVE_SCHED_ID NUMBER(3) := MM_PJM_UTIL.g_TG_OUT_SCHEDULE_ID; --580
v_TRANSACTION_ID_SCHED NUMBER(9);
v_RT_MW NUMBER;
v_DESIRED_MW NUMBER;
v_ACTIVE_SCHED NUMBER(3) := 0;
v_ACT_SCHED VARCHAR2(16);
v_COUNT BINARY_INTEGER;
v_P1 NUMBER;
v_P2 NUMBER;
v_P3 NUMBER;
v_P4 NUMBER;
v_P5 NUMBER;
v_P6 NUMBER;
v_P7 NUMBER;
v_P8 NUMBER;
v_P9 NUMBER;
v_P10 NUMBER;
v_Q1 NUMBER;
v_Q2 NUMBER;
v_Q3 NUMBER;
v_Q4 NUMBER;
v_Q5 NUMBER;
v_Q6 NUMBER;
v_Q7 NUMBER;
v_Q8 NUMBER;
v_Q9 NUMBER;
v_Q10 NUMBER;
--v_REC PJM_OPRES_GEN_CREDITS_DETAIL%ROWTYPE;
--v_UPDATE BOOLEAN := TRUE;
--v_GEN_ID VARCHAR2(16);
v_SCHED_MW NUMBER;
BEGIN
      IF p_OWN_PERCENT < 1 THEN
				v_SCHED_MW := GET_DA_GEN_BEFORE_OWN_PERCENT(p_TXN_ID_UNIT, p_DATE);
			ELSE
  			BEGIN
              SELECT AMOUNT INTO v_SCHED_MW
              FROM IT_SCHEDULE
              WHERE TRANSACTION_ID = p_TXN_ID_UNIT
              AND SCHEDULE_DATE = p_DATE
              AND SCHEDULE_STATE = GA.INTERNAL_STATE
              AND SCHEDULE_TYPE = p_SCHEDULE_TYPE;
          EXCEPTION
              WHEN NO_DATA_FOUND THEN
                  v_SCHED_MW := 0;
          END;
			END IF;

      --IF v_SCHED_MW = 0 THEN
        --get the active schedule from the output trait which was populated when the
        --op gen credits report was imported
        BEGIN
          SELECT TRAIT_VAL INTO v_ACT_SCHED
          FROM IT_TRAIT_SCHEDULE
          WHERE TRANSACTION_ID = p_TXN_ID_UNIT
          AND TRAIT_GROUP_ID = v_ACTIVE_SCHED_ID
          AND SCHEDULE_DATE = p_DATE
          AND SCHEDULE_STATE = GA.INTERNAL_STATE;
          v_ACTIVE_SCHED := TO_NUMBER(SUBSTR(v_ACT_SCHED,
                                              LENGTH(v_ACT_SCHED) - 1, LENGTH(v_ACT_SCHED)));
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
                  NULL;
          END;

        IF NVL(v_ACTIVE_SCHED,0) <> 0 THEN
            BEGIN
                SELECT TRAIT_VAL INTO v_RT_NO_LOAD_COST
                FROM IT_TRAIT_SCHEDULE ITS
                WHERE ITS.TRANSACTION_ID = p_TXN_ID_UNIT
                AND ITS.TRAIT_GROUP_ID = v_NOLOAD_CST_APPLY
                AND ITS.TRAIT_INDEX = 1
                AND ITS.SET_NUMBER = 1
                AND ITS.SCHEDULE_DATE = p_DATE;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    v_RT_NO_LOAD_COST := 0;
            END;

        --get the rt mw for this hour
        IF p_OWN_PERCENT < 1 THEN
				--don't restrict by contract, get total rt gen
					BEGIN
            SELECT SUM(NVL(ITS.AMOUNT,0)) INTO v_RT_MW
            FROM IT_SCHEDULE ITS, INTERCHANGE_TRANSACTION T
            WHERE T.TRANSACTION_TYPE = 'Generation'
            AND T.COMMODITY_ID IN (SELECT COMMODITY_ID FROM IT_COMMODITY WHERE COMMODITY_NAME = 'RealTime Energy')
            AND T.RESOURCE_ID = (SELECT OWNER_ENTITY_ID FROM TEMPORAL_ENTITY_ATTRIBUTE WHERE
                ATTRIBUTE_NAME = 'PJM_PNODEID' AND ATTRIBUTE_VAL = p_GEN_ID)
            AND T.TRANSACTION_ID = ITS.TRANSACTION_ID
            AND ITS.SCHEDULE_DATE = p_DATE
            AND ITS.SCHEDULE_STATE = GA.INTERNAL_STATE
            AND ITS.SCHEDULE_TYPE = p_SCHEDULE_TYPE;
        	EXCEPTION
            WHEN NO_DATA_FOUND THEN
            v_BAL_ENERGY_OFFER := -1;
        	END;
				ELSE
  				BEGIN
              SELECT SUM(NVL(ITS.AMOUNT,0)) INTO v_RT_MW
              FROM IT_SCHEDULE ITS, INTERCHANGE_TRANSACTION T
              WHERE T.TRANSACTION_TYPE = 'Generation'
              AND T.COMMODITY_ID IN (SELECT COMMODITY_ID FROM IT_COMMODITY WHERE COMMODITY_NAME = 'RealTime Energy')
              AND T.RESOURCE_ID = (SELECT OWNER_ENTITY_ID FROM TEMPORAL_ENTITY_ATTRIBUTE WHERE
                  ATTRIBUTE_NAME = 'PJM_PNODEID' AND ATTRIBUTE_VAL = p_GEN_ID)
              AND T.TRANSACTION_ID = ITS.TRANSACTION_ID
  						and T.CONTRACT_ID = p_CONTRACT_ID
              AND ITS.SCHEDULE_DATE = p_DATE
              AND ITS.SCHEDULE_STATE = GA.INTERNAL_STATE
              AND ITS.SCHEDULE_TYPE = p_SCHEDULE_TYPE;
          EXCEPTION
              WHEN NO_DATA_FOUND THEN
              v_BAL_ENERGY_OFFER := -1;
          END;
				END IF;

        --query for da energy offer
        IF v_BAL_ENERGY_OFFER <> -1 THEN
            IF v_RT_MW IS NULL OR v_RT_MW <= 0 THEN
                v_BAL_ENERGY_OFFER := 0;
            ELSE
                --get Schedule Transaction Id
                    IF v_ACTIVE_SCHED = -1 THEN
                        SELECT TRANSACTION_ID INTO v_TRANSACTION_ID_SCHED
                        FROM PJM_GEN_TXNS_BY_TYPE p
                        WHERE P.CONTRACT_ID = p_CONTRACT_ID
                        AND P.PJM_Gen_Id = p_GEN_ID
                        AND P.PJM_GEN_TXN_TYPE = 'Schedule'
                        AND p.AGREEMENT_TYPE LIKE '9%';

                    ELSE
                        SELECT TRANSACTION_ID INTO v_TRANSACTION_ID_SCHED
                        FROM PJM_GEN_TXNS_BY_TYPE p
                        WHERE P.CONTRACT_ID = p_CONTRACT_ID
                        AND P.PJM_Gen_Id = p_GEN_ID
                        AND P.PJM_GEN_TXN_TYPE = 'Schedule'
                        AND p.AGREEMENT_TYPE = TO_CHAR(v_ACTIVE_SCHED);
                    END IF;

                SELECT COUNT(SET_NUMBER) INTO v_COUNT
								FROM BID_OFFER_SET B
                WHERE B.TRANSACTION_ID = v_TRANSACTION_ID_SCHED
								AND SCHEDULE_STATE = GA.INTERNAL_STATE
								AND TRUNC(B.SCHEDULE_DATE, 'DD') = CASE WHEN p_DATE = TRUNC(p_DATE,'DD') THEN TRUNC(p_DATE - 1, 'DD')
																										ELSE TRUNC(p_DATE, 'DD') END;

                IF v_COUNT >=1 THEN
                    SELECT QUANTITY, PRICE
                    INTO v_Q1, v_P1
                    FROM BID_OFFER_SET
                    WHERE TRANSACTION_ID = v_TRANSACTION_ID_SCHED
                    AND SET_NUMBER = 1
										AND SCHEDULE_STATE = GA.INTERNAL_STATE
										AND TRUNC(SCHEDULE_DATE, 'DD') = CASE WHEN p_DATE = TRUNC(p_DATE,'DD') THEN TRUNC(p_DATE - 1, 'DD')
																										ELSE TRUNC(p_DATE, 'DD') END;
                END IF;

                IF v_COUNT >=2 THEN
                    SELECT QUANTITY, PRICE
                    INTO v_Q2, v_P2
                    FROM BID_OFFER_SET
                    WHERE TRANSACTION_ID = v_TRANSACTION_ID_SCHED
                    AND SET_NUMBER = 2
										AND SCHEDULE_STATE = GA.INTERNAL_STATE
										AND TRUNC(SCHEDULE_DATE, 'DD') = CASE WHEN p_DATE = TRUNC(p_DATE,'DD') THEN TRUNC(p_DATE - 1, 'DD')
																										ELSE TRUNC(p_DATE, 'DD') END;
                 END IF;

                 IF v_COUNT >=3 THEN
                    SELECT QUANTITY, PRICE
                    INTO v_Q3, v_P3
                    FROM BID_OFFER_SET
                    WHERE TRANSACTION_ID = v_TRANSACTION_ID_SCHED
                    AND SET_NUMBER = 3
										AND SCHEDULE_STATE = GA.INTERNAL_STATE
										AND TRUNC(SCHEDULE_DATE, 'DD') = CASE WHEN p_DATE = TRUNC(p_DATE,'DD') THEN TRUNC(p_DATE - 1, 'DD')
																										ELSE TRUNC(p_DATE, 'DD') END;
                 END IF;

                 IF v_COUNT >=4 THEN
                    SELECT QUANTITY, PRICE
                    INTO v_Q4, v_P4
                    FROM BID_OFFER_SET
                    WHERE TRANSACTION_ID = v_TRANSACTION_ID_SCHED
                    AND SET_NUMBER = 4
										AND SCHEDULE_STATE = GA.INTERNAL_STATE
										AND TRUNC(SCHEDULE_DATE, 'DD') = CASE WHEN p_DATE = TRUNC(p_DATE,'DD') THEN TRUNC(p_DATE - 1, 'DD')
																										ELSE TRUNC(p_DATE, 'DD') END;
                 END IF;

                 IF v_COUNT >=5 THEN
                    SELECT QUANTITY, PRICE
                    INTO v_Q5, v_P5
                    FROM BID_OFFER_SET
                    WHERE TRANSACTION_ID = v_TRANSACTION_ID_SCHED
                    AND SET_NUMBER = 5
										AND SCHEDULE_STATE = GA.INTERNAL_STATE
										AND TRUNC(SCHEDULE_DATE, 'DD') = CASE WHEN p_DATE = TRUNC(p_DATE,'DD') THEN TRUNC(p_DATE - 1, 'DD')
																										ELSE TRUNC(p_DATE, 'DD') END;
                 END IF;

                 IF v_COUNT >=6 THEN
                    SELECT QUANTITY, PRICE
                    INTO v_Q6, v_P6
                    FROM BID_OFFER_SET
                    WHERE TRANSACTION_ID = v_TRANSACTION_ID_SCHED
                    AND SET_NUMBER = 6
										AND SCHEDULE_STATE = GA.INTERNAL_STATE
										AND TRUNC(SCHEDULE_DATE, 'DD')= CASE WHEN p_DATE = TRUNC(p_DATE,'DD') THEN TRUNC(p_DATE - 1, 'DD')
																										ELSE TRUNC(p_DATE, 'DD') END;
                 END IF;

                 IF v_COUNT >=7 THEN
                    SELECT QUANTITY, PRICE
                    INTO v_Q7, v_P7
                    FROM BID_OFFER_SET
                    WHERE TRANSACTION_ID = v_TRANSACTION_ID_SCHED
                    AND SET_NUMBER = 7
										AND SCHEDULE_STATE = GA.INTERNAL_STATE
										AND TRUNC(SCHEDULE_DATE, 'DD') = CASE WHEN p_DATE = TRUNC(p_DATE,'DD') THEN TRUNC(p_DATE - 1, 'DD')
																										ELSE TRUNC(p_DATE, 'DD') END;
                 END IF;

                 IF v_COUNT >=8 THEN
                    SELECT QUANTITY, PRICE
                    INTO v_Q8, v_P8
                    FROM BID_OFFER_SET
                    WHERE TRANSACTION_ID = v_TRANSACTION_ID_SCHED
                    AND SET_NUMBER = 8
										AND SCHEDULE_STATE = GA.INTERNAL_STATE
										AND TRUNC(SCHEDULE_DATE, 'DD') = CASE WHEN p_DATE = TRUNC(p_DATE,'DD') THEN TRUNC(p_DATE - 1, 'DD')
																										ELSE TRUNC(p_DATE, 'DD') END;
                 END IF;

                 IF v_COUNT >=9 THEN
                    SELECT QUANTITY, PRICE
                    INTO v_Q9, v_P9
                    FROM BID_OFFER_SET
                    WHERE TRANSACTION_ID = v_TRANSACTION_ID_SCHED
                    AND SET_NUMBER = 9
										AND SCHEDULE_STATE = GA.INTERNAL_STATE
										AND TRUNC(SCHEDULE_DATE, 'DD') = CASE WHEN p_DATE = TRUNC(p_DATE,'DD') THEN TRUNC(p_DATE - 1, 'DD')
																										ELSE TRUNC(p_DATE, 'DD') END;
                 END IF;

                 IF v_COUNT >=10 THEN
                    SELECT QUANTITY, PRICE
                    INTO v_Q10, v_P10
                    FROM BID_OFFER_SET
                    WHERE TRANSACTION_ID = v_TRANSACTION_ID_SCHED
                    AND SET_NUMBER = 10
										AND SCHEDULE_STATE = GA.INTERNAL_STATE
										AND TRUNC(SCHEDULE_DATE, 'DD') = CASE WHEN p_DATE = TRUNC(p_DATE,'DD') THEN TRUNC(p_DATE - 1, 'DD')
																										ELSE TRUNC(p_DATE, 'DD') END;
                 END IF;


                BEGIN
                    SELECT TRAIT_VAL INTO v_DESIRED_MW
                    FROM IT_TRAIT_SCHEDULE ITS
                    WHERE ITS.TRANSACTION_ID = p_TXN_ID_UNIT
                    AND ITS.TRAIT_GROUP_ID = v_DESIRED_MW_ID
                    AND ITS.SCHEDULE_DATE = p_DATE;
                EXCEPTION
                    WHEN NO_DATA_FOUND THEN
                        v_DESIRED_MW := 0;
                END;

                v_BAL_ENERGY_OFFER := 0;
                IF v_RT_MW > 1.1 * v_DESIRED_MW THEN
                    v_RT_MW := v_DESIRED_MW;
                END IF;

                IF v_SCHED_MW = 0 THEN
                    v_BAL_ENERGY_OFFER := v_RT_MW * v_P1;
                ELSE

                IF v_RT_MW <= v_Q1 OR v_Q2 IS NULL THEN
                    v_BAL_ENERGY_OFFER := v_RT_MW * v_P1;
                 ELSIF v_RT_MW <= v_Q2 OR v_Q3 IS NULL THEN
                    v_BAL_ENERGY_OFFER := (v_Q1 * v_P1) + ((v_RT_MW - V_Q1) * v_P2);
                 ELSIF v_RT_MW <= v_Q3  OR v_Q4 IS NULL THEN
                    v_BAL_ENERGY_OFFER := (v_Q1 * v_P1) + ((v_Q2-v_Q1) * v_P2) + ((v_RT_MW - v_Q2) * v_P3);
                 ELSIF v_RT_MW <= v_Q4 OR v_Q5 IS NULL THEN
                    v_BAL_ENERGY_OFFER := (v_Q1 * v_P1) + ((v_Q2-v_Q1) * v_P2) + ((v_Q3- v_Q2) * v_P3) + ((v_RT_MW - v_Q3) * v_P4);
                 ELSIF v_RT_MW <= v_Q5 OR v_Q6 IS NULL THEN
                    v_BAL_ENERGY_OFFER := (v_Q1 * v_P1) + ((v_Q2-v_Q1) * v_P2) + ((v_Q3- v_Q2) * v_P3) + ((v_Q4 - v_Q3) * v_P4)+ ((v_RT_MW - v_Q4) * v_P5);
                ELSIF v_RT_MW <= v_Q6 OR v_Q7 IS NULL THEN
                    v_BAL_ENERGY_OFFER := (v_Q1 * v_P1) + ((v_Q2-v_Q1) * v_P2) + ((v_Q3- v_Q2) * v_P3) + ((v_Q4 - v_Q3) * v_P4)+ ((v_Q5 - v_Q4) * v_P5) + ((v_RT_MW - v_Q5) * v_P6);
                ELSIF v_RT_MW <= v_Q7 OR v_Q8 IS NULL THEN
                    v_BAL_ENERGY_OFFER := (v_Q1 * v_P1) + ((v_Q2-v_Q1) * v_P2) + ((v_Q3- v_Q2) * v_P3) + ((v_Q4 - v_Q3) * v_P4)+ ((v_Q5 - v_Q4) * v_P5) + ((V_Q6 - v_Q5) * v_P6)+ ((v_RT_MW - v_Q6) * v_P7);
                ELSIF v_RT_MW <= v_Q8 OR v_Q9 IS NULL THEN
                v_BAL_ENERGY_OFFER := (v_Q1 * v_P1) + ((v_Q2-v_Q1) * v_P2) + ((v_Q3- v_Q2) * v_P3) + ((v_Q4 - v_Q3) * v_P4)+
                ((v_Q5 - v_Q4) * v_P5) + ((V_Q6 - v_Q5) * v_P6)+ ((V_Q7 - v_Q6) * v_P7)+ ((v_RT_MW - v_Q7) * v_P8);
                ELSIF v_RT_MW <= v_Q9 OR v_Q10 IS NULL THEN
                v_BAL_ENERGY_OFFER := (v_Q1 * v_P1) + ((v_Q2-v_Q1) * v_P2) + ((v_Q3- v_Q2) * v_P3) + ((v_Q4 - v_Q3) * v_P4)+
                ((v_Q5 - v_Q4) * v_P5) + ((V_Q6 - v_Q5) * v_P6)+ ((V_Q7 - v_Q6) * v_P7)+ ((V_Q8 - v_Q7) * v_P8)+((v_RT_MW - v_Q8) * v_P9);
                ELSIF v_RT_MW <= v_Q10 THEN
                 v_BAL_ENERGY_OFFER := (v_Q1 * v_P1) + ((v_Q2-v_Q1) * v_P2) + ((v_Q3- v_Q2) * v_P3) + ((v_Q4 - v_Q3) * v_P4)+
                ((v_Q5 - v_Q4) * v_P5) + ((V_Q6 - v_Q5) * v_P6)+ ((V_Q7 - v_Q6) * v_P7)+ ((V_Q8 - v_Q7) * v_P8)+ ((V_Q9 - v_Q8) * v_P9)+ ((v_RT_MW - v_Q9) * v_P10);
                ELSE
                   v_BAL_ENERGY_OFFER := 0;
                END IF;

            END IF;
                BEGIN
                    SELECT TRAIT_VAL INTO v_RT_STARTUP_COST
                    FROM IT_TRAIT_SCHEDULE ITS
                    WHERE ITS.TRANSACTION_ID = p_TXN_ID_UNIT
                    AND ITS.TRAIT_GROUP_ID = v_STARTUP_CST_APPLY
                    AND ITS.TRAIT_INDEX = 1
                    AND ITS.SET_NUMBER = 1
                    AND ITS.SCHEDULE_DATE = p_DATE;
                EXCEPTION
                    WHEN NO_DATA_FOUND THEN
                        v_RT_STARTUP_COST := 0;
                END;

                v_RT_OFFER_AMOUNT := v_BAL_ENERGY_OFFER + v_RT_NO_LOAD_COST + v_RT_STARTUP_COST;

            END IF;
        ELSE
            v_RT_OFFER_AMOUNT := 0;
        END IF;

    --put the hourly detail into the PJM_OPRES_GEN_CREDITS table
 /*   IF v_RT_OFFER_AMOUNT > 0 THEN
        BEGIN
            SELECT GENERATOR_ID INTO v_GEN_ID
            FROM PJM_OPRES_GEN_CREDITS_DETAIL
            WHERE GENERATOR_ID = p_GEN_ID
            AND CHARGE_DATE = p_DATE
            AND STATEMENT_STATE = GA.INTERNAL_STATE;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
            v_REC.GENERATOR_ID := p_GEN_ID;
            v_REC.STATEMENT_STATE := GA.INTERNAL_STATE;
            v_REC.CHARGE_DATE := p_DATE;
            v_REC.SCHEDULE_ID := p_GEN_ID;
            v_REC.Rt_Energ_Offer := v_BAL_ENERGY_OFFER;
            v_REC.Rt_No_Load_Cost := v_RT_NO_LOAD_COST;
            v_REC.Rt_Startup_Cost := v_RT_STARTUP_COST;
            v_REC.Rt_Offer := v_RT_OFFER_AMOUNT;

            UPDATE_OP_RES_DETAIL('Insert', v_REC, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
            v_UPDATE := FALSE;
        END;

        IF v_UPDATE = TRUE THEN
            UPDATE_OP_RES_DETAIL('Update BalOffer', NULL, p_DATE, p_GEN_ID, NULL, NULL,
                            NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, v_BAL_ENERGY_OFFER,
                            v_RT_NO_LOAD_COST, v_RT_STARTUP_COST, v_RT_OFFER_AMOUNT);
        END IF;
    END IF;*/
    END IF;
    RETURN v_RT_OFFER_AMOUNT;
END GET_RT_OFFER_AMOUNT;
---------------------------------------------------------------------------------------
--used in Balancing Operating Reserves Credits
FUNCTION GET_BAL_MKT_VALUE
    (
    p_GEN_ID IN VARCHAR2,
    p_DATE IN DATE,
    p_CONTRACT_ID IN NUMBER,
    p_SCHEDULE_TYPE IN NUMBER,
    p_TXN_ID_UNIT IN NUMBER,
		p_OWN_PERCENT IN NUMBER
    ) RETURN NUMBER IS
v_SERVICE_PT_ID NUMBER(9);
v_LMP_VALUE NUMBER;
v_BAL_MKT_VALUE NUMBER := 0;
v_SCHED_MW NUMBER;
v_RT_MW NUMBER;
--v_GEN_ID VARCHAR2(16);
--v_UPDATE BOOLEAN := TRUE;
--v_REC PJM_OPRES_GEN_CREDITS_DETAIL%ROWTYPE;
BEGIN

    SELECT SR.SERVICE_POINT_ID INTO v_SERVICE_PT_ID
    FROM SUPPLY_RESOURCE SR, TEMPORAL_ENTITY_ATTRIBUTE T
    WHERE T.ATTRIBUTE_NAME = 'PJM_PNODEID'
    AND T.ATTRIBUTE_VAL = p_GEN_ID
    AND T.OWNER_ENTITY_ID = SR.RESOURCE_ID;

    SELECT NVL(MV.PRICE,0) INTO v_LMP_VALUE
    FROM MARKET_PRICE M, MARKET_PRICE_VALUE MV
    WHERE M.MARKET_PRICE_TYPE = 'Locational Marginal Price'
    AND M.MARKET_TYPE = 'RealTime'
    AND M.POD_ID = v_SERVICE_PT_ID
    AND MV.PRICE_CODE = 'A'
    AND MV.MARKET_PRICE_ID = M.MARKET_PRICE_ID
    AND MV.PRICE_DATE = p_DATE;

		IF p_OWN_PERCENT < 1 THEN
			v_SCHED_MW := GET_DA_GEN_BEFORE_OWN_PERCENT(p_TXN_ID_UNIT, p_DATE);
		ELSE
         BEGIN
          SELECT AMOUNT INTO v_SCHED_MW
          FROM IT_SCHEDULE
          WHERE TRANSACTION_ID = p_TXN_ID_UNIT
          AND SCHEDULE_DATE = p_DATE
          AND SCHEDULE_STATE = GA.INTERNAL_STATE
          AND SCHEDULE_TYPE = p_SCHEDULE_TYPE;
      EXCEPTION
          WHEN NO_DATA_FOUND THEN
              v_SCHED_MW := 0;
      END;
		END IF;

    IF p_OWN_PERCENT < 1 THEN
  		--don't restrict by contract, get total rt gen
			BEGIN
         	SELECT SUM(NVL(ITS.AMOUNT,0))INTO v_RT_MW
          FROM IT_SCHEDULE ITS, INTERCHANGE_TRANSACTION T
          WHERE T.TRANSACTION_TYPE = 'Generation'
          AND T.COMMODITY_ID IN (SELECT COMMODITY_ID FROM IT_COMMODITY WHERE COMMODITY_NAME = 'RealTime Energy')
          AND T.RESOURCE_ID = (SELECT OWNER_ENTITY_ID FROM TEMPORAL_ENTITY_ATTRIBUTE WHERE
              ATTRIBUTE_NAME = 'PJM_PNODEID' AND ATTRIBUTE_VAL = p_GEN_ID)
          AND T.TRANSACTION_ID = ITS.TRANSACTION_ID
          AND ITS.SCHEDULE_DATE = p_DATE
          AND ITS.SCHEDULE_STATE = GA.INTERNAL_STATE
          AND ITS.SCHEDULE_TYPE = p_SCHEDULE_TYPE;
      EXCEPTION
          WHEN NO_DATA_FOUND THEN
              v_RT_MW := 0;
      END;
		ELSE
  		BEGIN
         /* SELECT NVL(ITS.AMOUNT,0) INTO v_RT_MW
          FROM INTERCHANGE_TRANSACTION IT, IT_SCHEDULE ITS
          WHERE IT.TRANSACTION_TYPE = 'Generation'
          AND IT.COMMODITY_ID = (SELECT COMMODITY_ID FROM IT_COMMODITY WHERE COMMODITY_NAME = 'RealTime Energy')
          AND IT.CONTRACT_ID = P_CONTRACT_ID
          AND IT.POD_ID = v_SERVICE_PT_ID
          AND ITS.TRANSACTION_ID = IT.TRANSACTION_ID
          AND ITS.SCHEDULE_STATE = GA.INTERNAL_STATE
          AND ITS.SCHEDULE_TYPE = p_SCHEDULE_TYPE
          AND ITS.SCHEDULE_DATE = p_DATE
          AND ITS.AMOUNT <> 0;*/
					SELECT SUM(NVL(ITS.AMOUNT,0)) INTO v_RT_MW
          FROM IT_SCHEDULE ITS, INTERCHANGE_TRANSACTION T
          WHERE T.TRANSACTION_TYPE = 'Generation'
          AND T.COMMODITY_ID IN (SELECT COMMODITY_ID FROM IT_COMMODITY WHERE COMMODITY_NAME = 'RealTime Energy')
          AND T.RESOURCE_ID = (SELECT OWNER_ENTITY_ID FROM TEMPORAL_ENTITY_ATTRIBUTE WHERE
              ATTRIBUTE_NAME = 'PJM_PNODEID' AND ATTRIBUTE_VAL = p_GEN_ID)
          AND T.TRANSACTION_ID = ITS.TRANSACTION_ID
					AND T.CONTRACT_ID = p_CONTRACT_ID
          AND ITS.SCHEDULE_DATE = p_DATE
          AND ITS.SCHEDULE_STATE = GA.INTERNAL_STATE
          AND ITS.SCHEDULE_TYPE = p_SCHEDULE_TYPE;
      EXCEPTION
          WHEN NO_DATA_FOUND THEN
              v_RT_MW := 0;
      END;
		END IF;

    v_BAL_MKT_VALUE := (v_RT_MW - v_SCHED_MW) * v_LMP_VALUE;

    --put the hourly detail into the PJM_OPRES_GEN_CREDITS table
 /*   BEGIN
        SELECT GENERATOR_ID INTO v_GEN_ID
        FROM PJM_OPRES_GEN_CREDITS_DETAIL
        WHERE GENERATOR_ID = p_GEN_ID
        AND CHARGE_DATE = p_DATE
        AND STATEMENT_STATE = GA.INTERNAL_STATE;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
        v_REC.GENERATOR_ID := p_GEN_ID;
        v_REC.STATEMENT_STATE := GA.INTERNAL_STATE;
        v_REC.CHARGE_DATE := p_DATE;
        v_REC.SCHEDULE_ID := p_GEN_ID;
        v_REC.RT_LMP := v_LMP_VALUE;
        v_REC.RT_MW := v_RT_MW;
        v_REC.BAL_ENERG_MKT_VAL := v_BAL_MKT_VALUE;

        UPDATE_OP_RES_DETAIL('Insert', v_REC, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
        v_UPDATE := FALSE;
    END;

    IF v_UPDATE = TRUE THEN
        UPDATE_OP_RES_DETAIL('Update BalValue', NULL, p_DATE, p_GEN_ID, NULL, NULL, NULL, NULL,
                             NULL, NULL, NULL, v_LMP_VALUE, v_RT_MW, v_BAL_MKT_VALUE);
    END IF;    */

    RETURN NVL(v_BAL_MKT_VALUE,0);

END GET_BAL_MKT_VALUE;
---------------------------------------------------------------------------------------
FUNCTION GET_SPOT_CHARGE_AMT
    (
    p_COMPONENT_EXT_ID IN VARCHAR2,
    p_DATE IN DATE,
    p_CONTRACT_ID IN NUMBER
    ) RETURN NUMBER IS
v_CHARGE_ID BILLING_STATEMENT.CHARGE_ID%TYPE;
v_SPOT_AMT NUMBER;
BEGIN

    SELECT CHARGE_ID INTO v_CHARGE_ID
    FROM BILLING_STATEMENT B
    WHERE B.STATEMENT_STATE = GA.INTERNAL_STATE
    AND B.COMPONENT_ID = (SELECT COMPONENT_ID FROM COMPONENT WHERE EXTERNAL_IDENTIFIER =
                            p_COMPONENT_EXT_ID)
    AND B.STATEMENT_DATE = CASE WHEN from_cut(p_DATE,'EDT') = TRUNC(from_cut(p_DATE,'EDT'),'DD')
		THEN from_cut(p_DATE,'EDT') - 1 ELSE TRUNC(from_cut(P_date,'EDT'),'DD') END
    AND B.ENTITY_ID = (SELECT BILLING_ENTITY_ID FROM INTERCHANGE_CONTRACT
                        WHERE CONTRACT_ID = p_CONTRACT_ID);

    SELECT F.CHARGE_AMOUNT INTO v_SPOT_AMT
    FROM FORMULA_CHARGE F
    WHERE F.CHARGE_ID = v_CHARGE_ID
    AND F.CHARGE_DATE = p_DATE;

    RETURN NVL(v_SPOT_AMT, 0);

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        v_SPOT_AMT := 0;
        RETURN v_SPOT_AMT;
END GET_SPOT_CHARGE_AMT;
---------------------------------------------------------------------------------------------------
FUNCTION GET_DA_CREDIT_AMOUNT
    (
    p_GEN_ID IN VARCHAR2,
    p_DATE IN DATE,
    p_CONTRACT_ID IN NUMBER
    ) RETURN NUMBER IS
v_CHARGE_ID BILLING_STATEMENT.CHARGE_ID%TYPE;
v_DA_CREDIT NUMBER;
BEGIN
    --get charge_id
    SELECT CHARGE_ID INTO v_CHARGE_ID
    FROM BILLING_STATEMENT B
    WHERE B.STATEMENT_STATE = GA.INTERNAL_STATE
    AND B.COMPONENT_ID = (SELECT COMPONENT_ID FROM COMPONENT WHERE EXTERNAL_IDENTIFIER =
                            'PJM-2370')
    AND B.STATEMENT_DATE = TRUNC(p_DATE, 'DD')
    AND B.ENTITY_ID = (SELECT BILLING_ENTITY_ID FROM INTERCHANGE_CONTRACT
                        WHERE CONTRACT_ID = p_CONTRACT_ID);

    BEGIN
        SELECT VARIABLE_VAL INTO v_DA_CREDIT
        FROM FORMULA_CHARGE_VARIABLE F
        WHERE CHARGE_ID = v_CHARGE_ID
        AND F.ITERATOR_ID IN(SELECT ITERATOR_ID FROM FORMULA_CHARGE_ITERATOR
                                WHERE ITERATOR1 = p_GEN_ID AND CHARGE_ID = v_CHARGE_ID)
        AND TRUNC(F.CHARGE_DATE, 'DD') = TRUNC(p_DATE, 'DD')
        AND VARIABLE_VAL > 0;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            v_DA_CREDIT := 0;
    END;

    RETURN NVL(v_DA_CREDIT, 0);

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        v_DA_CREDIT := 0;
        RETURN v_DA_CREDIT;
END GET_DA_CREDIT_AMOUNT;
-----------------------------------------------------------------------------------------
FUNCTION GET_BAL_CREDIT_REVENUE
    (
    p_DATE IN DATE,
    p_CONTRACT_ID IN NUMBER,
		p_REVENUE_TYPE IN VARCHAR2,
		p_GEN_ID IN VARCHAR2
    ) RETURN NUMBER IS
v_CHARGE_ID BILLING_STATEMENT.CHARGE_ID%TYPE;
v_REVENUE NUMBER;
BEGIN
    SELECT C.COMBINED_CHARGE_ID INTO v_CHARGE_ID
    FROM BILLING_STATEMENT B, COMBINATION_CHARGE C
    WHERE B.STATEMENT_STATE = GA.EXTERNAL_STATE
    AND B.COMPONENT_ID = (SELECT COMPONENT_ID FROM COMPONENT WHERE EXTERNAL_IDENTIFIER =
                            'PJM-2375')
    AND B.STATEMENT_DATE = TRUNC(p_DATE, 'DD')
    AND B.ENTITY_ID = (SELECT BILLING_ENTITY_ID FROM INTERCHANGE_CONTRACT
                        WHERE CONTRACT_ID = p_CONTRACT_ID)
		AND C.CHARGE_ID = B.CHARGE_ID
		AND C.COMPONENT_ID = (SELECT COMPONENT_ID FROM COMPONENT WHERE EXTERNAL_IDENTIFIER =
													'PJM:BalOpResCredExcess');

    BEGIN
        SELECT SUM(VARIABLE_VAL) INTO v_REVENUE
        FROM FORMULA_CHARGE_VARIABLE F
        WHERE CHARGE_ID = v_CHARGE_ID
				AND VARIABLE_NAME = p_REVENUE_TYPE
				AND F.ITERATOR_ID IN(SELECT ITERATOR_ID FROM FORMULA_CHARGE_ITERATOR
                                WHERE ITERATOR1 = p_GEN_ID AND CHARGE_ID = v_CHARGE_ID);
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            v_REVENUE := 0;
    END;

    RETURN NVL(v_REVENUE, 0);

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        v_REVENUE := 0;
        RETURN v_REVENUE;
END GET_BAL_CREDIT_REVENUE;
-----------------------------------------------------------------------------------------
FUNCTION GET_DA_CREDIT
 (
    p_GEN_ID IN VARCHAR2,
    p_DATE IN DATE,
    p_CONTRACT_ID IN NUMBER,
    p_SCHEDULE_TYPE IN NUMBER
    ) RETURN NUMBER IS

v_DA_OFFER NUMBER := 0;
v_DA_OFFER_HOUR NUMBER :=0;
v_DA_MKT_VAL NUMBER := 0;
v_DA_CREDIT NUMBER :=0;
v_INTERVAL_BEGIN_DATE DATE;
v_INTERVAL_END_DATE DATE;
v_DATE DATE;
v_OWNERSHIP_PERCENTAGE NUMBER;
--v_DA_MKT_VAL_hr NUMBER := 0;

BEGIN

		UT.CUT_DAY_INTERVAL_RANGE(GA.ELECTRIC_MODEL,
                                  trunc(p_DATE, 'DD'),
                                  trunc(p_DATE, 'DD'),
                                  MM_PJM_UTIL.g_PJM_TIME_ZONE,
                                  60,
                                  v_INTERVAL_BEGIN_DATE,
                                  v_INTERVAL_END_DATE);
		v_OWNERSHIP_PERCENTAGE := GET_OWNERSHIP_PERCENTAGE(p_GEN_ID, p_CONTRACT_ID, TRUNC(p_DATE,'DD'));
    v_DATE := v_INTERVAL_BEGIN_DATE;

    WHILE v_DATE <= v_INTERVAL_END_DATE LOOP
        v_DA_OFFER_HOUR := GET_DA_OFFER_AMOUNT(p_GEN_ID, v_DATE, p_CONTRACT_ID, p_SCHEDULE_TYPE, v_OWNERSHIP_PERCENTAGE);
        v_DA_OFFER := v_DA_OFFER + nvl(v_DA_OFFER_HOUR,0);
        --DBMS_OUTPUT.put_line('OFFER ' || v_DA_OFFER_HOUR);
    IF v_DA_OFFER_HOUR <> -1 THEN
        --v_DA_MKT_VAL_hr := nvl(GET_DA_MKT_VALUE(p_GEN_ID,v_DATE,p_CONTRACT_ID, p_SCHEDULE_TYPE),0);
        v_DA_MKT_VAL := v_DA_MKT_VAL + nvl(GET_DA_MKT_VALUE(p_GEN_ID,v_DATE,p_CONTRACT_ID, p_SCHEDULE_TYPE, v_OWNERSHIP_PERCENTAGE),0);
        --DBMS_OUTPUT.put_line('VALUE ' || v_DA_MKT_VAL_hr);
    END IF;
        v_DATE := v_DATE + 1/24;
    END LOOP;

    IF v_DA_MKT_VAL = 0 THEN
        v_DA_CREDIT := 0;
    ELSIF v_DA_OFFER > v_DA_MKT_VAL THEN
        v_DA_CREDIT := (v_DA_OFFER - v_DA_MKT_VAL) * v_OWNERSHIP_PERCENTAGE;
    ELSE
            v_DA_CREDIT := 0;
    END IF;

    RETURN v_DA_CREDIT;

END GET_DA_CREDIT;
----------------------------------------------------------------------------------------------
FUNCTION GET_BAL_CREDIT
 (
    p_GEN_ID IN VARCHAR2,
    p_DATE IN DATE,
    p_CONTRACT_ID IN NUMBER,
    p_SCHEDULE_TYPE IN NUMBER
    ) RETURN NUMBER IS
v_RT_OFFER NUMBER := 0;
v_RT_OFFER_HOUR NUMBER :=0;
v_BAL_MKT_VAL NUMBER := 0;
v_BAL_CREDIT NUMBER :=0;
v_INTERVAL_BEGIN_DATE DATE;
v_INTERVAL_END_DATE DATE;
v_DATE DATE;
v_SUM NUMBER;
v_DA_MKT_VALUE NUMBER := 0;
v_DA_MKT_VALUE_HR NUMBER;
--v_BAL_MKT_VAL_hr NUMBER;
v_TRANSACTION_ID_UNIT NUMBER(9);
v_COMMIT_STATUS VARCHAR2(16);
v_OWNERSHIP_PERCENTAGE NUMBER;
v_TRAIT_ID NUMBER(3) := MM_PJM_UTIL.g_TG_UPD_COMMIT_STATUS;

BEGIN

    UT.CUT_DAY_INTERVAL_RANGE(GA.ELECTRIC_MODEL,
                              trunc(p_DATE, 'DD'),
                              trunc(p_DATE, 'DD'),
                              MM_PJM_UTIL.g_PJM_TIME_ZONE,
                              60,
                              v_INTERVAL_BEGIN_DATE,
                              v_INTERVAL_END_DATE);

	v_OWNERSHIP_PERCENTAGE := GET_OWNERSHIP_PERCENTAGE(p_GEN_ID, p_CONTRACT_ID, TRUNC(p_DATE,'DD'));
    v_DATE := v_INTERVAL_BEGIN_DATE;

    SELECT TRANSACTION_ID INTO v_TRANSACTION_ID_UNIT
    FROM PJM_GEN_TXNS_BY_TYPE p
    WHERE p.PJM_Gen_Id = p_GEN_ID
    AND p.CONTRACT_ID = p_CONTRACT_ID
    AND p.PJM_GEN_TXN_TYPE = 'Unit Data';

    WHILE v_DATE <= v_INTERVAL_END_DATE LOOP
        -- query for commit status; if commit status for current day/hour is not Economic then
        -- there is no Bal Op Reserves Credit
        SELECT T.TRAIT_VAL INTO v_COMMIT_STATUS
        FROM IT_TRAIT_SCHEDULE T
        WHERE T.TRANSACTION_ID = v_TRANSACTION_ID_UNIT
        AND T.SCHEDULE_STATE = GA.INTERNAL_STATE
        AND T.SCHEDULE_DATE = v_DATE
        AND T.TRAIT_GROUP_ID = v_TRAIT_ID;


        IF v_COMMIT_STATUS <> 'MustRun' THEN
            v_RT_OFFER_HOUR := GET_RT_OFFER_AMOUNT(p_GEN_ID, v_DATE, p_CONTRACT_ID,
													p_SCHEDULE_TYPE,
													v_TRANSACTION_ID_UNIT, v_OWNERSHIP_PERCENTAGE);
            --dbms_output.put_line('RT Offer Amount ' || V_rt_offer_hour);
            v_RT_OFFER := v_RT_OFFER + nvl(v_RT_OFFER_HOUR,0);
            --v_DA_MKT_VALUE := v_DA_MKT_VALUE + GET_DA_MKT_VALUE(p_GEN_ID, v_DATE, p_CONTRACT_ID, p_SCHEDULE_TYPE);
            BEGIN
                SELECT P.DA_VALUE INTO v_DA_MKT_VALUE_HR
                FROM PJM_OPRES_GEN_CREDITS_DETAIL P
                WHERE P.GENERATOR_ID = p_GEN_ID
                AND P.CHARGE_DATE = v_DATE
                AND P.STATEMENT_STATE = GA.INTERNAL_STATE;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    v_DA_MKT_VALUE_HR :=0;
            END;
             v_DA_MKT_VALUE := v_DA_MKT_VALUE + NVL(v_DA_MKT_VALUE_HR,0);

            IF v_RT_OFFER_HOUR <> -1 AND v_RT_OFFER_HOUR <> 0 THEN
                --v_BAL_MKT_VAL_hr := nvl(GET_BAL_MKT_VALUE(p_GEN_ID,v_DATE,p_CONTRACT_ID, p_SCHEDULE_TYPE),0);
                --dbms_output.put_line('Bal Mkt Val ' || v_BAL_MKT_VAL_hr);
                v_BAL_MKT_VAL := v_BAL_MKT_VAL + nvl(GET_BAL_MKT_VALUE(p_GEN_ID,v_DATE,p_CONTRACT_ID, p_SCHEDULE_TYPE, v_TRANSACTION_ID_UNIT, v_OWNERSHIP_PERCENTAGE),0);
            END IF;
        END IF;
        v_DATE := v_DATE + 1/24;
    END LOOP;

    v_SUM := v_BAL_MKT_VAL + v_DA_MKT_VALUE + GET_DA_CREDIT_AMOUNT(p_GEN_ID, p_DATE, p_CONTRACT_ID)
              + GET_BAL_CREDIT_REVENUE(p_DATE, p_CONTRACT_ID, 'ReactiveServRevenue', p_GEN_ID)
							+ GET_BAL_CREDIT_REVENUE(p_DATE, p_CONTRACT_ID, 'RegMktRevenue', p_GEN_ID)
							+ GET_BAL_CREDIT_REVENUE(p_DATE, p_CONTRACT_ID, 'SpinReserveRevenue', p_GEN_ID);
    IF v_RT_OFFER > v_SUM THEN
        --IF v_SUM >= 0 THEN
            v_BAL_CREDIT := (v_RT_OFFER - v_SUM) * v_OWNERSHIP_PERCENTAGE;
        --END IF;
    END IF;

    RETURN v_BAL_CREDIT;

END GET_BAL_CREDIT;
----------------------------------------------------------------------------------------------
FUNCTION GET_OFFER_AT_RT_MW
    (
    p_GEN_ID IN VARCHAR2,
    p_DATE IN DATE,
    p_CONTRACT_ID IN NUMBER,
    p_SCHEDULE_TYPE IN NUMBER
    ) RETURN NUMBER IS
TYPE BO_QTY_MAP IS TABLE OF NUMBER(10,3) INDEX BY BINARY_INTEGER;
TYPE BO_PRICE_MAP IS TABLE OF NUMBER(10,3) INDEX BY BINARY_INTEGER;
v_SCHED_ID NUMBER(3) := MM_PJM_UTIL.g_TG_MR_ACTIVE_SCHEDULE;
v_BO_QTY_MAP BO_QTY_MAP;
v_BO_PRICE_MAP BO_PRICE_MAP;
v_RT_MW NUMBER;
v_SERVICE_PT_ID NUMBER(9);
v_ACTIVE_SCHED NUMBER(3) := 0;
v_ACT_SCHED VARCHAR2(16);
v_TRANSACTION_ID_UNIT NUMBER(9);
v_TRANSACTION_ID_SCHED NUMBER(9);
v_OFFER NUMBER := 0;
v_COUNT NUMBER(2);
v_Q1 NUMBER;
v_P1 NUMBER;
BEGIN

    SELECT SR.SERVICE_POINT_ID INTO v_SERVICE_PT_ID
    FROM SUPPLY_RESOURCE SR, TEMPORAL_ENTITY_ATTRIBUTE T
    WHERE T.ATTRIBUTE_NAME = 'PJM_PNODEID'
    AND T.ATTRIBUTE_VAL = p_GEN_ID
    AND T.OWNER_ENTITY_ID = SR.RESOURCE_ID;

    --get rt_mw for the current hour
     BEGIN
        SELECT NVL(SUM(ITS.AMOUNT),0) INTO v_RT_MW
        FROM INTERCHANGE_TRANSACTION IT, IT_SCHEDULE ITS
        WHERE IT.TRANSACTION_TYPE = 'Generation'
        AND IT.COMMODITY_ID = (SELECT COMMODITY_ID FROM IT_COMMODITY WHERE COMMODITY_NAME = 'RealTime Energy')
        AND IT.CONTRACT_ID = p_CONTRACT_ID
        --AND IT.TRANSACTION_IDENTIFIER = p_GEN_ID
        AND IT.POD_ID = v_SERVICE_PT_ID
        AND ITS.TRANSACTION_ID = IT.TRANSACTION_ID
        AND ITS.SCHEDULE_STATE = GA.INTERNAL_STATE
        AND ITS.SCHEDULE_TYPE = p_SCHEDULE_TYPE
        AND ITS.SCHEDULE_DATE = p_DATE
        AND ITS.AMOUNT <> 0;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            v_RT_MW := 0;
    END;

    SELECT TRANSACTION_ID INTO v_TRANSACTION_ID_UNIT
    FROM PJM_GEN_TXNS_BY_TYPE p
    WHERE p.PJM_Gen_Id = p_GEN_ID
    AND p.CONTRACT_ID = p_CONTRACT_ID
    AND p.PJM_GEN_TXN_TYPE = 'Unit Data';

    BEGIN
          SELECT TRAIT_VAL INTO v_ACT_SCHED
          FROM IT_TRAIT_SCHEDULE
          WHERE TRANSACTION_ID = v_TRANSACTION_ID_UNIT
          AND TRAIT_GROUP_ID = v_SCHED_ID
          AND SCHEDULE_DATE = p_DATE
          AND SCHEDULE_STATE = GA.INTERNAL_STATE;
          v_ACTIVE_SCHED := TO_NUMBER(v_ACT_SCHED);
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            BEGIN
                SELECT DISTINCT TRAIT_VAL INTO v_ACT_SCHED
                FROM IT_TRAIT_SCHEDULE
                WHERE TRANSACTION_ID = v_TRANSACTION_ID_UNIT
                AND TRAIT_GROUP_ID = v_SCHED_ID
                AND TRUNC(SCHEDULE_DATE,'DD') = TRUNC(p_DATE, 'DD')
                AND SCHEDULE_STATE = GA.INTERNAL_STATE;
                v_ACTIVE_SCHED := TO_NUMBER(v_ACT_SCHED);
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    v_ACTIVE_SCHED := 0;
            END;
    END;

    IF NVL(v_ACTIVE_SCHED,0) <> 0 THEN
        SELECT TRANSACTION_ID INTO v_TRANSACTION_ID_SCHED
        FROM PJM_GEN_TXNS_BY_TYPE p
        WHERE P.CONTRACT_ID = p_CONTRACT_ID
        AND P.PJM_Gen_Id = p_GEN_ID
        AND P.PJM_GEN_TXN_TYPE = 'Schedule'
        AND p.AGREEMENT_TYPE = v_ACTIVE_SCHED;

        SELECT COUNT(SET_NUMBER) INTO v_COUNT
				FROM BID_OFFER_SET B
        WHERE B.TRANSACTION_ID = v_TRANSACTION_ID_SCHED
				AND SCHEDULE_STATE = GA.INTERNAL_STATE
				AND TRUNC(B.SCHEDULE_DATE, 'DD') = TRUNC(p_DATE, 'DD');

        FOR I IN 1..v_COUNT LOOP
            SELECT QUANTITY, PRICE
            INTO v_Q1, v_P1
            FROM BID_OFFER_SET
            WHERE TRANSACTION_ID = v_TRANSACTION_ID_SCHED
						AND SCHEDULE_STATE = GA.INTERNAL_STATE
            AND SET_NUMBER = I
            AND TRUNC(SCHEDULE_DATE, 'DD') = TRUNC(p_DATE, 'DD');

            v_BO_PRICE_MAP(I) := v_P1;
            v_BO_QTY_MAP(I) := v_Q1;
        END LOOP;

        FOR J IN 1..v_COUNT LOOP
            IF v_RT_MW <= v_BO_QTY_MAP(J) THEN
                v_OFFER := v_BO_PRICE_MAP(J);
                EXIT;
            END IF;

        END LOOP;
    END IF;

    RETURN NVL(v_OFFER,0);

END GET_OFFER_AT_RT_MW;
----------------------------------------------------------------------------------------------
FUNCTION GET_INADVERENT_MW
	(
	p_CONTRACT_ID IN NUMBER,
	p_DATE IN DATE,
	p_SCHEDULE_TYPE IN NUMBER
	) RETURN NUMBER IS
v_VAL NUMBER;
BEGIN

	SELECT NVL(SUM(S.AMOUNT),0) INTO v_VAL
	FROM IT_SCHEDULE S, INTERCHANGE_TRANSACTION T
	WHERE T.CONTRACT_ID = p_CONTRACT_ID
	AND T.TRANSACTION_TYPE = 'Load'
	AND T.COMMODITY_ID = (SELECT COMMODITY_ID FROM IT_COMMODITY WHERE COMMODITY_NAME = 'RealTime Energy')
	AND S.SCHEDULE_TYPE = p_SCHEDULE_TYPE
	AND S.SCHEDULE_STATE = GA.INTERNAL_STATE
	AND S.SCHEDULE_DATE = p_DATE
	AND T.TRANSACTION_NAME LIKE 'InadvertentMeterValues%'
	AND T.TRANSACTION_ID = S.TRANSACTION_ID;

	RETURN v_VAL;

EXCEPTION
	WHEN NO_DATA_FOUND THEN
		RETURN 0;

END GET_INADVERENT_MW;
-----------------------------------------------------------------------------------------------
FUNCTION GET_MWH_REDUCED
    (
    p_GEN_ID IN VARCHAR2,
    p_CONTRACT IN NUMBER,
    p_DATE IN DATE
    ) RETURN NUMBER IS
v_TXN_ID NUMBER(9);
v_MWH_REDUCED NUMBER;
v_TRAIT_VAL VARCHAR2(16);
v_TRAIT_ID NUMBER(3) := MM_PJM_UTIL.g_TG_OUT_MWH_REDUCED;
BEGIN

    BEGIN
        SELECT P.TRANSACTION_ID INTO v_TXN_ID
        FROM PJM_GEN_TXNS_BY_TYPE P, INTERCHANGE_TRANSACTION I
        WHERE P.PJM_Gen_Id = p_GEN_ID
        AND P.PJM_GEN_TXN_TYPE = 'Unit Data'
        AND I.CONTRACT_ID = p_CONTRACT
        AND I.TRANSACTION_ID = P.TRANSACTION_ID;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            v_TXN_ID := 0;
            v_MWH_REDUCED := 0;
    END;

    IF v_TXN_ID > 0 THEN
        BEGIN
            SELECT I.TRAIT_VAL INTO v_TRAIT_VAL
            FROM IT_TRAIT_SCHEDULE I
            WHERE I.TRANSACTION_ID = v_TXN_ID
            AND I.TRAIT_GROUP_ID = v_TRAIT_ID
            AND I.SCHEDULE_DATE = p_DATE;

            v_MWH_REDUCED := TO_NUMBER(v_TRAIT_VAL);
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                v_MWH_REDUCED := 0;
        END;
    END IF;

    RETURN NVL(v_MWH_REDUCED,0);

END GET_MWH_REDUCED;
-----------------------------------------------------------------------------------------------
FUNCTION GET_POSITIVE_RT_GEN
 		(
    p_CONTRACT IN NUMBER,
    p_SCHED_DATE IN DATE,
    p_SCHEDULE_TYPE IN NUMBER,
		p_SERVICE_POINT IN VARCHAR2
    ) RETURN NUMBER IS
v_RT_GEN NUMBER;
BEGIN
		SELECT SUM(ITS.AMOUNT) INTO v_RT_GEN
    FROM IT_SCHEDULE ITS, INTERCHANGE_TRANSACTION I
    WHERE I.CONTRACT_ID = p_CONTRACT
    AND I.TRANSACTION_TYPE = 'Generation'
    AND I.COMMODITY_ID = (SELECT COMMODITY_ID FROM IT_COMMODITY WHERE COMMODITY_NAME = 'RealTime Energy')
		AND I.POD_ID = (SELECT SERVICE_POINT_ID FROM SERVICE_POINT WHERE SERVICE_POINT_NAME = p_SERVICE_POINT)
    AND ITS.TRANSACTION_ID = I.TRANSACTION_ID
    AND I.END_DATE >= p_SCHED_DATE
    AND ITS.SCHEDULE_DATE = p_SCHED_DATE
    AND ITS.SCHEDULE_TYPE = p_SCHEDULE_TYPE
    AND ITS.SCHEDULE_STATE = GA.INTERNAL_STATE
    AND ITS.AMOUNT > 0;

		RETURN NVL(v_RT_GEN,0);
END GET_POSITIVE_RT_GEN;
--------------------------------------------------------------------------------------------------
/*FUNCTION GET_POSITIVE_RT_GEN
    (
    p_CONTRACT IN NUMBER,
    p_SCHED_DATE IN DATE,
    p_SCHEDULE_TYPE IN NUMBER
    ) RETURN NUMBER IS
v_RT_GEN NUMBER := 0;
v_RT_GEN_HR NUMBER :=0;
v_ALLOC NUMBER;
v_ALLOC_ATTR_ID NUMBER(9);
v_CONTRACT_ID_AETS NUMBER(9);
v_CONTRACT_ID_APMP NUMBER(9);
CURSOR c_RT_GEN(v_CONTRACT_ID IN NUMBER) IS
	SELECT I.TRANSACTION_ID "TXN_ID",
				I.POD_ID "SERVICE_PT"
	FROM INTERCHANGE_TRANSACTION I
	WHERE I.CONTRACT_ID = v_CONTRACT_ID
	AND I.TRANSACTION_TYPE = 'Generation'
	AND I.COMMODITY_ID = (SELECT COMMODITY_ID FROM IT_COMMODITY WHERE COMMODITY_NAME = 'RealTime Energy')
	AND I.END_DATE >= p_SCHED_DATE;

BEGIN
/*	BEGIN
		SELECT CONTRACT_ID
		INTO v_CONTRACT_ID_AETS
		FROM INTERCHANGE_CONTRACT
		WHERE CONTRACT_NAME = 'AETS';
		SELECT CONTRACT_ID
		INTO v_CONTRACT_ID_APMP
		FROM INTERCHANGE_CONTRACT
		WHERE CONTRACT_NAME = 'AP MP';
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			v_CONTRACT_ID_AETS := 0;
			v_CONTRACT_ID_APMP := 0;
	END;

	IF p_CONTRACT = v_CONTRACT_ID_AETS OR p_CONTRACT = v_CONTRACT_ID_APMP THEN
		IF p_CONTRACT = v_CONTRACT_ID_AETS THEN
			ID.ID_FOR_ENTITY_ATTRIBUTE('AYE Supply Allocation %', 'SERVICE_POINT', 'Number', TRUE, v_ALLOC_ATTR_ID);
		ELSE
			ID.ID_FOR_ENTITY_ATTRIBUTE('AYE MonPower Allocation %', 'SERVICE_POINT', 'Number', TRUE, v_ALLOC_ATTR_ID);
		END IF;

		FOR v_GEN IN c_RT_GEN(v_CONTRACT_ID_AETS) LOOP

			BEGIN
				SELECT T.ATTRIBUTE_VAL INTO v_ALLOC
				FROM TEMPORAL_ENTITY_ATTRIBUTE T
				WHERE T.OWNER_ENTITY_ID = v_GEN.Service_Pt
				AND T.ATTRIBUTE_ID = v_ALLOC_ATTR_ID;
			EXCEPTION
				WHEN NO_DATA_FOUND THEN
					v_ALLOC := 100;
			END;

			SELECT SUM(ITS.AMOUNT) * (v_ALLOC/100) INTO v_RT_GEN_HR
			FROM IT_SCHEDULE ITS
			WHERE ITS.TRANSACTION_ID = v_GEN.Txn_Id
			AND ITS.SCHEDULE_DATE = p_SCHED_DATE
    	AND ITS.SCHEDULE_TYPE = p_SCHEDULE_TYPE
    	AND ITS.SCHEDULE_STATE = GA.INTERNAL_STATE
    	AND ITS.AMOUNT > 0;

			v_RT_GEN := v_RT_GEN + NVL(v_RT_GEN_HR,0);
			IF p_CONTRACT = v_CONTRACT_ID_APMP THEN
				v_RT_GEN := v_RT_GEN + GET_POS_RT_GEN(p_CONTRACT,p_SCHED_DATE,p_SCHEDULE_TYPE);
			END IF;

		END LOOP;

	ELSE
			v_RT_GEN := GET_POS_RT_GEN(p_CONTRACT,p_SCHED_DATE,p_SCHEDULE_TYPE);
--END IF;
    RETURN NVL(v_RT_GEN,0);
END GET_POSITIVE_RT_GEN;*/
---------------------------------------------------------------------------------------------------
FUNCTION GET_RT_LOAD_FROM_GEN
    (
    p_CONTRACT IN NUMBER,
    p_SCHED_DATE IN DATE,
    p_SCHEDULE_TYPE IN NUMBER,
		p_SERVICE_POINT IN VARCHAR2
    ) RETURN NUMBER IS
v_RT_LOAD NUMBER;
BEGIN

    SELECT SUM(ITS.AMOUNT) INTO v_RT_LOAD
    FROM IT_SCHEDULE ITS, INTERCHANGE_TRANSACTION I
    WHERE I.CONTRACT_ID = p_CONTRACT
    AND I.TRANSACTION_TYPE = 'Generation'
		AND I.POD_ID = (SELECT SERVICE_POINT_ID FROM SERVICE_POINT WHERE SERVICE_POINT_NAME = p_SERVICE_POINT)
    AND I.COMMODITY_ID = (SELECT COMMODITY_ID FROM IT_COMMODITY WHERE COMMODITY_NAME = 'RealTime Energy')
    AND ITS.TRANSACTION_ID = I.TRANSACTION_ID
    AND I.END_DATE >= p_SCHED_DATE
    AND ITS.SCHEDULE_DATE = p_SCHED_DATE
    AND ITS.SCHEDULE_TYPE = p_SCHEDULE_TYPE
    AND ITS.SCHEDULE_STATE = GA.INTERNAL_STATE
    AND ITS.AMOUNT < 0;

    RETURN NVL(ABS(v_RT_LOAD),0);
END GET_RT_LOAD_FROM_GEN;
---------------------------------------------------------------------------------------------------
/*FUNCTION GET_RT_LOAD_FROM_GEN
    (
    p_CONTRACT IN NUMBER,
    p_SCHED_DATE IN DATE,
    p_SCHEDULE_TYPE IN NUMBER
    ) RETURN NUMBER IS
v_RT_LOAD NUMBER := 0;
v_RT_LOAD_HR NUMBER :=0;
v_CONTRACT_ID_AETS NUMBER(9);
v_CONTRACT_ID_APMP NUMBER(9);
v_ALLOC_ATTR_ID NUMBER(9);
v_ALLOC NUMBER;
CURSOR c_RT_GEN(v_CONTRACT_ID IN NUMBER) IS
	SELECT I.TRANSACTION_ID "TXN_ID",
				I.POD_ID "SERVICE_PT"
	FROM INTERCHANGE_TRANSACTION I
	WHERE I.CONTRACT_ID = v_CONTRACT_ID
	AND I.TRANSACTION_TYPE = 'Generation'
	AND I.COMMODITY_ID = (SELECT COMMODITY_ID FROM IT_COMMODITY WHERE COMMODITY_NAME = 'RealTime Energy')
	AND I.END_DATE >= p_SCHED_DATE;
BEGIN
/*	BEGIN
		SELECT CONTRACT_ID
		INTO v_CONTRACT_ID_AETS
		FROM INTERCHANGE_CONTRACT
		WHERE CONTRACT_NAME = 'AETS';
		SELECT CONTRACT_ID
		INTO v_CONTRACT_ID_APMP
		FROM INTERCHANGE_CONTRACT
		WHERE CONTRACT_NAME = 'AP MP';
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			v_CONTRACT_ID_AETS := 0;
			v_CONTRACT_ID_APMP := 0;
	END;

	IF p_CONTRACT = v_CONTRACT_ID_AETS OR p_CONTRACT = v_CONTRACT_ID_APMP THEN
		IF p_CONTRACT = v_CONTRACT_ID_AETS THEN
			ID.ID_FOR_ENTITY_ATTRIBUTE('AYE Supply Allocation %', 'SERVICE_POINT', 'Number', TRUE, v_ALLOC_ATTR_ID);
		ELSE
			ID.ID_FOR_ENTITY_ATTRIBUTE('AYE MonPower Allocation %', 'SERVICE_POINT', 'Number', TRUE, v_ALLOC_ATTR_ID);
		END IF;

		FOR v_GEN IN c_RT_GEN(v_CONTRACT_ID_AETS) LOOP

			BEGIN
				SELECT T.ATTRIBUTE_VAL INTO v_ALLOC
				FROM TEMPORAL_ENTITY_ATTRIBUTE T
				WHERE T.OWNER_ENTITY_ID = v_GEN.Service_Pt
				AND T.ATTRIBUTE_ID = v_ALLOC_ATTR_ID;
			EXCEPTION
				WHEN NO_DATA_FOUND THEN
					v_ALLOC := 100;
			END;

			SELECT SUM(ITS.AMOUNT) * (v_ALLOC/100) INTO v_RT_LOAD_HR
			FROM IT_SCHEDULE ITS
			WHERE ITS.TRANSACTION_ID = v_GEN.Txn_Id
			AND ITS.SCHEDULE_DATE = p_SCHED_DATE
    	AND ITS.SCHEDULE_TYPE = p_SCHEDULE_TYPE
    	AND ITS.SCHEDULE_STATE = GA.INTERNAL_STATE
    	AND ITS.AMOUNT < 0;

			v_RT_LOAD := v_RT_LOAD + ABS(NVL(v_RT_LOAD_HR,0));
			IF p_CONTRACT = v_CONTRACT_ID_APMP THEN
				v_RT_LOAD := v_RT_LOAD + GET_RT_LD_FROM_GEN(p_CONTRACT,p_SCHED_DATE,p_SCHEDULE_TYPE);
			END IF;

		END LOOP;
	ELSE	*/
			--v_RT_LOAD := GET_RT_LD_FROM_GEN(p_CONTRACT,p_SCHED_DATE,p_SCHEDULE_TYPE);


  /*  SELECT SUM(ITS.AMOUNT) INTO v_RT_LOAD
    FROM IT_SCHEDULE ITS, INTERCHANGE_TRANSACTION I
    WHERE I.CONTRACT_ID = p_CONTRACT
    AND I.TRANSACTION_TYPE = 'Generation'
    AND I.COMMODITY_ID = (SELECT COMMODITY_ID FROM IT_COMMODITY WHERE COMMODITY_NAME = 'RealTime Energy')
    AND ITS.TRANSACTION_ID = I.TRANSACTION_ID
    AND I.END_DATE >= p_SCHED_DATE
    AND ITS.SCHEDULE_DATE = p_SCHED_DATE
    AND ITS.SCHEDULE_TYPE = p_SCHEDULE_TYPE
    AND ITS.SCHEDULE_STATE = GA.INTERNAL_STATE
    AND ITS.AMOUNT < 0;

--END IF;

    RETURN NVL(ABS(v_RT_LOAD),0);
END GET_RT_LOAD_FROM_GEN;*/
---------------------------------------------------------------------------------------------------
FUNCTION GET_DA_GEN
    (
    p_CONTRACT IN NUMBER,
    p_SCHED_DATE IN DATE,
    p_SCHEDULE_TYPE IN NUMBER
    ) RETURN NUMBER IS
v_DA_GEN NUMBER;
BEGIN

    SELECT SUM(ITS.AMOUNT) INTO v_DA_GEN
    FROM IT_SCHEDULE ITS, INTERCHANGE_TRANSACTION I
    WHERE I.CONTRACT_ID = p_CONTRACT
    AND I.TRANSACTION_TYPE = 'Generation'
    AND I.COMMODITY_ID = (SELECT COMMODITY_ID FROM IT_COMMODITY WHERE COMMODITY_NAME = 'DayAhead Energy')
    AND ITS.TRANSACTION_ID = I.TRANSACTION_ID
    AND I.END_DATE >= p_SCHED_DATE
    AND ITS.SCHEDULE_DATE = p_SCHED_DATE
    AND ITS.SCHEDULE_TYPE = p_SCHEDULE_TYPE
    AND ITS.SCHEDULE_STATE = GA.INTERNAL_STATE;

    RETURN NVL(v_DA_GEN,0);
END GET_DA_GEN;
---------------------------------------------------------------------------------------------------
FUNCTION GET_DA_GEN_ALLOCATED
    (
    p_CONTRACT IN NUMBER,
    p_SCHED_DATE IN DATE,
    p_SCHEDULE_TYPE IN NUMBER
    ) RETURN NUMBER IS
v_DA_GEN NUMBER := 0;
v_DA_GEN_HR NUMBER :=0;
v_ALLOC NUMBER;
v_CONTRACT_ID_AETS NUMBER(9);
v_CONTRACT_ID_APMP NUMBER(9);
v_ALLOC_ATTR_ID NUMBER(9);

CURSOR c_DA_GEN(v_CONTRACT_ID IN NUMBER) IS
	SELECT I.TRANSACTION_ID "TXN_ID",
				I.POD_ID "SERVICE_PT"
	FROM INTERCHANGE_TRANSACTION I, PJM_GEN_TXNS_BY_TYPE P
	WHERE I.CONTRACT_ID = v_CONTRACT_ID
	AND I.TRANSACTION_TYPE = 'Generation'
	AND I.COMMODITY_ID = (SELECT COMMODITY_ID FROM IT_COMMODITY WHERE COMMODITY_NAME = 'DayAhead Energy')
	AND I.END_DATE >= p_SCHED_DATE
	AND P.TRANSACTION_ID = I.TRANSACTION_ID
	AND P.PJM_GEN_TXN_TYPE = 'Unit Data';
BEGIN
	BEGIN
		SELECT CONTRACT_ID
		INTO v_CONTRACT_ID_AETS
		FROM INTERCHANGE_CONTRACT
		WHERE CONTRACT_NAME = 'AETS';
		SELECT CONTRACT_ID
		INTO v_CONTRACT_ID_APMP
		FROM INTERCHANGE_CONTRACT
		WHERE CONTRACT_NAME = 'AP MP';
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			v_CONTRACT_ID_AETS := 0;
			v_CONTRACT_ID_APMP := 0;
	END;

	IF p_CONTRACT = v_CONTRACT_ID_AETS OR p_CONTRACT = v_CONTRACT_ID_APMP THEN
		IF p_CONTRACT = v_CONTRACT_ID_AETS THEN
			ID.ID_FOR_ENTITY_ATTRIBUTE('AYE Supply Allocation %', 'SERVICE_POINT', 'Number', TRUE, v_ALLOC_ATTR_ID);
		ELSE
			ID.ID_FOR_ENTITY_ATTRIBUTE('AYE MonPower Allocation %', 'SERVICE_POINT', 'Number', TRUE, v_ALLOC_ATTR_ID);
		END IF;

		FOR v_GEN IN c_DA_GEN(v_CONTRACT_ID_AETS) LOOP
			BEGIN
				SELECT T.ATTRIBUTE_VAL INTO v_ALLOC
				FROM TEMPORAL_ENTITY_ATTRIBUTE T
				WHERE T.OWNER_ENTITY_ID = v_GEN.Service_Pt
				AND T.ATTRIBUTE_ID = v_ALLOC_ATTR_ID;
			EXCEPTION
				WHEN NO_DATA_FOUND THEN
					v_ALLOC := 100;
			END;

			SELECT SUM(ITS.AMOUNT) * (v_ALLOC/100)
			INTO v_DA_GEN_HR
			FROM IT_SCHEDULE ITS
			WHERE ITS.TRANSACTION_ID = v_GEN.Txn_Id
			AND ITS.SCHEDULE_TYPE = p_SCHEDULE_TYPE
			AND ITS.SCHEDULE_STATE = GA.INTERNAL_STATE
			AND ITS.SCHEDULE_DATE = p_SCHED_DATE;

			v_DA_GEN := v_DA_GEN + NVL(v_DA_GEN_HR,0);
			IF p_CONTRACT = v_CONTRACT_ID_APMP THEN
				v_DA_GEN := v_DA_GEN + GET_DA_GEN(p_CONTRACT,p_SCHED_DATE, p_SCHEDULE_TYPE);
			END IF;
		END LOOP;

	ELSE
		v_DA_GEN := GET_DA_GEN(p_CONTRACT,p_SCHED_DATE, p_SCHEDULE_TYPE);
	END IF;

	RETURN v_DA_GEN;

END GET_DA_GEN_ALLOCATED;
---------------------------------------------------------------------------------------------------
FUNCTION GET_RT_LOAD_FROM_GEN_MNTH
    (
    p_CONTRACT IN NUMBER,
    p_SCHED_DATE IN DATE,
    p_SCHEDULE_TYPE IN NUMBER
    ) RETURN NUMBER IS
v_RT_LOAD NUMBER;
v_BEG_DATE DATE;
v_END_DATE DATE;
BEGIN

    v_BEG_DATE := TRUNC(p_SCHED_DATE, 'MM');
    v_END_DATE := LAST_DAY(v_BEG_DATE);

    SELECT SUM(ITS.AMOUNT) INTO v_RT_LOAD
    FROM IT_SCHEDULE ITS, INTERCHANGE_TRANSACTION I
    WHERE I.CONTRACT_ID = p_CONTRACT
    AND I.TRANSACTION_TYPE = 'Generation'
    AND I.COMMODITY_ID = (SELECT COMMODITY_ID FROM IT_COMMODITY WHERE COMMODITY_NAME = 'RealTime Energy')
    AND ITS.TRANSACTION_ID = I.TRANSACTION_ID
    AND ITS.SCHEDULE_DATE BETWEEN v_BEG_DATE AND v_END_DATE
    AND ITS.SCHEDULE_TYPE = p_SCHEDULE_TYPE
    AND ITS.SCHEDULE_STATE = GA.INTERNAL_STATE
    AND ITS.AMOUNT < 0;

    RETURN NVL(ABS(v_RT_LOAD),0);
END GET_RT_LOAD_FROM_GEN_MNTH;
-----------------------------------------------------------------------------------------------
FUNCTION GET_OFFER_AT_DA_MW
    (
    p_GEN_ID IN VARCHAR2,
    p_CONTRACT IN NUMBER,
    p_DATE IN DATE,
    p_SCHEDULE_TYPE IN NUMBER
    ) RETURN NUMBER IS
v_TRANSACTION_ID_UNIT NUMBER(9);
v_TRANSACTION_ID_SCHED NUMBER(9);
v_DA_MW NUMBER;
v_DA_ENERGY_OFFER NUMBER := 0;
v_ACTIVE_SCHED NUMBER(3) := 0;
v_ACT_SCHED VARCHAR2(16);
v_COUNT BINARY_INTEGER;
v_SCHED_ID NUMBER(3) := MM_PJM_UTIL.g_TG_MR_ACTIVE_SCHEDULE;
v_P1 NUMBER;
v_P2 NUMBER;
v_P3 NUMBER;
v_P4 NUMBER;
v_P5 NUMBER;
v_P6 NUMBER;
v_P7 NUMBER;
v_P8 NUMBER;
v_P9 NUMBER;
v_P10 NUMBER;
v_Q1 NUMBER;
v_Q2 NUMBER;
v_Q3 NUMBER;
v_Q4 NUMBER;
v_Q5 NUMBER;
v_Q6 NUMBER;
v_Q7 NUMBER;
v_Q8 NUMBER;
v_Q9 NUMBER;
v_Q10 NUMBER;
BEGIN

    SELECT TRANSACTION_ID INTO v_TRANSACTION_ID_UNIT
    FROM PJM_GEN_TXNS_BY_TYPE p
    WHERE p.PJM_Gen_Id = p_GEN_ID
    AND p.CONTRACT_ID = p_CONTRACT
    AND p.PJM_GEN_TXN_TYPE = 'Unit Data';

    BEGIN
        SELECT AMOUNT INTO v_DA_MW
        FROM IT_SCHEDULE
        WHERE TRANSACTION_ID = v_TRANSACTION_ID_UNIT
        AND SCHEDULE_DATE = p_DATE
        AND SCHEDULE_STATE = GA.INTERNAL_STATE
        AND SCHEDULE_TYPE = p_SCHEDULE_TYPE;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            v_DA_ENERGY_OFFER := -1;
    END;

    IF v_DA_ENERGY_OFFER <> -1 THEN
        BEGIN
            SELECT TRAIT_VAL INTO v_ACT_SCHED
            FROM IT_TRAIT_SCHEDULE
            WHERE TRANSACTION_ID = v_TRANSACTION_ID_UNIT
            AND TRAIT_GROUP_ID = v_SCHED_ID
            AND SCHEDULE_DATE = p_DATE
            AND SCHEDULE_STATE = GA.INTERNAL_STATE;
            v_ACTIVE_SCHED := TO_NUMBER(v_ACT_SCHED);
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                v_ACTIVE_SCHED := 0;
        END;

        IF NVL(v_ACTIVE_SCHED,0) <> 0 THEN
            SELECT TRANSACTION_ID INTO v_TRANSACTION_ID_SCHED
            FROM PJM_GEN_TXNS_BY_TYPE p
            WHERE P.CONTRACT_ID = p_CONTRACT
            AND P.PJM_Gen_Id = p_GEN_ID
            AND P.PJM_GEN_TXN_TYPE = 'Schedule'
            AND p.AGREEMENT_TYPE = v_ACTIVE_SCHED;

            SELECT COUNT(SET_NUMBER) INTO v_COUNT
			FROM BID_OFFER_SET B
            WHERE B.TRANSACTION_ID = v_TRANSACTION_ID_SCHED
			AND SCHEDULE_STATE = GA.INTERNAL_STATE
			AND TRUNC(B.SCHEDULE_DATE, 'DD') = TRUNC(p_DATE, 'DD');

            IF v_COUNT >=1 THEN
                SELECT QUANTITY, PRICE
                INTO v_Q1, v_P1
                FROM BID_OFFER_SET
                WHERE TRANSACTION_ID = v_TRANSACTION_ID_SCHED
                AND SET_NUMBER = 1
    						AND SCHEDULE_STATE = GA.INTERNAL_STATE
                AND TRUNC(SCHEDULE_DATE, 'DD') = TRUNC(p_DATE, 'DD');
            END IF;

            IF v_COUNT >=2 THEN
                SELECT QUANTITY, PRICE
                INTO v_Q2, v_P2
                FROM BID_OFFER_SET
                WHERE TRANSACTION_ID = v_TRANSACTION_ID_SCHED
                AND SET_NUMBER = 2
    						AND SCHEDULE_STATE = GA.INTERNAL_STATE
                AND TRUNC(SCHEDULE_DATE, 'DD') = TRUNC(p_DATE, 'DD');
             END IF;

             IF v_COUNT >=3 THEN
                SELECT QUANTITY, PRICE
                INTO v_Q3, v_P3
                FROM BID_OFFER_SET
                WHERE TRANSACTION_ID = v_TRANSACTION_ID_SCHED
                AND SET_NUMBER = 3
    						AND SCHEDULE_STATE = GA.INTERNAL_STATE
                AND TRUNC(SCHEDULE_DATE, 'DD') = TRUNC(p_DATE, 'DD');
             END IF;

             IF v_COUNT >=4 THEN
                SELECT QUANTITY, PRICE
                INTO v_Q4, v_P4
                FROM BID_OFFER_SET
                WHERE TRANSACTION_ID = v_TRANSACTION_ID_SCHED
                AND SET_NUMBER = 4
    						AND SCHEDULE_STATE = GA.INTERNAL_STATE

                AND TRUNC(SCHEDULE_DATE, 'DD') = TRUNC(p_DATE, 'DD');
             END IF;

             IF v_COUNT >=5 THEN
                SELECT QUANTITY, PRICE
                INTO v_Q5, v_P5
                FROM BID_OFFER_SET
                WHERE TRANSACTION_ID = v_TRANSACTION_ID_SCHED
                AND SET_NUMBER = 5
    						AND SCHEDULE_STATE = GA.INTERNAL_STATE
                AND TRUNC(SCHEDULE_DATE, 'DD') = TRUNC(p_DATE, 'DD');
             END IF;

             IF v_COUNT >=6 THEN
                SELECT QUANTITY, PRICE
                INTO v_Q6, v_P6
                FROM BID_OFFER_SET
                WHERE TRANSACTION_ID = v_TRANSACTION_ID_SCHED
                AND SET_NUMBER = 6
    						AND SCHEDULE_STATE = GA.INTERNAL_STATE
                AND TRUNC(SCHEDULE_DATE, 'DD') = TRUNC(p_DATE, 'DD');
             END IF;

             IF v_COUNT >=7 THEN
                SELECT QUANTITY, PRICE
                INTO v_Q7, v_P7
                FROM BID_OFFER_SET
                WHERE TRANSACTION_ID = v_TRANSACTION_ID_SCHED
                AND SET_NUMBER = 7
    						AND SCHEDULE_STATE = GA.INTERNAL_STATE
                AND TRUNC(SCHEDULE_DATE, 'DD') = TRUNC(p_DATE, 'DD');
             END IF;

             IF v_COUNT >=8 THEN
                SELECT QUANTITY, PRICE
                INTO v_Q8, v_P8
                FROM BID_OFFER_SET
                WHERE TRANSACTION_ID = v_TRANSACTION_ID_SCHED
                AND SET_NUMBER = 8
    						AND SCHEDULE_STATE = GA.INTERNAL_STATE
                AND TRUNC(SCHEDULE_DATE, 'DD') = TRUNC(p_DATE, 'DD');
             END IF;

             IF v_COUNT >=9 THEN
                SELECT QUANTITY, PRICE
                INTO v_Q9, v_P9
                FROM BID_OFFER_SET
                WHERE TRANSACTION_ID = v_TRANSACTION_ID_SCHED
                AND SET_NUMBER = 9
    						AND SCHEDULE_STATE = GA.INTERNAL_STATE
                AND TRUNC(SCHEDULE_DATE, 'DD') = TRUNC(p_DATE, 'DD');
             END IF;

             IF v_COUNT >=10 THEN
                SELECT QUANTITY, PRICE
                INTO v_Q10, v_P10
                FROM BID_OFFER_SET
                WHERE TRANSACTION_ID = v_TRANSACTION_ID_SCHED
                AND SET_NUMBER = 10
    						AND SCHEDULE_STATE = GA.INTERNAL_STATE
                AND TRUNC(SCHEDULE_DATE, 'DD') = TRUNC(p_DATE, 'DD');
            END IF;

            IF v_DA_MW <= v_Q1 THEN
                v_DA_ENERGY_OFFER := v_DA_MW * v_P1;
            ELSIF v_DA_MW <= v_Q2 THEN
                v_DA_ENERGY_OFFER := (v_Q1 * v_P1) + ((v_DA_MW - V_Q1) * v_P2);
            ELSIF v_DA_MW <= v_Q3 THEN
                v_DA_ENERGY_OFFER := (v_Q1 * v_P1) + ((v_Q2-v_Q1) * v_P2) + ((v_DA_MW - v_Q2) * v_P3);
            ELSIF v_DA_MW <= v_Q4 THEN
                v_DA_ENERGY_OFFER := (v_Q1 * v_P1) + ((v_Q2-v_Q1) * v_P2) + ((v_Q3- v_Q2) * v_P3) + ((v_DA_MW - v_Q3) * v_P4);
            ELSIF v_DA_MW <= v_Q5 THEN
                v_DA_ENERGY_OFFER := (v_Q1 * v_P1) + ((v_Q2-v_Q1) * v_P2) + ((v_Q3- v_Q2) * v_P3) + ((v_Q4 - v_Q3) * v_P4)+ ((v_DA_MW - v_Q4) * v_P5);
            ELSIF v_DA_MW <= v_Q6 THEN
                v_DA_ENERGY_OFFER := (v_Q1 * v_P1) + ((v_Q2-v_Q1) * v_P2) + ((v_Q3- v_Q2) * v_P3) + ((v_Q4 - v_Q3) * v_P4)+ ((v_Q5 - v_Q4) * v_P5) + ((v_DA_MW - v_Q5) * v_P6);
            ELSIF v_DA_MW <= v_Q7 THEN
                v_DA_ENERGY_OFFER := (v_Q1 * v_P1) + ((v_Q2-v_Q1) * v_P2) + ((v_Q3- v_Q2) * v_P3) + ((v_Q4 - v_Q3) * v_P4)+ ((v_Q5 - v_Q4) * v_P5) + ((V_Q6 - v_Q5) * v_P6)+ ((v_DA_MW - v_Q6) * v_P7);
            ELSIF v_DA_MW <= v_Q8 THEN
                v_DA_ENERGY_OFFER := (v_Q1 * v_P1) + ((v_Q2-v_Q1) * v_P2) + ((v_Q3- v_Q2) * v_P3) + ((v_Q4 - v_Q3) * v_P4)+
                    ((v_Q5 - v_Q4) * v_P5) + ((V_Q6 - v_Q5) * v_P6)+ ((V_Q7 - v_Q6) * v_P7)+ ((v_DA_MW - v_Q7) * v_P8);
            ELSIF v_DA_MW <= v_Q9 THEN
                v_DA_ENERGY_OFFER := (v_Q1 * v_P1) + ((v_Q2-v_Q1) * v_P2) + ((v_Q3- v_Q2) * v_P3) + ((v_Q4 - v_Q3) * v_P4)+
                    ((v_Q5 - v_Q4) * v_P5) + ((V_Q6 - v_Q5) * v_P6)+ ((V_Q7 - v_Q6) * v_P7)+ ((V_Q8 - v_Q7) * v_P8)+((v_DA_MW - v_Q8) * v_P9);
            ELSIF v_DA_MW <= v_Q10 THEN
                v_DA_ENERGY_OFFER := (v_Q1 * v_P1) + ((v_Q2-v_Q1) * v_P2) + ((v_Q3- v_Q2) * v_P3) + ((v_Q4 - v_Q3) * v_P4)+
                    ((v_Q5 - v_Q4) * v_P5) + ((V_Q6 - v_Q5) * v_P6)+ ((V_Q7 - v_Q6) * v_P7)+ ((V_Q8 - v_Q7) * v_P8)+ ((V_Q9 - v_Q8) * v_P9)+ ((v_DA_MW - v_Q9) * v_P10);
            ELSE
                v_DA_ENERGY_OFFER := 0;
            END IF;
                IF v_DA_ENERGY_OFFER <> 0 THEN
                    v_DA_ENERGY_OFFER := v_DA_ENERGY_OFFER / v_DA_MW;
                END IF;
        ELSE
            v_DA_ENERGY_OFFER := 0;
        END IF;
    ELSE
        v_DA_ENERGY_OFFER := 0;
    END IF;

        RETURN NVL(v_DA_ENERGY_OFFER,0);

END GET_OFFER_AT_DA_MW;
---------------------------------------------------------------------------------------------------
FUNCTION GET_ARR_RATE
    (
    p_CONTRACT_ID IN NUMBER,
    p_DATE IN DATE
    ) RETURN NUMBER IS
v_PSE VARCHAR2(32);
v_RATE NUMBER;
BEGIN
    SELECT CONTRACT_ALIAS INTO v_PSE
    FROM INTERCHANGE_CONTRACT
    WHERE CONTRACT_ID = p_CONTRACT_ID;

    v_PSE := SUBSTR(v_PSE,1, INSTR(v_PSE,': PJM') - 1);

    BEGIN
        SELECT MP.PRICE INTO v_RATE
        FROM MARKET_PRICE M, MARKET_PRICE_VALUE MP
        WHERE M.MARKET_PRICE_TYPE = 'ARR Rate'
        AND M.EXTERNAL_IDENTIFIER = 'PJM: ' || v_PSE || ':ARR Rate'
        AND MP.MARKET_PRICE_ID = M.MARKET_PRICE_ID
        AND MP.PRICE_CODE = 'A'
        AND TRUNC(MP.PRICE_DATE) = TRUNC(p_DATE);
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            v_RATE := 0;
    END;

    RETURN NVL(v_RATE,0);

END GET_ARR_RATE;
------------------------------------------------------------------------------------------------------
FUNCTION GET_PEAK_LOAD
    (
    p_CONTRACT_ID IN NUMBER,
    p_DATE IN DATE,
    p_STATEMENT_TYPE IN NUMBER
    ) RETURN NUMBER IS
v_PSE VARCHAR2(32);
v_LOAD NUMBER := 0;
v_CONTRACT_ID NUMBER(9);
BEGIN

    --Allegheny customization, for AETS use peak load from AP
    SELECT CONTRACT_NAME INTO v_PSE
    FROM INTERCHANGE_CONTRACT
    WHERE CONTRACT_ID = p_CONTRACT_ID;

    IF v_PSE = 'AETS' THEN
        SELECT CONTRACT_ID INTO v_CONTRACT_ID
        FROM INTERCHANGE_CONTRACT
        WHERE CONTRACT_NAME = 'AP';
    ELSE
        v_CONTRACT_ID := p_CONTRACT_ID;
    END IF;

    BEGIN
        SELECT S.AMOUNT INTO v_LOAD
        FROM IT_SCHEDULE S, INTERCHANGE_TRANSACTION T
        WHERE T.TRANSACTION_TYPE = 'Coincident Pk Ld'
        AND T.CONTRACT_ID = v_CONTRACT_ID
        AND S.TRANSACTION_ID = T.TRANSACTION_ID
        AND S.SCHEDULE_STATE = GA.INTERNAL_STATE
        AND S.SCHEDULE_TYPE = p_STATEMENT_TYPE
        AND TRUNC(S.SCHEDULE_DATE) = TRUNC(p_DATE);
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            v_LOAD := 0;
    END;

    RETURN v_LOAD;

END GET_PEAK_LOAD;
-------------------------------------------------------------------------------------------------
FUNCTION GET_CONGESTION_FLAG
    (
    p_DATE IN DATE,
    p_CONTRACT IN NUMBER,
    p_SCHEDULE_TYPE IN NUMBER
    ) RETURN NUMBER IS
v_FLAG NUMBER;
BEGIN
    SELECT S.AMOUNT INTO v_FLAG
    FROM IT_SCHEDULE S, INTERCHANGE_TRANSACTION T
    WHERE T.CONTRACT_ID = p_CONTRACT
    AND T.TRANSACTION_TYPE = 'Congestion Flag'
    AND S.SCHEDULE_DATE = p_DATE
    AND S.SCHEDULE_STATE = GA.INTERNAL_STATE
    AND S.SCHEDULE_TYPE = p_SCHEDULE_TYPE
    AND S.TRANSACTION_ID = T.TRANSACTION_ID;

    RETURN v_FLAG;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN -1;
END GET_CONGESTION_FLAG;
-------------------------------------------------------------------------------------------------
FUNCTION GET_BAL_IMPL_CONG_COMP_AMT
    (
    p_COMPONENT_EXT_ID IN VARCHAR2,
    p_DATE IN DATE,
    p_CONTRACT_ID IN NUMBER
    ) RETURN NUMBER IS
v_CHARGE_ID BILLING_STATEMENT.CHARGE_ID%TYPE;
--v_COMB_CHARGE_ID1 BILLING_STATEMENT.CHARGE_ID%TYPE;
--v_COMB_CHARGE_ID2 BILLING_STATEMENT.CHARGE_ID%TYPE;
v_NET_BILL_AMT NUMBER;
BEGIN

 /*   SELECT CHARGE_ID INTO v_CHARGE_ID
    FROM BILLING_STATEMENT B
    WHERE B.STATEMENT_STATE = GA.INTERNAL_STATE
    AND B.COMPONENT_ID = (SELECT COMPONENT_ID FROM COMPONENT WHERE EXTERNAL_IDENTIFIER =
                            'PJM:BalTxCongChg')
		AND B.STATEMENT_DATE = TRUNC(p_DATE, 'DD')
		--AND B.STATEMENT_DATE = CASE WHEN p_DATE = TRUNC(p_DATE,'DD') THEN p_DATE - 1 ELSE TRUNC(p_DATE,'DD') END
    AND B.ENTITY_ID = (SELECT BILLING_ENTITY_ID FROM INTERCHANGE_CONTRACT
                        WHERE CONTRACT_ID = p_CONTRACT_ID);

 		SELECT COMBINED_CHARGE_ID INTO v_COMB_CHARGE_ID1
    FROM COMBINATION_CHARGE C
		WHERE C.COMPONENT_ID = (SELECT COMPONENT_ID FROM COMPONENT WHERE EXTERNAL_IDENTIFIER =
                            'PJM:BalTxCongChg:Imp')
		AND C.CHARGE_ID = v_CHARGE_ID;

		SELECT COMBINED_CHARGE_ID INTO v_COMB_CHARGE_ID2
    FROM COMBINATION_CHARGE C
		WHERE C.COMPONENT_ID = (SELECT COMPONENT_ID FROM COMPONENT WHERE EXTERNAL_IDENTIFIER =
                            p_COMPONENT_EXT_ID)
		AND C.CHARGE_ID = v_COMB_CHARGE_ID1;

    SELECT SUM(F.CHARGE_AMOUNT) INTO v_NET_BILL_AMT
    FROM FORMULA_CHARGE F
    WHERE F.CHARGE_ID = v_COMB_CHARGE_ID2
    AND F.CHARGE_DATE = p_DATE;*/


		SELECT CHARGE_ID INTO v_CHARGE_ID
    FROM BILLING_STATEMENT B
    WHERE B.STATEMENT_STATE = GA.INTERNAL_STATE
    AND B.COMPONENT_ID = (SELECT COMPONENT_ID FROM COMPONENT WHERE EXTERNAL_IDENTIFIER =
                            p_COMPONENT_EXT_ID)
		AND B.STATEMENT_DATE = TRUNC(p_DATE, 'DD')
		--AND B.STATEMENT_DATE = CASE WHEN p_DATE = TRUNC(p_DATE,'DD') THEN p_DATE - 1 ELSE TRUNC(p_DATE,'DD') END
    AND B.ENTITY_ID = (SELECT BILLING_ENTITY_ID FROM INTERCHANGE_CONTRACT
                        WHERE CONTRACT_ID = p_CONTRACT_ID);

		SELECT SUM(F.CHARGE_AMOUNT) INTO v_NET_BILL_AMT
    FROM FORMULA_CHARGE F
    WHERE F.CHARGE_ID = v_CHARGE_ID
    AND F.CHARGE_DATE = p_DATE;

    RETURN NVL(v_NET_BILL_AMT, 0);

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        v_NET_BILL_AMT := 0;
        RETURN v_NET_BILL_AMT;
END GET_BAL_IMPL_CONG_COMP_AMT;
------------------------------------------------------------------------------------------------------
FUNCTION GET_EXTERNAL_CHG_AMOUNT
    (
    p_BILL_ENTITY IN NUMBER,
    p_COMPONENT_ID IN NUMBER,
    p_DATE IN DATE,
    p_STATEMENT_TYPE IN NUMBER
    ) RETURN NUMBER IS
v_CHARGE_AMOUNT BILLING_STATEMENT.CHARGE_AMOUNT%TYPE;
BEGIN

    SELECT CHARGE_AMOUNT
    INTO v_CHARGE_AMOUNT
    FROM BILLING_STATEMENT B
    WHERE COMPONENT_ID = p_COMPONENT_ID
    AND ENTITY_ID = p_BILL_ENTITY
    AND STATEMENT_TYPE = p_STATEMENT_TYPE
    AND STATEMENT_STATE = GA.EXTERNAL_STATE
    AND STATEMENT_DATE = TRUNC(p_DATE, 'DD');

    RETURN NVL(v_CHARGE_AMOUNT,0);

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN 0;
END GET_EXTERNAL_CHG_AMOUNT;
----------------------------------------------------------------------------
FUNCTION GET_REGULATION_AMOUNT
  (
  p_CONTRACT      IN NUMBER,
	p_CUT_DATE          IN DATE,
  p_STATEMENT_TYPE IN NUMBER
  ) RETURN NUMBER IS
v_SCHEDULEAMT NUMBER(9);
	BEGIN
		SELECT SUM(ITS.AMOUNT * NVL(P.OWNERSHIP_PERCENT/100,1))
			INTO v_SCHEDULEAMT
			FROM INTERCHANGE_TRANSACTION ITX,
           IT_SCHEDULE ITS,
           IT_COMMODITY ITC,
           PJM_SERVICE_POINT_OWNERSHIP P
		 WHERE ITX.TRANSACTION_TYPE = 'Generation'
       AND ITX.CONTRACT_ID = p_CONTRACT
       AND ITX.SC_ID = g_PJM_SC_ID
       AND ITC.COMMODITY_NAME = 'Regulation'
       AND ITX.COMMODITY_ID = ITC.COMMODITY_ID
       AND P.SERVICE_POINT_ID(+) = ITX.POD_ID
       AND P.CONTRACT_ID(+) = ITX.CONTRACT_ID
       AND NVL(P.END_DATE, '31-DEC-9999') > p_CUT_DATE
       AND ITS.TRANSACTION_ID = ITX.TRANSACTION_ID
       AND ITS.SCHEDULE_DATE = p_CUT_DATE
       AND ITS.SCHEDULE_STATE = GA.INTERNAL_STATE
       AND ITS.SCHEDULE_TYPE = p_STATEMENT_TYPE;
		RETURN NVL(v_SCHEDULEAMT, 0);
END GET_REGULATION_AMOUNT;
---------------------------------------------------------------------------------------
FUNCTION GET_OP_RES_CREDIT_AMT
    (
    p_CONTRACT_ID IN NUMBER,
    p_STATEMENT_DATE IN DATE,
    p_STATEMENT_TYPE_ID IN NUMBER,
    p_COMPONENT_IDENTIFIER IN VARCHAR2
    ) RETURN NUMBER IS
v_CHARGE_AMOUNT BILLING_STATEMENT.CHARGE_AMOUNT%TYPE;
BEGIN

    SELECT CHARGE_AMOUNT
    INTO v_CHARGE_AMOUNT
    FROM BILLING_STATEMENT B
    WHERE COMPONENT_ID =
                    (SELECT COMPONENT_ID
                    FROM COMPONENT
                    WHERE EXTERNAL_IDENTIFIER = p_COMPONENT_IDENTIFIER)
    AND ENTITY_ID =
                    (SELECT BILLING_ENTITY_ID
                    FROM INTERCHANGE_CONTRACT
                    WHERE CONTRACT_ID = p_CONTRACT_ID)
    AND STATEMENT_TYPE = p_STATEMENT_TYPE_ID
    AND STATEMENT_STATE = GA.EXTERNAL_STATE
    AND STATEMENT_DATE = TRUNC(p_STATEMENT_DATE, 'DD');

    RETURN NVL(v_CHARGE_AMOUNT,0);

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN 0;
END GET_OP_RES_CREDIT_AMT;
------------------------------------------------------------------------------------------
FUNCTION GET_COMBO_CREDIT_AMT
    (
    p_CONTRACT_ID IN NUMBER,
    p_STATEMENT_DATE IN DATE,
    p_STATEMENT_TYPE_ID IN NUMBER,
    p_PARENT_COMPONENT_IDENT IN VARCHAR2,
    p_COMPONENT_IDENTIFIER IN VARCHAR2
    ) RETURN NUMBER IS
v_CHARGE_ID BILLING_STATEMENT.CHARGE_ID%TYPE;
v_CHARGE_AMOUNT BILLING_STATEMENT.CHARGE_AMOUNT%TYPE;
BEGIN

    SELECT CHARGE_ID
    INTO v_CHARGE_ID
    FROM BILLING_STATEMENT
    WHERE COMPONENT_ID =
                    (SELECT COMPONENT_ID
                    FROM COMPONENT
                    WHERE EXTERNAL_IDENTIFIER = p_PARENT_COMPONENT_IDENT)
    AND ENTITY_ID =
                    (SELECT BILLING_ENTITY_ID
                    FROM INTERCHANGE_CONTRACT
                    WHERE CONTRACT_ID = p_CONTRACT_ID)
    AND STATEMENT_TYPE = p_STATEMENT_TYPE_ID
    AND STATEMENT_STATE = GA.EXTERNAL_STATE
    AND STATEMENT_DATE = TRUNC(p_STATEMENT_DATE, 'DD');

    SELECT CHARGE_AMOUNT
    INTO v_CHARGE_AMOUNT
    FROM COMBINATION_CHARGE
    WHERE COMPONENT_ID =
                    (SELECT COMPONENT_ID
                    FROM COMPONENT
                    WHERE EXTERNAL_IDENTIFIER = p_COMPONENT_IDENTIFIER)
    AND CHARGE_ID = v_CHARGE_ID;

    RETURN NVL(v_CHARGE_AMOUNT,0);

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN 0;
END GET_COMBO_CREDIT_AMT;
----------------------------------------------------------------------------
BEGIN
    SELECT SC.SC_ID INTO g_PJM_SC_ID FROM SC WHERE SC.SC_NAME = 'PJM';
EXCEPTION
	WHEN OTHERS THEN
		g_PJM_SC_ID := 0;
END MM_PJM_SHADOW_BILL;
/
