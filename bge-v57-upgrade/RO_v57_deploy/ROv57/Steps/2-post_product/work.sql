SELECT * FROM ENERGY_DISTRIBUTION_COMPANY

SELECT * FROM SERVICE_LOCATION WHERE SERVICE_LOCATION_ID = 113

SELECT * FROM INCUMBENT_ENTITY 

SELECT * FROM HOLIDAY order by 1

SELECT * FROM HOLIDAY_SET

select * from HOLIDAY_OBSERVANCE

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
COMMIT;
