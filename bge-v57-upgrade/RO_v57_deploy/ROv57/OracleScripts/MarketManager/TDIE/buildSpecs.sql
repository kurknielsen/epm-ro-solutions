SET DEFINE OFF      
prompt Market: TDIE
prompt =================
prompt compiling TDIE package specs
prompt =================

prompt SEQUENCE
@@sequence.sql

prompt TDIE_INVOICE_Types.sql
@@ TDIE_INVOICE_Types.sql

prompt MM_TDIE_UTIL.sql
@@MM_TDIE_UTIL.sql

prompt MM_TDIE_IMPORTS.sql
@@MM_TDIE_IMPORTS.sql

prompt MM_TDIE_UI.sql
@@MM_TDIE_UI.sql

prompt MM_TDIE_BACKING_SHEETS_UI.sql
@@MM_TDIE_BACKING_SHEETS_UI.sql

prompt MM_TDIE_BACKING_SHEETS.sql
@@MM_TDIE_BACKING_SHEETS.sql

prompt MM_TDIE_INVOICE.sql
@@MM_TDIE_INVOICE.sql

prompt MM_TDIE_INVOICE_UI.sql
@@MM_TDIE_INVOICE_UI.sql

PROMPT Building the Triggers...
@@TRIGGERS.sql

PROMPT Building the Views...
@@VIEWS.sql

SET DEFINE ON
