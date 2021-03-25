create or replace package body MEX_PJM_EES is
g_PJM_EES_MKT CONSTANT VARCHAR2(8) := 'pjmees';

FUNCTION WHAT_VERSION RETURN VARCHAR2 IS
BEGIN
    RETURN '$Revision: 1.1 $';
END WHAT_VERSION;


/*
The general look of a MEX package that implements concrete market interfaces should
generally have three categories of public procedures: Parse Procedures,
Fetch Procedures, and Submit Procedures.

And Fetch Procedures generally take this form:
procedure Fetch_Something (
	p_Parm in someParameterType,
	p_Output out MEX_Some_Report_Type_Output_TBL,
	p_Status out number
	) as
v_Data clob; -- or xmltype
begin
	-- build request clob/xmltype based on parameters
	<snip>
	MEX_Util.Run_MEX_Exchange(<snip>);
	if p_STATUS = MEX_UTIL.g_SUCCESS then
		Parse_Something(v_Data,p_Output);
	end if;
end Fetch_Something;

Finally, the Submit Procedures will typically be similar to the Fetch Procedures, as seen below:
procedure Submit_Something (
	p_Parm in someParameterType,
	p_Input in MEX_Some_Report_Type_Input_TBL,
	p_Status out number
	) as
v_Data clob; -- or xmltype
begin
	-- build submission clob/xmltype based on input table
	<snip>
	MEX_Util.Run_MEX_Exchange(<snip>);
end Submit_Something;
The Fetch Procedures could conceivably take parameters in the form of tables of objects
when many inputs are required. But the main difference, between a fetch and a submit
would be that no data is returned by a submission. Typically only status information will
be returned by a submission. For complicated submissions though the status could conceivably
require tables of objects to be correctly passed back to the application tier. The important
distinction is that the results of a submission aren't put into application data tables -
only application status tables, if they're put into anything at all.

The above implements passing of data via tables of objects as discussed in the sections
further above. One particular advantage to categorizing the routines this way is that
by always putting the Parse logic in its own public procedure the import logic can more
easily be unit tested without having to test it against a live web listener/ISO. We can
use Data Import in MarketManager to test the imports by importing a sample XML, CSV, etc
file. The application tier implementation would then call the Parse procedures to break
this file into the tables of objects with meaningful data. The application tier could then
encapsulate the logic that transforms the tables of objects into rows in application tables -
and this logic could be used for both fetching and importing the data from the ISO and for
importing it from a local file.
*/
-------------------------------------------------------------------------------------
PROCEDURE PARSE_TAG_RES_REPORT
	(
	p_XML IN XMLTYPE,
	p_RECORDS IN OUT MEX_PJM_EES_TAGRES_TBL,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) IS

  CURSOR c_XML IS
    SELECT EXTRACTVALUE(VALUE(TAGRES), '//tag_id') "TAG_ID",
           EXTRACTVALUE(VALUE(TAGRES), '//rampres_name') "NAME",
           EXTRACTVALUE(VALUE(TAGRES), '//rampres_status') "STATUS",
           EXTRACTVALUE(VALUE(TAGRES), '//implemented_mw') "MW",
           EXTRACTVALUE(VALUE(TAGRES), '//oasis_id') "OASIS_ID",
           TO_DATE(EXTRACTVALUE(VALUE(TAGRES), '//start_date'),
                   g_DATE_TIME_ZONE_FORMAT) "START_DATE",
           TO_DATE(EXTRACTVALUE(VALUE(TAGRES), '//stop_date'),
                   g_DATE_TIME_ZONE_FORMAT) "STOP_DATE"
      FROM TABLE(XMLSEQUENCE(EXTRACT(p_XML, '//tagres'))) TAGRES;

BEGIN

	p_STATUS := MEX_UTIL.G_SUCCESS;

	FOR v_XML IN c_XML LOOP
		--ignore all rows where stop_date < begin_date
		IF v_XML.STOP_DATE >= p_BEGIN_DATE THEN
			p_RECORDS.EXTEND();
			p_RECORDS(p_RECORDS.LAST) := MEX_PJM_EES_TAGRES(tagID         => v_XML.TAG_ID,
                                                      rampResName   => v_XML.NAME,
                                                      rampResStatus => v_XML.STATUS,
                                                      oasisID       => v_XML.OASIS_ID,
                                                      startDate     => v_XML.START_DATE,
                                                      stopDate      => v_XML.STOP_DATE,
                                                      actualMW      => TO_NUMBER(v_XML.MW));
		END IF;

	END LOOP;
EXCEPTION
  WHEN OTHERS THEN
    p_Status  := SQLCODE;
    p_Message := 'ERROR OCCURED IN MEX_PJM_EES.PARSE_TAG_RES_REPORT: ' ||
                 SQLERRM;
END PARSE_TAG_RES_REPORT;
--------------------------------------------------------------------------------------------------
PROCEDURE PARSE_TWO_SETTLEMENT_REPORT(p_XML     IN XMLTYPE,
                                      p_RECORDS IN OUT MEX_PJM_EES_TWOSETTLE_TBL,
                                      p_STATUS  OUT NUMBER,
                                      p_MESSAGE OUT VARCHAR2) IS
  CURSOR cXML IS
    SELECT EXTRACTVALUE(VALUE(TWO_SETTLEMENT), '//schedule_id') "SCHEDULE_ID",
           EXTRACTVALUE(VALUE(TWO_SETTLEMENT), '//status') "STATUS",
           EXTRACTVALUE(VALUE(TWO_SETTLEMENT), '//oasis_id') "OASIS_ID",
           TO_DATE(EXTRACTVALUE(VALUE(TWO_SETTLEMENT), '//start_date'),
                   g_DATE_TIME_ZONE_FORMAT) "START_DATE",
           TO_DATE(EXTRACTVALUE(VALUE(TWO_SETTLEMENT), '//stop_date'),
                   g_DATE_TIME_ZONE_FORMAT) "STOP_DATE",
           EXTRACTVALUE(VALUE(TWO_SETTLEMENT), '//requested_mw') "REQUESTED_MW",
           EXTRACTVALUE(VALUE(TWO_SETTLEMENT), '//cleared_mw') "CLEARED_MW"
      FROM TABLE(XMLSEQUENCE(EXTRACT(p_XML, '//schedule'))) TWO_SETTLEMENT;

BEGIN

  p_STATUS  := MEX_UTIL.G_SUCCESS;

  FOR v_XML IN cXML LOOP

    /*
    need to convert dates from GMT. Example in doc is not GMT, but
    something like to_date('Sun Nov 02 18:00:00 EST 2003', 'Dy Mon DD HH24:MI:SS "EST" YYYY')
    will work. Download something real from EES to get the right format.
    */
    --Ignore rows where stop_date < start_date.
    IF v_XML.STOP_DATE > v_XML.START_DATE THEN
      p_RECORDS.EXTEND();
      p_RECORDS(p_RECORDS.LAST) := MEX_PJM_EES_TWOSETTLE(scheduleID  => v_XML.SCHEDULE_ID,
                                                         status      => v_XML.STATUS,
                                                         oasisID     => v_XML.OASIS_ID,
                                                         startDate   => v_XML.START_DATE,
                                                         stopDate    => v_XML.STOP_DATE,
                                                         requestedMW => v_XML.REQUESTED_MW,
                                                         clearedMW   => v_XML.CLEARED_MW);
    END IF;

  END LOOP;
EXCEPTION
  WHEN OTHERS THEN
    p_STATUS  := SQLCODE;
    p_MESSAGE := 'ERROR OCCURED IN MEX_PJM_EES.PARSE_TWO_SETTLEMENT_REPORT: ' ||
                 SQLERRM;
END PARSE_TWO_SETTLEMENT_REPORT;
----------------------------------------------------------------------------------------------------
PROCEDURE FETCH_TAG_RES_REPORT
	(
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
    p_LOGGER IN OUT NOCOPY MM_LOGGER_ADAPTER,
	p_CRED IN MEX_CREDENTIALS,
	p_LOG_ONLY IN NUMBER,
	p_RECORDS OUT MEX_PJM_EES_TAGRES_TBL,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) IS

	v_XML XMLTYPE;
	v_REQ CLOB := NULL;
	v_RESP CLOB := NULL;
	v_MAP MEX_Util.Parameter_Map := Mex_Switchboard.c_Empty_Parameter_Map;
BEGIN

	p_STATUS  := MEX_UTIL.G_SUCCESS;
	p_RECORDS := MEX_PJM_EES_TAGRES_TBL();

-- mmw The date seems to be ignored.
--   	IF TRUNC(p_BEGIN_DATE) = TRUNC(p_END_DATE) THEN
--   		v_MAP('isodate') := TO_CHAR(p_BEGIN_DATE, 'MM/DD/YYYY');
--   	ELSE
--   		v_MAP('isostart') := TO_CHAR(p_BEGIN_DATE, 'MM/DD/YYYY');
--   		v_MAP('isostop') := TO_CHAR(p_END_DATE, 'MM/DD/YYYY');
--   	END IF;

--	v_MAP('isodebug') := 'false';
--	v_MAP('isosandbox') := 'false';

	v_MAP(MEX_PJM.c_ACTION) := 'download_reservation';

	MEX_PJM.RUN_PJM_BROWSERLESS(v_MAP,
	                            'ees',
	                             p_LOGGER,
	                             p_CRED,
	                             p_BEGIN_DATE,
	                             p_END_DATE,
	                             'DOWNLOAD',
	                     		 v_RESP,                                  
	                             p_STATUS, 
	                             p_MESSAGE,
								 p_LOG_ONLY);
  -- 2/25/2005, jbc: there's a known bug in the report where a start_date = p_BEGIN_DATE
  -- is always returned. We should ignore rows where stop_date < start_date.
	IF p_STATUS <> MEX_UTIL.g_SUCCESS THEN
		v_XML := xmltype(v_RESP);
		PARSE_TAG_RES_REPORT(v_XML, p_RECORDS, p_BEGIN_DATE, p_END_DATE, p_STATUS, p_MESSAGE);
	END IF;

	IF NOT v_RESP IS NULL THEN
		DBMS_LOB.FREETEMPORARY(v_RESP);
	END IF;

END FETCH_TAG_RES_REPORT;
----------------------------------------------------------------------------------------------------

PROCEDURE FETCH_TWO_SETTLEMENT_REPORT
	(
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
    p_LOGGER IN OUT NOCOPY MM_LOGGER_ADAPTER,
	p_CRED IN MEX_CREDENTIALS,
	p_LOG_ONLY IN NUMBER,
	p_RECORDS OUT MEX_PJM_EES_TWOSETTLE_TBL,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) IS

	v_XML XMLTYPE;
	v_RESP CLOB := NULL;
	v_REQ CLOB := NULL;
	v_MAP MEX_Util.Parameter_Map := Mex_Switchboard.c_Empty_Parameter_Map;
BEGIN

	p_RECORDS := MEX_PJM_EES_TWOSETTLE_TBL();
	p_STATUS  := MEX_UTIL.G_SUCCESS;

	v_MAP('twosettle') := 'true';
	v_MAP(MEX_PJM.c_ACTION) := 'download_twosettle';

	MEX_PJM.RUN_PJM_BROWSERLESS(v_MAP,
	                            'ees',
	                             p_LOGGER,
	                             p_CRED,
	                             p_BEGIN_DATE,
	                             p_END_DATE,
	                             'DOWNLOAD',
	                     		 v_RESP,                                  
	                             p_STATUS, 
	                             p_MESSAGE,
								 p_LOG_ONLY);

	IF p_STATUS <> MEX_UTIL.g_SUCCESS THEN
		v_XML := xmltype(v_RESP);
		PARSE_TWO_SETTLEMENT_REPORT(v_XML, p_RECORDS, p_STATUS, p_MESSAGE);
	END IF;

	IF NOT v_RESP IS NULL THEN
		DBMS_LOB.FREETEMPORARY(v_RESP);
	END IF;


END FETCH_TWO_SETTLEMENT_REPORT;

----------------------------------------------------------------------------------------------------

PROCEDURE GETX_TAG_RESERVATION
	(
	p_RECORDS MEX_PJM_EES_RAMPRES_TBL,
	P_XML_REQUEST_BODY OUT XMLTYPE,
	P_STATUS OUT NUMBER,
	P_MESSAGE OUT VARCHAR2
	) AS

	v_XML_FRAGMENT XMLTYPE;
	v_RESERVATION_FRAGMENT XMLTYPE;
	v_IDX BINARY_INTEGER;
BEGIN

	P_STATUS := MEX_UTIL.G_SUCCESS;

	-- don't forget to handle time zone, or convert to GMT
	-- convert to GMT and hour-beginning should be an MM responsibility (?)
	v_IDX := p_RECORDS.FIRST();
	WHILE p_RECORDS.EXISTS(v_IDX) LOOP
		SELECT XMLELEMENT("reservation",
											XMLELEMENT("upload_type", 'Submit New'),
											XMLELEMENT("pjm_id"),
											XMLELEMENT("reservation_name", p_RECORDS(v_IDX).RESERVATION_NAME),
											XMLELEMENT("outside_id"),
											XMLELEMENT("path", p_RECORDS(v_IDX).PATH),
											XMLELEMENT("realtime_profile",
																 XMLAGG(XMLELEMENT("energy_interval",
																									 XMLELEMENT("price", T.PRICE),
																									 XMLELEMENT("mw_value", T.QUANTITY),
																									 XMLELEMENT("interval_definition",
																															XMLELEMENT("interval_start",
																																				 XMLELEMENT("date",
																																										TO_CHAR(T.BEGIN_DATE,
																																														'YYYY-MM-DD')),
																																				 XMLELEMENT("time",
																																										TO_CHAR(T.BEGIN_DATE,
																																														'HH24:MM:SS'))),
																															XMLELEMENT("interval_end",
																																				 XMLELEMENT("date",
																																										TO_CHAR(T.END_DATE,
																																														'YYYY-MM-DD')),
																																				 XMLELEMENT("time",
																																										TO_CHAR(T.END_DATE,
																																														'HH24:MM:SS'))))))))
			INTO v_RESERVATION_FRAGMENT
			FROM TABLE(p_RECORDS(v_IDX).REALTIME_PROFILE) T;
  	SELECT XMLCONCAT(v_XML_FRAGMENT, v_RESERVATION_FRAGMENT) INTO v_XML_FRAGMENT FROM DUAL;
    v_IDX := p_RECORDS.NEXT(v_IDX);
	END LOOP;

  SELECT XMLELEMENT("ees", v_XML_FRAGMENT) INTO P_XML_REQUEST_BODY FROM DUAL;

EXCEPTION
	WHEN OTHERS THEN
		P_STATUS  := SQLCODE;
		P_MESSAGE := 'Error in MEX_PJM_EES.GETX_TAG_RESERVATION: ' || SQLERRM;
END GETX_TAG_RESERVATION;

  --------------------------------------------------------------------------------------------------------

PROCEDURE SUBMIT_TAG_RESERVATION
	(
	p_PARAMETER_MAP IN OUT MEX_Util.Parameter_Map,
	p_BEGIN_DATE    IN DATE,
	p_END_DATE		IN DATE,
	p_RECORDS 		IN OUT MEX_PJM_EES_RAMPRES_TBL,
	p_LOGGER 		IN OUT MM_LOGGER_ADAPTER,
	p_CRED 			IN MEX_CREDENTIALS,
	p_LOG_ONLY		IN NUMBER,
	p_STATUS 		OUT NUMBER,
	p_MESSAGE 		OUT VARCHAR2
	) IS
	v_XML_REQUEST  XMLTYPE;
	v_XML_RESPONSE XMLTYPE;
	v_RESPONSE     CLOB;
  	v_IDX VARCHAR2(32);
BEGIN
	p_STATUS  := MEX_UTIL.g_SUCCESS;

	GETX_TAG_RESERVATION(p_RECORDS, v_XML_REQUEST, p_STATUS, p_MESSAGE);
	MEX_PJM.RUN_PJM_BROWSERLESS(p_PARAMETER_MAP,
	                            'ees',
	                             p_LOGGER,
	                             p_CRED,
	                             p_BEGIN_DATE,
	                             p_END_DATE,
	                             'upload',
	                     		 v_RESPONSE,                                  
	                             p_STATUS, 
	                             p_MESSAGE,
								 'xml',
								 v_XML_REQUEST.Getclobval(),
								 p_LOG_ONLY);
								 
	IF p_STATUS = MEX_SWITCHBOARD.c_Status_Success THEN
    NULL;
		--PARSE_TAG_RESERVATION(XMLTYPE(v_RESPONSE), p_RECORDS, p_STATUS, p_MESSAGE);
	END IF;

EXCEPTION
	WHEN OTHERS THEN
		p_STATUS  := SQLCODE;
		p_MESSAGE := 'Error in MEX_PJM_EES.SUBMIT_TAG_RESERVATION: ' || SQLERRM;
END SUBMIT_TAG_RESERVATION;

--------------------------------------------------------------------------------------------------------

end MEX_PJM_EES;
/
