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
   --   MISO_5MIN_LMPS
   -------------------------------------
      SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'MISO_5MIN_LMPS', 'Report', 'MISO 5-minute LMP points', '', 8, 0, '401~MM_MISO.GET_5MIN_LMP_REPORT', v_OBJECT_ID);
      -------------------------------------
      --   MISO_5MIN_LMPS_Grid
      -------------------------------------
      <<L1>>
      DECLARE
         v_PARENT_OBJECT_ID NUMBER(9) := L0.v_OBJECT_ID;
         v_OBJECT_ID NUMBER(9);
      BEGIN
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'MISO_5MIN_LMPS_Grid', 'Grid', '', '', 0, 0, '301~MM_MISO.PUT_MISO_5MIN_LMP_SVC_PT^302~MM_MISO.DEL_MISO_5MIN_LMP_SVC_PT', v_OBJECT_ID);
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SERVICE_POINT_ID', 'Column', 'Use for 5min LMP', '', 0, 0, '1~o (Object List)^8~SERVICE_POINT', v_CHILD_OBJECT_ID);
      END;
       
END;
END;
/
