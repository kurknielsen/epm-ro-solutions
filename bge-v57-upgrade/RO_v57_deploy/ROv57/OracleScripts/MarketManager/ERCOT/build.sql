SET DEFINE OFF
prompt Market: ERCOT
prompt =================
prompt compiling ERCOT package bodies
prompt =================

prompt MM_ERCOT_UTIL
@@MM_ERCOT_UTIL-body.sql
prompt MM_ERCOT_SETTLEMENT
@@MM_ERCOT_SETTLEMENT-body.sql
prompt MM_ERCOT_EXTRACT
@@MM_ERCOT_EXTRACT-body.sql
prompt MM_ERCOT_LMP
@@MM_ERCOT_LMP-body.sql
prompt MM_ERCOT
@@MM_ERCOT-body.sql
prompt MM_ERCOT_SHADOW_BILL
@@MM_ERCOT_SHADOW_BILL-body.sql

SET DEFINE ON
