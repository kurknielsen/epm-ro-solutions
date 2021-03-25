DECLARE
   p_STATUS NUMBER;
   v_CHILD_OBJECT_ID NUMBER(9);
BEGIN
<<L0>>
DECLARE
   v_PARENT_OBJECT_ID NUMBER(9) := 0;
   v_OBJECT_ID NUMBER(9) := 0;
BEGIN
 
SO.ID_FOR_SYSTEM_OBJECT(v_PARENT_OBJECT_ID, 'SCHEDULING',0,'Layout','Default',TRUE,v_OBJECT_ID);
v_PARENT_OBJECT_ID := v_OBJECT_ID;
   -------------------------------------
   --   SCHEDULING_PJM_GENERATION
   -------------------------------------
      SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'SCHEDULING_PJM_GENERATION', 'Layout', 'PJM Generation', '', 9, 0, '-3~0^-2~0^701~Aggregate^704~Tabs^711~0', v_OBJECT_ID);
      SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SCHEDULING_PJM_GEN_STATUS', 'Layout', 'Daily Bid Status', '', 0, 0, '701~System View^708~Scheduling.PJM.Generation.StatusSummary', v_CHILD_OBJECT_ID);
      SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SCHEDULING_PJM_GEN_UPDATE_SUMM', 'Layout', 'Units by Day', '', 1, 0, '-3~0^-2~0^701~System View^708~Scheduling.PJM.Generation.UnitUpdateSummary^711~0', v_CHILD_OBJECT_ID);
      SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SCHEDULING_PJM_GEN_UPDATES', 'Layout', 'Units by Hour', '', 2, 0, '-3~0^-2~0^701~System View^708~Scheduling.PJM.Generation.UnitUpdates^711~0', v_CHILD_OBJECT_ID);
      -------------------------------------
      --   SCHEDULING_PJM_GEN_PCCURVES
      -------------------------------------
      <<L1>>
      DECLARE
         v_PARENT_OBJECT_ID NUMBER(9) := L0.v_OBJECT_ID;
         v_OBJECT_ID NUMBER(9);
      BEGIN
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'SCHEDULING_PJM_GEN_PCCURVES', 'Layout', 'Price and Cost Curves', '', 3, 0, '-3~0^-2~0^701~Aggregate^704~Tabs^711~0', v_OBJECT_ID);
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SCHEDULING_PJM_GEN_SCHED_DETAILS', 'Layout', 'Schedule Offers', '', 0, 0, '-3~0^-2~0^701~System View^708~Scheduling.PJM.Generation.PCCurves^711~0', v_CHILD_OBJECT_ID);
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SCHEDULING_PJM_GEN_UNIT_SCHEDULES', 'Layout', 'Schedule Details', '', 1, 0, '-3~0^-2~0^701~System View^708~Scheduling.PJM.Generation.UnitSchedules^711~0', v_CHILD_OBJECT_ID);
      END;
       
      SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SCHEDULING_PJM_GEN_DEFAULTS', 'Layout', 'Unit Details', '', 4, 0, '-3~0^-2~0^701~System View^708~Scheduling.PJM.Generation.UnitDefaults^711~0', v_CHILD_OBJECT_ID);
      SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SCHEDULING_PJM_GEN_REGULATION', 'Layout', 'Regulation', '', 5, 0, '-3~0^-2~0^701~System View^708~Scheduling.PJM.Generation.Regulation^711~0', v_CHILD_OBJECT_ID);
      SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SCHEDULING_PJM_GEN_SPIN', 'Layout', 'Spinning Reserves', '', 6, 0, '-3~0^-2~0^701~System View^708~Scheduling.PJM.Generation.SpinningReserves^711~0', v_CHILD_OBJECT_ID);
END;
END;
/