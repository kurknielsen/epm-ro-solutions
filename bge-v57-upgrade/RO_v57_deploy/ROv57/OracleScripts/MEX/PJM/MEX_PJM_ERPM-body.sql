CREATE OR REPLACE PACKAGE BODY MEX_PJM_ERPM IS

g_PJM_ERPM_NAMESPACE CONSTANT VARCHAR2(64) := 'xmlns="http://erpm.pjm.com/rpm/xml"';
g_PJM_ERPM_NAMESPACE_NAME CONSTANT VARCHAR2(64) := 'http://erpm.pjm.com/rpm/xml';
g_PJM_ERPM_MKT CONSTANT VARCHAR2(8) := 'pjmerpm';

---------------------------------------------------------------------------------------------------
FUNCTION WHAT_VERSION RETURN VARCHAR IS
BEGIN
     RETURN '$Revision: 1.1 $';
END WHAT_VERSION;
---------------------------------------------------------------------------------------------------
FUNCTION SAFE_STRING
    (
    p_XML       IN XMLTYPE,
    p_XPATH     IN VARCHAR2,
    p_NAMESPACE IN VARCHAR2 := NULL
    ) RETURN VARCHAR2 IS
    --RETURN TEXT FOR A PATH OR NULL IF IT DOESN'T EXIST.
v_XMLTMP XMLTYPE;
    BEGIN
        v_XMLTMP := XMLTYPE.EXTRACT(p_XML, p_XPATH, p_NAMESPACE);
        IF v_XMLTMP IS NULL THEN
            RETURN NULL;
        ELSE
            RETURN v_XMLTMP.GETSTRINGVAL();
        END IF;
END SAFE_STRING;
---------------------------------------------------------------------------------------
PROCEDURE RUN_PJM_QUERY
    (
    P_CRED IN mex_credentials,
	P_LOG_ONLY	IN NUMBER,
    p_XML_REQUEST_BODY  IN XMLTYPE,
    p_XML_RESPONSE_BODY OUT XMLTYPE,
    p_STATUS OUT NUMBER,
    p_ERROR_MESSAGE OUT VARCHAR2,
	p_LOGGER IN OUT mm_logger_adapter) AS
BEGIN
    p_STATUS := MEX_UTIL.g_SUCCESS;

	MEX_PJM.RUN_PJM_ACTION(P_CRED,
				   'query',
				   P_LOG_ONLY,
                   P_XML_REQUEST_BODY,
				   g_PJM_ERPM_NAMESPACE,
				   g_PJM_ERPM_MKT,
                   P_XML_RESPONSE_BODY,
				   p_STATUS,
                   P_ERROR_MESSAGE,
				   P_LOGGER);


    IF p_ERROR_MESSAGE IS NOT NULL THEN
        p_STATUS := 1;
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        p_ERROR_MESSAGE := 'MEX_PJM_EMKT.RUN_PJM_QUERY: ' || UT.GET_FULL_ERRM;
END RUN_PJM_QUERY;
-------------------------------------------------------------------------------------
PROCEDURE GETX_QUERY_NSPL
    (
    p_BEGIN_DATE IN DATE,
	p_COMPANY_NAME IN VARCHAR2,
    p_XML_REQUEST_BODY OUT XMLTYPE,
    p_STATUS OUT NUMBER,
    p_MESSAGE OUT VARCHAR2
    ) AS
BEGIN
    p_STATUS  := MEX_UTIL.G_SUCCESS;
    SELECT XMLELEMENT("QueryRequest", XMLATTRIBUTES(g_PJM_ERPM_NAMESPACE_NAME AS "xmlns"),
    		XMLELEMENT("QueryDailyZonalNSPLDetail",
    		XMLATTRIBUTES(to_Char(p_BEGIN_DATE, MEX_PJM_EMKT.G_DATE_FORMAT) AS "StartDay",
            p_COMPANY_NAME AS "CompanyName")))
    	INTO p_XML_REQUEST_BODY
    	FROM DUAL;

EXCEPTION
    WHEN OTHERS THEN
      p_STATUS  := SQLCODE;
      p_MESSAGE := 'ERROR OCCURED IN MEX_PJM_ERPM.GETX_QUERY_NSPL' || UT.GET_FULL_ERRM;
END GETX_QUERY_NSPL;
----------------------------------------------------------------------------------------------
PROCEDURE GETX_QUERY_CAP_OBLIG
    (
	p_BEGIN_DATE IN DATE,
	p_COMPANY_NAME IN VARCHAR2,
    p_XML_REQUEST_BODY OUT XMLTYPE,
    p_STATUS OUT NUMBER,
    p_MESSAGE OUT VARCHAR2
    ) AS

v_REPORT_NAME VARCHAR2(35) := 'QueryDailyZonalLoadObligationDetail';
v_REQUEST VARCHAR2(1042);
BEGIN
    p_STATUS  := MEX_UTIL.G_SUCCESS;
    --due to length of QueryDailyZonalLoadObligationDetail, must create request as text

    v_REQUEST := '<' || 'QueryRequest ' || g_PJM_ERPM_NAMESPACE || '><' || v_REPORT_NAME || ' CompanyName='
    || '"' || p_COMPANY_NAME || '"' || ' StartDay=' || '"' || to_Char(p_BEGIN_DATE, MEX_PJM_EMKT.G_DATE_FORMAT)
    || '"' || '> </' || v_REPORT_NAME || '></QueryRequest>';

    p_XML_REQUEST_BODY := XMLTYPE.CREATEXML(v_REQUEST);

  /*  SELECT XMLELEMENT("QueryRequest", XMLATTRIBUTES(g_PJM_ERPM_NAMESPACE_NAME AS "xmlns"),
    		XMLELEMENT("QueryDailyZonalLoadObligationDetail",
    		XMLATTRIBUTES(p_PARAMETER_MAP('BeginDate') AS "StartDay",
            p_PARAMETER_MAP('CompanyName') AS "CompanyName")))
    	INTO p_XML_REQUEST_BODY
    	FROM DUAL;   */

EXCEPTION
    WHEN OTHERS THEN
      p_STATUS  := SQLCODE;
      p_MESSAGE := 'ERROR OCCURED IN MEX_PJM_ERPM.GETX_QUERY_CAP_OBLIG' || UT.GET_FULL_ERRM;
END GETX_QUERY_CAP_OBLIG;
----------------------------------------------------------------------------------------------
PROCEDURE PARSE_NETWK_SERV_PK_LD
    (
    p_XML_RESPONSE IN XMLTYPE,
    p_RECORDS IN OUT NOCOPY MEX_PJM_ECAP_LOAD_OBL_TBL,
    p_STATUS OUT NUMBER,
    p_MESSAGE OUT VARCHAR2
    ) AS

CURSOR c_XML IS
    SELECT EXTRACTVALUE(VALUE(T), '//@LSEName', g_PJM_ERPM_NAMESPACE) "LSE",
             EXTRACTVALUE(VALUE(T), '//@ZoneName', g_PJM_ERPM_NAMESPACE) "ZONE",
             EXTRACTVALUE(VALUE(T), '//@AreaName', g_PJM_ERPM_NAMESPACE) "AREA",
             EXTRACTVALUE(VALUE(U), '//@Day', g_PJM_ERPM_NAMESPACE) "DAY",
             EXTRACTVALUE(VALUE(U), '//NSPL', g_PJM_ERPM_NAMESPACE) "NSPL"
    FROM TABLE(XMLSEQUENCE(EXTRACT(p_XML_RESPONSE,
                                       '//DailyZonalNSPLDetailSet/DailyZonalNSPLDetail',
                                       g_PJM_ERPM_NAMESPACE))) T,
             TABLE(XMLSEQUENCE(EXTRACT(VALUE(T),
                                       '//DailyZonalNSPL',
                                       g_PJM_ERPM_NAMESPACE))) U
    ORDER BY 4;

BEGIN
    p_STATUS  := MEX_UTIL.G_SUCCESS;
    FOR v_XML IN c_XML LOOP

        p_RECORDS.EXTEND();
        p_RECORDS(p_RECORDS.LAST) := MEX_PJM_ECAP_LOAD_OBL
                                        (
                                        SYSDATE,
                                        v_XML.LSE,
                                        'NSPL',
                                        v_XML.ZONE,
                                        v_XML.LSE,
                                        TO_DATE(v_XML.DAY,'YYYY-MM-DD'),
                                        NULL,
                                        v_XML.AREA,
                                        v_XML.LSE,
                                        NULL,
                                        NULL,
                                        v_XML.NSPL,
                                        NULL,
                                        NULL,
                                        NULL);

    END LOOP;

EXCEPTION
    WHEN OTHERS THEN
      p_STATUS  := SQLCODE;
      p_MESSAGE := 'ERROR OCCURED IN MEX_PJM_ERPM.PARSE_NETWK_SERV_PK_LD' || UT.GET_FULL_ERRM;

END PARSE_NETWK_SERV_PK_LD;
----------------------------------------------------------------------------------------------
PROCEDURE PARSE_CAPACITY_OBLIG
    (
    p_XML_RESPONSE IN XMLTYPE,
    p_RECORDS IN OUT NOCOPY MEX_PJM_ECAP_LOAD_OBL_TBL,
    p_STATUS OUT NUMBER,
    p_MESSAGE OUT VARCHAR2
    ) AS

CURSOR c_XML IS
    SELECT EXTRACTVALUE(VALUE(T), '//@LSEName', g_PJM_ERPM_NAMESPACE) "LSE",
             EXTRACTVALUE(VALUE(T), '//@ZoneName', g_PJM_ERPM_NAMESPACE) "ZONE",
             EXTRACTVALUE(VALUE(T), '//@AreaName', g_PJM_ERPM_NAMESPACE) "AREA",
             EXTRACTVALUE(VALUE(U), '//@Day', g_PJM_ERPM_NAMESPACE) "DAY",
             EXTRACTVALUE(VALUE(U), '//ObligationPeakLoad', g_PJM_ERPM_NAMESPACE) "PEAKLOAD",
             EXTRACTVALUE(VALUE(U), '//DailyUCAPObligation', g_PJM_ERPM_NAMESPACE) "OBLIGATION"
    FROM TABLE(XMLSEQUENCE(EXTRACT(p_XML_RESPONSE,
                                       '//DailyZonalLoadObligationDetailSet/DailyZonalLoadObligationDetail',
                                       g_PJM_ERPM_NAMESPACE))) T,
             TABLE(XMLSEQUENCE(EXTRACT(VALUE(T),
                                       '//DailyZonalLoadObligation',
                                       g_PJM_ERPM_NAMESPACE))) U
    ORDER BY 4;

BEGIN
    p_STATUS  := MEX_UTIL.G_SUCCESS;
    FOR v_XML IN c_XML LOOP

        p_RECORDS.EXTEND();
        p_RECORDS(p_RECORDS.LAST) := MEX_PJM_ECAP_LOAD_OBL
                                        (
                                        SYSDATE,
                                        v_XML.LSE,
                                        'NSPL',
                                        v_XML.ZONE,
                                        v_XML.LSE,
                                        TO_DATE(v_XML.DAY,'YYYY-MM-DD'),
                                        NULL,
                                        v_XML.AREA,
                                        v_XML.LSE,
                                        v_XML.PEAKLOAD,
                                        v_XML.OBLIGATION,
                                        NULL,
                                        NULL,
                                        NULL,
                                        NULL);

    END LOOP;

EXCEPTION
    WHEN OTHERS THEN
      p_STATUS  := SQLCODE;
      p_MESSAGE := 'ERROR OCCURED IN MEX_PJM_ERPM.PARSE_CAPACITY_OBLIG' || UT.GET_FULL_ERRM;

END PARSE_CAPACITY_OBLIG;
--------------------------------------------------------------------------------------
PROCEDURE FETCH_NETWK_SERV_PK_LD
    (
	p_CRED	IN mex_credentials,
	p_LOG_ONLY IN NUMBER,
	p_BEGIN_DATE IN DATE,
	p_COMPANY_NAME IN VARCHAR2,
    p_RECORDS OUT MEX_PJM_ECAP_LOAD_OBL_TBL,
    p_STATUS OUT NUMBER,
    p_MESSAGE OUT VARCHAR2,
	p_LOGGER IN OUT mm_logger_adapter) AS

v_XML_REQUEST  XMLTYPE;
v_XML_RESPONSE XMLTYPE;

BEGIN

    p_RECORDS := MEX_PJM_ECAP_LOAD_OBL_TBL();
    p_STATUS  := MEX_UTIL.G_SUCCESS;

    GETX_QUERY_NSPL(p_BEGIN_DATE, p_COMPANY_NAME, v_XML_REQUEST, p_STATUS, p_MESSAGE);

	RUN_PJM_QUERY(P_CRED,
				    P_LOG_ONLY,
					V_XML_REQUEST,
					V_XML_RESPONSE,
					p_STATUS,
					P_MESSAGE,
					P_LOGGER);


    IF p_STATUS = MEX_UTIL.G_SUCCESS THEN
        PARSE_NETWK_SERV_PK_LD(v_XML_RESPONSE, p_RECORDS, p_STATUS, p_MESSAGE);
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        p_STATUS  := SQLCODE;
        p_MESSAGE := 'Error in MEX_PJM_ERPM.FETCH_NETWK_SERV_PK_LD: ' || UT.GET_FULL_ERRM;
END FETCH_NETWK_SERV_PK_LD;
----------------------------------------------------------------------------------------
PROCEDURE FETCH_CAPACITY_OBLIGATION
    (
	p_CRED IN mex_credentials,
	p_LOG_ONLY IN NUMBER,
    p_BEGIN_DATE IN DATE,
	p_COMPANY_NAME IN VARCHAR2,
    p_RECORDS OUT MEX_PJM_ECAP_LOAD_OBL_TBL,
    p_STATUS OUT NUMBER,
    p_MESSAGE OUT VARCHAR2,
	p_LOGGER IN OUT mm_logger_adapter) AS

v_XML_REQUEST  XMLTYPE;
v_XML_RESPONSE XMLTYPE;

BEGIN

    p_RECORDS := MEX_PJM_ECAP_LOAD_OBL_TBL();
    p_STATUS  := MEX_UTIL.G_SUCCESS;
--    p_PARAMETER_MAP('ReportName') := 'QueryDailyZonalLoadObligationDetail';

    GETX_QUERY_CAP_OBLIG(p_BEGIN_DATE, p_COMPANY_NAME, v_XML_REQUEST, p_STATUS, p_MESSAGE);


	 RUN_PJM_QUERY(P_CRED,
				    P_LOG_ONLY,
					V_XML_REQUEST,
					V_XML_RESPONSE,
					p_STATUS,
					P_MESSAGE,
					P_LOGGER);

    IF p_STATUS = MEX_UTIL.G_SUCCESS THEN
        PARSE_CAPACITY_OBLIG(v_XML_RESPONSE, p_RECORDS, p_STATUS, p_MESSAGE);
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        p_STATUS  := SQLCODE;
        p_MESSAGE := 'Error in MEX_PJM_ERPM.FETCH_CAPACITY_OBLIGATION: ' || UT.GET_FULL_ERRM;
END FETCH_CAPACITY_OBLIGATION;
----------------------------------------------------------------------------------------

END MEX_PJM_ERPM;
/
