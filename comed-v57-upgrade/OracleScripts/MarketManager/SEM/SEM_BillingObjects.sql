DECLARE
   p_STATUS NUMBER;
   v_CHILD_OBJECT_ID NUMBER(9);
BEGIN
<<L0>>
DECLARE
   v_PARENT_OBJECT_ID NUMBER(9) := 0;
   v_OBJECT_ID NUMBER(9) := 0;
BEGIN
 
   -------------------------------------
   --   Billing
   -------------------------------------
      SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'Billing', 'Module', 'Billing', '', 0, 0, '-3~0^-2~0', v_OBJECT_ID);
      -------------------------------------
      --   Billing.Summary
      -------------------------------------
      <<L1>>
      DECLARE
         v_PARENT_OBJECT_ID NUMBER(9) := L0.v_OBJECT_ID;
         v_OBJECT_ID NUMBER(9);
      BEGIN
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'Billing.Summary', 'System View', 'Billing.Summary', '', 0, 0, '-3~0^-2~0^801~com.newenergyassoc.ro.mightyReport.MightyReportPanel', v_OBJECT_ID);
         <<L2>>
         DECLARE
            v_PARENT_OBJECT_ID NUMBER(9) := L1.v_OBJECT_ID;
            v_OBJECT_ID NUMBER(9);
         BEGIN
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'BILLING_SUMMARY', 'Report', 'Billing Summary Report', '', 0, 0, '-3~0^-2~0^401~BSJ.BILLING_SUMMARY;STATEMENT_DATE=BEGIN_DATE;STATEMENT_END_DATE=END_DATE;SHOW_CHARGE_AMOUNT=(value(DISPLAY_OPTIONS) and 1);SHOW_BILL_AMOUNT=(value(DISPLAY_OPTIONS) and 2) >> 1^402~0^403~Normal Grid^405~-1^406~0', v_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'BILLING_SUMMARY_Grid', 'Grid', 'Billing Summary Grid', '', 0, 0, '-3~0^-2~0^-1~Billing.SummaryGrid^305~0^308~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'INTERVAL', 'Report Filter', 'Interval', '', 1, 0, '-3~0^-2~0^501~s (Special List)^504~SP.GET_SYSTEM_LABEL_VALUES;MODEL_ID;"Billing;"Interval;"Values;"?^505~2 (Checked Box)^508~0^514~0^515~0^516~Titled Border^517~Billing Entities^518~ENTITY_ID^519~1', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'ENTITY_ID', 'Report Filter', 'Entities', '', 2, 0, '-3~0^-2~0^501~s (Special List)^504~BSJ.BILL_ENTITY_NAMES_BY_INTERVAL;CALLING_MODULE;MODEL_ID;INTERVAL^508~1^514~0^515~0^516~No Border^517~Billing Entities^519~1', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SHOW_ENTITY_DETAIL', 'Report Filter', 'Show Billing Entity', '', 3, 0, '501~k (Checkbox)^505~0 (No Checkbox)^506~1 (Checked)^508~0^514~0^515~0^517~Billing Entities', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'PRODUCT_ID', 'Report Filter', 'Product', '', 4, 0, '-3~0^-2~0^501~s (Special List)^504~BSJ.PRODUCT_NAMES;STATEMENT_TYPE;BEGIN_DATE;END_DATE;AS_OF_DATE^505~2 (Checked Box)^508~0^514~0^515~0^519~1^520~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'COMPONENT_ID', 'Report Filter', 'Component', '', 5, 0, '-3~0^-2~0^501~s (Special List)^504~BSJ.COMPONENT_NAMES;STATEMENT_TYPE;BEGIN_DATE;END_DATE;AS_OF_DATE^505~2 (Checked Box)^508~0^514~0^515~0^519~1^520~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'STATEMENT_STATE', 'Report Filter', 'Statement State', '', 6, 0, '-3~0^-2~1^-1~STATEMENT_STATE^508~0^514~0^515~0^519~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'DISPLAY_OPTIONS', 'Report Filter', 'Display Options', '', 9, 0, '-3~0^-2~0^501~r (Radio Button)^502~#1;Show Charge Amount|#2;Show Bill Amount|#3;Show Charge and Bill Amounts^508~0^514~0^515~0^519~0', v_CHILD_OBJECT_ID);
         END;
          
      END;
       
      -------------------------------------
      --   SEM.InvoiceData
      -------------------------------------
      <<L3>>
      DECLARE
         v_PARENT_OBJECT_ID NUMBER(9) := L0.v_OBJECT_ID;
         v_OBJECT_ID NUMBER(9);
      BEGIN
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'SEM.InvoiceData', 'System View', 'SEM Invoice Details', '', 0, 0, '-3~0^-2~0', v_OBJECT_ID);
         <<L4>>
         DECLARE
            v_PARENT_OBJECT_ID NUMBER(9) := L3.v_OBJECT_ID;
            v_OBJECT_ID NUMBER(9);
         BEGIN
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'SEMInvoiceData', 'Report', 'SEM Invoice Details', '', 0, 0, '-3~0^-2~0^401~SEM_REPORTS.GET_SEM_INVOICE_INFO^402~1^403~Lazy Master/Detail Grids^404~SEM_REPORTS.GET_SEM_INVOICE_JOBS^406~0^407~INVOICE_ID^409~Vertical', v_OBJECT_ID);
            <<L5>>
            DECLARE
               v_PARENT_OBJECT_ID NUMBER(9) := L4.v_OBJECT_ID;
               v_OBJECT_ID NUMBER(9);
            BEGIN
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'SEMInvoiceData_Grid_DETAIL', 'Grid', 'Job Details', '', 0, 0, '-3~0^-2~0^305~0^308~0^311~0', v_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SETTLEMENT_DAY', 'Column', '', '', 0, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^24~1^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'JOB_ID', 'Column', '', '', 1, 0, '', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'JOB_NAME', 'Column', '', '', 2, 0, '', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'JOB_NUMBER', 'Column', '', '', 3, 0, '', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'JOB_VERSION', 'Column', '', '', 4, 0, '', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'JOB_STATE', 'Column', '', '', 5, 0, '', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'JOB_STATUS', 'Column', '', '', 6, 0, '', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRUE_UP_BASED_ON', 'Column', '', '', 7, 0, '', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'STATEMENT_ID', 'Column', '', '', 8, 0, '', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'GLOBAL_PARTICIPANT_NAME', 'Column', '', '', 9, 0, '', v_CHILD_OBJECT_ID);
            END;
             
            <<L6>>
            DECLARE
               v_PARENT_OBJECT_ID NUMBER(9) := L4.v_OBJECT_ID;
               v_OBJECT_ID NUMBER(9);
            BEGIN
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'SEMInvoiceData_Grid_MASTER', 'Grid', 'Invoice Info', '', 0, 0, '-3~0^-2~0^305~0^308~0^311~0', v_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'INVOICE_ID', 'Column', '', '', 0, 1, '-3~0^-2~0^2~0^7~0^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'FIELD_NAME', 'Column', '', '', 1, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^24~1^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'FIELD_VAL', 'Column', '', '', 2, 0, '', v_CHILD_OBJECT_ID);
            END;
             
         END;
          
      END;
       
      -------------------------------------
      --   SEM.ParticipantInfo
      -------------------------------------
      <<L7>>
      DECLARE
         v_PARENT_OBJECT_ID NUMBER(9) := L0.v_OBJECT_ID;
         v_OBJECT_ID NUMBER(9);
      BEGIN
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'SEM.ParticipantInfo', 'System View', 'Sem.Participantinfo', '', 0, 0, '-3~0^-2~0', v_OBJECT_ID);
         <<L8>>
         DECLARE
            v_PARENT_OBJECT_ID NUMBER(9) := L7.v_OBJECT_ID;
            v_OBJECT_ID NUMBER(9);
         BEGIN
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'PIR', 'Report', 'Participant Info Report', '', 0, 0, '-3~0^-2~0^401~SEM_REPORTS.GET_PIR_REPORT^402~0^406~0', v_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'ENTITY_ID', 'Report Filter', 'Billing Entity', '', 0, 0, '-3~0^-2~0^501~s (Special List)^504~BSJ.BILL_ENTITY_NAMES;CALLING_MODULE;MODEL_ID^508~0^514~0^515~0^516~Titled Border^518~RESOURCE_NAME^519~0^520~0^521~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'RESOURCE_NAME', 'Report Filter', 'Resource', '', 1, 0, '501~s (Special List)^504~SEM_REPORTS.PIR_RESOURCE_NAMES;ENTITY_ID', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'VARIABLE_TYPE', 'Report Filter', 'Variable Type', '', 2, 0, '501~s (Special List)^504~SEM_REPORTS.PIR_VARIABLE_TYPES', v_CHILD_OBJECT_ID);
         END;
          
      END;
       
      -------------------------------------
      --   SEM.ReallocationAgreements
      -------------------------------------
      <<L9>>
      DECLARE
         v_PARENT_OBJECT_ID NUMBER(9) := L0.v_OBJECT_ID;
         v_OBJECT_ID NUMBER(9);
      BEGIN
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'SEM.ReallocationAgreements', 'System View', 'Sem.Reallocationagreements', '', 0, 0, '-3~0^-2~0', v_OBJECT_ID);
         <<L10>>
         DECLARE
            v_PARENT_OBJECT_ID NUMBER(9) := L9.v_OBJECT_ID;
            v_OBJECT_ID NUMBER(9);
         BEGIN
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'RAR', 'Report', 'Reallocation Agreements Report', '', 0, 0, '-3~0^-2~0^401~SEM_REPORTS.GET_RAR_REPORT^402~0^406~0', v_OBJECT_ID);
            <<L11>>
            DECLARE
               v_PARENT_OBJECT_ID NUMBER(9) := L10.v_OBJECT_ID;
               v_OBJECT_ID NUMBER(9);
            BEGIN
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'RAR_Grid', 'Grid', 'Rar Grid', '', 0, 0, '-3~0^-2~0^305~0^308~0^311~0', v_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'BEGIN_DATE', 'Column', 'Invoice Period Begin', '', 0, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'END_DATE', 'Column', 'Invoice Period End', '', 1, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'PSE_NAME', 'Column', 'Counter-Party', '', 2, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'AGREEMENT_NAME', 'Column', '', '', 3, 0, '', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'CHARGE_DATE', 'Column', '', '', 4, 0, '-3~0^-2~0^1~d (Date Picker)^2~0^3~yyyy-MM-dd KK:mm^7~0^13~0^20~1^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'UNIT', 'Column', '', '', 5, 0, '', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SRA_AMOUNT', 'Column', '', '', 6, 0, '', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'IS_VALID', 'Column', '', '', 7, 0, '', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'REASON_INVALID', 'Column', '', '', 8, 0, '-3~0^-2~0^1~b (Big Text Edit)^2~0^7~0^13~0^20~1^23~XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX^24~0^31~0', v_CHILD_OBJECT_ID);
            END;
             
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'ENTITY_ID', 'Report Filter', 'Billing Entity', '', 0, 0, '-3~0^-2~0^501~s (Special List)^504~BSJ.BILL_ENTITY_NAMES;CALLING_MODULE;MODEL_ID^508~0^514~0^515~0^516~Titled Border^518~COUNTERPARTY_ID,AGREEMENT_NAME^519~0^520~0^521~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'COUNTERPARTY_ID', 'Report Filter', 'Counter-Party', '', 1, 0, '501~s (Special List)^504~SEM_REPORTS.RAR_COUNTERPARTY_IDS^518~AGREEMENT_NAME', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'AGREEMENT_NAME', 'Report Filter', 'Agreement Name', '', 2, 0, '501~s (Special List)^504~SEM_REPORTS.RAR_AGREEMENT_NAMES', v_CHILD_OBJECT_ID);
         END;
          
      END;
       
      -------------------------------------
      --   Billing.Comparison
      -------------------------------------
      <<L12>>
      DECLARE
         v_PARENT_OBJECT_ID NUMBER(9) := L0.v_OBJECT_ID;
         v_OBJECT_ID NUMBER(9);
      BEGIN
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'Billing.Comparison', 'System View', 'Billing.Comparison', '', 1, 0, '-3~0^-2~0^801~com.newenergyassoc.ro.mightyReport.MightyReportPanel', v_OBJECT_ID);
         <<L13>>
         DECLARE
            v_PARENT_OBJECT_ID NUMBER(9) := L12.v_OBJECT_ID;
            v_OBJECT_ID NUMBER(9);
         BEGIN
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'BILLING_COMPARISON', 'Report', 'Billing Comparison', '', 0, 0, '-3~0^-2~0^401~BSJ.BILLING_COMPARISON;STATEMENT_DATE=BEGIN_DATE;STATEMENT_END_DATE=END_DATE;STATEMENT_TYPE1=STATEMENT_TYPE1_ID;STATEMENT_TYPE2=STATEMENT_TYPE2_ID;SHOW_CHARGE_AMOUNT=(value(DISPLAY_OPTIONS) and 1);SHOW_BILL_AMOUNT=(value(DISPLAY_OPTIONS) and 2) >> 1^402~0^403~Normal Grid^405~0^406~0', v_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'BILLING_COMPARISON_Grid', 'Grid', 'Billing Comparison Grid', '', 0, 0, '-3~0^-2~0^-1~Billing.ComparisonGrid^305~0^308~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'INTERVAL', 'Report Filter', 'Interval', '', 0, 0, '-3~0^-2~0^501~s (Special List)^504~SP.GET_SYSTEM_LABEL_VALUES;MODEL_ID;"Billing;"Interval;"Values;"?^505~2 (Checked Box)^508~0^514~0^515~0^517~Billing Entities^518~ENTITY_ID^519~1', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'ENTITY_ID', 'Report Filter', 'Billing Entities', '', 1, 0, '-3~0^-2~0^501~s (Special List)^504~BSJ.BILL_ENTITY_NAMES_BY_INTERVAL;CALLING_MODULE;MODEL_ID;INTERVAL^508~1^510~4^514~0^515~0^516~No Border^517~Billing Entities^519~1', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SHOW_ENTITY_DETAIL', 'Report Filter', 'Show Billing Entities', '', 2, 0, '-3~0^-2~0^501~k (Checkbox)^506~1 (Checked)^508~0^514~0^515~0^516~No Border^517~Billing Entities', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'PRODUCT_ID', 'Report Filter', 'Product', '', 3, 0, '-3~0^-2~0^501~s (Special List)^504~BSJ.PRODUCT_NAMES;STATEMENT_TYPE;BEGIN_DATE;END_DATE;AS_OF_DATE^505~2 (Checked Box)^508~0^514~0^515~0^519~1^520~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'COMPONENT_ID', 'Report Filter', 'Component', '', 4, 0, '-3~0^-2~0^501~s (Special List)^504~BSJ.COMPONENT_NAMES;STATEMENT_TYPE;BEGIN_DATE;END_DATE;AS_OF_DATE^505~2 (Checked Box)^508~0^514~0^515~0^519~1^520~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'STATEMENT_TYPE1_ID', 'Report Filter', 'Comparison From Schedule Type', '', 5, 0, '-3~0^-2~0^501~s (Special List)^504~BSJ.GET_STATEMENT_TYPES^508~0^514~0^515~0^516~No Border^517~Comparison States^519~1', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'STATEMENT_STATE1', 'Report Filter', 'Comparison State', '', 6, 0, '-3~0^-2~0^501~r (Radio Button)^502~#1;Internal|#2;External^508~0^514~0^515~0^516~No Border^517~Comparison States^519~1', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'STATEMENT_TYPE2_ID', 'Report Filter', 'Comparison To Schedule Type', '', 7, 0, '-3~0^-2~0^501~s (Special List)^504~BSJ.GET_STATEMENT_TYPES^508~0^514~0^515~0^516~No Border^517~Comparison States^519~1', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'STATEMENT_STATE2', 'Report Filter', 'Comparison State', '', 8, 0, '-3~0^-2~0^501~r (Radio Button)^502~#1;Internal|#2;External^508~0^514~0^515~0^516~No Border^517~Comparison States^519~1', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'DISPLAY_OPTIONS', 'Report Filter', 'Display Options', '', 11, 0, '501~r (Radio Button)^502~#1;Show Charge Amount|#2;Show Bill Amount|#3;Show Charge and Bill Amounts^515~0', v_CHILD_OBJECT_ID);
         END;
          
      END;
       
      -------------------------------------
      --   Billing.Invoice
      -------------------------------------
      <<L14>>
      DECLARE
         v_PARENT_OBJECT_ID NUMBER(9) := L0.v_OBJECT_ID;
         v_OBJECT_ID NUMBER(9);
      BEGIN
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'Billing.Invoice', 'System View', 'Billing.Invoice', '', 2, 0, '-3~0^-2~0^801~com.newenergyassoc.ro.mightyReport.MightyReportPanel', v_OBJECT_ID);
         <<L15>>
         DECLARE
            v_PARENT_OBJECT_ID NUMBER(9) := L14.v_OBJECT_ID;
            v_OBJECT_ID NUMBER(9);
         BEGIN
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'BILLING_INVOICE_REPORT', 'Report', 'Billing Invoice Report', '', 0, 0, '-3~0^-2~0^401~BSJ.GET_INVOICE_REPORT_RECORDS^402~0^403~Billing Invoice^406~0^411~ENTITY_ID^412~BSJ.INVOICE_ENTITY_NAMES', v_OBJECT_ID);
            <<L16>>
            DECLARE
               v_PARENT_OBJECT_ID NUMBER(9) := L15.v_OBJECT_ID;
               v_OBJECT_ID NUMBER(9);
            BEGIN
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'BILLING_INVOICE_REPORT_Grid', 'Grid', 'Billing Invoice Report Grid', '', 0, 0, '-3~0^-2~0^305~0^308~0', v_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'INVOICE_MONTH', 'Column', '', '', 0, 0, '', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'INVOICE_DATE', 'Column', '', '', 1, 0, '', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'INVOICE_NUMBER', 'Column', '', '', 2, 0, '', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'INVOICE_SUB_LEDGER_NUMBER', 'Column', '', '', 3, 0, '', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'BILLING_CONTACT', 'Column', '', '', 4, 0, '', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'BILLING_PHONE', 'Column', '', '', 5, 0, '', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'BILLING_FAX', 'Column', '', '', 6, 0, '', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'BILLING_STREET', 'Column', '', '', 7, 0, '', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'BILLING_CITY', 'Column', '', '', 8, 0, '', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'BILLING_STATE_CODE', 'Column', '', '', 9, 0, '', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'BILLING_POSTAL_CODE', 'Column', '', '', 10, 0, '', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'BILLING_COUNTRY_CODE', 'Column', '', '', 11, 0, '', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'INVOICE_TERMS', 'Column', '', '', 12, 0, '', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'INVOICE_PRIMARY_CONTACT', 'Column', '', '', 13, 0, '', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'INVOICE_PRIMARY_PHONE', 'Column', '', '', 14, 0, '', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'INVOICE_SECONDARY_CONTACT', 'Column', '', '', 15, 0, '', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'INVOICE_SECONDARY_PHONE', 'Column', '', '', 16, 0, '', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'PAY_CHECK_CONTACT', 'Column', '', '', 17, 0, '', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'PAY_CHECK_STREET', 'Column', '', '', 18, 0, '', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'PAY_CHECK_CITY', 'Column', '', '', 19, 0, '', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'PAY_CHECK_STATE_CODE', 'Column', '', '', 20, 0, '', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'PAY_CHECK_POSTAL_CODE', 'Column', '', '', 21, 0, '', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'PAY_CHECK_COUNTRY_CODE', 'Column', '', '', 22, 0, '', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'PAY_ELECTRONIC_DEBIT_NAME', 'Column', '', '', 23, 0, '', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'PAY_ELECTRONIC_DEBIT_NBR', 'Column', '', '', 24, 0, '', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'PAY_ELECTRONIC_CREDIT_NAME', 'Column', '', '', 25, 0, '', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'PAY_ELECTRONIC_CREDIT_NBR', 'Column', '', '', 26, 0, '', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'INVOICE_STATUS', 'Column', '', '', 27, 0, '', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'PAYMENT_DUE_DATE', 'Column', '', '', 28, 0, '', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'PAYMENT_DUE_DATE_DT', 'Column', '', '', 29, 0, '', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'LINE_ITEM_NAME', 'Column', '', '', 30, 0, '', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'LINE_ITEM_TYPE', 'Column', '', '', 31, 0, '', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'LINE_ITEM_GROUP_ORDER', 'Column', '', '', 32, 0, '', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'INVOICE_GROUP_NAME', 'Column', '', '', 33, 0, '', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'INVOICE_GROUP_ORDER', 'Column', '', '', 34, 0, '', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'LINE_ITEM_QUANTITY', 'Column', '', '', 35, 0, '', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'LINE_ITEM_RATE', 'Column', '', '', 36, 0, '', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'LINE_ITEM_AMOUNT', 'Column', '', '', 37, 0, '', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'EXCLUDE_FROM_INVOICE_TOTAL', 'Column', '', '', 38, 0, '', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SHOW_TITLE_ON_INVOICE', 'Column', '', '', 39, 0, '', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SHOW_SUBTOTAL_ON_INVOICE', 'Column', '', '', 40, 0, '', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'INVOICE_GROUP_DISPLAY_ORDER', 'Column', '', '', 41, 0, '', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'APPROVED_BY', 'Column', '', '', 42, 0, '', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'APPROVED_WHEN', 'Column', '', '', 43, 0, '', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'APPROVED_WHEN_DT', 'Column', '', '', 44, 0, '', v_CHILD_OBJECT_ID);
            END;
             
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'ENTITY_ID', 'Report Filter', 'Billing Entity', '', 0, 0, '-3~0^-2~1^-1~BILLING_ENTITY_ID^508~0^514~0^515~0^519~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'INVOICE_DATE', 'Report Filter', 'Invoice Date', '', 1, 0, '-2~1^-1~INVOICE_DATE', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'INVOICE_CATEGORY', 'Report Filter', 'Invoice Category', '', 2, 0, '-2~1^-1~INVOICE_CATEGORY', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'STATEMENT_STATE', 'Report Filter', 'Statement State', '', 3, 0, '-3~0^-2~1^-1~STATEMENT_STATE^508~0^514~0^515~0', v_CHILD_OBJECT_ID);
            <<L17>>
            DECLARE
               v_PARENT_OBJECT_ID NUMBER(9) := L15.v_OBJECT_ID;
               v_OBJECT_ID NUMBER(9);
            BEGIN
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'EDIT_LINE_ITEMS', 'Report Filter', 'Edit Line Items...', '', 4, 0, '-3~0^-2~0^501~b (Button)^508~0^514~0^515~0', v_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'EDIT_LINE_ITEMS', 'Action', 'Edit Line Items...', '', 0, 0, '1006~2^1007~Billing.InvoiceLineItems', v_CHILD_OBJECT_ID);
            END;
             
            <<L18>>
            DECLARE
               v_PARENT_OBJECT_ID NUMBER(9) := L15.v_OBJECT_ID;
               v_OBJECT_ID NUMBER(9);
            BEGIN
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'SEM_DETAILS', 'Report Filter', 'SEM Details...', '', 5, 0, '-3~0^-2~0^501~b (Button)^508~0^514~0^515~0^519~0^520~0^521~0', v_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'details', 'Action', 'SEM Details', '', 0, 0, '-3~0^-2~0^1006~2^1007~SEM.InvoiceData', v_CHILD_OBJECT_ID);
            END;
             
         END;
          
      END;
       
      -------------------------------------
      --   Billing.InvoiceValidation
      -------------------------------------
      <<L19>>
      DECLARE
         v_PARENT_OBJECT_ID NUMBER(9) := L0.v_OBJECT_ID;
         v_OBJECT_ID NUMBER(9);
      BEGIN
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'Billing.InvoiceValidation', 'System View', 'Billing.InvoiceValidation', '', 3, 0, '-3~0^-2~0^801~com.newenergyassoc.ro.mightyReport.MightyReportPanel', v_OBJECT_ID);
         <<L20>>
         DECLARE
            v_PARENT_OBJECT_ID NUMBER(9) := L19.v_OBJECT_ID;
            v_OBJECT_ID NUMBER(9);
         BEGIN
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'INVOICE_VALIDATION', 'Report', 'Invoice Validation', '', 0, 0, '-3~0^-2~0^401~BSJ.GET_INVOICE_VALIDATION^402~0^403~Normal Grid^405~0^406~0', v_OBJECT_ID);
            <<L21>>
            DECLARE
               v_PARENT_OBJECT_ID NUMBER(9) := L20.v_OBJECT_ID;
               v_OBJECT_ID NUMBER(9);
            BEGIN
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'INVOICE_VALIDATION_Grid', 'Grid', 'Invoice Validation Grid', '', 0, 0, '-3~0^-2~0^305~0^308~0^309~0', v_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'BILLING_CHARGES', 'Action', 'Statement Details...', '', 0, 0, '-3~0^-2~0^1005~ROW_SELECTED > 0^1006~2^1007~Billing.SummaryBillingCharges;ORIGINAL_DATE=INVOICE_BEGIN_DATE;ORIGINAL_END_DATE=INVOICE_END_DATE;STATEMENT_INTERVAL=ENTITY_INTERVAL;SHOW_INTERVAL=1;SHOW_ENTITY_DETAIL=1;SHOW_PRODUCT_ID=1;SHOW_COMPONENT_ID=1;SHOW_CHARGE_AMOUNT=(value(DISPLAY_OPTION) =`1 [2,4]) or (value(DISPLAY_OPTION) = 1 and DEFAULT_DISPLAY="CHARGE");SHOW_BILL_AMOUNT=(value(DISPLAY_OPTION) =`1 [3,4]) or (value(DISPLAY_OPTION) = 1 and DEFAULT_DISPLAY="BILL");PRODUCTS_COMPONENTS=PRODUCT_COMPONENT_PAIRS', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'LINE_ITEM_NAME', 'Column', '', '', 0, 0, '', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'LINE_ITEM_TYPE', 'Column', '', '', 1, 0, '', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'LINE_ITEM_DEFAULT_AMOUNT_DISP', 'Column', 'Invoice Amount', '', 2, 0, '-3~0^-2~0^2~0^3~Currency^4~0^7~0^9~0^11~7^12~0^13~1^14~2^15~0^20~0^22~0^24~0^25~if ( value(DISPLAY_OPTION) = 1, if (null(LINE_ITEM_DEFAULT_AMOUNT),"",LINE_ITEM_DEFAULT_AMOUNT), null())^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'LINE_ITEM_AMOUNT_DISP', 'Column', 'Invoice Charge Amount', '', 3, 0, '-3~0^-2~0^2~0^3~Currency^4~0^7~0^9~0^11~7^12~0^13~1^14~2^15~0^20~0^22~0^24~0^25~if ( value(DISPLAY_OPTION) =`1 [2,4], if (null(LINE_ITEM_AMOUNT),"",LINE_ITEM_AMOUNT), null())^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'LINE_ITEM_BILL_AMOUNT_DISP', 'Column', 'Invoice Bill Amount', '', 4, 0, '-3~0^-2~0^2~0^3~Currency^4~0^7~0^9~0^11~7^12~0^13~1^14~2^15~0^20~0^22~0^24~0^25~if ( value(DISPLAY_OPTION) =`1 [3,4], if (null(LINE_ITEM_BILL_AMOUNT),"",LINE_ITEM_BILL_AMOUNT), null())^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'DEFAULT_DISPLAY', 'Column', '', '', 5, 1, '-3~0^-2~0^2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'STATEMENT_TYPE', 'Column', '', '', 6, 1, '-3~0^-2~0^2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'STATEMENT_TYPE_NAME', 'Column', '', '', 7, 1, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'STATEMENT_STATE', 'Column', '', '', 8, 1, '-3~0^-2~0^2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'INVOICE_BEGIN_DATE', 'Column', '', '', 9, 1, '-3~0^-2~0^2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'INVOICE_END_DATE', 'Column', '', '', 10, 1, '-3~0^-2~0^2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'ENTITY_ID', 'Column', '', '', 11, 1, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'ENTITY_INTERVAL', 'Column', '', '', 12, 1, '-3~0^-2~0^2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'STATEMENT_DEFAULT_AMOUNT_DISP', 'Column', 'Statement Amount', '', 13, 0, '-3~0^-2~0^2~0^3~Currency^4~0^7~0^9~0^11~7^12~0^13~1^14~2^15~0^20~0^22~0^24~0^25~if ( value(DISPLAY_OPTION) = 1, if (null(STATEMENT_DEFAULT_AMOUNT),"",STATEMENT_DEFAULT_AMOUNT), null())^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'STATEMENT_CHARGE_AMOUNT_DISP', 'Column', 'Statement Charge Amount', '', 14, 0, '-3~0^-2~0^2~0^3~Currency^4~0^7~0^9~0^11~7^12~0^13~1^14~2^15~0^20~0^22~0^24~0^25~if ( value(DISPLAY_OPTION) =`1 [2,4], if (null(STATEMENT_CHARGE_AMOUNT),"",STATEMENT_CHARGE_AMOUNT), null())^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'STATEMENT_BILL_AMOUNT_DISP', 'Column', 'Statement Bill Amount', '', 15, 0, '-3~0^-2~0^2~0^3~Currency^4~0^7~0^9~0^11~7^12~0^13~1^14~2^15~0^20~0^22~0^24~0^25~if ( value(DISPLAY_OPTION) =`1 [3,4], if (null(STATEMENT_BILL_AMOUNT),"",STATEMENT_BILL_AMOUNT), null())^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'IN_DISPUTE', 'Column', '', '', 16, 0, '1~k (Checkbox)^2~0^4~0^7~0^9~0^11~0^12~4^13~0^14~0^15~0^20~1^22~0^24~0^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'PRODUCT_COMPONENT_PAIRS', 'Column', '', '', 17, 1, '-3~0^-2~0^2~0^4~0^7~0^9~0^11~9^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'DEFAULT_DIFFERENCE', 'Column', 'Difference', '', 18, 0, '-3~0^-2~0^2~0^3~Currency^4~0^7~0^9~0^11~7^12~0^13~1^14~2^15~0^20~0^22~0^24~0^25~if ( value(DISPLAY_OPTION) = 1, LINE_ITEM_DEFAULT_AMOUNT - STATEMENT_DEFAULT_AMOUNT, null())^26~0^28~BILLING_DIFFERENCE_COLUMN^29~DIFFERENCE=DEFAULT_DIFFERENCE;AMOUNT=STATEMENT_DEFAULT_AMOUNT^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'CHARGE_DIFFERENCE', 'Column', 'Charge Difference', '', 19, 0, '-3~0^-2~0^2~0^3~Currency^4~0^7~0^9~0^11~7^12~0^13~1^14~2^15~0^20~0^22~0^24~0^25~if ( value(DISPLAY_OPTION) =`1 [2,4], LINE_ITEM_AMOUNT - STATEMENT_CHARGE_AMOUNT, null())^26~0^28~BILLING_DIFFERENCE_COLUMN^29~DIFFERENCE=CHARGE_DIFFERENCE;AMOUNT=STATEMENT_CHARGE_AMOUNT^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'BILL_DIFFERENCE', 'Column', 'Bill Difference', '', 20, 0, '-3~0^-2~0^2~0^3~Currency^4~0^7~0^9~0^11~7^12~0^13~1^14~2^15~0^20~0^22~0^24~0^25~if ( value(DISPLAY_OPTION) =`1 [3,4], LINE_ITEM_BILL_AMOUNT - STATEMENT_BILL_AMOUNT, null())^26~0^28~BILLING_DIFFERENCE_COLUMN^29~DIFFERENCE=BILL_DIFFERENCE;AMOUNT=STATEMENT_BILL_AMOUNT^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SHOW_INTERVAL', 'Column', '', '', 21, 1, '', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SHOW_ENTITY_DETAIL', 'Column', '', '', 22, 1, '', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SHOW_PRODUCT_ID', 'Column', '', '', 23, 1, '', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SHOW_COMPONENT_ID', 'Column', '', '', 24, 1, '', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'LINE_ITEM_DEFAULT_AMOUNT', 'Column', '', '', 25, 1, '-3~0^-2~0^2~0^7~0^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'LINE_ITEM_AMOUNT', 'Column', '', '', 26, 1, '-3~0^-2~0^2~0^7~0^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'LINE_ITEM_BILL_AMOUNT', 'Column', '', '', 27, 1, '-3~0^-2~0^2~0^7~0^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'STATEMENT_DEFAULT_AMOUNT', 'Column', '', '', 28, 1, '-3~0^-2~0^2~0^7~0^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'STATEMENT_CHARGE_AMOUNT', 'Column', '', '', 29, 1, '-3~0^-2~0^2~0^7~0^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'STATEMENT_BILL_AMOUNT', 'Column', '', '', 30, 1, '-3~0^-2~0^2~0^7~0^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'ENTITY_ID_TEXT', 'Label', 'Billing Entity', '', 0, 0, '1101~2', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'PERIOD_DATE_STRING', 'Label', 'Billing Period', '', 1, 0, '1101~2', v_CHILD_OBJECT_ID);
            END;
             
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'ENTITY_ID', 'Report Filter', 'Billing Entity', '', 0, 0, '-3~0^-2~1^-1~BILLING_ENTITY_ID^508~0^514~0^515~0^519~0^520~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'INVOICE_DATE', 'Report Filter', 'Invoice Date', '', 1, 0, '-2~1^-1~INVOICE_DATE', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'INVOICE_CATEGORY', 'Report Filter', 'Invoice Category', '', 2, 0, '-2~1^-1~INVOICE_CATEGORY', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'STATEMENT_STATE', 'Report Filter', 'Statement State', '', 3, 0, '-2~1^-1~STATEMENT_STATE', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'DISPLAY_OPTION', 'Report Filter', 'Display Options', '', 4, 0, '-3~0^-2~1^-1~DISPLAY_OPTIONS^508~0^514~0^515~0^519~0', v_CHILD_OBJECT_ID);
         END;
          
      END;
       
      -------------------------------------
      --   Billing.InvoiceComparison
      -------------------------------------
      <<L22>>
      DECLARE
         v_PARENT_OBJECT_ID NUMBER(9) := L0.v_OBJECT_ID;
         v_OBJECT_ID NUMBER(9);
      BEGIN
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'Billing.InvoiceComparison', 'System View', 'Billing.InvoiceComparison', '', 4, 0, '-3~0^-2~0^801~com.newenergyassoc.ro.mightyReport.MightyReportPanel', v_OBJECT_ID);
         <<L23>>
         DECLARE
            v_PARENT_OBJECT_ID NUMBER(9) := L22.v_OBJECT_ID;
            v_OBJECT_ID NUMBER(9);
         BEGIN
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'INVOICE_COMPARISON', 'Report', 'Invoice Comparison', '', 0, 0, '-3~0^-2~0^401~BSJ.GET_INVOICE_COMPARISON;DISPLAY_OPTION=value(DISPLAY_OPTIONS)^402~0^403~Normal Grid^406~0', v_OBJECT_ID);
            <<L24>>
            DECLARE
               v_PARENT_OBJECT_ID NUMBER(9) := L23.v_OBJECT_ID;
               v_OBJECT_ID NUMBER(9);
            BEGIN
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'INVOICE_COMPARISON_Grid', 'Grid', 'Invoice Comparison Grid', '', 0, 0, '-3~0^-2~0^305~0^307~Anchored^308~0^309~0', v_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'LINE_ITEM_TYPE', 'Column', 'Line Item Type', '', 0, 0, '-3~0^-2~0^2~0^7~1^13~0^20~0^22~1^24~1^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'LINE_ITEM_NAME', 'Column', 'Line Item Name', '', 1, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~1^24~1^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'DEFAULT_AMOUNT_DIFFERENCE', 'Column', 'Difference', '', 2, 0, '-3~0^-2~0^2~0^3~Currency^7~0^11~7^13~1^20~0^22~6^24~0^25~eval (if (DISPLAY_OPTIONS = 1 and count(LINE_ITEM_DEFAULT_AMOUNT)=2, "LINE_ITEM_DEFAULT_AMOUNT[1] - LINE_ITEM_DEFAULT_AMOUNT[0]", "null()"))^28~BILLING_DIFFERENCE_COLUMN^29~DIFFERENCE=DEFAULT_AMOUNT_DIFFERENCE;AMOUNT=eval (if (count(LINE_ITEM_DEFAULT_AMOUNT)=2, "LINE_ITEM_DEFAULT_AMOUNT[0]", "null()"))^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'CHARGE_AMOUNT_DIFFERENCE', 'Column', 'Charge Difference', '', 3, 0, '-3~0^-2~0^2~0^3~Currency^7~0^11~7^13~1^20~0^22~6^24~0^25~eval (if (DISPLAY_OPTIONS =`1 [2,4] and count(LINE_ITEM_AMOUNT)=2, "LINE_ITEM_AMOUNT[1] - LINE_ITEM_AMOUNT[0]", "null()"))^28~BILLING_DIFFERENCE_COLUMN^29~DIFFERENCE=CHARGE_AMOUNT_DIFFERENCE;AMOUNT=eval (if (count(LINE_ITEM_AMOUNT)=2, "LINE_ITEM_AMOUNT[0]", "null()"))^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'BILL_AMOUNT_DIFFERENCE', 'Column', 'Bill Difference', '', 4, 0, '-3~0^-2~0^2~0^3~Currency^7~0^11~7^13~1^20~0^22~6^24~0^25~eval (if (DISPLAY_OPTIONS =`1 [3,4] and count(LINE_ITEM_BILL_AMOUNT)=2, "LINE_ITEM_BILL_AMOUNT[1] - LINE_ITEM_BILL_AMOUNT[0]", "null()"))^28~BILLING_DIFFERENCE_COLUMN^29~DIFFERENCE=BILL_AMOUNT_DIFFERENCE;AMOUNT=eval (if (count(LINE_ITEM_BILL_AMOUNT)=2, "LINE_ITEM_BILL_AMOUNT[0]", "null()"))^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'STATEMENT_STATE', 'Column', '', '', 5, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~4^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'STATEMENT_STATE_NAME', 'Column', '', '', 6, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~2^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'STATEMENT_TYPE_ORDER', 'Column', '', '', 7, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~4^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'STATEMENT_TYPE_NAME', 'Column', '', '', 8, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~2^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'STATEMENT_TYPE', 'Column', '', '', 9, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~4^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'LINE_ITEM_DEFAULT_AMOUNT_DISP', 'Column', 'Amount', '', 10, 0, '-3~0^-2~0^2~0^3~Currency^7~0^11~7^13~1^14~2^20~1^22~5^24~0^25~if (DISPLAY_OPTIONS = 1, if (null(LINE_ITEM_DEFAULT_AMOUNT), "", LINE_ITEM_DEFAULT_AMOUNT), null())^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'LINE_ITEM_AMOUNT_DISP', 'Column', 'Charge Amount', '', 11, 0, '-3~0^-2~0^2~0^3~Currency^7~0^11~7^13~1^14~2^20~1^22~5^24~0^25~if (DISPLAY_OPTIONS =`1 [2,4], if (null(LINE_ITEM_AMOUNT), "", LINE_ITEM_AMOUNT), null())^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'LINE_ITEM_BILL_AMOUNT_DISP', 'Column', 'Bill Amount', '', 12, 0, '-3~0^-2~0^2~0^3~Currency^7~0^11~7^13~1^14~2^20~1^22~5^24~0^25~if (DISPLAY_OPTIONS =`1 [3,4], if (null(LINE_ITEM_BILL_AMOUNT), "", LINE_ITEM_BILL_AMOUNT), null())^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'LINE_ITEM_DEFAULT_AMOUNT', 'Column', '', '', 13, 1, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~5^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'LINE_ITEM_AMOUNT', 'Column', '', '', 14, 1, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~5^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'LINE_ITEM_BILL_AMOUNT', 'Column', '', '', 15, 1, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~5^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'ENTITY_ID_TEXT', 'Label', 'Billing Entity', '', 0, 0, '-3~0^-2~0^1101~2', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'BILLING_PERIOD', 'Label', 'Billing Period', '', 1, 0, '-3~0^-2~0^1101~2', v_CHILD_OBJECT_ID);
            END;
             
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'ENTITY_ID', 'Report Filter', 'Billing Entity', '', 0, 0, '-3~0^-2~1^-1~BILLING_ENTITY_ID^508~0^514~0^515~0^519~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'INVOICE_DATE', 'Report Filter', 'Invoice Date', '', 1, 0, '-3~0^-2~0^501~s (Special List)^504~BSJ.GET_INVOICE_DATES;ENTITY_ID;#-1;#-1;BEGIN_DATE;END_DATE^508~0^514~0^515~0^518~INVOICE_CATEGORY^519~1', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'INVOICE_CATEGORY', 'Report Filter', 'Invoice Category', '', 2, 0, '-2~1^-1~INVOICE_CATEGORY', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'COMPARISON_STATES_ID', 'Report Filter', 'Comparison States', '', 3, 0, '-3~0^-2~0^501~s (Special List)^504~BSJ.GET_INV_COMP_STATEMENT_TYPES^508~1^514~0^515~0^519~1', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'DISPLAY_OPTIONS', 'Report Filter', 'Display Options', '', 4, 0, '-3~0^-2~1^-1~DISPLAY_OPTIONS^508~0^514~0^515~0^519~0', v_CHILD_OBJECT_ID);
         END;
          
      END;
       
      -------------------------------------
      --   Billing.StatementStatus
      -------------------------------------
      <<L25>>
      DECLARE
         v_PARENT_OBJECT_ID NUMBER(9) := L0.v_OBJECT_ID;
         v_OBJECT_ID NUMBER(9);
      BEGIN
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'Billing.StatementStatus', 'System View', 'Billing.StatementStatus', '', 5, 0, '-3~0^-2~0^801~com.newenergyassoc.ro.mightyReport.MightyReportPanel', v_OBJECT_ID);
         <<L26>>
         DECLARE
            v_PARENT_OBJECT_ID NUMBER(9) := L25.v_OBJECT_ID;
            v_OBJECT_ID NUMBER(9);
         BEGIN
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'STATEMENT_STATUS', 'Report', 'Statement Status', '', 0, 0, '-3~0^-2~0^401~BSJ.GET_STATEMENT_STATUS^402~0^403~Lazy Master/Detail Grids^404~BSJ.GET_STATEMENT_STATUS_DETAILS^405~-1^406~0^409~Vertical', v_OBJECT_ID);
            <<L27>>
            DECLARE
               v_PARENT_OBJECT_ID NUMBER(9) := L26.v_OBJECT_ID;
               v_OBJECT_ID NUMBER(9);
            BEGIN
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'STATEMENT_STATUS_Grid_DETAIL', 'Grid', 'Statement Status Grid Detail', '', 0, 0, '-3~0^-2~0^301~BSJ.PUT_STATEMENT_STATUS^305~0^308~0^309~3', v_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'STATEMENT_ENTRY_DATE', 'Column', '', '', 0, 0, '1~d (Date Picker)^2~0^3~M/d/yyyy hh:mm:ss a^4~7^7~0^9~0^11~0^12~1^13~0^14~0^15~0^20~1^22~0^24~0^26~-1^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'INVOICE_ENTRY_DATE', 'Column', '', '', 1, 0, '1~d (Date Picker)^2~0^3~M/d/yyyy hh:mm:ss a^4~7^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~1^22~0^24~0^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'INVOICE_BEGIN_DATE', 'Column', '', '', 2, 1, '2~0^3~Long Date^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'INVOICE_PERIOD', 'Column', '', '', 3, 0, '2~0^4~0^7~0^9~0^11~1^12~1^13~0^14~0^15~0^20~0^22~0^24~0^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'INVOICE_END_DATE', 'Column', '', '', 4, 1, '2~0^3~Long Date^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'REVIEW_STATUS', 'Column', '', '', 5, 0, '1~s (Special List)^2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^16~SP.GET_SYSTEM_LABEL_VALUES;#1;"Billing;"Status;"Values;"?^20~0^22~0^24~0^26~0^28~BILLING_STATUS_CODES^29~STATUS=REVIEW_STATUS^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'NOTES', 'Column', '', '', 6, 0, '1~b (Big Text Edit)^2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'ENTITY_ID', 'Column', '', '', 7, 1, '', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'STATEMENT_TYPE', 'Column', '', '', 8, 1, '', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'STATEMENT_STATE', 'Column', '', '', 9, 1, '', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'STATEMENT_DATE', 'Column', '', '', 10, 1, '', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'AS_OF_DATE', 'Column', '', '', 11, 1, '', v_CHILD_OBJECT_ID);
            END;
             
            <<L28>>
            DECLARE
               v_PARENT_OBJECT_ID NUMBER(9) := L26.v_OBJECT_ID;
               v_OBJECT_ID NUMBER(9);
            BEGIN
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'STATEMENT_STATUS_Grid_MASTER', 'Grid', 'Statement Status Grid Master', '', 0, 0, '-3~0^-2~0^305~0^307~Anchored^308~0^309~0', v_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'ENTITY_ID', 'Column', '', '', 0, 1, '-3~0^-2~0^2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~6^24~0^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'ENTITY_NAME', 'Column', 'Billing Entity', '', 1, 0, '2~0^4~0^7~0^9~0^11~0^12~1^13~0^14~0^15~0^20~1^22~1^24~1^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'STATEMENT_STATE', 'Column', '', '', 2, 0, '-3~0^-2~0^2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~4^24~0^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'STATEMENT_STATE_NAME', 'Column', 'Statement State', '', 3, 0, '-3~0^-2~0^2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~2^24~0^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'STATEMENT_TYPE_ORDER', 'Column', '', '', 4, 0, '22~4', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'STATEMENT_TYPE_NAME', 'Column', 'Statement Type', '', 5, 0, '-3~0^-2~0^2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~2^24~0^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'STATEMENT_TYPE', 'Column', '', '', 6, 0, '-3~0^-2~0^2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~4^24~0^26~-1^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'STATEMENT_DATE', 'Column', 'Date', '', 7, 0, '-3~0^-2~0^2~0^3~Medium Date^4~7^7~0^9~0^11~1^12~1^13~0^14~0^15~0^20~1^22~1^24~1^26~-1^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'AS_OF_DATE', 'Column', '', '', 8, 1, '-3~0^-2~0^2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~5^24~0^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'REVIEW_STATUS', 'Column', '', '', 9, 0, '-3~0^-2~0^2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~5^24~0^26~0^28~BILLING_STATUS_CODES^29~STATUS=REVIEW_STATUS^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'INVOICE_ENTRY_DATE', 'Column', '', '', 10, 1, '-3~0^-2~0^2~0^3~Short Date^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~5^24~0^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'STATEMENT_ENTRY_DATE', 'Column', '', '', 11, 1, '-3~0^-2~0^2~0^3~Short Date^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~5^24~0^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'INVOICE_AVAILABLE', 'Column', 'Invoice Available', '', 12, 0, '-3~0^-2~0^1~k (Checkbox)^2~0^4~11^7~0^9~0^11~4^12~0^13~0^14~0^15~0^20~1^22~5^24~0^26~-1^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'STATEMENT_AVAILABLE', 'Column', 'Statement Available', '', 13, 1, '-3~0^-2~0^1~k (Checkbox)^2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~1^22~5^24~0^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
            END;
             
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'ENTITY_ID', 'Report Filter', 'Billing Entity', '', 0, 0, '-3~0^-2~0^501~s (Special List)^504~BSJ.BILL_ENTITY_NAMES_INCL_ALL;CALLING_MODULE;MODLE_ID^508~0^514~0^515~0^519~1^520~0', v_CHILD_OBJECT_ID);
         END;
          
      END;
       
      -------------------------------------
      --   Billing.DisputeStatus
      -------------------------------------
      <<L29>>
      DECLARE
         v_PARENT_OBJECT_ID NUMBER(9) := L0.v_OBJECT_ID;
         v_OBJECT_ID NUMBER(9);
      BEGIN
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'Billing.DisputeStatus', 'System View', 'Billing.DisputeStatus', '', 6, 0, '-3~0^-2~0^801~com.newenergyassoc.ro.mightyReport.MightyReportPanel', v_OBJECT_ID);
         <<L30>>
         DECLARE
            v_PARENT_OBJECT_ID NUMBER(9) := L29.v_OBJECT_ID;
            v_OBJECT_ID NUMBER(9);
         BEGIN
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'GET_DISPUTE_STATUS', 'Report', 'Billing Dispute Status', '', 0, 0, '-3~0^-2~0^401~BSJ.GET_DISPUTE_STATUS_MASTER^402~0^403~Lazy Master/Detail Grids^404~BSJ.GET_DISPUTE_STATUS_DETAIL^405~-1^406~0^409~Vertical', v_OBJECT_ID);
            <<L31>>
            DECLARE
               v_PARENT_OBJECT_ID NUMBER(9) := L30.v_OBJECT_ID;
               v_OBJECT_ID NUMBER(9);
            BEGIN
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'GET_DISPUTE_STATUS_Grid_DETAIL', 'Grid', 'Dispute Status Grid Detail', '', 0, 0, '-3~0^-2~0^301~BSJ.PUT_BILLING_CHARGE_DISPUTE^305~0^308~0^309~0', v_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'CHARGE_DETAILS', 'Action', 'Charge Details', '', 0, 0, '-3~0^-2~0^1004~ROW_SELECTED>0^1006~2^1007~Billing.ChargeDetails;ORIGINAL_DATE=STATEMENT_DATE;ORIGINAL_END_DATE=STATEMENT_END_DATE', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'BILL_ENTITY', 'Column', 'Billing Entity', '', 0, 0, '1~x (No Edit)^2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~1^22~0^24~0^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'PRODUCT', 'Column', 'Product', '', 1, 0, '1~x (No Edit)^2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~1^22~0^24~0^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'COMPONENT', 'Column', 'Component', '', 2, 0, '1~x (No Edit)^2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~1^22~0^24~0^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'STATEMENT_DATE', 'Column', '', '', 3, 1, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'STATEMENT_END_DATE', 'Column', '', '', 3, 1, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'DISPUTE_DATE', 'Column', 'Dispute Date', '', 4, 0, '1~x (No Edit)^2~0^3~yyyy-MM-dd KK:mm^4~7^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~1^22~0^24~0^26~-1^28~BILLING_STATEMENT_DATE^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'DISPUTE_STATUS', 'Column', 'Dispute Status', '', 5, 0, '1~s (Special List)^2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^16~SP.GET_SYSTEM_LABEL_VALUES;#0;"Billing;"Status;"Values;"?^20~0^22~0^24~0^26~-1^28~BILLING_STATUS_CODES^29~STATUS=DISPUTE_STATUS^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'MARKET_STATUS', 'Column', '', '', 6, 1, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SUBMIT_STATUS', 'Column', '', '', 7, 1, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'BILLED_AMOUNT', 'Column', 'Billed Amount', '', 8, 0, '1~n (Numeric Edit)^2~0^3~Currency^4~0^7~0^9~0^11~0^12~0^13~0^14~2^15~0^20~0^22~0^24~0^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'CORRECT_AMOUNT', 'Column', 'Corrected Amount', '', 9, 0, '1~n (Numeric Edit)^2~0^3~Currency^4~0^7~0^9~0^11~0^12~0^13~0^14~2^15~0^20~0^22~0^24~0^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'DIFFERENCE', 'Column', 'Difference', '', 10, 0, '-3~0^-2~0^1~x (No Edit)^2~0^3~Currency^4~0^7~0^9~0^11~0^12~0^13~0^14~2^15~0^20~0^22~0^24~0^25~BILLED_AMOUNT - CORRECT_AMOUNT^26~0^28~BILLING_DIFFERENCE_COLUMN^29~AMOUNT=CORRECT_AMOUNT^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'DESCR', 'Column', 'Description', '', 11, 0, '1~b (Big Text Edit)^2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'ENTRY_DATE', 'Column', '', '', 12, 0, '1~d (Date Picker)^2~0^3~M/d/yyyy hh:mm:ss a^4~7^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~1^22~0^24~0^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'ENTITY_ID', 'Column', '', '', 13, 1, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'PRODUCT_ID', 'Column', '', '', 14, 1, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'COMPONENT_ID', 'Column', '', '', 15, 1, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'STATEMENT_TYPE', 'Column', '', '', 16, 1, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'STATEMENT_STATE', 'Column', '', '', 17, 1, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
            END;
             
            <<L32>>
            DECLARE
               v_PARENT_OBJECT_ID NUMBER(9) := L30.v_OBJECT_ID;
               v_OBJECT_ID NUMBER(9);
            BEGIN
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'GET_DISPUTE_STATUS_Grid_MASTER', 'Grid', 'Dispute Status Grid Master', '', 0, 0, '-3~0^-2~0^305~0^308~0^309~0', v_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'ENTITY_NAME', 'Column', 'Billing Entity', '', 0, 0, '-3~0^-2~0^1~x (No Edit)^2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~1^22~0^24~0^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'ENTITY_ID', 'Column', 'Billing_Entity_ID', '', 1, 1, '-3~0^-2~0^2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~1^22~0^24~0^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'STATEMENT_DATE', 'Column', 'Statement Date', '', 2, 0, '-3~0^-2~0^1~x (No Edit)^2~0^3~Short Date^4~7^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~1^22~0^24~0^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'OPEN_DISPUTES', 'Column', 'Open Disputes', '', 3, 0, '1~x (No Edit)^2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~1^22~0^24~0^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'CLOSED_DISPUTES', 'Column', 'Closed Disputes', '', 4, 0, '1~x (No Edit)^2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'REJECTED_DISPUTES', 'Column', 'Rejected Disputes', '', 5, 0, '1~x (No Edit)^2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
            END;
             
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'ENTITY_ID', 'Report Filter', 'Billing Entities', '', 0, 0, '-3~0^-2~0^501~s (Special List)^504~BSJ.BILL_ENTITY_NAMES_INCL_ALL;CALLING_MODULE;MODLE_ID^508~0^514~0^515~0^519~1^520~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'PRODUCT_ID', 'Report Filter', 'Product', '', 1, 0, '-3~0^-2~0^501~s (Special List)^504~BSJ.PRODUCT_NAMES;STATEMENT_TYPE;BEGIN_DATE;END_DATE;AS_OF_DATE^508~0^514~0^515~0^519~1^520~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'COMPONENT_ID', 'Report Filter', 'Component', '', 2, 0, '-3~0^-2~0^501~s (Special List)^504~BSJ.COMPONENT_NAMES;STATEMENT_TYPE;BEGIN_DATE;END_DATE;AS_OF_DATE^508~0^514~0^515~0^519~1^520~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'STATUS_FILTER', 'Report Filter', 'Status Filter', '', 3, 1, '-3~0^-2~0^501~s (Special List)^504~SP.GET_SYSTEM_LABEL_VALUES_ALL;#0;"Billing;"Status;"Values;"?^508~0^514~0^515~0^519~1^520~0', v_CHILD_OBJECT_ID);
         END;
          
      END;
       
      -------------------------------------
      --   Billing.ChargeDetails
      -------------------------------------
      <<L33>>
      DECLARE
         v_PARENT_OBJECT_ID NUMBER(9) := L0.v_OBJECT_ID;
         v_OBJECT_ID NUMBER(9);
      BEGIN
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'Billing.ChargeDetails', 'System View', 'Charge Details', '', 8, 0, '-3~0^-2~0^801~com.newenergyassoc.ro.billing.ChargeDetailsContentPanel', v_OBJECT_ID);
         <<L34>>
         DECLARE
            v_PARENT_OBJECT_ID NUMBER(9) := L33.v_OBJECT_ID;
            v_OBJECT_ID NUMBER(9);
         BEGIN
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'CHARGE_DETAILS_REPORT', 'Report', 'Charge Details', '', 0, 0, '-3~0^-2~0^401~BSJ.GET_CHARGE_DETAILS;STATEMENT_DATE=ORIGINAL_DATE;STATEMENT_END_DATE=ORIGINAL_END_DATE^402~1^403~Normal Grid^405~0^406~0^413~Billing.ChargeDetailsBase', v_OBJECT_ID);
            <<L35>>
            DECLARE
               v_PARENT_OBJECT_ID NUMBER(9) := L34.v_OBJECT_ID;
               v_OBJECT_ID NUMBER(9);
            BEGIN
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'CHARGE_DETAILS_REPORT_Grid_COMBINATION', 'Grid', 'Billing.ChargeDetailsBase', '', 0, 0, '-3~0^-2~0^305~0^308~0', v_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'DRILL_IN', 'Action', 'More Charge Details...', '', 0, 0, '-3~0^-2~0^1006~2^1007~Billing.ChargeDetails;PRODUCT_ID=-CHARGE_ID', v_CHILD_OBJECT_ID);
               <<L36>>
               DECLARE
                  v_PARENT_OBJECT_ID NUMBER(9) := L35.v_OBJECT_ID;
                  v_OBJECT_ID NUMBER(9);
               BEGIN
                  SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'DISPUTE_DETAILS', 'Action', 'Dispute Details...', '', 1, 0, '-3~0^-2~0^1006~8^1007~NA', v_OBJECT_ID);
                  SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SHOW_DETAILS', 'Action', 'Show Details', '', 0, 0, '-3~0^-2~0^1006~2^1007~Billing.ChargeDisputeDetails;STATEMENT_TYPE1=STATEMENT_TYPE;STATEMENT_STATE1=STATEMENT_STATE', v_CHILD_OBJECT_ID);
                  SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'REFRESH', 'Action', 'Refresh', '', 1, 0, '-3~0^-2~0^1006~6^1007~Billing.ChargeDetails', v_CHILD_OBJECT_ID);
               END;
                
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'CHARGE_DATE', 'Column', 'Charge Date', '', 0, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~1^24~0^28~BILLING_STATEMENT_DATE^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'CHARGE_END_DATE', 'Column', '', '', 1, 1, '-3~0^-2~0^2~0^7~0^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'COMPONENT_ID', 'Column', '', '', 2, 1, '-3~0^-2~0^2~0^7~0^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'CHARGE_ID', 'Column', '', '', 3, 1, '-3~0^-2~0^2~0^7~0^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'COMBINED_CHARGE_ID', 'Column', '', '', 4, 1, '-3~0^-2~0^2~0^7~0^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'CHARGE_VIEW_TYPE', 'Column', '', '', 5, 1, '-3~0^-2~0^2~0^7~0^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'COMPONENT_NAME', 'Column', '', '', 6, 0, '', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'COMPONENT_AMOUNT', 'Column', '', '', 7, 0, '-3~0^-2~0^2~0^7~0^11~7^13~1^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'BILL_COMPONENT_AMOUNT', 'Column', '', '', 8, 0, '-3~0^-2~0^2~0^7~0^11~7^13~1^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'COEFFICIENT', 'Column', '', '', 9, 0, '-3~0^-2~0^2~0^7~0^11~7^13~1^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'CHARGE_QUANTITY', 'Column', 'Charge Quantity', '', 10, 0, '-3~0^-2~0^2~0^7~0^11~7^13~1^14~2^20~0^22~6^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'BILL_QUANTITY', 'Column', 'Bill Quantity', '', 11, 0, '-3~0^-2~0^2~0^7~0^11~7^13~1^14~2^20~0^22~6^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'CHARGE_RATE', 'Column', 'Charge Rate', '', 12, 0, '-3~0^-2~0^2~0^3~Currency^7~0^11~7^13~1^20~0^22~6^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'CHARGE_FACTOR', 'Column', 'Charge Factor', '', 13, 0, '-3~0^-2~0^2~0^7~0^11~7^13~1^20~0^22~6^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'CHARGE_AMOUNT', 'Column', 'Charge Amount', '', 14, 0, '-3~0^-2~0^2~0^3~Currency^7~0^11~7^13~1^14~2^20~0^22~6^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'BILL_AMOUNT', 'Column', 'Bill Amount', '', 15, 0, '-3~0^-2~0^2~0^3~Currency^7~0^11~7^13~1^14~2^20~0^22~6^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'DISPUTE_STATUS', 'Column', 'Dispute Status', '', 16, 0, '-3~0^-2~0^1~s (Special List)^2~0^7~0^13~0^16~SP.GET_SYSTEM_LABEL_VALUES;#0;"Billing;"Status;"Values;"?^19~IF ( NULL ( ORIG_DISPUTE_STATUS ) , "label:mustInitiateFirst", "" )^20~0^22~6^24~0^28~BILLING_STATUS_CODES^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'ORIG_DISPUTE_STATUS', 'Column', 'Orig Dispute Status', '', 17, 1, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~6^24~0^25~DISPUTE_STATUS^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'ENTITY_NAME', 'Label', 'Billing Entity', '', 0, 0, '1101~2', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'STATEMENT_DATE_RANGE', 'Label', 'Statement Date', '', 1, 0, '-3~0^-2~0^1101~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'PRODUCT_NAME', 'Label', 'Product', '', 2, 0, '-3~0^-2~0^1101~2', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'COMPONENT_NAME', 'Label', 'Component', '', 3, 0, '-3~0^-2~0^1101~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'STATEMENT_TYPE_NAME', 'Label', 'Statement Type', '', 4, 0, '-3~0^-2~0^1101~2', v_CHILD_OBJECT_ID);
            END;
             
            <<L37>>
            DECLARE
               v_PARENT_OBJECT_ID NUMBER(9) := L34.v_OBJECT_ID;
               v_OBJECT_ID NUMBER(9);
            BEGIN
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'CHARGE_DETAILS_REPORT_Grid_FORMULA', 'Grid', 'Billing.ChargeDetailsBase', '', 0, 0, '-3~0^-2~0^305~0^307~Anchored^308~1', v_OBJECT_ID);
               <<L38>>
               DECLARE
                  v_PARENT_OBJECT_ID NUMBER(9) := L37.v_OBJECT_ID;
                  v_OBJECT_ID NUMBER(9);
               BEGIN
                  SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'DISPUTE_DETAILS', 'Action', 'Dispute Details...', '', 0, 0, '-3~0^-2~0^1006~8^1007~NA', v_OBJECT_ID);
                  SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SHOW_DETAILS', 'Action', 'Show Details', '', 0, 0, '-3~0^-2~0^1006~2^1007~Billing.ChargeDisputeDetails;STATEMENT_TYPE1=STATEMENT_TYPE;STATEMENT_STATE1=STATEMENT_STATE', v_CHILD_OBJECT_ID);
                  SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'REFRESH', 'Action', 'Refresh', '', 1, 0, '-3~0^-2~0^1006~6^1007~Billing.ChargeDetails', v_CHILD_OBJECT_ID);
               END;
                
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'CHARGE_DATE', 'Column', 'Charge Date', '', 0, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~1^24~1^28~BILLING_STATEMENT_DATE^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'ITERATOR1_NAME', 'Column', '', '', 1, 0, '-3~0^-2~0^2~0^7~0^13~1^20~0^22~7^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'ITERATOR1_VAL', 'Column', '-', '', 2, 0, '-3~0^-2~0^2~0^7~0^13~1^20~0^22~1^24~1^27~ITERATOR1_NAME^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'ITERATOR2_NAME', 'Column', '', '', 3, 0, '-3~0^-2~0^2~0^7~0^13~1^20~0^22~7^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'ITERATOR2_VAL', 'Column', '-', '', 4, 0, '-3~0^-2~0^2~0^7~0^13~1^20~0^22~1^24~1^27~ITERATOR2_NAME^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'ITERATOR3_NAME', 'Column', '', '', 5, 0, '-3~0^-2~0^2~0^7~0^13~1^20~0^22~7^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'ITERATOR3_VAL', 'Column', '-', '', 6, 0, '-3~0^-2~0^2~0^7~0^13~1^20~0^22~1^24~1^27~ITERATOR3_NAME^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'ITERATOR4_NAME', 'Column', '', '', 7, 0, '-3~0^-2~0^2~0^7~0^13~1^20~0^22~7^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'ITERATOR4_VAL', 'Column', '-', '', 8, 0, '-3~0^-2~0^2~0^7~0^13~1^20~0^22~1^24~1^27~ITERATOR4_NAME^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'ITERATOR5_NAME', 'Column', '', '', 9, 0, '-3~0^-2~0^2~0^7~0^13~1^20~0^22~7^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'ITERATOR5_VAL', 'Column', '-', '', 10, 0, '-3~0^-2~0^2~0^7~0^13~1^20~0^22~1^24~1^27~ITERATOR5_NAME^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'CHARGE_QUANTITY', 'Column', 'Charge Quantity', '', 11, 0, '-3~0^-2~0^2~0^7~0^11~7^13~1^14~2^20~0^22~6^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'BILL_QUANTITY', 'Column', 'Bill Quantity', '', 12, 0, '-3~0^-2~0^2~0^7~0^11~7^13~1^14~2^20~0^22~6^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'CHARGE_RATE', 'Column', 'Charge Rate', '', 13, 0, '-3~0^-2~0^2~0^3~Currency^7~0^11~7^13~1^20~0^22~6^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'CHARGE_FACTOR', 'Column', 'Charge Factor', '', 14, 0, '-3~0^-2~0^2~0^7~0^11~7^13~1^20~0^22~6^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'CHARGE_AMOUNT', 'Column', 'Charge Amount', '', 15, 0, '-3~0^-2~0^2~0^3~Currency^7~0^11~7^13~1^14~2^20~0^22~6^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'BILL_AMOUNT', 'Column', 'Bill Amount', '', 16, 0, '-3~0^-2~0^2~0^3~Currency^7~0^11~7^13~1^14~2^20~0^22~6^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'DISPUTE_STATUS', 'Column', 'Dispute Status', '', 17, 0, '-3~0^-2~0^1~s (Special List)^2~0^7~0^13~0^16~SP.GET_SYSTEM_LABEL_VALUES;#0;"Billing;"Status;"Values;"?^19~IF ( NULL ( ORIG_DISPUTE_STATUS ) , "label:mustInitiateFirst", "" )^20~0^22~6^24~0^28~BILLING_STATUS_CODES^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'ORIG_DISPUTE_STATUS', 'Column', 'Orig Dispute Status', '', 18, 1, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~6^24~0^25~DISPUTE_STATUS^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'VARIABLE_NAME', 'Column', '', '', 19, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~2^24~0^31~0^32~1', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'VARIABLE_VALUE', 'Column', '', '', 20, 0, '-3~0^-2~0^2~0^7~0^11~7^13~0^20~0^22~5^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'ENTITY_NAME', 'Label', 'Billing Entity', '', 0, 0, '1101~2', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'STATEMENT_DATE_RANGE', 'Label', 'Statement Date', '', 1, 0, '-3~0^-2~0^1101~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'PRODUCT_NAME', 'Label', 'Product', '', 2, 0, '-3~0^-2~0^1101~2', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'COMPONENT_NAME', 'Label', 'Component', '', 3, 0, '-3~0^-2~0^1101~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'STATEMENT_TYPE_NAME', 'Label', 'Statement Type', '', 4, 0, '-3~0^-2~0^1101~2', v_CHILD_OBJECT_ID);
            END;
             
            <<L39>>
            DECLARE
               v_PARENT_OBJECT_ID NUMBER(9) := L34.v_OBJECT_ID;
               v_OBJECT_ID NUMBER(9);
            BEGIN
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'CHARGE_DETAILS_REPORT_Grid_FTR ALLOC', 'Grid', 'Billing.ChargeDetailsBase', '', 0, 0, '-3~0^-2~0^305~0^308~0', v_OBJECT_ID);
               <<L40>>
               DECLARE
                  v_PARENT_OBJECT_ID NUMBER(9) := L39.v_OBJECT_ID;
                  v_OBJECT_ID NUMBER(9);
               BEGIN
                  SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'DISPUTE_DETAILS', 'Action', 'Dispute Details...', '', 0, 0, '-3~0^-2~0^1006~8^1007~NA', v_OBJECT_ID);
                  SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SHOW_DETAILS', 'Action', 'Show Details', '', 0, 0, '-3~0^-2~0^1006~2^1007~Billing.ChargeDisputeDetails;STATEMENT_TYPE1=STATEMENT_TYPE;STATEMENT_STATE1=STATEMENT_STATE', v_CHILD_OBJECT_ID);
                  SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'REFRESH', 'Action', 'Refresh', '', 1, 0, '-3~0^-2~0^1006~6^1007~Billing.ChargeDetails', v_CHILD_OBJECT_ID);
               END;
                
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'CHARGE_DATE', 'Column', 'Charge Date', '', 0, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~1^24~0^28~BILLING_STATEMENT_DATE^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SOURCE_NAME', 'Column', '', '', 0, 0, '', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SOURCE_ID', 'Column', '', '', 1, 1, '-3~0^-2~0^2~0^7~0^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'DELIVERY_POINT_NAME', 'Column', '', '', 2, 0, '', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'DELIVERY_POINT_ID', 'Column', '', '', 3, 1, '-3~0^-2~0^2~0^7~0^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SINK_NAME', 'Column', '', '', 4, 0, '', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SINK_ID', 'Column', '', '', 5, 1, '-3~0^-2~0^2~0^7~0^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'FTR_TYPE', 'Column', '', '', 6, 0, '', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'ALLOC_FACTOR', 'Column', '', '', 8, 0, '-3~0^-2~0^2~0^7~0^13~1^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'PURCHASES', 'Column', '', '', 9, 0, '', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SALES', 'Column', '', '', 10, 0, '', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'PRICE1', 'Column', '', '', 11, 0, '', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'PRICE2', 'Column', '', '', 12, 0, '', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'CHARGE_QUANTITY', 'Column', 'Charge Quantity', '', 13, 0, '-3~0^-2~0^2~0^7~0^11~7^13~1^14~2^20~0^22~6^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'BILL_QUANTITY', 'Column', 'Bill Quantity', '', 14, 0, '-3~0^-2~0^2~0^7~0^11~7^13~1^14~2^20~0^22~6^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'CHARGE_RATE', 'Column', 'Charge Rate', '', 15, 0, '-3~0^-2~0^2~0^3~Currency^7~0^11~7^13~1^20~0^22~6^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'CHARGE_FACTOR', 'Column', 'Charge Factor', '', 16, 0, '-3~0^-2~0^2~0^7~0^11~7^13~1^20~0^22~6^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'CHARGE_AMOUNT', 'Column', 'Charge Amount', '', 17, 0, '-3~0^-2~0^2~0^3~Currency^7~0^11~7^13~1^14~2^20~0^22~6^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'BILL_AMOUNT', 'Column', 'Bill Amount', '', 18, 0, '-3~0^-2~0^2~0^3~Currency^7~0^11~7^13~1^14~2^20~0^22~6^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'DISPUTE_STATUS', 'Column', 'Dispute Status', '', 20, 0, '-3~0^-2~0^1~s (Special List)^2~0^7~0^13~0^16~SP.GET_SYSTEM_LABEL_VALUES;#0;"Billing;"Status;"Values;"?^19~IF ( NULL ( ORIG_DISPUTE_STATUS ) , "label:mustInitiateFirst", "" )^20~0^22~6^24~0^28~BILLING_STATUS_CODES^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'ORIG_DISPUTE_STATUS', 'Column', 'Orig Dispute Status', '', 21, 1, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~6^24~0^25~DISPUTE_STATUS^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'ENTITY_NAME', 'Label', 'Billing Entity', '', 0, 0, '1101~2', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'STATEMENT_DATE_RANGE', 'Label', 'Statement Date', '', 1, 0, '-3~0^-2~0^1101~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'PRODUCT_NAME', 'Label', 'Product', '', 2, 0, '-3~0^-2~0^1101~2', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'COMPONENT_NAME', 'Label', 'Component', '', 3, 0, '-3~0^-2~0^1101~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'STATEMENT_TYPE_NAME', 'Label', 'Statement Type', '', 4, 0, '-3~0^-2~0^1101~2', v_CHILD_OBJECT_ID);
            END;
             
            <<L41>>
            DECLARE
               v_PARENT_OBJECT_ID NUMBER(9) := L34.v_OBJECT_ID;
               v_OBJECT_ID NUMBER(9);
            BEGIN
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'CHARGE_DETAILS_REPORT_Grid_SEM Detail', 'Grid', 'Billing.ChargeDetailsBase', '', 0, 0, '-3~0^-2~0^305~0^308~0^311~0', v_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'PIR_DETAILS', 'Action', 'Participant Info Details...', '', 0, 0, '1006~2^1007~SEM.ParticipantInfo;ENTITY_ID=ENTITY_ID;RESOURCE_NAME=RESOURCE_NAME;VARIABLE_TYPE="<ALL>"', v_CHILD_OBJECT_ID);
               <<L42>>
               DECLARE
                  v_PARENT_OBJECT_ID NUMBER(9) := L41.v_OBJECT_ID;
                  v_OBJECT_ID NUMBER(9);
               BEGIN
                  SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'DISPUTE_DETAILS', 'Action', 'Dispute Details...', '', 1, 0, '-3~0^-2~0^1006~8^1007~NA', v_OBJECT_ID);
                  SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SHOW_DETAILS', 'Action', 'Show Details', '', 0, 0, '-3~0^-2~0^1006~2^1007~Billing.ChargeDisputeDetails;STATEMENT_TYPE1=STATEMENT_TYPE;STATEMENT_STATE1=STATEMENT_STATE', v_CHILD_OBJECT_ID);
                  SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'REFRESH', 'Action', 'Refresh', '', 1, 0, '-3~0^-2~0^1006~6^1007~Billing.ChargeDetails', v_CHILD_OBJECT_ID);
               END;
                
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'CHARGE_DATE', 'Column', 'Charge Date', '', 0, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~1^24~0^28~BILLING_STATEMENT_DATE^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'CHARGE_ID', 'Column', '', '', 0, 1, '-3~0^-2~0^2~0^7~0^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'RESOLUTION', 'Column', '', '', 2, 1, '-3~0^-2~0^2~0^7~0^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'RESOURCE_NAME', 'Column', '', '', 3, 0, '', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'LOCATION_NAME', 'Column', '', '', 4, 0, '', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'REC_ORDER', 'Column', '', '', 5, 0, '', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'PAY_OR_CHARGE', 'Column', '', '', 6, 0, '', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'COMMENTS', 'Column', '', '', 7, 0, '', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'JURISDICTION', 'Column', '', '', 8, 0, '', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'CONTRACT', 'Column', '', '', 9, 0, '', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'CHARGE_QUANTITY', 'Column', 'Charge Quantity', '', 10, 0, '-3~0^-2~0^2~0^7~0^11~7^13~1^14~2^20~0^22~6^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'BILL_QUANTITY', 'Column', 'Bill Quantity', '', 11, 0, '-3~0^-2~0^2~0^7~0^11~7^13~1^14~2^20~0^22~6^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'QUANTITY_UNIT', 'Column', '', '', 11, 0, '', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'CHARGE_RATE', 'Column', 'Charge Rate', '', 12, 0, '-3~0^-2~0^2~0^3~Currency^7~0^11~7^13~1^20~0^22~6^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'AMOUNT_UNIT', 'Column', '', '', 13, 0, '', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'CHARGE_FACTOR', 'Column', 'Charge Factor', '', 13, 0, '-3~0^-2~0^2~0^7~0^11~7^13~1^20~0^22~6^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'CHARGE_AMOUNT', 'Column', 'Charge Amount', '', 14, 0, '-3~0^-2~0^2~0^3~Currency^7~0^11~7^13~1^14~2^20~0^22~6^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'BILL_AMOUNT', 'Column', 'Bill Amount', '', 15, 0, '-3~0^-2~0^2~0^3~Currency^7~0^11~7^13~1^14~2^20~0^22~6^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'DISPUTE_STATUS', 'Column', 'Dispute Status', '', 16, 0, '-3~0^-2~0^1~s (Special List)^2~0^7~0^13~0^16~SP.GET_SYSTEM_LABEL_VALUES;#0;"Billing;"Status;"Values;"?^19~IF ( NULL ( ORIG_DISPUTE_STATUS ) , "label:mustInitiateFirst", "" )^20~0^22~6^24~0^28~BILLING_STATUS_CODES^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'ORIG_DISPUTE_STATUS', 'Column', 'Orig Dispute Status', '', 17, 1, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~6^24~0^25~DISPUTE_STATUS^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'ENTITY_NAME', 'Label', 'Billing Entity', '', 0, 0, '1101~2', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'STATEMENT_DATE_RANGE', 'Label', 'Statement Date', '', 1, 0, '-3~0^-2~0^1101~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'PRODUCT_NAME', 'Label', 'Product', '', 2, 0, '-3~0^-2~0^1101~2', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'COMPONENT_NAME', 'Label', 'Component', '', 3, 0, '-3~0^-2~0^1101~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'STATEMENT_TYPE_NAME', 'Label', 'Statement Type', '', 4, 0, '-3~0^-2~0^1101~2', v_CHILD_OBJECT_ID);
            END;
             
         END;
          
      END;
       
      SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'Billing.CalculateStatements', 'System View', 'Billing.CalculateStatements', '', 9, 0, '801~com.newenergyassoc.ro.billing.BillingCalculateContentPanel', v_CHILD_OBJECT_ID);
      -------------------------------------
      --   Billing.ChargeDetailsComparison
      -------------------------------------
      <<L43>>
      DECLARE
         v_PARENT_OBJECT_ID NUMBER(9) := L0.v_OBJECT_ID;
         v_OBJECT_ID NUMBER(9);
      BEGIN
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'Billing.ChargeDetailsComparison', 'System View', 'Charge Details', '', 9, 0, '-3~0^-2~0^801~com.newenergyassoc.ro.billing.ChargeDetailsContentPanel', v_OBJECT_ID);
         <<L44>>
         DECLARE
            v_PARENT_OBJECT_ID NUMBER(9) := L43.v_OBJECT_ID;
            v_OBJECT_ID NUMBER(9);
         BEGIN
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'CHARGE_DETAILS_REPORT', 'Report', 'Charge Details Comparison', '', 0, 0, '-3~0^-2~0^401~BSJ.GET_CHARGE_DETAILS;STATEMENT_TYPE=STATEMENT_TYPE1_ID;STATEMENT_STATE=STATEMENT_STATE1;STATEMENT_DATE=ORIGINAL_DATE;STATEMENT_END_DATE=ORIGINAL_END_DATE^402~1^403~Comparison Grids^404~BSJ.GET_CHARGE_DETAILS;STATEMENT_TYPE=STATEMENT_TYPE2_ID;STATEMENT_STATE=STATEMENT_STATE2;STATEMENT_DATE=ORIGINAL_DATE;STATEMENT_END_DATE=ORIGINAL_END_DATE^406~0^413~Billing.ChargeDetailsComparisonLeft,Billing.ChargeDetailsComparisonRight', v_OBJECT_ID);
            <<L45>>
            DECLARE
               v_PARENT_OBJECT_ID NUMBER(9) := L44.v_OBJECT_ID;
               v_OBJECT_ID NUMBER(9);
            BEGIN
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'CHARGE_DETAILS_REPORT_Grid_COMBINATION', 'Grid', '-', '', 0, 0, '-3~0^-2~0^305~0^308~0', v_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'DRILL_IN', 'Action', 'More Charge Details...', '', 0, 0, '1006~2^1007~Billing.ChargeDetailsComparison;PRODUCT_ID=-CHARGE_ID', v_CHILD_OBJECT_ID);
               <<L46>>
               DECLARE
                  v_PARENT_OBJECT_ID NUMBER(9) := L45.v_OBJECT_ID;
                  v_OBJECT_ID NUMBER(9);
               BEGIN
                  SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'DISPUTE_DETAILS', 'Action', 'Dispute Details...', '', 1, 0, '-3~0^-2~0^1006~8^1007~NA', v_OBJECT_ID);
                  SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SHOW_DETAILS', 'Action', 'Show Details', '', 0, 0, '1006~2^1007~Billing.ChargeDisputeDetails;STATEMENT_TYPE1=STATEMENT_TYPE;STATEMENT_STATE1=STATEMENT_STATE', v_CHILD_OBJECT_ID);
                  SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'REFRESH', 'Action', 'Refresh', '', 1, 0, '-3~0^-2~0^1006~6^1007~Billing.ChargeDetailsComparison', v_CHILD_OBJECT_ID);
               END;
                
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'CHARGE_DATE', 'Column', 'Charge Date', '', 0, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~1^24~1^28~BILLING_STATEMENT_DATE^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'CHARGE_END_DATE', 'Column', '', '', 1, 1, '-3~0^-2~0^2~0^7~0^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'COMPONENT_ID', 'Column', '', '', 2, 1, '-3~0^-2~0^2~0^7~0^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'CHARGE_ID', 'Column', '', '', 3, 1, '-3~0^-2~0^2~0^7~0^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'COMBINED_CHARGE_ID', 'Column', '', '', 4, 1, '-3~0^-2~0^2~0^7~0^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'CHARGE_VIEW_TYPE', 'Column', '', '', 5, 1, '-3~0^-2~0^2~0^7~0^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'COMPONENT_NAME', 'Column', '', '', 6, 0, '', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'COMPONENT_AMOUNT', 'Column', '', '', 7, 0, '-3~0^-2~0^2~0^7~0^11~7^13~1^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'BILL_COMPONENT_AMOUNT', 'Column', '', '', 8, 0, '-3~0^-2~0^2~0^7~0^11~7^13~1^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'COEFFICIENT', 'Column', '', '', 9, 0, '-3~0^-2~0^2~0^7~0^11~7^13~1^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'CHARGE_QUANTITY', 'Column', 'Charge Quantity', '', 10, 0, '-3~0^-2~0^2~0^7~0^11~7^13~1^14~2^20~0^22~6^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'BILL_QUANTITY', 'Column', 'Bill Quantity', '', 11, 0, '-3~0^-2~0^2~0^7~0^11~7^13~1^14~2^20~0^22~6^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'CHARGE_RATE', 'Column', 'Charge Rate', '', 12, 0, '-3~0^-2~0^2~0^3~Currency^7~0^11~7^13~1^20~0^22~6^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'CHARGE_FACTOR', 'Column', 'Charge Factor', '', 13, 0, '-3~0^-2~0^2~0^7~0^11~7^13~1^20~0^22~6^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'CHARGE_AMOUNT', 'Column', 'Charge Amount', '', 14, 0, '-3~0^-2~0^2~0^3~Currency^7~0^11~7^13~1^14~2^20~0^22~6^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'BILL_AMOUNT', 'Column', 'Bill Amount', '', 15, 0, '-3~0^-2~0^2~0^3~Currency^7~0^11~7^13~1^14~2^20~0^22~6^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'CHARGE_DIFFERENCE', 'Column', 'Charge Difference', '', 16, 0, '-3~0^-2~0^2~0^7~0^11~7^13~1^14~2^20~0^22~6^24~0^25~IF(null(CHARGE_AMOUNT) and null(OTHER_CHARGE_AMOUNT), null(), CHARGE_AMOUNT - OTHER_CHARGE_AMOUNT)^28~BILLING_DIFFERENCE_COLUMN^29~DIFFERENCE=CHARGE_DIFFERENCE;AMOUNT=CHARGE_AMOUNT^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'BILL_DIFFERENCE', 'Column', 'Bill Difference', '', 17, 0, '-3~0^-2~0^2~0^7~0^11~7^13~1^14~2^20~0^22~6^24~0^25~IF(null(BILL_AMOUNT) and null(BILL_CHARGE_AMOUNT), null(), BILL_AMOUNT - BILL_CHARGE_AMOUNT)^28~BILLING_DIFFERENCE_COLUMN^29~DIFFERENCE=BILL_DIFFERENCE;AMOUNT=BILL_AMOUNT^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'DISPUTE_STATUS', 'Column', 'Dispute Status', '', 18, 0, '-3~0^-2~0^1~s (Special List)^2~0^7~0^13~0^16~SP.GET_SYSTEM_LABEL_VALUES;#0;"Billing;"Status;"Values;"?^19~IF ( NULL ( ORIG_DISPUTE_STATUS ) , "label:mustInitiateFirst", "" )^20~0^22~6^24~0^28~BILLING_STATUS_CODES^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'ORIG_DISPUTE_STATUS', 'Column', 'Orig Dispute Status', '', 19, 1, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~6^24~0^25~DISPUTE_STATUS^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'OTHER_CHARGE_AMOUNT', 'Column', 'Other Charge Amount', '', 20, 1, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~6^24~0^25~RIGHT.CHARGE_AMOUNT^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'OTHER_BILL_AMOUNT', 'Column', 'Other Bill Amount', '', 21, 1, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~6^24~0^25~RIGHT.BILL_AMOUNT^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'ENTITY_NAME', 'Label', 'Billing Entity', '', 0, 0, '1101~2', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'PRODUCT_NAME', 'Label', 'Product', '', 1, 0, '-3~0^-2~0^1101~2', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'STATEMENT_TYPE_NAME', 'Label', 'Statement Type', '', 2, 0, '-3~0^-2~0^1101~2', v_CHILD_OBJECT_ID);
            END;
             
            <<L47>>
            DECLARE
               v_PARENT_OBJECT_ID NUMBER(9) := L44.v_OBJECT_ID;
               v_OBJECT_ID NUMBER(9);
            BEGIN
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'CHARGE_DETAILS_REPORT_Grid_COMBINATION_COMPARE', 'Grid', '-', '', 0, 0, '-3~0^-2~0^305~0^308~0', v_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'DRILL_IN', 'Action', 'More Charge Details...', '', 0, 0, '1006~2^1007~Billing.ChargeDetailsComparison;PRODUCT_ID=-CHARGE_ID', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'CHARGE_DATE', 'Column', 'Charge Date', '', 0, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~1^24~1^28~BILLING_STATEMENT_DATE^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'CHARGE_END_DATE', 'Column', '', '', 1, 1, '-3~0^-2~0^2~0^7~0^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'COMPONENT_ID', 'Column', '', '', 2, 1, '-3~0^-2~0^2~0^7~0^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'CHARGE_ID', 'Column', '', '', 3, 1, '-3~0^-2~0^2~0^7~0^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'COMBINED_CHARGE_ID', 'Column', '', '', 4, 1, '-3~0^-2~0^2~0^7~0^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'CHARGE_VIEW_TYPE', 'Column', '', '', 5, 1, '-3~0^-2~0^2~0^7~0^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'COMPONENT_NAME', 'Column', '', '', 6, 0, '', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'COMPONENT_AMOUNT', 'Column', '', '', 7, 0, '-3~0^-2~0^2~0^7~0^11~7^13~1^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'BILL_COMPONENT_AMOUNT', 'Column', '', '', 8, 0, '-3~0^-2~0^2~0^7~0^11~7^13~1^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'COEFFICIENT', 'Column', '', '', 9, 0, '-3~0^-2~0^2~0^7~0^11~7^13~1^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'CHARGE_QUANTITY', 'Column', 'Charge Quantity', '', 10, 0, '-3~0^-2~0^2~0^7~0^11~7^13~1^14~2^20~0^22~6^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'BILL_QUANTITY', 'Column', 'Bill Quantity', '', 11, 0, '-3~0^-2~0^2~0^7~0^11~7^13~1^14~2^20~0^22~6^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'CHARGE_RATE', 'Column', 'Charge Rate', '', 12, 0, '-3~0^-2~0^2~0^3~Currency^7~0^11~7^13~1^20~0^22~6^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'CHARGE_FACTOR', 'Column', 'Charge Factor', '', 13, 0, '-3~0^-2~0^2~0^7~0^11~7^13~1^20~0^22~6^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'CHARGE_AMOUNT', 'Column', 'Charge Amount', '', 14, 0, '-3~0^-2~0^2~0^3~Currency^7~0^11~7^13~1^14~2^20~0^22~6^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'BILL_AMOUNT', 'Column', 'Bill Amount', '', 15, 0, '-3~0^-2~0^2~0^3~Currency^7~0^11~7^13~1^14~2^20~0^22~6^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'DISPUTE_STATUS', 'Column', 'Dispute Status', '', 16, 1, '-3~0^-2~0^1~x (No Edit)^2~0^7~0^13~0^20~0^22~6^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'OTHER_CHARGE_AMOUNT', 'Column', 'Other Charge Amount', '', 17, 1, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~6^24~0^25~LEFT.CHARGE_AMOUNT^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'CHARGE_DIFFERENCE', 'Column', 'Charge Difference', '', 18, 0, '-3~0^-2~0^2~0^7~0^13~1^14~2^20~0^22~6^24~0^25~IF(null(CHARGE_AMOUNT) and null(OTHER_CHARGE_AMOUNT), null(), CHARGE_AMOUNT - OTHER_CHARGE_AMOUNT)^28~BILLING_DIFFERENCE_COLUMN^29~DIFFERENCE=CHARGE_DIFFERENCE;AMOUNT=CHARGE_AMOUNT^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'OTHER_BILL_AMOUNT', 'Column', 'Other Bill Amount', '', 19, 1, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~6^24~0^25~LEFT.BILL_AMOUNT^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'BILL_DIFFERENCE', 'Column', 'Bill Difference', '', 20, 0, '-3~0^-2~0^2~0^7~0^13~1^14~2^20~0^22~6^24~0^25~IF(null(BILL_AMOUNT) and null(BILL_CHARGE_AMOUNT), null(), BILL_AMOUNT - BILL_CHARGE_AMOUNT)^28~BILLING_DIFFERENCE_COLUMN^29~DIFFERENCE=BILL_DIFFERENCE;AMOUNT=BILL_AMOUNT^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'STATEMENT_DATE_RANGE', 'Label', 'Statement Date', '', 0, 0, '-3~0^-2~0^1101~2', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'COMPONENT_NAME', 'Label', 'Component', '', 1, 0, '-3~0^-2~0^1101~2', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'STATEMENT_TYPE_NAME', 'Label', 'Statement Type', '', 2, 0, '-3~0^-2~0^1101~2', v_CHILD_OBJECT_ID);
            END;
             
            <<L48>>
            DECLARE
               v_PARENT_OBJECT_ID NUMBER(9) := L44.v_OBJECT_ID;
               v_OBJECT_ID NUMBER(9);
            BEGIN
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'CHARGE_DETAILS_REPORT_Grid_FORMULA', 'Grid', '-', '', 0, 0, '-3~0^-2~0^305~0^307~Anchored^308~1', v_OBJECT_ID);
               <<L49>>
               DECLARE
                  v_PARENT_OBJECT_ID NUMBER(9) := L48.v_OBJECT_ID;
                  v_OBJECT_ID NUMBER(9);
               BEGIN
                  SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'DISPUTE_DETAILS', 'Action', 'Dispute Details...', '', 0, 0, '-3~0^-2~0^1006~8^1007~NA', v_OBJECT_ID);
                  SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SHOW_DETAILS', 'Action', 'Show Details', '', 0, 0, '1006~2^1007~Billing.ChargeDisputeDetails;STATEMENT_TYPE1=STATEMENT_TYPE;STATEMENT_STATE1=STATEMENT_STATE', v_CHILD_OBJECT_ID);
                  SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'REFRESH', 'Action', 'Refresh', '', 1, 0, '-3~0^-2~0^1006~6^1007~Billing.ChargeDetailsComparison', v_CHILD_OBJECT_ID);
               END;
                
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'CHARGE_DATE', 'Column', 'Charge Date', '', 0, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~1^24~1^28~BILLING_STATEMENT_DATE^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'ITERATOR1_NAME', 'Column', '', '', 1, 0, '-3~0^-2~0^2~0^7~0^13~1^20~0^22~7^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'ITERATOR1_VAL', 'Column', '-', '', 2, 0, '-3~0^-2~0^2~0^7~0^13~1^20~0^22~1^24~1^27~ITERATOR1_NAME^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'ITERATOR2_NAME', 'Column', '', '', 3, 0, '-3~0^-2~0^2~0^7~0^13~1^20~0^22~7^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'ITERATOR2_VAL', 'Column', '-', '', 4, 0, '-3~0^-2~0^2~0^7~0^13~1^20~0^22~1^24~1^27~ITERATOR2_NAME^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'ITERATOR3_NAME', 'Column', '', '', 5, 0, '-3~0^-2~0^2~0^7~0^13~1^20~0^22~7^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'ITERATOR3_VAL', 'Column', '-', '', 6, 0, '-3~0^-2~0^2~0^7~0^13~1^20~0^22~1^24~1^27~ITERATOR3_NAME^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'ITERATOR4_NAME', 'Column', '', '', 7, 0, '-3~0^-2~0^2~0^7~0^13~1^20~0^22~7^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'ITERATOR4_VAL', 'Column', '-', '', 8, 0, '-3~0^-2~0^2~0^7~0^13~1^20~0^22~1^24~1^27~ITERATOR4_NAME^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'ITERATOR5_NAME', 'Column', '', '', 9, 0, '-3~0^-2~0^2~0^7~0^13~1^20~0^22~7^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'ITERATOR5_VAL', 'Column', '-', '', 10, 0, '-3~0^-2~0^2~0^7~0^13~1^20~0^22~1^24~1^27~ITERATOR5_NAME^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'CHARGE_QUANTITY', 'Column', 'Charge Quantity', '', 11, 0, '-3~0^-2~0^2~0^7~0^11~7^13~0^14~2^20~0^22~6^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'BILL_QUANTITY', 'Column', 'Bill Quantity', '', 12, 0, '-3~0^-2~0^2~0^7~0^11~7^13~1^14~2^20~0^22~6^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'CHARGE_RATE', 'Column', 'Charge Rate', '', 13, 0, '-3~0^-2~0^2~0^3~Currency^7~0^11~7^13~1^20~0^22~6^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'CHARGE_FACTOR', 'Column', 'Charge Factor', '', 14, 0, '-3~0^-2~0^2~0^7~0^11~7^13~1^20~0^22~6^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'CHARGE_AMOUNT', 'Column', 'Charge Amount', '', 15, 0, '-3~0^-2~0^2~0^3~Currency^7~0^11~7^13~1^14~2^20~0^22~6^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'BILL_AMOUNT', 'Column', 'Bill Amount', '', 16, 0, '-3~0^-2~0^2~0^3~Currency^7~0^11~7^13~1^14~2^20~0^22~6^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'CHARGE_DIFFERENCE', 'Column', 'Charge Difference', '', 17, 0, '-3~0^-2~0^2~0^7~0^11~7^13~1^14~2^20~0^22~6^24~0^25~IF(null(CHARGE_AMOUNT) and null(OTHER_CHARGE_AMOUNT), null(), CHARGE_AMOUNT - OTHER_CHARGE_AMOUNT)^28~BILLING_DIFFERENCE_COLUMN^29~DIFFERENCE=CHARGE_DIFFERENCE;AMOUNT=CHARGE_AMOUNT^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'BILL_DIFFERENCE', 'Column', 'Bill Difference', '', 18, 0, '-3~0^-2~0^2~0^3~###,###,##0.00^7~0^11~7^13~1^14~2^20~0^22~6^24~0^25~IF(null(BILL_AMOUNT) and null(BILL_CHARGE_AMOUNT), null(), BILL_AMOUNT - BILL_CHARGE_AMOUNT)^28~BILLING_DIFFERENCE_COLUMN^29~DIFFERENCE=BILL_DIFFERENCE;AMOUNT=BILL_AMOUNT^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'DISPUTE_STATUS', 'Column', 'Dispute Status', '', 19, 0, '-3~0^-2~0^1~s (Special List)^2~0^7~0^13~0^16~SP.GET_SYSTEM_LABEL_VALUES;#0;"Billing;"Status;"Values;"?^19~IF ( NULL ( ORIG_DISPUTE_STATUS ) , "label:mustInitiateFirst", "" )^20~0^22~6^24~0^28~BILLING_STATUS_CODES^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'ORIG_DISPUTE_STATUS', 'Column', 'Orig Dispute Status', '', 20, 1, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~6^24~0^25~DISPUTE_STATUS^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'OTHER_CHARGE_AMOUNT', 'Column', 'Other Charge Amount', '', 21, 1, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~6^24~0^25~RIGHT.CHARGE_AMOUNT^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'OTHER_BILL_AMOUNT', 'Column', 'Other Bill Amount', '', 22, 1, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~6^24~0^25~RIGHT.BILL_AMOUNT^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'VARIABLE_NAME', 'Column', '', '', 23, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~2^24~0^31~0^32~1', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'VARIABLE_VALUE', 'Column', '', '', 24, 0, '-3~0^-2~0^2~0^7~0^11~7^13~0^20~0^22~5^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'ENTITY_NAME', 'Label', 'Billing Entity', '', 0, 0, '1101~2', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'PRODUCT_NAME', 'Label', 'Product', '', 1, 0, '-3~0^-2~0^1101~2', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'STATEMENT_TYPE_NAME', 'Label', 'Statement Type', '', 2, 0, '-3~0^-2~0^1101~2', v_CHILD_OBJECT_ID);
            END;
             
            <<L50>>
            DECLARE
               v_PARENT_OBJECT_ID NUMBER(9) := L44.v_OBJECT_ID;
               v_OBJECT_ID NUMBER(9);
            BEGIN
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'CHARGE_DETAILS_REPORT_Grid_FORMULA_COMPARE', 'Grid', '-', '', 0, 0, '-3~0^-2~0^305~0^307~Anchored^308~1', v_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'CHARGE_DATE', 'Column', 'Charge Date', '', 0, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~1^24~1^28~BILLING_STATEMENT_DATE^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'ITERATOR1_NAME', 'Column', '', '', 1, 0, '-3~0^-2~0^2~0^7~0^13~1^20~0^22~7^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'ITERATOR1_VAL', 'Column', '-', '', 2, 0, '-3~0^-2~0^2~0^7~0^13~1^20~0^22~1^24~1^27~ITERATOR1_NAME^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'ITERATOR2_NAME', 'Column', '', '', 3, 0, '-3~0^-2~0^2~0^7~0^13~1^20~0^22~7^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'ITERATOR2_VAL', 'Column', '-', '', 4, 0, '-3~0^-2~0^2~0^7~0^13~1^20~0^22~1^24~1^27~ITERATOR2_NAME^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'ITERATOR3_NAME', 'Column', '', '', 5, 0, '-3~0^-2~0^2~0^7~0^13~1^20~0^22~7^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'ITERATOR3_VAL', 'Column', '-', '', 6, 0, '-3~0^-2~0^2~0^7~0^13~1^20~0^22~1^24~1^27~ITERATOR3_NAME^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'ITERATOR4_NAME', 'Column', '', '', 7, 0, '-3~0^-2~0^2~0^7~0^13~1^20~0^22~1^24~1^27~ITERATOR4_NAME^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'ITERATOR4_VAL', 'Column', '-', '', 8, 0, '-3~0^-2~0^2~0^7~0^13~1^20~0^22~1^24~1^27~ITERATOR4_NAME^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'ITERATOR5_NAME', 'Column', '', '', 9, 0, '-3~0^-2~0^2~0^7~0^13~1^20~0^22~7^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'ITERATOR5_VAL', 'Column', '-', '', 10, 0, '-3~0^-2~0^2~0^7~0^13~1^20~0^22~1^24~1^27~ITERATOR5_NAME^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'CHARGE_QUANTITY', 'Column', 'Charge Quantity', '', 11, 0, '-3~0^-2~0^2~0^7~0^11~7^13~1^14~2^20~0^22~6^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'BILL_QUANTITY', 'Column', 'Bill Quantity', '', 12, 0, '-3~0^-2~0^2~0^7~0^11~7^13~1^14~2^20~0^22~6^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'CHARGE_RATE', 'Column', 'Charge Rate', '', 13, 0, '-3~0^-2~0^2~0^3~Currency^7~0^11~7^13~0^20~0^22~6^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'CHARGE_FACTOR', 'Column', 'Charge Factor', '', 14, 0, '-3~0^-2~0^2~0^7~0^11~7^13~1^20~0^22~6^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'CHARGE_AMOUNT', 'Column', 'Charge Amount', '', 15, 0, '-3~0^-2~0^2~0^3~Currency^7~0^11~7^13~1^14~2^20~0^22~6^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'BILL_AMOUNT', 'Column', 'Bill Amount', '', 16, 0, '-3~0^-2~0^2~0^3~Currency^7~0^11~7^13~1^14~2^20~0^22~6^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'OTHER_CHARGE_AMOUNT', 'Column', 'Other Charge Amount', '', 17, 1, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~6^24~0^25~LEFT.CHARGE_AMOUNT^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'CHARGE_DIFFERENCE', 'Column', 'Charge Difference', '', 18, 0, '-3~0^-2~0^2~0^7~0^11~7^13~1^14~2^20~0^22~6^24~0^25~IF(null(CHARGE_AMOUNT) and null(OTHER_CHARGE_AMOUNT), null(), CHARGE_AMOUNT - OTHER_CHARGE_AMOUNT)^28~BILLING_DIFFERENCE_COLUMN^29~DIFFERENCE=CHARGE_DIFFERENCE;AMOUNT=CHARGE_AMOUNT^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'OTHER_BILL_AMOUNT', 'Column', 'Other Bill Amount', '', 19, 1, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~6^24~0^25~LEFT.BILL_AMOUNT^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'BILL_DIFFERENCE', 'Column', 'Bill Difference', '', 20, 0, '-3~0^-2~0^2~0^7~0^11~7^13~1^14~2^20~0^22~6^24~0^25~IF(null(BILL_AMOUNT) and null(BILL_CHARGE_AMOUNT), null(), BILL_AMOUNT - BILL_CHARGE_AMOUNT)^28~BILLING_DIFFERENCE_COLUMN^29~DIFFERENCE=BILL_DIFFERENCE;AMOUNT=BILL_AMOUNT^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'DISPUTE_STATUS', 'Column', 'Dispute Status', '', 21, 1, '-3~0^-2~0^1~x (No Edit)^2~0^7~0^13~0^20~0^22~6^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'VARIABLE_NAME', 'Column', '', '', 22, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~2^24~0^31~0^32~1', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'VARIABLE_VALUE', 'Column', '', '', 23, 0, '-3~0^-2~0^2~0^7~0^11~7^13~0^20~0^22~5^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'STATEMENT_DATE_RANGE', 'Label', 'Statement Date', '', 0, 0, '-3~0^-2~0^1101~2', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'COMPONENT_NAME', 'Label', 'Component', '', 1, 0, '-3~0^-2~0^1101~2', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'STATEMENT_TYPE_NAME', 'Label', 'Statement Type', '', 2, 0, '-3~0^-2~0^1101~2', v_CHILD_OBJECT_ID);
            END;
             
         END;
          
      END;
       
      -------------------------------------
      --   Billing.InvoiceLineItems
      -------------------------------------
      <<L51>>
      DECLARE
         v_PARENT_OBJECT_ID NUMBER(9) := L0.v_OBJECT_ID;
         v_OBJECT_ID NUMBER(9);
      BEGIN
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'Billing.InvoiceLineItems', 'System View', 'Invoice Line Items', '', 9, 0, '-3~0^-2~0^801~com.newenergyassoc.ro.mightyReport.MightyReportPanel', v_OBJECT_ID);
         <<L52>>
         DECLARE
            v_PARENT_OBJECT_ID NUMBER(9) := L51.v_OBJECT_ID;
            v_OBJECT_ID NUMBER(9);
         BEGIN
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'INVOICE_LINE_ITEMS_REPORT', 'Report', 'Invoice Line Items Report', '', 0, 0, '-3~0^-2~0^401~BSJ.GET_INVOICE_LINE_ITEMS_REPORT^402~1^406~0', v_OBJECT_ID);
            <<L53>>
            DECLARE
               v_PARENT_OBJECT_ID NUMBER(9) := L52.v_OBJECT_ID;
               v_OBJECT_ID NUMBER(9);
            BEGIN
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'INVOICE_LINE_ITEMS_REPORT_Grid', 'Grid', 'Invoice Line Items Report Grid', '', 0, 0, '-3~0^-2~0^301~BSJ.PUT_INVOICE_LINE_ITEM;INVOICE_DATE_STRING=INVOICE_DATE^305~1^308~0^310~com.newenergyassoc.ro.billing.LineItemEditorPolicy', v_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'EDIT_LINE_ITEM', 'Action', 'Edit Line Item...', '', 0, 0, '-3~0^-2~0^1001~E^1002~ALT SHIFT G^1006~10^1007~MODE=0', v_CHILD_OBJECT_ID);
               <<L54>>
               DECLARE
                  v_PARENT_OBJECT_ID NUMBER(9) := L53.v_OBJECT_ID;
                  v_OBJECT_ID NUMBER(9);
               BEGIN
                  SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'DELETE_LINE_ITEM', 'Action', 'Delete Line Item...', '', 1, 0, '-3~0^-2~0^1006~8^1007~NA', v_OBJECT_ID);
                  SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'DELETE_WARNING', 'Action', '', '', 0, 0, '-3~0^-2~0^1006~5^1007~If(TRUE, "label:deleteLineItemWarning", "")', v_CHILD_OBJECT_ID);
                  SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'DELETE_PROCEDURE', 'Action', '', '', 1, 0, '1006~3^1007~BSJ.DELETE_INVOICE_LINE_ITEM', v_CHILD_OBJECT_ID);
                  SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'REFRESH_REPORT', 'Action', '', '', 2, 0, '1006~6^1007~Billing.InvoiceLineItems', v_CHILD_OBJECT_ID);
               END;
                
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'ADD_LINE_ITEM', 'Action', 'Add Line Item...', '', 2, 0, '-3~0^-2~0^1006~10^1007~MODE=2;IS_MANUAL_LINE_ITEM=1', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'VIEW_LINE_ITEM', 'Action', 'View Line Item...', '', 3, 1, '-3~0^-2~0^1006~10^1007~MODE=1', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'INVOICE_ID', 'Column', 'Invoice Id', '', 0, 1, '-3~0^-2~0^2~0^7~0^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'LINE_ITEM_NAME', 'Column', 'Name', '', 0, 0, '-3~0^-2~0^1~e (Standard Edit)^2~0^7~0^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'LINE_ITEM_CATEGORY', 'Column', 'Category', '', 1, 0, '-3~0^-2~0^1~s (Special List)^2~0^7~0^13~0^16~|BSJ.GET_INVOICE_CATEGORIES;ENTITY_ID;INVOICE_DATE;#0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'LINE_ITEM_TYPE', 'Column', 'Type', '', 2, 1, '-3~0^-2~0^1~s (Special List)^2~0^7~0^13~0^16~BSJ.GET_INVOICE_LINE_ITEM_TYPES;IS_MANUAL_LINE_ITEM^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'LINE_ITEM_QUANTITY', 'Column', 'Quantity', '', 3, 0, '-3~0^-2~0^1~n (Numeric Edit)^2~0^3~###,###,##0.00^7~0^11~7^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'LINE_ITEM_RATE', 'Column', 'Rate', '', 4, 0, '-3~0^-2~0^1~n (Numeric Edit)^2~0^3~###,###,##0.00^7~0^11~7^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'LINE_ITEM_AMOUNT', 'Column', 'Charge Amount', '', 5, 0, '-3~0^-2~0^1~n (Numeric Edit)^2~0^3~Currency^7~0^11~7^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'LINE_ITEM_BILL_AMOUNT', 'Column', 'Billing Amount', '', 6, 0, '-3~0^-2~0^1~n (Numeric Edit)^2~0^3~Currency^7~0^11~7^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'DEFAULT_DISPLAY', 'Column', 'Default Amount Type', '', 7, 1, '-3~0^-2~0^1~c (Combo Box)^2~0^5~CHARGE|BILL^7~0^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'INVOICE_GROUP_ID', 'Column', 'Invoice Group', '', 8, 1, '-3~0^-2~0^1~o (Object List)^2~0^7~0^8~INVOICE_GROUP^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'INVOICE_GROUP_ORDER', 'Column', 'Group Order', '', 9, 1, '-3~0^-2~0^1~n (Numeric Edit)^2~0^3~###,###,##0^7~0^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'EXCLUDE_FROM_INVOICE_TOTAL', 'Column', 'Exclude from Invoice Total', '', 10, 1, '-3~0^-2~0^1~k (Checkbox)^2~0^7~0^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'IS_TAXED', 'Column', 'Is Taxed', '', 11, 1, '-3~0^-2~0^1~k (Checkbox)^2~0^7~0^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'STATEMENT_TYPE', 'Column', 'Statement Type', '', 12, 1, '-3~0^-2~0^1~o (Object List)^2~0^7~0^8~STATEMENT_TYPE^13~0^20~1^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'BEGIN_DATE', 'Column', 'Begin Date', '', 13, 1, '-3~0^-2~0^2~0^3~Short Date^7~0^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'END_DATE', 'Column', 'End Date', '', 14, 1, '-3~0^-2~0^2~0^3~Short Date^7~0^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TAX_COMPONENT_ID', 'Column', 'Tax Component', '', 15, 1, '-3~0^-2~0^1~s (Special List)^2~0^7~0^13~0^16~BSJ.TAX_COMPONENTS^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TAX_GEOGRAPHY_ID', 'Column', 'Tax Location', '', 16, 1, '-3~0^-2~0^2~0^7~0^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'IS_MANUAL_LINE_ITEM', 'Column', 'Is Manual Line Item', '', 17, 1, '-3~0^-2~0^2~0^7~0^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
            END;
             
         END;
          
      END;
       
      SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'Billing.ExportStatements', 'System View', 'Billing.ExportStatements', '', 10, 0, '801~com.newenergyassoc.ro.billing.BillingExportContentPanel', v_CHILD_OBJECT_ID);
      -------------------------------------
      --   Billing.SummaryBillingCharges
      -------------------------------------
      <<L55>>
      DECLARE
         v_PARENT_OBJECT_ID NUMBER(9) := L0.v_OBJECT_ID;
         v_OBJECT_ID NUMBER(9);
      BEGIN
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'Billing.SummaryBillingCharges', 'System View', 'Billing Charges', '', 10, 0, '-3~0^-2~0^801~com.newenergyassoc.ro.mightyReport.MightyReportPanel', v_OBJECT_ID);
         <<L56>>
         DECLARE
            v_PARENT_OBJECT_ID NUMBER(9) := L55.v_OBJECT_ID;
            v_OBJECT_ID NUMBER(9);
         BEGIN
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'SUMMARY_BILLING_CHARGES', 'Report', 'Summary Billing Charges', '', 0, 0, '-3~0^-2~0^401~BSJ.BILLING_SUMMARY;STATEMENT_DATE=ORIGINAL_DATE;STATEMENT_END_DATE=ORIGINAL_END_DATE^402~1^403~Normal Grid^405~0^406~0', v_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SUMMARY_BILLING_CHARGES_Grid', 'Grid', 'Summary Billing Charges Grid', '', 0, 0, '-3~0^-2~0^-1~Billing.SummaryGrid^305~0^308~0', v_CHILD_OBJECT_ID);
         END;
          
      END;
       
      -------------------------------------
      --   Billing.ComparisonBillingCharges
      -------------------------------------
      <<L57>>
      DECLARE
         v_PARENT_OBJECT_ID NUMBER(9) := L0.v_OBJECT_ID;
         v_OBJECT_ID NUMBER(9);
      BEGIN
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'Billing.ComparisonBillingCharges', 'System View', 'Billing Charges', '', 11, 0, '-3~0^-2~0^801~com.newenergyassoc.ro.mightyReport.MightyReportPanel', v_OBJECT_ID);
         <<L58>>
         DECLARE
            v_PARENT_OBJECT_ID NUMBER(9) := L57.v_OBJECT_ID;
            v_OBJECT_ID NUMBER(9);
         BEGIN
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'COMPARISON_BILLING_CHARGES', 'Report', 'Comparison Billing Charges', '', 0, 0, '-3~0^-2~0^401~BSJ.BILLING_COMPARISON;STATEMENT_DATE=ORIGINAL_DATE;STATEMENT_END_DATE=ORIGINAL_END_DATE;STATEMENT_TYPE1=STATEMENT_TYPE1_ID;STATEMENT_TYPE2=STATEMENT_TYPE2_ID^402~1^403~Normal Grid^405~0^406~0', v_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'COMPARISON_BILLING_CHARGES_Grid', 'Grid', 'Comparison Billing Charges Grid', '', 0, 0, '-3~0^-2~0^-1~Billing.ComparisonGrid^305~0^308~0', v_CHILD_OBJECT_ID);
         END;
          
      END;
       
      -------------------------------------
      --   Billing.ChargeDisputeDetails
      -------------------------------------
      <<L59>>
      DECLARE
         v_PARENT_OBJECT_ID NUMBER(9) := L0.v_OBJECT_ID;
         v_OBJECT_ID NUMBER(9);
      BEGIN
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'Billing.ChargeDisputeDetails', 'System View', 'Dispute Details', '', 12, 0, '-3~0^-2~0^801~com.newenergyassoc.ro.billing.ChargeDisputeDetailsContentPanel', v_OBJECT_ID);
         <<L60>>
         DECLARE
            v_PARENT_OBJECT_ID NUMBER(9) := L59.v_OBJECT_ID;
            v_OBJECT_ID NUMBER(9);
         BEGIN
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'CHARGE_DISPUTE_DETAILS_REPORT', 'Report', 'Charge Dispute Details', '', 0, 0, '-3~0^-2~0^401~BSJ.GET_CHARGE_DISPUTE_DETAILS;STATEMENT_DATE=ORIGINAL_DATE;STATEMENT_END_DATE=ORIGINAL_END_DATE^402~1^403~Normal Grid^406~0', v_OBJECT_ID);
            <<L61>>
            DECLARE
               v_PARENT_OBJECT_ID NUMBER(9) := L60.v_OBJECT_ID;
               v_OBJECT_ID NUMBER(9);
            BEGIN
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'CHARGE_DISPUTE_DETAILS_REPORT_Grid', 'Grid', 'Charge Dispute Details Report Grid', '', 0, 0, '-3~0^-2~0^301~BSJ.PUT_BILLING_CHARGE_DISPUTE^305~0^308~0', v_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'DISPUTE_DATE', 'Column', '', '', 0, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^24~1^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'STATEMENT_TYPE', 'Column', '', '', 1, 1, '-3~0^-2~0^2~0^7~0^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'STATEMENT_STATE', 'Column', '', '', 2, 1, '-3~0^-2~0^2~0^7~0^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'BILLED_AMOUNT', 'Column', '', '', 3, 0, '-3~0^-2~0^1~n (Numeric Edit)^2~0^7~0^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'CORRECT_AMOUNT', 'Column', '', '', 4, 0, '-3~0^-2~0^1~n (Numeric Edit)^2~0^7~0^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'INITIATE', 'Column', 'Inititate?', '', 5, 0, '1~k (Checkbox)^20~1', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'DISPUTE_STATUS', 'Column', '', '', 6, 0, '-3~0^-2~0^1~s (Special List)^2~0^7~0^13~0^16~SP.GET_SYSTEM_LABEL_VALUES;#0;"Billing;"Status;"Values;"?^20~0^24~0^28~BILLING_STATUS_CODES^29~STATUS=DISPUTE_STATUS^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'MARKET_STATUS', 'Column', '', '', 7, 1, '-3~0^-2~0^2~0^7~0^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SUBMIT_STATUS', 'Column', '', '', 8, 1, '-3~0^-2~0^2~0^7~0^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'DESCR', 'Column', 'Description', '', 9, 0, '-3~0^-2~0^1~b (Big Text Edit)^2~0^7~0^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'ENTRY_DATE', 'Column', '', '', 10, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
            END;
             
         END;
          
      END;
       
END;
END;
/
