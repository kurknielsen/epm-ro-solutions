CREATE OR REPLACE PACKAGE WS_CSV_IMPORT IS
-- $Revision: 1.4 $

FUNCTION WHAT_VERSION RETURN VARCHAR2;

PROCEDURE TX_NETWORK_IMPORT
	(
	p_IMPORT_FILE IN CLOB,
	p_MESSAGE OUT VARCHAR2
	); 

PROCEDURE INTERVAL_METERED_USAGE_IMPORT
	(
	p_IMPORT_FILE IN CLOB,
	p_USE_EXTERNAL_IDENTIFIERS IN NUMBER,
	p_MESSAGE OUT VARCHAR2
	);
	
PROCEDURE NON_INTERVAL_METERED_USAGE_IMP
	(
	p_IMPORT_FILE IN CLOB,
	p_USE_EXTERNAL_IDENTIFIERS IN NUMBER,
	p_MESSAGE OUT VARCHAR2
	);
	
PROCEDURE WEATHER_IMPORT
	(
	p_IMPORT_FILE IN CLOB,
	p_MESSAGE OUT VARCHAR2
	);

PROCEDURE LOAD_PROFILE_IMPORT
	(
	p_IMPORT_FILE IN CLOB,
	p_MESSAGE OUT VARCHAR2
	);

PROCEDURE ACCOUNT_DATA_IMPORT
	(
	p_IMPORT_FILE IN CLOB,
	p_MESSAGE OUT VARCHAR2
	);

PROCEDURE MARKET_PRICES_IMPORT
	(
	p_IMPORT_FILE IN CLOB,
	p_MESSAGE OUT VARCHAR2
	);

END WS_CSV_IMPORT;
/
CREATE OR REPLACE PACKAGE BODY WS_CSV_IMPORT IS

c_WS_IMPORT_FILE_NAME VARCHAR2(32) := 'Web Services';
c_WS_IMPORT_FILE_DELIMITER CHAR(1) := ',';

-----------------------------------------------------------------------------
FUNCTION WHAT_VERSION RETURN VARCHAR2 IS
BEGIN
    RETURN '$Revision: 1.4 $';
END WHAT_VERSION;
---------------------------------------------------------------------------------------------------
PROCEDURE TX_NETWORK_IMPORT
	(
	p_IMPORT_FILE IN CLOB,
	p_MESSAGE OUT VARCHAR2
	) AS
	
	v_PROCESS_ID VARCHAR2(12);
	v_STATUS NUMBER(9);
	
BEGIN

	DATA_IMPORT.STANDARD_IMPORT(NULL, -- BEGIN DATE, END DATE HAVE NO EFFECT ON THIS IMPORT
                                NULL,
                                p_IMPORT_FILE,
								c_WS_IMPORT_FILE_NAME,
								DATA_IMPORT.TX_NETWORK_IMPORT_OPTION,
								',',
								c_WS_IMPORT_FILE_DELIMITER,
								v_STATUS,
								v_PROCESS_ID,
								p_MESSAGE);

END TX_NETWORK_IMPORT;
-----------------------------------------------------------------------------
PROCEDURE INTERVAL_METERED_USAGE_IMPORT
	(
	p_IMPORT_FILE IN CLOB,
	p_USE_EXTERNAL_IDENTIFIERS IN NUMBER,
	p_MESSAGE OUT VARCHAR2
	) AS
	
	v_PROCESS_ID VARCHAR2(12);
	v_STATUS NUMBER(9);
	
BEGIN

	DATA_IMPORT.STANDARD_IMPORT(NULL, -- BEGIN DATE, END DATE HAVE NO EFFECT ON THIS IMPORT
                                NULL,
                                p_IMPORT_FILE,
								c_WS_IMPORT_FILE_NAME,
								CASE WHEN p_USE_EXTERNAL_IDENTIFIERS = 1
									THEN DATA_IMPORT.INTVL_METERD_USAGE_DATA_EXT
									ELSE DATA_IMPORT.INTVL_METERD_USAGE_DATA END,
								',',
								c_WS_IMPORT_FILE_DELIMITER,
								v_STATUS,
								v_PROCESS_ID,
								p_MESSAGE);

END INTERVAL_METERED_USAGE_IMPORT;
-----------------------------------------------------------------------------
PROCEDURE NON_INTERVAL_METERED_USAGE_IMP
	(
	p_IMPORT_FILE IN CLOB,
	p_USE_EXTERNAL_IDENTIFIERS IN NUMBER,
	p_MESSAGE OUT VARCHAR2
	) AS
	
	v_PROCESS_ID VARCHAR2(12);
	v_STATUS NUMBER(9);
	
BEGIN

	DATA_IMPORT.STANDARD_IMPORT(NULL, -- BEGIN DATE, END DATE HAVE NO EFFECT ON THIS IMPORT
                                NULL,
                                p_IMPORT_FILE,
								c_WS_IMPORT_FILE_NAME,
								CASE WHEN p_USE_EXTERNAL_IDENTIFIERS = 1 
									THEN DATA_IMPORT.NON_INTVL_MTR_USG_DATA_EXT
									ELSE DATA_IMPORT.NON_INTVL_METERD_USAGE_DATA END,
								',',
								c_WS_IMPORT_FILE_DELIMITER,
								v_STATUS,
								v_PROCESS_ID,
								p_MESSAGE);

END NON_INTERVAL_METERED_USAGE_IMP;
-----------------------------------------------------------------------------
PROCEDURE WEATHER_IMPORT
	(
	p_IMPORT_FILE IN CLOB,
	p_MESSAGE OUT VARCHAR2
	) AS
	
	v_PROCESS_ID VARCHAR2(12);
	v_STATUS NUMBER(9);
	
BEGIN

	DATA_IMPORT.STANDARD_IMPORT(NULL, -- BEGIN DATE, END DATE HAVE NO EFFECT ON THIS IMPORT
                                NULL,
                                p_IMPORT_FILE,
								c_WS_IMPORT_FILE_NAME,
								DATA_IMPORT.WEATHER_DATA_IMPORT_OPTION,
								',',
								c_WS_IMPORT_FILE_DELIMITER,
								v_STATUS,
								v_PROCESS_ID,
								p_MESSAGE);

END WEATHER_IMPORT;
-----------------------------------------------------------------------------
PROCEDURE LOAD_PROFILE_IMPORT
	(
	p_IMPORT_FILE IN CLOB,
	p_MESSAGE OUT VARCHAR2
	) AS
	
	v_PROCESS_ID VARCHAR2(12);
	v_STATUS NUMBER(9);
	
BEGIN

	DATA_IMPORT.STANDARD_IMPORT(NULL, -- BEGIN DATE, END DATE HAVE NO EFFECT ON THIS IMPORT
                                NULL,
                                p_IMPORT_FILE,
								c_WS_IMPORT_FILE_NAME,
								DATA_IMPORT.LOAD_PROFILE_IMPORT_OPTION,
								',',
								c_WS_IMPORT_FILE_DELIMITER,
								v_STATUS,
								v_PROCESS_ID,
								p_MESSAGE);

END LOAD_PROFILE_IMPORT;
-----------------------------------------------------------------------------
PROCEDURE ACCOUNT_DATA_IMPORT
	(
	p_IMPORT_FILE IN CLOB,
	p_MESSAGE OUT VARCHAR2
	) AS
	
	v_PROCESS_ID VARCHAR2(12);
	v_STATUS NUMBER(9);
	
BEGIN

	DATA_IMPORT.STANDARD_IMPORT(NULL, -- BEGIN DATE, END DATE HAVE NO EFFECT ON THIS IMPORT
                                NULL,
                                p_IMPORT_FILE,
								c_WS_IMPORT_FILE_NAME,
								DATA_IMPORT.ACCOUNT_DATA_IMPORT_OPTION,
								',',
								c_WS_IMPORT_FILE_DELIMITER,
								v_STATUS,
								v_PROCESS_ID,
								p_MESSAGE);

END ACCOUNT_DATA_IMPORT;
-----------------------------------------------------------------------------
PROCEDURE MARKET_PRICES_IMPORT
	(
	p_IMPORT_FILE IN CLOB,
	p_MESSAGE OUT VARCHAR2
	) AS
	
	v_PROCESS_ID VARCHAR2(12);
	v_STATUS NUMBER(9);
	
BEGIN

	DATA_IMPORT.STANDARD_IMPORT(NULL, -- BEGIN DATE, END DATE HAVE NO EFFECT ON THIS IMPORT
                                NULL,
                                p_IMPORT_FILE,
								c_WS_IMPORT_FILE_NAME,
								DATA_IMPORT.MARKET_PRICE_IMPORT_OPTION,
								',',
								c_WS_IMPORT_FILE_DELIMITER,
								v_STATUS,
								v_PROCESS_ID,
								p_MESSAGE);

END MARKET_PRICES_IMPORT;
-----------------------------------------------------------------------------
END WS_CSV_IMPORT;
/