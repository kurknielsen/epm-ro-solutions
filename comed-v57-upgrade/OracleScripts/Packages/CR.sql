CREATE OR REPLACE PACKAGE CR AS
--Revision $Revision: 1.23 $

-- Customer Level package

FUNCTION WHAT_VERSION RETURN VARCHAR;


PROCEDURE TREE_BRANCHES_CUSTOMER
    (
	p_DISPLAY_PREFERENCE IN VARCHAR,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_STATUS OUT NUMBER,
	p_CURSOR IN OUT GA.REFCURSOR
	);

PROCEDURE TREE_NODES_CUSTOMER
    (
	p_EDC_ID IN NUMBER,
	p_PSE_ID IN NUMBER,
	p_ESP_ID IN NUMBER,
	p_POOL_ID IN NUMBER,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_STATUS OUT NUMBER,
	p_CURSOR IN OUT GA.REFCURSOR
	);

PROCEDURE GET_CUSTOMERS_FOR_ACCOUNT
    (
	p_AGGREGATE_ID IN NUMBER,
	p_FILTER_STRING IN VARCHAR,
	p_FILTER_BY IN VARCHAR,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_STATUS OUT NUMBER,
	p_CURSOR IN OUT GA.REFCURSOR
	);

PROCEDURE CUSTOMER_ENROLLMENT
   (
	p_EDC_ID IN NUMBER,
	p_PSE_ID IN NUMBER,
	p_ESP_ID IN NUMBER,
	p_POOL_ID IN NUMBER,
	p_AGGREGATE_ID IN NUMBER,
	p_CUSTOMER_ID IN NUMBER,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_STATUS OUT NUMBER,
	p_CURSOR IN OUT GA.REFCURSOR
	);

PROCEDURE CUSTOMER_USAGE
   (
	p_EDC_ID IN NUMBER,
	p_PSE_ID IN NUMBER,
	p_ESP_ID IN NUMBER,
	p_POOL_ID IN NUMBER,
	p_AGGREGATE_ID IN NUMBER,
	p_CUSTOMER_ID IN NUMBER,
	p_BILL_CODE IN VARCHAR,
	p_CONSUMPTION_CODE IN VARCHAR,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_STATUS OUT NUMBER,
	p_CURSOR IN OUT GA.REFCURSOR
	);

PROCEDURE CUSTOMER_REPORTS
    (
	p_EDC_ID IN NUMBER,
	p_PSE_ID IN NUMBER,
	p_ESP_ID IN NUMBER,
	p_POOL_ID IN NUMBER,
	p_AGGREGATE_ID IN NUMBER,
	p_CUSTOMER_ID IN NUMBER,
	p_REPORT_NAME IN VARCHAR,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_STATUS OUT NUMBER,
	p_CURSOR IN OUT GA.REFCURSOR
	);

PROCEDURE UPDATE_CUSTOMER_CONSUMPTION
	(
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_BILL_CODE IN CHAR,
	p_CONSUMPTION_CODE IN CHAR,
	p_BILLED_USAGE IN NUMBER,
	p_METERED_USAGE IN NUMBER,
	p_METERS_READ IN NUMBER,
	p_IGNORE_CONSUMPTION IN NUMBER,
	p_CONSUMPTION_ID IN NUMBER,
	p_USER_NAME IN VARCHAR,
	p_STATUS OUT NUMBER
	 );

g_TOTAL NUMBER(2) := -2;
g_NA_BRANCH NUMBER(2) := -3; --The Id Is Not Defined In The Tree.
g_NA_NODE NUMBER(2) := 0;
g_NA_TABLE NUMBER(2) := 0;
g_ANYTIME NUMBER(1) := 1;

g_ALL_DETAIL NUMBER(2) := -1;
g_ALL_SUMMARY NUMBER(2) := -2;

g_BY_EDC NUMBER(1) := 1;
g_BY_ESP NUMBER(1) := 2;
g_BY_AGG NUMBER(1) := 3;

g_LOW_DATE DATE := LOW_DATE;
g_SECOND NUMBER (8,6) := 1/86400;
g_DOMAIN_NAME VARCHAR(16) := 'Data Setup';

END CR;
/
CREATE OR REPLACE PACKAGE BODY CR AS
---------------------------------------------------------------------------------------------------
FUNCTION WHAT_VERSION RETURN VARCHAR IS
BEGIN
    RETURN '$Revision: 1.23 $';
END WHAT_VERSION;
----------------------------------------------------------------------------------------------------
PROCEDURE NULL_CURSOR
    (
	p_CURSOR IN OUT GA.REFCURSOR
	) AS

BEGIN

	OPEN p_CURSOR FOR
		SELECT NULL FROM DUAL;

END NULL_CURSOR;
----------------------------------------------------------------------------------------------------
PROCEDURE SET_DISPLAY_PREFERENCES
    (
	p_DISPLAY_PREFERENCE IN VARCHAR,
	p_EDC IN OUT NUMBER,
	p_PSE IN OUT NUMBER,
	p_ESP IN OUT NUMBER,
	p_POOL IN OUT NUMBER
	) AS

BEGIN

	SELECT DECODE(INSTR(UPPER(p_DISPLAY_PREFERENCE), 'EDC'),0,0,1) INTO p_EDC FROM DUAL;
	SELECT DECODE(INSTR(UPPER(p_DISPLAY_PREFERENCE), 'PSE'),0,0,1) INTO p_PSE FROM DUAL;
	SELECT DECODE(INSTR(UPPER(p_DISPLAY_PREFERENCE), 'ESP'),0,0,1) INTO p_ESP FROM DUAL;
	SELECT DECODE(INSTR(UPPER(p_DISPLAY_PREFERENCE), 'POOL'),0,0,1) INTO p_POOL FROM DUAL;

END SET_DISPLAY_PREFERENCES;
---------------------------------------------------------------------------------------------------
PROCEDURE TREE_BRANCHES_CUSTOMER
    (
	p_DISPLAY_PREFERENCE IN VARCHAR,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_STATUS OUT NUMBER,
	p_CURSOR IN OUT GA.REFCURSOR
	) AS

-- Answer a recordset containing the EDC-PSE-ESP relationships for Enrollment

v_BEGIN_DATE DATE := TRUNC(p_BEGIN_DATE);
v_END_DATE DATE := TRUNC(p_END_DATE);
v_EDC NUMBER(1);
v_PSE NUMBER(1);
v_ESP NUMBER(1);
v_POOL NUMBER(1);
v_ESP_TYPE CHAR(1);

BEGIN

	IF NOT CAN_READ(g_DOMAIN_NAME) THEN
		ERRS.RAISE_NO_READ_MODULE(g_DOMAIN_NAME);
	END IF;

    p_STATUS := GA.SUCCESS;

	SET_DISPLAY_PREFERENCES(p_DISPLAY_PREFERENCE, v_EDC, v_PSE, v_ESP, v_POOL);

	OPEN p_CURSOR FOR
		SELECT DECODE(v_EDC,1, B.EDC_ID, CONSTANTS.NOT_ASSIGNED) "EDC_ID",
		    DECODE(v_EDC, 1, B.EDC_NAME, NULL) "EDC_NAME",
			DECODE(v_PSE, 1, C.PSE_ID, CONSTANTS.NOT_ASSIGNED) "PSE_ID",
		    DECODE(v_PSE, 1, C.PSE_NAME, NULL) "PSE_NAME",
			DECODE(v_ESP, 1, D.ESP_ID, CONSTANTS.NOT_ASSIGNED) "ESP_ID",
			DECODE(v_ESP, 1, D.ESP_NAME, NULL) "ESP_NAME",
			DECODE(v_POOL, 1, E.POOL_ID, CONSTANTS.NOT_ASSIGNED) "POOL_ID",
			DECODE(v_POOL, 1, E.POOL_NAME, NULL) "POOL_NAME"
		FROM
			(SELECT DISTINCT EDC_ID, PSE_ID, ESP_ID, POOL_ID
			FROM ACCOUNT_ENROLLMENT_TREE
			WHERE EDC_BEGIN_DATE <= v_END_DATE AND NVL(EDC_END_DATE, v_END_DATE) >= v_BEGIN_DATE
				AND ESP_BEGIN_DATE <= v_END_DATE AND NVL(ESP_END_DATE, v_END_DATE) >= v_BEGIN_DATE
				AND PSE_BEGIN_DATE <= v_END_DATE AND NVL(PSE_END_DATE, v_END_DATE) >= v_BEGIN_DATE)  A,
			ENERGY_DISTRIBUTION_COMPANY B,
			PURCHASING_SELLING_ENTITY C,
			ENERGY_SERVICE_PROVIDER D,
			POOL E
		WHERE B.EDC_ID = A.EDC_ID
			AND C.PSE_ID = A.PSE_ID
			AND D.ESP_ID = A.ESP_ID
			AND E.POOL_ID = A.POOL_ID
		ORDER BY 2,4,6,8;

END TREE_BRANCHES_CUSTOMER;
---------------------------------------------------------------------------------------------------
PROCEDURE TREE_NODES_CUSTOMER
    (
	p_EDC_ID IN NUMBER,
	p_PSE_ID IN NUMBER,
	p_ESP_ID IN NUMBER,
	p_POOL_ID IN NUMBER,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_STATUS OUT NUMBER,
	p_CURSOR IN OUT GA.REFCURSOR
	) AS

-- Answer a recordset containing the aggregate retail accounts associated with an EDC-PSE-ESP.

BEGIN

	IF NOT CAN_READ(g_DOMAIN_NAME) THEN
		ERRS.RAISE_NO_READ_MODULE(g_DOMAIN_NAME);
	END IF;

	p_STATUS := GA.SUCCESS;
		OPEN p_CURSOR FOR
	    	 SELECT ACCOUNT_NAME, ACCOUNT_ID, AGGREGATE_ID
			 FROM AGGREGATE_ACCOUNTS A
   		 WHERE (p_EDC_ID = g_NA_BRANCH OR A.EDC_ID = p_EDC_ID)
					AND (p_ESP_ID = g_NA_BRANCH OR A.ESP_ID = p_ESP_ID)
					AND (p_PSE_ID = g_NA_BRANCH OR A.PSE_ID = p_PSE_ID)
					AND (p_POOL_ID = g_NA_BRANCH OR A.POOL_ID = p_POOL_ID)
					AND A.CASE_ID = A.CASE_ID
					AND A.AGGREGATE_ID > 0
					AND A.SERVICE_DATE BETWEEN TRUNC(p_BEGIN_DATE) AND TRUNC(p_END_DATE)
					AND A.AS_OF_DATE = g_LOW_DATE
			  GROUP BY ACCOUNT_NAME, ACCOUNT_ID, AGGREGATE_ID
			  ORDER BY 1,2,3;

END TREE_NODES_CUSTOMER;
---------------------------------------------------------------------------------------------------
PROCEDURE GET_CUSTOMERS_FOR_ACCOUNT
    (
	p_AGGREGATE_ID IN NUMBER,
	p_FILTER_STRING IN VARCHAR,
	p_FILTER_BY IN VARCHAR,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_STATUS OUT NUMBER,
	p_CURSOR IN OUT GA.REFCURSOR
	) AS

-- Answer a recordset containing the CUSTOMERS ASSOCIATED WITH AN AGGREGATE ACCOUNT.
v_FILTER_BY CHAR(1);
BEGIN

	IF NOT CAN_READ(g_DOMAIN_NAME) THEN
		ERRS.RAISE_NO_READ_MODULE(g_DOMAIN_NAME);
	END IF;

	p_STATUS := GA.SUCCESS;
	v_FILTER_BY := UPPER(SUBSTR(p_FILTER_BY,1,1));
		OPEN p_CURSOR FOR
		    SELECT DECODE(v_FILTER_BY, 'N', B.CUSTOMER_NAME, B.CUSTOMER_IDENTIFIER) "CUSTOMER_NAME",
				A.CUSTOMER_ID
			FROM AGGREGATE_ACCOUNT_CUSTOMER A, CUSTOMER B
			WHERE A.AGGREGATE_ID = p_AGGREGATE_ID
					AND A.BEGIN_DATE <= TRUNC(p_END_DATE)
					AND NVL(A.END_DATE,HIGH_DATE) >= TRUNC(p_BEGIN_DATE)
					AND A.CUSTOMER_ID = B.CUSTOMER_ID
					AND B.CUSTOMER_NAME LIKE DECODE(v_FILTER_BY,'N',p_FILTER_STRING,B.CUSTOMER_NAME)
					AND B.CUSTOMER_IDENTIFIER LIKE DECODE(v_FILTER_BY,'I',p_FILTER_STRING,B.CUSTOMER_IDENTIFIER)
			ORDER BY 1;

END GET_CUSTOMERS_FOR_ACCOUNT;
---------------------------------------------------------------------------------------------------
PROCEDURE CUSTOMER_ENROLLMENT_BRANCH
    (
	p_EDC_ID IN NUMBER,
	p_PSE_ID IN NUMBER,
	p_ESP_ID IN NUMBER,
	p_POOL_ID IN NUMBER,
	p_AGGREGATE_ID IN NUMBER,
	p_CUSTOMER_ID IN NUMBER,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_STATUS OUT NUMBER,
	p_CURSOR IN OUT GA.REFCURSOR
	) AS

-- Answer a recordset containing the enrollment summary for the selection.
v_BEGIN_DATE DATE := TRUNC(p_BEGIN_DATE);
v_END_DATE DATE := TRUNC(p_END_DATE);
v_WORK_ID NUMBER(9);
BEGIN

	p_STATUS := GA.SUCCESS;
	IF p_CUSTOMER_ID = g_ALL_SUMMARY THEN
		UT.GET_RTO_WORK_ID(v_WORK_ID);
		UT.POST_RTO_WORK_DATE_RANGE(v_WORK_ID, v_BEGIN_DATE, v_END_DATE, 'DD');
		OPEN p_CURSOR FOR
			SELECT Z.SERVICE_DATE, Z.AGGREGATE_ACCOUNTS, Z.CUSTOMERS
			FROM (
					 SELECT  A.SERVICE_DATE,COUNT(*) "AGGREGATE_ACCOUNTS" , SUM(A.SERVICE_ACCOUNTS) "CUSTOMERS"
					 FROM AGGREGATE_ACCOUNT_SERVICE A,  AGGREGATE_ACCOUNT_ESP B, ACCOUNT_EDC D, PSE_ESP E
					 WHERE (p_EDC_ID = g_NA_BRANCH OR D.EDC_ID = p_EDC_ID)
					 AND (p_ESP_ID = g_NA_BRANCH OR B.ESP_ID = p_ESP_ID)
					 AND (p_PSE_ID = g_NA_BRANCH OR E.PSE_ID = p_PSE_ID)
					 AND (p_POOL_ID = g_NA_BRANCH OR B.POOL_ID = p_POOL_ID)
					 AND A.AGGREGATE_ID > 0
					 AND A.AGGREGATE_ID = B.AGGREGATE_ID
					 AND B.ESP_ID = E.ESP_ID
					 AND B.ACCOUNT_ID = D.ACCOUNT_ID
					 AND A.SERVICE_DATE BETWEEN B.BEGIN_DATE AND NVL(B.END_DATE,A.SERVICE_DATE)
					 AND A.SERVICE_DATE BETWEEN D.BEGIN_DATE AND NVL(D.END_DATE,A.SERVICE_DATE)
					 AND A.SERVICE_DATE BETWEEN E.BEGIN_DATE AND NVL(E.END_DATE,A.SERVICE_DATE)
					 AND A.SERVICE_DATE BETWEEN p_BEGIN_DATE AND p_END_DATE
					 AND A.AS_OF_DATE = g_LOW_DATE
					 AND A.CASE_ID = A.CASE_ID
					 GROUP BY A.SERVICE_DATE
					 ) Z,
					 RTO_WORK C
			WHERE C.WORK_DATE BETWEEN P_BEGIN_DATE AND P_END_DATE
			AND Z.SERVICE_DATE = C.WORK_DATE;

		UT.PURGE_RTO_WORK(v_WORK_ID);
	ELSIF p_CUSTOMER_ID = g_ALL_DETAIL THEN
		OPEN p_CURSOR FOR
				SELECT B.SERVICE_DATE,	F.ESP_NAME,	F.ESP_ID,	F.ACCOUNT_NAME,	F.ACCOUNT_ID,	F.AGGREGATE_ID, E.CUSTOMER_NAME,	E.CUSTOMER_IDENTIFIER,	E.CUSTOMER_ID
				FROM AGGREGATE_ACCOUNT_SERVICE B, AGGREGATE_ACCOUNT_ESP_ALL F, CUSTOMER E, AGGREGATE_ACCOUNT_CUSTOMER C, PSE_ESP A, ACCOUNT_EDC D
				WHERE C.CUSTOMER_ID = E.CUSTOMER_ID
				AND C.AGGREGATE_ID = F.AGGREGATE_ID
				AND B.AGGREGATE_ID = F.AGGREGATE_ID
				AND E.CUSTOMER_IS_ACTIVE = 1
				AND F.ACCOUNT_ID = D.ACCOUNT_ID
				AND A.ESP_ID = F.ESP_ID
				AND (p_EDC_ID = g_NA_BRANCH OR D.EDC_ID = p_EDC_ID)
				AND (p_ESP_ID = g_NA_BRANCH OR F.ESP_ID = p_ESP_ID)
				AND (p_PSE_ID = g_NA_BRANCH OR A.PSE_ID = p_PSE_ID)
				AND (p_POOL_ID = g_NA_BRANCH OR F.POOL_ID = p_POOL_ID)
				AND B.SERVICE_DATE BETWEEN  F.BEGIN_DATE AND NVL(F.END_DATE,B.SERVICE_DATE)
				AND B.SERVICE_DATE BETWEEN  C.BEGIN_DATE AND NVL(C.END_DATE,B.SERVICE_DATE)
				AND B.SERVICE_DATE BETWEEN  p_BEGIN_DATE AND p_END_DATE
				AND B.AS_OF_DATE = g_LOW_DATE
				AND B.CASE_ID = B.CASE_ID
				ORDER BY 1,2,5,8;
	ELSE
		-- Work-around VB bug - this procedure can get called
		-- with invalid customer ID in the middle of selection
		-- change event in VB code
		OPEN p_CURSOR FOR
			SELECT NULL as "-"
			FROM DUAL
			WHERE  0=1;
	END IF;

EXCEPTION
	WHEN OTHERS THEN
		UT.PURGE_RTO_WORK(v_WORK_ID);
		ERRS.LOG_AND_RAISE();

END CUSTOMER_ENROLLMENT_BRANCH;

---------------------------------------------------------------------------------------------------
PROCEDURE CUSTOMER_ENROLLMENT_AGGREGATE
    (
	p_AGGREGATE_ID IN NUMBER,
	p_CUSTOMER_ID IN NUMBER,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_STATUS OUT NUMBER,
	p_CURSOR IN OUT GA.REFCURSOR
	) AS

-- Answer a recordset containing the enrollment detail for the selection.
v_BEGIN_DATE DATE := TRUNC(p_BEGIN_DATE);
v_END_DATE DATE := TRUNC(p_END_DATE);
v_WORK_ID NUMBER(9);
BEGIN

	p_STATUS := GA.SUCCESS;
	UT.GET_RTO_WORK_ID(v_WORK_ID);
	UT.POST_RTO_WORK_DATE_RANGE(v_WORK_ID, v_BEGIN_DATE, v_END_DATE, 'DD');

	IF p_CUSTOMER_ID = g_ALL_SUMMARY THEN
		OPEN p_CURSOR FOR
			SELECT W.SERVICE_DATE, W.SERVICE_ACCOUNTS, X.ESP_NAME, X.ESP_ID, Y.ACCOUNT_NAME, Y.ACCOUNT_ID
			FROM
			  (SELECT C.WORK_DATE "SERVICE_DATE",
					COUNT(*) "SERVICE_ACCOUNTS",
					B.ACCOUNT_ID,
					B.ESP_ID
				FROM AGGREGATE_ACCOUNT_CUSTOMER A, AGGREGATE_ACCOUNTS B, RTO_WORK C
				WHERE C.WORK_ID = v_WORK_ID
					AND A.AGGREGATE_ID = p_AGGREGATE_ID
					AND C.WORK_DATE BETWEEN A.BEGIN_DATE AND NVL(A.END_DATE,HIGH_DATE)
					AND B.SERVICE_DATE = C.WORK_DATE
					AND B.AGGREGATE_ID = A.AGGREGATE_ID
				 GROUP BY C.WORK_DATE, B.ACCOUNT_ID, B.ESP_ID) W,
				ENERGY_SERVICE_PROVIDER X,
				ACCOUNT Y
			WHERE X.ESP_ID = W.ESP_ID
				AND Y.ACCOUNT_ID = W.ACCOUNT_ID
			ORDER BY 1;
		ELSIF p_CUSTOMER_ID = g_ALL_DETAIL THEN
			OPEN p_CURSOR FOR
				SELECT W.SERVICE_DATE, X.ESP_NAME, X.ESP_ID, Y.ACCOUNT_NAME, Y.ACCOUNT_ID, Z.CUSTOMER_NAME, Z.CUSTOMER_IDENTIFIER, Z.CUSTOMER_ID
				FROM
				  (SELECT C.WORK_DATE "SERVICE_DATE",
						A.CUSTOMER_ID,
						B.ACCOUNT_ID,
						B.ESP_ID
					FROM AGGREGATE_ACCOUNT_CUSTOMER A, AGGREGATE_ACCOUNTS B, RTO_WORK C
					WHERE C.WORK_ID = v_WORK_ID
						AND A.AGGREGATE_ID = p_AGGREGATE_ID
						AND C.WORK_DATE BETWEEN A.BEGIN_DATE AND NVL(A.END_DATE,HIGH_DATE)
						AND B.SERVICE_DATE = C.WORK_DATE
						AND B.AGGREGATE_ID = A.AGGREGATE_ID) W,
					ENERGY_SERVICE_PROVIDER X,
					ACCOUNT Y,
					CUSTOMER Z
				WHERE X.ESP_ID = W.ESP_ID
					AND Y.ACCOUNT_ID = W.ACCOUNT_ID
					AND Z.CUSTOMER_ID = W.CUSTOMER_ID
				ORDER BY 1,2,4,6;
		ELSE
			-- Work-around VB bug - this procedure can get called
			-- with invalid customer ID in the middle of selection
			-- change event in VB code
			OPEN p_CURSOR FOR
				SELECT NULL as "-"
				FROM DUAL
				WHERE  0=1;
		END IF;


		UT.PURGE_RTO_WORK(v_WORK_ID);

EXCEPTION
	WHEN OTHERS THEN
		UT.PURGE_RTO_WORK(v_WORK_ID);
		ERRS.LOG_AND_RAISE();

END CUSTOMER_ENROLLMENT_AGGREGATE;
---------------------------------------------------------------------------------------------------
PROCEDURE CUSTOMER_ENROLLMENT_DETAIL
    (
	p_CUSTOMER_ID IN NUMBER,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_STATUS OUT NUMBER,
	p_CURSOR IN OUT GA.REFCURSOR
	) AS

-- Answer a recordset containing the enrollment detail for the selection.
v_BEGIN_DATE DATE := TRUNC(p_BEGIN_DATE);
v_END_DATE DATE := TRUNC(p_END_DATE);
BEGIN

	p_STATUS := GA.SUCCESS;
	OPEN p_CURSOR FOR
		SELECT W.SERVICE_DATE, W.SERVICE_ACCOUNTS,
			W.USAGE_FACTOR, X.ESP_NAME, X.ESP_ID, Y.ACCOUNT_NAME, Y.ACCOUNT_ID,
			Z.CUSTOMER_NAME, Z.CUSTOMER_IDENTIFIER, Z.CUSTOMER_ID
		FROM
			(SELECT B.SERVICE_DATE,
				NVL(C.SERVICE_ACCOUNTS,1) "SERVICE_ACCOUNTS",
				C.USAGE_FACTOR,
				A.CUSTOMER_ID,
			 	B.AGGREGATE_ID,
				B.ACCOUNT_ID,
				B.ESP_ID
			FROM AGGREGATE_ACCOUNT_CUSTOMER A, AGGREGATE_ACCOUNTS B, CUSTOMER_SERVICE C
			WHERE  A.BEGIN_DATE <= v_END_DATE
				AND NVL(A.END_DATE,HIGH_DATE) >= v_BEGIN_DATE
				AND A.CUSTOMER_ID = p_CUSTOMER_ID
				AND B.SERVICE_DATE BETWEEN A.BEGIN_DATE AND NVL(A.END_DATE,HIGH_DATE)
				AND B.SERVICE_DATE BETWEEN v_BEGIN_DATE AND v_END_DATE  -- only specified days
				AND B.AGGREGATE_ID = A.AGGREGATE_ID
				AND C.CUSTOMER_ID(+) = p_CUSTOMER_ID
				AND C.SERVICE_DATE(+) = B.SERVICE_DATE) W,
			ENERGY_SERVICE_PROVIDER X,
			ACCOUNT Y,
			CUSTOMER Z
		WHERE X.ESP_ID = W.ESP_ID
			AND Y.ACCOUNT_ID = W.ACCOUNT_ID
			AND Z.CUSTOMER_ID = W.CUSTOMER_ID
		ORDER BY 1;

END CUSTOMER_ENROLLMENT_DETAIL;
---------------------------------------------------------------------------------------------------
PROCEDURE CUSTOMER_ENROLLMENT
    (
	p_EDC_ID IN NUMBER,
	p_PSE_ID IN NUMBER,
	p_ESP_ID IN NUMBER,
	p_POOL_ID IN NUMBER,
	p_AGGREGATE_ID IN NUMBER,
	p_CUSTOMER_ID IN NUMBER,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_STATUS OUT NUMBER,
	p_CURSOR IN OUT GA.REFCURSOR
	) AS

-- Answer a recordset containing the enrollment for the selection.

BEGIN

	IF NOT CAN_READ(g_DOMAIN_NAME) THEN
		ERRS.RAISE_NO_READ_MODULE(g_DOMAIN_NAME);
	END IF;

	IF p_CUSTOMER_ID > 0 THEN
		CUSTOMER_ENROLLMENT_DETAIL(p_CUSTOMER_ID, p_BEGIN_DATE, p_END_DATE, p_STATUS, p_CURSOR);
	ELSIF NOT p_AGGREGATE_ID = g_NA_NODE THEN
		CUSTOMER_ENROLLMENT_AGGREGATE(p_AGGREGATE_ID, p_CUSTOMER_ID, p_BEGIN_DATE, p_END_DATE, p_STATUS, p_CURSOR);
	ELSE
		CUSTOMER_ENROLLMENT_BRANCH(p_EDC_ID, p_PSE_ID, p_ESP_ID, p_POOL_ID, p_AGGREGATE_ID, p_CUSTOMER_ID, p_BEGIN_DATE, p_END_DATE, p_STATUS, p_CURSOR);
	END IF;

END CUSTOMER_ENROLLMENT;
---------------------------------------------------------------------------------------------------
PROCEDURE CUSTOMER_USAGE_BRANCH
    (
	p_EDC_ID IN NUMBER,
	p_PSE_ID IN NUMBER,
	p_ESP_ID IN NUMBER,
	p_POOL_ID IN NUMBER,
	p_AGGREGATE_ID IN NUMBER,
	p_CUSTOMER_ID IN NUMBER,
	p_BILL_CODE IN CHAR,
	p_CONSUMPTION_CODE IN CHAR,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_STATUS OUT NUMBER,
	p_CURSOR IN OUT GA.REFCURSOR
	) AS

-- Answer a recordset containing the USAGE summary for the selection.
v_BEGIN_DATE DATE := TRUNC(p_BEGIN_DATE);
v_END_DATE DATE := TRUNC(p_END_DATE);
BEGIN

	p_STATUS := GA.SUCCESS;
	IF p_CUSTOMER_ID = g_ALL_SUMMARY THEN
		OPEN p_CURSOR FOR
			SELECT W.BEGIN_DATE, W.END_DATE, X.ESP_NAME, X.ESP_ID, Y.ACCOUNT_NAME, Y.ACCOUNT_ID,
					W.BILL_CODE, W.CONSUMPTION_CODE, W.BILLED_USAGE, W.METERED_USAGE, W.METERS_READ, W.RECEIVED_DATE
			FROM
				(SELECT A.BEGIN_DATE, A.END_DATE, C.AGGREGATE_ID, C.ACCOUNT_ID, C.ESP_ID, A.BILL_CODE, A.CONSUMPTION_CODE,
				  SUM(A.BILLED_USAGE) "BILLED_USAGE",
				  SUM(A.METERED_USAGE) "METERED_USAGE",
				  SUM(A.METERS_READ) "METERS_READ",
				  MAX(A.RECEIVED_DATE) "RECEIVED_DATE"
				  FROM CUSTOMER_CONSUMPTION A,
				  		 AGGREGATE_ACCOUNT_CUSTOMER B,
				  		 AGGREGATE_ACCOUNT_ESP C,
						 ACCOUNT_EDC D,
						 PSE_ESP E
				  WHERE (p_BILL_CODE = '<' OR A.BILL_CODE = p_BILL_CODE)
						AND (p_CONSUMPTION_CODE = '<' OR A.CONSUMPTION_CODE = p_CONSUMPTION_CODE)
						AND A.IGNORE_CONSUMPTION = 0
						AND A.BEGIN_DATE <= v_END_DATE
						AND A.END_DATE >= v_BEGIN_DATE
				  		AND B.CUSTOMER_ID = A.CUSTOMER_ID
						AND B.BEGIN_DATE <= A.END_DATE
						AND NVL(B.END_DATE, HIGH_DATE) >= A.BEGIN_DATE
						AND (p_ESP_ID = g_NA_BRANCH OR C.ESP_ID = p_ESP_ID)
						AND (p_POOL_ID = g_NA_BRANCH OR C.POOL_ID = p_POOL_ID)
						AND C.AGGREGATE_ID = B.AGGREGATE_ID
						AND C.BEGIN_DATE <= A.END_DATE
						AND NVL(C.END_DATE, HIGH_DATE) >= A.BEGIN_DATE
						AND (p_EDC_ID = g_NA_BRANCH OR D.EDC_ID = p_EDC_ID)
						AND D.ACCOUNT_ID = C.ACCOUNT_ID
						AND D.BEGIN_DATE <= A.END_DATE
						AND NVL(D.END_DATE, HIGH_DATE) >= A.BEGIN_DATE
						AND (p_PSE_ID = g_NA_BRANCH OR E.PSE_ID = p_PSE_ID)
						AND E.ESP_ID = C.ESP_ID
						AND E.BEGIN_DATE <= A.END_DATE
						AND NVL(E.END_DATE, HIGH_DATE) >= A.BEGIN_DATE
				   GROUP BY A.BEGIN_DATE, A.END_DATE, C.AGGREGATE_ID, C.ACCOUNT_ID, C.ESP_ID, A.BILL_CODE, A.CONSUMPTION_CODE) W,
				ENERGY_SERVICE_PROVIDER X,
				ACCOUNT Y
			WHERE X.ESP_ID = W.ESP_ID
				AND Y.ACCOUNT_ID = W.ACCOUNT_ID
			ORDER BY 1,3,5,7,8;
	ELSIF p_CUSTOMER_ID = g_ALL_DETAIL THEN
			OPEN p_CURSOR FOR
			SELECT W.BEGIN_DATE, W.END_DATE, X.ESP_NAME, X.ESP_ID, Y.ACCOUNT_NAME, Y.ACCOUNT_ID,
				Z.CUSTOMER_NAME, Z.CUSTOMER_ID, W.AGGREGATE_ID,  W.BILL_CODE, W.CONSUMPTION_CODE, W.BILLED_USAGE,
				W.METERED_USAGE, W.METERS_READ, W.RECEIVED_DATE, W.BILL_PROCESSED_DATE, W.IGNORE_CONSUMPTION, W.CONSUMPTION_ID,
				W.HAS_AUDIT_TRAIL
			FROM
				(SELECT A.BEGIN_DATE, A.END_DATE, C.AGGREGATE_ID, C.ACCOUNT_ID, C.ESP_ID, A.CUSTOMER_ID, A.BILL_CODE, A.CONSUMPTION_CODE,
				  A.BILLED_USAGE, A.METERED_USAGE, A.METERS_READ, A.RECEIVED_DATE, A.BILL_PROCESSED_DATE, A.IGNORE_CONSUMPTION, A.CONSUMPTION_ID,
				  0 AS HAS_AUDIT_TRAIL
				  FROM CUSTOMER_CONSUMPTION A,
				  		 AGGREGATE_ACCOUNT_CUSTOMER B,
				  		 AGGREGATE_ACCOUNT_ESP C,
						 ACCOUNT_EDC D,
						 PSE_ESP E
				  WHERE (p_BILL_CODE = '<' OR A.BILL_CODE = p_BILL_CODE)
						AND (p_CONSUMPTION_CODE = '<' OR A.CONSUMPTION_CODE = p_CONSUMPTION_CODE)
						AND A.BEGIN_DATE <= v_END_DATE
						AND A.END_DATE >= v_BEGIN_DATE
				  		AND B.CUSTOMER_ID = A.CUSTOMER_ID
						AND B.BEGIN_DATE <= A.END_DATE
						AND NVL(B.END_DATE, HIGH_DATE) >= A.BEGIN_DATE
						AND (p_ESP_ID = g_NA_BRANCH OR C.ESP_ID = p_ESP_ID)
						AND (p_POOL_ID = g_NA_BRANCH OR C.POOL_ID = p_POOL_ID)
						AND C.AGGREGATE_ID = B.AGGREGATE_ID
						AND C.BEGIN_DATE <= A.END_DATE
						AND NVL(C.END_DATE, HIGH_DATE) >= A.BEGIN_DATE
						AND (p_EDC_ID = g_NA_BRANCH OR D.EDC_ID = p_EDC_ID)
						AND D.ACCOUNT_ID = C.ACCOUNT_ID
						AND D.BEGIN_DATE <= A.END_DATE
						AND NVL(D.END_DATE, HIGH_DATE) >= A.BEGIN_DATE
						AND (p_PSE_ID = g_NA_BRANCH OR E.PSE_ID = p_PSE_ID)
						AND E.ESP_ID = C.ESP_ID
						AND E.BEGIN_DATE <= A.END_DATE
						AND NVL(E.END_DATE, HIGH_DATE) >= A.BEGIN_DATE) W,
				ENERGY_SERVICE_PROVIDER X,
				ACCOUNT Y,
				CUSTOMER Z
			WHERE X.ESP_ID = W.ESP_ID
				AND Y.ACCOUNT_ID = W.ACCOUNT_ID
				AND Z.CUSTOMER_ID = W.CUSTOMER_ID
			ORDER BY 1,3,5,8,9;
	ELSE
		-- Work-around VB bug - this procedure can get called
		-- with invalid customer ID in the middle of selection
		-- change event in VB code
		OPEN p_CURSOR FOR
			SELECT NULL as "-"
			FROM DUAL
			WHERE  0=1;
	END IF;
END CUSTOMER_USAGE_BRANCH;
---------------------------------------------------------------------------------------------------
PROCEDURE CUSTOMER_USAGE_AGGREGATE
    (
	p_AGGREGATE_ID IN NUMBER,
	p_CUSTOMER_ID IN NUMBER,
	p_BILL_CODE IN CHAR,
	p_CONSUMPTION_CODE IN CHAR,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_STATUS OUT NUMBER,
	p_CURSOR IN OUT GA.REFCURSOR
	) AS

-- Answer a recordset containing the USAGE detail for the selection.
v_BEGIN_DATE DATE := TRUNC(p_BEGIN_DATE);
v_END_DATE DATE := TRUNC(p_END_DATE);
BEGIN

	p_STATUS := GA.SUCCESS;

	IF p_CUSTOMER_ID = g_ALL_SUMMARY THEN
		OPEN p_CURSOR FOR
			SELECT W.BEGIN_DATE, W.END_DATE, X.ESP_NAME, X.ESP_ID, Y.ACCOUNT_NAME, Y.ACCOUNT_ID,
					W.BILL_CODE, W.CONSUMPTION_CODE, W.BILLED_USAGE, W.METERED_USAGE, W.METERS_READ, W.RECEIVED_DATE
			FROM
				(SELECT A.BEGIN_DATE, A.END_DATE, C.AGGREGATE_ID, C.ACCOUNT_ID, C.ESP_ID, A.BILL_CODE, A.CONSUMPTION_CODE,
				  SUM(A.BILLED_USAGE) "BILLED_USAGE",
				  SUM(A.METERED_USAGE) "METERED_USAGE",
				  SUM(A.METERS_READ) "METERS_READ",
				  MAX(A.RECEIVED_DATE) "RECEIVED_DATE"
				  FROM CUSTOMER_CONSUMPTION A, AGGREGATE_ACCOUNT_CUSTOMER B, AGGREGATE_ACCOUNT_ESP C
				  WHERE B.AGGREGATE_ID = p_AGGREGATE_ID
				  		AND (p_BILL_CODE = '<' OR A.BILL_CODE = p_BILL_CODE)
						AND (p_CONSUMPTION_CODE = '<' OR A.CONSUMPTION_CODE = p_CONSUMPTION_CODE)
						AND A.IGNORE_CONSUMPTION = 0
						AND A.BEGIN_DATE <= v_END_DATE
						AND A.END_DATE >= v_BEGIN_DATE
						AND B.CUSTOMER_ID = A.CUSTOMER_ID
						AND B.BEGIN_DATE <= A.END_DATE
						AND NVL(B.END_DATE, HIGH_DATE) >= A.BEGIN_DATE
						AND C.AGGREGATE_ID = B.AGGREGATE_ID
						AND A.BEGIN_DATE <= A.END_DATE
						AND NVL(A.END_DATE, HIGH_DATE) >= A.BEGIN_DATE
				   GROUP BY A.BEGIN_DATE, A.END_DATE, C.AGGREGATE_ID, C.ACCOUNT_ID, C.ESP_ID, A.BILL_CODE, A.CONSUMPTION_CODE) W,
				ENERGY_SERVICE_PROVIDER X,
				ACCOUNT Y
			WHERE X.ESP_ID = W.ESP_ID
				AND Y.ACCOUNT_ID = W.ACCOUNT_ID
			ORDER BY 1,3,5,7,8;
		ELSIF p_CUSTOMER_ID = g_ALL_DETAIL THEN
			OPEN p_CURSOR FOR
				SELECT W.BEGIN_DATE, W.END_DATE, X.ESP_NAME, X.ESP_ID, Y.ACCOUNT_NAME, Y.ACCOUNT_ID,
					Z.CUSTOMER_NAME, Z.CUSTOMER_ID, W.AGGREGATE_ID,  W.BILL_CODE, W.CONSUMPTION_CODE, W.BILLED_USAGE,
					W.METERED_USAGE, W.METERS_READ, W.RECEIVED_DATE, W.BILL_PROCESSED_DATE, W.IGNORE_CONSUMPTION, W.CONSUMPTION_ID,
					W.HAS_AUDIT_TRAIL
				FROM
					(SELECT A.BEGIN_DATE, A.END_DATE, C.AGGREGATE_ID, C.ACCOUNT_ID, C.ESP_ID, A.CUSTOMER_ID, A.BILL_CODE, A.CONSUMPTION_CODE,
					  A.BILLED_USAGE, A.METERED_USAGE, A.METERS_READ, A.RECEIVED_DATE, A.BILL_PROCESSED_DATE, A.IGNORE_CONSUMPTION, A.CONSUMPTION_ID,
					  0 AS HAS_AUDIT_TRAIL
					  FROM CUSTOMER_CONSUMPTION A, AGGREGATE_ACCOUNT_CUSTOMER B, AGGREGATE_ACCOUNT_ESP C
					  WHERE B.AGGREGATE_ID = p_AGGREGATE_ID
					  		AND (p_BILL_CODE = '<' OR A.BILL_CODE = p_BILL_CODE)
							AND (p_CONSUMPTION_CODE = '<' OR A.CONSUMPTION_CODE = p_CONSUMPTION_CODE)
							AND A.BEGIN_DATE <= v_END_DATE
							AND A.END_DATE >= v_BEGIN_DATE
							AND B.CUSTOMER_ID = A.CUSTOMER_ID
							AND B.BEGIN_DATE <= A.END_DATE
							AND NVL(B.END_DATE, HIGH_DATE) >= A.BEGIN_DATE
							AND C.AGGREGATE_ID = B.AGGREGATE_ID
							AND A.BEGIN_DATE <= A.END_DATE
							AND NVL(A.END_DATE, HIGH_DATE) >= A.BEGIN_DATE) W,
					ENERGY_SERVICE_PROVIDER X,
					ACCOUNT Y,
					CUSTOMER Z
				WHERE X.ESP_ID = W.ESP_ID
					AND Y.ACCOUNT_ID = W.ACCOUNT_ID
					AND Z.CUSTOMER_ID = W.CUSTOMER_ID
				ORDER BY 1,3,5,8,9;
		ELSE
			-- Work-around VB bug - this procedure can get called
			-- with invalid customer ID in the middle of selection
			-- change event in VB code
			OPEN p_CURSOR FOR
				SELECT NULL as "-"
				FROM DUAL
				WHERE  0=1;
		END IF;
END CUSTOMER_USAGE_AGGREGATE;
---------------------------------------------------------------------------------------------------
PROCEDURE CUSTOMER_USAGE_DETAIL
    (
	p_CUSTOMER_ID IN NUMBER,
	p_BILL_CODE IN CHAR,
	p_CONSUMPTION_CODE IN CHAR,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_STATUS OUT NUMBER,
	p_CURSOR IN OUT GA.REFCURSOR
	) AS

-- Answer a recordset containing the USAGE detail for the selection.
v_BEGIN_DATE DATE := TRUNC(p_BEGIN_DATE);
v_END_DATE DATE := TRUNC(p_END_DATE);


BEGIN

	p_STATUS := GA.SUCCESS;
	OPEN p_CURSOR FOR
		SELECT B.CUSTOMER_NAME, B.CUSTOMER_IDENTIFIER, A.CUSTOMER_ID, A.BEGIN_DATE, A.END_DATE, A.BILL_CODE, A.CONSUMPTION_CODE, A.RECEIVED_DATE,
			A.METER_TYPE, A.METER_READING, A.BILLED_USAGE, A.METERED_USAGE, A.METERS_READ, A.CONVERSION_FACTOR, A.IGNORE_CONSUMPTION, A.BILL_PROCESSED_DATE,
			A.CONSUMPTION_ID, 0 AS HAS_AUDIT_TRAIL
		FROM CUSTOMER_CONSUMPTION A, CUSTOMER B
		WHERE A.CUSTOMER_ID = p_CUSTOMER_ID
			AND A.BEGIN_DATE <= p_END_DATE
			AND A.END_DATE >= p_BEGIN_DATE
			AND (p_BILL_CODE = '<' OR A.BILL_CODE = p_BILL_CODE)
			AND (p_CONSUMPTION_CODE = '<' OR A.CONSUMPTION_CODE = p_CONSUMPTION_CODE)
			AND A.CUSTOMER_ID = B.CUSTOMER_ID
		ORDER BY 1,4,5,6,7;

END CUSTOMER_USAGE_DETAIL;
---------------------------------------------------------------------------------------------------
PROCEDURE CUSTOMER_USAGE
    (
	p_EDC_ID IN NUMBER,
	p_PSE_ID IN NUMBER,
	p_ESP_ID IN NUMBER,
	p_POOL_ID IN NUMBER,
	p_AGGREGATE_ID IN NUMBER,
	p_CUSTOMER_ID IN NUMBER,
	p_BILL_CODE IN VARCHAR,
	p_CONSUMPTION_CODE IN VARCHAR,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_STATUS OUT NUMBER,
	p_CURSOR IN OUT GA.REFCURSOR
	) AS

-- Answer a recordset containing the USAGE for the selection.
v_BILL_CODE CHAR(1) := UPPER(SUBSTR(p_BILL_CODE,1,1));
v_CONSUMPTION_CODE CHAR(1) := UPPER(SUBSTR(p_CONSUMPTION_CODE,1,1));

BEGIN

	IF NOT CAN_READ(g_DOMAIN_NAME) THEN
		ERRS.RAISE_NO_READ_MODULE(g_DOMAIN_NAME);
	END IF;

	IF p_CUSTOMER_ID > 0 THEN
		CUSTOMER_USAGE_DETAIL(p_CUSTOMER_ID, v_BILL_CODE, v_CONSUMPTION_CODE, p_BEGIN_DATE, p_END_DATE, p_STATUS, p_CURSOR);
	ELSIF NOT p_AGGREGATE_ID = g_NA_NODE THEN
		CUSTOMER_USAGE_AGGREGATE(p_AGGREGATE_ID, p_CUSTOMER_ID, v_BILL_CODE, v_CONSUMPTION_CODE, p_BEGIN_DATE, p_END_DATE, p_STATUS, p_CURSOR);
	ELSE
		CUSTOMER_USAGE_BRANCH(p_EDC_ID, p_PSE_ID, p_ESP_ID, p_POOL_ID, p_AGGREGATE_ID, p_CUSTOMER_ID, v_BILL_CODE, v_CONSUMPTION_CODE, p_BEGIN_DATE, p_END_DATE, p_STATUS, p_CURSOR);
	END IF;

END CUSTOMER_USAGE;
---------------------------------------------------------------------------------------------------
PROCEDURE CUSTOMER_REPORTS
    (
	p_EDC_ID IN NUMBER,
	p_PSE_ID IN NUMBER,
	p_ESP_ID IN NUMBER,
	p_POOL_ID IN NUMBER,
	p_AGGREGATE_ID IN NUMBER,
	p_CUSTOMER_ID IN NUMBER,
	p_REPORT_NAME IN VARCHAR,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_STATUS OUT NUMBER,
	p_CURSOR IN OUT GA.REFCURSOR
	) AS

-- Answer a recordset containing the REPORT for the selection.
BEGIN

	IF NOT CAN_READ(g_DOMAIN_NAME) THEN
		ERRS.RAISE_NO_READ_MODULE(g_DOMAIN_NAME);
	END IF;


		NULL_CURSOR(p_CURSOR);

END CUSTOMER_REPORTS;
---------------------------------------------------------------------------------------------------
PROCEDURE UPDATE_CUSTOMER_CONSUMPTION
	(
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_BILL_CODE IN CHAR,
	p_CONSUMPTION_CODE IN CHAR,
	p_BILLED_USAGE IN NUMBER,
	p_METERED_USAGE IN NUMBER,
	p_METERS_READ IN NUMBER,
	p_IGNORE_CONSUMPTION IN NUMBER,
	p_CONSUMPTION_ID IN NUMBER,
	p_USER_NAME IN VARCHAR,
	p_STATUS OUT NUMBER
	 ) AS


-- Update changed fields in CUSTOMER_CONSUMPTION table, and store a record in ENTITY_AUDIT_TRAIL
v_OLD_CONSUMPTION CUSTOMER_CONSUMPTION%ROWTYPE;
BEGIN

	IF NOT CAN_WRITE(g_DOMAIN_NAME) THEN
		ERRS.RAISE_NO_WRITE_MODULE(g_DOMAIN_NAME);
	END IF;

    p_STATUS := GA.SUCCESS;

	 SELECT *
	 INTO v_OLD_CONSUMPTION
	 FROM CUSTOMER_CONSUMPTION
	 WHERE CONSUMPTION_ID = p_CONSUMPTION_ID;

	 UPDATE CUSTOMER_CONSUMPTION
	 SET BEGIN_DATE = p_BEGIN_DATE,
	 	  END_DATE = p_END_DATE,
		  BILL_CODE = UPPER(p_BILL_CODE),
		  CONSUMPTION_CODE = UPPER(p_CONSUMPTION_CODE),
		  BILLED_USAGE = p_BILLED_USAGE,
		  METERS_READ = p_METERS_READ,
		  METERED_USAGE = p_METERED_USAGE,
		  IGNORE_CONSUMPTION = p_IGNORE_CONSUMPTION
	 WHERE CONSUMPTION_ID = p_CONSUMPTION_ID;

END UPDATE_CUSTOMER_CONSUMPTION;
---------------------------------------------------------------------------------------------------
END CR; 
/
