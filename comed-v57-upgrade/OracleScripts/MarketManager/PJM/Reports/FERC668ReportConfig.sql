DECLARE
   p_STATUS NUMBER;
   v_CHILD_OBJECT_ID NUMBER(9);
BEGIN
<<L0>>
DECLARE
   v_PARENT_OBJECT_ID NUMBER(9) := 0;
   v_OBJECT_ID NUMBER(9) := 0;
BEGIN
 
SO.ID_FOR_SYSTEM_OBJECT(v_PARENT_OBJECT_ID, 'Scheduling',0,'Module','Default',TRUE,v_OBJECT_ID);
v_PARENT_OBJECT_ID := v_OBJECT_ID;
SO.ID_FOR_SYSTEM_OBJECT(v_PARENT_OBJECT_ID, 'Scheduling.Other1',0,'System View','Default',TRUE,v_OBJECT_ID);
v_PARENT_OBJECT_ID := v_OBJECT_ID;
   -------------------------------------
   --   AYE_GENERATION_REVENUE
   -------------------------------------
      SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'AYE_GENERATION_REVENUE', 'Report', 'FERC 668 Report', '', 0, 0, '-3~0^-2~0^401~MM_PJM_FERC.GET_FERC_668_RPT^402~0^403~Normal Grid^406~0^409~Vertical', v_OBJECT_ID);
      -------------------------------------
      --   AYE_GENERATION_REVENUE_Grid
      -------------------------------------
      <<L1>>
      DECLARE
         v_PARENT_OBJECT_ID NUMBER(9) := L0.v_OBJECT_ID;
         v_OBJECT_ID NUMBER(9);
      BEGIN
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'AYE_GENERATION_REVENUE_Grid', 'Grid', 'Aye Generation Revenue Grid', '', 0, 0, '-3~0^-2~0^305~0^308~0', v_OBJECT_ID);
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'DAY_HOUR', 'Column', 'Date', '', 0, 0, '-3~0^-2~0^2~0^3~yyyy-MM-dd KK:mm^7~0^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'DAY', 'Column', '', '', 1, 1, '-3~0^-2~0^2~0^7~0^13~0^14~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'HOUR', 'Column', '', '', 2, 1, '-3~0^-2~0^2~0^7~0^13~0^14~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'DA_FERC_ACCT_555_MWH', 'Column', '', '', 3, 0, '-3~0^-2~0^2~0^7~0^13~0^14~2^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'DA_FERC_ACCT_555_$', 'Column', '', '', 4, 0, '-3~0^-2~0^2~0^7~0^13~0^14~2^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'DA_FERC_ACCT_447_MWH', 'Column', '', '', 5, 0, '-3~0^-2~0^2~0^7~0^13~0^14~2^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'DA_FERC_ACCT_447_$', 'Column', '', '', 6, 0, '-3~0^-2~0^2~0^7~0^13~0^14~2^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'RT_FERC_ACCT_555_MWH', 'Column', '', '', 7, 0, '-3~0^-2~0^2~0^7~0^13~0^14~2^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'RT_FERC_ACCT_555_$', 'Column', '', '', 8, 0, '-3~0^-2~0^2~0^7~0^13~0^14~2^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'RT_FERC_ACCT_447_MWH', 'Column', '', '', 9, 0, '-3~0^-2~0^2~0^7~0^13~0^14~2^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'RT_FERC_ACCT_447_$', 'Column', '', '', 10, 0, '-3~0^-2~0^2~0^7~0^13~0^14~2^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
      END;
       
      -------------------------------------
      --   AYE_GENERATION_REVENUE_Grid_DETAIL
      -------------------------------------
      <<L2>>
      DECLARE
         v_PARENT_OBJECT_ID NUMBER(9) := L0.v_OBJECT_ID;
         v_OBJECT_ID NUMBER(9);
      BEGIN
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'AYE_GENERATION_REVENUE_Grid_DETAIL', 'Grid', 'Daily Details', '', 0, 0, '-3~0^-2~0^305~0^308~0', v_OBJECT_ID);
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SHOW_HOUR_VAL_GEN_REV', 'Action', 'Show Hourly Details', '', 0, 0, '-3~0^-2~0^1006~0^1007~MM_PJM_REVENUE_REPORTS.GET_GEN_REV_RPT;ROLLUP_TO="Hour";BEGIN_DATE=SCHEDULE_DATE_DATE;END_DATE=SCHEDULE_DATE_DATE^1010~Bottom', v_CHILD_OBJECT_ID);
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SCHEDULE_DATE', 'Column', 'Date', '', 0, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'RESOURCE_NAME', 'Column', '', '', 1, 1, '-3~0^-2~0^2~0^7~0^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'DA_MW', 'Column', 'DA MWh', '', 2, 0, '-3~0^-2~0^2~0^3~###,###,##0.000^7~0^11~7^13~0^14~2^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'DA_CASH', 'Column', 'DA Cash', '', 3, 0, '-3~0^-2~0^2~0^3~###,###,##0.00^7~0^11~7^13~0^14~2^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'BAL_MW', 'Column', 'RT MWh', '', 4, 0, '-3~0^-2~0^2~0^3~###,###,##0.000^7~0^11~7^13~0^14~2^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'BAL_CASH', 'Column', 'RT Cash', '', 5, 0, '-3~0^-2~0^2~0^3~###,###,##0.00^7~0^11~7^13~0^14~2^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'ACTUAL_MW', 'Column', 'Actual MWh', '', 6, 0, '-3~0^-2~0^2~0^3~###,###,##0.000^7~0^11~7^13~0^14~2^20~0^24~0^25~DA_MW + BAL_MW^31~0', v_CHILD_OBJECT_ID);
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TOTAL_CASH', 'Column', 'Total Cash', '', 7, 0, '-3~0^-2~0^2~0^3~###,###,##0.00^7~0^11~7^13~0^14~2^20~0^24~0^25~DA_CASH + BAL_CASH^31~0', v_CHILD_OBJECT_ID);
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SCHEDULE_DATE_DATE', 'Column', '', '', 8, 1, '-3~0^-2~0^2~0^7~0^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
         <<L3>>
         DECLARE
            v_PARENT_OBJECT_ID NUMBER(9) := L2.v_OBJECT_ID;
            v_OBJECT_ID NUMBER(9);
         BEGIN
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'MM_PJM_REVENUE_REPORTS.GET_GEN_REV_RPT;ROLLUP_TO="Hour";BEGIN_DATE=SCHEDULE_DATE_DATE;END_DATE=SCHEDULE_DATE_DATE', 'Grid', 'Hourly Details', '', 0, 0, '-3~0^-2~0^305~0^308~0', v_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SCHEDULE_DATE', 'Column', 'Date', '', 0, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'RESOURCE_NAME', 'Column', '', '', 1, 1, '-3~0^-2~0^2~0^7~0^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'DA_MW', 'Column', 'DA MWh', '', 2, 0, '-3~0^-2~0^2~0^3~###,###,##0.000^7~0^11~7^13~0^14~2^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'DA_CASH', 'Column', 'DA Cash', '', 3, 0, '-3~0^-2~0^2~0^3~###,###,##0.00^7~0^11~7^13~0^14~2^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'BAL_MW', 'Column', 'RT MWh', '', 4, 0, '-3~0^-2~0^2~0^3~###,###,##0.00^7~0^11~7^13~0^14~2^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'BAL_CASH', 'Column', 'RT Cash', '', 5, 0, '-3~0^-2~0^2~0^3~###,###,##0.000^7~0^11~7^13~0^14~2^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'ACTUAL_MW', 'Column', 'Actual MWh', '', 6, 0, '-3~0^-2~0^2~0^3~###,###,##0.00^7~0^11~7^13~0^14~2^20~0^24~0^25~DA_MW + BAL_MW^31~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'ACTUAL_CASH', 'Column', 'Total Cash', '', 7, 0, '-3~0^-2~0^2~0^3~###,###,##0.00^7~0^11~7^13~0^14~2^20~0^24~0^25~DA_CASH + BAL_CASH^31~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'RESOURCE_NAME', 'Label', 'Resource', '', 0, 0, '1101~2^1102~RESOURCE_NAME', v_CHILD_OBJECT_ID);
         END;
          
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'RESOURCE', 'Label', 'Resource', '', 0, 0, '-3~0^-2~0^1101~2^1102~=RESOURCE_NAME', v_CHILD_OBJECT_ID);
      END;
       
      -------------------------------------
      --   AYE_GENERATION_REVENUE_Grid_MASTER
      -------------------------------------
      <<L4>>
      DECLARE
         v_PARENT_OBJECT_ID NUMBER(9) := L0.v_OBJECT_ID;
         v_OBJECT_ID NUMBER(9);
      BEGIN
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'AYE_GENERATION_REVENUE_Grid_MASTER', 'Grid', 'Generation Revenue Summary', '', 0, 0, '-3~0^-2~0^305~0^308~0', v_OBJECT_ID);
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'RESOURCE_NAME', 'Column', 'Unit', '', 1, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'DA_MW', 'Column', 'DA MWh', '', 2, 0, '-3~0^-2~0^2~0^3~###,###,##0.000^7~0^11~7^13~0^14~2^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'DA_CASH', 'Column', 'DA Cash', '', 3, 0, '-3~0^-2~0^2~0^3~###,###,##0.00^7~0^11~7^13~0^14~2^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'BAL_MW', 'Column', 'RT MWh', '', 4, 0, '-3~0^-2~0^2~0^3~###,###,##0.000^7~0^11~7^13~0^14~2^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'BAL_CASH', 'Column', 'RT Cash', '', 5, 0, '-3~0^-2~0^2~0^3~###,###,##0.00^7~0^11~7^13~0^14~2^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'ACTUAL_MW', 'Column', 'Actual MWh', '', 6, 0, '-3~0^-2~0^2~0^3~###,###,##0.000^7~0^11~7^13~0^14~2^20~0^24~0^25~DA_MW + BAL_MW^31~0', v_CHILD_OBJECT_ID);
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TOTAL_CASH', 'Column', '', '', 7, 0, '-3~0^-2~0^2~0^3~###,###,##0.00^7~0^11~7^13~0^14~2^20~0^24~0^25~DA_CASH + BAL_CASH^31~0', v_CHILD_OBJECT_ID);
      END;
       
      SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'PSE_ID', 'Report Filter', 'Account:', '', 0, 0, '-3~0^-2~0^501~s (Special List)^504~MM_PJM_REVENUE_REPORTS.GET_ALLOWED_PJM_ACCTS^508~1^509~,^510~30^514~0^515~0^519~0^520~0', v_CHILD_OBJECT_ID);
END;
END;
/
