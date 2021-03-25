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
   --   BILAT_CONTRACT_VALIDAT_RPT
   -------------------------------------
      SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'BILAT_CONTRACT_VALIDAT_RPT', 'Report', 'Bilateral Contract Validation', '', 1, 0, '401~MM.BILAT_CONTRACT_VALIDAT_RPT', v_OBJECT_ID);
      -------------------------------------
      --   BILAT_CONTRACT_VALIDAT_RPT_Grid
      -------------------------------------
      <<L1>>
      DECLARE
         v_PARENT_OBJECT_ID NUMBER(9) := L0.v_OBJECT_ID;
         v_OBJECT_ID NUMBER(9);
      BEGIN
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'BILAT_CONTRACT_VALIDAT_RPT_Grid', 'Grid', '', '', 0, 0, '301~MM.PUT_BILAT_CONTRACT_VALIDAT_RPT^304~MM.BILAT_CONTRACT_DRILL_DOWN', v_OBJECT_ID);
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRANSACTION_ID_INT', 'Column', 'Transaction Id Int', '', 0, 1, '', v_CHILD_OBJECT_ID);
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'OVERRIDE_INTERNAL', 'Column', 'Override Internal', '', 1, 0, '1~k (Checkbox)^4~11', v_CHILD_OBJECT_ID);
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'INTERNAL_EXISTS', 'Column', 'Internal Exists', '', 2, 0, '1~x (No Edit)^3~Yes;No^4~11', v_CHILD_OBJECT_ID);
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'HAS_DIFFERENCES', 'Column', 'Has Differences', '', 3, 0, '1~x (No Edit)^3~Yes;No^4~11', v_CHILD_OBJECT_ID);
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRANSACTION_NAME', 'Column', 'Transaction Name', '', 4, 0, '', v_CHILD_OBJECT_ID);
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRANSACTION_ID_EXT', 'Column', 'Transaction Id Ext', '', 5, 1, '', v_CHILD_OBJECT_ID);
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRANSACTION_IDENTIFIER', 'Column', 'Transaction Identifier', '', 6, 0, '', v_CHILD_OBJECT_ID);
         <<L2>>
         DECLARE
            v_PARENT_OBJECT_ID NUMBER(9) := L1.v_OBJECT_ID;
            v_OBJECT_ID NUMBER(9);
         BEGIN
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'grdDrillDown', 'Grid', '', '', 0, 0, '201~MM.BILAT_CONTRACT_DRILL_DOWN', v_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'FIELD', 'Column', 'Field Name', '', 0, 0, '', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'INTERNAL', 'Column', 'Internal Value', '', 1, 0, '', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'EXTERNAL', 'Column', 'External Value', '', 2, 0, '', v_CHILD_OBJECT_ID);
         END;
          
      END;
       
      SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SC_ID', 'Report Filter', 'Schedule Coordinator', '', 1, 0, '501~o (Object List)^503~SC', v_CHILD_OBJECT_ID);
      SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'COUNTER_PARTY_ID', 'Report Filter', 'Counter Party', '', 2, 0, '501~o (Object List)^503~PSE|#1;<All>', v_CHILD_OBJECT_ID);
END;
END;
/
