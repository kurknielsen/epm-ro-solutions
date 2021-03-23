CREATE OR REPLACE PACKAGE MM_PJM_CE IS

   -- Purpose : Handle CapacityExchange interactions with PJM
   -- $Revision: 1.0 $

   g_pjm_erpm_namespace      CONSTANT VARCHAR2(64) := 'xmlns="http://erpm.pjm.com/rpm/xml"';
   g_pjm_ermp_namespace_name CONSTANT VARCHAR2(64) := 'http://erpm.pjm.com/rpm/xml';

   FUNCTION what_version RETURN VARCHAR;

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
   );

   PROCEDURE upload_file
   (
      p_clob    IN CLOB,
      p_status  OUT NUMBER,
      p_message IN OUT VARCHAR2
   );

   PROCEDURE post_content_to_pjm
   (
      p_content IN CLOB,
      p_status  OUT NUMBER,
      p_message IN OUT VARCHAR2
   );

   g_et_query_nspl             VARCHAR2(16) := 'Query NSPL';
   g_et_query_plc              VARCHAR2(16) := 'Query PLC';
   g_et_query_capacity_oblig   VARCHAR2(32) := 'Query Capacity Obligation';
   g_et_query_ucap             VARCHAR2(40) := 'Query Unforced Capacity';
   g_et_query_plc_scale_factor VARCHAR2(32) := 'Query PLC Scale Factor';
   g_et_query_short_names      VARCHAR2(32) := 'Query Contract Names';

   g_transaction_type    interchange_transaction.transaction_type%TYPE := 'Ancillary';
   g_schedule_group_name schedule_group.schedule_group_name%TYPE := 'EGS';
   g_plc_type            VARCHAR2(16) := 'PLC';
   g_ucap_type           VARCHAR2(16) := 'UCAP';

END MM_PJM_CE;
/

