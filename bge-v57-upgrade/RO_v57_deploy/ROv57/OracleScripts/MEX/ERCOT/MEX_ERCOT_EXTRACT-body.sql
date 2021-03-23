CREATE OR REPLACE PACKAGE BODY MEX_ERCOT_EXTRACT IS
----------------------------------------------------------------------------------------------------
FUNCTION WHAT_VERSION RETURN VARCHAR2 IS
BEGIN
    RETURN '$Revision: 1.1 $';
END WHAT_VERSION;
---------------------------------------------------------------------------------------------------
PROCEDURE PARSE_ESIID
	(
    p_RESPONSE_CLOB IN CLOB,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
    ) IS
v_LINES PARSE_UTIL.BIG_STRING_TABLE_MP;
v_COLS PARSE_UTIL.STRING_TABLE;
v_IDX BINARY_INTEGER;
v_ESIID ESIID%ROWTYPE;
BEGIN
	p_STATUS := MEX_UTIL.g_SUCCESS;
	PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_RESPONSE_CLOB, v_LINES);
	v_IDX := v_LINES.FIRST;

	WHILE v_LINES.EXISTS(v_IDX) LOOP
        PARSE_UTIL.PARSE_DELIMITED_STRING(v_LINES(v_IDX),',',v_COLS);
        v_ESIID.Uidesiid := v_COLS(1);
        v_ESIID.Esiid := v_COLS(2);
        v_ESIID.Starttime := TO_DATE(v_COLS(3), 'mm/dd/yyyy hh24:mi:ss');
        v_ESIID.Stoptime := TO_DATE(v_COLS(4), 'mm/dd/yyyy hh24:mi:ss');
        v_ESIID.Addtime := TO_DATE(v_COLS(5), 'mm/dd/yyyy hh24:mi:ss');
        BEGIN
            INSERT INTO ESIID VALUES v_ESIID;
        EXCEPTION
 	        WHEN DUP_VAL_ON_INDEX THEN
            UPDATE ESIID
            SET ESIID = v_ESIID.ESIID,
                STARTTIME = v_ESIID.STARTTIME,
                STOPTIME = v_ESIID.STOPTIME,
                ADDTIME = v_ESIID.ADDTIME
            WHERE UIDESIID = v_ESIID.UIDESIID;
        END;
    	v_IDX := v_LINES.NEXT(v_IDX);
	END LOOP;

    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
      p_STATUS := SQLCODE;
      p_MESSAGE := 'Error in MEX_ERCOT_SETTLEMENT.PARSE_ESIID: ' || SQLERRM;
END PARSE_ESIID;
----------------------------------------------------------------------------------------------------
PROCEDURE PARSE_ESIID_SERV_HIST
	(
    p_RESPONSE_CLOB IN CLOB,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
    ) IS
v_LINES PARSE_UTIL.BIG_STRING_TABLE_MP;
v_COLS PARSE_UTIL.STRING_TABLE;
v_IDX BINARY_INTEGER;
v_ESIID_SERV_HIST ESIIDSERVICEHIST%ROWTYPE;
BEGIN
	p_STATUS := MEX_UTIL.g_SUCCESS;
	PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_RESPONSE_CLOB, v_LINES);
	v_IDX := v_LINES.FIRST;

	WHILE v_LINES.EXISTS(v_IDX) LOOP
        PARSE_UTIL.PARSE_DELIMITED_STRING(v_LINES(v_IDX),',',v_COLS);
        v_ESIID_SERV_HIST.Uidesiid := v_COLS(1);
        v_ESIID_SERV_HIST.Servicecode := v_COLS(2);
        v_ESIID_SERV_HIST.Starttime := TO_DATE(v_COLS(3), 'mm/dd/yyyy hh24:mi:ss');
        v_ESIID_SERV_HIST.Stoptime := TO_DATE(v_COLS(4), 'mm/dd/yyyy hh24:mi:ss');
        v_ESIID_SERV_HIST.Repcode := v_COLS(5);
        v_ESIID_SERV_HIST.Stationcode := v_COLS(6);
        v_ESIID_SERV_HIST.Profilecode := v_COLS(7);
        v_ESIID_SERV_HIST.Losscode := v_COLS(8);
        v_ESIID_SERV_HIST.Addtime := TO_DATE(v_COLS(9), 'mm/dd/yyyy hh24:mi:ss');
        v_ESIID_SERV_HIST.Dispatchfl := v_COLS(10);
        v_ESIID_SERV_HIST.Mrecode := v_COLS(11);
        v_ESIID_SERV_HIST.Tdspcode := v_COLS(12);
        v_ESIID_SERV_HIST.Regioncode := v_COLS(13);
        v_ESIID_SERV_HIST.Dispatchassetcode := v_COLS(14);
        v_ESIID_SERV_HIST.Status := v_COLS(15);
        v_ESIID_SERV_HIST.Zip := v_COLS(16);
        v_ESIID_SERV_HIST.Pgccode := v_COLS(17);
        v_ESIID_SERV_HIST.Dispatchtype := v_COLS(18);

        BEGIN
            INSERT INTO ESIIDSERVICEHIST VALUES v_ESIID_SERV_HIST;
        EXCEPTION
 	        WHEN DUP_VAL_ON_INDEX THEN
            UPDATE ESIIDSERVICEHIST
            SET STOPTIME = v_ESIID_SERV_HIST.Stoptime,
                REPCODE = v_ESIID_SERV_HIST.Repcode,
                STATIONCODE = v_ESIID_SERV_HIST.Stationcode,
                PROFILECODE = v_ESIID_SERV_HIST.Profilecode,
                LOSSCODE = v_ESIID_SERV_HIST.Losscode,
                ADDTIME = v_ESIID_SERV_HIST.ADDTIME,
                DISPATCHFL = v_ESIID_SERV_HIST.Dispatchfl,
                MRECODE = v_ESIID_SERV_HIST.Mrecode,
                TDSPCODE = v_ESIID_SERV_HIST.Tdspcode,
                REGIONCODE = v_ESIID_SERV_HIST.Regioncode,
                DISPATCHASSETCODE = v_ESIID_SERV_HIST.Dispatchassetcode,
                STATUS = v_ESIID_SERV_HIST.Status,
                ZIP = v_ESIID_SERV_HIST.Zip,
                PGCCODE = v_ESIID_SERV_HIST.Pgccode,
                DISPATCHTYPE = v_ESIID_SERV_HIST.Dispatchtype
            WHERE UIDESIID = v_ESIID_SERV_HIST.UIDESIID
            AND SERVICECODE = v_ESIID_SERV_HIST.Servicecode
            AND STARTTIME = v_ESIID_SERV_HIST.Starttime;
        END;
    	v_IDX := v_LINES.NEXT(v_IDX);
	END LOOP;

    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
      p_STATUS := SQLCODE;
      p_MESSAGE := 'Error in MEX_ERCOT_SETTLEMENT.PARSE_ESIID_SERV_HIST: ' || SQLERRM;
END PARSE_ESIID_SERV_HIST;
----------------------------------------------------------------------------------------------------
PROCEDURE PARSE_ESIID_SERV_HIST_DEL
	(
    p_RESPONSE_CLOB IN CLOB,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
    ) IS
v_LINES PARSE_UTIL.BIG_STRING_TABLE_MP;
v_COLS PARSE_UTIL.STRING_TABLE;
v_IDX BINARY_INTEGER;
v_ESIID_DEL ESIIDSERVICEHIST_DELETE%ROWTYPE;
BEGIN
	p_STATUS := MEX_UTIL.g_SUCCESS;
	PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_RESPONSE_CLOB, v_LINES);
	v_IDX := v_LINES.FIRST;

	WHILE v_LINES.EXISTS(v_IDX) LOOP
        PARSE_UTIL.PARSE_DELIMITED_STRING(v_LINES(v_IDX),',',v_COLS);
        v_ESIID_DEL.Uidesiid := v_COLS(1);
        v_ESIID_DEL.Servicecode := v_COLS(2);
        v_ESIID_DEL.Starttime := TO_DATE(v_COLS(3), 'mm/dd/yyyy hh24:mi:ss');
        v_ESIID_DEL.d_Timestamp := TO_DATE(v_COLS(4), 'mm/dd/yyyy hh24:mi:ss');
        v_ESIID_DEL.Src_Addtime := TO_DATE(v_COLS(5), 'mm/dd/yyyy hh24:mi:ss');
        BEGIN
            INSERT INTO ESIIDSERVICEHIST_DELETE VALUES v_ESIID_DEL;
        EXCEPTION
 	        WHEN DUP_VAL_ON_INDEX THEN
            UPDATE ESIIDSERVICEHIST_DELETE
            SET D_TIMESTAMP = v_ESIID_DEL.d_Timestamp
            WHERE UIDESIID = v_ESIID_DEL.UIDESIID
            AND SERVICECODE = v_ESIID_DEL.Servicecode
            AND STARTTIME = v_ESIID_DEL.Starttime
            AND SRC_ADDTIME = v_ESIID_DEL.Src_Addtime;
        END;
    	v_IDX := v_LINES.NEXT(v_IDX);
	END LOOP;

    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
      p_STATUS := SQLCODE;
      p_MESSAGE := 'Error in MEX_ERCOT_SETTLEMENT.PARSE_ESIID_SERV_HIST_DEL: ' || SQLERRM;
END PARSE_ESIID_SERV_HIST_DEL;
----------------------------------------------------------------------------------------------------
PROCEDURE PARSE_ESIID_USAGE
	(
    p_RESPONSE_CLOB IN CLOB,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
    ) IS
v_LINES PARSE_UTIL.BIG_STRING_TABLE_MP;
v_COLS PARSE_UTIL.STRING_TABLE;
v_IDX BINARY_INTEGER;
v_ESIID_USAGE ESIIDUSAGE%ROWTYPE;
BEGIN
	p_STATUS := MEX_UTIL.g_SUCCESS;
	PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_RESPONSE_CLOB, v_LINES);
	v_IDX := v_LINES.FIRST;

	WHILE v_LINES.EXISTS(v_IDX) LOOP
        PARSE_UTIL.PARSE_DELIMITED_STRING(v_LINES(v_IDX),',',v_COLS);
        v_ESIID_USAGE.Uidesiid := v_COLS(1);
        v_ESIID_USAGE.Starttime := TO_DATE(v_COLS(2), 'mm/dd/yyyy hh24:mi:ss');
        v_ESIID_USAGE.Stoptime := TO_DATE(v_COLS(3), 'mm/dd/yyyy hh24:mi:ss');
        v_ESIID_USAGE.Billmonth := v_COLS(4);
        v_ESIID_USAGE.Metertype := v_COLS(5);
        v_ESIID_USAGE.Total := v_COLS(6);
        v_ESIID_USAGE.Readstatus := v_COLS(7);
        v_ESIID_USAGE.Avgdailyusg := v_COLS(8);
        v_ESIID_USAGE.Onpk := v_COLS(9);
        v_ESIID_USAGE.Offpk := v_COLS(10);
        v_ESIID_USAGE.Mdpk := v_COLS(11);
        v_ESIID_USAGE.Spk := v_COLS(12);
        v_ESIID_USAGE.Onpkadu := v_COLS(13);
        v_ESIID_USAGE.Offpkadu := v_COLS(14);
        v_ESIID_USAGE.Mdpkadu := v_COLS(15);
        v_ESIID_USAGE.Spkadu := v_COLS(16);
        v_ESIID_USAGE.Addtime := TO_DATE(v_COLS(17), 'mm/dd/yyyy hh24:mi:ss');
        v_ESIID_USAGE.Globprocid := v_COLS(18);
        v_ESIID_USAGE.Timestamp := TO_DATE(v_COLS(19), 'mm/dd/yyyy hh24:mi:ss');

        BEGIN
            INSERT INTO ESIIDUSAGE VALUES v_ESIID_USAGE;
        EXCEPTION
 	        WHEN DUP_VAL_ON_INDEX THEN
            UPDATE ESIIDUSAGE
            SET STOPTIME = v_ESIID_USAGE.Stoptime,
                BILLMONTH = v_ESIID_USAGE.Billmonth,
                TOTAL = v_ESIID_USAGE.Total,
                READSTATUS = v_ESIID_USAGE.Readstatus,
                AVGDAILYUSG = v_ESIID_USAGE.Avgdailyusg,
                ONPK = v_ESIID_USAGE.Onpk,
                OFFPK = v_ESIID_USAGE.Offpk,
                MDPK = v_ESIID_USAGE.Mdpk,
                SPK = v_ESIID_USAGE.Spk,
                ONPKADU = v_ESIID_USAGE.Onpkadu,
                OFFPKADU = v_ESIID_USAGE.Offpkadu,
                MDPKADU = v_ESIID_USAGE.Mdpkadu,
                SPKADU = v_ESIID_USAGE.Spkadu,
                ADDTIME = v_ESIID_USAGE.Addtime,
                GLOBPROCID = v_ESIID_USAGE.Globprocid,
                TIMESTAMP = v_ESIID_USAGE.Timestamp
            WHERE UIDESIID = v_ESIID_USAGE.UIDESIID
            AND STARTTIME = v_ESIID_USAGE.Starttime
            AND METERTYPE = v_ESIID_USAGE.Metertype;
        END;
    	v_IDX := v_LINES.NEXT(v_IDX);
	END LOOP;

    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
      p_STATUS := SQLCODE;
      p_MESSAGE := 'Error in MEX_ERCOT_SETTLEMENT.PARSE_ESIID_USAGE: ' || SQLERRM;
END PARSE_ESIID_USAGE;
----------------------------------------------------------------------------------------------------
PROCEDURE PARSE_ESIID_USAGE_DEL
	(
    p_RESPONSE_CLOB IN CLOB,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
    ) IS
v_LINES PARSE_UTIL.BIG_STRING_TABLE_MP;
v_COLS PARSE_UTIL.STRING_TABLE;
v_IDX BINARY_INTEGER;
v_ESIID_U_DEL ESIIDUSAGE_DELETE%ROWTYPE;
BEGIN
	p_STATUS := MEX_UTIL.g_SUCCESS;
	PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_RESPONSE_CLOB, v_LINES);
	v_IDX := v_LINES.FIRST;

	WHILE v_LINES.EXISTS(v_IDX) LOOP
        PARSE_UTIL.PARSE_DELIMITED_STRING(v_LINES(v_IDX),',',v_COLS);
        v_ESIID_U_DEL.Uidesiid := v_COLS(1);
        v_ESIID_U_DEL.Starttime := TO_DATE(v_COLS(2), 'mm/dd/yyyy hh24:mi:ss');
        v_ESIID_U_DEL.Metertype := v_COLS(3);
        v_ESIID_U_DEL.d_Timestamp := TO_DATE(v_COLS(4), 'mm/dd/yyyy hh24:mi:ss');
        v_ESIID_U_DEL.Src_Timestamp := TO_DATE(v_COLS(5), 'mm/dd/yyyy hh24:mi:ss');
        BEGIN
            INSERT INTO ESIIDUSAGE_DELETE VALUES v_ESIID_U_DEL;
        EXCEPTION
 	        WHEN DUP_VAL_ON_INDEX THEN
            UPDATE ESIIDUSAGE_DELETE
            SET D_TIMESTAMP = v_ESIID_U_DEL.d_Timestamp
            WHERE UIDESIID = v_ESIID_U_DEL.UIDESIID
            AND STARTTIME = v_ESIID_U_DEL.Starttime
            AND METERTYPE = v_ESIID_U_DEL.Metertype
            AND SRC_TIMESTAMP = v_ESIID_U_DEL.Src_Timestamp;
        END;
    	v_IDX := v_LINES.NEXT(v_IDX);
	END LOOP;

    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
      p_STATUS := SQLCODE;
      p_MESSAGE := 'Error in MEX_ERCOT_SETTLEMENT.PARSE_ESIID_USAGE_DEL: ' || SQLERRM;
END PARSE_ESIID_USAGE_DEL;
----------------------------------------------------------------------------------------------------
PROCEDURE PARSE_ESIID_COUNTS
	(
    p_RESPONSE_CLOB IN CLOB,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
    ) IS
v_LINES PARSE_UTIL.BIG_STRING_TABLE_MP;
v_COLS PARSE_UTIL.STRING_TABLE;
v_IDX BINARY_INTEGER;
v_ESIID_COUNTS EXTRACT_TABLE_COUNTS%ROWTYPE;
BEGIN
	p_STATUS := MEX_UTIL.g_SUCCESS;
	PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_RESPONSE_CLOB, v_LINES);
	v_IDX := v_LINES.FIRST;

	WHILE v_LINES.EXISTS(v_IDX) LOOP
        PARSE_UTIL.PARSE_DELIMITED_STRING(v_LINES(v_IDX),',',v_COLS);
        v_ESIID_COUNTS.Record_Count := v_COLS(1);
        v_ESIID_COUNTS.Table_Name := v_COLS(2);
        BEGIN
            INSERT INTO EXTRACT_TABLE_COUNTS VALUES v_ESIID_COUNTS;
        EXCEPTION
 	        WHEN DUP_VAL_ON_INDEX THEN
            UPDATE EXTRACT_TABLE_COUNTS
            SET RECORD_COUNT = v_ESIID_COUNTS.Record_Count
            WHERE TABLE_NAME = v_ESIID_COUNTS.Table_Name;
        END;
    	v_IDX := v_LINES.NEXT(v_IDX);
	END LOOP;

    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
      p_STATUS := SQLCODE;
      p_MESSAGE := 'Error in MEX_ERCOT_SETTLEMENT.PARSE_ESIID_COUNTS: ' || SQLERRM;
END PARSE_ESIID_COUNTS;
----------------------------------------------------------------------------------------------------
PROCEDURE PARSE_ESIID_MRE
	(
    p_RESPONSE_CLOB IN CLOB,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
    ) IS
v_LINES PARSE_UTIL.BIG_STRING_TABLE_MP;
v_COLS PARSE_UTIL.STRING_TABLE;
v_IDX BINARY_INTEGER;
v_ESIID_MRE MRE%ROWTYPE;
BEGIN
	p_STATUS := MEX_UTIL.g_SUCCESS;
	PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_RESPONSE_CLOB, v_LINES);
	v_IDX := v_LINES.FIRST;

	WHILE v_LINES.EXISTS(v_IDX) LOOP
        PARSE_UTIL.PARSE_DELIMITED_STRING(v_LINES(v_IDX),',',v_COLS);
        v_ESIID_MRE.Mrecode := v_COLS(1);
        v_ESIID_MRE.Mrename := v_COLS(2);
        v_ESIID_MRE.Starttiime := TO_DATE(v_COLS(3), 'mm/dd/yyyy hh24:mi:ss');
        v_ESIID_MRE.Stoptime := TO_DATE(v_COLS(4), 'mm/dd/yyyy hh24:mi:ss');
        v_ESIID_MRE.Addtime := TO_DATE(v_COLS(5), 'mm/dd/yyyy hh24:mi:ss');
        v_ESIID_MRE.Dunsnumber := v_COLS(6);
        BEGIN
            INSERT INTO MRE VALUES v_ESIID_MRE;
        EXCEPTION
 	        WHEN DUP_VAL_ON_INDEX THEN
            UPDATE MRE
            SET MRENAME = v_ESIID_MRE.Mrename,
                STARTTIIME = v_ESIID_MRE.Starttiime,
                STOPTIME = v_ESIID_MRE.Stoptime,
                ADDTIME = v_ESIID_MRE.Addtime,
                DUNSNUMBER = v_ESIID_MRE.Dunsnumber
            WHERE MRECODE = v_ESIID_MRE.Mrecode;
        END;
    	v_IDX := v_LINES.NEXT(v_IDX);
	END LOOP;

    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
      p_STATUS := SQLCODE;
      p_MESSAGE := 'Error in MEX_ERCOT_SETTLEMENT.PARSE_ESIID_MRE: ' || SQLERRM;
END PARSE_ESIID_MRE;
----------------------------------------------------------------------------------------------------
PROCEDURE PARSE_ESIID_PGC
	(
    p_RESPONSE_CLOB IN CLOB,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
    ) IS
v_LINES PARSE_UTIL.BIG_STRING_TABLE_MP;
v_COLS PARSE_UTIL.STRING_TABLE;
v_IDX BINARY_INTEGER;
v_ESIID_PGC PGC%ROWTYPE;
BEGIN
	p_STATUS := MEX_UTIL.g_SUCCESS;
	PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_RESPONSE_CLOB, v_LINES);
	v_IDX := v_LINES.FIRST;

	WHILE v_LINES.EXISTS(v_IDX) LOOP
        PARSE_UTIL.PARSE_DELIMITED_STRING(v_LINES(v_IDX),',',v_COLS);
        v_ESIID_PGC.Pgccode := v_COLS(1);
        v_ESIID_PGC.Pgcname := v_COLS(2);
        v_ESIID_PGC.Starttime := TO_DATE(v_COLS(3), 'mm/dd/yyyy hh24:mi:ss');
        v_ESIID_PGC.Stoptime := TO_DATE(v_COLS(4), 'mm/dd/yyyy hh24:mi:ss');
        v_ESIID_PGC.Addtime := TO_DATE(v_COLS(5), 'mm/dd/yyyy hh24:mi:ss');
        v_ESIID_PGC.Dunsnumber := v_COLS(6);
        BEGIN
            INSERT INTO PGC VALUES v_ESIID_PGC;
        EXCEPTION
 	        WHEN DUP_VAL_ON_INDEX THEN
            UPDATE PGC
            SET PGCNAME = v_ESIID_PGC.Pgcname,
                STARTTIME = v_ESIID_PGC.Starttime,
                STOPTIME = v_ESIID_PGC.Stoptime,
                ADDTIME = v_ESIID_PGC.Addtime,
                DUNSNUMBER = v_ESIID_PGC.Dunsnumber
            WHERE PGCCODE = v_ESIID_PGC.Pgccode;
        END;
    	v_IDX := v_LINES.NEXT(v_IDX);
	END LOOP;

    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
      p_STATUS := SQLCODE;
      p_MESSAGE := 'Error in MEX_ERCOT_SETTLEMENT.PARSE_ESIID_PGC: ' || SQLERRM;
END PARSE_ESIID_PGC;
----------------------------------------------------------------------------------------------------
PROCEDURE PARSE_ESIID_REP
	(
    p_RESPONSE_CLOB IN CLOB,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
    ) IS
v_LINES PARSE_UTIL.BIG_STRING_TABLE_MP;
v_COLS PARSE_UTIL.STRING_TABLE;
v_IDX BINARY_INTEGER;
v_ESIID_REP REP%ROWTYPE;
BEGIN
	p_STATUS := MEX_UTIL.g_SUCCESS;
	PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_RESPONSE_CLOB, v_LINES);
	v_IDX := v_LINES.FIRST;

	WHILE v_LINES.EXISTS(v_IDX) LOOP
        PARSE_UTIL.PARSE_DELIMITED_STRING(v_LINES(v_IDX),',',v_COLS);
        v_ESIID_REP.Repcode := v_COLS(1);
        v_ESIID_REP.Repname := v_COLS(2);
        v_ESIID_REP.Starttime := TO_DATE(v_COLS(3), 'mm/dd/yyyy hh24:mi:ss');
        v_ESIID_REP.Stoptime := TO_DATE(v_COLS(4), 'mm/dd/yyyy hh24:mi:ss');
        v_ESIID_REP.Addtime := TO_DATE(v_COLS(5), 'mm/dd/yyyy hh24:mi:ss');
        v_ESIID_REP.Dunsnumber := v_COLS(6);
        BEGIN
            INSERT INTO REP VALUES v_ESIID_REP;
        EXCEPTION
 	        WHEN DUP_VAL_ON_INDEX THEN
            UPDATE REP
            SET REPNAME = v_ESIID_REP.Repname,
                STARTTIME = v_ESIID_REP.Starttime,
                STOPTIME = v_ESIID_REP.Stoptime,
                ADDTIME = v_ESIID_REP.Addtime,
                DUNSNUMBER = v_ESIID_REP.Dunsnumber
            WHERE REPCODE = v_ESIID_REP.Repcode;
        END;
    	v_IDX := v_LINES.NEXT(v_IDX);
	END LOOP;

    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
      p_STATUS := SQLCODE;
      p_MESSAGE := 'Error in MEX_ERCOT_SETTLEMENT.PARSE_ESIID_REP: ' || SQLERRM;
END PARSE_ESIID_REP;
----------------------------------------------------------------------------------------------------
PROCEDURE PARSE_ESIID_STATION
	(
    p_RESPONSE_CLOB IN CLOB,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
    ) IS
v_LINES PARSE_UTIL.BIG_STRING_TABLE_MP;
v_COLS PARSE_UTIL.STRING_TABLE;
v_IDX BINARY_INTEGER;
v_ESIID_STATION STATION%ROWTYPE;
BEGIN
	p_STATUS := MEX_UTIL.g_SUCCESS;
	PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_RESPONSE_CLOB, v_LINES);
	v_IDX := v_LINES.FIRST;

	WHILE v_LINES.EXISTS(v_IDX) LOOP
        PARSE_UTIL.PARSE_DELIMITED_STRING(v_LINES(v_IDX),',',v_COLS);
        v_ESIID_STATION.Stationcode := v_COLS(1);
        v_ESIID_STATION.Stationname:= v_COLS(2);
        v_ESIID_STATION.Starttime := TO_DATE(v_COLS(3), 'mm/dd/yyyy hh24:mi:ss');
        v_ESIID_STATION.Stoptime := TO_DATE(v_COLS(4), 'mm/dd/yyyy hh24:mi:ss');
        v_ESIID_STATION.Addtime := TO_DATE(v_COLS(5), 'mm/dd/yyyy hh24:mi:ss');
        BEGIN
            INSERT INTO STATION VALUES v_ESIID_STATION;
        EXCEPTION
 	        WHEN DUP_VAL_ON_INDEX THEN
            UPDATE STATION
            SET STATIONNAME = v_ESIID_STATION.Stationname,
                STARTTIME = v_ESIID_STATION.Starttime,
                STOPTIME = v_ESIID_STATION.Stoptime,
                ADDTIME = v_ESIID_STATION.Addtime
            WHERE STATIONCODE = v_ESIID_STATION.Stationcode;
        END;
    	v_IDX := v_LINES.NEXT(v_IDX);
	END LOOP;

    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
      p_STATUS := SQLCODE;
      p_MESSAGE := 'Error in MEX_ERCOT_SETTLEMENT.PARSE_ESIID_STATION: ' || SQLERRM;
END PARSE_ESIID_STATION;
----------------------------------------------------------------------------------------------------
PROCEDURE PARSE_ESIID_STATION_HIST
	(
    p_RESPONSE_CLOB IN CLOB,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
    ) IS
v_LINES PARSE_UTIL.BIG_STRING_TABLE_MP;
v_COLS PARSE_UTIL.STRING_TABLE;
v_IDX BINARY_INTEGER;
v_ESIID_STATION_HIST STATIONSERVICEHIST%ROWTYPE;
BEGIN
	p_STATUS := MEX_UTIL.g_SUCCESS;
	PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_RESPONSE_CLOB, v_LINES);
	v_IDX := v_LINES.FIRST;

	WHILE v_LINES.EXISTS(v_IDX) LOOP
        PARSE_UTIL.PARSE_DELIMITED_STRING(v_LINES(v_IDX),',',v_COLS);
        v_ESIID_STATION_HIST.Stationcode := v_COLS(1);
        v_ESIID_STATION_HIST.Starttime := TO_DATE(v_COLS(2), 'mm/dd/yyyy hh24:mi:ss');
        v_ESIID_STATION_HIST.Stoptime := TO_DATE(v_COLS(3), 'mm/dd/yyyy hh24:mi:ss');
        v_ESIID_STATION_HIST.Ufezonecode := v_COLS(4);
        v_ESIID_STATION_HIST.Cmzonecode := v_COLS(5);
        v_ESIID_STATION_HIST.Addtime := TO_DATE(v_COLS(6), 'mm/dd/yyyy hh24:mi:ss');
        v_ESIID_STATION_HIST.Subufecode := v_COLS(7);
        BEGIN
            INSERT INTO STATIONSERVICEHIST VALUES v_ESIID_STATION_HIST;
        EXCEPTION
 	        WHEN DUP_VAL_ON_INDEX THEN
            UPDATE STATIONSERVICEHIST
            SET STOPTIME = v_ESIID_STATION_HIST.Stoptime,
                UFEZONECODE = v_ESIID_STATION_HIST.Ufezonecode,
                CMZONECODE = v_ESIID_STATION_HIST.Cmzonecode,
                ADDTIME = v_ESIID_STATION_HIST.Addtime,
                SUBUFECODE = v_ESIID_STATION_HIST.Subufecode
            WHERE STATIONCODE = v_ESIID_STATION_HIST.Stationcode
            AND STARTTIME = v_ESIID_STATION_HIST.Starttime;
        END;
    	v_IDX := v_LINES.NEXT(v_IDX);
	END LOOP;

    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
      p_STATUS := SQLCODE;
      p_MESSAGE := 'Error in MEX_ERCOT_SETTLEMENT.PARSE_ESIID_STATION_HIST: ' || SQLERRM;
END PARSE_ESIID_STATION_HIST;
----------------------------------------------------------------------------------------------------
PROCEDURE PARSE_ESIID_TDSP
	(
    p_RESPONSE_CLOB IN CLOB,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
    ) IS
v_LINES PARSE_UTIL.BIG_STRING_TABLE_MP;
v_COLS PARSE_UTIL.STRING_TABLE;
v_IDX BINARY_INTEGER;
v_ESIID_TDSP TDSP%ROWTYPE;
BEGIN
	p_STATUS := MEX_UTIL.g_SUCCESS;
	PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_RESPONSE_CLOB, v_LINES);
	v_IDX := v_LINES.FIRST;

	WHILE v_LINES.EXISTS(v_IDX) LOOP
        PARSE_UTIL.PARSE_DELIMITED_STRING(v_LINES(v_IDX),',',v_COLS);
        v_ESIID_TDSP.Tdspcode := v_COLS(1);
        v_ESIID_TDSP.Tdspname := v_COLS(2);
        v_ESIID_TDSP.Starttime := TO_DATE(v_COLS(3), 'mm/dd/yyyy hh24:mi:ss');
        v_ESIID_TDSP.Stoptime := TO_DATE(v_COLS(4), 'mm/dd/yyyy hh24:mi:ss');
        v_ESIID_TDSP.Addtime := TO_DATE(v_COLS(5), 'mm/dd/yyyy hh24:mi:ss');
        v_ESIID_TDSP.Dunsnumber := v_COLS(6);
        v_ESIID_TDSP.Noiecode := v_COLS(7);
        BEGIN
            INSERT INTO TDSP VALUES v_ESIID_TDSP;
        EXCEPTION
 	        WHEN DUP_VAL_ON_INDEX THEN
            UPDATE TDSP
            SET TDSPNAME = v_ESIID_TDSP.Tdspname,
                STARTTIME = v_ESIID_TDSP.Starttime,
                STOPTIME = v_ESIID_TDSP.Stoptime,
                ADDTIME = v_ESIID_TDSP.Addtime,
                DUNSNUMBER = v_ESIID_TDSP.Dunsnumber,
                NOIECODE = v_ESIID_TDSP.Noiecode
            WHERE TDSPCODE = v_ESIID_TDSP.Tdspcode;
        END;
    	v_IDX := v_LINES.NEXT(v_IDX);
	END LOOP;

    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
      p_STATUS := SQLCODE;
      p_MESSAGE := 'Error in MEX_ERCOT_SETTLEMENT.PARSE_ESIID_TDSP: ' || SQLERRM;
END PARSE_ESIID_TDSP;
----------------------------------------------------------------------------------------------------
PROCEDURE PARSE_ESIID_CMZONE
	(
    p_RESPONSE_CLOB IN CLOB,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
    ) IS
v_LINES PARSE_UTIL.BIG_STRING_TABLE_MP;
v_COLS PARSE_UTIL.STRING_TABLE;
v_IDX BINARY_INTEGER;
v_ESIID_CMZONE CMZONE%ROWTYPE;
BEGIN
	p_STATUS := MEX_UTIL.g_SUCCESS;
	PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_RESPONSE_CLOB, v_LINES);
	v_IDX := v_LINES.FIRST;

	WHILE v_LINES.EXISTS(v_IDX) LOOP
        PARSE_UTIL.PARSE_DELIMITED_STRING(v_LINES(v_IDX),',',v_COLS);
        v_ESIID_CMZONE.Cmzonecode := v_COLS(1);
        v_ESIID_CMZONE.Cmzonename := v_COLS(2);
        v_ESIID_CMZONE.Starttime := TO_DATE(v_COLS(3), 'mm/dd/yyyy hh24:mi:ss');
        v_ESIID_CMZONE.Stoptime := TO_DATE(v_COLS(4), 'mm/dd/yyyy hh24:mi:ss');
        v_ESIID_CMZONE.Addtime := TO_DATE(v_COLS(5), 'mm/dd/yyyy hh24:mi:ss');
        BEGIN
            INSERT INTO CMZONE VALUES v_ESIID_CMZONE;
        EXCEPTION
 	        WHEN DUP_VAL_ON_INDEX THEN
            UPDATE CMZONE
            SET CMZONENAME = v_ESIID_CMZONE.Cmzonename,
                STARTTIME = v_ESIID_CMZONE.Starttime,
                STOPTIME = v_ESIID_CMZONE.Stoptime,
                ADDTIME = v_ESIID_CMZONE.Addtime
            WHERE CMZONECODE = v_ESIID_CMZONE.Cmzonecode;
        END;
    	v_IDX := v_LINES.NEXT(v_IDX);
	END LOOP;

    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
      p_STATUS := SQLCODE;
      p_MESSAGE := 'Error in MEX_ERCOT_SETTLEMENT.PARSE_ESIID_CMZONE: ' || SQLERRM;
END PARSE_ESIID_CMZONE;
----------------------------------------------------------------------------------------------------
PROCEDURE PARSE_CHANNEL_CUT_DATA
	(
    p_RESPONSE_CLOB IN CLOB,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
    ) IS
v_LINES PARSE_UTIL.BIG_STRING_TABLE_MP;
v_COLS PARSE_UTIL.STRING_TABLE;
v_IDX BINARY_INTEGER;
v_CHANNEL_DATA LSCHANNELCUTDATA%ROWTYPE;
BEGIN
	p_STATUS := MEX_UTIL.g_SUCCESS;
	PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_RESPONSE_CLOB, v_LINES);
	v_IDX := v_LINES.FIRST;

	WHILE v_LINES.EXISTS(v_IDX) LOOP
        PARSE_UTIL.PARSE_DELIMITED_STRING(v_LINES(v_IDX),',',v_COLS);
        v_CHANNEL_DATA.Uidchannelcut := v_COLS(1);
        v_CHANNEL_DATA.Addtime := TO_DATE(v_COLS(2), 'mm/dd/yyyy hh24:mi:ss');
        v_CHANNEL_DATA.Trade_Date := TO_DATE(v_COLS(3), 'mm/dd/yyyy hh24:mi:ss');
        v_CHANNEL_DATA.Int001 := v_COLS(4);
        v_CHANNEL_DATA.Int002 := v_COLS(5);
        v_CHANNEL_DATA.Int003 := v_COLS(6);
        v_CHANNEL_DATA.Int004 := v_COLS(7);
        v_CHANNEL_DATA.Int005 := v_COLS(8);
        v_CHANNEL_DATA.Int006 := v_COLS(9);
        v_CHANNEL_DATA.Int007 := v_COLS(10);
        v_CHANNEL_DATA.Int008 := v_COLS(11);
        v_CHANNEL_DATA.Int009 := v_COLS(12);
        v_CHANNEL_DATA.Int010 := v_COLS(13);
        v_CHANNEL_DATA.Int011 := v_COLS(14);
        v_CHANNEL_DATA.Int012 := v_COLS(15);
        v_CHANNEL_DATA.Int013 := v_COLS(16);
        v_CHANNEL_DATA.Int014 := v_COLS(17);
        v_CHANNEL_DATA.Int015 := v_COLS(18);
        v_CHANNEL_DATA.Int016 := v_COLS(19);
        v_CHANNEL_DATA.Int017 := v_COLS(20);
        v_CHANNEL_DATA.Int018 := v_COLS(21);
        v_CHANNEL_DATA.Int019 := v_COLS(22);
        v_CHANNEL_DATA.Int020 := v_COLS(23);
        v_CHANNEL_DATA.Int021 := v_COLS(24);
        v_CHANNEL_DATA.Int022 := v_COLS(25);
        v_CHANNEL_DATA.Int023 := v_COLS(26);
        v_CHANNEL_DATA.Int024 := v_COLS(27);
        v_CHANNEL_DATA.Int025 := v_COLS(28);
        v_CHANNEL_DATA.Int026 := v_COLS(29);
        v_CHANNEL_DATA.Int027 := v_COLS(30);
        v_CHANNEL_DATA.Int028 := v_COLS(31);
        v_CHANNEL_DATA.Int029 := v_COLS(32);
        v_CHANNEL_DATA.Int030 := v_COLS(33);
        v_CHANNEL_DATA.Int031 := v_COLS(34);
        v_CHANNEL_DATA.Int032 := v_COLS(35);
        v_CHANNEL_DATA.Int033 := v_COLS(36);
        v_CHANNEL_DATA.Int034 := v_COLS(37);
        v_CHANNEL_DATA.Int035 := v_COLS(38);
        v_CHANNEL_DATA.Int036 := v_COLS(39);
        v_CHANNEL_DATA.Int037 := v_COLS(40);
        v_CHANNEL_DATA.Int038 := v_COLS(41);
        v_CHANNEL_DATA.Int039 := v_COLS(42);
        v_CHANNEL_DATA.Int040 := v_COLS(43);
        v_CHANNEL_DATA.Int041 := v_COLS(44);
        v_CHANNEL_DATA.Int042 := v_COLS(45);
        v_CHANNEL_DATA.Int043 := v_COLS(46);
        v_CHANNEL_DATA.Int044 := v_COLS(47);
        v_CHANNEL_DATA.Int045 := v_COLS(48);
        v_CHANNEL_DATA.Int046 := v_COLS(49);
        v_CHANNEL_DATA.Int047 := v_COLS(50);
        v_CHANNEL_DATA.Int048 := v_COLS(51);
        v_CHANNEL_DATA.Int049 := v_COLS(52);
        v_CHANNEL_DATA.Int050 := v_COLS(53);
        v_CHANNEL_DATA.Int051 := v_COLS(54);
        v_CHANNEL_DATA.Int052 := v_COLS(55);
        v_CHANNEL_DATA.Int053 := v_COLS(56);
        v_CHANNEL_DATA.Int054 := v_COLS(57);
        v_CHANNEL_DATA.Int055 := v_COLS(58);
        v_CHANNEL_DATA.Int056 := v_COLS(59);
        v_CHANNEL_DATA.Int057 := v_COLS(60);
        v_CHANNEL_DATA.Int058 := v_COLS(61);
        v_CHANNEL_DATA.Int059 := v_COLS(62);
        v_CHANNEL_DATA.Int060 := v_COLS(63);
        v_CHANNEL_DATA.Int061 := v_COLS(64);
        v_CHANNEL_DATA.Int062 := v_COLS(65);
        v_CHANNEL_DATA.Int063 := v_COLS(66);
        v_CHANNEL_DATA.Int064 := v_COLS(67);
        v_CHANNEL_DATA.Int065 := v_COLS(68);
        v_CHANNEL_DATA.Int066 := v_COLS(69);
        v_CHANNEL_DATA.Int067 := v_COLS(70);
        v_CHANNEL_DATA.Int068 := v_COLS(71);
        v_CHANNEL_DATA.Int069 := v_COLS(72);
        v_CHANNEL_DATA.Int070 := v_COLS(73);
        v_CHANNEL_DATA.Int071 := v_COLS(74);
        v_CHANNEL_DATA.Int072 := v_COLS(75);
        v_CHANNEL_DATA.Int073 := v_COLS(76);
        v_CHANNEL_DATA.Int074 := v_COLS(77);
        v_CHANNEL_DATA.Int075 := v_COLS(78);
        v_CHANNEL_DATA.Int076 := v_COLS(79);
        v_CHANNEL_DATA.Int077 := v_COLS(80);
        v_CHANNEL_DATA.Int078 := v_COLS(81);
        v_CHANNEL_DATA.Int079 := v_COLS(82);
        v_CHANNEL_DATA.Int080 := v_COLS(83);
        v_CHANNEL_DATA.Int081 := v_COLS(84);
        v_CHANNEL_DATA.Int082 := v_COLS(85);
        v_CHANNEL_DATA.Int083 := v_COLS(86);
        v_CHANNEL_DATA.Int084 := v_COLS(87);
        v_CHANNEL_DATA.Int085 := v_COLS(88);
        v_CHANNEL_DATA.Int086 := v_COLS(89);
        v_CHANNEL_DATA.Int087 := v_COLS(90);
        v_CHANNEL_DATA.Int088 := v_COLS(91);
        v_CHANNEL_DATA.Int089 := v_COLS(92);
        v_CHANNEL_DATA.Int090 := v_COLS(93);
        v_CHANNEL_DATA.Int091 := v_COLS(94);
        v_CHANNEL_DATA.Int092 := v_COLS(95);
        v_CHANNEL_DATA.Int093 := v_COLS(96);
        v_CHANNEL_DATA.Int094 := v_COLS(97);
        v_CHANNEL_DATA.Int095 := v_COLS(98);
        v_CHANNEL_DATA.Int096 := v_COLS(99);
        v_CHANNEL_DATA.Int097 := v_COLS(100);
        v_CHANNEL_DATA.Int098 := v_COLS(101);
        v_CHANNEL_DATA.Int099 := v_COLS(102);
        v_CHANNEL_DATA.Int100 := v_COLS(103);
        BEGIN
            INSERT INTO LSCHANNELCUTDATA VALUES v_CHANNEL_DATA;
        EXCEPTION
 	        WHEN DUP_VAL_ON_INDEX THEN
            UPDATE LSCHANNELCUTDATA
            	SET ADDTIME = v_CHANNEL_DATA.ADDTIME,
                    INT001 = v_CHANNEL_DATA.INT001,
                    INT002 = v_CHANNEL_DATA.INT002,
					INT003 = v_CHANNEL_DATA.INT003,
					INT004 = v_CHANNEL_DATA.INT004,
					INT005 = v_CHANNEL_DATA.INT005,
					INT006 = v_CHANNEL_DATA.INT006,
					INT007 = v_CHANNEL_DATA.INT007,
					INT008 = v_CHANNEL_DATA.INT008,
					INT009 = v_CHANNEL_DATA.INT009,
					INT010 = v_CHANNEL_DATA.INT010,
                    INT011 = v_CHANNEL_DATA.INT011,
                    INT012 = v_CHANNEL_DATA.INT012,
                    INT013 = v_CHANNEL_DATA.INT013,
                    INT014 = v_CHANNEL_DATA.INT014,
                    INT015 = v_CHANNEL_DATA.INT015,
                    INT016 = v_CHANNEL_DATA.INT016,
                    INT017 = v_CHANNEL_DATA.INT017,
                    INT018 = v_CHANNEL_DATA.INT018,
                    INT019 = v_CHANNEL_DATA.INT019,
                    INT020 = v_CHANNEL_DATA.INT020,
                    INT021 = v_CHANNEL_DATA.INT021,
                    INT022 = v_CHANNEL_DATA.INT022,
                    INT023 = v_CHANNEL_DATA.INT023,
                    INT024 = v_CHANNEL_DATA.INT024,
                    INT025 = v_CHANNEL_DATA.INT025,
                    INT026 = v_CHANNEL_DATA.INT026,
                    INT027 = v_CHANNEL_DATA.INT027,
                    INT028 = v_CHANNEL_DATA.INT028,
                    INT029 = v_CHANNEL_DATA.INT029,
                    INT030 = v_CHANNEL_DATA.INT030,
                    INT031 = v_CHANNEL_DATA.INT031,
                    INT032 = v_CHANNEL_DATA.INT032,
                    INT033 = v_CHANNEL_DATA.INT033,
                    INT034 = v_CHANNEL_DATA.INT034,
                    INT035 = v_CHANNEL_DATA.INT035,
                    INT036 = v_CHANNEL_DATA.INT036,
                    INT037 = v_CHANNEL_DATA.INT037,
                    INT038 = v_CHANNEL_DATA.INT038,
                    INT039 = v_CHANNEL_DATA.INT039,
                    INT040 = v_CHANNEL_DATA.INT040,
                    INT041 = v_CHANNEL_DATA.INT041,
                    INT042 = v_CHANNEL_DATA.INT042,
                    INT043 = v_CHANNEL_DATA.INT043,
                    INT044 = v_CHANNEL_DATA.INT044,
                    INT045 = v_CHANNEL_DATA.INT045,
                    INT046 = v_CHANNEL_DATA.INT046,
                    INT047 = v_CHANNEL_DATA.INT047,
                    INT048 = v_CHANNEL_DATA.INT048,
                    INT049 = v_CHANNEL_DATA.INT049,
                    INT050 = v_CHANNEL_DATA.INT050,
                    INT051 = v_CHANNEL_DATA.INT051,
                    INT052 = v_CHANNEL_DATA.INT052,
                    INT053 = v_CHANNEL_DATA.INT053,
                    INT054 = v_CHANNEL_DATA.INT054,
                    INT055 = v_CHANNEL_DATA.INT055,
                    INT056 = v_CHANNEL_DATA.INT056,
                    INT057 = v_CHANNEL_DATA.INT057,
                    INT058 = v_CHANNEL_DATA.INT058,
                    INT059 = v_CHANNEL_DATA.INT059,
                    INT060 = v_CHANNEL_DATA.INT060,
                    INT061 = v_CHANNEL_DATA.INT061,
                    INT062 = v_CHANNEL_DATA.INT062,
                    INT063 = v_CHANNEL_DATA.INT063,
                    INT064 = v_CHANNEL_DATA.INT064,
                    INT065 = v_CHANNEL_DATA.INT065,
                    INT066 = v_CHANNEL_DATA.INT066,
                    INT067 = v_CHANNEL_DATA.INT067,
                    INT068 = v_CHANNEL_DATA.INT068,
                    INT069 = v_CHANNEL_DATA.INT069,
                    INT070 = v_CHANNEL_DATA.INT070,
                    INT071 = v_CHANNEL_DATA.INT071,
                    INT072 = v_CHANNEL_DATA.INT072,
                    INT073 = v_CHANNEL_DATA.INT073,
                    INT074 = v_CHANNEL_DATA.INT074,
                    INT075 = v_CHANNEL_DATA.INT075,
                    INT076 = v_CHANNEL_DATA.INT076,
                    INT077 = v_CHANNEL_DATA.INT077,
                    INT078 = v_CHANNEL_DATA.INT078,
                    INT079 = v_CHANNEL_DATA.INT079,
                    INT080 = v_CHANNEL_DATA.INT080,
                    INT081 = v_CHANNEL_DATA.INT081,
                    INT082 = v_CHANNEL_DATA.INT082,
                    INT083 = v_CHANNEL_DATA.INT083,
                    INT084 = v_CHANNEL_DATA.INT084,
                    INT085 = v_CHANNEL_DATA.INT085,
                    INT086 = v_CHANNEL_DATA.INT086,
                    INT087 = v_CHANNEL_DATA.INT087,
                    INT088 = v_CHANNEL_DATA.INT088,
                    INT089 = v_CHANNEL_DATA.INT089,
                    INT090 = v_CHANNEL_DATA.INT090,
                    INT091 = v_CHANNEL_DATA.INT091,
                    INT092 = v_CHANNEL_DATA.INT092,
                    INT093 = v_CHANNEL_DATA.INT093,
                    INT094 = v_CHANNEL_DATA.INT094,
                    INT095 = v_CHANNEL_DATA.INT095,
                    INT096 = v_CHANNEL_DATA.INT096,
                    INT097 = v_CHANNEL_DATA.INT097,
                    INT098 = v_CHANNEL_DATA.INT098,
                    INT099 = v_CHANNEL_DATA.INT099,
    				INT100 = v_CHANNEL_DATA.INT100
				WHERE UIDCHANNELCUT  = v_CHANNEL_DATA.Uidchannelcut
                AND TRADE_DATE = v_CHANNEL_DATA.Trade_Date;
        END;
    	v_IDX := v_LINES.NEXT(v_IDX);
	END LOOP;

    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
      p_STATUS := SQLCODE;
      p_MESSAGE := 'Error in MEX_ERCOT_SETTLEMENT.PARSE_CHANNEL_CUT_DATA: ' || SQLERRM;
END PARSE_CHANNEL_CUT_DATA;
----------------------------------------------------------------------------------------------------
PROCEDURE PARSE_CHANNEL_CUT_HEADER
	(
    p_RESPONSE_CLOB IN CLOB,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
    ) IS
v_LINES PARSE_UTIL.BIG_STRING_TABLE_MP;
v_COLS PARSE_UTIL.STRING_TABLE;
v_IDX BINARY_INTEGER;
v_CHANNEL_HEAD LSCHANNELCUTHEADER%ROWTYPE;
BEGIN
	p_STATUS := MEX_UTIL.g_SUCCESS;
	PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_RESPONSE_CLOB, v_LINES);
	v_IDX := v_LINES.FIRST;

	WHILE v_LINES.EXISTS(v_IDX) LOOP
        PARSE_UTIL.PARSE_DELIMITED_STRING(v_LINES(v_IDX),',',v_COLS);
        v_CHANNEL_HEAD.Uidchannelcut := v_COLS(1);
        v_CHANNEL_HEAD.Uidchannel := v_COLS(2);
        v_CHANNEL_HEAD.Recorder := v_COLS(3);
        v_CHANNEL_HEAD.Channel := v_COLS(4);
        v_CHANNEL_HEAD.Starttime:= TO_DATE(v_COLS(5), 'mm/dd/yyyy hh24:mi:ss');
        v_CHANNEL_HEAD.Stoptime := TO_DATE(v_COLS(6), 'mm/dd/yyyy hh24:mi:ss');
        v_CHANNEL_HEAD.Spi := v_COLS(7);
        v_CHANNEL_HEAD.Uomcode := v_COLS(8);
        v_CHANNEL_HEAD.Dstparticipant := v_COLS(9);
        v_CHANNEL_HEAD.Timezone := v_COLS(10);
        v_CHANNEL_HEAD.Origin := v_COLS(11);
        v_CHANNEL_HEAD.Startreading := v_COLS(12);
        v_CHANNEL_HEAD.Stopreading := v_COLS(13);
        v_CHANNEL_HEAD.Metermultiplier := v_COLS(14);
        v_CHANNEL_HEAD.Meteroffset := v_COLS(15);
        v_CHANNEL_HEAD.Pulsemultiplier := v_COLS(16);
        v_CHANNEL_HEAD.Pulseoffset := v_COLS(17);
        v_CHANNEL_HEAD.Edited := v_COLS(18);
        v_CHANNEL_HEAD.Internalvalidation := v_COLS(19);
        v_CHANNEL_HEAD.Externalvalidation := v_COLS(20);
        v_CHANNEL_HEAD.Mergeflag := v_COLS(21);
        v_CHANNEL_HEAD.Deleteflag := v_COLS(22);
        v_CHANNEL_HEAD.Valflage := v_COLS(23);
        v_CHANNEL_HEAD.Valflagi := v_COLS(24);
        v_CHANNEL_HEAD.Valflago := v_COLS(25);
        v_CHANNEL_HEAD.Valflagn := v_COLS(26);
        v_CHANNEL_HEAD.Tkwrittenflag := v_COLS(27);
        v_CHANNEL_HEAD.Dcflow := v_COLS(28);
        v_CHANNEL_HEAD.Acceptrejectstatus := v_COLS(29);
        v_CHANNEL_HEAD.Translationtime := TO_DATE(v_COLS(30), 'mm/dd/yyyy hh24:mi:ss');
        v_CHANNEL_HEAD.Descriptor := v_COLS(31);
        v_CHANNEL_HEAD.Addtime := TO_DATE(v_COLS(32), 'mm/dd/yyyy hh24:mi:ss');
        v_CHANNEL_HEAD.Intervalcount := v_COLS(33);
        v_CHANNEL_HEAD.Chnlcuttimestamp := TO_DATE(v_COLS(34), 'mm/dd/yyyy hh24:mi:ss');
        BEGIN
            INSERT INTO LSCHANNELCUTHEADER VALUES v_CHANNEL_HEAD;
        EXCEPTION
 	        WHEN DUP_VAL_ON_INDEX THEN
            UPDATE LSCHANNELCUTHEADER
            	SET UIDCHANNEL = v_CHANNEL_HEAD.Uidchannel,
					RECORDER = v_CHANNEL_HEAD.Recorder,
                    CHANNEL = v_CHANNEL_HEAD.Channel,
                    STARTTIME = v_CHANNEL_HEAD.Starttime,
					STOPTIME = v_CHANNEL_HEAD.Stoptime,
					SPI = v_CHANNEL_HEAD.Spi,
					UOMCODE = v_CHANNEL_HEAD.Uomcode,
					DSTPARTICIPANT = v_CHANNEL_HEAD.Dstparticipant,
					TIMEZONE = v_CHANNEL_HEAD.Timezone,
					ORIGIN = v_CHANNEL_HEAD.Origin,
					STARTREADING = v_CHANNEL_HEAD.Startreading,
					STOPREADING = v_CHANNEL_HEAD.Stopreading,
                    METERMULTIPLIER = v_CHANNEL_HEAD.Metermultiplier,
                    METEROFFSET = v_CHANNEL_HEAD.Meteroffset,
                    PULSEMULTIPLIER = v_CHANNEL_HEAD.Pulsemultiplier,
                    PULSEOFFSET = v_CHANNEL_HEAD.Pulseoffset,
                    EDITED = v_CHANNEL_HEAD.Edited,
                    INTERNALVALIDATION = v_CHANNEL_HEAD.Internalvalidation,
                    EXTERNALVALIDATION = v_CHANNEL_HEAD.Externalvalidation,
                    MERGEFLAG = v_CHANNEL_HEAD.Mergeflag,
                    DELETEFLAG = v_CHANNEL_HEAD.Deleteflag,
                    VALFLAGE = v_CHANNEL_HEAD.Valflage,
                    VALFLAGI = v_CHANNEL_HEAD.Valflagi,
                    VALFLAGO = v_CHANNEL_HEAD.Valflago,
                    VALFLAGN = v_CHANNEL_HEAD.Valflagn,
                    TKWRITTENFLAG = v_CHANNEL_HEAD.Tkwrittenflag,
                    DCFLOW = v_CHANNEL_HEAD.Dcflow,
                    ACCEPTREJECTSTATUS = v_CHANNEL_HEAD.Acceptrejectstatus,
                    TRANSLATIONTIME = v_CHANNEL_HEAD.Translationtime,
                    DESCRIPTOR = v_CHANNEL_HEAD.Descriptor,
                    ADDTIME = v_CHANNEL_HEAD.Addtime,
                    INTERVALCOUNT = v_CHANNEL_HEAD.Intervalcount,
                    CHNLCUTTIMESTAMP = v_CHANNEL_HEAD.Chnlcuttimestamp
				WHERE UIDCHANNELCUT  = v_CHANNEL_HEAD.UIDCHANNELCUT;
        END;
    	v_IDX := v_LINES.NEXT(v_IDX);
	END LOOP;

    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
      p_STATUS := SQLCODE;
      p_MESSAGE := 'Error in MEX_ERCOT_SETTLEMENT.PARSE_CHANNEL_CUT_HEADER: ' || SQLERRM;
END PARSE_CHANNEL_CUT_HEADER;
----------------------------------------------------------------------------------------------------
PROCEDURE PARSE_CHANNEL_DELETE
	(
    p_RESPONSE_CLOB IN CLOB,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
    ) IS
v_LINES PARSE_UTIL.BIG_STRING_TABLE_MP;
v_COLS PARSE_UTIL.STRING_TABLE;
v_IDX BINARY_INTEGER;
v_CHANNEL_DEL LSCHANNELCUTHEADER_DELETE%ROWTYPE;
BEGIN
	p_STATUS := MEX_UTIL.g_SUCCESS;
	PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_RESPONSE_CLOB, v_LINES);
	v_IDX := v_LINES.FIRST;

	WHILE v_LINES.EXISTS(v_IDX) LOOP
        PARSE_UTIL.PARSE_DELIMITED_STRING(v_LINES(v_IDX),',',v_COLS);
        v_CHANNEL_DEL.Uidchannelcut := v_COLS(1);
        v_CHANNEL_DEL.d_Timestamp := TO_DATE(v_COLS(2), 'mm/dd/yyyy hh24:mi:ss');
        v_CHANNEL_DEL.Src_Chnlcuttimestamp := TO_DATE(v_COLS(3), 'mm/dd/yyyy hh24:mi:ss');
        BEGIN
            INSERT INTO LSCHANNELCUTHEADER_DELETE VALUES v_CHANNEL_DEL;
        EXCEPTION
 	        WHEN DUP_VAL_ON_INDEX THEN
            UPDATE LSCHANNELCUTHEADER_DELETE
            SET D_TIMESTAMP = v_CHANNEL_DEL.d_Timestamp
            WHERE UIDCHANNELCUT = v_CHANNEL_DEL.Uidchannelcut
            AND SRC_CHNLCUTTIMESTAMP = v_CHANNEL_DEL.Src_Chnlcuttimestamp;
        END;
    	v_IDX := v_LINES.NEXT(v_IDX);
	END LOOP;

    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
      p_STATUS := SQLCODE;
      p_MESSAGE := 'Error in MEX_ERCOT_SETTLEMENT.PARSE_CHANNEL_DELETE: ' || SQLERRM;
END PARSE_CHANNEL_DELETE;
----------------------------------------------------------------------------------------------------
PROCEDURE PARSE_ESIID_PROFILECLASS
	(
    p_RESPONSE_CLOB IN CLOB,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
    ) IS
v_LINES PARSE_UTIL.BIG_STRING_TABLE_MP;
v_COLS PARSE_UTIL.STRING_TABLE;
v_IDX BINARY_INTEGER;
v_ESIID_PROFILE PROFILECLASS%ROWTYPE;
BEGIN
	p_STATUS := MEX_UTIL.g_SUCCESS;
	PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_RESPONSE_CLOB, v_LINES);
	v_IDX := v_LINES.FIRST;

	WHILE v_LINES.EXISTS(v_IDX) LOOP
        PARSE_UTIL.PARSE_DELIMITED_STRING(v_LINES(v_IDX),',',v_COLS);
        v_ESIID_PROFILE.Profilecode := v_COLS(1);
        v_ESIID_PROFILE.Weathersensitivity := v_COLS(2);
        v_ESIID_PROFILE.Metertype := v_COLS(3);
        v_ESIID_PROFILE.Starttime := TO_DATE(v_COLS(4), 'mm/dd/yyyy hh24:mi:ss');
        v_ESIID_PROFILE.Stoptime := TO_DATE(v_COLS(5), 'mm/dd/yyyy hh24:mi:ss');
        v_ESIID_PROFILE.Addtime := TO_DATE(v_COLS(6), 'mm/dd/yyyy hh24:mi:ss');
        v_ESIID_PROFILE.Toutype := v_COLS(7);
        v_ESIID_PROFILE.Profilecutcode := v_COLS(8);
        BEGIN
            INSERT INTO PROFILECLASS VALUES v_ESIID_PROFILE;
        EXCEPTION
 	        WHEN DUP_VAL_ON_INDEX THEN
            UPDATE PROFILECLASS
            SET WEATHERSENSITIVITY = v_ESIID_PROFILE.Weathersensitivity,
                METERTYPE = v_ESIID_PROFILE.Metertype,
                STARTTIME = v_ESIID_PROFILE.Starttime,
                STOPTIME = v_ESIID_PROFILE.Stoptime,
                ADDTIME = v_ESIID_PROFILE.Addtime,
                TOUTYPE = v_ESIID_PROFILE.Toutype,
                PROFILECUTCODE = v_ESIID_PROFILE.Profilecutcode
            WHERE PROFILECODE = v_ESIID_PROFILE.Profilecode;
        END;
    	v_IDX := v_LINES.NEXT(v_IDX);
	END LOOP;

    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
      p_STATUS := SQLCODE;
      p_MESSAGE := 'Error in MEX_ERCOT_SETTLEMENT.PARSE_ESIID_PROFILECLASS: ' || SQLERRM;
END PARSE_ESIID_PROFILECLASS;
----------------------------------------------------------------------------------------------------
PROCEDURE FETCH_ESIID_EXTRACT
	(
    p_URL IN VARCHAR2,
    p_CRED IN mex_credentials,
	p_LOG_ONLY IN NUMBER,
    p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2,
	p_LOGGER IN OUT mm_logger_adapter
    ) IS
v_RESPONSE_XML XMLTYPE := NULL;
v_REQUEST_CLOB CLOB;
v_RESPONSE_CLOB CLOB;
v_RESULT	   MEX_RESULT;

	CURSOR c_FILES(v_XML IN XMLTYPE) IS
	SELECT EXTRACTVALUE(VALUE(U),
							'//File',
							MEX_SWITCHBOARD.c_MEX_FILELIST_NAMESPACE_DEF) "FILENAME"
	FROM TABLE(XMLSEQUENCE(EXTRACT(v_XML,
									'//FileList',
									MEX_SWITCHBOARD.c_MEX_FILELIST_NAMESPACE_DEF))) T,
	TABLE(XMLSEQUENCE(EXTRACT(VALUE(T),
							'//File',
							MEX_SWITCHBOARD.c_MEX_FILELIST_NAMESPACE_DEF))) U;
BEGIN



    v_RESULT := Mex_Switchboard.FetchURL(p_URL_to_Fetch => p_URL,
										 p_Logger => p_LOGGER,
										 p_Cred => p_CRED,
										 p_Log_Only => p_LOG_ONLY);

	p_STATUS  := v_RESULT.STATUS_CODE;
    IF v_RESULT.STATUS_CODE <> MEX_Switchboard.c_Status_Success THEN
    	v_RESPONSE_CLOB := NULL;
    ELSE
    	v_RESPONSE_CLOB := v_RESULT.RESPONSE;
    END IF;

    IF p_STATUS = MEX_UTIL.g_SUCCESS THEN
        v_RESPONSE_XML :=  XMLTYPE.CREATEXML(v_RESPONSE_CLOB);
        FOR v_FILE IN c_FILES(v_RESPONSE_XML) LOOP
            DBMS_OUTPUT.put_line(v_FILE.FILENAME);
			-- send the request
			DBMS_LOB.CREATETEMPORARY(v_REQUEST_CLOB, TRUE);
			DBMS_LOB.CREATETEMPORARY(v_RESPONSE_CLOB, TRUE);

            p_STATUS := GA.SUCCESS;

			v_RESULT := Mex_Switchboard.FetchFile(p_FilePath => v_FILE.FILENAME,
												 p_Logger => p_LOGGER,
												 p_Cred => p_CRED,
												 p_Log_Only => p_LOG_ONLY);

			p_STATUS  := v_RESULT.STATUS_CODE;
			IF v_RESULT.STATUS_CODE <> MEX_Switchboard.c_Status_Success THEN
				v_RESPONSE_CLOB := NULL;
			ELSE
				v_RESPONSE_CLOB := v_RESULT.RESPONSE;
			END IF;

			IF p_STATUS = MEX_UTIL.g_SUCCESS THEN
				IF v_FILE.FILENAME LIKE '%-ESIID-%.csv' THEN
					PARSE_ESIID(v_RESPONSE_CLOB, p_STATUS, p_MESSAGE);
				ELSIF v_FILE.FILENAME LIKE '%-ESIIDSERVICEHIST-%.csv' THEN
					PARSE_ESIID_SERV_HIST(v_RESPONSE_CLOB, p_STATUS, p_MESSAGE);
				ELSIF v_FILE.FILENAME LIKE '%-ESIIDSERVICEHIST_DELETE-%.csv' THEN
					PARSE_ESIID_SERV_HIST_DEL(v_RESPONSE_CLOB, p_STATUS, p_MESSAGE);
				ELSIF v_FILE.FILENAME LIKE '%-ESIIDUSAGE-%.csv' THEN
					PARSE_ESIID_USAGE(v_RESPONSE_CLOB, p_STATUS, p_MESSAGE);
				ELSIF v_FILE.FILENAME LIKE '%-ESIIDUSAGE_DELETE-%.csv' THEN
					PARSE_ESIID_USAGE_DEL(v_RESPONSE_CLOB, p_STATUS, p_MESSAGE);
				ELSIF v_FILE.FILENAME LIKE '%ESIID_EXTRACT.COUNTS.csv' THEN
					PARSE_ESIID_COUNTS(v_RESPONSE_CLOB, p_STATUS, p_MESSAGE);
				ELSIF v_FILE.FILENAME LIKE '%MRE-%.csv' THEN
					PARSE_ESIID_MRE(v_RESPONSE_CLOB, p_STATUS, p_MESSAGE);
				ELSIF v_FILE.FILENAME LIKE '%PGC-%.csv' THEN
					PARSE_ESIID_PGC(v_RESPONSE_CLOB, p_STATUS, p_MESSAGE);
				ELSIF v_FILE.FILENAME LIKE '%REP-%.csv' THEN
					PARSE_ESIID_REP(v_RESPONSE_CLOB, p_STATUS, p_MESSAGE);
				ELSIF v_FILE.FILENAME LIKE '%STATION-%.csv' THEN
					PARSE_ESIID_STATION(v_RESPONSE_CLOB, p_STATUS, p_MESSAGE);
				ELSIF v_FILE.FILENAME LIKE '%STATIONSERVICEHIST-%.csv' THEN
					PARSE_ESIID_STATION_HIST(v_RESPONSE_CLOB, p_STATUS, p_MESSAGE);
				ELSIF v_FILE.FILENAME LIKE '%TDSP-%.csv' THEN
					PARSE_ESIID_TDSP(v_RESPONSE_CLOB, p_STATUS, p_MESSAGE);
				ELSIF v_FILE.FILENAME LIKE '%CMZONE%.csv' THEN
					PARSE_ESIID_CMZONE(v_RESPONSE_CLOB, p_STATUS, p_MESSAGE);
				ELSIF v_FILE.FILENAME LIKE '%LSCHANNELCUTDATA%.csv' THEN
					PARSE_CHANNEL_CUT_DATA(v_RESPONSE_CLOB, p_STATUS, p_MESSAGE);
				ELSIF v_FILE.FILENAME LIKE '%LSCHANNELCUTHEADER%.csv' THEN
					PARSE_CHANNEL_CUT_HEADER(v_RESPONSE_CLOB, p_STATUS, p_MESSAGE);
				ELSIF v_FILE.FILENAME LIKE '%LSCHANNELCUTHEADER_DELETE%.csv' THEN
					PARSE_CHANNEL_DELETE(v_RESPONSE_CLOB, p_STATUS, p_MESSAGE);
				ELSIF v_FILE.FILENAME LIKE '%PROFILECLASS%.csv' THEN
					PARSE_ESIID_PROFILECLASS(v_RESPONSE_CLOB, p_STATUS, p_MESSAGE);
				END IF;
			END IF;

            DBMS_LOB.FREETEMPORARY(v_REQUEST_CLOB);
            DBMS_LOB.FREETEMPORARY(v_RESPONSE_CLOB);

		END LOOP;
    END IF;

	DBMS_LOB.FREETEMPORARY(v_RESPONSE_CLOB);

END FETCH_ESIID_EXTRACT;
----------------------------------------------------------------------------------------------------
PROCEDURE FETCH_ESIID_EXTRACT_PAGE
	(
	p_CRED	IN mex_credentials,
	p_BEGIN_DATE IN DATE,
    p_END_DATE IN DATE,
	p_LOG_ONLY IN NUMBER,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2,
	p_LOGGER IN OUT mm_logger_adapter
	) IS
v_RESPONSE_CLOB CLOB;
v_URL       VARCHAR2(255);
v_FILENAME  VARCHAR2(255);
v_DATE VARCHAR2(16);
v_LOC_BEGIN NUMBER;
v_LOC_END NUMBER;
v_DOC_ID VARCHAR2(32);
v_CURRENT_DATE DATE;

v_RESULT	   MEX_RESULT;
BEGIN

    p_STATUS  := MEX_UTIL.g_SUCCESS;
    v_URL := GET_DICTIONARY_VALUE('LOAD EXTRACT DOWNLOAD URL', 0, 'MarketExchange', 'ERCOT', 'EXTRACT', '?');

    v_RESULT := Mex_Switchboard.FetchURL(p_URL_to_Fetch => v_URL,
										 p_Logger => p_LOGGER,
										 p_Cred => p_CRED,
										 p_Log_Only => p_LOG_ONLY);

	p_STATUS  := v_RESULT.STATUS_CODE;
    IF v_RESULT.STATUS_CODE <> MEX_Switchboard.c_Status_Success THEN
    	v_RESPONSE_CLOB := NULL;
    ELSE
    	v_RESPONSE_CLOB := v_RESULT.RESPONSE;
    END IF;

    IF p_STATUS = MEX_UTIL.g_SUCCESS THEN
		  -- Loop through the incremented begin date till we reach the end date
		v_CURRENT_DATE := p_BEGIN_DATE;
		WHILE v_CURRENT_DATE <= p_END_DATE
		LOOP
			--parse the response to find the file for the current date
			v_DATE := TO_CHAR(v_CURRENT_DATE,'MM-DD-YYYY');

			IF v_RESPONSE_CLOB IS NOT NULL THEN
				v_LOC_BEGIN := INSTR(v_RESPONSE_CLOB,'ext.(' || v_DATE);
				IF v_LOC_BEGIN = 0 THEN
					--LOG TO APP EVENT LOG THERE IS NO FILENAME FOR THIS DATE
					LOGS.LOG_WARN('There is no filename avaliable for ' || v_DATE || ' .');
				ELSE
					--v_LOC_BEGIN := INSTR(v_RESPONSE_CLOB, '<a href="/contentproxy/proxy?doc_id=',v_LOC_BEGIN - 55);
					--we need to extract the proxy?doc_id= for a specific file
					--the "https://pi.ercot.com/ has been added to the url, so 55 chars is not enough to go back the the <a href position
					--changed to 70
					v_LOC_BEGIN := INSTR(v_RESPONSE_CLOB, '<a href="https://pi.ercot.com/contentproxy/proxy?doc_id=',v_LOC_BEGIN - 70);
					v_LOC_END := INSTR(v_RESPONSE_CLOB, '</a>', v_LOC_BEGIN);
					v_FILENAME := SUBSTR(v_RESPONSE_CLOB, v_LOC_BEGIN, v_LOC_END-v_LOC_BEGIN+LENGTH('</a>'));
					v_LOC_BEGIN := INSTR(v_FILENAME,'proxy?doc_id=');
					v_LOC_END := INSTR(v_FILENAME,'"', v_LOC_BEGIN);
					v_DOC_ID := SUBSTR(v_FILENAME, v_LOC_BEGIN, v_LOC_END-v_LOC_BEGIN);
					v_URL := 'https://tml.ercot.com/contentproxy/' || v_DOC_ID;

					--now fetch the desired load response file
					FETCH_ESIID_EXTRACT(v_URL,
										p_CRED,
										p_LOG_ONLY,
										p_STATUS,
										p_MESSAGE,
										p_LOGGER);
				END IF;
			END IF;
			  v_CURRENT_DATE := v_CURRENT_DATE + 1;
		END LOOP;
    END IF;

	DBMS_LOB.FREETEMPORARY(v_RESPONSE_CLOB);

EXCEPTION
	WHEN OTHERS THEN
	p_STATUS  := SQLCODE;
	p_MESSAGE := 'Error in MEX_ERCOT_SETTLEMENT.FETCH_ESIID_EXTRACT_PAGE: ' || SQLERRM;
END FETCH_ESIID_EXTRACT_PAGE;
--------------------------------------------------------------------------------------------------
PROCEDURE PARSE_LOAD_EXTRACT_HEADER
	(
    v_RESPONSE_CLOB IN CLOB,
    p_WORK_ID IN NUMBER,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
    ) IS
v_LINES PARSE_UTIL.BIG_STRING_TABLE_MP;
v_COLS PARSE_UTIL.STRING_TABLE;
v_IDX BINARY_INTEGER;
v_INITIAL BINARY_INTEGER;
v_FINAL BINARY_INTEGER;
v_TRUEUP BINARY_INTEGER;
v_MARKET_INT_HEADER ERCOT_MARKET_HEADER_WORK%ROWTYPE;
BEGIN
	p_STATUS := MEX_UTIL.g_SUCCESS;

    SELECT STATEMENT_TYPE_ORDER
    INTO v_INITIAL
    FROM STATEMENT_TYPE
    WHERE STATEMENT_TYPE_NAME = MEX_ERCOT.g_ERCOT_INITIAL;

    SELECT STATEMENT_TYPE_ORDER
    INTO v_FINAL
    FROM STATEMENT_TYPE
    WHERE STATEMENT_TYPE_NAME = MEX_ERCOT.g_ERCOT_FINAL;

	--the value of MEX_ERCOT.g_ERCOT_TRUEUP constant has been changed from True-Up 
	--to TrueUp, but the value of statement type remains the same (True-Up).
	--reference a new constant in MEX_ERCOT for this particular situation
	SELECT STATEMENT_TYPE_ORDER
    INTO v_TRUEUP
    FROM STATEMENT_TYPE
    WHERE STATEMENT_TYPE_NAME = MEX_ERCOT.g_ERCOT_TRUEUP_STMNT;

    PARSE_UTIL.PARSE_CLOB_INTO_LINES(v_RESPONSE_CLOB, v_LINES);
	v_IDX := v_LINES.FIRST;

	WHILE v_LINES.EXISTS(v_IDX) LOOP
        PARSE_UTIL.PARSE_DELIMITED_STRING(v_LINES(v_IDX),',',v_COLS);
        v_MARKET_INT_HEADER.WORK_ID := p_WORK_ID;
    	v_MARKET_INT_HEADER.INTERVAL_DATA_ID := v_COLS(1);
        v_MARKET_INT_HEADER.INTERVAL_ID := v_COLS(2);
        v_MARKET_INT_HEADER.RECORDER := v_COLS(3);
        IF v_COLS(4) = 1 THEN
            v_MARKET_INT_HEADER.MARKET_INTERVAL := v_INITIAL;
        ELSIF v_COLS(4) = 4 THEN
            v_MARKET_INT_HEADER.MARKET_INTERVAL := v_FINAL;
        ELSIF v_COLS(4) BETWEEN 5 AND 9 THEN
            v_MARKET_INT_HEADER.MARKET_INTERVAL := v_TRUEUP;
        ELSE
            v_MARKET_INT_HEADER.MARKET_INTERVAL := v_COLS(4);
        END IF;
        v_MARKET_INT_HEADER.START_TIME := TRUNC(TO_DATE(v_COLS(5), 'mm/dd/yyyy hh24:mi:ss'));
        v_MARKET_INT_HEADER.STOP_TIME := TRUNC(TO_DATE(v_COLS(6), 'mm/dd/yyyy hh24:mi:ss'));
        v_MARKET_INT_HEADER.SECONDS_PER_INTERVAL := v_COLS(7);
        v_MARKET_INT_HEADER.MEASUREMENT_UNITS_CODE := v_COLS(8);
        v_MARKET_INT_HEADER.DSTPARTICIPANT := v_COLS(9);
        v_MARKET_INT_HEADER.TIMEZONE := v_COLS(10);
        v_MARKET_INT_HEADER.ORIGIN := v_COLS(11);
        v_MARKET_INT_HEADER.EDITED := v_COLS(12);
        v_MARKET_INT_HEADER.INTERNALVALIDATION := v_COLS(13);
        v_MARKET_INT_HEADER.EXTERNALVALIDATION := v_COLS(14);
        v_MARKET_INT_HEADER.MERGEFLAG := v_COLS(15);
        v_MARKET_INT_HEADER.DELETEFLAG := v_COLS(16);
        v_MARKET_INT_HEADER.VALFLAGE := v_COLS(17);
        v_MARKET_INT_HEADER.VALFLAGI := v_COLS(18);
        v_MARKET_INT_HEADER.VALFLAGO := v_COLS(19);
        v_MARKET_INT_HEADER.VALFLAGN := v_COLS(20);
        v_MARKET_INT_HEADER.TKWRITTENFLAG := v_COLS(21);
        v_MARKET_INT_HEADER.DCFLOW := v_COLS(22);
        v_MARKET_INT_HEADER.ACCEPTREJECTSTATUS := v_COLS(23);
        v_MARKET_INT_HEADER.TRANSLATIONTIME := v_COLS(24);
        v_MARKET_INT_HEADER.DESCRIPTOR := v_COLS(25);
        v_MARKET_INT_HEADER.TIMESTAMP := TRUNC(TO_DATE(v_COLS(26), 'mm/dd/yyyy hh24:mi:ss'));
        v_MARKET_INT_HEADER.COUNT := v_COLS(27);
        v_MARKET_INT_HEADER.TRANSACTION_DATE := TRUNC(TO_DATE(v_COLS(28), 'mm/dd/yyyy hh24:mi:ss'));
 		INSERT INTO ERCOT_MARKET_HEADER_WORK VALUES v_MARKET_INT_HEADER;
    	v_IDX := v_LINES.NEXT(v_IDX);
	END LOOP;

    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
      p_STATUS := SQLCODE;
      p_MESSAGE := 'Error in MEX_ERCOT_SETTLEMENT.PARSE_LOAD_EXTRACT_HEADER: ' || SQLERRM;
END PARSE_LOAD_EXTRACT_HEADER;
----------------------------------------------------------------------------------------------------
PROCEDURE PARSE_LOAD_EXTRACT_DATA
	(
    p_RESPONSE_CLOB IN CLOB,
    p_WORK_ID IN NUMBER,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
    ) IS
v_LINES PARSE_UTIL.BIG_STRING_TABLE_MP;
v_COLS PARSE_UTIL.STRING_TABLE;
v_IDX BINARY_INTEGER;
v_COLUMN BINARY_INTEGER;
v_MARKET_INT_DATA ERCOT_MARKET_DATA_WORK%ROWTYPE;
v_DATE DATE;
v_BEGIN_DATE DATE;
v_INTERVAL_SECS NUMBER;
BEGIN
	p_STATUS := MEX_UTIL.g_SUCCESS;
	PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_RESPONSE_CLOB, v_LINES);
	v_IDX := v_LINES.FIRST;

	WHILE v_LINES.EXISTS(v_IDX) LOOP
        PARSE_UTIL.PARSE_DELIMITED_STRING(v_LINES(v_IDX),',',v_COLS);
        v_COLUMN := 4;

        BEGIN
            SELECT H.SECONDS_PER_INTERVAL
            INTO v_INTERVAL_SECS
            FROM ERCOT_MARKET_HEADER_WORK H
            WHERE WORK_ID = p_WORK_ID
            AND H.INTERVAL_DATA_ID = v_COLS(1);
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                v_INTERVAL_SECS := 0;
        END;

        IF v_INTERVAL_SECS = 3600 THEN
            v_DATE := TRUNC(TO_DATE(v_COLS(3), 'mm/dd/yyyy hh24:mi:ss')) + 1/24;
            v_BEGIN_DATE := v_DATE;
            WHILE v_COLUMN < 28 LOOP
                v_MARKET_INT_DATA.WORK_ID := p_WORK_ID;
            	v_MARKET_INT_DATA.INTERVAL_DATA_ID := v_COLS(1);
                v_MARKET_INT_DATA.TRANSACTION_DATE := TRUNC(TO_DATE(v_COLS(2), 'mm/dd/yyyy hh24:mi:ss'));
            	v_MARKET_INT_DATA.TRADE_DATE := TO_CUT(v_DATE, MEX_ERCOT.g_ERCOT_TIME_ZONE);
                v_MARKET_INT_DATA.LOAD_AMOUNT := v_COLS(v_COLUMN);
                v_DATE := v_DATE + 1/24;
                v_COLUMN := v_COLUMN + 1;
                INSERT INTO ERCOT_MARKET_DATA_WORK VALUES v_MARKET_INT_DATA;
            END LOOP;
        ELSE   --v_INTERVAL_SECS = 900
            v_DATE := TRUNC(TO_DATE(v_COLS(3), 'mm/dd/yyyy hh24:mi:ss')) + 1/96;
            v_BEGIN_DATE := v_DATE;
            WHILE v_COLS.EXISTS(v_COLUMN) LOOP
                EXIT WHEN v_COLUMN > 99;
                v_MARKET_INT_DATA.WORK_ID := p_WORK_ID;
            	v_MARKET_INT_DATA.INTERVAL_DATA_ID := v_COLS(1);
                v_MARKET_INT_DATA.TRANSACTION_DATE := TRUNC(TO_DATE(v_COLS(2), 'mm/dd/yyyy hh24:mi:ss'));
            	v_MARKET_INT_DATA.TRADE_DATE := TO_CUT(v_DATE, MEX_ERCOT.g_ERCOT_TIME_ZONE);
                v_MARKET_INT_DATA.LOAD_AMOUNT := v_COLS(v_COLUMN);
                v_DATE := v_DATE + 1/96;
                v_COLUMN := v_COLUMN + 1;
                INSERT INTO ERCOT_MARKET_DATA_WORK VALUES v_MARKET_INT_DATA;
            END LOOP;
        END IF;

    	v_IDX := v_LINES.NEXT(v_IDX);
	END LOOP;

    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
      p_STATUS := SQLCODE;
      p_MESSAGE := 'Error in MEX_ERCOT_SETTLEMENT.PARSE_LOAD_EXTRACT_DATA: ' || SQLERRM;
END PARSE_LOAD_EXTRACT_DATA;
----------------------------------------------------------------------------------------------------
PROCEDURE FETCH_LOAD_EXTRACT
	(
	p_CRED IN mex_credentials,
    p_URL IN VARCHAR2,
    p_WORK_ID IN NUMBER,
	p_LOG_ONLY IN NUMBER,
    p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2,
	p_LOGGER IN OUT mm_logger_adapter
    ) IS
v_RESPONSE_XML XMLTYPE := NULL;
v_REQUEST_CLOB CLOB;
v_RESPONSE_CLOB CLOB;
v_HEADER_PARSED BOOLEAN := FALSE;
v_MKT_DATA_FILE VARCHAR2(512);
v_RESULT mex_result;

	CURSOR c_FILES(v_XML IN XMLTYPE) IS
	SELECT EXTRACTVALUE(VALUE(U),
							'//File',
							MEX_SWITCHBOARD.c_MEX_FILELIST_NAMESPACE_DEF) "FILENAME"
	FROM TABLE(XMLSEQUENCE(EXTRACT(v_XML,
									'//FileList',
									MEX_SWITCHBOARD.c_MEX_FILELIST_NAMESPACE_DEF))) T,
	TABLE(XMLSEQUENCE(EXTRACT(VALUE(T),
							'//File',
							MEX_SWITCHBOARD.c_MEX_FILELIST_NAMESPACE_DEF))) U;
BEGIN


    v_RESULT := Mex_Switchboard.FetchURL(p_URL_to_Fetch => p_URL,
										 p_Logger => p_LOGGER,
										 p_Cred => p_CRED,
										 p_Log_Only => p_LOG_ONLY);

	p_STATUS  := v_RESULT.STATUS_CODE;
    IF v_RESULT.STATUS_CODE <> MEX_Switchboard.c_Status_Success THEN
    	v_RESPONSE_CLOB := NULL;
    ELSE
    	v_RESPONSE_CLOB := v_RESULT.RESPONSE;
    END IF;

    IF p_STATUS = MEX_UTIL.g_SUCCESS THEN
        v_RESPONSE_XML :=  XMLTYPE.CREATEXML(v_RESPONSE_CLOB);
        FOR v_FILE IN c_FILES(v_RESPONSE_XML) LOOP
			-- send the request
			DBMS_LOB.CREATETEMPORARY(v_REQUEST_CLOB, TRUE);
			DBMS_LOB.CREATETEMPORARY(v_RESPONSE_CLOB, TRUE);
			-- only interested in certain files
			IF v_FILE.FILENAME LIKE '%-MARKET_INTERVAL_HEADER-%.csv' OR
                	v_FILE.FILENAME LIKE '%-MARKET_INTERVAL_DATA-%.csv' OR
                    v_FILE.FILENAME LIKE '%PUBLIC_MARKET_INTERVAL_HEADER-%.csv' OR
                    v_FILE.FILENAME LIKE '%PUBLIC_MARKET_INTERVAL_DATA-%.csv' THEN

				p_STATUS := GA.SUCCESS;
                -- the market_header file must be parsed before the market data file
                -- because information in the header file tells us if there are 24
                -- or 96 columns of data.
                IF v_FILE.FILENAME LIKE '%MARKET_INTERVAL_HEADER-%.csv' THEN
                    v_HEADER_PARSED := TRUE;


					v_RESULT := Mex_Switchboard.FetchFile(p_FilePath => v_FILE.FILENAME,
														 p_Logger => p_LOGGER,
														 p_Cred => p_CRED,
														 p_Log_Only => p_LOG_ONLY);


					p_STATUS  := v_RESULT.STATUS_CODE;
					IF v_RESULT.STATUS_CODE <> MEX_Switchboard.c_Status_Success THEN
						v_RESPONSE_CLOB := NULL;
					ELSE
						v_RESPONSE_CLOB := v_RESULT.RESPONSE;
					END IF;

					IF p_STATUS = MEX_UTIL.g_SUCCESS THEN
						PARSE_LOAD_EXTRACT_HEADER(v_RESPONSE_CLOB, p_WORK_ID, p_STATUS, p_MESSAGE);
						DBMS_LOB.FREETEMPORARY(v_REQUEST_CLOB);
						DBMS_LOB.FREETEMPORARY(v_RESPONSE_CLOB);
						--process the market data file if it is waiting
						IF v_MKT_DATA_FILE IS NOT NULL THEN
							-- send the request
							DBMS_LOB.CREATETEMPORARY(v_REQUEST_CLOB, TRUE);
							DBMS_LOB.CREATETEMPORARY(v_RESPONSE_CLOB, TRUE);

							v_RESULT := Mex_Switchboard.FetchFile(p_FilePath => v_MKT_DATA_FILE,
																 p_Logger => p_LOGGER,
																 p_Cred => p_CRED,
																 p_Log_Only => p_LOG_ONLY);


							p_STATUS  := v_RESULT.STATUS_CODE;
							IF v_RESULT.STATUS_CODE <> MEX_Switchboard.c_Status_Success THEN
								v_RESPONSE_CLOB := NULL;
							ELSE
								v_RESPONSE_CLOB := v_RESULT.RESPONSE;
							END IF;

							IF p_STATUS = MEX_UTIL.g_SUCCESS THEN
								PARSE_LOAD_EXTRACT_DATA(v_RESPONSE_CLOB, p_WORK_ID, p_STATUS, p_MESSAGE);
								DBMS_LOB.FREETEMPORARY(v_REQUEST_CLOB);
								DBMS_LOB.FREETEMPORARY(v_RESPONSE_CLOB);
								v_HEADER_PARSED := FALSE;
								v_MKT_DATA_FILE := NULL;
							END IF;
						END IF;
					END IF;
                ELSIF v_FILE.FILENAME LIKE '%MARKET_INTERVAL_DATA-%.csv' AND v_HEADER_PARSED = FALSE THEN
                    -- if this is the data file and the header file hasn't been processed, wait
                    v_MKT_DATA_FILE := v_FILE.FILENAME;

                END IF;
			END IF;
		END LOOP;
    END IF;

	--DBMS_LOB.FREETEMPORARY(v_RESPONSE_CLOB);

END FETCH_LOAD_EXTRACT;
----------------------------------------------------------------------------------------------------
PROCEDURE FETCH_LOAD_EXTRACT_PAGE
	(
	p_CRED IN mex_credentials,
	p_BEGIN_DATE IN DATE,
    p_END_DATE IN DATE,
	p_LOG_ONLY IN NUMBER,
    p_WORK_ID OUT NUMBER,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2,
	p_LOGGER IN OUT mm_logger_adapter
	) IS
v_RESPONSE_CLOB CLOB;
v_URL       VARCHAR2(255);
v_FILENAME  VARCHAR2(255);
v_DATE VARCHAR2(16);
v_LOC_BEGIN NUMBER;
v_LOC_END NUMBER;
v_DOC_ID VARCHAR2(32);
v_CURRENT_DATE DATE;
v_RESULT	   MEX_RESULT;
BEGIN

    p_STATUS  := MEX_UTIL.g_SUCCESS;
    --first return the Load Extract webpage source
    v_URL := GET_DICTIONARY_VALUE('LOAD EXTRACT PAGE URL', 0, 'MarketExchange', 'ERCOT', 'EXTRACT', '?');

    v_RESULT := Mex_Switchboard.FetchURL(p_URL_to_Fetch => v_URL,
										 p_Logger => p_LOGGER,
										 p_Cred => p_CRED,
										 p_Log_Only => p_LOG_ONLY);

	p_STATUS  := v_RESULT.STATUS_CODE;
    IF v_RESULT.STATUS_CODE <> MEX_Switchboard.c_Status_Success THEN
    	v_RESPONSE_CLOB := NULL;
    ELSE
    	v_RESPONSE_CLOB := v_RESULT.RESPONSE;
    END IF;

    IF p_STATUS = MEX_UTIL.g_SUCCESS THEN
      -- Loop through the incremented begin date till we reach the end date
		v_CURRENT_DATE := p_BEGIN_DATE;
			--GENERATE A WORK ID
		SELECT AID.NEXTVAL INTO p_WORK_ID FROM DUAL;
		WHILE v_CURRENT_DATE <= p_END_DATE
		LOOP
			--parse the response to find the file for the current date
			v_DATE := TO_CHAR(v_CURRENT_DATE,'MM-DD-YYYY');

			IF v_RESPONSE_CLOB IS NOT NULL THEN
				v_LOC_BEGIN := INSTR(v_RESPONSE_CLOB,'ext.(' || v_DATE);
				IF v_LOC_BEGIN = 0 THEN
					--LOG TO APP EVENT LOG THERE IS NO FILENAME FOR THIS DATE
					LOGS.LOG_WARN('There is no filename avaliable for ' || v_DATE || ' .');
				ELSE
					--v_LOC_BEGIN := INSTR(v_RESPONSE_CLOB, '<a href="/contentproxy/proxy?doc_id=',v_LOC_BEGIN - 55);
					v_LOC_BEGIN := INSTR(v_RESPONSE_CLOB, '<a href="https://pi.ercot.com/contentproxy/proxy?doc_id=',v_LOC_BEGIN - 70);
					v_LOC_END := INSTR(v_RESPONSE_CLOB, '</a>', v_LOC_BEGIN);
					v_FILENAME := SUBSTR(v_RESPONSE_CLOB, v_LOC_BEGIN, v_LOC_END-v_LOC_BEGIN+LENGTH('</a>'));
					v_LOC_BEGIN := INSTR(v_FILENAME,'proxy?doc_id=');
					v_LOC_END := INSTR(v_FILENAME,'"', v_LOC_BEGIN);
					v_DOC_ID := SUBSTR(v_FILENAME, v_LOC_BEGIN, v_LOC_END-v_LOC_BEGIN);
					v_URL := GET_DICTIONARY_VALUE('LOAD EXTRACT BASE URL', 0, 'MarketExchange', 'ERCOT', 'EXTRACT', '?') || v_DOC_ID;

					--now fetch the desired load response file
					FETCH_LOAD_EXTRACT(p_CRED,
										v_URL,
										p_WORK_ID,
										p_LOG_ONLY,
										p_STATUS,
										p_MESSAGE,
										p_LOGGER);
				END IF;
			END IF;
			v_CURRENT_DATE := v_CURRENT_DATE + 1;
		END LOOP;
    END IF;

	DBMS_LOB.FREETEMPORARY(v_RESPONSE_CLOB);

EXCEPTION
	WHEN OTHERS THEN
	p_STATUS  := SQLCODE;
	p_MESSAGE := 'Error in MEX_ERCOT_SETTLEMENT.FETCH_LOAD_EXTRACT_PAGE: ' || SQLERRM;
END FETCH_LOAD_EXTRACT_PAGE;
--------------------------------------------------------------------------------------------------
END MEX_ERCOT_EXTRACT;
/
