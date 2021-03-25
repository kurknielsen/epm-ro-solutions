SET DEFINE OFF
prompt Market: PJM

prompt Creating PJM objects
@@PJM_Objects.sql
@@PJM_EMKT_Objects.sql
@@PJM_EES_Objects.sql

prompt =================
prompt compiling PJM package specs
prompt =================

prompt MEX_PJM
@@MEX_PJM.sql
prompt MEX_PJM_EFTR
@@MEX_PJM_EFTR.sql
prompt MEX_PJM_ESCHED
@@MEX_PJM_ESCHED.sql
prompt MEX_PJM_SETTLEMENT
@@MEX_PJM_SETTLEMENT.sql
prompt MEX_PJM_SETTLEMENT_MSRS
@@MEX_PJM_SETTLEMENT_MSRS.sql
prompt MEX_PJM_EES
@@MEX_PJM_EES.sql
prompt MEX_PJM_EMKT
@@MEX_PJM_EMKT.sql
prompt MEX_PJM_LMP
@@MEX_PJM_LMP.sql
prompt MEX_PJM_OASIS
@@MEX_PJM_OASIS.sql
prompt MEX_PJM_ERPM
@@MEX_PJM_ERPM.sql

SET DEFINE ON