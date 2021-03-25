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
   -------------------------------------
   --   Scheduling.PJM.Generation.UnitDefaults
   -------------------------------------
      SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'Scheduling.PJM.Generation.UnitDefaults', 'System View', 'Scheduling.PJM.Generation.UnitDefaults', '', 6, 0, '-3~0^-2~0', v_OBJECT_ID);
      -------------------------------------
      --   SUMMARY_REPORT
      -------------------------------------
      <<L1>>
      DECLARE
         v_PARENT_OBJECT_ID NUMBER(9) := L0.v_OBJECT_ID;
         v_OBJECT_ID NUMBER(9);
      BEGIN
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'SUMMARY_REPORT', 'Report', 'Summary', '', 1, 0, '-3~0^-2~0^401~MM_PJM_GEN_REPORTS.GET_UNIT_DETAILS_RPT^402~0^403~Normal Grid^405~0^406~0', v_OBJECT_ID);
         <<L2>>
         DECLARE
            v_PARENT_OBJECT_ID NUMBER(9) := L1.v_OBJECT_ID;
            v_OBJECT_ID NUMBER(9);
         BEGIN
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'SUMMARY_REPORT_Grid', 'Grid', 'Summary Report Grid', '', 0, 0, '-3~0^-2~0^301~TG.PUT_IT_TRAIT_SCHED_DETAIL_RPT;SCHEDULE_STATE=1^305~0^307~ResourceTrait^308~1', v_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'CURVE_EDITOR', 'Action', 'Curve Editor...', '', 0, 0, '-1~BID_CURVE_EDITOR_ACTION^1004~IS_SERIES = 1', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TO_PJM_COMPARE', 'Action', 'To PJM Comparison', '', 1, 0, '-3~0^-2~0^1006~2^1007~Scheduling.PJM.Generation.PJMComparison;TRANSACTION_ID=TRANSACTION_ID;TRAIT_GROUP_FILTER="%";INTERVAL="Day";UNIT_NAME=RESOURCE_NAME', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'CUT_DATE_SCHEDULING', 'Column', 'Date', '', 0, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~1^23~12/31/9999^24~1^31~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'RESOURCE_NAME', 'Column', 'Unit', '', 1, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~6^24~1^31~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRANSACTION_ID', 'Column', '', '', 1, 1, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~1^24~0^31~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'PSE_NAME', 'Column', 'Account', '', 2, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~6^24~0^31~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'GROUP_ORDER', 'Column', '', '', 3, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~4^24~0^31~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SET_NUMBER', 'Column', '', '', 4, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~4^24~0^31~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRAIT_ORDER', 'Column', '', '', 5, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~4^24~0^31~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRAIT_GROUP_ID', 'Column', '', '', 6, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~4^24~0^31~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRAIT_INDEX', 'Column', '', '', 8, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~4^24~0^31~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'DATA_TYPE', 'Column', '', '', 9, 0, '', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'EDIT_MASK', 'Column', '', '', 10, 0, '', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'COMBO_LIST', 'Column', '', '', 11, 0, '', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'FORMAT', 'Column', '', '', 12, 0, '', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRAIT_VAL', 'Column', '', '', 13, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~5^24~0^28~GEN_PJM_DETAILS_TOTAL^31~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'GROUP_DISPLAY_NAME', 'Column', '', '', 14, 0, '22~2', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'DISPLAY_NAME', 'Column', '', '', 15, 0, '-3~0^-2~0^2~0^7~0^13~1^20~0^22~3^24~0^31~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SUBMIT_STATUS', 'Column', 'Status', '', 16, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~6^24~0^28~BidOfferStatus^29~X=SUBMIT_STATUS^31~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'IS_SERIES', 'Column', '', '', 17, 0, '22~4', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TG.GET_BID_CURVE_EDITOR', 'Grid', 'Tg.Get Bid Curve Editor', '', 0, 0, '-3~0^-2~0^-1~Scheduling.BidCurveEditorGrid^305~0^308~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'PERIOD_ONE_STARTUP_COSTS', 'Label', 'Period 1', '', 0, 0, '-3~0^-2~0^1101~4^1102~"April 1 - September 30"', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'PERIOD_TWO_STARTUP_COSTS', 'Label', 'Period 2', '', 1, 0, '1101~3^1102~"October 1 - March 31"', v_CHILD_OBJECT_ID);
         END;
          
         <<L3>>
         DECLARE
            v_PARENT_OBJECT_ID NUMBER(9) := L1.v_OBJECT_ID;
            v_OBJECT_ID NUMBER(9);
         BEGIN
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'BTN_SUBMIT_TO_PJM', 'Report Filter', 'Submit to PJM...', '', 0, 0, '-3~0^-2~0^501~b (Button)^508~0^514~0^515~0^519~0^520~0', v_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'ACT_SUBMIT_TO_PJM', 'Action', 'Submit to PJM...', '', 0, 0, '-3~0^-2~0^1006~2^1007~Scheduling.BidOfferSubmit;CONTEXT_TYPE="Sched:PJM:eMKT:SubmitUnitDetail";ENTITY_ID=Value(TRANSACTION_ID)^1010~Top', v_CHILD_OBJECT_ID);
         END;
          
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'UNIT_TYPE', 'Report Filter', 'Unit Type', '', 1, 0, '-3~0^-2~0^501~s (Special List)^504~MM_PJM_GEN_REPORTS.GET_PUMPED_HYDRO_FILTER^508~0^514~0^515~0^518~TRANSACTION_ID^519~0^520~0', v_CHILD_OBJECT_ID);
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'PERIOD_TYPE', 'Report Filter', 'Period', '', 2, 0, '501~c (Combo Box)^502~PERIOD1|PERIOD2', v_CHILD_OBJECT_ID);
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRANSACTION_ID', 'Report Filter', 'Units', '', 3, 0, '-3~0^-2~0^501~s (Special List)^504~MM_PJM_GEN_REPORTS.GET_RESOURCE_TXN_LIST_ALL;"Unit Data;BEGIN_DATE;END_DATE;UNIT_TYPE^508~0^510~10^513~1^514~0^515~0^519~0^520~1', v_CHILD_OBJECT_ID);
      END;
       
END;
END;
/
