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
   --   Scheduling
   -------------------------------------
      SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'Scheduling', 'Module', 'Scheduling', '', 0, 0, '-3~0^-2~0', v_OBJECT_ID);

      -------------------------------------
      --   Scheduling.PJM.Generation.UnitSchedules
      -------------------------------------
      <<L130>>
      DECLARE
         v_PARENT_OBJECT_ID NUMBER(9) := L0.v_OBJECT_ID;
         v_OBJECT_ID NUMBER(9);
      BEGIN
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'Scheduling.PJM.Generation.UnitSchedules', 'System View', 'Scheduling.PJM.Generation.UnitSchedules', '', 0, 0, '-3~0^-2~0', v_OBJECT_ID);
         <<L131>>
         DECLARE
            v_PARENT_OBJECT_ID NUMBER(9) := L130.v_OBJECT_ID;
            v_OBJECT_ID NUMBER(9);
         BEGIN
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'PJM_SCHEDULE_DETAILS', 'Report', 'Schedule Details', '', 1, 0, '-3~0^-2~0^401~MM_PJM_GEN_REPORTS.GET_UNIT_DETAILS_RPT;IS_SCHEDULE_DETAILS=1^402~0^406~0', v_OBJECT_ID);
            <<L132>>
            DECLARE
               v_PARENT_OBJECT_ID NUMBER(9) := L131.v_OBJECT_ID;
               v_OBJECT_ID NUMBER(9);
            BEGIN
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'PJM_SCHEDULE_DETAILS_Grid', 'Grid', 'Summary Report Grid', '', 0, 0, '-3~0^-2~0^301~TG.PUT_IT_TRAIT_SCHED_DETAIL_RPT;SCHEDULE_STATE=1^305~0^307~ResourceTrait^308~1', v_OBJECT_ID);
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
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRAIT_VAL', 'Column', '', '', 13, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~5^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'GROUP_DISPLAY_NAME', 'Column', '', '', 14, 0, '22~2', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'DISPLAY_NAME', 'Column', '', '', 15, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~3^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SUBMIT_STATUS', 'Column', 'Status', '', 16, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~6^24~0^28~BidOfferStatus^29~X=SUBMIT_STATUS^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'IS_SERIES', 'Column', '', '', 17, 0, '22~4', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRANSACTION_ALIAS', 'Column', 'Schedule Name', '', 18, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'AGREEMENT_TYPE', 'Column', 'Nbr', '', 19, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~6^24~1^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TG.GET_BID_CURVE_EDITOR', 'Grid', 'Tg.Get Bid Curve Editor', '', 0, 0, '-3~0^-2~0^-1~Scheduling.BidCurveEditorGrid^305~0^308~0', v_CHILD_OBJECT_ID);
            END;
             
            <<L133>>
            DECLARE
               v_PARENT_OBJECT_ID NUMBER(9) := L131.v_OBJECT_ID;
               v_OBJECT_ID NUMBER(9);
            BEGIN
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'BTN_SUBMIT_TO_PJM', 'Report Filter', 'Submit to PJM...', '', 0, 0, '-3~0^-2~0^501~b (Button)^508~0^514~0^515~0^519~0^520~0', v_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'ACT_SUBMIT_TO_PJM', 'Action', 'Submit to PJM...', '', 0, 0, '-3~0^-2~0^1006~2^1007~Scheduling.BidOfferSubmit;CONTEXT_TYPE="Sched:PJM:eMKT:SubmitScheduleDetail";ENTITY_ID=Value(TRANSACTION_ID)^1010~Top', v_CHILD_OBJECT_ID);
            END;
             
         END;
          
         <<L134>>
         DECLARE
            v_PARENT_OBJECT_ID NUMBER(9) := L130.v_OBJECT_ID;
            v_OBJECT_ID NUMBER(9);
         BEGIN
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'PJM_UNIT_SCHEDULES', 'Report', 'Unit Schedules', '', 2, 0, '-3~0^-2~0^401~MM_PJM_GEN_REPORTS.GET_UNIT_SCHEDULE_RPT^402~0^406~0', v_OBJECT_ID);
            <<L135>>
            DECLARE
               v_PARENT_OBJECT_ID NUMBER(9) := L134.v_OBJECT_ID;
               v_OBJECT_ID NUMBER(9);
            BEGIN
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'PJM_UNIT_SCHEDULES_Grid', 'Grid', 'Pjm Unit Schedules Grid', '', 0, 0, '-3~0^-2~0^301~MM_PJM_GEN_REPORTS.PUT_UNIT_SCHEDULE_RPT^305~1^308~0', v_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TO_SCHEDULE_DETAILS', 'Action', 'To Schedule Details', '', 0, 0, '1006~6^1007~Scheduling.PJM.Generation.PCCurves;RESOURCE_ID=RESOURCE_ID^1010~Top', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRANSACTION_NAME', 'Column', '', '', 0, 1, '-3~0^-2~0^2~0^7~0^13~0^20~0^24~0^31~1', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRANSACTION_ID', 'Column', '', '', 1, 1, '-3~0^-2~0^2~0^7~0^13~0^20~0^24~0^31~1', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'RESOURCE_ID', 'Column', 'Unit', '', 2, 0, '-3~0^-2~0^1~o (Object List)^2~0^7~0^8~RESOURCE^13~0^20~0^23~BLAH BLAH BLAH BLAH^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'PSE_ID', 'Column', 'Contract', '', 3, 0, '-3~0^-2~0^1~o (Object List)^2~0^7~0^8~PSE^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SCHEDULE_NUMBER', 'Column', 'Number', '', 4, 0, '-3~0^-2~0^1~n (Numeric Edit)^2~0^7~0^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SCHEDULE_NAME', 'Column', '', '', 5, 0, '-3~0^-2~0^1~e (Standard Edit)^2~0^7~0^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SCHEDULE_DESCRIPTION', 'Column', '', '', 6, 0, '-3~0^-2~0^1~e (Standard Edit)^2~0^7~0^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
            END;
             
            <<L136>>
            DECLARE
               v_PARENT_OBJECT_ID NUMBER(9) := L134.v_OBJECT_ID;
               v_OBJECT_ID NUMBER(9);
            BEGIN
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'BTN_SUBMIT_TO_PJM', 'Report Filter', 'Submit to PJM...', '', 0, 0, '-3~0^-2~0^501~b (Button)^508~0^514~0^515~0^519~0^520~0', v_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'ACT_SUBMIT_TO_PJM', 'Action', 'Submit to PJM...', '', 0, 0, '-3~0^-2~0^1006~2^1007~Scheduling.BidOfferSubmit;CONTEXT_TYPE="Sched:PJM:eMKT:SubmitUnitSchedule";ENTITY_ID=Value(TRANSACTION_ID)^1010~Top', v_CHILD_OBJECT_ID);
            END;
             
         END;
          
      END;
       
      -------------------------------------
      --   Scheduling.PJM.Generation.PCCurves
      -------------------------------------
      <<L186>>
      DECLARE
         v_PARENT_OBJECT_ID NUMBER(9) := L0.v_OBJECT_ID;
         v_OBJECT_ID NUMBER(9);
      BEGIN
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'Scheduling.PJM.Generation.PCCurves', 'System View', 'Scheduling.PJM.Generation.PCCurves', '', 5, 0, '-3~0^-2~0', v_OBJECT_ID);
         <<L187>>
         DECLARE
            v_PARENT_OBJECT_ID NUMBER(9) := L186.v_OBJECT_ID;
            v_OBJECT_ID NUMBER(9);
         BEGIN
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'SCHEDULE_DATA', 'Report', 'Schedule Data', '', 3, 0, '-3~0^-2~0^401~MM_PJM_GEN_REPORTS.GET_SCHEDULE_OFFER_RPT_MASTER;SCHEDULE_STATE=1^402~0^403~Lazy Master/Detail Grids^404~MM_PJM_GEN_REPORTS.GET_SCHEDULE_OFFER_RPT;SCHEDULE_STATE=1;INTERVAL="<Offer>"^406~0^409~Vertical', v_OBJECT_ID);
            <<L188>>
            DECLARE
               v_PARENT_OBJECT_ID NUMBER(9) := L187.v_OBJECT_ID;
               v_OBJECT_ID NUMBER(9);
            BEGIN
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'SCHEDULE_DATA_Grid_DETAIL', 'Grid', 'Schedule Offers', '', 0, 0, '-3~0^-2~0^301~TG.PUT_IT_TRAIT_SCHED_DETAIL_RPT;SCHEDULE_STATE=1^305~0^307~ResourceTrait^308~1', v_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'CURVE_EDITOR', 'Action', 'Add Rows...', '', 0, 0, '-2~1^-1~BID_CURVE_EDITOR_ACTION', v_CHILD_OBJECT_ID);
               <<L189>>
               DECLARE
                  v_PARENT_OBJECT_ID NUMBER(9) := L188.v_OBJECT_ID;
                  v_OBJECT_ID NUMBER(9);
               BEGIN
                  SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'SHIFT_THIS_CURVE', 'Action', 'Shift This Curve', '', 1, 0, '-3~0^-2~0^1006~3^1007~MM_PJM_GEN_REPORTS.SHIFT_PRICE_CURVE^1008~All^1009~Selected^1010~Top', v_OBJECT_ID);
                  SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'refresh', 'Action', 'Refresh', '', 0, 0, '1006~6^1007~Scheduling.PJM.Generation.PCCurves', v_CHILD_OBJECT_ID);
               END;
                
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SCHEDULE_DATE_STR', 'Column', 'Date', '', 0, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRANSACTION_IDENTIFIER', 'Column', '', '', 2, 0, '', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRANSACTION_NAME', 'Column', '', '', 3, 0, '', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SCHEDULE_NAME', 'Column', '', '', 4, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~2^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SCHEDULE_DESCRIPTION', 'Column', '', '', 5, 0, '', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRAIT_ORDER', 'Column', '', '', 5, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~4^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SCHEDULE_NUMBER', 'Column', '', '', 6, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRANSACTION_ID', 'Column', '', '', 6, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~4^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRAIT_GROUP_ID', 'Column', '', '', 7, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~4^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRAIT_INDEX', 'Column', '', '', 8, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~4^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRAIT_GROUP_NAME', 'Column', '', '', 9, 0, '', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'CUT_DATE_SCHEDULING', 'Column', '', '', 10, 1, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~6^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'DISPLAY_NAME', 'Column', '', '', 10, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~2^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SET_NUMBER', 'Column', 'Nbr', '', 11, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~1^24~1^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'DATA_TYPE', 'Column', '', '', 12, 0, '', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'EDIT_MASK', 'Column', '', '', 13, 0, '', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'COMBO_LIST', 'Column', '', '', 14, 0, '', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'FORMAT', 'Column', '', '', 15, 0, '', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRAIT_VAL', 'Column', '', '', 16, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~5^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'GROUP_ORDER', 'Column', '', '', 20, 0, '', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TG.GET_BID_CURVE_EDITOR', 'Grid', 'Tg.Get Bid Curve Editor', '', 0, 0, '-3~0^-2~0^-1~Scheduling.BidCurveEditorGrid^305~0^308~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'UNIT_NAME', 'Label', 'Unit', '', 0, 0, '1101~2^1102~=RESOURCE_ID_TEXT', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'DATA_DATE', 'Label', 'Date', '', 1, 0, '1101~1^1102~=Format(BEGIN_DATE, "MMMM dd, yyyy")', v_CHILD_OBJECT_ID);
            END;
             
            <<L190>>
            DECLARE
               v_PARENT_OBJECT_ID NUMBER(9) := L187.v_OBJECT_ID;
               v_OBJECT_ID NUMBER(9);
            BEGIN
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'SCHEDULE_DATA_Grid_MASTER', 'Grid', 'Unit Schedules', '', 0, 0, '-3~0^-2~0^305~0^308~0', v_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TO_PJM_COMPARISON', 'Action', 'To PJM Comparison', '', 0, 0, '-3~0^-2~0^1006~2^1007~Scheduling.PJM.Generation.PJMComparison;TRANSACTION_ID=TRANSACTION_ID;TRAIT_GROUP_FILTER="%";INTERVAL="<Offer>";UNIT_NAME=RESOURCE_ID_TEXT', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TO_SCHEDULE_DETAILS', 'Action', 'To Schedule Details', '', 1, 0, '-3~0^-2~0^1006~2^1007~Scheduling.PJM.Generation.PJMDetails;TRANSACTION_ID=TRANSACTION_ID;TRAIT_GROUP_FILTER="%";INTERVAL="<Offer>";TRANSACTION_ID_TEXT=RESOURCE_ID_TEXT;BID_OFFER_SUBMIT_NAME="Sched:PJM:eMKT:SubmitScheduleDetail"', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SCHEDULE_DATE_STR', 'Column', 'Date', '', 0, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SUBMIT_STATUS', 'Column', '', '', 1, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^24~0^28~BidOfferStatus^29~X=SUBMIT_STATUS^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SEL_AVAILABLE', 'Column', '<html><body><b>Available</b></body></html>', '', 2, 0, '-3~0^-2~0^1~c (Combo Box)^2~0^5~true|false^7~0^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRANSACTION_ID', 'Column', '', '', 3, 1, '-3~0^-2~0^2~0^7~0^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRANSACTION_IDENTIFIER', 'Column', '', '', 4, 1, '-3~0^-2~0^2~0^7~0^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRANSACTION_NAME', 'Column', '', '', 5, 1, '-3~0^-2~0^2~0^7~0^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SCHEDULE_NAME', 'Column', '', '', 6, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SCHEDULE_DESCRIPTION', 'Column', '', '', 7, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SCHEDULE_NUMBER', 'Column', '', '', 8, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'CUT_DATE_SCHEDULING', 'Column', '', '', 9, 1, '-3~0^-2~0^2~0^7~0^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SUBMITTED_BY', 'Column', '', '', 10, 1, '-3~0^-2~0^2~0^7~0^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SUBMIT_DATE', 'Column', '', '', 11, 1, '-3~0^-2~0^2~0^7~0^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'UNIT_NAME', 'Label', 'Unit', '', 0, 0, '1101~2^1102~=RESOURCE_ID_TEXT', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'DATA_DATE', 'Label', 'Date', '', 1, 0, '1101~1^1102~=Format(BEGIN_DATE, "MMMM dd, yyyy")', v_CHILD_OBJECT_ID);
            END;
             
            <<L191>>
            DECLARE
               v_PARENT_OBJECT_ID NUMBER(9) := L187.v_OBJECT_ID;
               v_OBJECT_ID NUMBER(9);
            BEGIN
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'SUBMIT_TO_PJM', 'Report Filter', 'Submit Offer to PJM...', '', 1, 0, '-3~0^-2~0^501~b (Button)^508~0^514~0^515~0^519~0^520~0', v_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'ACT_SUBMIT_TO_PJM', 'Action', 'Submit Offer to PJM...', '', 0, 0, '-3~0^-2~0^1006~2^1007~Scheduling.BidOfferSubmit;CONTEXT_TYPE="Sched:PJM:eMKT:SubmitScheduleOffer";ENTITY_ID=Value(TRANSACTION_ID)^1010~Top', v_CHILD_OBJECT_ID);
            END;
             
            <<L192>>
            DECLARE
               v_PARENT_OBJECT_ID NUMBER(9) := L187.v_OBJECT_ID;
               v_OBJECT_ID NUMBER(9);
            BEGIN
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'SUBMIT_TO_PJM_AVAIL', 'Report Filter', 'Submit Schedule Selection to PJM...', '', 2, 0, '-3~0^-2~0^501~b (Button)^508~0^514~0^515~0^519~0^520~0', v_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SUBMIT_TO_PJM_AVAIL_ACT', 'Action', 'Submit Schedule Selection to PJM...', '', 0, 0, '-3~0^-2~0^1006~2^1007~Scheduling.BidOfferSubmit;CONTEXT_TYPE="Sched:PJM:eMKT:SubmitScheduleSelection";ENTITY_ID=Value(TRANSACTION_ID)^1010~Top', v_CHILD_OBJECT_ID);
            END;
             
            <<L193>>
            DECLARE
               v_PARENT_OBJECT_ID NUMBER(9) := L187.v_OBJECT_ID;
               v_OBJECT_ID NUMBER(9);
            BEGIN
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'SUBMIT_TO_PJM_DETAILS', 'Report Filter', 'Submit Details to PJM...', '', 3, 1, '-3~0^-2~0^501~b (Button)^508~0^514~0^515~0^519~0^520~0', v_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SUBMIT_TO_PJM_DETAILS', 'Action', 'Submit Details to PJM...', '', 0, 0, '-3~0^-2~0^1006~2^1007~Scheduling.BidOfferSubmit;CONTEXT_TYPE="Sched:PJM:eMKT:SubmitScheduleDetail";ENTITY_ID=Value(TRANSACTION_ID)^1010~Top', v_CHILD_OBJECT_ID);
            END;
             
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'MULTIPLIER', 'Report Filter', 'Multiplier', '', 5, 0, '501~e (Standard Edit)', v_CHILD_OBJECT_ID);
            <<L194>>
            DECLARE
               v_PARENT_OBJECT_ID NUMBER(9) := L187.v_OBJECT_ID;
               v_OBJECT_ID NUMBER(9);
            BEGIN
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'APPLY_MULTIPLIER', 'Report Filter', 'Apply Multiplier', '', 6, 1, '-3~0^-2~0^501~b (Button)^508~0^514~0^515~0^519~0^520~0', v_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'APPLY_MULTIPLIER', 'Action', 'Apply Multiplier', '', 0, 0, '-3~0^-2~0^1006~3^1007~MM_PJM_REPORTS.SHIFT_PRICE_CURVE^1008~All^1009~Selected^1010~Top', v_CHILD_OBJECT_ID);
            END;
             
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'ADDER', 'Report Filter', 'Adder', '', 7, 0, '-3~0^-2~0^501~e (Standard Edit)^508~0^514~0^515~0^519~0^520~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'RESOURCE_ID', 'Report Filter', 'Units', '', 10, 0, '-3~0^-2~0^501~s (Special List)^504~MM_PJM_GEN_REPORTS.GET_RESOURCE_LIST;"Schedule;BEGIN_DATE;END_DATE^508~0^510~10^513~1^514~0^515~0^519~0^520~1', v_CHILD_OBJECT_ID);
         END;
          
      END;
       
      -------------------------------------
      --   Scheduling.PJM.Generation.UnitDefaults
      -------------------------------------
      <<L195>>
      DECLARE
         v_PARENT_OBJECT_ID NUMBER(9) := L0.v_OBJECT_ID;
         v_OBJECT_ID NUMBER(9);
      BEGIN
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'Scheduling.PJM.Generation.UnitDefaults', 'System View', 'Scheduling.PJM.Generation.UnitDefaults', '', 6, 0, '-3~0^-2~0', v_OBJECT_ID);
         <<L196>>
         DECLARE
            v_PARENT_OBJECT_ID NUMBER(9) := L195.v_OBJECT_ID;
            v_OBJECT_ID NUMBER(9);
         BEGIN
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'SUMMARY_REPORT', 'Report', 'Summary', '', 1, 0, '-3~0^-2~0^401~MM_PJM_GEN_REPORTS.GET_UNIT_DETAILS_RPT^402~0^403~Normal Grid^405~0^406~0', v_OBJECT_ID);
            <<L197>>
            DECLARE
               v_PARENT_OBJECT_ID NUMBER(9) := L196.v_OBJECT_ID;
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
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRAIT_VAL', 'Column', '', '', 13, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~5^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'GROUP_DISPLAY_NAME', 'Column', '', '', 14, 0, '22~2', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'DISPLAY_NAME', 'Column', '', '', 15, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~3^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SUBMIT_STATUS', 'Column', 'Status', '', 16, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~6^24~0^28~BidOfferStatus^29~X=SUBMIT_STATUS^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'IS_SERIES', 'Column', '', '', 17, 0, '22~4', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TG.GET_BID_CURVE_EDITOR', 'Grid', 'Tg.Get Bid Curve Editor', '', 0, 0, '-3~0^-2~0^-1~Scheduling.BidCurveEditorGrid^305~0^308~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'PERIOD_ONE_STARTUP_COSTS', 'Label', 'Period 1', '', 0, 0, '-3~0^-2~0^1101~4^1102~"April 1 - September 30"', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'PERIOD_TWO_STARTUP_COSTS', 'Label', 'Period 2', '', 1, 0, '1101~3^1102~"October 1 - March 31"', v_CHILD_OBJECT_ID);
            END;
             
            <<L198>>
            DECLARE
               v_PARENT_OBJECT_ID NUMBER(9) := L196.v_OBJECT_ID;
               v_OBJECT_ID NUMBER(9);
            BEGIN
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'BTN_SUBMIT_TO_PJM', 'Report Filter', 'Submit to PJM...', '', 0, 0, '-3~0^-2~0^501~b (Button)^508~0^514~0^515~0^519~0^520~0', v_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'ACT_SUBMIT_TO_PJM', 'Action', 'Submit to PJM...', '', 0, 0, '-3~0^-2~0^1006~2^1007~Scheduling.BidOfferSubmit;CONTEXT_TYPE="Sched:PJM:eMKT:SubmitUnitDetail";ENTITY_ID=Value(TRANSACTION_ID)^1010~Top', v_CHILD_OBJECT_ID);
            END;
             
         END;
          
      END;
       
      -------------------------------------
      --   Scheduling.PJM.Generation.UnitUpdates
      -------------------------------------
      <<L199>>
      DECLARE
         v_PARENT_OBJECT_ID NUMBER(9) := L0.v_OBJECT_ID;
         v_OBJECT_ID NUMBER(9);
      BEGIN
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'Scheduling.PJM.Generation.UnitUpdates', 'System View', 'Scheduling.PJM.Generation.UnitUpdates', '', 7, 0, '-3~0^-2~0', v_OBJECT_ID);
         <<L200>>
         DECLARE
            v_PARENT_OBJECT_ID NUMBER(9) := L199.v_OBJECT_ID;
            v_OBJECT_ID NUMBER(9);
         BEGIN
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'UNIT_DATA', 'Report', 'Unit Data', '', 2, 0, '-3~0^-2~0^401~MM_PJM_GEN_REPORTS.GET_TRAITS_WITH_STATUS_RPT;SCHEDULE_STATE=1;TRAIT_GROUP_FILTER="Summary";INTERVAL="Hour"^402~0^403~Normal Grid^405~0^406~0^409~Vertical', v_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'UnitUpdateChart', 'Chart', '', '', 0, 1, '-3~0^-2~0^901~9^904~Unit Updates^905~TRAIT_VAL^906~1^907~1^908~0^910~0^912~0^913~1', v_CHILD_OBJECT_ID);
            <<L201>>
            DECLARE
               v_PARENT_OBJECT_ID NUMBER(9) := L200.v_OBJECT_ID;
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
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRAIT_VAL', 'Column', '', '', 12, 0, '-3~0^-2~0^2~0^7~0^13~0^14~0^20~0^22~5^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'ROWNUM', 'Column', '', '', 13, 1, '-3~0^-2~0^2~0^7~0^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'REAL_ROWNUM', 'Column', '', '', 14, 1, '-3~0^-2~0^2~0^7~0^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'CUT_DATE_SCHEDULING', 'Column', '', '', 15, 1, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~6^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SUBMIT_STATUS', 'Column', '', '', 16, 0, '22~6^28~BidOfferStatus^29~X=SUBMIT_STATUS', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SUBMITTED_BY', 'Column', '', '', 17, 1, '22~6', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SUBMIT_DATE', 'Column', '', '', 18, 1, '22~6', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'UNIT_NAME', 'Label', 'Unit', '', 0, 0, '1101~2^1102~=TRANSACTION_ID_TEXT', v_CHILD_OBJECT_ID);
            END;
             
            <<L202>>
            DECLARE
               v_PARENT_OBJECT_ID NUMBER(9) := L200.v_OBJECT_ID;
               v_OBJECT_ID NUMBER(9);
            BEGIN
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'BTN_PJM_SUBMIT_UNIT_UPDATES', 'Report Filter', 'Submit to PJM...', '', 1, 0, '-3~0^-2~0^501~b (Button)^508~0^514~0^515~0^519~0^520~0', v_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'ACT_PJM_SUBMIT_UNIT_UPDATES', 'Action', 'Submit to PJM...', '', 0, 0, '-3~0^-2~0^1006~2^1007~Scheduling.BidOfferSubmit;CONTEXT_TYPE="Sched:PJM:eMKT:SubmitUnitUpdate";TRANSACTION_ID=Value(TRANSACTION_ID)', v_CHILD_OBJECT_ID);
            END;
             
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'FROM_DATE', 'Report Filter', 'From Date', '', 4, 0, '-3~0^-2~0^501~d (Date Picker)^508~0^514~0^515~0^517~Roll Forward Hourly Unit Data^519~0^520~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TO_DATE', 'Report Filter', 'To Date', '', 5, 0, '-3~0^-2~0^501~d (Date Picker)^508~0^514~0^515~0^517~Roll Forward Hourly Unit Data^519~0^520~0', v_CHILD_OBJECT_ID);
            <<L203>>
            DECLARE
               v_PARENT_OBJECT_ID NUMBER(9) := L200.v_OBJECT_ID;
               v_OBJECT_ID NUMBER(9);
            BEGIN
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'ROLL_DATA_FORWARD', 'Report Filter', 'Roll Forward All Units', '', 6, 0, '-3~0^-2~0^501~b (Button)^508~0^514~0^515~0^517~Roll Forward Hourly Unit Data^519~0^520~0', v_OBJECT_ID);
               <<L204>>
               DECLARE
                  v_PARENT_OBJECT_ID NUMBER(9) := L203.v_OBJECT_ID;
                  v_OBJECT_ID NUMBER(9);
               BEGIN
                  SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'ACT_ROLL_DATA_FORWARD', 'Action', 'Roll Forward All Units', '', 0, 0, '-3~0^-2~0^1006~5^1007~="You are about to delete all hourly Unit Update data on " + Format(TO_DATE,"MMMM dd, yyyy") + " and replace it with data from " + Format(FROM_DATE,"MMMM dd, yyyy") + ".  Do you want to continue?"', v_OBJECT_ID);
                  SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'ROLL_FORWARD', 'Action', 'Roll Forward All Units', '', 0, 0, '1006~3^1007~MM_PJM_GEN_REPORTS.ROLL_FORWARD_UNIT_UPDATES;DELETE_EXISTING_DATA=1', v_CHILD_OBJECT_ID);
               END;
                
            END;
             
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRANSACTION_ID', 'Report Filter', 'Units', '', 10, 0, '-3~0^-2~0^501~s (Special List)^504~MM_PJM_GEN_REPORTS.GET_RESOURCE_TXN_LIST;"Unit Data;BEGIN_DATE;END_DATE^508~0^510~10^513~1^514~0^515~0^519~0^520~1', v_CHILD_OBJECT_ID);
         END;
          
      END;
       
      -------------------------------------
      --   Scheduling.PJM.Generation.UnitUpdateSummary
      -------------------------------------
      <<L205>>
      DECLARE
         v_PARENT_OBJECT_ID NUMBER(9) := L0.v_OBJECT_ID;
         v_OBJECT_ID NUMBER(9);
      BEGIN
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'Scheduling.PJM.Generation.UnitUpdateSummary', 'System View', 'Scheduling.PJM.Generation.UnitUpdateSummary', '', 8, 0, '-3~0^-2~0', v_OBJECT_ID);
         <<L206>>
         DECLARE
            v_PARENT_OBJECT_ID NUMBER(9) := L205.v_OBJECT_ID;
            v_OBJECT_ID NUMBER(9);
         BEGIN
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'PJM_UNIT_UPDATE_SUMMARY', 'Report', 'Pjm Unit Update Summary', '', 0, 0, '-3~0^-2~0^401~MM_PJM_GEN_REPORTS.GET_UNIT_UPDATE_SUMMARY_RPT^402~0^406~0', v_OBJECT_ID);
            <<L207>>
            DECLARE
               v_PARENT_OBJECT_ID NUMBER(9) := L206.v_OBJECT_ID;
               v_OBJECT_ID NUMBER(9);
            BEGIN
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'PJM_UNIT_UPDATE_SUMMARY_Grid', 'Grid', 'Pjm Unit Update Summary Grid', '', 0, 0, '-3~0^-2~0^305~0^307~Anchored^308~1', v_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TO_HOURLY_DETAILS', 'Action', 'To Hourly Details', '', 0, 0, '1006~6^1007~Scheduling.PJM.Generation.UnitUpdates;TRANSACTION_ID=TRANSACTION_ID^1010~Top', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'RESOURCE_NAME', 'Column', 'Unit Name', '', 0, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~1^24~1^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'DISPLAY_ORDER', 'Column', '', '', 2, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~4^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRANSACTION_ID', 'Column', '', '', 3, 1, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~6^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRAIT_GROUP_ID', 'Column', '', '', 4, 1, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~4^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRAIT_INDEX', 'Column', '', '', 5, 1, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~4^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'DISPLAY_NAME', 'Column', '', '', 6, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~2^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRAIT_VAL', 'Column', '', '', 7, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~5^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'RESOURCE_ID', 'Column', '', '', 8, 1, '22~6', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'PSE_NAME', 'Column', 'Acct', '', 9, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~1^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'LBL_UNIT_DATA_DATE', 'Label', 'Unit Data Date', '', 0, 0, '1101~2^1102~=Format(BEGIN_DATE, "MMMM dd, yyyy")', v_CHILD_OBJECT_ID);
            END;
             
            <<L208>>
            DECLARE
               v_PARENT_OBJECT_ID NUMBER(9) := L206.v_OBJECT_ID;
               v_OBJECT_ID NUMBER(9);
            BEGIN
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'BTN_HOURLY_DETAILS', 'Report Filter', 'To Hourly Details', '', 0, 0, '-3~0^-2~0^501~b (Button)^508~0^514~0^515~0^519~0^520~0', v_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'HOURLY_DETAILS', 'Action', 'To Hourly Details', '', 0, 0, '-3~0^-2~0^1006~6^1007~Scheduling.PJM.Generation.UnitUpdates;TRANSACTION_ID=TRANSACTION_ID^1010~Top', v_CHILD_OBJECT_ID);
            END;
             
            <<L209>>
            DECLARE
               v_PARENT_OBJECT_ID NUMBER(9) := L206.v_OBJECT_ID;
               v_OBJECT_ID NUMBER(9);
            BEGIN
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'BTN_PC_CURVES', 'Report Filter', 'To Price and Cost Curves', '', 1, 0, '-3~0^-2~0^501~b (Button)^508~0^514~0^515~0^519~0^520~0', v_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'ACT_PC_CURVES', 'Action', 'To Price and Cost Curves', '', 0, 0, '-3~0^-2~0^1006~6^1007~Scheduling.PJM.Generation.PCCurves;RESOURCE_ID=RESOURCE_ID^1010~Top', v_CHILD_OBJECT_ID);
            END;
             
         END;
          
      END;
       
      -------------------------------------
      --   Scheduling.PJM.Generation.Regulation
      -------------------------------------
      <<L210>>
      DECLARE
         v_PARENT_OBJECT_ID NUMBER(9) := L0.v_OBJECT_ID;
         v_OBJECT_ID NUMBER(9);
      BEGIN
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'Scheduling.PJM.Generation.Regulation', 'System View', 'Scheduling.PJM.Generation.Regulation', '', 9, 0, '-3~0^-2~0', v_OBJECT_ID);
         <<L211>>
         DECLARE
            v_PARENT_OBJECT_ID NUMBER(9) := L210.v_OBJECT_ID;
            v_OBJECT_ID NUMBER(9);
         BEGIN
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'PJM_REGULATION_RPT', 'Report', 'Regulation Details', '', 0, 0, '-3~0^-2~0^401~MM_PJM_GEN_REPORTS.GET_TRAITS_WITH_STATUS_RPT;SCHEDULE_STATE=1;TRAIT_GROUP_FILTER="%";INTERVAL="Hour"^402~0^403~Normal Grid^406~0^409~Vertical', v_OBJECT_ID);
            <<L212>>
            DECLARE
               v_PARENT_OBJECT_ID NUMBER(9) := L211.v_OBJECT_ID;
               v_OBJECT_ID NUMBER(9);
            BEGIN
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'PJM_REGULATION_RPT_Grid', 'Grid', 'Regulation Updates', '', 0, 0, '-3~0^-2~0^301~TG.PUT_IT_TRAIT_SCHED_DETAIL_RPT^305~0^307~ResourceTrait^308~1', v_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TO_PJM_COMPARE', 'Action', 'To PJM Comparison', '', 0, 0, '-3~0^-2~0^1006~2^1007~Scheduling.PJM.Generation.PJMComparison;TRANSACTION_ID=TRANSACTION_ID;TRAIT_GROUP_FILTER="%";INTERVAL="Hour";UNIT_NAME=TRANSACTION_ID_TEXT', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TO_OFFER', 'Action', 'To Regulation Offer', '', 1, 0, '-3~0^-2~0^1006~2^1007~Scheduling.PJM.Generation.PJMDetails;TRANSACTION_ID=TRANSACTION_ID;TRAIT_GROUP_FILTER="%";INTERVAL="<Offer>";BID_OFFER_SUBMIT_NAME="Sched:PJM:eMKT:SubmitRegOffer"', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SCHEDULE_DATE_STR', 'Column', 'Date', '', 0, 0, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~1^24~1^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'GROUP_ORDER', 'Column', '', '', 1, 0, '22~4', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SET_NUMBER', 'Column', '', '', 2, 0, '-3~0^-2~0^2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~4^24~0^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRAIT_ORDER', 'Column', '', '', 3, 0, '22~4', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRAIT_GROUP_ID', 'Column', '', '', 4, 0, '-3~0^-2~0^2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~4^24~0^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRAIT_GROUP_NAME', 'Column', '', '', 5, 0, '-3~0^-2~0^2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~3^24~0^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRAIT_INDEX', 'Column', '', '', 6, 0, '-3~0^-2~0^2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~4^24~0^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'DISPLAY_NAME', 'Column', '', '', 7, 0, '-3~0^-2~0^2~0^4~0^7~0^9~0^11~1^12~0^13~0^14~0^15~0^20~0^22~3^24~0^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'DATA_TYPE', 'Column', '', '', 8, 1, '-3~0^-2~0^2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'EDIT_MASK', 'Column', '', '', 9, 1, '-3~0^-2~0^2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'COMBO_LIST', 'Column', '', '', 10, 1, '-3~0^-2~0^2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'FORMAT', 'Column', '', '', 11, 1, '-3~0^-2~0^2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRAIT_VAL', 'Column', '', '', 12, 0, '-3~0^-2~0^2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~5^24~0^26~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'CUT_DATE_SCHEDULING', 'Column', '', '', 13, 1, '-3~0^-2~0^2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~6^24~0^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SUBMIT_STATUS', 'Column', 'Status', '', 14, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~6^24~0^28~BidOfferStatus^29~X=SUBMIT_STATUS^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SUBMIT_DATE', 'Column', '', '', 15, 1, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~6^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SUBMITTED_BY', 'Column', '', '', 16, 1, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~6^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'UNIT_NAME', 'Label', 'Unit', '', 0, 0, '1101~2^1102~=TRANSACTION_ID_TEXT', v_CHILD_OBJECT_ID);
            END;
             
            <<L213>>
            DECLARE
               v_PARENT_OBJECT_ID NUMBER(9) := L211.v_OBJECT_ID;
               v_OBJECT_ID NUMBER(9);
            BEGIN
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'SUBMIT_UPDATE_TO_PUM', 'Report Filter', 'Submit Updates to PJM...', '', 1, 0, '-3~0^-2~0^501~b (Button)^508~0^514~0^515~0^519~0^520~0', v_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'ACT_SUBMIT_UPDATES_TO_PJM', 'Action', 'Submit Updates to PJM...', '', 0, 0, '-3~0^-2~0^1006~2^1007~Scheduling.BidOfferSubmit;CONTEXT_TYPE="Sched:PJM:eMKT:SubmitRegUpdate";TRANSACTION_ID=Value(TRANSACTION_ID)^1010~Top', v_CHILD_OBJECT_ID);
            END;
             
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'FROM_DATE', 'Report Filter', 'From Date', '', 4, 0, '-3~0^-2~0^501~d (Date Picker)^508~0^514~0^515~0^517~Roll Forward Hourly Reg Data^519~0^520~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TO_DATE', 'Report Filter', 'To Date', '', 5, 0, '-3~0^-2~0^501~d (Date Picker)^508~0^514~0^515~0^517~Roll Forward Hourly Reg Data^519~0^520~0', v_CHILD_OBJECT_ID);
            <<L214>>
            DECLARE
               v_PARENT_OBJECT_ID NUMBER(9) := L211.v_OBJECT_ID;
               v_OBJECT_ID NUMBER(9);
            BEGIN
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'ROLL_DATA_FORWARD', 'Report Filter', 'Roll Forward All Units', '', 6, 0, '-3~0^-2~0^501~b (Button)^508~0^514~0^515~0^517~Roll Forward Hourly Reg Data^519~0^520~0', v_OBJECT_ID);
               <<L215>>
               DECLARE
                  v_PARENT_OBJECT_ID NUMBER(9) := L214.v_OBJECT_ID;
                  v_OBJECT_ID NUMBER(9);
               BEGIN
                  SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'ACT_ROLL_DATA_FORWARD', 'Action', 'Roll Forward All Units', '', 0, 0, '-3~0^-2~0^1006~5^1007~="You are about to delete all hourly Regulation Update data on " + Format(TO_DATE,"MMMM dd, yyyy") + " and replace it with data from " + Format(FROM_DATE,"MMMM dd, yyyy") + ".  Do you want to continue?"', v_OBJECT_ID);
                  SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'ROLL_FORWARD', 'Action', 'Roll Forward All Units', '', 0, 0, '1006~3^1007~MM_PJM_GEN_REPORTS.ROLL_FORWARD_REG_UPDATES;DELETE_EXISTING_DATA=1', v_CHILD_OBJECT_ID);
               END;
                
            END;
             
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRANSACTION_ID', 'Report Filter', 'Units', '', 10, 0, '-3~0^-2~0^501~s (Special List)^504~MM_PJM_GEN_REPORTS.GET_RESOURCE_TXN_LIST;"Regulation;BEGIN_DATE;END_DATE^508~0^510~10^513~1^514~0^515~0^519~0^520~1', v_CHILD_OBJECT_ID);
         END;
          
      END;
       
      -------------------------------------
      --   Scheduling.PJM.Generation.SpinningReserves
      -------------------------------------
      <<L216>>
      DECLARE
         v_PARENT_OBJECT_ID NUMBER(9) := L0.v_OBJECT_ID;
         v_OBJECT_ID NUMBER(9);
      BEGIN
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'Scheduling.PJM.Generation.SpinningReserves', 'System View', 'Scheduling.PJM.Generation.SpinningReserves', '', 9, 0, '-3~0^-2~0', v_OBJECT_ID);
         <<L217>>
         DECLARE
            v_PARENT_OBJECT_ID NUMBER(9) := L216.v_OBJECT_ID;
            v_OBJECT_ID NUMBER(9);
         BEGIN
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'PJM_SPIN_RPT', 'Report', 'Spinning Reserve Details', '', 0, 0, '-3~0^-2~0^401~MM_PJM_GEN_REPORTS.GET_TRAITS_WITH_STATUS_RPT;SCHEDULE_STATE=1;TRAIT_GROUP_FILTER="%";INTERVAL="Hour"^402~0^403~Normal Grid^406~0^409~Vertical', v_OBJECT_ID);
            <<L218>>
            DECLARE
               v_PARENT_OBJECT_ID NUMBER(9) := L217.v_OBJECT_ID;
               v_OBJECT_ID NUMBER(9);
            BEGIN
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'PJM_SPIN_RPT_Grid', 'Grid', 'Spinning Reserve Updates', '', 0, 0, '-3~0^-2~0^301~TG.PUT_IT_TRAIT_SCHED_DETAIL_RPT^305~0^307~ResourceTrait^308~1', v_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TO_PJM_COMPARE', 'Action', 'To PJM Comparison', '', 0, 0, '-3~0^-2~0^1006~2^1007~Scheduling.PJM.Generation.PJMComparison;TRANSACTION_ID=TRANSACTION_ID;TRAIT_GROUP_FILTER="%";INTERVAL="Hour";UNIT_NAME=TRANSACTION_ID_TEXT', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TO_OFFER', 'Action', 'To Spinning Reserve Offer', '', 1, 0, '-3~0^-2~0^1006~2^1007~Scheduling.PJM.Generation.PJMDetails;TRANSACTION_ID=TRANSACTION_ID;TRAIT_GROUP_FILTER="%";INTERVAL="<Offer>";BID_OFFER_SUBMIT_NAME="Sched:PJM:eMKT:SubmitSpinOffer"', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SCHEDULE_DATE_STR', 'Column', 'Date', '', 0, 0, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~1^24~1^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'GROUP_ORDER', 'Column', '', '', 1, 0, '22~4', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SET_NUMBER', 'Column', '', '', 2, 0, '-3~0^-2~0^2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~4^24~0^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRAIT_ORDER', 'Column', '', '', 3, 0, '22~4', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRAIT_GROUP_ID', 'Column', '', '', 4, 0, '-3~0^-2~0^2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~4^24~0^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRAIT_GROUP_NAME', 'Column', '', '', 5, 0, '-3~0^-2~0^2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~3^24~0^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRAIT_INDEX', 'Column', '', '', 6, 0, '-3~0^-2~0^2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~4^24~0^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'DISPLAY_NAME', 'Column', '', '', 7, 0, '-3~0^-2~0^2~0^4~0^7~0^9~0^11~1^12~0^13~0^14~0^15~0^20~0^22~3^24~0^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'DATA_TYPE', 'Column', '', '', 8, 1, '-3~0^-2~0^2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'EDIT_MASK', 'Column', '', '', 9, 1, '-3~0^-2~0^2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'COMBO_LIST', 'Column', '', '', 10, 1, '-3~0^-2~0^2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'FORMAT', 'Column', '', '', 11, 1, '-3~0^-2~0^2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRAIT_VAL', 'Column', '', '', 12, 0, '-3~0^-2~0^2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~5^24~0^26~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'CUT_DATE_SCHEDULING', 'Column', '', '', 13, 1, '-3~0^-2~0^2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~6^24~0^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SUBMIT_STATUS', 'Column', 'Status', '', 14, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~6^24~0^28~BidOfferStatus^29~X=SUBMIT_STATUS^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SUBMIT_DATE', 'Column', '', '', 15, 1, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~6^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SUBMITTED_BY', 'Column', '', '', 16, 1, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~6^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'UNIT_NAME', 'Label', 'Unit', '', 0, 0, '1101~2^1102~=TRANSACTION_ID_TEXT', v_CHILD_OBJECT_ID);
            END;
             
            <<L219>>
            DECLARE
               v_PARENT_OBJECT_ID NUMBER(9) := L217.v_OBJECT_ID;
               v_OBJECT_ID NUMBER(9);
            BEGIN
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'SUBMIT_UPDATES_TO_PJM', 'Report Filter', 'Submit Updates to PJM...', '', 1, 0, '-3~0^-2~0^501~b (Button)^508~0^514~0^515~0^519~0^520~0', v_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'ACT_SUBMIT_UPDATES_TO_PJM', 'Action', 'Submit Updates to PJM...', '', 0, 0, '-3~0^-2~0^1006~2^1007~Scheduling.BidOfferSubmit;CONTEXT_TYPE="Sched:PJM:eMKT:SubmitSpinUpdate";TRANSACTION_ID=Value(TRANSACTION_ID)^1010~Top', v_CHILD_OBJECT_ID);
            END;
             
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'FROM_DATE', 'Report Filter', 'From Date', '', 4, 0, '-3~0^-2~0^501~d (Date Picker)^508~0^514~0^515~0^517~Roll Forward Hourly Spin Data^519~0^520~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TO_DATE', 'Report Filter', 'To Date', '', 5, 0, '-3~0^-2~0^501~d (Date Picker)^508~0^514~0^515~0^517~Roll Forward Hourly Spin Data^519~0^520~0', v_CHILD_OBJECT_ID);
            <<L220>>
            DECLARE
               v_PARENT_OBJECT_ID NUMBER(9) := L217.v_OBJECT_ID;
               v_OBJECT_ID NUMBER(9);
            BEGIN
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'ROLL_DATA_FORWARD', 'Report Filter', 'Roll Forward All Units', '', 6, 0, '-3~0^-2~0^501~b (Button)^508~0^514~0^515~0^517~Roll Forward Hourly Spin Data^519~0^520~0', v_OBJECT_ID);
               <<L221>>
               DECLARE
                  v_PARENT_OBJECT_ID NUMBER(9) := L220.v_OBJECT_ID;
                  v_OBJECT_ID NUMBER(9);
               BEGIN
                  SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'ACT_ROLL_DATA_FORWARD', 'Action', 'Roll Forward All Units', '', 0, 0, '-3~0^-2~0^1006~5^1007~="You are about to delete all hourly Spinning Reserve Update data on " + Format(TO_DATE,"MMMM dd, yyyy") + " and replace it with data from " + Format(FROM_DATE,"MMMM dd, yyyy") + ".  Do you want to continue?"', v_OBJECT_ID);
                  SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'ROLL_FORWARD', 'Action', 'Roll Forward All Units', '', 0, 0, '1006~3^1007~MM_PJM_GEN_REPORTS.ROLL_FORWARD_SPIN_UPDATES;DELETE_EXISTING_DATA=1', v_CHILD_OBJECT_ID);
               END;
                
            END;
             
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRANSACTION_ID', 'Report Filter', 'Units', '', 10, 0, '-3~0^-2~0^501~s (Special List)^504~MM_PJM_GEN_REPORTS.GET_RESOURCE_TXN_LIST;"Spinning Reserve;BEGIN_DATE;END_DATE^508~0^510~10^513~1^514~0^515~0^519~0^520~1', v_CHILD_OBJECT_ID);
         END;
          
      END;
       
      -------------------------------------
      --   Scheduling.PJM.Generation.StatusSummary
      -------------------------------------
      <<L222>>
      DECLARE
         v_PARENT_OBJECT_ID NUMBER(9) := L0.v_OBJECT_ID;
         v_OBJECT_ID NUMBER(9);
      BEGIN
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'Scheduling.PJM.Generation.StatusSummary', 'System View', 'Scheduling.PJM.Generation.StatusSummary', '', 10, 0, '-3~0^-2~0', v_OBJECT_ID);
         <<L223>>
         DECLARE
            v_PARENT_OBJECT_ID NUMBER(9) := L222.v_OBJECT_ID;
            v_OBJECT_ID NUMBER(9);
         BEGIN
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'PJM_STATUS_SUMMARY', 'Report', 'Status Summary', '', 0, 0, '-3~0^-2~0^401~MM_PJM_GEN_REPORTS.GET_STATUS_SUMMARY_RPT^402~0^406~0', v_OBJECT_ID);
            <<L224>>
            DECLARE
               v_PARENT_OBJECT_ID NUMBER(9) := L223.v_OBJECT_ID;
               v_OBJECT_ID NUMBER(9);
            BEGIN
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'PJM_STATUS_SUMMARY_Grid', 'Grid', 'Pjm Status Summary Grid', '', 0, 0, '-3~0^-2~0^305~0^307~Anchored^308~1', v_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TO_UNIT_DATA', 'Action', 'To Details', '', 0, 0, '-3~0^-2~0^1005~PJM_GEN_TXN_TYPE="Unit Data" AND INTERVAL="Hourly" AND TRANSACTION_ID > 0^1006~6^1007~Scheduling.PJM.Generation.UnitUpdates;TRANSACTION_ID=TRANSACTION_ID^1010~Top', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TO_SCHEDULE', 'Action', 'To Details', '', 1, 0, '-3~0^-2~0^1005~PJM_GEN_TXN_TYPE="Schedule"  AND INTERVAL="Hourly" AND TRANSACTION_ID > 0^1006~6^1007~Scheduling.PJM.Generation.PCCurves;RESOURCE_ID=RESOURCE_ID^1010~Top', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TO_SPINNING_RESERVE', 'Action', 'To Details', '', 2, 0, '-3~0^-2~0^1005~PJM_GEN_TXN_TYPE="Spinning Reserve" AND INTERVAL="Hourly" AND TRANSACTION_ID > 0^1006~6^1007~Scheduling.PJM.Generation.SpinningReserves;TRANSACTION_ID=TRANSACTION_ID^1010~Top', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TO_REGULATION', 'Action', 'To Details', '', 3, 0, '-3~0^-2~0^1005~PJM_GEN_TXN_TYPE="Regulation" AND INTERVAL="Hourly" AND TRANSACTION_ID > 0^1006~6^1007~Scheduling.PJM.Generation.Regulation;TRANSACTION_ID=TRANSACTION_ID^1010~Top', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TO_UNIT_DATA_DAY', 'Action', 'To Details', '', 4, 0, '1005~PJM_GEN_TXN_TYPE="Unit Data" AND INTERVAL="Daily" AND TRANSACTION_ID > 0^1006~6^1007~Scheduling.PJM.Generation.UnitDefaults^1010~Top', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TO_SCHEDULE_DAY', 'Action', 'To Details', '', 5, 0, '1005~PJM_GEN_TXN_TYPE="Schedule"  AND INTERVAL="Daily" AND TRANSACTION_ID > 0^1006~6^1007~Scheduling.PJM.Generation.UnitSchedules;REPORT_NAME=PJM_SCHEDULE_DETAILS^1010~Top', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TO_SPINNING_RESERVE_DAY', 'Action', 'To Details', '', 6, 0, '-3~0^-2~0^1005~PJM_GEN_TXN_TYPE="Spinning Reserve" AND INTERVAL="Daily" AND TRANSACTION_ID > 0^1006~2^1007~Scheduling.PJM.Generation.PJMDetails;TRANSACTION_ID=TRANSACTION_ID;TRAIT_GROUP_FILTER="%";INTERVAL="<Offer>";BID_OFFER_SUBMIT_NAME="Sched:PJM:eMKT:SubmitSpinOffer"^1010~Top', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TO_REGULATION_DAY', 'Action', 'To Details', '', 7, 0, '-3~0^-2~0^1005~PJM_GEN_TXN_TYPE="Regulation" AND INTERVAL="Daily" AND TRANSACTION_ID > 0^1006~2^1007~Scheduling.PJM.Generation.PJMDetails;TRANSACTION_ID=TRANSACTION_ID;TRAIT_GROUP_FILTER="%";INTERVAL="<Offer>";BID_OFFER_SUBMIT_NAME="Sched:PJM:eMKT:SubmitRegOffer"^1010~Top', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'RESOURCE_NAME', 'Column', 'Unit Name', '', 0, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~1^24~1^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'PSE_NAME', 'Column', 'Acct', '', 1, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~6^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TYPE_ORDER', 'Column', '', '', 2, 0, '22~4', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'PJM_GEN_TXN_TYPE', 'Column', '', '', 3, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~2^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'INTERVAL', 'Column', '', '', 4, 0, '22~2', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRANSACTION_ID', 'Column', '', '', 4, 1, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~5^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'RESOURCE_ID', 'Column', '', '', 5, 1, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~1^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SUBMIT_STATUS', 'Column', '', '', 5, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~5^24~0^28~BidOfferStatus^29~X=SUBMIT_STATUS^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'BID_STATUS_DATE', 'Label', 'Bid Status Date', '', 0, 0, '1101~2^1102~=Format(BEGIN_DATE, "MMMM dd, yyyy")', v_CHILD_OBJECT_ID);
            END;
             
         END;
          
      END;
       
      -------------------------------------
      --   Scheduling.PJM.Generation.PJMComparison
      -------------------------------------
      <<L244>>
      DECLARE
         v_PARENT_OBJECT_ID NUMBER(9) := L0.v_OBJECT_ID;
         v_OBJECT_ID NUMBER(9);
      BEGIN
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'Scheduling.PJM.Generation.PJMComparison', 'System View', 'PJM Comparison', '', 105, 0, '-3~0^-2~0', v_OBJECT_ID);
         <<L245>>
         DECLARE
            v_PARENT_OBJECT_ID NUMBER(9) := L244.v_OBJECT_ID;
            v_OBJECT_ID NUMBER(9);
         BEGIN
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'PJM_GEN_COMPARISON', 'Report', 'PJM Comparison', '', 0, 0, '-3~0^-2~0^401~TG.GET_IT_TRAIT_SCHED_TRAIT_RPT;SCHEDULE_STATE=1^402~1^403~Comparison Grids^404~TG.GET_IT_TRAIT_SCHED_TRAIT_RPT;SCHEDULE_STATE=2^406~0^409~Vertical^410~SCHEDULE_DATE_STR', v_OBJECT_ID);
            <<L246>>
            DECLARE
               v_PARENT_OBJECT_ID NUMBER(9) := L245.v_OBJECT_ID;
               v_OBJECT_ID NUMBER(9);
            BEGIN
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'PJM_GEN_COMPARISON_Grid', 'Grid', 'Internal', '', 0, 0, '-3~0^-2~0^301~TG.PUT_IT_TRAIT_SCHED_DETAIL_RPT^305~0^307~ResourceTrait^308~1^309~0', v_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SCHEDULE_DATE_STR', 'Column', 'Date', '', 0, 0, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~1^24~1^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'GROUP_ORDER', 'Column', '', '', 1, 0, '22~4', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SET_NUMBER', 'Column', '', '', 2, 0, '-3~0^-2~0^2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~4^24~0^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRAIT_ORDER', 'Column', '', '', 3, 0, '22~4', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRAIT_GROUP_ID', 'Column', '', '', 4, 0, '-3~0^-2~0^2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~4^24~0^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRAIT_GROUP_NAME', 'Column', '', '', 5, 0, '-3~0^-2~0^2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~3^24~0^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRAIT_INDEX', 'Column', '', '', 6, 0, '-3~0^-2~0^2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~4^24~0^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'DISPLAY_NAME', 'Column', '', '', 7, 0, '-3~0^-2~0^2~0^4~0^7~0^9~0^11~1^12~0^13~0^14~0^15~0^20~0^22~3^24~0^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'DATA_TYPE', 'Column', '', '', 8, 1, '-3~0^-2~0^2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'EDIT_MASK', 'Column', '', '', 9, 1, '-3~0^-2~0^2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'COMBO_LIST', 'Column', '', '', 10, 1, '-3~0^-2~0^2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'FORMAT', 'Column', '', '', 11, 1, '-3~0^-2~0^2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRAIT_VAL', 'Column', '', '', 12, 0, '-3~0^-2~0^2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~5^24~0^26~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'CUT_DATE_SCHEDULING', 'Column', '', '', 13, 1, '-3~0^-2~0^2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~6^24~0^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'LBL_UNIT_NAME', 'Label', 'Unit', '', 0, 0, '-3~0^-2~0^1101~2^1102~=UNIT_NAME', v_CHILD_OBJECT_ID);
            END;
             
            <<L247>>
            DECLARE
               v_PARENT_OBJECT_ID NUMBER(9) := L245.v_OBJECT_ID;
               v_OBJECT_ID NUMBER(9);
            BEGIN
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'PJM_GEN_COMPARISON_Grid_COMPARE', 'Grid', 'PJM', '', 0, 0, '-3~0^-2~0^305~0^307~ResourceTrait^308~1^309~0', v_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SCHEDULE_DATE_STR', 'Column', 'Date', '', 0, 0, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~1^24~1^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'GROUP_ORDER', 'Column', '', '', 1, 0, '22~4', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SET_NUMBER', 'Column', '', '', 2, 0, '-3~0^-2~0^2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~4^24~0^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRAIT_ORDER', 'Column', '', '', 3, 0, '22~4', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRAIT_GROUP_ID', 'Column', '', '', 4, 0, '-3~0^-2~0^2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~4^24~0^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRAIT_GROUP_NAME', 'Column', '', '', 5, 0, '-3~0^-2~0^2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~3^24~0^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRAIT_INDEX', 'Column', '', '', 6, 0, '-3~0^-2~0^2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~4^24~0^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'DISPLAY_NAME', 'Column', '', '', 7, 0, '-3~0^-2~0^2~0^4~0^7~0^9~0^11~1^12~0^13~0^14~0^15~0^20~0^22~3^24~0^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'DATA_TYPE', 'Column', '', '', 8, 1, '-3~0^-2~0^2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'EDIT_MASK', 'Column', '', '', 9, 1, '-3~0^-2~0^2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'COMBO_LIST', 'Column', '', '', 10, 1, '-3~0^-2~0^2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'FORMAT', 'Column', '', '', 11, 1, '-3~0^-2~0^2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRAIT_VAL', 'Column', '', '', 12, 0, '-3~0^-2~0^2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~1^22~5^24~0^26~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'CUT_DATE_SCHEDULING', 'Column', '', '', 13, 1, '-3~0^-2~0^2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~6^24~0^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'LBL_UNIT_NAME', 'Label', 'Unit', '', 0, 0, '1101~2^1102~=UNIT_NAME', v_CHILD_OBJECT_ID);
            END;
             
         END;
          
      END;
       
      -------------------------------------
      --   Scheduling.PJM.Generation.PJMDetails
      -------------------------------------
      <<L248>>
      DECLARE
         v_PARENT_OBJECT_ID NUMBER(9) := L0.v_OBJECT_ID;
         v_OBJECT_ID NUMBER(9);
      BEGIN
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'Scheduling.PJM.Generation.PJMDetails', 'System View', 'PJM Generation Details', '', 106, 0, '', v_OBJECT_ID);
         <<L249>>
         DECLARE
            v_PARENT_OBJECT_ID NUMBER(9) := L248.v_OBJECT_ID;
            v_OBJECT_ID NUMBER(9);
         BEGIN
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'PJM_GEN_DETAILS', 'Report', 'Internal Data', '', 1, 0, '-3~0^-2~0^401~MM_PJM_GEN_REPORTS.GET_TRAITS_WITH_STATUS_RPT;SCHEDULE_STATE=1^402~1^403~Normal Grid^406~0', v_OBJECT_ID);
            <<L250>>
            DECLARE
               v_PARENT_OBJECT_ID NUMBER(9) := L249.v_OBJECT_ID;
               v_OBJECT_ID NUMBER(9);
            BEGIN
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'PJM_GEN_DETAILS_Grid', 'Grid', 'Pjm Gen Details Grid', '', 0, 0, '-3~0^-2~0^301~TG.PUT_IT_TRAIT_SCHED_DETAIL_RPT^305~Scheduling.BidOfferSubmit;CONTEXT_TYPE="Sched:PJM:eMKT:SubmitRegUpdate";TRANSACTION_ID=Value(TRANSACTION_ID)^307~ResourceTrait^308~1', v_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TO_PJM_COMPARE', 'Action', 'To PJM Comparison', '', 0, 0, '-3~0^-2~0^1006~2^1007~Scheduling.PJM.Generation.PJMComparison;TRANSACTION_ID=TRANSACTION_ID;TRAIT_GROUP_FILTER="%";INTERVAL=INTERVAL;UNIT_NAME=TRANSACTION_ID_TEXT', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SUBMIT_TO_PJM', 'Action', 'Submit to PJM...', '', 2, 0, '-3~0^-2~0^1006~2^1007~Scheduling.BidOfferSubmit;CONTEXT_TYPE=BID_OFFER_SUBMIT_NAME;TRANSACTION_ID=Value(TRANSACTION_ID)', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SCHEDULE_DATE_STR', 'Column', 'Date', '', 0, 0, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~1^24~1^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'GROUP_ORDER', 'Column', '', '', 1, 0, '22~4', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SET_NUMBER', 'Column', '', '', 2, 0, '-3~0^-2~0^2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~4^24~0^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRAIT_ORDER', 'Column', '', '', 3, 0, '22~4', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRAIT_GROUP_ID', 'Column', '', '', 4, 0, '-3~0^-2~0^2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~4^24~0^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRAIT_GROUP_NAME', 'Column', '', '', 5, 0, '-3~0^-2~0^2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~3^24~0^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRAIT_INDEX', 'Column', '', '', 6, 0, '-3~0^-2~0^2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~4^24~0^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'DISPLAY_NAME', 'Column', '', '', 7, 0, '-3~0^-2~0^2~0^4~0^7~0^9~0^11~1^12~0^13~0^14~0^15~0^20~0^22~3^24~0^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'DATA_TYPE', 'Column', '', '', 8, 1, '-3~0^-2~0^2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'EDIT_MASK', 'Column', '', '', 9, 1, '-3~0^-2~0^2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'COMBO_LIST', 'Column', '', '', 10, 1, '-3~0^-2~0^2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'FORMAT', 'Column', '', '', 11, 1, '-3~0^-2~0^2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRAIT_VAL', 'Column', '', '', 12, 0, '-3~0^-2~0^2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~5^24~0^26~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'CUT_DATE_SCHEDULING', 'Column', '', '', 13, 1, '-3~0^-2~0^2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~6^24~0^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SUBMIT_STATUS', 'Column', 'Status', '', 14, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~6^24~0^28~BidOfferStatus^29~X=SUBMIT_STATUS^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SUBMIT_DATE', 'Column', '', '', 15, 1, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~6^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SUBMITTED_BY', 'Column', '', '', 16, 1, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~6^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'UNIT_NAME', 'Label', 'Unit', '', 0, 0, '1101~2^1102~=TRANSACTION_ID_TEXT', v_CHILD_OBJECT_ID);
            END;
             
         END;
          
      END;
       
END;
END;
/
