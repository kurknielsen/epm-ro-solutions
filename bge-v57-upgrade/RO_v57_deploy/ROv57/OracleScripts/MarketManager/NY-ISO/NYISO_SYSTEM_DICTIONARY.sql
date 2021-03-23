-- CVS Revision: $Revision: 1.2 $
SET DEFINE OFF	

BEGIN
  -- LMPs
  PUT_DICTIONARY_VALUE('URL', 'http://mis.nyiso.com/public/csv/damlbmp/', 0, 'MarketExchange', 'NYISO', 'LBMP', 'Zonal DA');
  PUT_DICTIONARY_VALUE('URL', 'http://mis.nyiso.com/public/csv/damlbmp/', 0, 'MarketExchange', 'NYISO', 'LBMP', 'Generator DA');
  PUT_DICTIONARY_VALUE('URL', 'http://mis.nyiso.com/public/csv/refbus/', 0, 'MarketExchange', 'NYISO', 'LBMP', 'Reference Bus DA');
  PUT_DICTIONARY_VALUE('URL', 'http://mis.nyiso.com/public/csv/rtlbmp/', 0, 'MarketExchange', 'NYISO', 'LBMP', 'Zonal RTI');
  PUT_DICTIONARY_VALUE('URL', 'http://mis.nyiso.com/public/csv/rtlbmp/', 0, 'MarketExchange', 'NYISO', 'LBMP', 'Generator RTI');
  PUT_DICTIONARY_VALUE('URL', 'http://mis.nyiso.com/public/csv/refbus/', 0, 'MarketExchange', 'NYISO', 'LBMP', 'Reference Bus RTI');
  PUT_DICTIONARY_VALUE('URL', 'http://mis.nyiso.com/public/csv/hamlbmp/', 0, 'MarketExchange', 'NYISO', 'LBMP', 'Zonal BHA');
  PUT_DICTIONARY_VALUE('URL', 'http://mis.nyiso.com/public/csv/hamlbmp/', 0, 'MarketExchange', 'NYISO', 'LBMP', 'Generator BHA');
  PUT_DICTIONARY_VALUE('URL', 'http://mis.nyiso.com/public/csv/refbus/', 0, 'MarketExchange', 'NYISO', 'LBMP', 'Reference Bus BHA');
  -- Load
  PUT_DICTIONARY_VALUE('URL', 'http://mis.nyiso.com/public/csv/isolf/', 0, 'MarketExchange', 'NYISO', 'LOAD', 'ISO Load');
  PUT_DICTIONARY_VALUE('URL', 'http://mis.nyiso.com/public/csv/pal/', 0, 'MarketExchange', 'NYISO', 'LOAD', 'Real Time Load');
  PUT_DICTIONARY_VALUE('URL', 'http://mis.nyiso.com/public/csv/palIntegrated/', 0, 'MarketExchange', 'NYISO', 'LOAD', 'Integrated Real Time Load');
  -- TC
  PUT_DICTIONARY_VALUE('URL', 'http://mis.nyiso.com/public/csv/atc_ttc/', 0, 'MarketExchange', 'NYISO', 'TC', 'ATC TTC');


END;
/
-- save changes to database
COMMIT;
SET DEFINE ON	
--Reset
