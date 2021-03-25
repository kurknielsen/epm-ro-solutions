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
   --   PJM_GEN_NAMES_RPT
   -------------------------------------
      SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'PJM_GEN_NAMES_RPT', 'Report', 'Generator Names/IDs', '', 6, 0, '401~MM_PJM_EMKT.GEN_NAMES_RPT^403~Normal Grid^405~-1', v_OBJECT_ID);
      -------------------------------------
      --   PJM_GEN_NAMES_RPT_Grid
      -------------------------------------
      <<L1>>
      DECLARE
         v_PARENT_OBJECT_ID NUMBER(9) := L0.v_OBJECT_ID;
         v_OBJECT_ID NUMBER(9);
      BEGIN
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'PJM_GEN_NAMES_RPT_Grid', 'Grid', 'Pjm Gen Names Rpt Grid', '', 0, 0, '-3~0^-2~0^301~MM_PJM_EMKT.PUT_GEN_NAMES_RPT^305~0^308~0', v_OBJECT_ID);
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'RESOURCE_ID', 'Column', '', '', 0, 1, '-3~0^-2~0^2~0^7~0^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'RESOURCE_NAME', 'Column', '', '', 1, 0, '-3~0^-2~0^1~e (Standard Edit)^2~0^7~0^13~0^20~0^24~0^28~MY_COMPARE^29~X=RESOURCE_NAME;Y=PJM_CID^31~0', v_CHILD_OBJECT_ID);
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'PJM_CID', 'Column', 'PJM Identifier', '', 2, 0, '-3~0^-2~0^1~x (No Edit)^2~0^7~0^13~0^20~0^24~0^28~MY_COMPARE^29~X=RESOURCE_NAME;Y=PJM_CID^31~0', v_CHILD_OBJECT_ID);
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SERVICE_POINT_ID', 'Column', 'Service Point', '', 3, 0, '1~o (Object List)^8~SERVICE_POINT', v_CHILD_OBJECT_ID);
      END;
       
END;
END;
/
