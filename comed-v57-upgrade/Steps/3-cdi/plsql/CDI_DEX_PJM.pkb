CREATE OR REPLACE PACKAGE BODY CDI_DEX_PJM AS

   pkgc_pkg_nme CONSTANT VARCHAR2(30) := 'CDI_DEX_PJM';

   g_debug_exchanges VARCHAR2(8) := 'FALSE';

   g_schedules_rpttype    VARCHAR2(32) := 'schedules';
   g_schedule_import_type NUMBER(9) := 1; -- import schedules into forecast/external
   -- column numbers in Schedules CSV file
   g_schedules_conf_begin NUMBER(2) := 14;
   g_schedules_conf_end   NUMBER(2) := 38;
   g_schedules_pend_begin NUMBER(2) := 39;
   g_schedules_pend_end   NUMBER(2) := 63;
   g_pjm_edt_timezone CONSTANT CHAR(3) := 'EDT';


   --   g_ESCHED_ATTR ENTITY_ATTRIBUTE.ATTRIBUTE_ID%TYPE;

   -- --------------------------------------------------------------------------------------
   -- IS_SELF_SCHEDULING
   -- --------------------------------------------------------------------------------------
   -- MODIFICATION HISTORY
   -- Person         Date         Comments
   -- -----------    -----------  ----------------------------------------------------------
   --  KN            Jan 6 2014   Created
   -- --------------------------------------------------------------------------------------
   FUNCTION is_self_scheduling(p_pse_alias IN VARCHAR2) RETURN NUMBER IS
      v_self_scheduling NUMBER(1);
   BEGIN
      SELECT COUNT(*)
        INTO v_self_scheduling
        FROM cdi_ufc_uft_participation a,
             pse
       WHERE a.pse_name = pse.pse_external_identifier
         AND upper(pse.pse_alias) = upper(TRIM(p_pse_alias))
         AND a.is_self_scheduling = 1;

      IF v_self_scheduling > 0 THEN
         RETURN 1;
      ELSE
         RETURN 0;
      END IF;
   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         RETURN 0;
   END is_self_scheduling;
   -- --------------------------------------------------------------------------------------
   -- GET_CONTRACT_TRANSACTION_ID
   -- --------------------------------------------------------------------------------------
   -- MODIFICATION HISTORY
   -- Person         Date         Comments
   -- -----------    -----------  ----------------------------------------------------------
   --  KN            Jan 6 2014   Created
   -- --------------------------------------------------------------------------------------
   FUNCTION get_contract_transaction_id
   (
      p_contract_number IN VARCHAR2,
      p_service_date    IN DATE
   ) RETURN NUMBER IS
      v_transaction_id NUMBER(9);
   BEGIN
      SELECT b.transaction_id
        INTO v_transaction_id
        FROM tp_contract_number      a,
             interchange_transaction b
       WHERE b.contract_id = a.contract_id
         AND a.contract_number = p_contract_number
         AND b.transaction_type = 'Load'
         AND p_service_date BETWEEN a.begin_date AND
             nvl(a.end_date, p_service_date);
      RETURN v_transaction_id;
   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         logs.log_warn('Interchange Transaction Not Found For TP Contract Number: ' ||
                       p_contract_number);
         RETURN constants.not_assigned;
      WHEN TOO_MANY_ROWS THEN
         logs.log_info('Multiple TP Contract Number Records With Contract Number: ' ||
                       p_contract_number || ' For Service Date: ' ||
                       text_util.to_char_date(p_service_date));
         RETURN constants.not_assigned;

   END get_contract_transaction_id;

   -- --------------------------------------------------------------------------------------
   -- ID_FOR_STATEMENT_TYPE
   -- --------------------------------------------------------------------------------------
   -- MODIFICATION HISTORY
   -- Person         Date         Comments
   -- -----------    -----------  ----------------------------------------------------------
   --  KN            Jan 6 2014   Created
   -- --------------------------------------------------------------------------------------
   FUNCTION id_for_statement_type(p_statement_type_name IN VARCHAR) RETURN NUMBER IS
      v_statement_type_id   NUMBER;
      v_statement_type_name statement_type.statement_type_name%TYPE;
   BEGIN

      v_statement_type_name := ltrim(rtrim(p_statement_type_name));

      IF v_statement_type_name IS NULL THEN
         RETURN 0;
      END IF;

      BEGIN
         SELECT statement_type_id
           INTO v_statement_type_id
           FROM statement_type
          WHERE statement_type_name = v_statement_type_name;
      EXCEPTION
         WHEN NO_DATA_FOUND THEN
            errs.log_and_continue(p_log_level => logs.c_level_debug);
            v_statement_type_id := ga.no_data_found;
      END;

      RETURN v_statement_type_id;
   END id_for_statement_type;

   -- --------------------------------------------------------------------------------------
   -- IDS_FOR_SUPPLIER_TRANSACTIONs
   --  Retrun a list of all Wholesale Supplier Transaction IDS
   -- --------------------------------------------------------------------------------------
   -- MODIFICATION HISTORY
   -- Person         Date         Comments
   -- -----------    -----------  ----------------------------------------------------------
   --  KN            Feb 4 2014   Created
   --  RTo           Apr 15 2020  RTOU Project
   -- --------------------------------------------------------------------------------------
   PROCEDURE ids_for_supplier_transactions
   (
      p_schedule_type   IN VARCHAR2,
      p_begin_date      IN DATE,
      p_end_date        IN DATE,
      p_time_zone       IN VARCHAR2,
      p_transaction_ids OUT VARCHAR2
   ) IS
      v_begin_date DATE;
      v_end_date   DATE;
   BEGIN

      ut.cut_date_range(ga.electric_model,
                        p_begin_date,
                        p_end_date,
                        p_time_zone,
                        v_begin_date,
                        v_end_date);

      --      SELECT listagg(transaction_id, ',') WITHIN GROUP(ORDER BY transaction_id) transaction_ids
      FOR cur_rec IN (SELECT transaction_id
                        FROM (SELECT it.transaction_id
                                FROM interchange_transaction   it,
                                     it_schedule               s,
                                     cdi_ufc_uft_participation cdi,
                                     pse
                               WHERE it.pse_id = pse.pse_id
                                 AND it.transaction_type = 'Load'
                                 AND pse.pse_name = cdi.pse_name
                                 AND cdi.is_ufe_participant = 1
                                 AND s.transaction_id = it.transaction_id
                                 AND s.schedule_state = ga.internal_state
                                 AND s.schedule_type = p_schedule_type
                                 AND s.schedule_date BETWEEN v_begin_date AND
                                     v_end_date
                              UNION
                              -- Hourly and Blended do not PSE iD to tie back to So...
                              SELECT it.transaction_id
                                FROM interchange_transaction   it,
                                     it_schedule               s,
                                     cdi_ufc_uft_participation cdi
                               WHERE it.transaction_type = 'Load'
                                    --                 AND it.transaction_name IN ('CPP-H@COMED', 'B_SUPPLIED@COMED')
                                    --                 AND (CASE
                                    --                        WHEN it.transaction_name = 'CPP-H@COMED' THEN
                                    --                         'CPP-H'
                                    --                        WHEN it.transaction_name = 'B_SUPPLIED@COMED' THEN
                                    --                         'CPP-B'
                                    --                     END) = cdi.pool_name
                                 AND it.transaction_name IN
                                     ('CEDPH-H-2008', 'COMED-B-2010', 'CERTOU')
                                 AND (CASE
                                        WHEN it.transaction_name = 'CEDPH-H-2008' THEN
                                         'CPP-H'
                                        WHEN it.transaction_name = 'COMED-B-2010' THEN
                                         'CPP-B'
                                        WHEN it.transaction_name = 'CERTOU' THEN
                                         'RTOU'
                                     END) = cdi.pool_name
                                 AND cdi.is_ufe_participant = 1
                                 AND s.transaction_id = it.transaction_id
                                 AND s.schedule_state = ga.internal_state
                                 AND s.schedule_type = p_schedule_type
                                 AND s.schedule_date BETWEEN v_begin_date AND
                                     v_end_date
                               GROUP BY it.transaction_id))
      LOOP
         p_transaction_ids := p_transaction_ids || ',' ||
                              cur_rec.transaction_id;
      END LOOP;

      p_transaction_ids := ltrim(p_transaction_ids, ',');

   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         logs.log_warn(pkgc_pkg_nme ||
                       '.IDS_FOR_SUPPLIER_TRANSACTIONs: No Wholesale Supplier Transactions found');
      WHEN OTHERS THEN
         logs.log_error(ut.get_full_errm,
                        pkgc_pkg_nme,
                        'IDS_FOR_SUPPLIER_TRANSACTIONS');

   END ids_for_supplier_transactions;

   -- --------------------------------------------------------------------------------------
   -- PUT_SCHEDULE_NORMAL_DAY
   -- --------------------------------------------------------------------------------------
   -- MODIFICATION HISTORY
   -- Person         Date         Comments
   -- -----------    -----------  ----------------------------------------------------------
   --  KN            Jan 6 2014   Created
   -- --------------------------------------------------------------------------------------
   --
   -- --------------------------------------------------------------------------------------
   PROCEDURE put_schedule_normal_day
   (
      p_columns        IN parse_util.string_table,
      p_transaction_id IN NUMBER,
      p_date           IN DATE
   ) AS
      v_value  VARCHAR2(16);
      v_date   DATE;
      v_status NUMBER;
   BEGIN
      -- Columns 14 To 38 Are Confirmed Entries, 39 To 63 Are Pending --
      FOR v_hour IN 1 .. 24
      LOOP
         IF nvl(LENGTH(p_columns(v_hour + g_schedules_conf_begin - 1)), 0) > 0 THEN
            v_value := p_columns(v_hour + g_schedules_conf_begin - 1);
         ELSIF nvl(LENGTH(p_columns(v_hour + g_schedules_pend_begin - 1)), 0) > 0 THEN
            v_value := p_columns(v_hour + g_schedules_pend_begin - 1);
         ELSE
            v_value := NULL;
         END IF;
         IF v_value IS NOT NULL THEN
            v_date := p_date + v_hour / 24;
            v_date := to_cut(v_date, g_pjm_edt_timezone); --MM_PJM_UTIL.g_PJM_TIME_ZONE);
            itj.put_it_schedule(p_transaction_id,
                                g_schedule_import_type,
                                constants.external_state,
                                v_date,
                                constants.low_date,
                                to_number(v_value),
                                NULL,
                                v_status);
         END IF;
      END LOOP;
   END put_schedule_normal_day;
   -- --------------------------------------------------------------------------------------
   -- PUT_SCHEDULE_LONG_DAY
   -- --------------------------------------------------------------------------------------
   -- MODIFICATION HISTORY
   -- Person         Date         Comments
   -- -----------    -----------  ----------------------------------------------------------
   --  KN            Jan 6 2014   Created
   -- --------------------------------------------------------------------------------------
   --
   -- --------------------------------------------------------------------------------------
   PROCEDURE put_schedule_long_day
   (
      p_columns        IN parse_util.string_table,
      p_transaction_id IN NUMBER,
      p_date           IN DATE
   ) AS
      v_value  VARCHAR2(16);
      v_date   DATE;
      v_status NUMBER;
   BEGIN
      -- Columns 14 To 38 Are Confirmed Entries, 39 To 63 Are Pending --
      FOR v_hour IN 1 .. 25
      LOOP
         IF nvl(LENGTH(p_columns(v_hour + g_schedules_conf_begin - 1)), 0) > 0 THEN
            v_value := p_columns(v_hour + g_schedules_conf_begin - 1);
         ELSIF nvl(LENGTH(p_columns(v_hour + g_schedules_pend_begin - 1)), 0) > 0 THEN
            v_value := p_columns(v_hour + g_schedules_pend_begin - 1);
         ELSE
            v_value := NULL;
         END IF;
         IF v_value IS NOT NULL THEN
            IF v_hour = 25 THEN
               -- 25Th Hour Represents The Second Hour-Two --
               v_date := p_date + 2 / 24 + (1 / (24 * 60 * 60));
            ELSE
               v_date := p_date + v_hour / 24;
            END IF;
            v_date := to_cut(v_date, g_pjm_edt_timezone); --MM_PJM_UTIL.g_PJM_TIME_ZONE);
            itj.put_it_schedule(p_transaction_id,
                                g_schedule_import_type,
                                constants.external_state,
                                v_date,
                                constants.low_date,
                                to_number(v_value),
                                NULL,
                                v_status);
         END IF;
      END LOOP;
   END put_schedule_long_day;
   -- --------------------------------------------------------------------------------------
   -- PUT_SCHEDULE_CSV_LINE
   -- --------------------------------------------------------------------------------------
   -- MODIFICATION HISTORY
   -- Person         Date         Comments
   -- -----------    -----------  ----------------------------------------------------------
   --  KN            Jan 6 2014   Created
   -- --------------------------------------------------------------------------------------
   --
   -- --------------------------------------------------------------------------------------
   PROCEDURE put_schedule_short_day
   (
      p_columns        IN parse_util.string_table,
      p_transaction_id IN NUMBER,
      p_date           IN DATE
   ) AS
      v_value  VARCHAR2(16);
      v_date   DATE;
      v_status NUMBER;
   BEGIN
      -- Columns 14 To 38 Are Confirmed Entries, 39 To 63 Are Pending --
      FOR v_hour IN 1 .. 24
      LOOP
         IF nvl(LENGTH(p_columns(v_hour + g_schedules_conf_begin - 1)), 0) > 0 THEN
            v_value := p_columns(v_hour + g_schedules_conf_begin - 1);
         ELSIF nvl(LENGTH(p_columns(v_hour + g_schedules_pend_begin - 1)), 0) > 0 THEN
            v_value := p_columns(v_hour + g_schedules_pend_begin - 1);
         ELSE
            v_value := NULL;
         END IF;
         IF v_value IS NOT NULL THEN
            v_date := p_date + v_hour / 24;
            v_date := to_cut(v_date, g_pjm_edt_timezone); --MM_PJM_UTIL.g_PJM_TIME_ZONE);
            IF v_hour = 2 THEN
               v_date := v_date + 1 / 24;
            END IF;
            itj.put_it_schedule(p_transaction_id,
                                g_schedule_import_type,
                                constants.external_state,
                                v_date,
                                constants.low_date,
                                to_number(v_value),
                                NULL,
                                v_status);
         END IF;
      END LOOP;
   END put_schedule_short_day;
   -- --------------------------------------------------------------------------------------
   -- PUT_SCHEDULE_CSV_LINE
   -- --------------------------------------------------------------------------------------
   -- MODIFICATION HISTORY
   -- Person         Date         Comments
   -- -----------    -----------  ----------------------------------------------------------
   --  KN            Jan 6 2014   Created
   -- --------------------------------------------------------------------------------------
   --
   -- --------------------------------------------------------------------------------------
   FUNCTION put_schedule_csv_line
   (
      p_csv_line     IN VARCHAR2,
      p_no_contracts IN OUT NOCOPY parse_util.string_table
   ) RETURN BOOLEAN IS
      v_columns         parse_util.string_table;
      v_contract_number VARCHAR2(32);
      v_pse_alias       VARCHAR2(32);
      v_service_date    DATE;
      v_transaction_id  NUMBER(9);
      v_tx_begin_date   DATE;
      v_tx_end_date     DATE;
      v_index           BINARY_INTEGER;
      v_num_hours       NUMBER(2);
   BEGIN
      parse_util.tokens_from_string(p_csv_line, ',', v_columns);
      v_contract_number := v_columns(1);
      v_pse_alias       := v_columns(3);
      v_service_date    := to_date(v_columns(2), 'DD-MON-YY');
      v_transaction_id  := get_contract_transaction_id(p_contract_number => v_contract_number,
                                                       p_service_date    => v_service_date);
      IF is_self_scheduling(v_pse_alias) = 1 THEN
         logs.log_info('Is Self Scheduling - ' || v_pse_alias || ' Contract: ' ||
                       v_contract_number);
         IF v_transaction_id <= 0 THEN
            -- See If This Contract Number Is Already In List
            v_index := p_no_contracts.first;
            WHILE p_no_contracts.exists(v_index)
            LOOP
               IF p_no_contracts(v_index) = v_contract_number THEN
                  RETURN FALSE; -- already there? nothing more to do
               END IF;
               v_index := p_no_contracts.next(v_index);
            END LOOP;
            -- Not Already There? Then Record Contract Number
            p_no_contracts(p_no_contracts.count) := v_contract_number;
            RETURN FALSE;
         ELSE
            -- Extend Transaction'S Date Range If Necessary
            SELECT begin_date,
                   end_date
              INTO v_tx_begin_date,
                   v_tx_end_date
              FROM interchange_transaction
             WHERE transaction_id = v_transaction_id;
            IF v_tx_begin_date > v_service_date THEN
               UPDATE interchange_transaction
                  SET begin_date = v_service_date
                WHERE transaction_id = v_transaction_id;
            END IF;
            IF v_tx_end_date < v_service_date THEN
               UPDATE interchange_transaction
                  SET end_date = v_service_date
                WHERE transaction_id = v_transaction_id;
            END IF;
            -- Determine How Long The Day Is
            IF nvl(LENGTH(v_columns(g_schedules_conf_end)), 0) > 0 OR
               nvl(LENGTH(v_columns(g_schedules_pend_end)), 0) > 0 THEN
               v_num_hours := 25; -- 25 Entries Indicates Long DST Day
            ELSIF nvl(LENGTH(v_columns(g_schedules_conf_end - 1)), 0) = 0 AND
                  nvl(LENGTH(v_columns(g_schedules_pend_end - 1)), 0) = 0 THEN
               v_num_hours := 23; -- 24th Missing? Then Perhaps It'S Short DST Day
            ELSE
               v_num_hours := 24;
            END IF;
            IF v_service_date = trunc(dst_fall_back_date(v_service_date)) OR
               v_num_hours > 24 THEN
               put_schedule_long_day(v_columns,
                                     v_transaction_id,
                                     v_service_date);
            ELSIF v_service_date = trunc(dst_spring_ahead_date(v_service_date)) OR
                  v_num_hours < 24 THEN
               put_schedule_short_day(v_columns,
                                      v_transaction_id,
                                      v_service_date);
            ELSE
               put_schedule_normal_day(v_columns,
                                       v_transaction_id,
                                       v_service_date);
            END IF;
            RETURN TRUE;
         END IF;
      ELSE
         RETURN FALSE;
      END IF;
   END put_schedule_csv_line;
   -- --------------------------------------------------------------------------------------
   -- IMPORT_SUPPLIER_SCHEDULES
   -- --------------------------------------------------------------------------------------
   -- MODIFICATION HISTORY
   -- Person         Date         Comments
   -- -----------    -----------  ----------------------------------------------------------
   --  KN            Jan 6 2014   Created
   -- --------------------------------------------------------------------------------------
   --
   -- --------------------------------------------------------------------------------------
   PROCEDURE import_supplier_schedules(
                                       --      p_EXTERNAL_ACCOUNT_NAME IN VARCHAR2,
                                       p_csv     IN CLOB,
                                       p_status  OUT NUMBER,
                                       p_message OUT VARCHAR2,
                                       p_success IN OUT NUMBER,
                                       p_failure IN OUT NUMBER,
                                       p_logger  IN OUT mm_logger_adapter) AS

      v_lines        parse_util.big_string_table_mp;
      v_no_contracts parse_util.string_table;
      v_rec_count    NUMBER := 0;
      v_rec_no_count NUMBER := 0;
      v_index        BINARY_INTEGER;

   BEGIN
      p_status := ga.success;
      parse_util.parse_clob_into_lines(p_csv, v_lines);
      v_index := v_lines.next(v_lines.first); -- first line is just header, so start with second line
      -- import one line at a time
      WHILE v_lines.exists(v_index)
      LOOP
         IF LENGTH(v_lines(v_index)) > 0 THEN
            IF put_schedule_csv_line(v_lines(v_index), v_no_contracts) THEN
               v_rec_count := v_rec_count + 1;
               p_success := p_success + 1;
            ELSE
               v_rec_no_count := v_rec_no_count + 1;
               p_failure := p_failure + 1;
            END IF;

         END IF;

         v_index := v_lines.next(v_index);
      END LOOP;

      IF v_rec_count > 0 THEN
         -- we've imported at least one schedule
         COMMIT;
      END IF;

      -- build report of what happened
      p_status  := ga.success;
      p_message := 'Query Self Schedules Complete. See Process Log For Details.' ||
                   chr(10) || 'Records Processed: ' || to_char(v_rec_count) ||
                   chr(10) || 'Records Not Processed: ' ||
                   to_char(v_rec_no_count) || chr(10) ||
                   'Contract Numbers Not Found: ' ||
                   to_char(v_no_contracts.count);
      logs.log_info(p_message);
      IF v_no_contracts.count > 0 THEN
         v_index := v_no_contracts.first;
         WHILE v_no_contracts.exists(v_index)
         LOOP
            logs.log_warn('Contract Number Not Found: ' ||
                          v_no_contracts(v_index));
            v_index := v_no_contracts.next(v_index);
         END LOOP;
      END IF;

   EXCEPTION
      WHEN OTHERS THEN
         p_status  := SQLCODE;
         p_message := p_message ||
                      'ERROR OCCURED IN MM_PJM_ESCHED.IMPORT_SCHEDULES: ' ||
                      ut.get_full_errm;
   END import_supplier_schedules;
   -- --------------------------------------------------------------------------------------
   -- IMPORT_SELF_SCHEDULES
   -- --------------------------------------------------------------------------------------
   -- MODIFICATION HISTORY
   -- Person         Date         Comments
   -- -----------    -----------  ----------------------------------------------------------
   --  KN            Jan 6 2014   Created
   -- --------------------------------------------------------------------------------------
   --
   -- --------------------------------------------------------------------------------------
   PROCEDURE import_self_schedules
   (
      p_cred       IN mex_credentials,
      p_begin_date IN DATE,
      p_end_date   IN DATE,
      p_log_only   IN NUMBER,
      p_status     OUT NUMBER,
      p_message    OUT VARCHAR2,
      p_success    IN OUT NUMBER,
      p_failure    IN OUT NUMBER,
      p_logger     IN OUT mm_logger_adapter
   ) AS
      v_clob   CLOB;
      v_params mex_util.parameter_map := mex_switchboard.c_empty_parameter_map;
      --      v_RECORDS MEX_PJM_ESCHED_SCHEDULE_TBL;
   BEGIN
      p_status := ga.success;

      --    IF MM_PJM_UTIL.HAS_ESUITE_ACCESS(g_ESCHED_ATTR,
      --                                       p_CRED.EXTERNAL_ACCOUNT_NAME) THEN

      v_params(mex_pjm.c_report_type) := g_schedules_rpttype;
      v_params(mex_pjm.c_debug) := g_debug_exchanges;
      mex_pjm.run_pjm_browserless(v_params,
                                  'esched', -- p_REQUEST_APP
                                  p_logger,
                                  p_cred,
                                  p_begin_date,
                                  p_end_date,
                                  'download', -- p_REQUEST_DIR
                                  v_clob,
                                  p_status,
                                  p_message,
                                  p_log_only);
      IF p_status = mex_util.g_success THEN
         import_supplier_schedules( --p_CRED.EXTERNAL_ACCOUNT_NAME,
                                   v_clob,
                                   p_status,
                                   p_message,
                                   p_success,
                                   p_failure,
                                   p_logger
                                   );
      END IF;
      --   END IF;

   END import_self_schedules;

   -- --------------------------------------------------------------------------------------
   -- COPY_FORECAST_TO_PRELIMINAY
   -- --------------------------------------------------------------------------------------
   -- MODIFICATION HISTORY
   -- Person         Date         Comments
   -- -----------    -----------  ----------------------------------------------------------
   --  KN            Jan 4 2014   Created
   -- --------------------------------------------------------------------------------------
   --  Copies only SUPPLIER (RES) INTERNAL FORECAST Schedules to INTERNAL Prelimiary Schedules
   --    This is done only to make Sumitting Supplier (RES), B and H schedules to PJM inSchedules easier
   --    Otherwise we would have to MIX states for the B,H and RES schedules for the SCHEDULING process.
   -- --------------------------------------------------------------------------------------
   PROCEDURE copy_forecast_to_preliminay
   (
      p_begin_date IN DATE,
      p_end_date   IN DATE,
      p_time_zone  IN VARCHAR2,
      p_status     OUT NUMBER,
      p_message    OUT VARCHAR2
   ) AS
      lc_proc_nme CONSTANT VARCHAR2(40) := 'COPY_FORECAST_TO_PRELIMINAY';

      v_begin_date DATE;
      v_end_date   DATE;
      v_cnt        NUMBER;
   BEGIN

      ut.cut_date_range(ga.electric_model,
                        p_begin_date,
                        p_end_date,
                        p_time_zone,
                        v_begin_date,
                        v_end_date);

      MERGE INTO it_schedule s
      USING (SELECT s.transaction_id,
                    ga.schedule_type_prelim schedule_type,
                    ga.internal_state       schedule_state,
                    s.schedule_date,
                    s.as_of_date,
                    s.amount,
                    s.price,
                    s.lock_state
               FROM interchange_transaction   it,
                    it_schedule               s,
                    cdi_ufc_uft_participation cdi,
                    pse
              WHERE it.pse_id = pse.pse_id
                AND it.transaction_type = 'Load'
                AND cdi.pse_name = pse.pse_name
                AND cdi.is_ufe_participant = 1
                AND s.transaction_id = it.transaction_id
                AND s.schedule_state = ga.internal_state
                AND s.schedule_type = ga.schedule_type_forecast
                AND s.schedule_date BETWEEN v_begin_date AND v_end_date) v_s
      ON (s.transaction_id = v_s.transaction_id AND s.schedule_type = v_s.schedule_type AND s.schedule_date = v_s.schedule_date AND s.schedule_state = v_s.schedule_state)
      WHEN MATCHED THEN
         UPDATE
            SET s.amount = v_s.amount
      WHEN NOT MATCHED THEN
         INSERT
         VALUES
            (v_s.transaction_id,
             v_s.schedule_type,
             v_s.schedule_state,
             v_s.schedule_date,
             v_s.as_of_date,
             v_s.amount,
             v_s.price,
             v_s.lock_state);

      COMMIT;
   EXCEPTION
      WHEN OTHERS THEN
         p_status  := SQLCODE;
         p_message := pkgc_pkg_nme || '.COPY_FORECAST_TO_PRELIMINAY: ' ||
                      ut.get_full_errm;

   END copy_forecast_to_preliminay;

   -- --------------------------------------------------------------------------------------
   -- COPY_SELF_SCHEDULES_INTERNAL
   -- --------------------------------------------------------------------------------------
   -- MODIFICATION HISTORY
   -- Person         Date         Comments
   -- -----------    -----------  ----------------------------------------------------------
   --  KN            Jan 6 2014   Created
   -- --------------------------------------------------------------------------------------
   -- The Data Exchange process will copy the External Self Schedules only for the Suppliers
   -- that have Self Scheduling flag enabled in the Scheduling UFE Participation report.
   -- The copied data will be stored in â€œIT_SCHEDULEâ€? PL/SQL table as internal records. They will be displayed
   -- in Energy Scheduling | Scheduler tab under â€œAmountâ€? column. If there is no External amount for a particular
   -- time interval, then no copy will be done. The internal state will be unchanged.
   -- The Data Exchange will be sensitive to Time Zone. It will copy the Schedules with respect to the Time Zone selected on the Scheduler Screen.
   --
   -- After the job is run, Internal and External amounts will match for each Supplier that is Self Supplied.
   -- --------------------------------------------------------------------------------------
   PROCEDURE copy_self_schedules_internal
   (
      p_begin_date IN DATE,
      p_end_date   IN DATE,
      p_time_zone  IN VARCHAR2,
      p_status     OUT NUMBER,
      p_message    OUT VARCHAR2
   ) AS
      lc_proc_nme CONSTANT VARCHAR2(40) := 'COPY_SELF_SCHEDULES_INTERNAL';

      v_begin_date       DATE;
      v_end_date         DATE;
      v_begin_date_local DATE;
      v_end_date_local   DATE;
      v_cnt              NUMBER;
   BEGIN

      ut.cut_date_range(ga.electric_model,
                        p_begin_date,
                        p_end_date,
                        p_time_zone, --g_PJM_EDT_TIMEZONE, Schedules from GUI TZ
                        v_begin_date,
                        v_end_date);

      -- Cut Range for Load Timezone for accurate count msg
      ut.cut_date_range(ga.electric_model,
                        p_begin_date,
                        p_end_date,
                        ga.local_time_zone,
                        v_begin_date_local,
                        v_end_date_local);

      MERGE INTO it_schedule s
      USING (SELECT s.transaction_id,
                    s.schedule_type,
                    ga.internal_state schedule_state,
                    s.schedule_date,
                    s.as_of_date,
                    s.amount,
                    s.price,
                    s.lock_state
               FROM interchange_transaction   it,
                    it_schedule               s,
                    cdi_ufc_uft_participation cdi,
                    pse
              WHERE it.pse_id = pse.pse_id
                AND it.transaction_type = 'Load'
                AND cdi.pse_name = pse.pse_name
                AND cdi.is_self_scheduling = 1
                AND s.transaction_id = it.transaction_id
                AND s.schedule_state = ga.external_state
                AND s.schedule_type = ga.schedule_type_forecast
                AND s.schedule_date BETWEEN v_begin_date AND v_end_date
             UNION
             -- Hourly and Blended do not PSE iD to tie back to So...
             SELECT s.transaction_id,
                    s.schedule_type,
                    ga.internal_state schedule_state,
                    s.schedule_date,
                    s.as_of_date,
                    s.amount,
                    s.price,
                    s.lock_state
               FROM interchange_transaction   it,
                    it_schedule               s,
                    cdi_ufc_uft_participation cdi
              WHERE it.transaction_type = 'Load'
                AND (CASE
                       WHEN it.transaction_name = 'CPP-H@COMED' THEN
                        'CPP-H'
                       WHEN it.transaction_name = 'B_SUPPLIED@COMED' THEN
                        'CPP-B'
                    END) = cdi.pool_name
                AND cdi.is_self_scheduling = 1
                AND s.schedule_type = ga.schedule_type_forecast
                AND s.schedule_state = ga.external_state
                AND s.transaction_id = it.transaction_id
                AND s.schedule_date BETWEEN v_begin_date AND v_end_date) v_s
      ON (s.transaction_id = v_s.transaction_id AND s.schedule_type = v_s.schedule_type AND s.schedule_date = v_s.schedule_date AND s.schedule_state = v_s.schedule_state)
      WHEN MATCHED THEN
         UPDATE
            SET s.amount = v_s.amount
      WHEN NOT MATCHED THEN
         INSERT
         VALUES
            (v_s.transaction_id,
             v_s.schedule_type,
             v_s.schedule_state,
             v_s.schedule_date,
             v_s.as_of_date,
             v_s.amount,
             v_s.price,
             v_s.lock_state);

      -- log the number of schedule days copied
      IF SQL%ROWCOUNT <> 0 THEN

         SELECT COUNT(x.schedday)
           INTO v_cnt
           FROM (SELECT s.transaction_id schedday
                   FROM interchange_transaction   it,
                        it_schedule               s,
                        cdi_ufc_uft_participation cdi,
                        pse
                  WHERE it.pse_id = pse.pse_id
                    AND it.transaction_type = 'Load'
                    AND cdi.pse_name = pse.pse_name
                    AND cdi.is_self_scheduling = 1
                    AND s.transaction_id = it.transaction_id
                    AND s.schedule_state = ga.external_state
                    AND s.schedule_type = ga.schedule_type_forecast
                    AND s.schedule_date BETWEEN v_begin_date AND v_end_date
                 UNION
                 -- Hourly and Blended do not PSE iD to tie back to So...
                 SELECT s.transaction_id schedday
                   FROM interchange_transaction   it,
                        it_schedule               s,
                        cdi_ufc_uft_participation cdi
                  WHERE it.transaction_type = 'Load'
                    AND (CASE
                           WHEN it.transaction_name = 'CPP-H@COMED' THEN
                            'CPP-H'
                           WHEN it.transaction_name = 'B_SUPPLIED@COMED' THEN
                            'CPP-B'
                        END) = cdi.pool_name
                    AND cdi.is_self_scheduling = 1
                    AND s.schedule_type = ga.schedule_type_forecast
                    AND s.schedule_state = ga.external_state
                    AND s.transaction_id = it.transaction_id
                    AND s.schedule_date BETWEEN v_begin_date_local AND
                        v_end_date_local) x;

         logs.log_info(SQL%ROWCOUNT || ' Self Schedules copied', lc_proc_nme);
         logs.log_info(v_cnt || ' Self Schedules copied', lc_proc_nme);
         p_message := v_cnt || ' Self Schedules copied';
      ELSE

         logs.log_info(0 || ' Self Schedules copied', lc_proc_nme);
         logs.log_info(0 || ' Self Schedules copied', lc_proc_nme);
         p_message := 0 || ' Self Schedules copied';
      END IF;

      COMMIT;
   EXCEPTION
      WHEN OTHERS THEN
         p_status  := SQLCODE;
         p_message := pkgc_pkg_nme || '.COPY_SELF_SCHEDULES_INTERNAL: ' ||
                      ut.get_full_errm;
   END copy_self_schedules_internal;

   -- --------------------------------------------------------------------------------------
   -- BACKUP_SCHEDULES_PRE_UFE
   -- --------------------------------------------------------------------------------------
   -- MODIFICATION HISTORY
   -- Person         Date         Comments
   -- -----------    -----------  ----------------------------------------------------------
   --  KN            Jan 06 2014  Created
   --  RTo           Apr 15 2020  Added RTOU
   -- --------------------------------------------------------------------------------------
   -- The Data Exchange process will be executed against the PSEs flagged as UFE Participant in
   -- the Scheduling UFE Participation report to copy the Internal Forecast Amounts to new Schedule Statement type â€œWithout UFEâ€?.
   -- The Data Exchange will be sensitive to Time Zone. It will copy the Schedules with respect
   -- to the Time Zone selected on the Scheduler Screen.
   -- --------------------------------------------------------------------------------------
   PROCEDURE backup_schedules_pre_ufe
   (
      p_begin_date IN DATE,
      p_end_date   IN DATE,
      p_time_zone  IN VARCHAR2,
      p_status     OUT NUMBER,
      p_message    OUT VARCHAR2
   ) AS
      lc_proc_nme CONSTANT VARCHAR2(40) := 'BACKUP_SCHEDULES_PRE_UFE';

      v_begin_date         DATE;
      v_end_date           DATE;
      v_settlement_type_id NUMBER;
      v_cnt                NUMBER;

   BEGIN

      v_settlement_type_id := id_for_statement_type('Without UFE');
      IF v_settlement_type_id = ga.no_data_found THEN
         p_message := pkgc_pkg_nme ||
                      '.BACKUP_SCHEDULES_PRE_UFE: Failed, SETTLEMENT_TYPE Without UFE does not exist';
         errs.log_and_raise;
      END IF;
      ut.cut_date_range(ga.electric_model,
                        p_begin_date,
                        p_end_date,
                        g_pjm_edt_timezone,
                        v_begin_date,
                        v_end_date);

      logs.set_process_target_parameter('Cut Begin Date',
                                        text_util.to_char_time(v_begin_date));
      logs.set_process_target_parameter('Cut End Date',
                                        text_util.to_char_time(v_end_date));
      MERGE INTO it_schedule s
      USING (SELECT s.transaction_id,
                    v_settlement_type_id schedule_type,
                    s.schedule_state,
                    s.schedule_date,
                    s.as_of_date,
                    s.amount,
                    s.price,
                    s.lock_state
               FROM interchange_transaction   it,
                    it_schedule               s,
                    cdi_ufc_uft_participation cdi,
                    pse
              WHERE it.pse_id = pse.pse_id
                AND it.transaction_type = 'Load'
                AND pse.pse_name = cdi.pse_name
                AND cdi.is_ufe_participant = 1
                AND s.transaction_id = it.transaction_id
                AND s.schedule_state = ga.internal_state
                AND s.schedule_type = ga.schedule_type_forecast
                AND s.schedule_date BETWEEN v_begin_date AND v_end_date
             UNION
             -- Hourly and Blended do not PSE iD to tie back to So...
             -- Added RTOU 04/15/2020
             SELECT s.transaction_id,
                    v_settlement_type_id schedule_type,
                    s.schedule_state,
                    s.schedule_date,
                    s.as_of_date,
                    s.amount,
                    s.price,
                    s.lock_state
               FROM interchange_transaction   it,
                    it_schedule               s,
                    cdi_ufc_uft_participation cdi
              WHERE it.transaction_type = 'Load'
                AND it.transaction_name IN ('CPP-H@COMED', 'B_SUPPLIED@COMED', 'RTOU@COMED')
                AND (CASE
                       WHEN it.transaction_name = 'CPP-H@COMED' THEN
                        'CPP-H'
                       WHEN it.transaction_name = 'B_SUPPLIED@COMED' THEN
                        'CPP-B'
                       WHEN it.transaction_name = 'RTOU@COMED' THEN
                        'RTOU'
                    END) = cdi.pool_name
                AND cdi.is_ufe_participant = 1
                AND s.transaction_id = it.transaction_id
                AND s.schedule_state = ga.internal_state
                AND s.schedule_type = ga.schedule_type_forecast
                AND s.schedule_date BETWEEN v_begin_date AND v_end_date) v_s
      ON (s.transaction_id = v_s.transaction_id AND s.schedule_type = v_s.schedule_type AND s.schedule_date = v_s.schedule_date AND s.schedule_state = v_s.schedule_state)
      WHEN MATCHED THEN
         UPDATE
            SET s.amount = v_s.amount
      WHEN NOT MATCHED THEN
         INSERT
         VALUES
            (v_s.transaction_id,
             v_s.schedule_type,
             v_s.schedule_state,
             v_s.schedule_date,
             v_s.as_of_date,
             v_s.amount,
             v_s.price,
             v_s.lock_state);

      -- log the number of schedule days backed up
      IF SQL%ROWCOUNT > 0 THEN
         SELECT COUNT(x.schedday)
           INTO v_cnt
           FROM (SELECT s.transaction_id schedday
                   FROM interchange_transaction   it,
                        it_schedule               s,
                        cdi_ufc_uft_participation cdi,
                        pse
                  WHERE it.pse_id = pse.pse_id
                    AND it.transaction_type = 'Load'
                    AND pse.pse_name = cdi.pse_name
                    AND cdi.is_ufe_participant = 1
                    AND s.transaction_id = it.transaction_id
                    AND s.schedule_state = ga.internal_state
                    AND s.schedule_type = ga.schedule_type_forecast
                    AND s.schedule_date BETWEEN v_begin_date AND v_end_date
                 UNION
                 -- Hourly and Blended do not PSE iD to tie back to So...
                 SELECT s.transaction_id schedday
                   FROM interchange_transaction   it,
                        it_schedule               s,
                        cdi_ufc_uft_participation cdi
                  WHERE it.transaction_type = 'Load'
                    AND it.transaction_name IN
                        ('CPP-H@COMED', 'B_SUPPLIED@COMED', 'RTOU@COMED')
                    AND (CASE
                           WHEN it.transaction_name = 'CPP-H@COMED' THEN
                            'CPP-H'
                           WHEN it.transaction_name = 'B_SUPPLIED@COMED' THEN
                            'CPP-B'
                           WHEN it.transaction_name = 'RTOU@COMED' THEN
                            'RTOU'
                        END) = cdi.pool_name
                    AND cdi.is_ufe_participant = 1
                    AND s.transaction_id = it.transaction_id
                    AND s.schedule_state = ga.internal_state
                    AND s.schedule_type = ga.schedule_type_forecast
                    AND s.schedule_date BETWEEN v_begin_date AND v_end_date) x;


         logs.log_info(v_cnt || ' Scheduleds Copied to Without UFE',
                       lc_proc_nme);
         p_message := v_cnt || ' Scheduleds Copied to Without UFE';
      END IF;

      COMMIT;
   EXCEPTION
      WHEN OTHERS THEN
         p_status  := SQLCODE;
         p_message := pkgc_pkg_nme || '.BACKUP_SCHEDULES_PRE_UFE: ' ||
                      ut.get_full_errm;
   END backup_schedules_pre_ufe;

   -- --------------------------------------------------------------------------------------
   -- CALCULATE_WHOLESALE_UFE
   -- --------------------------------------------------------------------------------------
   -- MODIFICATION HISTORY
   -- Person         Date         Comments
   -- -----------    -----------  ----------------------------------------------------------
   --  KN            Feb 4 2021   Assigned SQL$ROWCOUNT to variable
   --  KN            Jan 6 2014   Created
   -- --------------------------------------------------------------------------------------
   -- UFE = Zone Load  (Certified Suppliers - Municipalities  CPP-H - CPP-QF  CPP-B)
   -- UFE should be calculated for each hour of the days between begin and end date
   --    in data exchange window
   -- --------------------------------------------------------------------------------------
   PROCEDURE calculate_wholesale_ufe
   (
      p_schedule_type IN VARCHAR2,
      p_begin_date    IN DATE,
      p_end_date      IN DATE,
      p_time_zone     IN VARCHAR2,
      p_status        OUT NUMBER,
      p_message       OUT VARCHAR2
   ) AS
      lc_proc_nme CONSTANT VARCHAR2(40) := 'CALCULATE_WHOLESALE_UFE';

      c_zone_load      interchange_transaction.transaction_name%TYPE := 'ComEd Initial Zone Load';
      c_cpph           interchange_transaction.transaction_name%TYPE := 'CPP-H@COMED';
      c_cppqf          interchange_transaction.transaction_name%TYPE := 'CPP-QF@COMED';
      c_cppb           interchange_transaction.transaction_name%TYPE := 'B_SUPPLIED@COMED';
      c_rtou           interchange_transaction.transaction_name%TYPE := 'RTOU@COMED';
      v_day_ahead_ufe  interchange_transaction.transaction_id%TYPE;
      v_scheduling_ufe interchange_transaction.transaction_id%TYPE;
      v_begin_date     DATE;
      v_end_date       DATE;
      v_status         PLS_INTEGER;
      v_count          PLS_INTEGER;

      -- --------------------------------------------------------------------------------------
      --
      -- --------------------------------------------------------------------------------------
      FUNCTION create_load
      (
         p_transaction_id interchange_transaction.transaction_name%TYPE,
         p_type_in        it_schedule.schedule_type%TYPE,
         p_type_out       it_schedule.schedule_type%TYPE
      ) RETURN NUMBER AS
      BEGIN
         MERGE INTO it_schedule s
         USING (SELECT p_transaction_id transaction_id,
                       p_type_out       schedule_type,
                       s.schedule_state,
                       s.schedule_date,
                       s.as_of_date,
                       s.amount,
                       s.price,
                       s.lock_state
                  FROM interchange_transaction it,
                       it_schedule             s
                 WHERE it.transaction_name = c_zone_load
                   AND s.transaction_id = it.transaction_id
                   AND s.schedule_state = ga.internal_state
                   AND s.schedule_type = p_type_in
                   AND s.schedule_date BETWEEN v_begin_date AND v_end_date) v_s
         ON (s.transaction_id = v_s.transaction_id AND s.schedule_type = v_s.schedule_type AND s.schedule_date = v_s.schedule_date)
         WHEN MATCHED THEN
            UPDATE
               SET s.amount = v_s.amount
         WHEN NOT MATCHED THEN
            INSERT
            VALUES
               (v_s.transaction_id,
                v_s.schedule_type,
                v_s.schedule_state,
                v_s.schedule_date,
                v_s.as_of_date,
                v_s.amount,
                v_s.price,
                v_s.lock_state);
         RETURN 1;
      EXCEPTION
         WHEN OTHERS THEN
            p_status  := SQLCODE;
            p_message := pkgc_pkg_nme || '.create_load: ' || ut.get_full_errm;
            RETURN 0;
      END create_load;

      -- --------------------------------------------------------------------------------------
      -- Certified Suppliers:
      --    Transaction Name like @COMED
      --    Transaction Interval is HOUR
      --    ESP_TYPE is CERTIFIED
      --    Less Municipalities:  MUNIs can be identified by cross referencing the UFC
      --             and UFT Participation Report (CDI_UFC_UFT_PARTICIPATION table)
      -- --------------------------------------------------------------------------------------
      FUNCTION apply_certified
      (
         p_transaction_id interchange_transaction.transaction_name%TYPE,
         p_type_in        it_schedule.schedule_type%TYPE,
         p_type_out       it_schedule.schedule_type%TYPE
      ) RETURN NUMBER AS
      BEGIN

         MERGE INTO it_schedule s
         USING (SELECT p_transaction_id transaction_id,
                       p_type_out schedule_type,
                       c.schedule_date,
                       SUM(c.amount) amount
                  FROM it_schedule c
                 WHERE c.schedule_date BETWEEN v_begin_date AND v_end_date
                   AND c.schedule_state = ga.internal_state
                   AND c.schedule_type = p_type_in
                   AND EXISTS
                 (SELECT 1
                          FROM interchange_transaction a,
                               pse_esp                 pe,
                               energy_service_provider es
                         WHERE (a.transaction_name LIKE '%@COMED' OR
                               a.transaction_name LIKE '%@ComEd')
                           AND a.transaction_id = c.transaction_id
                           AND upper(a.transaction_interval) = 'HOUR'
                           AND a.pse_id > 0
                           AND a.pse_id = pe.pse_id
                           AND pe.esp_id = es.esp_id
                           AND upper(es.esp_type) = 'CERTIFIED'
                           AND EXISTS
                         (SELECT 1
                                  FROM tp_contract_number b
                                 WHERE a.contract_id = b.contract_id))
                 GROUP BY c.schedule_date) v_s
         ON (s.transaction_id = v_s.transaction_id AND s.schedule_type = v_s.schedule_type AND s.schedule_date = v_s.schedule_date)
         WHEN MATCHED THEN
            UPDATE
               SET s.amount = s.amount - v_s.amount;
         v_count := SQL%ROWCOUNT;
         logs.log_info('Certified intervals applied ' || to_char(v_count));

         RETURN 1;
      EXCEPTION
         WHEN OTHERS THEN
            p_status  := SQLCODE;
            p_message := pkgc_pkg_nme || '.apply_certified: ' ||
                         ut.get_full_errm;
            RETURN 0;
      END apply_certified;

      -- --------------------------------------------------------------------------------------
      --  CPP-H, CPP-QF, B_SUPPLIED@COMED
      -- --------------------------------------------------------------------------------------
      FUNCTION apply_non_load
      (
         p_transaction_id   interchange_transaction.transaction_name%TYPE,
         p_transaction_name interchange_transaction.transaction_name%TYPE,
         p_type_in          it_schedule.schedule_type%TYPE,
         p_type_out         it_schedule.schedule_type%TYPE
      ) RETURN NUMBER AS
      BEGIN
         MERGE INTO it_schedule s
         USING (SELECT p_transaction_id transaction_id,
                       p_type_out schedule_type,
                       s.schedule_date,
                       SUM(s.amount) amount
                  FROM interchange_transaction it,
                       it_schedule             s
                 WHERE it.transaction_name = p_transaction_name
                   AND s.transaction_id = it.transaction_id
                   AND s.schedule_state = ga.internal_state
                   AND s.schedule_type = p_type_in
                   AND s.schedule_date BETWEEN v_begin_date AND v_end_date
                 GROUP BY s.schedule_date) v_s
         ON (s.transaction_id = v_s.transaction_id AND s.schedule_type = v_s.schedule_type AND s.schedule_date = v_s.schedule_date)
         WHEN MATCHED THEN
            UPDATE
               SET s.amount = s.amount - v_s.amount;

         logs.log_info(p_transaction_name || ' applied ' ||
                       to_char(SQL%ROWCOUNT));
         RETURN 1;
      EXCEPTION
         WHEN OTHERS THEN
            p_status  := SQLCODE;
            p_message := pkgc_pkg_nme || '.apply_non_load: ' ||
                         ut.get_full_errm;
            RETURN 0;
      END apply_non_load;
      -- --------------------------------------------------------------------------------------
      --  Municipalities
      -- --------------------------------------------------------------------------------------
      FUNCTION apply_muni
      (
         p_transaction_id interchange_transaction.transaction_name%TYPE,
         p_type_in        it_schedule.schedule_type%TYPE,
         p_type_out       it_schedule.schedule_type%TYPE
      ) RETURN NUMBER AS
      BEGIN
         MERGE INTO it_schedule s
         USING (SELECT p_transaction_id transaction_id,
                       p_type_out schedule_type,
                       s.schedule_date,
                       SUM(s.amount) amount
                  FROM interchange_transaction   it,
                       it_schedule               s,
                       cdi_ufc_uft_participation cdi,
                       pse
                 WHERE it.pse_id = pse.pse_id
                   AND it.transaction_type = 'Load'
                   AND pse.pse_name = cdi.pse_name
                   AND cdi.pool_name = 'MUNI'
                   AND s.transaction_id = it.transaction_id
                   AND s.schedule_state = ga.internal_state
                   AND s.schedule_type = p_type_in
                   AND s.schedule_date BETWEEN v_begin_date AND v_end_date
                 GROUP BY s.schedule_date) v_s
         ON (s.transaction_id = v_s.transaction_id AND s.schedule_type = v_s.schedule_type AND s.schedule_date = v_s.schedule_date)
         WHEN MATCHED THEN
            UPDATE
               SET s.amount = s.amount - v_s.amount;

         logs.log_info('MUNIs applied ' || to_char(SQL%ROWCOUNT));
         RETURN 1;
      EXCEPTION
         WHEN OTHERS THEN
            p_status  := SQLCODE;
            p_message := pkgc_pkg_nme || '.apply_muni: ' || ut.get_full_errm;
            RETURN 0;
      END apply_muni;
      -- --------------------------------------------------------------------------------------
      --
      -- --------------------------------------------------------------------------------------
   BEGIN
      logs.log_info('Running ' || p_schedule_type);
      ut.cut_date_range(ga.electric_model,
                        p_begin_date,
                        p_end_date,
                        p_time_zone,
                        v_begin_date,
                        v_end_date);

      CASE p_schedule_type
         WHEN 'Day Ahead UFE' THEN
            id.id_for_transaction('Day Ahead UFE',
                                  'Load',
                                  FALSE,
                                  v_day_ahead_ufe);

            IF v_day_ahead_ufe = ga.no_data_found THEN
               p_message := 'Please setup Day Ahead UFE Transactions';
               logs.log_error('Schedule Transaction is not setup for "Day Ahead UFE"');
               RETURN;
            END IF;
            logs.log_info('Day Ahead UFE');
            v_status := create_load(v_day_ahead_ufe,
                                    ga.schedule_type_forecast,
                                    ga.schedule_type_forecast);

            IF v_status = 1 THEN
               logs.log_info('Applying Certified Suppliers');
               v_status := apply_certified(v_day_ahead_ufe,
                                           ga.schedule_type_forecast,
                                           ga.schedule_type_forecast);
            END IF;

            IF v_status = 1 THEN
               logs.log_info('Applying CPPH');
               v_status := apply_non_load(v_day_ahead_ufe,
                                          c_cpph,
                                          ga.schedule_type_forecast,
                                          ga.schedule_type_forecast);
            END IF;

            IF v_status = 1 THEN
               logs.log_info('Applying CPPQF');
               v_status := apply_non_load(v_day_ahead_ufe,
                                          c_cppqf,
                                          ga.schedule_type_forecast,
                                          ga.schedule_type_forecast);
            END IF;

            IF v_status = 1 THEN
               logs.log_info('Applying CPP-B');
               v_status := apply_non_load(v_day_ahead_ufe,
                                          c_cppb,
                                          ga.schedule_type_forecast,
                                          ga.schedule_type_forecast);
            END IF;

            IF v_status = 1 THEN
               logs.log_info('Applying RTOU');
               v_status := apply_non_load(v_day_ahead_ufe,
                                          c_rtou,
                                          ga.schedule_type_forecast,
                                          ga.schedule_type_forecast);
            END IF;

         WHEN 'Scheduling UFE' THEN
            id.id_for_transaction('Scheduling UFE',
                                  'Load',
                                  FALSE,
                                  v_scheduling_ufe);

            IF v_scheduling_ufe = ga.no_data_found THEN
               p_message := 'Please setup Scheduling UFE Transactions';
               logs.log_error('Schedule Transaction is not setup for "Scheduling UFE"');
               RETURN;
            END IF;
            logs.log_info('Scheduling UFE');
            v_status := create_load(v_scheduling_ufe,
                                    ga.schedule_type_final,
                                    ga.schedule_type_prelim);
            IF v_status = 1 THEN
               logs.log_info('Applying Certified Suppliers');
               v_status := apply_certified(v_scheduling_ufe,
                                           ga.schedule_type_forecast,
                                           ga.schedule_type_prelim);
            END IF;

            IF v_status = 1 THEN
               logs.log_info('Applying CPPH');
               v_status := apply_non_load(v_scheduling_ufe,
                                          c_cpph,
                                          ga.schedule_type_prelim,
                                          ga.schedule_type_prelim);
            END IF;

            IF v_status = 1 THEN
               logs.log_info('Applying CPPQF');
               v_status := apply_non_load(v_scheduling_ufe,
                                          c_cppqf,
                                          ga.schedule_type_prelim,
                                          ga.schedule_type_prelim);
            END IF;

            IF v_status = 1 THEN
               logs.log_info('Applying CPP-B');
               v_status := apply_non_load(v_scheduling_ufe,
                                          c_cppb,
                                          ga.schedule_type_prelim,
                                          ga.schedule_type_prelim);
            END IF;

            IF v_status = 1 THEN
               logs.log_info('Applying RTOU');
               v_status := apply_non_load(v_scheduling_ufe,
                                          c_rtou,
                                          ga.schedule_type_prelim,
                                          ga.schedule_type_prelim);
            END IF;

      END CASE;

      COMMIT;

   END calculate_wholesale_ufe;
   -- --------------------------------------------------------------------------------------
   -- SHARE_WHOLESALE_UFE
   -- --------------------------------------------------------------------------------------
   -- MODIFICATION HISTORY
   -- Person         Date         Comments
   -- -----------    -----------  ----------------------------------------------------------
   --  KN            Jan 06 2014  Created
   --  RTo           Apr 15 2020  RTOU Project
   -- --------------------------------------------------------------------------------------
   -- RULES:
   -- Share UFE with all certified supplies, CPP-H and CPP-B (B_SUPPLIED@COMED) but not with Municipalities or CPP-QF.
   --       This will be on the UFE Participation report in Scheduling module Other tab for each scheduling supplier.
   -- Schedule amount for CPP-H is adjusted by the CPP-QF load but the CPP-QF does not share UFE.
   -- Update Forecast state schedules with UFE amounts during Day Ahead and Scheduling process for Certified Suppliers
   -- Update Forecast state schedule with UFE amount during Day Ahead process for CPP-H
   -- Update Preliminary state schedule with UFE amount during Scheduling process for CPP-H
   -- Update Forecast state schedule with UFE amount during Day Ahead process for B_SUPPLIED
   -- Update Preliminary state schedule with UFE amount during Scheduling process for B_SUPPLIED
   -- Schedule amounts uploaded and downloaded for CPP-H are under the contract CEDPH-H-2008
   -- Schedule amounts uploaded and downloaded for CPP-B are under the contract COMED-B-2010
   -- Current reports and data exchanges require Forecast state for Day Ahead process for CPP-H and CPP-B and Preliminary
   --        state for CPP-H and CPP-B
   -- Rounding needs to be done to the nearest kWh
   -- --------------------------------------------------------------------------------------
   PROCEDURE share_wholesale_ufe
   (
      p_schedule_type IN VARCHAR2,
      p_begin_date    IN DATE,
      p_end_date      IN DATE,
      p_time_zone     IN VARCHAR2,
      p_status        OUT NUMBER,
      p_message       OUT VARCHAR2
   ) AS
      lc_proc_nme CONSTANT VARCHAR2(40) := 'SHARE_WHOLESALE_UFE';

      c_zone_load           interchange_transaction.transaction_name%TYPE := 'ComEd Initial Zone Load';
      c_cpph                interchange_transaction.transaction_name%TYPE := 'CPP-H@COMED';
      c_cppb                interchange_transaction.transaction_name%TYPE := 'B_SUPPLIED@COMED';
      c_rtou                interchange_transaction.transaction_name%TYPE := 'RTOU@COMED';
      c_cppqf               interchange_transaction.transaction_name%TYPE := 'CPP-QF@COMED';
      c_da_ufe              interchange_transaction.transaction_name%TYPE := 'Day Ahead UFE';
      c_sched_ufe           interchange_transaction.transaction_name%TYPE := 'Scheduling UFE';
      c_without_ufe_type_id it_schedule.schedule_type%TYPE := id_for_statement_type('Without UFE');

      v_zone_load      interchange_transaction.transaction_id%TYPE;
      v_cpp_h          interchange_transaction.transaction_id%TYPE;
      v_cpp_b          interchange_transaction.transaction_id%TYPE;
      v_rtou           interchange_transaction.transaction_id%TYPE;
      v_ufe            interchange_transaction.transaction_id%TYPE;
      v_type_in        it_schedule.schedule_type%TYPE;
      v_load_zone_type it_schedule.schedule_type%TYPE;
      v_begin_date     DATE;
      v_end_date       DATE;
      v_status         PLS_INTEGER;

   BEGIN

      CASE p_schedule_type
         WHEN 'Day Ahead UFE' THEN
            v_type_in        := ga.schedule_type_forecast;
            v_load_zone_type := ga.schedule_type_forecast;
            id.id_for_transaction(c_da_ufe, 'Load', FALSE, v_ufe);
         WHEN 'Scheduling UFE' THEN
            v_type_in        := ga.schedule_type_prelim;
            v_load_zone_type := ga.schedule_type_final;
            id.id_for_transaction(c_sched_ufe, 'Load', FALSE, v_ufe);
      END CASE;

      IF v_type_in IS NULL THEN
         p_message := 'Invalid Schedule Type';
         logs.log_error('Error for Schedule Type ' || p_schedule_type);
      END IF;

      ut.cut_date_range(ga.electric_model,
                        p_begin_date,
                        p_end_date,
                        p_time_zone,
                        v_begin_date,
                        v_end_date);

      v_begin_date := advance_date(v_begin_date - 1/86400, 'HOUR');

      id.id_for_transaction(c_zone_load, 'Load', FALSE, v_zone_load);
      id.id_for_transaction(c_cpph, 'Load', FALSE, v_cpp_h);
      id.id_for_transaction(c_cppb, 'Load', FALSE, v_cpp_b);
      id.id_for_transaction(c_rtou, 'Load', FALSE, v_rtou);

      -- --------------------------------------------------------------------------------------
      -- Update Forecast state schedules
      -- with UFE amounts during Day Ahead AND Scheduling process for Certified Suppliers
      -- NOTE: 'Without UFE' numbers will be created for Day Ahead and Scheduling before each Share UFE
      --        Calculation is run.  This is why we are able to use the same 'Without UFE' state for both
      -- --------------------------------------------------------------------------------------
      BEGIN
         logs.log_info('Calculating Certified Suppliers UFE Share');
         MERGE INTO it_schedule s
         USING (SELECT cert.transaction_id,
                       ga.internal_state schedule_state,
                       ga.schedule_type_forecast schedule_type, -- Always Forecast for Certs
                       t.column_value schedule_date,
                       round(nvl(cert.amount, 0) * nvl(ufe.amount, 0) /
                            (nvl(total_cert.amount, 0) +  nvl(cpph.amount,0) + nvl(cppb.amount, 0) + nvl(rtou.amount, 0)) +
                             nvl(cert.amount, 0), 3) amount
                  FROM it_schedule ufe,
                       it_schedule cpph,
                       it_schedule cppb,
                       it_schedule rtou,
                       TABLE(CAST (get_date_range_interval(v_begin_date, v_end_date, 'H') AS DATE_TABLE)) t,
                       -- Certified Supplier
                       (SELECT c.transaction_id,
                               c.schedule_date,
                               SUM(c.amount) amount
                          FROM it_schedule c
                         WHERE c.schedule_state = ga.internal_state
                           AND c.schedule_type = c_without_ufe_type_id
                           AND c.schedule_date BETWEEN v_begin_date AND v_end_date
                           AND EXISTS
                               (SELECT 1
                                  FROM interchange_transaction a,
                                       pse_esp                 pe,
                                       energy_service_provider es
                                 WHERE (a.transaction_name LIKE '%@COMED' OR
                                       a.transaction_name LIKE '%@ComEd')
                                   AND a.transaction_id = c.transaction_id
                                   AND upper(a.transaction_interval) = 'HOUR'
                                   AND a.pse_id > 0
                                   AND a.pse_id = pe.pse_id
                                   AND pe.esp_id = es.esp_id
                                   AND upper(es.esp_type) = 'CERTIFIED'
                                   AND EXISTS
                                      (SELECT 1
                                         FROM tp_contract_number b
                                         WHERE a.contract_id = b.contract_id)
                                      --Is UFF Participation true
                                   AND EXISTS
                                       (SELECT 1
                                          FROM cdi_ufc_uft_participation cdi,
                                               interchange_transaction   sit,
                                               pse
                                         WHERE cdi.pse_name = pse.pse_name
                                           AND sit.transaction_id =
                                               c.transaction_id
                                           AND pse.pse_id = sit.pse_id
                                           AND cdi.is_ufe_participant = 1))
                         GROUP BY transaction_id,
                                  schedule_date) cert,
                       (SELECT c.schedule_date,
                           SUM(c.amount) amount
                          FROM it_schedule c
                         WHERE c.schedule_state = ga.internal_state
                           AND c.schedule_type = c_without_ufe_type_id
                           AND c.schedule_date BETWEEN v_begin_date AND v_end_date
                           AND EXISTS
                               (SELECT 1
                                  FROM interchange_transaction a,
                                       pse_esp                 pe,
                                       energy_service_provider es
                                 WHERE (a.transaction_name LIKE '%@COMED' OR
                                       a.transaction_name LIKE '%@ComEd')
                                   AND a.transaction_id = c.transaction_id
                                   AND upper(a.transaction_interval) = 'HOUR'
                                   AND a.pse_id > 0
                                   AND a.pse_id = pe.pse_id
                                   AND pe.esp_id = es.esp_id
                                   AND upper(es.esp_type) = 'CERTIFIED'
                                   AND EXISTS
                                       (SELECT 1
                                          FROM tp_contract_number b
                                         WHERE a.contract_id = b.contract_id)
                                     --Is UFF Participation true
                                    AND EXISTS
                                        (SELECT 1
                                           FROM cdi_ufc_uft_participation cdi,
                                                interchange_transaction   sit,
                                                pse
                                          WHERE cdi.pse_name = pse.pse_name
                                            AND pse.pse_id = sit.pse_id
                                            AND cdi.is_ufe_participant = 1))
                         GROUP BY schedule_date) total_cert
                 WHERE t.column_value = ufe.schedule_date(+)
                   AND t.column_value = cpph.schedule_date(+)
                   AND t.column_value = cppb.schedule_date(+)
                   AND t.column_value = rtou.schedule_date(+)
                   AND t.column_value = cert.schedule_date(+)
                   AND t.column_value = total_cert.schedule_date(+)
                      -- UFE
                   AND ufe.transaction_id(+) = v_ufe
                   AND ufe.schedule_state(+) = ga.internal_state
                   AND ufe.schedule_type(+) = v_type_in
                      -- CPP-h
                   AND cpph.transaction_id(+) = v_cpp_h
                   AND cpph.schedule_state(+) = ga.internal_state
                   AND cpph.schedule_type(+) = c_without_ufe_type_id
                      -- B_SUPPLIED
                   AND cppb.transaction_id(+) = v_cpp_b
                   AND cppb.schedule_state(+) = ga.internal_state
                   AND cppb.schedule_type(+) = c_without_ufe_type_id
                      -- RTOU
                   AND rtou.transaction_id(+) = v_rtou
                   AND rtou.schedule_state(+) = ga.internal_state
                   AND rtou.schedule_type(+) = c_without_ufe_type_id) v_s
         ON (s.transaction_id = v_s.transaction_id AND s.schedule_type = v_s.schedule_type AND s.schedule_state = v_s.schedule_state AND s.schedule_date = v_s.schedule_date)
         WHEN MATCHED THEN
            UPDATE
               SET s.amount = v_s.amount;

         logs.log_info('Certified Suppliser Intervals Updated ' ||
                       to_char(SQL%ROWCOUNT));

         -- --------------------------------------------------------------------------------------
         -- Update Forecast state schedule with UFE amount during Day Ahead process for CPP-H
         -- Update Preliminary state schedule with UFE amount during Scheduling process for CPP-H
         -- NOTE: 'Without UFE' numbers will be created for Day Ahead and Scheduling before each Share UFE
         --        Calculation is run.  This is why we are able to use the same 'Without UFE' state for both
         -- --------------------------------------------------------------------------------------
         logs.log_info('Calculating CPP-H UFE Share');
         MERGE INTO it_schedule s
         USING (SELECT cpph.transaction_id,
                       ga.internal_state schedule_state,
                       v_type_in schedule_type,
                       t.column_value schedule_date,
                       round(nvl(cpph.amount, 0) * nvl(ufe.amount, 0) /
                            (nvl(cert.amount, 0) +  nvl(cpph.amount,0) + nvl(cppb.amount, 0) + nvl(rtou.amount, 0)) +
                             nvl(cpph.amount, 0),3) amount
                  FROM it_schedule ufe,
                       it_schedule cpph,
                       it_schedule cppb,
                       it_schedule rtou,
                       TABLE(CAST (get_date_range_interval(v_begin_date, v_end_date, 'H') AS DATE_TABLE)) t,
                       -- Certified Supplier
                       (SELECT c.schedule_date,
                               SUM(c.amount) amount
                          FROM it_schedule c
                         WHERE c.schedule_state = ga.internal_state
                           AND c.schedule_type = c_without_ufe_type_id
                           AND EXISTS
                               (SELECT 1
                                  FROM interchange_transaction a,
                                       pse_esp                 pe,
                                       energy_service_provider es
                                 WHERE (a.transaction_name LIKE '%@COMED' OR
                                       a.transaction_name LIKE '%@ComEd')
                                   AND a.transaction_id = c.transaction_id
                                   AND upper(a.transaction_interval) = 'HOUR'
                                   AND a.pse_id > 0
                                   AND a.pse_id = pe.pse_id
                                   AND pe.esp_id = es.esp_id
                                   AND upper(es.esp_type) = 'CERTIFIED'
                                   AND EXISTS
                                       (SELECT 1
                                          FROM tp_contract_number b
                                         WHERE a.contract_id = b.contract_id)
                                      --Is UFF Participation true
                                   AND EXISTS
                                       (SELECT 1
                                          FROM cdi_ufc_uft_participation cdi,
                                               interchange_transaction   sit,
                                               pse
                                         WHERE cdi.pse_name = pse.pse_name
                                           AND sit.transaction_id =
                                               c.transaction_id
                                           AND pse.pse_id = sit.pse_id
                                           AND cdi.is_ufe_participant = 1))
                         GROUP BY schedule_date) cert
                 WHERE t.column_value = ufe.schedule_date(+)
                   AND t.column_value = cpph.schedule_date(+)
                   AND t.column_value = cppb.schedule_date(+)
                   AND t.column_value = rtou.schedule_date(+)
                   AND t.column_value = cert.schedule_date(+)
                      -- UFE
                   AND ufe.transaction_id(+) = v_ufe
                   AND ufe.schedule_state(+) = ga.internal_state
                   AND ufe.schedule_type(+) = v_type_in
                      -- CPP-h
                   AND cpph.transaction_id(+) = v_cpp_h
                   AND cpph.schedule_state(+) = ga.internal_state
                   AND cpph.schedule_type(+) = c_without_ufe_type_id
                      -- B_SUPPLIED
                   AND cppb.transaction_id(+) = v_cpp_b
                   AND cppb.schedule_state(+) = ga.internal_state
                   AND cppb.schedule_type(+) = c_without_ufe_type_id
                      -- RTOU
                   AND rtou.transaction_id(+) = v_rtou
                   AND rtou.schedule_state(+) = ga.internal_state
                   AND rtou.schedule_type(+) = c_without_ufe_type_id) v_s
         ON (s.transaction_id = v_s.transaction_id AND s.schedule_type = v_s.schedule_type AND s.schedule_state = v_s.schedule_state AND s.schedule_date = v_s.schedule_date)
         WHEN MATCHED THEN
            UPDATE
               SET s.amount = v_s.amount;

         logs.log_info('CPP-H Intervals Updated ' || to_char(SQL%ROWCOUNT));

         -- --------------------------------------------------------------------------------------
         -- Update Forecast state schedule with UFE amount during Day Ahead process for RTOU
         -- Update Preliminary state schedule with UFE amount during Scheduling process for RTOU
         -- NOTE: 'Without UFE' numbers will be created for Day Ahead and Scheduling before each Share UFE
         --        Calculation is run.  This is why we are able to use the same 'Without UFE' state for both
         -- --------------------------------------------------------------------------------------
         logs.log_info('Calculating RTOU UFE Share');
         MERGE INTO it_schedule s
         USING (SELECT rtou.transaction_id,
                       ga.internal_state schedule_state,
                       v_type_in schedule_type,
                       t.column_value schedule_date,
                       round(nvl(rtou.amount, 0) * nvl(ufe.amount, 0) /
                            (nvl(cert.amount, 0) +  nvl(cpph.amount,0) + nvl(cppb.amount, 0) + nvl(rtou.amount, 0)) +
                             nvl(rtou.amount, 0),3) amount
                  FROM it_schedule ufe,
                       it_schedule cpph,
                       it_schedule cppb,
                       it_schedule rtou,
                       TABLE(CAST (get_date_range_interval(v_begin_date, v_end_date, 'H') AS DATE_TABLE)) t,
                       (SELECT c.schedule_date,
                               SUM(c.amount) amount
                          FROM it_schedule c
                         WHERE c.schedule_state = ga.internal_state
                           AND c.schedule_type = c_without_ufe_type_id
                           AND EXISTS
                               (SELECT 1
                                  FROM interchange_transaction a,
                                       pse_esp                 pe,
                                       energy_service_provider es
                                 WHERE (a.transaction_name LIKE '%@COMED' OR
                                       a.transaction_name LIKE '%@ComEd')
                                   AND a.transaction_id = c.transaction_id
                                   AND upper(a.transaction_interval) = 'HOUR'
                                   AND a.pse_id > 0
                                   AND a.pse_id = pe.pse_id
                                   AND pe.esp_id = es.esp_id
                                   AND upper(es.esp_type) = 'CERTIFIED'
                                   AND EXISTS
                                       (SELECT 1
                                          FROM tp_contract_number b
                                         WHERE a.contract_id = b.contract_id)
                                      --Is UFF Participation true
                                   AND EXISTS
                                       (SELECT 1
                                          FROM cdi_ufc_uft_participation cdi,
                                               interchange_transaction   sit,
                                               pse
                                         WHERE cdi.pse_name = pse.pse_name
                                           AND sit.transaction_id =
                                               c.transaction_id
                                           AND pse.pse_id = sit.pse_id
                                           AND cdi.is_ufe_participant = 1))
                         GROUP BY schedule_date) cert
                 WHERE t.column_value = ufe.schedule_date(+)
                   AND t.column_value = cpph.schedule_date(+)
                   AND t.column_value = cppb.schedule_date(+)
                   AND t.column_value = rtou.schedule_date(+)
                   AND t.column_value = cert.schedule_date(+)
                      -- UFE
                   AND ufe.transaction_id(+) = v_ufe
                   AND ufe.schedule_state(+) = ga.internal_state
                   AND ufe.schedule_type(+) = v_type_in
                      -- CPP-h
                   AND cpph.transaction_id(+) = v_cpp_h
                   AND cpph.schedule_state(+) = ga.internal_state
                   AND cpph.schedule_type(+) = c_without_ufe_type_id
                      -- B_SUPPLIED
                   AND cppb.transaction_id(+) = v_cpp_b
                   AND cppb.schedule_state(+) = ga.internal_state
                   AND cppb.schedule_type(+) = c_without_ufe_type_id
                      -- RTOU
                   AND rtou.transaction_id(+) = v_rtou
                   AND rtou.schedule_state(+) = ga.internal_state
                   AND rtou.schedule_type(+) = c_without_ufe_type_id) v_s
         ON (s.transaction_id = v_s.transaction_id AND s.schedule_type = v_s.schedule_type AND s.schedule_state = v_s.schedule_state AND s.schedule_date = v_s.schedule_date)
         WHEN MATCHED THEN
            UPDATE
               SET s.amount = v_s.amount;

         logs.log_info('RTOU Intervals Updated ' || to_char(SQL%ROWCOUNT));
         -- --------------------------------------------------------------------------------------
         -- Update Forecast state schedule with UFE amount during Day Ahead process for B_SUPPLIED
         -- Update Preliminary state schedule with UFE amount during Scheduling process for B_SUPPLIED
         -- NOTE: 'Without UFE' numbers will be created for Day Ahead and Scheduling before each Share UFE
         --        Calculation is run.  This is why we are able to use the same 'Without UFE' state for both
         -- --------------------------------------------------------------------------------------
         logs.log_info('Calculating B_SUPPLIED UFE Share');
         MERGE INTO it_schedule s
         USING (SELECT cppb.transaction_id,
                       ga.internal_state schedule_state,
                       v_type_in schedule_type,
                       t.column_value schedule_date,
                       round(nvl(cppb.amount, 0) * nvl(ufe.amount, 0) /
                            (nvl(cert.amount, 0) +  nvl(cpph.amount,0) + nvl(cppb.amount, 0) + nvl(rtou.amount, 0)) +
                             nvl(cppb.amount, 0),3) amount
                  FROM it_schedule ufe,
                       it_schedule cpph,
                       it_schedule cppb,
                       it_schedule rtou,
                       TABLE(CAST (get_date_range_interval(v_begin_date, v_end_date, 'H') AS DATE_TABLE)) t,
                       (SELECT c.schedule_date,
                               SUM(c.amount) amount
                          FROM it_schedule c
                         WHERE c.schedule_state = ga.internal_state
                           AND c.schedule_type = c_without_ufe_type_id
                           AND EXISTS
                               (SELECT 1
                                  FROM interchange_transaction a,
                                       pse_esp                 pe,
                                       energy_service_provider es
                                 WHERE (a.transaction_name LIKE '%@COMED' OR
                                       a.transaction_name LIKE '%@ComEd')
                                   AND a.transaction_id = c.transaction_id
                                   AND upper(a.transaction_interval) = 'HOUR'
                                   AND a.pse_id > 0
                                   AND a.pse_id = pe.pse_id
                                   AND pe.esp_id = es.esp_id
                                   AND upper(es.esp_type) = 'CERTIFIED'
                                   AND EXISTS
                                       (SELECT 1
                                          FROM tp_contract_number b
                                         WHERE a.contract_id = b.contract_id)
                                      --Is UFF Participation true
                                   AND EXISTS
                                       (SELECT 1
                                          FROM cdi_ufc_uft_participation cdi,
                                               interchange_transaction   sit,
                                               pse
                                         WHERE cdi.pse_name = pse.pse_name
                                           AND sit.transaction_id =
                                               c.transaction_id
                                           AND pse.pse_id = sit.pse_id
                                           AND cdi.is_ufe_participant = 1))
                         GROUP BY schedule_date) cert
                 WHERE t.column_value = ufe.schedule_date(+)
                   AND t.column_value = cpph.schedule_date(+)
                   AND t.column_value = cppb.schedule_date(+)
                   AND t.column_value = rtou.schedule_date(+)
                   AND t.column_value = cert.schedule_date(+)
                      -- UFE
                   AND ufe.transaction_id(+) = v_ufe
                   AND ufe.schedule_state(+) = ga.internal_state
                   AND ufe.schedule_type(+) = v_type_in
                      -- CPP-h
                   AND cpph.transaction_id = v_cpp_h
                   AND cpph.schedule_state = ga.internal_state
                   AND cpph.schedule_type = c_without_ufe_type_id
                      -- B_SUPPLIED
                   AND cppb.transaction_id(+) = v_cpp_b
                   AND cppb.schedule_state(+) = ga.internal_state
                   AND cppb.schedule_type(+) = c_without_ufe_type_id
                      -- RTOU
                   AND rtou.transaction_id(+) = v_rtou
                   AND rtou.schedule_state(+) = ga.internal_state
                   AND rtou.schedule_type(+) = c_without_ufe_type_id) v_s
         ON (s.transaction_id = v_s.transaction_id AND s.schedule_type = v_s.schedule_type AND s.schedule_state = v_s.schedule_state AND s.schedule_date = v_s.schedule_date)
         WHEN MATCHED THEN
            UPDATE
               SET s.amount = v_s.amount;
         logs.log_info('B_SUPPLIED Intervals Updated ' || to_char(SQL%ROWCOUNT));
      END;

      COMMIT;
   END share_wholesale_ufe;
   -- --------------------------------------------------------------------------------------
   -- AGGREGATE_INTERNAL_ESP_SCH
   -- --------------------------------------------------------------------------------------
   -- MODIFICATION HISTORY
   -- Person         Date         Comments
   -- -----------    -----------  ----------------------------------------------------------
   --  KN           Feb 26 2014   Created
   -- --------------------------------------------------------------------------------------
   -- Sum certified supplier schedules (i.e. certified supplier less municipalities and municipalities)
   -- in the Internal state only. It can be executed in Data Exchange screen under Scheduling Data Exchange type.
   -- --------------------------------------------------------------------------------------
   PROCEDURE aggregate_internal_esp_sch
   (
      p_begin_date IN DATE,
      p_end_date   IN DATE,
      p_time_zone  IN VARCHAR2,
      p_status     OUT NUMBER,
      p_message    OUT VARCHAR2
   ) IS

      lc_proc_nme CONSTANT VARCHAR2(40) := 'AGGREGATE_INTERNAL_ESP_SCH';
      -- LOCAL VARIABLES --
      v_schedule_val  NUMBER;
      v_schedule_date DATE;
      --      v_to_balance    BOOLEAN DEFAULT FALSE;

      c_agg_cert_esp VARCHAR2(64) := 'AggregatedCertifiedESP';
      c_agg_esp      VARCHAR2(64) := 'AggregatedESP';
      c_pass_thru    VARCHAR2(16) := 'Pass-Thru'; --'Load';  --'Generation';

      v_balance_id NUMBER DEFAULT 0;
      v_status     NUMBER;
      v_price      NUMBER;
      v_as_of_date DATE := g_low_date;
      v_count      NUMBER;
      --      v_time_zone        CHAR(3) := g_PJM_TIME_ZONE; --Defect 1206 Mm_Pjm_Util.g_PJM_TIME_ZONE;  --'EDT' -
      v_begin_date DATE;
      v_end_date   DATE;

      v_agg_esp_id      NUMBER;
      v_agg_cert_esp_id NUMBER;



      CURSOR c1 IS
         SELECT c.schedule_date schedule_date,
                SUM(c.amount) amount
           FROM it_schedule c
          WHERE c.schedule_date BETWEEN v_begin_date AND v_end_date
            AND schedule_state = ga.internal_state
            AND schedule_type = ga.schedule_type_forecast
            AND EXISTS
          (SELECT 1
                   FROM interchange_transaction a
                  WHERE (transaction_name LIKE '%@COMED' OR
                        transaction_name LIKE '%@ComEd')
                    AND a.transaction_id = c.transaction_id
                    AND upper(a.transaction_type) = 'LOAD'
                    AND EXISTS (SELECT 1
                           FROM tp_contract_number b
                          WHERE a.contract_id = b.contract_id
                            AND b.contract_number NOT IN
                                (15606, 7019, 7015, 2055))
                 --Is UFF Participation true
                 /*   AND EXISTS
                 (SELECT 1
                          FROM cdi_ufc_uft_participation cdi,
                               interchange_transaction   sit,
                               pse
                         WHERE cdi.pse_name = pse.pse_name
                           AND sit.transaction_id = c.transaction_id
                           AND pse.pse_id = sit.pse_id
                           AND cdi.is_ufe_participant = 1)*/
                 )
          GROUP BY c.schedule_date;

      CURSOR c2 IS
         SELECT c.schedule_date schedule_date,
                SUM(c.amount) amount
           FROM it_schedule c
          WHERE c.schedule_date BETWEEN v_begin_date AND v_end_date
            AND schedule_state = ga.internal_state
            AND schedule_type = ga.schedule_type_forecast
            AND EXISTS (SELECT *
                   FROM interchange_transaction a,
                        pse_esp                 pe,
                        energy_service_provider es
                  WHERE (transaction_name LIKE '%@COMED' OR
                        transaction_name LIKE '%@ComEd')
                    AND a.transaction_id = c.transaction_id
                    AND upper(transaction_interval) = 'HOUR'
                    AND a.pse_id > 0
                    AND a.pse_id = pe.pse_id
                    AND pe.esp_id = es.esp_id
                    AND upper(es.esp_type) = 'CERTIFIED'
                    AND EXISTS
                  (SELECT 1
                           FROM tp_contract_number b
                          WHERE a.contract_id = b.contract_id)
                 --Is UFF Participation true
                 /*   AND EXISTS
                 (SELECT 1
                          FROM cdi_ufc_uft_participation cdi,
                               interchange_transaction   sit,
                               pse
                         WHERE cdi.pse_name = pse.pse_name
                           AND sit.transaction_id = c.transaction_id
                           AND pse.pse_id = sit.pse_id
                           AND cdi.is_ufe_participant = 1)*/
                 )
          GROUP BY c.schedule_date
          ORDER BY 1;

   BEGIN
      -- START LOGGING --
      --   g_PROC_NAME := 'AGGREGATE_ESP_SCHEDULES';
      p_status := ga.success;

      ut.cut_date_range(ga.electric_model,
                        p_begin_date,
                        p_end_date,
                        p_time_zone,
                        v_begin_date,
                        v_end_date);

      logs.set_process_target_parameter('Time Zone', p_time_zone);
      logs.set_process_target_parameter('Cut Begin Date',
                                        text_util.to_char_time(v_begin_date));
      logs.set_process_target_parameter('Cut End Date',
                                        text_util.to_char_time(v_end_date));

      id.id_for_transaction(c_agg_esp, c_pass_thru, FALSE, v_agg_esp_id);
      id.id_for_transaction(c_agg_cert_esp,
                            c_pass_thru,
                            FALSE,
                            v_agg_cert_esp_id);

      IF v_agg_esp_id > 0 THEN

         FOR cl IN c1
         LOOP

            v_schedule_val := cl.amount;
            --v_schedule_date := to_cut(cl.scHEDULE_DATE, LOCAL_TIME_ZONE)+1/24;
            v_schedule_date := cl.schedule_date;

            IF instr(to_char(v_schedule_date, 'MM/DD/YYYY HH:MI:SS PM'),
                     '59:59',
                     1,
                     1) > 0 THEN
               v_schedule_date := v_schedule_date + 1 / 86400;
            END IF;

            itj.put_it_schedule(v_agg_esp_id,
                                ga.schedule_type_forecast,
                                ga.internal_state,
                                v_schedule_date,
                                v_as_of_date,
                                v_schedule_val,
                                v_price,
                                v_status);

         END LOOP;
      ELSE
         p_status := -1;
         --    Post_To_App_Event_Log('SCHEDULING','DATA EXCHANGE','AggregatedESP(imported) schedule',
         --             'WARNING','Log','AGGREGATE_IMPORTED_ESP',NULL,'AggregatedESP transaction is not defined in the system','COMED');

      END IF;
      --------------

      IF v_agg_cert_esp_id > 0 THEN

         FOR cl IN c2
         LOOP

            v_schedule_val := cl.amount;
            --v_schedule_date := to_cut(cl.schedule_DATE, LOCAL_TIME_ZONE)+1/24;
            v_schedule_date := cl.schedule_date;

            IF instr(to_char(v_schedule_date, 'MM/DD/YYYY HH:MI:SS PM'),
                     '59:59',
                     1,
                     1) > 0 THEN
               v_schedule_date := v_schedule_date + 1 / 86400;
            END IF;

            itj.put_it_schedule(v_agg_cert_esp_id,
                                ga.schedule_type_forecast,
                                ga.internal_state,
                                v_schedule_date,
                                v_as_of_date,
                                v_schedule_val,
                                v_price,
                                v_status);

            --v_SCHEDULE_TYPE  := 2;  -- PRELIMINARY
            itj.put_it_schedule(v_agg_cert_esp_id,
                                ga.schedule_type_prelim,
                                ga.internal_state,
                                v_schedule_date,
                                v_as_of_date,
                                v_schedule_val,
                                v_price,
                                v_status);

         END LOOP;


      END IF;

      IF p_status = ga.success THEN
         COMMIT;
      END IF;

   EXCEPTION
      WHEN OTHERS THEN
         p_status  := SQLCODE;
         p_message := pkgc_pkg_nme || '.COPY_SELF_SCHEDULES_INTERNAL: ' ||
                      ut.get_full_errm;

   END aggregate_internal_esp_sch;
   -- --------------------------------------------------------------------------------------
   -- COPY_H_QF_B_TO_PRELIM
   -- --------------------------------------------------------------------------------------
   -- MODIFICATION HISTORY
   -- Person         Date         Comments
   -- -----------    -----------  ----------------------------------------------------------
   --  KN            Apr 21 2014   Created
   --  RTo           Apr 12 2020   Added RTOU
   -- --------------------------------------------------------------------------------------
   -- The Data Exchange process will copy H, QF, RTOU and Blended from Forecast to
   -- Preliminary
   -- --------------------------------------------------------------------------------------
   PROCEDURE copy_h_qf_b_to_prelim
   (
      p_begin_date IN DATE,
      p_end_date   IN DATE,
      p_time_zone  IN VARCHAR2,
      p_status     OUT NUMBER,
      p_message    OUT VARCHAR2
   ) AS
      lc_proc_nme CONSTANT VARCHAR2(40) := 'COPY_H_QF_B_TO_PRELIM';

      v_begin_date       DATE;
      v_end_date         DATE;
      v_begin_date_local DATE;
      v_end_date_local   DATE;
      v_cnt              NUMBER;
   BEGIN

      ut.cut_date_range(ga.electric_model,
                        p_begin_date,
                        p_end_date,
                        p_time_zone, --g_PJM_EDT_TIMEZONE, Schedules from GUI TZ
                        v_begin_date,
                        v_end_date);

      -- Cut Range for Load Timezone for accurate count msg
      ut.cut_date_range(ga.electric_model,
                        p_begin_date,
                        p_end_date,
                        ga.local_time_zone,
                        v_begin_date_local,
                        v_end_date_local);

      MERGE INTO it_schedule s
      USING (SELECT s.transaction_id,
                    ga.schedule_type_prelim schedule_type,
                    ga.internal_state       schedule_state,
                    s.schedule_date,
                    s.as_of_date,
                    s.amount,
                    s.price,
                    s.lock_state
               FROM interchange_transaction it,
                    it_schedule             s
              WHERE it.transaction_type = 'Load'
                AND it.transaction_name IN
                    ('CPP-QF@COMED', 'CPP-H@COMED', 'B_SUPPLIED@COMED', 'RTOU@COMED')
                AND s.schedule_type = ga.schedule_type_forecast
                AND s.schedule_state = ga.internal_state
                AND s.transaction_id = it.transaction_id
                AND s.schedule_date BETWEEN v_begin_date AND v_end_date) v_s
      ON (s.transaction_id = v_s.transaction_id AND s.schedule_type = v_s.schedule_type AND s.schedule_date = v_s.schedule_date AND s.schedule_state = v_s.schedule_state)
      WHEN MATCHED THEN
         UPDATE
            SET s.amount = v_s.amount
      WHEN NOT MATCHED THEN
         INSERT
         VALUES
            (v_s.transaction_id,
             v_s.schedule_type,
             v_s.schedule_state,
             v_s.schedule_date,
             v_s.as_of_date,
             v_s.amount,
             v_s.price,
             v_s.lock_state);

      -- log the number of schedule days copied
      IF SQL%ROWCOUNT <> 0 THEN

         SELECT COUNT(x.schedday)
           INTO v_cnt
           FROM (SELECT s.transaction_id schedday
                   FROM interchange_transaction it,
                        it_schedule             s
                  WHERE it.transaction_type = 'Load'
                    AND it.transaction_name IN
                        ('CPP-QF@COMED', 'CPP-H@COMED', 'B_SUPPLIED@COMED', 'RTOU@COMED' )
                    AND s.schedule_type = ga.schedule_type_forecast
                    AND s.schedule_state = ga.internal_state
                    AND s.transaction_id = it.transaction_id
                    AND s.schedule_date BETWEEN v_begin_date_local AND
                        v_end_date_local) x;

         logs.log_info(v_cnt || ' Schedules copied', lc_proc_nme);
         p_message := v_cnt || ' Schedules copied';
      ELSE

         logs.log_info(0 || ' Schedules copied', lc_proc_nme);
         p_message := 0 || ' Self Schedules copied';
      END IF;

      COMMIT;
   EXCEPTION
      WHEN OTHERS THEN
         p_status  := SQLCODE;
         p_message := pkgc_pkg_nme || '.COPY_H_QF_B_TO_PRELIM: ' ||
                      ut.get_full_errm;

   END copy_h_qf_b_to_prelim;

   -- --------------------------------------------------------------------------------------
   -- COPY_FORECAST_ZL_TO_FINAL
   -- --------------------------------------------------------------------------------------
   -- MODIFICATION HISTORY
   -- Person         Date         Comments
   -- -----------    -----------  ----------------------------------------------------------
   --  KN            Apr 21 2014   Created
   -- --------------------------------------------------------------------------------------
   --
   -- --------------------------------------------------------------------------------------
   PROCEDURE copy_forecast_zl_to_final
   (
      p_begin_date IN DATE,
      p_end_date   IN DATE,
      p_time_zone  IN VARCHAR2,
      p_status     OUT NUMBER,
      p_message    OUT VARCHAR2
   ) AS
      lc_proc_nme CONSTANT VARCHAR2(40) := 'copy_forecast_zl_to_final';

      v_begin_date DATE;
      v_end_date   DATE;
      v_cnt        NUMBER;
   BEGIN

      ut.cut_date_range(ga.electric_model,
                        p_begin_date,
                        p_end_date,
                        p_time_zone,
                        v_begin_date,
                        v_end_date);

      MERGE INTO it_schedule s
      USING (SELECT s.transaction_id,
                    ga.SCHEDULE_TYPE_FINAL schedule_type,
                    ga.internal_state      schedule_state,
                    s.schedule_date,
                    s.as_of_date,
                    s.amount,
                    s.price,
                    s.lock_state
               FROM interchange_transaction it,
                    it_schedule             s
              WHERE it.transaction_type = 'Zonal Load'
                AND it.transaction_name = 'ComEd Initial Zone Load'
                AND s.transaction_id = it.transaction_id
                AND s.schedule_state = ga.internal_state
                AND s.schedule_type = ga.schedule_type_forecast
                AND s.schedule_date BETWEEN v_begin_date AND v_end_date) v_s
      ON (s.transaction_id = v_s.transaction_id AND s.schedule_type = v_s.schedule_type AND s.schedule_date = v_s.schedule_date AND s.schedule_state = v_s.schedule_state)
      WHEN MATCHED THEN
         UPDATE
            SET s.amount = v_s.amount
      WHEN NOT MATCHED THEN
         INSERT
         VALUES
            (v_s.transaction_id,
             v_s.schedule_type,
             v_s.schedule_state,
             v_s.schedule_date,
             v_s.as_of_date,
             v_s.amount,
             v_s.price,
             v_s.lock_state);

      COMMIT;
   EXCEPTION
      WHEN OTHERS THEN
         p_status  := SQLCODE;
         p_message := pkgc_pkg_nme || '.COPY_FORECAST_ZL_TO_FINAL: ' ||
                      ut.get_full_errm;

   END copy_forecast_zl_to_final;

   -- ------ --------------------------------------------------------------------------------
   -- SET_IT_ORIG_CONTRACT
   -- --------------------------------------------------------------------------------------
   -- MODIFICATION HISTORY
   -- Person         Date         Comments
   -- -----------    -----------  ----------------------------------------------------------
   --  KN           Mar 14 2014   Created
   -- --------------------------------------------------------------------------------------
   -- Set Transaction To Original Contract
   --     Find all @COMED transactions with a contract with BEGIN DATE of p_BEGIN_DATE
   --     Update each of these contracts with their corresponding NEW contract with END DATE = p_END_DATE
   -- --------------------------------------------------------------------------------------
   PROCEDURE set_it_orig_contract
   (
      p_begin_date IN DATE,
      p_end_date   IN DATE,
      p_status     OUT NUMBER,
      p_message    OUT VARCHAR2
   ) IS
      v_new_contract_id            interchange_transaction.contract_id%TYPE;
      v_new_transaction_identifier interchange_transaction.transaction_identifier%TYPE;
      v_new_contract               VARCHAR2(50);
      v_cnt                        NUMBER := 0;
   BEGIN
      logs.start_process('Restore Original Contract Based on BEGIN DATE of NEW CONTRACT');
      logs.set_process_target_parameter('Original Contract Start Date',
                                        text_util.to_char_date(p_begin_date));
      logs.set_process_target_parameter('New Contract End Date',
                                        text_util.to_char_date(p_end_date));
      FOR r_rec IN (

                    SELECT it.transaction_id,
                            it.transaction_alias,
                            it.transaction_identifier,
                            substr(it.transaction_alias,
                                   1,
                                   (instr(it.transaction_alias, '@', 1, 1) - 1)) contract_name,
                            it.contract_id,
                            c.contract_number || '-' || c.contract_name contract
                      FROM interchange_transaction it,
                            tp_contract_number      c
                     WHERE it.transaction_alias LIKE '%@COMED'
                       AND it.transaction_type = 'Load'
                       AND it.contract_id <> 0
                       AND c.contract_id = it.contract_id
                       AND c.begin_date = p_end_date)
      LOOP

         BEGIN
            SELECT tp.contract_id,
                   tp.contract_number,
                   tp.contract_number || '-' || tp.contract_name
              INTO v_new_contract_id,
                   v_new_transaction_identifier,
                   v_new_contract
              FROM tp_contract_number tp
             WHERE tp.contract_name = r_rec.contract_name
               AND tp.end_date = p_begin_date;

            logs.log_info(r_rec.transaction_alias || '  Old Contract: ' ||
                          r_rec.contract || '  New Contract: ' ||
                          v_new_contract);
            UPDATE interchange_transaction it
               SET it.contract_id            = v_new_contract_id,
                   it.transaction_identifier = v_new_transaction_identifier
             WHERE it.transaction_id = r_rec.transaction_id;

            v_cnt := v_cnt + 1;

         EXCEPTION
            WHEN NO_DATA_FOUND THEN
               logs.log_info(r_rec.transaction_alias ||
                             '  Not Updated - No NEW contract');
         END;
      END LOOP;
      p_message := to_char(v_cnt) || ' Original Contracts Restored';
      logs.stop_process(p_message, p_status);

   END set_it_orig_contract;
   -- --------------------------------------------------------------------------------------
   -- SET_IT_NEW_CONTRACT
   -- --------------------------------------------------------------------------------------
   -- MODIFICATION HISTORY
   -- Person         Date         Comments
   -- -----------    -----------  ----------------------------------------------------------
   --  KN           Mar 14 2014   Created
   -- --------------------------------------------------------------------------------------
   -- Set Transaction To New Contract
   --     Find all @COMED transactions with a contract END DATE = v_switch_end_date
   --     Update each of these contracts with their corresponding NEW contract with a BEGIN DATE of v_switch_begin_date
   -------------------------------------------------------------------------------
   PROCEDURE set_it_new_contract
   (
      p_begin_date IN DATE,
      p_end_date   IN DATE,
      p_status     OUT NUMBER,
      p_message    OUT VARCHAR2
   ) IS
      v_new_contract_id            interchange_transaction.contract_id%TYPE;
      v_new_transaction_identifier interchange_transaction.transaction_identifier%TYPE;
      v_new_contract               VARCHAR2(50);
      v_cnt                        NUMBER := 0;
   BEGIN

      logs.start_process('Assign New Contract Based on END DATE of Original Contract');
      logs.set_process_target_parameter('New Contract Start Date',
                                        text_util.to_char_date(p_end_date));
      logs.set_process_target_parameter('Original Contract End Date',
                                        text_util.to_char_date(p_begin_date));
      FOR r_rec IN (SELECT it.transaction_id,
                           it.transaction_alias,
                           it.transaction_identifier,
                           substr(it.transaction_alias,
                                  1,
                                  (instr(it.transaction_alias, '@', 1, 1) - 1)) contract_name,
                           it.contract_id,
                           c.contract_number || '-' || c.contract_name contract
                      FROM interchange_transaction it,
                           tp_contract_number      c
                     WHERE it.transaction_alias LIKE '%@COMED'
                       AND it.transaction_type = 'Load'
                       AND it.contract_id <> 0
                       AND c.contract_id = it.contract_id
                       AND c.end_date = p_begin_date)
      LOOP

         BEGIN
            SELECT tp.contract_id,
                   tp.contract_number,
                   tp.contract_number || '-' || tp.contract_name
              INTO v_new_contract_id,
                   v_new_transaction_identifier,
                   v_new_contract
              FROM tp_contract_number tp
             WHERE tp.contract_name = r_rec.contract_name
               AND tp.begin_date = p_end_date;

            logs.log_info(r_rec.transaction_alias || '  Old Contract: ' ||
                          r_rec.contract || '  New Contract: ' ||
                          v_new_contract);

            UPDATE interchange_transaction it
               SET it.contract_id            = v_new_contract_id,
                   it.transaction_identifier = v_new_transaction_identifier
             WHERE it.transaction_id = r_rec.transaction_id;

            v_cnt := v_cnt + 1;

         EXCEPTION
            WHEN NO_DATA_FOUND THEN
               logs.log_info(r_rec.transaction_alias ||
                             '  Not Updated - No NEW contract');
         END;
      END LOOP;

      p_message := to_char(v_cnt) || ' New Contracts Assigned';
      logs.stop_process(p_message, p_status);

   END set_it_new_contract;

END CDI_DEX_PJM;
/
