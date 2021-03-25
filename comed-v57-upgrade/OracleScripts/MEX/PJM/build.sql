SET DEFINE OFF

prompt =================
prompt compiling PJM package bodies
prompt =================

prompt MEX_PJM
@@MEX_PJM-body.sql
prompt MEX_PJM_EFTR
@@MEX_PJM_EFTR-body.sql
prompt MEX_PJM_ESCHED
@@MEX_PJM_ESCHED-body.sql
prompt MEX_PJM_SETTLEMENT
@@MEX_PJM_SETTLEMENT-body.sql
prompt MEX_PJM_SETTLEMENT_MSRS
@@MEX_PJM_SETTLEMENT_MSRS-body.sql
prompt MEX_PJM_EES
@@MEX_PJM_EES-body.sql
prompt MEX_PJM_EMKT
@@MEX_PJM_EMKT-body.sql
prompt MEX_PJM_LMP
@@MEX_PJM_LMP-body.sql
prompt MEX_PJM_OASIS
@@MEX_PJM_OASIS-body.sql
prompt MEX_PJM_ERPM
@@MEX_PJM_ERPM-body.sql

SET DEFINE ON
