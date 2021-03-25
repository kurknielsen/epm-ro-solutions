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
   --   EMTR_METER_NODE_MAP
   -------------------------------------
      SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'EMTR_METER_NODE_MAP', 'Report', 'eMTR Meter/Node Map', '', 7, 0, '-3~0^-2~0^401~MM_PJM_EMTR.METER_SVC_PT_MAPPING_RPT^402~0^403~Normal Grid^405~2^406~0', v_OBJECT_ID);
      -------------------------------------
      --   EMTR_METER_NODE_MAP_Grid
      -------------------------------------
      <<L1>>
      DECLARE
         v_PARENT_OBJECT_ID NUMBER(9) := L0.v_OBJECT_ID;
         v_OBJECT_ID NUMBER(9);
      BEGIN
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'EMTR_METER_NODE_MAP_Grid', 'Grid', 'Emtr Meter Node Map Grid', '', 0, 0, '-3~0^-2~0^301~MM_PJM_EMTR.PUT_METER_SVC_PT_MAPPING^305~0^308~0', v_OBJECT_ID);
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'EXTERNAL_IDENTIFIER', 'Column', '', '', 0, 0, '', v_CHILD_OBJECT_ID);
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'METER_ID', 'Column', '', '', 1, 1, '-3~0^-2~0^2~0^7~0^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'METER_NAME', 'Column', '', '', 2, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SERVICE_POINT_ID', 'Column', 'Service Point', '', 3, 0, '-3~0^-2~0^1~o (Object List)^2~0^7~0^8~SERVICE_POINT^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SVC_PT_NAME', 'Column', '', '', 4, 1, '-3~0^-2~0^2~0^7~0^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
      END;
       
END;
END;
/
