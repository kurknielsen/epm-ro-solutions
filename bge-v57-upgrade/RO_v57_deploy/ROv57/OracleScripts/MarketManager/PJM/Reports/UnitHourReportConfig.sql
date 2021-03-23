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
   --   Scheduling.PJM.Generation.UnitUpdates
   -------------------------------------
      SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'Scheduling.PJM.Generation.UnitUpdates', 'System View', 'Scheduling.PJM.Generation.UnitUpdates', '', 7, 0, '-3~0^-2~0', v_OBJECT_ID);
      -------------------------------------
      --   UNIT_DATA
      -------------------------------------
      <<L1>>
      DECLARE
         v_PARENT_OBJECT_ID NUMBER(9) := L0.v_OBJECT_ID;
         v_OBJECT_ID NUMBER(9);
      BEGIN
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'UNIT_DATA', 'Report', 'Unit Data', '', 2, 0, '-3~0^-2~0^401~MM_PJM_GEN_REPORTS.GET_TRAITS_WITH_STATUS_RPT;SCHEDULE_STATE=1;TRAIT_GROUP_FILTER="Summary";INTERVAL="Hour"^402~0^403~Normal Grid^405~0^406~0^409~Vertical', v_OBJECT_ID);
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'UnitUpdateChart', 'Chart', '', '', 0, 1, '-3~0^-2~0^901~9^904~Unit Updates^905~TRAIT_VAL^906~1^907~1^908~0^910~0^912~0^913~1', v_CHILD_OBJECT_ID);
         <<L2>>
         DECLARE
            v_PARENT_OBJECT_ID NUMBER(9) := L1.v_OBJECT_ID;
            v_OBJECT_ID NUMBER(9);
         BEGIN
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'UNIT_DATA_Grid', 'Grid', 'Unit Data Grid', '', 0, 0, '-3~0^-2~0^301~TG.PUT_IT_TRAIT_SCHED_DETAIL_RPT;SCHEDULE_STATE=1^305~0^307~ResourceTrait^308~1', v_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TO_PJM_COMPARISON', 'Action', 'To PJM Comparison', '', 0, 0, '-3~0^-2~0^1006~2^1007~Scheduling.PJM.Generation.PJMComparison;TRANSACTION_ID=TRANSACTION_ID;TRAIT_GROUP_FILTER="Summary";INTERVAL="Hour";UNIT_NAME=TRANSACTION_ID_TEXT', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SCHEDULE_DATE_STR', 'Column', 'Date', '', 0, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~1^24~1^31~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'GROUP_ORDER', 'Column', '', '', 1, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~4^24~0^31~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRAIT_ORDER', 'Column', '', '', 2, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~4^24~0^31~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRAIT_GROUP_ID', 'Column', '', '', 3, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~4^24~0^31~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRAIT_INDEX', 'Column', '', '', 4, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~4^24~0^31~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRAIT_GROUP_NAME', 'Column', '', '', 5, 1, '-3~0^-2~0^2~0^7~0^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'DISPLAY_NAME', 'Column', '', '', 6, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~3^24~0^31~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SET_NUMBER', 'Column', '', '', 7, 1, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~4^24~0^31~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'DATA_TYPE', 'Column', '', '', 8, 1, '-3~0^-2~0^2~0^7~0^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'EDIT_MASK', 'Column', '', '', 9, 1, '-3~0^-2~0^2~0^7~0^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'COMBO_LIST', 'Column', '', '', 10, 1, '-3~0^-2~0^2~0^7~0^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'FORMAT', 'Column', '', '', 11, 1, '-3~0^-2~0^2~0^7~0^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRAIT_VAL', 'Column', '', '', 12, 0, '-3~0^-2~0^2~0^4~0^7~0^13~0^14~0^15~0^20~0^22~5^24~0^28~GEN_PJM_HOUR_TOTAL^31~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'ROWNUM', 'Column', '', '', 13, 1, '-3~0^-2~0^2~0^7~0^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'REAL_ROWNUM', 'Column', '', '', 14, 1, '-3~0^-2~0^2~0^7~0^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'CUT_DATE_SCHEDULING', 'Column', '', '', 15, 1, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~6^24~0^31~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SUBMIT_STATUS', 'Column', '', '', 16, 0, '22~6^28~BidOfferStatus^29~X=SUBMIT_STATUS', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SUBMITTED_BY', 'Column', '', '', 17, 1, '22~6', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SUBMIT_DATE', 'Column', '', '', 18, 1, '22~6', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRAIT_VAL_NUM', 'Column', '', '', 19, 1, '-3~0^-2~0^2~0^7~0^13~0^14~0^20~0^22~5^24~0^31~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'UNIT_NAME', 'Label', 'Unit', '', 0, 0, '1101~2^1102~=TRANSACTION_ID_TEXT', v_CHILD_OBJECT_ID);
         END;
          
         <<L3>>
         DECLARE
            v_PARENT_OBJECT_ID NUMBER(9) := L1.v_OBJECT_ID;
            v_OBJECT_ID NUMBER(9);
         BEGIN
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'BTN_PJM_SUBMIT_UNIT_UPDATES', 'Report Filter', 'Submit to PJM...', '', 1, 0, '-3~0^-2~0^501~b (Button)^508~0^514~0^515~0^519~0^520~0', v_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'ACT_PJM_SUBMIT_UNIT_UPDATES', 'Action', 'Submit to PJM...', '', 0, 0, '-3~0^-2~0^1006~2^1007~Scheduling.BidOfferSubmit;CONTEXT_TYPE="Sched:PJM:eMKT:SubmitUnitUpdate";TRANSACTION_ID=Value(TRANSACTION_ID)', v_CHILD_OBJECT_ID);
         END;
          
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'FROM_DATE', 'Report Filter', 'From Date', '', 4, 0, '-3~0^-2~0^501~d (Date Picker)^508~0^514~0^515~0^517~Roll Forward Hourly Unit Data^519~0^520~0', v_CHILD_OBJECT_ID);
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TO_DATE', 'Report Filter', 'To Date', '', 5, 0, '-3~0^-2~0^501~d (Date Picker)^508~0^514~0^515~0^517~Roll Forward Hourly Unit Data^519~0^520~0', v_CHILD_OBJECT_ID);
         <<L4>>
         DECLARE
            v_PARENT_OBJECT_ID NUMBER(9) := L1.v_OBJECT_ID;
            v_OBJECT_ID NUMBER(9);
         BEGIN
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'ROLL_DATA_FORWARD', 'Report Filter', 'Roll Forward All Units', '', 6, 0, '-3~0^-2~0^501~b (Button)^508~0^514~0^515~0^517~Roll Forward Hourly Unit Data^519~0^520~0', v_OBJECT_ID);
            <<L5>>
            DECLARE
               v_PARENT_OBJECT_ID NUMBER(9) := L4.v_OBJECT_ID;
               v_OBJECT_ID NUMBER(9);
            BEGIN
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'ACT_ROLL_DATA_FORWARD', 'Action', 'Roll Forward All Units', '', 0, 0, '-3~0^-2~0^1006~5^1007~="You are about to delete all hourly Unit Update data on " + Format(TO_DATE,"MMMM dd, yyyy") + " and replace it with data from " + Format(FROM_DATE,"MMMM dd, yyyy") + ".  Do you want to continue?"', v_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'ROLL_FORWARD', 'Action', 'Roll Forward All Units', '', 0, 0, '1006~3^1007~MM_PJM_GEN_REPORTS.ROLL_FORWARD_UNIT_UPDATES;DELETE_EXISTING_DATA=1', v_CHILD_OBJECT_ID);
            END;
             
         END;
          
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRANSACTION_ID', 'Report Filter', 'Units', '', 10, 0, '-3~0^-2~0^501~s (Special List)^504~MM_PJM_GEN_REPORTS.GET_RESOURCE_TXN_LIST;"Unit Data;BEGIN_DATE;END_DATE^508~0^510~10^513~1^514~0^515~0^519~0^520~1', v_CHILD_OBJECT_ID);
      END;
       
END;
END;
/
