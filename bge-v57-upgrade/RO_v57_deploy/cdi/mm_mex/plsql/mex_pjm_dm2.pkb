CREATE OR REPLACE PACKAGE BODY mex_pjm_dm2 AS
   ----------------------------------------------------------------------------------------------------
   -- Copyright 2017 by ABB.
   -- All Rights Reserved.  Proprietary and Confidential.
   ----------------------------------------------------------------------------------------------------
   -- PURPOSE:  PJM DataMiner2 Market Exchange Package
   -- REFER.:
   -- DESC:     Contains processes needed for communicate to PJM DataMiner2 interfaces
   ----------------------------------------------------------------------------------------------------
   -- REVISION HISTORY
   -- DATE       AUTHOR         DESCRIPTION
   ------------- -------------- -----------------------------------------------------------------------
   --2017-Dec-1  Kurk Nielsen   Initial version - From MM_PJM_LMP
   ----------------------------------------------------------------------------------------------------
   -- Public type declarations
   ----------------------------------------------------------------------------------------------------
   -- what_version
   ----------------------------------------------------------------------------------------------------
   ghr CONSTANT NUMBER := 0.04166666666666666666666666666666666666666666666666;

   FUNCTION what_version RETURN VARCHAR2 IS
   BEGIN
      RETURN '$Revision: 1.0 $';
   END what_version;
   ----------------------------------------------------------------------------------------------------
   -- PARSE_LMP
   ----------------------------------------------------------------------------------------------------
   PROCEDURE parse_lmp
   (
      p_csv         IN CLOB
     ,p_market_type IN VARCHAR2
     ,p_monthly     IN VARCHAR2
     ,p_records     OUT mex_pjm_lmp_dm2_obj_tbl
     ,p_status      OUT NUMBER
     ,p_message     OUT VARCHAR2
   ) IS
      v_lines    parse_util.big_string_table_mp;
      v_fields   parse_util.string_table;
      v_index    BINARY_INTEGER;
      v_date_utc DATE;
      v_date_etc DATE;

   BEGIN
      p_status  := mex_util.g_success;
      p_records := mex_pjm_lmp_dm2_obj_tbl();

      -- parse the clob into lines
      parse_util.parse_clob_into_lines(p_csv, v_lines);
      v_index := v_lines.first + 1; -- To account for header
      -- loop over lines
      WHILE v_lines.exists(v_index)
      LOOP
         IF LENGTH(v_lines(v_index)) > 0 THEN
            --   parse each line into fields
            parse_util.tokens_from_string(v_lines(v_index), ',', v_fields);
            --start importing LMP values from each line
            FOR i IN 1 .. v_fields.count
            LOOP
               p_records.extend();
               --Add an Hour to Date to make them ending hour
               v_date_utc := to_date(v_fields(1), 'mm/dd/yyyy hh:mi:ss AM') + ghr;
               v_date_etc := date_util.to_cut_date_from_iso(to_char(to_date(v_fields(1),
                                                                            'mm/dd/yyyy hh:mi:ss AM'),
                                                                    'YYYY-MM-DD HH24:MI:SS')) + ghr;
               IF p_monthly = 1 THEN
                  IF p_market_type = 'RT' THEN
                     p_records(p_records.last) := mex_pjm_lmp_dm2_obj(v_date_utc,
                                                                      v_date_etc,
                                                                      v_fields(3),
                                                                      v_fields(4),
                                                                      v_fields(5),
                                                                      v_fields(6),
                                                                      v_fields(7),
                                                                      v_fields(8),
                                                                      v_fields(9),
                                                                      v_fields(10),
                                                                      v_fields(11),
                                                                      v_fields(12),
                                                                      NULL,
                                                                      NULL);
                  ELSE
                     p_records(p_records.last) := mex_pjm_lmp_dm2_obj(v_date_utc,
                                                                      v_date_etc,
                                                                      v_fields(3),
                                                                      v_fields(4),
                                                                      v_fields(5),
                                                                      v_fields(6),
                                                                      v_fields(7),
                                                                      v_fields(8),
                                                                      v_fields(13),
                                                                      v_fields(14),
                                                                      v_fields(15),
                                                                      v_fields(16),
                                                                      NULL,
                                                                      NULL);
                  END IF;
               ELSE
                  p_records(p_records.last) := mex_pjm_lmp_dm2_obj(v_date_utc,
                                                                   v_date_etc,
                                                                   v_fields(3),
                                                                   v_fields(4),
                                                                   v_fields(5),
                                                                   v_fields(6),
                                                                   v_fields(7),
                                                                   v_fields(8),
                                                                   v_fields(9),
                                                                   v_fields(10),
                                                                   v_fields(11),
                                                                   v_fields(12),
                                                                   v_fields(13),
                                                                   v_fields(14));
               END IF;
            END LOOP;
         END IF;
         v_index := v_lines.next(v_index);
      END LOOP;

   EXCEPTION
      WHEN OTHERS THEN
         p_status  := SQLCODE;
         p_message := 'Error in MEX_PJM_DM2.PARSE_LMP: ' || SQLERRM;
   END parse_lmp;

   ----------------------------------------------------------------------------------------------------
   -- FETCH_LMP
   ----------------------------------------------------------------------------------------------------
   PROCEDURE fetch_lmp
   (
      p_date        IN DATE
     ,p_market_type IN VARCHAR2
     ,p_monthly     IN NUMBER
     ,p_row_count   IN NUMBER
     ,p_start_row   IN NUMBER
     ,p_records     OUT mex_pjm_lmp_dm2_obj_tbl
     ,p_status      OUT NUMBER
     ,p_message     OUT VARCHAR2
     ,p_logger      IN OUT NOCOPY mm_logger_adapter
   ) IS

      v_response_clob   CLOB;
      v_lmp_url         VARCHAR2(255);
      v_lmp_base_url    VARCHAR2(40);
      v_request_headers mex_util.parameter_map;
      v_result          mex_result;

      v_sandbox          BOOLEAN;
      v_url_setting      system_dictionary.setting_name%TYPE;
      v_sub_key          system_dictionary.value%TYPE;
      v_query_parameters VARCHAR2(100);

      ex_no_metadata EXCEPTION;

   BEGIN
      p_status  := mex_util.g_success;
      p_records := mex_pjm_lmp_dm2_obj_tbl();

      v_sandbox := nvl(get_dictionary_value('Use Sandbox',
                                            0,
                                            'MarketExchange',
                                            'PJM',
                                            'DataMiner2'),
                       0) = '1';
      IF v_sandbox THEN
         v_url_setting := 'Sandbox URL';
      ELSE
         v_url_setting := 'Production URL';
      END IF;
      v_lmp_base_url     := get_dictionary_value(v_url_setting,
                                                 0,
                                                 'MarketExchange',
                                                 'PJM',
                                                 'DataMiner2');
      v_query_parameters := get_dictionary_value('Query Parameters',
                                                 0,
                                                 'MarketExchange',
                                                 'PJM',
                                                 'DataMiner2');
      v_sub_key          := get_dictionary_value('Ocp-Apim-Subscription-Key',
                                                 0,
                                                 'MarketExchange',
                                                 'PJM',
                                                 'DataMiner2');

      IF v_sub_key IS NULL THEN
         RAISE ex_no_metadata;
      END IF;
      v_request_headers('Accept') := 'text/csv';
      v_request_headers('Content-Type') := 'text/plain';
      v_request_headers('Accept-Language') := 'en-US,en;q=0.8';
      v_request_headers('Ocp-Apim-Subscription-Key') := v_sub_key;

      IF p_monthly = 1 THEN
         v_lmp_url := v_lmp_base_url || '/rt_da_monthly_lmps';
      ELSIF upper(p_market_type) LIKE 'D%' THEN
         v_lmp_url := v_lmp_base_url || '/da_hrl_lmps';
      ELSE
         v_lmp_url := v_lmp_base_url || '/rt_hrl_lmps';
      END IF;
      --v_lmp_base_url := 'https://api-train.pjm.com/api/v1/da_hrl_lmps?download=false&rowCount=100&startRow=1&datetime_beginning_utc=11/1/2017';
      v_lmp_url := v_lmp_url || '?download=False&rowCount=';
      v_lmp_url := v_lmp_url || p_row_count || '&StartRow=';
      v_lmp_url := v_lmp_url || p_start_row || '&IsActiveMetadata=True&';
      IF v_query_parameters IS NOT NULL THEN
         v_lmp_url := v_lmp_url || v_query_parameters;
      END IF;
      IF p_monthly = 0 THEN
         v_lmp_url := v_lmp_url || '&row_is_current=TRUE';
      END IF;
      v_lmp_url := v_lmp_url || '&sort=pnode_id&';
      v_lmp_url := v_lmp_url || 'datetime_beginning_ept=' ||
                   to_char(p_date, 'mm/dd/yyyy');
      logs.log_info('URL: ' || v_lmp_url);
      v_result := mex_switchboard.fetchurl(p_url_to_fetch    => v_lmp_url,
                                           p_request_headers => v_request_headers,
                                           p_logger          => p_logger);

      p_status := v_result.status_code;
      IF v_result.status_code <> mex_switchboard.c_status_success THEN
         v_response_clob := NULL;
      ELSE
         v_response_clob := v_result.response;
      END IF;
      IF p_status = mex_util.g_success THEN
         parse_lmp(v_response_clob,
                   p_market_type,
                   p_monthly,
                   p_records,
                   p_status,
                   p_message);
      END IF;
   EXCEPTION
      WHEN ex_no_metadata THEN
         p_status := ga.general_exception;
         logs.log_error('PJM DataMiner2 Subscription-Key is missing. Please add key to System Settings -> PMM -> DataMiner2');
      WHEN OTHERS THEN
         p_status  := SQLCODE;
         p_message := 'Error in MEX_PJM_DM2.FETCH_LMP: ' || SQLERRM;

   END fetch_lmp;
END mex_pjm_dm2;
/

