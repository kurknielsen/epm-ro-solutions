SET DEFINE OFF
prompt Market: ERCOT
prompt =================
prompt compiling ERCOT package specs
prompt =================

prompt MM_ERCOT_UTIL
@@MM_ERCOT_UTIL.sql
prompt MM_ERCOT_SETTLEMENT
@@MM_ERCOT_SETTLEMENT.sql
prompt MM_ERCOT_EXTRACT
@@MM_ERCOT_EXTRACT.sql
prompt MM_ERCOT_LMP
@@MM_ERCOT_LMP.sql
prompt MM_ERCOT
@@MM_ERCOT.sql
prompt MM_ERCOT_SHADOW_BILL
@@MM_ERCOT_SHADOW_BILL.sql

SET DEFINE ON