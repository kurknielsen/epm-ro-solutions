CREATE OR REPLACE PACKAGE BODY mm_pjm_dm2 AS
   ----------------------------------------------------------------------------------------------------
   -- Copyright 2017 by ABB.
   -- All Rights Reserved.  Proprietary and Confidential.
   ----------------------------------------------------------------------------------------------------
   -- PURPOSE:  PJM DataMiner2 Market Manager
   -- REFER.:
   -- DESC:     This Package contains PJM DataMiner2 Market processes
   ----------------------------------------------------------------------------------------------------
   -- REVISION HISTORY
   -- DATE       AUTHOR         DESCRIPTION
   ------------- -------------- -----------------------------------------------------------------------
   --2017-Dec-1  Kurk Nielsen   Initial version - Copied rom MM_PJM_LMP and modifed for DataMiner2
   ----------------------------------------------------------------------------------------------------
   -- Public type declarations
   g_pjm_sc_id        sc.sc_id%TYPE;
   g_energy_component VARCHAR2(16) := 'Energy Component';
   g_cong_component   VARCHAR2(32) := 'Marginal Congestion Component';
   g_loss_component   VARCHAR2(32) := 'Marginal Loss Component';
   g_lmp              VARCHAR2(32) := 'Locational Marginal Price';

   ----------------------------------------------------------------------------------------------------
   -- what_version
   ----------------------------------------------------------------------------------------------------
   FUNCTION what_version RETURN VARCHAR2 IS
   BEGIN
      RETURN '$Revision: 1.0 $';
   END what_version;
   ----------------------------------------------------------------------------------------------------
   -- GET_MARKET_PRICE_ID (Modified for DataMiner2 which filters only relevent pNode_IDs)
   ----------------------------------------------------------------------------------------------------
   FUNCTION get_market_price_id
   (
      p_external_id       IN VARCHAR2
     ,p_market_type       IN VARCHAR2
     ,p_market_price_type IN VARCHAR2
   ) RETURN NUMBER IS

      v_mkt_price_id market_price.market_price_id%TYPE;

   BEGIN
      BEGIN
         SELECT mp.market_price_id
           INTO v_mkt_price_id
           FROM market_price mp
          WHERE mp.market_price_type = p_market_price_type
            AND mp.market_type = p_market_type
            AND mp.external_identifier =
                decode(p_market_price_type,
                       g_energy_component,
                       mp.external_identifier,
                       p_external_id);
      EXCEPTION
         WHEN NO_DATA_FOUND THEN
            logs.log_warn('Market Price ID not found for pNodeID:' ||
                          p_external_id || ' Market Price Type:' ||
                          p_market_price_type || ' Market Type:' ||
                          p_market_type);
            v_mkt_price_id := NULL;
      END;

      RETURN v_mkt_price_id;

   END get_market_price_id;
   ----------------------------------------------------------------------------------------------------
   -- put_market_price
   ----------------------------------------------------------------------------------------------------
   PROCEDURE put_market_price
   (
      p_monthly    IN NUMBER
     ,p_price_id   IN market_price_value.market_price_id%TYPE
     ,p_price_date IN market_price_value.price_date%TYPE
     ,p_price      IN market_price_value.price%TYPE
   ) IS
      TYPE ARRAY IS VARRAY(3) OF VARCHAR2(1);
      v_price_code_array ARRAY;
   BEGIN

      IF p_monthly = 1 THEN
         v_price_code_array := ARRAY('A');
      ELSE
         v_price_code_array := ARRAY('A', 'F', 'P');
      END IF;

      FOR i IN v_price_code_array.first .. v_price_code_array.last
      LOOP
         BEGIN
            INSERT INTO market_price_value
               (market_price_id,
                price_code,
                price_date,
                as_of_date,
                price_basis,
                price)
            VALUES
               (p_price_id,
                v_price_code_array(i),
                p_price_date,
                low_date,
                NULL,
                p_price);
         EXCEPTION
            WHEN DUP_VAL_ON_INDEX THEN
               UPDATE market_price_value
                  SET price = p_price
                WHERE market_price_id = p_price_id
                  AND price_code = v_price_code_array(i)
                  AND price_date = p_price_date
                  AND as_of_date = low_date;
         END;
      END LOOP;
   END put_market_price;
   ----------------------------------------------------------------------------------------------------
   -- import_lmp
   ----------------------------------------------------------------------------------------------------
   PROCEDURE import_lmp
   (
      p_market_type IN VARCHAR2
     ,p_monthly     IN NUMBER
     ,p_records     IN mex_pjm_lmp_dm2_obj_tbl
     ,p_status      OUT NUMBER
     ,p_message     OUT VARCHAR2
   ) IS

      v_idx           BINARY_INTEGER;
      v_last_pnode_id VARCHAR2(255) := 'foobar';
      v_market_type   VARCHAR2(32);

      v_mp_id_sep market_price.market_price_id%TYPE; --Energy Component
      v_mp_id_lmp market_price.market_price_id%TYPE; --Locational Marginal Price
      v_mp_id_mcc market_price.market_price_id%TYPE; --Marginal Congestion Component
      v_mp_id_mlc market_price.market_price_id%TYPE; --Marginal Loss Component

   BEGIN
      p_status := ga.success;

      IF upper(p_market_type) LIKE 'D%' THEN
         v_market_type := mm_pjm_util.g_dayahead;
      ELSE
         v_market_type := mm_pjm_util.g_realtime;
      END IF;
      logs.log_info('Begin Import');
      v_idx := p_records.first;
      WHILE p_records.exists(v_idx)
      LOOP
         IF v_last_pnode_id != p_records(v_idx).pnode_id THEN
            v_mp_id_sep := get_market_price_id(p_records(v_idx).pnode_id,
                                               v_market_type,
                                               g_energy_component);
            v_mp_id_lmp := get_market_price_id(p_records(v_idx).pnode_id,
                                               v_market_type,
                                               g_lmp);
            v_mp_id_mcc := get_market_price_id(p_records(v_idx).pnode_id,
                                               v_market_type,
                                               g_cong_component);
            v_mp_id_mlc := get_market_price_id(p_records(v_idx).pnode_id,
                                               v_market_type,
                                               g_loss_component);

            logs.log_debug('v_last_pnode_id=' || v_last_pnode_id ||
                           ' pnodeID=' || p_records(v_idx).pnode_id ||
                           ' v_mp_id_sep=' || v_mp_id_sep || ' v_mp_id_lmp=' ||
                           v_mp_id_lmp || ' v_mp_id_mcc=' || v_mp_id_mcc ||
                           ' v_mp_id_mlc=' || v_mp_id_mlc);

            v_last_pnode_id := p_records(v_idx).pnode_id;
         END IF;
         -- Eneryg Component
         IF v_mp_id_sep IS NOT NULL THEN
            put_market_price(p_monthly,
                             v_mp_id_sep,
                             p_records  (v_idx).datetime_beginning_ept,
                             p_records  (v_idx).system_energy_price);

         END IF;
         --Locational Marginal Price
         IF v_mp_id_lmp IS NOT NULL THEN
            put_market_price(p_monthly,
                             v_mp_id_lmp,
                             p_records  (v_idx).datetime_beginning_ept,
                             p_records  (v_idx).total_lmp);

         END IF;
         --Marginal Congestion Component
         IF v_mp_id_mcc IS NOT NULL THEN
            put_market_price(p_monthly,
                             v_mp_id_mcc,
                             p_records  (v_idx).datetime_beginning_ept,
                             p_records  (v_idx).congestion_price);
         END IF;
         --Marginal Loss Component
         IF v_mp_id_mlc IS NOT NULL THEN
            put_market_price(p_monthly,
                             v_mp_id_mlc,
                             p_records  (v_idx).datetime_beginning_ept,
                             p_records  (v_idx).marginal_loss_price);
         END IF;
         v_idx := p_records.next(v_idx);
      END LOOP;
      logs.log_info('End Import');
      IF p_status >= 0 THEN
         COMMIT;
      END IF;
   EXCEPTION
      WHEN OTHERS THEN
         p_status  := SQLCODE;
         p_message := 'MM_PJM_DM2.IMPORT_LMP: ' || ut.get_full_errm;
   END import_lmp;

   ----------------------------------------------------------------------------------------------------
   -- QUERY_LMP
   ----------------------------------------------------------------------------------------------------
   PROCEDURE query_lmp
   (
      p_market_type IN VARCHAR2
     ,p_monthly     IN NUMBER
     ,p_date        IN DATE
     ,p_status      OUT NUMBER
     ,p_message     OUT VARCHAR2
     ,p_logger      IN OUT mm_logger_adapter
   ) IS

      v_lmp_tbl   mex_pjm_lmp_dm2_obj_tbl;
      v_row_count NUMBER := 0;
      v_lines     NUMBER := 0;
      v_start_row NUMBER := 1;
      v_columns   NUMBER := 14;
   BEGIN

      p_status := ga.success;
      IF p_monthly = 1 THEN
         v_columns := 16; -- Monthly DA/RT contains 16 fields
      END IF;
      v_row_count := nvl(get_dictionary_value('Row Count',
                                              0,
                                              'MarketExchange',
                                              'PJM',
                                              'DataMiner2'),
                         0);

      v_lines := v_row_count + 1; --Establinsh base for first run
      WHILE v_row_count <= v_lines
      LOOP
         mex_pjm_dm2.fetch_lmp(p_date,
                               p_market_type,
                               p_monthly,
                               v_row_count,
                               v_start_row,
                               v_lmp_tbl,
                               p_status,
                               p_message,
                               p_logger);


         IF p_status = ga.success THEN
            IF v_lmp_tbl.count = 0 THEN
               p_message := p_market_type || ' Prices not found for ' ||
                            to_char(p_date, 'MM/DD/YYYY');
               logs.log_warn(p_message);
               EXIT;
            ELSE
               import_lmp(p_market_type,
                          p_monthly,
                          v_lmp_tbl,
                          p_status,
                          p_message);
               v_lines     := v_lmp_tbl.count / v_columns; --> lmp_tbl is devided by number of  columns
               v_start_row := v_start_row + v_lines;
               logs.log_info('Lines Imported =' || v_lines || '  Start Row=' ||
                             v_start_row);
            END IF;
         ELSE
            logs.log_error(p_message);
            EXIT;
         END IF;
      END LOOP;

   EXCEPTION
      WHEN OTHERS THEN
         p_message := ut.get_full_errm;
         p_status  := SQLCODE;
   END query_lmp;

   ----------------------------------------------------------------------------------------------------
   -- market_exchange
   ----------------------------------------------------------------------------------------------------
   PROCEDURE market_exchange
   (
      p_begin_date    IN DATE
     ,p_end_date      IN DATE
     ,p_exchange_type IN VARCHAR2
     ,p_log_type      IN NUMBER
     ,p_trace_on      IN NUMBER
     ,p_status        OUT NUMBER
     ,p_message       OUT VARCHAR2
   ) AS

      v_current_date DATE;
      v_market_type  VARCHAR2(2);
      v_monthly      NUMBER := 0;

      v_cred   mex_credentials;
      v_logger mm_logger_adapter;
   BEGIN
      IF upper(p_exchange_type) LIKE '%DAY%' THEN
         v_market_type := 'DA';
      ELSE
         v_market_type := 'RT';
      END IF;
      IF upper(p_exchange_type) LIKE '%MONTHLY%' THEN
         v_monthly := 1;
      END IF;

      mm_util.init_mex(ec.es_pjm,
                       'dataminer2',
                       'PJM:DM2: ' || p_exchange_type,
                       p_exchange_type,
                       p_log_type,
                       p_trace_on,
                       v_cred,
                       v_logger,
                       TRUE);
      mm_util.start_exchange(FALSE, v_logger);

      logs.set_process_target_parameter('BEGIN_DATE',
                                        to_char(p_begin_date, 'yyyy-mm-dd'));
      logs.set_process_target_parameter('END_DATE',
                                        to_char(p_end_date, 'yyyy-mm-dd'));

      v_current_date := trunc(p_begin_date);

      --LOOP OVER DATES
      LOOP
         query_lmp(v_market_type,
                   v_monthly,
                   v_current_date,
                   p_status,
                   p_message,
                   v_logger);

         EXIT WHEN v_current_date >= trunc(p_end_date);
         v_current_date := v_current_date + 1;
      END LOOP;

      mm_util.stop_exchange(v_logger, p_status, p_message, p_message);
   EXCEPTION
      WHEN OTHERS THEN
         p_message := ut.get_full_errm;
         p_status  := SQLCODE;
         mm_util.stop_exchange(v_logger, p_status, p_message, p_message);
   END market_exchange;
   ----------------------------------------------------------------------------------------------------
-- Initialization
----------------------------------------------------------------------------------------------------
BEGIN
   -- Initialization
   SELECT sc_id
     INTO g_pjm_sc_id
     FROM schedule_coordinator
    WHERE sc_name = 'PJM';
EXCEPTION
   WHEN OTHERS THEN
      g_pjm_sc_id := 0;
END mm_pjm_dm2;
/

