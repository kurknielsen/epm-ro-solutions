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
   --   MARKET_CLOSINGS
   -------------------------------------
      SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'MARKET_CLOSINGS', 'Report', 'Market Closings', '', 9, 0, '401~MM.MARKET_CLOSINGS_REPORT', v_OBJECT_ID);
      -------------------------------------
      --   MARKET_CLOSINGS_Grid
      -------------------------------------
      <<L1>>
      DECLARE
         v_PARENT_OBJECT_ID NUMBER(9) := L0.v_OBJECT_ID;
         v_OBJECT_ID NUMBER(9);
      BEGIN
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'MARKET_CLOSINGS_Grid', 'Grid', '', '', 0, 0, '301~MM.MARKET_CLOSINGS_REPORT_UPDATE^302~MM.MARKET_CLOSINGS_REPORT_DELETE', v_OBJECT_ID);
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'DUMMY', 'Column', 'dummy', '', 0, 1, '', v_CHILD_OBJECT_ID);
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'CLOSING_TYPE', 'Column', 'Closing Type', '', 1, 0, '1~c (Combo Box)^5~Award|LMP|Bid|Trait', v_CHILD_OBJECT_ID);
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SC_ID', 'Column', 'Schedule Coordinator', '', 2, 0, '1~o (Object List)^8~SC', v_CHILD_OBJECT_ID);
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'COMMODITY_ID', 'Column', 'Commodity', '', 3, 0, '1~o (Object List)^8~IT_COMMODITY', v_CHILD_OBJECT_ID);
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRANSACTION_TYPE', 'Column', 'Transaction Type', '', 4, 0, '1~c (Combo Box)^5~Generation|Load|Purchase|Sale', v_CHILD_OBJECT_ID);
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'IS_IMPORT_EXPORT', 'Column', 'Is Import Export', '', 5, 0, '', v_CHILD_OBJECT_ID);
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRUNCATE_TO', 'Column', 'Truncate To', '', 6, 0, '', v_CHILD_OBJECT_ID);
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'DAYS_ADDED', 'Column', 'Days Added', '', 7, 0, '', v_CHILD_OBJECT_ID);
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'HOURS_ADDED', 'Column', 'Hours Added', '', 8, 0, '', v_CHILD_OBJECT_ID);
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'MINUTES_ADDED', 'Column', 'Minutes Added', '', 9, 0, '', v_CHILD_OBJECT_ID);
      END;
       
      SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SC_ID', 'Report Filter', 'Schedule Coordinator', '', 1, 0, '501~o (Object List)^503~SC', v_CHILD_OBJECT_ID);
END;
END;
/
