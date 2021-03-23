prompt Market: ISONE

--prompt ISONE crebas
--@@crebas.sql

prompt Creating ISONE objects
@@isone_objects.sql

prompt =================
prompt build ISONE Logic
prompt =================

prompt MEX_ISONE
@@mex_isone.sql

set define off

prompt MEX_ISONE_LMP
@@mex_isone_lmp.sql

set define on