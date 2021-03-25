CREATE OR REPLACE PACKAGE MEX_NYISO_SETTLEMENT IS
-- $Revision: 1.8 $

	-- Author  : LDUMITRIU
	-- Created : 6/20/2006 10:16:35
	-- Purpose :

	TYPE DSS_REPORT_MAP IS TABLE OF VARCHAR2(256) INDEX BY VARCHAR2(256);
	g_DSS_REP_MAP DSS_REPORT_MAP;


	g_DSS_TIME_ZONE  CONSTANT VARCHAR2(3) := 'GMT';
	g_DSS_DATE_TIME_FORMAT CONSTANT VARCHAR2(21) := 'YYYY/MM/DD HH24:MI:SS';

	g_NYISO_DSS_MARKET              CONSTANT VARCHAR2(14) := 'nyiso-dss';
	g_DSS_FILE_LIST_ACTION          CONSTANT VARCHAR2(14) := 'filelist';
	g_DSS_FILE_RETRIEVE_ACTION      CONSTANT VARCHAR2(14) := 'fileretrieve';
	g_DSS_FILE_DELETE_ACTION        CONSTANT VARCHAR2(14) := 'filedelete';
	g_DSS_LOGOUT_ACTION             CONSTANT VARCHAR2(14) := 'logout';
	g_DSS_AUTOMATED_LEVEL           CONSTANT NUMBER(1) := 3;

	g_DSS_INVOICE_REPORT_NAME       CONSTANT VARCHAR2(32) := 'Invoice Availability';
	g_DSS_DAM_ENERG_REP_NAME        CONSTANT VARCHAR2(32) := 'LSE_DAM_Energy';
	g_DSS_NYISO_TOTAL_REP_NAME      CONSTANT VARCHAR2(32) := 'LSE_NYISO_Totals';
	g_DSS_NYISO_RESID_REP_NAME      CONSTANT VARCHAR2(32) := 'LSE_NYISO_Residuals';
	g_DSS_NYISO_RATES_REP_NAME      CONSTANT VARCHAR2(32) := 'LSE_NYISO_Rates';
	g_DSS_BAL_MKT_EN_REP_NAME       CONSTANT VARCHAR2(32) := 'LSE_SCDBalMkt_Enrg';
    g_DSS_DAM_VIRT_SUPPLY_REP_NAME  CONSTANT VARCHAR2(32) := 'VC_DAM_Virtual_Supply';
    g_DSS_DAM_VIRT_LOAD_REP_NAME    CONSTANT VARCHAR2(32) := 'VC_DAM_Virtual_Load';
	g_DSS_BAL_MKT_VL_REP_NAME       CONSTANT VARCHAR2(32) := 'VC_SCDBalMkt_VL';
	g_DSS_BAL_MKT_VS_REP_NAME       CONSTANT VARCHAR2(32) := 'VC_SCDBalMkt_VS';
	g_DSS_DATE_FORMAT               CONSTANT VARCHAR2(16) := 'Dy Mon DD YYYY';
	
	g_REQUEST_CONTENT_TYPE CONSTANT  VARCHAR2(16) := 'text/x-oasis-csv';
	
    -- Error messages when retrieving files from DSS
    g_DSS_ERR_NO_ERROR                CONSTANT NUMBER(1) := 0;
    g_DSS_ERR_ZERO_ROWS               CONSTANT NUMBER(1) := -1;
    g_DSS_ERR_ROWCOUNT_EXCEEDED       CONSTANT NUMBER(1) := -2;
    g_DSS_ERR_FILESIZE_EXCEEDED       CONSTANT NUMBER(1) := -3;

    -- Stores the cookie string globally. Set it only when retrieving the Inbox list
    -- Reset it when you logout.
    g_DSS_COOKIE_STRING        VARCHAR(8192);
	

FUNCTION WHAT_VERSION RETURN VARCHAR2;

	FUNCTION GET_COOKIE_STRING(p_COOKIES MEX_COOKIE_TBL) RETURN VARCHAR2;
    FUNCTION CHECK_ERROR_MESSAGES(p_CLOB CLOB, p_LOGGER IN OUT NOCOPY mm_logger_adapter) RETURN NUMBER;

    ------------------------------------------------------------------------------------
    PROCEDURE FETCH_INBOX_LIST(p_CRED    IN mex_credentials,
							   p_RECORDS   OUT MEX_NY_DOC_IDENT_TBL,
							   p_STATUS    OUT NUMBER,
							   p_LOGGER IN OUT NOCOPY mm_logger_adapter);

	PROCEDURE FETCH_DAM_ENERGY(p_DATE            IN DATE,
							   p_DOC_LIST        IN MEX_NY_DOC_IDENT_TBL,
							   p_CRED    IN mex_credentials,
							   p_REPORT_TYPE     IN VARCHAR2,
							   p_RECORDS         OUT MEX_NY_DAM_ENERGY_TBL,
							   p_STATUS          OUT NUMBER,
							   p_LOGGER IN OUT NOCOPY mm_logger_adapter);

	PROCEDURE FETCH_BAL_MARKET_ENERGY(p_DATE            IN DATE,
									  p_DOC_LIST        IN MEX_NY_DOC_IDENT_TBL,
									  p_CRED    IN mex_credentials,
									  p_REPORT_TYPE     IN VARCHAR2,
									  p_RECORDS         OUT MEX_NY_BAL_MKT_EN_TBL,
									  p_STATUS          OUT NUMBER,
									  p_LOGGER IN OUT NOCOPY mm_logger_adapter);

    PROCEDURE FETCH_DAM_VIRTUAL_SUPPLY(p_DATE            IN DATE,
							           p_DOC_LIST        IN MEX_NY_DOC_IDENT_TBL,
							           p_CRED    IN mex_credentials,
                                       p_REPORT_TYPE     IN VARCHAR2,
							           p_RECORDS         OUT MEX_NY_DAM_VIR_SUP_TBL,
							           p_STATUS          OUT NUMBER,
							           p_LOGGER IN OUT NOCOPY mm_logger_adapter);

    PROCEDURE FETCH_DAM_VIRTUAL_LOAD(p_DATE            IN DATE,
							           p_DOC_LIST        IN MEX_NY_DOC_IDENT_TBL,
							           p_CRED    IN mex_credentials,
                                       p_REPORT_TYPE     IN VARCHAR2,
							           p_RECORDS         OUT MEX_NY_DAM_VIR_LOAD_TBL,
							           p_STATUS          OUT NUMBER,
							           p_LOGGER IN OUT NOCOPY mm_logger_adapter);

	PROCEDURE FETCH_NYISO_TOTALS(p_DATE            IN DATE,
								 p_DOC_LIST        IN MEX_NY_DOC_IDENT_TBL,
								 p_CRED    IN mex_credentials,
								 p_REPORT_TYPE     IN VARCHAR2,
								 p_RECORDS         OUT MEX_NY_TOTAL_TBL,
								 p_STATUS          OUT NUMBER,
								 p_LOGGER IN OUT NOCOPY mm_logger_adapter);

	PROCEDURE FETCH_NYISO_RESIDUALS(p_DATE            IN DATE,
									p_DOC_LIST        IN MEX_NY_DOC_IDENT_TBL,
									p_CRED    IN mex_credentials,
									p_REPORT_TYPE     IN VARCHAR2,
									p_RECORDS         OUT MEX_NY_RESIDUAL_TBL,
									p_STATUS          OUT NUMBER,
									p_LOGGER IN OUT NOCOPY mm_logger_adapter);

	PROCEDURE FETCH_NYISO_RATES(p_DATE            IN DATE,
								p_DOC_LIST        IN MEX_NY_DOC_IDENT_TBL,
								p_CRED    IN mex_credentials,
								p_REPORT_TYPE     IN VARCHAR2,
								p_RECORDS         OUT MEX_NY_RATES_TBL,
								p_STATUS          OUT NUMBER,
								p_LOGGER IN OUT NOCOPY mm_logger_adapter);

	PROCEDURE FETCH_INVOICE_SUMMARY(p_DATE            IN DATE,
									p_DOC_LIST        IN MEX_NY_DOC_IDENT_TBL,
									p_CRED    IN mex_credentials,
									p_RECORDS         OUT MEX_NY_INVOICE_TBL,
                                    p_DSS_ERROR_MESSAGE_TYPE OUT NUMBER,
									p_STATUS          OUT NUMBER,
									p_LOGGER IN OUT NOCOPY mm_logger_adapter);

	PROCEDURE FETCH_BAL_MKT_VIRT_LOAD(p_DATE            IN DATE,
    								  p_DOC_LIST        IN MEX_NY_DOC_IDENT_TBL,
    								  p_CRED    IN mex_credentials,
    								  p_REPORT_TYPE     IN VARCHAR2,
    								  p_RECORDS         OUT MEX_NY_BAL_VL_TBL,
    								  p_STATUS          OUT NUMBER,
    								  p_LOGGER IN OUT NOCOPY mm_logger_adapter);

	PROCEDURE FETCH_BAL_MKT_VIRT_SUPPLY(p_DATE            IN DATE,
    									p_DOC_LIST        IN MEX_NY_DOC_IDENT_TBL,
    									p_CRED    IN mex_credentials,
    									p_REPORT_TYPE     IN VARCHAR2,
    									p_RECORDS         OUT MEX_NY_BAL_VS_TBL,
    									p_STATUS          OUT NUMBER,
    									p_LOGGER IN OUT NOCOPY mm_logger_adapter);
	------------------------------------------------------------------------------------

	PROCEDURE PARSE_INBOX_LIST(p_CLOB        IN CLOB,
						   p_RECORDS     IN OUT MEX_NY_DOC_IDENT_TBL,
						   p_STATUS      OUT NUMBER,
						   p_LOGGER IN OUT NOCOPY mm_logger_adapter);

	PROCEDURE PARSE_INVOICE_SUMMARY(p_CLOB    IN CLOB,
								p_RECORDS OUT MEX_NY_INVOICE_TBL,
                                p_DSS_ERROR_MESSAGE_TYPE OUT NUMBER,
								p_STATUS  OUT NUMBER,
								p_LOGGER IN OUT NOCOPY mm_logger_adapter);

	PROCEDURE PARSE_NYISO_RATES(p_CLOB    IN CLOB,
							p_RECORDS OUT MEX_NY_RATES_TBL,
							p_STATUS  OUT NUMBER,
							p_LOGGER IN OUT NOCOPY mm_logger_adapter);

	PROCEDURE PARSE_DAM_ENERGY(p_CLOB    IN CLOB,
							   p_RECORDS OUT MEX_NY_DAM_ENERGY_TBL,
							   p_STATUS  OUT NUMBER,
							   p_LOGGER IN OUT NOCOPY mm_logger_adapter);

	PROCEDURE PARSE_BAL_MARKET_ENERGY(p_CLOB    IN CLOB,
								  p_RECORDS OUT MEX_NY_BAL_MKT_EN_TBL,
								  p_STATUS  OUT NUMBER,
								  p_LOGGER IN OUT NOCOPY mm_logger_adapter);

    PROCEDURE PARSE_DAM_VIRTUAL_SUPPLY(p_CLOB IN CLOB,
							           p_RECORDS OUT MEX_NY_DAM_VIR_SUP_TBL,
							           p_STATUS  OUT NUMBER,
							           p_LOGGER IN OUT NOCOPY mm_logger_adapter);

    PROCEDURE PARSE_DAM_VIRTUAL_LOAD(p_CLOB    IN CLOB,
							         p_RECORDS OUT MEX_NY_DAM_VIR_LOAD_TBL,
							         p_STATUS  OUT NUMBER,
							         p_LOGGER IN OUT NOCOPY mm_logger_adapter);

	PROCEDURE PARSE_NYISO_TOTALS(p_CLOB    IN CLOB,
							 p_RECORDS OUT MEX_NY_TOTAL_TBL,
							 p_STATUS  OUT NUMBER,
							 p_LOGGER IN OUT NOCOPY mm_logger_adapter);

	PROCEDURE PARSE_NYISO_RESIDUALS(p_CLOB    IN CLOB,
								p_RECORDS OUT MEX_NY_RESIDUAL_TBL,
								p_STATUS  OUT NUMBER,
								p_LOGGER IN OUT NOCOPY mm_logger_adapter);

	PROCEDURE PARSE_BAL_MKT_VIRT_SUPPLY(p_CLOB    IN CLOB,
									p_RECORDS OUT MEX_NY_BAL_VS_TBL,
									p_STATUS  OUT NUMBER,
									p_LOGGER IN OUT NOCOPY mm_logger_adapter);

	PROCEDURE PARSE_BAL_MKT_VIRT_LOAD(p_CLOB    IN CLOB,
								  p_RECORDS OUT MEX_NY_BAL_VL_TBL,
								  p_STATUS  OUT NUMBER,
								  p_LOGGER IN OUT NOCOPY mm_logger_adapter);
    ------------------------------------------------------------------------------------
    PROCEDURE DELETE_DSS_REPORTS(p_CRED    IN mex_credentials,
                            p_DATE             IN DATE,
							p_DOC_LIST         IN MEX_NY_DOC_IDENT_TBL,
							p_STATUS           OUT NUMBER,
							p_LOGGER         IN OUT mm_logger_adapter);
    ------------------------------------------------------------------------------------
	----================================================================================
	/*PROCEDURE FETCH_NYISO_RATES(p_DATE            IN DATE,
							p_DOC_LIST        IN MEX_NY_DOC_IDENT_TBL,
							p_CRED    IN mex_credentials,
							p_REPORT_TYPE     IN VARCHAR2,
							p_STATUS          OUT NUMBER,
							p_MESSAGE         OUT VARCHAR2);

	PROCEDURE FETCH_NYISO_RESIDUALS(p_DATE            IN DATE,
									p_DOC_LIST        IN MEX_NY_DOC_IDENT_TBL,
									p_CRED    IN mex_credentials,
									p_REPORT_TYPE     IN VARCHAR2,
									p_STATUS          OUT NUMBER,
									p_MESSAGE         OUT VARCHAR2);

	PROCEDURE FETCH_NYISO_TOTALS(p_DATE            IN DATE,
								 p_DOC_LIST        IN MEX_NY_DOC_IDENT_TBL,
								 p_CRED    IN mex_credentials,
								 p_REPORT_TYPE     IN VARCHAR2,
								 p_STATUS          OUT NUMBER,
								 p_MESSAGE         OUT VARCHAR2);

	PROCEDURE FETCH_DAM_ENERGY(p_DATE            IN DATE,
							   p_DOC_LIST        IN MEX_NY_DOC_IDENT_TBL,
							   p_CRED    IN mex_credentials,
							   p_REPORT_TYPE     IN VARCHAR2,
							   p_STATUS          OUT NUMBER,
							   p_MESSAGE         OUT VARCHAR2);

	PROCEDURE FETCH_DAM_VIRTUAL_SUPPLY(p_DATE            IN DATE,
							           p_DOC_LIST        IN MEX_NY_DOC_IDENT_TBL,
							           p_CRED    IN mex_credentials,
                                       p_REPORT_TYPE     IN VARCHAR2,
							           p_STATUS          OUT NUMBER,
							           p_MESSAGE         OUT VARCHAR2);

    PROCEDURE FETCH_DAM_VIRTUAL_LOAD(p_DATE            IN DATE,
							           p_DOC_LIST        IN MEX_NY_DOC_IDENT_TBL,
							           p_CRED    IN mex_credentials,
                                       p_REPORT_TYPE     IN VARCHAR2,
							           p_STATUS          OUT NUMBER,
							           p_MESSAGE         OUT VARCHAR2);

	PROCEDURE FETCH_BAL_MARKET_ENERGY(p_DATE            IN DATE,
								  p_DOC_LIST        IN MEX_NY_DOC_IDENT_TBL,
								  p_CRED    IN mex_credentials,
								  p_REPORT_TYPE     IN VARCHAR2,
								  p_STATUS          OUT NUMBER,
								  p_MESSAGE         OUT VARCHAR2);

	PROCEDURE FETCH_BAL_MKT_VIRT_LOAD(p_DATE            IN DATE,
								  p_DOC_LIST        IN MEX_NY_DOC_IDENT_TBL,
								  p_CRED    IN mex_credentials,
								  p_REPORT_TYPE     IN VARCHAR2,
								  p_STATUS          OUT NUMBER,
								  p_MESSAGE         OUT VARCHAR2);

	PROCEDURE FETCH_BAL_MKT_VIRT_SUPPLY(p_DATE            IN DATE,
									p_DOC_LIST        IN MEX_NY_DOC_IDENT_TBL,
									p_CRED    IN mex_credentials,
									p_REPORT_TYPE     IN VARCHAR2,
									p_STATUS          OUT NUMBER,
									p_MESSAGE         OUT VARCHAR2);


	PROCEDURE GET_NYISO_RATES(p_REPORT_TYPE     IN VARCHAR2,
							p_RECORDS         OUT MEX_NY_RATES_TBL,
							p_STATUS          OUT NUMBER,
							p_MESSAGE         OUT VARCHAR2);


	PROCEDURE GET_NYISO_RESIDUALS(p_REPORT_TYPE     IN VARCHAR2,
                              p_RECORDS         OUT mex_ny_residual_tbl,
								p_STATUS          OUT NUMBER,
								p_MESSAGE         OUT VARCHAR2);

	PROCEDURE GET_NYISO_TOTALS(p_REPORT_TYPE     IN VARCHAR2,
						   p_RECORDS         OUT mex_ny_total_tbl,
							 p_STATUS          OUT NUMBER,
							 p_MESSAGE         OUT VARCHAR2);

	PROCEDURE GET_DAM_VIRTUAL_SUPPLY(p_REPORT_TYPE     IN VARCHAR2,
								p_RECORDS         OUT mex_ny_dam_vir_sup_tbl,
						        p_STATUS          OUT NUMBER,
						        p_MESSAGE         OUT VARCHAR2);

	PROCEDURE GET_DAM_VIRTUAL_LOAD(p_REPORT_TYPE     IN VARCHAR2,
						   p_RECORDS         OUT MEX_NY_DAM_VIR_LOAD_TBL ,
						   p_STATUS          OUT NUMBER,
						   p_MESSAGE         OUT VARCHAR2);

	PROCEDURE GET_DAM_ENERGY(p_REPORT_TYPE     IN VARCHAR2,
                         p_RECORDS         OUT mex_ny_dam_energy_tbl,
						   p_STATUS          OUT NUMBER,
						   p_MESSAGE         OUT VARCHAR2);


	PROCEDURE GET_BAL_MARKET_ENERGY(p_REPORT_TYPE     IN VARCHAR2,
								  p_RECORDS         OUT MEX_NY_BAL_MKT_EN_TBL,
								  p_STATUS          OUT NUMBER,
								  p_MESSAGE         OUT VARCHAR2);

	PROCEDURE GET_BAL_MKT_VIRT_LOAD(p_REPORT_TYPE     IN VARCHAR2,
								  p_RECORDS         OUT MEX_NY_BAL_VL_TBL,
								  p_STATUS          OUT NUMBER,
								  p_MESSAGE         OUT VARCHAR2);

	PROCEDURE GET_BAL_MKT_VIRT_SUPPLY(p_REPORT_TYPE     IN VARCHAR2,
									p_RECORDS         OUT MEX_NY_BAL_VS_TBL,
									p_STATUS          OUT NUMBER,
									p_MESSAGE         OUT VARCHAR2);*/


END MEX_NYISO_SETTLEMENT;
/