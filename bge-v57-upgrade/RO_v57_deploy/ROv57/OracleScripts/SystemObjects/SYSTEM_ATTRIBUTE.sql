DELETE FROM SYSTEM_ATTRIBUTE;

-- For All Categories
INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
-1, 'Shared Configuration Object', '%', 'Specifies the name of another "shared" system object that contains the real configuration values', NULL, 0, SYSDATE);
INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
-2, 'Shared Conf - Override Disp Name', '%', 'Specifies whether this object''s display name should be used instead of the shared config object''s', NULL, 1, SYSDATE);
INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
-3, 'Shared Conf - Override Is Hidden', '%', 'Specifies whether this object''s "hidden" flag should be used instead of the shared config object''s', NULL, 1, SYSDATE);
INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
-4, 'Help Document Name', '%', 'Specifies the Wiki Help Document for this System Object', NULL, 0, SYSDATE);
INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
-5, 'Row Limit', '%', 'Specifies the number of rows allowed when populating this System Object.', NULL, 0, SYSDATE);
INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
-6, 'Row Limit Message Formula', '%', 'Specifies a special message to display when the Row Limit is hit. The attribute will be evaluated as a formula.', NULL, 0, SYSDATE);
INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
-7, 'Product Script Type', '%', 'Specifies the Product Script Type for the System Object', '|Core|SEM|TDIE', 0, SYSDATE);


-- IO Field
INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
101, 'Read Only', 'IO Field', 'If a Field is flagged as Read Only, the user will not be able to edit it from the Entity Manager.', NULL, 1, SYSDATE); 
INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
102, 'Data Type', 'IO Field', 'The Data Type of a Field determines how the Field will be displayed and edited.', 'Boolean|Color|Date|Number|String|Big Text', 0, SYSDATE); 
INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
103, 'Combo List', 'IO Field', 'The Combo List is a pipe (|) separated list of options from which the user can choose.', NULL, 0, SYSDATE); 
INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
104, 'Entity Name', 'IO Field', 'The Entity Name is used for an entity populated Combo List for the Field.', NULL, 0, SYSDATE); 
INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
105, 'Max Length', 'IO Field', 'The maximum allowed string length for this field.', NULL, 0, SYSDATE); 
INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
106, 'Hidden Bits', 'IO Field', 'The attributes and tabs that are hidden depending on the value of this field. *Value1;@Attribute1;@Attribute2;^Tab1;*Value2;^Tab1', NULL, 0, SYSDATE); 
INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
107, 'Special List Proc', 'IO Field', 'Specifies the name and parameters of a procedure.  Start with | if editable.  |EM.COUNTER_PARTIES;COUNTER_PARTY_TYPE', NULL, 0, SYSDATE); 
INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
108, 'Default Value', 'IO Field', 'Specifies the default value for an IO field.', NULL, 0, SYSDATE);
INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
109, 'Edit Mask', 'IO Field', 'The Edit Mask restricts the user to only be able to enter data in a certain format.  ', NULL, 0, SYSDATE);
INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
110, 'Format', 'IO Field', 'The Format attribute is applied to the raw data in the column for neater display to the user.  Dates and numbers are good candidates for formatting.', '|Currency|Short Date|Medium Date|Long Date|yyyy-MM-dd hh:mm a|yyyy-MM-dd KK:mm|yyyy-MM-dd|###,###,##0.00|###,###,##0.00''%''', 0,SYSDATE); 
INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
111, 'Hide When Formula', 'IO Field', 'The formula that determines whether this attribute is hidden based on other IO Fields.', NULL, 0,SYSDATE); 
INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
112, 'Is Combo Box Editable', 'IO Field', 'Specifies if the combo box is editable.', NULL, 1,SYSDATE);
INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
113, 'Special Combo Display Parameter', 'IO Field', 'The display parameter is a parameter on the entity get procedure which is used to get the display text for special / entity combos to avoid loading its combo model until the user needs to edit the attribute.', NULL, 0,SYSDATE);
INSERT INTO SYSTEM_ATTRIBUTE (ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE) VALUES (
114, 'Numerous Search Options', 'IO Field', 'Specifies a list of options to have in the tree''s find dialog. The list will be formatted using the combo list syntax.', NULL, 0, SYSDATE);
INSERT INTO SYSTEM_ATTRIBUTE (ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE) VALUES (
115, 'Is Numerous Formula', 'IO Field', 'Specifies a formula that will determine if the Special Combo or Object List is Numerous ''Is Numerous''..', NULL, 0, SYSDATE);
INSERT INTO SYSTEM_ATTRIBUTE (ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE) VALUES (
116, 'Special Combo Content Type', 'IO Field', 'Specifies the type of special combo.', 'Auto|Text|Object', 0, SYSDATE);


-- IO Table
INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
201, 'Put Procedure Name', 'IO Table', 'Specifies the custom PUT package and procedure for an entity.', NULL, 0, SYSDATE); 
INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
202, 'Get Procedure Name', 'IO Table', 'Specifies the custom GET package and procedure for an entity.', NULL, 0, SYSDATE); 
INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
203, 'Delete Procedure Name', 'IO Table', 'Specifies the custom DELETE package and procedure for an entity.', NULL, 0, SYSDATE); 
INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
204, 'TreeList Procedure Name', 'IO Table', 'Specifies the custom package and procedure for retrieving the list of entities for the Entity Manager tree.', NULL, 0, SYSDATE); 
INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
205, 'StandAlone Entity Caption', 'IO Table', 'Specifies the Form Caption for Entity Manager when displaying "stand-alone" entities: ones that aren''t displayed amongst other entity types.', NULL, 0, SYSDATE); 
INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
206, 'Filter By Date', 'IO Table', 'Specifies whether the custom TreeList Procedure takes begin and end dates for filtering the entity list by dates.', NULL, 1, SYSDATE); 
INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
208, 'After Put Procedure Name', 'IO Table', 'Specifies the custom After Put procedure package and procedure for an entity.', NULL, 0, SYSDATE); 
--INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
--207, 'Validation Rule', 'IO Table', 'Specifies a formula-based validation rule for validating table attributes before they are saved.', NULL, 0, SYSDATE); 
INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
209, 'Copy Procedure Name', 'IO Table', 'Specifies the custom COPY package and procedure for an entity.', NULL, 0, SYSDATE); 

-- Grid
INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
301, 'Put Procedure Name', 'Grid', 'Specifies the custom PUT package and procedure for a grid.', NULL, 0, SYSDATE); 
INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
302, 'Delete Procedure Name', 'Grid', 'Specifies the custom DELETE package and procedure for a grid.', NULL, 0, SYSDATE); 
--INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
--303, 'Validation Formula', 'Grid', 'Specifies a formula-based validation rule for validating grid contents before they are saved.', NULL, 0, SYSDATE); 
INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
304, 'Drill Down Proc', 'Grid', 'Specifies the name and parameters of a procedure for drilldown.  EM.COUNTER_PARTIES;COUNTER_PARTY_TYPE', NULL, 0,SYSDATE);
INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
305, 'Can Change Row Count', 'Grid', 'Specifies whether or not the user can change the number of rows in the grid via the right-click Insert and Delete options', NULL, 1, SYSDATE);
INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
306, 'Drill Down Action Name', 'Grid', 'Specifies the name of the Drill Down Action that will use the Drill Down Proc.', NULL, 0, SYSDATE); 
INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
307, 'Grid Display Type', 'Grid', 'Specifies the display type for this Mighty Grid.', 'Standard|Anchored|PriceQuantity|ResourceTrait|RowModelGrid', 0, SYSDATE);
INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
308, 'Hiding Single Data Column Label', 'Grid', 'Specifies whether to hide the Data Column label on an Anchored Grid when there is only one data column. ', NULL, 1, SYSDATE);
INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
309, 'Auto Resize Mode', 'Grid', 'Specifies the column resize mode for the grid', '#0;OFF|#4;ALL_COLUMN|#3;LAST_COLUMN|#2;SUBSEQUENT_COLUMNS|#1;NEXT_COLUMN', 0, SYSDATE);
INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
310, 'Editor Policy', 'Grid', 'Specifies the Java class that is responsible for overriding layout attributes of the MightyGridEditor.', NULL, 0, SYSDATE);
INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
311, 'Disable Action Double Click', 'Grid', 'Specified whether the first action is launched by double clicking on a cell.', NULL, 1, SYSDATE);
INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
312, 'Row Key Sort', 'Grid', 'Specifies the sorting mechanism to use with Anchored Grid Row Keys.', '#0;Lexical Sort|#1;Value Based Sort', 0, SYSDATE);
-- Report
INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
401, 'Get Procedure 1', 'Report', 'Specifies the custom GET package and procedure for a report.', NULL, 0, SYSDATE);
INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
402, 'Hiding Filter Panel', 'Report', 'Specifies whether the filter panel is displayed.', NULL, 1, SYSDATE);
INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
403, 'Data Panel Type', 'Report', 'Specifies the data panel display type for this report.', '|Normal Grid|Comparison Grids|Master/Detail Grids|Lazy Master/Detail Grids|Crystal Report|Billing Invoice|Entity View|Configuration View', 0, SYSDATE);
INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
404, 'Get Procedure 2', 'Report', 'Specifies the custom GET package and procedure for a report.', NULL, 0, SYSDATE); 
INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
405, 'Data Browser Mode', 'Report', 'Specifies whether this report contains a Data Browser option.', '#-1;None|#1;Read Only|#2;Editable', 0, SYSDATE);
INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
406, 'Refresh After Selection', 'Report', 'Specifies if the report should automatically refesh after a new Report Type is selected by the user', NULL, 1, SYSDATE); 
INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
407, 'Master Detail Filter Column', 'Report', 'Specifies the name of the column which is used to filter the detail grid. It must have a corresponding column in the master grid.', NULL, 0, SYSDATE); 
INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
408, 'Autorefresh Time', 'Report', 'Whether to automatically refresh the report and if so, how often. (10 - 900 seconds, 0 for off)', '|0|15|30|60|300|600|900', 0, SYSDATE); 
INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
409, 'Multi-Grid Orientation', 'Report', 'Specifies the orientation of grids when more than one is present. Vertical shows them above and below, Horizontal shows them side by side.', 'Vertical|Horizontal', 0, SYSDATE);
INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
410, 'Comparison-Grid Row Keys', 'Report', 'Specifies the columns which make up the key to compare rows in the 2 different grids.', NULL, 0, SYSDATE);
INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
411, 'Crystal Template Type', 'Report', 'Specifies the formula that is evaluated at run-time to determine which Crystal Template Type to use when displaying a report.', NULL, 0, SYSDATE);
INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
412, 'Crystal Template Type List Proc', 'Report', 'Specifies the custom package and procedure that will enumerate all Crystal Template Types for a procedure.', NULL, 0, SYSDATE);
INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
413, 'Base Grid Config', 'Report', 'Specifies the name of a Shared Grid object that has minimal configuration that should be used by the report''s grids.', NULL, 0, SYSDATE);
INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
414, 'Comparison-Grid Priority columns', 'Report', 'Specifies the columns which are checked for difference before the rest of the row', NULL, 0, SYSDATE);
INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
415, 'Comparison-Grid Ignore columns', 'Report', 'Specifies the columns for which difference is ignored', NULL, 0, SYSDATE);
INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
417, 'Splitter Size', 'Report', 'Specifies the size of the java splitter in Master/Detail Grids.', NULL, 0, SYSDATE);
INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
418, 'Sub Report Formula', 'Report', 'Specifies a formula that is used to build the Grid Name.', NULL, 0, SYSDATE);
INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
419, 'Global Report Parameters', 'Report', 'Parameters which override report filters.', NULL, 0, SYSDATE);

-- Report Filter
INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
501, 'Filter Type', 'Report Filter', 'The Filter Control Type determines whether the filter will be a combo-box or a checkbox and how it will be populated.', 'e (Standard Edit)|d (Date Picker)|c (Combo Box)|k (Checkbox)|o (Object List)|s (Special List)|b (Button)|x (Custom)|r (Radio Button)|t (Tree)|a (Date Range)', 0, SYSDATE); 
INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
502, 'Combo List', 'Report Filter', 'The Combo List Attribute allows the admin to define a list, separated by pipe (|) characters, that will show up as items in the filter.', NULL, 0,SYSDATE); 
INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
503, 'Entity Name', 'Report Filter', 'The Entity Name Attribute allows the admin to associate the filter with an Entity Object.', NULL, 0, SYSDATE); 
INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
504, 'Special List Proc', 'Report Filter', 'Specifies the name and parameters of a procedure.  EM.COUNTER_PARTIES;"PSE', NULL, 0,SYSDATE);
INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
505, 'Optional Checkbox', 'Report Filter', 'This specifies whether drop-down list control filters have a display checkbox next to them.', '0 (No Checkbox)|1 (Unchecked Box)|2 (Checked Box)', 0, SYSDATE); 
INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
506, 'Checkbox Default', 'Report Filter', 'This specifies whether checkbox control filters are checked by default.', '0 (Unchecked)|1 (Checked)', 0, SYSDATE); 
INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
507, 'TextBox/Combo Default', 'Report Filter', 'This specifies what the default text in a textbox control filter is.', NULL, 0, SYSDATE); 
INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
508, 'Allow Multi-Select', 'Report Filter', 'This specifies whether a list filter allows multiple items to be selected.', NULL, 1,SYSDATE);
INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
509, 'Multi-Select Delimiter', 'Report Filter', 'This specifies the delimiter used in the Get Procedure when allowMultiSelect is true.', NULL, 0,SYSDATE);
INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
510, 'ListBox Height', 'Report Filter', 'This specifies the number of rows to display in a multi-select list filter.', NULL, 0,SYSDATE);
INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
512, 'Custom Class', 'Report Filter', 'This specifies the custom filter Java class to use.', NULL, 0,SYSDATE);
INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
513, 'Fill Weight', 'Report Filter', 'This specifies the percentage of the remaining available space that this component should occupy.', NULL, 0,SYSDATE);
INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
515, 'Is Cached', 'Report Filter', 'This specifies whether this report filter is cached for use by other reports.', NULL, 1,SYSDATE);
INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
516, 'Border Type', 'Report Filter', 'This specifies whether this report filter should have a border or not','Titled Border|No Border',0,SYSDATE);
INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
517, 'Filter Group', 'Report Filter', 'This specifies a comma delimited list of filter groups that this filter belongs to.',NULL,0,SYSDATE);
INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
518, 'Dependent Filters', 'Report Filter', 'This specifies a comma delimited list of filter names that are dependent on this filter.',NULL,0,SYSDATE);
INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
519, 'Is Required', 'Report Filter', 'This specifies if a filter is required or not.',NULL,1,SYSDATE);
INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
520, 'Refresh on Select', 'Report Filter', 'Specifies if the report should automatically refesh after a filter value is selected by the user', NULL, 1, SYSDATE); 
INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
521, 'Exclude From Presets', 'Report Filter', 'Specifies if the filter should be removed not be added to the last saved presets', NULL, 1, SYSDATE); 
INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
522, 'Is Combo Box Editable', 'Report Filter', 'Specifies if the combo box is editable.', NULL, 1,SYSDATE);
INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
523, 'Refresh Before Report', 'Report Filter', 'Specifies whether this filter should be refreshed prior to refreshing the report (ie. Trees).', NULL, 1, SYSDATE); 
INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
524, 'Find Dialog Search Procedure', 'Report Filter', 'Specifies the name of stored proceudre used by the tree''s find dialog. It must have a p_SEARCH_STRING parameter.', NULL, 0, SYSDATE);
INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
525, 'Find Dialog Search Options', 'Report Filter', 'Specifies a list of options to have in the tree''s find dialog. The list will be formatted using the combo list syntax.', NULL, 0, SYSDATE);
INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
526, 'Disable Action Double Click', 'Report Filter', 'Specifies whether double-click actions can be executed for this filter (ie. Trees).', NULL, 1, SYSDATE);
INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
527, 'Format', 'Report Filter', 'The Format attribute is applied to the raw data in the filter for neater display to the user.  Only Dates filters can use formatting.  If a filter has a format that includes time, the datepicker widget will allow for time selection.', '|Short Date|Medium Date|Long Date|yyyy-MM-dd hh:mm a|yyyy-MM-dd KK:mm|yyyy-MM-dd', 0, SYSDATE);
INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
528, 'Disable When Formula', 'Report Filter', 'Specifies a formula that must evaluate to a boolean that determines whether the filter is disabled or enabled.', NULL, 0, SYSDATE);
INSERT INTO SYSTEM_ATTRIBUTE (ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE) VALUES (
529, 'Special Combo Content Type', 'Report Filter', 'Specifies the type of special combo.', 'Auto|Text|Object', 0, SYSDATE);
INSERT INTO SYSTEM_ATTRIBUTE (ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE) VALUES (
530, 'Visible When Formula', 'Report Filter', 'Specifies the formula to eavluate to hide or unhide a filter .', NULL, 0, SYSDATE);

-- Column
INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
1, 'Edit Type', 'Column', 'The Edit Type of a column determines what will happen when the user attempts to edit the column.', 'e (Standard Edit)|b (Big Text Edit)|n (Numeric Edit)|d (Date Picker)|c (Combo Box)|k (Checkbox)|x (No Edit)|o (Object List)|s (Special List)|r (Color)', 0, SYSDATE); 
INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
2, 'Not Null', 'Column', 'If the Not Null attribute is activated for a column, a save will not be allowed unless the user has entered a value for that column.', NULL, 1,SYSDATE);
INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
3, 'Format', 'Column', 'The Format attribute is applied to the raw data in the column for neater display to the user.  Dates and numbers are good candidates for formatting.', '|Currency|Short Date|Medium Date|Long Date|yyyy-MM-dd hh:mm a|yyyy-MM-dd KK:mm|yyyy-MM-dd|###,###,##0.00|###,###,##0.00''%''', 0,SYSDATE); 
INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
4, 'Data Type', 'Column', 'A checkbox will be displayed in a column with a Data Type of Checkbox.  A column with a Data Type of Date will be sorted as a Date instead of a String.', '#0;Standard|#11;Checkbox|#7;Date', 0,SYSDATE); 
INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
5, 'Combo List', 'Column', 'The Combo List Attribute allows the admin to define a list, separated by pipe (|) characters, that will show up as a combo list in the grid.', NULL, 0,SYSDATE); 
INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
6, 'Edit Mask', 'Column', 'The Edit Mask restricts the user to only be able to enter data in a certain format.  ', NULL, 0, SYSDATE);
INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
7, 'Merge ', 'Column', 'The Merge Attribute allows the column to merge with other columns with the same values.', NULL, 1, SYSDATE); 
INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
8, 'Entity Name', 'Column', 'The Entity Name Attribute allows the admin to associate the column with an Entity Object.', NULL, 0, SYSDATE); 
INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
9, 'Date Aligned Grid Mode', 'Column', 'This mode determines the way the column will function in a date aligned grid.', '#0;None|#1;Date/Time|#2;Column Header and Break|#3;Column Header Only|#4;Column Break Only|#5;Data|#6;Id', 0,SYSDATE); 
INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
10, 'Date Interval', 'Column', 'This interval overrides whatever the GUI uses as the interval in a date aligned grid.', 'NA|15 Minute|30 Minute|Hour|Day|Week|Month|Quarter|Year', 0,SYSDATE); 
INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
11, 'Alignment', 'Column', 'Determines how the data will be aligned within the grid.', '#1;Left Center|#4;Center Center|#7;Right Center|#9;General', 0,SYSDATE);
INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
12, 'Fixed Alignment', 'Column', 'Determines how the fixed header data will be aligned within the grid.  (Overrides Alignment)', '#1;Left Center|#4;Center Center|#7;Right Center|#9;General', 0,SYSDATE); 
INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
13, 'Hidden When Null', 'Column', 'If set, the column will be hidden if all data values are null.', NULL, 1,SYSDATE);
INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
14, 'Total Row Mode', 'Column', 'Determines how the column will be aggregated in the total row at the top of the grid.', '#0;Exclude|#2;Sum|#4;Count|#5;Average|#6;Max|#7;Min|#8;Standard Deviation|#9;Variance|#10;Manning Coef', 0,SYSDATE); 
INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
15, 'Total Column Mode', 'Column', 'Determines how the column will be aggregated in the total column at the left of the grid.', '#0;Exclude|#1;Add|#2;Subtract', 0,SYSDATE);
INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
16, 'Special List Proc', 'Column', 'Specifies the name and parameters of a procedure.  Start with | if editable.  |EM.COUNTER_PARTIES;COUNTER_PARTY_TYPE', NULL, 0,SYSDATE);
--INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
--17, 'Default Value', 'Column', 'Specifies a formula-based default value for this Column.', NULL, 0, SYSDATE);
INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
18, 'Drill Down Proc', 'Column', 'Specifies the name and parameters of a procedure for drilldown.  EM.COUNTER_PARTIES;COUNTER_PARTY_TYPE', NULL, 0,SYSDATE);
INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
19, 'After Edit Validation Formula', 'Column', 'Specifies a formula-based validation rule for validating a cells contents after an edit.', NULL, 0, SYSDATE);
INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
20, 'Read Only', 'Column', 'Specifies the column as Read Only, the user will not be able to edit the column in the grid.', NULL, 1, SYSDATE); 
INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
21, 'Drill Down Action Name', 'Column', 'Specifies the name of the Drill Down Action that will use the Drill Down Proc.', NULL, 0, SYSDATE); 
INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
22, 'Anchor Type', 'Column', 'When the Grid Type is "Anchored", the Anchor Type specifies this columns roll in the grid.', '#0;None|#1;Key|#6;Anchored|#7;Anchored Header|#2;Column Header and Break|#3;Column Header Only|#4;Column Break Only|#5;Data', 0, SYSDATE); 
INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
23, 'Column Width Prototype', 'Column', 'Specifies a prototype string value to use to determine the optimal width of a column.', NULL, 0, SYSDATE); 
INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
24, 'Fixed', 'Column', 'If a Column is flagged as Fixed, then the column will appear as a Row Header.', NULL, 1, SYSDATE); 
INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
25, 'Formula', 'Column', 'Specifies the formula to use to evaluate the value of this column for a given row. This uses the NewEnergy FormulaService.', NULL, 0, SYSDATE); 
INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
26, 'Data Browser Mode', 'Column', 'Specifies whether this column can display Data Browser data.', '#-1;None|#1;Data', 0, SYSDATE);
INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
27, 'Anchor Header Column', 'Column', 'When the Column Anchored Type is "Anchored" this attribute defines the header column value.', NULL, 0, SYSDATE); 
INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
28, 'Conditional Format Name', 'Column', 'The name of the Conditional Format to apply to this column', NULL, 0, SYSDATE); 
INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
29, 'Conditional Format Variables', 'Column', 'The list of the variables to substitute in the Format When Formula.', NULL, 0, SYSDATE);
INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
30, 'Row Model Mode', 'Column', 'Specifies whether this column participates in the RowModel and what role this column plays.', '#0;None|#1;Column|#2;Key|#3;Edit Type|#4;Combo List|#5;Is Boolean', 0, SYSDATE);
INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
31, 'Exclude From Duplicate', 'Column', 'Specifies whether this column can be duplicated when the Duplicate Row action is fired.', NULL, 1, SYSDATE);
INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
32, 'Anchor Column Required', 'Column', 'Specifies whether this column is required - applicable to anchored grids only.', '#0;No|#1;Yes|#2;At Least One', 0, SYSDATE);
INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
33, 'Special Combo Display Column', 'Column', 'Specifies the name of the hidden column in the grid that provides the display test for the Special Combo cell.', NULL, 0, SYSDATE);
INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
34, 'Is Combo Box Editable', 'Column', 'Specifies if the combo box is editable.', NULL, 1,SYSDATE);
INSERT INTO SYSTEM_ATTRIBUTE (ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE) VALUES (
35, 'Numerous Search Options', 'Column', 'Specifies a list of options to have in the tree''s find dialog. The list will be formatted using the combo list syntax.', NULL, 0, SYSDATE);
INSERT INTO SYSTEM_ATTRIBUTE (ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE) VALUES (
36, 'Is Numerous Formula', 'Column', 'Specifies a formula that will determine if the Special Combo or Object List is Numerous ''Is Numerous''..', NULL, 0, SYSDATE);
INSERT INTO SYSTEM_ATTRIBUTE (ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE) VALUES (
37, 'Special Combo Content Type', 'Column', 'Specifies the type of special combo.', 'Auto|Text|Object', 0, SYSDATE);
INSERT INTO SYSTEM_ATTRIBUTE (ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE) VALUES (
38, 'Ignore Column Modification', 'Column', 'Any edits made to this column will not cause the row (or grid) to be marked as modified.', NULL, 1, SYSDATE);

-- IO SubTab
INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
601, 'Hide When Formula', 'IO SubTab', 'The formula that determines whether this subtab is hidden based on other IO Fields.', NULL, 0,SYSDATE); 
INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
602, 'Custom Get Procedure', 'IO SubTab', 'Allows users to specify custom GET procedures, if none is specified then Entity Manager will continue using the EM package.', NULL, 0,SYSDATE); 
INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
603, 'Custom Set Procedure', 'IO SubTab', 'Allows users to specify custom SET procedures, if none is specified then Entity Manager will continue using the EM package.', NULL, 0,SYSDATE); 
INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
604, 'Custom Delete Procedure', 'IO SubTab', 'Allows users to specify custom DELETE procedures, if none is specified then Entity Manager will continue using the DX package.', NULL, 0,SYSDATE); 
INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
605, 'Table Name', 'IO SubTab', 'The name of the table for the sub tab.  This will be used to copy the sub tab, if no table name is given, then the table will not be copied automatically.', NULL, 0,SYSDATE); 
INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
606, 'Owner ID Column', 'IO SubTab', 'The name of the owner ID column for the table of the sub tab.  This will be used to copy the sub tab, if no name is given, then the table will not be copied automatically.', NULL, 0,SYSDATE); 

-- Layout
INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
701, 'Pane Type', 'Layout', 'The type of Pane represented by this Layout.', 'Aggregate|Splitter|System View|VBD|Link', 0,SYSDATE); 
INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
703, 'Tab Config Path', 'Layout', 'Used by home page to look up System Dictionary tab config for VBD Pane Type Layout.', NULL, 0,SYSDATE); 
INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
704, 'Navigation Style', 'Layout', 'Specifies how child Layouts of an Aggregate Layout are arranged : via tabs, tree, etc.', 'Tabs', 0,SYSDATE); 
INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
705, 'Orientation', 'Layout', 'Specifies the orientation of a Splitter Pane Type Layout', 'Horizontal|Vertical', 0,SYSDATE); 
INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
706, 'Size', 'Layout', 'Specifies the location of the splitter bar on a Splitter Pane Type Layout.  Use % to specify percent.', NULL, 0,SYSDATE); 
INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
707, 'Aggregate Path', 'Layout', 'Specifies the path of a System View Layout in an aggregate hierarchy.', NULL, 0,SYSDATE); 
INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
708, 'View Reference', 'Layout', 'The name of the System View System Object to display in a System View Type Layout.', NULL, 0,SYSDATE); 
INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
709, 'URL', 'Layout', 'The URL to pull up for a Layout of Pane Type Link.', NULL, 0,SYSDATE); 
INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
710, 'Target', 'Layout', 'The target frame of a Layout.', '|_top|_blank|Main', 0,SYSDATE); 
INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
711, 'Expand Menu OnLoad', 'Layout', 'Specifies whether to have the Layout menu expanded when the home page applet is loaded', NULL, 1,SYSDATE); 

-- SystemView
INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
801, 'Java Class', 'System View', 'The java class to invoke for this System View.', '|com.newenergyassoc.ro.mightyReport.MightyReportPanel|com.newenergyassoc.ro.mightyReport.TabbedMightyReportPanel', 0,SYSDATE); 

-- MightyChart
INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
901, 'Chart Type', 'Chart', 'The type of JCChart to display in this view.', '#0;LINE|#1;SCATTER PLOT|#9;BAR|#8;AREA', 0,SYSDATE);
INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
902, 'X Axis Label', 'Chart', 'The label to display for the X Axis', NULL, 0,SYSDATE);
INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
903, 'Y Axis Label', 'Chart', 'The label to display for the Y Axis', NULL, 0,SYSDATE);
INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
904, 'Header', 'Chart', 'The title to display for this Chart', NULL, 0,SYSDATE);
INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
905, 'Data Columns', 'Chart', 'A comma-delimited list of the Column names to use for this charts data model', NULL, 0, SYSDATE);
INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
906, 'Bar Chart Threshold', 'Chart', 'The threshold is the number of datapoints need before switching to from a bar chart to a line graph.', NULL, 0,SYSDATE);
INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
907, 'Showing Legend', 'Chart', 'Determines whether we are showing a chart legend.', NULL, 1, SYSDATE);
INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
908, 'Update On Row Select', 'Chart', 'Determines whether this charts data is based on the selected row of the grid.', NULL, 1, SYSDATE);
INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
910, 'Update On Column Select', 'Chart', 'Determines whether this charts data is based on the selected column of the grid.', NULL, 1, SYSDATE);
INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
911, 'Label Columns', 'Chart', 'A comma-delimited list of the Column names to use for labelling a single row.', NULL, 0, SYSDATE);
INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
912, 'Show Line Symbols', 'Chart', 'Determines whether to show line symbols on a PLOT style chart.', NULL, 1, SYSDATE);
INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
913, 'Allow Hot Hitting', 'Chart', 'Determines whether a user can click on the chart and select a value in the grid.', NULL, 1, SYSDATE);
INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
914, 'Max Legend Width', 'Chart', 'Determines the maximum length of a legend label. Zero or Empty uses the default size of 30.', NULL, 0, SYSDATE);

-- Actions
INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
1001, 'Mnemonic', 'Action', 'Specifies the ALT+key that can be used to invoke this action.', NULL, 0, SYSDATE);
INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
1002, 'Shortcut Key', 'Action', 'Specifies the keystroke that can be used to invoke this action (ie. ctrl alt 3)', NULL, 0, SYSDATE);
INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
1004, 'Enabled When Formula', 'Action', 'Specifies the formula used to determine whether this Action is enabled.', NULL, 0, SYSDATE);
INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
1005, 'Visible When Formula', 'Action', 'Specifies the formula used to determine whether this Action is visible.', NULL, 0, SYSDATE);
INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
1006, 'Type', 'Action', 'Specifies the type of Action that will be used.', '#0;Drill-Down|#1;Layout|#2;System View|#3;Procedure|#4;Warning Procedure|#5;Warning Message|#6;Navigate|#10;Grid Editor|#7;Parent Menu|#8;No Operation|#9;Custom Class|#11;Text Dialog Drill Down|#12;File Import|#13;File Export|#14;Background Procedure|#15;Background File Import|#16;Refresh|#17;Save|#18;Jump To Entity', 0, SYSDATE);
INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
1007, 'Type Reference', 'Action', 'Specifies a reference string that is used differently based on the Action Type.', NULL, 0, SYSDATE);
INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
1008, 'Row Scope', 'Action', 'Specifies the rows on which the action will execute (may be a formula).', '|Selected|All', 0, SYSDATE);
INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
1009, 'Column Break Scope', 'Action', 'Specifies the column breaks on which the action will execute (all or only the selected column).', 'Selected|All', 0, SYSDATE);
INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
1010, 'Target Grid Name', 'Action', 'Specifies the GRID on which the action will act (for actions on filters)', '|Master|Detail|Slave|Top|Bottom|Left|Right|Upper|Summary|Lower', 0, SYSDATE);
INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
1011, 'Is Dialog Modal', 'Action', 'Specifies whether the dialog is modal.', NULL, 1, SYSDATE);
INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
1012, 'Warning Dialog Type', 'Action', 'Specifies which buttons to have on the Warning dialog.', '#4;Yes|#0;Yes,No|#1;Yes,No,Cancel|#2;Yes,Cancel', 0, SYSDATE);
INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
1013, 'Job Class', 'Action', 'Specifies the Database Job Class to use when running an action asynchronously.', NULL, 0, SYSDATE);
INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
1014, 'File Dialog FilterSet', 'Action', 'Specifies the Filters on the File Dialog.', '|txt;Text files (*.txt)|dat;Data files (*.dat)|csv;Comma Delimited files(*.csv)', 0, SYSDATE);
INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
1015, 'Is Multi File Export', 'Action', 'Specifies the whether the File Export action is multiple files. If the action supports multiple files then it will require specifying a directory instead of a single file name.', NULL, 1, SYSDATE);
INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
1016, 'Child Parameters', 'Action', 'Specifies which parameters should be provided to children actions.', NULL, 0, SYSDATE);
INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
1017, 'Dialog Dimensions', 'Action', 'The dimensions of the new dialog (applies only to System View, Layout, Navigate and Drill Down.  Format: Width,Height.)', NULL, 0, SYSDATE);

-- Labels
INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
1101, 'Location', 'Label', 'Specifies the location of the label in relation to the MightyGrid', '#0;Top Right|#1;Top Center|#2;Top Left|#3;Bottom Right|#4;Bottom Center|#5;Bottom Left', 0, SYSDATE);
INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
1102, 'Label Formula', 'Label', 'Specifies the formula to get the grid label', NULL, 0, SYSDATE);
INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
1103, 'Hidden When Null', 'Label', 'If set, the column will be hidden if all data values are null.', NULL, 1,SYSDATE);

-- Trees
INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
1201, 'Get Procedure', 'Tree', 'Specifies the name of the stored procedure used to populate the tree.', NULL, 0, SYSDATE);
INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
1202, 'Sub Tree Name Formula', 'Tree', 'Specifies the name of the Sub Tree to load when a Lazy Loaded tree node is clicked', NULL, 0, SYSDATE);
INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
1203, 'Is Numerous Formula', 'Tree', 'Specifies a formula that will determine if the last node in this sub-tree ''Is Numerous''..', NULL, 0, SYSDATE);
INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
1204, 'Is Numerous Options', 'Tree', 'Specifies a list of options to have in the tree''s find dialog. The list will be formatted using the combo list syntax.', NULL, 0, SYSDATE);
INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
1205, 'Is Recursive', 'Tree', 'Specifies whether this tree may have a recursive sub-tree.', NULL, 1, SYSDATE);

-- Tree Columns 
INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
1301, 'Tree Column Type', 'Tree Column', 'Specifies the formula to get the grid label', 'Node|Data', 0, SYSDATE);
INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
1302, 'Node Name', 'Tree Column', 'Defines which "Node Tree" Column it is associated with.', NULL, 0, SYSDATE);
INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
1303, 'Formula', 'Tree Column', 'Defines a formula that can be evaluated to populate the value of a tree node.', NULL, 0, SYSDATE);
INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
1304, 'Display Formula', 'Tree Column', 'Specifies the formula that defines the display text used by the tree node.', NULL, 0, SYSDATE);
INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
1305, 'Icon Formula', 'Tree Column', 'Specifies the formula that defines the name of the icon used by the tree node.', NULL, 0, SYSDATE);

-- Data Exchanges
INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
1401, 'Type', 'Data Exchange', 'Specifies the Type of Data Exchange.', '|Data Exchange|Bid Offer|Billing Export|Billing Calculate|SO Import|SO Export', 0, SYSDATE);
INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
1402, 'Entity List Procedure', 'Data Exchange', 'Specifies the stored procedure to call to populate the entity list on the Data Exchange Dialog.', NULL, 0, SYSDATE);
INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
1403, 'Show Delimiters', 'Data Exchange', 'Specifies that the Data Exchange Dialog should show the list of delimiters specified in System Settings under Global/Data Import/Delimiters.', NULL, 1, SYSDATE);
INSERT INTO SYSTEM_ATTRIBUTE ( ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY, ATTRIBUTE_DESC, ATTRIBUTE_COMBO_LIST, ATTRIBUTE_IS_BOOLEAN, ENTRY_DATE ) VALUES ( 
1404, 'Single Select Entity List', 'Data Exchange', 'Specifies that the Data Exchange Dialog should only allow a single entity to be selected.', NULL, 1, SYSDATE);

COMMIT;
