CREATE OR REPLACE PACKAGE MM_ETAG IS

g_NOT_ASSIGNED NUMBER(1) := 0;
g_LOW_DATE DATE := LOW_DATE;
g_ALL_CHAR VARCHAR2(8) := '<All>';

TYPE REF_CURSOR IS REF CURSOR;

PROCEDURE GET_TRANSACTION_ETAG_RPT_SUMM
	(
	p_SCHEDULE_TYPE IN NUMBER,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,	
	p_LCA_CODE IN VARCHAR2, --SINK
	p_TAG_STATUS IN VARCHAR2,
	p_UNASSIGNED_ETAGS IN NUMBER,
	p_TIME_ZONE IN VARCHAR2,
	p_STATUS OUT NUMBER,
	p_CURSOR IN OUT REF_CURSOR
	);

PROCEDURE GET_TRANSACTION_LIST
  	(
	p_ETAG_ID IN NUMBER,
	p_TRANSACTION_ID IN NUMBER,
	p_UNASSIGNED_TRANSACTIONS IN NUMBER,
    p_STATUS OUT NUMBER,
  	p_CURSOR IN OUT REF_CURSOR
	);

PROCEDURE PUT_TRANSACTION_ETAG_RPT_SUMM
	(
	p_ETAG_ID IN NUMBER,
	p_TRANSACTION_ID IN NUMBER,
	p_STATUS OUT NUMBER
	);
	
PROCEDURE GET_TRANSACTION_ETAG_RPT_DETL
	(
	p_DETAIL_TYPE IN VARCHAR2,
	p_ETAG_ID IN NUMBER,
	p_STATUS OUT NUMBER,
	p_CURSOR IN OUT REF_CURSOR
	);

PROCEDURE GET_SINK_FILTER_LIST
	(
	p_STATUS OUT NUMBER,
	p_CURSOR IN OUT REF_CURSOR
	);
	
PROCEDURE GET_ETAG_STATUS_FILTER_LIST
	(
	p_STATUS OUT NUMBER,
	p_CURSOR IN OUT REF_CURSOR
	);
	
	
END MM_ETAG;
/
CREATE OR REPLACE PACKAGE BODY MM_ETAG IS

PROCEDURE GET_TRANSACTION_ETAG_RPT_SUMM
	(
	p_SCHEDULE_TYPE IN NUMBER,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,	
	p_LCA_CODE IN VARCHAR2, --SINK
	p_TAG_STATUS IN VARCHAR2,
	p_UNASSIGNED_ETAGS IN NUMBER,
	p_TIME_ZONE IN VARCHAR2,
	p_STATUS OUT NUMBER,
	p_CURSOR IN OUT REF_CURSOR
	) AS

BEGIN
	p_STATUS := GA.SUCCESS;

--  Here is the ETAG_DATE_RANGE view as of Jan 16, 2006.
-- 	CREATE OR REPLACE VIEW ETAG_DATE_RANGE AS
-- 	SELECT A.ETAG_ID, NVL(MIN(C.START_DATE),LOW_DATE) "BEGIN_DATE", NVL(MAX(C.END_DATE),HIGH_DATE) "END_DATE"
-- 	FROM ETAG A, ETAG_PROFILE B, ETAG_PROFILE_VALUE C
-- 	WHERE B.ETAG_ID(+) = A.ETAG_ID
-- 		AND C.PROFILE_KEY_ID(+) = B.PROFILE_KEY_ID
-- 	GROUP BY A.ETAG_ID;	

	--Show only etags that have not been assigned to a transaction.
	IF p_UNASSIGNED_ETAGS = 1 THEN
		OPEN p_CURSOR FOR
			SELECT E.*, 0 "TRANSACTION_ID"
			FROM ETAG E, ETAG_DATE_RANGE EDR
			WHERE EDR.ETAG_ID = E.ETAG_ID
				AND EDR.BEGIN_DATE <= p_END_DATE
				AND EDR.END_DATE >= p_BEGIN_DATE 
				AND (E.ETAG_STATUS = p_TAG_STATUS OR p_TAG_STATUS = g_ALL_CHAR)
				AND (E.LCA_CODE = p_LCA_CODE OR p_LCA_CODE = g_ALL_CHAR)
				AND NOT E.ETAG_ID IN (SELECT ETAG_ID FROM ETAG_TRANSACTION);
	--Show all etags for date range with their transactions.
	ELSE
		OPEN p_CURSOR FOR
			SELECT E.*, NVL(ET.TRANSACTION_ID,0) "TRANSACTION_ID"
			FROM ETAG E, ETAG_TRANSACTION ET, ETAG_DATE_RANGE EDR
			WHERE EDR.ETAG_ID = E.ETAG_ID
				AND EDR.BEGIN_DATE <= p_END_DATE
				AND EDR.END_DATE >= p_BEGIN_DATE 
				AND (E.ETAG_STATUS = p_TAG_STATUS OR p_TAG_STATUS = g_ALL_CHAR)
				AND (E.LCA_CODE = p_LCA_CODE OR p_LCA_CODE = g_ALL_CHAR)
				AND	ET.ETAG_ID(+) = E.ETAG_ID;
	END IF;	
	
END GET_TRANSACTION_ETAG_RPT_SUMM;
-- -------------------------------------------------------------------------------------
--   PROCEDURE ETAG_ASSIGNMENT_REPORT
--   (
--   p_MODEL_ID IN NUMBER,
--   p_SCHEDULE_TYPE IN NUMBER,
--   p_BEGIN_DATE IN DATE,
--   p_END_DATE IN DATE,
--   p_AS_OF_DATE IN DATE,
--   p_TIME_ZONE IN VARCHAR2,
--   p_NOTUSED_ID1 IN NUMBER,
--   p_NOTUSED_ID2 IN NUMBER,
--   p_NOTUSED_ID3 IN NUMBER,
--   p_REPORT_NAME IN VARCHAR2,
--   p_ZOD_NAME IN VARCHAR2,
--   p_TAG_STATUS IN VARCHAR2,
--   p_SHOW_ASSIGNED IN NUMBER,
--   p_STATUS OUT NUMBER,
--   p_CURSOR IN OUT REF_CURSOR
--   ) AS
-- 
--   BEGIN
-- 
--   	p_STATUS := GA.SUCCESS;
-- 
-- 
--   OPEN p_CURSOR FOR
--   SELECT
--     E.ETAG_ID, DECODE(NVL(IT.TRANSACTION_NAME,'<Unassigned>'),'<Unassigned>',0,1) "ACCEPTED",
-- 	NVL(IT.TRANSACTION_NAME,'<Unassigned>') "TRANSACTION_NAME", E.ETAG_NAME,
-- 	E.ETAG_STATUS STATUS, /*EP_G.SOURCE_CODE, EP_L.SINK_CODE, */EPV.START_DATE, EPV.END_DATE, EPV.MW_LEVEL,
-- 	E.ENTRY_DATE
--   FROM ETAG E, --ETAG_PHYSICAL_SEGMENT EP_G, ETAG_PHYSICAL_SEGMENT EP_L, 
--   	ETAG_PROFILE EP, ETAG_PROFILE_VALUE EPV,
--     ETAG_TRANSACTION ET, INTERCHANGE_TRANSACTION IT
--   WHERE (E.ETAG_STATUS = p_TAG_STATUS OR p_TAG_STATUS = '<All>')
--     AND (E.LCA_CODE = p_ZOD_NAME OR p_ZOD_NAME = '<All>')
-- --    AND E.ETAG_ID = EP_G.ETAG_ID
-- --    AND EP_G.SOURCE_CODE IS NOT NULL
-- --	AND E.ETAG_ID = EP_L.ETAG_ID
-- --    AND EP_L.SINK_CODE IS NOT NULL
-- 	AND E.ETAG_ID = EP.ETAG_ID
-- 	AND EP.PARENT_TYPE = 'GEN'
-- 	AND EP.PROFILE_KEY_ID = EPV.PROFILE_KEY_ID
-- 	AND EPV.START_DATE <= TRUNC(p_END_DATE) + 1
-- 	AND EPV.END_DATE >= TRUNC(p_BEGIN_DATE)
-- 	AND E.ETAG_ID = ET.ETAG_ID
-- 	AND ET.TRANSACTION_ID = IT.TRANSACTION_ID(+)
-- 	AND (IT.TRANSACTION_ID IS NULL OR p_SHOW_ASSIGNED = 1)
--   ORDER BY EPV.START_DATE ASC;
-- 
--   EXCEPTION
-- 	    WHEN OTHERS THEN
-- 		    p_STATUS := SQLCODE;
-- 
--   END ETAG_ASSIGNMENT_REPORT;
-------------------------------------------------------------------------------------
PROCEDURE GET_TRANSACTION_LIST
  	(
	p_ETAG_ID IN NUMBER,
	p_TRANSACTION_ID IN NUMBER,
	p_UNASSIGNED_TRANSACTIONS IN NUMBER,
    p_STATUS OUT NUMBER,
  	p_CURSOR IN OUT REF_CURSOR
  	) AS

  BEGIN

	p_STATUS := GA.SUCCESS;
	
	--Show all transactions that can be assigned, even if they are already assigned.
	IF p_UNASSIGNED_TRANSACTIONS = 0 THEN
		OPEN p_CURSOR FOR
			SELECT TRANSACTION_NAME, TRANSACTION_ID
			FROM INTERCHANGE_TRANSACTION A, IT_COMMODITY B
			WHERE TRANSACTION_TYPE IN ('Purchase','Sale')
				AND B.COMMODITY_TYPE = 'Energy'
				AND A.COMMODITY_ID = B.COMMODITY_ID
			ORDER BY TRANSACTION_NAME;
	--If there is a particular Transaction already selected, then return it.
	--Show only the transactions that have no etag assignment
	ELSE --p_UNASSIGNED_TRANSACTIONS = 1 THEN
		OPEN p_CURSOR FOR
			SELECT TRANSACTION_NAME, TRANSACTION_ID
			FROM INTERCHANGE_TRANSACTION
			WHERE TRANSACTION_ID = p_TRANSACTION_ID
				AND TRANSACTION_ID > 0
			UNION ALL
			SELECT TRANSACTION_NAME, TRANSACTION_ID
			FROM INTERCHANGE_TRANSACTION A, IT_COMMODITY B
			WHERE TRANSACTION_TYPE IN ('Purchase','Sale')
				AND B.COMMODITY_TYPE = 'Energy'
				AND A.COMMODITY_ID = B.COMMODITY_ID
				AND NOT TRANSACTION_ID IN (SELECT TRANSACTION_ID FROM ETAG_TRANSACTION) 
			ORDER BY 1;
	END IF;
	
END GET_TRANSACTION_LIST;
-------------------------------------------------------------------------------------
PROCEDURE PUT_TRANSACTION_ETAG_RPT_SUMM
	(
	p_ETAG_ID IN NUMBER,
	p_TRANSACTION_ID IN NUMBER,
	p_STATUS OUT NUMBER
	) AS 
BEGIN

	p_STATUS := GA.SUCCESS;

	UPDATE ETAG_TRANSACTION
		SET TRANSACTION_ID = p_TRANSACTION_ID
		WHERE ETAG_ID = p_ETAG_ID;

	IF SQL%NOTFOUND THEN
		INSERT INTO ETAG_TRANSACTION VALUES (p_ETAG_ID, p_TRANSACTION_ID);
	END IF;

END PUT_TRANSACTION_ETAG_RPT_SUMM;
-------------------------------------------------------------------------------------
--   PROCEDURE ETAG_VOLUMES_REPORT
--   (
--   p_MODEL_ID IN NUMBER,
--   p_SCHEDULE_TYPE IN NUMBER,
--   p_BEGIN_DATE IN DATE,
--   p_END_DATE IN DATE,
--   p_AS_OF_DATE IN DATE,
--   p_TIME_ZONE IN VARCHAR2,
--   p_NOTUSED_ID1 IN NUMBER,
--   p_NOTUSED_ID2 IN NUMBER,
--   p_NOTUSED_ID3 IN NUMBER,
--   p_REPORT_NAME IN VARCHAR2,
--   p_ZOD_ID IN NUMBER,
--   p_TRANSACTION_ID IN NUMBER,
--   p_STATUS OUT NUMBER,
--   p_CURSOR IN OUT REF_CURSOR
--   ) AS
-- 
--   v_BEGIN_DATE DATE;
--   v_END_DATE DATE;
-- 
--   BEGIN
-- 
--   	p_STATUS := GA.SUCCESS;
-- 
-- 	Ut.CUT_DATE_RANGE(1,
--     	              TRUNC(p_BEGIN_DATE),
--     				  TRUNC(p_END_DATE),
--     				  p_TIME_ZONE,
--     				  v_BEGIN_DATE,
--     				  v_END_DATE);
-- 
-- 
--   OPEN p_CURSOR FOR
--   SELECT SCHEDULE_DATE, TRANSACTION_ID, ETAG_ID, TRANSACTION_NAME, TXN_LABEL, MW_AMOUNT
--     FROM (
--   SELECT
--     FROM_CUT_AS_HED(SCHEDULE_DATE, p_TIME_ZONE) SCHEDULE_DATE,
-- 	IT.TRANSACTION_ID,
-- 	IT.TRANSACTION_ID ETAG_ID,
-- 	TRANSACTION_NAME,
-- 	'SCHEDULE MW' "TXN_LABEL",
-- 	1 SORT_ORDER,
-- 	ITS.AMOUNT "MW_AMOUNT"
--   FROM INTERCHANGE_TRANSACTION IT, IT_SCHEDULE ITS
--   WHERE (IT.TRANSACTION_ID = p_TRANSACTION_ID OR p_TRANSACTION_ID = -1)
--     AND EXISTS (SELECT ET.TRANSACTION_ID FROM ETAG_TRANSACTION ET
-- 			      WHERE ET.TRANSACTION_ID = IT.TRANSACTION_ID)
--   	AND ITS.TRANSACTION_ID = IT.TRANSACTION_ID
-- 	AND ITS.SCHEDULE_TYPE = 1
-- 	AND ITS.SCHEDULE_STATE = 1
-- 	AND ITS.SCHEDULE_DATE BETWEEN v_BEGIN_DATE AND v_END_DATE
-- 	AND ITS.AS_OF_DATE = g_LOW_DATE
-- 	AND (IT.TRANSACTION_TYPE = 'Purchase' or IT.TRANSACTION_TYPE = 'Sale')
-- 	AND IT.BEGIN_DATE <= v_END_DATE
-- 	AND IT.END_DATE >= v_BEGIN_DATE
-- UNION ALL
--   SELECT
--     FROM_CUT_AS_HED(SCHEDULE_DATE, p_TIME_ZONE) SCHEDULE_DATE,
-- 	ET.TRANSACTION_ID,
-- 	ET.ETAG_ID,
-- 	ETAG_NAME "TRANSACTION_NAME",
-- 	'TAG MW' "TXN_LABEL",
-- 	2 SORT_ORDER,
-- 	EPV.MW_LEVEL "MW_AMOUNT"
--   FROM ETAG E, ETAG_TRANSACTION ET, ETAG_PROFILE EP, ETAG_PROFILE_VALUE EPV,
--   	   IT_SCHEDULE ITS --SYSTEM_DATE_TIME SDT
--   WHERE E.ETAG_ID = ET.ETAG_ID
--     AND (ET.TRANSACTION_ID = p_TRANSACTION_ID OR p_TRANSACTION_ID = -1)
-- 	AND ET.TRANSACTION_ID <> 0
-- 	AND E.ETAG_ID = EP.ETAG_ID
-- 	AND EP.PARENT_TYPE = 'GEN'
-- 	AND EP.PROFILE_KEY_ID = EPV.PROFILE_KEY_ID
--   	AND ITS.TRANSACTION_ID = ET.TRANSACTION_ID
-- 	AND ITS.SCHEDULE_TYPE = 1
-- 	AND ITS.SCHEDULE_STATE = 1
-- 	AND ITS.SCHEDULE_DATE BETWEEN v_BEGIN_DATE AND v_END_DATE
-- 	AND ITS.AS_OF_DATE = g_LOW_DATE
-- 	AND FROM_CUT(ITS.SCHEDULE_DATE,p_TIME_ZONE) BETWEEN EPV.START_DATE + (1/24) AND EPV.END_DATE
-- -- 	AND SDT.TIME_ZONE = 'PDT'
-- -- 	AND SDT.DATA_INTERVAL_TYPE = 1
-- -- 	AND SDT.DAY_TYPE = '1'
-- -- 	AND SDT.CUT_DATE <= TO_CUT(TRUNC(p_END_DATE) + 1,'PDT')
-- -- 	AND SDT.CUT_DATE >= TO_CUT(TRUNC(p_BEGIN_DATE),'PDT')
-- -- 	AND SDT.CUT_DATE BETWEEN EPV.START_DATE AND EPV.END_DATE
-- UNION ALL
--   SELECT FROM_CUT_AS_HED(SCHEDULE_DATE, p_TIME_ZONE) SCHEDULE_DATE,
--     IT.TRANSACTION_ID,
-- 	1 ETAG_ID,
-- 	'MISMATCH' TRANSACTION_NAME,
-- 	'MW' "TXN_LABEL",
-- 	3 SORT_ORDER,
-- 	MAX(ITS.AMOUNT) - SUM(EPV.MW_LEVEL) "MW_AMOUNT"
--   FROM INTERCHANGE_TRANSACTION IT, ETAG_TRANSACTION ET,
--   	   ETAG_PROFILE EP, ETAG_PROFILE_VALUE EPV, IT_SCHEDULE ITS
--   WHERE (IT.TRANSACTION_ID = p_TRANSACTION_ID OR p_TRANSACTION_ID = -1)
--     AND IT.TRANSACTION_ID = ET.TRANSACTION_ID
-- 	AND ET.ETAG_ID = EP.ETAG_ID
-- 	AND EP.PARENT_TYPE = 'GEN'
-- 	AND EP.PROFILE_KEY_ID = EPV.PROFILE_KEY_ID
--   	AND ITS.TRANSACTION_ID = IT.TRANSACTION_ID
-- 	AND ITS.SCHEDULE_TYPE = 1
-- 	AND ITS.SCHEDULE_STATE = 1
-- 	AND ITS.SCHEDULE_DATE BETWEEN v_BEGIN_DATE AND v_END_DATE
-- 	AND ITS.AS_OF_DATE = g_LOW_DATE
-- 	AND (IT.TRANSACTION_TYPE = 'Purchase' or IT.TRANSACTION_TYPE = 'Sale')
-- 	AND IT.BEGIN_DATE <= v_END_DATE
-- 	AND IT.END_DATE >= v_BEGIN_DATE
-- 	AND FROM_CUT(ITS.SCHEDULE_DATE,p_TIME_ZONE) BETWEEN EPV.START_DATE + (1/24) AND EPV.END_DATE
--   GROUP BY SCHEDULE_DATE, IT.TRANSACTION_ID, TRANSACTION_NAME
--   HAVING MAX(ITS.AMOUNT) - SUM(EPV.MW_LEVEL) <> 0)
--   ORDER BY TRANSACTION_ID, SORT_ORDER, ETAG_ID, SCHEDULE_DATE;
-- 
--   EXCEPTION
-- 	    WHEN OTHERS THEN
-- 		    p_STATUS := SQLCODE;
-- 
--   END ETAG_VOLUMES_REPORT;

-------------------------------------------------------------------------------------
PROCEDURE GET_TRANSACTION_ETAG_RPT_DETL
	(
	p_DETAIL_TYPE IN VARCHAR2,
	p_ETAG_ID IN NUMBER,
	p_STATUS OUT NUMBER,
	p_CURSOR IN OUT REF_CURSOR
	) AS
BEGIN

	IF p_DETAIL_TYPE = 'Profiles' THEN
		EM.ETAG_PROFILES(p_ETAG_ID, p_STATUS, p_CURSOR);
	ELSIF p_DETAIL_TYPE = 'Physical Segments' THEN
		EM.ETAG_PHYSICAL_SEGMENTS(p_ETAG_ID, p_STATUS, p_CURSOR);
	ELSIF p_DETAIL_TYPE = 'Market Segments' THEN
		EM.ETAG_MARKET_SEGMENTS(p_ETAG_ID, p_STATUS, p_CURSOR);
	ELSE
		OPEN p_CURSOR FOR
			SELECT NULL FROM DUAL WHERE 1 = 0;
	END IF;	
		
END GET_TRANSACTION_ETAG_RPT_DETL;
-------------------------------------------------------------------------------------
PROCEDURE GET_SINK_FILTER_LIST
	(
	p_STATUS OUT NUMBER,
	p_CURSOR IN OUT REF_CURSOR
	) AS
BEGIN
	
	OPEN p_CURSOR FOR
		SELECT g_ALL_CHAR FROM DUAL
		UNION ALL
		SELECT DISTINCT GCA_CODE FROM ETAG ORDER BY 1;
		
END GET_SINK_FILTER_LIST;
-------------------------------------------------------------------------------------
PROCEDURE GET_ETAG_STATUS_FILTER_LIST
	(
	p_STATUS OUT NUMBER,
	p_CURSOR IN OUT REF_CURSOR
	) AS
BEGIN
	
	OPEN p_CURSOR FOR
		SELECT g_ALL_CHAR FROM DUAL
		UNION ALL
		SELECT DISTINCT ETAG_STATUS FROM ETAG ORDER BY 1;
		
END GET_ETAG_STATUS_FILTER_LIST;
-------------------------------------------------------------------------------------
END MM_ETAG;
/

