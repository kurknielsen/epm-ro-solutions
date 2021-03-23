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
SO.ID_FOR_SYSTEM_OBJECT(v_PARENT_OBJECT_ID, 'Scheduling.BidsNOffersPJM',0,'System View','Default',TRUE,v_OBJECT_ID);
v_PARENT_OBJECT_ID := v_OBJECT_ID;
   -------------------------------------
   --   SPARSE_TRAIT_REPORT
   -------------------------------------
      SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'SPARSE_TRAIT_REPORT', 'Report', 'Unit Detail', '', 1, 0, '-3~0^-2~0^401~TG.GET_IT_TRAIT_SCHED_SPARSE_RPT;SCHEDULE_STATE=1;TRAIT_GROUP_FILTER="%";DATE_OFFSET=0^402~0^403~Lazy Master/Detail Grids^404~TG.GET_IT_TRAIT_SPARSE_SERIES_RPT;SCHEDULE_STATE=1;TRAIT_GROUP_FILTER="StartupCost";DATE_OFFSET=0^405~0^406~0^407~TRANSACTION_ID^409~Vertical', v_OBJECT_ID);
      -------------------------------------
      --   SPARSE_TRAIT_REPORT_Grid_DETAIL_DETAIL
      -------------------------------------
      <<L1>>
      DECLARE
         v_PARENT_OBJECT_ID NUMBER(9) := L0.v_OBJECT_ID;
         v_OBJECT_ID NUMBER(9);
      BEGIN
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'SPARSE_TRAIT_REPORT_Grid_DETAIL_DETAIL', 'Grid', ' ', '', 0, 0, '-3~0^-2~0^301~TG.PUT_IT_TRAIT_SCHED_SPARSE_RPT^305~0^307~Anchored^308~0^309~0', v_OBJECT_ID);
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SCHEDULE_DATE', 'Column', 'Begin Date', '', 0, 0, '2~0^3~Short Date^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~1^24~0^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SCHEDULE_TIME', 'Column', '', '', 1, 1, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SCHEDULE_END_DATE', 'Column', 'End Date', '', 2, 0, '2~0^3~Short Date^4~0^7~0^9~0^11~0^12~4^13~0^14~0^15~0^20~0^22~1^24~0^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SCHEDULE_END_TIME', 'Column', '', '', 3, 1, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRAIT_GROUP_ID', 'Column', '', '', 4, 0, '-3~0^-2~0^2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~4^24~0^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRAIT_GROUP_NAME', 'Column', '', '', 5, 0, '-3~0^-2~0^2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~3^24~0^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRAIT_GROUP_INDEX_NAME', 'Column', '', '', 6, 0, '-3~0^-2~0^2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~2^24~0^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRAIT_INDEX', 'Column', '', '', 7, 0, '-3~0^-2~0^2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~4^24~0^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SET_NUMBER', 'Column', '', '', 8, 0, '-3~0^-2~0^2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~2^24~0^26~0^30~0^31~0^32~1', v_CHILD_OBJECT_ID);
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'DATA_TYPE', 'Column', '', '', 9, 1, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'EDIT_MASK', 'Column', '', '', 10, 1, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'COMBO_LIST', 'Column', '', '', 11, 1, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'FORMAT', 'Column', '', '', 12, 1, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRAIT_VAL', 'Column', '', '', 13, 0, '1~e (Standard Edit)^2~0^3~###,###,##0.0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~5^24~0^26~0^28~EveryOther^29~X=SET_NUMBER_DATA^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'ORIG_SCHEDULE_DATE', 'Column', '', '', 14, 1, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~5^24~0^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SET_NUMBER_DATA', 'Column', '', '', 15, 1, '22~5', v_CHILD_OBJECT_ID);
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'CUT_DATE_SCHEDULING', 'Column', '', '', 16, 1, '22~5^25~=ORIG_SCHEDULE_DATE', v_CHILD_OBJECT_ID);
      END;
       
      -------------------------------------
      --   SPARSE_TRAIT_REPORT_Grid_DETAIL_MASTER
      -------------------------------------
      <<L2>>
      DECLARE
         v_PARENT_OBJECT_ID NUMBER(9) := L0.v_OBJECT_ID;
         v_OBJECT_ID NUMBER(9);
      BEGIN
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'SPARSE_TRAIT_REPORT_Grid_DETAIL_MASTER', 'Grid', ' ', '', 0, 0, '-3~0^-2~0^301~TG.PUT_IT_TRAIT_SCHED_SPARSE_RPT^305~TG.PUT_IT_TRAIT_SCHED_SPARSE_RPT^308~0^309~0', v_OBJECT_ID);
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SCHEDULE_DATE', 'Column', 'Start Date', '', 0, 0, '1~d (Date Picker)^2~0^4~7^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0^28~EveryOther^29~X=ROWNUM^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SCHEDULE_TIME', 'Column', 'Time', '', 1, 0, '2~0^4~0^6~##:##^7~0^9~0^11~0^12~0^13~1^14~0^15~0^20~0^22~0^23~24:24^24~0^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SCHEDULE_END_DATE', 'Column', 'End Date', '', 2, 0, '-3~0^-2~0^1~d (Date Picker)^2~0^4~7^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0^28~EveryOther^29~X=ROWNUM^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SCHEDULE_END_TIME', 'Column', 'Time', '', 3, 0, '2~0^4~0^6~##:##^7~0^9~0^11~0^12~0^13~1^14~0^15~0^20~0^22~0^23~24:24^24~0^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRAIT_GROUP_INDEX_ID', 'Column', 'Trait Name', '', 4, 0, '1~s (Special List)^2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^16~TG.TRAIT_GROUP_INDEX_LIST_SPARSE;TRANSACTION_ID;"%^20~0^22~0^23~PJM.HighEmergencyTempRangeTemp^24~0^26~0^28~EveryOther^29~X=ROWNUM^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRAIT_GROUP_INDEX_NAME', 'Column', '', '', 5, 1, '1~x (No Edit)^2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^23~MISO DEFAULT DISPATCH MINIMUM^24~0^26~0', v_CHILD_OBJECT_ID);
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SET_NUMBER', 'Column', '', '', 6, 1, '1~n (Numeric Edit)^2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^25~=1^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'DATA_TYPE', 'Column', '', '', 7, 1, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0', v_CHILD_OBJECT_ID);
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'EDIT_MASK', 'Column', '', '', 8, 1, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0', v_CHILD_OBJECT_ID);
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'COMBO_LIST', 'Column', '', '', 9, 1, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0', v_CHILD_OBJECT_ID);
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'FORMAT', 'Column', '', '', 10, 1, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0', v_CHILD_OBJECT_ID);
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRAIT_VAL', 'Column', 'Value', '', 11, 0, '1~e (Standard Edit)^2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0^28~EveryOther^29~X=ROWNUM^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'ORIG_SCHEDULE_DATE', 'Column', '', '', 12, 1, '2~0^4~7^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0', v_CHILD_OBJECT_ID);
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'ROWNUM', 'Column', '', '', 13, 1, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
      END;
       
      SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SPARSE_TRAIT_REPORT_Grid_SUMMARY', 'Grid', '', '', 0, 1, '-3~0^-2~0^305~0^308~0', v_CHILD_OBJECT_ID);
      SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRANSACTION_ID', 'Report Filter', 'Transaction ID', '', 0, 0, '501~x (Custom)^508~0^512~com.newenergyassoc.ro.scheduling.bao.BidsAndOffersTreeFilterComponent^513~1^514~1^515~1', v_CHILD_OBJECT_ID);
END;
END;
/