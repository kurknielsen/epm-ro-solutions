
CREATE OR REPLACE PACKAGE BODY ZBUILD_SCHEDULING_OBJECTS IS
-- $Revision: 1.3 $
----------------------------------------------------------------------------------------------------
FUNCTION WHAT_VERSION RETURN VARCHAR IS
BEGIN
    RETURN '$Revision: 1.3 $';
END WHAT_VERSION;
----------------------------------------------------------------------------------------------------
PROCEDURE BUILD IS
   p_STATUS NUMBER;
   v_CHILD_OBJECT_ID NUMBER(9);
BEGIN
<<L0>>
DECLARE
   v_PARENT_OBJECT_ID NUMBER(9) := 0;
   v_OBJECT_ID NUMBER(9) := 0;
BEGIN
 
   -------------------------------------
   --   Scheduling
   -------------------------------------
      SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'Scheduling', 'Module', 'Scheduling', '', 0, 0, '-3~0^-2~0', v_OBJECT_ID);
      -------------------------------------
      --   GasDelivery.Assignments
      -------------------------------------
      <<L1>>
      DECLARE
         v_PARENT_OBJECT_ID NUMBER(9) := L0.v_OBJECT_ID;
         v_OBJECT_ID NUMBER(9);
      BEGIN
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'GasDelivery.Assignments', 'System View', 'Gasdelivery.Assignments', '', 0, 0, '-3~0^-2~0^801~com.newenergyassoc.ro.scheduling.balancing.BalancingContentPanel', v_OBJECT_ID);
         <<L2>>
         DECLARE
            v_PARENT_OBJECT_ID NUMBER(9) := L1.v_OBJECT_ID;
            v_OBJECT_ID NUMBER(9);
         BEGIN
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'LOAD_BALANCING_REPORT', 'Report', 'Assignments By Supply', '', 0, 0, '-3~0^-2~0^401~GDJ.GAS_DEL_BY_SUPPLY_SUMMARY^402~0^403~Lazy Master/Detail Grids^404~GDJ.GAS_DEL_BY_SUPPLY_DETAILS^406~0^409~Vertical', v_OBJECT_ID);
            <<L3>>
            DECLARE
               v_PARENT_OBJECT_ID NUMBER(9) := L2.v_OBJECT_ID;
               v_OBJECT_ID NUMBER(9);
            BEGIN
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'LOAD_BALANCING_REPORT_Grid_MASTER', 'Grid', 'Supply Transactions', '', 1, 0, '-3~0^-2~0^305~0^308~0', v_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SUPPLY_TRANSACTION_NAME', 'Column', 'Supply Transaction', '', 0, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^24~1^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SUPPLY_TRANSACTION_ID', 'Column', '', '', 1, 1, '-3~0^-2~0^2~0^7~0^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'VOLUME', 'Column', 'Total Volume', '', 2, 0, '-3~0^-2~0^2~0^7~0^11~7^13~0^14~2^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'ALLOC', 'Column', 'Total Allocated', '', 3, 0, '-3~0^-2~0^2~0^7~0^11~7^13~0^14~2^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TO_BE_ALLOCATED', 'Column', 'To Be Allocated', '', 4, 0, '-3~0^-2~0^2~0^7~0^11~7^13~0^14~2^20~0^24~0^25~VOLUME - ALLOC^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'DELIVERY_COUNT', 'Column', 'Number of Delivery Paths', '', 5, 0, '11~7', v_CHILD_OBJECT_ID);
            END;
             
            <<L4>>
            DECLARE
               v_PARENT_OBJECT_ID NUMBER(9) := L2.v_OBJECT_ID;
               v_OBJECT_ID NUMBER(9);
            BEGIN
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'LOAD_BALANCING_REPORT_Grid_DETAIL', 'Grid', 'Deliveries for Selected Supply', '', 2, 0, '-3~0^-2~0^301~GDJ.PUT_GAS_DEL_REPORT^305~0^307~Anchored^308~0', v_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'Show', 'Action', 'Show Transaction...', '', 0, 0, '-3~0^-2~0^1004~not islist(TRANSACTION_ID)^1006~2^1007~Common.EntityManager;entityType="TRANSACTION";entityId=TRANSACTION_ID', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'LimitValidation', 'Action', 'Contract Limit Validation...', '', 1, 0, '-3~0^-2~0^1004~not islist(DELIVERY_TRANSACTION_ID)^1006~2^1007~GasDelivery.DeliveryLimitsValidation;DELIVERY_ID=DELIVERY_TRANSACTION_ID', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'Segment Details', 'Action', 'Delivery Segment Details', '', 2, 0, '-3~0^-2~0^1004~not islist(DELIVERY_TRANSACTION_ID)^1006~6^1007~GasDelivery.Assignments;REPORT_NAME="SEGMENT_DETAILS";PIPELINE_ID=-1;POR_ID=-1;POD_ID=-1;DELIVERY_ID=DELIVERY_TRANSACTION_ID', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SCHEDULE_DATE', 'Column', '', '', 0, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~1^24~1^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SUPPLY_TRANSACTION_ID', 'Column', '', '', 2, 1, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~6^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SUPPLY_TRANSACTION_NAME', 'Column', '', '', 3, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~7^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SUPPLY_VOLUME', 'Column', '', '', 4, 0, '-3~0^-2~0^2~0^7~0^11~7^13~0^14~2^20~0^22~6^24~0^27~SUPPLY_TRANSACTION_NAME^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'ALLOCATED_VOLUME_OLD', 'Column', '', '', 5, 1, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~6^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'ALLOCATED_VOLUME', 'Column', '', '', 6, 0, '-3~0^-2~0^2~0^7~0^11~7^13~0^14~2^20~0^22~6^24~0^25~ALLOCATED_VOLUME_OLD - SUM(ASSIGNED_AMOUNT_OLD) + SUM(ASSIGNED_AMOUNT)^27~SUPPLY_TRANSACTION_NAME^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TO_BE_ALLOCATED', 'Column', '', '', 7, 0, '-3~0^-2~0^2~0^7~0^11~7^13~0^14~2^20~0^22~6^24~0^25~SUPPLY_VOLUME - ALLOCATED_VOLUME^27~SUPPLY_TRANSACTION_NAME^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'IMBALANCE_AMOUNT', 'Column', '', '', 8, 1, '22~6^25~-TO_BE_ALLOCATED', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'HAS_NO_ASSIGNMENTS', 'Column', '', '', 9, 0, '22~4', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'DELIVERY_TRANSACTION_NAME', 'Column', '', '', 10, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~2^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'DELIVERY_TRANSACTION_ID', 'Column', '', '', 11, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~4^24~0^31~0^32~1', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRANSACTION_ID', 'Column', '', '', 12, 1, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~5^24~0^25~DELIVERY_TRANSACTION_ID^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SCHEDULED_OLD', 'Column', '', '', 13, 1, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~5^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SCHEDULED', 'Column', '', '', 14, 0, '-3~0^-2~0^2~0^7~0^11~7^13~0^14~2^20~0^22~5^24~0^25~SCHEDULED_OLD - ASSIGNED_AMOUNT_OLD + ASSIGNED_AMOUNT^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SUPPLY_PRICE', 'Column', '', '', 15, 1, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~5^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'ASSIGNED_AMOUNT', 'Column', '<html><b>Assigned</b></html>', '', 16, 0, '-3~0^-2~0^1~n (Numeric Edit)^2~0^7~0^11~7^13~0^14~2^19~if ( ASSIGNED_AMOUNT > LIMIT, "label:alertAssignedHigh", if ( ASSIGNED_AMOUNT < 0 , "label:alertAssignedLow", "" ) )^20~0^22~5^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'ASSIGNED_AMOUNT_OLD', 'Column', '', '', 17, 1, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~5^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'UNSCHEDULED', 'Column', '', '', 18, 1, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~5^24~0^25~TO_BE_ALLOCATED^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'LIMIT', 'Column', '', '', 19, 1, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~5^24~0^25~ASSIGNED_AMOUNT+UNSCHEDULED^31~0', v_CHILD_OBJECT_ID);
            END;
             
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SELLER_ID', 'Report Filter', 'Counter-Party', '', 0, 0, '-3~0^-2~0^501~s (Special List)^504~GDJ.GET_COUNTERPARTIES;#1;BEGIN_DATE;END_DATE^508~0^514~0^515~0^517~Supply^519~0^520~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SUPPLY_POD_ID', 'Report Filter', 'POD', '', 1, 0, '-3~0^-2~0^501~s (Special List)^504~GDJ.GET_SUPPLY_POINTS;BEGIN_DATE;END_DATE^508~0^514~0^515~0^517~Supply^519~0^520~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'PIPELINE_ID', 'Report Filter', 'Pipeline', '', 2, 0, '-3~0^-2~0^501~s (Special List)^504~GDJ.GET_DELIVERY_PIPELINES;BEGIN_DATE;END_DATE^508~0^514~0^515~0^517~Deliveries^518~DELIVERY_POD_ID^519~0^520~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'DELIVERY_POD_ID', 'Report Filter', 'POD', '', 3, 0, '-3~0^-2~0^501~s (Special List)^504~GDJ.GET_DELIVERY_POINTS;PIPELINE_ID;BEGIN_DATE;END_DATE^508~0^514~0^515~0^517~Deliveries^519~0^520~0', v_CHILD_OBJECT_ID);
         END;
          
         <<L5>>
         DECLARE
            v_PARENT_OBJECT_ID NUMBER(9) := L1.v_OBJECT_ID;
            v_OBJECT_ID NUMBER(9);
         BEGIN
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'SUPPLY_SCHEDULING_REPORT', 'Report', 'Assignments By Delivery', '', 1, 0, '-3~0^-2~0^401~GDJ.GAS_DEL_BY_DELIVERY_SUMMARY^402~0^403~Lazy Master/Detail Grids^404~GDJ.GAS_DEL_BY_DELIVERY_DETAILS^406~0^409~Vertical', v_OBJECT_ID);
            <<L6>>
            DECLARE
               v_PARENT_OBJECT_ID NUMBER(9) := L5.v_OBJECT_ID;
               v_OBJECT_ID NUMBER(9);
            BEGIN
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'SUPPLY_SCHEDULING_REPORT_Grid_MASTER', 'Grid', 'Deliveries', '', 1, 0, '-3~0^-2~0^305~0^308~0', v_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'LimitValidation', 'Action', 'Contract Limit Validation...', '', 0, 0, '-3~0^-2~0^1006~2^1007~GasDelivery.DeliveryLimitsValidation;DELIVERY_ID=DELIVERY_TRANSACTION_ID', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SegmentDetails', 'Action', 'Delivery Segment Details', '', 1, 0, '1006~6^1007~GasDelivery.Assignments;REPORT_NAME="SEGMENT_DETAILS";PIPELINE_ID=-1;POR_ID=-1;POD_ID=-1;DELIVERY_ID=DELIVERY_TRANSACTION_ID', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'DELIVERY_TRANSACTION_NAME', 'Column', 'Delivery Transaction', '', 0, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^24~1^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'DELIVERY_TRANSACTION_ID', 'Column', '', '', 1, 1, '-3~0^-2~0^2~0^7~0^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'VOLUME', 'Column', 'Total Volume', '', 2, 0, '-3~0^-2~0^2~0^7~0^11~7^13~0^14~2^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SUPPLY_COUNT', 'Column', 'Number of Supply Deals', '', 3, 0, '11~7', v_CHILD_OBJECT_ID);
            END;
             
            <<L7>>
            DECLARE
               v_PARENT_OBJECT_ID NUMBER(9) := L5.v_OBJECT_ID;
               v_OBJECT_ID NUMBER(9);
            BEGIN
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'SUPPLY_SCHEDULING_REPORT_Grid_DETAIL', 'Grid', 'Supply Transactions for Selected Delivery', '', 2, 0, '-3~0^-2~0^301~GDJ.PUT_GAS_DEL_REPORT^305~0^307~Anchored^308~0', v_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'Show', 'Action', 'Show Transaction...', '', 0, 0, '1004~not islist(TRANSACTION_ID)^1006~2^1007~Common.EntityManager;entityType="TRANSACTION";entityId=TRANSACTION_ID', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'LimitValidation', 'Action', 'Contract Limit Validation...', '', 1, 0, '-3~0^-2~0^1006~2^1007~GasDelivery.DeliveryLimitsValidation;DELIVERY_ID=DELIVERY_TRANSACTION_ID', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SegmentDetails', 'Action', 'Delivery Segment Details', '', 2, 0, '1006~6^1007~GasDelivery.Assignments;REPORT_NAME="SEGMENT_DETAILS";PIPELINE_ID=-1;POR_ID=-1;POD_ID=-1;DELIVERY_ID=DELIVERY_TRANSACTION_ID', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SCHEDULE_DATE', 'Column', '', '', 0, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~1^24~1^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'DELIVERY_TRANSACTION_ID', 'Column', '', '', 1, 1, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~6^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'DELIVERY_TRANSACTION_NAME', 'Column', '', '', 2, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~7^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SCHEDULED_OLD', 'Column', '', '', 3, 1, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~6^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SCHEDULED', 'Column', '', '', 4, 0, '-3~0^-2~0^2~0^7~0^11~7^13~0^14~2^20~0^22~6^24~0^25~SCHEDULED_OLD - SUM(ASSIGNED_AMOUNT_OLD) + SUM(ASSIGNED_AMOUNT)^27~DELIVERY_TRANSACTION_NAME^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'UNSCHEDULED', 'Column', '', '', 5, 1, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~6^24~0^25~9999999^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SUPPLY_TRANSACTION_NAME', 'Column', '', '', 6, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~2^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SUPPLY_TRANSACTION_ID', 'Column', '', '', 7, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~4^24~0^31~0^32~1', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRANSACTION_ID', 'Column', '', '', 8, 1, '22~5^25~SUPPLY_TRANSACTION_ID', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SUPPLY_VOLUME', 'Column', '', '', 10, 0, '-3~0^-2~0^2~0^7~0^11~7^13~0^14~2^20~0^22~5^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'ALLOCATED_VOLUME', 'Column', '', '', 11, 0, '-3~0^-2~0^2~0^7~0^11~7^13~0^14~2^20~0^22~5^24~0^25~TOTAL_ASSIGNED - ASSIGNED_AMOUNT_OLD + ASSIGNED_AMOUNT^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TO_BE_ALLOCATED', 'Column', '', '', 12, 0, '-3~0^-2~0^2~0^7~0^11~7^13~0^14~2^20~0^22~5^24~0^25~SUPPLY_VOLUME - ALLOCATED_VOLUME^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'IMBALANCE', 'Column', '', '', 13, 1, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~5^24~0^25~-TO_BE_ALLOCATED^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'ASSIGNED_AMOUNT', 'Column', '<html><b>Assigned</b></html>', '', 14, 0, '-3~0^-2~0^1~n (Numeric Edit)^2~0^7~0^11~7^13~0^14~2^19~if ( TOTAL_ASSIGNED - ASSIGNED_AMOUNT_OLD + ASSIGNED_AMOUNT > SUPPLY_VOLUME, "label:alertAssignedHigh", if ( ASSIGNED_AMOUNT < 0 , "label:alertAssignedLow", "" ) )^20~0^22~5^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'ASSIGNED_AMOUNT_OLD', 'Column', '', '', 15, 1, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~5^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TOTAL_ASSIGNED', 'Column', '', '', 16, 1, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~5^24~0^31~0', v_CHILD_OBJECT_ID);
            END;
             
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'PIPELINE_ID', 'Report Filter', 'Pipeline', '', 0, 0, '-3~0^-2~0^501~s (Special List)^504~GDJ.GET_DELIVERY_PIPELINES;BEGIN_DATE;END_DATE^508~0^514~0^515~0^517~Deliveries^518~POR_ID,POD_ID^519~0^520~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'POR_ID', 'Report Filter', 'POR', '', 1, 0, '501~s (Special List)^504~GDJ.GET_DELIVERY_RECEIPT_POINTS;PIPELINE_ID;BEGIN_DATE;END_DATE^517~Deliveries', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'POD_ID', 'Report Filter', 'POD', '', 2, 0, '501~s (Special List)^504~GDJ.GET_DELIVERY_POINTS;PIPELINE_ID;BEGIN_DATE;END_DATE^517~Deliveries', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SELLER_ID', 'Report Filter', 'Counter-Party', '', 3, 0, '501~s (Special List)^504~GDJ.GET_COUNTERPARTIES;#1;BEGIN_DATE;END_DATE^517~Supply', v_CHILD_OBJECT_ID);
         END;
          
         <<L8>>
         DECLARE
            v_PARENT_OBJECT_ID NUMBER(9) := L1.v_OBJECT_ID;
            v_OBJECT_ID NUMBER(9);
         BEGIN
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'SEGMENT_DETAILS', 'Report', 'Delivery Segment Details', '', 2, 0, '-3~0^-2~0^401~GDJ.DELIVERY_SEGMENTS_SUMMARY^402~0^403~Lazy Master/Detail Grids^404~GDJ.DELIVERY_SEGMENTS_DETAILS^406~0^407~SCHEDULE_DATE,TRANSACTION_ID^409~Vertical', v_OBJECT_ID);
            <<L9>>
            DECLARE
               v_PARENT_OBJECT_ID NUMBER(9) := L8.v_OBJECT_ID;
               v_OBJECT_ID NUMBER(9);
            BEGIN
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'SEGMENT_DETAILS_Grid_DETAIL', 'Grid', 'Delivery Details', '', 0, 0, '-3~0^-2~0^305~0^308~0', v_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'LimitValidation', 'Action', 'Contract Limit Validation...', '', 0, 0, '-3~0^-2~0^1006~2^1007~GasDelivery.DeliveryLimitsValidation;DELIVERY_ID=TRANSACTION_ID;DELIVERY_NAME=TRANSACTION_NAME;BEGIN_DATE=truncate(SCHEDULE_DATE);END_DATE=truncate(SCHEDULE_DATE)', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SEGMENT_ORDER', 'Column', 'Segment', '', 0, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'POR_NAME', 'Column', 'POR', '', 1, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'POD_NAME', 'Column', 'POD', '', 2, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'CONTRACT_NAME', 'Column', 'Contract', '', 3, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'RECEIVED_AMOUNT', 'Column', 'Received', '', 4, 0, '-3~0^-2~0^2~0^7~0^13~0^14~6^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'FUEL_AMOUNT', 'Column', 'Fuel', '', 5, 0, '-3~0^-2~0^2~0^7~0^13~0^14~2^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'DELIVERED_AMOUNT', 'Column', 'Delivered', '', 6, 0, '-3~0^-2~0^2~0^7~0^13~0^14~7^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'FUEL_PCT', 'Column', 'Fuel %', '', 7, 1, '-3~0^-2~0^2~0^7~0^11~7^13~0^20~0^22~5^24~0^25~FUEL_AMOUNT*100/RECEIVED_AMOUNT^31~0', v_CHILD_OBJECT_ID);
            END;
             
            <<L10>>
            DECLARE
               v_PARENT_OBJECT_ID NUMBER(9) := L8.v_OBJECT_ID;
               v_OBJECT_ID NUMBER(9);
            BEGIN
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'SEGMENT_DETAILS_Grid_MASTER', 'Grid', 'Deliveries', '', 0, 0, '-3~0^-2~0^305~0^307~Anchored^308~0', v_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'LimitValidation', 'Action', 'Contract Limit Validation...', '', 0, 0, '-3~0^-2~0^1006~2^1007~GasDelivery.DeliveryLimitsValidation;DELIVERY_ID=TRANSACTION_ID;DELIVERY_NAME=TRANSACTION_NAME', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SCHEDULE_DATE', 'Column', '', '', 0, 1, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~6^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SCHEDULE_DATE_DISP', 'Column', 'Schedule Date', '', 1, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~1^24~1^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TOTAL_FUEL', 'Column', '', '', 2, 1, '-3~0^-2~0^2~0^7~0^11~7^13~0^14~2^20~0^22~6^24~0^25~sum ( FUEL_AMOUNT )^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRANSACTION_NAME', 'Column', '', '', 3, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~2^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRANSACTION_ID', 'Column', '', '', 4, 1, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~5^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'RECEIVED_AMOUNT', 'Column', '', '', 5, 0, '-3~0^-2~0^2~0^7~0^11~7^13~0^14~2^20~0^22~5^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'FUEL_AMOUNT', 'Column', '', '', 6, 0, '-3~0^-2~0^2~0^7~0^11~7^13~0^14~2^20~0^22~5^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'DELIVERED_AMOUNT', 'Column', '', '', 7, 0, '-3~0^-2~0^2~0^7~0^11~7^13~0^14~2^20~0^22~5^24~0^31~0', v_CHILD_OBJECT_ID);
            END;
             
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'PIPELINE_ID', 'Report Filter', 'Pipeline', '', 0, 0, '501~s (Special List)^504~GDJ.GET_DELIVERY_PIPELINES;BEGIN_DATE;END_DATE^518~POR_ID,POD_ID,DELIVERY_ID', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'POR_ID', 'Report Filter', 'POR', '', 1, 0, '501~s (Special List)^504~GDJ.GET_DELIVERY_RECEIPT_POINTS;PIPELINE_ID;BEGIN_DATE;END_DATE^518~DELIVERY_ID', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'POD_ID', 'Report Filter', 'POD', '', 2, 0, '501~s (Special List)^504~GDJ.GET_DELIVERY_POINTS;PIPELINE_ID;BEGIN_DATE;END_DATE^518~DELIVERY_ID', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'DELIVERY_ID', 'Report Filter', 'Deliveries', '', 3, 0, '501~s (Special List)^504~GDJ.GET_DELIVERIES;PIPELINE_ID;POR_ID;POD_ID;BEGIN_DATE;END_DATE^508~1', v_CHILD_OBJECT_ID);
         END;
          
         <<L11>>
         DECLARE
            v_PARENT_OBJECT_ID NUMBER(9) := L1.v_OBJECT_ID;
            v_OBJECT_ID NUMBER(9);
         BEGIN
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'RECV_VOL_CALC', 'Report', 'Received Volume Calculator', '', 3, 0, '-3~0^-2~0^401~GDJ.RECEIVED_VOLUME_CALCULATOR^402~0^406~0', v_OBJECT_ID);
            <<L12>>
            DECLARE
               v_PARENT_OBJECT_ID NUMBER(9) := L11.v_OBJECT_ID;
               v_OBJECT_ID NUMBER(9);
            BEGIN
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'RECV_VOL_CALC_Grid', 'Grid', 'Recv Vol Calc Grid', '', 0, 0, '-3~0^-2~0^305~0^308~0', v_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRANSACTION_NAME', 'Column', 'Delivery', '', 0, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^24~1^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'FUEL_PCT', 'Column', '', '', 1, 1, '-3~0^-2~0^2~0^7~0^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'DELIVERED_VOLUME', 'Column', '<html><b>Delivered Volume</b></html>', '', 2, 0, '1~n (Numeric Edit)^11~7', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'FUEL_VOLUME', 'Column', '', '', 3, 0, '11~7^25~DELIVERED_VOLUME*FUEL_PCT/100', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'RECEIVED_VOLUME', 'Column', '', '', 4, 0, '11~7^25~DELIVERED_VOLUME+FUEL_VOLUME', v_CHILD_OBJECT_ID);
            END;
             
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'PIPELINE_ID', 'Report Filter', 'Pipeline', '', 0, 0, '501~s (Special List)^504~GDJ.GET_DELIVERY_PIPELINES;BEGIN_DATE;END_DATE^514~0^518~POR_ID,POD_ID', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'POR_ID', 'Report Filter', 'POR', '', 1, 0, '501~s (Special List)^504~GDJ.GET_DELIVERY_RECEIPT_POINTS;PIPELINE_ID;BEGIN_DATE;END_DATE', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'POD_ID', 'Report Filter', 'POD', '', 2, 0, '501~s (Special List)^504~GDJ.GET_DELIVERY_POINTS;PIPELINE_ID;BEGIN_DATE;END_DATE', v_CHILD_OBJECT_ID);
         END;
          
      END;
       
      -------------------------------------
      --   GasDelivery.ContractLimits
      -------------------------------------
      <<L13>>
      DECLARE
         v_PARENT_OBJECT_ID NUMBER(9) := L0.v_OBJECT_ID;
         v_OBJECT_ID NUMBER(9);
      BEGIN
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'GasDelivery.ContractLimits', 'System View', '', '', 0, 0, '-3~0^-2~0^801~com.newenergyassoc.ro.mightyReport.MightyReportPanel', v_OBJECT_ID);
         <<L14>>
         DECLARE
            v_PARENT_OBJECT_ID NUMBER(9) := L13.v_OBJECT_ID;
            v_OBJECT_ID NUMBER(9);
         BEGIN
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'POINT_CONTRACT_LIMITS', 'Report', 'Point Limit Validation', '', 1, 0, '-3~0^-2~0^401~GDJ.LIMITS_VALIDATION_SUMMARY;FOR_SEGMENTS=0;DELIVERY_ID=-1;INVALID_ONLY=if(SHOW_ID=1,1,0);AVAILABLE_ONLY=if(SHOW_ID=2,1,0)^402~0^403~Lazy Master/Detail Grids^404~GDJ.LIMITS_VALIDATION_DETAILS;FOR_SEGMENTS=0^406~0^409~Vertical', v_OBJECT_ID);
            <<L15>>
            DECLARE
               v_PARENT_OBJECT_ID NUMBER(9) := L14.v_OBJECT_ID;
               v_OBJECT_ID NUMBER(9);
            BEGIN
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'POINT_CONTRACT_LIMITS_Grid_MASTER', 'Grid', 'Summary', '', 0, 0, '-3~0^-2~0^305~0^308~0', v_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'PIPELINE_NAME', 'Column', 'Pipeline', '', 0, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^24~1^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'PIPELINE_ID', 'Column', '', '', 1, 1, '-3~0^-2~0^2~0^7~0^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'POR_NAME', 'Column', 'Service Point', '', 2, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^24~1^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'POR_ID', 'Column', '', '', 3, 1, '-3~0^-2~0^2~0^7~0^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'CONTRACT_NAME', 'Column', 'Contract', '', 4, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^24~1^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'CONTRACT_ID', 'Column', '', '', 5, 1, '-3~0^-2~0^2~0^7~0^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'CAPACITY_PURCHASED', 'Column', '', '', 6, 0, '-3~0^-2~0^2~0^7~0^11~7^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'CAPACITY_SOLD', 'Column', '', '', 7, 0, '-3~0^-2~0^2~0^7~0^11~7^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TOTAL_RECEIVED', 'Column', '', '', 8, 0, '-3~0^-2~0^2~0^7~0^11~7^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TOTAL_DELIVERED', 'Column', '', '', 9, 0, '-3~0^-2~0^2~0^7~0^11~7^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TOTAL_EXCESS', 'Column', '', '', 10, 0, '-3~0^-2~0^2~0^7~0^11~7^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TOTAL_AVAIL', 'Column', '', '', 11, 0, '-3~0^-2~0^2~0^7~0^11~7^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'MISSING_LIMITS', 'Column', '', '', 12, 1, '-3~0^-2~0^2~0^7~0^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
            END;
             
            <<L16>>
            DECLARE
               v_PARENT_OBJECT_ID NUMBER(9) := L14.v_OBJECT_ID;
               v_OBJECT_ID NUMBER(9);
            BEGIN
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'POINT_CONTRACT_LIMITS_Grid_DETAIL', 'Grid', 'Details', '', 1, 0, '-3~0^-2~0^305~0^308~0', v_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'Details', 'Action', 'Show Details...', '', 0, 0, '-3~0^-2~0^1006~2^1007~GasDelivery.PointLimitValidationDetails', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SCHEDULE_DATE', 'Column', '', '', 0, 1, '-3~0^-2~0^2~0^7~0^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SCHEDULE_DATE_DISP', 'Column', 'Schedule Date', '', 1, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^24~1^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'MAX_DAILY_QUANTITY', 'Column', '', '', 2, 0, '-3~0^-2~0^2~0^7~0^11~7^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'CAPACITY_PURCHASED', 'Column', '', '', 3, 0, '-3~0^-2~0^2~0^7~0^11~7^13~0^14~2^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'CAPACITY_SOLD', 'Column', '', '', 4, 0, '-3~0^-2~0^2~0^7~0^11~7^13~0^14~2^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TOTAL_RECEIVED', 'Column', '', '', 5, 0, '-3~0^-2~0^2~0^7~0^11~7^13~0^14~2^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TOTAL_DELIVERED', 'Column', '', '', 6, 0, '-3~0^-2~0^2~0^7~0^11~7^13~0^14~2^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TOTAL_EXCESS', 'Column', '', '', 7, 0, '-3~0^-2~0^2~0^7~0^11~7^13~0^14~2^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TOTAL_AVAIL', 'Column', '', '', 8, 0, '-3~0^-2~0^2~0^7~0^11~7^13~0^14~2^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'MISSING_LIMITS', 'Column', '', '', 9, 1, '-3~0^-2~0^2~0^7~0^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
            END;
             
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'PIPELINE_ID', 'Report Filter', 'Pipeline', '', 0, 0, '501~o (Object List)^503~PIPELINE|#-1;<ALL>^518~CONTRACT_ID', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'CONTRACT_ID', 'Report Filter', 'Contract', '', 1, 0, '501~s (Special List)^504~GDJ.GET_PIPELINE_CONTRACTS;PIPELINE_ID;BEGIN_DATE;END_DATE', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SHOW_ID', 'Report Filter', 'Display Options', '', 2, 0, '-3~0^-2~0^501~r (Radio Button)^502~#0;Show All|#1;Show Invalid Only|#2;Show Available Only^508~0^514~0^515~0^519~0^520~0', v_CHILD_OBJECT_ID);
         END;
          
         <<L17>>
         DECLARE
            v_PARENT_OBJECT_ID NUMBER(9) := L13.v_OBJECT_ID;
            v_OBJECT_ID NUMBER(9);
         BEGIN
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'SEGMENT_CONTRACT_LIMITS', 'Report', 'Segment Limit Validation', '', 2, 0, '-3~0^-2~0^401~GDJ.LIMITS_VALIDATION_SUMMARY;FOR_SEGMENTS=1;DELIVERY_ID=-1;INVALID_ONLY=if(SHOW_ID=1,1,0);AVAILABLE_ONLY=if(SHOW_ID=2,1,0)^402~0^403~Lazy Master/Detail Grids^404~GDJ.LIMITS_VALIDATION_DETAILS;FOR_SEGMENTS=1^406~0^409~Vertical', v_OBJECT_ID);
            <<L18>>
            DECLARE
               v_PARENT_OBJECT_ID NUMBER(9) := L17.v_OBJECT_ID;
               v_OBJECT_ID NUMBER(9);
            BEGIN
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'SEGMENT_CONTRACT_LIMITS_Grid_MASTER', 'Grid', 'Summary', '', 0, 0, '-3~0^-2~0^305~0^308~0', v_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'PIPELINE_NAME', 'Column', 'Pipeline', '', 0, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^24~1^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'PIPELINE_ID', 'Column', '', '', 1, 1, '-3~0^-2~0^2~0^7~0^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'POR_NAME', 'Column', 'POR', '', 2, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^24~1^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'POR_ID', 'Column', '', '', 3, 1, '-3~0^-2~0^2~0^7~0^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'POD_NAME', 'Column', 'POD', '', 4, 0, '24~1', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'POD_ID', 'Column', '', '', 5, 1, '', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'CONTRACT_NAME', 'Column', '', '', 6, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^24~1^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'CONTRACT_ID', 'Column', '', '', 7, 1, '-3~0^-2~0^2~0^7~0^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'CAPACITY_PURCHASED', 'Column', '', '', 8, 0, '-3~0^-2~0^2~0^7~0^11~7^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'CAPACITY_SOLD', 'Column', '', '', 9, 0, '-3~0^-2~0^2~0^7~0^11~7^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TOTAL_RECEIVED', 'Column', '', '', 10, 0, '-3~0^-2~0^2~0^7~0^11~7^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TOTAL_DELIVERED', 'Column', '', '', 11, 0, '-3~0^-2~0^2~0^7~0^11~7^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TOTAL_EXCESS', 'Column', '', '', 12, 0, '-3~0^-2~0^2~0^7~0^11~7^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TOTAL_AVAIL', 'Column', '', '', 13, 0, '-3~0^-2~0^2~0^7~0^11~7^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'MISSING_LIMITS', 'Column', '', '', 14, 1, '-3~0^-2~0^2~0^7~0^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
            END;
             
            <<L19>>
            DECLARE
               v_PARENT_OBJECT_ID NUMBER(9) := L17.v_OBJECT_ID;
               v_OBJECT_ID NUMBER(9);
            BEGIN
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'SEGMENT_CONTRACT_LIMITS_Grid_DETAIL', 'Grid', 'Details', '', 1, 0, '-3~0^-2~0^305~0^308~0', v_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'Details', 'Action', 'Show Details...', '', 0, 0, '-3~0^-2~0^1006~2^1007~GasDelivery.SegmentLimitValidationDetails', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SCHEDULE_DATE', 'Column', '', '', 0, 1, '-3~0^-2~0^2~0^7~0^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SCHEDULE_DATE_DISP', 'Column', 'Schedule Date', '', 1, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^24~1^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'MAX_DAILY_QUANTITY', 'Column', '', '', 2, 0, '-3~0^-2~0^2~0^7~0^11~7^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'CAPACITY_PURCHASED', 'Column', '', '', 3, 0, '-3~0^-2~0^2~0^7~0^11~7^13~0^14~2^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'CAPACITY_SOLD', 'Column', '', '', 4, 0, '-3~0^-2~0^2~0^7~0^11~7^13~0^14~2^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TOTAL_RECEIVED', 'Column', '', '', 5, 0, '-3~0^-2~0^2~0^7~0^11~7^13~0^14~2^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TOTAL_DELIVERED', 'Column', '', '', 6, 0, '-3~0^-2~0^2~0^7~0^11~7^13~0^14~2^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TOTAL_EXCESS', 'Column', '', '', 7, 0, '-3~0^-2~0^2~0^7~0^11~7^13~0^14~2^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TOTAL_AVAIL', 'Column', '', '', 8, 0, '-3~0^-2~0^2~0^7~0^11~7^13~0^14~2^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'MISSING_LIMITS', 'Column', '', '', 9, 1, '-3~0^-2~0^2~0^7~0^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
            END;
             
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'PIPELINE_ID', 'Report Filter', 'Pipeline', '', 0, 0, '501~o (Object List)^503~PIPELINE|#-1;<ALL>^518~CONTRACT_ID', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'CONTRACT_ID', 'Report Filter', 'Contract', '', 1, 0, '501~s (Special List)^504~GDJ.GET_PIPELINE_CONTRACTS;PIPELINE_ID;BEGIN_DATE;END_DATE', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SHOW_ID', 'Report Filter', 'Display Options', '', 2, 0, '-3~0^-2~0^501~r (Radio Button)^502~#0;Show All|#1;Show Invalid Only|#2;Show Available Only^508~0^514~0^515~0^519~0^520~0', v_CHILD_OBJECT_ID);
         END;
          
      END;
       
      -------------------------------------
      --   GasDelivery.DeliveryLimitsValidation
      -------------------------------------
      <<L20>>
      DECLARE
         v_PARENT_OBJECT_ID NUMBER(9) := L0.v_OBJECT_ID;
         v_OBJECT_ID NUMBER(9);
      BEGIN
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'GasDelivery.DeliveryLimitsValidation', 'System View', 'Contract Limit Validation', '', 0, 0, '-3~0^-2~0^801~com.newenergyassoc.ro.mightyReport.MightyReportPanel', v_OBJECT_ID);
         <<L21>>
         DECLARE
            v_PARENT_OBJECT_ID NUMBER(9) := L20.v_OBJECT_ID;
            v_OBJECT_ID NUMBER(9);
         BEGIN
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'POINT_LIMITS', 'Report', 'Point Limit Validation', '', 0, 0, '-3~0^-2~0^401~GDJ.LIMITS_VALIDATION_SUMMARY;FOR_SEGMENTS=0;PIPELINE_ID=-1;CONTRACT_ID=-1;INVALID_ONLY=0;AVAILABLE_ONLY=0^402~0^403~Lazy Master/Detail Grids^404~GDJ.LIMITS_VALIDATION_DETAILS;FOR_SEGMENTS=0^406~1^409~Vertical', v_OBJECT_ID);
            <<L22>>
            DECLARE
               v_PARENT_OBJECT_ID NUMBER(9) := L21.v_OBJECT_ID;
               v_OBJECT_ID NUMBER(9);
            BEGIN
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'POINT_LIMITS_Grid_MASTER', 'Grid', 'Summary', '', 0, 0, '-3~0^-2~0^305~0^308~0', v_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'PIPELINE_ID', 'Column', '', '', 0, 1, '-3~0^-2~0^2~0^7~0^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'PIPELINE_NAME', 'Column', '', '', 1, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^24~1^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'POR_ID', 'Column', '', '', 2, 1, '-3~0^-2~0^2~0^7~0^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'POR_NAME', 'Column', 'Service Point', '', 3, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^24~1^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'CONTRACT_ID', 'Column', '', '', 6, 1, '-3~0^-2~0^2~0^7~0^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'CONTRACT_NAME', 'Column', '', '', 7, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^24~1^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'CAPACITY_PURCHASED', 'Column', '', '', 8, 0, '-3~0^-2~0^2~0^7~0^11~7^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'CAPACITY_SOLD', 'Column', '', '', 9, 0, '-3~0^-2~0^2~0^7~0^11~7^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TOTAL_RECEIVED', 'Column', '', '', 10, 0, '-3~0^-2~0^2~0^7~0^11~7^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TOTAL_DELIVERED', 'Column', '', '', 11, 0, '-3~0^-2~0^2~0^7~0^11~7^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TOTAL_EXCESS', 'Column', '', '', 12, 0, '-3~0^-2~0^2~0^7~0^11~7^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TOTAL_AVAIL', 'Column', '', '', 13, 0, '-3~0^-2~0^2~0^7~0^11~7^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'MISSING_LIMITS', 'Column', '', '', 14, 1, '-3~0^-2~0^2~0^7~0^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'DELIVERY_NAME', 'Label', 'Validating Points for Delivery', '', 0, 0, '1101~2', v_CHILD_OBJECT_ID);
            END;
             
            <<L23>>
            DECLARE
               v_PARENT_OBJECT_ID NUMBER(9) := L21.v_OBJECT_ID;
               v_OBJECT_ID NUMBER(9);
            BEGIN
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'POINT_LIMITS_Grid_DETAIL', 'Grid', 'Details', '', 1, 0, '-3~0^-2~0^305~0^308~0', v_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'Details', 'Action', 'Show Details...', '', 0, 0, '-3~0^-2~0^1006~2^1007~GasDelivery.PointLimitValidationDetails', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SCHEDULE_DATE', 'Column', '', '', 0, 1, '-3~0^-2~0^2~0^7~0^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SCHEDULE_DATE_DISP', 'Column', 'Schedule Date', '', 1, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^24~1^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'MAX_DAILY_QUANTITY', 'Column', '', '', 2, 0, '-3~0^-2~0^2~0^7~0^11~7^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'CAPACITY_PURCHASED', 'Column', '', '', 3, 0, '-3~0^-2~0^2~0^7~0^11~7^13~0^14~2^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'CAPACITY_SOLD', 'Column', '', '', 4, 0, '-3~0^-2~0^2~0^7~0^11~7^13~0^14~2^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TOTAL_RECEIVED', 'Column', '', '', 5, 0, '-3~0^-2~0^2~0^7~0^11~7^13~0^14~2^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TOTAL_DELIVERED', 'Column', '', '', 6, 0, '-3~0^-2~0^2~0^7~0^11~7^13~0^14~2^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TOTAL_EXCESS', 'Column', '', '', 7, 0, '-3~0^-2~0^2~0^7~0^11~7^13~0^14~2^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TOTAL_AVAIL', 'Column', '', '', 8, 0, '-3~0^-2~0^2~0^7~0^11~7^13~0^14~2^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'MISSING_LIMITS', 'Column', '', '', 9, 1, '-3~0^-2~0^2~0^7~0^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
            END;
             
         END;
          
         <<L24>>
         DECLARE
            v_PARENT_OBJECT_ID NUMBER(9) := L20.v_OBJECT_ID;
            v_OBJECT_ID NUMBER(9);
         BEGIN
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'SEGMENT_LIMITS', 'Report', 'Segment Limit Validation', '', 1, 0, '-3~0^-2~0^401~GDJ.LIMITS_VALIDATION_SUMMARY;FOR_SEGMENTS=1;PIPELINE_ID=-1;CONTRACT_ID=-1;INVALID_ONLY=0;AVAILABLE_ONLY=0^402~0^403~Lazy Master/Detail Grids^404~GDJ.LIMITS_VALIDATION_DETAILS;FOR_SEGMENTS=1^406~1^409~Vertical', v_OBJECT_ID);
            <<L25>>
            DECLARE
               v_PARENT_OBJECT_ID NUMBER(9) := L24.v_OBJECT_ID;
               v_OBJECT_ID NUMBER(9);
            BEGIN
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'SEGMENT_LIMITS_Grid_MASTER', 'Grid', 'Summary', '', 0, 0, '-3~0^-2~0^305~0^308~0', v_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'PIPELINE_ID', 'Column', '', '', 0, 1, '-3~0^-2~0^2~0^7~0^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'PIPELINE_NAME', 'Column', '', '', 1, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^24~1^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'POR_ID', 'Column', '', '', 2, 1, '-3~0^-2~0^2~0^7~0^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'POR_NAME', 'Column', 'POR', '', 3, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^24~1^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'POD_ID', 'Column', '', '', 4, 1, '', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'POD_NAME', 'Column', 'POD', '', 5, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^24~1^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'CONTRACT_ID', 'Column', '', '', 6, 1, '-3~0^-2~0^2~0^7~0^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'CONTRACT_NAME', 'Column', '', '', 7, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^24~1^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'CAPACITY_PURCHASED', 'Column', '', '', 8, 0, '-3~0^-2~0^2~0^7~0^11~7^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'CAPACITY_SOLD', 'Column', '', '', 9, 0, '-3~0^-2~0^2~0^7~0^11~7^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TOTAL_RECEIVED', 'Column', '', '', 10, 0, '-3~0^-2~0^2~0^7~0^11~7^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TOTAL_DELIVERED', 'Column', '', '', 11, 0, '-3~0^-2~0^2~0^7~0^11~7^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TOTAL_EXCESS', 'Column', '', '', 12, 0, '-3~0^-2~0^2~0^7~0^11~7^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TOTAL_AVAIL', 'Column', '', '', 13, 0, '-3~0^-2~0^2~0^7~0^11~7^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'MISSING_LIMITS', 'Column', '', '', 14, 1, '-3~0^-2~0^2~0^7~0^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'DELIVERY_NAME', 'Label', 'Validating Segments for Delivery', '', 0, 0, '-3~0^-2~0^1101~2', v_CHILD_OBJECT_ID);
            END;
             
            <<L26>>
            DECLARE
               v_PARENT_OBJECT_ID NUMBER(9) := L24.v_OBJECT_ID;
               v_OBJECT_ID NUMBER(9);
            BEGIN
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'SEGMENT_LIMITS_Grid_DETAIL', 'Grid', 'Details', '', 1, 0, '-3~0^-2~0^305~0^308~0', v_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'Details', 'Action', 'Show Details...', '', 0, 0, '-3~0^-2~0^1006~2^1007~GasDelivery.SegmentLimitValidationDetails', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SCHEDULE_DATE', 'Column', '', '', 0, 1, '-3~0^-2~0^2~0^7~0^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SCHEDULE_DATE_DISP', 'Column', 'Schedule Date', '', 1, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^24~1^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'MAX_DAILY_QUANTITY', 'Column', '', '', 2, 0, '-3~0^-2~0^2~0^7~0^11~7^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'CAPACITY_PURCHASED', 'Column', '', '', 3, 0, '-3~0^-2~0^2~0^7~0^11~7^13~0^14~2^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'CAPACITY_SOLD', 'Column', '', '', 4, 0, '-3~0^-2~0^2~0^7~0^11~7^13~0^14~2^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TOTAL_RECEIVED', 'Column', '', '', 5, 0, '-3~0^-2~0^2~0^7~0^11~7^13~0^14~2^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TOTAL_DELIVERED', 'Column', '', '', 6, 0, '-3~0^-2~0^2~0^7~0^11~7^13~0^14~2^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TOTAL_EXCESS', 'Column', '', '', 7, 0, '-3~0^-2~0^2~0^7~0^11~7^13~0^14~2^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TOTAL_AVAIL', 'Column', '', '', 8, 0, '-3~0^-2~0^2~0^7~0^11~7^13~0^14~2^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'MISSING_LIMITS', 'Column', '', '', 9, 1, '-3~0^-2~0^2~0^7~0^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
            END;
             
         END;
          
      END;
       
      -------------------------------------
      --   GasDelivery.PointLimitValidationDetails
      -------------------------------------
      <<L27>>
      DECLARE
         v_PARENT_OBJECT_ID NUMBER(9) := L0.v_OBJECT_ID;
         v_OBJECT_ID NUMBER(9);
      BEGIN
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'GasDelivery.PointLimitValidationDetails', 'System View', 'Contract Limits - Details', '', 0, 0, '-3~0^-2~0^801~com.newenergyassoc.ro.mightyReport.MightyReportPanel', v_OBJECT_ID);
         <<L28>>
         DECLARE
            v_PARENT_OBJECT_ID NUMBER(9) := L27.v_OBJECT_ID;
            v_OBJECT_ID NUMBER(9);
         BEGIN
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'LimitValidationDetails', 'Report', 'LimitValidationDetails', '', 0, 0, '-3~0^-2~0^401~GDJ.LIMITS_VALIDATION_TXNS;FOR_SEGMENTS=0;SHOW_CAPACITY=1;SHOW_DELIVERIES=0^402~1^403~Comparison Grids^404~GDJ.LIMITS_VALIDATION_TXNS;FOR_SEGMENTS=0;SHOW_CAPACITY=0;SHOW_DELIVERIES=1^406~0', v_OBJECT_ID);
            <<L29>>
            DECLARE
               v_PARENT_OBJECT_ID NUMBER(9) := L28.v_OBJECT_ID;
               v_OBJECT_ID NUMBER(9);
            BEGIN
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'LimitValidationDetails_Grid', 'Grid', 'Capacity Transactions', '', 0, 0, '-3~0^-2~0^305~0^308~0', v_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRANSACTION_NAME', 'Column', '', '', 0, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^24~1^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'CAPACITY_PURCHASED', 'Column', '', '', 1, 0, '-3~0^-2~0^2~0^7~0^11~7^13~0^14~2^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'CAPACITY_SOLD', 'Column', '', '', 2, 0, '-3~0^-2~0^2~0^7~0^11~7^13~0^14~2^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TOTAL_RECEIVED', 'Column', '', '', 3, 1, '-3~0^-2~0^2~0^7~0^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TOTAL_DELIVERED', 'Column', '', '', 4, 1, '-3~0^-2~0^2~0^7~0^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'POR_NAME', 'Label', 'Service Point', '', 0, 0, '-3~0^-2~0^1101~2', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'CONTRACT_NAME', 'Label', 'Contract', '', 1, 0, '-3~0^-2~0^1101~0', v_CHILD_OBJECT_ID);
            END;
             
            <<L30>>
            DECLARE
               v_PARENT_OBJECT_ID NUMBER(9) := L28.v_OBJECT_ID;
               v_OBJECT_ID NUMBER(9);
            BEGIN
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'LimitValidationDetails_Grid_COMPARE', 'Grid', 'Deliveries', '', 0, 0, '-3~0^-2~0^305~0^308~0', v_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRANSACTION_NAME', 'Column', '', '', 0, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^24~1^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'CAPACITY_PURCHASED', 'Column', '', '', 1, 1, '-3~0^-2~0^2~0^7~0^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'CAPACITY_SOLD', 'Column', '', '', 2, 1, '-3~0^-2~0^2~0^7~0^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TOTAL_RECEIVED', 'Column', '', '', 3, 0, '-3~0^-2~0^2~0^7~0^11~7^13~0^14~2^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TOTAL_DELIVERED', 'Column', '', '', 4, 0, '-3~0^-2~0^2~0^7~0^11~7^13~0^14~2^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SCHEDULE_DATE_DISP', 'Label', 'Schedule Date', '', 0, 0, '1101~0', v_CHILD_OBJECT_ID);
            END;
             
         END;
          
      END;
       
      -------------------------------------
      --   GasDelivery.SegmentLimitValidationDetails
      -------------------------------------
      <<L31>>
      DECLARE
         v_PARENT_OBJECT_ID NUMBER(9) := L0.v_OBJECT_ID;
         v_OBJECT_ID NUMBER(9);
      BEGIN
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'GasDelivery.SegmentLimitValidationDetails', 'System View', 'Contract Limits - Details', '', 0, 0, '-3~0^-2~0^801~com.newenergyassoc.ro.mightyReport.MightyReportPanel', v_OBJECT_ID);
         <<L32>>
         DECLARE
            v_PARENT_OBJECT_ID NUMBER(9) := L31.v_OBJECT_ID;
            v_OBJECT_ID NUMBER(9);
         BEGIN
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'LimitValidationDetails', 'Report', 'LimitValidationDetails', '', 0, 0, '-3~0^-2~0^401~GDJ.LIMITS_VALIDATION_TXNS;FOR_SEGMENTS=1;SHOW_CAPACITY=1;SHOW_DELIVERIES=0^402~1^403~Comparison Grids^404~GDJ.LIMITS_VALIDATION_TXNS;FOR_SEGMENTS=1;SHOW_CAPACITY=0;SHOW_DELIVERIES=1^406~0', v_OBJECT_ID);
            <<L33>>
            DECLARE
               v_PARENT_OBJECT_ID NUMBER(9) := L32.v_OBJECT_ID;
               v_OBJECT_ID NUMBER(9);
            BEGIN
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'LimitValidationDetails_Grid', 'Grid', 'Capacity Transactions', '', 0, 0, '-3~0^-2~0^305~0^308~0', v_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRANSACTION_NAME', 'Column', '', '', 0, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^24~1^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'CAPACITY_PURCHASED', 'Column', '', '', 1, 0, '-3~0^-2~0^2~0^7~0^11~7^13~0^14~2^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'CAPACITY_SOLD', 'Column', '', '', 2, 0, '-3~0^-2~0^2~0^7~0^11~7^13~0^14~2^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TOTAL_RECEIVED', 'Column', '', '', 3, 1, '-3~0^-2~0^2~0^7~0^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TOTAL_DELIVERED', 'Column', '', '', 4, 1, '-3~0^-2~0^2~0^7~0^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'POR_NAME', 'Label', 'POR', '', 0, 0, '-3~0^-2~0^1101~2', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'POD_NAME', 'Label', 'POD', '', 1, 0, '-3~0^-2~0^1101~0', v_CHILD_OBJECT_ID);
            END;
             
            <<L34>>
            DECLARE
               v_PARENT_OBJECT_ID NUMBER(9) := L32.v_OBJECT_ID;
               v_OBJECT_ID NUMBER(9);
            BEGIN
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'LimitValidationDetails_Grid_COMPARE', 'Grid', 'Deliveries', '', 1, 0, '-3~0^-2~0^305~0^308~0', v_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRANSACTION_NAME', 'Column', '', '', 0, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^24~1^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'CAPACITY_PURCHASED', 'Column', '', '', 1, 1, '-3~0^-2~0^2~0^7~0^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'CAPACITY_SOLD', 'Column', '', '', 2, 1, '-3~0^-2~0^2~0^7~0^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TOTAL_RECEIVED', 'Column', '', '', 3, 0, '-3~0^-2~0^2~0^7~0^11~7^13~0^14~2^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TOTAL_DELIVERED', 'Column', '', '', 4, 0, '-3~0^-2~0^2~0^7~0^11~7^13~0^14~2^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'CONTRACT_NAME', 'Label', 'Contract', '', 0, 0, '1101~2', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SCHEDULE_DATE_DISP', 'Label', 'Schedule Date', '', 1, 0, '-3~0^-2~0^1101~0', v_CHILD_OBJECT_ID);
            END;
             
         END;
          
      END;
       
      -------------------------------------
      --   GasDelivery.Storage
      -------------------------------------
      <<L35>>
      DECLARE
         v_PARENT_OBJECT_ID NUMBER(9) := L0.v_OBJECT_ID;
         v_OBJECT_ID NUMBER(9);
      BEGIN
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'GasDelivery.Storage', 'System View', 'Gasdelivery.Storage', '', 0, 0, '-3~0^-2~0^801~com.newenergyassoc.ro.mightyReport.MightyReportPanel', v_OBJECT_ID);
         <<L36>>
         DECLARE
            v_PARENT_OBJECT_ID NUMBER(9) := L35.v_OBJECT_ID;
            v_OBJECT_ID NUMBER(9);
         BEGIN
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'STORAGE_POSITION', 'Report', 'Storage Position', '', 0, 0, '-3~0^-2~0^401~GDJ.GET_STORAGE_SUMMARY^402~0^403~Lazy Master/Detail Grids^404~GDJ.GET_STORAGE_DETAILS^406~0^409~Vertical', v_OBJECT_ID);
            <<L37>>
            DECLARE
               v_PARENT_OBJECT_ID NUMBER(9) := L36.v_OBJECT_ID;
               v_OBJECT_ID NUMBER(9);
            BEGIN
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'STORAGE_POSITION_Grid_MASTER', 'Grid', 'Contract Summary', '', 0, 0, '-3~0^-2~0^305~0^308~0', v_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'CONTRACT_NAME', 'Column', 'Storage Contract', '', 0, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'CONTRACT_ID', 'Column', '', '', 1, 1, '-3~0^-2~0^2~0^7~0^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'STARTING_BALANCE', 'Column', '', '', 2, 0, '-3~0^-2~0^2~0^7~0^11~7^13~0^14~2^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TOTAL_INJECTIONS', 'Column', 'Total Gross Injections', '', 3, 0, '-3~0^-2~0^2~0^7~0^11~7^13~0^14~2^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TOTAL_INJECTION_FUEL', 'Column', '', '', 4, 0, '-3~0^-2~0^2~0^7~0^11~7^13~0^14~2^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TOTAL_WITHDRAWALS', 'Column', 'Total Net Withdrawals', '', 5, 0, '-3~0^-2~0^2~0^7~0^11~7^13~0^14~2^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TOTAL_WITHDRAWAL_FUEL', 'Column', '', '', 6, 0, '-3~0^-2~0^2~0^7~0^11~7^13~0^14~2^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'ENDING_BALANCE', 'Column', '', '', 7, 0, '-3~0^-2~0^2~0^7~0^11~7^13~0^14~2^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'EXCEED_MAX_CAPACITY', 'Column', '', '', 8, 1, '-3~0^-2~0^2~0^7~0^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'EXCEED_MAX_INJECTION', 'Column', '', '', 9, 1, '-3~0^-2~0^2~0^7~0^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'EXCEED_MAX_WITHDRAWAL', 'Column', '', '', 10, 1, '-3~0^-2~0^2~0^7~0^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
            END;
             
            <<L38>>
            DECLARE
               v_PARENT_OBJECT_ID NUMBER(9) := L36.v_OBJECT_ID;
               v_OBJECT_ID NUMBER(9);
            BEGIN
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'STORAGE_POSITION_Grid_DETAIL', 'Grid', 'Storage Schedule', '', 1, 0, '-3~0^-2~0^305~0^308~0', v_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'DETAILS', 'Action', 'Storage Activity...', '', 0, 0, '1006~0^1007~GDJ.GET_STORAGE_TXNS', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SCHEDULE_DATE', 'Column', '', '', 0, 1, '-3~0^-2~0^2~0^7~0^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SCHEDULE_DATE_DISP', 'Column', 'Schedule Date', '', 1, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^24~1^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'CONTRACT_ID', 'Column', '', '', 2, 1, '-3~0^-2~0^2~0^7~0^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'MAX_CAPACITY', 'Column', '', '', 3, 0, '-3~0^-2~0^2~0^7~0^11~7^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'STARTING_BALANCE', 'Column', '', '', 4, 0, '-3~0^-2~0^2~0^7~0^11~7^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'PCT_FULL', 'Column', 'Percent Full', '', 5, 0, '-3~0^-2~0^2~0^7~0^11~7^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'MAX_INJECTIONS', 'Column', '', '', 6, 0, '-3~0^-2~0^2~0^7~0^11~7^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TOTAL_GROSS_INJECTIONS', 'Column', 'Gross Injections', '', 7, 0, '-3~0^-2~0^2~0^7~0^11~7^13~0^14~2^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TOTAL_INJECTION_FUEL', 'Column', 'Injection Fuel', '', 8, 0, '-3~0^-2~0^2~0^7~0^11~7^13~0^14~2^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TOTAL_NET_INJECTIONS', 'Column', 'Net Injections', '', 9, 0, '-3~0^-2~0^2~0^7~0^11~7^13~0^14~2^20~0^24~0^25~TOTAL_GROSS_INJECTIONS-TOTAL_INJECTION_FUEL^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'MAX_WITHDRAWALS', 'Column', '', '', 10, 0, '-3~0^-2~0^2~0^7~0^11~7^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TOTAL_GROSS_WITHDRAWALS', 'Column', 'Gross Withdrawals', '', 11, 0, '-3~0^-2~0^2~0^7~0^11~7^13~0^14~2^20~0^24~0^25~TOTAL_NET_WITHDRAWALS+TOTAL_WITHDRAWAL_FUEL^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TOTAL_WITHDRAWAL_FUEL', 'Column', 'Withdrawal Fuel', '', 12, 0, '-3~0^-2~0^2~0^7~0^11~7^13~0^14~2^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TOTAL_NET_WITHDRAWALS', 'Column', 'Net Withdrawals', '', 13, 0, '-3~0^-2~0^2~0^7~0^11~7^13~0^14~2^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'ENDING_BALANCE', 'Column', '', '', 14, 0, '-3~0^-2~0^2~0^7~0^11~7^13~0^20~0^24~0^25~STARTING_BALANCE-TOTAL_GROSS_WITHDRAWALS+TOTAL_NET_INJECTIONS^31~0', v_CHILD_OBJECT_ID);
               <<L39>>
               DECLARE
                  v_PARENT_OBJECT_ID NUMBER(9) := L38.v_OBJECT_ID;
                  v_OBJECT_ID NUMBER(9);
               BEGIN
                  SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'GDJ.GET_STORAGE_TXNS', 'Grid', 'Gdj.Get Storage Txns', '', 0, 0, '-3~0^-2~0^305~0^308~0', v_OBJECT_ID);
                  SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRANSACTION_NAME', 'Column', 'Transaction', '', 0, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
                  SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'INJECTIONS', 'Column', 'Injected Amount', '', 1, 0, '-3~0^-2~0^2~0^7~0^11~7^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
                  SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'WITHDRAWALS', 'Column', 'Withdrawn Amount', '', 2, 0, '-3~0^-2~0^2~0^7~0^11~7^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
                  SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'CONTRACT_NAME', 'Label', 'Contract', '', 0, 0, '-3~0^-2~0^1101~2', v_CHILD_OBJECT_ID);
                  SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SCHEDULE_DATE_DISP', 'Label', 'Schedule Date', '', 1, 0, '-3~0^-2~0^1101~0', v_CHILD_OBJECT_ID);
               END;
                
            END;
             
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'CONTRACT_ID', 'Report Filter', 'Contract', '', 0, 0, '501~s (Special List)^504~GDJ.GET_STORAGE_CONTRACTS;BEGIN_DATE;END_DATE^508~1', v_CHILD_OBJECT_ID);
            <<L40>>
            DECLARE
               v_PARENT_OBJECT_ID NUMBER(9) := L36.v_OBJECT_ID;
               v_OBJECT_ID NUMBER(9);
            BEGIN
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'CALC', 'Report Filter', 'Calculate Storage Schedules', '', 1, 0, '-3~0^-2~0^501~b (Button)^508~0^514~0^515~0^519~0^520~0', v_OBJECT_ID);
               <<L41>>
               DECLARE
                  v_PARENT_OBJECT_ID NUMBER(9) := L40.v_OBJECT_ID;
                  v_OBJECT_ID NUMBER(9);
               BEGIN
                  SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'Macro', 'Action', 'Calculate Storage Schedules', '', 0, 0, '-3~0^-2~0^1006~8', v_OBJECT_ID);
                  SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'CALC', 'Action', 'Calculate', '', 0, 0, '1006~3^1007~ITJ.CALC_STORAGE_SCHEDULES', v_CHILD_OBJECT_ID);
                  SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'REFRESH', 'Action', 'Refresh', '', 1, 0, '1006~6^1007~GasDelivery.Storage', v_CHILD_OBJECT_ID);
               END;
                
            END;
             
         END;
          
      END;
       
      -------------------------------------
      --   SEM.InterconnectorData
      -------------------------------------
      <<L42>>
      DECLARE
         v_PARENT_OBJECT_ID NUMBER(9) := L0.v_OBJECT_ID;
         v_OBJECT_ID NUMBER(9);
      BEGIN
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'SEM.InterconnectorData', 'System View', 'Sem.Interconnectordata', '', 0, 0, '-3~0^-2~0', v_OBJECT_ID);
         <<L43>>
         DECLARE
            v_PARENT_OBJECT_ID NUMBER(9) := L42.v_OBJECT_ID;
            v_OBJECT_ID NUMBER(9);
         BEGIN
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'INTERCONNECTOR_DETAILS', 'Report', 'Interconnector Details', '', 0, 0, '-3~0^-2~0^401~SEM_REPORTS.INTERCONNECTOR_DETAILS^402~0^406~0', v_OBJECT_ID);
            <<L44>>
            DECLARE
               v_PARENT_OBJECT_ID NUMBER(9) := L43.v_OBJECT_ID;
               v_OBJECT_ID NUMBER(9);
            BEGIN
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'INTERCONNECTOR_DETAILS_Grid', 'Grid', 'Interconnector Details Grid', '', 0, 0, '-3~0^-2~0^305~0^307~Anchored^308~0^311~0', v_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SCHEDULE_DATE', 'Column', '', '', 0, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~1^24~1^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SERVICE_POINT_NAME', 'Column', '', '', 1, 0, '22~2', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'MAXIMUM_EXPORT_MW', 'Column', 'ATC Export', '', 2, 0, '-3~0^-2~0^2~0^7~0^13~1^20~0^22~5^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'MAXIMUM_IMPORT_MW', 'Column', 'ATC Import', '', 3, 0, '-3~0^-2~0^2~0^7~0^13~1^20~0^22~5^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'REV_MAXIMUM_EXPORT_MW', 'Column', 'Revised ATC Export', '', 4, 0, '-3~0^-2~0^2~0^7~0^13~1^20~0^22~5^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'REV_MAXIMUM_IMPORT_MW', 'Column', 'Revised ATC Import', '', 5, 0, '-3~0^-2~0^2~0^7~0^13~1^20~0^22~5^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'INDICATIVE_NET_FLOW', 'Column', '', '', 6, 0, '-3~0^-2~0^2~0^7~0^13~1^20~0^22~5^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'INDICATIVE_RESIDUAL_CAPACITY', 'Column', '', '', 7, 0, '-3~0^-2~0^2~0^7~0^13~1^20~0^22~5^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'INITIAL_NET_FLOW', 'Column', '', '', 8, 0, '-3~0^-2~0^2~0^7~0^13~1^20~0^22~5^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'INITIAL_RESIDUAL_CAPACITY', 'Column', '', '', 90, 0, '-3~0^-2~0^2~0^7~0^13~1^20~0^22~5^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'UNIT_NOMINATION', 'Column', 'Agg. Nomination', '', 91, 0, '-3~0^-2~0^2~0^7~0^13~1^20~0^22~5^24~0^31~0', v_CHILD_OBJECT_ID);
            END;
             
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'POD_ID', 'Report Filter', 'Interconnector(s)', '', 0, 0, '-3~0^-2~0^501~s (Special List)^504~SEM_REPORTS.IC_NAMES^508~1^509~,^510~2^514~0^515~0^519~0^520~0^521~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SHOW_ATC', 'Report Filter', 'Show ATC', '', 1, 0, '-3~0^-2~0^501~k (Checkbox)^506~1 (Checked)^508~0^514~0^515~0^517~Display Options^519~0^520~0^521~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SHOW_REV_ATC', 'Report Filter', 'Show Revised ATC', '', 2, 0, '-3~0^-2~0^501~k (Checkbox)^506~1 (Checked)^508~0^514~0^515~0^517~Display Options^519~0^520~0^521~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SHOW_INDIC', 'Report Filter', 'Show Indicative Flow', '', 3, 0, '-3~0^-2~0^501~k (Checkbox)^506~1 (Checked)^508~0^514~0^515~0^517~Display Options^519~0^520~0^521~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SHOW_INIT', 'Report Filter', 'Show Initial Flow', '', 4, 0, '-3~0^-2~0^501~k (Checkbox)^506~1 (Checked)^508~0^514~0^515~0^517~Display Options^519~0^520~0^521~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SHOW_NOMS', 'Report Filter', 'Show Agg. Nominations', '', 5, 0, '-3~0^-2~0^501~k (Checkbox)^506~1 (Checked)^508~0^514~0^515~0^517~Display Options^519~0^520~0^521~0', v_CHILD_OBJECT_ID);
         END;
          
         <<L45>>
         DECLARE
            v_PARENT_OBJECT_ID NUMBER(9) := L42.v_OBJECT_ID;
            v_OBJECT_ID NUMBER(9);
         BEGIN
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'INTERCONNECTOR_ERR_UNIT_BAL', 'Report', 'Interconnector Net Actuals', '', 1, 0, '-3~0^-2~0^401~SEM_REPORTS.INTERCONNECTOR_NET_ACTUALS^402~0^406~0', v_OBJECT_ID);
            <<L46>>
            DECLARE
               v_PARENT_OBJECT_ID NUMBER(9) := L45.v_OBJECT_ID;
               v_OBJECT_ID NUMBER(9);
            BEGIN
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'INTERCONNECTOR_ERR_UNIT_BAL_Grid', 'Grid', 'Interconnector Err Unit Bal Grid', '', 0, 0, '-3~0^-2~0^305~0^307~Anchored^308~0', v_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SERVICE_POINT_NAME', 'Column', '', '', 0, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~2^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'PSE_NAME', 'Column', '', '', 1, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~2^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'RUN_TYPE', 'Column', '', '', 2, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~2^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SCHEDULE_DATE', 'Column', '', '', 3, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~1^24~1^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SCHEDULE_MW', 'Column', 'Net Actual MW', '', 4, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~5^24~0^31~0', v_CHILD_OBJECT_ID);
            END;
             
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'POD_ID', 'Report Filter', 'Interconnector(s)', '', 1, 0, '-3~0^-2~0^501~s (Special List)^504~SEM_REPORTS.IC_NAMES^508~1^510~2^514~0^515~0^518~PSE_ID^519~0^520~0^521~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'PSE_ID', 'Report Filter', 'Participant(s)', '', 2, 0, '-3~0^-2~0^501~s (Special List)^504~SEM_REPORTS.PSE_NAMES_ICNA;BEGIN_DATE;END_DATE;TIME_ZONE;POD_ID^508~1^509~,^514~0^515~0^518~SERVICE_POINT_NAME^519~0^520~0^521~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'RUN_TYPE', 'Report Filter', 'Version(s)', '', 3, 0, '-3~0^-2~0^501~c (Combo Box)^502~Ex-Ante|Ex-Post 1|Ex-Post 2^508~1^510~4^514~0^515~0^519~0^520~0^521~0', v_CHILD_OBJECT_ID);
         END;
          
         <<L47>>
         DECLARE
            v_PARENT_OBJECT_ID NUMBER(9) := L42.v_OBJECT_ID;
            v_OBJECT_ID NUMBER(9);
         BEGIN
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'INTERCONNECTOR_AUCTION_RTLS', 'Report', 'Capacity Holdings', '', 2, 0, '-3~0^-2~0^401~SEM_REPORTS.INTERCONNECTOR_CAP_HOLDINGS^402~0^406~0', v_OBJECT_ID);
            <<L48>>
            DECLARE
               v_PARENT_OBJECT_ID NUMBER(9) := L47.v_OBJECT_ID;
               v_OBJECT_ID NUMBER(9);
            BEGIN
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'INTERCONNECTOR_AUCTION_RTLS_Grid', 'Grid', 'Interconnector Auction Rtls Grid', '', 0, 0, '-3~0^-2~0^305~0^307~Anchored^308~0', v_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SCHEDULE_DATE', 'Column', '', '', 0, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~1^24~1^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'PSE_NAME', 'Column', '', '', 1, 0, '22~2', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SERVICE_POINT_NAME', 'Column', '', '', 2, 0, '22~2', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'PERIODICITY', 'Column', '', '', 3, 0, '22~2', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'IC_EXPORT_CAPACITY', 'Column', 'Export Capacity', '', 4, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~5^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'IC_IMPORT_CAPACITY', 'Column', 'Import Capacity', '', 5, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~5^24~0^31~0', v_CHILD_OBJECT_ID);
            END;
             
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'POD_ID', 'Report Filter', 'Interconnector(s)', '', 0, 0, '-3~0^-2~0^501~s (Special List)^504~SEM_REPORTS.IC_NAMES^508~1^510~2^514~0^515~0^518~PSE_ID^519~0^520~0^521~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'PSE_ID', 'Report Filter', 'Participant(s)', '', 1, 0, '-3~0^-2~0^501~s (Special List)^504~SEM_REPORTS.PSE_NAMES_IC;BEGIN_DATE;END_DATE;TIME_ZONE;POD_ID^508~1^509~,^514~0^515~0^518~SERVICE_POINT_NAME^519~0^520~0^521~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'PERIODICITY', 'Report Filter', 'Version(s)', '', 2, 0, '-3~0^-2~0^501~c (Combo Box)^502~Annual|Monthly|Daily|Daily Active^508~1^510~4^514~0^515~0^519~0^520~0^521~0', v_CHILD_OBJECT_ID);
         END;
          
      END;
       
      -------------------------------------
      --   SEM.LossFactors
      -------------------------------------
      <<L49>>
      DECLARE
         v_PARENT_OBJECT_ID NUMBER(9) := L0.v_OBJECT_ID;
         v_OBJECT_ID NUMBER(9);
      BEGIN
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'SEM.LossFactors', 'System View', 'Sem.Lossfactors', '', 0, 0, '-3~0^-2~0', v_OBJECT_ID);
         <<L50>>
         DECLARE
            v_PARENT_OBJECT_ID NUMBER(9) := L49.v_OBJECT_ID;
            v_OBJECT_ID NUMBER(9);
         BEGIN
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'TRANS_ADJ_LOSS_FACTORS', 'Report', 'Transmission Loss Adjustment Factors', '', 1, 0, '-3~0^-2~0^401~SEM_REPORTS.TRANS_ADJ_LOSS_FACTORS^402~0^406~0', v_OBJECT_ID);
            <<L51>>
            DECLARE
               v_PARENT_OBJECT_ID NUMBER(9) := L50.v_OBJECT_ID;
               v_OBJECT_ID NUMBER(9);
            BEGIN
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'TRANS_ADJ_LOSS_FACTORS_Grid', 'Grid', 'Trans Adj Loss Factors Grid', '', 0, 0, '-3~0^-2~0^305~0^307~Anchored^308~1', v_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SCHEDULE_DATE', 'Column', '', '', 0, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~1^24~1^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'LOSS_FACTOR', 'Column', '', '', 1, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~5^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'PSE_NAME', 'Column', '', '', 2, 0, '22~2', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SERVICE_POINT_NAME', 'Column', '', '', 3, 0, '22~2', v_CHILD_OBJECT_ID);
            END;
             
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'PSE_ID', 'Report Filter', 'Participant(s)', '', 0, 0, '-3~0^-2~0^501~s (Special List)^504~SEM_REPORTS.PSE_NAMES_TLAF;BEGIN_DATE;END_DATE;TIME_ZONE^508~1^509~,^514~0^515~0^518~SERVICE_POINT_ID^519~0^520~0^521~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SERVICE_POINT_ID', 'Report Filter', 'Resource(s)', '', 1, 0, '-3~0^-2~0^501~s (Special List)^504~SEM_REPORTS.SERVICE_POINT_NAME;PSE_ID;BEGIN_DATE;END_DATE;TIME_ZONE^508~1^509~,^514~0^515~0^519~0^520~0^521~0', v_CHILD_OBJECT_ID);
         END;
          
      END;
       
      -------------------------------------
      --   SEM.MarketForecast
      -------------------------------------
      <<L52>>
      DECLARE
         v_PARENT_OBJECT_ID NUMBER(9) := L0.v_OBJECT_ID;
         v_OBJECT_ID NUMBER(9);
      BEGIN
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'SEM.MarketForecast', 'System View', 'Sem.Marketforecast', '', 0, 0, '-3~0^-2~0', v_OBJECT_ID);
         <<L53>>
         DECLARE
            v_PARENT_OBJECT_ID NUMBER(9) := L52.v_OBJECT_ID;
            v_OBJECT_ID NUMBER(9);
         BEGIN
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'LOAD_FORECAST_SUMMARY', 'Report', 'Load Forecast Summary', '', 1, 0, '401~SEM_REPORTS.LOAD_FORECAST_SUMMARY', v_OBJECT_ID);
            <<L54>>
            DECLARE
               v_PARENT_OBJECT_ID NUMBER(9) := L53.v_OBJECT_ID;
               v_OBJECT_ID NUMBER(9);
            BEGIN
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'LOAD_FORECAST_SUMMARY_Grid', 'Grid', 'Load Forecast Summary Grid', '', 0, 0, '-3~0^-2~0^305~0^307~Anchored^308~0', v_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'JURISDICTION', 'Column', '', '', 0, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~2^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SCHEDULE_DATE', 'Column', '', '', 1, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~1^24~1^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'LOAD_MW', 'Column', 'Forecast MW', '', 2, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~5^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'ASSUMPTIONS', 'Column', '', '', 3, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~5^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'NET_MW', 'Column', 'Net Load Forecast', '', 4, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~5^24~0^31~0', v_CHILD_OBJECT_ID);
            END;
             
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'JURISDICTIONS', 'Report Filter', 'Jurisdiction(s)', '', 0, 0, '-3~0^-2~0^501~c (Combo Box)^502~ROI|NI^507~ROI^508~1^509~,^510~2^514~0^515~0^519~0^520~0^521~0', v_CHILD_OBJECT_ID);
         END;
          
         <<L55>>
         DECLARE
            v_PARENT_OBJECT_ID NUMBER(9) := L52.v_OBJECT_ID;
            v_OBJECT_ID NUMBER(9);
         BEGIN
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'LOAD_FORECAST_ASSUMPTIONS', 'Report', 'Load Forecast and Assumptions', '', 2, 0, '-3~0^-2~0^401~SEM_REPORTS.LOAD_FORECAST_ASSUMPTIONS^402~0^406~0', v_OBJECT_ID);
            <<L56>>
            DECLARE
               v_PARENT_OBJECT_ID NUMBER(9) := L55.v_OBJECT_ID;
               v_OBJECT_ID NUMBER(9);
            BEGIN
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'LOAD_FORECAST_ASSUMPTIONS_Grid', 'Grid', 'Load Forecast Assumptions Grid', '', 0, 0, '-3~0^-2~0^305~0^307~Anchored^308~0', v_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SCHEDULE_DATE', 'Column', '', '', 0, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~1^24~1^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'LOAD_MW', 'Column', 'Forecast MW', '', 1, 0, '-3~0^-2~0^2~0^3~###,###,##0.000^7~0^13~0^20~0^22~5^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'ASSUMPTIONS', 'Column', '', '', 2, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~5^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'JURISDICTION', 'Column', '', '', 3, 0, '22~2', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'PERIODICITY', 'Column', '', '', 4, 0, '22~2', v_CHILD_OBJECT_ID);
            END;
             
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'JURISDICTIONS', 'Report Filter', 'Jurisdiction(s)', '', 0, 0, '-3~0^-2~0^501~c (Combo Box)^502~ROI|NI^507~ROI^508~1^509~,^510~2^514~0^515~0^519~0^520~0^521~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'PERIODICITY', 'Report Filter', 'Version(s)', '', 1, 0, '-3~0^-2~0^501~c (Combo Box)^502~Annual|Monthly|Daily (D+1)|Daily (D+2)|Daily (D+3)|Daily (D+4)^507~Annual^508~1^509~,^510~6^514~0^515~0^519~0^520~0^521~0', v_CHILD_OBJECT_ID);
         END;
          
         <<L57>>
         DECLARE
            v_PARENT_OBJECT_ID NUMBER(9) := L52.v_OBJECT_ID;
            v_OBJECT_ID NUMBER(9);
         BEGIN
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'WIND_GEN_FORECAST', 'Report', 'Wind Generation Forecast', '', 3, 0, '-3~0^-2~0^401~SEM_REPORTS.WIND_GEN_FORECAST;PARTICIPANTS=PSE_ID^402~0^406~0', v_OBJECT_ID);
            <<L58>>
            DECLARE
               v_PARENT_OBJECT_ID NUMBER(9) := L57.v_OBJECT_ID;
               v_OBJECT_ID NUMBER(9);
            BEGIN
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'WIND_GEN_FORECAST_Grid', 'Grid', 'Wind Gen Forecast Grid', '', 0, 0, '-3~0^-2~0^305~0^307~Anchored^308~0', v_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'JURISDICTION', 'Column', '', '', 0, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~2^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'PSE_NAME', 'Column', '', '', 1, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~2^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'PERIODICITY', 'Column', '', '', 2, 0, '22~2', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SCHEDULE_DATE', 'Column', '', '', 3, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~1^24~1^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'FORECAST_MW', 'Column', 'Forecast MW', '', 4, 0, '-3~0^-2~0^2~0^3~0.000^7~0^11~7^13~0^20~0^22~5^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'ASSUMPTIONS', 'Column', '', '', 5, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~5^24~0^31~0', v_CHILD_OBJECT_ID);
            END;
             
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'DAY_TYPE', 'Report Filter', 'Version(s)', '', 1, 0, '-3~0^-2~0^501~c (Combo Box)^502~Daily (D+1)|Daily (D+2)^503~DAY_TYPE^508~1^509~,^510~2^514~0^515~0^519~0^520~0^521~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'JURISDICTIONS', 'Report Filter', 'Jurisdiction(s)', '', 2, 0, '-3~0^-2~0^501~c (Combo Box)^502~ROI|NI^507~ROI^508~1^509~,^510~2^514~0^515~0^518~PSE_ID^519~0^520~0^521~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'PSE_ID', 'Report Filter', 'Participant(s)', '', 3, 0, '-3~0^-2~0^501~s (Special List)^504~SEM_REPORTS.PSE_NAME;JURISDICTIONS;BEGIN_DATE;END_DATE;TIME_ZONE^508~1^509~,^514~0^515~0^519~0^520~0^521~0', v_CHILD_OBJECT_ID);
         END;
          
         <<L59>>
         DECLARE
            v_PARENT_OBJECT_ID NUMBER(9) := L52.v_OBJECT_ID;
            v_OBJECT_ID NUMBER(9);
         BEGIN
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'NONWIND_GEN_FORECAST', 'Report', 'Non-Wind Autonomous Forecast', '', 4, 0, '401~SEM_REPORTS.NONWIND_GEN_FORECAST', v_OBJECT_ID);
            <<L60>>
            DECLARE
               v_PARENT_OBJECT_ID NUMBER(9) := L59.v_OBJECT_ID;
               v_OBJECT_ID NUMBER(9);
            BEGIN
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'NONWIND_GEN_FORECAST_Grid', 'Grid', 'Nonwind Gen Forecast Grid', '', 0, 0, '-3~0^-2~0^305~0^307~Anchored^308~0', v_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'JURISDICTION', 'Column', '', '', 0, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~2^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SCHEDULE_DATE', 'Column', '', '', 1, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~1^24~1^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'FORECAST_MW', 'Column', 'Forecast MW', '', 2, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~5^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'ASSUMPTIONS', 'Column', '', '', 3, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~5^24~0^31~0', v_CHILD_OBJECT_ID);
            END;
             
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'JURISDICTIONS', 'Report Filter', 'Jurisdiction(s)', '', 0, 0, '-3~0^-2~0^501~c (Combo Box)^502~ROI|NI^507~ROI^508~1^509~,^510~2^514~0^515~0^519~0^520~0^521~0', v_CHILD_OBJECT_ID);
         END;
          
         <<L61>>
         DECLARE
            v_PARENT_OBJECT_ID NUMBER(9) := L52.v_OBJECT_ID;
            v_OBJECT_ID NUMBER(9);
         BEGIN
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'LOSS_LOAD_PROB_FORECAST', 'Report', 'Loss of Load Probability Forecast', '', 5, 0, '-3~0^-2~0^401~SEM_REPORTS.LOSS_LOAD_PROB_FORECAST^402~0^406~0', v_OBJECT_ID);
            <<L62>>
            DECLARE
               v_PARENT_OBJECT_ID NUMBER(9) := L61.v_OBJECT_ID;
               v_OBJECT_ID NUMBER(9);
            BEGIN
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'LOSS_LOAD_PROB_FORECAST_Grid', 'Grid', 'Loss Load Prob Forecast Grid', '', 0, 0, '-3~0^-2~0^305~0^308~0', v_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SCHEDULE_DATE', 'Column', '', '', 0, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^24~1^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'LOSS_OF_LOAD_PROBABILITY', 'Column', '', '', 1, 0, '', v_CHILD_OBJECT_ID);
            END;
             
         END;
          
         <<L63>>
         DECLARE
            v_PARENT_OBJECT_ID NUMBER(9) := L52.v_OBJECT_ID;
            v_OBJECT_ID NUMBER(9);
         BEGIN
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'CUSTOM_REPORT_DAILY_FCST_CHANGE', 'Report', '(D+2) - (D+1) Daily Foreast Change Report', '', 6, 0, '-3~0^-2~0^401~SEM_CUSTOM_REPORTS.DAILY_FCST_CHANGE_REPORT^402~0^406~0', v_OBJECT_ID);
            <<L64>>
            DECLARE
               v_PARENT_OBJECT_ID NUMBER(9) := L63.v_OBJECT_ID;
               v_OBJECT_ID NUMBER(9);
            BEGIN
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'CUSTOM_REPORT_DAILY_FCST_CHANGE_Grid', 'Grid', 'Custom Report Daily Fcst Change Grid', '', 0, 0, '-3~0^-2~0^305~0^308~0', v_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SCHEDULE_DATE', 'Column', '', '', 0, 0, '-3~0^-2~0^2~0^3~yyyy-MM-dd HH:mm^7~0^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'JURISDICTION', 'Column', '', '', 1, 0, '', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'D1_FORECAST_MW', 'Column', '(D+1) Foreast MW', '', 3, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'D2_FORECAST_MW', 'Column', '(D+2) Forecast MW', '', 6, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'CHANGE', 'Column', 'Change between (D+2)and(D+1)', '', 7, 0, '-3~0^-2~0^2~0^7~0^11~4^13~0^20~0^24~0^28~CR_DLY_FCST_DIFF_THRESHOLD^31~0', v_CHILD_OBJECT_ID);
            END;
             
         END;
          
      END;
       
      -------------------------------------
      --   SEM.MeterData
      -------------------------------------
      <<L65>>
      DECLARE
         v_PARENT_OBJECT_ID NUMBER(9) := L0.v_OBJECT_ID;
         v_OBJECT_ID NUMBER(9);
      BEGIN
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'SEM.MeterData', 'System View', 'Sem.Meterdata', '', 0, 0, '-3~0^-2~0', v_OBJECT_ID);
         <<L66>>
         DECLARE
            v_PARENT_OBJECT_ID NUMBER(9) := L65.v_OBJECT_ID;
            v_OBJECT_ID NUMBER(9);
         BEGIN
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'LOAD_ACTUALS', 'Report', 'Actual Load Summary', '', 0, 0, '-3~0^-2~0^401~SEM_REPORTS.ACTUAL_LOAD_SUMMARY^402~0^406~0', v_OBJECT_ID);
            <<L67>>
            DECLARE
               v_PARENT_OBJECT_ID NUMBER(9) := L66.v_OBJECT_ID;
               v_OBJECT_ID NUMBER(9);
            BEGIN
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'LOAD_ACTUALS_Grid', 'Grid', 'Load Actuals Grid', '', 0, 0, '-3~0^-2~0^305~0^307~Anchored^308~0', v_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'JURISDICTION', 'Column', '', '', 0, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~2^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'PERIODICITY', 'Column', '', '', 1, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~2^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SCHEDULE_DATE', 'Column', '', '', 2, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~1^24~1^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'LOAD_MW', 'Column', 'Load MW', '', 3, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~5^24~0^31~0', v_CHILD_OBJECT_ID);
            END;
             
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'JURISDICTIONS', 'Report Filter', 'Jurisdiction(s)', '', 0, 0, '-3~0^-2~0^501~c (Combo Box)^502~ROI|NI^508~1^509~,^510~2^514~0^515~0^519~0^520~0^521~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'RUN_TYPE', 'Report Filter', 'Version(s)', '', 1, 0, '-3~0^-2~0^501~c (Combo Box)^502~Ex-Ante|Ex-Post 1|Ex-Post 2^508~1^509~,^510~3^514~0^515~0^519~0^520~0^521~0', v_CHILD_OBJECT_ID);
         END;
          
         <<L68>>
         DECLARE
            v_PARENT_OBJECT_ID NUMBER(9) := L65.v_OBJECT_ID;
            v_OBJECT_ID NUMBER(9);
         BEGIN
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'METER_DATA', 'Report', 'Meter Summary', '', 1, 0, '-3~0^-2~0^401~SEM_REPORTS.METER_DATA_SUMMARY^402~0^406~0', v_OBJECT_ID);
            <<L69>>
            DECLARE
               v_PARENT_OBJECT_ID NUMBER(9) := L68.v_OBJECT_ID;
               v_OBJECT_ID NUMBER(9);
            BEGIN
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'METER_DATA_Grid', 'Grid', 'Meter Data Grid', '', 0, 0, '-3~0^-2~0^305~0^307~Anchored^308~0', v_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SCHEDULE_DATE', 'Column', '', '', 0, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~1^24~1^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'PERIODICITY', 'Column', '', '', 1, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~2^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TOTAL_GEN', 'Column', '', '', 2, 0, '22~5', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TOTAL_LOAD', 'Column', '', '', 3, 0, '22~5', v_CHILD_OBJECT_ID);
            END;
             
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'PERIODICITY', 'Report Filter', 'Version(s)', '', 0, 0, '-3~0^-2~0^501~c (Combo Box)^502~Daily (D-1)|Daily (D-3)^508~1^509~,^510~2^514~0^515~0^519~0^520~0^521~0', v_CHILD_OBJECT_ID);
         END;
          
         <<L70>>
         DECLARE
            v_PARENT_OBJECT_ID NUMBER(9) := L65.v_OBJECT_ID;
            v_OBJECT_ID NUMBER(9);
         BEGIN
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'METER_DATA2', 'Report', 'Meter Detail', '', 2, 0, '-3~0^-2~0^401~SEM_REPORTS.METER_DATA_DETAIL^402~0^406~0', v_OBJECT_ID);
            <<L71>>
            DECLARE
               v_PARENT_OBJECT_ID NUMBER(9) := L70.v_OBJECT_ID;
               v_OBJECT_ID NUMBER(9);
            BEGIN
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'METER_DATA2_Grid', 'Grid', 'Meter Data2 Grid', '', 0, 0, '-3~0^-2~0^305~0^307~Anchored^308~1', v_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SCHEDULE_DATE', 'Column', '', '', 0, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~1^24~1^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'JURISDICTION', 'Column', '', '', 1, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~2^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'RESOURCE_TYPE', 'Column', '', '', 2, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~2^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SERVICE_POINT_NAME', 'Column', '', '', 3, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~2^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'PERIODICITY', 'Column', '', '', 4, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~2^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'METERED_MW', 'Column', '', '', 5, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~5^24~0^31~0', v_CHILD_OBJECT_ID);
            END;
             
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'PERIODICITY', 'Report Filter', 'Version(s)', '', 1, 0, '-3~0^-2~0^501~c (Combo Box)^502~Daily (D-1)|Daily (D-3)^508~1^509~,^510~2^514~0^515~0^518~POD_ID^519~0^520~0^521~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'JURISDICTIONS', 'Report Filter', 'Jurisdiction(s)', '', 2, 0, '-3~0^-2~0^501~c (Combo Box)^502~ROI|NI^507~ROI^508~1^509~,^510~2^514~0^515~0^518~POD_ID^519~0^520~0^521~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'RESOURCE_TYPE', 'Report Filter', 'Resource Type(s)', '', 3, 0, '-3~0^-2~0^501~c (Combo Box)^502~PPMG|PPTG|VPMG|VPTG|APTG|DU|SU|I^507~PPMG^508~1^509~,^510~8^514~0^515~0^518~POD_ID^519~0^520~0^521~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'POD_ID', 'Report Filter', 'Resource(s)', '', 4, 0, '-3~0^-2~0^501~s (Special List)^504~SEM_REPORTS.POD_NAMES_METER;BEGIN_DATE;END_DATE;TIME_ZONE;JURISDICTIONS;RESOURCE_TYPE^508~1^514~0^515~0^519~0^520~0^521~0', v_CHILD_OBJECT_ID);
         END;
          
         <<L72>>
         DECLARE
            v_PARENT_OBJECT_ID NUMBER(9) := L65.v_OBJECT_ID;
            v_OBJECT_ID NUMBER(9);
         BEGIN
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'ERROR_SUPPLY', 'Report', 'Jurisdiction Error Supply', '', 3, 0, '401~SEM_REPORTS.LOAD_ERROR_SUPPLY', v_OBJECT_ID);
            <<L73>>
            DECLARE
               v_PARENT_OBJECT_ID NUMBER(9) := L72.v_OBJECT_ID;
               v_OBJECT_ID NUMBER(9);
            BEGIN
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'ERROR_SUPPLY_Grid', 'Grid', 'Error Supply Grid', '', 0, 0, '-3~0^-2~0^305~0^307~Anchored^308~0', v_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'JURISDICTION', 'Column', '', '', 0, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~2^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'PERIODICITY', 'Column', '', '', 1, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~2^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SCHEDULE_DATE', 'Column', '', '', 2, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~1^24~1^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'LOAD_MW', 'Column', 'Error Supply MW', '', 3, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~5^24~0^31~0', v_CHILD_OBJECT_ID);
            END;
             
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'JURISDICTIONS', 'Report Filter', 'Jurisdiction(s)', '', 0, 0, '-3~0^-2~0^501~c (Combo Box)^502~ROI|NI^507~ROI^508~1^509~,^510~2^514~0^515~0^519~0^520~0^521~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'PERIODICITY', 'Report Filter', 'Version(s)', '', 1, 0, '-3~0^-2~0^501~c (Combo Box)^502~Daily (D-1)|Daily (D-4)^508~1^509~,^510~2^514~0^515~0^519~0^520~0^521~0', v_CHILD_OBJECT_ID);
         END;
          
         <<L74>>
         DECLARE
            v_PARENT_OBJECT_ID NUMBER(9) := L65.v_OBJECT_ID;
            v_OBJECT_ID NUMBER(9);
         BEGIN
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'DISP', 'Report', 'Dispatch Instructions', '', 4, 0, '-3~0^-2~0^401~SEM_REPORTS.DISPATCH_INSTR^402~0^406~0', v_OBJECT_ID);
            <<L75>>
            DECLARE
               v_PARENT_OBJECT_ID NUMBER(9) := L74.v_OBJECT_ID;
               v_OBJECT_ID NUMBER(9);
            BEGIN
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'DISP_Grid', 'Grid', 'Disp Grid', '', 0, 0, '-3~0^-2~0^305~0^308~0', v_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'PSE_NAME', 'Column', 'Participant Name', '', 0, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^24~1^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SERVICE_POINT_NAME', 'Column', 'Resource Name', '', 1, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^24~1^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'INSTRUCTION_TIME_STAMP', 'Column', '', '', 2, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^24~1^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'INSTRUCTION_ISSUE_TIME', 'Column', '', '', 3, 0, '', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'DISPATCH_INSTRUCTION', 'Column', '', '', 4, 0, '', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'RAMP_UP_RATE', 'Column', '', '', 5, 0, '', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'RAMP_DOWN_RATE', 'Column', '', '', 6, 0, '', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'INSTRUCTION_CODE', 'Column', '', '', 7, 0, '', v_CHILD_OBJECT_ID);
            END;
             
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'PSE_ID', 'Report Filter', 'Participant(s)', '', 0, 0, '-3~0^-2~0^501~s (Special List)^504~SEM_REPORTS.PSE_NAMES_DISP;BEGIN_DATE;END_DATE;TIME_ZONE^508~1^509~,^514~0^515~0^518~SERVICE_POINT_ID^519~0^520~0^521~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'POD_ID', 'Report Filter', 'Resource(s)', '', 1, 0, '-3~0^-2~0^501~s (Special List)^504~SEM_REPORTS.POD_NAMES_DISP;PSE_ID;BEGIN_DATE;END_DATE;TIME_ZONE^508~1^509~,^514~0^515~0^519~0^520~0^521~0', v_CHILD_OBJECT_ID);
         END;
          
      END;
       
      -------------------------------------
      --   SEM.OutageSchedules
      -------------------------------------
      <<L76>>
      DECLARE
         v_PARENT_OBJECT_ID NUMBER(9) := L0.v_OBJECT_ID;
         v_OBJECT_ID NUMBER(9);
      BEGIN
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'SEM.OutageSchedules', 'System View', 'Sem.Outageschedules', '', 0, 0, '-3~0^-2~0', v_OBJECT_ID);
         <<L77>>
         DECLARE
            v_PARENT_OBJECT_ID NUMBER(9) := L76.v_OBJECT_ID;
            v_OBJECT_ID NUMBER(9);
         BEGIN
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'INACTIVE_PSEs', 'Report', 'Suspended/Terminated Participants', '', 0, 0, '-3~0^-2~0^401~SEM_REPORTS.GET_INACTIVE_PSEs^402~0^406~0', v_OBJECT_ID);
            <<L78>>
            DECLARE
               v_PARENT_OBJECT_ID NUMBER(9) := L77.v_OBJECT_ID;
               v_OBJECT_ID NUMBER(9);
            BEGIN
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'INACTIVE_PSEs_Grid', 'Grid', 'Inactive Pses Grid', '', 0, 0, '-3~0^-2~0^305~0^308~0', v_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SYSTEM_NAME', 'Column', 'System', '', 0, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'PSE_NAME', 'Column', 'Participant', '', 1, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'USER_NAME', 'Column', 'User', '', 2, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'REQUEST_TYPE', 'Column', '', '', 3, 0, '', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'EFF_DATE', 'Column', 'Effective Date', '', 4, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'EXP_DATE', 'Column', 'Expiration Date', '', 5, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
            END;
             
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'REQ_TYPE', 'Report Filter', 'Request Type', '', 0, 0, '501~r (Radio Button)^502~Terminated|Suspended|Both', v_CHILD_OBJECT_ID);
         END;
          
         <<L79>>
         DECLARE
            v_PARENT_OBJECT_ID NUMBER(9) := L76.v_OBJECT_ID;
            v_OBJECT_ID NUMBER(9);
         BEGIN
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'OUTAGE_SCHEDULES', 'Report', 'Outage Schedules', '', 1, 0, '-3~0^-2~0^401~SEM_REPORTS.OUTAGE_SCHEDULES^402~0^406~0', v_OBJECT_ID);
            <<L80>>
            DECLARE
               v_PARENT_OBJECT_ID NUMBER(9) := L79.v_OBJECT_ID;
               v_OBJECT_ID NUMBER(9);
            BEGIN
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'OUTAGE_SCHEDULES_Grid', 'Grid', 'Outage Schedules Grid', '', 0, 0, '-3~0^-2~0^305~0^308~0', v_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SERVICE_POINT_NAME', 'Column', 'Resource', '', 0, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^24~1^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'BEGIN_TIME', 'Column', '', '', 1, 0, '-3~0^-2~0^2~0^3~yyyy-MM-dd KK:mm^7~0^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'END_TIME', 'Column', '', '', 2, 0, '-3~0^-2~0^2~0^3~yyyy-MM-dd KK:mm^7~0^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'OUTAGE_REASON_FLAG', 'Column', 'Outage Reason', '', 3, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'DERATE_MW', 'Column', '', '', 4, 0, '-3~0^-2~0^2~0^7~0^13~1^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'EQUIPMENT_STATUS', 'Column', '', '', 5, 0, '-3~0^-2~0^2~0^7~0^13~1^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
            END;
             
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'REPORT_SOURCE', 'Report Filter', 'Outage Type', '', 0, 0, '-3~0^-2~0^501~s (Special List)^504~SEM_REPORTS.OUTAGE_RPT_SOURCES^508~0^514~0^515~0^518~POD_ID^519~0^520~0^521~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'POD_ID', 'Report Filter', 'Resource(s)', '', 1, 0, '-3~0^-2~0^501~s (Special List)^504~SEM_REPORTS.POD_NAMES_OUTAGES;REPORT_SOURCE;BEGIN_DATE;END_DATE;TIME_ZONE^508~1^509~,^514~0^515~0^519~0^520~0^521~0', v_CHILD_OBJECT_ID);
         END;
          
         <<L81>>
         DECLARE
            v_PARENT_OBJECT_ID NUMBER(9) := L76.v_OBJECT_ID;
            v_OBJECT_ID NUMBER(9);
         BEGIN
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'SYSTEM_FREQUENCY', 'Report', 'SO System Frequency', '', 2, 0, '-3~0^-2~0^401~SEM_REPORTS.SYSTEM_FREQUENCY^402~0^406~0', v_OBJECT_ID);
            <<L82>>
            DECLARE
               v_PARENT_OBJECT_ID NUMBER(9) := L81.v_OBJECT_ID;
               v_OBJECT_ID NUMBER(9);
            BEGIN
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'SYSTEM_FREQUENCY_Grid', 'Grid', 'System Frequency Grid', '', 0, 0, '-3~0^-2~0^305~0^308~0^311~0', v_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'PSE_NAME', 'Column', 'Participant Name', '', 0, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SCHEDULE_DATE', 'Column', '', '', 1, 0, '', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'NORMAL_FREQUENCY', 'Column', '', '', 2, 0, '', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'AVERAGE_FREQUENCY', 'Column', '', '', 3, 0, '', v_CHILD_OBJECT_ID);
            END;
             
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'PSE_ID', 'Report Filter', 'Participant(s)', '', 0, 0, '-3~0^-2~0^501~s (Special List)^504~SEM_REPORTS.PSE_NAMES_FREQUENCY;BEGIN_DATE;END_DATE;TIME_ZONE^508~1^509~,^514~0^515~0^519~0^520~0^521~0', v_CHILD_OBJECT_ID);
         END;
          
      END;
       
      -------------------------------------
      --   SEM.Schedules
      -------------------------------------
      <<L83>>
      DECLARE
         v_PARENT_OBJECT_ID NUMBER(9) := L0.v_OBJECT_ID;
         v_OBJECT_ID NUMBER(9);
      BEGIN
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'SEM.Schedules', 'System View', 'SEM.Schedules', '', 0, 0, '-3~0^-2~0^801~com.newenergyassoc.ro.scheduling.scheduler.SchedulerContentPanel', v_OBJECT_ID);
         <<L84>>
         DECLARE
            v_PARENT_OBJECT_ID NUMBER(9) := L83.v_OBJECT_ID;
            v_OBJECT_ID NUMBER(9);
         BEGIN
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'Schedules', 'Report', 'Schedules', '', 0, 0, '-3~0^-2~0^401~SEM_REPORTS.GET_SEM_SCHEDULES^402~0^406~0', v_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'Chart', 'Chart', 'Chart', '', 0, 0, '901~0^905~AMOUNT^913~1', v_CHILD_OBJECT_ID);
            <<L85>>
            DECLARE
               v_PARENT_OBJECT_ID NUMBER(9) := L84.v_OBJECT_ID;
               v_OBJECT_ID NUMBER(9);
            BEGIN
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'Schedules_Grid', 'Grid', 'Schedules Grid', '', 0, 0, '-3~0^-2~0^305~0^307~Anchored^308~1^311~0', v_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SCHEDULER', 'Action', 'Edit Schedule...', '', 0, 1, '-3~0^-2~0^1006~2^1007~Scheduling.Scheduler;TRANSACTION_ID=TRANSACTION_ID;STATEMENT_TYPE=SCHEDULE_TYPE', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRANSACTION_NAME', 'Column', '', '', 0, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~2^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SCHEDULE_DATE', 'Column', '', '', 1, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~1^24~1^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SCHEDULE_TIME', 'Column', 'Time', '', 2, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~1^24~1^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'STATEMENT_TYPE_ORDER', 'Column', '', '', 3, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~4^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SCHEDULE_TYPE', 'Column', '', '', 4, 1, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~5^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'STATEMENT_TYPE_NAME', 'Column', '', '', 5, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~3^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'AMOUNT', 'Column', '', '', 6, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~5^24~0^31~0', v_CHILD_OBJECT_ID);
            END;
             
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRANSACTION_ID', 'Report Filter', 'Transaction Id', '', 0, 0, '501~x (Custom)^508~0^512~com.newenergyassoc.ro.scheduling.scheduler.SchedulerTreeFilterComponent^513~1', v_CHILD_OBJECT_ID);
         END;
          
      END;
       
      -------------------------------------
      --   Scheduling.Balancing
      -------------------------------------
      <<L86>>
      DECLARE
         v_PARENT_OBJECT_ID NUMBER(9) := L0.v_OBJECT_ID;
         v_OBJECT_ID NUMBER(9);
      BEGIN
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'Scheduling.Balancing', 'System View', 'Scheduling.Balancing', '', 0, 0, '801~com.newenergyassoc.ro.scheduling.balancing.BalancingContentPanel', v_OBJECT_ID);
         <<L87>>
         DECLARE
            v_PARENT_OBJECT_ID NUMBER(9) := L86.v_OBJECT_ID;
            v_OBJECT_ID NUMBER(9);
         BEGIN
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'LOAD_BALANCING_REPORT', 'Report', 'Load Balancing', '', 0, 0, '401~LB.GET_BALANCE_LOAD_REPORT;UPDATE_DEMAND=0^402~0^403~Normal Grid^405~0^406~0', v_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'LOAD_BALANCING_CHART', 'Chart', '', '', 0, 0, '901~0^902~Date^903~Amount^904~Imbalance^905~IMBALANCE_AMOUNT,SUPPLY,DEMAND_AMOUNT^907~1^908~0^910~0', v_CHILD_OBJECT_ID);
            <<L88>>
            DECLARE
               v_PARENT_OBJECT_ID NUMBER(9) := L87.v_OBJECT_ID;
               v_OBJECT_ID NUMBER(9);
            BEGIN
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'LOAD_BALANCING_REPORT_Grid', 'Grid', 'Load Balancing Report Grid', '', 0, 0, '-3~0^-2~0^301~LB.PUT_BALANCE_REPORT^305~0^307~Anchored^308~0^309~0', v_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SHOW_TRANSACTION', 'Action', 'Show Transaction...', '', 0, 0, '-3~0^-2~0^1004~not islist(TRANSACTION_ID)^1006~2^1007~Common.EntityManager;entityType="TRANSACTION";entityId=TRANSACTION_ID', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SCHEDULE_DATE', 'Column', 'Date', '', 0, 0, '2~0^4~0^7~0^9~0^11~1^12~0^13~0^14~0^15~0^20~0^22~1^24~1^26~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SCHEDULE_TIME', 'Column', 'Time', '', 1, 0, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~1^24~1^26~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SUPPLY', 'Column', '', '', 2, 1, '1~n (Numeric Edit)^2~0^3~###,###,##0.00^4~0^7~0^9~0^11~7^12~0^13~0^14~0^15~0^20~1^22~6^24~0^25~= SUM(ASSIGNED_AMOUNT)^26~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'IMBALANCE_AMOUNT', 'Column', '<html><center>Imbalance<br>Amount</center></html>', '', 3, 0, '1~n (Numeric Edit)^2~0^3~###,###,##0.00^4~0^7~0^9~0^11~7^12~0^13~0^14~0^15~0^20~1^22~6^24~0^25~=SUPPLY - DEMAND_AMOUNT^26~0^30~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'IMBALANCE_PRICE', 'Column', '<html><center>Imbalance<br>Price</center></html>', '', 4, 0, '1~n (Numeric Edit)^2~0^3~Currency^4~0^7~0^9~0^11~7^12~0^13~0^14~0^15~0^20~1^22~6^24~0^26~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'IMBALANCE_COST', 'Column', '<html><center>Imbalance<br>Cost</center></html>', '', 5, 0, '1~n (Numeric Edit)^2~0^3~Currency^4~0^7~0^9~0^11~7^12~0^13~0^14~0^15~0^20~1^22~6^24~0^25~= -IMBALANCE_AMOUNT * IMBALANCE_PRICE^26~0^30~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'NET_COST', 'Column', '<html><center>Net<br>Cost</center></html>', '', 6, 0, '1~n (Numeric Edit)^2~0^3~Currency^4~0^7~0^9~0^11~7^12~0^13~0^14~0^15~0^20~1^22~6^24~0^25~= IMBALANCE_COST + SUM(COST)^26~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'BALANCE_TRANSACTION_ID', 'Column', '', '', 7, 1, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~6^24~0^26~0^30~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'BALANCE_TRANSACTION_NAME', 'Column', '', '', 8, 1, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~7^24~0^26~0^30~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'DEMAND_AMOUNT_OLD', 'Column', '', '', 9, 1, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~6^24~0^26~0^30~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'DEMAND_AMOUNT', 'Column', 'Amount', '', 10, 0, '-3~0^-2~0^1~n (Numeric Edit)^2~0^3~###,###,##0.00^4~0^7~0^9~0^11~7^12~0^13~0^14~0^15~0^20~1^22~6^24~0^25~DEMAND_AMOUNT_OLD^26~0^27~BALANCE_TRANSACTION_NAME^30~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'UPDATE_DEMAND', 'Column', '', '', 11, 1, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~6^24~0^26~0^30~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SUPPLY_TRANSACTION_NAME', 'Column', '', '', 12, 0, '-3~0^-2~0^2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~2^24~0^26~0^30~0^31~0^32~1', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SUPPLY_TRANSACTION_ID', 'Column', '', '', 13, 0, '-3~0^-2~0^2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~4^24~0^26~0^30~0^31~0^32~1', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRANSACTION_ID', 'Column', '', '', 14, 1, '22~5^25~SUPPLY_TRANSACTION_ID', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'DISP_MAX', 'Column', 'Contract Limit', '', 15, 0, '-3~0^-2~0^1~n (Numeric Edit)^2~0^3~###,###,##0.00^4~0^7~0^9~0^11~7^12~0^13~1^14~0^15~0^20~1^22~5^24~0^26~0^30~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'DISP_MIN', 'Column', 'Contract Min.', '', 16, 0, '-3~0^-2~0^1~n (Numeric Edit)^2~0^3~###,###,##0.00^4~0^7~0^9~0^11~7^12~0^13~1^14~0^15~0^20~1^22~5^24~0^26~0^30~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'FIXED_SCHEDULED', 'Column', 'Scheduled', '', 17, 0, '-3~0^-2~0^2~0^3~###,###,##0.00^4~0^7~0^9~0^11~7^12~0^13~1^14~0^15~0^20~1^22~5^24~0^26~0^30~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TOTAL_ASSIGNED', 'Column', 'Total Assigned', '', 18, 0, '-3~0^-2~0^2~0^4~0^7~0^9~0^11~7^12~0^13~0^14~0^15~0^20~1^22~5^24~0^25~IF ( IS_FIXED, FIXED_TOTAL_ASSIGNED, DISP_SCHEDULED )^26~0^30~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'DISP_SCHEDULED', 'Column', '', '', 19, 1, '-3~0^-2~0^2~0^3~###,###,##0.00^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~5^24~0^25~DISP_SCHEDULED_OLD - ASSIGNED_AMOUNT_OLD + ASSIGNED_AMOUNT^26~0^30~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'FIXED_TOTAL_ASSIGNED', 'Column', '', '', 20, 1, '-3~0^-2~0^2~0^3~###,###,##0.00^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~5^24~0^25~FIXED_TOTAL_ASSIGNED_OLD - ASSIGNED_AMOUNT_OLD + ASSIGNED_AMOUNT^26~0^30~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'UNSCHEDULED', 'Column', 'Unassigned', '', 21, 0, '-3~0^-2~0^1~n (Numeric Edit)^2~0^3~###,###,##0.00^4~0^7~0^9~0^11~7^12~1^13~0^14~0^15~0^20~1^22~5^24~0^25~= MAX - TOTAL_ASSIGNED^26~0^30~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SUPPLY_PRICE', 'Column', 'Price', '', 22, 0, '-3~0^-2~0^1~n (Numeric Edit)^2~0^3~Currency^4~0^7~0^9~0^11~7^12~0^13~0^14~0^15~0^20~1^22~5^24~0^26~0^30~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'ASSIGNED_AMOUNT', 'Column', '<html><strong>Assigned</strong></html>', '', 23, 0, '-3~0^-2~0^1~n (Numeric Edit)^2~0^3~###,###,##0.00^4~0^7~0^9~0^11~7^12~0^13~0^14~0^15~0^19~=IF (TOTAL_ASSIGNED_OLD-ASSIGNED_AMOUNT_OLD+ASSIGNED_AMOUNT > MAX, "label:alertAssignedHigh", IF ( ASSIGNED_AMOUNT < 0, "label:alertAssignedLow", "") )^20~0^22~5^24~0^26~0^30~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'ASSIGNED_AMOUNT_OLD', 'Column', '', '', 24, 1, '-3~0^-2~0^2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~5^24~0^26~0^30~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'COST', 'Column', 'Cost', '', 25, 0, '-3~0^-2~0^1~n (Numeric Edit)^2~0^3~Currency^4~0^7~0^9~0^11~7^12~0^13~0^14~0^15~0^20~1^22~5^24~0^25~= SUPPLY_PRICE * ASSIGNED_AMOUNT^26~0^30~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'IS_FIXED', 'Column', '', '', 26, 1, '-3~0^-2~0^1~k (Checkbox)^2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~5^24~0^26~0^30~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'FIXED_TOTAL_ASSIGNED_OLD', 'Column', '', '', 27, 1, '-3~0^-2~0^2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~5^24~0^26~0^30~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'DISP_SCHEDULED_OLD', 'Column', '', '', 28, 1, '-3~0^-2~0^2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~5^24~0^26~0^30~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TOTAL_ASSIGNED_OLD', 'Column', '', '', 29, 1, '-3~0^-2~0^2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~5^24~0^25~IF ( IS_FIXED, FIXED_TOTAL_ASSIGNED_OLD, DISP_SCHEDULED_OLD )^26~0^30~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'MAX', 'Column', '', '', 30, 1, '-3~0^-2~0^2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~5^24~0^25~IF ( IS_FIXED, FIXED_SCHEDULED, DISP_MAX )^26~0^30~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'MIN', 'Column', '', '', 31, 1, '-3~0^-2~0^2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~5^24~0^25~IF ( IS_FIXED, FIXED_SCHEDULED, DISP_MIN )^26~0^30~0^31~0', v_CHILD_OBJECT_ID);
            END;
             
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'BALANCE_TRANSACTION_ID', 'Report Filter', 'Load Transaction', '', 0, 0, '501~s (Special List)^504~LB.BALANCE_TRANSACTION_NAMES;BEGIN_DATE;END_DATE^508~0^514~0^515~0', v_CHILD_OBJECT_ID);
         END;
          
         <<L89>>
         DECLARE
            v_PARENT_OBJECT_ID NUMBER(9) := L86.v_OBJECT_ID;
            v_OBJECT_ID NUMBER(9);
         BEGIN
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'SUPPLY_SCHEDULING_REPORT', 'Report', 'Supply Scheduling', '', 1, 0, '401~LB.GET_BALANCE_SUPPLY_REPORT^402~0^403~Normal Grid^405~0^406~0', v_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SUPPLY_SCHEDULING_REPORT_CHART', 'Chart', 'Supply Scheduling Report Chart', '', 0, 0, '901~0^902~Amount^903~Date^904~Supply Scheduling^905~TOTAL_LOAD,TOTAL_SUPPLY,TOTAL_IMBALANCE^907~1^908~0^910~0', v_CHILD_OBJECT_ID);
            <<L90>>
            DECLARE
               v_PARENT_OBJECT_ID NUMBER(9) := L89.v_OBJECT_ID;
               v_OBJECT_ID NUMBER(9);
            BEGIN
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'SUPPLY_SCHEDULING_REPORT_Grid', 'Grid', 'Supply Scheduling Report Grid', '', 0, 0, '-3~0^-2~0^301~LB.PUT_BALANCE_REPORT^305~0^307~Anchored^308~0^309~0', v_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SHOW_TRANSACTION', 'Action', 'Show Transaction...', '', 0, 0, '-3~0^-2~0^1004~not islist(TRANSACTION_ID)^1006~2^1007~Common.EntityManager;entityType="TRANSACTION";entityId=TRANSACTION_ID', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SCHEDULE_DATE', 'Column', 'Date', '', 1, 0, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~1^24~1^26~0^30~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SCHEDULE_TIME', 'Column', 'Time', '', 2, 0, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~1^24~1^26~0^30~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'DISP_MAX', 'Column', 'Contract Limit', '', 3, 0, '1~n (Numeric Edit)^2~0^3~###,###,##0.00^4~0^7~0^9~0^11~7^12~0^13~1^14~0^15~0^20~1^22~6^24~0^26~0^27~SUPPLY_TRANSACTION_NAME^30~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'DISP_MIN', 'Column', 'Contract Min.', '', 4, 0, '1~n (Numeric Edit)^2~0^3~###,###,##0.00^4~0^7~0^9~0^11~7^12~0^13~1^14~0^15~0^20~1^22~6^24~0^26~0^27~SUPPLY_TRANSACTION_NAME^30~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'FIXED_SCHEDULED', 'Column', 'Scheduled', '', 5, 0, '1~n (Numeric Edit)^2~0^3~###,###,##0.00^4~0^7~0^9~0^11~7^12~0^13~1^14~0^15~0^20~1^22~6^24~0^26~0^27~SUPPLY_TRANSACTION_NAME^30~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SUPPLY_PRICE', 'Column', 'Price', '', 6, 0, '1~n (Numeric Edit)^2~0^3~Currency^4~0^7~0^9~0^11~7^12~0^13~0^14~0^15~0^20~1^22~6^24~0^26~0^27~SUPPLY_TRANSACTION_NAME^30~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TOTAL_ASSIGNED', 'Column', 'Total Assigned', '', 7, 0, '2~0^4~0^7~0^9~0^11~7^12~0^13~0^14~0^15~0^20~0^22~6^24~0^25~IF (IS_FIXED, FIXED_TOTAL_ASSIGNED, DISP_SCHEDULED)^26~0^27~SUPPLY_TRANSACTION_NAME^30~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'FIXED_TOTAL_ASSIGNED', 'Column', '', '', 8, 1, '1~n (Numeric Edit)^2~0^3~###,###,##0.00^4~0^7~0^9~0^11~7^12~0^13~0^14~0^15~0^20~1^22~6^24~0^25~= FIXED_TOTAL_ASSIGNED_OLD - SUM ( ASSIGNED_AMOUNT_OLD ) + SUM ( ASSIGNED_AMOUNT )^26~0^30~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'DISP_SCHEDULED', 'Column', '', '', 9, 1, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~6^24~0^25~= DISP_SCHEDULED_OLD - SUM ( ASSIGNED_AMOUNT_OLD ) + SUM ( ASSIGNED_AMOUNT )^26~0^30~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'UNSCHEDULED', 'Column', 'Unassigned', '', 10, 0, '1~n (Numeric Edit)^2~0^3~###,###,##0.00^4~0^7~0^9~0^11~7^12~0^13~0^14~0^15~0^20~1^22~6^24~0^25~= MAX - TOTAL_ASSIGNED^26~0^27~SUPPLY_TRANSACTION_NAME^30~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'IS_FIXED', 'Column', '', '', 11, 1, '1~k (Checkbox)^2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~6^24~0^26~0^30~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SUPPLY_TRANSACTION_ID', 'Column', '', '', 12, 1, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~6^24~0^26~0^30~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SUPPLY_TRANSACTION_NAME', 'Column', '', '', 13, 1, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~7^24~0^26~0^30~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'FIXED_TOTAL_ASSIGNED_OLD', 'Column', '', '', 14, 1, '1~n (Numeric Edit)^2~0^3~###,###,##0.00^4~0^7~0^9~0^11~7^12~0^13~0^14~0^15~0^20~1^22~6^24~0^26~0^27~SUPPLY_TRANSACTION_NAME^30~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'DISP_SCHEDULED_OLD', 'Column', '', '', 15, 1, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~6^24~0^26~0^30~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'MAX', 'Column', '', '', 16, 1, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~6^24~0^25~IF (IS_FIXED, FIXED_SCHEDULED, DISP_MAX)^26~0^30~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'MIN', 'Column', '', '', 17, 1, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~6^24~0^25~IF (IS_FIXED, FIXED_SCHEDULED, DISP_MIN)^26~0^30~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TOTAL_LOAD', 'Column', '<html><center>Total<br>Load</center></html>', '', 18, 0, '1~n (Numeric Edit)^2~0^3~###,###,##0.00^4~0^7~0^9~0^11~7^12~0^13~0^14~0^15~0^20~1^22~6^24~0^25~= SUM(DEMAND_AMOUNT)^26~0^30~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TOTAL_IMBALANCE', 'Column', '<html><center>Total<br>Imbalance</center></html>', '', 19, 0, '1~n (Numeric Edit)^2~0^3~###,###,##0.00^4~0^7~0^9~0^11~7^12~0^13~0^14~0^15~0^20~1^22~6^24~0^25~= SUM(IMBALANCE)^26~0^30~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TOTAL_SUPPLY', 'Column', '<html><center>Total<br>Supply</center></html>', '', 20, 0, '1~n (Numeric Edit)^2~0^3~###,###,##0.00^4~0^7~0^9~0^11~7^12~0^13~0^14~0^15~0^20~1^22~6^24~0^25~=SUM(SUPPLY)^26~0^30~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'BALANCE_TRANSACTION_NAME', 'Column', '', '', 21, 0, '-3~0^-2~0^2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~2^24~0^26~0^30~0^31~0^32~1', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'BALANCE_TRANSACTION_ID', 'Column', '', '', 22, 0, '-3~0^-2~0^2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~4^24~0^26~0^30~0^31~0^32~1', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRANSACTION_ID', 'Column', '', '', 23, 1, '22~5^25~BALANCE_TRANSACTION_ID', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'DEMAND_AMOUNT', 'Column', 'Amount', '', 24, 0, '-3~0^-2~0^1~n (Numeric Edit)^2~0^3~###,###,##0.00^4~0^7~0^9~0^11~7^12~0^13~0^14~0^15~0^20~1^22~5^24~0^26~0^30~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SUPPLY', 'Column', 'Supply', '', 25, 0, '-3~0^-2~0^1~n (Numeric Edit)^2~0^3~###,###,##0.00^4~0^7~0^9~0^11~7^12~0^13~0^14~0^15~0^20~1^22~5^24~0^25~= SUPPLY_OLD - ASSIGNED_AMOUNT_OLD + ASSIGNED_AMOUNT^26~0^30~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SUPPLY_OLD', 'Column', 'Supply Old', '', 26, 1, '-3~0^-2~0^1~n (Numeric Edit)^2~0^3~###,###,##0.00^4~0^7~0^9~0^11~7^12~0^13~0^14~0^15~0^20~1^22~5^24~0^26~0^30~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'ASSIGNED_AMOUNT', 'Column', '<html><strong>Assigned</stong><html>', '', 27, 0, '-3~0^-2~0^1~n (Numeric Edit)^2~0^3~###,###,##0.00^4~0^7~0^9~0^11~7^12~0^13~0^14~0^15~0^19~= IF(LOAD_ASSIGNED_AMOUNT > LOAD_SCHEDULED_AMOUNT, "label:alertSupplySched","")^20~0^22~5^24~0^26~0^30~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'ASSIGNED_AMOUNT_OLD', 'Column', 'Assigned Old', '', 28, 1, '-3~0^-2~0^1~n (Numeric Edit)^2~0^3~###,###,###.00^4~0^7~0^9~0^11~7^12~0^13~0^14~0^15~0^20~1^22~5^24~0^26~0^30~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'IMBALANCE', 'Column', 'Imbalance', '', 29, 0, '-3~0^-2~0^1~n (Numeric Edit)^2~0^3~###,###,##0.00^4~0^7~0^9~0^11~7^12~0^13~0^14~0^15~0^20~1^22~5^24~0^25~= SUPPLY - DEMAND_AMOUNT^26~0^30~0^31~0', v_CHILD_OBJECT_ID);
            END;
             
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SUPPLY_TRANSACTION_ID', 'Report Filter', 'Supply Transactions', '', 0, 0, '501~s (Special List)^504~LB.BALANCE_SUPPLY_NAMES;BEGIN_DATE;END_DATE^508~0^514~0^515~0', v_CHILD_OBJECT_ID);
         END;
          
         <<L91>>
         DECLARE
            v_PARENT_OBJECT_ID NUMBER(9) := L86.v_OBJECT_ID;
            v_OBJECT_ID NUMBER(9);
         BEGIN
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'UNSCHEDULED_SUPPLY_REPORT', 'Report', 'Unscheduled Supply', '', 2, 0, '401~LB.GET_BALANCE_LOAD_REPORT;UPDATE_DEMAND=1^402~0^403~Normal Grid^405~0^406~0', v_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'UNSCHEDULED_SUPPLY_REPORT_CHART', 'Chart', 'Unscheduled Supply Chart', '', 0, 0, '901~0^902~Date^903~Amount^904~Unscheduled Supply^905~DEMAND_AMOUNT,TOTAL_SHORTFALL^907~1^908~0^910~0', v_CHILD_OBJECT_ID);
            <<L92>>
            DECLARE
               v_PARENT_OBJECT_ID NUMBER(9) := L91.v_OBJECT_ID;
               v_OBJECT_ID NUMBER(9);
            BEGIN
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'UNSCHEDULED_SUPPLY_REPORT_Grid', 'Grid', 'Unscheduled Suppply Report Grid', '', 0, 0, '-3~0^-2~0^301~LB.PUT_BALANCE_REPORT^305~0^307~Anchored^308~0^309~0', v_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SHOW_TRANSACTION', 'Action', 'Show Transaction...', '', 0, 0, '-3~0^-2~0^1004~not islist(TRANSACTION_ID)^1006~2^1007~Common.EntityManager;entityType="TRANSACTION";entityId=TRANSACTION_ID', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SCHEDULE_DATE', 'Column', 'Date', '', 0, 0, '2~0^4~0^7~0^9~0^11~1^12~0^13~0^14~0^15~0^20~0^22~1^24~1^26~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SCHEDULE_TIME', 'Column', 'Time', '', 1, 0, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~1^24~1^26~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'DEMAND_AMOUNT', 'Column', 'Amount', '', 2, 0, '1~n (Numeric Edit)^2~0^3~###,###,##0.00^4~0^7~0^9~0^11~7^12~0^13~0^14~0^15~0^20~1^22~6^24~0^25~DEMAND_AMOUNT_OLD - SUM(ASSIGNED_AMOUNT_OLD) + SUM(ASSIGNED_AMOUNT)^26~0^27~BALANCE_TRANSACTION_NAME^30~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'DEMAND_AMOUNT_OLD', 'Column', '', '', 3, 1, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~6^24~0^26~0^30~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'IMBALANCE_PRICE', 'Column', 'Price', '', 4, 0, '1~n (Numeric Edit)^2~0^3~Currency^4~0^7~0^9~0^11~7^12~0^13~0^14~0^15~0^20~1^22~6^24~0^26~0^27~BALANCE_TRANSACTION_NAME^30~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'REVENUE', 'Column', 'Revenue', '', 5, 0, '1~n (Numeric Edit)^2~0^3~Currency^4~0^7~0^9~0^11~7^12~0^13~0^14~0^15~0^20~1^22~6^24~0^25~= DEMAND_AMOUNT * IMBALANCE_PRICE^26~0^27~BALANCE_TRANSACTION_NAME^30~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'BALANCE_TRANSACTION_ID', 'Column', '', '', 6, 1, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~6^24~0^26~0^30~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'BALANCE_TRANSACTION_NAME', 'Column', '', '', 7, 1, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~7^24~0^26~0^30~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'UPDATE_DEMAND', 'Column', '', '', 8, 1, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~6^24~0^26~0^30~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TOTAL_SHORTFALL', 'Column', '', '', 9, 0, '2~0^4~0^7~0^9~0^11~7^12~0^13~0^14~0^15~0^20~0^22~6^24~0^25~SUM ( SHORTFALL )^26~0^30~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SUPPLY_TRANSACTION_NAME', 'Column', '', '', 10, 0, '-3~0^-2~0^2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~2^24~0^26~0^30~0^31~0^32~1', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SUPPLY_TRANSACTION_ID', 'Column', '', '', 11, 0, '-3~0^-2~0^2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~4^24~0^26~0^30~0^31~0^32~1', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRANSACTION_ID', 'Column', '', '', 12, 1, '22~5^25~SUPPLY_TRANSACTION_ID', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'DISP_MAX', 'Column', 'Contract Limit', '', 13, 0, '-3~0^-2~0^1~n (Numeric Edit)^2~0^3~###,###,##0.00^4~0^7~0^9~0^11~7^12~0^13~1^14~0^15~0^20~1^22~5^24~0^26~0^30~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'DISP_MIN', 'Column', 'Contract Min.', '', 14, 0, '-3~0^-2~0^1~n (Numeric Edit)^2~0^3~###,###,##0.00^4~0^7~0^9~0^11~7^12~0^13~1^14~0^15~0^20~1^22~5^24~0^26~0^30~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'FIXED_SCHEDULED', 'Column', 'Scheduled', '', 15, 0, '-3~0^-2~0^2~0^3~###,###,##0.00^4~0^7~0^9~0^11~7^12~0^13~1^14~0^15~0^20~1^22~5^24~0^26~0^30~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TOTAL_ASSIGNED', 'Column', 'Total Assigned', '', 16, 0, '-3~0^-2~0^2~0^4~0^7~0^9~0^11~7^12~0^13~0^14~0^15~0^20~1^22~5^24~0^25~IF ( IS_FIXED, FIXED_TOTAL_ASSIGNED, DISP_SCHEDULED )^26~0^30~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'DISP_SCHEDULED', 'Column', '', '', 17, 1, '-3~0^-2~0^2~0^3~###,###,##0.00^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~5^24~0^25~DISP_SCHEDULED_OLD - ASSIGNED_AMOUNT_OLD + ASSIGNED_AMOUNT^26~0^30~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'FIXED_TOTAL_ASSIGNED', 'Column', '', '', 18, 1, '-3~0^-2~0^2~0^3~###,###,##0.00^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~5^24~0^25~FIXED_TOTAL_ASSIGNED_OLD - ASSIGNED_AMOUNT_OLD + ASSIGNED_AMOUNT^26~0^30~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SHORTFALL', 'Column', '', '', 19, 0, '-3~0^-2~0^2~0^4~0^7~0^9~0^11~7^12~0^13~0^14~0^15~0^20~1^22~5^24~0^25~MAX ( 0, MIN - TOTAL_ASSIGNED )^26~0^30~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SUPPLY_PRICE', 'Column', 'Price', '', 20, 0, '-3~0^-2~0^1~n (Numeric Edit)^2~0^3~Currency^4~0^7~0^9~0^11~7^12~0^13~0^14~0^15~0^20~1^22~5^24~0^26~0^30~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'ASSIGNED_AMOUNT', 'Column', '<html><strong>Assigned</strong></html>', '', 21, 0, '-3~0^-2~0^1~n (Numeric Edit)^2~0^3~###,###,##0.00^4~0^7~0^9~0^11~7^12~0^13~0^14~0^15~0^19~=IF (TOTAL_ASSIGNED_OLD-ASSIGNED_AMOUNT_OLD+ASSIGNED_AMOUNT > MAX, "label:alertAssignedHigh", IF ( ASSIGNED_AMOUNT < 0, "label:alertAssignedLow", "") )^20~0^22~5^24~0^26~0^30~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'ASSIGNED_AMOUNT_OLD', 'Column', '', '', 22, 1, '-3~0^-2~0^2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~5^24~0^26~0^30~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'COST', 'Column', 'Cost', '', 23, 0, '1~n (Numeric Edit)^2~0^3~Currency^4~0^7~0^9~0^11~7^12~0^13~0^14~0^15~0^20~1^22~5^24~0^25~= SUPPLY_PRICE * ASSIGNED_AMOUNT^26~0^30~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'IS_FIXED', 'Column', '', '', 24, 1, '1~k (Checkbox)^2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~5^24~0^26~0^30~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'FIXED_TOTAL_ASSIGNED_OLD', 'Column', '', '', 25, 1, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~5^24~0^26~0^30~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'DISP_SCHEDULED_OLD', 'Column', '', '', 26, 1, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~5^24~0^26~0^30~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TOTAL_ASSIGNED_OLD', 'Column', '', '', 27, 1, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~5^24~0^25~IF ( IS_FIXED, FIXED_TOTAL_ASSIGNED_OLD, DISP_SCHEDULED_OLD )^26~0^30~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'MAX', 'Column', '', '', 28, 1, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~5^24~0^25~IF ( IS_FIXED, FIXED_SCHEDULED, DISP_MAX )^26~0^30~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'MIN', 'Column', '', '', 29, 1, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~5^24~0^25~IF ( IS_FIXED, FIXED_SCHEDULED, DISP_MIN )^26~0^30~0^31~0', v_CHILD_OBJECT_ID);
            END;
             
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'BALANCE_TRANSACTION_ID', 'Report Filter', 'Sale Transaction', '', 0, 0, '501~s (Special List)^504~LB.BALANCE_SALE_NAMES;BEGIN_DATE;END_DATE^508~0^514~0^515~0', v_CHILD_OBJECT_ID);
         END;
          
         <<L93>>
         DECLARE
            v_PARENT_OBJECT_ID NUMBER(9) := L86.v_OBJECT_ID;
            v_OBJECT_ID NUMBER(9);
         BEGIN
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'DEAL_EVAL_REPORT', 'Report', 'Deal Evaluation', '', 3, 0, '401~LB.GET_DEAL_EVAL_SUMMARY^402~0^403~Lazy Master/Detail Grids^404~LB.GET_DEAL_EVAL_DETAILS^405~0^406~0^409~Vertical', v_OBJECT_ID);
            <<L94>>
            DECLARE
               v_PARENT_OBJECT_ID NUMBER(9) := L93.v_OBJECT_ID;
               v_OBJECT_ID NUMBER(9);
            BEGIN
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'DEAL_EVAL_REPORT_Grid_DETAIL', 'Grid', 'Deal Eval Report Grid Detail', '', 0, 0, '305~0^308~0^309~0', v_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SCHEDULE_DATE', 'Column', '', '', 0, 0, '', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'LOAD', 'Column', '', '', 1, 0, '', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'COMMITTED_SUPPLY', 'Column', '', '', 2, 0, '', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'COMMITTED_COST', 'Column', '', '', 3, 0, '', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'DYNAMIC_SCHEDULE', 'Column', '', '', 4, 0, '', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'DYNAMIC_COST', 'Column', '', '', 5, 0, '', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'EVAL_SCHEDULE', 'Column', '', '', 6, 0, '', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'EVAL_COST', 'Column', '', '', 7, 0, '', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TOTAL_SUPPLY_COST', 'Column', '', '', 8, 0, '25~COMMITTED_COST+DYNAMIC_COST+EVAL_COST', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'WACOG', 'Column', 'WACOG', '', 9, 0, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^25~EVAL ( IF ( TOTAL_SUPPLY = 0, """""", "TOTAL_SUPPLY_COST/TOTAL_SUPPLY") )^26~0^30~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'REMAINING_IMBALANCE', 'Column', '', '', 10, 0, '25~LOAD - TOTAL_SUPPLY', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TOTAL_SUPPLY', 'Column', '', '', 11, 1, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^25~COMMITTED_SUPPLY+DYNAMIC_SCHEDULE+EVAL_SCHEDULE^26~0^30~0^31~0', v_CHILD_OBJECT_ID);
            END;
             
            <<L95>>
            DECLARE
               v_PARENT_OBJECT_ID NUMBER(9) := L93.v_OBJECT_ID;
               v_OBJECT_ID NUMBER(9);
            BEGIN
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'DEAL_EVAL_REPORT_Grid_MASTER', 'Grid', 'Deal Eval Report Grid Master', '', 0, 0, '305~0^308~0^309~0', v_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'ORDER_BY', 'Column', '', '', 0, 1, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0^30~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SUPPLY_TRANSACTION_NAME', 'Column', 'Supply Deal', '', 1, 0, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0^30~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SUPPLY_TRANSACTION_ID', 'Column', '', '', 2, 1, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0^30~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'EVALUATE', 'Column', '', '', 3, 0, '1~k (Checkbox)^2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0^30~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'BEGIN_DATE', 'Column', '', '', 4, 0, '', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'END_DATE', 'Column', '', '', 5, 0, '', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TOTAL_COST', 'Column', '', '', 6, 0, '', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'WACOG', 'Column', 'WACOG', '', 7, 0, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0^30~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'REMAINING_IMBALANCE', 'Column', '', '', 8, 0, '', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'LAST_EVALUATED', 'Column', '', '', 9, 0, '', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'STATUS', 'Column', '', '', 10, 0, '', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'NOTES', 'Column', '', '', 11, 0, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^19~IF ( LENGTH(STATUS) = 0, "lbl:alertNoNotes", "")^20~0^22~0^24~0^26~0^30~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'LOAD_TRANSACTION_ID', 'Column', '', '', 12, 1, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0^30~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'DYNAMIC_TRANSACTION_ID', 'Column', '', '', 13, 1, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0^30~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'CUT_BEGIN_DATE', 'Column', '', '', 14, 1, '', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'CUT_END_DATE', 'Column', '', '', 15, 1, '', v_CHILD_OBJECT_ID);
            END;
             
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'LOAD_TRANSACTION_ID', 'Report Filter', 'Load Transaction', '', 0, 0, '501~s (Special List)^504~LB.BALANCE_TRANSACTION_NAMES;BEGIN_DATE;END_DATE', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'DYNAMIC_TRANSACTION_ID', 'Report Filter', 'Dynamic Transaction', '', 1, 0, '501~s (Special List)^504~LB.GET_DYNAMIC_SCHEDULE_LIST;BEGIN_DATE;END_DATE;LOAD_TRANSACTION_ID', v_CHILD_OBJECT_ID);
         END;
          
      END;
       
      -------------------------------------
      --   Scheduling.BidOfferFill
      -------------------------------------
      <<L96>>
      DECLARE
         v_PARENT_OBJECT_ID NUMBER(9) := L0.v_OBJECT_ID;
         v_OBJECT_ID NUMBER(9);
      BEGIN
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'Scheduling.BidOfferFill', 'System View', 'Scheduling.Bidofferfill', '', 0, 0, '801~com.newenergyassoc.ro.scheduling.bao.fill.BidsAndOffersFillContentPanel', v_OBJECT_ID);
         <<L97>>
         DECLARE
            v_PARENT_OBJECT_ID NUMBER(9) := L96.v_OBJECT_ID;
            v_OBJECT_ID NUMBER(9);
         BEGIN
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'BOF_PQ_GRID', 'Grid', 'BOF_PQ_GRID', '', 0, 0, '', v_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'BEGIN_HOUR', 'Column', 'Begin Hour', '', 1, 0, '1~n (Numeric Edit)', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'END_HOUR', 'Column', 'End Hour', '', 2, 0, '1~n (Numeric Edit)', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'Q1', 'Column', '', '', 3, 0, '1~n (Numeric Edit)', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'P1', 'Column', '', '', 4, 0, '1~n (Numeric Edit)', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'Q2', 'Column', '', '', 5, 0, '1~n (Numeric Edit)', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'P2', 'Column', '', '', 6, 0, '1~n (Numeric Edit)', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'Q3', 'Column', '', '', 7, 0, '1~n (Numeric Edit)', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'P3', 'Column', '', '', 8, 0, '1~n (Numeric Edit)', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'Q4', 'Column', '', '', 9, 0, '1~n (Numeric Edit)', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'P4', 'Column', '', '', 10, 0, '1~n (Numeric Edit)', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'Q5', 'Column', '', '', 11, 0, '1~n (Numeric Edit)', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'P5', 'Column', '', '', 12, 0, '1~n (Numeric Edit)', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'Q6', 'Column', '', '', 13, 0, '1~n (Numeric Edit)', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'P6', 'Column', '', '', 14, 0, '1~n (Numeric Edit)', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'Q7', 'Column', '', '', 15, 0, '1~n (Numeric Edit)', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'P7', 'Column', '', '', 16, 0, '1~n (Numeric Edit)', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'Q8', 'Column', '', '', 17, 0, '1~n (Numeric Edit)', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'P8', 'Column', '', '', 18, 0, '1~n (Numeric Edit)', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'Q9', 'Column', '', '', 19, 0, '1~n (Numeric Edit)', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'P9', 'Column', '', '', 20, 0, '1~n (Numeric Edit)', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'Q10', 'Column', '', '', 21, 0, '1~n (Numeric Edit)', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'P10', 'Column', '', '', 22, 0, '1~n (Numeric Edit)', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'Q11', 'Column', '', '', 23, 0, '1~n (Numeric Edit)', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'P11', 'Column', '', '', 24, 0, '1~n (Numeric Edit)', v_CHILD_OBJECT_ID);
         END;
          
         <<L98>>
         DECLARE
            v_PARENT_OBJECT_ID NUMBER(9) := L96.v_OBJECT_ID;
            v_OBJECT_ID NUMBER(9);
         BEGIN
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'BOF_RR_GRID', 'Grid', 'BOF_RR_GRID', '', 0, 0, '', v_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'BEGIN_HOUR', 'Column', 'Begin Hour', '', 1, 0, '1~n (Numeric Edit)', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'END_HOUR', 'Column', 'End Hour', '', 2, 0, '1~n (Numeric Edit)', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'RQ1', 'Column', '', '', 3, 0, '1~n (Numeric Edit)', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'RU1', 'Column', '', '', 4, 0, '1~n (Numeric Edit)', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'RD1', 'Column', '', '', 5, 0, '1~n (Numeric Edit)', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'RQ2', 'Column', '', '', 6, 0, '1~n (Numeric Edit)', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'RU2', 'Column', '', '', 7, 0, '1~n (Numeric Edit)', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'RD2', 'Column', '', '', 8, 0, '1~n (Numeric Edit)', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'RQ3', 'Column', '', '', 9, 0, '1~n (Numeric Edit)', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'RU3', 'Column', '', '', 10, 0, '1~n (Numeric Edit)', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'RD3', 'Column', '', '', 11, 0, '1~n (Numeric Edit)', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'RQ4', 'Column', '', '', 12, 0, '1~n (Numeric Edit)', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'RU4', 'Column', '', '', 13, 0, '1~n (Numeric Edit)', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'RD4', 'Column', '', '', 14, 0, '1~n (Numeric Edit)', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'RQ5', 'Column', '', '', 15, 0, '1~n (Numeric Edit)', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'RU5', 'Column', '', '', 16, 0, '1~n (Numeric Edit)', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'RD5', 'Column', '', '', 17, 0, '1~n (Numeric Edit)', v_CHILD_OBJECT_ID);
         END;
          
      END;
       
      -------------------------------------
      --   Scheduling.BidOfferSubmit
      -------------------------------------
      <<L99>>
      DECLARE
         v_PARENT_OBJECT_ID NUMBER(9) := L0.v_OBJECT_ID;
         v_OBJECT_ID NUMBER(9);
      BEGIN
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'Scheduling.BidOfferSubmit', 'System View', 'Scheduling.Bidoffersubmit', '', 0, 0, '801~com.newenergyassoc.ro.scheduling.bao.submit.BidOfferSubmitContentPanel', v_OBJECT_ID);
         <<L100>>
         DECLARE
            v_PARENT_OBJECT_ID NUMBER(9) := L99.v_OBJECT_ID;
            v_OBJECT_ID NUMBER(9);
         BEGIN
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'BID_OFFER_SUBMIT_HOURS_GRID', 'Grid', 'Bid Offer Submit Hours Grid', '', 0, 0, '305~0^308~0^309~1', v_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'HOUR1', 'Column', '1', '', 0, 0, '1~k (Checkbox)^2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'HOUR2', 'Column', '2', '', 1, 0, '1~k (Checkbox)^2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'HOUR2D', 'Column', '2d', '', 2, 0, '1~k (Checkbox)^2~0^4~0^7~0^9~0^11~0^12~0^13~1^14~0^15~0^20~0^22~0^24~0^26~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'HOUR3', 'Column', '3', '', 3, 0, '1~k (Checkbox)^2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'HOUR4', 'Column', '4', '', 4, 0, '1~k (Checkbox)^2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'HOUR5', 'Column', '5', '', 5, 0, '1~k (Checkbox)^2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'HOUR6', 'Column', '6', '', 6, 0, '1~k (Checkbox)^2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'HOUR7', 'Column', '7', '', 7, 0, '1~k (Checkbox)^2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'HOUR8', 'Column', '8', '', 8, 0, '1~k (Checkbox)^2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'HOUR9', 'Column', '9', '', 9, 0, '1~k (Checkbox)^2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'HOUR10', 'Column', '10', '', 10, 0, '1~k (Checkbox)^2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'HOUR11', 'Column', '11', '', 11, 0, '1~k (Checkbox)^2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'HOUR12', 'Column', '12', '', 12, 0, '1~k (Checkbox)^2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'HOUR13', 'Column', '13', '', 13, 0, '1~k (Checkbox)^2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'HOUR14', 'Column', '14', '', 14, 0, '1~k (Checkbox)^2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'HOUR15', 'Column', '15', '', 15, 0, '1~k (Checkbox)^2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'HOUR16', 'Column', '16', '', 16, 0, '1~k (Checkbox)^2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'HOUR17', 'Column', '17', '', 17, 0, '1~k (Checkbox)^2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'HOUR18', 'Column', '18', '', 18, 0, '1~k (Checkbox)^2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'HOUR19', 'Column', '19', '', 19, 0, '1~k (Checkbox)^2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'HOUR20', 'Column', '20', '', 20, 0, '1~k (Checkbox)^2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'HOUR21', 'Column', '21', '', 21, 0, '1~k (Checkbox)^2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'HOUR22', 'Column', '22', '', 22, 0, '1~k (Checkbox)^2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'HOUR23', 'Column', '23', '', 23, 0, '1~k (Checkbox)^2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'HOUR24', 'Column', '24', '', 24, 0, '1~k (Checkbox)^2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0', v_CHILD_OBJECT_ID);
         END;
          
      END;
       
      -------------------------------------
      --   Scheduling.BidsNOffers
      -------------------------------------
      <<L101>>
      DECLARE
         v_PARENT_OBJECT_ID NUMBER(9) := L0.v_OBJECT_ID;
         v_OBJECT_ID NUMBER(9);
      BEGIN
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'Scheduling.BidsNOffers', 'System View', 'Scheduling.Bidsnoffers', '', 0, 0, '-3~0^-2~0^801~com.newenergyassoc.ro.scheduling.bao.BidsAndOffersContentPanel', v_OBJECT_ID);
         <<L102>>
         DECLARE
            v_PARENT_OBJECT_ID NUMBER(9) := L101.v_OBJECT_ID;
            v_OBJECT_ID NUMBER(9);
         BEGIN
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'DETAILED_TRAIT_REPORT', 'Report', 'Summary', '', 1, 1, '-3~0^-2~0^401~TG.GET_IT_TRAIT_SCHED_DETAIL_RPT;SCHEDULE_STATE=1;TRAIT_GROUP_FILTER="Detail";INTERVAL="<Offer>"^402~0^403~Normal Grid^405~0^406~0', v_OBJECT_ID);
            <<L103>>
            DECLARE
               v_PARENT_OBJECT_ID NUMBER(9) := L102.v_OBJECT_ID;
               v_OBJECT_ID NUMBER(9);
            BEGIN
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'DETAILED_TRAIT_REPORT_Grid_DETAIL', 'Grid', 'Detailed Trait Report Grid Detail', '', 0, 0, '-3~0^-2~0^301~TG.PUT_IT_TRAIT_SCHED_DETAIL_RPT^305~0^307~ResourceTrait^308~1^309~0', v_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'BID_OFFER_ACTION', 'Action', 'Bid/Offer Actions...', '', 0, 0, '-3~0^-2~0^-1~BID_OFFER_SUBMIT_ACTION', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'EDIT_BID_CURVE', 'Action', 'Curve Editor...', '', 1, 0, '-3~0^-2~0^-1~BID_CURVE_EDITOR_ACTION', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'CUT_DATE_SCHEDULING', 'Column', 'CUT_DATE_SCHEDULING', '', 0, 1, '1~x (No Edit)^2~0^3~Short Date^4~7^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~6^24~0^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SCHEDULE_DATE_STR', 'Column', 'Date', '', 0, 0, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~1^24~1^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'PRICE', 'Column', '', '', 1, 0, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~1^22~1^24~1^26~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'AMOUNT', 'Column', 'Quantity', '', 2, 0, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~1^22~1^24~1^26~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'REVIEW_STATUS', 'Column', 'Review', '', 3, 0, '2~0^4~0^7~0^9~0^11~1^12~0^13~0^14~0^15~0^20~1^22~6^24~0^26~0^28~BidOfferStatus^29~X=REVIEW_STATUS^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SUBMIT_STATUS', 'Column', 'Submit', '', 4, 0, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~1^22~6^24~0^26~0^28~BidOfferStatus^29~X=SUBMIT_STATUS^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'MARKET_STATUS', 'Column', 'Market', '', 5, 0, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~1^22~6^24~0^26~0^28~BidOfferStatus^29~X=MARKET_STATUS^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'REASON_FOR_CHANGE', 'Column', '', '', 6, 1, '1~e (Standard Edit)^2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~6^24~0^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'OTHER_REASON', 'Column', 'Notes', '', 7, 0, '1~e (Standard Edit)^2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~6^24~0^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'PROCESS_MESSAGE', 'Column', 'Market Response', '', 8, 0, '-3~0^-2~0^1~b (Big Text Edit)^2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~1^22~6^24~0^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'GROUP_ORDER', 'Column', '', '', 9, 0, '22~4', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SET_NUMBER', 'Column', '', '', 10, 0, '-3~0^-2~0^2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~4^24~0^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRAIT_ORDER', 'Column', '', '', 11, 0, '22~4', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRAIT_GROUP_ID', 'Column', '', '', 12, 0, '-3~0^-2~0^2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~4^24~0^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRAIT_INDEX', 'Column', '', '', 13, 0, '-3~0^-2~0^2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~4^24~0^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRAIT_GROUP_NAME', 'Column', '', '', 14, 0, '-3~0^-2~0^2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~2^24~0^26~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'DISPLAY_NAME', 'Column', '', '', 15, 0, '-3~0^-2~0^2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~2^24~0^26~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRAIT_VAL', 'Column', '', '', 16, 0, '-3~0^-2~0^1~e (Standard Edit)^2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~5^24~0^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'DATA_TYPE', 'Column', '', '', 17, 0, '-3~0^-2~0^2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'EDIT_MASK', 'Column', '', '', 18, 0, '-3~0^-2~0^2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'COMBO_LIST', 'Column', '', '', 19, 0, '-3~0^-2~0^2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'FORMAT', 'Column', '', '', 20, 0, '-3~0^-2~0^2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TG.GET_BID_CURVE_EDITOR', 'Grid', '', '', 0, 0, '-1~Scheduling.BidCurveEditorGrid', v_CHILD_OBJECT_ID);
            END;
             
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRANSACTION_ID', 'Report Filter', 'Transaction ID', '', 0, 0, '501~x (Custom)^508~0^512~com.newenergyassoc.ro.scheduling.bao.BidsAndOffersTreeFilterComponent^513~1^514~1^515~1', v_CHILD_OBJECT_ID);
         END;
          
         <<L104>>
         DECLARE
            v_PARENT_OBJECT_ID NUMBER(9) := L101.v_OBJECT_ID;
            v_OBJECT_ID NUMBER(9);
         BEGIN
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'STANDARD_TRAIT_REPORT', 'Report', 'Offer Details', '', 2, 0, '-3~0^-2~0^401~TG.GET_IT_TRAIT_SCHED_TRAIT_RPT;SCHEDULE_STATE=1;TRAIT_GROUP_FILTER="%"^402~0^403~Normal Grid^405~0^406~0', v_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'STANDARD_TRAIT_REPORT_Grid_DETAIL', 'Grid', '', '', 0, 0, '-3~0^-2~0^-1~Scheduling.TraitDetailsGrid^305~0^308~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'STANDARD_TRAIT_REPORT_Grid_SUMMARY', 'Grid', '', '', 0, 0, '', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'INTERVAL', 'Report Filter', 'Interval', '', 0, 0, '-3~0^-2~0^501~c (Combo Box)^502~<Offer>|Hour|Day|Month|Year|30 Minute^508~0^514~0^515~0^519~0^520~0^521~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRANSACTION_ID', 'Report Filter', 'Transaction Id', '', 1, 0, '501~x (Custom)^508~0^512~com.newenergyassoc.ro.scheduling.bao.BidsAndOffersTreeFilterComponent^513~1^514~1^515~1', v_CHILD_OBJECT_ID);
         END;
          
         <<L105>>
         DECLARE
            v_PARENT_OBJECT_ID NUMBER(9) := L101.v_OBJECT_ID;
            v_OBJECT_ID NUMBER(9);
         BEGIN
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'SPARSE_TRAIT_REPORT', 'Report', 'Sparse Data', '', 3, 0, '-3~0^-2~0^401~TG.GET_IT_TRAIT_SCHED_SPARSE_RPT;SCHEDULE_STATE=1;TRAIT_GROUP_FILTER="%"^402~0^403~Normal Grid^405~0^406~0', v_OBJECT_ID);
            <<L106>>
            DECLARE
               v_PARENT_OBJECT_ID NUMBER(9) := L105.v_OBJECT_ID;
               v_OBJECT_ID NUMBER(9);
            BEGIN
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'SPARSE_TRAIT_REPORT_Grid_DETAIL', 'Grid', 'Sparse Trait Report Grid Detail', '', 0, 0, '-3~0^-2~0^301~TG.PUT_IT_TRAIT_SCHED_SPARSE_RPT^305~1^308~0^309~0', v_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'BID_OFFER_ACTION', 'Action', 'Bid/Offer Actions', '', 0, 0, '-1~BID_OFFER_SUBMIT_ACTION', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SCHEDULE_DATE', 'Column', 'Start Date', '', 0, 0, '1~d (Date Picker)^2~0^4~7^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SCHEDULE_TIME', 'Column', 'Time', '', 1, 0, '1~e (Standard Edit)^2~0^4~0^6~##:##^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^23~24:24^24~0^26~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SCHEDULE_END_DATE', 'Column', 'End Date', '', 2, 0, '1~d (Date Picker)^2~0^4~7^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SCHEDULE_END_TIME', 'Column', 'Time', '', 3, 0, '1~e (Standard Edit)^2~0^4~0^6~##:##^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^23~24:24^24~0^26~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRAIT_GROUP_INDEX_ID', 'Column', 'Trait Name', '', 4, 0, '1~s (Special List)^2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^16~TG.TRAIT_GROUP_INDEX_LIST_SPARSE;TRANSACTION_ID;"%^20~0^22~0^24~0^26~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRAIT_GROUP_INDEX_NAME', 'Column', '', '', 5, 1, '1~x (No Edit)^2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^23~MISO DEFAULT DISPATCH MINIMUM^24~0^26~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SET_NUMBER', 'Column', '', '', 6, 0, '1~n (Numeric Edit)^2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'DATA_TYPE', 'Column', '', '', 7, 1, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'EDIT_MASK', 'Column', '', '', 8, 1, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'COMBO_LIST', 'Column', '', '', 9, 1, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'FORMAT', 'Column', '', '', 10, 1, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRAIT_VAL', 'Column', 'Value', '', 11, 0, '1~e (Standard Edit)^2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'ORIG_SCHEDULE_DATE', 'Column', '', '', 12, 1, '2~0^4~7^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0', v_CHILD_OBJECT_ID);
            END;
             
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRANSACTION_ID', 'Report Filter', 'Transaction ID', '', 0, 0, '501~x (Custom)^508~0^512~com.newenergyassoc.ro.scheduling.bao.BidsAndOffersTreeFilterComponent^513~1^514~1^515~1', v_CHILD_OBJECT_ID);
         END;
          
         <<L107>>
         DECLARE
            v_PARENT_OBJECT_ID NUMBER(9) := L101.v_OBJECT_ID;
            v_OBJECT_ID NUMBER(9);
         BEGIN
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'DETAILED_COMPARE_REPORT', 'Report', 'Comparison', '', 4, 0, '-3~0^-2~0^401~TG.GET_IT_TRAIT_SCHED_TRAIT_RPT;SCHEDULE_STATE=1;TRAIT_GROUP_FILTER="%"^402~0^403~Comparison Grids^404~TG.GET_IT_TRAIT_SCHED_TRAIT_RPT;SCHEDULE_STATE=2;TRAIT_GROUP_FILTER="%"^405~0^406~0^410~SCHEDULE_DATE_STR', v_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'DETAILED_COMPARE_REPORT_Grid', 'Grid', 'Internal', '', 1, 0, '-3~0^-2~1^-1~Scheduling.TraitDetailsGrid^305~0^308~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'DETAILED_COMPARE_REPORT_Grid_COMPARE', 'Grid', 'External', '', 2, 0, '-3~0^-2~1^-1~Scheduling.TraitDetailsExternalGrid^305~0^308~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'INTERVAL', 'Report Filter', 'Interval', '', 1, 0, '-3~0^-2~0^501~c (Combo Box)^502~<Offer>|Hour|Day|Month|Year|30 Minute^508~0^514~0^515~0^519~0^520~0^521~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRANSACTION_ID', 'Report Filter', 'Transaction ID', '', 2, 0, '-3~0^-2~0^501~x (Custom)^508~0^512~com.newenergyassoc.ro.scheduling.bao.BidsAndOffersTreeFilterComponent^513~1^514~0^515~1^519~0^520~0^521~0', v_CHILD_OBJECT_ID);
         END;
          
         <<L108>>
         DECLARE
            v_PARENT_OBJECT_ID NUMBER(9) := L101.v_OBJECT_ID;
            v_OBJECT_ID NUMBER(9);
         BEGIN
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'SPARSE_COMPARE_REPORT', 'Report', 'Sparse Comparison', '', 5, 1, '-3~0^-2~0^401~TG.GET_IT_TRAIT_SCHED_SPARSE_RPT;SCHEDULE_STATE=1;TRAIT_GROUP_FILTER="%"^402~0^403~Comparison Grids^404~TG.GET_IT_TRAIT_SCHED_SPARSE_RPT;SCHEDULE_STATE=2;TRAIT_GROUP_FILTER="%"^405~0^406~0', v_OBJECT_ID);
            <<L109>>
            DECLARE
               v_PARENT_OBJECT_ID NUMBER(9) := L108.v_OBJECT_ID;
               v_OBJECT_ID NUMBER(9);
            BEGIN
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'SPARSE_COMPARE_REPORT_Grid', 'Grid', 'Internal', '', 0, 0, '-3~0^-2~0^301~TG.PUT_IT_TRAIT_SCHED_SPARSE_RPT^305~1^308~0^309~0', v_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'BID_OFFER_SUBMIT_ACTION', 'Action', 'Bid/Offer Actions...', '', 0, 0, '-1~BID_OFFER_SUBMIT_ACTION', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SCHEDULE_DATE', 'Column', 'Start Date', '', 0, 0, '1~d (Date Picker)^2~0^4~7^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SCHEDULE_TIME', 'Column', 'Time', '', 1, 0, '2~0^4~0^6~##:##^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^23~24:24^24~0^26~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SCHEDULE_END_DATE', 'Column', 'End Date', '', 2, 0, '1~d (Date Picker)^2~0^4~7^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SCHEDULE_END_TIME', 'Column', 'Time', '', 3, 0, '2~0^4~0^6~##:##^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^23~24:24^24~0^26~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRAIT_GROUP_INDEX_ID', 'Column', 'Trait Name', '', 4, 0, '1~s (Special List)^2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^16~TG.TRAIT_GROUP_INDEX_LIST_SPARSE;TRANSACTION_ID;"%^20~0^22~0^24~0^26~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRAIT_GROUP_INDEX_NAME', 'Column', '', '', 5, 1, '1~x (No Edit)^2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^23~MISO DEFAULT DISPATCH MINIMUM^24~0^26~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SET_NUMBER', 'Column', '', '', 6, 0, '1~n (Numeric Edit)^2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'DATA_TYPE', 'Column', '', '', 7, 1, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'EDIT_MASK', 'Column', '', '', 8, 1, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'COMBO_LIST', 'Column', '', '', 9, 1, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'FORMAT', 'Column', '', '', 10, 1, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRAIT_VAL', 'Column', 'Value', '', 11, 0, '1~e (Standard Edit)^2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'ORIG_SCHEDULE_DATE', 'Column', '', '', 12, 1, '2~0^4~7^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0', v_CHILD_OBJECT_ID);
            END;
             
            <<L110>>
            DECLARE
               v_PARENT_OBJECT_ID NUMBER(9) := L108.v_OBJECT_ID;
               v_OBJECT_ID NUMBER(9);
            BEGIN
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'SPARSE_COMPARE_REPORT_Grid_COMPARE', 'Grid', 'External', '', 0, 0, '-3~0^-2~0^301~TG.PUT_IT_TRAIT_SCHED_SPARSE_RPT^305~1^308~0^309~0', v_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'BID_OFFER_ACTION', 'Action', 'Bid/Offer Actions...', '', 0, 0, '-1~BID_OFFER_SUBMIT_ACTION', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SCHEDULE_DATE', 'Column', 'Start Date', '', 0, 0, '1~d (Date Picker)^2~0^4~7^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SCHEDULE_TIME', 'Column', 'Time', '', 1, 0, '2~0^4~0^6~##:##^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^23~24:24^24~0^26~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SCHEDULE_END_DATE', 'Column', 'End Date', '', 2, 0, '1~d (Date Picker)^2~0^4~7^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SCHEDULE_END_TIME', 'Column', 'Time', '', 3, 0, '2~0^4~0^6~##:##^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^23~24:24^24~0^26~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRAIT_GROUP_INDEX_ID', 'Column', 'Trait Name', '', 4, 0, '1~s (Special List)^2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^16~TG.TRAIT_GROUP_INDEX_LIST_SPARSE;TRANSACTION_ID;"%^20~0^22~0^24~0^26~0', v_CHILD_OBJECT_ID);
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
          
         <<L111>>
         DECLARE
            v_PARENT_OBJECT_ID NUMBER(9) := L101.v_OBJECT_ID;
            v_OBJECT_ID NUMBER(9);
         BEGIN
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'STATUS_REPORT', 'Report', 'Status Details', '', 6, 0, '-3~0^-2~0^401~BO.BID_OFFER_STATUS_REPORT^402~0^406~0', v_OBJECT_ID);
            <<L112>>
            DECLARE
               v_PARENT_OBJECT_ID NUMBER(9) := L111.v_OBJECT_ID;
               v_OBJECT_ID NUMBER(9);
            BEGIN
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'STATUS_REPORT_Grid_DETAIL', 'Grid', 'Status Report Grid Detail', '', 0, 0, '-3~0^-2~0^301~BO.PUT_BID_OFFER_STATUS_REASON^305~0^308~0^309~0', v_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'BID_OFFER_ACTION', 'Action', 'Bid/Offer Actions...', '', 0, 0, '-1~BID_OFFER_SUBMIT_ACTION', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRANSACTION_NAME', 'Column', '', '', 0, 1, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~1^22~0^24~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SCHEDULE_DATE', 'Column', 'Schedule Date', '', 1, 0, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~1^22~0^24~1^26~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'CREATE_DATE', 'Column', 'Create Date', '', 2, 0, '1~d (Date Picker)^2~0^3~Short Date^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~1^22~0^24~0^26~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'REVIEW_STATUS', 'Column', '', '', 3, 0, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~1^22~0^24~0^26~0^28~BidOfferStatus^29~X=REVIEW_STATUS^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'REVIEW_DATE', 'Column', '', '', 4, 0, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~1^22~0^24~0^26~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'REVIEWED_BY', 'Column', '', '', 5, 0, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~1^22~0^24~0^26~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SUBMIT_STATUS', 'Column', 'Submit Status', '', 6, 0, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~1^22~0^24~0^28~BidOfferStatus^29~X=SUBMIT_STATUS^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SUBMIT_DATE', 'Column', 'Submit Date', '', 7, 0, '1~d (Date Picker)^2~0^3~Short Date^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~1^22~0^24~0^26~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SUBMITTED_BY', 'Column', 'Submitted By', '', 8, 0, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~1^22~0^24~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'MARKET_STATUS', 'Column', 'Market Status', '', 9, 0, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~1^22~0^24~0^28~BidOfferStatus^29~X=MARKET_STATUS^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'MARKET_STATUS_DATE', 'Column', 'Market Status Date', '', 10, 0, '1~d (Date Picker)^2~0^3~Short Date^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~1^22~0^24~0^26~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'REASON_FOR_CHANGE', 'Column', 'Reason for Change', '', 11, 0, '1~e (Standard Edit)^2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'OTHER_REASON', 'Column', 'Other Reason', '', 12, 0, '1~e (Standard Edit)^2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'PROCESS_MESSAGE', 'Column', 'Process Message', '', 13, 0, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~1^22~0^24~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'ENTRY_DATE', 'Column', 'Entry Date', '', 14, 0, '1~d (Date Picker)^2~0^3~Short Date^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~1^22~0^24~0^26~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'CUT_DATE_SCHEDULING', 'Column', '', '', 15, 1, '', v_CHILD_OBJECT_ID);
            END;
             
            <<L113>>
            DECLARE
               v_PARENT_OBJECT_ID NUMBER(9) := L111.v_OBJECT_ID;
               v_OBJECT_ID NUMBER(9);
            BEGIN
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'STATUS_REPORT_Grid_SUMMARY', 'Grid', 'Status Report Grid Summary', '', 0, 0, '305~0^307~Anchored^308~0^309~0', v_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRANSACTION_NAME', 'Column', 'Transaction Name', '', 0, 0, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~2^24~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SCHEDULE_DATE', 'Column', 'Date', '', 1, 0, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~1^24~1', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SCHEDULE_TIME', 'Column', 'Time', '', 2, 0, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~1^24~1', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'REVIEW_STATUS', 'Column', 'Review Status', '', 3, 0, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~1^22~5^24~0^28~BidOfferStatus^29~X=REVIEW_STATUS^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SUBMIT_STATUS', 'Column', 'Submit Status', '', 4, 0, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~1^22~5^24~0^28~BidOfferStatus^29~X=SUBMIT_STATUS^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'MARKET_STATUS', 'Column', 'Market Status', '', 5, 0, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~1^22~5^24~0^28~BidOfferStatus^29~X=MARKET_STATUS^31~0', v_CHILD_OBJECT_ID);
            END;
             
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRANSACTION_ID', 'Report Filter', 'Transaction Id', '', 0, 0, '501~x (Custom)^508~0^512~com.newenergyassoc.ro.scheduling.bao.BidsAndOffersTreeFilterComponent^513~1^514~1^515~1', v_CHILD_OBJECT_ID);
         END;
          
      END;
       
      -------------------------------------
      --   Scheduling.Comparison
      -------------------------------------
      <<L114>>
      DECLARE
         v_PARENT_OBJECT_ID NUMBER(9) := L0.v_OBJECT_ID;
         v_OBJECT_ID NUMBER(9);
      BEGIN
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'Scheduling.Comparison', 'System View', 'Scheduling.Comparison', '', 0, 0, '801~com.newenergyassoc.ro.scheduling.comparison.ComparisonContentPanel', v_OBJECT_ID);
         <<L115>>
         DECLARE
            v_PARENT_OBJECT_ID NUMBER(9) := L114.v_OBJECT_ID;
            v_OBJECT_ID NUMBER(9);
         BEGIN
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'SCHEDULE_COMPARISON_REPORT', 'Report', 'Schedule Comparison', '', 0, 0, '-3~0^-2~0^401~ITJ.GET_SCHEDULE_COMPARISON_REPORT;SCHEDULE_STATE1=IF(SCHEDULE_STATE1=1, 2, 1);SCHEDULE_STATE2=IF(SCHEDULE_STATE2=1, 2, 1)^402~0^403~Lazy Master/Detail Grids^404~ITJ.COMPARE_TRANSACTION_STATE;SCHEDULE_STATE1=IF(SCHEDULE_STATE1=1, 2, 1);SCHEDULE_STATE2=IF(SCHEDULE_STATE2=1, 2, 1)^405~-1^406~0', v_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SCHEDULE_COMPARISON_CHART', 'Chart', 'Schedule Comparison Chart', '', 0, 0, '901~0^902~Date^903~Amount^904~Schedule Comparison^905~Alpha,Beta^907~1^908~0^910~0', v_CHILD_OBJECT_ID);
            <<L116>>
            DECLARE
               v_PARENT_OBJECT_ID NUMBER(9) := L115.v_OBJECT_ID;
               v_OBJECT_ID NUMBER(9);
            BEGIN
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'SCHEDULE_COMPARISON_REPORT_Grid_DETAIL', 'Grid', 'Transaction Detail', '', 0, 0, '305~0^307~Anchored^308~0^309~0', v_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'Date', 'Column', '', '', 0, 0, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~1^24~1^26~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'Time', 'Column', '', '', 1, 0, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~1^24~1^26~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRANSACTION_ID', 'Column', '', '', 2, 0, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~4^24~0^26~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRANSACTION_NAME', 'Column', '', '', 3, 0, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~3^24~0^26~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'Alpha', 'Column', 'Amount 1', '', 4, 0, '1~n (Numeric Edit)^2~0^3~###,###,##0.00^4~0^7~0^9~0^11~7^12~0^13~0^14~0^15~0^20~1^22~5^24~0^26~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'Beta', 'Column', 'Amount 2', '', 5, 0, '1~n (Numeric Edit)^2~0^3~###,###,##0.00^4~0^7~0^9~0^11~7^12~0^13~0^14~0^15~0^20~1^22~5^24~0^26~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'Difference', 'Column', 'Delta', '', 6, 0, '1~n (Numeric Edit)^2~0^3~###,###,##0.00^4~0^7~0^9~0^11~7^12~0^13~0^14~0^15~0^20~1^22~5^24~0^26~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'Difference_Pct', 'Column', 'Delta %', '', 7, 0, '1~n (Numeric Edit)^2~0^3~###,###,##0.00%^4~0^7~0^9~0^11~7^12~0^13~0^14~0^15~0^20~1^22~5^24~0^26~0', v_CHILD_OBJECT_ID);
            END;
             
            <<L117>>
            DECLARE
               v_PARENT_OBJECT_ID NUMBER(9) := L115.v_OBJECT_ID;
               v_OBJECT_ID NUMBER(9);
            BEGIN
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'SCHEDULE_COMPARISON_REPORT_Grid_MASTER', 'Grid', 'Transactions', '', 0, 0, '305~0^308~0^309~0', v_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRANSACTION_ID', 'Column', '', '', 0, 1, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRANSACTION_NAME', 'Column', 'Name', '', 1, 0, '1~e (Standard Edit)^2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~1^22~0^24~0^26~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'CONTRACT_NAME', 'Column', 'Contract Name', '', 2, 0, '1~e (Standard Edit)^2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~1^22~0^24~0^26~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'CONTRACT_NUMBER', 'Column', 'Contract Number', '', 3, 0, '1~e (Standard Edit)^2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~1^22~0^24~0^26~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'ALPHA_AMOUNT', 'Column', 'Amount 1', '', 4, 0, '1~n (Numeric Edit)^2~0^3~###,###,##0.00^4~0^7~0^9~0^11~7^12~0^13~0^14~0^15~0^20~1^22~0^24~0^26~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'BETA_AMOUNT', 'Column', 'Amount 2', '', 5, 0, '1~n (Numeric Edit)^2~0^3~###,###,##0.00^4~0^7~0^9~0^11~7^12~0^13~0^14~0^15~0^20~1^22~0^24~0^26~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'DIFFERENCE', 'Column', 'Delta', '', 6, 0, '1~n (Numeric Edit)^2~0^3~###,###,##0.00^4~0^7~0^9~0^11~7^12~0^13~0^14~0^15~0^20~1^22~0^24~0^25~= ALPHA_AMOUNT - BETA_AMOUNT^26~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'PERCENTAGE', 'Column', 'Delta %', '', 7, 0, '1~n (Numeric Edit)^2~0^3~###,###,##0.00%^4~0^7~0^9~0^11~7^12~0^13~0^14~0^15~0^20~1^22~0^24~0^25~= eval ( If (ALPHA_AMOUNT > 0, (DIFFERENCE * 100) / ALPHA_AMOUNT, 0 ) )^26~0^30~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'ACCEPT', 'Column', 'Accept', '', 8, 0, '1~k (Checkbox)^2~0^4~0^7~0^9~0^11~0^12~0^13~1^14~0^15~0^20~0^22~0^24~0^26~0', v_CHILD_OBJECT_ID);
            END;
             
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRANSACTION_INTERVAL', 'Report Filter', 'Interval', '', 0, 0, '501~c (Combo Box)^502~Hour|Day|Week|Month|Year|5 Minute|10 Minute|15 Minute|30 Minute^507~Hour^508~0^514~0^515~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'CATEGORY', 'Report Filter', 'Transaction Type', '', 1, 0, '501~s (Special List)^504~SP.GET_SYSTEM_LABEL_VALUES;#1;"Scheduling;"TransactionDialog;"Combo Lists;"Transaction Type^508~0^514~0^515~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'COMMODITY_TYPE', 'Report Filter', 'Commodity', '', 2, 0, '501~o (Object List)^503~$IT_COMMODITY^508~0^514~0^515~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'PSE_ID', 'Report Filter', 'PSE', '', 3, 0, '501~s (Special List)^504~ITJ.PURCHASER_NAMES;BEGIN_DATE;END_DATE;#0^508~0^514~0^515~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'PORPOD_TYPE', 'Report Filter', 'POR POD Type', '', 4, 0, '501~c (Combo Box)^502~<ALL>|Retail|Wholesale|Generation^508~0^514~0^515~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'POD_ID', 'Report Filter', 'POD', '', 5, 0, '501~s (Special List)^504~ITJ.POD_NAMES;BEGIN_DATE;END_DATE;#0^508~0^514~0^515~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'POR_ID', 'Report Filter', 'POR', '', 6, 0, '501~s (Special List)^504~ITJ.POR_NAMES;BEGIN_DATE;END_DATE;#0^508~0^514~0^515~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SCHEDULE_TYPE1', 'Report Filter', 'Schedule Type', '', 7, 0, '-3~0^-2~0^501~o (Object List)^503~STATEMENT_TYPE^508~0^514~0^515~0^516~No Border^517~Comparison States,From^519~0^520~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SCHEDULE_STATE1', 'Report Filter', 'External', '', 8, 0, '-3~0^-2~0^501~k (Checkbox)^506~0 (Unchecked)^508~0^514~0^515~0^517~Comparison States,From^519~0^520~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SCHEDULE_TYPE2', 'Report Filter', 'Schedule Type', '', 9, 0, '-3~0^-2~0^501~o (Object List)^503~STATEMENT_TYPE^508~0^514~0^515~0^516~No Border^517~Comparison States,To^519~0^520~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SCHEDULE_STATE2', 'Report Filter', 'External', '', 10, 0, '-3~0^-2~0^501~k (Checkbox)^506~0 (Unchecked)^508~0^514~0^515~0^517~Comparison States,To^519~0^520~0', v_CHILD_OBJECT_ID);
         END;
          
      END;
       
      -------------------------------------
      --   Scheduling.Contracts
      -------------------------------------
      <<L118>>
      DECLARE
         v_PARENT_OBJECT_ID NUMBER(9) := L0.v_OBJECT_ID;
         v_OBJECT_ID NUMBER(9);
      BEGIN
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'Scheduling.Contracts', 'System View', 'Scheduling.Contracts', '', 0, 0, '-3~0^-2~0^801~com.newenergyassoc.ro.scheduling.contracts.ContractsContentPanel', v_OBJECT_ID);
         <<L119>>
         DECLARE
            v_PARENT_OBJECT_ID NUMBER(9) := L118.v_OBJECT_ID;
            v_OBJECT_ID NUMBER(9);
         BEGIN
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'Contracts_Report', 'Report', '', '', 0, 0, '-3~0^-2~0^401~ITJ.GET_CONTRACTS^402~1^406~1', v_OBJECT_ID);
            <<L120>>
            DECLARE
               v_PARENT_OBJECT_ID NUMBER(9) := L119.v_OBJECT_ID;
               v_OBJECT_ID NUMBER(9);
            BEGIN
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'Contracts_Report_Grid', 'Grid', 'Contracts Report Grid', '', 0, 0, '-3~0^-2~0^305~0^308~0^309~0', v_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SHOW_CONTRACT', 'Action', 'Show Contract', '', 0, 0, '-3~0^-2~0^1006~2^1007~Common.EntityManager;entityType="INTERCHANGE_CONTRACT";entityId=CONTRACT_ID', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'CONTRACT_ID', 'Column', '', '', 0, 1, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~1^22~0^24~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'CONTRACT_NAME', 'Column', '', '', 1, 0, '2~0^7~0^13~0^20~1^24~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'CONTRACT_ALIAS', 'Column', '', '', 2, 0, '2~0^7~0^13~0^20~1^24~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'CONTRACT_DESC', 'Column', '', '', 3, 0, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~1^22~0^24~0^26~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'CONTRACT_TYPE', 'Column', '', '', 4, 0, '-3~0^-2~0^2~0^7~0^13~0^20~1^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'BILLING_ENTITY_NAME', 'Column', '', '', 5, 0, '-3~0^-2~0^2~0^7~0^13~0^20~1^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'AGREEMENT_TYPE', 'Column', '', '', 6, 0, '2~0^7~0^13~0^20~1^24~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'BEGIN_DATE', 'Column', '', '', 7, 0, '2~0^3~Short Date^7~0^13~0^20~1^24~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'END_DATE', 'Column', '', '', 8, 0, '2~0^3~Short Date^7~0^13~0^20~1^24~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'IS_EVERGREEN', 'Column', '', '', 9, 0, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~1^22~0^24~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'CONTRACT_FILE_NAME', 'Column', '', '', 10, 0, '2~0^7~0^13~0^20~1^24~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'ENTRY_DATE', 'Column', '', '', 11, 0, '2~0^7~0^13~0^20~1^24~0', v_CHILD_OBJECT_ID);
            END;
             
         END;
          
      END;
       
      -------------------------------------
      --   Scheduling.MarketPrices
      -------------------------------------
      <<L121>>
      DECLARE
         v_PARENT_OBJECT_ID NUMBER(9) := L0.v_OBJECT_ID;
         v_OBJECT_ID NUMBER(9);
      BEGIN
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'Scheduling.MarketPrices', 'System View', 'Scheduling.Marketprices', '', 0, 0, '801~com.newenergyassoc.ro.scheduling.marketprices.MarketPricesContentPanel', v_OBJECT_ID);
         <<L122>>
         DECLARE
            v_PARENT_OBJECT_ID NUMBER(9) := L121.v_OBJECT_ID;
            v_OBJECT_ID NUMBER(9);
         BEGIN
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'MarketPrices_Report', 'Report', 'MarketPrices Report', '', 0, 0, '-3~0^-2~0^401~PR.MARKET_PRICES^402~0^403~Normal Grid^405~2^406~0', v_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'MarketPrices_Report_CHART', 'Chart', 'Market Prices Report Chart', '', 0, 0, '901~0^902~Date^903~Price^904~Market Prices^905~PRICE^907~1^908~0', v_CHILD_OBJECT_ID);
            <<L123>>
            DECLARE
               v_PARENT_OBJECT_ID NUMBER(9) := L122.v_OBJECT_ID;
               v_OBJECT_ID NUMBER(9);
            BEGIN
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'MarketPrices_Report_Grid', 'Grid', 'Marketprices Report Grid', '', 0, 0, '-3~0^-2~0^301~PR.PUT_MARKET_PRICE_VALUE_UI^305~0^307~Anchored^308~0^309~0', v_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'MARKET_PRICE_NAME', 'Column', 'Name', '', 0, 0, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~2^24~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'MARKET_PRICE_ID', 'Column', 'Id', '', 1, 1, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~5^24~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'PRICE_DATE', 'Column', 'Date', '', 2, 0, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~1^24~1', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'PRICE_BASIS', 'Column', 'Price Basis', '', 3, 0, '1~n (Numeric Edit)^2~0^4~0^7~0^9~0^11~7^12~0^13~0^14~0^15~0^19~=IF(ALLOW_EDIT < 1, "label:allowEditMessage", "")^20~0^22~5^24~0^26~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'PRICE', 'Column', 'Price', '', 4, 0, '-3~0^-2~0^1~n (Numeric Edit)^2~0^3~Currency^4~0^7~0^9~0^11~7^12~0^13~0^14~0^15~0^19~=IF(ALLOW_EDIT < 1, "label:allowEditMessage", "")^20~0^22~5^24~0^26~1^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'ALLOW_EDIT', 'Column', 'Allow Edit', '', 5, 1, '2~0^4~0^7~0^9~0^11~7^12~0^13~0^14~0^15~0^20~0^22~5^24~0^26~0', v_CHILD_OBJECT_ID);
            END;
             
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'PRICE_CODE', 'Report Filter', 'Price Type', '', 0, 0, '501~x (Custom)^502~Forecast|Preliminary|Actual^508~0^512~com.newenergyassoc.ro.scheduling.marketprices.MarketPriceTypeFilterComponent^514~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'INTERVAL', 'Report Filter', 'Interval', '', 1, 0, '-3~0^-2~0^501~c (Combo Box)^502~5 Minute|10 Minute|15 Minute|30 Minute|Hour|Day|Week|Month|Quarter|Year^507~Hour^508~0^514~0^515~0^518~MARKET_PRICE_IDS^519~0^520~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'MARKET_PRICE_IDS', 'Report Filter', 'Market Price Ids', '', 2, 0, '501~x (Custom)^508~0^512~com.newenergyassoc.ro.scheduling.marketprices.MarketPriceTreeFilterComponent^513~1^514~0', v_CHILD_OBJECT_ID);
         END;
          
      END;
       
      SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'Scheduling.Other1', 'System View', 'Scheduling.Other1', '', 0, 0, '-3~0^-2~0^801~com.newenergyassoc.ro.mightyReport.MightyReportPanel', v_CHILD_OBJECT_ID);
      -------------------------------------
      --   Scheduling.Positions
      -------------------------------------
      <<L124>>
      DECLARE
         v_PARENT_OBJECT_ID NUMBER(9) := L0.v_OBJECT_ID;
         v_OBJECT_ID NUMBER(9);
      BEGIN
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'Scheduling.Positions', 'System View', 'Scheduling.Positions', '', 0, 0, '-3~0^-2~0^801~com.newenergyassoc.ro.scheduling.positions.PositionsContentPanel', v_OBJECT_ID);
         <<L125>>
         DECLARE
            v_PARENT_OBJECT_ID NUMBER(9) := L124.v_OBJECT_ID;
            v_OBJECT_ID NUMBER(9);
         BEGIN
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'Positions_Report', 'Report', 'General Position', '', 0, 0, '-3~0^-2~0^401~ITJ.GET_PHYSICAL_POSITION^402~0^403~Normal Grid^406~0', v_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'Positions_Report_Chart', 'Chart', '', '', 0, 0, '901~9^902~Date^903~Amount^904~Physical Position^905~LOAD,NET_SUPPLY^906~25^907~1^908~0', v_CHILD_OBJECT_ID);
            <<L126>>
            DECLARE
               v_PARENT_OBJECT_ID NUMBER(9) := L125.v_OBJECT_ID;
               v_OBJECT_ID NUMBER(9);
            BEGIN
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'Positions_Report_Grid', 'Grid', 'Positions Report Grid', '', 0, 0, '305~0^308~0^309~0', v_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'DATE', 'Column', 'Date', '', 0, 0, '1~x (No Edit)^2~0^7~0^13~0^20~1^24~1', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TIME', 'Column', 'Time', '', 1, 0, '1~x (No Edit)^2~0^7~0^13~0^20~1^24~1', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'LOAD', 'Column', 'Load', '', 2, 0, '1~e (Standard Edit)^2~0^3~###,###,##0.00^4~0^7~0^9~0^11~7^12~0^13~0^14~2^15~0^20~0^22~0^24~0^26~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'GENERATION', 'Column', 'Generation', '', 3, 0, '1~x (No Edit)^2~0^3~###,###,##0.00^4~0^7~0^9~0^11~7^12~0^13~0^14~2^15~0^20~1^22~0^24~0^26~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'PURCHASES', 'Column', 'Purchases', '', 4, 0, '1~x (No Edit)^2~0^3~###,###,##0.00^4~0^7~0^9~0^11~7^12~0^13~0^14~2^15~0^20~1^22~0^24~0^26~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SALES', 'Column', 'Sales', '', 5, 0, '1~x (No Edit)^2~0^3~###,###,##0.00^7~0^11~7^13~0^14~2^20~1^24~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'PASS_THRU_AMOUNT', 'Column', 'Pass Thru Amount', '', 6, 1, '1~x (No Edit)^2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~1^22~0^24~0^26~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'NET_SUPPLY', 'Column', 'Net Supply', '', 7, 0, '1~x (No Edit)^2~0^3~###,###,##0.00^4~0^7~0^9~0^11~7^12~0^13~0^14~2^15~0^20~1^22~0^24~0^25~= GENERATION + PURCHASES - SALES^26~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'IMBALANCE', 'Column', 'Imbalance', '', 8, 0, '1~x (No Edit)^2~0^3~###,###,##0.00^4~0^7~0^9~0^11~7^12~0^13~0^14~2^15~0^20~1^22~0^24~0^25~= NET_SUPPLY - LOAD^26~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'PERCENT', 'Column', 'Percent', '', 9, 0, '1~x (No Edit)^2~0^3~###,###,##0.00%^4~0^7~0^9~0^11~7^12~0^13~0^14~5^15~0^20~1^22~0^24~0^25~=eval ( If (LOAD > 0, "(IMBALANCE / LOAD) ", "0") )^26~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'NET_OVER', 'Column', 'Net Over', '', 10, 0, '1~x (No Edit)^2~0^3~###,###,##0.00^4~0^7~0^9~0^11~7^12~0^13~0^14~2^15~0^20~1^22~0^24~0^25~= If(IMBALANCE > 0, IMBALANCE, 0)^26~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'NET_UNDER', 'Column', 'Net Under', '', 11, 0, '1~x (No Edit)^2~0^3~###,###,##0.00^4~0^7~0^9~0^11~7^12~0^13~0^14~2^15~0^20~1^22~0^24~0^25~= If(IMBALANCE < 0, ABS(IMBALANCE), 0)^26~0', v_CHILD_OBJECT_ID);
            END;
             
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'INTERVAL', 'Report Filter', 'Interval', '', 0, 0, '501~c (Combo Box)^502~Hour|Day|Month|Year|30 Minute|15 Minute|10 Minute|5 Minute^508~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'COMMODITY_TYPE', 'Report Filter', 'Commodity', '', 1, 0, '501~c (Combo Box)^502~Energy|Capacity|Transmission|Gas^508~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'PURCHASER_ID', 'Report Filter', 'Purchaser', '', 2, 0, '501~s (Special List)^504~ITJ.PURCHASER_NAMES;BEGIN_DATE;END_DATE;#0^508~0^514~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SELLER_ID', 'Report Filter', 'Seller', '', 3, 0, '501~s (Special List)^504~ITJ.SELLER_NAMES;BEGIN_DATE;END_DATE;#0^508~0^514~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'EDC_ID', 'Report Filter', 'EDC', '', 4, 0, '501~s (Special List)^504~ITJ.EDC_NAMES;BEGIN_DATE;END_DATE;#0^508~0^514~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'PORPOD_TYPE', 'Report Filter', 'POR/POD Type', '', 5, 0, '501~c (Combo Box)^502~<ALL>^508~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'POD_ID', 'Report Filter', 'POD', '', 6, 0, '501~s (Special List)^504~ITJ.POD_NAMES;BEGIN_DATE;END_DATE;#0^508~0^514~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'POR_ID', 'Report Filter', 'POR', '', 7, 0, '501~s (Special List)^504~ITJ.POR_NAMES;BEGIN_DATE;END_DATE;#0^508~0^514~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TP_ID', 'Report Filter', 'TP', '', 8, 0, '501~s (Special List)^504~ITJ.TP_NAMES;BEGIN_DATE;END_DATE;#0^508~0^514~0', v_CHILD_OBJECT_ID);
         END;
          
         <<L127>>
         DECLARE
            v_PARENT_OBJECT_ID NUMBER(9) := L124.v_OBJECT_ID;
            v_OBJECT_ID NUMBER(9);
         BEGIN
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'GAS_Position', 'Report', 'Gas Position', '', 1, 0, '-3~0^-2~0^401~GDJ.GET_POSITION^402~0^406~0', v_OBJECT_ID);
            <<L128>>
            DECLARE
               v_PARENT_OBJECT_ID NUMBER(9) := L127.v_OBJECT_ID;
               v_OBJECT_ID NUMBER(9);
            BEGIN
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'GAS_Position_Grid', 'Grid', 'Gas Position Grid', '', 0, 0, '-3~0^-2~0^305~0^307~Anchored^308~1', v_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'Details', 'Action', 'Transaction Details...', '', 0, 0, '-3~0^-2~0^1004~not islist(TRANSACTION_TYPE)^1006~0^1007~GDJ.GET_POSITION_TXNS', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SCHEDULE_DATE_DISP', 'Column', 'Schedule Date', '', 0, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~1^24~1^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SCHEDULE_DATE', 'Column', '', '', 1, 1, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~6^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SUPPLY', 'Column', '', '', 2, 0, '-3~0^-2~0^2~0^7~0^11~7^13~0^14~2^20~0^22~6^24~0^25~sum ( cols ( "if ( TRANSACTION_TYPE !=* [ ""Load"", ""Sale"", ""Injection"" ], AMOUNT, 0)"))^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SUPPLY_ACCUM', 'Column', '', '', 3, 1, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~6^24~0^25~sum ( cols ( "if ( TRANSACTION_TYPE !=* [ ""Load"", ""Sale"", ""Injection"" ], AMOUNT_ACCUM, 0)"))^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'DEMAND', 'Column', '', '', 4, 0, '-3~0^-2~0^2~0^7~0^11~7^13~0^14~2^20~0^22~6^24~0^25~sum ( cols ( "if ( TRANSACTION_TYPE =`1 [ ""Load"", ""Sale"", ""Injection"" ], AMOUNT, 0)"))^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'DEMAND_ACCUM', 'Column', '', '', 5, 1, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~6^24~0^25~sum ( cols ( "if ( TRANSACTION_TYPE =`1 [ ""Load"", ""Sale"", ""Injection"" ], AMOUNT_ACCUM, 0)"))^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TOTAL_FUEL', 'Column', 'Fuel', '', 6, 0, '-3~0^-2~0^2~0^7~0^11~7^13~1^14~2^20~0^22~6^24~0^25~sum ( FUEL )^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TOTAL_FUEL_ACCUM', 'Column', '', '', 7, 1, '22~6^25~sum ( FUEL_ACCUM )', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'POSITION', 'Column', 'Net Position', '', 8, 0, '-3~0^-2~0^2~0^7~0^11~7^13~0^14~2^20~0^22~6^24~0^25~SUPPLY - DEMAND - TOTAL_FUEL^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'POSITION_ACCUM', 'Column', 'Accumulated Position', '', 9, 0, '-3~0^-2~0^2~0^7~0^11~7^13~0^20~0^22~6^24~0^25~SUPPLY_ACCUM - DEMAND_ACCUM - TOTAL_FUEL_ACCUM^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRANSACTION_TYPE', 'Column', '', '', 10, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~2^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'AMOUNT', 'Column', '', '', 11, 0, '-3~0^-2~0^2~0^7~0^11~7^13~1^14~2^20~0^22~5^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'AMOUNT_ACCUM', 'Column', '', '', 12, 1, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~5^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'FUEL', 'Column', '', '', 13, 1, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~5^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'FUEL_ACCUM', 'Column', '', '', 14, 1, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~5^24~0^31~0', v_CHILD_OBJECT_ID);
               <<L129>>
               DECLARE
                  v_PARENT_OBJECT_ID NUMBER(9) := L128.v_OBJECT_ID;
                  v_OBJECT_ID NUMBER(9);
               BEGIN
                  SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'GDJ.GET_POSITION_TXNS', 'Grid', 'Gdj.Get Position Txns', '', 0, 0, '-3~0^-2~0^305~0^308~0', v_OBJECT_ID);
                  SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRANSACTION_NAME', 'Column', '', '', 0, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^24~1^31~0', v_CHILD_OBJECT_ID);
                  SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'AMOUNT', 'Column', '', '', 1, 0, '-3~0^-2~0^2~0^7~0^11~7^13~0^14~2^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
                  SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRANSACTION_TYPE', 'Label', 'Transaction Type', '', 0, 0, '1101~2', v_CHILD_OBJECT_ID);
                  SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SCHEDULE_DATE_DISP', 'Label', 'Schedule Date', '', 1, 0, '1101~0', v_CHILD_OBJECT_ID);
               END;
                
            END;
             
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'PIPELINE_ID', 'Report Filter', 'Pipeline', '', 0, 0, '-3~0^-2~0^501~o (Object List)^503~PIPELINE|#-1;<ALL>^508~0^514~0^515~0^517~By Pipeline^518~ZONE_ID,POINT_ID^519~0^520~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'ZONE_ID', 'Report Filter', 'Pipeline Zone', '', 1, 0, '-3~0^-2~0^501~s (Special List)^504~GDJ.GET_PIPELINE_ZONES;PIPELINE_ID^508~0^514~0^515~0^517~By Pipeline^518~POINT_ID^519~0^520~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'POINT_ID', 'Report Filter', 'Pipeline Point', '', 2, 0, '-3~0^-2~0^501~s (Special List)^504~GDJ.GET_POINTS_FOR_PIPELINE_ZONE;PIPELINE_ID;ZONE_ID^508~0^514~0^515~0^517~By Pipeline^519~0^520~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'INCLUDE_FUEL', 'Report Filter', 'Include Fuel?', '', 3, 0, '-3~0^-2~0^501~k (Checkbox)^506~1 (Checked)^508~0^514~0^515~0^517~By Pipeline^519~0^520~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'EDC_ID', 'Report Filter', 'EDC', '', 4, 0, '-3~0^-2~0^501~o (Object List)^503~EDC|#-1;<ALL>^508~0^514~0^515~0^517~By Business Entity^519~0^520~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'PSE_ID', 'Report Filter', 'Counter-Party', '', 5, 0, '-3~0^-2~0^501~s (Special List)^504~GDJ.GET_COUNTERPARTIES;#0;BEGIN_DATE;END_DATE^508~0^514~0^515~0^517~By Business Entity^519~0^520~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'POOL_ID', 'Report Filter', 'Pool', '', 6, 0, '-3~0^-2~0^501~o (Object List)^503~POOL|#-1;<ALL>^508~0^514~0^515~0^517~By Business Entity^519~0^520~0', v_CHILD_OBJECT_ID);
         END;
          
         <<L130>>
         DECLARE
            v_PARENT_OBJECT_ID NUMBER(9) := L124.v_OBJECT_ID;
            v_OBJECT_ID NUMBER(9);
         BEGIN
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'GasPointPosition', 'Report', 'Pipeline Point Position', '', 2, 0, '-3~0^-2~0^401~GDJ.GET_POINT_POSITION^402~0^406~0', v_OBJECT_ID);
            <<L131>>
            DECLARE
               v_PARENT_OBJECT_ID NUMBER(9) := L130.v_OBJECT_ID;
               v_OBJECT_ID NUMBER(9);
            BEGIN
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'GasPointPosition_Grid', 'Grid', 'Gaspointposition Grid', '', 0, 0, '-3~0^-2~0^305~0^307~Anchored^308~1', v_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'Details', 'Action', 'Transaction Details...', '', 0, 0, '1004~not islist(TRANSACTION_TYPE)^1006~0^1007~GDJ.GET_POSITION_TXNS;EDC_ID=-1;PSE_ID=-1;POOL_ID=-1', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'POINT_NAME', 'Column', 'Pipeline Point', '', 0, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~1^24~1^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SCHEDULE_DATE_DISP', 'Column', 'Schedule Date', '', 1, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~1^24~1^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'POINT_ID', 'Column', '', '', 2, 1, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~6^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SCHEDULE_DATE', 'Column', '', '', 3, 1, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~6^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SUPPLY', 'Column', 'Supply / Delivered', '', 4, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~6^24~0^25~sum( cols( " if ( TRANSACTION_TYPE !=* [ ""Load"", ""Sale"", ""Injection"" ] , AMOUNT , 0 )" ) ) + sum(DELIV)^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'DEMAND', 'Column', 'Demand / Received', '', 5, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~6^24~0^25~sum( cols( " if ( TRANSACTION_TYPE =`1 [ ""Load"", ""Sale"", ""Injection"" ] , AMOUNT , 0 )" ) ) + sum(RECV)^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'POSITION', 'Column', '', '', 6, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~6^24~0^25~SUPPLY - DEMAND^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRANSACTION_TYPE', 'Column', '', '', 7, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~2^24~0^31~0^32~1', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'AMOUNT', 'Column', '', '', 8, 0, '-3~0^-2~0^2~0^7~0^13~1^20~0^22~5^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'DELIV', 'Column', '', '', 9, 1, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~5^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'RECV', 'Column', '', '', 10, 1, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~5^24~0^31~0', v_CHILD_OBJECT_ID);
               <<L132>>
               DECLARE
                  v_PARENT_OBJECT_ID NUMBER(9) := L131.v_OBJECT_ID;
                  v_OBJECT_ID NUMBER(9);
               BEGIN
                  SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'GDJ.GET_POSITION_TXNS;EDC_ID=-1;PSE_ID=-1;POOL_ID=-1', 'Grid', 'Gdj.Get Position Txns;Edc Id=-1;Pse Id=-1;Pool Id=-1', '', 0, 0, '-3~0^-2~0^305~0^308~0', v_OBJECT_ID);
                  SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRANSACTION_NAME', 'Column', '', '', 0, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^24~1^31~0', v_CHILD_OBJECT_ID);
                  SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'AMOUNT', 'Column', '', '', 1, 0, '-3~0^-2~0^2~0^7~0^11~7^13~0^14~2^20~0^24~0^31~0', v_CHILD_OBJECT_ID);
                  SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRANSACTION_TYPE', 'Label', 'Transaction Type', '', 0, 0, '1101~2', v_CHILD_OBJECT_ID);
                  SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SCHEDULE_DATE_DISP', 'Label', 'Schedule Date', '', 1, 0, '1101~0', v_CHILD_OBJECT_ID);
               END;
                
            END;
             
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'PIPELINE_ID', 'Report Filter', 'Pipeline', '', 0, 0, '-3~0^-2~0^501~o (Object List)^503~PIPELINE|#-1;<ALL>^508~0^514~0^515~0^518~ZONE_ID,POINT_ID^519~0^520~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'ZONE_ID', 'Report Filter', 'Pipeline Zone', '', 1, 0, '-3~0^-2~0^501~s (Special List)^504~GDJ.GET_PIPELINE_ZONES;PIPELINE_ID^508~0^514~0^515~0^518~POINT_ID^519~0^520~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'POINT_ID', 'Report Filter', 'Pipeline Point', '', 2, 0, '-3~0^-2~0^501~s (Special List)^504~GDJ.GET_POINTS_FOR_PIPELINE_ZONE;PIPELINE_ID;ZONE_ID^508~0^514~0^515~0^519~0^520~0', v_CHILD_OBJECT_ID);
         END;
          
      END;
       
      -------------------------------------
      --   Scheduling.Scheduler
      -------------------------------------
      <<L133>>
      DECLARE
         v_PARENT_OBJECT_ID NUMBER(9) := L0.v_OBJECT_ID;
         v_OBJECT_ID NUMBER(9);
      BEGIN
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'Scheduling.Scheduler', 'System View', '', '', 0, 0, '801~com.newenergyassoc.ro.scheduling.scheduler.SchedulerContentPanel', v_OBJECT_ID);
         <<L134>>
         DECLARE
            v_PARENT_OBJECT_ID NUMBER(9) := L133.v_OBJECT_ID;
            v_OBJECT_ID NUMBER(9);
         BEGIN
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'Scheduler_Report', 'Report', 'Scheduler Report', '', 0, 0, '-3~0^-2~0^401~ITJ.GET_IT_SCHEDULE^402~0^403~Normal Grid^405~0^406~0', v_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'Scheduler_Report_Chart', 'Chart', 'Sheduler Report Chart', '', 0, 0, '-3~0^-2~0^901~9^902~Date^903~Amount^904~Schedule^905~AMOUNT^906~25^907~1^908~0^910~0^912~0^913~1', v_CHILD_OBJECT_ID);
            <<L135>>
            DECLARE
               v_PARENT_OBJECT_ID NUMBER(9) := L134.v_OBJECT_ID;
               v_OBJECT_ID NUMBER(9);
            BEGIN
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'Scheduler_Report_Grid', 'Grid', 'Scheduler Report Grid', '', 0, 0, '-3~0^-2~0^301~ITJ.SCHEDULE_UPDATE_REQUEST^305~0^307~Standard^308~0^309~0', v_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SCHEDULE_DATE', 'Column', 'Date', '', 0, 0, '-3~0^-2~0^2~0^7~0^13~0^20~0^22~1^24~1^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SCHEDULE_TIME', 'Column', 'Time', '', 1, 0, '-3~0^-2~0^2~0^7~0^13~1^20~0^22~2^24~1^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'AMOUNT', 'Column', 'Amount', '', 2, 0, '-3~0^-2~0^1~n (Numeric Edit)^2~0^3~###,###,##0.00^4~0^7~0^9~0^11~7^12~0^13~0^14~2^15~0^20~0^22~5^24~0^26~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'PRICE', 'Column', 'Price', '', 3, 1, '-3~0^-2~0^1~n (Numeric Edit)^2~0^3~Currency^4~0^7~0^9~0^11~7^12~0^13~0^14~5^15~0^20~0^22~5^24~0^26~0^30~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'COST', 'Column', 'Cost', '', 4, 0, '-3~0^-2~0^2~0^3~Currency^4~0^7~0^9~0^11~7^12~0^13~0^14~2^15~0^20~1^22~5^24~0^25~AMOUNT * PRICE^26~0^30~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'EXT_AMOUNT', 'Column', 'External Amount', '', 5, 0, '-3~0^-2~0^1~n (Numeric Edit)^2~0^3~###,###,###.##^7~0^11~7^13~1^14~2^20~0^22~5^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'EXT_PRICE', 'Column', 'External Price', '', 6, 0, '-3~0^-2~0^1~n (Numeric Edit)^2~0^3~Currency^7~0^11~7^13~1^14~2^20~0^22~5^24~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'EXT_COST', 'Column', 'External Cost', '', 7, 0, '-3~0^-2~0^1~x (No Edit)^2~0^3~Currency^4~0^7~0^9~0^11~7^12~0^13~1^14~2^15~0^20~1^22~5^24~0^25~if (null(EXT_AMOUNT, EXT_PRICE), null(), EXT_AMOUNT * EXT_PRICE)^26~0^30~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'MARKET_PRICE', 'Column', 'Market Price', '', 8, 0, '-3~0^-2~0^2~0^3~Currency^7~0^11~7^13~1^14~5^20~1^22~5^24~0^31~0', v_CHILD_OBJECT_ID);
            END;
             
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRANSACTION_ID', 'Report Filter', 'Transaction Id', '', 0, 0, '501~x (Custom)^508~0^512~com.newenergyassoc.ro.scheduling.scheduler.SchedulerTreeFilterComponent^513~1', v_CHILD_OBJECT_ID);
         END;
          
      END;
       
      -------------------------------------
      --   Scheduling.SubStations
      -------------------------------------
      <<L136>>
      DECLARE
         v_PARENT_OBJECT_ID NUMBER(9) := L0.v_OBJECT_ID;
         v_OBJECT_ID NUMBER(9);
      BEGIN
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'Scheduling.SubStations', 'System View', '', '', 0, 0, '801~com.newenergyassoc.ro.scheduling.subStations.SubStationsContentPanel', v_OBJECT_ID);
         <<L137>>
         DECLARE
            v_PARENT_OBJECT_ID NUMBER(9) := L136.v_OBJECT_ID;
            v_OBJECT_ID NUMBER(9);
         BEGIN
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'SubStations_Report', 'Report', 'Substations Report', '', 0, 0, '401~ITJ.GET_SUB_STATION_DATA^402~0', v_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SubStations_Report_Chart', 'Chart', '', '', 0, 0, '901~0', v_CHILD_OBJECT_ID);
            <<L138>>
            DECLARE
               v_PARENT_OBJECT_ID NUMBER(9) := L137.v_OBJECT_ID;
               v_OBJECT_ID NUMBER(9);
            BEGIN
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'SubStations_Report_Grid', 'Grid', '', '', 0, 0, '305~0', v_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'DATE', 'Column', '', '', 0, 0, '', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'ENTITY_NAME', 'Column', '', '', 1, 0, '', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'ENTITY_ID', 'Column', '', '', 2, 0, '', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'OPERATION_CODE', 'Column', '', '', 3, 0, '', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'AMOUNT', 'Column', '', '', 4, 0, '2~0^7~0^13~0^20~0^24~0', v_CHILD_OBJECT_ID);
            END;
             
            <<L139>>
            DECLARE
               v_PARENT_OBJECT_ID NUMBER(9) := L137.v_OBJECT_ID;
               v_OBJECT_ID NUMBER(9);
            BEGIN
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'SubStations_Report_Grid_METER_NAME', 'Grid', 'Substations Report Grid Meter Name', '', 0, 0, '301~ITJ.PUT_SUB_STATION_VALUE^305~0^307~Anchored^308~0^309~0', v_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'DATE', 'Column', 'Date', '', 0, 0, '2~0^7~0^13~0^20~0^22~1^24~1', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TIME', 'Column', 'Time', '', 1, 0, '2~0^7~0^13~1^20~0^22~1^24~1', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'ENTITY_NAME', 'Column', 'Entity Name', '', 2, 0, '2~0^7~0^13~0^20~0^22~2^24~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'ENTITY_ID', 'Column', 'Entity Id', '', 3, 1, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~5^24~0^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'AMOUNT', 'Column', 'Amount', '', 4, 0, '1~n (Numeric Edit)^2~0^3~###,###,##0.00^4~0^7~0^9~0^11~7^12~0^13~0^14~2^15~0^20~0^22~5^24~0^26~0^30~0^31~0^32~0', v_CHILD_OBJECT_ID);
            END;
             
            <<L140>>
            DECLARE
               v_PARENT_OBJECT_ID NUMBER(9) := L137.v_OBJECT_ID;
               v_OBJECT_ID NUMBER(9);
            BEGIN
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'SubStations_Report_Grid_SERVICE_POINT_NAME', 'Grid', '', '', 0, 0, '305~0^307~Anchored^308~1', v_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'DATE', 'Column', 'Date', '', 0, 0, '2~0^7~0^13~0^20~0^22~1^24~1', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TIME', 'Column', 'Time', '', 1, 0, '2~0^7~0^13~1^20~0^22~1^24~1', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'ENTITY_NAME', 'Column', 'Entity Name', '', 2, 0, '2~0^7~0^11~9^13~0^20~0^22~2^24~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'ENTITY_ID', 'Column', 'Entity Id', '', 3, 0, '2~0^7~0^13~0^20~0^24~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'AMOUNT', 'Column', 'Amount', '', 4, 0, '1~x (No Edit)^2~0^3~###,###,##0.00^7~0^11~7^13~0^14~2^20~1^22~5^24~0', v_CHILD_OBJECT_ID);
            END;
             
            <<L141>>
            DECLARE
               v_PARENT_OBJECT_ID NUMBER(9) := L137.v_OBJECT_ID;
               v_OBJECT_ID NUMBER(9);
            BEGIN
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'SubStations_Report_Grid_SUB_STATION_NAME', 'Grid', '', '', 0, 0, '305~0^307~Anchored^308~1', v_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'DATE', 'Column', 'Date', '', 0, 0, '2~0^7~0^13~0^20~0^22~1^24~1', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TIME', 'Column', 'Time', '', 1, 0, '2~0^7~0^13~1^20~0^22~1^24~1', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'ENTITY_NAME', 'Column', 'Entity Name', '', 2, 0, '2~0^7~0^13~0^20~0^22~2^24~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'ENTITY_ID', 'Column', 'Entity Id', '', 3, 0, '2~0^7~0^13~0^20~0^24~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'OPERATION_CODE', 'Column', 'Op Code', '', 4, 0, '2~0^7~0^13~0^20~0^22~3^24~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'AMOUNT', 'Column', 'Amount', '', 5, 0, '1~x (No Edit)^2~0^3~###,###,##0.00^7~0^11~7^13~0^14~2^20~1^22~5^24~0', v_CHILD_OBJECT_ID);
            END;
             
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'INTERVAL', 'Report Filter', 'Interval', '', 0, 0, '501~c (Combo Box)^502~Hour|Day|Month|Year^508~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'ENTITY_ID', 'Report Filter', 'Entity Id', '', 1, 0, '501~x (Custom)^508~0^512~com.newenergyassoc.ro.scheduling.subStations.SubStationsTreeFilterComponent^513~1^514~1', v_CHILD_OBJECT_ID);
         END;
          
      END;
       
      -------------------------------------
      --   Scheduling.Summary
      -------------------------------------
      <<L142>>
      DECLARE
         v_PARENT_OBJECT_ID NUMBER(9) := L0.v_OBJECT_ID;
         v_OBJECT_ID NUMBER(9);
      BEGIN
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'Scheduling.Summary', 'System View', '', '', 0, 0, '801~com.newenergyassoc.ro.mightyReport.MightyReportPanel', v_OBJECT_ID);
         <<L143>>
         DECLARE
            v_PARENT_OBJECT_ID NUMBER(9) := L142.v_OBJECT_ID;
            v_OBJECT_ID NUMBER(9);
         BEGIN
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'Summary_Report', 'Report', 'Summary Report', '', 0, 0, '-3~0^-2~0^401~ITJ.GET_SUMMARY^402~0^403~Normal Grid^406~0', v_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'Summary_Report_Chart', 'Chart', 'Summary Report Chart', '', 0, 1, '901~9^904~Summary^905~LOAD,NET_SUPPLY_AMOUNT,NET_SUPPLY_COST,NET_SUPPLY_WACOG^906~25^907~1^908~1', v_CHILD_OBJECT_ID);
            <<L144>>
            DECLARE
               v_PARENT_OBJECT_ID NUMBER(9) := L143.v_OBJECT_ID;
               v_OBJECT_ID NUMBER(9);
            BEGIN
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'Summary_Report_Grid_HOURLY', 'Grid', 'Summary Report Grid Hourly', '', 0, 0, '305~0^307~Anchored^308~0^309~0', v_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SCHEDULE_DATE', 'Column', 'Date', '', 0, 0, '2~0^7~0^13~0^20~0^22~1^24~1', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SCHEDULE_TIME', 'Column', 'Time', '', 0, 0, '2~0^7~0^13~1^20~0^22~1^24~1', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'ENTITY_NAME', 'Column', '', '', 1, 0, '2~0^7~0^13~0^20~0^22~2^24~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'ENTITY_ID', 'Column', '', '', 2, 1, '2~0^7~0^13~0^20~0^24~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'IS_TOTAL', 'Column', '', '', 3, 1, '2~0^7~0^13~0^20~0^24~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'PERIOD_NAME', 'Column', '', '', 4, 0, '2~0^7~0^13~0^20~0^22~2^24~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'PERIOD_ID', 'Column', '', '', 5, 1, '2~0^7~0^13~0^20~0^24~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'LOAD', 'Column', '', '', 6, 0, '1~n (Numeric Edit)^2~0^3~###,###,##0.00^4~0^7~0^9~0^11~7^12~7^13~0^14~2^15~0^20~1^22~5^24~0^26~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'MIN_LOAD', 'Column', '', '', 7, 1, '2~0^7~0^13~0^20~0^24~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'MAX_LOAD', 'Column', '', '', 8, 1, '2~0^7~0^13~0^20~0^24~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'AVG_LOAD', 'Column', '', '', 9, 1, '2~0^7~0^13~0^20~0^24~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'NET_SUPPLY_AMOUNT', 'Column', '', '', 10, 0, '2~0^3~###,###,##0.00^7~0^11~7^12~7^13~0^14~2^20~1^22~5^24~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'NET_SUPPLY_COST', 'Column', '', '', 11, 0, '2~0^3~Currency^7~0^11~7^13~0^14~2^20~1^22~5^24~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'NET_SUPPLY_WACOG', 'Column', '', '', 12, 0, '2~0^3~###,###,##0.00^7~0^11~7^13~0^14~2^20~1^22~5^24~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'PURCHASE_AMOUNT', 'Column', '', '', 13, 1, '2~0^7~0^13~0^20~0^24~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'PURCHASE_COST', 'Column', '', '', 14, 1, '2~0^7~0^13~0^20~0^24~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'PURCHASE_WACOG', 'Column', '', '', 15, 1, '2~0^7~0^13~0^20~0^24~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SALE_AMOUNT', 'Column', '', '', 16, 1, '2~0^7~0^13~0^20~0^24~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SALE_COST', 'Column', '', '', 17, 1, '2~0^7~0^13~0^20~0^24~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SALE_WACOG', 'Column', '', '', 18, 1, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~0^24~0^26~0', v_CHILD_OBJECT_ID);
            END;
             
            <<L145>>
            DECLARE
               v_PARENT_OBJECT_ID NUMBER(9) := L143.v_OBJECT_ID;
               v_OBJECT_ID NUMBER(9);
            BEGIN
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'Summary_Report_Grid_HOURLY_SHOW_DETAIL', 'Grid', '', '', 0, 0, '305~0^307~Anchored^308~0', v_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SCHEDULE_DATE', 'Column', 'Date', '', 0, 0, '2~0^7~0^13~0^20~0^22~1^24~1', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SCHEDULE_TIME', 'Column', 'Time', '', 1, 0, '2~0^7~0^13~1^20~0^22~1^24~1', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'ENTITY_NAME', 'Column', '', '', 2, 0, '2~0^7~0^13~0^20~0^22~2^24~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'ENTITY_ID', 'Column', '', '', 3, 1, '2~0^7~0^13~0^20~0^24~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'IS_TOTAL', 'Column', '', '', 4, 1, '2~0^7~0^13~0^20~0^24~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'PERIOD_NAME', 'Column', '', '', 5, 0, '2~0^7~0^13~0^20~0^22~2^24~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'PERIOD_ID', 'Column', '', '', 6, 1, '2~0^7~0^13~0^20~0^24~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'LOAD', 'Column', '', '', 7, 0, '2~0^3~###,###,##0.00^7~0^11~7^13~0^14~2^20~1^22~5^24~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'MIN_LOAD', 'Column', '', '', 8, 1, '2~0^7~0^13~0^20~0^24~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'MAX_LOAD', 'Column', '', '', 9, 1, '2~0^7~0^13~0^20~0^24~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'AVG_LOAD', 'Column', '', '', 10, 1, '2~0^7~0^13~0^20~0^24~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'NET_SUPPLY_AMOUNT', 'Column', '', '', 11, 0, '2~0^3~###,###,##0.00^7~0^11~7^13~0^14~2^20~1^22~5^24~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'NET_SUPPLY_COST', 'Column', '', '', 12, 0, '2~0^3~Currency^7~0^11~7^13~0^14~2^20~1^22~5^24~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'NET_SUPPLY_WACOG', 'Column', '', '', 13, 0, '2~0^3~###,###,##0.00^7~0^11~7^13~0^14~2^20~1^22~5^24~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'PURCHASE_AMOUNT', 'Column', '', '', 14, 0, '2~0^3~###,###,##0.00^7~0^11~7^13~0^14~2^20~1^22~5^24~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'PURCHASE_COST', 'Column', '', '', 15, 0, '2~0^3~Currency^7~0^11~7^13~0^14~2^20~1^22~5^24~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'PURCHASE_WACOG', 'Column', '', '', 16, 0, '2~0^3~###,###,##0.00^7~0^11~7^13~0^14~2^20~1^22~5^24~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SALE_AMOUNT', 'Column', '', '', 17, 0, '2~0^3~###,###,##0.00^7~0^11~7^13~0^14~2^20~1^22~5^24~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SALE_COST', 'Column', '', '', 18, 0, '2~0^3~Currency^7~0^11~7^13~0^14~2^20~1^22~5^24~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SALE_WACOG', 'Column', '', '', 19, 0, '2~0^3~###,###,##0.00^7~0^11~7^13~0^14~2^20~1^22~5^24~0', v_CHILD_OBJECT_ID);
            END;
             
            <<L146>>
            DECLARE
               v_PARENT_OBJECT_ID NUMBER(9) := L143.v_OBJECT_ID;
               v_OBJECT_ID NUMBER(9);
            BEGIN
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'Summary_Report_Grid_NONHOURLY', 'Grid', '', '', 0, 0, '305~0^307~Anchored^308~0', v_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SCHEDULE_DATE', 'Column', 'Date', '', 0, 0, '2~0^7~0^13~0^20~0^22~1^24~1', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SCHEDULE_TIME', 'Column', 'Time', '', 0, 0, '2~0^7~0^13~1^20~0^22~1^24~1', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'ENTITY_NAME', 'Column', '', '', 1, 0, '2~0^7~0^13~0^20~0^22~2^24~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'ENTITY_ID', 'Column', '', '', 2, 1, '2~0^7~0^13~0^20~0^24~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'IS_TOTAL', 'Column', '', '', 3, 1, '2~0^7~0^13~0^20~0^24~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'PERIOD_NAME', 'Column', '', '', 4, 0, '2~0^7~0^13~0^20~0^22~2^24~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'PERIOD_ID', 'Column', '', '', 5, 1, '2~0^7~0^13~0^20~0^24~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'LOAD', 'Column', '', '', 6, 0, '2~0^3~###,###,##0.00^7~0^11~7^12~7^13~0^14~2^20~1^22~5^24~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'MIN_LOAD', 'Column', '', '', 7, 0, '2~0^3~###,###,##0.00^7~0^11~7^12~7^13~0^14~2^20~1^22~5^24~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'MAX_LOAD', 'Column', '', '', 8, 0, '2~0^3~###,###,##0.00^7~0^11~7^12~7^13~0^14~2^20~1^22~5^24~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'AVG_LOAD', 'Column', '', '', 9, 0, '2~0^3~###,###,##0.00^7~0^11~7^12~7^13~0^14~2^20~1^22~5^24~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'NET_SUPPLY_AMOUNT', 'Column', '', '', 10, 0, '2~0^3~###,###,##0.00^7~0^11~7^12~7^13~0^14~2^20~1^22~5^24~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'NET_SUPPLY_COST', 'Column', '', '', 11, 0, '2~0^3~Currency^7~0^11~7^13~0^14~2^20~1^22~5^24~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'NET_SUPPLY_WACOG', 'Column', '', '', 12, 0, '2~0^3~###,###,##0.00^7~0^11~7^13~0^14~2^20~1^22~5^24~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'PURCHASE_AMOUNT', 'Column', '', '', 13, 1, '2~0^7~0^13~0^20~0^24~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'PURCHASE_COST', 'Column', '', '', 14, 1, '2~0^7~0^13~0^20~0^24~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'PURCHASE_WACOG', 'Column', '', '', 15, 1, '2~0^7~0^13~0^20~0^24~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SALE_AMOUNT', 'Column', '', '', 16, 1, '2~0^7~0^13~0^20~0^24~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SALE_COST', 'Column', '', '', 17, 1, '2~0^7~0^13~0^20~0^24~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SALE_WACOG', 'Column', '', '', 18, 1, '2~0^7~0^13~0^20~0^24~0', v_CHILD_OBJECT_ID);
            END;
             
            <<L147>>
            DECLARE
               v_PARENT_OBJECT_ID NUMBER(9) := L143.v_OBJECT_ID;
               v_OBJECT_ID NUMBER(9);
            BEGIN
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'Summary_Report_Grid_NONHOURLY_SHOW_DETAIL', 'Grid', '', '', 0, 0, '305~0^307~Anchored^308~0', v_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SCHEDULE_DATE', 'Column', 'Date', '', 0, 0, '2~0^7~0^13~0^20~0^22~1^24~1', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SCHEDULE_TIME', 'Column', 'Time', '', 1, 0, '2~0^7~0^13~1^20~0^22~1^24~1', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'ENTITY_NAME', 'Column', '', '', 2, 0, '2~0^7~0^13~0^20~0^22~2^24~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'ENTITY_ID', 'Column', '', '', 3, 1, '2~0^7~0^13~0^20~0^24~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'IS_TOTAL', 'Column', '', '', 4, 1, '2~0^7~0^13~0^20~0^24~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'PERIOD_NAME', 'Column', '', '', 5, 0, '2~0^7~0^13~0^20~0^22~2^24~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'PERIOD_ID', 'Column', '', '', 6, 1, '2~0^7~0^13~0^20~0^24~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'LOAD', 'Column', '', '', 7, 0, '2~0^3~###,###,##0.00^7~0^11~7^13~0^14~2^20~1^22~5^24~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'MIN_LOAD', 'Column', '', '', 8, 0, '2~0^3~###,###,##0.00^7~0^11~7^12~7^13~0^14~2^20~1^22~5^24~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'MAX_LOAD', 'Column', '', '', 9, 0, '2~0^3~###,###,##0.00^7~0^11~7^12~7^13~0^14~2^20~1^22~5^24~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'AVG_LOAD', 'Column', '', '', 10, 0, '2~0^3~###,###,##0.00^7~0^11~7^12~7^13~0^14~2^20~1^22~5^24~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'NET_SUPPLY_AMOUNT', 'Column', '', '', 11, 0, '2~0^3~###,###,##0.00^7~0^11~7^13~0^14~2^20~1^22~5^24~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'NET_SUPPLY_COST', 'Column', '', '', 12, 0, '2~0^3~Currency^7~0^11~7^13~0^14~2^20~1^22~5^24~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'NET_SUPPLY_WACOG', 'Column', '', '', 13, 0, '2~0^3~###,###,##0.00^7~0^11~7^13~0^14~2^20~1^22~5^24~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'PURCHASE_AMOUNT', 'Column', '', '', 14, 0, '2~0^3~###,###,##0.00^7~0^11~7^13~0^14~2^20~1^22~5^24~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'PURCHASE_COST', 'Column', '', '', 15, 0, '2~0^3~Currency^7~0^11~7^13~0^14~2^20~1^22~5^24~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'PURCHASE_WACOG', 'Column', '', '', 16, 0, '2~0^3~###,###,##0.00^7~0^11~7^13~0^14~2^20~1^22~5^24~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SALE_AMOUNT', 'Column', '', '', 17, 0, '2~0^3~###,###,##0.00^7~0^11~7^13~0^14~2^20~1^22~5^24~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SALE_COST', 'Column', '', '', 18, 0, '2~0^3~Currency^7~0^11~7^13~0^14~2^20~1^22~5^24~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SALE_WACOG', 'Column', '', '', 19, 0, '2~0^3~###,###,##0.00^7~0^11~7^13~0^14~2^20~1^22~5^24~0', v_CHILD_OBJECT_ID);
            END;
             
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'COMMODITY', 'Report Filter', 'Commodity', '', 0, 0, '501~c (Combo Box)^502~Energy|Capacity|Transmission|Gas^508~0^514~0^515~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'ENTITY_TYPE', 'Report Filter', 'Entity Type', '', 1, 0, '-3~0^-2~0^501~c (Combo Box)^502~EDC|TP|POR|POD|Purchaser|Seller^508~0^514~0^515~0^518~ENTITY_IDs^519~0^520~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'ENTITY_IDs', 'Report Filter', 'Entities', '', 2, 0, '501~s (Special List)^504~ITJ.ENTITY_NAMES;ENTITY_TYPE;BEGIN_DATE;END_DATE;#1^508~0^514~0^515~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'INTERVAL', 'Report Filter', 'Interval', '', 3, 0, '501~x (Custom)^502~Hour|Day|Week|Month|Quarter|Year^508~0^512~com.newenergyassoc.ro.scheduling.summary.SummaryIntervalFilterComponent^514~1', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SHOW_DETAIL', 'Report Filter', 'Show Detail', '', 4, 0, '501~k (Checkbox)^506~0 (Unchecked)^508~0^514~1', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TEMPLATE_ID', 'Report Filter', 'Templates', '', 5, 0, '501~o (Object List)^503~TEMPLATE|#0;<None>^508~0^514~0', v_CHILD_OBJECT_ID);
         END;
          
      END;
       
      -------------------------------------
      --   Scheduling.Transactions
      -------------------------------------
      <<L148>>
      DECLARE
         v_PARENT_OBJECT_ID NUMBER(9) := L0.v_OBJECT_ID;
         v_OBJECT_ID NUMBER(9);
      BEGIN
         SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'Scheduling.Transactions', 'System View', 'Scheduling.Transactions', '', 0, 0, '801~com.newenergyassoc.ro.scheduling.transactions.TransactionsContentPanel', v_OBJECT_ID);
         <<L149>>
         DECLARE
            v_PARENT_OBJECT_ID NUMBER(9) := L148.v_OBJECT_ID;
            v_OBJECT_ID NUMBER(9);
         BEGIN
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'TRANSACTIONS_REPORT', 'Report', 'Transactions Report', '', 0, 0, '-3~0^-2~0^401~ITJ.GET_TRANSACTION_REPORT^402~0^403~Normal Grid^405~-1^406~0', v_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRANSACTIONS_REPORT_CHART', 'Chart', '', '', 0, 0, '901~9^902~Date^904~Transactions^907~1^908~0^910~1', v_CHILD_OBJECT_ID);
            <<L150>>
            DECLARE
               v_PARENT_OBJECT_ID NUMBER(9) := L149.v_OBJECT_ID;
               v_OBJECT_ID NUMBER(9);
            BEGIN
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_PARENT_OBJECT_ID, 'TRANSACTIONS_REPORT_Grid', 'Grid', 'Transactions Report Grid', '', 0, 0, '-3~0^-2~0^305~0^307~Anchored^308~0^309~0', v_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SHOW_TRANSACTION', 'Action', 'Show Transation', '', 0, 0, '-3~0^-2~0^1004~(NOT NULL(TRANSACTION_ID)) AND (IS_NUMBER(TRANSACTION_ID)) AND (TRANSACTION_ID > 0)^1006~2^1007~Common.EntityManager;entityType="TRANSACTION";entityId=TRANSACTION_ID', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'EDIT_SCHEDULE', 'Action', 'Edit Schedule', '', 1, 0, '-3~0^-2~0^1004~(NOT NULL(TRANSACTION_ID)) AND (IS_NUMBER(TRANSACTION_ID)) AND (TRANSACTION_ID > 0)^1006~6^1007~Scheduling.Scheduler;TRANSACTION_ID=TRANSACTION_ID', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SCHEDULE_DATE', 'Column', 'Date', '', 0, 0, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~1^24~1^26~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SCHEDULE_TIME', 'Column', 'Time', '', 1, 0, '-3~0^-2~0^2~0^4~0^7~0^9~0^11~0^12~0^13~1^14~0^15~0^20~0^22~1^24~1^26~0^31~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'NET', 'Column', 'Net', '', 2, 0, '1~n (Numeric Edit)^2~0^3~###,###,###.00^4~0^7~0^9~0^11~7^12~0^13~0^14~0^15~0^20~1^22~6^24~0^25~=SUM(COLS("IF(TRANSACTION_TYPE=""Purchase"" OR TRANSACTION_TYPE=""Generation"",-AMOUNT,AMOUNT)"))^26~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRANSACTION_ID', 'Column', 'Id', '', 3, 0, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~4^24~0^26~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRANSACTION_NAME', 'Column', 'Name', '', 4, 0, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~3^24~0^26~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'COMMODITY_TYPE', 'Column', 'Commodity', '', 5, 1, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~2^24~0^26~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRANSACTION_TYPE', 'Column', 'Type', '', 6, 0, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~2^24~0^26~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SC_NAME', 'Column', 'Schedule Coordinator', '', 7, 1, '2~0^4~0^7~0^9~0^11~0^12~0^13~0^14~0^15~0^20~0^22~2^24~0^26~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'AMOUNT', 'Column', 'Amount', '', 8, 0, '1~n (Numeric Edit)^2~0^3~###,###,###.00^4~0^7~0^9~0^11~7^12~0^13~0^14~0^15~0^20~1^22~5^24~0^26~0', v_CHILD_OBJECT_ID);
               SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'PRICE', 'Column', 'Price', '', 9, 0, '1~n (Numeric Edit)^2~0^3~Currency^4~0^7~0^9~0^11~7^12~0^13~0^14~0^15~0^20~1^22~5^24~0^26~0', v_CHILD_OBJECT_ID);
            END;
             
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'TRANSACTION_INTERVAL', 'Report Filter', 'Interval', '', 0, 0, '501~c (Combo Box)^502~Hour|Day|Week|Month|Year|5 Minute|10 Minute|15 Minute|30 Minute^507~Hour^508~0^514~0^515~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'SC_ID', 'Report Filter', 'Schedule Coordinator', '', 1, 0, '-3~0^-2~0^501~o (Object List)^503~SC|#-1;<ALL>^504~EN.SC_LIST;"%;#0;#0^508~0^514~0^515~0^519~0^520~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'CATEGORY', 'Report Filter', 'Transaction Type', '', 2, 0, '501~s (Special List)^504~SP.GET_SYSTEM_LABEL_VALUES;#1;"Scheduling;"TransactionDialog;"Combo Lists;"Transaction Type^508~1^514~0^515~0', v_CHILD_OBJECT_ID);
            SO.PUT_SYSTEM_OBJECT_FOR_SCRIPT(v_OBJECT_ID, 'COMMODITY_ID', 'Report Filter', 'Commodity', '', 3, 0, '-3~0^-2~0^501~o (Object List)^503~IT_COMMODITY^508~1^514~0^515~0^519~0^520~0', v_CHILD_OBJECT_ID);
         END;
          
      END;
       
END;
END BUILD;
END ZBUILD_SCHEDULING_OBJECTS;
/

Declare
Begin
ZBUILD_SCHEDULING_OBJECTS.BUILD;
end;
/
