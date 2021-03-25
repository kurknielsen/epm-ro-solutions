CREATE OR REPLACE PACKAGE BODY MM_TDIE_UTIL IS

c_MSG_SENDER_CID CONSTANT VARCHAR2(512) := 'Sender CID must be one the 4 known values: '
				||  c_TDIE_TUOS_ROI_SENDER || ', '
				||  c_TDIE_TUOS_NI_SENDER || ', '
				||  c_TDIE_DUOS_ROI_SENDER || ', '
                ||  c_TDIE_UOS_SENDER
				||  c_TDIE_DUOS_NI_SENDER || '.';
c_MSG_SENDER_PSE CONSTANT VARCHAR2(512) := 'Sender PSE ID must be one the 4 known values: '
				||  c_TDIE_TUOS_ROI_SENDER_PSE_ID || '(' || TEXT_UTIL.TO_CHAR_ENTITY(c_TDIE_TUOS_ROI_SENDER_PSE_ID,EC.ED_PSE) || '), '
				||  c_TDIE_DUOS_ROI_SENDER_PSE_ID || '(' ||  TEXT_UTIL.TO_CHAR_ENTITY(c_TDIE_DUOS_ROI_SENDER_PSE_ID,EC.ED_PSE) || '), '
				||  c_TDIE_TUOS_NI_SENDER_PSE_ID || '(' ||  TEXT_UTIL.TO_CHAR_ENTITY(c_TDIE_TUOS_NI_SENDER_PSE_ID,EC.ED_PSE) || '), '
				||  c_TDIE_DUOS_NI_SENDER_PSE_ID || '(' ||  TEXT_UTIL.TO_CHAR_ENTITY(c_TDIE_DUOS_NI_SENDER_PSE_ID,EC.ED_PSE) || ').';

--------------------------------------------------------------------------------
FUNCTION WHAT_VERSION RETURN VARCHAR IS
BEGIN
   RETURN '$Revision: 1.3 $';
END WHAT_VERSION;
--------------------------------------------------------------------------------
FUNCTION GET_SEM_NET_DEMAND_TRANSACTION
	(
	p_SUPPLIER_UNIT IN VARCHAR2
	) RETURN NUMBER AS
BEGIN
	RETURN MM_SEM_UTIL.GET_TRANSACTION_ID('Net Demand', p_SUPPLIER_UNIT, TRUE,
                                              p_EXTERNAL_IDENTIFIER => 'NDLF:'||p_SUPPLIER_UNIT,
                                              p_IS_BID_OFFER => 0);
END GET_SEM_NET_DEMAND_TRANSACTION;
--------------------------------------------------------------------------------
FUNCTION CONVERT_UOM_CODE(p_UOM_CODE IN VARCHAR2) RETURN VARCHAR2 AS
v_UOM VARCHAR2(16);
BEGIN
	CASE p_UOM_CODE
		WHEN 'KWH' THEN
			v_UOM := 'KWH';
		WHEN 'KWT' THEN
			v_UOM := 'KW';
		WHEN 'K3' THEN
			v_UOM := 'KVARH';
		WHEN 'KVR' THEN
			v_UOM := 'KVAR';
		WHEN 'KVA' THEN
			v_UOM := 'KVA';
		WHEN 'MWH' THEN
			v_UOM := 'MWH';
		ELSE
			v_UOM := p_UOM_CODE;
	END CASE;
	RETURN v_UOM;
END CONVERT_UOM_CODE;
--------------------------------------------------------------------------------
FUNCTION JURISDICTION_FOR_SENDER_PSE(p_SENDER_PSE_ID NUMBER) RETURN VARCHAR2 AS
v_RESULT VARCHAR2(4);
BEGIN
	IF p_SENDER_PSE_ID = c_TDIE_TUOS_ROI_SENDER_PSE_ID OR p_SENDER_PSE_ID = c_TDIE_DUOS_ROI_SENDER_PSE_ID THEN
		v_RESULT := c_TDIE_JURISDICTION_ROI;
	ELSIF p_SENDER_PSE_ID = c_TDIE_DUOS_NI_SENDER_PSE_ID OR p_SENDER_PSE_ID = c_TDIE_TUOS_NI_SENDER_PSE_ID
        OR p_SENDER_PSE_ID = c_TDIE_UOS_SENDER_PSE_ID THEN
		v_RESULT := c_TDIE_JURISDICTION_NI;
	ELSE
		ERRS.RAISE_BAD_ARGUMENT('Sender PSE ID', p_SENDER_PSE_ID, c_MSG_SENDER_PSE);
	END IF;
	RETURN v_RESULT;
END JURISDICTION_FOR_SENDER_PSE;
--------------------------------------------------------------------------------
FUNCTION JURISDICTION_FOR_SENDER_CID(p_SENDER_CID VARCHAR2) RETURN VARCHAR2 AS
v_RESULT VARCHAR2(4);
BEGIN
	IF p_SENDER_CID = c_TDIE_TUOS_ROI_SENDER OR p_SENDER_CID = c_TDIE_DUOS_ROI_SENDER THEN
		v_RESULT := c_TDIE_JURISDICTION_ROI;
	ELSIF p_SENDER_CID = c_TDIE_UOS_SENDER OR p_SENDER_CID = c_TDIE_TUOS_NI_SENDER
        OR p_SENDER_CID = c_TDIE_DUOS_NI_SENDER THEN
		v_RESULT := c_TDIE_JURISDICTION_NI;
	ELSE
		ERRS.RAISE_BAD_ARGUMENT('Sender CID', p_SENDER_CID, c_MSG_SENDER_CID);
	END IF;
	RETURN v_RESULT;
END JURISDICTION_FOR_SENDER_CID;
--------------------------------------------------------------------------------
FUNCTION GET_TYPE_FOR_SENDER_CID(p_SENDER_CID VARCHAR2) RETURN VARCHAR2 AS
BEGIN
	IF SENDER_CID_IS_DUOS(p_SENDER_CID) THEN
		RETURN c_TDIE_EXTERNAL_TYPE_DUOS;
	ELSE
		RETURN c_TDIE_EXTERNAL_TYPE_TUOS;
	END IF;
END GET_TYPE_FOR_SENDER_CID;
--------------------------------------------------------------------------------
FUNCTION SENDER_CID_IS_TUOS(p_SENDER_CID VARCHAR2) RETURN BOOLEAN AS
BEGIN
	RETURN SENDER_PSE_IS_TUOS(GET_SENDER_PSE_ID(p_SENDER_CID));
END SENDER_CID_IS_TUOS;
--------------------------------------------------------------------------------
FUNCTION SENDER_CID_IS_DUOS(p_SENDER_CID VARCHAR2) RETURN BOOLEAN AS
BEGIN
	RETURN SENDER_PSE_IS_DUOS(GET_SENDER_PSE_ID(p_SENDER_CID));
END SENDER_CID_IS_DUOS;
--------------------------------------------------------------------------------
FUNCTION SENDER_PSE_IS_DUOS(p_SENDER_PSE_ID NUMBER) RETURN BOOLEAN AS
v_RESULT BOOLEAN;
BEGIN
	IF p_SENDER_PSE_ID = c_TDIE_DUOS_NI_SENDER_PSE_ID OR p_SENDER_PSE_ID = c_TDIE_DUOS_ROI_SENDER_PSE_ID
        OR p_SENDER_PSE_ID = c_TDIE_UOS_SENDER_PSE_ID THEN
		v_RESULT := TRUE;
	ELSIF p_SENDER_PSE_ID = c_TDIE_TUOS_ROI_SENDER_PSE_ID OR p_SENDER_PSE_ID = c_TDIE_TUOS_NI_SENDER_PSE_ID THEN
		v_RESULT := FALSE;
	ELSE
		ERRS.RAISE_BAD_ARGUMENT('Sender PSE ID', p_SENDER_PSE_ID, c_MSG_SENDER_PSE);
	END IF;
	RETURN v_RESULT;
END SENDER_PSE_IS_DUOS;
--------------------------------------------------------------------------------
FUNCTION SENDER_PSE_IS_TUOS(p_SENDER_PSE_ID NUMBER) RETURN BOOLEAN AS
BEGIN
	RETURN NOT SENDER_PSE_IS_DUOS(p_SENDER_PSE_ID);
END SENDER_PSE_IS_TUOS;
--------------------------------------------------------------------------------
FUNCTION GET_SENDER_PSE_ID(p_SENDER_CID VARCHAR2) RETURN NUMBER AS
v_SENDER_PSE_ID PSE.PSE_ID%TYPE;
BEGIN
	CASE p_SENDER_CID
		WHEN c_TDIE_TUOS_ROI_SENDER THEN
			v_SENDER_PSE_ID := c_TDIE_TUOS_ROI_SENDER_PSE_ID;
		WHEN c_TDIE_TUOS_NI_SENDER THEN
			v_SENDER_PSE_ID := c_TDIE_TUOS_NI_SENDER_PSE_ID;
		WHEN c_TDIE_DUOS_ROI_SENDER THEN
			v_SENDER_PSE_ID := c_TDIE_DUOS_ROI_SENDER_PSE_ID;
		WHEN c_TDIE_UOS_SENDER THEN
			v_SENDER_PSE_ID := c_TDIE_UOS_SENDER_PSE_ID;
        WHEN c_TDIE_DUOS_NI_SENDER THEN
            v_SENDER_PSE_ID := c_TDIE_DUOS_NI_SENDER_PSE_ID;
		ELSE
			ERRS.RAISE_BAD_ARGUMENT('Sender CID', p_SENDER_CID, c_MSG_SENDER_CID);
	END CASE;
	RETURN v_SENDER_PSE_ID;
END GET_SENDER_PSE_ID;
--------------------------------------------------------------------------------
FUNCTION GET_EDC_ID_FOR_JURISDICTION(p_JURISDICTION VARCHAR2) RETURN NUMBER AS
BEGIN
    IF p_JURISDICTION = c_TDIE_JURISDICTION_ROI THEN
        RETURN g_ESBN_EDC_ID;
    ELSIF p_JURISDICTION = c_TDIE_JURISDICTION_NI THEN
        RETURN g_NIE_EDC_ID;
    ELSE
        ERRS.RAISE_BAD_ARGUMENT('Jurisdiction',
					p_JURISDICTION,
					'The selected Jurisdiction was unrecognized.');
    END IF;
END GET_EDC_ID_FOR_JURISDICTION;
--------------------------------------------------------------------------------
FUNCTION VERIFY_STATIC_DATA_DURATION(p_COUNT IN PLS_INTEGER, p_EXPECTED IN PLS_INTEGER) RETURN BOOLEAN IS
BEGIN
	IF NVL(p_COUNT,0) = 0 THEN
		RETURN FALSE; -- relationship must be valid for at least one day
	ELSIF p_COUNT >= p_EXPECTED THEN
		RETURN TRUE; -- not sure how/why we would have too many...
	ELSIF p_COUNT < p_EXPECTED THEN
		RETURN p_EXPECTED - p_COUNT <= NVL(c_STATIC_DATA_DATE_THRESHOLD,0);
	END IF;
END VERIFY_STATIC_DATA_DURATION;
--------------------------------------------------------------------------------
FUNCTION GET_SUPPLY_UNIT_FOR_GENERATOR
	(
	p_GENERATOR_ID IN NUMBER,
	p_SCHEDULE_DATE IN DATE
	) RETURN NUMBER AS
v_OPER_DATE	DATE;
v_SU_ID		NUMBER(9);
BEGIN

	-- determine operating date for specified schedule date
	v_OPER_DATE := TRUNC( FROM_CUT(p_SCHEDULE_DATE, MM_SEM_UTIL.g_TZ)-1/86400 );

	BEGIN

		SELECT DISTINCT SU_SP_ID
		INTO v_SU_ID
		FROM TDIE_GEN_UNITS
		WHERE GEN_SP_ID = p_GENERATOR_ID
			AND v_OPER_DATE BETWEEN BEGIN_DATE AND NVL(END_DATE, CONSTANTS.HIGH_DATE);
	EXCEPTION
		WHEN TOO_MANY_ROWS THEN
			LOGS.LOG_ERROR('Generator Unit [' || EI.GET_ENTITY_NAME(EC.ED_SERVICE_POINT,p_GENERATOR_ID) || ']
			has more than one Supplier Unit assignment. Run the ''Check EARN ID to SU Mapping'' process for more details.');
			RETURN NULL;
	END;

	RETURN v_SU_ID;

EXCEPTION
	WHEN NO_DATA_FOUND THEN
		RETURN NULL;

END GET_SUPPLY_UNIT_FOR_GENERATOR;
----------------------------------------------------------------------------------------------------
FUNCTION VERIFY_SERVICE_LOCATION_METER
	(
	p_SERVICE_LOCATION_ID IN NUMBER,
	p_METER_ID IN NUMBER,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE
	) RETURN BOOLEAN IS
v_EXPECTED	PLS_INTEGER := p_END_DATE - p_BEGIN_DATE + 1;
v_COUNT		PLS_INTEGER;
BEGIN
	SELECT SUM(LEAST(NVL(A.END_DATE,CONSTANTS.HIGH_DATE),p_END_DATE)
					- GREATEST(A.BEGIN_DATE,p_BEGIN_DATE) + 1) -- total span of days
		INTO v_COUNT
		FROM SERVICE_LOCATION_METER A
		WHERE A.SERVICE_LOCATION_ID = p_SERVICE_LOCATION_ID
		  AND A.METER_ID = p_METER_ID
		  AND A.BEGIN_DATE <= p_END_DATE
		  AND NVL(A.END_DATE, CONSTANTS.HIGH_DATE) >= p_BEGIN_DATE;

	RETURN MM_TDIE_UTIL.VERIFY_STATIC_DATA_DURATION(v_COUNT,v_EXPECTED);
END VERIFY_SERVICE_LOCATION_METER;
----------------------------------------------------------------------------------------------------
FUNCTION VERIFY_SERVICE_LOCATION_METER
	(
	p_MPRN IN VARCHAR2,
	p_METER_ID IN NUMBER,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE
	) RETURN BOOLEAN IS
v_SERVICE_LOCATION_ID NUMBER(9);
BEGIN
	v_SERVICE_LOCATION_ID := EI.GET_ID_FROM_IDENTIFIER_EXTSYS(p_MPRN,
                                                              EC.ED_SERVICE_LOCATION,
                                                              EC.ES_TDIE,
                                                              EI.g_DEFAULT_IDENTIFIER_TYPE);

	RETURN VERIFY_SERVICE_LOCATION_METER(v_SERVICE_LOCATION_ID, p_METER_ID, p_BEGIN_DATE, p_END_DATE);
END VERIFY_SERVICE_LOCATION_METER;
----------------------------------------------------------------------------------------------------
FUNCTION GET_METER_ID_IMPL
	(
    p_SERVICE_LOCATION_ID IN NUMBER,
    p_SERIAL_NUMBER IN VARCHAR2,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE
	) RETURN NUMBER IS
	v_METER_ID NUMBER(9);
BEGIN

    -- PICK THE METER WHICH HAS THE GREATEST NUMBER OF DAYS ASSIGNMENT FOR THE DATE RANGE
    -- IF TWO TIE ON THAT CRITERIA, PICK THE ONE WITH THE EARLIER BEGIN DATE
	SELECT M.METER_ID
    INTO v_METER_ID
    FROM (SELECT SLM.METER_ID,
                MIN(SLM.BEGIN_DATE) AS MIN_BEGIN,
                SUM(LEAST(NVL(SLM.END_DATE, CONSTANTS.HIGH_DATE), p_END_DATE) -
                    GREATEST(SLM.BEGIN_DATE, p_BEGIN_DATE) + 1) AS NUM_DAYS
            FROM SERVICE_LOCATION_METER SLM
            WHERE SERVICE_LOCATION_ID = p_SERVICE_LOCATION_ID
                AND BEGIN_DATE <= p_END_DATE
                AND NVL(END_DATE, CONSTANTS.HIGH_DATE) >= p_BEGIN_DATE
                AND EI.GET_ENTITY_IDENTIFIER_EXTSYS(EC.ED_METER, METER_ID, EC.ES_TDIE) = p_SERIAL_NUMBER
            GROUP BY SLM.METER_ID
            ORDER BY NUM_DAYS DESC, MIN_BEGIN) M
    WHERE ROWNUM = 1;

	RETURN v_METER_ID;
END GET_METER_ID_IMPL;
----------------------------------------------------------------------------------------------------
FUNCTION GET_METER_ID
	(
    p_SERVICE_LOCATION_ID IN NUMBER,
    p_SERIAL_NUMBER IN VARCHAR2,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_TIMESLOT_CODE IN VARCHAR2 := NULL,
  	p_GENERATOR_UNITID IN VARCHAR2 := NULL
	) RETURN NUMBER IS

	v_METER_ID NUMBER(9);
	v_SERIAL_NUMBER EXTERNAL_SYSTEM_IDENTIFIER.EXTERNAL_IDENTIFIER%TYPE;

BEGIN

	IF p_TIMESLOT_CODE IS NOT NULL THEN
    	BEGIN
    		-- First, look for a Meter that is for a specific TIMESLOT_CODE
    		v_SERIAL_NUMBER := p_SERIAL_NUMBER || '-' || p_TIMESLOT_CODE;
        	v_METER_ID := GET_METER_ID_IMPL(p_SERVICE_LOCATION_ID,v_SERIAL_NUMBER,p_BEGIN_DATE,p_END_DATE);
    	EXCEPTION
    		WHEN NO_DATA_FOUND THEN
    			ERRS.LOG_AND_CONTINUE('Could not find Meter with Ext Id = ' || v_SERIAL_NUMBER, p_LOG_LEVEL => LOGS.c_LEVEL_DEBUG_MORE_DETAIL);
    	END;      
	END IF;
  
  IF p_GENERATOR_UNITID IS NOT NULL THEN
    	BEGIN
    		-- First, look for a Meter that is for a specific Generator UnitID
    		v_SERIAL_NUMBER := p_SERIAL_NUMBER || '-' || p_GENERATOR_UNITID;
        	v_METER_ID := GET_METER_ID_IMPL(p_SERVICE_LOCATION_ID,v_SERIAL_NUMBER,p_BEGIN_DATE,p_END_DATE);
    	EXCEPTION
    		WHEN NO_DATA_FOUND THEN
    			ERRS.LOG_AND_CONTINUE('Could not find Meter with Ext Id = ' || v_SERIAL_NUMBER, p_LOG_LEVEL => LOGS.c_LEVEL_DEBUG_MORE_DETAIL);
    	END;      
	END IF;

	IF v_METER_ID IS NULL THEN
		v_METER_ID := GET_METER_ID_IMPL(p_SERVICE_LOCATION_ID,p_SERIAL_NUMBER,p_BEGIN_DATE,p_END_DATE);
	END IF;

	RETURN v_METER_ID;
EXCEPTION
	WHEN NO_DATA_FOUND THEN
        ERRS.RAISE(MSGCODES.c_ERR_NO_SUCH_ENTRY,'No Meter was found for Identifier='
            || p_SERIAL_NUMBER || ' and Service Location='
            || TEXT_UTIL.TO_CHAR_ENTITY(p_SERVICE_LOCATION_ID, EC.ED_SERVICE_LOCATION)
			|| ' for dates '||TEXT_UTIL.TO_CHAR_DATE_RANGE(p_BEGIN_DATE, p_END_DATE));

END GET_METER_ID;
--------------------------------------------------------------------------------
FUNCTION GET_METER_ID
	(
    p_MPRN IN VARCHAR2,
    p_SERIAL_NUMBER IN VARCHAR2,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_TIMESLOT_CODE IN VARCHAR2,
  	p_GENERATOR_UNITID IN VARCHAR2 := NULL
	) RETURN NUMBER IS
v_SERVICE_LOCATION_ID NUMBER(9);
BEGIN

    v_SERVICE_LOCATION_ID := EI.GET_ID_FROM_IDENTIFIER_EXTSYS(p_MPRN,
                                                              EC.ED_SERVICE_LOCATION,
                                                              EC.ES_TDIE,
                                                              EI.g_DEFAULT_IDENTIFIER_TYPE);
    RETURN GET_METER_ID(v_SERVICE_LOCATION_ID, p_SERIAL_NUMBER, p_BEGIN_DATE, p_END_DATE, p_TIMESLOT_CODE, p_GENERATOR_UNITID);

END GET_METER_ID;
--------------------------------------------------------------------------------
-- Returns true if the specified message type code corresponds to a supported
-- QH/HH 3XX message type code (341 or 342)
FUNCTION IS_QH_HH_3XX_MESSAGE
	(
    p_MESSAGE_TYPE_CODE IN VARCHAR2
	) RETURN BOOLEAN IS
BEGIN
	RETURN p_MESSAGE_TYPE_CODE IN ('341','342','N341','N342');
END IS_QH_HH_3XX_MESSAGE;
--------------------------------------------------------------------------------
-- Returns true if the specified message type code corresponds to a supported
-- NQH/NHH 3XX message type code (300, 306, 307, 310, 320, 332, etc...)
FUNCTION IS_NQH_NHH_3XX_MESSAGE
	(
    p_MESSAGE_TYPE_CODE IN VARCHAR2
	) RETURN BOOLEAN IS
BEGIN
	RETURN p_MESSAGE_TYPE_CODE IN
		('300','300S','300W','305','306','306W','307','307W','310','310W','320','320W','332','332W',
		 'N300','N300S','N300W','N306','N307','N310','N320','N332');
END IS_NQH_NHH_3XX_MESSAGE;
--------------------------------------------------------------------------------
FUNCTION METER_EXISTS
	(
    p_SERVICE_LOCATION_ID IN NUMBER,
    p_SERIAL_NUMBER IN VARCHAR2
	) RETURN BOOLEAN IS
	v_COUNT  INTEGER;
BEGIN
    -- Check if there is even 1 METER_ID for the SERVICE_LOCATION and
	-- SERIAL_NUMBER by not including date-range. Fine, if meter is terminated.
	SELECT COUNT(*)
	INTO v_COUNT
    FROM SERVICE_LOCATION_METER SLM
    WHERE SERVICE_LOCATION_ID = p_SERVICE_LOCATION_ID
    AND EI.GET_ENTITY_IDENTIFIER_EXTSYS(EC.ED_METER, METER_ID, EC.ES_TDIE) = p_SERIAL_NUMBER;

	RETURN SYS.DIUTIL.INT_TO_BOOL(v_COUNT);
END METER_EXISTS;
--------------------------------------------------------------------------------
FUNCTION METER_EXISTS
	(
    p_MPRN IN VARCHAR2,
    p_SERIAL_NUMBER IN VARCHAR2
	) RETURN BOOLEAN IS
	v_SERVICE_LOCATION_ID SERVICE_LOCATION_METER.SERVICE_LOCATION_ID%TYPE;
BEGIN
     -- Get Service Location Id to pass it
     v_SERVICE_LOCATION_ID := EI.GET_ID_FROM_IDENTIFIER_EXTSYS(p_MPRN,
                                                              EC.ED_SERVICE_LOCATION,
                                                              EC.ES_TDIE,
                                                              EI.g_DEFAULT_IDENTIFIER_TYPE);

	RETURN METER_EXISTS(v_SERVICE_LOCATION_ID, p_SERIAL_NUMBER);
END METER_EXISTS;
--------------------------------------------------------------------------------
END MM_TDIE_UTIL;
/
