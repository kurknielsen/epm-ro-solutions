CREATE OR REPLACE PACKAGE DEMAND_RESPONSE_UTIL IS
-- $Revision: 1.14 $

c_PROGRAM_TYPE_DLC 				CONSTANT VARCHAR2(32) := 'Direct Load Control';
c_PROGRAM_TYPE_PK_TIME_REBATE 	CONSTANT VARCHAR2(32) := 'Peak Time Rebate';
c_PROGRAM_TYPE_CRIT_PRICING 	CONSTANT VARCHAR2(32) := 'TOU/Critical Peak Pricing';
c_PROGRAM_TYPE_RT_PRICING 		CONSTANT VARCHAR2(32) := 'Real Time Pricing';
c_PROGRAM_TYPE_ENVIR_EMISSION 	CONSTANT VARCHAR2(32) := 'Environmental/Emission';

c_PAYMENT_TYPE_ONE_TIME 		CONSTANT VARCHAR2(32) := 'One-Time Fixed';
c_PAYMENT_TYPE_PER_EVENT 		CONSTANT VARCHAR2(32) := 'Per Event';
c_PAYMENT_TYPE_ANNUAL 			CONSTANT VARCHAR2(32) := 'Annual';
c_PAYMENT_TYPE_MONTHLY 			CONSTANT VARCHAR2(32) := 'Monthly';
c_PAYMENT_TYPE_DAILY 			CONSTANT VARCHAR2(32) := 'Daily';
c_PAYMENT_TYPE_PER_EVENT_INTVL 	CONSTANT VARCHAR2(32) := 'Per Event Interval';

c_PAYMENT_TYPE_MONTHLY_LIMIT	CONSTANT VARCHAR2(32) := 'Monthly Limit';
c_PAYMENT_TYPE_PER_KWH			CONSTANT VARCHAR2(32) := 'Per KWh';
c_PAYMENT_TYPE_CPP_PREMIUM		CONSTANT VARCHAR2(32) := 'CPP Premium';

c_EVENT_STATUS_NEW   			CONSTANT VARCHAR2(16) := 'New';
c_EVENT_STATUS_CHANGED 			CONSTANT VARCHAR2(16) := 'Changed';
c_EVENT_STATUS_STARTED 			CONSTANT VARCHAR2(16) := 'Started';
c_EVENT_STATUS_SUBMITTED		CONSTANT VARCHAR2(16) := 'Submitted';
c_EVENT_STATUS_CONFIRMED		CONSTANT VARCHAR2(15) := 'Confirmed';
c_EVENT_STATUS_CANCELLED		CONSTANT VARCHAR2(16) := 'Cancelled';
c_EVENT_STATUS_SYSTEM_OVERRIDE	CONSTANT VARCHAR2(16) := 'System Override';
c_EVENT_STATUS_ENDED			CONSTANT VARCHAR2(16) := 'Ended';
c_EVENT_STATUS_RESUMED			CONSTANT VARCHAR2(16) := 'Resumed';

c_EXCEPTION_TYPE_FAILURE        CONSTANT VARCHAR2(32) := 'Failure';
c_EXCEPTION_TYPE_OPTOUT         CONSTANT VARCHAR2(32) := 'Opt Out';
c_EXCEPTION_TYPE_OVERRIDE       CONSTANT VARCHAR2(32) := 'Override';

c_LIMIT_TYPE_EXECUTION 			CONSTANT VARCHAR2(32) := 'Execution Limit';

FUNCTION WHAT_VERSION RETURN VARCHAR2;

-- Sends the DERMS data if the Event Dispatch Message URL is defined
-- and the Smart Grid External System is enabled.
-- Otherwise, just log the XML and raise an exception.
PROCEDURE SEND_DERMS_DISPATCH_MESSAGE
	(
	p_EVENT_ID IN NUMBER,
	p_CUT_BEGIN_DATE IN DATE,
	p_CUT_END_DATE IN DATE,
	p_SUCCESS_COUNT OUT BINARY_INTEGER,
	p_FAIL_COUNT OUT BINARY_INTEGER
	);

PROCEDURE SEND_OPENADR_MSG
	(
	p_EVENT_ID IN NUMBER,
	p_CUT_BEGIN_DATE IN DATE,
	p_CUT_END_DATE IN DATE,
    p_CURRENT_DATE IN DATE := SYSDATE, -- Used only for unit test
	p_SUCCESS_COUNT OUT BINARY_INTEGER,
	p_FAIL_COUNT OUT BINARY_INTEGER
	);

PROCEDURE SEND_DERMS_DISP_MSG_OPENADR
	(
	p_EVENT_ID IN NUMBER,
	p_CUT_BEGIN_DATE IN DATE,
	p_CUT_END_DATE IN DATE,
    p_CURRENT_DATE IN DATE := SYSDATE, -- Used only for unit test
	p_SUCCESS_COUNT OUT BINARY_INTEGER,
	p_FAIL_COUNT OUT BINARY_INTEGER
	);

PROCEDURE SEND_DERMS_PRICE_MSG_OPENADR
	(
	p_EVENT_ID IN NUMBER,
	p_CUT_BEGIN_DATE IN DATE,
	p_CUT_END_DATE IN DATE,
    p_CURRENT_DATE IN DATE := SYSDATE, -- Used only for unit test
	p_SUCCESS_COUNT OUT BINARY_INTEGER,
	p_FAIL_COUNT OUT BINARY_INTEGER
	);

PROCEDURE SEND_DERMS_CO2_MSG_OPENADR
	(
	p_EVENT_ID IN NUMBER,
	p_CUT_BEGIN_DATE IN DATE,
	p_CUT_END_DATE IN DATE,
    p_CURRENT_DATE IN DATE := SYSDATE, -- Used only for unit test
	p_SUCCESS_COUNT OUT BINARY_INTEGER,
	p_FAIL_COUNT OUT BINARY_INTEGER
	);  

-- Sends the DERMS Cancel if the Event Dispatch Message URL is defined
-- and the Smart Grid External System is enabled.
-- Otherwise, just log the XML and raise an exception.
PROCEDURE SEND_EVENT_CANCEL_MESSAGE
	(
	p_EVENT_ID IN NUMBER,
	p_SUCCESS_COUNT OUT BINARY_INTEGER,
	p_FAIL_COUNT OUT BINARY_INTEGER
	);


FUNCTION SEND_SMART_GRID_MESSAGE
	(
	p_ACTION IN VARCHAR2,
	p_CLOB IN CLOB
	) RETURN BOOLEAN;

FUNCTION GET_OPENADR_PYLD_ENTITY_ATTR
	(
	p_ATTRIBUTE_NAME IN VARCHAR,
	p_OWNER_ENTITY_ID IN NUMBER
	) RETURN VARCHAR2;
    
FUNCTION GET_OADR_CUT_DATE
    (
    p_OADR_DATE_STRING IN VARCHAR2,
    p_DURATION IN VARCHAR2
    ) RETURN DATE;
    
PROCEDURE OADR_POLL;
    
$if $$UNIT_TEST_MODE = 1 $then

PROCEDURE PARSE_UPDT_RPT_TO_WORK
	(
	p_SAFE_XML_TYPE IN XMLTYPE,
    p_INV_RID_COLL IN STRING_COLLECTION,
    p_WORK_ID OUT NUMBER
	);
    
PROCEDURE VAL_UPDT_RPT_FOR_IMPORT
    (
    p_SAFE_XML_TYPE IN XMLTYPE,
    p_RESPONSE_CODE OUT NUMBER,
    p_INV_RID_COLL OUT STRING_COLLECTION,
    p_REQUEST_ID OUT VARCHAR2,
    p_VEN_ID OUT VARCHAR2
    );
    
PROCEDURE UPDATE_SERVICE_LOAD
    (
    p_WORK_ID IN NUMBER
    );

$end

END DEMAND_RESPONSE_UTIL;
/
CREATE OR REPLACE PACKAGE BODY DEMAND_RESPONSE_UTIL IS
-------------------------------------------------------------------------------------------
c_ENTITY_IDENT_NAME CONSTANT VARCHAR2(32) := 'NAME';
c_ENTITY_IDENT_ALIAS CONSTANT VARCHAR2(32) := 'ALIAS';
c_ENTITY_IDENT_EXT_IDENT CONSTANT VARCHAR2(32) := 'EXTERNAL IDENTIFIER';
c_ACTION_SEND_DISP_SCHED CONSTANT VARCHAR2(32) := 'send.schedule';
c_ACTION_CANCEL_EVENT CONSTANT VARCHAR2(32) := 'send.cancellation';
c_MARKET_SMART_GRID CONSTANT VARCHAR2(32) := 'smartgrid';
c_SMARTGRID_NAMESPACE CONSTANT VARCHAR2(32) := 'http://services.gridpoint.com/';

c_OPENADR_EMIX_NAMESPACE CONSTANT VARCHAR2(128) := 'http://docs.oasis-open.org/ns/emix/2011/06';
c_OPENADR_POWER_NAMESPACE CONSTANT VARCHAR2(128) := 'http://docs.oasis-open.org/ns/emix/2011/06/power';
c_OPENADR_SCALE_NAMESPACE CONSTANT VARCHAR2(128) := 'http://docs.oasis-open.org/ns/emix/2011/06/siscale';
c_OPENADR_EI_NAMESPACE CONSTANT VARCHAR2(128) := 'http://docs.oasis-open.org/ns/energyinterop/201110';
c_OPENADR_PYLD_NAMESPACE CONSTANT VARCHAR2(128) := 'http://docs.oasis-open.org/ns/energyinterop/201110/payloads';
c_OPENADR_OADR_NAMESPACE CONSTANT VARCHAR2(128) := 'http://openadr.org/oadr-2.0b/2012/07';
c_OPENADR_N2_NAMESPACE CONSTANT VARCHAR2(128) := 'http://www.altova.com/samplexml/other-namespace';
c_OPENADR_GML_NAMESPACE CONSTANT VARCHAR2(128) := 'http://www.opengis.net/gml/3.2';
c_OPENADR_DS_NAMESPACE CONSTANT VARCHAR2(128) := 'http://www.w3.org/2000/09/xmldsig#';
c_OPENADR_XSI_NAMESPACE CONSTANT VARCHAR2(128) := 'http://www.w3.org/2001/XMLSchema-instance';
c_OPENADR_ATOM_NAMESPACE CONSTANT VARCHAR2(128) := 'http://www.w3.org/2005/Atom';
c_OPENADR_XCAL_NAMESPACE CONSTANT VARCHAR2(128) := 'urn:ietf:params:xml:ns:icalendar-2.0';
c_OPENADR_STRM_NAMESPACE CONSTANT VARCHAR2(128) := 'urn:ietf:params:xml:ns:icalendar-2.0:stream';

c_OPENADR_NAMESPACES CONSTANT VARCHAR2(4000) := 'xmlns:emix="http://docs.oasis-open.org/ns/emix/2011/06" xmlns:power="http://docs.oasis-open.org/ns/emix/2011/06/power" xmlns:scale="http://docs.oasis-open.org/ns/emix/2011/06/siscale" xmlns:ei="http://docs.oasis-open.org/ns/energyinterop/201110" xmlns:pyld="http://docs.oasis-open.org/ns/energyinterop/201110/payloads" xmlns:oadr="http://openadr.org/oadr-2.0b/2012/07" xmlns:n2="http://www.altova.com/samplexml/other-namespace" xmlns:gml="http://www.opengis.net/gml/3.2" xmlns:ds="http://www.w3.org/2000/09/xmldsig#" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:atom="http://www.w3.org/2005/Atom" xmlns:xcal="urn:ietf:params:xml:ns:icalendar-2.0" xmlns:strm="urn:ietf:params:xml:ns:icalendar-2.0:stream"';

c_OADR_POLL_PAYLOAD CONSTANT VARCHAR2(4000) := 
    '<?xml version="1.0" encoding="UTF-8"?>
    <oadr:oadrPayload xmlns:emix="http://docs.oasis-open.org/ns/emix/2011/06" xmlns:power="http://docs.oasis-open.org/ns/emix/2011/06/power" xmlns:scale="http://docs.oasis-open.org/ns/emix/2011/06/siscale" xmlns:ei="http://docs.oasis-open.org/ns/energyinterop/201110" xmlns:pyld="http://docs.oasis-open.org/ns/energyinterop/201110/payloads" xmlns:oadr="http://openadr.org/oadr-2.0b/2012/07" xmlns:n2="http://www.altova.com/samplexml/other-namespace" xmlns:gml="http://www.opengis.net/gml/3.2" xmlns:ds="http://www.w3.org/2000/09/xmldsig#" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:atom="http://www.w3.org/2005/Atom" xmlns:xcal="urn:ietf:params:xml:ns:icalendar-2.0" xmlns:strm="urn:ietf:params:xml:ns:icalendar-2.0:stream" xsi:schemaLocation="http://openadr.org/oadr-2.0b/2012/07 file:///C:/Jia/Product%20Management/Business%20Strategy/OpenADR/Alliance%20OpenADR%202.0%20Profiling/Profile%20B/Profile_B_Schema_20130701/oadr_20b.xsd">
        <oadr:oadrSignedObject>
            <oadr:oadrPoll ei:schemaVersion="2.0b">
                <ei:venID>VEN_Ventyx_DRMS</ei:venID>
            </oadr:oadrPoll>
        </oadr:oadrSignedObject>
    </oadr:oadrPayload>';
    
c_OADR_UPDTD_RPT_PAYLOAD_TPL CONSTANT VARCHAR2(4000) :=
    '<?xml version="1.0" encoding="UTF-8"?>
    <oadr:oadrUpdatedReport xmlns:ei="http://docs.oasis-open.org/ns/energyinterop/201110" xmlns:pyld="http://docs.oasis-open.org/ns/energyinterop/201110/payloads" xmlns:oadr="http://openadr.org/oadr-2.0b/2012/07" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://openadr.org/oadr-2.0b/2012/07">
        <ei:eiResponse>
            <ei:responseCode>%responseCode%</ei:responseCode>
            <ei:responseDescription>%responseDescription%</ei:responseDescription>
            <pyld:requestID>%requestID%</pyld:requestID>
        </ei:eiResponse>
        <ei:venID>%venID%</ei:venID>
    </oadr:oadrUpdatedReport>';
    
c_OADR_RESP_OK CONSTANT NUMBER := 200;
c_OADR_RESP_MET_NOT_EXIST CONSTANT NUMBER := 464;
c_OADR_RESP_REP_NOT_SUPPT CONSTANT NUMBER := 465;
-------------------------------------------------------------------------------------------
FUNCTION WHAT_VERSION RETURN VARCHAR2 IS
BEGIN
    RETURN '$Revision: 1.14 $';
END WHAT_VERSION;
---------------------------------------------------------------------------------------------------
FUNCTION SEND_SMART_GRID_MESSAGE
	(
	p_ACTION IN VARCHAR2,
	p_CLOB IN CLOB
	) RETURN BOOLEAN
AS
BEGIN
	MEX_UTIL.SEND_MESSAGE(p_MARKET => c_MARKET_SMART_GRID,
					 	p_ACTION => p_ACTION,
					 	p_EXTERNAL_SYSTEM_ID => EC.ES_SMART_GRID ,
						p_EXTERNAL_ACCOUNT_NAME => NULL,
					 	p_REQUEST_CLOB => p_CLOB);
	RETURN TRUE;

EXCEPTION
	WHEN MSGCODES.e_ERR_MEX_SEND_MESSAGE THEN
		ERRS.LOG_AND_CONTINUE;
		RETURN FALSE;

END SEND_SMART_GRID_MESSAGE;
-------------------------------------------------------------------------------------------
FUNCTION SEND_SMART_GRID_MSG_OPENADR
    (
    p_CLOB IN CLOB
    ) RETURN BOOLEAN
AS
    v_MEX_RESULT MEX_RESULT;
    v_URL_TO_FETCH SYSTEM_DICTIONARY.VALUE%TYPE;
    v_LOGGER MM_LOGGER_ADAPTER;
    v_CREDENTIALS MEX_CREDENTIALS;
    v_START_INDEX NUMBER;
    v_END_INDEX NUMBER;
    v_RESPONSE_CODE VARCHAR2(32);
    v_RESPONSE_DESCRIPTION VARCHAR2(4000);
BEGIN

    v_URL_TO_FETCH := GET_DICTIONARY_VALUE('End Point URL', 0, 'Load Management', 'Demand Response', 'Event Dispatch Message');
    
    IF v_URL_TO_FETCH IS NULL THEN
        RETURN FALSE;
    END IF;
    
	MEX_SWITCHBOARD.INIT_MEX(p_EXTERNAL_SYSTEM_ID => EC.ES_SMART_GRID,
			         	     p_EXTERNAL_ACCOUNT_NAME => NULL,
			         	     p_PROCESS_NAME => 'SEND_SMART_GRID_MSG_OPENADR',
			         	     p_EXCHANGE_NAME => 'SEND_SMART_GRID_MSG_OPENADR',
			         	     p_LOG_TYPE => MEX_SWITCHBOARD.g_LOG_ALL,
			         	     p_TRACE_ON => 0,
			         	     p_CREDENTIALS => v_CREDENTIALS,
			         	     p_LOGGER => v_LOGGER
                             );
                     
    
    v_MEX_RESULT := MEX_SWITCHBOARD.FETCHURL(p_URL_TO_FETCH => v_URL_TO_FETCH,
                                             p_LOGGER => v_LOGGER,
                                             p_CRED => v_CREDENTIALS,
                                             p_REQUEST_CONTENTTYPE => 'application/xml',
                                             p_REQUEST => p_CLOB
                                             );
                                             
    IF v_MEX_RESULT.STATUS_CODE <> 0 THEN
        RETURN FALSE;
    END IF;
    
    v_START_INDEX := INSTR(v_MEX_RESULT.RESPONSE, 'responseCode') + 13;
    v_END_INDEX := INSTR(v_MEX_RESULT.RESPONSE, '<', v_START_INDEX);
    v_RESPONSE_CODE := SUBSTR(v_MEX_RESULT.RESPONSE, v_START_INDEX, v_END_INDEX - v_START_INDEX);      
    IF v_RESPONSE_CODE <> '200' THEN
        v_START_INDEX := INSTR(v_MEX_RESULT.RESPONSE, 'responseDescription') + 20;
        v_END_INDEX := INSTR(v_MEX_RESULT.RESPONSE, '<', v_START_INDEX);
        v_RESPONSE_DESCRIPTION := SUBSTR(v_MEX_RESULT.RESPONSE, v_START_INDEX, v_END_INDEX - v_START_INDEX);
  
        v_LOGGER.LOG_ERROR('responseCode=' || v_RESPONSE_CODE || ', responseDescription=' || v_RESPONSE_DESCRIPTION);
        RETURN FALSE;
    END IF;
    
    RETURN TRUE;
                                       
END SEND_SMART_GRID_MSG_OPENADR;
-------------------------------------------------------------------------------------------
PROCEDURE SEND_DERMS_DISPATCH_MESSAGE
    (
    p_EVENT_ID IN NUMBER,
    p_CUT_BEGIN_DATE IN DATE,
    p_CUT_END_DATE IN DATE,
    p_SUCCESS_COUNT OUT BINARY_INTEGER,
    p_FAIL_COUNT OUT BINARY_INTEGER
    ) AS

v_RESULT XMLTYPE;
v_TIME_ZONE SERVICE_ZONE.TIME_ZONE%TYPE;
v_ENTITY_IDENTIFIER VARCHAR2(16);
v_PROGRAM_INTERVAL VARCHAR2(32);
v_EVENT_NAME DR_EVENT.EVENT_NAME%TYPE;
v_PROGRAM_NAME PROGRAM.PROGRAM_NAME%TYPE;
v_PROGRAM_ID PROGRAM.PROGRAM_ID%TYPE;
v_PROGRAM_ALIAS PROGRAM.PROGRAM_ALIAS%TYPE;
v_PROGRAM_EXT_IDENT PROGRAM.EXTERNAL_IDENTIFIER%TYPE;
v_EXT_SYSTEM_ID NUMBER(9);

v_SENT BOOLEAN := FALSE;

BEGIN
    -- Reset counters
    p_SUCCESS_COUNT := 0;
    p_FAIL_COUNT := 0;

    -- Get the Program Interval
    SELECT E.EVENT_NAME, P.PROGRAM_NAME, NVL(GET_INTERVAL_ABBREVIATION(P.PROGRAM_INTERVAL), DATE_UTIL.c_ABBR_HOUR),
        P.PROGRAM_ID, P.PROGRAM_ALIAS, P.EXTERNAL_IDENTIFIER
    INTO v_EVENT_NAME, v_PROGRAM_NAME, v_PROGRAM_INTERVAL,
        v_PROGRAM_ID, v_PROGRAM_ALIAS, v_PROGRAM_EXT_IDENT
    FROM DR_EVENT E, VPP V, PROGRAM P
    WHERE E.EVENT_ID = p_EVENT_ID
        AND E.VPP_ID = V.VPP_ID
        AND P.PROGRAM_ID = V.PROGRAM_ID;

    -- Get Entity Identifier from the System Settings
    v_ENTITY_IDENTIFIER := UPPER(GET_DICTIONARY_VALUE('Entity Identifier', 0, 'Load Management', 'Demand Response', 'Event Dispatch Message'));

    -- Get the External System ID
    IF v_ENTITY_IDENTIFIER NOT IN (c_ENTITY_IDENT_NAME,
        c_ENTITY_IDENT_ALIAS, c_ENTITY_IDENT_EXT_IDENT) THEN
        BEGIN
            SELECT E.EXTERNAL_SYSTEM_ID
            INTO v_EXT_SYSTEM_ID
            FROM EXTERNAL_SYSTEM E
            WHERE E.EXTERNAL_SYSTEM_NAME = v_ENTITY_IDENTIFIER;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                v_EXT_SYSTEM_ID := NULL;
        END;
    END IF;

    FOR v_REC IN (SELECT DISTINCT ES.EXTERNAL_SYSTEM_ID, ES.EXTERNAL_SYSTEM_NAME,
                                E.START_TIME, E.STOP_TIME
                    FROM DER_SEGMENT_RESULT R,
                        DR_EVENT E,
                        VIRTUAL_POWER_PLANT VPP,
                        EXTERNAL_SYSTEM ES
                    WHERE R.IS_EXTERNAL = 0
                        AND R.SERVICE_CODE = 'D'
                        AND E.EVENT_ID = p_EVENT_ID
                        AND E.VPP_ID = VPP.VPP_ID
                        AND R.PROGRAM_ID = VPP.PROGRAM_ID
                        AND R.SERVICE_ZONE_ID = VPP.SERVICE_ZONE_ID
                        AND ES.EXTERNAL_SYSTEM_ID = R.EXTERNAL_SYSTEM_ID
                        AND EXISTS (SELECT 1
                                    FROM DER_SEGMENT_RESULT_DATA D
                                    WHERE D.DER_SEGMENT_RESULT_ID = R.DER_SEGMENT_RESULT_ID
                                        AND D.RESULT_DATE BETWEEN p_CUT_BEGIN_DATE AND p_CUT_END_DATE)) LOOP

        v_SENT := TRUE;

        SELECT XMLELEMENT("sg:CreateEvent", XMLATTRIBUTES(c_SMARTGRID_NAMESPACE AS "xmlns:sg"),
                XMLELEMENT("sg:schedule",
                    XMLELEMENT("sg:eventIdent", v_EVENT_NAME),
                    XMLELEMENT("sg:externalSystemIdent", v_REC.EXTERNAL_SYSTEM_NAME),
                    XMLELEMENT("sg:identifiedBy", NULL),
                    XMLELEMENT("sg:programIdent", (CASE WHEN v_ENTITY_IDENTIFIER = c_ENTITY_IDENT_NAME THEN v_PROGRAM_NAME
                                                    WHEN v_ENTITY_IDENTIFIER = c_ENTITY_IDENT_ALIAS THEN NVL(v_PROGRAM_ALIAS, v_PROGRAM_NAME)
                                                    WHEN v_ENTITY_IDENTIFIER = c_ENTITY_IDENT_EXT_IDENT THEN NVL(v_PROGRAM_EXT_IDENT, v_PROGRAM_NAME)
                                                    ELSE NVL(EI.GET_ENTITY_IDENTIFIER_EXTSYS(EC.ED_PROGRAM, v_PROGRAM_ID, v_EXT_SYSTEM_ID), v_PROGRAM_NAME)
                                                    END)),
                    XMLELEMENT("sg:sections",
                        XMLAGG(
                            XMLELEMENT("sg:sectionSchedule",
                                XMLELEMENT("sg:participantCount",
                                                                 (SELECT MAX(D.DER_COUNT)
                                                                    FROM DER_SEGMENT_RESULT_DATA D
                                                                    WHERE D.DER_SEGMENT_RESULT_ID = R.DER_SEGMENT_RESULT_ID
                                                                        AND D.RESULT_DATE BETWEEN p_CUT_BEGIN_DATE AND p_CUT_END_DATE)),
                                XMLELEMENT("sg:schedule",
                                    (SELECT XMLAGG(
                                                XMLELEMENT("sg:scheduleItem",
                                                    XMLELEMENT("sg:amount",
                                                        (D.LOAD_VAL + D.FAILURE_VAL + D.OPT_OUT_VAL + D.OVERRIDE_VAL)
                                                        * DATE_UTIL.GET_INTERVAL_DIVISOR('HH',v_PROGRAM_INTERVAL,D.RESULT_DATE, v_TIME_ZONE)
                                                    ),
                                                    XMLELEMENT("sg:dateTime",
                                                        DATE_UTIL.TO_CHAR_ISO_AS_GMT(D.RESULT_DATE))
                                                    )
                                                )
                                    FROM DER_SEGMENT_RESULT_DATA D
                                    WHERE D.DER_SEGMENT_RESULT_ID = R.DER_SEGMENT_RESULT_ID
                                        AND D.RESULT_DATE BETWEEN p_CUT_BEGIN_DATE AND p_CUT_END_DATE)
                                ),
                                XMLELEMENT("sg:sectionIdent", (CASE WHEN v_ENTITY_IDENTIFIER = c_ENTITY_IDENT_NAME THEN FS.FEEDER_SEGMENT_NAME
                                                                    WHEN v_ENTITY_IDENTIFIER = c_ENTITY_IDENT_ALIAS THEN NVL(FS.FEEDER_SEGMENT_ALIAS, FS.FEEDER_SEGMENT_NAME)
                                                                    WHEN v_ENTITY_IDENTIFIER = c_ENTITY_IDENT_EXT_IDENT THEN NVL(FS.EXTERNAL_IDENTIFIER, FS.FEEDER_SEGMENT_NAME)
                                                                    ELSE NVL(EI.GET_ENTITY_IDENTIFIER_EXTSYS(EC.ED_TX_FEEDER_SEGMENT, R.FEEDER_SEGMENT_ID, v_EXT_SYSTEM_ID), FS.FEEDER_SEGMENT_NAME)
                                                                END))
                            )
                        )
                    ),
                    XMLELEMENT("sg:startTime", DATE_UTIL.TO_CHAR_ISO_AS_GMT(v_REC.START_TIME)),
                    XMLELEMENT("sg:stopTime", DATE_UTIL.TO_CHAR_ISO_AS_GMT(v_REC.STOP_TIME))
					--ORDER BY ES.EXTERNAL_SYSTEM_NAME
				)
			)
		INTO v_RESULT
		FROM DER_SEGMENT_RESULT R,
			DR_EVENT E,
			VIRTUAL_POWER_PLANT VPP,
			TX_FEEDER_SEGMENT FS,
			EXTERNAL_SYSTEM ES
		WHERE R.IS_EXTERNAL = 0
			AND R.SERVICE_CODE = 'D'
			AND E.EVENT_ID = p_EVENT_ID
			AND E.VPP_ID = VPP.VPP_ID
			AND R.PROGRAM_ID = VPP.PROGRAM_ID
			AND FS.FEEDER_SEGMENT_ID = R.FEEDER_SEGMENT_ID
			AND ES.EXTERNAL_SYSTEM_ID = R.EXTERNAL_SYSTEM_ID
			AND R.EXTERNAL_SYSTEM_ID = v_REC.EXTERNAL_SYSTEM_ID
			AND EXISTS (SELECT 1
						FROM DER_SEGMENT_RESULT_DATA D
						WHERE D.DER_SEGMENT_RESULT_ID = R.DER_SEGMENT_RESULT_ID
							AND D.RESULT_DATE BETWEEN p_CUT_BEGIN_DATE AND p_CUT_END_DATE);

		-- SEND ONE MESSAGE FOR EACH EXTERNAL SYSTEM
		IF SEND_SMART_GRID_MESSAGE(c_ACTION_SEND_DISP_SCHED, v_RESULT.GETCLOBVAL()) THEN
			p_SUCCESS_COUNT := p_SUCCESS_COUNT+1;
		ELSE
			p_FAIL_COUNT := p_FAIL_COUNT+1;
		END IF;

	END LOOP;

	IF NOT v_SENT THEN
		LOGS.LOG_WARN('There are no dispatch data for '||
						TEXT_UTIL.TO_CHAR_ENTITY(p_EVENT_ID, EC.ED_DR_EVENT, TRUE)||
						' in the given date range: '||TEXT_UTIL.TO_CHAR_TIME(p_CUT_BEGIN_DATE)||' -> '||TEXT_UTIL.TO_CHAR_TIME(p_CUT_END_DATE)||
						'. No dispatch messages sent.');
	END IF;

END SEND_DERMS_DISPATCH_MESSAGE;

-------------------------------------------------
FUNCTION GET_OPENADR_PYLD_ENTITY_ATTR
	(
	p_ATTRIBUTE_NAME IN VARCHAR,
	p_OWNER_ENTITY_ID IN NUMBER
	) RETURN VARCHAR2 IS

v_ATTRIBUTE_ID NUMBER;
v_ATTRIBUTE_NAME VARCHAR2(64);
v_RET TEMPORAL_ENTITY_ATTRIBUTE.ATTRIBUTE_VAL%TYPE;

BEGIN

	v_ATTRIBUTE_NAME := LTRIM(RTRIM(p_ATTRIBUTE_NAME));
	ID.ID_FOR_ENTITY_ATTRIBUTE(v_ATTRIBUTE_NAME, EC.ED_PROGRAM, NULL, FALSE, v_ATTRIBUTE_ID);

	IF v_ATTRIBUTE_ID <= 0 THEN
		ERRS.RAISE(MSGCODES.c_ERR_NO_SUCH_ENTRY,'Attribute with Name = ' || v_ATTRIBUTE_NAME);
	END IF;

	SELECT MAX(DECODE(ATTRIBUTE_VAL, GA.UNDEFINED_ATTRIBUTE, NULL, ATTRIBUTE_VAL))
	INTO v_RET
	FROM TEMPORAL_ENTITY_ATTRIBUTE
	WHERE OWNER_ENTITY_ID = p_OWNER_ENTITY_ID
        AND ENTITY_DOMAIN_ID = EC.ED_PROGRAM
	    AND ATTRIBUTE_ID = v_ATTRIBUTE_ID
		AND BEGIN_DATE = CONSTANTS.LOW_DATE
        AND NVL(END_DATE, CONSTANTS.HIGH_DATE) = CONSTANTS.HIGH_DATE;

	RETURN v_RET;
END GET_OPENADR_PYLD_ENTITY_ATTR;
-------------------------------------------------------------------------------------------
PROCEDURE SEND_OPENADR_MSG
  (
	p_EVENT_ID IN NUMBER,
	p_CUT_BEGIN_DATE IN DATE,
	p_CUT_END_DATE IN DATE,
    p_CURRENT_DATE IN DATE := SYSDATE,
	p_SUCCESS_COUNT OUT BINARY_INTEGER,
	p_FAIL_COUNT OUT BINARY_INTEGER
	) AS

  v_PROGRAM_TYPE PROGRAM.PROGRAM_TYPE%TYPE;
-------------------------------------------------
BEGIN
	 -- Get the Program Type
	SELECT P.PROGRAM_TYPE
	INTO v_PROGRAM_TYPE
	FROM DR_EVENT E, VPP V, PROGRAM P
	WHERE E.EVENT_ID = p_EVENT_ID
		AND E.VPP_ID = V.VPP_ID
		AND P.PROGRAM_ID = V.PROGRAM_ID;

  IF v_PROGRAM_TYPE = DEMAND_RESPONSE_UTIL.c_PROGRAM_TYPE_DLC THEN
      SEND_DERMS_DISP_MSG_OPENADR(p_EVENT_ID => p_EVENT_ID,
                      p_CUT_BEGIN_DATE => p_CUT_BEGIN_DATE,
                      p_CUT_END_DATE => p_CUT_END_DATE,
                      p_SUCCESS_COUNT => p_SUCCESS_COUNT,
                      p_FAIL_COUNT => p_FAIL_COUNT);

  ELSIF v_PROGRAM_TYPE = DEMAND_RESPONSE_UTIL.c_PROGRAM_TYPE_RT_PRICING THEN
      SEND_DERMS_PRICE_MSG_OPENADR(p_EVENT_ID => p_EVENT_ID,
                    p_CUT_BEGIN_DATE => p_CUT_BEGIN_DATE,
                    p_CUT_END_DATE => p_CUT_END_DATE,
                    p_SUCCESS_COUNT => p_SUCCESS_COUNT,
                    p_FAIL_COUNT => p_FAIL_COUNT);
                    
  ELSIF v_PROGRAM_TYPE = DEMAND_RESPONSE_UTIL.c_PROGRAM_TYPE_ENVIR_EMISSION THEN
      SEND_DERMS_CO2_MSG_OPENADR(p_EVENT_ID => p_EVENT_ID,
                    p_CUT_BEGIN_DATE => p_CUT_BEGIN_DATE,
                    p_CUT_END_DATE => p_CUT_END_DATE,
                    p_SUCCESS_COUNT => p_SUCCESS_COUNT,
                    p_FAIL_COUNT => p_FAIL_COUNT);
  END IF;

END SEND_OPENADR_MSG;
-------------------------------------------------------------------------------------------
PROCEDURE SEND_DERMS_DISP_MSG_OPENADR
	(
	p_EVENT_ID IN NUMBER,
	p_CUT_BEGIN_DATE IN DATE,
	p_CUT_END_DATE IN DATE,
    p_CURRENT_DATE IN DATE := SYSDATE,
	p_SUCCESS_COUNT OUT BINARY_INTEGER,
	p_FAIL_COUNT OUT BINARY_INTEGER
	) AS

v_RESULT XMLTYPE;
v_SENT BOOLEAN := FALSE;
-------------------------------------------------

BEGIN
	-- Reset counters
	p_SUCCESS_COUNT := 0;
	p_FAIL_COUNT := 0;

  FOR v_REC IN (SELECT DISTINCT E.EVENT_ID, F.PRIORITY
                  FROM DER_SEGMENT_RESULT R,
                      DR_EVENT E,
                      VIRTUAL_POWER_PLANT VPP,
                      TX_FEEDER_SEGMENT F
                  WHERE R.IS_EXTERNAL = 0
                      AND R.SERVICE_CODE = 'D'
                      AND E.EVENT_ID = p_EVENT_ID
                      AND E.VPP_ID = VPP.VPP_ID
                      AND R.PROGRAM_ID = VPP.PROGRAM_ID
                      AND R.SERVICE_ZONE_ID = VPP.SERVICE_ZONE_ID
                      AND F.FEEDER_SEGMENT_ID = R.FEEDER_SEGMENT_ID
                      AND EXISTS (SELECT 1
                                  FROM DER_SEGMENT_RESULT_DATA D
                                  WHERE D.DER_SEGMENT_RESULT_ID = R.DER_SEGMENT_RESULT_ID
                                      AND D.RESULT_DATE BETWEEN p_CUT_BEGIN_DATE AND p_CUT_END_DATE)
                  ORDER BY F.PRIORITY) LOOP

  v_SENT := TRUE;

    SELECT XMLELEMENT("oadr:oadrPayload",
            XMLATTRIBUTES(c_OPENADR_EMIX_NAMESPACE AS "xmlns:emix",
                        c_OPENADR_POWER_NAMESPACE AS "xmlns:power",
                        c_OPENADR_SCALE_NAMESPACE AS "xmlns:scale",
                        c_OPENADR_EI_NAMESPACE AS "xmlns:ei",
                        c_OPENADR_PYLD_NAMESPACE AS "xmlns:pyld",
                        c_OPENADR_OADR_NAMESPACE AS "xmlns:oadr",
                        c_OPENADR_N2_NAMESPACE AS "xmlns:n2",
                        c_OPENADR_GML_NAMESPACE AS "xmlns:gml",
                        c_OPENADR_DS_NAMESPACE AS "xmlns:ds",
                        c_OPENADR_XSI_NAMESPACE AS "xmlns:xsi",
                        c_OPENADR_ATOM_NAMESPACE AS "xmlns:atom",
                        c_OPENADR_XCAL_NAMESPACE AS "xmlns:xcal",
                        c_OPENADR_STRM_NAMESPACE AS "xmlns:strm"),
                            XMLELEMENT("oadr:oadrSignedObject",
                                XMLELEMENT("oadr:oadrDistributeEvent", XMLATTRIBUTES('2.0b' as "ei:schemaVersion"),
                                    XMLELEMENT("pyld:requestID", 'Msg_'||EVENT_NAME || DECODE(PRIORITY,null,'', '_' || TO_CHAR(PRIORITY)) || TO_CHAR(p_CURRENT_DATE, '_YYYY_MM_DD_HH24_MI_SS')),
                                    XMLELEMENT("ei:vtnID", 'Ventyx DRMS'),
                                    XMLELEMENT("oadr:oadrEvent",
                                        -- Event
                                        XMLELEMENT("ei:eiEvent",
                                           -- Event Description
                                           XMLELEMENT("ei:eventDescriptor",
                                              XMLELEMENT("ei:eventID", EVENT_NAME || DECODE(PRIORITY,null,'', '-' || TO_CHAR(PRIORITY))),
                                              XMLELEMENT("ei:modificationNumber", 0),
                                              XMLELEMENT("ei:priority", GET_OPENADR_PYLD_ENTITY_ATTR(DEMAND_RESPONSE.c_OPENADR_EVENT_PRIORITY, PROGRAM_ID)),
                                              XMLELEMENT("ei:eiMarketContext", XMLELEMENT("emix:marketContext", PROGRAM_NAME || DECODE(PRIORITY,null,'', '-' || TO_CHAR(PRIORITY)))),
                                              XMLELEMENT("ei:createdDateTime", DATE_UTIL.TO_CHAR_ISO_AS_GMT(p_CURRENT_DATE)),
                                              XMLELEMENT("ei:eventStatus", EVENT_STATUS)
                                           ),
                                           -- Active Period
                                           XMLELEMENT("ei:eiActivePeriod",
                                              XMLELEMENT("xcal:properties",
                                                XMLELEMENT("xcal:dtstart", XMLELEMENT("xcal:date-time", DATE_UTIL.TO_CHAR_ISO_AS_GMT(START_TIME))),
                                                XMLELEMENT("xcal:duration", XMLELEMENT("xcal:duration",
                                                            'PT'|| (SELECT COUNT(D.RESULT_DATE)
                                                                    FROM DER_SEGMENT_RESULT_DATA D
                                                                    WHERE D.DER_SEGMENT_RESULT_ID = X.DER_SEGMENT_RESULT_ID
                                                                        AND D.RESULT_DATE BETWEEN p_CUT_BEGIN_DATE AND p_CUT_END_DATE
                                                                        AND (D.LOAD_VAL + D.FAILURE_VAL + D.OPT_OUT_VAL + D.OVERRIDE_VAL) > 0)
                                                            || 'H'))),
                                              XMLELEMENT("xcal:components")
                                           ),
                                           -- Event Signals
                                           XMLELEMENT("ei:eiEventSignals",
                                              XMLELEMENT("ei:eiEventSignal",
                                                XMLELEMENT("strm:intervals",
                                                    (SELECT XMLAGG(
                                                                    XMLELEMENT("ei:interval",
                                                                        -- Interval begining
                                                                        XMLELEMENT("xcal:dtstart", XMLELEMENT("xcal:date-time", DATE_UTIL.TO_CHAR_ISO_AS_GMT(D.RESULT_DATE-1/24))),
                                                                        XMLELEMENT("xcal:duration", XMLELEMENT("xcal:duration", 'PT1H')),
                                                                        XMLELEMENT("ei:signalPayload", XMLELEMENT("ei:payloadFloat", XMLELEMENT("ei:value", '0')))
                                                                    )
                                                              )
                                                        FROM DER_SEGMENT_RESULT_DATA D
                                                        WHERE D.DER_SEGMENT_RESULT_ID = X.DER_SEGMENT_RESULT_ID
                                                            AND D.RESULT_DATE BETWEEN p_CUT_BEGIN_DATE AND p_CUT_END_DATE
                                                            AND (D.LOAD_VAL + D.FAILURE_VAL + D.OPT_OUT_VAL + D.OVERRIDE_VAL) > 0)
                                                ),
                                                XMLELEMENT("ei:signalName", GET_OPENADR_PYLD_ENTITY_ATTR(DEMAND_RESPONSE.c_OPENADR_SIGNAL_NAME, PROGRAM_ID)),
                                                XMLELEMENT("ei:signalType", GET_OPENADR_PYLD_ENTITY_ATTR(DEMAND_RESPONSE.c_OPENADR_SIGNAL_TYPE, PROGRAM_ID)),
                                                XMLELEMENT("ei:signalID", GET_OPENADR_PYLD_ENTITY_ATTR(DEMAND_RESPONSE.c_OPENADR_SIGNAL_NAME, PROGRAM_ID))
                                              )
                                           ),
                                         -- Target
                                         FEEDER_SEGMENTS
                                        ),
                                        XMLELEMENT("oadr:oadrResponseRequired", CASE UPPER(TRIM(GET_OPENADR_PYLD_ENTITY_ATTR(DEMAND_RESPONSE.c_OPENADR_RESPONSE_REQUIRED, PROGRAM_ID)))
                                                                                    WHEN '1' THEN 'always'
                                                                                    WHEN '0' THEN 'never' END
                                                    )
                                    )
                                )
                )
         )
    INTO v_RESULT
    FROM (SELECT MAX(E.EVENT_NAME) AS EVENT_NAME,
            MAX(FS.PRIORITY) AS PRIORITY,
            MAX(R.PROGRAM_ID) AS PROGRAM_ID,
            MAX(P.PROGRAM_NAME) AS PROGRAM_NAME,
            MAX(E.EVENT_STATUS) AS EVENT_STATUS,
            MAX(E.START_TIME) AS START_TIME,
            MAX(R.DER_SEGMENT_RESULT_ID) AS DER_SEGMENT_RESULT_ID,
            XMLELEMENT("ei:eiTarget",XMLAGG(XMLELEMENT("ei:resourceID", FS.FEEDER_SEGMENT_NAME))) AS FEEDER_SEGMENTS
        FROM DER_SEGMENT_RESULT R,
            DR_EVENT E,
            TX_FEEDER_SEGMENT FS,
            PROGRAM P,
            VIRTUAL_POWER_PLANT VPP
        WHERE R.IS_EXTERNAL = 0
            AND R.SERVICE_CODE = 'D'
            AND E.EVENT_ID = v_REC.EVENT_ID
            AND E.VPP_ID = VPP.VPP_ID
            AND R.PROGRAM_ID = VPP.PROGRAM_ID
            AND ((v_REC.PRIORITY IS NOT NULL AND FS.PRIORITY = v_REC.PRIORITY)
    OR (v_REC.PRIORITY IS NULL AND FS.PRIORITY IS NULL))
            AND FS.FEEDER_SEGMENT_ID = R.FEEDER_SEGMENT_ID
            AND P.PROGRAM_ID = R.PROGRAM_ID
            AND EXISTS (SELECT 1
                        FROM DER_SEGMENT_RESULT_DATA D
                        WHERE D.DER_SEGMENT_RESULT_ID = R.DER_SEGMENT_RESULT_ID
                            AND D.RESULT_DATE BETWEEN p_CUT_BEGIN_DATE AND p_CUT_END_DATE)
       GROUP BY E.EVENT_NAME,
            FS.PRIORITY,
            R.PROGRAM_ID,
            P.PROGRAM_NAME,
            E.EVENT_STATUS,
            E.START_TIME
      ORDER BY E.EVENT_NAME,
            FS.PRIORITY,
            R.PROGRAM_ID,
            P.PROGRAM_NAME,
            E.EVENT_STATUS,
            E.START_TIME) X;

        $if $$UNIT_TEST_MODE = 1 $THEN
            IF UNIT_TEST_UTIL.g_CURRENT_TEST_PROCEDURE LIKE 'TEST_DEMAND_RESPONSE_UTIL.T_DISP_MSSG_OPENADR%' THEN
                INSERT INTO RTO_WORK(WORK_ID, WORK_SEQ, WORK_DATA)
                SELECT v_REC.EVENT_ID, v_REC.PRIORITY, v_RESULT.GETSTRINGVAL() FROM DUAL;
            END IF;
        $end

        $if $$UNIT_TEST_MODE = 0 OR $$UNIT_TEST_MODE IS NULL $THEN
            -- SEND ONE MESSAGE FOR EACH EXTERNAL SYSTEM
            IF SEND_SMART_GRID_MSG_OPENADR(v_RESULT.GETCLOBVAL()) THEN
                p_SUCCESS_COUNT := p_SUCCESS_COUNT+1;
            ELSE
                p_FAIL_COUNT := p_FAIL_COUNT+1;
            END IF;
        $end

	END LOOP;

	IF NOT v_SENT THEN
		LOGS.LOG_WARN('There are no dispatch data for '||
						TEXT_UTIL.TO_CHAR_ENTITY(p_EVENT_ID, EC.ED_DR_EVENT, TRUE)||
						' in the given date range: '||TEXT_UTIL.TO_CHAR_TIME(p_CUT_BEGIN_DATE)||' -> '||TEXT_UTIL.TO_CHAR_TIME(p_CUT_END_DATE)||
						'. No dispatch messages sent.');
	END IF;
END SEND_DERMS_DISP_MSG_OPENADR;
-------------------------------------------------------------------------------------------
PROCEDURE SEND_DERMS_PRICE_MSG_OPENADR
	(
	p_EVENT_ID IN NUMBER,
	p_CUT_BEGIN_DATE IN DATE,
	p_CUT_END_DATE IN DATE,
    p_CURRENT_DATE IN DATE := SYSDATE,
	p_SUCCESS_COUNT OUT BINARY_INTEGER,
	p_FAIL_COUNT OUT BINARY_INTEGER
	) AS

v_RESULT XMLTYPE;
v_SENT BOOLEAN := FALSE;
-------------------------------------------------

BEGIN
	-- Reset counters
	p_SUCCESS_COUNT := 0;
	p_FAIL_COUNT := 0;

	v_SENT := TRUE;


    -- Pricing Signal
     SELECT XMLELEMENT("oadr:oadrPayload",
          XMLATTRIBUTES(c_OPENADR_EMIX_NAMESPACE AS "xmlns:emix",
                    c_OPENADR_POWER_NAMESPACE AS "xmlns:power",
                    c_OPENADR_SCALE_NAMESPACE AS "xmlns:scale",
                    c_OPENADR_EI_NAMESPACE AS "xmlns:ei",
                    c_OPENADR_PYLD_NAMESPACE AS "xmlns:pyld",
                    c_OPENADR_OADR_NAMESPACE AS "xmlns:oadr",
                    c_OPENADR_N2_NAMESPACE AS "xmlns:n2",
                    c_OPENADR_GML_NAMESPACE AS "xmlns:gml",
                    c_OPENADR_DS_NAMESPACE AS "xmlns:ds",
                    c_OPENADR_XSI_NAMESPACE AS "xmlns:xsi",
                    c_OPENADR_ATOM_NAMESPACE AS "xmlns:atom",
                    c_OPENADR_XCAL_NAMESPACE AS "xmlns:xcal",
                    c_OPENADR_STRM_NAMESPACE AS "xmlns:strm"),
                        XMLELEMENT("oadr:oadrSignedObject",
                            XMLELEMENT("oadr:oadrDistributeEvent", XMLATTRIBUTES('2.0b' as "ei:schemaVersion"),
                                XMLELEMENT("pyld:requestID", 'Msg_'||E.EVENT_NAME || '_' ||TO_CHAR(p_CURRENT_DATE, '_YYYY_MM_DD_HH24_MI_SS')),
                                XMLELEMENT("ei:vtnID", 'Ventyx DRMS'),
                                XMLELEMENT("oadr:oadrEvent",
                                    -- Event
                                    XMLELEMENT("ei:eiEvent",
                                       -- Event Description
                                       XMLELEMENT("ei:eventDescriptor",
                                          XMLELEMENT("ei:eventID", E.EVENT_NAME),
                                          XMLELEMENT("ei:modificationNumber", 0),
                                          XMLELEMENT("ei:priority", GET_OPENADR_PYLD_ENTITY_ATTR(DEMAND_RESPONSE.c_OPENADR_EVENT_PRIORITY, VPP.PROGRAM_ID)),
                                          XMLELEMENT("ei:eiMarketContext", XMLELEMENT("emix:marketContext", P.PROGRAM_NAME)),
                                          XMLELEMENT("ei:createdDateTime", DATE_UTIL.TO_CHAR_ISO_AS_GMT(p_CURRENT_DATE)),
                                          XMLELEMENT("ei:eventStatus", E.EVENT_STATUS)
                                       ),
                                       -- Active Period
                                       XMLELEMENT("ei:eiActivePeriod",
                                          XMLELEMENT("xcal:properties",
                                            XMLELEMENT("xcal:dtstart", XMLELEMENT("xcal:date-time", DATE_UTIL.TO_CHAR_ISO_AS_GMT(E.START_TIME))),
                                            XMLELEMENT("xcal:duration", XMLELEMENT("xcal:duration",
                                                        'PT'||  (SELECT COUNT(D.EVENT_ID)
                                                                FROM DR_EVENT_SCHEDULE D
                                                                WHERE D.EVENT_ID = E.EVENT_ID
                                                                    AND D.SCHEDULE_DATE BETWEEN p_CUT_BEGIN_DATE AND p_CUT_END_DATE)
                                                        || 'H'))),
                                          XMLELEMENT("xcal:components")
                                       ),
                                       -- Event Signals
                                       XMLELEMENT("ei:eiEventSignals",
                                          XMLELEMENT("ei:eiEventSignal",
                                            XMLELEMENT("strm:intervals",
                                                (SELECT XMLAGG(
                                                                XMLELEMENT("ei:interval",
                                                                    -- Interval begining
                                                                    XMLELEMENT("xcal:dtstart", XMLELEMENT("xcal:date-time", DATE_UTIL.TO_CHAR_ISO_AS_GMT(D.SCHEDULE_DATE-1/24))),
                                                                    XMLELEMENT("xcal:duration", XMLELEMENT("xcal:duration", 'PT1H')),
                                                                    XMLELEMENT("ei:signalPayload", XMLELEMENT("ei:payloadFloat", XMLELEMENT("ei:value", D.PRICE)))
                                                                )
                                                          )
                                                    FROM DR_EVENT_SCHEDULE D
                                                    WHERE D.EVENT_ID = E.EVENT_ID
                                                        AND D.SCHEDULE_DATE BETWEEN p_CUT_BEGIN_DATE AND p_CUT_END_DATE)
                                            ),
                                            XMLELEMENT("ei:signalName", GET_OPENADR_PYLD_ENTITY_ATTR(DEMAND_RESPONSE.c_OPENADR_SIGNAL_NAME, VPP.PROGRAM_ID)),
                                            XMLELEMENT("ei:signalType", GET_OPENADR_PYLD_ENTITY_ATTR(DEMAND_RESPONSE.c_OPENADR_SIGNAL_TYPE, VPP.PROGRAM_ID)),
                                            XMLELEMENT("ei:signalID", GET_OPENADR_PYLD_ENTITY_ATTR(DEMAND_RESPONSE.c_OPENADR_SIGNAL_NAME, VPP.PROGRAM_ID)),
                                                 -- Item
                                                XMLELEMENT("oadr:currencyPerKWh",
                                                    -- Item Description
                                                    XMLELEMENT("oadr:itemDescription",GET_OPENADR_PYLD_ENTITY_ATTR(DEMAND_RESPONSE.c_OPENADR_SIGNAL_UNIT_DESC, VPP.PROGRAM_ID)),
                                                    XMLELEMENT("oadr:itemUnits",GET_OPENADR_PYLD_ENTITY_ATTR(DEMAND_RESPONSE.c_OPENADR_SIGNAL_UNIT, VPP.PROGRAM_ID)),
                                                    XMLELEMENT("scale:siScaleCode",'none')
                                                )
                                              )
                                           ),

                                         -- Target
                                         XMLELEMENT("ei:eiTarget", XMLELEMENT("ei:groupID", P.PROGRAM_NAME))
                                        ),
                                        XMLELEMENT("oadr:oadrResponseRequired", CASE UPPER(TRIM(GET_OPENADR_PYLD_ENTITY_ATTR(DEMAND_RESPONSE.c_OPENADR_RESPONSE_REQUIRED, VPP.PROGRAM_ID)))
                                                                                    WHEN '1' THEN 'always'
                                                                                    WHEN '0' THEN 'never' END
                                                    )
                                    )
                                )
                )
          )
          INTO v_RESULT
          FROM DR_EVENT E,
              PROGRAM P,
              VIRTUAL_POWER_PLANT VPP
          WHERE E.EVENT_ID = p_EVENT_ID
              AND P.PROGRAM_ID = VPP.PROGRAM_ID
              AND E.VPP_ID = VPP.VPP_ID
          ORDER BY E.EVENT_ID;


  $if $$UNIT_TEST_MODE = 1 $THEN
    IF UNIT_TEST_UTIL.g_CURRENT_TEST_PROCEDURE LIKE 'TEST_DEMAND_RESPONSE_UTIL.T_DISP_MSSG_OPENADR%' OR
      UNIT_TEST_UTIL.g_CURRENT_TEST_PROCEDURE LIKE 'TEST_DEMAND_RESPONSE_UTIL.T_DISP_PRICE_OPENADR%' THEN
          INSERT INTO RTO_WORK(WORK_ID, WORK_DATA)
          SELECT P_EVENT_ID, v_RESULT.GETSTRINGVAL() FROM DUAL;
    END IF;
  $end

  $if $$UNIT_TEST_MODE = 0 OR $$UNIT_TEST_MODE IS NULL $THEN
      -- SEND ONE MESSAGE FOR EACH EXTERNAL SYSTEM
      IF SEND_SMART_GRID_MSG_OPENADR(v_RESULT.GETCLOBVAL()) THEN
          p_SUCCESS_COUNT := p_SUCCESS_COUNT+1;
      ELSE
          p_FAIL_COUNT := p_FAIL_COUNT+1;
      END IF;
  $end




	IF NOT v_SENT THEN
		LOGS.LOG_WARN('There are no dispatch data for '||
						TEXT_UTIL.TO_CHAR_ENTITY(p_EVENT_ID, EC.ED_DR_EVENT, TRUE)||
						' in the given date range: '||TEXT_UTIL.TO_CHAR_TIME(p_CUT_BEGIN_DATE)||' -> '||TEXT_UTIL.TO_CHAR_TIME(p_CUT_END_DATE)||
						'. No dispatch messages sent.');
	END IF;
END SEND_DERMS_PRICE_MSG_OPENADR;
-------------------------------------------------------------------------------------------
PROCEDURE SEND_DERMS_CO2_MSG_OPENADR
	(
	p_EVENT_ID IN NUMBER,
	p_CUT_BEGIN_DATE IN DATE,
	p_CUT_END_DATE IN DATE,
    p_CURRENT_DATE IN DATE := SYSDATE,
	p_SUCCESS_COUNT OUT BINARY_INTEGER,
	p_FAIL_COUNT OUT BINARY_INTEGER
	) AS

v_RESULT XMLTYPE;
v_SENT BOOLEAN := FALSE;
-------------------------------------------------

BEGIN
	-- Reset counters
	p_SUCCESS_COUNT := 0;
	p_FAIL_COUNT := 0;

	v_SENT := TRUE;


    -- Pricing Signal
     SELECT XMLELEMENT("oadr:oadrPayload",
          XMLATTRIBUTES(c_OPENADR_EMIX_NAMESPACE AS "xmlns:emix",
                    c_OPENADR_POWER_NAMESPACE AS "xmlns:power",
                    c_OPENADR_SCALE_NAMESPACE AS "xmlns:scale",
                    c_OPENADR_EI_NAMESPACE AS "xmlns:ei",
                    c_OPENADR_PYLD_NAMESPACE AS "xmlns:pyld",
                    c_OPENADR_OADR_NAMESPACE AS "xmlns:oadr",
                    c_OPENADR_N2_NAMESPACE AS "xmlns:n2",
                    c_OPENADR_GML_NAMESPACE AS "xmlns:gml",
                    c_OPENADR_DS_NAMESPACE AS "xmlns:ds",
                    c_OPENADR_XSI_NAMESPACE AS "xmlns:xsi",
                    c_OPENADR_ATOM_NAMESPACE AS "xmlns:atom",
                    c_OPENADR_XCAL_NAMESPACE AS "xmlns:xcal",
                    c_OPENADR_STRM_NAMESPACE AS "xmlns:strm"),
                        XMLELEMENT("oadr:oadrSignedObject",
                            XMLELEMENT("oadr:oadrDistributeEvent", XMLATTRIBUTES('2.0b' as "ei:schemaVersion"),
                                XMLELEMENT("pyld:requestID", 'Msg_'||E.EVENT_NAME || '_' ||TO_CHAR(p_CURRENT_DATE, '_YYYY_MM_DD_HH24_MI_SS')),
                                XMLELEMENT("ei:vtnID", 'Ventyx DRMS'),
                                XMLELEMENT("oadr:oadrEvent",
                                    -- Event
                                    XMLELEMENT("ei:eiEvent",
                                       -- Event Description
                                       XMLELEMENT("ei:eventDescriptor",
                                          XMLELEMENT("ei:eventID", E.EVENT_NAME),
                                          XMLELEMENT("ei:modificationNumber", 0),
                                          XMLELEMENT("ei:priority", GET_OPENADR_PYLD_ENTITY_ATTR(DEMAND_RESPONSE.c_OPENADR_EVENT_PRIORITY, VPP.PROGRAM_ID)),
                                          XMLELEMENT("ei:eiMarketContext", XMLELEMENT("emix:marketContext", P.PROGRAM_NAME)),
                                          XMLELEMENT("ei:createdDateTime", DATE_UTIL.TO_CHAR_ISO_AS_GMT(p_CURRENT_DATE)),
                                          XMLELEMENT("ei:eventStatus", E.EVENT_STATUS)
                                       ),
                                       -- Active Period
                                       XMLELEMENT("ei:eiActivePeriod",
                                          XMLELEMENT("xcal:properties",
                                            XMLELEMENT("xcal:dtstart", XMLELEMENT("xcal:date-time", DATE_UTIL.TO_CHAR_ISO_AS_GMT(E.START_TIME))),
                                            XMLELEMENT("xcal:duration", XMLELEMENT("xcal:duration",
                                                        'PT'||  (SELECT COUNT(I.SCHEDULE_DATE)
                                                                FROM IT_SCHEDULE I
                                                                WHERE I.TRANSACTION_ID = T.TRANSACTION_ID
                                                                    AND I.SCHEDULE_DATE BETWEEN p_CUT_BEGIN_DATE AND p_CUT_END_DATE)
                                                        || 'H'))),
                                          XMLELEMENT("xcal:components")
                                       ),
                                       -- Event Signals
                                       XMLELEMENT("ei:eiEventSignals",
                                          XMLELEMENT("ei:eiEventSignal",
                                            XMLELEMENT("strm:intervals",
                                                (SELECT XMLAGG(
                                                                XMLELEMENT("ei:interval",
                                                                    -- Interval begining
                                                                    XMLELEMENT("xcal:dtstart", XMLELEMENT("xcal:date-time", DATE_UTIL.TO_CHAR_ISO_AS_GMT(I.SCHEDULE_DATE-1/24))),
                                                                    XMLELEMENT("xcal:duration", XMLELEMENT("xcal:duration", 'PT1H')),
                                                                    XMLELEMENT("ei:signalPayload", XMLELEMENT("ei:payloadFloat", XMLELEMENT("ei:value", I.AMOUNT)))
                                                                )
                                                          )
                                                    FROM IT_SCHEDULE I
                                                    WHERE I.TRANSACTION_ID = T.TRANSACTION_ID
                                                        AND I.SCHEDULE_DATE BETWEEN p_CUT_BEGIN_DATE AND p_CUT_END_DATE)
                                            ),
                                            XMLELEMENT("ei:signalName", GET_OPENADR_PYLD_ENTITY_ATTR(DEMAND_RESPONSE.c_OPENADR_SIGNAL_NAME, VPP.PROGRAM_ID)),
                                            XMLELEMENT("ei:signalType", GET_OPENADR_PYLD_ENTITY_ATTR(DEMAND_RESPONSE.c_OPENADR_SIGNAL_TYPE, VPP.PROGRAM_ID)),
                                            XMLELEMENT("ei:signalID", GET_OPENADR_PYLD_ENTITY_ATTR(DEMAND_RESPONSE.c_OPENADR_SIGNAL_NAME, VPP.PROGRAM_ID)),
                                                 -- Item
                                                XMLELEMENT("oadr:customUnit",
                                                    -- Item Description
                                                    XMLELEMENT("oadr:itemDescription",GET_OPENADR_PYLD_ENTITY_ATTR(DEMAND_RESPONSE.c_OPENADR_SIGNAL_UNIT_DESC, VPP.PROGRAM_ID)),
                                                    XMLELEMENT("oadr:itemUnits",GET_OPENADR_PYLD_ENTITY_ATTR(DEMAND_RESPONSE.c_OPENADR_SIGNAL_UNIT, VPP.PROGRAM_ID)),
                                                    XMLELEMENT("scale:siScaleCode",'none')
                                                )
                                              )
                                           ),

                                         -- Target
                                         XMLELEMENT("ei:eiTarget", XMLELEMENT("ei:groupID", P.PROGRAM_NAME))
                                        ),
                                        XMLELEMENT("oadr:oadrResponseRequired", CASE UPPER(TRIM(GET_OPENADR_PYLD_ENTITY_ATTR(DEMAND_RESPONSE.c_OPENADR_RESPONSE_REQUIRED, VPP.PROGRAM_ID)))
                                                                                    WHEN '1' THEN 'always'
                                                                                    WHEN '0' THEN 'never' END
                                                    )
                                    )
                                )
                )
          )
          INTO v_RESULT
          FROM DR_EVENT E,
              PROGRAM P,
              INTERCHANGE_TRANSACTION T,
              VIRTUAL_POWER_PLANT VPP
          WHERE E.EVENT_ID = p_EVENT_ID
              AND P.PROGRAM_ID = VPP.PROGRAM_ID
              AND P.TRANSACTION_ID = T.TRANSACTION_ID
              AND E.VPP_ID = VPP.VPP_ID
          ORDER BY E.EVENT_ID;


  $if $$UNIT_TEST_MODE = 1 $THEN
    IF UNIT_TEST_UTIL.g_CURRENT_TEST_PROCEDURE LIKE 'TEST_DEMAND_RESPONSE_UTIL.T_DISP_MSSG_OPENADR%' OR
      UNIT_TEST_UTIL.g_CURRENT_TEST_PROCEDURE LIKE 'TEST_DEMAND_RESPONSE_UTIL.T_DISP_PRICE_OPENADR%' OR
      UNIT_TEST_UTIL.g_CURRENT_TEST_PROCEDURE LIKE 'TEST_DEMAND_RESPONSE_UTIL.T_DISP_CO2_OPENADR%' THEN
          INSERT INTO RTO_WORK(WORK_ID, WORK_DATA)
          SELECT P_EVENT_ID, v_RESULT.GETSTRINGVAL() FROM DUAL;
    END IF;
  $end

  $if $$UNIT_TEST_MODE = 0 OR $$UNIT_TEST_MODE IS NULL $THEN
      -- SEND ONE MESSAGE FOR EACH EXTERNAL SYSTEM
      IF SEND_SMART_GRID_MSG_OPENADR(v_RESULT.GETCLOBVAL()) THEN
          p_SUCCESS_COUNT := p_SUCCESS_COUNT+1;
      ELSE
          p_FAIL_COUNT := p_FAIL_COUNT+1;
      END IF;
  $end




	IF NOT v_SENT THEN
		LOGS.LOG_WARN('There are no dispatch data for '||
						TEXT_UTIL.TO_CHAR_ENTITY(p_EVENT_ID, EC.ED_DR_EVENT, TRUE)||
						' in the given date range: '||TEXT_UTIL.TO_CHAR_TIME(p_CUT_BEGIN_DATE)||' -> '||TEXT_UTIL.TO_CHAR_TIME(p_CUT_END_DATE)||
						'. No dispatch messages sent.');
	END IF;
END SEND_DERMS_CO2_MSG_OPENADR;
-------------------------------------------------------------------------------------------
PROCEDURE SEND_EVENT_CANCEL_MESSAGE
	(
	p_EVENT_ID IN NUMBER,
	p_SUCCESS_COUNT OUT BINARY_INTEGER,
	p_FAIL_COUNT OUT BINARY_INTEGER
	) AS

v_RESULT XMLTYPE;
v_SENT BOOLEAN := FALSE;

BEGIN
	-- Reset counters
	p_SUCCESS_COUNT := 0;
	p_FAIL_COUNT := 0;

	-- CANCEL THE EVENT FOR ALL EXTERNAL SYSTEMS
	FOR v_REC IN (SELECT DISTINCT ES.EXTERNAL_SYSTEM_NAME, E.EVENT_NAME
					FROM DER_SEGMENT_RESULT R,
						DR_EVENT E,
						VIRTUAL_POWER_PLANT VPP,
						EXTERNAL_SYSTEM ES
					WHERE R.IS_EXTERNAL = 0
						AND R.SERVICE_CODE = 'D'
						AND E.EVENT_ID = p_EVENT_ID
						AND E.VPP_ID = VPP.VPP_ID
						AND R.PROGRAM_ID = VPP.PROGRAM_ID
						AND R.SERVICE_ZONE_ID = VPP.SERVICE_ZONE_ID
						AND ES.EXTERNAL_SYSTEM_ID = R.EXTERNAL_SYSTEM_ID) LOOP

		v_SENT := TRUE;

		SELECT XMLELEMENT("sg:CancelEvent", XMLATTRIBUTES(c_SMARTGRID_NAMESPACE AS "xmlns:sg"),
					XMLELEMENT("sg:cancellation",
						XMLELEMENT("sg:eventIdent", v_REC.EVENT_NAME),
						XMLELEMENT("sg:externalSystemIdent", v_REC.EXTERNAL_SYSTEM_NAME),
						XMLELEMENT("sg:identifiedBy", NULL)
						))
		INTO v_RESULT
		FROM DR_EVENT E
		WHERE E.EVENT_ID = p_EVENT_ID;

		IF SEND_SMART_GRID_MESSAGE(c_ACTION_CANCEL_EVENT,v_RESULT.GETCLOBVAL()) THEN
			p_SUCCESS_COUNT := p_SUCCESS_COUNT+1;
		ELSE
			p_FAIL_COUNT := p_FAIL_COUNT+1;
		END IF;

	END LOOP;

	IF NOT v_SENT THEN
		LOGS.LOG_WARN('There are no dispatch data for '||
						TEXT_UTIL.TO_CHAR_ENTITY(p_EVENT_ID, EC.ED_DR_EVENT, TRUE)||
						'. No cancel messages sent.');
	END IF;

END SEND_EVENT_CANCEL_MESSAGE;
-------------------------------------------------------------------------------------------
FUNCTION GET_OADR_CUT_DATE
    (
    p_OADR_DATE_STRING IN VARCHAR2,
    p_DURATION IN VARCHAR2
    ) RETURN DATE AS
BEGIN
    RETURN DATE_UTIL.TO_CUT_DATE_FROM_ISO(
        REPLACE(p_OADR_DATE_STRING, 'Z', '-00')) + 
            CASE 
            WHEN p_DURATION = 'PT1H' THEN 1/24 
            WHEN p_DURATION = 'PT15M' THEN 15/1440 
            WHEN p_DURATION = 'PT30M' THEN 30/1440 
            ELSE 0
            END;
END GET_OADR_CUT_DATE;
-------------------------------------------------------------------------------------------
PROCEDURE VAL_UPDT_RPT_FOR_IMPORT
    (
    p_SAFE_XML_TYPE IN XMLTYPE,
    p_RESPONSE_CODE OUT NUMBER,
    p_INV_RID_COLL OUT STRING_COLLECTION,
    p_REQUEST_ID OUT VARCHAR2,
    p_VEN_ID OUT VARCHAR2
    ) AS
    
    v_REPORT_NAME VARCHAR2(4000);
    v_VALID_REPORT BOOLEAN := FALSE;
    v_DISTINCT_RID_COLL STRING_COLLECTION;
    v_OADR_BEGIN_DATE VARCHAR2(32);
    v_OADR_DURATION VARCHAR2(8);
    v_BEGIN_DATE DATE;
    v_END_DATE DATE;
    v_CURR_DATE DATE;
    v_VALID_RID BOOLEAN;
    v_ACCOUNT_ID ACCOUNT.ACCOUNT_ID%TYPE;
    v_SL_ID SERVICE_LOCATION.SERVICE_LOCATION_ID%TYPE;
    v_METER_ID METER.METER_ID%TYPE;
    v_ACCOUNT_MODEL_OPTION ACCOUNT.ACCOUNT_MODEL_OPTION%TYPE;

BEGIN

    -- validate report name and get requestID, venID, start date, and duration
    BEGIN
        SELECT EXTRACTVALUE(VALUE(T), '//oadr:oadrReport/ei:reportName', c_OPENADR_NAMESPACES),
               EXTRACTVALUE(VALUE(T), '//pyld:requestID', c_OPENADR_NAMESPACES),
               EXTRACTVALUE(VALUE(T), '//ei:venID', c_OPENADR_NAMESPACES),
               EXTRACTVALUE(VALUE(T), '//oadr:oadrReport/xcal:dtstart/xcal:date-time', c_OPENADR_NAMESPACES),
               EXTRACTVALUE(VALUE(T), '//oadr:oadrReport/xcal:duration/xcal:duration', c_OPENADR_NAMESPACES)
        INTO v_REPORT_NAME,
             p_REQUEST_ID,
             p_VEN_ID,
             v_OADR_BEGIN_DATE,
             v_OADR_DURATION
        FROM TABLE(XMLSEQUENCE(EXTRACT(p_SAFE_XML_TYPE, '/oadr:oadrPayload/oadr:oadrSignedObject/oadr:oadrUpdateReport', c_OPENADR_NAMESPACES))) T;
        
        IF v_REPORT_NAME = 'TELEMETRY_USAGE' THEN
            v_VALID_REPORT := TRUE;
        END IF;
    EXCEPTION WHEN OTHERS THEN
        v_VALID_REPORT := FALSE;
    END;
    
    IF v_VALID_REPORT = FALSE THEN
        p_RESPONSE_CODE := c_OADR_RESP_REP_NOT_SUPPT;
        RETURN;
    END IF;
    
    -- get the service dates this report covers
    v_BEGIN_DATE := TRUNC(FROM_CUT(GET_OADR_CUT_DATE(v_OADR_BEGIN_DATE, v_OADR_DURATION), GA.LOCAL_TIME_ZONE) - 1/1440);
    v_END_DATE := v_BEGIN_DATE + 1;
    
    -- validate rIDs
    SELECT DISTINCT EXTRACTVALUE(VALUE(P), '//oadr:oadrReportPayload/ei:rID', c_OPENADR_NAMESPACES)
    BULK COLLECT INTO v_DISTINCT_RID_COLL
    FROM TABLE(XMLSEQUENCE(EXTRACT(p_SAFE_XML_TYPE, '/oadr:oadrPayload/oadr:oadrSignedObject/oadr:oadrUpdateReport/oadr:oadrReport/strm:intervals/ei:interval', c_OPENADR_NAMESPACES))) T,
         TABLE(XMLSEQUENCE(EXTRACT(VALUE(T), '//oadr:oadrReportPayload', c_OPENADR_NAMESPACES))) P
    ;
    
    p_INV_RID_COLL := STRING_COLLECTION();
    v_CURR_DATE := v_BEGIN_DATE;
    WHILE v_CURR_DATE <= v_END_DATE LOOP
        FOR cur_DISTINCT_RID IN ( SELECT COLUMN_VALUE AS RID FROM TABLE(CAST(v_DISTINCT_RID_COLL AS STRING_COLLECTION)) ) LOOP
            v_VALID_RID := FALSE;
            v_ACCOUNT_ID := EI.GET_ID_FROM_NAME(cur_DISTINCT_RID.RID, EC.ED_ACCOUNT, p_QUIET => 1);
            IF v_ACCOUNT_ID > 0 THEN -- account exists named with rid name
                v_SL_ID := EI.GET_ID_FROM_NAME(cur_DISTINCT_RID.RID, EC.ED_SERVICE_LOCATION, p_QUIET => 1);
                IF v_SL_ID > 0 THEN -- service location exists for service date
                    SELECT ACCOUNT_MODEL_OPTION INTO v_ACCOUNT_MODEL_OPTION FROM ACCOUNT WHERE ACCOUNT_ID = v_ACCOUNT_ID;
                    IF v_ACCOUNT_MODEL_OPTION = ACCOUNTS_METERS.c_ACCT_MODEL_OPTION_METER THEN -- check meter
                        BEGIN
                            -- check meter exists named with rid name
                            SELECT METER_ID 
                            INTO v_METER_ID 
                            FROM METER 
                            WHERE METER_NAME = cur_DISTINCT_RID.RID;
                            
                            -- check the account service location exists for meter on the service date
                            SELECT METER_ID 
                            INTO v_SL_ID 
                            FROM SERVICE_LOCATION_METER 
                            WHERE SERVICE_LOCATION_ID = v_SL_ID
	                          AND v_CURR_DATE BETWEEN BEGIN_DATE AND NVL(END_DATE, v_CURR_DATE);
                              
                            -- we have a valid meter modelled rid at this point
                            v_VALID_RID := TRUE;
                              
                        EXCEPTION WHEN NO_DATA_FOUND THEN NULL;
                        END;
                    ELSE
                        -- we have a valid account modelled rid at this point
                        v_VALID_RID := TRUE;
                    END IF;
                END IF;
            END IF;
            
            IF v_VALID_RID = FALSE AND NOT UT.STRING_COLLECTION_CONTAINS(p_INV_RID_COLL, cur_DISTINCT_RID.RID) THEN
                p_INV_RID_COLL.EXTEND();
                p_INV_RID_COLL(p_INV_RID_COLL.COUNT) := cur_DISTINCT_RID.RID;
            END IF;
        END LOOP;
        
        v_CURR_DATE := v_CURR_DATE + 1;
    END LOOP;
    
    IF p_INV_RID_COLL.COUNT > 0 THEN
        p_RESPONSE_CODE := c_OADR_RESP_MET_NOT_EXIST;
        RETURN;
    END IF;
    
    -- otherwise, valid
    p_RESPONSE_CODE := c_OADR_RESP_OK;

END VAL_UPDT_RPT_FOR_IMPORT;
-------------------------------------------------------------------------------------------
PROCEDURE PARSE_UPDT_RPT_TO_WORK
	(
	p_SAFE_XML_TYPE IN XMLTYPE,
    p_INV_RID_COLL IN STRING_COLLECTION,
    p_WORK_ID OUT NUMBER
	) AS

BEGIN

    UT.GET_RTO_WORK_ID(p_WORK_ID);
    
    INSERT INTO RTO_WORK(WORK_ID, WORK_DATE, WORK_DATA, WORK_DATA2)
    SELECT p_WORK_ID AS WORK_ID,
           GET_OADR_CUT_DATE(DATE_TIME, DURATION) AS WORK_DATE,
           RID AS WORK_DATA,
           LOAD_VALUE AS WORK_DATA2
    FROM (
        SELECT EXTRACTVALUE(VALUE(P), '//oadr:oadrReportPayload/ei:rID', c_OPENADR_NAMESPACES) AS RID,
               EXTRACTVALUE(VALUE(T), '//ei:interval/xcal:dtstart/xcal:date-time', c_OPENADR_NAMESPACES) AS DATE_TIME,
               EXTRACTVALUE(VALUE(T), '//ei:interval/xcal:duration/xcal:duration', c_OPENADR_NAMESPACES) AS DURATION,
               EXTRACTVALUE(VALUE(P), '//oadr:oadrReportPayload/ei:payloadFloat/ei:value', c_OPENADR_NAMESPACES) AS LOAD_VALUE
        FROM TABLE(XMLSEQUENCE(EXTRACT(p_SAFE_XML_TYPE, '/oadr:oadrPayload/oadr:oadrSignedObject/oadr:oadrUpdateReport/oadr:oadrReport/strm:intervals/ei:interval', c_OPENADR_NAMESPACES))) T,
             TABLE(XMLSEQUENCE(EXTRACT(VALUE(T), '//oadr:oadrReportPayload', c_OPENADR_NAMESPACES))) P
    )
    WHERE RID NOT IN ( SELECT COLUMN_VALUE FROM TABLE(CAST(p_INV_RID_COLL AS STRING_COLLECTION)) )
    ;    

END PARSE_UPDT_RPT_TO_WORK;
-------------------------------------------------------------------------------------------
PROCEDURE STORE_SERVICE_LOAD
	(
	p_SERVICE_ID IN NUMBER,
	p_SERVICE_CODE IN CHAR,
	p_LOAD_DATE IN GA.DATE_TABLE,
	p_LOAD IN GA.FLOAT_TABLE,
	p_TX_LOSS IN GA.FACTOR_TABLE,
	p_DX_LOSS IN GA.FACTOR_TABLE,
	p_UE_LOSS IN GA.FACTOR_TABLE
	) AS

v_INDEX BINARY_INTEGER;
v_LOAD_CODE CHAR(1) := GA.STANDARD;
v_BEGIN_DATE DATE;
v_END_DATE DATE;

BEGIN

	v_BEGIN_DATE := p_LOAD_DATE(p_LOAD_DATE.FIRST);
	v_END_DATE := p_LOAD_DATE(p_LOAD_DATE.LAST);

	DELETE SERVICE_LOAD
	WHERE SERVICE_ID = p_SERVICE_ID
		AND SERVICE_CODE = p_SERVICE_CODE
		AND LOAD_DATE BETWEEN v_BEGIN_DATE AND v_END_DATE
		AND LOAD_CODE = v_LOAD_CODE;

	FORALL v_INDEX IN 1..p_LOAD_DATE.COUNT
		INSERT INTO SERVICE_LOAD(SERVICE_ID, SERVICE_CODE, LOAD_DATE, LOAD_CODE, LOAD_VAL, TX_LOSS_VAL, DX_LOSS_VAL, UE_LOSS_VAL)
		VALUES (p_SERVICE_ID, p_SERVICE_CODE, p_LOAD_DATE(v_INDEX), v_LOAD_CODE, p_LOAD(v_INDEX), p_TX_LOSS(v_INDEX),  p_DX_LOSS(v_INDEX), p_UE_LOSS(v_INDEX));

END STORE_SERVICE_LOAD;
----------------------------------------------------------------------------------------------------
PROCEDURE UPDATE_SERVICE_LOAD
    (
    p_WORK_ID IN NUMBER
    ) AS
    
    v_BEGIN_DATE DATE;
    v_END_DATE DATE;
    v_CURR_DATE DATE;
    v_ACCOUNT_ID ACCOUNT.ACCOUNT_ID%TYPE;
    v_SL_ID SERVICE_LOCATION.SERVICE_LOCATION_ID%TYPE;
    v_METER_ID METER.METER_ID%TYPE;
    v_ACCOUNT_MODEL_OPTION ACCOUNT.ACCOUNT_MODEL_OPTION%TYPE;
    v_ACCOUNT_SERVICE_ID ACCOUNT_SERVICE.ACCOUNT_SERVICE_ID%TYPE;
    v_PROVIDER_SERVICE_ID PROVIDER_SERVICE.PROVIDER_SERVICE_ID%TYPE;
    v_PROVIDER_SERVICE PROVIDER_SERVICE%ROWTYPE;
    v_SERVICE_DELIVERY_ID SERVICE_DELIVERY.SERVICE_DELIVERY_ID%TYPE;
    v_SERVICE_ID SERVICE.SERVICE_ID%TYPE;
    v_ACCOUNT_MODEL_ID ACCOUNT.MODEL_ID%TYPE;
    
    v_LOAD_DATES GA.DATE_TABLE;
    v_LOAD_VALUES GA.FLOAT_TABLE;
    v_TX_LOSS GA.FACTOR_TABLE;
	v_DX_LOSS GA.FACTOR_TABLE;
	v_UE_LOSS GA.FACTOR_TABLE;
    
BEGIN

    SELECT TRUNC(FROM_CUT(MIN(WORK_DATE), GA.LOCAL_TIME_ZONE) - 1/1440)
    INTO v_BEGIN_DATE
    FROM RTO_WORK
    WHERE WORK_ID = p_WORK_ID;
    v_END_DATE := v_BEGIN_DATE + 1;
    
    v_CURR_DATE := v_BEGIN_DATE;
    WHILE v_CURR_DATE <= v_END_DATE LOOP
        FOR cur_DISTINCT_RID IN ( SELECT DISTINCT WORK_DATA AS RID FROM RTO_WORK WHERE WORK_ID = p_WORK_ID ) LOOP
            v_ACCOUNT_ID := EI.GET_ID_FROM_NAME(cur_DISTINCT_RID.RID, EC.ED_ACCOUNT);
            v_SL_ID := EI.GET_ID_FROM_NAME(cur_DISTINCT_RID.RID, EC.ED_SERVICE_LOCATION);
            SELECT ACCOUNT_MODEL_OPTION INTO v_ACCOUNT_MODEL_OPTION FROM ACCOUNT WHERE ACCOUNT_ID = v_ACCOUNT_ID;
            IF v_ACCOUNT_MODEL_OPTION = ACCOUNTS_METERS.c_ACCT_MODEL_OPTION_METER THEN
                v_METER_ID := EI.GET_ID_FROM_NAME(cur_DISTINCT_RID.RID, EC.ED_METER);
            ELSE
                v_METER_ID := CONSTANTS.NOT_ASSIGNED;
            END IF;
            
            SELECT MODEL_ID
            INTO v_ACCOUNT_MODEL_ID
            FROM ACCOUNT
            WHERE ACCOUNT_ID = v_ACCOUNT_ID;
            
            CS.GET_ACCOUNT_SERVICE_ID(v_ACCOUNT_ID,v_SL_ID,v_METER_ID,CONSTANTS.NOT_ASSIGNED,v_ACCOUNT_SERVICE_ID);
            v_PROVIDER_SERVICE_ID := CS.GET_PROVIDER_SERVICE_ID(v_ACCOUNT_SERVICE_ID,v_CURR_DATE);
            v_PROVIDER_SERVICE := CS.GET_PROVIDER_SERVICE(v_PROVIDER_SERVICE_ID);
            CS.GET_SERVICE_DELIVERY_ID(v_ACCOUNT_SERVICE_ID, v_PROVIDER_SERVICE_ID, v_CURR_DATE, v_SERVICE_DELIVERY_ID);
            v_SERVICE_ID := CS.GET_SERVICE_ID(v_ACCOUNT_MODEL_ID,GA.BASE_SCENARIO_ID,CONSTANTS.LOW_DATE,v_PROVIDER_SERVICE_ID,v_ACCOUNT_SERVICE_ID,v_SERVICE_DELIVERY_ID);
            
            v_LOAD_DATES.DELETE;
            v_LOAD_VALUES.DELETE;
            v_TX_LOSS.DELETE;
            v_DX_LOSS.DELETE;
            v_UE_LOSS.DELETE;
            
            SELECT WORK_DATE,
                   TO_NUMBER(WORK_DATA2)
            BULK COLLECT INTO v_LOAD_DATES,
                              v_LOAD_VALUES
            FROM RTO_WORK RW
            WHERE RW.WORK_ID = p_WORK_ID
              AND TRUNC(FROM_CUT(WORK_DATE, GA.LOCAL_TIME_ZONE) - 1/1400) = v_CURR_DATE
              AND WORK_DATA = cur_DISTINCT_RID.RID
            ORDER BY WORK_DATE;
              
            IF v_LOAD_DATES.COUNT > 0 THEN
                FS.APPLY_LOSS_FACTORS(v_ACCOUNT_SERVICE_ID, v_PROVIDER_SERVICE.EDC_ID, v_CURR_DATE, v_LOAD_VALUES, v_TX_LOSS, v_DX_LOSS, v_UE_LOSS);
                STORE_SERVICE_LOAD(v_SERVICE_ID, GA.ACTUAL_SERVICE, v_LOAD_DATES, v_LOAD_VALUES, v_TX_LOSS, v_DX_LOSS, v_UE_LOSS);
            END IF;
	
        END LOOP;
        v_CURR_DATE := v_CURR_DATE + 1;
    END LOOP;

END UPDATE_SERVICE_LOAD;
-------------------------------------------------------------------------------------------
FUNCTION BUILD_OADR_UPDTD_RPT_PAYLOAD
    (
    p_RESPONSE_CODE IN NUMBER,
    p_INV_RID_COLL IN STRING_COLLECTION,
    p_REQUEST_ID IN VARCHAR2,
    p_VEN_ID IN VARCHAR2
    ) RETURN VARCHAR2 AS
    
    v_UPDTD_RPT_PAYLOAD VARCHAR2(4000);
    v_DESCRIPTION VARCHAR2(4000);
    
BEGIN

    v_UPDTD_RPT_PAYLOAD := c_OADR_UPDTD_RPT_PAYLOAD_TPL;
    v_UPDTD_RPT_PAYLOAD := REPLACE(v_UPDTD_RPT_PAYLOAD, '%responseCode%', p_RESPONSE_CODE);
    
    IF p_RESPONSE_CODE = 200 THEN
        v_UPDTD_RPT_PAYLOAD := REPLACE(v_UPDTD_RPT_PAYLOAD, '%responseDescription%', 'OK');
    ELSIF p_RESPONSE_CODE = 464 AND p_INV_RID_COLL IS NOT NULL THEN
        v_DESCRIPTION := 'Account/SL/(Meter) does not exist: ';
        FOR I IN 1..p_INV_RID_COLL.COUNT LOOP
            v_DESCRIPTION := v_DESCRIPTION || p_INV_RID_COLL(I);
            IF I < p_INV_RID_COLL.COUNT THEN
                v_DESCRIPTION := v_DESCRIPTION || ',';
            END IF;
        END LOOP;
        v_UPDTD_RPT_PAYLOAD := REPLACE(v_UPDTD_RPT_PAYLOAD, '%responseDescription%', v_DESCRIPTION);
    ELSIF p_RESPONSE_CODE = 465 THEN
        v_UPDTD_RPT_PAYLOAD := REPLACE(v_UPDTD_RPT_PAYLOAD, '%responseDescription%', 'Report is not supported.');
    END IF;
    
    v_UPDTD_RPT_PAYLOAD := REPLACE(v_UPDTD_RPT_PAYLOAD, '%requestID%', p_REQUEST_ID);
    v_UPDTD_RPT_PAYLOAD := REPLACE(v_UPDTD_RPT_PAYLOAD, '%venID%', p_VEN_ID);
    
    RETURN v_UPDTD_RPT_PAYLOAD;

END BUILD_OADR_UPDTD_RPT_PAYLOAD;
-------------------------------------------------------------------------------------------
PROCEDURE OADR_POLL AS

    v_POLL_URL SYSTEM_DICTIONARY.VALUE%TYPE;
    v_MEX_RESULT MEX_RESULT;
    v_LOGGER MM_LOGGER_ADAPTER;
    v_CREDENTIALS MEX_CREDENTIALS;
    v_REQUEST_ID VARCHAR2(4000);
    v_SAFE_XML_TYPE XMLTYPE;
    v_RESPONSE_CODE NUMBER;
    v_INV_RID_COLL STRING_COLLECTION;
    v_VEN_ID VARCHAR2(32);
    v_UPDTD_RPT_PAYLOAD VARCHAR2(4000);
    v_WORK_ID RTO_WORK.WORK_ID%TYPE;
    v_FINISH_TEXT VARCHAR2(4000);
    v_PROCESS_STATUS NUMBER;

BEGIN

    SAVEPOINT BEGIN_OADR_POLL;
    LOGS.START_PROCESS('oadrPoll');

    -- get the poll url
    v_POLL_URL := GET_DICTIONARY_VALUE('OpenADR Poll URL', 0, 'Load Management', 'Demand Response');
    IF v_POLL_URL IS NULL THEN
        LOGS.LOG_ERROR('Load Management>Demand Response>OpenADR Poll URL not set.', 'DEMAND_RESPONSE_UTIL.OADR_POLL');
        LOGS.STOP_PROCESS(p_FINISH_TEXT => v_FINISH_TEXT, p_PROCESS_STATUS => v_PROCESS_STATUS);
        RETURN;
    END IF;
    
    MEX_SWITCHBOARD.INIT_MEX(p_EXTERNAL_SYSTEM_ID => EC.ES_SMART_GRID,
			         	     p_EXTERNAL_ACCOUNT_NAME => NULL,
			         	     p_PROCESS_NAME => 'OADR_POLL',
			         	     p_EXCHANGE_NAME => 'OADR_POLL',
			         	     p_LOG_TYPE => MEX_SWITCHBOARD.g_LOG_ALL,
			         	     p_TRACE_ON => 0,
			         	     p_CREDENTIALS => v_CREDENTIALS,
			         	     p_LOGGER => v_LOGGER
                             );
                     
    
    -- call the poll web service
    v_MEX_RESULT := MEX_SWITCHBOARD.FETCHURL(p_URL_TO_FETCH => v_POLL_URL,
                                             p_LOGGER => v_LOGGER,
                                             p_CRED => v_CREDENTIALS,
                                             p_REQUEST_CONTENTTYPE => 'application/xml',
                                             p_REQUEST => c_OADR_POLL_PAYLOAD
                                             );
    
    -- bail out on basic failures
    IF v_MEX_RESULT.STATUS_CODE <> 0 THEN
        LOGS.LOG_ERROR('Error calling oadrPoll web service.', 'DEMAND_RESPONSE_UTIL.OADR_POLL');
        LOGS.STOP_PROCESS(p_FINISH_TEXT => v_FINISH_TEXT, p_PROCESS_STATUS => v_PROCESS_STATUS);
        RETURN;
    END IF;    
    IF v_MEX_RESULT.RESPONSE IS NULL THEN
        LOGS.LOG_ERROR('oadrPoll web service did not return a response payload.', 'DEMAND_RESPONSE_UTIL.OADR_POLL');
        LOGS.STOP_PROCESS(p_FINISH_TEXT => v_FINISH_TEXT, p_PROCESS_STATUS => v_PROCESS_STATUS);
        RETURN;
    END IF;
    
    -- check if this is an update report response payload
    v_SAFE_XML_TYPE := PARSE_UTIL.CREATE_XML_SAFE(v_MEX_RESULT.RESPONSE);
    BEGIN
        SELECT EXTRACTVALUE(VALUE(T), '//pyld:requestID', c_OPENADR_NAMESPACES)
        INTO v_REQUEST_ID
        FROM TABLE(XMLSEQUENCE(EXTRACT(v_SAFE_XML_TYPE, '/oadr:oadrPayload/oadr:oadrSignedObject/oadr:oadrUpdateReport', c_OPENADR_NAMESPACES))) T;
    EXCEPTION WHEN OTHERS THEN
        LOGS.LOG_INFO('oadrUpdateReport payload not received from oadrPoll.  Nothing to do.', 'DEMAND_RESPONSE_UTIL.OADR_POLL');
        LOGS.STOP_PROCESS(p_FINISH_TEXT => v_FINISH_TEXT, p_PROCESS_STATUS => v_PROCESS_STATUS);
        RETURN;
    END;
    
    -- validate update report xml for importing
    VAL_UPDT_RPT_FOR_IMPORT(v_SAFE_XML_TYPE, v_RESPONSE_CODE, v_INV_RID_COLL, v_REQUEST_ID, v_VEN_ID);
    
    -- build updated report payload
    v_UPDTD_RPT_PAYLOAD := BUILD_OADR_UPDTD_RPT_PAYLOAD(v_RESPONSE_CODE, v_INV_RID_COLL, v_REQUEST_ID, v_VEN_ID);
    
    -- import as long as valid report
    IF v_RESPONSE_CODE <> 465 THEN
        LOGS.LOG_INFO('Valid oadrUpdateReport named TELEMETRY_USAGE received from oadrPoll.  Importing...', 'DEMAND_RESPONSE_UTIL.OADR_POLL');
        PARSE_UPDT_RPT_TO_WORK(v_SAFE_XML_TYPE, v_INV_RID_COLL, v_WORK_ID);
        UPDATE_SERVICE_LOAD(v_WORK_ID);
    END IF;
    
    -- call poll web service with updated report payload
    LOGS.LOG_INFO('...Import complete.  Sending oadrUpdatedReport to oadrPoll.', 'DEMAND_RESPONSE_UTIL.OADR_POLL');
    v_MEX_RESULT := MEX_SWITCHBOARD.FETCHURL(p_URL_TO_FETCH => v_POLL_URL,
                                             p_LOGGER => v_LOGGER,
                                             p_CRED => v_CREDENTIALS,
                                             p_REQUEST_CONTENTTYPE => 'application/xml',
                                             p_REQUEST => v_UPDTD_RPT_PAYLOAD
                                             );
    IF v_MEX_RESULT.STATUS_CODE <> 0 THEN
        LOGS.LOG_ERROR('Error calling oadrPoll web service.', 'DEMAND_RESPONSE_UTIL.OADR_POLL');
        LOGS.STOP_PROCESS(p_FINISH_TEXT => v_FINISH_TEXT, p_PROCESS_STATUS => v_PROCESS_STATUS);
        RETURN;
    END IF;    

    LOGS.STOP_PROCESS(p_FINISH_TEXT => v_FINISH_TEXT, p_PROCESS_STATUS => v_PROCESS_STATUS);
    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
        ERRS.ABORT_PROCESS(p_SAVEPOINT_NAME => 'BEGIN_OADR_POLL');

END OADR_POLL;
-------------------------------------------------------------------------------------------
END DEMAND_RESPONSE_UTIL;
/
