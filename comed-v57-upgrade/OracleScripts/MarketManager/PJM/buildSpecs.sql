SET DEFINE OFF
prompt market:PJM

prompt =================
prompt compiling PJM package specs
prompt =================

prompt MM_PJM_UTIL
@@MM_PJM_UTIL.sql

prompt MM_PJM_REVENUE_REPORTS 
@@MM_PJM_REVENUE_REPORTS.sql

prompt PJM_VIEWS
@@PJM_VIEWS.sql

prompt DATE_CONST
@@DATE_CONST.sql

prompt MM_PJM_EFTR
@@MM_PJM_EFTR.sql
prompt MM_PJM_EMKT_UTIL
@@MM_PJM_EMKT_UTIL.sql
prompt MM_PJM_EMKT_GEN
@@MM_PJM_EMKT_GEN.sql
prompt MM_PJM_EMKT
@@MM_PJM_EMKT.sql
prompt MM_PJM_GEN_REPORTS
@@MM_PJM_GEN_REPORTS
prompt MM_PJM_EMTR
@@MM_PJM_EMTR.sql
prompt MM_PJM_ESCHED
@@MM_PJM_ESCHED.sql
prompt MM_PJM_LMP
@@MM_PJM_LMP.sql
prompt MM_PJM_OASIS
@@MM_PJM_OASIS.sql

prompt MM_PJM_SETTLEMENT
@@MM_PJM_SETTLEMENT.sql

prompt MM_PJM_SETTLEMENT_MSRS
@@MM_PJM_SETTLEMENT_MSRS.sql

prompt MM_PJM_EES
@@MM_PJM_EES.sql

prompt MM_PJM_ERPM
@@MM_PJM_ERPM.sql

prompt MM_PJM
@@MM_PJM.sql

prompt MM_PJM_SHADOW_BILL
@@MM_PJM_SHADOW_BILL.sql

prompt MM_PJM_SCHEDULED
@@MM_PJM_SCHEDULED.sql

prompt MM_PJM_FERC
@@MM_PJM_FERC.sql

prompt MM_PJM_POWERMETER
@@MM_PJM_POWERMETER.sql

SET DEFINE ON