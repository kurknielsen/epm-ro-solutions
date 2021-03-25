CREATE OR REPLACE PACKAGE BODY MEX_ERCOT IS
-----------------------------------------------------------------------------------------------------------
FUNCTION WHAT_VERSION RETURN VARCHAR2 IS
BEGIN
    RETURN '$Revision: 1.1 $';
END WHAT_VERSION;
---------------------------------------------------------------------------------------------------
PROCEDURE PARSE_MKT_DATA(p_WORK_ID IN NUMBER,
                         p_CLOB IN CLOB,
						 p_STATUS        OUT NUMBER,
						 p_MESSAGE       OUT VARCHAR2) AS

	v_LINES             PARSE_UTIL.BIG_STRING_TABLE_MP;
	v_COLS              PARSE_UTIL.STRING_TABLE;
	v_IDX               BINARY_INTEGER;
	v_JDX               BINARY_INTEGER;
	v_MARKET_DATA       ERCOT_MARKET_DATA_WORK%ROWTYPE;
	v_TRADE_DATE        DATE;


BEGIN

	p_STATUS := MEX_UTIL.g_SUCCESS;

	/*--CLEAR OUT THE 'ERCOT_MARKET_DATA_WORK' TABLE
	TRUNCATE_TABLE('ERCOT_MARKET_DATA_WORK', p_STATUS, p_MESSAGE);*/


    PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_CLOB, v_LINES);
    v_IDX := v_LINES.FIRST;

    WHILE v_LINES.EXISTS(v_IDX) LOOP
		PARSE_UTIL.PARSE_DELIMITED_STRING(v_LINES(v_IDX),',',v_COLS);


        v_TRADE_DATE := TO_CUT(TRUNC(TO_DATE(v_COLS(3), 'MM/DD/YYYY HH24:MI:SS')),g_ERCOT_TIME_ZONE) + 1/96;

		v_JDX := 4;
      	WHILE v_COLS.EXISTS(v_JDX) LOOP
            EXIT WHEN v_JDX > 99;
    		v_MARKET_DATA.WORK_ID := p_WORK_ID;
    		v_MARKET_DATA.INTERVAL_DATA_ID := v_COLS(1);
        	v_MARKET_DATA.TRANSACTION_DATE := TRUNC(TO_DATE(V_COLS(2), 'MM/DD/YYYY HH24:MI:SS'));
        	v_MARKET_DATA.TRADE_DATE := v_TRADE_DATE;
            v_MARKET_DATA.LOAD_AMOUNT := v_COLS(v_JDX);

    		INSERT INTO ERCOT_MARKET_DATA_WORK VALUES v_MARKET_DATA;
    		--next quarter hour (there are 96 quarter hours in a single day)
            v_TRADE_DATE := v_TRADE_DATE + 1/96;
    		--value for the next quarter hour
            v_JDX := v_JDX + 1;
        END LOOP;

    	--next line
    	v_IDX := v_LINES.NEXT(v_IDX);
    END LOOP;
    COMMIT;


EXCEPTION
	WHEN OTHERS THEN
		p_STATUS  := SQLCODE;
		p_MESSAGE := 'Error in MEX_ERCOT.PARSE_MKT_DATA: ' || SQLERRM;
END PARSE_MKT_DATA;
-----------------------------------------------------------------------------------------------------
PROCEDURE PARSE_MKT_HEADER(p_WORK_ID IN NUMBER,
						   p_CLOB    IN CLOB,
						   p_STATUS  OUT NUMBER,
						   p_MESSAGE OUT VARCHAR2) AS

	v_LINES         PARSE_UTIL.BIG_STRING_TABLE_MP;
	v_COLS          PARSE_UTIL.STRING_TABLE;
	v_IDX           BINARY_INTEGER;
	v_MARKET_HEADER ERCOT_MARKET_HEADER_WORK%ROWTYPE;

BEGIN

	p_STATUS := MEX_UTIL.g_SUCCESS;

	/*--CLEAR OUT THE ERCOT_MARKET_HEADER_WORK TABLE
	TRUNCATE_TABLE('ERCOT_MARKET_HEADER_WORK', p_STATUS, p_MESSAGE);*/

    PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_CLOB, v_LINES);
    v_IDX := v_LINES.FIRST;

    WHILE v_LINES.EXISTS(v_IDX) LOOP
        PARSE_UTIL.PARSE_DELIMITED_STRING(v_LINES(v_IDX),',',v_COLS);

        v_MARKET_HEADER.WORK_ID          := p_WORK_ID;
        v_MARKET_HEADER.INTERVAL_DATA_ID := v_COLS(1);
        v_MARKET_HEADER.INTERVAL_ID      := v_COLS(2);
        v_MARKET_HEADER.RECORDER         := v_COLS(3);
        v_MARKET_HEADER.MARKET_INTERVAL  := v_COLS(4);
        --TO DO: apply TO_CUT to make it standard time
        v_MARKET_HEADER.START_TIME             := TO_CUT(TRUNC(TO_DATE(v_COLS(5),
        														   'MM/DD/YYYY HH24:MI:SS')),
        											 g_ERCOT_TIME_ZONE);
        v_MARKET_HEADER.STOP_TIME              := TO_CUT(TRUNC(TO_DATE(v_COLS(6),
        														   'MM/DD/YYYY HH24:MI:SS')),
        											 g_ERCOT_TIME_ZONE);
        v_MARKET_HEADER.SECONDS_PER_INTERVAL   := v_COLS(7);
        v_MARKET_HEADER.MEASUREMENT_UNITS_CODE := v_COLS(8);
        v_MARKET_HEADER.DSTPARTICIPANT         := V_COLS(9);
        v_MARKET_HEADER.TIMEZONE               := v_COLS(10);
        v_MARKET_HEADER.ORIGIN                 := v_COLS(11);
        v_MARKET_HEADER.EDITED                 := v_COLS(12);
        v_MARKET_HEADER.INTERNALVALIDATION     := v_COLS(13);
        v_MARKET_HEADER.EXTERNALVALIDATION     := v_COLS(14);
        v_MARKET_HEADER.MERGEFLAG              := v_COLS(15);
        v_MARKET_HEADER.DELETEFLAG             := v_COLS(16);
        v_MARKET_HEADER.VALFLAGE               := v_COLS(17);
        v_MARKET_HEADER.VALFLAGI               := v_COLS(18);
        v_MARKET_HEADER.VALFLAGO               := v_COLS(19);
        v_MARKET_HEADER.VALFLAGN               := v_COLS(20);
        v_MARKET_HEADER.TKWRITTENFLAG         := v_COLS(21);
        v_MARKET_HEADER.DCFLOW                 := v_COLS(22);
        v_MARKET_HEADER.ACCEPTREJECTSTATUS     := v_COLS(23);
        v_MARKET_HEADER.TRANSLATIONTIME        := v_COLS(24);
        v_MARKET_HEADER.DESCRIPTOR             := v_COLS(25);
        v_MARKET_HEADER.TIMESTAMP              := TRUNC(TO_DATE(v_COLS(26),
        													'MM/DD/YYYY HH24:MI:SS'));
        v_MARKET_HEADER.COUNT                  := v_COLS(27);
        v_MARKET_HEADER.TRANSACTION_DATE       := TRUNC(TO_DATE(v_COLS(28),
        													'MM/DD/YYYY HH24:MI:SS'));

        INSERT INTO ERCOT_MARKET_HEADER_WORK VALUES v_MARKET_HEADER;
        v_IDX := v_LINES.NEXT(v_IDX);
    END LOOP;

    COMMIT;


EXCEPTION
	WHEN OTHERS THEN
		p_STATUS  := SQLCODE;
		p_MESSAGE := 'Error in MEX_ERCOT.PARSE_MKT_HEADER: ' || SQLERRM;
END PARSE_MKT_HEADER;
----------------------------------------------------------------------------------------------------
END MEX_ERCOT;
/
