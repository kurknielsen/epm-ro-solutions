CREATE OR REPLACE PACKAGE MEX_PJM_CE IS

   -- Purpose : Handle Fetch and Parse of CapacityExchange reports
   -- $Revision: 1.0 $

   FUNCTION what_version RETURN VARCHAR;

   PROCEDURE fetch_netwk_serv_pk_ld
   (
      p_cred         IN mex_credentials,
      p_log_only     IN NUMBER,
      p_begin_date   IN DATE,
      p_company_name IN VARCHAR2,
      p_records      OUT mex_pjm_ecap_load_obl_tbl,
      p_status       OUT NUMBER,
      p_message      OUT VARCHAR2,
      p_logger       IN OUT mm_logger_adapter
   );

   PROCEDURE fetch_capacity_obligation
   (
      p_cred         IN mex_credentials,
      p_log_only     IN NUMBER,
      p_begin_date   IN DATE,
      p_company_name IN VARCHAR2,
      p_records      OUT mex_pjm_ecap_load_obl_tbl,
      p_status       OUT NUMBER,
      p_message      OUT VARCHAR2,
      p_logger       IN OUT mm_logger_adapter
   );

   PROCEDURE parse_netwk_serv_pk_ld
   (
      p_xml_response IN xmltype,
      p_records      IN OUT NOCOPY mex_pjm_ecap_load_obl_tbl,
      p_status       OUT NUMBER,
      p_message      OUT VARCHAR2
   );

   PROCEDURE parse_capacity_oblig
   (
      p_xml_response IN xmltype,
      p_records      IN OUT NOCOPY mex_pjm_ecap_load_obl_tbl,
      p_status       OUT NUMBER,
      p_message      OUT VARCHAR2
   );

   PROCEDURE run_pjm_submit
   (
      p_cred              IN mex_credentials,
      p_log_only          IN BINARY_INTEGER,
      p_xml_request_body  IN xmltype,
      p_xml_response_body OUT xmltype,
      p_status            OUT NUMBER,
      p_error_message     OUT VARCHAR2,
      p_logger            IN OUT mm_logger_adapter
   );

   PROCEDURE query_plc_scale_factor
   (
      p_credentials  IN mex_credentials,
      p_log_only     IN NUMBER,
      p_query_date   IN DATE,
      p_company_name IN VARCHAR2,
      p_records      IN OUT mex_schedule_tbl,
      p_status       OUT NUMBER,
      p_message      OUT VARCHAR2,
      p_logger       IN OUT mm_logger_adapter
   );

   PROCEDURE query_uploaded_mw
   (
      p_credentials  IN mex_credentials,
      p_log_only     IN NUMBER,
      p_query_date   IN DATE,
      p_company_name IN VARCHAR2,
      p_records      IN OUT mex_pjm_ecap_load_obl_tbl,
      p_status       OUT NUMBER,
      p_message      OUT VARCHAR2,
      p_logger       IN OUT mm_logger_adapter
   );

END MEX_PJM_CE;
/

