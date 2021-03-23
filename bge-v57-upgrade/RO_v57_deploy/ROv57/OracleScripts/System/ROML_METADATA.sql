-- clear out tables
delete roml_prefix_map;
delete roml_col_rules_map;
delete roml_entity_depends;
delete roml_entity;
-- and then rebuild
-- ROML_ENTITY
insert into roml_entity (roml_entity_nid, roml_entity_name, table_name, table_alias, is_object, is_data, save_id, id_column, use_seq, export_order, date1_col, date2_col)
                 values (1, 'PSE', 'PURCHASING_SELLING_ENTITY', 'PSE', 1, 0, 0, '', '', 2, '', '');
insert into roml_entity (roml_entity_nid, roml_entity_name, table_name, table_alias, is_object, is_data, save_id, id_column, use_seq, export_order, date1_col, date2_col)
                 values (2, 'CONTRACT', 'INTERCHANGE_CONTRACT', 'CONTRACT', 1, 0, 0, '', '', 1, 'BEGIN_DATE', 'END_DATE');
insert into roml_entity (roml_entity_nid, roml_entity_name, table_name, table_alias, is_object, is_data, save_id, id_column, use_seq, export_order, date1_col, date2_col)
                 values (3, 'TP_CONTRACT_NUMBER', 'TP_CONTRACT_NUMBER', '', 0, 0, 0, '', '', -1, '', '');
insert into roml_entity (roml_entity_nid, roml_entity_name, table_name, table_alias, is_object, is_data, save_id, id_column, use_seq, export_order, date1_col, date2_col)
                 values (4, 'TRANSMISSION_PROVIDER', 'TRANSMISSION_PROVIDER', 'TP', 1, 0, 0, '', '', 99, '', '');
insert into roml_entity (roml_entity_nid, roml_entity_name, table_name, table_alias, is_object, is_data, save_id, id_column, use_seq, export_order, date1_col, date2_col)
                 values (6, 'CONTRACT_PRODUCT_COMPONENT', 'CONTRACT_PRODUCT_COMPONENT', '', 0, 0, 0, '', '', -1, 'BEGIN_DATE', 'END_DATE');
insert into roml_entity (roml_entity_nid, roml_entity_name, table_name, table_alias, is_object, is_data, save_id, id_column, use_seq, export_order, date1_col, date2_col)
                 values (7, 'PRODUCT', 'PRODUCT', 'PRODUCT', 1, 0, 0, '', '', 3, '', '');
insert into roml_entity (roml_entity_nid, roml_entity_name, table_name, table_alias, is_object, is_data, save_id, id_column, use_seq, export_order, date1_col, date2_col)
                 values (8, 'COMPONENT', 'COMPONENT', 'COMPONENT', 1, 0, 0, '', '', 4, '', '');
insert into roml_entity (roml_entity_nid, roml_entity_name, table_name, table_alias, is_object, is_data, save_id, id_column, use_seq, export_order, date1_col, date2_col)
                 values (9, 'TRANSACTION', 'INTERCHANGE_TRANSACTION', 'TRANSACTION', 1, 0, 0, '', '', 5, 'BEGIN_DATE', 'END_DATE');
insert into roml_entity (roml_entity_nid, roml_entity_name, table_name, table_alias, is_object, is_data, save_id, id_column, use_seq, export_order, date1_col, date2_col)
                 values (16, 'SERVICE_ZONE', 'SERVICE_ZONE', 'SERVICE_ZONE', 1, 0, 0, '', '', 99, '', '');
insert into roml_entity (roml_entity_nid, roml_entity_name, table_name, table_alias, is_object, is_data, save_id, id_column, use_seq, export_order, date1_col, date2_col)
                 values (18, 'SC', 'SCHEDULE_COORDINATOR', 'SC', 1, 0, 0, '', '', 99, '', '');
insert into roml_entity (roml_entity_nid, roml_entity_name, table_name, table_alias, is_object, is_data, save_id, id_column, use_seq, export_order, date1_col, date2_col)
                 values (19, 'COMMODITY', 'IT_COMMODITY', 'COMMODITY', 1, 0, 0, '', '', 99, '', '');
insert into roml_entity (roml_entity_nid, roml_entity_name, table_name, table_alias, is_object, is_data, save_id, id_column, use_seq, export_order, date1_col, date2_col)
                 values (20, 'TRAN_GROUP', 'SCHEDULE_GROUP', 'SCHEDULE_GROUP', 1, 0, 0, '', '', -1, '', '');
insert into roml_entity (roml_entity_nid, roml_entity_name, table_name, table_alias, is_object, is_data, save_id, id_column, use_seq, export_order, date1_col, date2_col)
                 values (21, 'MARKET_PRICE', 'MARKET_PRICE', 'MARKET_PRICE', 1, 0, 0, '', '', 99, '', '');
insert into roml_entity (roml_entity_nid, roml_entity_name, table_name, table_alias, is_object, is_data, save_id, id_column, use_seq, export_order, date1_col, date2_col)
                 values (22, 'PRODUCT_COMPONENT', 'PRODUCT_COMPONENT', '', 0, 0, 0, '', '', -1, 'BEGIN_DATE', 'END_DATE');
insert into roml_entity (roml_entity_nid, roml_entity_name, table_name, table_alias, is_object, is_data, save_id, id_column, use_seq, export_order, date1_col, date2_col)
                 values (23, 'TEMPLATE', 'TEMPLATE', 'TEMPLATE', 1, 0, 0, '', '', 99, '', '');
insert into roml_entity (roml_entity_nid, roml_entity_name, table_name, table_alias, is_object, is_data, save_id, id_column, use_seq, export_order, date1_col, date2_col)
                 values (24, 'SERVICE_POINT', 'SERVICE_POINT', 'SERVICE_POINT', 1, 0, 0, '', '', 99, '', '');
insert into roml_entity (roml_entity_nid, roml_entity_name, table_name, table_alias, is_object, is_data, save_id, id_column, use_seq, export_order, date1_col, date2_col)
                 values (25, 'TRAN_PSE', 'PURCHASING_SELLING_ENTITY', 'PSE', 1, 0, 0, '', '', -1, '', '');
insert into roml_entity (roml_entity_nid, roml_entity_name, table_name, table_alias, is_object, is_data, save_id, id_column, use_seq, export_order, date1_col, date2_col)
                 values (26, 'INVOICE_GROUP', 'INVOICE_GROUP', 'INVOICE_GROUP', 1, 0, 0, '', '', 99, '', '');
insert into roml_entity (roml_entity_nid, roml_entity_name, table_name, table_alias, is_object, is_data, save_id, id_column, use_seq, export_order, date1_col, date2_col)
                 values (28, 'COMPONENT_BLOCK_COMPOSITE', 'COMPONENT_COMPOSITE', '', 0, 0, 0, '', '', -1, 'BEGIN_DATE', 'END_DATE');
insert into roml_entity (roml_entity_nid, roml_entity_name, table_name, table_alias, is_object, is_data, save_id, id_column, use_seq, export_order, date1_col, date2_col)
                 values (29, 'COMPONENT_BLOCK_RATE', 'COMPONENT_BLOCK_RATE', '', 0, 0, 0, '', '', -1, 'BEGIN_DATE', 'END_DATE');
insert into roml_entity (roml_entity_nid, roml_entity_name, table_name, table_alias, is_object, is_data, save_id, id_column, use_seq, export_order, date1_col, date2_col)
                 values (30, 'COMPONENT_COINCIDENT_PEAK', 'COMPONENT_COINCIDENT_PEAK', '', 0, 0, 0, '', '', -1, 'BEGIN_DATE', 'END_DATE');
insert into roml_entity (roml_entity_nid, roml_entity_name, table_name, table_alias, is_object, is_data, save_id, id_column, use_seq, export_order, date1_col, date2_col)
                 values (31, 'SYSTEM_LOAD', 'SYSTEM_LOAD', 'SYSTEM_LOAD', 1, 0, 0, '', '', 99, '', '');
insert into roml_entity (roml_entity_nid, roml_entity_name, table_name, table_alias, is_object, is_data, save_id, id_column, use_seq, export_order, date1_col, date2_col)
                 values (32, 'COMPONENT_CONVERSION_RATE', 'COMPONENT_CONVERSION_RATE', '', 0, 0, 0, '', '', -1, 'BEGIN_DATE', 'END_DATE');
insert into roml_entity (roml_entity_nid, roml_entity_name, table_name, table_alias, is_object, is_data, save_id, id_column, use_seq, export_order, date1_col, date2_col)
                 values (33, 'COMPONENT_FLAT_RATE', 'COMPONENT_FLAT_RATE', '', 0, 0, 0, '', '', -1, 'BEGIN_DATE', 'END_DATE');
insert into roml_entity (roml_entity_nid, roml_entity_name, table_name, table_alias, is_object, is_data, save_id, id_column, use_seq, export_order, date1_col, date2_col)
                 values (34, 'COMPONENT_FORMULA_INPUT', 'COMPONENT_FORMULA_INPUT', '', 0, 0, 0, '', '', -1, 'BEGIN_DATE', 'END_DATE');
insert into roml_entity (roml_entity_nid, roml_entity_name, table_name, table_alias, is_object, is_data, save_id, id_column, use_seq, export_order, date1_col, date2_col)
                 values (36, 'SCHEDULE_GROUP', 'SCHEDULE_GROUP', 'SCHEDULE_GROUP', 1, 0, 0, '', '', 99, '', '');
insert into roml_entity (roml_entity_nid, roml_entity_name, table_name, table_alias, is_object, is_data, save_id, id_column, use_seq, export_order, date1_col, date2_col)
                 values (37, 'COMPONENT_FORMULA_VARIABLE', 'COMPONENT_FORMULA_VARIABLE', '', 0, 0, 0, '', '', -1, 'BEGIN_DATE', 'END_DATE');
insert into roml_entity (roml_entity_nid, roml_entity_name, table_name, table_alias, is_object, is_data, save_id, id_column, use_seq, export_order, date1_col, date2_col)
                 values (38, 'COMPONENT_IMBALANCE', 'COMPONENT_IMBALANCE', '', 0, 0, 1, 'IMBALANCE_ID', '', -1, 'BEGIN_DATE', 'END_DATE');
insert into roml_entity (roml_entity_nid, roml_entity_name, table_name, table_alias, is_object, is_data, save_id, id_column, use_seq, export_order, date1_col, date2_col)
                 values (39, 'COMPONENT_IMBALANCE_BAND', 'COMPONENT_IMBALANCE_BAND', '', 0, 0, 0, '', '', -1, 'BEGIN_DATE', 'END_DATE');
insert into roml_entity (roml_entity_nid, roml_entity_name, table_name, table_alias, is_object, is_data, save_id, id_column, use_seq, export_order, date1_col, date2_col)
                 values (40, 'COMPONENT_PERCENTAGE', 'COMPONENT_PERCENTAGE', '', 0, 0, 0, '', '', -1, 'BEGIN_DATE', 'END_DATE');
insert into roml_entity (roml_entity_nid, roml_entity_name, table_name, table_alias, is_object, is_data, save_id, id_column, use_seq, export_order, date1_col, date2_col)
                 values (42, 'COMPONENT_TOU_RATE', 'COMPONENT_TOU_RATE', '', 0, 0, 0, '', '', -1, 'BEGIN_DATE', 'END_DATE');
insert into roml_entity (roml_entity_nid, roml_entity_name, table_name, table_alias, is_object, is_data, save_id, id_column, use_seq, export_order, date1_col, date2_col)
                 values (43, 'PERIOD', 'PERIOD', 'PERIOD', 1, 0, 0, '', '', 99, '', '');
insert into roml_entity (roml_entity_nid, roml_entity_name, table_name, table_alias, is_object, is_data, save_id, id_column, use_seq, export_order, date1_col, date2_col)
                 values (44, 'SEASON', 'SEASON', 'SEASON', 1, 0, 0, '', '', 99, '', '');
insert into roml_entity (roml_entity_nid, roml_entity_name, table_name, table_alias, is_object, is_data, save_id, id_column, use_seq, export_order, date1_col, date2_col)
                 values (45, 'SEASON_TEMPLATE', 'SEASON_TEMPLATE', '', 0, 0, 0, '', '', -1, '', '');
insert into roml_entity (roml_entity_nid, roml_entity_name, table_name, table_alias, is_object, is_data, save_id, id_column, use_seq, export_order, date1_col, date2_col)
                 values (46, 'SYSTEM_LABEL', 'SYSTEM_LABEL', '', 0, 0, 0, '', '', -1, '', '');
insert into roml_entity (roml_entity_nid, roml_entity_name, table_name, table_alias, is_object, is_data, save_id, id_column, use_seq, export_order, date1_col, date2_col)
                 values (48, 'COMPONENT_COMBINATION', 'COMPONENT_COMBINATION', '', 0, 0, 0, '', '', -1, 'BEGIN_DATE', 'END_DATE');
insert into roml_entity (roml_entity_nid, roml_entity_name, table_name, table_alias, is_object, is_data, save_id, id_column, use_seq, export_order, date1_col, date2_col)
                 values (49, 'COMPONENT_MARKET_PRICE', 'COMPONENT_MARKET_PRICE', '', 0, 0, 0, '', '', -1, 'BEGIN_DATE', 'END_DATE');
insert into roml_entity (roml_entity_nid, roml_entity_name, table_name, table_alias, is_object, is_data, save_id, id_column, use_seq, export_order, date1_col, date2_col)
                 values (50, 'COMPONENT_FORMULA_ITERATOR', 'COMPONENT_FORMULA_ITERATOR', '', 0, 0, 0, '', '', -1, 'BEGIN_DATE', 'END_DATE');
insert into roml_entity (roml_entity_nid, roml_entity_name, table_name, table_alias, is_object, is_data, save_id, id_column, use_seq, export_order, date1_col, date2_col)
                 values (51, 'SYSTEM_REALM', 'SYSTEM_REALM', 'REALM', 1, 0, 0, '', '', 99, '', '');
insert into roml_entity (roml_entity_nid, roml_entity_name, table_name, table_alias, is_object, is_data, save_id, id_column, use_seq, export_order, date1_col, date2_col)
                 values (53, 'GEOGRAPHY', 'GEOGRAPHY', 'GEOGRAPHY', 1, 0, 0, '', '', 99, '', '');
insert into roml_entity (roml_entity_nid, roml_entity_name, table_name, table_alias, is_object, is_data, save_id, id_column, use_seq, export_order, date1_col, date2_col)
                 values (55, 'IT_SCHEDULE', 'IT_SCHEDULE', '', 0, 1, 0, '', '', -1, 'SCHEDULE_DATE', '');
insert into roml_entity (roml_entity_nid, roml_entity_name, table_name, table_alias, is_object, is_data, save_id, id_column, use_seq, export_order, date1_col, date2_col)
                 values (56, 'BILLING_STATEMENT', 'BILLING_STATEMENT', '', 0, 1, 1, 'CHARGE_ID', 'BID', -1, 'STATEMENT_DATE', '');
insert into roml_entity (roml_entity_nid, roml_entity_name, table_name, table_alias, is_object, is_data, save_id, id_column, use_seq, export_order, date1_col, date2_col)
                 values (57, 'MARKET_PRICE_VALUE', 'MARKET_PRICE_VALUE', '', 0, 1, 0, '', '', -1, 'PRICE_DATE', '');
insert into roml_entity (roml_entity_nid, roml_entity_name, table_name, table_alias, is_object, is_data, save_id, id_column, use_seq, export_order, date1_col, date2_col)
                 values (58, 'STATEMENT_TYPE', 'STATEMENT_TYPE', 'STATEMENT_TYPE', 1, 0, 0, '', '', 99, '', '');
insert into roml_entity (roml_entity_nid, roml_entity_name, table_name, table_alias, is_object, is_data, save_id, id_column, use_seq, export_order, date1_col, date2_col)
                 values (59, 'BILLING_CHARGE', 'BILLING_CHARGE', '', 0, 1, 0, '', '', -1, '', '');
insert into roml_entity (roml_entity_nid, roml_entity_name, table_name, table_alias, is_object, is_data, save_id, id_column, use_seq, export_order, date1_col, date2_col)
                 values (60, 'COMBINATION_CHARGE', 'COMBINATION_CHARGE', '', 0, 1, 0, '', '', -1, '', '');
insert into roml_entity (roml_entity_nid, roml_entity_name, table_name, table_alias, is_object, is_data, save_id, id_column, use_seq, export_order, date1_col, date2_col)
                 values (61, 'CONVERSION_CHARGE', 'CONVERSION_CHARGE', '', 0, 1, 0, '', '', -1, '', '');
insert into roml_entity (roml_entity_nid, roml_entity_name, table_name, table_alias, is_object, is_data, save_id, id_column, use_seq, export_order, date1_col, date2_col)
                 values (62, 'FORMULA_CHARGE', 'FORMULA_CHARGE', '', 0, 1, 0, '', '', -1, '', '');
insert into roml_entity (roml_entity_nid, roml_entity_name, table_name, table_alias, is_object, is_data, save_id, id_column, use_seq, export_order, date1_col, date2_col)
                 values (63, 'FORMULA_CHARGE_ITERATOR_NAME', 'FORMULA_CHARGE_ITERATOR_NAME', '', 0, 1, 0, '', '', -1, '', '');
insert into roml_entity (roml_entity_nid, roml_entity_name, table_name, table_alias, is_object, is_data, save_id, id_column, use_seq, export_order, date1_col, date2_col)
                 values (64, 'FORMULA_CHARGE_ITERATOR', 'FORMULA_CHARGE_ITERATOR', '', 0, 1, 0, '', '', -1, '', '');
insert into roml_entity (roml_entity_nid, roml_entity_name, table_name, table_alias, is_object, is_data, save_id, id_column, use_seq, export_order, date1_col, date2_col)
                 values (65, 'FORMULA_CHARGE_VARIABLE', 'FORMULA_CHARGE_VARIABLE', '', 0, 1, 0, '', '', -1, '', '');
insert into roml_entity (roml_entity_nid, roml_entity_name, table_name, table_alias, is_object, is_data, save_id, id_column, use_seq, export_order, date1_col, date2_col)
                 values (66, 'FTR_CHARGE', 'FTR_CHARGE', '', 0, 1, 0, '', '', -1, '', '');
insert into roml_entity (roml_entity_nid, roml_entity_name, table_name, table_alias, is_object, is_data, save_id, id_column, use_seq, export_order, date1_col, date2_col)
                 values (67, 'IMBALANCE_CHARGE', 'IMBALANCE_CHARGE', '', 0, 1, 0, '', '', -1, '', '');
insert into roml_entity (roml_entity_nid, roml_entity_name, table_name, table_alias, is_object, is_data, save_id, id_column, use_seq, export_order, date1_col, date2_col)
                 values (68, 'IMBALANCE_CHARGE_BAND', 'IMBALANCE_CHARGE_BAND', '', 0, 1, 0, '', '', -1, '', '');
insert into roml_entity (roml_entity_nid, roml_entity_name, table_name, table_alias, is_object, is_data, save_id, id_column, use_seq, export_order, date1_col, date2_col)
                 values (69, 'LMP_CHARGE', 'LMP_CHARGE', '', 0, 1, 0, '', '', -1, '', '');
insert into roml_entity (roml_entity_nid, roml_entity_name, table_name, table_alias, is_object, is_data, save_id, id_column, use_seq, export_order, date1_col, date2_col)
                 values (70, 'TAX_CHARGE', 'TAX_CHARGE', '', 0, 1, 0, '', '', -1, '', '');
insert into roml_entity (roml_entity_nid, roml_entity_name, table_name, table_alias, is_object, is_data, save_id, id_column, use_seq, export_order, date1_col, date2_col)
                 values (71, 'TRANSMISSION_CHARGE', 'TRANSMISSION_CHARGE', '', 0, 1, 0, '', '', -1, '', '');
insert into roml_entity (roml_entity_nid, roml_entity_name, table_name, table_alias, is_object, is_data, save_id, id_column, use_seq, export_order, date1_col, date2_col)
                 values (72, 'BILLING_CHARGE_DISPUTE', 'BILLING_CHARGE_DISPUTE', '', 0, 1, 0, '', '', -1, 'STATEMENT_DATE', '');
insert into roml_entity (roml_entity_nid, roml_entity_name, table_name, table_alias, is_object, is_data, save_id, id_column, use_seq, export_order, date1_col, date2_col)
                 values (73, 'IT_TRAIT_SCHEDULE', 'IT_TRAIT_SCHEDULE', '', 0, 1, 0, '', '', -1, 'SCHEDULE_DATE', '');
insert into roml_entity (roml_entity_nid, roml_entity_name, table_name, table_alias, is_object, is_data, save_id, id_column, use_seq, export_order, date1_col, date2_col)
                 values (74, 'IT_TRAIT_SCHEDULE_STATUS', 'IT_TRAIT_SCHEDULE_STATUS', '', 0, 1, 0, '', '', -1, 'SCHEDULE_DATE', '');
insert into roml_entity (roml_entity_nid, roml_entity_name, table_name, table_alias, is_object, is_data, save_id, id_column, use_seq, export_order, date1_col, date2_col)
                 values (75, 'INVOICE', 'INVOICE', '', 0, 1, 1, 'INVOICE_ID', 'BID', -1, 'BEGIN_DATE', '');
insert into roml_entity (roml_entity_nid, roml_entity_name, table_name, table_alias, is_object, is_data, save_id, id_column, use_seq, export_order, date1_col, date2_col)
                 values (76, 'INVOICE_USER_LINE_ITEM', 'INVOICE_USER_LINE_ITEM', '', 0, 1, 0, '', '', -1, '', '');
insert into roml_entity (roml_entity_nid, roml_entity_name, table_name, table_alias, is_object, is_data, save_id, id_column, use_seq, export_order, date1_col, date2_col)
                 values (77, 'INVOICE_LINE_ITEM', 'INVOICE_LINE_ITEM', '', 0, 1, 0, '', '', -1, '', '');
insert into roml_entity (roml_entity_nid, roml_entity_name, table_name, table_alias, is_object, is_data, save_id, id_column, use_seq, export_order, date1_col, date2_col)
                 values (78, 'TX_SUB_STATION', 'TX_SUB_STATION', 'SUB_STATION', 1, 0, 0, '', '', 99, 'BEGIN_DATE', 'END_DATE');
insert into roml_entity (roml_entity_nid, roml_entity_name, table_name, table_alias, is_object, is_data, save_id, id_column, use_seq, export_order, date1_col, date2_col)
                 values (79, 'TX_SUB_STATION_METER', 'TX_SUB_STATION_METER', 'METER', 1, 0, 0, '', '', 99, 'BEGIN_DATE', 'END_DATE');
insert into roml_entity (roml_entity_nid, roml_entity_name, table_name, table_alias, is_object, is_data, save_id, id_column, use_seq, export_order, date1_col, date2_col)
                 values (80, 'TX_SUB_STATION_METER_POINT', 'TX_SUB_STATION_METER_POINT', 'METER_POINT', 1, 0, 0, '', '', 99, 'BEGIN_DATE', 'END_DATE');
insert into roml_entity (roml_entity_nid, roml_entity_name, table_name, table_alias, is_object, is_data, save_id, id_column, use_seq, export_order, date1_col, date2_col)
                 values (81, 'MEASUREMENT_SOURCE', 'MEASUREMENT_SOURCE', 'MEASUREMENT_SOURCE', 1, 0, 0, '', '', 99, 'BEGIN_DATE', 'END_DATE');
insert into roml_entity (roml_entity_nid, roml_entity_name, table_name, table_alias, is_object, is_data, save_id, id_column, use_seq, export_order, date1_col, date2_col)
                 values (82, 'MEASUREMENT_SOURCE_VALUE', 'MEASUREMENT_SOURCE_VALUE', '', 0, 1, 0, '', '', -1, 'SOURCE_DATE', '');
insert into roml_entity (roml_entity_nid, roml_entity_name, table_name, table_alias, is_object, is_data, save_id, id_column, use_seq, export_order, date1_col, date2_col)
                 values (83, 'TX_SUB_STATION_METER_PT_VALUE', 'TX_SUB_STATION_METER_PT_VALUE', '', 0, 1, 0, '', '', -1, 'METER_DATE', '');
insert into roml_entity (roml_entity_nid, roml_entity_name, table_name, table_alias, is_object, is_data, save_id, id_column, use_seq, export_order, date1_col, date2_col)
                 values (84, 'TX_SUB_STATION_METER_OWNER', 'TX_SUB_STATION_METER_OWNER', '', 0, 0, 0, '', '', -1, 'BEGIN_DATE', 'END_DATE');
insert into roml_entity (roml_entity_nid, roml_entity_name, table_name, table_alias, is_object, is_data, save_id, id_column, use_seq, export_order, date1_col, date2_col)
                 values (85, 'TX_SUB_STATION_METER_PT_SOURCE', 'TX_SUB_STATION_METER_PT_SOURCE', '', 0, 0, 0, '', '', -1, 'BEGIN_DATE', 'END_DATE');
insert into roml_entity (roml_entity_nid, roml_entity_name, table_name, table_alias, is_object, is_data, save_id, id_column, use_seq, export_order, date1_col, date2_col)
                 values (87, 'DATA_VALIDATION_RULE', 'DATA_VALIDATION_RULE', '', 0, 0, 0, '', '', -1, 'BEGIN_DATE', 'END_DATE');
insert into roml_entity (roml_entity_nid, roml_entity_name, table_name, table_alias, is_object, is_data, save_id, id_column, use_seq, export_order, date1_col, date2_col)
                 values (88, 'RESOURCE', 'SUPPLY_RESOURCE', 'RESOURCE', 1, 0, 0, '', '', 99, '', '');
insert into roml_entity (roml_entity_nid, roml_entity_name, table_name, table_alias, is_object, is_data, save_id, id_column, use_seq, export_order, date1_col, date2_col)
                 values (89, 'RESOURCE_GROUP', 'SUPPLY_RESOURCE_GROUP', 'RESOURCE_GROUP', 1, 0, 0, '', '', 99, '', '');
insert into roml_entity (roml_entity_nid, roml_entity_name, table_name, table_alias, is_object, is_data, save_id, id_column, use_seq, export_order, date1_col, date2_col)
                 values (90, 'RESOURCE_METER', 'SUPPLY_RESOURCE_METER', '', 0, 0, 0, '', '', -1, 'BEGIN_DATE', 'END_DATE');
insert into roml_entity (roml_entity_nid, roml_entity_name, table_name, table_alias, is_object, is_data, save_id, id_column, use_seq, export_order, date1_col, date2_col)
                 values (91, 'RESOURCE_OWNER', 'SUPPLY_RESOURCE_OWNER', '', 0, 0, 0, '', '', -1, 'BEGIN_DATE', 'END_DATE');
insert into roml_entity (roml_entity_nid, roml_entity_name, table_name, table_alias, is_object, is_data, save_id, id_column, use_seq, export_order, date1_col, date2_col)
                 values (92, 'CALCULATION_PROCESS', 'CALCULATION_PROCESS', 'CALC_PROCESS', 1, 0, 0, '', '', 99, '', '');
insert into roml_entity (roml_entity_nid, roml_entity_name, table_name, table_alias, is_object, is_data, save_id, id_column, use_seq, export_order, date1_col, date2_col)
                 values (93, 'CALCULATION_PROCESS_GLOBAL', 'CALCULATION_PROCESS_GLOBAL', '', 0, 0, 0, '', '', -1, '', '');
insert into roml_entity (roml_entity_nid, roml_entity_name, table_name, table_alias, is_object, is_data, save_id, id_column, use_seq, export_order, date1_col, date2_col)
                 values (95, 'CALCULATION_PROCESS_STEP', 'CALCULATION_PROCESS_STEP', '', 0, 0, 1, 'CALC_STEP_ID', '', -1, 'BEGIN_DATE', 'END_DATE');
insert into roml_entity (roml_entity_nid, roml_entity_name, table_name, table_alias, is_object, is_data, save_id, id_column, use_seq, export_order, date1_col, date2_col)
                 values (96, 'CALCULATION_PROCESS_STEP_PARM', 'CALCULATION_PROCESS_STEP_PARM', '', 0, 0, 0, '', '', -1, '', '');
insert into roml_entity (roml_entity_nid, roml_entity_name, table_name, table_alias, is_object, is_data, save_id, id_column, use_seq, export_order, date1_col, date2_col)
                 values (97, 'CALCULATION_RUN', 'CALCULATION_RUN', '', 0, 1, 1, 'CALC_RUN_ID', 'RUN_ID', -1, 'RUN_DATE', '');
insert into roml_entity (roml_entity_nid, roml_entity_name, table_name, table_alias, is_object, is_data, save_id, id_column, use_seq, export_order, date1_col, date2_col)
                 values (98, 'CALCULATION_RUN_GLOBAL', 'CALCULATION_RUN_GLOBAL', '', 0, 1, 0, '', '', -1, '', '');
insert into roml_entity (roml_entity_nid, roml_entity_name, table_name, table_alias, is_object, is_data, save_id, id_column, use_seq, export_order, date1_col, date2_col)
                 values (99, 'CALCULATION_RUN_STEP', 'CALCULATION_RUN_STEP', '', 0, 1, 1, 'CHARGE_ID', 'BID', -1, '', '');
insert into roml_entity (roml_entity_nid, roml_entity_name, table_name, table_alias, is_object, is_data, save_id, id_column, use_seq, export_order, date1_col, date2_col)
                 values (100, 'CALCULATION_RUN_STEP_PARM', 'CALCULATION_RUN_STEP_PARM', '', 0, 1, 0, '', '', -1, '', '');
insert into roml_entity (roml_entity_nid, roml_entity_name, table_name, table_alias, is_object, is_data, save_id, id_column, use_seq, export_order, date1_col, date2_col)
                 values (101, 'COMPONENT_FORMULA_RESULT', 'COMPONENT_FORMULA_RESULT', '', 0, 0, 0, '', '', -1, 'BEGIN_DATE', 'END_DATE');
insert into roml_entity (roml_entity_nid, roml_entity_name, table_name, table_alias, is_object, is_data, save_id, id_column, use_seq, export_order, date1_col, date2_col)
                 values (102, 'ENTITY_GROUP', 'ENTITY_GROUP', 'ENTITY_GROUP', 1, 0, 0, '', '', 99, '', '');
insert into roml_entity (roml_entity_nid, roml_entity_name, table_name, table_alias, is_object, is_data, save_id, id_column, use_seq, export_order, date1_col, date2_col)
                 values (103, 'ENTITY_GROUP_ASSIGNMENT', 'ENTITY_GROUP_ASSIGNMENT', '', 0, 0, 0, '', '', -1, 'BEGIN_DATE', 'END_DATE');
insert into roml_entity (roml_entity_nid, roml_entity_name, table_name, table_alias, is_object, is_data, save_id, id_column, use_seq, export_order, date1_col, date2_col)
                 values (104, 'COMPONENT_FORMULA_PARAMETER', 'COMPONENT_FORMULA_PARAMETER', '', 0, 0, 0, '', '', -1, '', '');
insert into roml_entity (roml_entity_nid, roml_entity_name, table_name, table_alias, is_object, is_data, save_id, id_column, use_seq, export_order, date1_col, date2_col)
                 values (106, 'SYSTEM_REALM_COLUMN', 'SYSTEM_REALM_COLUMN', '', 0, 0, 0, '', '', -1, '', '');
insert into roml_entity (roml_entity_nid, roml_entity_name, table_name, table_alias, is_object, is_data, save_id, id_column, use_seq, export_order, date1_col, date2_col)
                 values (107, 'COMPONENT_FORMULA_ENTITY_REF', 'COMPONENT_FORMULA_ENTITY_REF', '', 0, 0, 0, '', '', 0, '', '');
insert into roml_entity (roml_entity_nid, roml_entity_name, table_name, table_alias, is_object, is_data, save_id, id_column, use_seq, export_order, date1_col, date2_col)
                 values (108, 'EXTERNAL_SYSTEM_IDENTIFIER', 'EXTERNAL_SYSTEM_IDENTIFIER', '', 0, 0, 0, '', '', -1, '', '');
insert into roml_entity (roml_entity_nid, roml_entity_name, table_name, table_alias, is_object, is_data, save_id, id_column, use_seq, export_order, date1_col, date2_col)
                 values (110, 'ANCILLARY_SERVICE', 'ANCILLARY_SERVICE', 'ANCILLARY_SERVICE', 1, 0, 0, '', '', 99, '', '');
insert into roml_entity (roml_entity_nid, roml_entity_name, table_name, table_alias, is_object, is_data, save_id, id_column, use_seq, export_order, date1_col, date2_col)
                 values (111, 'ENTITY_ATTRIBUTE', 'ENTITY_ATTRIBUTE', 'ATTRIBUTE', 1, 0, 0, '', '', 99, '', '');
insert into roml_entity (roml_entity_nid, roml_entity_name, table_name, table_alias, is_object, is_data, save_id, id_column, use_seq, export_order, date1_col, date2_col)
                 values (112, 'TEMPORAL_ENTITY_ATTRIBUTE', 'TEMPORAL_ENTITY_ATTRIBUTE', '', 0, 0, 0, '', '', -1, 'BEGIN_DATE', 'END_DATE');
insert into roml_entity (roml_entity_nid, roml_entity_name, table_name, table_alias, is_object, is_data, save_id, id_column, use_seq, export_order, date1_col, date2_col)
                 values (113, 'ENERGY_DISTRIBUTION_COMPANY', 'ENERGY_DISTRIBUTION_COMPANY', 'EDC', 1, NULL, NULL, '', '', 99, '', '');
-- ROML_ENTITY_DEPENDS
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (1, 56, 'ENTITY_ID=PSE_ID');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (1, 72, 'ENTITY_ID=PSE_ID');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (2, 1, 'PSE_ID=BILLING_ENTITY_ID');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (2, 3, 'CONTRACT_ID');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (2, 6, 'CONTRACT_ID');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (3, 4, 'TP_ID');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (6, 7, 'PRODUCT_ID');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (7, 22, 'PRODUCT_ID');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (7, 108, 'ENTITY_ID=PRODUCT_ID;ENTITY_DOMAIN_ID=-620');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (8, 19, 'COMMODITY_ID=LMP_BASE_COMMODITY_ID');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (8, 19, 'COMMODITY_ID=LMP_COMMODITY_ID');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (8, 21, 'MARKET_PRICE_ID');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (8, 23, 'TEMPLATE_ID');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (8, 24, 'SERVICE_POINT_ID');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (8, 26, 'INVOICE_GROUP_ID');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (8, 28, 'COMPONENT_ID');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (8, 29, 'COMPONENT_ID');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (8, 30, 'COMPONENT_ID');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (8, 32, 'COMPONENT_ID');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (8, 33, 'COMPONENT_ID');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (8, 34, 'COMPONENT_ID');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (8, 37, 'COMPONENT_ID');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (8, 38, 'COMPONENT_ID');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (8, 40, 'COMPONENT_ID');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (8, 42, 'COMPONENT_ID');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (8, 48, 'COMPONENT_ID');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (8, 49, 'COMPONENT_ID');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (8, 50, 'COMPONENT_ID');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (8, 101, 'COMPONENT_ID');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (8, 104, 'COMPONENT_ID');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (8, 107, 'COMPONENT_ID');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (8, 108, 'ENTITY_ID=COMPONENT_ID;ENTITY_DOMAIN_ID=-630');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (8, 110, 'ANCILLARY_SERVICE_ID');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (8, 112, 'OWNER_ENTITY_ID=COMPONENT_ID;ENTITY_DOMAIN_ID=-630');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (9, 9, 'TRANSACTION_ID=LINK_TRANSACTION_ID');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (9, 9, 'TRANSACTION_ID=TX_TRANSACTION_ID');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (9, 16, 'SERVICE_ZONE_ID=ZOD_ID');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (9, 16, 'SERVICE_ZONE_ID=ZOR_ID');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (9, 18, 'SC_ID');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (9, 19, 'COMMODITY_ID');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (9, 20, 'SCHEDULE_GROUP_ID');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (9, 21, 'MARKET_PRICE_ID');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (9, 24, 'SERVICE_POINT_ID=POD_ID');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (9, 24, 'SERVICE_POINT_ID=POR_ID');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (9, 24, 'SERVICE_POINT_ID=SINK_ID');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (9, 24, 'SERVICE_POINT_ID=SOURCE_ID');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (9, 25, 'PSE_ID=PURCHASER_ID');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (9, 25, 'PSE_ID=SELLER_ID');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (9, 55, 'TRANSACTION_ID');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (9, 73, 'TRANSACTION_ID');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (9, 74, 'TRANSACTION_ID');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (9, 88, 'RESOURCE_ID');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (21, 16, 'SERVICE_ZONE_ID=ZOD_ID');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (21, 18, 'SC_ID');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (21, 19, 'COMMODITY_ID');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (21, 24, 'SERVICE_POINT_ID=POD_ID');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (21, 57, 'MARKET_PRICE_ID');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (22, 8, 'COMPONENT_ID');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (23, 45, 'TEMPLATE_ID');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (23, 108, 'ENTITY_ID=TEMPLATE_ID;ENTITY_DOMAIN_ID=-810');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (24, 16, 'SERVICE_ZONE_ID');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (28, 53, 'GEOGRAPHY_ID=SUB_COMPONENT_ID;$SUB_COMPONENT_TYPE=''GEOGRAPHY''');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (29, 53, 'GEOGRAPHY_ID=SUB_COMPONENT_ID;$SUB_COMPONENT_TYPE=''GEOGRAPHY''');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (30, 31, 'SYSTEM_LOAD_ID=A_SYSTEM_LOAD_ID');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (30, 31, 'SYSTEM_LOAD_ID=B_SYSTEM_LOAD_ID');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (30, 53, 'GEOGRAPHY_ID=SUB_COMPONENT_ID;$SUB_COMPONENT_TYPE=''GEOGRAPHY''');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (32, 36, 'SCHEDULE_GROUP_ID');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (32, 53, 'GEOGRAPHY_ID=SUB_COMPONENT_ID;$SUB_COMPONENT_TYPE=''GEOGRAPHY''');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (33, 53, 'GEOGRAPHY_ID=SUB_COMPONENT_ID;$SUB_COMPONENT_TYPE=''GEOGRAPHY''');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (34, 9, 'TRANSACTION_ID=ENTITY_ID;$ENTITY_DOMAIN_ID=-200;$ENTITY_TYPE=''E''');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (34, 21, 'MARKET_PRICE_ID=ENTITY_ID;$ENTITY_DOMAIN_ID=-610;$ENTITY_TYPE=''E''');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (34, 51, 'REALM_ID=ENTITY_ID;$ENTITY_TYPE=''R''');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (34, 53, 'GEOGRAPHY_ID=SUB_COMPONENT_ID;$SUB_COMPONENT_TYPE=''GEOGRAPHY''');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (34, 78, 'SUB_STATION_ID=ENTITY_ID;$ENTITY_DOMAIN_ID=-380;$ENTITY_TYPE=''E''');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (34, 79, 'METER_ID=ENTITY_ID;$ENTITY_DOMAIN_ID=-390;$ENTITY_TYPE=''E''');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (34, 80, 'METER_POINT_ID=ENTITY_ID;$ENTITY_DOMAIN_ID=-1030;$ENTITY_TYPE=''E''');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (34, 81, 'MEASUREMENT_SOURCE_ID=ENTITY_ID;$ENTITY_DOMAIN_ID=-1040;$ENTITY_TYPE=''E''');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (34, 102, 'ENTITY_GROUP_ID=ENTITY_ID;$ENTITY_TYPE=''G''');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (36, 9, 'SCHEDULE_GROUP_ID');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (37, 53, 'GEOGRAPHY_ID=SUB_COMPONENT_ID;$SUB_COMPONENT_TYPE=''GEOGRAPHY''');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (38, 8, 'COMPONENT_ID=BASE_COMPONENT_ID');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (38, 39, 'BAND_ID');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (38, 53, 'GEOGRAPHY_ID=SUB_COMPONENT_ID;$SUB_COMPONENT_TYPE=''GEOGRAPHY''');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (42, 43, 'PERIOD_ID');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (42, 53, 'GEOGRAPHY_ID=SUB_COMPONENT_ID;$SUB_COMPONENT_TYPE=''GEOGRAPHY''');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (43, 108, 'ENTITY_ID=PERIOD_ID;ENTITY_DOMAIN_ID=-790');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (45, 43, 'PERIOD_ID');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (45, 44, 'SEASON_ID');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (48, 8, 'COMPONENT_ID=COMBINED_COMPONENT_ID');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (48, 53, 'GEOGRAPHY_ID=SUB_COMPONENT_ID;$SUB_COMPONENT_TYPE=''GEOGRAPHY''');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (49, 53, 'GEOGRAPHY_ID=SUB_COMPONENT_ID;$SUB_COMPONENT_TYPE=''GEOGRAPHY''');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (50, 53, 'GEOGRAPHY_ID=SUB_COMPONENT_ID;$SUB_COMPONENT_TYPE=''GEOGRAPHY''');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (51, 106, 'REALM_ID');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (53, 53, 'GEOGRAPHY_ID=PARENT_GEOGRAPHY_ID');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (55, 58, 'STATEMENT_TYPE_ID=SCHEDULE_TYPE');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (56, 7, 'PRODUCT_ID');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (56, 8, 'COMPONENT_ID');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (56, 58, 'STATEMENT_TYPE_ID=STATEMENT_TYPE');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (56, 59, 'CHARGE_ID');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (56, 60, 'CHARGE_ID');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (56, 61, 'CHARGE_ID');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (56, 62, 'CHARGE_ID');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (56, 63, 'CHARGE_ID');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (56, 64, 'CHARGE_ID');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (56, 65, 'CHARGE_ID');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (56, 66, 'CHARGE_ID');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (56, 67, 'CHARGE_ID');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (56, 68, 'CHARGE_ID');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (56, 69, 'CHARGE_ID');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (56, 70, 'CHARGE_ID');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (56, 71, 'CHARGE_ID');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (59, 24, 'SERVICE_POINT_ID');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (60, 8, 'COMPONENT_ID');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (60, 59, 'CHARGE_ID=COMBINED_CHARGE_ID');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (60, 60, 'CHARGE_ID=COMBINED_CHARGE_ID');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (60, 61, 'CHARGE_ID=COMBINED_CHARGE_ID');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (60, 62, 'CHARGE_ID=COMBINED_CHARGE_ID');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (60, 63, 'CHARGE_ID=COMBINED_CHARGE_ID');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (60, 64, 'CHARGE_ID=COMBINED_CHARGE_ID');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (60, 65, 'CHARGE_ID=COMBINED_CHARGE_ID');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (60, 66, 'CHARGE_ID=COMBINED_CHARGE_ID');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (60, 67, 'CHARGE_ID=COMBINED_CHARGE_ID');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (60, 68, 'CHARGE_ID=COMBINED_CHARGE_ID');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (60, 69, 'CHARGE_ID=COMBINED_CHARGE_ID');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (60, 70, 'CHARGE_ID=COMBINED_CHARGE_ID');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (60, 71, 'CHARGE_ID=COMBINED_CHARGE_ID');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (61, 36, 'SCHEDULE_GROUP_ID');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (66, 24, 'SERVICE_POINT_ID=DELIVERY_POINT_ID');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (66, 24, 'SERVICE_POINT_ID=SINK_ID');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (66, 24, 'SERVICE_POINT_ID=SOURCE_ID');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (69, 24, 'SERVICE_POINT_ID=DELIVERY_POINT_ID');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (69, 24, 'SERVICE_POINT_ID=SINK_ID');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (69, 24, 'SERVICE_POINT_ID=SOURCE_ID');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (70, 7, 'PRODUCT_ID');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (70, 8, 'COMPONENT_ID');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (70, 24, 'SERVICE_POINT_ID');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (70, 53, 'GEOGRAPHY_ID');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (71, 9, 'TRANSACTION_ID');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (72, 7, 'PRODUCT_ID');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (72, 8, 'COMPONENT_ID');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (72, 58, 'STATEMENT_TYPE_ID=STATEMENT_TYPE');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (73, 58, 'STATEMENT_TYPE_ID');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (75, 58, 'STATEMENT_TYPE_ID=STATEMENT_TYPE');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (76, 75, 'INVOICE_ID');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (77, 58, 'STATEMENT_TYPE_ID=STATEMENT_TYPE');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (79, 24, 'SERVICE_POINT_ID');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (79, 78, 'SUB_STATION_ID');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (79, 79, 'METER_ID=REF_METER_ID');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (79, 84, 'METER_ID');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (80, 79, 'METER_ID');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (80, 83, 'METER_POINT_ID');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (80, 85, 'METER_POINT_ID');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (80, 87, 'ENTITY_ID=METER_POINT_ID;ENTITY_DOMAIN_ID=-1030');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (81, 82, 'MEASUREMENT_SOURCE_ID');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (83, 81, 'MEASUREMENT_SOURCE_ID');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (84, 25, 'PSE_ID=OWNER_ID');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (84, 25, 'PSE_ID=PARTY1_ID');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (84, 25, 'PSE_ID=PARTY2_ID');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (85, 81, 'MEASUREMENT_SOURCE_ID');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (88, 24, 'SERVICE_POINT_ID');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (88, 89, 'RESOURCE_GROUP_ID');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (88, 90, 'RESOURCE_ID');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (88, 91, 'RESOURCE_ID');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (89, 16, 'SERVICE_ZONE_ID');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (90, 79, 'METER_ID');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (91, 25, 'PSE_ID=OWNER_ID');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (92, 51, 'REALM_ID=CONTEXT_REALM_ID');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (92, 93, 'CALC_PROCESS_ID');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (92, 95, 'CALC_PROCESS_ID');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (92, 102, 'ENTITY_GROUP_ID=CONTEXT_GROUP_ID');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (95, 8, 'COMPONENT_ID');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (95, 96, 'CALC_STEP_ID');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (101, 9, 'TRANSACTION_ID=ENTITY_ID;$ENTITY_DOMAIN_ID=-200;$ENTITY_TYPE=''E''');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (101, 21, 'MARKET_PRICE_ID=ENTITY_ID;$ENTITY_DOMAIN_ID=-610;$ENTITY_TYPE=''E''');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (101, 51, 'REALM_ID=ENTITY_ID;$ENTITY_TYPE=''R''');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (101, 53, 'GEOGRAPHY_ID=SUB_COMPONENT_ID;$SUB_COMPONENT_TYPE=''GEOGRAPHY''');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (101, 78, 'SUB_STATION_ID=ENTITY_ID;$ENTITY_DOMAIN_ID=-380;$ENTITY_TYPE=''E''');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (101, 79, 'METER_ID=ENTITY_ID;$ENTITY_DOMAIN_ID=-390;$ENTITY_TYPE=''E''');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (101, 80, 'METER_POINT_ID=ENTITY_ID;$ENTITY_DOMAIN_ID=-1030;$ENTITY_TYPE=''E''');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (101, 81, 'MEASUREMENT_SOURCE_ID=ENTITY_ID;$ENTITY_DOMAIN_ID=-1040;$ENTITY_TYPE=''E''');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (101, 102, 'ENTITY_GROUP_ID=ENTITY_ID;$ENTITY_TYPE=''G''');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (102, 102, 'ENTITY_GROUP_ID=PARENT_GROUP_ID');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (102, 108, 'ENTITY_ID=ENTITY_GROUP_ID;ENTITY_DOMAIN_ID=-1010');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (102, 112, 'OWNER_ENTITY_ID=ENTITY_GROUP_ID;ENTITY_DOMAIN_ID=-1010');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (107, 8, 'COMPONENT_ID=ENTITY_ID;$ENTITY_DOMAIN_ID=-630');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (107, 21, 'MARKET_PRICE_ID=ENTITY_ID;$ENTITY_DOMAIN_ID=-610');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (107, 23, 'TEMPLATE_ID=ENTITY_ID;$ENTITY_DOMAIN_ID=-810');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (107, 43, 'PERIOD_ID=ENTITY_ID;$ENTITY_DOMAIN_ID=-790');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (107, 102, 'ENTITY_GROUP_ID=ENTITY_ID;$ENTITY_DOMAIN_ID=-1010');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (107, 110, 'ANCILLARY_SERVICE_ID=ENTITY_ID;$ENTITY_DOMAIN_ID=-320');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (107, 113, 'EDC_ID=ENTITY_ID;$ENTITY_DOMAIN_ID=-100');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (110, 108, 'ENTITY_ID=ANCILLARY_SERVICE_ID;ENTITY_DOMAIN_ID=-320');
insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)
                         values (112, 111, 'ATTRIBUTE_ID');
-- ROML_COLUMN_RULES_MAP
insert into roml_col_rules_map (column_name, rule, roml_entity_nid, table_name)
                        values ('ENTITY_ID', '*', 56, 'PURCHASING_SELLING_ENTITY');
insert into roml_col_rules_map (column_name, rule, roml_entity_nid, table_name)
                        values ('ENTITY_ID', 'ENTITY_DOMAIN_ID=-100', 107, 'ENERGY_DISTRIBUTION_COMPANY');
insert into roml_col_rules_map (column_name, rule, roml_entity_nid, table_name)
                        values ('ENTITY_ID', 'ENTITY_DOMAIN_ID=-1010', 107, 'ENTITY_GROUP');
insert into roml_col_rules_map (column_name, rule, roml_entity_nid, table_name)
                        values ('ENTITY_ID', 'ENTITY_DOMAIN_ID=-1030', 87, 'TX_SUB_STATION_METER_POINT');
insert into roml_col_rules_map (column_name, rule, roml_entity_nid, table_name)
                        values ('ENTITY_ID', 'ENTITY_DOMAIN_ID=-1030;ENTITY_TYPE=E', 34, 'TX_SUB_STATION_METER_POINT');
insert into roml_col_rules_map (column_name, rule, roml_entity_nid, table_name)
                        values ('ENTITY_ID', 'ENTITY_DOMAIN_ID=-1030;ENTITY_TYPE=E', 101, 'TX_SUB_STATION_METER_POINT');
insert into roml_col_rules_map (column_name, rule, roml_entity_nid, table_name)
                        values ('ENTITY_ID', 'ENTITY_DOMAIN_ID=-1040;ENTITY_TYPE=E', 34, 'MEASUREMENT_SOURCE');
insert into roml_col_rules_map (column_name, rule, roml_entity_nid, table_name)
                        values ('ENTITY_ID', 'ENTITY_DOMAIN_ID=-1040;ENTITY_TYPE=E', 101, 'MEASUREMENT_SOURCE');
insert into roml_col_rules_map (column_name, rule, roml_entity_nid, table_name)
                        values ('ENTITY_ID', 'ENTITY_DOMAIN_ID=-200;ENTITY_TYPE=E', 34, 'INTERCHANGE_TRANSACTION');
insert into roml_col_rules_map (column_name, rule, roml_entity_nid, table_name)
                        values ('ENTITY_ID', 'ENTITY_DOMAIN_ID=-200;ENTITY_TYPE=E', 101, 'INTERCHANGE_TRANSACTION');
insert into roml_col_rules_map (column_name, rule, roml_entity_nid, table_name)
                        values ('ENTITY_ID', 'ENTITY_DOMAIN_ID=-320', 107, 'ANCILLARY_SERVICE');
insert into roml_col_rules_map (column_name, rule, roml_entity_nid, table_name)
                        values ('ENTITY_ID', 'ENTITY_DOMAIN_ID=-320', 108, 'ANCILLARY_SERVICE');
insert into roml_col_rules_map (column_name, rule, roml_entity_nid, table_name)
                        values ('ENTITY_ID', 'ENTITY_DOMAIN_ID=-380;ENTITY_TYPE=E', 34, 'TX_SUB_STATION');
insert into roml_col_rules_map (column_name, rule, roml_entity_nid, table_name)
                        values ('ENTITY_ID', 'ENTITY_DOMAIN_ID=-380;ENTITY_TYPE=E', 101, 'TX_SUB_STATION');
insert into roml_col_rules_map (column_name, rule, roml_entity_nid, table_name)
                        values ('ENTITY_ID', 'ENTITY_DOMAIN_ID=-390;ENTITY_TYPE=E', 34, 'TX_SUB_STATION_METER');
insert into roml_col_rules_map (column_name, rule, roml_entity_nid, table_name)
                        values ('ENTITY_ID', 'ENTITY_DOMAIN_ID=-390;ENTITY_TYPE=E', 101, 'TX_SUB_STATION_METER');
insert into roml_col_rules_map (column_name, rule, roml_entity_nid, table_name)
                        values ('ENTITY_ID', 'ENTITY_DOMAIN_ID=-610', 107, 'MARKET_PRICE');
insert into roml_col_rules_map (column_name, rule, roml_entity_nid, table_name)
                        values ('ENTITY_ID', 'ENTITY_DOMAIN_ID=-610;ENTITY_TYPE=E', 34, 'MARKET_PRICE');
insert into roml_col_rules_map (column_name, rule, roml_entity_nid, table_name)
                        values ('ENTITY_ID', 'ENTITY_DOMAIN_ID=-610;ENTITY_TYPE=E', 101, 'MARKET_PRICE');
insert into roml_col_rules_map (column_name, rule, roml_entity_nid, table_name)
                        values ('ENTITY_ID', 'ENTITY_DOMAIN_ID=-620', 108, 'PRODUCT');
insert into roml_col_rules_map (column_name, rule, roml_entity_nid, table_name)
                        values ('ENTITY_ID', 'ENTITY_DOMAIN_ID=-630', 107, 'COMPONENT');
insert into roml_col_rules_map (column_name, rule, roml_entity_nid, table_name)
                        values ('ENTITY_ID', 'ENTITY_DOMAIN_ID=-630', 108, 'COMPONENT');
insert into roml_col_rules_map (column_name, rule, roml_entity_nid, table_name)
                        values ('ENTITY_ID', 'ENTITY_DOMAIN_ID=-790', 107, 'PERIOD');
insert into roml_col_rules_map (column_name, rule, roml_entity_nid, table_name)
                        values ('ENTITY_ID', 'ENTITY_DOMAIN_ID=-790', 108, 'PERIOD');
insert into roml_col_rules_map (column_name, rule, roml_entity_nid, table_name)
                        values ('ENTITY_ID', 'ENTITY_DOMAIN_ID=-810', 107, 'TEMPLATE');
insert into roml_col_rules_map (column_name, rule, roml_entity_nid, table_name)
                        values ('ENTITY_ID', 'ENTITY_DOMAIN_ID=-810', 108, 'TEMPLATE');
insert into roml_col_rules_map (column_name, rule, roml_entity_nid, table_name)
                        values ('ENTITY_ID', 'ENTITY_TYPE=G', 34, 'ENTITY_GROUP');
insert into roml_col_rules_map (column_name, rule, roml_entity_nid, table_name)
                        values ('ENTITY_ID', 'ENTITY_TYPE=G', 101, 'ENTITY_GROUP');
insert into roml_col_rules_map (column_name, rule, roml_entity_nid, table_name)
                        values ('ENTITY_ID', 'ENTITY_TYPE=R', 34, 'SYSTEM_REALM');
insert into roml_col_rules_map (column_name, rule, roml_entity_nid, table_name)
                        values ('ENTITY_ID', 'ENTITY_TYPE=R', 101, 'SYSTEM_REALM');
insert into roml_col_rules_map (column_name, rule, roml_entity_nid, table_name)
                        values ('OWNER_ENTITY_ID', 'ENTITY_DOMAIN_ID=-1010', 112, 'ENTITY_GROUP');
insert into roml_col_rules_map (column_name, rule, roml_entity_nid, table_name)
                        values ('OWNER_ENTITY_ID', 'ENTITY_DOMAIN_ID=-620', 112, 'PRODUCT');
insert into roml_col_rules_map (column_name, rule, roml_entity_nid, table_name)
                        values ('OWNER_ENTITY_ID', 'ENTITY_DOMAIN_ID=-630', 112, 'COMPONENT');
insert into roml_col_rules_map (column_name, rule, roml_entity_nid, table_name)
                        values ('SCHEDULE_TYPE', '*', NULL, 'STATEMENT_TYPE');
insert into roml_col_rules_map (column_name, rule, roml_entity_nid, table_name)
                        values ('STATEMENT_TYPE', '*', NULL, 'STATEMENT_TYPE');
insert into roml_col_rules_map (column_name, rule, roml_entity_nid, table_name)
                        values ('SUB_COMPONENT_ID', 'SUB_COMPONENT_TYPE=GEOGRAPHY', NULL, 'GEOGRAPHY');
-- ROML_PREFIX_MAP
insert into roml_prefix_map (column_prefix, table_name)
                     values ('ANCILLARY_SERVICE', 'ANCILLARY_SERVICE');
insert into roml_prefix_map (column_prefix, table_name)
                     values ('ATTRIBUTE', 'ENTITY_ATTRIBUTE');
insert into roml_prefix_map (column_prefix, table_name)
                     values ('A_SYSTEM_LOAD', 'SYSTEM_LOAD');
insert into roml_prefix_map (column_prefix, table_name)
                     values ('BASE_COMPONENT', 'COMPONENT');
insert into roml_prefix_map (column_prefix, table_name)
                     values ('BILLING_ENTITY', 'PURCHASING_SELLING_ENTITY');
insert into roml_prefix_map (column_prefix, table_name)
                     values ('B_SYSTEM_LOAD', 'SYSTEM_LOAD');
insert into roml_prefix_map (column_prefix, table_name)
                     values ('CALC_PROCESS', 'CALCULATION_PROCESS');
insert into roml_prefix_map (column_prefix, table_name)
                     values ('CALC_STEP', 'CALCULATION_PROCESS_STEP');
insert into roml_prefix_map (column_prefix, table_name)
                     values ('CHARGE', 'BILLING_STATEMENT');
insert into roml_prefix_map (column_prefix, table_name)
                     values ('COMBINED_COMPONENT', 'COMPONENT');
insert into roml_prefix_map (column_prefix, table_name)
                     values ('COMMODITY', 'IT_COMMODITY');
insert into roml_prefix_map (column_prefix, table_name)
                     values ('COMPONENT', 'COMPONENT');
insert into roml_prefix_map (column_prefix, table_name)
                     values ('CONTRACT', 'INTERCHANGE_CONTRACT');
insert into roml_prefix_map (column_prefix, table_name)
                     values ('EDC', 'ENERGY_DISTRIBUTION_COMPANY');
insert into roml_prefix_map (column_prefix, table_name)
                     values ('ENTITY_GROUP', 'ENTITY_GROUP');
insert into roml_prefix_map (column_prefix, table_name)
                     values ('GEOGRAPHY', 'GEOGRAPHY');
insert into roml_prefix_map (column_prefix, table_name)
                     values ('IMBALANCE', 'COMPONENT_IMBALANCE');
insert into roml_prefix_map (column_prefix, table_name)
                     values ('INVOICE', 'INVOICE');
insert into roml_prefix_map (column_prefix, table_name)
                     values ('INVOICE_GROUP', 'INVOICE_GROUP');
insert into roml_prefix_map (column_prefix, table_name)
                     values ('LINK_TRANSACTION', 'INTERCHANGE_TRANSACTION');
insert into roml_prefix_map (column_prefix, table_name)
                     values ('LMP_BASE_COMMODITY', 'IT_COMMODITY');
insert into roml_prefix_map (column_prefix, table_name)
                     values ('LMP_COMMODITY', 'IT_COMMODITY');
insert into roml_prefix_map (column_prefix, table_name)
                     values ('MARKET_PRICE', 'MARKET_PRICE');
insert into roml_prefix_map (column_prefix, table_name)
                     values ('METER', 'TX_SUB_STATION_METER');
insert into roml_prefix_map (column_prefix, table_name)
                     values ('METER_POINT', 'TX_SUB_STATION_METER_POINT');
insert into roml_prefix_map (column_prefix, table_name)
                     values ('PARENT_GEOGRAPHY', 'GEOGRAPHY');
insert into roml_prefix_map (column_prefix, table_name)
                     values ('PARENT_GROUP', 'ENTITY_GROUP');
insert into roml_prefix_map (column_prefix, table_name)
                     values ('PERIOD', 'PERIOD');
insert into roml_prefix_map (column_prefix, table_name)
                     values ('POD', 'SERVICE_POINT');
insert into roml_prefix_map (column_prefix, table_name)
                     values ('POR', 'SERVICE_POINT');
insert into roml_prefix_map (column_prefix, table_name)
                     values ('PRODUCT', 'PRODUCT');
insert into roml_prefix_map (column_prefix, table_name)
                     values ('PSE', 'PURCHASING_SELLING_ENTITY');
insert into roml_prefix_map (column_prefix, table_name)
                     values ('PURCHASER', 'PURCHASING_SELLING_ENTITY');
insert into roml_prefix_map (column_prefix, table_name)
                     values ('REALM', 'SYSTEM_REALM');
insert into roml_prefix_map (column_prefix, table_name)
                     values ('REALM_TYPE', 'SYSTEM_REALM_TYPE');
insert into roml_prefix_map (column_prefix, table_name)
                     values ('RESOURCE', 'SUPPLY_RESOURCE');
insert into roml_prefix_map (column_prefix, table_name)
                     values ('SC', 'SCHEDULE_COORDINATOR');
insert into roml_prefix_map (column_prefix, table_name)
                     values ('SCHEDULE_GROUP', 'SCHEDULE_GROUP');
insert into roml_prefix_map (column_prefix, table_name)
                     values ('SEASON', 'SEASON');
insert into roml_prefix_map (column_prefix, table_name)
                     values ('SELLER', 'PURCHASING_SELLING_ENTITY');
insert into roml_prefix_map (column_prefix, table_name)
                     values ('SERVICE_POINT', 'SERVICE_POINT');
insert into roml_prefix_map (column_prefix, table_name)
                     values ('SERVICE_ZONE', 'SERVICE_ZONE');
insert into roml_prefix_map (column_prefix, table_name)
                     values ('SINK', 'SERVICE_POINT');
insert into roml_prefix_map (column_prefix, table_name)
                     values ('SOURCE', 'SERVICE_POINT');
insert into roml_prefix_map (column_prefix, table_name)
                     values ('STATEMENT_TYPE', 'STATEMENT_TYPE');
insert into roml_prefix_map (column_prefix, table_name)
                     values ('SUB_STATION', 'TX_SUB_STATION');
insert into roml_prefix_map (column_prefix, table_name)
                     values ('SYSTEM_LOAD', 'SYSTEM_LOAD');
insert into roml_prefix_map (column_prefix, table_name)
                     values ('TAX_COMPONENT', 'COMPONENT');
insert into roml_prefix_map (column_prefix, table_name)
                     values ('TEMPLATE', 'TEMPLATE');
insert into roml_prefix_map (column_prefix, table_name)
                     values ('TP', 'TRANSMISSION_PROVIDER');
insert into roml_prefix_map (column_prefix, table_name)
                     values ('TRANSACTION', 'INTERCHANGE_TRANSACTION');
insert into roml_prefix_map (column_prefix, table_name)
                     values ('TX_TRANSACTION', 'INTERCHANGE_TRANSACTION');
insert into roml_prefix_map (column_prefix, table_name)
                     values ('ZOD', 'SERVICE_ZONE');
insert into roml_prefix_map (column_prefix, table_name)
                     values ('ZOR', 'SERVICE_ZONE');
commit;
