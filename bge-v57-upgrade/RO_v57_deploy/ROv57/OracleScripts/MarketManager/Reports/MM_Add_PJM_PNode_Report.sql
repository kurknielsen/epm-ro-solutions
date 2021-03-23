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
   --   PJM_PNODES_RPT
   -------------------------------------
      SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'PJM_PNODES_RPT', 'Report', 'Add PJM PNode', '', 5, 0, '401~MM_PJM_EMKT.PJM_PNODES_RPT', v_OBJECT_ID);
      -------------------------------------
      --   PJM_PNODES_RPT_Grid
      -------------------------------------
      <<L1>>
      DECLARE
         v_PARENT_OBJECT_ID NUMBER(9) := L0.v_OBJECT_ID;
         v_OBJECT_ID NUMBER(9);
      BEGIN
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'PJM_PNODES_RPT_Grid', 'Grid', '', '', 0, 0, '301~MM_PJM_EMKT.PUT_PJM_PNODES_RPT', v_OBJECT_ID);
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'DUMMY', 'Column', 'dummy', '', 0, 1, '', v_CHILD_OBJECT_ID);
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'ADD_SVC_POINT', 'Column', 'Add Svc Point', '', 1, 0, '1~k (Checkbox)^4~11', v_CHILD_OBJECT_ID);
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'NODENAME', 'Column', 'Node Name', '', 2, 0, '', v_CHILD_OBJECT_ID);
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'NODETYPE', 'Column', 'Node Type', '', 3, 0, '', v_CHILD_OBJECT_ID);
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'PNODEID', 'Column', 'Pnodeid', '', 4, 1, '', v_CHILD_OBJECT_ID);
      END;
       
      SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'NODE_TYPE', 'Report Filter', 'Node Type', '', 1, 0, '501~c (Combo Box)^502~<All>|500|Aggregate|Bus|Interface|Zone^507~<All>', v_CHILD_OBJECT_ID);
END;
END;
/
