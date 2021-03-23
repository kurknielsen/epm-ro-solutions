CREATE OR REPLACE PACKAGE BODY MEX_PJM_CE IS

   g_pjm_erpm_namespace      CONSTANT VARCHAR2(64) := 'xmlns="http://erpm.pjm.com/rpm/xml"';
   g_pjm_erpm_namespace_name CONSTANT VARCHAR2(64) := 'http://erpm.pjm.com/rpm/xml';
   g_pjm_ce_mkt              CONSTANT VARCHAR2(20) := 'pjmcapacityexchange';

   ---------------------------------------------------------------------------------------------------
   FUNCTION what_version RETURN VARCHAR IS
   BEGIN
      RETURN '$Revision: 1.0 $';
   END what_version;
   ---------------------------------------------------------------------------------------------------
   FUNCTION safe_string
   (
      p_xml       IN xmltype,
      p_xpath     IN VARCHAR2,
      p_namespace IN VARCHAR2 := NULL
   ) RETURN VARCHAR2 IS
      --RETURN TEXT FOR A PATH OR NULL IF IT DOESN'T EXIST.
      v_xmltmp xmltype;
   BEGIN
      v_xmltmp := xmltype.extract(p_xml, p_xpath, p_namespace);
      IF v_xmltmp IS NULL THEN
         RETURN NULL;
      ELSE
         RETURN v_xmltmp.getstringval();
      END IF;
   END safe_string;
   ---------------------------------------------------------------------------------------------------
   PROCEDURE run_pjm_authenticate
   (
      p_cred     IN mex_credentials,
      p_log_only IN BINARY_INTEGER,
      p_market   IN VARCHAR2,
      p_logger   IN OUT mm_logger_adapter,
      p_token_id OUT VARCHAR2
   ) AS

      v_result mex_result;
      v_request CONSTANT CLOB := to_clob('{}');
      v_response      CLOB;
      v_start         BINARY_INTEGER;
      v_end           BINARY_INTEGER;
      v_parameter_map mex_util.parameter_map;
      v_sandbox       NUMBER(1);
      v_url           VARCHAR2(2000);

   BEGIN

      v_sandbox := nvl(get_dictionary_value('Use Sandbox',
                                            0,
                                            'MarketExchange',
                                            'PJM',
                                            substr(p_market, 4),
                                            '?'),
                       0);

      IF v_sandbox = 1 THEN
         v_url := nvl(get_dictionary_value('Sandbox URL',
                                           0,
                                           'MarketExchange',
                                           'PJM',
                                           'SSO',
                                           '?'),
                      0);
      ELSE
         v_url := nvl(get_dictionary_value('Production URL',
                                           0,
                                           'MarketExchange',
                                           'PJM',
                                           'SSO',
                                           '?'),
                      0);
      END IF;

      v_parameter_map('url') := 'https://ssotrain.pjm.com/access/authenticate/'; -- v_url;

      v_parameter_map('MEX-REQUEST-HEADER-X-OpenAM-Username') := p_cred.username;
      v_parameter_map('MEX-REQUEST-HEADER-X-OpenAM-Password') := security_controls.decode(p_cred.password);

      v_result := mex_switchboard.invoke(p_market              => 'pjmsso',
                                         p_action              => 'authenticate',
                                         p_logger              => p_logger,
                                         p_cred                => p_cred,
                                         p_parms               => v_parameter_map,
                                         p_request_contenttype => 'application/json',
                                         p_request             => v_request,
                                         p_log_only            => p_log_only);

      IF v_result.status_code <> mex_switchboard.c_status_success THEN
         p_token_id := NULL;
         RETURN;
      ELSE
         v_response := v_result.response;
         v_start    := instr(v_response, 'tokenId');
         v_start    := instr(v_response, '"', v_start, 2) + 1;
         v_end      := instr(v_response, '"', v_start);
         p_token_id := substr(v_response, v_start, v_end - v_start);
      END IF;

   END run_pjm_authenticate;
   ----------------------------------------------------------------------------------
   PROCEDURE run_pjm_action
   (
      p_cred              IN mex_credentials,
      p_action            IN VARCHAR2,
      p_log_only          IN BINARY_INTEGER,
      p_xml_request_body  IN xmltype,
      p_pjm_namespace     IN VARCHAR2,
      p_market            IN VARCHAR2,
      p_token_id          IN VARCHAR2,
      p_xml_response_body OUT xmltype,
      p_status            OUT NUMBER,
      p_error_message     OUT VARCHAR2,
      p_logger            IN OUT mm_logger_adapter
   ) AS

      v_pjm_error_xml     xmltype;
      v_pjm_error_code    VARCHAR2(32);
      v_pjm_error_message VARCHAR2(2000);
      v_pjm_error_line    VARCHAR2(32);
      v_result            mex_result;
      v_request           CLOB;
      v_parms             mex_util.parameter_map;
      v_sandbox           NUMBER(1);
      v_url               VARCHAR2(2000);
      v_market            VARCHAR2(50);

   BEGIN

      -- Add This XML To The Request --
      dbms_lob.createtemporary(v_request, TRUE);
      dbms_lob.open(v_request, dbms_lob.lob_readwrite);
      dbms_lob.append(v_request, p_xml_request_body.getclobval());
      dbms_lob.close(v_request);

      v_market  := substr(p_market, 4);
      v_url     := '/' || v_market || '/xml/' || p_action;
      v_sandbox := nvl(get_dictionary_value('Use Sandbox',
                                            0,
                                            'MarketExchange',
                                            'PJM',
                                            v_market,
                                            '?'),
                       0);
      IF v_sandbox = 1 THEN
         v_url := nvl(get_dictionary_value('Sandbox URL',
                                           0,
                                           'MarketExchange',
                                           'PJM',
                                           v_market,
                                           '?'),
                      0) || v_url;
         v_parms('MEX-REQUEST-HEADER-Cookie') := 'pjmauthtrain=' || p_token_id;
      ELSE
         v_url := nvl(get_dictionary_value('Production URL',
                                           0,
                                           'MarketExchange',
                                           'PJM',
                                           v_market,
                                           '?'),
                      0) || v_url;
         v_parms('MEX-REQUEST-HEADER-Cookie') := 'pjmauth=' || p_token_id;
      END IF;

      v_parms('url') := v_url;

      v_result := mex_switchboard.invoke(p_market              => 'sys',
                                         p_action              => 'fetchurl',
                                         p_logger              => p_logger,
                                         p_cred                => NULL,
                                         p_parms               => v_parms,
                                         p_request_contenttype => 'text/xml',
                                         p_request             => v_request,
                                         p_log_only            => p_log_only);

      p_status := v_result.status_code;
      IF v_result.status_code <> mex_switchboard.c_status_success THEN
         p_xml_response_body := NULL;
      ELSE
         p_xml_response_body := xmltype.createxml(v_result.response);
         -- If Error Occured From PJM Parsing, Log It And Return Error --
         v_pjm_error_xml := p_xml_response_body.extract('/descendant::Error',
                                                        p_pjm_namespace);
         IF v_pjm_error_xml IS NOT NULL THEN
            v_pjm_error_code    := safe_string(v_pjm_error_xml,
                                               'Error/Code/text()',
                                               p_pjm_namespace);
            v_pjm_error_message := safe_string(v_pjm_error_xml,
                                               'Error/Text/text()',
                                               p_pjm_namespace);
            v_pjm_error_line    := safe_string(v_pjm_error_xml,
                                               'Error/Line/text()',
                                               p_pjm_namespace);
            p_error_message     := v_pjm_error_code || ' ' ||
                                   v_pjm_error_message || ' ' ||
                                   v_pjm_error_line;
            p_logger.log_exchange_error('Parse Errors: ' || p_error_message);
            p_status            := mex_switchboard.c_status_error;
            p_xml_response_body := NULL;
         END IF;
      END IF;

   EXCEPTION
      WHEN OTHERS THEN
         p_error_message := 'MEX_PJM_CE.RUN_PJM_ACTION: ' || SQLERRM;
         p_status        := SQLCODE;
   END run_pjm_action;
   ---------------------------------------------------------------------------------------------------
   PROCEDURE run_pjm_query
   (
      p_cred              IN mex_credentials,
      p_log_only          IN NUMBER,
      p_xml_request_body  IN xmltype,
      p_xml_response_body OUT xmltype,
      p_status            OUT NUMBER,
      p_error_message     OUT VARCHAR2,
      p_logger            IN OUT mm_logger_adapter
   ) AS

      v_token_id VARCHAR2(1000);

   BEGIN
      p_status := mex_util.g_success;

      run_pjm_authenticate(p_cred     => p_cred,
                           p_log_only => p_log_only,
                           p_market   => g_pjm_ce_mkt,
                           p_logger   => p_logger,
                           p_token_id => v_token_id);

      run_pjm_action(p_cred,
                     'query',
                     p_log_only,
                     p_xml_request_body,
                     g_pjm_erpm_namespace,
                     g_pjm_ce_mkt,
                     v_token_id,
                     p_xml_response_body,
                     p_status,
                     p_error_message,
                     p_logger);

      IF p_error_message IS NOT NULL THEN
         p_status := 1;
      END IF;
   EXCEPTION
      WHEN OTHERS THEN
         p_error_message := 'MEX_PJM_CE.RUN_PJM_QUERY: ' || ut.get_full_errm;
   END run_pjm_query;
   -------------------------------------------------------------------------------------
   PROCEDURE run_pjm_submit
   (
      p_cred              IN mex_credentials,
      p_log_only          IN BINARY_INTEGER,
      p_xml_request_body  IN xmltype,
      p_xml_response_body OUT xmltype,
      p_status            OUT NUMBER,
      p_error_message     OUT VARCHAR2,
      p_logger            IN OUT mm_logger_adapter
   ) AS

      v_xml_request          xmltype;
      v_xml_response         xmltype;
      v_pjm_transaction_code xmltype;
      v_token_id             VARCHAR2(1000);

   BEGIN

      run_pjm_authenticate(p_cred     => p_cred,
                           p_log_only => p_log_only,
                           p_market   => g_pjm_ce_mkt,
                           p_logger   => p_logger,
                           p_token_id => v_token_id);

      run_pjm_action(p_cred,
                     'submit',
                     p_log_only,
                     p_xml_request_body,
                     g_pjm_erpm_namespace,
                     g_pjm_ce_mkt,
                     v_token_id,
                     p_xml_response_body,
                     p_status,
                     p_error_message,
                     p_logger);

      --Log the transaction code.
      IF NOT p_xml_response_body IS NULL THEN
         v_pjm_transaction_code := p_xml_response_body.extract('/SubmitResponse/Success/TransactionID/text()',
                                                               g_pjm_erpm_namespace);

         IF NOT v_pjm_transaction_code IS NULL THEN
            p_logger.log_exchange_identifier(v_pjm_transaction_code.getstringval());
         END IF;
      END IF;

   EXCEPTION
      WHEN OTHERS THEN
         p_error_message := 'MEX_PJM_CE.RUN_PJM_SUBMIT: ' || SQLERRM;
         p_status        := SQLCODE;
   END run_pjm_submit;
   ----------------------------------------------------------------------------------------
   PROCEDURE getx_query_nspl
   (
      p_begin_date       IN DATE,
      p_company_name     IN VARCHAR2,
      p_xml_request_body OUT xmltype,
      p_status           OUT NUMBER,
      p_message          OUT VARCHAR2
   ) AS

      v_request VARCHAR2(2048) := '<QueryRequest ' || g_pjm_erpm_namespace ||
                                  '><QueryDailyZonalNSPLDetail' || ' Day=' || '"' ||
                                  to_char(p_begin_date,
                                          mex_pjm_emkt.g_date_format) || '"' ||
                                  '/></QueryRequest>';
   BEGIN
      p_status           := mex_util.g_success;
      p_xml_request_body := xmltype.createxml(v_request);

   EXCEPTION
      WHEN OTHERS THEN
         p_status  := SQLCODE;
         p_message := 'ERROR OCCURED IN MEX_PJM_CE.GETX_QUERY_NSPL' ||
                      ut.get_full_errm;
   END getx_query_nspl;
   ----------------------------------------------------------------------------------------------
   PROCEDURE getx_query_cap_oblig
   (
      p_begin_date       IN DATE,
      p_company_name     IN VARCHAR2,
      p_xml_request_body OUT xmltype,
      p_status           OUT NUMBER,
      p_message          OUT VARCHAR2
   ) AS

      v_request VARCHAR2(1042);

   BEGIN
      p_status := mex_util.g_success;
      --due to length of QueryDailyZonalLoadObligationDetail, must create request as text

      v_request := '<' || 'QueryRequest ' || g_pjm_erpm_namespace ||
                   '><QueryDailyZonalLoadObligationDetail' || ' Day=' || '"' ||
                   to_char(p_begin_date, mex_pjm_emkt.g_date_format) || '"' ||
                   '/></QueryRequest>';

      p_xml_request_body := xmltype.createxml(v_request);

   EXCEPTION
      WHEN OTHERS THEN
         p_status  := SQLCODE;
         p_message := 'ERROR OCCURED IN MEX_PJM_CE.GETX_QUERY_CAP_OBLIG' ||
                      ut.get_full_errm;
   END getx_query_cap_oblig;
   ----------------------------------------------------------------------------------------------
   PROCEDURE parse_netwk_serv_pk_ld
   (
      p_xml_response IN xmltype,
      p_records      IN OUT NOCOPY mex_pjm_ecap_load_obl_tbl,
      p_status       OUT NUMBER,
      p_message      OUT VARCHAR2
   ) AS

      CURSOR c_xml IS
         SELECT extractvalue(VALUE(t), '//@LSEName', g_pjm_erpm_namespace) "LSE",
                extractvalue(VALUE(t), '//@ZoneName', g_pjm_erpm_namespace) "ZONE",
                extractvalue(VALUE(t), '//@AreaName', g_pjm_erpm_namespace) "AREA",
                extractvalue(VALUE(u), '//@Day', g_pjm_erpm_namespace) "DAY",
                extractvalue(VALUE(u), '//NSPL', g_pjm_erpm_namespace) "NSPL"
           FROM TABLE(xmlsequence(extract(p_xml_response,
                                          '//DailyZonalNSPLDetailSet/DailyZonalNSPLDetail',
                                          g_pjm_erpm_namespace))) t,
                TABLE(xmlsequence(extract(VALUE(t),
                                          '//DailyZonalNSPL',
                                          g_pjm_erpm_namespace))) u
          ORDER BY 4;

   BEGIN
      p_status := mex_util.g_success;
      FOR v_xml IN c_xml LOOP

         p_records.extend();
         p_records(p_records.last) := mex_pjm_ecap_load_obl(SYSDATE,
                                                            v_xml.lse,
                                                            'NSPL',
                                                            v_xml.zone,
                                                            v_xml.lse,
                                                            to_date(v_xml.day,
                                                                    'YYYY-MM-DD'),
                                                            NULL,
                                                            v_xml.area,
                                                            v_xml.lse,
                                                            NULL,
                                                            NULL,
                                                            v_xml.nspl,
                                                            NULL,
                                                            NULL,
                                                            NULL);

      END LOOP;

   EXCEPTION
      WHEN OTHERS THEN
         p_status  := SQLCODE;
         p_message := 'ERROR OCCURED IN MEX_PJM_CE.PARSE_NETWK_SERV_PK_LD' ||
                      ut.get_full_errm;

   END parse_netwk_serv_pk_ld;
   ----------------------------------------------------------------------------------------------
   PROCEDURE parse_capacity_oblig
   (
      p_xml_response IN xmltype,
      p_records      IN OUT NOCOPY mex_pjm_ecap_load_obl_tbl,
      p_status       OUT NUMBER,
      p_message      OUT VARCHAR2
   ) AS

      CURSOR c_xml IS
         SELECT extractvalue(VALUE(t), '//@LSEName', g_pjm_erpm_namespace) "LSE",
                extractvalue(VALUE(t), '//@ZoneName', g_pjm_erpm_namespace) "ZONE",
                extractvalue(VALUE(t), '//@AreaName', g_pjm_erpm_namespace) "AREA",
                extractvalue(VALUE(u), '//@Day', g_pjm_erpm_namespace) "DAY",
                extractvalue(VALUE(u),
                             '//ObligationPeakLoad',
                             g_pjm_erpm_namespace) "PEAKLOAD",
                extractvalue(VALUE(u),
                             '//DailyUCAPObligation',
                             g_pjm_erpm_namespace) "OBLIGATION"
           FROM TABLE(xmlsequence(extract(p_xml_response,
                                          '//DailyZonalLoadObligationDetailSet/DailyZonalLoadObligationDetail',
                                          g_pjm_erpm_namespace))) t,
                TABLE(xmlsequence(extract(VALUE(t),
                                          '//DailyZonalLoadObligation',
                                          g_pjm_erpm_namespace))) u
          ORDER BY 4;

   BEGIN
      p_status := mex_util.g_success;
      FOR v_xml IN c_xml LOOP

         p_records.extend();
         p_records(p_records.last) := mex_pjm_ecap_load_obl(SYSDATE,
                                                            v_xml.lse,
                                                            'NSPL',
                                                            v_xml.zone,
                                                            v_xml.lse,
                                                            to_date(v_xml.day,
                                                                    'YYYY-MM-DD'),
                                                            NULL,
                                                            v_xml.area,
                                                            v_xml.lse,
                                                            v_xml.peakload,
                                                            v_xml.obligation,
                                                            NULL,
                                                            NULL,
                                                            NULL,
                                                            NULL);

      END LOOP;

   EXCEPTION
      WHEN OTHERS THEN
         p_status  := SQLCODE;
         p_message := 'ERROR OCCURED IN MEX_PJM_CE.PARSE_CAPACITY_OBLIG' ||
                      ut.get_full_errm;

   END parse_capacity_oblig;
   --------------------------------------------------------------------------------------
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
   ) AS

      v_xml_request  xmltype;
      v_xml_response xmltype;

   BEGIN

      p_records := mex_pjm_ecap_load_obl_tbl();
      p_status  := mex_util.g_success;

      getx_query_nspl(p_begin_date,
                      p_company_name,
                      v_xml_request,
                      p_status,
                      p_message);

      run_pjm_query(p_cred,
                    p_log_only,
                    v_xml_request,
                    v_xml_response,
                    p_status,
                    p_message,
                    p_logger);

      IF p_status = mex_util.g_success THEN
         parse_netwk_serv_pk_ld(v_xml_response, p_records, p_status, p_message);
      END IF;

   EXCEPTION
      WHEN OTHERS THEN
         p_status  := SQLCODE;
         p_message := 'Error in MEX_PJM_CE.FETCH_NETWK_SERV_PK_LD: ' ||
                      ut.get_full_errm;
   END fetch_netwk_serv_pk_ld;
   ----------------------------------------------------------------------------------------
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
   ) AS

      v_xml_request  xmltype;
      v_xml_response xmltype;

   BEGIN

      p_records := mex_pjm_ecap_load_obl_tbl();
      p_status  := mex_util.g_success;
      --    p_PARAMETER_MAP('ReportName') := 'QueryDailyZonalLoadObligationDetail';

      getx_query_cap_oblig(p_begin_date,
                           p_company_name,
                           v_xml_request,
                           p_status,
                           p_message);

      run_pjm_query(p_cred,
                    p_log_only,
                    v_xml_request,
                    v_xml_response,
                    p_status,
                    p_message,
                    p_logger);

      IF p_status = mex_util.g_success THEN
         parse_capacity_oblig(v_xml_response, p_records, p_status, p_message);
      END IF;

   EXCEPTION
      WHEN OTHERS THEN
         p_status  := SQLCODE;
         p_message := 'Error in MEX_PJM_CE.FETCH_CAPACITY_OBLIGATION: ' ||
                      ut.get_full_errm;
   END fetch_capacity_obligation;
   ----------------------------------------------------------------------------------------
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
   ) AS
      v_xml_request  xmltype;
      v_xml_response xmltype;
      v_report_name  VARCHAR2(64) := 'QueryPeakLoadSummary';
      v_request      VARCHAR2(1042) := '<QueryRequest ' || g_pjm_erpm_namespace || '><' ||
                                       v_report_name || ' Day=' || '"' ||
                                       to_char(p_query_date,
                                               mex_pjm_emkt.g_date_format) || '"' ||
                                       '/></QueryRequest>';
      v_scale        NUMBER;

      CURSOR c_xml IS
         SELECT extractvalue(VALUE(s), '//LSE', g_pjm_erpm_namespace) "LSE",
                extractvalue(VALUE(s), '//ZoneName', g_pjm_erpm_namespace) "ZONE",
                extractvalue(VALUE(s), '//AreaName', g_pjm_erpm_namespace) "AREA",
                extractvalue(VALUE(s), '//@Day', g_pjm_erpm_namespace) "DAY",
                extractvalue(VALUE(s), '//ScalingFactor', g_pjm_erpm_namespace) "SCALE_FACTOR"
           FROM TABLE(xmlsequence(extract(v_xml_response,
                                          '//PeakLoadSummarySet/PeakLoadSummary',
                                          g_pjm_erpm_namespace))) s
          ORDER BY 4;

   BEGIN

      p_status := mex_util.g_success;
      --p_LOGGER.LOG_INFO('Query PLC Scale Factor Entry');
      v_xml_request := xmltype.createxml(v_request);
      run_pjm_query(p_credentials,
                    p_log_only,
                    v_xml_request,
                    v_xml_response,
                    p_status,
                    p_message,
                    p_logger);
      IF p_status = mex_util.g_success THEN
         FOR v_xml IN c_xml LOOP
            p_records.extend();
            p_records(p_records.last) := mex_schedule(to_date(v_xml.day,
                                                              mex_pjm_emkt.g_date_format),
                                                      NULL,
                                                      v_xml.scale_factor);
            EXIT;
         END LOOP;
         --p_LOGGER.LOG_INFO('Records Returned: ' || TO_CHAR(p_RECORDS.COUNT));
         --p_LOGGER.LOG_INFO('Query PLC Scale Factor Exit');
      END IF;
   END query_plc_scale_factor;
   --------------------------------------------------------------------------------
   -- REVISION HISTORY
   -- DATE       AUTHOR         DESCRIPTION
   ------------ -------------- --------------------------------------------------
   --2020-11-13 Kurk Nielsen   Chamged Query Requset Day to 'StartDay'
   ------------------------------------------------------------------------------   
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
   ) AS

      v_xml_request  xmltype;
      v_xml_response xmltype;
      v_report_name  VARCHAR2(64) := 'QueryPeakLoadSummary';
      v_request      VARCHAR2(2048) := '<' || 'QueryRequest ' ||
                                       g_pjm_erpm_namespace || '><' ||
                                       v_report_name || ' StartDay=' || '"' ||
                                       to_char(p_query_date,
                                               mex_pjm_emkt.g_date_format) || '"' ||
                                       '/></QueryRequest>';

      CURSOR c_xml IS
         SELECT extractvalue(VALUE(s), '//LSE', g_pjm_erpm_namespace) "LSE",
                extractvalue(VALUE(s), '//ZoneName', g_pjm_erpm_namespace) "ZONE",
                extractvalue(VALUE(s), '//AreaName', g_pjm_erpm_namespace) "AREA",
                extractvalue(VALUE(s), '//@Day', g_pjm_erpm_namespace) "DAY",
                extractvalue(VALUE(s), '//UploadedMW', g_pjm_erpm_namespace) "UPLOADEDMW"
           FROM TABLE(xmlsequence(extract(v_xml_response,
                                          '//PeakLoadSummarySet/PeakLoadSummary',
                                          g_pjm_erpm_namespace))) s
          ORDER BY 4;

   BEGIN

      p_status := mex_util.g_success;
      -- p_LOGGER.LOG_INFO('Query PLC Uploaded MW Entry');

      p_records     := mex_pjm_ecap_load_obl_tbl();
      v_xml_request := xmltype.createxml(v_request);
      run_pjm_query(p_credentials,
                    p_log_only,
                    v_xml_request,
                    v_xml_response,
                    p_status,
                    p_message,
                    p_logger);
      IF p_status = mex_util.g_success THEN
         FOR v_xml IN c_xml LOOP
            p_records.extend();
            p_records(p_records.last) := mex_pjm_ecap_load_obl(SYSDATE,
                                                               v_xml.lse,
                                                               'PLC',
                                                               v_xml.zone,
                                                               v_xml.lse,
                                                               to_date(v_xml.day,
                                                                       'YYYY-MM-DD'),
                                                               NULL,
                                                               v_xml.area,
                                                               v_xml.lse,
                                                               NULL,
                                                               v_xml.uploadedmw,
                                                               NULL,
                                                               NULL,
                                                               NULL,
                                                               NULL);

         END LOOP;
         --p_LOGGER.LOG_INFO('Records Returned: ' || TO_CHAR(p_RECORDS.COUNT));
         --p_LOGGER.LOG_INFO('Query Uploaded MW Exit');
      END IF;
   END query_uploaded_mw;

END MEX_PJM_CE;
/
