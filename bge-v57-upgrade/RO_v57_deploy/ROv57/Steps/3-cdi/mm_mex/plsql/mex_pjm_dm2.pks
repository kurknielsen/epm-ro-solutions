CREATE OR REPLACE PACKAGE mex_pjm_dm2 AS
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

   FUNCTION what_version RETURN VARCHAR2;

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
   );

   PROCEDURE parse_lmp
   (
      p_csv         IN CLOB
     ,p_market_type IN VARCHAR2
     ,p_monthly     IN VARCHAR2
     ,p_records     OUT mex_pjm_lmp_dm2_obj_tbl
     ,p_status      OUT NUMBER
     ,p_message     OUT VARCHAR2
   );

END mex_pjm_dm2;
/

