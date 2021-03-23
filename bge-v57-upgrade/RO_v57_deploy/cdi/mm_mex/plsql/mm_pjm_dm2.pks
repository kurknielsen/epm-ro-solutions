CREATE OR REPLACE PACKAGE mm_pjm_dm2 AS
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
   FUNCTION what_version RETURN VARCHAR2;

   PROCEDURE import_lmp
   (
      p_market_type IN VARCHAR2
     ,p_monthly     IN NUMBER
     ,p_records     IN mex_pjm_lmp_dm2_obj_tbl
     ,p_status      OUT NUMBER
     ,p_message     OUT VARCHAR2
   );

   PROCEDURE query_lmp
   (
      p_market_type IN VARCHAR2
     ,p_monthly     IN NUMBER
     ,p_date        IN DATE
     ,p_status      OUT NUMBER
     ,p_message     OUT VARCHAR2
     ,p_logger      IN OUT mm_logger_adapter
   );

   PROCEDURE market_exchange
   (
      p_begin_date    IN DATE
     ,p_end_date      IN DATE
     ,p_exchange_type IN VARCHAR2
     ,p_log_type      IN NUMBER
     ,p_trace_on      IN NUMBER
     ,p_status        OUT NUMBER
     ,p_message       OUT VARCHAR2
   );

   g_et_day_ahead_lmp       VARCHAR2(20) := 'Query Day-ahead LMP';
   g_et_real_time_lmp       VARCHAR2(20) := 'Query Real-time LMP';
   g_et_day_ahead_lmp_month VARCHAR2(64) := 'Query Monthly Day-ahead LMP';
   g_et_real_time_lmp_month VARCHAR2(64) := 'Query Monthly Real-time LMP';

END mm_pjm_dm2;
/

