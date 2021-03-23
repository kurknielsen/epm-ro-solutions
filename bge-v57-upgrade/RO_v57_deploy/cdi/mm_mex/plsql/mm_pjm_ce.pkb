CREATE OR REPLACE PACKAGE BODY MM_PJM_CE IS

   c_one_second            CONSTANT NUMBER := 1 / (24 * 60 * 60);
   c_log_only              CONSTANT NUMBER(1) := 0;
   c_allocation            CONSTANT VARCHAR2(16) := 'Allocation';
   c_ucap_allocation_calc  CONSTANT VARCHAR2(32) := 'INV: UCAP Allocation';
   c_egs                   CONSTANT VARCHAR2(16) := 'EGS';
   c_erpm_ds               CONSTANT VARCHAR2(16) := 'eRPM-DS';
   c_capacity              CONSTANT VARCHAR2(16) := 'Capacity';
   c_transmission          CONSTANT VARCHAR2(16) := 'Transmission';
   c_ucap                  CONSTANT VARCHAR2(16) := 'UCAP';
   
   FUNCTION what_version RETURN VARCHAR IS
   BEGIN
      RETURN '$Revision: 1.18 $';
   END what_version;

   ---------------------------------------------------------------------------------------

   FUNCTION id_for_service_zone(p_zone_name IN VARCHAR2) RETURN NUMBER AS
      v_id NUMBER(9);
   BEGIN
      SELECT nvl(MAX(service_zone_id), 0)
        INTO v_id
        FROM service_zone
       WHERE service_zone_alias = p_zone_name;
      RETURN v_id;
   END id_for_service_zone;

   -------------------------------------------------------------------------------------------------------

   FUNCTION get_tx_id
   (
      p_ext_id           IN VARCHAR2,
      p_trans_type       IN VARCHAR2 := 'Market Result',
      p_name             IN VARCHAR2 := NULL,
      p_interval         IN VARCHAR2 := 'Hour',
      p_commodity_id     IN NUMBER := 0,
      p_contract_id      IN NUMBER := 0,
      p_zod_id           IN NUMBER := 0,
      p_service_point_id IN NUMBER := 0,
      p_pool_id          IN NUMBER := 0,
      p_seller_id        IN NUMBER := 0
   ) RETURN NUMBER IS

      v_id             NUMBER;
      v_sc             NUMBER(9);
      v_suffix         VARCHAR2(32) := '';
      v_tmp            VARCHAR2(32);
      v_name           VARCHAR2(64);
      v_transaction    interchange_transaction%ROWTYPE;
      v_transaction_id interchange_transaction.transaction_id%TYPE;

   BEGIN
      IF p_ext_id IS NULL THEN
         SELECT transaction_id
           INTO v_id
           FROM interchange_transaction
          WHERE transaction_type = p_trans_type
            AND contract_id = p_contract_id
            AND (p_service_point_id = 0 OR pod_id = p_service_point_id)
            AND (p_pool_id = 0 OR pool_id = p_pool_id)
            AND (p_seller_id = 0 OR seller_id = p_seller_id)
            AND (p_zod_id = 0 OR zod_id = p_zod_id);
      ELSE
         SELECT transaction_id
           INTO v_id
           FROM interchange_transaction
          WHERE transaction_identifier = p_ext_id
            AND (p_contract_id = 0 OR contract_id = p_contract_id)
            AND (p_service_point_id = 0 OR pod_id = p_service_point_id)
            AND (p_pool_id = 0 OR pool_id = p_pool_id)
            AND (p_seller_id = 0 OR seller_id = p_seller_id)
            AND (p_zod_id = 0 OR zod_id = p_zod_id);
      END IF;

      RETURN v_id;

   EXCEPTION
      WHEN no_data_found THEN
         v_name := nvl(p_name, p_ext_id);

         SELECT sc_id
           INTO v_sc
           FROM schedule_coordinator
          WHERE sc_name = 'PJM';

         IF p_contract_id <> 0 THEN
            SELECT ': ' || contract_name
              INTO v_tmp
              FROM interchange_contract
             WHERE contract_id = p_contract_id;
            v_suffix := v_suffix || v_tmp;
         END IF;
         IF p_seller_id <> 0 THEN
            SELECT ': ' || pse_name
              INTO v_tmp
              FROM purchasing_selling_entity
             WHERE pse_id = p_seller_id;
            v_suffix := v_suffix || v_tmp;
         END IF;
         IF p_pool_id <> 0 THEN
            SELECT ': ' || pool_name
              INTO v_tmp
              FROM pool
             WHERE pool_id = p_pool_id;
            v_suffix := v_suffix || v_tmp;
         END IF;
         IF p_service_point_id <> 0 THEN
            SELECT ': ' || service_point_name
              INTO v_tmp
              FROM service_point
             WHERE service_point_id = p_service_point_id;
            v_suffix := v_suffix || v_tmp;
         END IF;
         --create the transaction
         v_transaction.transaction_id         := 0;
         v_transaction.transaction_name       := substr(v_name || v_suffix,
                                                        1,
                                                        64);
         v_transaction.transaction_alias      := substr(v_name || v_suffix,
                                                        1,
                                                        32);
         v_transaction.transaction_desc       := v_name || v_suffix;
         v_transaction.transaction_type       := p_trans_type;
         v_transaction.transaction_identifier := p_ext_id;
         v_transaction.transaction_interval   := p_interval;
         v_transaction.begin_date             := to_date('1/1/2000',
                                                         'MM/DD/YYYY');
         v_transaction.end_date               := to_date('12/31/2020',
                                                         'MM/DD/YYYY');
         v_transaction.seller_id              := p_seller_id;
         v_transaction.contract_id            := p_contract_id;
         v_transaction.sc_id                  := v_sc;
         v_transaction.pod_id                 := p_service_point_id;
         v_transaction.pool_id                := p_pool_id;
         v_transaction.zod_id                 := p_zod_id;
         v_transaction.commodity_id           := p_commodity_id;

         mm_util.put_transaction(v_transaction_id,
                                 v_transaction,
                                 ga.internal_state,
                                 'Active');

         RETURN v_transaction_id;
   END get_tx_id;

   ---------------------------------------------------------------------------------------------------

   FUNCTION get_ucap_transaction_id
   (
      p_contract_name IN VARCHAR2,
      p_service_date  IN DATE
   ) RETURN NUMBER IS

      v_pse_id            NUMBER(9);
      v_commodity_id      NUMBER(9);
      v_contract_id       NUMBER(9) := 0;
      v_schedule_group_id NUMBER(9) := 0;
      v_transaction_id    NUMBER := 0;

      v_transaction_name interchange_transaction.transaction_name%TYPE;

   BEGIN

      SELECT MAX(commodity_id)
        INTO v_commodity_id
        FROM it_commodity
       WHERE commodity_name = g_ucap_type;

      SELECT MAX(it.transaction_id)
        INTO v_transaction_id
        FROM interchange_transaction it, tp_contract_number b
       WHERE it.contract_id = b.contract_id
         AND p_service_date BETWEEN b.begin_date AND
             nvl(b.end_date, constants.high_date)
         AND it.schedule_group_id IN
             (SELECT schedule_group_id
                FROM schedule_group
               WHERE schedule_group_name IN ('EGS', 'eRPM-DS'))
         AND it.commodity_id =
             (SELECT commodity_id
                FROM it_commodity
               WHERE commodity_name = g_ucap_type)
         AND b.contract_name = p_contract_name
         AND rownum = 1;

      IF v_transaction_id IS NULL THEN
         v_transaction_id := 0;
         SELECT MAX(billing_entity_id), MAX(contract_id)
           INTO v_pse_id, v_contract_id
           FROM (SELECT a.billing_entity_id billing_entity_id,
                        a.contract_id contract_id
                   FROM interchange_contract a, tp_contract_number b
                  WHERE a.contract_id = b.contract_id
                    AND b.contract_name = p_contract_name
                    AND p_service_date BETWEEN b.begin_date AND
                        nvl(b.end_date, high_date)
                  ORDER BY a.contract_id DESC)
          WHERE rownum = 1;

         IF v_contract_id IS NOT NULL THEN
            -- Generate Only For EGS --
            IF v_pse_id = 0 OR v_pse_id IS NULL THEN
               SELECT MAX(schedule_group_id)
                 INTO v_schedule_group_id
                 FROM schedule_group
                WHERE schedule_group_name = g_schedule_group_name;
               v_transaction_name := 'PSE ' || p_contract_name ||
                                     '_UCAP@PECO Retail';
               io.put_transaction(o_oid                      => v_transaction_id,
                                  p_transaction_name         => v_transaction_name,
                                  p_transaction_alias        => v_transaction_name,
                                  p_transaction_desc         => 'PJM Shortname transaction created eRPM',
                                  p_transaction_id           => v_transaction_id,
                                  p_transaction_type         => g_transaction_type,
                                  p_transaction_code         => 1,
                                  p_transaction_identifier   => p_contract_name,
                                  p_is_firm                  => 0,
                                  p_is_import_schedule       => 0,
                                  p_is_export_schedule       => 0,
                                  p_is_balance_transaction   => 0,
                                  p_is_bid_offer             => 0,
                                  p_is_exclude_from_position => 0,
                                  p_is_import_export         => 0,
                                  p_is_dispatchable          => 0,
                                  p_transaction_interval     => 'Day',
                                  p_external_interval        => 'Day',
                                  p_etag_code                => NULL,
                                  p_begin_date               => trunc(p_service_date),
                                  p_end_date                 => trunc(p_service_date),
                                  p_purchaser_id             => NULL,
                                  p_seller_id                => NULL,
                                  p_contract_id              => v_contract_id,
                                  p_sc_id                    => 0,
                                  p_por_id                   => 0,
                                  p_pod_id                   => 0,
                                  p_commodity_id             => v_commodity_id,
                                  p_service_type_id          => 0,
                                  p_tx_transaction_id        => 0,
                                  p_path_id                  => 0,
                                  p_link_transaction_id      => 0,
                                  p_edc_id                   => 0,
                                  p_pse_id                   => v_pse_id,
                                  p_esp_id                   => 0,
                                  p_pool_id                  => 0,
                                  p_schedule_group_id        => v_schedule_group_id,
                                  p_market_price_id          => 0,
                                  p_zor_id                   => 0,
                                  p_zod_id                   => 0,
                                  p_source_id                => 0,
                                  p_sink_id                  => 0,
                                  p_resource_id              => 0,
                                  p_agreement_type           => NULL,
                                  p_approval_type            => NULL,
                                  p_loss_option              => NULL,
                                  p_trait_category           => NULL,
                                  p_tp_id                    => 0);
            ELSE
               NULL; --@@Deprecate: v_transaction_id := cdi_procurement.shortname_transaction(p_contract_name, v_pse_id, v_commodity_id, g_transaction_type, 'Day', p_service_date);
            END IF;
         END IF;
      END IF;

      -- Update The Date Range For This Transaction --
      UPDATE interchange_transaction
         SET begin_date = least(begin_date, p_service_date),
             end_date   = greatest(nvl(end_date, p_service_date), p_service_date)
       WHERE transaction_id = v_transaction_id;

      RETURN v_transaction_id;
   END get_ucap_transaction_id;

   -------------------------------------------------------------------------------

   PROCEDURE put_schedule_value
   (
      p_tx_id       IN NUMBER,
      p_sched_date  IN DATE,
      p_amount      NUMBER,
      p_price       NUMBER := NULL,
      p_to_internal BOOLEAN := TRUE
   ) AS

      v_status NUMBER;

   BEGIN

      FOR v_idx IN 1 .. mm_pjm_util.g_statement_type_id_array.count LOOP
         IF p_to_internal THEN
            itj.put_it_schedule(p_transaction_id => p_tx_id,
                                p_schedule_type  => mm_pjm_util.g_statement_type_id_array(v_idx),
                                p_schedule_state => 1,
                                p_schedule_date  => p_sched_date,
                                p_as_of_date     => SYSDATE,
                                p_amount         => p_amount,
                                p_price          => p_price,
                                p_status         => v_status);
         END IF;
         itj.put_it_schedule(p_transaction_id => p_tx_id,
                             p_schedule_type  => mm_pjm_util.g_statement_type_id_array(v_idx),
                             p_schedule_state => 2,
                             p_schedule_date  => p_sched_date,
                             p_as_of_date     => SYSDATE,
                             p_amount         => p_amount,
                             p_price          => p_price,
                             p_status         => v_status);
      END LOOP;

   END put_schedule_value;

   ---------------------------------------------------------------------------------------------------

   PROCEDURE put_final_schedule_value
   (
      p_tx_id       IN NUMBER,
      p_sched_date  IN DATE,
      p_amount      NUMBER,
      p_price       NUMBER := NULL,
      p_to_internal BOOLEAN := FALSE
   ) AS

      v_status NUMBER;

   BEGIN

      IF p_to_internal THEN
         itj.put_it_schedule(p_transaction_id => p_tx_id,
                             p_schedule_type  => ga.schedule_type_final,
                             p_schedule_state => 1,
                             p_schedule_date  => p_sched_date,
                             p_as_of_date     => SYSDATE,
                             p_amount         => p_amount,
                             p_price          => p_price,
                             p_status         => v_status);
      END IF;
      itj.put_it_schedule(p_transaction_id => p_tx_id,
                          p_schedule_type  => ga.schedule_type_final,
                          p_schedule_state => 2,
                          p_schedule_date  => p_sched_date,
                          p_as_of_date     => SYSDATE,
                          p_amount         => p_amount,
                          p_price          => p_price,
                          p_status         => v_status);

   END put_final_schedule_value;

   -- -------------------------------------------------------------------------------
   -- IMPORT_NSPL : MODFICATION HISTORY
   -- -------------------------------------------------------------------------------
   -- User  Date         CR        Comments
   -- ----  -----------  --------  --------------------------------------------------
   -- KEN   2014-Jul-21  00200949  Too Many Unnecessary Warnings when Downloading PLCs RESP
   -- RTo   2013-APR-15  00157018  Add support to only process rows until p_end_date
   -- -------------------------------------------------------------------------------
   PROCEDURE import_nspl
   (
      p_records  IN mex_pjm_ecap_load_obl_tbl,
      p_end_date DATE,
      p_status   OUT NUMBER,
      p_message  OUT VARCHAR2,
      p_logger   IN OUT mm_logger_adapter
   ) AS

      v_index          BINARY_INTEGER;
      v_zone_name      VARCHAR2(16);
      v_transaction_id NUMBER(9);
      v_zod_id         NUMBER(9);
      v_lse_name       VARCHAR2(64);

   BEGIN

      p_status := ga.success;
      IF p_records.count = 0 THEN
         p_logger.log_warn('No Records Were Downloaded.');

         RETURN;
      END IF;

      v_index := p_records.first;

      WHILE p_records.exists(v_index) LOOP
         IF p_records(v_index).loaddate <= p_end_date THEN
            v_lse_name  := p_records(v_index).companyselected;
            v_zone_name := p_records(v_index).zonearea;
            v_zod_id    := id_for_service_zone(v_zone_name);

            SELECT MAX(transaction_id)
              INTO v_transaction_id
              FROM interchange_transaction a,
                   interchange_contract c,
                   tp_contract_number t
             WHERE transaction_type = 'Ancillary'
               AND a.schedule_group_id IN
                   (SELECT schedule_group_id
                      FROM schedule_group
                     WHERE schedule_group_name IN ('eRPM-DS', 'EGS'))
               AND a.commodity_id =
                   (SELECT commodity_id
                      FROM it_commodity
                     WHERE commodity_name = 'Transmission')
               AND a.contract_id <> 0
               AND a.contract_id = c.contract_id
               AND c.contract_id = t.contract_id
               AND p_records(v_index).loaddate BETWEEN t.begin_date AND
                   nvl(t.end_date, constants.high_date)
               AND t.contract_name = v_lse_name;

            IF v_transaction_id IS NULL THEN
               IF nvl(p_records(v_index).nspl, 0) = 0 THEN
                  p_logger.log_info('No Transmission Provider Contract Found For "' ||
                                    v_lse_name || '" On: ' ||
                                    text_util.to_char_date(p_records(v_index)
                                                           .loaddate) ||
                                    '. NSPL Import Disabled For This Record.');
               ELSE
                  p_logger.log_error('Greater than zero nspl sent for inactive Transmission Provider Contract Found  "' ||
                                     v_lse_name || '" On: ' ||
                                     text_util.to_char_date(p_records(v_index)
                                                            .loaddate) ||
                                     '. NSPL Import Disabled For this Record.');
               END IF;
            ELSE
               put_final_schedule_value(v_transaction_id,
                                        p_records       (v_index)
                                        .loaddate + c_one_second,
                                        p_records       (v_index).nspl);
            END IF;

         END IF;
         v_index := p_records.next(v_index);

      END LOOP;
   END import_nspl;

   PROCEDURE import_nspl
   (
      p_cred       IN mex_credentials,
      p_log_only   IN NUMBER,
      p_begin_date IN DATE,
      p_end_date   IN DATE,
      p_status     OUT NUMBER,
      p_message    OUT VARCHAR2,
      p_logger     IN OUT mm_logger_adapter
   ) AS

      v_records                    mex_pjm_ecap_load_obl_tbl;
      v_begin_date                 DATE := p_begin_date;
      v_sub_periods_with_no_import PLS_INTEGER := 0;

   BEGIN

      p_status := ga.success;
      p_logger.log_info('Import NSPL For Time Period: ' ||
                        text_util.to_char_date(p_begin_date) || '-' ||
                        text_util.to_char_date(p_end_date));

      -- Delete Existing External Final NSPL Data For EGS And Allocated Default Supplier Short Name Schedule Data --
      DELETE it_schedule
       WHERE transaction_id IN
             (SELECT transaction_id
                FROM interchange_transaction
               WHERE transaction_type = 'Ancillary'
                 AND schedule_group_id IN
                     (SELECT schedule_group_id
                        FROM schedule_group
                       WHERE schedule_group_name IN
                             (c_erpm_ds,
                              c_egs,
                              c_allocation))
                 AND commodity_id =
                     (SELECT commodity_id
                        FROM it_commodity
                       WHERE commodity_name = c_transmission))
         AND schedule_type = ga.schedule_type_final
         AND schedule_state = constants.external_state
         AND schedule_date BETWEEN p_begin_date AND p_end_date + c_one_second;
      p_logger.log_info('Number Of Records Deleted Prior To Import: ' ||
                        to_char(SQL%ROWCOUNT) || '.');

      -- Perform The Import In Five(5) Day Sub-Period Blocks --
      WHILE v_begin_date <= p_end_date LOOP
         mex_pjm_ce.fetch_netwk_serv_pk_ld(p_cred,
                                           p_log_only,
                                           v_begin_date,
                                           p_cred.external_account_name,
                                           v_records,
                                           p_status,
                                           p_message,
                                           p_logger);
         IF p_status = ga.success THEN
            IF v_records.count = 0 THEN
               v_sub_periods_with_no_import := v_sub_periods_with_no_import + 1;
               p_logger.log_warn('No NSPL Content Imported For Sub-Period: ' ||
                                 text_util.to_char_date(v_begin_date) || '-' ||
                                 text_util.to_char_date(least(v_begin_date + 4,
                                                              p_end_date)) || '.');
            ELSE
               import_nspl(v_records,
                           p_end_date,
                           p_status,
                           p_message,
                           p_logger);
               p_logger.log_info('NSPL Import Complete For Sub-Period: ' ||
                                 text_util.to_char_date(v_begin_date) || '-' ||
                                 text_util.to_char_date(least(v_begin_date + 4,
                                                              p_end_date)) || '.');
            END IF;
         END IF;
         v_begin_date := v_begin_date + 5;
      END LOOP;

      IF v_sub_periods_with_no_import > 0 THEN
         p_message := 'Detected ' || to_char(v_sub_periods_with_no_import) ||
                      ' Sub-Periods With No Import Content.';
      END IF;

   END import_nspl;

   -- -------------------------------------------------------------------------------
   -- IMPORT_PLC : MODFICATION HISTORY
   -- -------------------------------------------------------------------------------
   -- User  Date         CR        Comments
   -- ----  -----------  --------  --------------------------------------------------
   -- KEN   2014-Sep-05  00200949  Fixed error with put_final_schedule_value - p_records(v_index).obligation
   -- KEN   2014-Jul-21  00200949  Too Many Unnecessary Warnings when Downloading PLCs RESP
   -- -------------------------------------------------------------------------------
   PROCEDURE import_plc
   (
      p_records IN mex_pjm_ecap_load_obl_tbl,
      p_status  OUT NUMBER,
      p_message OUT VARCHAR2,
      p_logger  IN OUT mm_logger_adapter
   ) AS

      v_index          BINARY_INTEGER;
      v_zone_name      VARCHAR2(16);
      v_transaction_id NUMBER(9);
      v_zod_id         NUMBER(9);
      v_lse_name       VARCHAR2(64);

   BEGIN
      p_status := ga.success;
      v_index  := p_records.first;

      WHILE p_records.exists(v_index) LOOP
         v_lse_name  := p_records(v_index).companyselected;
         v_zone_name := p_records(v_index).zonearea;
         v_zod_id    := id_for_service_zone(v_zone_name);

         SELECT MAX(transaction_id)
           INTO v_transaction_id
           FROM interchange_transaction a,
                interchange_contract c,
                tp_contract_number t
          WHERE transaction_type = 'Ancillary'
            AND a.schedule_group_id IN
                (SELECT schedule_group_id
                   FROM schedule_group
                  WHERE schedule_group_name IN ('eRPM-DS', 'EGS'))
            AND a.commodity_id =
                (SELECT commodity_id
                   FROM it_commodity
                  WHERE commodity_name = 'Capacity')
            AND a.contract_id <> 0
            AND a.contract_id = c.contract_id
            AND c.contract_id = t.contract_id
            AND p_records(v_index).loaddate BETWEEN t.begin_date AND
                nvl(t.end_date, constants.high_date)
            AND t.contract_name = v_lse_name;

         IF v_transaction_id IS NULL THEN
            IF p_records(v_index).obligation = 0 THEN
               p_logger.log_info('No Transmission Provider Contract Found For "' ||
                                 v_lse_name || '" On: ' ||
                                 text_util.to_char_date(p_records(v_index)
                                                        .loaddate) ||
                                 '. PLC Import Disabled For This Record.');
            ELSE
               p_logger.log_error('Greater than zero obligation sent for inactive Transmission Provider Contract Found  "' ||
                                  v_lse_name || '" On: ' ||
                                  text_util.to_char_date(p_records(v_index)
                                                         .loaddate) ||
                                  '. PLC Import Disabled For this Record.');
            END IF;
         ELSE
            put_final_schedule_value(v_transaction_id,
                                     p_records       (v_index)
                                     .loaddate + c_one_second,
                                     p_records       (v_index).obligation);
         END IF;

         v_index := p_records.next(v_index);
      END LOOP;

   END import_plc;

   PROCEDURE import_plc
   (
      p_cred       IN mex_credentials,
      p_log_only   IN NUMBER,
      p_begin_date IN DATE,
      p_end_date   IN DATE,
      p_status     OUT NUMBER,
      p_message    OUT VARCHAR2,
      p_logger     IN OUT mm_logger_adapter
   ) AS

      v_records             mex_pjm_ecap_load_obl_tbl;
      v_begin_date          DATE := p_begin_date;
      v_days_with_no_import PLS_INTEGER := 0;

   BEGIN

      p_status := ga.success;
      p_logger.log_info('Import PLC For Time Period: ' ||
                        text_util.to_char_date(p_begin_date) || '-' ||
                        text_util.to_char_date(p_end_date));

      -- Delete Existing External Final PLC Data For EGS And Allocated Default Supplier Short Name Schedule Data --
      DELETE it_schedule
       WHERE transaction_id IN
             (SELECT transaction_id
                FROM interchange_transaction
               WHERE transaction_type = 'Ancillary'
                 AND schedule_group_id IN
                     (SELECT schedule_group_id
                        FROM schedule_group
                       WHERE schedule_group_name IN
                             (c_erpm_ds,
                              c_egs,
                              c_allocation))
                 AND commodity_id =
                     (SELECT commodity_id
                        FROM it_commodity
                       WHERE commodity_name = c_capacity))
         AND schedule_type = ga.schedule_type_final
         AND schedule_state = constants.external_state
         AND schedule_date BETWEEN p_begin_date AND p_end_date + c_one_second;
      p_logger.log_info('Number Of Records Deleted Prior To Import: ' ||
                        to_char(SQL%ROWCOUNT) || '.');

      WHILE v_begin_date <= p_end_date LOOP
         mex_pjm_ce.query_uploaded_mw(p_cred,
                                      p_log_only,
                                      v_begin_date,
                                      p_cred.external_account_name,
                                      v_records,
                                      p_status,
                                      p_message,
                                      p_logger);
         IF p_status = ga.success THEN
            IF v_records.count = 0 THEN
               v_days_with_no_import := v_days_with_no_import + 1;
               p_logger.log_warn('No PLC Content Imported For ' ||
                                 text_util.to_char_date(v_begin_date) || '.');
            ELSE
               import_plc(v_records, p_status, p_message, p_logger);
               p_logger.log_info('PLC Import Complete For: ' ||
                                 text_util.to_char_date(v_begin_date));
            END IF;
         END IF;
         v_begin_date := v_begin_date + 1;
      END LOOP;

      IF v_days_with_no_import > 0 THEN
         p_message := 'Detected ' || to_char(v_days_with_no_import) ||
                      ' Days With No Import Content.';
      END IF;

   END import_plc;

   PROCEDURE import_nspl_short_name
   (
      p_records IN mex_pjm_ecap_load_obl_tbl,
      p_status  OUT NUMBER,
      p_message OUT VARCHAR2,
      p_logger  IN OUT mm_logger_adapter,
      p_nspl_sn IN OUT BOOLEAN
   ) AS

      v_index    BINARY_INTEGER;
      v_lse_name VARCHAR2(64);

   BEGIN

      p_status := ga.success;
      IF p_records.count = 0 THEN
         p_logger.log_warn('No Records Were Downloaded.');
         RETURN;
      END IF;

      v_index := p_records.first;

      WHILE p_records.exists(v_index) LOOP
         v_lse_name := p_records(v_index).companyselected;
         -- Collect only names with at least one non-zero value
         IF p_records(v_index).nspl > 0.0 THEN
            INSERT INTO cdi_pjm_short_name_temp VALUES (v_lse_name);
            p_nspl_sn := TRUE;
         END IF;
         v_index := p_records.next(v_index);
      END LOOP;

   END import_nspl_short_name;

    PROCEDURE import_plc_short_names
   (
      p_records IN mex_pjm_ecap_load_obl_tbl,
      p_status  OUT NUMBER,
      p_message OUT VARCHAR2,
      p_logger  IN OUT mm_logger_adapter,
      p_plc_sn  IN OUT BOOLEAN
   ) AS

      v_index    BINARY_INTEGER;
      v_lse_name VARCHAR2(64);

   BEGIN
      p_status := ga.success;
      v_index  := p_records.first;

      WHILE p_records.exists(v_index) LOOP
         v_lse_name := p_records(v_index).companyselected;
         -- Collect only names with at least one non-zero value
         IF p_records(v_index).obligation > 0.0 THEN
            INSERT INTO cdi_pjm_short_name_temp VALUES (v_lse_name);
            p_plc_sn := TRUE;
         END IF;
         v_index := p_records.next(v_index);
      END LOOP;

      COMMIT;

   END import_plc_short_names;

   PROCEDURE import_short_names
   (
      p_cred       IN mex_credentials,
      p_log_only   IN NUMBER,
      p_begin_date IN DATE,
      p_end_date   IN DATE,
      p_status     OUT NUMBER,
      p_message    OUT VARCHAR2,
      p_logger     IN OUT mm_logger_adapter
   ) AS

      v_records             mex_pjm_ecap_load_obl_tbl;
      v_begin_date          DATE := p_begin_date;
      v_days_with_no_import PLS_INTEGER := 0;

      v_sub_periods_with_no_import PLS_INTEGER := 0;
      v_records_nspl               mex_pjm_ecap_load_obl_tbl;

      v_count       NUMBER;
      v_delete_done BOOLEAN := FALSE;
      v_plc_sn      BOOLEAN := FALSE;
      v_nspl_sn     BOOLEAN := FALSE;

   BEGIN

      p_status := ga.success;
      p_logger.log_info('Import PLC Short Names For Time Period: ' ||
                        text_util.to_char_date(p_begin_date) || '-' ||
                        text_util.to_char_date(p_end_date));

      WHILE v_begin_date <= p_end_date LOOP
         mex_pjm_ce.query_uploaded_mw(p_cred,
                                      p_log_only,
                                      v_begin_date,
                                      p_cred.external_account_name,
                                      v_records,
                                      p_status,
                                      p_message,
                                      p_logger);
         IF p_status = ga.success THEN
            IF v_records.count = 0 THEN
               v_days_with_no_import := v_days_with_no_import + 1;
               p_logger.log_warn('No Short Names Imported For ' ||
                                 text_util.to_char_date(v_begin_date) || '.');
            ELSE
               -- Clean the TEMP table before new data population
               IF NOT v_delete_done THEN
                  DELETE FROM cdi_pjm_short_name_temp;
                  v_delete_done := TRUE;
               END IF;
               import_plc_short_names(v_records,
                                      p_status,
                                      p_message,
                                      p_logger,
                                      v_plc_sn);
               IF v_plc_sn THEN
                  p_logger.log_info('PLC Short Names Import Complete For: ' ||
                                    text_util.to_char_date(v_begin_date));
               ELSE
                  p_logger.log_warn('No PLC Short Names with non-zero Schedule for: ' ||
                                    text_util.to_char_date(v_begin_date));
               END IF;
            END IF;
         END IF;
         v_begin_date := v_begin_date + 1;
         v_plc_sn     := FALSE;
      END LOOP;

      IF v_days_with_no_import > 0 THEN
         p_message := 'Detected ' || to_char(v_days_with_no_import) ||
                      ' Days With No Import Content.';
      END IF;

      p_logger.log_info('Import NSPL Short Names For Time Period: ' ||
                        text_util.to_char_date(p_begin_date) || '-' ||
                        text_util.to_char_date(p_end_date));
      v_begin_date := p_begin_date;

      -- Perform The Import In Five(5) Day Sub-Period Blocks --
      WHILE v_begin_date <= p_end_date LOOP
         mex_pjm_ce.fetch_netwk_serv_pk_ld(p_cred,
                                           p_log_only,
                                           v_begin_date,
                                           p_cred.external_account_name,
                                           v_records_nspl,
                                           p_status,
                                           p_message,
                                           p_logger);
         IF p_status = ga.success THEN
            IF v_records_nspl.count = 0 THEN
               v_sub_periods_with_no_import := v_sub_periods_with_no_import + 1;
               p_logger.log_warn('No NSPL Short Names Imported For Sub-Period: ' ||
                                 text_util.to_char_date(v_begin_date) || '-' ||
                                 text_util.to_char_date(least(v_begin_date + 4,
                                                              p_end_date)) || '.');
            ELSE
               -- Clean the TEMP table before new data population
               IF NOT v_delete_done THEN
                  DELETE FROM cdi_pjm_short_name_temp;
                  v_delete_done := TRUE;
               END IF;
               import_nspl_short_name(v_records_nspl,
                                      p_status,
                                      p_message,
                                      p_logger,
                                      v_nspl_sn);
               IF v_nspl_sn THEN
                  p_logger.log_info('NSPL Short Name Import Complete For Sub-Period: ' ||
                                    text_util.to_char_date(v_begin_date) || '-' ||
                                    text_util.to_char_date(least(v_begin_date + 4,
                                                                 p_end_date)) || '.');
               ELSE
                  p_logger.log_warn('No NSPL Short Names with non-zero Schedule For Sub-Period: ' ||
                                    text_util.to_char_date(v_begin_date) || '-' ||
                                    text_util.to_char_date(least(v_begin_date + 4,
                                                                 p_end_date)) || '.');
               END IF;
            END IF;
         END IF;
         v_begin_date := v_begin_date + 5;
         v_nspl_sn    := FALSE;
      END LOOP;

      IF v_sub_periods_with_no_import > 0 THEN
         p_message := 'Detected ' || to_char(v_sub_periods_with_no_import) ||
                      ' Sub-Periods With No Import Content.';
      END IF;

      -- Populate data into main PJM Short Name table
      SELECT COUNT(DISTINCT contract_name)
        INTO v_count
        FROM cdi_pjm_short_name_temp;

      IF v_count < 1 OR (NOT v_delete_done) THEN
         p_logger.log_warn('No Short Names Imported.');
      ELSE
         DELETE FROM cdi_pjm_short_name;

         INSERT INTO cdi_pjm_short_name(pjm_short_name)
            (SELECT DISTINCT contract_name FROM cdi_pjm_short_name_temp);

         p_logger.log_info(to_char(v_count) || ' Short Names Downloaded');

      END IF;

   END import_short_names;

   PROCEDURE allocate_ucap
   (
      p_begin_date IN DATE,
      p_end_date   IN DATE,
      p_status     OUT NUMBER,
      p_message    OUT VARCHAR2
   ) IS

      v_calc_process_id   calculation_process.calc_process_id%TYPE;
      v_selected_entities number_collection;

   BEGIN
      p_status := ga.success;
      SELECT MAX(calc_process_id)
        INTO v_calc_process_id
        FROM calculation_process
       WHERE calc_process_name = c_ucap_allocation_calc;

      calc_engine.run_calc_process(v_calc_process_id,
                                   v_selected_entities,
                                   ga.schedule_type_final,
                                   p_begin_date,
                                   p_end_date,
                                   constants.low_date,
                                   0,
                                   p_status,
                                   p_message);
   END allocate_ucap;

   PROCEDURE import_ucap
   (
      p_records    IN mex_pjm_ecap_load_obl_tbl,
      p_begin_date IN DATE,
      p_end_date   IN DATE,
      p_status     OUT NUMBER,
      p_message    OUT VARCHAR2,
      p_logger     IN OUT mm_logger_adapter
   ) AS

      v_index          BINARY_INTEGER;
      v_transaction_id NUMBER(9);
      v_lse_name       VARCHAR2(64);
      v_loaddate       DATE;

   BEGIN
      p_status := ga.success;
      v_index  := p_records.first;

      WHILE p_records.exists(v_index) LOOP
         v_lse_name := p_records(v_index).companyselected;
         v_loaddate := p_records(v_index).loaddate;

         v_transaction_id := get_ucap_transaction_id(v_lse_name,
                                                     trunc(v_loaddate));

         -- Process the record only when the load date is within the user-defined period
         IF v_loaddate >= p_begin_date AND v_loaddate <= p_end_date THEN
            IF v_transaction_id > 0 THEN
               put_final_schedule_value(v_transaction_id,
                                        v_loaddate + c_one_second,
                                        p_records(v_index).obligation,
                                        p_to_internal => TRUE);
            ELSE
               IF nvl(p_records(v_index).obligation, 0) = 0 THEN
                  p_logger.log_info('No Transmission Provider Contract Found For "' ||
                                    v_lse_name || '" On: ' ||
                                    text_util.to_char_date(p_records(v_index)
                                                           .loaddate) ||
                                    '. UCAP Import Disabled For This Record.');
               ELSE
                  p_logger.log_error('Greater than zero ucap sent for inactive Transmission Provider Contract Found  "' ||
                                     v_lse_name || '" On: ' ||
                                     text_util.to_char_date(v_loaddate) ||
                                     '. UCAP Import Disabled For This Record.');
               END IF;
            END IF;
         END IF;

         v_index := p_records.next(v_index);
      END LOOP;

      p_logger.log_info('Begin CalcEngine UCAP Allocation.');
      allocate_ucap(p_begin_date, p_end_date, p_status, p_message);
      p_logger.log_info('End CalcEngine UCAP Allocation.');

   END import_ucap;

   PROCEDURE import_ucap
   (
      p_cred       IN mex_credentials,
      p_log_only   IN NUMBER,
      p_begin_date IN DATE,
      p_end_date   IN DATE,
      p_status     OUT NUMBER,
      p_message    OUT VARCHAR2,
      p_logger     IN OUT mm_logger_adapter
   ) AS

      v_records                    mex_pjm_ecap_load_obl_tbl;
      v_begin_date                 DATE := p_begin_date;
      v_sub_periods_with_no_import PLS_INTEGER := 0;

   BEGIN

      p_status := ga.success;
      p_logger.log_info('Import UCAP For Time Period: ' ||
                        text_util.to_char_date(p_begin_date) || '-' ||
                        text_util.to_char_date(p_end_date));

      -- Delete Internal Short Name And Allocated UCAP Schedules For Default Suppliers --
      -- Internal UCAP Data For EGS Suppliers And --
      -- External Data For Short Name EGS And Default Supplier UCAP Schedule Data --
      DELETE it_schedule
       WHERE transaction_id IN
             (SELECT transaction_id
                FROM interchange_transaction
               WHERE transaction_type = 'Ancillary'
                 AND schedule_group_id IN
                     (SELECT schedule_group_id
                        FROM schedule_group
                       WHERE schedule_group_name IN
                             (c_erpm_ds,
                              c_egs,
                              c_allocation))
                 AND commodity_id =
                     (SELECT commodity_id
                        FROM it_commodity
                       WHERE commodity_name = c_ucap))
         AND schedule_type = ga.schedule_type_final
         AND schedule_state IN
             (constants.internal_state, constants.external_state)
         AND schedule_date BETWEEN p_begin_date AND p_end_date + c_one_second;
      p_logger.log_info('Number Of Records Deleted Prior To Import: ' ||
                        to_char(SQL%ROWCOUNT) || '.');

      -- Perform The Import In Five(5) Day Sub-Period Blocks --
      WHILE v_begin_date <= p_end_date LOOP
         mex_pjm_ce.fetch_capacity_obligation(p_cred,
                                              p_log_only,
                                              v_begin_date,
                                              p_cred.external_account_name,
                                              v_records,
                                              p_status,
                                              p_message,
                                              p_logger);
         IF p_status = ga.success THEN
            IF v_records.count = 0 THEN
               v_sub_periods_with_no_import := v_sub_periods_with_no_import + 1;
               p_logger.log_warn('No UCAP Content Imported For Sub-Period: ' ||
                                 text_util.to_char_date(v_begin_date) || '-' ||
                                 text_util.to_char_date(least(v_begin_date + 4,
                                                              p_end_date)) || '.');
            ELSE
               import_ucap(v_records,
                           --p_begin_date,
                           v_begin_date,
                           least(v_begin_date + 4, p_end_date),
                           --p_end_date,
                           p_status,
                           p_message,
                           p_logger);

               p_logger.log_info('UCAP Import Complete For Sub-Period: ' ||
                                 text_util.to_char_date(v_begin_date) || '-' ||
                                 text_util.to_char_date(least(v_begin_date + 4,
                                                              p_end_date)) || '.' ||
                                 'Date passed to import_ucap:' ||
                                 text_util.to_char_date(v_begin_date) || '-' ||
                                 text_util.to_char_date(least(v_begin_date + 4,
                                                              p_end_date)));
            END IF;
         END IF;

         v_begin_date := v_begin_date + 5;
      END LOOP;

   END import_ucap;

   PROCEDURE import_plc_scale_factor
   (
      p_records        IN mex_schedule_tbl,
      p_transaction_id IN NUMBER,
      p_logger         IN OUT mm_logger_adapter,
      p_count          IN OUT NUMBER,
      p_status         OUT NUMBER,
      p_message        OUT VARCHAR2
   ) AS

      v_scale   NUMBER;
      v_date    DATE;
      v_pr_date DATE;
      v_index   BINARY_INTEGER;

   BEGIN
      p_status  := ga.success;
      v_index   := p_records.first;
      v_pr_date := low_date;
      WHILE p_records.exists(v_index) LOOP
         v_scale := p_records(v_index).rate;
         v_date  := p_records(v_index).cut_time + c_one_second;
         IF v_date <> v_pr_date THEN
            put_final_schedule_value(p_transaction_id, v_date, v_scale);
            p_count   := p_count + 1;
            v_pr_date := v_date;
         END IF;
         v_index := p_records.next(v_index);
      END LOOP;
   END import_plc_scale_factor;

   PROCEDURE import_plc_scale_factor
   (
      p_credentials IN mex_credentials,
      p_log_only    IN NUMBER,
      p_begin_date  IN DATE,
      p_end_date    IN DATE,
      p_status      OUT NUMBER,
      p_message     OUT VARCHAR2,
      p_logger      IN OUT mm_logger_adapter
   ) AS

      v_records    mex_schedule_tbl := mex_schedule_tbl();
      v_begin_date DATE;
      v_count      NUMBER := 0;

      v_transaction interchange_transaction%ROWTYPE;
      c_transaction_name CONSTANT VARCHAR2(32) := 'PLC Scale Factor';

      PROCEDURE set_transaction AS
      BEGIN
         SELECT MAX(transaction_id)
           INTO v_transaction.transaction_id
           FROM interchange_transaction
          WHERE transaction_name = c_transaction_name;

         IF v_transaction.transaction_id IS NULL THEN
            v_transaction.transaction_name     := c_transaction_name;
            v_transaction.transaction_alias    := c_transaction_name;
            v_transaction.transaction_desc     := c_transaction_name;
            v_transaction.transaction_type     := 'Market Result';
            v_transaction.begin_date           := low_date;
            v_transaction.end_date             := high_date;
            v_transaction.transaction_interval := 'Day';
            v_transaction.external_interval    := 'Day';

            SELECT nvl(MAX(schedule_group_id), constants.not_assigned)
              INTO v_transaction.schedule_group_id
              FROM schedule_group
             WHERE schedule_group_name = 'Scale Factor';

            SELECT nvl(MAX(commodity_id), constants.not_assigned)
              INTO v_transaction.commodity_id
              FROM it_commodity
             WHERE commodity_name = 'Scale Factor';
         ELSE
            SELECT *
              INTO v_transaction
              FROM interchange_transaction
             WHERE transaction_id = v_transaction.transaction_id;
         END IF;
         mm_util.put_transaction(v_transaction.transaction_id,
                                 v_transaction,
                                 ga.internal_state,
                                 'Active');
      END set_transaction;

   BEGIN

      p_status := ga.success;
      p_logger.log_info('Import PLC Scale Factor');
      p_logger.log_info('Begin Date: ' || text_util.to_char_date(p_begin_date) ||
                        ', End Date: ' || text_util.to_char_date(p_end_date));
      -- Query The Peak Load Scale Factors From PJM --
      v_begin_date := p_begin_date;
      set_transaction;
      WHILE v_begin_date <= p_end_date LOOP
         mex_pjm_ce.query_plc_scale_factor(p_credentials,
                                           p_log_only,
                                           v_begin_date,
                                           p_credentials.external_account_name,
                                           v_records,
                                           p_status,
                                           p_message,
                                           p_logger);
         v_begin_date := v_begin_date + 1;
      END LOOP;

      IF p_status = ga.success AND v_records.count > 0 THEN
         IF v_transaction.transaction_id > 0 THEN
            import_plc_scale_factor(v_records,
                                    v_transaction.transaction_id,
                                    p_logger,
                                    v_count,
                                    p_status,
                                    p_message);
         END IF;
      END IF;

      IF v_count > 0 THEN
         p_message := 'PLC Scale Factor Records Imported: ' || to_char(v_count);
         p_logger.log_info(p_message);
      ELSE
         p_message := 'No PLC Scale Factor Records Imported';
         p_logger.log_warn(p_message);
      END IF;

   END import_plc_scale_factor;

   PROCEDURE market_exchange
   (
      p_begin_date            IN DATE,
      p_end_date              IN DATE,
      p_exchange_type         IN VARCHAR2,
      p_entity_list           IN VARCHAR2,
      p_entity_list_delimiter IN CHAR,
      p_log_only              IN NUMBER := 0,
      p_log_type              IN NUMBER,
      p_trace_on              IN NUMBER,
      p_status                OUT NUMBER,
      p_message               OUT VARCHAR2
   ) AS

      v_cred                mex_credentials;
      v_logger              mm_logger_adapter;
      v_log_only            NUMBER;
      v_erpm_access_attr_id NUMBER(9);

   BEGIN

      v_log_only := nvl(p_log_only, 0);

      mm_util.init_mex(p_external_system_id    => ec.es_pjm,
                       p_external_account_name => MM_PJM.c_EXTERNAL_ACCOUNT_NAME, --@@Implementation Override--
                       p_process_name          => 'PJM:CE:' || p_exchange_type,
                       p_exchange_name         => p_exchange_type,
                       p_log_type              => p_log_type,
                       p_trace_on              => p_trace_on,
                       p_credentials           => v_cred,
                       p_logger                => v_logger,
                       p_is_public             => false);  --@@Implementation Override--

      mm_util.start_exchange(FALSE, v_logger);
      --@@Implementation Override Begin: Case 00200150: add target begin/end date in process log.
      logs.set_process_target_parameter('BEGIN_DATE', to_char(p_begin_date, 'yyyy-mm-dd'));
      logs.set_process_target_parameter('END_DATE', to_char(p_end_date, 'yyyy-mm-dd'));
      --@@Implementation Override End: Case 00200150

      id.id_for_entity_attribute('PJM: eRPM', ec.ed_interchange_contract, 'String', FALSE, v_erpm_access_attr_id);

      IF mm_pjm_util.has_esuite_access(v_erpm_access_attr_id, v_cred.external_account_name) THEN

         IF v_cred.external_account_name = MM_PJM.c_EXTERNAL_ACCOUNT_NAME THEN --@@Implementation Override--
            CASE p_exchange_type
               WHEN g_et_query_nspl THEN
                  import_nspl(v_cred,
                              v_log_only,
                              p_begin_date,
                              p_end_date,
                              p_status,
                              p_message,
                              v_logger);
               WHEN g_et_query_plc THEN
                  -- Same Procedure Call As g_ET_QUERY_CAPACITY_OBLIG --
                  import_plc(v_cred,
                             v_log_only,
                             p_begin_date,
                             p_end_date,
                             p_status,
                             p_message,
                             v_logger);
               WHEN g_et_query_capacity_oblig THEN
                  import_plc(v_cred,
                             v_log_only,
                             p_begin_date,
                             p_end_date,
                             p_status,
                             p_message,
                             v_logger);
               WHEN g_et_query_ucap THEN
                  import_ucap(v_cred,
                              v_log_only,
                              p_begin_date,
                              p_end_date,
                              p_status,
                              p_message,
                              v_logger);
               WHEN g_et_query_plc_scale_factor THEN
                  import_plc_scale_factor(v_cred,
                                          v_log_only,
                                          p_begin_date,
                                          p_end_date,
                                          p_status,
                                          p_message,
                                          v_logger);
               WHEN g_et_query_short_names THEN
                  import_short_names(v_cred,
                                     v_log_only,
                                     p_begin_date,
                                     p_end_date,
                                     p_status,
                                     p_message,
                                     v_logger);
               ELSE
                  p_status  := -1;
                  p_message := 'Exchange Type ' || p_exchange_type ||
                               ' Not Found.';
                  v_logger.log_error(p_message);
            END CASE;
         END IF;

      END IF;

      COMMIT;
      mm_util.stop_exchange(v_logger, p_status, p_message, p_message);

   EXCEPTION
      WHEN OTHERS THEN
         p_message := ut.get_full_errm;
         p_status  := SQLCODE;
         ROLLBACK;
         mm_util.stop_exchange(v_logger, p_status, p_message, p_message);
   END market_exchange;

   PROCEDURE upload_file
   (
      p_clob    IN CLOB,
      p_status  OUT NUMBER,
      p_message IN OUT VARCHAR2
   ) AS

      v_log_only      NUMBER(1) := 0;
      v_cred          mex_credentials;
      v_logger        mm_logger_adapter;
      v_response_xml  xmltype;
      p_log_type      NUMBER := 2;
      p_exchange_type VARCHAR2(16) := 'Submit';

   BEGIN

      --Init MEX to get a logger, but we reset the credentials for each Transaction.
      mm_util.init_mex(ec.es_pjm,
                       MM_PJM.c_EXTERNAL_ACCOUNT_NAME,
                       'PLC/NSPL: Submit To PJM',
                       p_exchange_type,
                       p_log_type,
                       0,
                       v_cred,
                       v_logger);

      IF substr(p_message, 1, 1) <> '0' THEN
         mex_pjm_ce.run_pjm_submit(v_cred,
                                   v_log_only,
                                   xmltype.createxml(p_clob),
                                   v_response_xml,
                                   p_status,
                                   p_message,
                                   v_logger);
      ELSE
         v_logger.log_warn(p_message);
         p_message := NULL;
         p_status  := 0;
      END IF;

      IF p_message IS NULL THEN
         p_message := v_logger.get_end_message;
      END IF;

   EXCEPTION
      WHEN OTHERS THEN
         p_status  := SQLCODE;
         p_message := ut.get_full_errm;
         mm_util.stop_exchange(v_logger, p_status, p_message, p_message);
   END upload_file;

   PROCEDURE post_content_to_pjm
   (
      p_content IN CLOB,
      p_status  OUT NUMBER,
      p_message IN OUT VARCHAR2
   ) AS

      v_credentials  mex_credentials;
      v_logger       mm_logger_adapter;
      v_response_xml xmltype;

   BEGIN

      mm_util.init_mex(p_external_system_id    => ec.es_pjm,
                       p_external_account_name => MM_PJM.c_EXTERNAL_ACCOUNT_NAME,
                       p_process_name          => 'PLC/NSPL: Submit To PJM (CE)',
                       p_exchange_name         => 'Submit',
                       p_log_type              => 2,
                       p_trace_on              => 0,
                       p_credentials           => v_credentials,
                       p_logger                => v_logger);

      mex_pjm_ce.run_pjm_submit(v_credentials,
                                c_log_only,
                                xmltype.createxml(p_content),
                                v_response_xml,
                                p_status,
                                p_message,
                                v_logger);

   EXCEPTION
      WHEN OTHERS THEN
         p_status  := SQLCODE;
         p_message := ut.get_full_errm;
         mm_util.stop_exchange(v_logger, p_status, p_message, p_message);

   END post_content_to_pjm;

END MM_PJM_CE;
/

