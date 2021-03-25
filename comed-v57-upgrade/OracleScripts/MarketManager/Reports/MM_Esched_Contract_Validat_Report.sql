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
   --   ESCHED_CONTRACT_VALIDAT_RPT
   -------------------------------------
      SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'ESCHED_CONTRACT_VALIDAT_RPT', 'Report', 'eSchedule Contract Validation', '', 2, 0, '401~MM_PJM.ESCHED_CONTRACT_RPT', v_OBJECT_ID);
      -------------------------------------
      --   ESCHED_CONTRACT_VALIDAT_RPT_Grid
      -------------------------------------
      <<L1>>
      DECLARE
         v_PARENT_OBJECT_ID NUMBER(9) := L0.v_OBJECT_ID;
         v_OBJECT_ID NUMBER(9);
      BEGIN
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'ESCHED_CONTRACT_VALIDAT_RPT_Grid', 'Grid', '', '', 0, 0, '301~MM_PJM.PUT_ESCHED_CONTRACT_RPT', v_OBJECT_ID);
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRANSACTION_ID_INT', 'Column', 'Transaction Id Int', '', 0, 1, '', v_CHILD_OBJECT_ID);
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'OVERRIDE_INTERNAL', 'Column', 'Override Internal', '', 1, 0, '1~k (Checkbox)^4~11', v_CHILD_OBJECT_ID);
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'INTERNAL_EXISTS', 'Column', 'Internal Exists', '', 2, 0, '1~x (No Edit)^3~Yes;No^4~11', v_CHILD_OBJECT_ID);
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'HAS_DIFFERENCES', 'Column', 'Has Differences', '', 3, 0, '1~x (No Edit)^3~Yes;No^4~11', v_CHILD_OBJECT_ID);
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRANSACTION_NAME', 'Column', 'Transaction Name', '', 4, 0, '', v_CHILD_OBJECT_ID);
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRANSACTION_ID_EXT', 'Column', 'Transaction Id Ext', '', 5, 1, '', v_CHILD_OBJECT_ID);
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRANSACTION_IDENTIFIER', 'Column', 'Transaction Identifier', '', 6, 0, '', v_CHILD_OBJECT_ID);
      END;
       
END;
END;
/
