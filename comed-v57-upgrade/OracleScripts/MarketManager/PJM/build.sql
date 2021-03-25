SET DEFINE OFF
prompt market:PJM

prompt =================
prompt compiling PJM package bodies
prompt =================

prompt MM_PJM_UTIL
@@MM_PJM_UTIL-body.sql

prompt MM_PJM_REVENUE_REPORTS 
@@MM_PJM_REVENUE_REPORTS-body.sql


prompt MM_PJM_EFTR
@@MM_PJM_EFTR-body.sql
prompt MM_PJM_EMKT_UTIL
@@MM_PJM_EMKT_UTIL-body.sql
prompt MM_PJM_EMKT_GEN
@@MM_PJM_EMKT_GEN-body.sql
prompt MM_PJM_EMKT
@@MM_PJM_EMKT-body.sql
prompt MM_PJM_GEN_REPORTS
@@MM_PJM_GEN_REPORTS-body.sql
prompt MM_PJM_EMTR
@@MM_PJM_EMTR-body.sql
prompt MM_PJM_ESCHED
@@MM_PJM_ESCHED-body.sql
prompt MM_PJM_LMP
@@MM_PJM_LMP-body.sql
prompt MM_PJM_OASIS
@@MM_PJM_OASIS-body.sql

prompt MM_PJM_SETTLEMENT
@@MM_PJM_SETTLEMENT-body.sql

prompt MM_PJM_SETTLEMENT_MSRS
@@MM_PJM_SETTLEMENT_MSRS-body.sql

prompt MM_PJM_EES
@@MM_PJM_EES-body.sql

prompt MM_PJM_ERPM
@@MM_PJM_ERPM-body.sql

prompt MM_PJM
@@MM_PJM-body.sql

prompt MM_PJM_SHADOW_BILL
@@MM_PJM_SHADOW_BILL-body.sql

prompt MM_PJM_SCHEDULED
@@MM_PJM_SCHEDULED-body.sql

prompt MM_PJM_FERC
@@MM_PJM_FERC-body.sql

prompt MM_PJM_POWERMETER
@@MM_PJM_POWERMETER-body.sql

SET DEFINE ON


