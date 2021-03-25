prompt Market: ERCOT

SET DEFINE OFF

prompt =================
prompt prompt compiling ERCOT package bodies
prompt =================

prompt MEX_ERCOT
@@MEX_ERCOT-body.sql
prompt MEX_ERCOT_LMP
@@MEX_ERCOT_LMP-body.sql
prompt MEX_ERCOT_EXTRACT
@@MEX_ERCOT_EXTRACT-body.sql
prompt MEX_ERCOT_SETTLEMENT
@@MEX_ERCOT_SETTLEMENT-body.sql

SET DEFINE ON