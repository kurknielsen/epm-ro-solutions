--------------------------------------------------
-- Export file for user ROMO                    --
-- Created by USKUNIE on 1/27/2021, 12:41:54 AM --
--------------------------------------------------

set define off
spool packages_merged.log

prompt
prompt Creating package CS
prompt ===================
prompt
@@cs.pkg
prompt
prompt Creating package MM
prompt ===================
prompt
--@@mm.pkg
prompt
prompt Creating package MS
prompt ===================
prompt
@@ms.pkg
prompt
prompt Creating package XS
prompt ===================
prompt
@@xs.pkg
prompt
prompt Creating package body ACCOUNTS_METERS
prompt =====================================
prompt
@@accounts_meters.pkb
prompt
prompt Creating package body AUDIT_TRAIL
prompt =================================
prompt
@@audit_trail.pkb
prompt
prompt Creating package body CS
prompt ========================
prompt
@@cs.pkb
prompt
prompt Creating package body CX
prompt ========================
prompt
@@cx.pkb
prompt
prompt Creating package body FP
prompt ========================
prompt
@@fp.pkb
prompt
prompt Creating package body FS
prompt ========================
prompt
@@fs.pkb
prompt
prompt Creating package body IO
prompt ========================
prompt
@@io.pkb
prompt
prompt Creating package body ITJ
prompt =========================
prompt
@@itj.pkb
prompt
prompt Creating package body LI
prompt ========================
prompt
--@@li.pkb
prompt
prompt Creating package body MEX_SWITCHBOARD
prompt =====================================
prompt
@@mex_switchboard.pkb
prompt
prompt Creating package body MM
prompt ========================
prompt
--@@mm.pkb
prompt
prompt Creating package body MS
prompt ========================
prompt
@@ms.pkb
prompt
prompt Creating package body PF
prompt ========================
prompt
@@pf.pkb
prompt
prompt Creating package body PI
prompt ========================
prompt
@@pi.pkb
prompt
prompt Creating package body PR
prompt ========================
prompt
@@pr.pkb
prompt
prompt Creating package body QC
prompt ========================
prompt
@@qc.pkb
prompt
prompt Creating package body XS
prompt ========================
prompt
@@xs.pkb

spool off
