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
SO.ID_FOR_SYSTEM_OBJECT(v_PARENT_OBJECT_ID, 'PJM_LOAD_FORECAST_RPT',0,'Report','Default',TRUE,v_OBJECT_ID);
v_PARENT_OBJECT_ID := v_OBJECT_ID;
   -------------------------------------
   --   PJM_LOAD_FORECAST_RPT_Grid
   -------------------------------------
      SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'PJM_LOAD_FORECAST_RPT_Grid', 'Grid', 'Pjm Load Forecast Rpt Grid', '', 0, 0, '-3~0^-2~0^305~0^307~Anchored^308~0^309~3', v_OBJECT_ID);
      SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SERVICE_ZONE_NAME', 'Column', 'Zone', '', 0, 0, '-3~0^-2~0^2~0^4~0^7~0^9~0^13~0^20~0^22~2^24~0^31~0', v_CHILD_OBJECT_ID);
      SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SCHEDULE_DATE', 'Column', 'Date', '', 1, 0, '-3~0^-2~0^2~0^4~7^7~0^9~0^13~0^20~0^22~1^24~1^31~0', v_CHILD_OBJECT_ID);
      SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'AMOUNT', 'Column', 'MWh', '', 2, 0, '-3~0^-2~0^2~0^4~0^7~0^9~0^11~4^13~0^20~0^22~5^24~0^31~0', v_CHILD_OBJECT_ID);
      SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'LOAD_FORECAST_REFRESH', 'Label', 'Last Updated', '', 0, 0, '-3~0^-2~0^1101~2^1102~=Format(LAST_UPDATE_DATE, "HH:mm MMMM dd, yyyy")', v_CHILD_OBJECT_ID);
END;
END;
/
