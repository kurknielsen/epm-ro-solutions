DEFINE DEFAULT_LOC= 'C:\ROv57\OracleScripts'

DEFINE MINT_DIR = 'MarketManager'
DEFINE LOG_FILE = 'databaseMINTBuildWorker.log'

@&DEFAULT_LOC\&MINT_DIR\Common\buildWorker.sql &DEFAULT_LOC &MINT_DIR &LOG_FILE

spool off;
exit;

