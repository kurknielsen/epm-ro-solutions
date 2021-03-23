CREATE OR REPLACE PACKAGE MM_SEM_CFD_UTIL IS

  -- $Revision: 1.4 $

	--USD Exchange Rates
	k_PRICE_EXCH_EUR_TO_USD  CONSTANT VARCHAR2(32) := 'Exchange Rate: Euro to USD';
	k_PRICE_EXCH_GBP_TO_USD  CONSTANT VARCHAR2(32) := 'Exchange Rate: GBP to USD';
	--k_PRICE_EXCH_EUR_TO_GBP  CONSTANT VARCHAR2(64) := 'Trading Day Exchange Rate: Euro to Pound';
	k_PRICE_EXCH_EUR_TO_GBP  CONSTANT VARCHAR2(64) := 'ECB Exchange Rate (GBP/EUR)';

	--Forward Natural Gas Price in GBP/Therm (NG in calculations)
	k_PRICE_NAT_GAS CONSTANT VARCHAR2(64) := 'Forward Natural Gas Price in p/therm';

	--Forward Low Sulphur Fuel Oil Price in USD/metric tonne (LSFO in calculations)
	k_PRICE_LOW_SULPHUR_FUEL_USD CONSTANT VARCHAR2(64) := 'Forward Low Sulphur Fuel Oil Price in USD';

	--Forward Gasoil Frontline Swaps Price in USD/metric tonne (GO in calculations)
	k_PRICE_GASOIL_FRONTLINE_USD CONSTANT VARCHAR2(64) := 'Forward Gasoil Frontline Swaps Price in USD';
	--Forward Gasoil 0.2% Cargo Swaps Price in USD/metric tonne (GO in calculations)
	k_PRICE_GASOIL_CARGO_USD CONSTANT VARCHAR2(64) := 'Forward Gasoil Cargo Swaps Price in USD';

	--Forward Carbon Price in Euro/metric tonne (C in calculations)
	k_PRICE_CARBON CONSTANT VARCHAR(64) := 'Forward Carbon Price in EUR';

	--Currency names
	k_CURRENCY_EUR CONSTANT VARCHAR2(8) := 'EUR';
	k_CURRENCY_GBP CONSTANT VARCHAR2(8) := 'GBP';

	--Credit Cover Regimes
	k_CC_REGIME_ESTSEM CONSTANT VARCHAR2(32) := 'ESTSEM';
	k_CC_REGIME_INDEX CONSTANT VARCHAR2(32) := 'Index';
	k_CC_REGIME_PERCENTAGE CONSTANT VARCHAR2(32) := 'Percentage';
	k_CC_REGIME_NONE CONSTANT VARCHAR2(32) := 'None';

	--Cutoff Options
	k_CUTOFF_INDEX_UNKNOWN CONSTANT VARCHAR2(32) := 'Until Index Unknown';
	k_CUTOFF_END_OF_MONTH CONSTANT VARCHAR2(32) := 'End of month';
	k_CUTOFF_WDX CONSTANT VARCHAR2(32) := 'WDX';

	--Other Constants
	k_LOW_DATE                       CONSTANT DATE           := LOW_DATE;
	k_TIME_ZONE                      CONSTANT CHAR(3)        := 'EDT';
	k_ALL_TXT_FILTER                 CONSTANT VARCHAR2(16)   := '<ALL>';
	k_ALL_INT_FILTER                 CONSTANT INTEGER        := -1;
	k_CONTRACT_TYPE_DIRECTED         CONSTANT VARCHAR2(32)   := 'DC';
	k_CONTRACT_TYPE_NON_DIRECTED     CONSTANT VARCHAR2(32)   := 'NDC';
	k_AGREEMENT_BUYER_PAYS           CONSTANT VARCHAR2(32)   := 'Buyer pays';
	k_AGREEMENT_SELLER_PAYS          CONSTANT VARCHAR2(32)   := 'Seller pays';
	k_VAT_SCHEDULE_TYPE_ID           CONSTANT NUMBER(1)      := 3;
	k_ONE_SECOND                     CONSTANT NUMBER         := 1/86400;
	k_INDEX_PRICE_CODE               CONSTANT CHAR(1)        := 'A';

	FUNCTION WHAT_VERSION RETURN VARCHAR;

FUNCTION PUT_MARKET_PRICE(p_PRICE_NAME IN MARKET_PRICE.MARKET_PRICE_NAME%TYPE,
						  p_PRICE_DATE IN MARKET_PRICE_VALUE.PRICE_DATE%TYPE,
						  p_PRICE IN MARKET_PRICE_VALUE.PRICE%TYPE) RETURN NUMBER;
END MM_SEM_CFD_UTIL;
/