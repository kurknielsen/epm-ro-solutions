CREATE OR REPLACE PACKAGE WS_TIME_SERIES_IMPORT IS
-- $Revision: 1.3 $

FUNCTION WHAT_VERSION RETURN VARCHAR2;

PROCEDURE SCHEDULE_UPDATE
	(
	p_IDENTIFIED_BY         IN VARCHAR2 := NULL,
	p_TRANSACTION_IDENTS    IN STRING_COLLECTION,
	p_STATEMENT_TYPE_IDENTS IN STRING_COLLECTION,
	p_SCHEDULE_STATES       IN NUMBER_COLLECTION,
	p_SCHEDULE_DATES        IN DATE_COLLECTION_COLLECTION,
	p_SCHEDULE_AMOUNTS      IN NUMBER_COLLECTION_COLLECTION,
	p_SCHEDULE_PRICES       IN NUMBER_COLLECTION_COLLECTION := NULL
	);

PROCEDURE MARKET_PRICE_UPDATE
	(
	p_IDENTIFIED_BY       IN VARCHAR2 := NULL,
	p_MARKET_PRICE_IDENTS IN STRING_COLLECTION,
	p_PRICE_CODES         IN STRING_COLLECTION,
	p_DATES               IN DATE_COLLECTION_COLLECTION,
	p_PRICES              IN NUMBER_COLLECTION_COLLECTION,
	p_PRICE_BASIS         IN NUMBER_COLLECTION_COLLECTION := NULL
	);

PROCEDURE SCHEDULE_MANAGEMENT_IMPORT
	(
	p_SCHEDULE_IDS     IN STRING_COLLECTION,
	p_DATASOURCES      IN STRING_COLLECTION,
	p_SCHEDULE_DATES   IN DATE_COLLECTION_COLLECTION,
	p_SCHEDULE_AMOUNTS IN NUMBER_COLLECTION_COLLECTION,
	p_MESSAGE          OUT VARCHAR2
	);

END WS_TIME_SERIES_IMPORT;
/
CREATE OR REPLACE PACKAGE BODY WS_TIME_SERIES_IMPORT IS
--------------------------------------------------------------------------------
FUNCTION WHAT_VERSION RETURN VARCHAR2 IS
BEGIN
    RETURN '$Revision: 1.3 $';
END WHAT_VERSION;
---------------------------------------------------------------------------------------------------
PROCEDURE SCHEDULE_UPDATE
	(
	p_IDENTIFIED_BY         IN VARCHAR2 := NULL,
	p_TRANSACTION_IDENTS    IN STRING_COLLECTION,
	p_STATEMENT_TYPE_IDENTS IN STRING_COLLECTION,
	p_SCHEDULE_STATES       IN NUMBER_COLLECTION,
	p_SCHEDULE_DATES        IN DATE_COLLECTION_COLLECTION,
	p_SCHEDULE_AMOUNTS      IN NUMBER_COLLECTION_COLLECTION,
	p_SCHEDULE_PRICES       IN NUMBER_COLLECTION_COLLECTION := NULL
	) AS
	v_TRANSACTION_IDS    NUMBER_COLLECTION;
	v_STATEMENT_TYPE_IDS NUMBER_COLLECTION;
BEGIN
	v_TRANSACTION_IDS := EI.GET_IDS_FROM_WS_IDENTIFIERS(p_TRANSACTION_IDENTS, EC.ED_TRANSACTION, p_IDENTIFIED_BY);
	v_STATEMENT_TYPE_IDS := EI.GET_IDS_FROM_WS_IDENTIFIERS(p_STATEMENT_TYPE_IDENTS,
														   EC.ED_STATEMENT_TYPE,
														   p_IDENTIFIED_BY);
	ITJ.PUT_IT_SCHEDULES(v_TRANSACTION_IDS,
						 v_STATEMENT_TYPE_IDS,
						 p_SCHEDULE_STATES,
						 p_SCHEDULE_DATES,
						 p_SCHEDULE_AMOUNTS,
						 p_SCHEDULE_PRICES);
EXCEPTION
	WHEN OTHERS THEN
		ERRS.LOG_AND_RAISE();
END SCHEDULE_UPDATE;
--------------------------------------------------------------------------------
PROCEDURE MARKET_PRICE_UPDATE
	(
	p_IDENTIFIED_BY       IN VARCHAR2 := NULL,
	p_MARKET_PRICE_IDENTS IN STRING_COLLECTION,
	p_PRICE_CODES         IN STRING_COLLECTION,
	p_DATES               IN DATE_COLLECTION_COLLECTION,
	p_PRICES              IN NUMBER_COLLECTION_COLLECTION,
	p_PRICE_BASIS         IN NUMBER_COLLECTION_COLLECTION := NULL
	) AS
	v_MARKET_PRICE_IDS NUMBER_COLLECTION;
BEGIN
	v_MARKET_PRICE_IDS := EI.GET_IDS_FROM_WS_IDENTIFIERS(p_MARKET_PRICE_IDENTS, EC.ED_MARKET_PRICE, p_IDENTIFIED_BY);
	PR.PUT_MARKET_PRICE_VALUES(v_MARKET_PRICE_IDS, p_PRICE_CODES, p_DATES, p_PRICES, p_PRICE_BASIS);
EXCEPTION
	WHEN OTHERS THEN
		ERRS.LOG_AND_RAISE();
END MARKET_PRICE_UPDATE;
--------------------------------------------------------------------------------
PROCEDURE SCHEDULE_MANAGEMENT_IMPORT
	(
	p_SCHEDULE_IDS     IN STRING_COLLECTION,
	p_DATASOURCES      IN STRING_COLLECTION,
	p_SCHEDULE_DATES   IN DATE_COLLECTION_COLLECTION,
	p_SCHEDULE_AMOUNTS IN NUMBER_COLLECTION_COLLECTION,
	p_MESSAGE          OUT VARCHAR2
	) AS
BEGIN
	ITJ.SCHEDULE_MANAGEMENT_IMPORT(p_SCHEDULE_IDS, p_DATASOURCES, p_SCHEDULE_DATES, p_SCHEDULE_AMOUNTS, p_MESSAGE);
EXCEPTION
	WHEN OTHERS THEN
		ERRS.LOG_AND_RAISE();
END SCHEDULE_MANAGEMENT_IMPORT;
--------------------------------------------------------------------------------
END WS_TIME_SERIES_IMPORT;
/
