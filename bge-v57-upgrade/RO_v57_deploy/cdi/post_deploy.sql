set verify off
spool post_deploy.log

prompt *** dml *************************************************************************************************************************
@@dml/deploy.sql

spool off;
exit;
