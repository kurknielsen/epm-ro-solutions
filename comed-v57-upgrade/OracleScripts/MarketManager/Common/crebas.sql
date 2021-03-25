DEFINE DEFAULT_LOC= 'C:\ROv57\OracleScripts'

DEFINE MINT_DIR = 'MarketManager'
DEFINE MEX_DIR = 'MEX'

spool creabas.log

@&DEFAULT_LOC\&MINT_DIR\Common\crebasWorker.sql &DEFAULT_LOC &MINT_DIR &MEX_DIR

spool off;
exit;

