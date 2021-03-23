create or replace package body MM_PJM_SCHEDULED is

FUNCTION WHAT_VERSION RETURN VARCHAR2 IS
BEGIN
    RETURN '$Revision: 1.1 $';
END WHAT_VERSION;
----------------------------------------------------------------------------------------------------
FUNCTION GET_FIFTH_BUSINESS_DAY
    (
    p_DAY IN DATE
    ) RETURN DATE IS
v_DATE DATE;
v_BIZDAY_COUNTER BINARY_INTEGER := 0;
BEGIN
    v_DATE := FIRST_DAY(p_DAY);

    WHILE v_BIZDAY_COUNTER < 5 LOOP
        IF TO_CHAR(v_DATE, 'Dy') NOT IN (DATE_CONST.k_SUN, DATE_CONST.k_SAT) THEN
            IF IS_HOLIDAY_FOR_SET(v_DATE, 0) = 0 THEN
				v_BIZDAY_COUNTER := v_BIZDAY_COUNTER + 1;
		    END IF;
        END IF;
        IF v_BIZDAY_COUNTER < 5 THEN
            v_DATE := v_DATE + 1;
        ELSE
            EXIT;
        END IF;
    END LOOP;

    RETURN v_DATE;

END GET_FIFTH_BUSINESS_DAY;
--------------------------------------------------------------------
/*
	Daily settlement report downloads are typically available on a lag
	that ranges between 3 and 10 days (and isn't ever really consistent).
	Also, until the previous month is "closed" on the 5th business day, it
	appears that no reports are posted for the current month. The 5th business day
	is no earlier than the 5th (if the first is on a Monday), and no later than
	the 10th (if the first is on a Saturday and Monday is a holiday).
*/
PROCEDURE SETTLEMENT_DATE_RANGE(p_DATE IN DATE, p_BEGIN_DATE OUT DATE, p_END_DATE OUT DATE) IS
  v_DATE    DATE;
	v_WEEKDAY_COUNTER NUMBER(2) := 0;
BEGIN
	-- how many weekdays have we had so far this month?
	v_DATE := TRUNC(p_DATE, 'MM');
	WHILE v_DATE <= p_DATE LOOP
		IF TO_CHAR(v_DATE, 'Dy') NOT IN (DATE_CONST.k_SUN, DATE_CONST.k_SAT) THEN
			IF IS_HOLIDAY_FOR_SET(v_DATE, 0) = 0 THEN
				v_WEEKDAY_COUNTER := v_WEEKDAY_COUNTER + 1;
			END IF;
		END IF;
		v_DATE := v_DATE + 1;
	END LOOP;

	IF v_WEEKDAY_COUNTER <= 5 THEN
		p_BEGIN_DATE := ADD_MONTHS(TRUNC(p_DATE, 'MM'), -1);
		p_END_DATE := LAST_DAY(p_BEGIN_DATE);
  ELSE
		p_BEGIN_DATE := TRUNC(p_DATE, 'MM');
		p_END_DATE := p_DATE;
  END IF;
END SETTLEMENT_DATE_RANGE;
--------------------------------------------------------------------
PROCEDURE SETTLEMENT_DATE_RANGE
    (
    p_DATE IN DATE,
    p_BEGIN_DATE OUT DATE,
    p_END_DATE OUT DATE,
    p_WKDAY_COUNTER OUT NUMBER
    ) IS
v_DATE DATE;
v_WEEKDAY_COUNTER NUMBER(2) := 0;
BEGIN
	-- how many weekdays have we had so far this month?
	v_DATE := TRUNC(p_DATE, 'MM');
	WHILE v_DATE <= p_DATE LOOP
		IF TO_CHAR(v_DATE, 'Dy') NOT IN (DATE_CONST.k_SUN, DATE_CONST.k_SAT) THEN
			IF IS_HOLIDAY_FOR_SET(v_DATE, 0) = 0 THEN
				v_WEEKDAY_COUNTER := v_WEEKDAY_COUNTER + 1;
			END IF;
		END IF;
		v_DATE := v_DATE + 1;
	END LOOP;

    p_WKDAY_COUNTER := v_WEEKDAY_COUNTER;

	IF v_WEEKDAY_COUNTER <= 5 THEN
		p_BEGIN_DATE := ADD_MONTHS(TRUNC(p_DATE, 'MM'), -1);
		p_END_DATE := LAST_DAY(p_BEGIN_DATE);
	ELSE
		p_BEGIN_DATE := TRUNC(p_DATE, 'MM');
		p_END_DATE := p_DATE;
	END IF;
END SETTLEMENT_DATE_RANGE;
--------------------------------------------------------------------
PROCEDURE PJM_PUBLIC_DA_LMP
	(
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE
	) AS

  p_STATUS         NUMBER;
  p_MESSAGE        VARCHAR2(256);
  v_BEGIN_DATE DATE := TRUNC(p_BEGIN_DATE);
  v_END_DATE DATE := TRUNC(p_END_DATE);

BEGIN
p_STATUS := MEX_SWITCHBOARD.c_STATUS_SUCCESS;

	MM_PJM_LMP.MARKET_EXCHANGE(v_BEGIN_DATE, v_END_DATE, MM_PJM_LMP.g_ET_DAY_AHEAD_LMP, g_LOG_TYPE, g_TRACE_ON, p_STATUS, p_MESSAGE);

  IF p_STATUS != MEX_SWITCHBOARD.c_STATUS_SUCCESS THEN
       LOGS.LOG_WARN('Problem querying PJM day-ahead LMPs: ' || p_message);
     END IF;
END PJM_PUBLIC_DA_LMP;
---------------------------------------------------------------------------------------

PROCEDURE PJM_PUBLIC_RT_LMP
	(
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE
	) IS
  p_STATUS         NUMBER;
  p_MESSAGE        VARCHAR2(256);
  v_BEGIN_DATE DATE := TRUNC(p_BEGIN_DATE);
  v_END_DATE DATE := TRUNC(p_END_DATE);

BEGIN
p_STATUS := MEX_SWITCHBOARD.c_STATUS_SUCCESS;

	MM_PJM_LMP.MARKET_EXCHANGE(v_BEGIN_DATE, v_END_DATE, MM_PJM_LMP.g_ET_REAL_TIME_LMP, g_LOG_TYPE, g_TRACE_ON, p_STATUS, p_MESSAGE);

    IF p_STATUS != MEX_SWITCHBOARD.c_STATUS_SUCCESS THEN
      LOGS.LOG_WARN('Problem querying PJM real-time LMPs: ' || p_message);
    END IF;
END PJM_PUBLIC_RT_LMP;
---------------------------------------------------------------------------------------
PROCEDURE PJM_FTR_ZONAL_LMP IS
	p_STATUS NUMBER;
	p_MESSAGE VARCHAR2(256);
    v_BEGIN_DATE DATE;
    v_END_DATE DATE;
BEGIN
	p_STATUS := MEX_SWITCHBOARD.c_STATUS_SUCCESS;
	SETTLEMENT_DATE_RANGE(SYSDATE, v_BEGIN_DATE, v_END_DATE);
    IF TRUNC(SYSDATE,'MM') = v_BEGIN_DATE THEN
        v_END_DATE := v_BEGIN_DATE;
    ELSE
        v_END_DATE := TRUNC(SYSDATE,'MM');
    END IF;

	MM_PJM_LMP.MARKET_EXCHANGE(v_BEGIN_DATE, v_END_DATE, MM_PJM_LMP.g_ET_FTR_ZONAL_LMP, g_LOG_TYPE, g_TRACE_ON, p_STATUS, p_MESSAGE);

	IF p_STATUS != MEX_SWITCHBOARD.c_STATUS_SUCCESS THEN
		LOGS.LOG_WARN('Problem running FTR Zonal LMPs: ' || p_MESSAGE);
	END IF;
END PJM_FTR_ZONAL_LMP;
---------------------------------------------------------------------------------------
PROCEDURE PJM_PNODE_LIST IS
	p_STATUS NUMBER;
	p_MESSAGE VARCHAR2(256);
BEGIN

	MM_PJM_LMP.MARKET_EXCHANGE(TRUNC(SYSDATE), TRUNC(SYSDATE), MM_PJM_LMP.g_ET_QUERY_PNODES, g_LOG_TYPE, g_TRACE_ON, p_STATUS, p_MESSAGE);

	IF p_STATUS != MEX_SWITCHBOARD.c_STATUS_SUCCESS THEN
		LOGS.LOG_WARN('Problem running QueryNodeList: ' || p_message);
	END IF;
END PJM_PNODE_LIST;
---------------------------------------------------------------------------------------
PROCEDURE PJM_EMKT_MARKET_RESULTS
	(
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE
	) IS
	p_STATUS NUMBER;
	p_MESSAGE VARCHAR2(256);
BEGIN

	MM_PJM_EMKT.MARKET_EXCHANGE(TRUNC(p_BEGIN_DATE), TRUNC(p_END_DATE), MM_PJM_EMKT.g_ET_QUERY_MARKET_RESULTS, NULL, NULL, g_LOG_ONLY, g_LOG_TYPE, g_TRACE_ON, p_STATUS, p_MESSAGE);

	IF p_STATUS != MEX_SWITCHBOARD.c_STATUS_SUCCESS THEN
		LOGS.LOG_WARN('Problem running Query Market Results: ' || p_message);
	END IF;
END PJM_EMKT_MARKET_RESULTS;
---------------------------------------------------------------------------------------
PROCEDURE PJM_EMKT_DEMAND_BIDS
	(
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE
	) IS
	p_STATUS NUMBER;
	p_MESSAGE VARCHAR2(256);
BEGIN

	MM_PJM_EMKT.MARKET_EXCHANGE(TRUNC(p_BEGIN_DATE), TRUNC(p_END_DATE), MM_PJM_EMKT.g_ET_QUERY_DEMAND_BIDS, NULL, NULL, g_LOG_ONLY, g_LOG_TYPE, g_TRACE_ON, p_STATUS, p_MESSAGE);

	IF p_STATUS != MEX_SWITCHBOARD.c_STATUS_SUCCESS THEN
		LOGS.LOG_WARN('Problem running Query Demand Bids: ' || p_message);
	END IF;
END PJM_EMKT_DEMAND_BIDS;
---------------------------------------------------------------------------------------
PROCEDURE PJM_ESCHED_RT_DAILY_TXNS
	(
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE
	) IS
	p_STATUS     NUMBER;
	p_MESSAGE    VARCHAR2(256);
	v_BEGIN_DATE DATE := TRUNC(p_BEGIN_DATE);
	v_END_DATE   DATE := TRUNC(p_END_DATE);
BEGIN
	p_STATUS := MEX_SWITCHBOARD.c_STATUS_SUCCESS;

	MM_PJM_ESCHED.MARKET_EXCHANGE(v_BEGIN_DATE, v_END_DATE, MM_PJM_ESCHED.g_ET_QUERY_RL_TIME_DAILY_TXNS,
								 NULL, NULL, g_LOG_ONLY, g_LOG_TYPE, g_TRACE_ON, p_STATUS, p_MESSAGE);

	IF p_STATUS != MEX_SWITCHBOARD.c_STATUS_SUCCESS THEN
		LOGS.LOG_WARN('Problem importing PJM Real-time Daily Transactions: ' || p_message);
	END IF;
END PJM_ESCHED_RT_DAILY_TXNS;
---------------------------------------------------------------------------------------
PROCEDURE PJM_ESCHED_COMPANIES IS
	p_STATUS NUMBER;
	p_MESSAGE VARCHAR2(256);
BEGIN

	MM_PJM_ESCHED.MARKET_EXCHANGE(TRUNC(SYSDATE), TRUNC(SYSDATE), MM_PJM_ESCHED.g_ET_QUERY_COMPANIES,
								 NULL, NULL, g_LOG_ONLY, g_LOG_TYPE, g_TRACE_ON, p_STATUS, p_MESSAGE);

	IF p_STATUS != MEX_SWITCHBOARD.c_STATUS_SUCCESS THEN
		LOGS.LOG_WARN('Problem running Query Companies: ' || p_message);
	END IF;
END PJM_ESCHED_COMPANIES;
---------------------------------------------------------------------------------------
PROCEDURE PJM_ESCHED_CONTRACTS
	(
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE
	) IS
	p_STATUS NUMBER;
	p_MESSAGE VARCHAR2(256);
BEGIN
  -- download the eSchedule contracts
	MM_PJM_ESCHED.MARKET_EXCHANGE(TRUNC(p_BEGIN_DATE), TRUNC(p_END_DATE), MM_PJM_ESCHED.g_ET_QUERY_CONTRACTS,
								 NULL, NULL, g_LOG_ONLY, g_LOG_TYPE, g_TRACE_ON, p_STATUS, p_MESSAGE);

	IF p_STATUS != MEX_SWITCHBOARD.c_STATUS_SUCCESS THEN
		LOGS.LOG_WARN('Problem running eSchedule: Query Contracts: ' || p_message);
	END IF;
END PJM_ESCHED_CONTRACTS;
---------------------------------------------------------------------------------------
PROCEDURE PJM_ESCHED_SCHEDULES	(
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE
	) IS
	p_STATUS NUMBER;
	p_MESSAGE VARCHAR2(256);
BEGIN
  -- download the eSchedule schedules
	MM_PJM_ESCHED.MARKET_EXCHANGE(TRUNC(p_BEGIN_DATE), TRUNC(p_END_DATE), MM_PJM_ESCHED.g_ET_QUERY_SCHEDULES,
								 NULL, NULL, g_LOG_ONLY, g_LOG_TYPE, g_TRACE_ON, p_STATUS, p_MESSAGE);

	IF p_STATUS != MEX_SWITCHBOARD.c_STATUS_SUCCESS THEN
		LOGS.LOG_WARN('Problem running eSchedule: Query Schedules: ' || p_message);
	END IF;
END PJM_ESCHED_SCHEDULES;
---------------------------------------------------------------------------------------
PROCEDURE PJM_ESCHED_CONTRS_SCHEDS
	(
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE
	) IS
BEGIN
     PJM_ESCHED_CONTRACTS(p_BEGIN_DATE, p_END_DATE);
     PJM_ESCHED_SCHEDULES(p_BEGIN_DATE, p_END_DATE);
END PJM_ESCHED_CONTRS_SCHEDS;
---------------------------------------------------------------------------------------
PROCEDURE PJM_EMTR_METERS
	(
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE
	) IS
	p_STATUS NUMBER;
	p_MESSAGE VARCHAR2(256);
BEGIN
	-- download the eMTR meters
	MM_PJM_EMTR.MARKET_EXCHANGE(TRUNC(p_BEGIN_DATE), TRUNC(p_END_DATE), MM_PJM_EMTR.g_ET_QUERY_METER_ACCOUNTS,
								 NULL, NULL, g_LOG_ONLY, g_LOG_TYPE, g_TRACE_ON, p_STATUS, p_MESSAGE);

	IF p_STATUS != MEX_SWITCHBOARD.c_STATUS_SUCCESS THEN
		LOGS.LOG_WARN('Problem running Query Meter Accounts: ' || p_message);
	END IF;
END PJM_EMTR_METERS;
---------------------------------------------------------------------------------------
PROCEDURE PJM_EMTR_METER_VALS
	(
	p_BEGIN_DATE DATE,
	p_END_DATE DATE
	) IS
	p_STATUS NUMBER;
	p_MESSAGE VARCHAR2(256);
BEGIN
	-- download the eMTR meter values
	MM_PJM_EMTR.MARKET_EXCHANGE(TRUNC(p_BEGIN_DATE), TRUNC(p_END_DATE), MM_PJM_EMTR.g_ET_QUERY_ALLOC_METER_VALUES,
								 NULL, NULL, g_LOG_ONLY, g_LOG_TYPE, g_TRACE_ON, p_STATUS, p_MESSAGE);

	IF p_STATUS != MEX_SWITCHBOARD.c_STATUS_SUCCESS THEN
		LOGS.LOG_WARN('Problem running eMTR: Query Allocated Meter Values: ' || p_message);
	END IF;
END PJM_EMTR_METER_VALS;
---------------------------------------------------------------------------------------
PROCEDURE PJM_EMTR_METERS_AND_VALS
	(
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE
	) IS
BEGIN
     PJM_EMTR_METERS(p_BEGIN_DATE, p_END_DATE);
     PJM_EMTR_METER_VALS(p_BEGIN_DATE, p_END_DATE);
END PJM_EMTR_METERS_AND_VALS;
---------------------------------------------------------------------------------------
PROCEDURE PJM_EMKT_ALL_BID_OFFERS
	(
	p_TO_INTERNAL IN NUMBER,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE
	) IS
	p_STATUS NUMBER;
	p_MESSAGE VARCHAR2(256);
	v_SCHEDULE_STATE NUMBER(1);
BEGIN
     p_STATUS := MEX_SWITCHBOARD.c_STATUS_SUCCESS;
     IF p_TO_INTERNAL <> 0 THEN
        v_SCHEDULE_STATE := GA.INTERNAL_STATE;
     ELSE
         v_SCHEDULE_STATE := GA.EXTERNAL_STATE;
     END IF;

	MM_PJM_EMKT.QUERY_ALL_BIDS_OF_TYPE('All', TRUNC(p_BEGIN_DATE), TRUNC(p_END_DATE), v_SCHEDULE_STATE,
								 g_LOG_ONLY, g_LOG_TYPE, g_TRACE_ON, p_STATUS, p_MESSAGE);

	IF p_STATUS != MEX_SWITCHBOARD.c_STATUS_SUCCESS THEN
		LOGS.LOG_WARN('Problem running eMKT Bids and Offers Query: ' || p_message);
	END IF;
END PJM_EMKT_ALL_BID_OFFERS;
---------------------------------------------------------------------------------------
PROCEDURE PJM_EMKT_ROLL_FORWARD_OFFERS
	(
	p_TO_INTERNAL IN NUMBER,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE
	) IS
	p_STATUS NUMBER;
	p_MESSAGE VARCHAR2(256);
	v_SCHEDULE_STATE NUMBER(1);
BEGIN
     p_STATUS := MEX_SWITCHBOARD.c_STATUS_SUCCESS;
     IF p_TO_INTERNAL <> 0 THEN
        v_SCHEDULE_STATE := GA.INTERNAL_STATE;
     ELSE
         v_SCHEDULE_STATE := GA.EXTERNAL_STATE;
     END IF;

	MM_PJM_EMKT.QUERY_ALL_BIDS_OF_TYPE('ROLL_FORWARDS', TRUNC(p_BEGIN_DATE), TRUNC(p_END_DATE), v_SCHEDULE_STATE,
								 g_LOG_ONLY, g_LOG_TYPE, g_TRACE_ON, p_STATUS, p_MESSAGE);

	IF p_STATUS != MEX_SWITCHBOARD.c_STATUS_SUCCESS THEN
		LOGS.LOG_WARN('Problem running eMKT Bids and Offers Query: ' || p_message);
	END IF;
END PJM_EMKT_ROLL_FORWARD_OFFERS;
---------------------------------------------------------------------------------------
PROCEDURE PJM_ZONAL_LOAD_FORECAST IS
	p_STATUS NUMBER;
	p_MESSAGE VARCHAR2(256);
BEGIN
     p_STATUS := MEX_SWITCHBOARD.c_STATUS_SUCCESS;

	MM_PJM_OASIS.MARKET_EXCHANGE(TRUNC(SYSDATE), TRUNC(SYSDATE), MM_PJM_OASIS.g_ET_QUERY_LOAD_FORECAST,
								 NULL, NULL, g_LOG_ONLY, g_LOG_TYPE, g_TRACE_ON, p_STATUS, p_MESSAGE);

	IF p_STATUS != MEX_SWITCHBOARD.c_STATUS_SUCCESS THEN
		LOGS.LOG_WARN('Problem running PJM Zonal Load Forecast Query: ' || p_message);
	END IF;
END PJM_ZONAL_LOAD_FORECAST;
---------------------------------------------------------------------------------------
PROCEDURE PJM_SPOT_MKT_DAILY_SUMMARY IS
	p_STATUS NUMBER;
	p_MESSAGE VARCHAR2(256);
	v_BEGIN_DATE DATE;
	v_END_DATE DATE;
BEGIN
	p_STATUS := MEX_SWITCHBOARD.c_STATUS_SUCCESS;
	SETTLEMENT_DATE_RANGE(SYSDATE, v_BEGIN_DATE, v_END_DATE);
	MM_PJM_SETTLEMENT_MSRS.MARKET_EXCHANGE(v_BEGIN_DATE, v_END_DATE, MEX_PJM_SETTLEMENT_MSRS.g_ET_SPOT_MKT_ENERGY_SUMMARY,
	 							NULL, NULL, g_LOG_ONLY, g_LOG_TYPE, g_TRACE_ON, p_STATUS, p_MESSAGE);

	IF p_STATUS != MEX_SWITCHBOARD.c_STATUS_SUCCESS THEN
		LOGS.LOG_WARN('Problem importing PJM Spot Market Daily Summary: ' || p_message);
	END IF;
END PJM_SPOT_MKT_DAILY_SUMMARY;
---------------------------------------------------------------------------------------
PROCEDURE PJM_CONG_LOSS_REPORTS IS
	p_STATUS NUMBER;
	p_MESSAGE VARCHAR2(256);
	v_BEGIN_DATE DATE;
	v_END_DATE DATE;
BEGIN
	p_STATUS := MEX_SWITCHBOARD.c_STATUS_SUCCESS;
	SETTLEMENT_DATE_RANGE(SYSDATE, v_BEGIN_DATE, v_END_DATE);

	MM_PJM_SETTLEMENT_MSRS.MARKET_EXCHANGE(v_BEGIN_DATE, v_END_DATE, MEX_PJM_SETTLEMENT_MSRS.g_ET_CONGESTION_SUMMARY,
	 							NULL, NULL, g_LOG_ONLY, g_LOG_TYPE, g_TRACE_ON, p_STATUS, p_MESSAGE);

	IF p_STATUS != MEX_SWITCHBOARD.c_STATUS_SUCCESS THEN
		LOGS.LOG_WARN('Problem importing PJM Congestion Reports: ' || p_message);
	END IF;
END PJM_CONG_LOSS_REPORTS;
---------------------------------------------------------------------------------------
PROCEDURE PJM_MONTH_TO_DATE_BILL IS
	p_STATUS NUMBER;
	p_MESSAGE VARCHAR2(256);
	v_BEGIN_DATE DATE;
	v_END_DATE DATE;
BEGIN
	p_STATUS := MEX_SWITCHBOARD.c_STATUS_SUCCESS;
	SETTLEMENT_DATE_RANGE(SYSDATE, v_BEGIN_DATE, v_END_DATE);

	MM_PJM_SETTLEMENT_MSRS.MARKET_EXCHANGE(v_BEGIN_DATE, v_END_DATE, MEX_PJM_SETTLEMENT_MSRS.g_ET_MONTH_TO_DATE_BILL,
	 							NULL, NULL, g_LOG_ONLY, g_LOG_TYPE, g_TRACE_ON, p_STATUS, p_MESSAGE);

	IF p_STATUS != MEX_SWITCHBOARD.c_STATUS_SUCCESS THEN
		LOGS.LOG_WARN('Problem importing PJM Month to Date Bill: ' || p_MESSAGE);
	END IF;
END PJM_MONTH_TO_DATE_BILL;
---------------------------------------------------------------------------------------
PROCEDURE PJM_REGULATION_CREDITS IS
	p_STATUS NUMBER;
	p_MESSAGE VARCHAR2(256);
	v_BEGIN_DATE DATE;
	v_END_DATE DATE;
BEGIN
	p_STATUS := MEX_SWITCHBOARD.c_STATUS_SUCCESS;
	SETTLEMENT_DATE_RANGE(SYSDATE, v_BEGIN_DATE, v_END_DATE);

	MM_PJM_SETTLEMENT_MSRS.MARKET_EXCHANGE(v_BEGIN_DATE, v_END_DATE, MEX_PJM_SETTLEMENT_MSRS.g_ET_REGULATION_CRED_SUMMARY,
	 							NULL, NULL, g_LOG_ONLY, g_LOG_TYPE, g_TRACE_ON, p_STATUS, p_MESSAGE);

	IF p_STATUS != MEX_SWITCHBOARD.c_STATUS_SUCCESS THEN
		LOGS.LOG_WARN('Problem importing PJM Regulation Credits: ' || p_MESSAGE);
	END IF;
END PJM_REGULATION_CREDITS;
---------------------------------------------------------------------------------------
PROCEDURE PJM_LOC_RELIABILITY_SUMMARY IS
	p_STATUS NUMBER;
	p_MESSAGE VARCHAR2(256);
	v_BEGIN_DATE DATE;
	v_END_DATE DATE;
BEGIN
	p_STATUS := MEX_SWITCHBOARD.c_STATUS_SUCCESS;
	SETTLEMENT_DATE_RANGE(SYSDATE, v_BEGIN_DATE, v_END_DATE);

	MM_PJM_SETTLEMENT_MSRS.MARKET_EXCHANGE(v_BEGIN_DATE, v_END_DATE, MEX_PJM_SETTLEMENT_MSRS.g_ET_LOC_RELIABILITY_SUMM,
	 							NULL, NULL, g_LOG_ONLY, g_LOG_TYPE, g_TRACE_ON, p_STATUS, p_MESSAGE);

	IF p_STATUS != MEX_SWITCHBOARD.c_STATUS_SUCCESS THEN
		LOGS.LOG_WARN('Problem importing PJM Locational Reliability Summary: ' || p_MESSAGE);
	END IF;
END PJM_LOC_RELIABILITY_SUMMARY;
---------------------------------------------------------------------------------------
PROCEDURE PJM_RPM_AUCTION_SUMMARY IS
	p_STATUS NUMBER;
	p_MESSAGE VARCHAR2(256);
	v_BEGIN_DATE DATE;
	v_END_DATE DATE;
BEGIN
	p_STATUS := MEX_SWITCHBOARD.c_STATUS_SUCCESS;
	SETTLEMENT_DATE_RANGE(SYSDATE, v_BEGIN_DATE, v_END_DATE);

	MM_PJM_SETTLEMENT_MSRS.MARKET_EXCHANGE(v_BEGIN_DATE, v_END_DATE, MEX_PJM_SETTLEMENT_MSRS.g_ET_RPM_AUCTION_SUMMARY,
	 							NULL, NULL, g_LOG_ONLY, g_LOG_TYPE, g_TRACE_ON, p_STATUS, p_MESSAGE);

	IF p_STATUS != MEX_SWITCHBOARD.c_STATUS_SUCCESS THEN
		LOGS.LOG_WARN('Problem importing PJM RPM Auction Summary: ' || p_MESSAGE);
	END IF;
END PJM_RPM_AUCTION_SUMMARY;
---------------------------------------------------------------------------------------
PROCEDURE PJM_EXPLICIT_CONGESTION IS
	p_STATUS NUMBER;
	p_MESSAGE VARCHAR2(256);
	v_BEGIN_DATE DATE;
	v_END_DATE DATE;
BEGIN
	p_STATUS := MEX_SWITCHBOARD.c_STATUS_SUCCESS;
	SETTLEMENT_DATE_RANGE(SYSDATE, v_BEGIN_DATE, v_END_DATE);

	MM_PJM_SETTLEMENT_MSRS.MARKET_EXCHANGE(v_BEGIN_DATE, v_END_DATE, MEX_PJM_SETTLEMENT_MSRS.g_ET_EXPLICIT_CONGESTION_SUMM,
	 							NULL, NULL, g_LOG_ONLY, g_LOG_TYPE, g_TRACE_ON, p_STATUS, p_MESSAGE);

	IF p_STATUS != MEX_SWITCHBOARD.c_STATUS_SUCCESS THEN
		LOGS.LOG_WARN('Problem importing PJM Explicit Congestion Summary: ' || p_message);
	END IF;
END PJM_EXPLICIT_CONGESTION;
---------------------------------------------------------------------------------------
PROCEDURE PJM_OP_RESERVES_REPORTS IS
	p_STATUS NUMBER;
	p_MESSAGE VARCHAR2(256);
	v_BEGIN_DATE DATE;
	v_END_DATE DATE;
BEGIN
	p_STATUS := MEX_SWITCHBOARD.c_STATUS_SUCCESS;
	SETTLEMENT_DATE_RANGE(SYSDATE, v_BEGIN_DATE, v_END_DATE);

	MM_PJM_SETTLEMENT_MSRS.MARKET_EXCHANGE(v_BEGIN_DATE, v_END_DATE, MEX_PJM_SETTLEMENT_MSRS.g_ET_OPER_RESERVES_SUMMARY,
	 							NULL, NULL, g_LOG_ONLY, g_LOG_TYPE, g_TRACE_ON, p_STATUS, p_MESSAGE);

	IF p_STATUS != MEX_SWITCHBOARD.c_STATUS_SUCCESS THEN
		LOGS.LOG_WARN('Problem importing PJM Op Reserves Reports: ' || p_message);
	END IF;
END PJM_OP_RESERVES_REPORTS;
---------------------------------------------------------------------------------------
PROCEDURE PJM_FTR_TARGET_ALLOCATION IS
	p_STATUS NUMBER;
	p_MESSAGE VARCHAR2(256);
	v_BEGIN_DATE DATE;
	v_END_DATE DATE;
BEGIN
	p_STATUS := MEX_SWITCHBOARD.c_STATUS_SUCCESS;
	SETTLEMENT_DATE_RANGE(SYSDATE, v_BEGIN_DATE, v_END_DATE);

	MM_PJM_SETTLEMENT_MSRS.MARKET_EXCHANGE(v_BEGIN_DATE, v_END_DATE, MEX_PJM_SETTLEMENT_MSRS.g_ET_FTR_TARGET_CREDITS,
	 							NULL, NULL, g_LOG_ONLY, g_LOG_TYPE, g_TRACE_ON, p_STATUS, p_MESSAGE);

	IF p_STATUS != MEX_SWITCHBOARD.c_STATUS_SUCCESS THEN
		LOGS.LOG_WARN('Problem importing PJM FTR Target Allocation: ' || p_message);
	END IF;
END PJM_FTR_TARGET_ALLOCATION;
---------------------------------------------------------------------------------------
PROCEDURE PJM_DA_DAILY_TRANSACTIONS IS
	p_STATUS NUMBER;
	p_MESSAGE VARCHAR2(256);
	v_BEGIN_DATE DATE;
	v_END_DATE DATE;
BEGIN
	p_STATUS := MEX_SWITCHBOARD.c_STATUS_SUCCESS;
	SETTLEMENT_DATE_RANGE(SYSDATE, v_BEGIN_DATE, v_END_DATE);

	MM_PJM_SETTLEMENT_MSRS.MARKET_EXCHANGE(v_BEGIN_DATE, v_END_DATE, MEX_PJM_ESCHED.g_ET_DAY_AHEAD_DAILY_TRANS,
	 							NULL, NULL, g_LOG_ONLY, g_LOG_TYPE, g_TRACE_ON, p_STATUS, p_MESSAGE);

	IF p_STATUS != MEX_SWITCHBOARD.c_STATUS_SUCCESS THEN
		LOGS.LOG_WARN('Problem importing PJM Day-ahead Daily Transactions: ' || p_message);
	END IF;
END PJM_DA_DAILY_TRANSACTIONS;
---------------------------------------------------------------------------------------
PROCEDURE PJM_RT_DAILY_TRANSACTIONS IS
	p_STATUS NUMBER;
	p_MESSAGE VARCHAR2(256);
	v_BEGIN_DATE DATE;
	v_END_DATE DATE;
BEGIN
	p_STATUS := MEX_SWITCHBOARD.c_STATUS_SUCCESS;
	SETTLEMENT_DATE_RANGE(SYSDATE, v_BEGIN_DATE, v_END_DATE);

	MM_PJM_SETTLEMENT_MSRS.MARKET_EXCHANGE(v_BEGIN_DATE, v_END_DATE, MEX_PJM_ESCHED.g_ET_REAL_TIME_DLY_TRANS,
	 							NULL, NULL, g_LOG_ONLY, g_LOG_TYPE, g_TRACE_ON, p_STATUS, p_MESSAGE);

	IF p_STATUS != MEX_SWITCHBOARD.c_STATUS_SUCCESS THEN
		LOGS.LOG_WARN('Problem importing PJM Real-time Daily Transactions: ' || p_message);
	END IF;
END PJM_RT_DAILY_TRANSACTIONS;
---------------------------------------------------------------------------------------
PROCEDURE PJM_SYNC_RESERVE_REPORTS IS
	p_STATUS NUMBER;
	p_MESSAGE VARCHAR2(256);
	v_BEGIN_DATE DATE;
	v_END_DATE DATE;
BEGIN
	p_STATUS := MEX_SWITCHBOARD.c_STATUS_SUCCESS;
	SETTLEMENT_DATE_RANGE(SYSDATE, v_BEGIN_DATE, v_END_DATE);

	MM_PJM_SETTLEMENT_MSRS.MARKET_EXCHANGE(v_BEGIN_DATE, v_END_DATE, MEX_PJM_SETTLEMENT_MSRS.g_ET_SYNC_RESERVE_OBLIG_DETAIL,
	 							NULL, NULL, g_LOG_ONLY, g_LOG_TYPE, g_TRACE_ON, p_STATUS, p_MESSAGE);

	IF p_STATUS != MEX_SWITCHBOARD.c_STATUS_SUCCESS THEN
		LOGS.LOG_WARN('Problem importing PJM Spinning Reserve Reports: ' || p_message);
	END IF;
END PJM_SYNC_RESERVE_REPORTS;
---------------------------------------------------------------------------------------
PROCEDURE PJM_INADVERT_INTRCH_SUMMARY IS
	p_STATUS NUMBER;
	p_MESSAGE VARCHAR2(256);
	v_BEGIN_DATE DATE;
	v_END_DATE DATE;
BEGIN
	p_STATUS := MEX_SWITCHBOARD.c_STATUS_SUCCESS;
	SETTLEMENT_DATE_RANGE(SYSDATE, v_BEGIN_DATE, v_END_DATE);


	MM_PJM_SETTLEMENT_MSRS.MARKET_EXCHANGE(v_BEGIN_DATE, v_END_DATE, MEX_PJM_SETTLEMENT_MSRS.g_ET_INADVERTENT_INTERCHANGE,
	 							NULL, NULL, g_LOG_ONLY, g_LOG_TYPE, g_TRACE_ON, p_STATUS, p_MESSAGE);

	IF p_STATUS != MEX_SWITCHBOARD.c_STATUS_SUCCESS THEN
		LOGS.LOG_WARN('Problem importing PJM Inadvertent Interchange Summary: ' || p_message);
	END IF;
END PJM_INADVERT_INTRCH_SUMMARY;
---------------------------------------------------------------------------------------
PROCEDURE PJM_TRANS_LOSS_CR_SUMMARY IS
	p_STATUS NUMBER;
	p_MESSAGE VARCHAR2(256);
	v_BEGIN_DATE DATE;
	v_END_DATE DATE;
BEGIN
	p_STATUS := MEX_SWITCHBOARD.c_STATUS_SUCCESS;
	SETTLEMENT_DATE_RANGE(SYSDATE, v_BEGIN_DATE, v_END_DATE);

	MM_PJM_SETTLEMENT_MSRS.MARKET_EXCHANGE(v_BEGIN_DATE, v_END_DATE, MEX_PJM_SETTLEMENT_MSRS.g_ET_TRANSMISSION_LOSS_CREDITS,
	 							NULL, NULL, g_LOG_ONLY, g_LOG_TYPE, g_TRACE_ON, p_STATUS, p_MESSAGE);

	IF p_STATUS != MEX_SWITCHBOARD.c_STATUS_SUCCESS THEN
		LOGS.LOG_WARN('Problem importing PJM Transmission Loss Credit Summary: ' || p_message);
	END IF;
END PJM_TRANS_LOSS_CR_SUMMARY;
---------------------------------------------------------------------------------------
PROCEDURE PJM_EXPLICIT_LOSS_SUMMARY IS
	p_STATUS NUMBER;
	p_MESSAGE VARCHAR2(256);
	v_BEGIN_DATE DATE;
	v_END_DATE DATE;
BEGIN
	p_STATUS := MEX_SWITCHBOARD.c_STATUS_SUCCESS;
	SETTLEMENT_DATE_RANGE(SYSDATE, v_BEGIN_DATE, v_END_DATE);

	MM_PJM_SETTLEMENT_MSRS.MARKET_EXCHANGE(v_BEGIN_DATE, v_END_DATE, MEX_PJM_SETTLEMENT_MSRS.g_ET_EXPLICIT_LOSS_CHARGES,
	 							NULL, NULL, g_LOG_ONLY, g_LOG_TYPE, g_TRACE_ON, p_STATUS, p_MESSAGE);

	IF p_STATUS != MEX_SWITCHBOARD.c_STATUS_SUCCESS THEN
		LOGS.LOG_WARN('Problem importing PJM Explicit Loss Summary: ' || p_message);
	END IF;
END PJM_EXPLICIT_LOSS_SUMMARY;
---------------------------------------------------------------------------------------
PROCEDURE PJM_LOAD_W_WO_LOSSES_SUMMARY IS
	p_STATUS NUMBER;
	p_MESSAGE VARCHAR2(256);
	v_BEGIN_DATE DATE;
	v_END_DATE DATE;
BEGIN
	p_STATUS := MEX_SWITCHBOARD.c_STATUS_SUCCESS;
	SETTLEMENT_DATE_RANGE(SYSDATE, v_BEGIN_DATE, v_END_DATE);

	MM_PJM_ESCHED.MARKET_EXCHANGE(v_BEGIN_DATE, v_END_DATE, MM_PJM_ESCHED.g_ET_QUERY_LOAD,
								 NULL, NULL, g_LOG_ONLY, g_LOG_TYPE, g_TRACE_ON, p_STATUS, p_MESSAGE);

	IF p_STATUS != MEX_SWITCHBOARD.c_STATUS_SUCCESS THEN
		LOGS.LOG_WARN('Problem importing PJM Load w/w.o. Losses Summary: ' || p_message);
	END IF;
END PJM_LOAD_W_WO_LOSSES_SUMMARY;
---------------------------------------------------------------------------------------
PROCEDURE PJM_REGULATION_SUMMARY IS
	p_STATUS NUMBER;
	p_MESSAGE VARCHAR2(256);
	v_BEGIN_DATE DATE;
	v_END_DATE DATE;
BEGIN
	p_STATUS := MEX_SWITCHBOARD.c_STATUS_SUCCESS;
	SETTLEMENT_DATE_RANGE(SYSDATE, v_BEGIN_DATE, v_END_DATE);

	MM_PJM_SETTLEMENT_MSRS.MARKET_EXCHANGE(v_BEGIN_DATE, v_END_DATE, MEX_PJM_SETTLEMENT_MSRS.g_ET_REGULATION_SUMMARY,
	 							NULL, NULL, g_LOG_ONLY, g_LOG_TYPE, g_TRACE_ON, p_STATUS, p_MESSAGE);

	IF p_STATUS != MEX_SWITCHBOARD.c_STATUS_SUCCESS THEN
		LOGS.LOG_WARN('Problem importing PJM Regulation Summary: ' || p_message);
	END IF;
END PJM_REGULATION_SUMMARY;
---------------------------------------------------------------------------------------
PROCEDURE PJM_IMPORT_SETTLEMENT_STATEMNT IS
	p_STATUS NUMBER;
	p_MESSAGE VARCHAR2(256);
v_BEGIN_DATE DATE;
v_DATE DATE;
v_END_DATE DATE;
v_WKDAY_COUNTER NUMBER;
v_PSE_IDS NUMBER_COLLECTION;
CURSOR p_PJM_CONTRACTS IS
    SELECT C.BILLING_ENTITY_ID
    FROM INTERCHANGE_CONTRACT C
    WHERE C.SC_ID = (SELECT SC.SC_ID FROM SC WHERE SC.SC_NAME = 'PJM');
BEGIN
     p_STATUS := MEX_SWITCHBOARD.c_STATUS_SUCCESS;
     v_PSE_IDS := NUMBER_COLLECTION();
     --only download if 5th biz day of month
     SETTLEMENT_DATE_RANGE(SYSDATE, v_DATE, v_END_DATE, v_WKDAY_COUNTER);
     --if it is Sat or Sun and the 5th biz day fell on a Friday, the download already happened
     IF (v_WKDAY_COUNTER = 5) AND (TO_CHAR(SYSDATE, 'Dy') NOT IN (DATE_CONST.k_SUN, DATE_CONST.k_SAT)) THEN    
        v_BEGIN_DATE := FIRST_DAY(SYSDATE - NUMTOYMINTERVAL(1, 'MONTH'));

		MM_PJM_SETTLEMENT_MSRS.MARKET_EXCHANGE(v_BEGIN_DATE, v_END_DATE, MM_PJM_SETTLEMENT_MSRS.g_ET_IMP_SETTLEMENT_STMT,
	 							NULL, NULL, g_LOG_ONLY, g_LOG_TYPE, g_TRACE_ON, p_STATUS, p_MESSAGE);

        --now calculate the bill for the entire month
        FOR v_PJM_CONTRACT IN p_PJM_CONTRACTS LOOP
            IF v_PJM_CONTRACT.BILLING_ENTITY_ID IS NOT NULL THEN
                v_PSE_IDS := NUMBER_COLLECTION(v_PJM_CONTRACT.BILLING_ENTITY_ID);
                PC.BILLING_STATEMENT_REQUEST(p_CALLING_MODULE => 'Billing',
                                    p_MODEL_ID => 1,
                                    p_PSE_IDS => v_PSE_IDS,
                                    p_PRODUCT_ID => -1,
                                    p_COMPONENT_ID => -1,
                                    p_SCHEDULE_TYPE => 1,
                                    p_STATEMENT_TYPE => 1,
    							    p_BEGIN_DATE => v_BEGIN_DATE,
                                    p_END_DATE => LAST_DAY(v_BEGIN_DATE),
                                    p_INPUT_AS_OF_DATE => NULL,
                                    p_OUTPUT_AS_OF_DATE => NULL,
                                    p_GENERATE_INVOICE => 1.0,
                                    p_TRACE_ON => 0.0,
                                    p_PROCESS_STATUS => p_STATUS,
                                    p_MESSAGE => p_MESSAGE);

                IF p_STATUS != MEX_SWITCHBOARD.c_STATUS_SUCCESS THEN
    		        LOGS.LOG_WARN('Problem importing PJM Settlement Statement: ' || p_message);
    	        END IF;
            END IF;
        END LOOP;
    END IF;
END PJM_IMPORT_SETTLEMENT_STATEMNT;
---------------------------------------------------------------------------------------
PROCEDURE PJM_DAILY_SETTLEMENT IS
BEGIN
     PJM_MONTH_TO_DATE_BILL;
     PJM_SPOT_MKT_DAILY_SUMMARY;
     PJM_CONG_LOSS_REPORTS;    
     PJM_EXPLICIT_CONGESTION;
     PJM_OP_RESERVES_REPORTS;     
     PJM_FTR_TARGET_ALLOCATION;
     PJM_DA_DAILY_TRANSACTIONS;
     PJM_RT_DAILY_TRANSACTIONS;     
     PJM_INADVERT_INTRCH_SUMMARY;     
     PJM_TRANS_LOSS_CR_SUMMARY;
     PJM_EXPLICIT_LOSS_SUMMARY;
     PJM_REGULATION_SUMMARY;
     PJM_REGULATION_CREDITS;
     PJM_SYNC_RESERVE_REPORTS;
     PJM_LOC_RELIABILITY_SUMMARY;
     PJM_RPM_AUCTION_SUMMARY;          
     
END PJM_DAILY_SETTLEMENT;
---------------------------------------------------------------------------------------
PROCEDURE PJM_ERPM_NSPL
	(
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE
	) IS
p_STATUS NUMBER;
p_MESSAGE VARCHAR2(256);
BEGIN
    p_STATUS := MEX_SWITCHBOARD.c_STATUS_SUCCESS;

	MM_PJM_ERPM.MARKET_EXCHANGE(TRUNC(p_BEGIN_DATE), TRUNC(p_END_DATE), MM_PJM_ERPM.g_ET_QUERY_NSPL,
	 							NULL, NULL, g_LOG_ONLY, g_LOG_TYPE, g_TRACE_ON, p_STATUS, p_MESSAGE);

	IF p_STATUS <> MEX_SWITCHBOARD.c_STATUS_SUCCESS THEN
		LOGS.LOG_WARN('Problem importing PJM eRPM NSPL: ' || p_message);
	END IF;
END PJM_ERPM_NSPL;
---------------------------------------------------------------------------------------
PROCEDURE PJM_ERPM_CAP_OBLIGATION
    (
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE
	) IS
p_STATUS NUMBER;
p_MESSAGE VARCHAR2(256);
BEGIN
    p_STATUS := MEX_SWITCHBOARD.c_STATUS_SUCCESS;
     --assume downloaded on 5th of next month
	MM_PJM_ERPM.MARKET_EXCHANGE(TRUNC(p_BEGIN_DATE), TRUNC(p_END_DATE), MM_PJM_ERPM.g_ET_QUERY_CAPACITY_OBLIG,
	 							NULL, NULL, g_LOG_ONLY, g_LOG_TYPE, g_TRACE_ON, p_STATUS, p_MESSAGE);

	IF p_STATUS <> MEX_SWITCHBOARD.c_STATUS_SUCCESS THEN
		LOGS.LOG_WARN('Problem importing PJM Capacity Obligation: ' || p_message);
	END IF;
END PJM_ERPM_CAP_OBLIGATION;
---------------------------------------------------------------------------------------
PROCEDURE PJM_ERPM_REPORTS
	(
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE
	) IS
BEGIN
     PJM_ERPM_NSPL(p_BEGIN_DATE, p_END_DATE);
     PJM_ERPM_CAP_OBLIGATION(p_BEGIN_DATE, p_END_DATE);
END PJM_ERPM_REPORTS;
---------------------------------------------------------------------------------------
PROCEDURE PJM_SPREG_AWARD
	(
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE
	) IS
	p_STATUS NUMBER;
	p_MESSAGE VARCHAR2(256);
BEGIN
    p_STATUS := MEX_SWITCHBOARD.c_STATUS_SUCCESS;

	MM_PJM_EMKT.MARKET_EXCHANGE(TRUNC(p_BEGIN_DATE), TRUNC(p_END_DATE), MM_PJM_EMKT.g_ET_QUERY_SPREG_AWARDS,
	 							NULL, NULL, g_LOG_ONLY, g_LOG_TYPE, g_TRACE_ON, p_STATUS, p_MESSAGE);

	IF p_STATUS != MEX_SWITCHBOARD.c_STATUS_SUCCESS THEN
		LOGS.LOG_WARN('Problem importing SPREG Awards: ' || p_message);
	END IF;
END PJM_SPREG_AWARD;
---------------------------------------------------------------------------------------
PROCEDURE PJM_FTR_POSITION
	(
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE
	) IS
	p_STATUS NUMBER;
	p_MESSAGE VARCHAR2(256);
BEGIN
    p_STATUS := MEX_SWITCHBOARD.c_STATUS_SUCCESS;

    XS.data_exchange(p_request_type          => 1,
                     p_begin_date            => TRUNC(p_BEGIN_DATE),
                     p_end_date              => TRUNC(p_END_DATE),
                     p_as_of_date            => LOW_DATE,
                     p_exchange_type         => 'PJM: eftr: Query FTR Position',
                     p_module_name           => 'Scheduling',
                     p_entity_list           => NULL,
                     p_entity_list_delimiter => NULL,
                     p_status                => p_status,
                     p_message               => p_message);

	MM_PJM_EFTR.MARKET_EXCHANGE(TRUNC(p_BEGIN_DATE), TRUNC(p_END_DATE), MM_PJM_EFTR.g_ET_QUERY_FTR_POSITION,
	 							g_LOG_ONLY, g_LOG_TYPE, g_TRACE_ON, p_STATUS, p_MESSAGE);

	IF p_STATUS <> MEX_SWITCHBOARD.c_STATUS_SUCCESS THEN
		LOGS.LOG_WARN('Problem importing PJM FTR Position: ' || p_message);
	END IF;
END PJM_FTR_POSITION;
---------------------------------------------------------------------------------------
PROCEDURE PJM_CALCULATE_BILL
    (
    p_NUM_DAYS IN NUMBER
    ) IS
p_STATUS NUMBER;
p_MESSAGE VARCHAR2(256);
v_BEGIN_DATE DATE;
v_END_DATE DATE;
v_CALC_BEGIN DATE;
v_CALC_END DATE;
v_PSE_IDS NUMBER_COLLECTION;
v_WKDAY_COUNTER NUMBER;
p_DONT_CALC BOOLEAN := FALSE;
CURSOR p_PJM_CONTRACTS IS
    SELECT C.BILLING_ENTITY_ID
    FROM INTERCHANGE_CONTRACT C
    WHERE C.SC_ID = (SELECT SC.SC_ID FROM SC WHERE SC.SC_NAME = 'PJM');
BEGIN
     --enter desired pse ids and date range
    p_STATUS := MEX_SWITCHBOARD.c_STATUS_SUCCESS;
    v_PSE_IDS := NUMBER_COLLECTION();

    SETTLEMENT_DATE_RANGE(SYSDATE, v_BEGIN_DATE, v_END_DATE, v_WKDAY_COUNTER);

    IF TO_NUMBER(TO_CHAR(SYSDATE,'DD')) < 11 THEN
        --don't do a current month recalc on business day 6 as a full month
        --recalc for the previous month will be going on at this time
        IF v_WKDAY_COUNTER = 6 THEN
            p_DONT_CALC := TRUE;
        ELSIF TRUNC(SYSDATE, 'MM') = v_BEGIN_DATE THEN
            -- past 5th business day
            v_CALC_BEGIN := TRUNC(SYSDATE, 'MM');
            v_CALC_END := SYSDATE;
        ELSE
            --within first 5 business days, recalc entire previous month
            v_CALC_BEGIN := v_BEGIN_DATE;
            v_CALC_END := v_END_DATE;
        END IF;

    ELSE
        IF TRUNC(SYSDATE - TO_NUMBER(p_NUM_DAYS), 'MM') <> TRUNC(SYSDATE, 'MM') THEN
            -- if 15 days or less have elapsed in current month, just calc current month
            v_CALC_BEGIN := TRUNC(SYSDATE, 'MM');
            v_CALC_END := SYSDATE;
        ELSIF TO_CHAR(SYSDATE, 'Dy') = DATE_CONST.k_SUN THEN
            --calc entire month on Sundays
            v_CALC_BEGIN := TRUNC(SYSDATE, 'MM');
            v_CALC_END := SYSDATE;
        --Mondays, just calculate for the current day
        ELSIF TO_CHAR(SYSDATE, 'Dy') = DATE_CONST.k_MON THEN
            v_CALC_BEGIN := SYSDATE;
            v_CALC_END := SYSDATE;
        ELSE
            v_CALC_BEGIN := SYSDATE - TO_NUMBER(p_NUM_DAYS);
            v_CALC_END := SYSDATE;
        END IF;
    END IF;

    IF p_DONT_CALC = FALSE THEN
        FOR v_PJM_CONTRACT IN p_PJM_CONTRACTS LOOP
            IF v_PJM_CONTRACT.BILLING_ENTITY_ID IS NOT NULL THEN
                v_PSE_IDS := NUMBER_COLLECTION(v_PJM_CONTRACT.BILLING_ENTITY_ID);
                PC.BILLING_STATEMENT_REQUEST(p_CALLING_MODULE => 'Billing',
                                    p_MODEL_ID => 1,
                                    p_PSE_IDS => v_PSE_IDS,
                                    p_PRODUCT_ID => -1,
                                    p_COMPONENT_ID => -1,
                                    p_SCHEDULE_TYPE => 1,
                                    p_STATEMENT_TYPE => 1,
    							    p_BEGIN_DATE => v_CALC_BEGIN,
                                    p_END_DATE => v_CALC_END,
                                    p_INPUT_AS_OF_DATE => NULL,
                                    p_OUTPUT_AS_OF_DATE => NULL,
                                    p_GENERATE_INVOICE => 1.0,
                                    p_TRACE_ON => 0.0,
                                    p_PROCESS_STATUS => p_STATUS,
                                    p_MESSAGE => p_MESSAGE);


      	        IF p_STATUS != MEX_SWITCHBOARD.c_STATUS_SUCCESS THEN
    		        LOGS.LOG_WARN('Problem calculating PJM bill: ' || p_MESSAGE);
                END IF;
            END IF;
        END LOOP;
     END IF;
END PJM_CALCULATE_BILL;
---------------------------------------------------------------------------------------

PROCEDURE PJM_OP_RESV_RATES IS
	p_STATUS     NUMBER;
	p_MESSAGE    VARCHAR2(256);
	v_BEGIN_DATE DATE;
	v_END_DATE   DATE;

BEGIN
	p_STATUS := MEX_SWITCHBOARD.c_STATUS_SUCCESS;

	SETTLEMENT_DATE_RANGE(SYSDATE, v_BEGIN_DATE, v_END_DATE);

	MM_PJM_OASIS.MARKET_EXCHANGE(v_BEGIN_DATE, v_END_DATE, MM_PJM_OASIS.g_ET_QUERY_OP_RESV_RATES,
								 NULL, NULL, g_LOG_ONLY, g_LOG_TYPE, g_TRACE_ON, p_STATUS, p_MESSAGE);

	IF p_STATUS != MEX_SWITCHBOARD.c_STATUS_SUCCESS THEN
		LOGS.LOG_WARN('Problem querying PJM operating reserve rates: ' || p_message);
	END IF;
END PJM_OP_RESV_RATES;
---------------------------------------------------------------------------------------
end MM_PJM_SCHEDULED;
/
