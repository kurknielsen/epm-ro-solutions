DEFINE DEFAULT_LOC = 'C:\CVSRoot\branch_v4_1_0_ui_20080214\RetailOffice\Database\MINT'

PROMPT Setting the default market data
@&DEFAULT_LOC\Common\Setup.sql

PROMPT MISO DATA
@&DEFAULT_LOC\MISO\SetupMarket.sql

PROMPT NY-ISO DATA
@&DEFAULT_LOC\NY-ISO\SetupMarket.sql

PROMPT PJM DATA
@&DEFAULT_LOC\PJM\SetupMarket.sql

PROMPT ERCOT DATA
@&DEFAULT_LOC\ERCOT\SetupMarket.sql

PROMPT SEM DATA
@&DEFAULT_LOC\SEM\SetupMarket.sql

PROMPT OASIS DATA
@&DEFAULT_LOC\OASIS\SetupMarket.sql

PROMPT TDIE DATA
@&DEFAULT_LOC\TDIE\SetupMarket.sql

commit;