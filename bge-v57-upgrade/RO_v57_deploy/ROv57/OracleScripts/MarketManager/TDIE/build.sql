SET DEFINE OFF      
prompt Market: TDIE
prompt =================
prompt compiling TDIE package bodies
prompt =================

prompt MM_TDIE_UTIL.sql
@@MM_TDIE_UTIL-body.sql

prompt MM_TDIE_IMPORTS.sql
@@MM_TDIE_IMPORTS-body.sql

prompt MM_TDIE_UI.sql
@@MM_TDIE_UI-body.sql

prompt MM_TDIE_BACKING_SHEETS_UI.sql
@@MM_TDIE_BACKING_SHEETS_UI-body.sql

prompt MM_TDIE_BACKING_SHEETS.sql
@@MM_TDIE_BACKING_SHEETS-body.sql

prompt MM_TDIE_INVOICE.sql
@@MM_TDIE_INVOICE-body.sql

prompt MM_TDIE_INVOICE_UI.sql
@@MM_TDIE_INVOICE_UI-body.sql

SET DEFINE ON
