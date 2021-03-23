INSERT INTO HOLIDAY_SET(HOLIDAY_SET_ID, HOLIDAY_SET_NAME, HOLIDAY_SET_ALIAS, HOLIDAY_SET_DESC, ENTRY_DATE)
VALUES(101, 'BGE Holiday Set', '?', '?', TO_DATE('12/14/2020 14:17:21', 'MM/DD/YYYY HH24:MI:SS'));
INSERT INTO HOLIDAY(HOLIDAY_ID, HOLIDAY_NAME, HOLIDAY_ALIAS, HOLIDAY_DESC, ENTRY_DATE)
VALUES(101, 'New Years Day', '?', '?', SYSDATE);
INSERT INTO HOLIDAY(HOLIDAY_ID, HOLIDAY_NAME, HOLIDAY_ALIAS, HOLIDAY_DESC, ENTRY_DATE)
VALUES(102, 'Presidents Day', '?', '?', SYSDATE);
INSERT INTO HOLIDAY(HOLIDAY_ID, HOLIDAY_NAME, HOLIDAY_ALIAS, HOLIDAY_DESC, ENTRY_DATE)
VALUES(103, 'Good Friday', '?', '?', SYSDATE);
INSERT INTO HOLIDAY(HOLIDAY_ID, HOLIDAY_NAME, HOLIDAY_ALIAS, HOLIDAY_DESC, ENTRY_DATE)
VALUES(104, 'Memorial Day', '?', '?', SYSDATE);
INSERT INTO HOLIDAY(HOLIDAY_ID, HOLIDAY_NAME, HOLIDAY_ALIAS, HOLIDAY_DESC, ENTRY_DATE)
VALUES(105, 'Independence Day', '?', '?', SYSDATE);
INSERT INTO HOLIDAY(HOLIDAY_ID, HOLIDAY_NAME, HOLIDAY_ALIAS, HOLIDAY_DESC, ENTRY_DATE)
VALUES(106, 'Labor Day', '?', '?', SYSDATE);
INSERT INTO HOLIDAY(HOLIDAY_ID, HOLIDAY_NAME, HOLIDAY_ALIAS, HOLIDAY_DESC, ENTRY_DATE)
VALUES(107, 'Thanksgiving', '?', '?', SYSDATE);
INSERT INTO HOLIDAY(HOLIDAY_ID, HOLIDAY_NAME, HOLIDAY_ALIAS, HOLIDAY_DESC, ENTRY_DATE)
VALUES(108, 'Christmas', '?', '?', SYSDATE);
INSERT INTO HOLIDAY_OBSERVANCE(HOLIDAY_ID, HOLIDAY_YEAR, HOLIDAY_DATE, ENTRY_DATE)
SELECT HOLIDAY_ID, '2019' "HOLIDAY_YEAR", TO_DATE('01/01/2019','MM/DD/YYYY') "HOLIDAY_DATE", SYSDATE "ENTRY_DATE" FROM HOLIDAY WHERE HOLIDAY_NAME = 'New Years Day'    UNION
SELECT HOLIDAY_ID, '2019' "HOLIDAY_YEAR", TO_DATE('05/27/2019','MM/DD/YYYY') "HOLIDAY_DATE", SYSDATE "ENTRY_DATE" FROM HOLIDAY WHERE HOLIDAY_NAME = 'Memorial Day'     UNION
SELECT HOLIDAY_ID, '2019' "HOLIDAY_YEAR", TO_DATE('07/04/2019','MM/DD/YYYY') "HOLIDAY_DATE", SYSDATE "ENTRY_DATE" FROM HOLIDAY WHERE HOLIDAY_NAME = 'Independence Day' UNION
SELECT HOLIDAY_ID, '2019' "HOLIDAY_YEAR", TO_DATE('09/02/2019','MM/DD/YYYY') "HOLIDAY_DATE", SYSDATE "ENTRY_DATE" FROM HOLIDAY WHERE HOLIDAY_NAME = 'Labor Day'        UNION
SELECT HOLIDAY_ID, '2019' "HOLIDAY_YEAR", TO_DATE('11/28/2019','MM/DD/YYYY') "HOLIDAY_DATE", SYSDATE "ENTRY_DATE" FROM HOLIDAY WHERE HOLIDAY_NAME = 'Thanksgiving'     UNION
SELECT HOLIDAY_ID, '2019' "HOLIDAY_YEAR", TO_DATE('12/25/2019','MM/DD/YYYY') "HOLIDAY_DATE", SYSDATE "ENTRY_DATE" FROM HOLIDAY WHERE HOLIDAY_NAME = 'Christmas'        UNION
SELECT HOLIDAY_ID, '2020' "HOLIDAY_YEAR", TO_DATE('01/01/2020','MM/DD/YYYY') "HOLIDAY_DATE", SYSDATE "ENTRY_DATE" FROM HOLIDAY WHERE HOLIDAY_NAME = 'New Years Day'    UNION
SELECT HOLIDAY_ID, '2020' "HOLIDAY_YEAR", TO_DATE('05/25/2020','MM/DD/YYYY') "HOLIDAY_DATE", SYSDATE "ENTRY_DATE" FROM HOLIDAY WHERE HOLIDAY_NAME = 'Memorial Day'     UNION
SELECT HOLIDAY_ID, '2020' "HOLIDAY_YEAR", TO_DATE('07/03/2020','MM/DD/YYYY') "HOLIDAY_DATE", SYSDATE "ENTRY_DATE" FROM HOLIDAY WHERE HOLIDAY_NAME = 'Independence Day' UNION
SELECT HOLIDAY_ID, '2020' "HOLIDAY_YEAR", TO_DATE('09/07/2020','MM/DD/YYYY') "HOLIDAY_DATE", SYSDATE "ENTRY_DATE" FROM HOLIDAY WHERE HOLIDAY_NAME = 'Labor Day'        UNION
SELECT HOLIDAY_ID, '2020' "HOLIDAY_YEAR", TO_DATE('11/26/2020','MM/DD/YYYY') "HOLIDAY_DATE", SYSDATE "ENTRY_DATE" FROM HOLIDAY WHERE HOLIDAY_NAME = 'Thanksgiving'     UNION
SELECT HOLIDAY_ID, '2020' "HOLIDAY_YEAR", TO_DATE('12/25/2020','MM/DD/YYYY') "HOLIDAY_DATE", SYSDATE "ENTRY_DATE" FROM HOLIDAY WHERE HOLIDAY_NAME = 'Christmas'        UNION
SELECT HOLIDAY_ID, '2021' "HOLIDAY_YEAR", TO_DATE('01/01/2021','MM/DD/YYYY') "HOLIDAY_DATE", SYSDATE "ENTRY_DATE" FROM HOLIDAY WHERE HOLIDAY_NAME = 'New Years Day'    UNION
SELECT HOLIDAY_ID, '2021' "HOLIDAY_YEAR", TO_DATE('05/31/2021','MM/DD/YYYY') "HOLIDAY_DATE", SYSDATE "ENTRY_DATE" FROM HOLIDAY WHERE HOLIDAY_NAME = 'Memorial Day'     UNION
SELECT HOLIDAY_ID, '2021' "HOLIDAY_YEAR", TO_DATE('07/05/2021','MM/DD/YYYY') "HOLIDAY_DATE", SYSDATE "ENTRY_DATE" FROM HOLIDAY WHERE HOLIDAY_NAME = 'Independence Day' UNION
SELECT HOLIDAY_ID, '2021' "HOLIDAY_YEAR", TO_DATE('09/06/2021','MM/DD/YYYY') "HOLIDAY_DATE", SYSDATE "ENTRY_DATE" FROM HOLIDAY WHERE HOLIDAY_NAME = 'Labor Day'        UNION
SELECT HOLIDAY_ID, '2021' "HOLIDAY_YEAR", TO_DATE('11/25/2021','MM/DD/YYYY') "HOLIDAY_DATE", SYSDATE "ENTRY_DATE" FROM HOLIDAY WHERE HOLIDAY_NAME = 'Thanksgiving'     UNION
SELECT HOLIDAY_ID, '2021' "HOLIDAY_YEAR", TO_DATE('12/24/2021','MM/DD/YYYY') "HOLIDAY_DATE", SYSDATE "ENTRY_DATE" FROM HOLIDAY WHERE HOLIDAY_NAME = 'Christmas'        UNION
SELECT HOLIDAY_ID, '2022' "HOLIDAY_YEAR", TO_DATE('12/31/2021','MM/DD/YYYY') "HOLIDAY_DATE", SYSDATE "ENTRY_DATE" FROM HOLIDAY WHERE HOLIDAY_NAME = 'New Years Day'    UNION
SELECT HOLIDAY_ID, '2022' "HOLIDAY_YEAR", TO_DATE('05/30/2022','MM/DD/YYYY') "HOLIDAY_DATE", SYSDATE "ENTRY_DATE" FROM HOLIDAY WHERE HOLIDAY_NAME = 'Memorial Day'     UNION
SELECT HOLIDAY_ID, '2022' "HOLIDAY_YEAR", TO_DATE('07/04/2022','MM/DD/YYYY') "HOLIDAY_DATE", SYSDATE "ENTRY_DATE" FROM HOLIDAY WHERE HOLIDAY_NAME = 'Independence Day' UNION
SELECT HOLIDAY_ID, '2022' "HOLIDAY_YEAR", TO_DATE('09/05/2022','MM/DD/YYYY') "HOLIDAY_DATE", SYSDATE "ENTRY_DATE" FROM HOLIDAY WHERE HOLIDAY_NAME = 'Labor Day'        UNION
SELECT HOLIDAY_ID, '2022' "HOLIDAY_YEAR", TO_DATE('11/24/2022','MM/DD/YYYY') "HOLIDAY_DATE", SYSDATE "ENTRY_DATE" FROM HOLIDAY WHERE HOLIDAY_NAME = 'Thanksgiving'     UNION
SELECT HOLIDAY_ID, '2022' "HOLIDAY_YEAR", TO_DATE('12/26/2022','MM/DD/YYYY') "HOLIDAY_DATE", SYSDATE "ENTRY_DATE" FROM HOLIDAY WHERE HOLIDAY_NAME = 'Christmas';
INSERT INTO HOLIDAY_SCHEDULE(HOLIDAY_SET_ID, HOLIDAY_ID, ENTRY_DATE)
SELECT 101, 101, SYSDATE FROM DUAL UNION
SELECT 101, 102, SYSDATE FROM DUAL UNION
SELECT 101, 103, SYSDATE FROM DUAL UNION
SELECT 101, 104, SYSDATE FROM DUAL UNION
SELECT 101, 105, SYSDATE FROM DUAL UNION
SELECT 101, 106, SYSDATE FROM DUAL UNION
SELECT 101, 107, SYSDATE FROM DUAL UNION
SELECT 101, 108, SYSDATE FROM DUAL;
UPDATE ENERGY_DISTRIBUTION_COMPANY SET EDC_HOLIDAY_SET_ID = 101, EDC_MARKET_PRICE_ID = 101 WHERE EDC_ID = 101;
COMMIT;

