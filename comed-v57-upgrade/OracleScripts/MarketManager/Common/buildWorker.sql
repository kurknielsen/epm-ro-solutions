spool &3

prompt ********************************************************
prompt Building MINT using scripts in &1
prompt ********************************************************

prompt Common tables and sequences
@&1\&2\common\SEQUENCE.sql

prompt compiling MEX and MINT package specs
@&1\MEX\Common\buildSpecs.sql
@&1\&2\Common\buildSpecs.sql

prompt MEX build
@&1\MEX\Common\buildWorker.sql &1

prompt Other common
@&1\&2\common\MM_UTIL-body.sql
@&1\&2\functions\build.sql

prompt building PJM...
@&1\&2\PJM\build.sql

--prompt building MISO...
--@&1\&2\MISO\build.sql

--prompt building NYISO...
--@&1\&2\NY-ISO\build.sql

--prompt building ETAG...
--@&1\&2\ETAG\build.sql

--prompt building TSIN...
--@&1\&2\TSIN\build.sql

--prompt building OASIS...
--@&1\&2\OASIS\build.sql

--prompt building ISONE...
--@&1\&2\ISONE\build.sql

--prompt building ERCOT...
--@&1\&2\ERCOT\build.sql

--prompt building SEM...
--@&1\&2\SEM\build.sql

prompt compiling MM package...
@&1\&2\common\MM-body.sql

--prompt building TDIE...
--@&1\&2\TDIE\build.sql

prompt Enabling MEX Switchboard external system...
BEGIN
UPDATE EXTERNAL_SYSTEM SET IS_ENABLED=1 WHERE EXTERNAL_SYSTEM_ID=EC.ES_MEX_SWITCHBOARD;
END;
/

prompt Initializing layouts...
@&1\&2\common\LayoutDefaultsMarketManager.sql
