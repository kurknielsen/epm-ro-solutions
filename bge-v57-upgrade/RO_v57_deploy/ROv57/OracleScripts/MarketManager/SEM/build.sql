SET DEFINE OFF      
prompt Market: SEM
prompt =================
prompt compiling SEM package bodies
prompt =================

prompt MM_SEM_UTIL
@@MM_SEM_UTIL-body.sql
		
prompt MM_SEM_OFFER.sql
@@MM_SEM_OFFER-body.sql

prompt MM_SEM_OFFER_UTIL
@@MM_SEM_OFFER_UTIL-body.sql

prompt MM_SEM
@@MM_SEM-body.sql

prompt MM_SEM_GEN_OFFER
@@MM_SEM_GEN_OFFER-body.sql

prompt MM_SEM_IC_OFFER
@@MM_SEM_IC_OFFER-body.sql

prompt MM_SEM_LOAD_OFFER
@@MM_SEM_LOAD_OFFER-body.sql

prompt MM_SEM_REPORTS
@@MM_SEM_REPORTS-body.sql

prompt MM_SEM_SHADOW_BILL
@@MM_SEM_SHADOW_BILL-body.sql

prompt MM_SEM_SETTLEMENT_PARSE
@@MM_SEM_SETTLEMENT_PARSE-body.sql

prompt MM_SEM_SETTLEMENT
@@MM_SEM_SETTLEMENT-body.sql

prompt MM_SEM_SRA_OFFER
@@MM_SEM_SRA_OFFER-body.sql

prompt SEM_REPORTS	
@@SEM_REPORTS-body.sql

prompt SEM_REPORTS_UTIL
@@SEM_REPORTS_UTIL-body.sql

prompt MM_SEM_CREDIT_SHADOW
@@MM_SEM_CREDIT_SHADOW-body.sql

prompt SEM_CREDIT_REPORTS
@@SEM_CREDIT_REPORTS-body.sql

prompt MM_SEM_CFD_UTIL.sql
@@MM_SEM_CFD_UTIL-body.sql

prompt MM_SEM_CFD_CALC.sql
@@MM_SEM_CFD_CALC-body.sql

prompt MM_SEM_CFD_UI.sql
@@MM_SEM_CFD_UI-body.sql

prompt MM_SEM_CFD_CREDIT.sql
@@MM_SEM_CFD_CREDIT-body.sql

prompt MM_SEM_CFD_REPORTS.sql
@@MM_SEM_CFD_REPORTS-body.sql

prompt MM_SEM_CFD_ADJUSTMENT.sql
@@MM_SEM_CFD_ADJUSTMENT-body.sql

prompt MM_SEM_CFD_INV.sql
@@MM_SEM_CFD_INV-body.sql

prompt MM_SEM_CFD_ALERTS.sql
@@MM_SEM_CFD_ALERTS-body.sql

prompt MM_SEM_CFD_DIFF_PMTS.sql
@@MM_SEM_CFD_DIFF_PMTS-body.sql

prompt SEM_CFD_SCHEDULE_FILL.sql
@@SEM_CFD_SCHEDULE_FILL-body.sql

prompt SEM_SETTLEMENT_COMP.sql
@@SEM_SETTLEMENT_COMP-body.sql

prompt MM_SEM_TLAF.sql
@@MM_SEM_TLAF-body.sql

prompt MM_SEM_PIR_IMPORT.sql
@@MM_SEM_PIR_IMPORT-body.sql

prompt MM_SEM_PIR_IMPORT_UI.sql
@@MM_SEM_PIR_IMPORT_UI-body.sql

prompt MM_SEM_SETTLEMENT_CALENDAR.sql
@@MM_SEM_SETTLEMENT_CALENDAR-body.sql

SET DEFINE ON  
