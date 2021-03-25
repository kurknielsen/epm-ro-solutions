--This script will create a BidsAndOffers PJM System View.
--You will need to add it to the appropriate Layout as needed.

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
   --   Scheduling.BidsNOffers
   -------------------------------------
      SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'Scheduling.BidsNOffersPJM', 'System View', 'Scheduling.BidsnoffersPJM', '', 0, 0, '801~com.newenergyassoc.ro.scheduling.bao.BidsAndOffersContentPanel', v_OBJECT_ID);
      -------------------------------------
      --   STATUS_REPORT
      -------------------------------------
      <<L1>>
      DECLARE
         v_PARENT_OBJECT_ID NUMBER(9) := L0.v_OBJECT_ID;
         v_OBJECT_ID NUMBER(9);
      BEGIN
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'STATUS_REPORT', 'Report', 'Status', '', 0, 0, '401~BO.BID_OFFER_STATUS_REPORT^402~0^403~0^405~0^406~0', v_OBJECT_ID);
         <<L2>>
         DECLARE
            v_PARENT_OBJECT_ID NUMBER(9) := L1.v_OBJECT_ID;
            v_OBJECT_ID NUMBER(9);
         BEGIN
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'STATUS_REPORT_Grid_DETAIL', 'Grid', 'Status Report Grid Detail', '', 0, 0, '301~BO.PUT_BID_OFFER_STATUS_REASON^305~0^308~0^309~0', v_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRANSACTION_NAME', 'Column', '', '', 0, 1, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~1^22~0^24~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SCHEDULE_DATE', 'Column', 'Schedule Date', '', 1, 0, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~1^22~0^24~1^26~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'CREATE_DATE', 'Column', 'Create Date', '', 2, 0, '1~d (Date Picker)^2~0^3~Short Date^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~1^22~0^24~0^26~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'REVIEW_STATUS', 'Column', '', '', 3, 0, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~1^22~0^24~0^26~0^28~BidOfferStatus^29~X=REVIEW_STATUS^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'REVIEW_DATE', 'Column', '', '', 4, 0, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~1^22~0^24~0^26~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'REVIEWED_BY', 'Column', '', '', 5, 0, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~1^22~0^24~0^26~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SUBMIT_STATUS', 'Column', 'Submit Status', '', 6, 0, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~1^22~0^24~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SUBMIT_DATE', 'Column', 'Submit Date', '', 7, 0, '1~d (Date Picker)^2~0^3~Short Date^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~1^22~0^24~0^26~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SUBMITTED_BY', 'Column', 'Submitted By', '', 8, 0, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~1^22~0^24~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'MARKET_STATUS', 'Column', 'Market Status', '', 9, 0, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~1^22~0^24~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'MARKET_STATUS_DATE', 'Column', 'Market Status Date', '', 10, 0, '1~d (Date Picker)^2~0^3~Short Date^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~1^22~0^24~0^26~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'REASON_FOR_CHANGE', 'Column', 'Reason for Change', '', 11, 1, '1~e (Standard Edit)^2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'OTHER_REASON', 'Column', 'Notes', '', 12, 0, '1~e (Standard Edit)^2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'PROCESS_MESSAGE', 'Column', 'Process Message', '', 13, 1, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~1^22~0^24~0^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'ENTRY_DATE', 'Column', 'Entry Date', '', 14, 0, '1~d (Date Picker)^2~0^3~Short Date^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~1^22~0^24~0^26~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'CUT_DATE_SCHEDULING', 'Column', '', '', 15, 1, '', v_CHILD_OBJECT_ID);
         END;
          
         <<L3>>
         DECLARE
            v_PARENT_OBJECT_ID NUMBER(9) := L1.v_OBJECT_ID;
            v_OBJECT_ID NUMBER(9);
         BEGIN
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'STATUS_REPORT_Grid_SUMMARY', 'Grid', 'Status Report Grid Summary', '', 0, 0, '305~0^307~Anchored^308~0^309~0', v_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRANSACTION_NAME', 'Column', 'Transaction Name', '', 0, 0, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~2^24~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SCHEDULE_DATE', 'Column', 'Date', '', 1, 0, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~1^24~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SCHEDULE_TIME', 'Column', 'Time', '', 2, 0, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~1^24~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'REVIEW_STATUS', 'Column', 'Review Status', '', 3, 0, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~1^22~5^24~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SUBMIT_STATUS', 'Column', 'Submit Status', '', 4, 0, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~1^22~5^24~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'MARKET_STATUS', 'Column', 'Market Status', '', 5, 0, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~1^22~5^24~0', v_CHILD_OBJECT_ID);
         END;
          
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRANSACTION_ID', 'Report Filter', 'Transaction Id', '', 0, 0, '501~x (Custom)^508~0^512~com.newenergyassoc.ro.scheduling.bao.BidsAndOffersTreeFilterComponent^513~1^514~1^515~1', v_CHILD_OBJECT_ID);
      END;
       
      -------------------------------------
      --   SPARSE_TRAIT_REPORT
      -------------------------------------
      <<L4>>
      DECLARE
         v_PARENT_OBJECT_ID NUMBER(9) := L0.v_OBJECT_ID;
         v_OBJECT_ID NUMBER(9);
      BEGIN
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'SPARSE_TRAIT_REPORT', 'Report', 'Unit Detail', '', 1, 0, '401~TG.GET_IT_TRAIT_SCHED_SPARSE_RPT;SCHEDULE_STATE=1;TRAIT_GROUP_FILTER="%";DATE_OFFSET=0^402~0^403~0^405~0^406~0', v_OBJECT_ID);
         <<L5>>
         DECLARE
            v_PARENT_OBJECT_ID NUMBER(9) := L4.v_OBJECT_ID;
            v_OBJECT_ID NUMBER(9);
         BEGIN
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'SPARSE_TRAIT_REPORT_Grid_DETAIL', 'Grid', 'Sparse Trait Report Grid Detail', '', 0, 0, '301~TG.PUT_IT_TRAIT_SCHED_SPARSE_RPT^305~1^308~0^309~0', v_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SCHEDULE_DATE', 'Column', 'Start Date', '', 0, 0, '1~d (Date Picker)^2~0^4~7^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0^28~EveryOther^29~X=ROWNUM^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SCHEDULE_TIME', 'Column', 'Time', '', 1, 0, '2~0^4~0^6~##:##^7~0^9~0^11~0^12~0^13~1^14~0^15~0^20~0^22~0^23~24:24^24~0^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SCHEDULE_END_DATE', 'Column', 'End Date', '', 2, 0, '1~d (Date Picker)^2~0^4~7^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0^28~EveryOther^29~X=ROWNUM^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
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
          
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SPARSE_TRAIT_REPORT_Grid_SUMMARY', 'Grid', '', '', 0, 0, '', v_CHILD_OBJECT_ID);
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRANSACTION_ID', 'Report Filter', 'Transaction ID', '', 0, 0, '501~x (Custom)^508~0^512~com.newenergyassoc.ro.scheduling.bao.BidsAndOffersTreeFilterComponent^513~1^514~1^515~1', v_CHILD_OBJECT_ID);
      END;
       
      -------------------------------------
      --   UNIT_RAMP_RATES
      -------------------------------------
      <<L6>>
      DECLARE
         v_PARENT_OBJECT_ID NUMBER(9) := L0.v_OBJECT_ID;
         v_OBJECT_ID NUMBER(9);
      BEGIN
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'UNIT_RAMP_RATES', 'Report', 'Unit Ramp Rates', '', 2, 0, '401~TG.GET_IT_TRAIT_SPARSE_SERIES_RPT;SCHEDULE_STATE=1;TRAIT_GROUP_FILTER="RampRates";DATE_OFFSET=0^402~0^403~-1^405~0^406~0', v_OBJECT_ID);
         <<L7>>
         DECLARE
            v_PARENT_OBJECT_ID NUMBER(9) := L6.v_OBJECT_ID;
            v_OBJECT_ID NUMBER(9);
         BEGIN
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'UNIT_RAMP_RATES_Grid', 'Grid', 'Unit Ramp Rates Grid', '', 0, 0, '305~0^307~Anchored^308~1^309~0', v_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SCHEDULE_DATE', 'Column', 'Begin Date', '', 0, 0, '2~0^3~Short Date^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~1^24~0^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SCHEDULE_TIME', 'Column', '', '', 1, 1, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SCHEDULE_END_DATE', 'Column', 'End Date', '', 2, 0, '2~0^3~Short Date^4~0^7~0^9~0^11~0^12~4^13~0^14~0^15~0^20~0^22~1^24~0^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SCHEDULE_END_TIME', 'Column', '', '', 3, 1, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRAIT_GROUP_ID', 'Column', '', '', 4, 0, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~4^24~0^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRAIT_GROUP_NAME', 'Column', '', '', 5, 0, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~3^24~0^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SET_NUMBER', 'Column', '', '', 6, 0, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~2^24~0^26~0^30~0^31~0^32~1', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRAIT_INDEX', 'Column', '', '', 7, 0, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~4^24~0^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRAIT_GROUP_INDEX_NAME', 'Column', '', '', 8, 0, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~3^24~0^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'DATA_TYPE', 'Column', '', '', 9, 1, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'EDIT_MASK', 'Column', '', '', 10, 1, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'COMBO_LIST', 'Column', '', '', 11, 1, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'FORMAT', 'Column', '', '', 12, 1, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRAIT_VAL', 'Column', '', '', 13, 0, '1~e (Standard Edit)^2~0^3~###,###,##0.0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~5^24~0^26~0^28~EveryOther^29~X=SET_NUMBER_DATA^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'ORIG_SCHEDULE_DATE', 'Column', '', '', 14, 1, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~5^24~0^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SET_NUMBER_DATA', 'Column', '', '', 15, 1, '22~5', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'CUT_DATE_SCHEDULING', 'Column', '', '', 16, 1, '22~5^25~=ORIG_SCHEDULE_DATE', v_CHILD_OBJECT_ID);
         END;
          
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRANSACTION_ID', 'Report Filter', '', '', 0, 0, '501~x (Custom)^512~com.newenergyassoc.ro.scheduling.bao.BidsAndOffersTreeFilterComponent^513~1^515~1', v_CHILD_OBJECT_ID);
      END;
       
      -------------------------------------
      --   STANDARD_TRAIT_REPORT
      -------------------------------------
      <<L8>>
      DECLARE
         v_PARENT_OBJECT_ID NUMBER(9) := L0.v_OBJECT_ID;
         v_OBJECT_ID NUMBER(9);
      BEGIN
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'STANDARD_TRAIT_REPORT', 'Report', 'Unit Updates', '', 3, 0, '401~TG.GET_IT_TRAIT_SCHED_TRAIT_RPT;SCHEDULE_STATE=1;TRAIT_GROUP_FILTER="Updates";INTERVAL="Hour"^402~0^403~0^405~0^406~0', v_OBJECT_ID);
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'STANDARD_TRAIT_REPORT_Grid', 'Grid', '', '', 0, 0, '', v_CHILD_OBJECT_ID);
         <<L9>>
         DECLARE
            v_PARENT_OBJECT_ID NUMBER(9) := L8.v_OBJECT_ID;
            v_OBJECT_ID NUMBER(9);
         BEGIN
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'STANDARD_TRAIT_REPORT_Grid_DETAIL', 'Grid', 'Standard Trait Report Grid Detail', '', 0, 0, '301~TG.PUT_IT_TRAIT_SCHEDULE^305~0^307~ResourceTrait^308~1^309~0', v_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SCHEDULE_DATE_STR', 'Column', 'Date', '', 0, 0, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~1^24~0^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRAIT_GROUP_ID', 'Column', '', '', 1, 1, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~5^24~0^26~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRAIT_INDEX', 'Column', '', '', 2, 1, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~5^24~0^26~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRAIT_GROUP_NAME', 'Column', '', '', 3, 0, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~2^24~0^26~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'DISPLAY_NAME', 'Column', '', '', 4, 0, '2~0^4~0^7~0^9~0^11~1^12~0^13~0^14~0^15~0^20~0^22~2^24~0^26~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SET_NUMBER', 'Column', '', '', 5, 1, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~5^24~0^26~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'DATA_TYPE', 'Column', '', '', 6, 1, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'EDIT_MASK', 'Column', '', '', 7, 1, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'COMBO_LIST', 'Column', '', '', 8, 1, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'FORMAT', 'Column', '', '', 9, 1, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRAIT_VAL', 'Column', '', '', 10, 0, '1~e (Standard Edit)^2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~5^24~0^26~0^28~EveryOther^29~X=ROWNUM+1^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'ROWNUM', 'Column', '', '', 11, 1, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~5^24~0^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'CUT_DATE_SCHEDULING', 'Column', '', '', 12, 1, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~5^24~0^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SCHEDULE_DATE', 'Column', '', '', 13, 1, '22~5^25~=CUT_DATE_SCHEDULING', v_CHILD_OBJECT_ID);
         END;
          
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRANSACTION_ID', 'Report Filter', 'Transaction Id', '', 1, 0, '501~x (Custom)^508~0^512~com.newenergyassoc.ro.scheduling.bao.BidsAndOffersTreeFilterComponent^513~1^514~1^515~1', v_CHILD_OBJECT_ID);
      END;
       
      -------------------------------------
      --   DETAILED_TRAIT_REPORT
      -------------------------------------
      <<L10>>
      DECLARE
         v_PARENT_OBJECT_ID NUMBER(9) := L0.v_OBJECT_ID;
         v_OBJECT_ID NUMBER(9);
      BEGIN
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'DETAILED_TRAIT_REPORT', 'Report', 'Schedule Offers', '', 4, 0, '401~TG.GET_IT_TRAIT_SCHED_DETAIL_RPT;SCHEDULE_STATE=1;TRAIT_GROUP_FILTER="Detailed";INTERVAL="<Offer>"^402~0^403~0^405~0^406~0', v_OBJECT_ID);
         <<L11>>
         DECLARE
            v_PARENT_OBJECT_ID NUMBER(9) := L10.v_OBJECT_ID;
            v_OBJECT_ID NUMBER(9);
         BEGIN
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'DETAILED_TRAIT_REPORT_Grid_DETAIL', 'Grid', 'Detailed Trait Report Grid Detail', '', 0, 0, '301~ALLEGHENY_CUSTOM.PUT_IT_TRAIT_SCHED_DETAIL_RPT^305~0^307~ResourceTrait^308~1^309~0', v_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'CUT_DATE_SCHEDULING', 'Column', 'CUT_DATE_SCHEDULING', '', 0, 1, '1~x (No Edit)^2~0^3~Short Date^4~7^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~5^24~0^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SCHEDULE_DATE_STR', 'Column', 'Date', '', 0, 0, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~1^24~0^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'PRICE', 'Column', '', '', 1, 0, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~1^22~1^24~0^26~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'AMOUNT', 'Column', 'Quantity', '', 2, 0, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~1^22~1^24~0^26~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'REVIEW_STATUS', 'Column', 'Review', '', 3, 0, '2~0^4~0^7~0^9~0^11~1^12~0^13~0^14~0^15~0^20~1^22~6^24~0^26~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SUBMIT_STATUS', 'Column', 'Submit', '', 4, 0, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~1^22~6^24~0^26~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'MARKET_STATUS', 'Column', 'Market', '', 5, 0, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~1^22~6^24~0^26~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'REASON_FOR_CHANGE', 'Column', '', '', 6, 1, '1~e (Standard Edit)^2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~6^24~0^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'OTHER_REASON', 'Column', 'Notes', '', 7, 0, '1~e (Standard Edit)^2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~6^24~0^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'PRICE_MULTIPLIER', 'Column', 'Price Multiplier', '', 8, 0, '1~e (Standard Edit)^2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~6^24~0^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'PROCESS_MESSAGE', 'Column', '', '', 8, 1, '1~e (Standard Edit)^2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~6^24~0^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRAIT_GROUP_ID', 'Column', '', '', 9, 1, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~5^24~0^26~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRAIT_INDEX', 'Column', '', '', 10, 1, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~5^24~0^26~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRAIT_GROUP_NAME', 'Column', '', '', 11, 0, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~2^24~0^26~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'DISPLAY_NAME', 'Column', '', '', 12, 0, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~2^24~0^26~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRAIT_VAL', 'Column', '', '', 13, 0, '1~e (Standard Edit)^2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~5^24~0^26~0^28~EveryOther^29~X=IF(TRAIT_GROUP_ID=1,SET_NUMBER,0)^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SET_NUMBER', 'Column', '', '', 14, 1, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~5^24~0^26~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'DATA_TYPE', 'Column', '', '', 15, 0, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'EDIT_MASK', 'Column', '', '', 16, 0, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'COMBO_LIST', 'Column', '', '', 17, 0, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'FORMAT', 'Column', '', '', 18, 0, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0', v_CHILD_OBJECT_ID);
         END;
          
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRANSACTION_ID', 'Report Filter', 'Transaction ID', '', 0, 0, '501~x (Custom)^508~0^512~com.newenergyassoc.ro.scheduling.bao.BidsAndOffersTreeFilterComponent^513~1^514~1^515~1', v_CHILD_OBJECT_ID);
      END;
       
      -------------------------------------
      --   SCHEDULE_DETAIL_REPORT
      -------------------------------------
      <<L12>>
      DECLARE
         v_PARENT_OBJECT_ID NUMBER(9) := L0.v_OBJECT_ID;
         v_OBJECT_ID NUMBER(9);
      BEGIN
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'SCHEDULE_DETAIL_REPORT', 'Report', 'Schedule Detail', '', 5, 0, '401~TG.GET_IT_TRAIT_SCHED_TRAIT_RPT;SCHEDULE_STATE=1;TRAIT_GROUP_FILTER="%";INTERVAL="Day"^402~0^403~0^405~0^406~0', v_OBJECT_ID);
         <<L13>>
         DECLARE
            v_PARENT_OBJECT_ID NUMBER(9) := L12.v_OBJECT_ID;
            v_OBJECT_ID NUMBER(9);
         BEGIN
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'SCHEDULE_DETAIL_REPORT_Grid', 'Grid', 'Schedule Detail Report Grid', '', 0, 0, '301~TG.PUT_IT_TRAIT_SCHED_DETAIL_RPT^305~0^307~Standard^308~0^309~0', v_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SCHEDULE_DATE_STR', 'Column', 'Schedule Date', '', 0, 0, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0^28~EveryOther^29~X=REAL_ROWNUM^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRAIT_GROUP_ID', 'Column', '', '', 1, 1, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRAIT_INDEX', 'Column', '', '', 2, 1, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRAIT_GROUP_NAME', 'Column', '', '', 3, 1, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'DISPLAY_NAME', 'Column', 'Trait Name', '', 4, 0, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0^28~EveryOther^29~X=REAL_ROWNUM^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SET_NUMBER', 'Column', '', '', 5, 1, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^25~=1^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'DATA_TYPE', 'Column', '', '', 6, 1, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'EDIT_MASK', 'Column', '', '', 7, 1, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'COMBO_LIST', 'Column', '', '', 8, 1, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'FORMAT', 'Column', '', '', 9, 1, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRAIT_VAL', 'Column', 'Value', '', 10, 0, '1~e (Standard Edit)^2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^23~This is about right.^24~0^26~0^28~EveryOther^29~X=REAL_ROWNUM^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'REAL_ROWNUM', 'Column', '', '', 11, 1, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'CUT_DATE_SCHEDULING', 'Column', '', '', 12, 1, '2~0^4~7^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
         END;
          
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRANSACTION_ID', 'Report Filter', '', '', 0, 0, '501~x (Custom)^512~com.newenergyassoc.ro.scheduling.bao.BidsAndOffersTreeFilterComponent^513~1^515~1', v_CHILD_OBJECT_ID);
      END;
       
      -------------------------------------
      --   UNIT_SUMMARY_REPORT
      -------------------------------------
      <<L14>>
      DECLARE
         v_PARENT_OBJECT_ID NUMBER(9) := L0.v_OBJECT_ID;
         v_OBJECT_ID NUMBER(9);
      BEGIN
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'UNIT_SUMMARY_REPORT', 'Report', 'Unit Summary', '', 6, 0, '401~ALLEGHENY_CUSTOM.UNIT_SUMMARY^402~1^403~-1^405~0^406~0', v_OBJECT_ID);
         <<L15>>
         DECLARE
            v_PARENT_OBJECT_ID NUMBER(9) := L14.v_OBJECT_ID;
            v_OBJECT_ID NUMBER(9);
         BEGIN
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'UNIT_SUMMARY_REPORT_Grid', 'Grid', 'Unit Summary Report Grid', '', 0, 0, '305~0^307~Anchored^308~1^309~0', v_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRANSACTION_NAME', 'Column', '', '', 0, 1, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'CONTRACT_NAME', 'Column', '', '', 1, 0, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~1^24~0^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'RESOURCE_NAME', 'Column', '', '', 2, 0, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~1^24~0^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRAIT_GROUP_ID', 'Column', '', '', 3, 1, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~5^24~0^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRAIT_INDEX', 'Column', '', '', 4, 1, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRAIT_GROUP_NAME', 'Column', '', '', 5, 0, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~2^24~0^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'DISPLAY_NAME', 'Column', '', '', 6, 0, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~2^24~0^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SET_NUMBER', 'Column', '', '', 7, 1, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~5^24~0^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'DATA_TYPE', 'Column', '', '', 8, 1, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'EDIT_MASK', 'Column', '', '', 9, 1, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'COMBO_LIST', 'Column', '', '', 10, 1, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'FORMAT', 'Column', '', '', 11, 1, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRAIT_VAL', 'Column', '', '', 12, 0, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~5^24~0^26~0^28~EveryOther^29~X=IF(TRAIT_GROUP_ID=1,SET_NUMBER,0)^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SCHEDULE_DATE', 'Column', '', '', 13, 1, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'ROWNUM', 'Column', '', '', 14, 1, '22~5', v_CHILD_OBJECT_ID);
         END;
          
      END;
       
      -------------------------------------
      --   DETAILED_COMPARE_REPORT
      -------------------------------------
      <<L16>>
      DECLARE
         v_PARENT_OBJECT_ID NUMBER(9) := L0.v_OBJECT_ID;
         v_OBJECT_ID NUMBER(9);
      BEGIN
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'DETAILED_COMPARE_REPORT', 'Report', 'Bid Comparison', '', 7, 0, '401~TG.GET_IT_TRAIT_SCHED_DETAIL_RPT;SCHEDULE_STATE=1;TRAIT_GROUP_FILTER="Detailed";INTERVAL="<Offer>"^402~0^403~1^404~TG.GET_IT_TRAIT_SCHED_DETAIL_RPT;SCHEDULE_STATE=2;TRAIT_GROUP_FILTER="Detailed";INTERVAL="<Offer>"^405~0^406~0^410~SCHEDULE_DATE_STR', v_OBJECT_ID);
         <<L17>>
         DECLARE
            v_PARENT_OBJECT_ID NUMBER(9) := L16.v_OBJECT_ID;
            v_OBJECT_ID NUMBER(9);
         BEGIN
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'DETAILED_COMPARE_REPORT_Grid', 'Grid', 'Internal', '', 0, 0, '301~TG.PUT_IT_TRAIT_SCHED_DETAIL_RPT^305~0^307~ResourceTrait^308~1^309~0', v_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'CUT_DATE_SCHEDULING', 'Column', 'CUT_DATE_SCHEDULING', '', 0, 1, '1~x (No Edit)^2~0^3~Short Date^4~7^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~5^24~0^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SCHEDULE_DATE_STR', 'Column', 'Date', '', 0, 0, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~1^24~0^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'PRICE', 'Column', '', '', 1, 0, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~1^22~1^24~0^26~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'AMOUNT', 'Column', 'Quantity', '', 2, 0, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~1^22~1^24~0^26~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'REVIEW_STATUS', 'Column', 'Review', '', 3, 0, '2~0^4~0^7~0^9~0^11~1^12~0^13~0^14~0^15~0^20~1^22~6^24~0^26~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SUBMIT_STATUS', 'Column', 'Submit', '', 4, 0, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~1^22~6^24~0^26~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'MARKET_STATUS', 'Column', 'Market', '', 5, 0, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~1^22~6^24~0^26~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'REASON_FOR_CHANGE', 'Column', '', '', 6, 1, '1~e (Standard Edit)^2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~6^24~0^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'OTHER_REASON', 'Column', 'Notes', '', 7, 0, '1~e (Standard Edit)^2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~6^24~0^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'PROCESS_MESSAGE', 'Column', '', '', 8, 1, '1~e (Standard Edit)^2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~6^24~0^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRAIT_GROUP_ID', 'Column', '', '', 9, 1, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~5^24~0^26~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRAIT_INDEX', 'Column', '', '', 10, 1, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~5^24~0^26~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRAIT_GROUP_NAME', 'Column', '', '', 11, 0, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~2^24~0^26~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'DISPLAY_NAME', 'Column', '', '', 12, 0, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~2^24~0^26~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRAIT_VAL', 'Column', '', '', 13, 0, '1~e (Standard Edit)^2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~5^24~0^26~0^28~EveryOther^29~X=IF(TRAIT_GROUP_ID=1,SET_NUMBER,0)^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SET_NUMBER', 'Column', '', '', 14, 1, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~5^24~0^26~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'DATA_TYPE', 'Column', '', '', 15, 0, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'EDIT_MASK', 'Column', '', '', 16, 0, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'COMBO_LIST', 'Column', '', '', 17, 0, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'FORMAT', 'Column', '', '', 18, 0, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0', v_CHILD_OBJECT_ID);
         END;
          
         <<L18>>
         DECLARE
            v_PARENT_OBJECT_ID NUMBER(9) := L16.v_OBJECT_ID;
            v_OBJECT_ID NUMBER(9);
         BEGIN
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'DETAILED_COMPARE_REPORT_Grid_COMPARE', 'Grid', 'External', '', 0, 0, '301~TG.PUT_IT_TRAIT_SCHED_DETAIL_RPT^305~0^307~ResourceTrait^308~1^309~0', v_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'CUT_DATE_SCHEDULING', 'Column', 'CUT_DATE_SCHEDULING', '', 0, 1, '1~x (No Edit)^2~0^3~Short Date^4~7^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~5^24~0^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SCHEDULE_DATE_STR', 'Column', 'Date', '', 0, 0, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~1^24~0^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'PRICE', 'Column', '', '', 1, 0, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~1^22~1^24~0^26~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'AMOUNT', 'Column', 'Quantity', '', 2, 0, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~1^22~1^24~0^26~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'REVIEW_STATUS', 'Column', 'Review', '', 3, 0, '2~0^4~0^7~0^9~0^11~1^12~0^13~0^14~0^15~0^20~1^22~6^24~0^26~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SUBMIT_STATUS', 'Column', 'Submit', '', 4, 0, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~1^22~6^24~0^26~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'MARKET_STATUS', 'Column', 'Market', '', 5, 0, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~1^22~6^24~0^26~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'REASON_FOR_CHANGE', 'Column', '', '', 6, 1, '1~e (Standard Edit)^2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~6^24~0^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'OTHER_REASON', 'Column', 'Notes', '', 7, 0, '1~e (Standard Edit)^2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~6^24~0^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'PROCESS_MESSAGE', 'Column', '', '', 8, 1, '1~e (Standard Edit)^2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~6^24~0^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRAIT_GROUP_ID', 'Column', '', '', 9, 1, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~5^24~0^26~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRAIT_INDEX', 'Column', '', '', 10, 1, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~5^24~0^26~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRAIT_GROUP_NAME', 'Column', '', '', 11, 0, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~2^24~0^26~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'DISPLAY_NAME', 'Column', '', '', 12, 0, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~2^24~0^26~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRAIT_VAL', 'Column', '', '', 13, 0, '1~e (Standard Edit)^2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~5^24~0^26~0^28~EveryOther^29~X=IF(TRAIT_GROUP_ID=1,SET_NUMBER,0)^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SET_NUMBER', 'Column', '', '', 14, 1, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~5^24~0^26~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'DATA_TYPE', 'Column', '', '', 15, 0, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'EDIT_MASK', 'Column', '', '', 16, 0, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'COMBO_LIST', 'Column', '', '', 17, 0, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'FORMAT', 'Column', '', '', 18, 0, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0', v_CHILD_OBJECT_ID);
         END;
          
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRANSACTION_ID', 'Report Filter', 'Transaction ID', '', 0, 0, '501~x (Custom)^508~0^512~com.newenergyassoc.ro.scheduling.bao.BidsAndOffersTreeFilterComponent^513~1^514~0^515~1', v_CHILD_OBJECT_ID);
      END;
       
      -------------------------------------
      --   SPARSE_COMPARE_REPORT
      -------------------------------------
      <<L19>>
      DECLARE
         v_PARENT_OBJECT_ID NUMBER(9) := L0.v_OBJECT_ID;
         v_OBJECT_ID NUMBER(9);
      BEGIN
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'SPARSE_COMPARE_REPORT', 'Report', 'Unit Comparison', '', 8, 1, '401~TG.GET_IT_TRAIT_SCHED_SPARSE_RPT;SCHEDULE_STATE=1;TRAIT_GROUP_FILTER="%"^402~0^403~1^404~TG.GET_IT_TRAIT_SCHED_SPARSE_RPT;SCHEDULE_STATE=2;TRAIT_GROUP_FILTER="%"^405~0^406~0', v_OBJECT_ID);
         <<L20>>
         DECLARE
            v_PARENT_OBJECT_ID NUMBER(9) := L19.v_OBJECT_ID;
            v_OBJECT_ID NUMBER(9);
         BEGIN
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'SPARSE_COMPARE_REPORT_Grid', 'Grid', 'Internal', '', 0, 0, '301~TG.PUT_IT_TRAIT_SCHED_SPARSE_RPT^305~1^308~0^309~0', v_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SCHEDULE_DATE', 'Column', 'Start Date', '', 0, 0, '1~d (Date Picker)^2~0^4~7^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SCHEDULE_TIME', 'Column', 'Time', '', 1, 0, '2~0^4~0^6~##:##^7~0^9~0^11~0^12~0^13~1^14~0^15~0^20~0^22~0^23~24:24^24~0^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SCHEDULE_END_DATE', 'Column', 'End Date', '', 2, 0, '1~d (Date Picker)^2~0^4~7^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SCHEDULE_END_TIME', 'Column', 'Time', '', 3, 0, '2~0^4~0^6~##:##^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^23~24:24^24~0^26~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRAIT_GROUP_INDEX_ID', 'Column', 'Trait Name', '', 4, 0, '1~s (Special List)^2~0^4~0^7~0^9~0^11~0^12~0^13~1^14~0^15~0^16~TG.TRAIT_GROUP_INDEX_LIST_SPARSE;TRANSACTION_ID;"%^20~0^22~0^23~PJM.Default High EmergencyTempRangeTemp^24~0^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRAIT_GROUP_INDEX_NAME', 'Column', '', '', 5, 1, '1~x (No Edit)^2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^23~MISO DEFAULT DISPATCH MINIMUM^24~0^26~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SET_NUMBER', 'Column', '', '', 6, 0, '1~n (Numeric Edit)^2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'DATA_TYPE', 'Column', '', '', 7, 1, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'EDIT_MASK', 'Column', '', '', 8, 1, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'COMBO_LIST', 'Column', '', '', 9, 1, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'FORMAT', 'Column', '', '', 10, 1, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRAIT_VAL', 'Column', 'Value', '', 11, 0, '1~e (Standard Edit)^2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'ORIG_SCHEDULE_DATE', 'Column', '', '', 12, 1, '2~0^4~7^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0', v_CHILD_OBJECT_ID);
         END;
          
         <<L21>>
         DECLARE
            v_PARENT_OBJECT_ID NUMBER(9) := L19.v_OBJECT_ID;
            v_OBJECT_ID NUMBER(9);
         BEGIN
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'SPARSE_COMPARE_REPORT_Grid_COMPARE', 'Grid', 'External', '', 0, 0, '301~TG.PUT_IT_TRAIT_SCHED_SPARSE_RPT^305~1^308~0^309~0', v_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SCHEDULE_DATE', 'Column', 'Start Date', '', 0, 0, '1~d (Date Picker)^2~0^4~7^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SCHEDULE_TIME', 'Column', 'Time', '', 1, 0, '2~0^4~0^6~##:##^7~0^9~0^11~0^12~0^13~1^14~0^15~0^20~0^22~0^23~24:24^24~0^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SCHEDULE_END_DATE', 'Column', 'End Date', '', 2, 0, '1~d (Date Picker)^2~0^4~7^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SCHEDULE_END_TIME', 'Column', 'Time', '', 3, 0, '2~0^4~0^6~##:##^7~0^9~0^11~0^12~0^13~1^14~0^15~0^20~0^22~0^23~24:24^24~0^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRAIT_GROUP_INDEX_ID', 'Column', 'Trait Name', '', 4, 0, '1~s (Special List)^2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^16~TG.TRAIT_GROUP_INDEX_LIST_SPARSE;TRANSACTION_ID;"%^20~0^22~0^23~PJM.Default High EmergencyTempRangeTemp^24~0^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRAIT_GROUP_INDEX_NAME', 'Column', '', '', 5, 1, '1~x (No Edit)^2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^23~MISO DEFAULT DISPATCH MINIMUM^24~0^26~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SET_NUMBER', 'Column', '', '', 6, 0, '1~n (Numeric Edit)^2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'DATA_TYPE', 'Column', '', '', 7, 1, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'EDIT_MASK', 'Column', '', '', 8, 1, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'COMBO_LIST', 'Column', '', '', 9, 1, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'FORMAT', 'Column', '', '', 10, 1, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRAIT_VAL', 'Column', 'Value', '', 11, 0, '1~e (Standard Edit)^2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'ORIG_SCHEDULE_DATE', 'Column', '', '', 12, 1, '2~0^4~7^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0', v_CHILD_OBJECT_ID);
         END;
          
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRANSACTION_ID', 'Report Filter', 'Transaction ID', '', 0, 0, '501~x (Custom)^508~0^512~com.newenergyassoc.ro.scheduling.bao.BidsAndOffersTreeFilterComponent^513~1^514~0^515~1', v_CHILD_OBJECT_ID);
      END;
       
      -------------------------------------
      --   DETAILED_TRAIT_REPORT2
      -------------------------------------
      <<L22>>
      DECLARE
         v_PARENT_OBJECT_ID NUMBER(9) := L0.v_OBJECT_ID;
         v_OBJECT_ID NUMBER(9);
      BEGIN
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'DETAILED_TRAIT_REPORT2', 'Report', 'Regulation Updates', '', 9, 0, '401~TG.GET_IT_TRAIT_SCHED_TRAIT_RPT;SCHEDULE_STATE=1;TRAIT_GROUP_FILTER="Regulation";INTERVAL="Hour"^402~0^403~0^405~0^406~0', v_OBJECT_ID);
         <<L23>>
         DECLARE
            v_PARENT_OBJECT_ID NUMBER(9) := L22.v_OBJECT_ID;
            v_OBJECT_ID NUMBER(9);
         BEGIN
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'DETAILED_TRAIT_REPORT2_Grid', 'Grid', '', '', 0, 0, '301~TG.PUT_IT_TRAIT_SCHEDULE^305~0^307~ResourceTrait^308~1^309~0', v_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SCHEDULE_DATE_STR', 'Column', 'Date', '', 0, 0, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~1^24~0^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRAIT_GROUP_ID', 'Column', '', '', 1, 1, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~5^24~0^26~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRAIT_INDEX', 'Column', '', '', 2, 1, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~5^24~0^26~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRAIT_GROUP_NAME', 'Column', '', '', 3, 0, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~2^24~0^26~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'DISPLAY_NAME', 'Column', '', '', 4, 0, '2~0^4~0^7~0^9~0^11~1^12~0^13~0^14~0^15~0^20~0^22~2^24~0^26~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SET_NUMBER', 'Column', '', '', 5, 1, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~5^24~0^26~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'DATA_TYPE', 'Column', '', '', 6, 1, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'EDIT_MASK', 'Column', '', '', 7, 1, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'COMBO_LIST', 'Column', '', '', 8, 1, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'FORMAT', 'Column', '', '', 9, 1, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRAIT_VAL', 'Column', '', '', 10, 0, '1~e (Standard Edit)^2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~5^24~0^26~0^28~EveryOther^29~X=ROWNUM+1^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'ROWNUM', 'Column', '', '', 11, 1, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~5^24~0^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'CUT_DATE_SCHEDULING', 'Column', '', '', 12, 1, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~5^24~0^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SCHEDULE_DATE', 'Column', '', '', 13, 1, '22~5^25~=CUT_DATE_SCHEDULING', v_CHILD_OBJECT_ID);
         END;
          
         <<L24>>
         DECLARE
            v_PARENT_OBJECT_ID NUMBER(9) := L22.v_OBJECT_ID;
            v_OBJECT_ID NUMBER(9);
         BEGIN
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'DETAILED_TRAIT_REPORT2_Grid_DETAIL', 'Grid', '', '', 0, 0, '', v_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SCHEDULE_DATE_STR', 'Column', '', '', 0, 0, '', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRAIT_GROUP_ID', 'Column', '', '', 1, 0, '', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRAIT_INDEX', 'Column', '', '', 2, 0, '', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRAIT_GROUP_NAME', 'Column', '', '', 3, 0, '', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'DISPLAY_NAME', 'Column', '', '', 4, 0, '', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SET_NUMBER', 'Column', '', '', 5, 0, '', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'DATA_TYPE', 'Column', '', '', 6, 0, '', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'EDIT_MASK', 'Column', '', '', 7, 0, '', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'COMBO_LIST', 'Column', '', '', 8, 0, '', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'FORMAT', 'Column', '', '', 9, 0, '', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRAIT_VAL', 'Column', '', '', 10, 0, '', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'ROWNUM', 'Column', '', '', 11, 0, '', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'REAL_ROWNUM', 'Column', '', '', 12, 0, '', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'CUT_DATE_SCHEDULING', 'Column', '', '', 13, 0, '', v_CHILD_OBJECT_ID);
         END;
          
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRANSACTION_ID', 'Report Filter', 'Transaction Id', '', 0, 0, '501~x (Custom)^508~0^512~com.newenergyassoc.ro.scheduling.bao.BidsAndOffersTreeFilterComponent^513~1^514~0^515~1', v_CHILD_OBJECT_ID);
      END;
       
      SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'REGULATION_OFFER_REPORT', 'Report', 'Regulation Offers', '', 10, 1, '', v_CHILD_OBJECT_ID);
END;
END;
/
