CREATE OR REPLACE PACKAGE BODY MM_TDIE_BACKING_SHEETS IS
--------------------------------------------------------------------------------
-- Created : 11/19/2009 12:14
-- Purpose : Download Retail Financial Settlement Backing Sheets
-- $Revision: 1.6 $
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
--                PACKAGE TYPES, CONSTANTS AND VARIABLES
--------------------------------------------------------------------------------
g_PACKAGE_NAME         CONSTANT VARCHAR(30)    := 'MM_TDIE_BACKING_SHEETS';
g_TUOS_DATE_FORMAT     CONSTANT VARCHAR2(11)   := 'DD-MON-YY';

g_UOS_DATE_FORMAT      CONSTANT VARCHAR2(10)    := 'DD/MM/YYYY';
g_UOS_TIMESTAMP_FORMAT CONSTANT VARCHAR2(32)   := g_UOS_DATE_FORMAT || ' HH24:MI:SS';

g_CSV_DATE_FORMAT      CONSTANT VARCHAR2(8)    := 'YYYYMMDD';
g_CSV_TIMESTAMP_FORMAT CONSTANT VARCHAR2(32)   := 'YYYYMMDDHH24MISS';
g_DBG_DATETIME_FORMAT  CONSTANT VARCHAR2(25)   := 'MM-DD-YYYY HH24:MI:SS';
g_CRLF                 CONSTANT VARCHAR2(10)   := UTL_TCP.CRLF;
--g_SUCCESS              CONSTANT NUMBER         := GA.SUCCESS;
--g_FAILURE              CONSTANT NUMBER         := 1; -- No Constant Exists.
g_BACKING_SHEET_DUOS   CONSTANT VARCHAR2(10)    := 'DUoS (ROI)';
g_BACKING_SHEET_DUOS_NI CONSTANT VARCHAR2(9)   := 'DUoS (NI)';
g_BACKING_SHEET_TUOS   CONSTANT VARCHAR2(10)    := 'TUoS (ROI)';
g_BACKING_SHEET_UOS    CONSTANT VARCHAR2(4)    := 'UoS';
g_IMPORT_TIMESTAMP              DATE           := NULL;
g_IMPORT_FILE_PATH              VARCHAR2(1000) := NULL;
g_PROCESS_ID                    VARCHAR2(12)   := NULL;

c_MINUS_NUM_FORMAT     CONSTANT VARCHAR2(20)   := '9999999999D9999999MI';
c_NUM_FORMAT           CONSTANT VARCHAR2(20)   := '9999999999D9999999';

--------------------------------------------------------------------------------
--                  PRIVATE PROCEDURES AND FUNCTIONS
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- This function converts the string values into numeric values where needed.
-- If the value is able to convert to a number then number is returned otherwise
-- a NULL value is returned.
FUNCTION CONVERT_TO_NUMBER(p_INPUT_STRING  IN VARCHAR2,
                           p_FORMAT_STRING IN VARCHAR2 DEFAULT NULL)
RETURN NUMBER IS
BEGIN
   IF p_FORMAT_STRING IS NOT NULL THEN
      RETURN TO_NUMBER(p_INPUT_STRING, p_FORMAT_STRING);
   ELSE
      RETURN TO_NUMBER(p_INPUT_STRING);
   END IF;
EXCEPTION
   WHEN VALUE_ERROR THEN
      ERRS.RAISE(p_MESSAGE_CODE => MSGCODES.c_ERR_INVALID_NUMBER,
                 p_EXTRA_MESSAGE => 'Invalid number ['||p_INPUT_STRING||
                                    CASE
                                       WHEN p_FORMAT_STRING IS NOT NULL THEN
                                          '] the expected format is ['||p_FORMAT_STRING||'].'
                                       ELSE
                                          '].'
                                    END);
END CONVERT_TO_NUMBER;

--------------------------------------------------------------------------------
-- This function converts the string values into date values where needed.
-- If the value is able to convert to a date then date is returned otherwise
-- a NULL value is returned.
FUNCTION CONVERT_TO_DATE(p_INPUT_STRING  IN VARCHAR2,
                         p_FORMAT_STRING IN VARCHAR2)
RETURN DATE IS
BEGIN
   RETURN TO_DATE(p_INPUT_STRING, p_FORMAT_STRING);
EXCEPTION
   WHEN OTHERS THEN
      IF SQLCODE BETWEEN -1899 AND -1800 THEN
        ERRS.RAISE(p_MESSAGE_CODE => MSGCODES.c_ERR_INVALID_DATE,
                   p_EXTRA_MESSAGE => 'Invalid date ['||p_INPUT_STRING
                                      ||'] the expected format ['
                                      ||p_FORMAT_STRING||'].');
      ELSE
        ERRS.LOG_AND_RAISE(p_LOG_LEVEL => LOGS.c_LEVEL_DEBUG);
      END IF;

END CONVERT_TO_DATE;

--------------------------------------------------------------------------------
-- This is a private routine for maintaining the list of codes for the TUoS
-- backing sheet API.  The codes are stored in the TDIE_TUOS_
PROCEDURE MAINTAIN_TUOS_CODES(p_INVOICE_NUMBER  IN VARCHAR2)
IS
   TYPE t_TUOS_CODE_REC IS RECORD(CODE_TYPE  VARCHAR2(64),
                                  CODE_NAME  VARCHAR2(64));

   TYPE v_TUOS_CODES_TAB_TYPE IS TABLE OF t_TUOS_CODE_REC INDEX BY BINARY_INTEGER;

   c_CODE_TYPE_METER     CONSTANT VARCHAR2(64) := 'METER_NAME';
   c_CODE_TYPE_ACCOUNT   CONSTANT VARCHAR2(64) := 'ACCOUNT_CODE';
   c_CODE_TYPE_CHARGE    CONSTANT VARCHAR2(64) := 'CHARGE_TYPE';
   c_CODE_TYPE_RATE      CONSTANT VARCHAR2(64) := 'RATE_NAME';
   c_CODE_TYPE_QUANTITY  CONSTANT VARCHAR2(64) := 'QUANTITY_NAME';
   v_TUOS_CODES_TAB               v_TUOS_CODES_TAB_TYPE;

BEGIN
   -----------------------------------------------------------------------------
   -- Maintain METER_NAMEs code types.
   BEGIN
      SELECT DISTINCT
             c_CODE_TYPE_METER AS CODE_TYPE,
             TTID.METER_NAME   AS CODE_VALUE
        BULK COLLECT INTO v_TUOS_CODES_TAB
        FROM TDIE_TUOS_INVOICE_DETAIL TTID
       WHERE TTID.INVOICE_NUMBER = p_INVOICE_NUMBER
         AND TTID.METER_NAME IS NOT NULL
         AND TTID.METER_NAME NOT IN (SELECT TTC.CODE_VALUE
                                       FROM TDIE_TUOS_CODES TTC
                                      WHERE TTC.CODE_TYPE = c_CODE_TYPE_METER);

      IF v_TUOS_CODES_TAB.COUNT > 0 THEN
         FORALL M IN v_TUOS_CODES_TAB.FIRST..v_TUOS_CODES_TAB.LAST
            INSERT INTO TDIE_TUOS_CODES VALUES v_TUOS_CODES_TAB(M);
      END IF;--IF v_TUOS_CODES_TAB.COUNT > 0 THEN

      EXCEPTION
         WHEN NO_DATA_FOUND THEN
            NULL; -- NO NEW VALUES
   END;-- Maintain METER_NAMEs code types.

   -----------------------------------------------------------------------------
   -- Maintain ACCOUNT_CODEs code types.
   BEGIN
      SELECT DISTINCT
             c_CODE_TYPE_ACCOUNT AS CODE_TYPE,
             TTID.ACCOUNT_CODE   AS CODE_VALUE
        BULK COLLECT INTO v_TUOS_CODES_TAB
        FROM TDIE_TUOS_INVOICE_DETAIL TTID
       WHERE TTID.INVOICE_NUMBER = p_INVOICE_NUMBER
         AND TTID.ACCOUNT_CODE IS NOT NULL
         AND TTID.ACCOUNT_CODE NOT IN (SELECT TTC.CODE_VALUE
                                         FROM TDIE_TUOS_CODES TTC
                                        WHERE TTC.CODE_TYPE = c_CODE_TYPE_ACCOUNT);

      IF v_TUOS_CODES_TAB.COUNT > 0 THEN
         FORALL A IN v_TUOS_CODES_TAB.FIRST..v_TUOS_CODES_TAB.LAST
            INSERT INTO TDIE_TUOS_CODES VALUES v_TUOS_CODES_TAB(A);

      END IF;--IF v_TUOS_CODES_TAB.COUNT > 0 THEN

      EXCEPTION
         WHEN NO_DATA_FOUND THEN
            NULL; -- NO NEW VALUES
   END;-- Maintain ACCOUNT_CODEs code types.

   -----------------------------------------------------------------------------
   -- Maintain CHARGE_TYPEs code types.
   BEGIN
      SELECT DISTINCT
             c_CODE_TYPE_CHARGE AS CODE_TYPE,
             TTICD.INV_DET_NAME AS CODE_VALUE
        BULK COLLECT INTO v_TUOS_CODES_TAB
        FROM TDIE_TUOS_INV_CHARGE_DTL TTICD
       WHERE TTICD.INVOICE_NUMBER = p_INVOICE_NUMBER
         AND TTICD.INV_DET_NAME IS NOT NULL
         AND TTICD.INV_DET_TYPE = c_TUOS_DET_TYPE_CHG_INTRVL
         AND TTICD.INV_DET_NAME NOT IN (SELECT TTC.CODE_VALUE
                                          FROM TDIE_TUOS_CODES TTC
                                         WHERE TTC.CODE_TYPE = c_CODE_TYPE_CHARGE);

      IF v_TUOS_CODES_TAB.COUNT > 0 THEN
         FORALL C IN v_TUOS_CODES_TAB.FIRST..v_TUOS_CODES_TAB.LAST
            INSERT INTO TDIE_TUOS_CODES VALUES v_TUOS_CODES_TAB(C);

      END IF;--IF v_TUOS_CODES_TAB.COUNT > 0 THEN

      EXCEPTION
         WHEN NO_DATA_FOUND THEN
            NULL; -- NO NEW VALUES
   END;-- Maintain CHARGE_TYPEs code types.

   -----------------------------------------------------------------------------
   -- Maintain RATE_NAMEs code types.
   BEGIN
      SELECT DISTINCT
             c_CODE_TYPE_RATE AS CODE_TYPE,
             TTICD.INV_DET_NAME AS CODE_VALUE
        BULK COLLECT INTO v_TUOS_CODES_TAB
        FROM TDIE_TUOS_INV_CHARGE_DTL TTICD
       WHERE TTICD.INVOICE_NUMBER = p_INVOICE_NUMBER
         AND TTICD.INV_DET_NAME IS NOT NULL
         AND TTICD.INV_DET_TYPE = c_TUOS_DET_TYPE_RATES
         AND TTICD.INV_DET_NAME NOT IN (SELECT TTC.CODE_VALUE
                                          FROM TDIE_TUOS_CODES TTC
                                         WHERE TTC.CODE_TYPE = c_CODE_TYPE_RATE);

      IF v_TUOS_CODES_TAB.COUNT > 0 THEN
         FORALL R IN v_TUOS_CODES_TAB.FIRST..v_TUOS_CODES_TAB.LAST
            INSERT INTO TDIE_TUOS_CODES VALUES v_TUOS_CODES_TAB(R);

      END IF;--IF v_TUOS_CODES_TAB.COUNT > 0 THEN

      EXCEPTION
         WHEN NO_DATA_FOUND THEN
            NULL; -- NO NEW VALUES
   END;-- Maintain RATE_NAMEs code types.

   -----------------------------------------------------------------------------
   -- Maintain QUANTITY_NAMEs code types.
   BEGIN
      SELECT DISTINCT
             c_CODE_TYPE_QUANTITY AS CODE_TYPE,
             TTICD.INV_DET_NAME AS CODE_VALUE
        BULK COLLECT INTO v_TUOS_CODES_TAB
        FROM TDIE_TUOS_INV_CHARGE_DTL TTICD
       WHERE TTICD.INVOICE_NUMBER = p_INVOICE_NUMBER
         AND TTICD.INV_DET_NAME IS NOT NULL
         AND TTICD.INV_DET_TYPE = c_TUOS_DET_TYPE_CHG_PARM
         AND TTICD.INV_DET_NAME NOT IN (SELECT TTC.CODE_VALUE
                                          FROM TDIE_TUOS_CODES TTC
                                         WHERE TTC.CODE_TYPE = c_CODE_TYPE_QUANTITY);

      IF v_TUOS_CODES_TAB.COUNT > 0 THEN
         FORALL Q IN v_TUOS_CODES_TAB.FIRST..v_TUOS_CODES_TAB.LAST
            INSERT INTO TDIE_TUOS_CODES VALUES v_TUOS_CODES_TAB(Q);

      END IF;--IF v_TUOS_CODES_TAB.COUNT > 0 THEN

      EXCEPTION
         WHEN NO_DATA_FOUND THEN
            NULL; -- NO NEW VALUES
   END;-- Maintain QUANTITY_NAMEs code types.


END MAINTAIN_TUOS_CODES;


--------------------------------------------------------------------------------
-- This is a private routine for mapping the TUoS supply units
PROCEDURE MAP_TUOS_SUPPLY_UNITS(p_INVOICE_NUMBER  IN VARCHAR2)
IS
   CURSOR cur_TUOS_INV_DTL IS
      SELECT *
        FROM TDIE_TUOS_INVOICE_DETAIL
       WHERE INVOICE_NUMBER = p_INVOICE_NUMBER
         FOR UPDATE;

   v_MPRN          TDIE_TUOS_INVOICE_DETAIL.MPRN%TYPE := NULL;
   v_SUPPLY_UNIT   TDIE_TUOS_INVOICE_DETAIL.SUPPLY_UNIT%TYPE := NULL;

BEGIN

   FOR TID IN cur_TUOS_INV_DTL LOOP
      v_MPRN        := NULL;
      v_SUPPLY_UNIT := NULL;

      -- Mapping lookup
      BEGIN
         SELECT TSUP.SUPPLY_UNIT,
                NULL
           INTO v_SUPPLY_UNIT,
                v_MPRN
           FROM TDIE_TUOS_SUPPLY_UNIT_MAP TSUP
          WHERE TSUP.ACCOUNT_CODE = TID.ACCOUNT_CODE
            AND TSUP.METER_NAME   = TID.METER_NAME;

         EXCEPTION
            WHEN NO_DATA_FOUND THEN
               v_MPRN        := TID.METER_NAME;
               v_SUPPLY_UNIT := NULL;
      END;-- Lookup mapping...

      UPDATE TDIE_TUOS_INVOICE_DETAIL
         SET MPRN = v_MPRN,
             SUPPLY_UNIT = v_SUPPLY_UNIT
       WHERE CURRENT OF cur_TUOS_INV_DTL;

   END LOOP;--FOR TID IN cur_TUOS_INV_DTL LOOP

END MAP_TUOS_SUPPLY_UNITS;

--------------------------------------------------------------------------------
-- This is a private function to format the given table record into a string.
FUNCTION TO_CHAR_TDIE_DUOS_INV(
   p_REC     IN TDIE_DUOS_INVOICE%ROWTYPE
   ) RETURN VARCHAR2 IS
BEGIN
   RETURN ('INVOICE_NUMBER            = '||p_REC.INVOICE_NUMBER||', '||g_CRLF
         ||'SENDER_CID                = '||p_REC.SENDER_CID||', '||g_CRLF
         ||'RECIPIENT_CID             = '||p_REC.RECIPIENT_CID||', '||g_CRLF
         ||'MARKET_TIMESTAMP          = '||TO_CHAR(p_REC.MARKET_TIMESTAMP,g_DBG_DATETIME_FORMAT)||g_CRLF
         ||'CONTROL_TOTAL             = '||TO_CHAR(p_REC.CONTROL_TOTAL)||', '||g_CRLF
         ||'TOTAL_RECORDS             = '||TO_CHAR(p_REC.TOTAL_RECORDS)||', '||g_CRLF
         ||'RETAIL_INVOICE_ID         = '||TO_CHAR(p_REC.RETAIL_INVOICE_ID)||', '||g_CRLF
         ||'NET_CHARGE_AMT_IMPORTED   = '||TO_CHAR(p_REC.NET_CHARGE_AMT_IMPORTED)||', '||g_CRLF
         ||'GROSS_CHARGE_AMT_IMPORTED = '||TO_CHAR(p_REC.GROSS_CHARGE_AMT_IMPORTED)||', '||g_CRLF
         ||'RECORDS_IMPORTED          = '||TO_CHAR(p_REC.RECORDS_IMPORTED)||', '||g_CRLF
         ||'IMPORT_TIMESTAMP          = '||TO_CHAR(p_REC.IMPORT_TIMESTAMP,g_DBG_DATETIME_FORMAT)||g_CRLF
         ||'FILE_NAME                 = '||p_REC.FILE_NAME||', '||g_CRLF
         ||'PROCESS_ID                = '||TO_CHAR(p_REC.PROCESS_ID)||'.'||g_CRLF);
END TO_CHAR_TDIE_DUOS_INV;


--------------------------------------------------------------------------------
-- This is a private function to format the given table record into a string.
FUNCTION TO_CHAR_TDIE_DUOS_INV_DTL(
   p_REC     IN TDIE_DUOS_INVOICE_DETAIL%ROWTYPE
   ) RETURN VARCHAR2 IS
BEGIN
   RETURN ('INVOICE_NUMBER           = '||p_REC.INVOICE_NUMBER||', '||g_CRLF
         ||'INVOICE_ITEM_NUMBER      = '||TO_CHAR(p_REC.INVOICE_ITEM_NUMBER)||', '||g_CRLF
         ||'MPRN                     = '||p_REC.MPRN||', '||g_CRLF
         ||'ADJUSTED_REFERENCE       = '||TO_CHAR(p_REC.ADJUSTED_REFERENCE)||', '||g_CRLF
         ||'INVOICE_TYPE             = '||p_REC.INVOICE_TYPE||', '||g_CRLF
         ||'DUOS_GROUP               = '||p_REC.DUOS_GROUP||', '||g_CRLF
         ||'BILLING_BEGIN_DATE       = '||TO_CHAR(p_REC.BILLING_BEGIN_DATE,g_DBG_DATETIME_FORMAT)||g_CRLF
         ||'BILLING_END_DATE         = '||TO_CHAR(p_REC.BILLING_END_DATE,g_DBG_DATETIME_FORMAT)||g_CRLF
         ||'ENERGY_CONSUMPTION_DAY   = '||TO_CHAR(p_REC.ENERGY_CONSUMPTION_DAY)||', '||g_CRLF
         ||'ENERGY_CHARGE_DAY        = '||TO_CHAR(p_REC.ENERGY_CHARGE_DAY)||', '||g_CRLF
         ||'ENERGY_CONSUMPTION_NIGHT = '||TO_CHAR(p_REC.ENERGY_CONSUMPTION_NIGHT)||', '||g_CRLF
         ||'ENERGY_CHARGE_NIGHT      = '||TO_CHAR(p_REC.ENERGY_CHARGE_NIGHT)||', '||g_CRLF
         ||'ENERGY_CONSUMPTION_24HR  = '||TO_CHAR(p_REC.ENERGY_CONSUMPTION_24HR)||', '||g_CRLF
         ||'ENERGY_CHARGE_24HR       = '||TO_CHAR(p_REC.ENERGY_CHARGE_24HR)||', '||g_CRLF
         ||'STANDING_CHARGE          = '||TO_CHAR(p_REC.STANDING_CHARGE)||', '||g_CRLF
         ||'CAPACITY_CHARGE          = '||TO_CHAR(p_REC.CAPACITY_CHARGE)||', '||g_CRLF
         ||'MAX_IMPORT_CAPACITY      = '||TO_CHAR(p_REC.MAX_IMPORT_CAPACITY)||', '||g_CRLF
         ||'MAX_KVA                  = '||TO_CHAR(p_REC.MAX_KVA)||', '||g_CRLF
         ||'MIC_SURCHARGE            = '||TO_CHAR(p_REC.MIC_SURCHARGE)||', '||g_CRLF
         ||'REACTIVE_ENERGY          = '||TO_CHAR(p_REC.REACTIVE_ENERGY)||', '||g_CRLF
         ||'POWER_FACTOR_SURCHARGE   = '||TO_CHAR(p_REC.POWER_FACTOR_SURCHARGE)||', '||g_CRLF
         ||'NET_AMOUNT               = '||TO_CHAR(p_REC.NET_AMOUNT)||', '||g_CRLF
         ||'GROSS_AMOUNT             = '||TO_CHAR(p_REC.GROSS_AMOUNT)||'.'||g_CRLF);
END TO_CHAR_TDIE_DUOS_INV_DTL;

--------------------------------------------------------------------------------
-- This is a private function to format the given table record into a string.
FUNCTION TO_CHAR_TDIE_DUOS_NI_INV(
   p_REC     IN TDIE_DUOS_NI_INVOICE%ROWTYPE
   ) RETURN VARCHAR2 IS
BEGIN
   RETURN ('INVOICE_NUMBER            = '||p_REC.INVOICE_NUMBER||', '||g_CRLF
         ||'PROVIDER                  = '||p_REC.PROVIDER||', '||g_CRLF
         ||'SUPPLIER                  = '||p_REC.SUPPLIER||', '||g_CRLF
         ||'MARKET_TIMESTAMP          = '||TO_CHAR(p_REC.MARKET_TIMESTAMP,g_DBG_DATETIME_FORMAT)||g_CRLF
         ||'TOTAL_ITEMISED_LINES      = '||TO_CHAR(p_REC.TOTAL_ITEMISED_LINES)||', '||g_CRLF
         ||'RECORDS_IMPORTED          = '||TO_CHAR(p_REC.RECORDS_IMPORTED)||', '||g_CRLF
         ||'MPRN_COUNT                = '||TO_CHAR(p_REC.MPRN_COUNT)||', '||g_CRLF
         ||'IMPORTED_REVENUE          = '||TO_CHAR(p_REC.IMPORTED_REVENUE)||', '||g_CRLF
         ||'REVENUE_EXCL_VAT          = '||TO_CHAR(p_REC.REVENUE_EXCL_VAT)||', '||g_CRLF
         ||'REVENUE_INC_VAT           = '||TO_CHAR(p_REC.REVENUE_INC_VAT)||', '||g_CRLF
         ||'IMPORT_TIMESTAMP          = '||TO_CHAR(p_REC.IMPORT_TIMESTAMP,g_DBG_DATETIME_FORMAT)||g_CRLF
         ||'FILE_NAME                 = '||p_REC.FILE_NAME||', '||g_CRLF
         ||'PROCESS_ID                = '||TO_CHAR(p_REC.PROCESS_ID)||'.'||g_CRLF);
END TO_CHAR_TDIE_DUOS_NI_INV;


--------------------------------------------------------------------------------
-- This is a private function to format the given table record into a string.
FUNCTION TO_CHAR_TDIE_DUOS_NI_INV_DTL(
   p_REC     IN TDIE_DUOS_NI_INVOICE_DETAIL%ROWTYPE
   ) RETURN VARCHAR2 IS
BEGIN
   RETURN ('INVOICE_NUMBER           = '||p_REC.INVOICE_NUMBER||', '||g_CRLF
         ||'ITEM_NUMBER              = '||TO_CHAR(p_REC.ITEM_NUMBER)||', '||g_CRLF
         ||'POD_ID                   = '||p_REC.POD_ID ||', '||g_CRLF
         ||'ADJUST_REF               = '||TO_CHAR(p_REC.ADJUST_REF)||', '||g_CRLF
         ||'INVOICE_TYPE             = '||p_REC.INVOICE_TYPE||', '||g_CRLF
         ||'DUOS_GROUP               = '||p_REC.DUOS_GROUP||', '||g_CRLF
         ||'BILLING_BEGIN_DATE       = '||TO_CHAR(p_REC.BILLING_BEGIN_DATE,g_DBG_DATETIME_FORMAT)||g_CRLF
         ||'BILLING_END_DATE         = '||TO_CHAR(p_REC.BILLING_END_DATE,g_DBG_DATETIME_FORMAT)||g_CRLF
         ||'RATE_CATEGORY            = '||p_REC.RATE_CATEGORY||', '||g_CRLF
         ||'STAND_CHARGE             = '||TO_CHAR(p_REC.STAND_CHARGE)||', '||g_CRLF
         ||'UNR_VOLUME               = '||TO_CHAR(p_REC.UNR_VOLUME)||', '||g_CRLF
         ||'UNR_CHARGE               = '||TO_CHAR(p_REC.UNR_CHARGE)||', '||g_CRLF
         ||'D01_VOLUME               = '||TO_CHAR(p_REC.D01_VOLUME)||', '||g_CRLF
         ||'D01_CHARGE               = '||TO_CHAR(p_REC.D01_CHARGE)||', '||g_CRLF
         ||'N01_VOLUME               = '||TO_CHAR(p_REC.N01_VOLUME)||', '||g_CRLF
         ||'N01_CHARGE               = '||TO_CHAR(p_REC.N01_CHARGE)||', '||g_CRLF
         ||'D02_VOLUME               = '||TO_CHAR(p_REC.D02_VOLUME)||', '||g_CRLF
         ||'D02_CHARGE               = '||TO_CHAR(p_REC.D02_CHARGE)||', '||g_CRLF
         ||'N02_VOLUME               = '||TO_CHAR(p_REC.N02_VOLUME)||', '||g_CRLF
         ||'N02_CHARGE               = '||TO_CHAR(p_REC.N02_CHARGE)||', '||g_CRLF
         ||'N03_VOLUME               = '||TO_CHAR(p_REC.N03_VOLUME)||', '||g_CRLF
         ||'N03_CHARGE               = '||TO_CHAR(p_REC.N03_CHARGE)||', '||g_CRLF
         ||'N04_VOLUME               = '||TO_CHAR(p_REC.N04_VOLUME)||', '||g_CRLF
         ||'N04_CHARGE               = '||TO_CHAR(p_REC.N04_CHARGE)||', '||g_CRLF
         ||'HT1_VOLUME               = '||TO_CHAR(p_REC.HT1_VOLUME)||', '||g_CRLF
         ||'HT1_CHARGE               = '||TO_CHAR(p_REC.HT1_CHARGE)||', '||g_CRLF
         ||'HT2_VOLUME               = '||TO_CHAR(p_REC.HT2_VOLUME)||', '||g_CRLF
         ||'HT2_CHARGE               = '||TO_CHAR(p_REC.HT2_CHARGE)||', '||g_CRLF
         ||'HT3_VOLUME               = '||TO_CHAR(p_REC.HT3_VOLUME)||', '||g_CRLF
         ||'HT3_CHARGE               = '||TO_CHAR(p_REC.HT3_CHARGE)||', '||g_CRLF
         ||'W1_VOLUME                = '||TO_CHAR(p_REC.W1_VOLUME)||', '||g_CRLF
         ||'W1_CHARGE                = '||TO_CHAR(p_REC.W1_CHARGE)||', '||g_CRLF
         ||'W2_VOLUME                = '||TO_CHAR(p_REC.W2_VOLUME)||', '||g_CRLF
         ||'W2_CHARGE                = '||TO_CHAR(p_REC.W2_CHARGE)||', '||g_CRLF
         ||'FR1_VOLUME               = '||TO_CHAR(p_REC.FR1_VOLUME)||', '||g_CRLF
         ||'FR1_CHARGE               = '||TO_CHAR(p_REC.FR1_CHARGE)||', '||g_CRLF
         ||'FR2_VOLUME               = '||TO_CHAR(p_REC.FR2_VOLUME)||', '||g_CRLF
         ||'FR2_CHARGE               = '||TO_CHAR(p_REC.FR2_CHARGE)||', '||g_CRLF
         ||'FR3_VOLUME               = '||TO_CHAR(p_REC.FR3_VOLUME)||', '||g_CRLF
         ||'FR3_CHARGE               = '||TO_CHAR(p_REC.FR3_CHARGE)||', '||g_CRLF
         ||'FR4_VOLUME               = '||TO_CHAR(p_REC.FR4_VOLUME)||', '||g_CRLF
         ||'FR4_CHARGE               = '||TO_CHAR(p_REC.FR4_CHARGE)||', '||g_CRLF
         ||'KP5_VOLUME               = '||TO_CHAR(p_REC.KP5_VOLUME)||', '||g_CRLF
         ||'KP5_CHARGE               = '||TO_CHAR(p_REC.KP5_CHARGE)||', '||g_CRLF
         ||'KP6_VOLUME               = '||TO_CHAR(p_REC.KP6_VOLUME)||', '||g_CRLF
         ||'KP6_CHARGE               = '||TO_CHAR(p_REC.KP6_CHARGE)||', '||g_CRLF
         ||'KP7_VOLUME               = '||TO_CHAR(p_REC.KP7_VOLUME)||', '||g_CRLF
         ||'KP7_CHARGE               = '||TO_CHAR(p_REC.KP7_CHARGE)||', '||g_CRLF
         ||'KP8_VOLUME               = '||TO_CHAR(p_REC.KP8_VOLUME)||', '||g_CRLF
         ||'KP8_CHARGE               = '||TO_CHAR(p_REC.KP8_CHARGE)||', '||g_CRLF
         ||'R21_VOLUME               = '||TO_CHAR(p_REC.R21_VOLUME)||', '||g_CRLF
         ||'R21_CHARGE               = '||TO_CHAR(p_REC.R21_CHARGE)||', '||g_CRLF
         ||'R22_VOLUME               = '||TO_CHAR(p_REC.R22_VOLUME)||', '||g_CRLF
         ||'R22_CHARGE               = '||TO_CHAR(p_REC.R22_CHARGE)||', '||g_CRLF
         ||'R23_VOLUME               = '||TO_CHAR(p_REC.R23_VOLUME)||', '||g_CRLF
         ||'R23_CHARGE               = '||TO_CHAR(p_REC.R23_CHARGE)||', '||g_CRLF
         ||'R24_VOLUME               = '||TO_CHAR(p_REC.R24_VOLUME)||', '||g_CRLF
         ||'R24_CHARGE               = '||TO_CHAR(p_REC.R24_CHARGE)||', '||g_CRLF
         ||'R25_VOLUME               = '||TO_CHAR(p_REC.R25_VOLUME)||', '||g_CRLF
         ||'R25_CHARGE               = '||TO_CHAR(p_REC.R25_CHARGE)||', '||g_CRLF
         ||'UNMTRD_VOLUME            = '||TO_CHAR(p_REC.UNMTRD_VOLUME)||', '||g_CRLF
         ||'UNMTRD_CHARGE            = '||TO_CHAR(p_REC.UNMTRD_CHARGE)||', '||g_CRLF
         ||'SMO_VOLUME               = '||TO_CHAR(p_REC.SMO_VOLUME)||', '||g_CRLF
         ||'SMO_CHARGE               = '||TO_CHAR(p_REC.SMO_CHARGE)||', '||g_CRLF
         ||'NFD_VOLUME               = '||TO_CHAR(p_REC.NFD_VOLUME)||', '||g_CRLF
         ||'NFD_CHARGE               = '||TO_CHAR(p_REC.NFD_CHARGE)||', '||g_CRLF
         ||'DJD_VOLUME               = '||TO_CHAR(p_REC.DJD_VOLUME)||', '||g_CRLF
         ||'DJD_CHARGE               = '||TO_CHAR(p_REC.DJD_CHARGE)||', '||g_CRLF
         ||'NKP_VOLUME               = '||TO_CHAR(p_REC.NKP_VOLUME)||', '||g_CRLF
         ||'NKP_CHARGE               = '||TO_CHAR(p_REC.NKP_CHARGE)||', '||g_CRLF
         ||'DJPK_VOLUME              = '||TO_CHAR(p_REC.DJPK_VOLUME)||', '||g_CRLF
         ||'DJPK_CHARGE              = '||TO_CHAR(p_REC.DJPK_CHARGE)||', '||g_CRLF
         ||'EW_VOLUME                = '||TO_CHAR(p_REC.EW_VOLUME)||', '||g_CRLF
         ||'EW_CHARGE                = '||TO_CHAR(p_REC.EW_CHARGE)||', '||g_CRLF
         ||'NT_VOLUME                = '||TO_CHAR(p_REC.NT_VOLUME)||', '||g_CRLF
         ||'NT_CHARGE                = '||TO_CHAR(p_REC.NT_CHARGE)||', '||g_CRLF
         ||'RPC_VOLUME               = '||TO_CHAR(p_REC.RPC_VOLUME)||', '||g_CRLF
         ||'RPC_CHARGE               = '||TO_CHAR(p_REC.RPC_CHARGE)||', '||g_CRLF
         ||'CSC_VOLUME               = '||TO_CHAR(p_REC.CSC_VOLUME)||', '||g_CRLF
         ||'CSC_CHARGE               = '||TO_CHAR(p_REC.CSC_CHARGE)||', '||g_CRLF
         ||'MIC_VOLUME               = '||TO_CHAR(p_REC.MIC_VOLUME)||', '||g_CRLF
         ||'MIC_CHARGE               = '||TO_CHAR(p_REC.MIC_CHARGE)||', '||g_CRLF
         ||'R26_VOLUME               = '||TO_CHAR(p_REC.R26_VOLUME)||', '||g_CRLF
         ||'R26_CHARGE               = '||TO_CHAR(p_REC.R26_CHARGE)||', '||g_CRLF
         ||'TOTAL_REVENUE            = '||TO_CHAR(p_REC.TOTAL_REVENUE)||', '||g_CRLF
         ||'REVENUE_INC_VAT          = '||TO_CHAR(p_REC.REVENUE_INC_VAT)||'.'||g_CRLF);

END TO_CHAR_TDIE_DUOS_NI_INV_DTL;


--------------------------------------------------------------------------------
-- This is a private function to format the given table record into a string.
FUNCTION TO_CHAR_TDIE_TUOS_INV(
   p_REC     IN TDIE_TUOS_INVOICE%ROWTYPE
   ) RETURN VARCHAR2 IS
BEGIN
   RETURN ('INVOICE_NUMBER            = '||p_REC.INVOICE_NUMBER||', '||g_CRLF
         ||'INVOICE_NAME	           = '||p_REC.INVOICE_NAME||', '||g_CRLF
         ||'INVOICE_TYPE	           = '||p_REC.INVOICE_TYPE||', '||g_CRLF
         ||'INVOICE_START_DATE	     = '||TO_CHAR(p_REC.INVOICE_START_DATE,g_DBG_DATETIME_FORMAT)||g_CRLF
         ||'INVOICE_END_DATE	        = '||TO_CHAR(p_REC.INVOICE_END_DATE,g_DBG_DATETIME_FORMAT)||g_CRLF
         ||'INVOICE_STATUS	           = '||p_REC.INVOICE_STATUS||', '||g_CRLF
         ||'INVOICE_DATE	           = '||TO_CHAR(p_REC.INVOICE_DATE,g_DBG_DATETIME_FORMAT)||g_CRLF
         ||'INVOICE_DUE_DATE	        = '||TO_CHAR(p_REC.INVOICE_DUE_DATE,g_DBG_DATETIME_FORMAT)||g_CRLF
         ||'CUSTOMER_ID	              = '||p_REC.CUSTOMER_ID||', '||g_CRLF
         ||'CUSTOMER_CATEGORY	        = '||p_REC.CUSTOMER_CATEGORY||', '||g_CRLF
         ||'CUSTOMER_TYPE	           = '||p_REC.CUSTOMER_TYPE||', '||g_CRLF
         ||'CUSTOMER_CODE	           = '||p_REC.CUSTOMER_CODE||', '||g_CRLF
         ||'CUSTOMER_NAME	           = '||p_REC.CUSTOMER_NAME||', '||g_CRLF
         ||'MPRN_COUNT	              = '||TO_CHAR(p_REC.MPRN_COUNT)||', '||g_CRLF
         ||'RETAIL_INVOICE_ID	        = '||TO_CHAR(p_REC.RETAIL_INVOICE_ID)||', '||g_CRLF
         ||'NET_CHARGE_AMT_IMPORTED	  = '||TO_CHAR(p_REC.NET_CHARGE_AMT_IMPORTED)||', '||g_CRLF
         ||'GROSS_CHARGE_AMT_IMPORTED = '||TO_CHAR(p_REC.GROSS_CHARGE_AMT_IMPORTED)||', '||g_CRLF
         ||'RECORDS_IMPORTED	        = '||TO_CHAR(p_REC.RECORDS_IMPORTED)||', '||g_CRLF
         ||'IMPORT_TIMESTAMP	        = '||TO_CHAR(p_REC.IMPORT_TIMESTAMP,g_DBG_DATETIME_FORMAT)||g_CRLF
         ||'FILE_NAME	              = '||p_REC.FILE_NAME||', '||g_CRLF
         ||'PROCESS_ID                = '||TO_CHAR(p_REC.PROCESS_ID)||'.'||g_CRLF);
END TO_CHAR_TDIE_TUOS_INV;


--------------------------------------------------------------------------------
-- This is a private function to format the given table record into a string.
FUNCTION TO_CHAR_TDIE_TUOS_INV_DTL(
   p_REC     IN TDIE_TUOS_INVOICE_DETAIL%ROWTYPE
   ) RETURN VARCHAR2 IS
BEGIN
   RETURN ('INVOICE_NUMBER   = '||p_REC.INVOICE_NUMBER||', '||g_CRLF
         ||'ACCOUNT_XID	     = '||TO_CHAR(p_REC.ACCOUNT_XID)||', '||g_CRLF
         ||'ACCOUNT_CATEGORY = '||p_REC.ACCOUNT_CATEGORY||', '||g_CRLF
         ||'ACCOUNT_TYPE	  = '||p_REC.ACCOUNT_TYPE||', '||g_CRLF
         ||'ACCOUNT_CODE	  = '||p_REC.ACCOUNT_CODE||', '||g_CRLF
         ||'ACCOUNT_NAME	  = '||p_REC.ACCOUNT_NAME||', '||g_CRLF
         ||'METER_XID	     = '||TO_CHAR(p_REC.METER_XID)||', '||g_CRLF
         ||'METER_CATEGORY  = '||p_REC.METER_CATEGORY||', '||g_CRLF
         ||'METER_TYPE	     = '||p_REC.METER_TYPE||', '||g_CRLF
         ||'METER_CODE	     = '||p_REC.METER_CODE||', '||g_CRLF
         ||'METER_NAME	     = '||p_REC.METER_NAME||', '||g_CRLF
         ||'BILL_NAME	     = '||p_REC.BILL_NAME||', '||g_CRLF
         ||'BILL_CONTACT	  = '||p_REC.BILL_CONTACT||', '||g_CRLF
         ||'BILL_ADDRESS1	  = '||p_REC.BILL_ADDRESS1||', '||g_CRLF
         ||'BILL_ADDRESS2	  = '||p_REC.BILL_ADDRESS2||', '||g_CRLF
         ||'BILL_CITY	     = '||p_REC.BILL_CITY||', '||g_CRLF
         ||'BILL_REGION	     = '||p_REC.BILL_REGION||', '||g_CRLF
         ||'BILL_COUNTRY	  = '||p_REC.BILL_COUNTRY||', '||g_CRLF
         ||'BILL_POSTAL_CODE = '||p_REC.BILL_POSTAL_CODE||', '||g_CRLF
         ||'MPRN	           = '||TO_CHAR(p_REC.MPRN)||', '||g_CRLF
         ||'SUPPLY_UNIT     = '||TO_CHAR(p_REC.SUPPLY_UNIT)||'.'||g_CRLF);
END TO_CHAR_TDIE_TUOS_INV_DTL;


--------------------------------------------------------------------------------
-- This is a private function to format the given table record into a string.
FUNCTION TO_CHAR_TDIE_TUOS_INV_CHG_DTL(
   p_REC     IN TDIE_TUOS_INV_CHARGE_DTL%ROWTYPE
   ) RETURN VARCHAR2 IS
BEGIN
   RETURN ('INVOICE_NUMBER               = '||p_REC.INVOICE_NUMBER||', '||g_CRLF
         ||'ACCOUNT_XID	                 = '||TO_CHAR(p_REC.ACCOUNT_XID)||', '||g_CRLF
         ||'METER_NAME	                 = '||p_REC.METER_NAME||', '||g_CRLF
         ||'INVOICE_CATEGORY	        = '||p_REC.INVOICE_CATEGORY||', '||g_CRLF
         ||'INV_DET_START_DATE	        = '||TO_CHAR(p_REC.INV_DET_START_DATE,g_DBG_DATETIME_FORMAT)||g_CRLF
         ||'INV_DET_END_DATE             = '||TO_CHAR(p_REC.INV_DET_END_DATE,g_DBG_DATETIME_FORMAT)||g_CRLF
         ||'INV_DET_CATEGORY  	        = '||p_REC.INV_DET_CATEGORY||', '||g_CRLF
         ||'INV_DET_TYPE	              = '||p_REC.INV_DET_TYPE||', '||g_CRLF
         ||'INV_DET_CODE	              = '||p_REC.INV_DET_CODE||', '||g_CRLF
         ||'INV_DET_CATEGORY2 	        = '||p_REC.INV_DET_CATEGORY2||', '||g_CRLF
         ||'INV_DET_SEQ	                 = '||TO_CHAR(p_REC.INV_DET_SEQ)||', '||g_CRLF
         ||'INV_DET_NAME	              = '||p_REC.INV_DET_NAME||', '||g_CRLF
         ||'INV_DET_VALUE	              = '||TO_CHAR(p_REC.INV_DET_VALUE)||', '||g_CRLF
         ||'INV_DET_UOM	                 = '||p_REC.INV_DET_UOM||', '||g_CRLF
         ||'MULTI_CIP_FLAG	              = '||p_REC.MULTI_CIP_FLAG||', '||g_CRLF
         ||'VAT_CHARGE	                 = '||TO_CHAR(p_REC.VAT_CHARGE)||', '||g_CRLF
         ||'INV_DET_VALUE_CHARGE	        = '||TO_CHAR(p_REC.INV_DET_VALUE_CHARGE)||', '||g_CRLF
         ||'INV_DET_VALUE_CHARGE_NO_VAT  = '||TO_CHAR(p_REC.INV_DET_VALUE_CHARGE_NO_VAT)||', '||g_CRLF
         ||'INV_DET_TYPE_SORT	           = '||p_REC.INV_DET_TYPE_SORT||', '||g_CRLF
         ||'EIR_RPT_INV_DET_ID	        = '||TO_CHAR(p_REC.EIR_RPT_INV_DET_ID)||', '||g_CRLF
         ||'BILL_DATE	                 = '||TO_CHAR(p_REC.BILL_DATE,g_DBG_DATETIME_FORMAT)||g_CRLF
         ||'CIP_DATE	                    = '||p_REC.CIP_DATE||g_CRLF
         ||'INV_STATUS_DRAFT	           = '||p_REC.INV_STATUS_DRAFT||', '||g_CRLF
         ||'INV_NUMBER_RELEASED	        = '||p_REC.INV_NUMBER_RELEASED||', '||g_CRLF
         ||'INV_DATE_RELEASED	           = '||TO_CHAR(p_REC.INV_DATE_RELEASED,g_DBG_DATETIME_FORMAT)||g_CRLF
         ||'INV_DET_NOTES	              = '||p_REC.INV_DET_NOTES||', '||g_CRLF
         ||'INV_DET_NOTE_SORT	           = '||p_REC.INV_DET_NOTE_SORT||'.'||g_CRLF);
END TO_CHAR_TDIE_TUOS_INV_CHG_DTL;


--------------------------------------------------------------------------------
-- This is a private function to format the given table record into a string.
FUNCTION TO_CHAR_TDIE_UOS_INV(
   p_REC     IN TDIE_UOS_INVOICE%ROWTYPE
   ) RETURN VARCHAR2 IS
BEGIN
   RETURN ('INVOICE_NUMBER               = '||p_REC.INVOICE_NUMBER||', '||g_CRLF
         ||'SENDER_CID	                 = '||p_REC.SENDER_CID||', '||g_CRLF
         ||'RECIPIENT_CID	              = '||p_REC.RECIPIENT_CID||', '||g_CRLF
         ||'MARKET_TIMESTAMP	           = '||TEXT_UTIL.TO_CHAR_TIME(p_REC.MARKET_TIMESTAMP)||g_CRLF
         ||'DUE_DATE	                    = '||TEXT_UTIL.TO_CHAR_DATE(p_REC.DUE_DATE)||g_CRLF
         ||'TOTAL_CONSUMPTION	           = '||TO_CHAR(p_REC.TOTAL_CONSUMPTION)||', '||g_CRLF
         ||'TOTAL_CSC	                 = '||TO_CHAR(p_REC.TOTAL_CSC)||', '||g_CRLF
         ||'TOTAL_REACTIVE	              = '||TO_CHAR(p_REC.TOTAL_REACTIVE)||', '||g_CRLF
         ||'TOTAL_STANDING_CHARGE	     = '||TO_CHAR(p_REC.TOTAL_STANDING_CHARGE)||', '||g_CRLF
         ||'TOTAL_TRANSMISSION_REBATE	  = '||TO_CHAR(p_REC.TOTAL_TRANSMISSION_REBATE)||', '||g_CRLF
         ||'TOTAL_AD_HOC	              = '||TO_CHAR(p_REC.TOTAL_AD_HOC)||', '||g_CRLF
         ||'TOTAL_CONSUMPTION_ADJUSTMENT = '||TO_CHAR(p_REC.TOTAL_CONSUMPTION_ADJUSTMENT)||', '||g_CRLF
         ||'TOTAL_VAT	                 = '||TO_CHAR(p_REC.TOTAL_VAT)||', '||g_CRLF
         ||'TOTAL_CANCELED	              = '||TO_CHAR(p_REC.TOTAL_CANCELED)||', '||g_CRLF
         ||'TOTAL_CONSUMPTION_KWH	     = '||TO_CHAR(p_REC.TOTAL_CONSUMPTION_KWH)||', '||g_CRLF
         ||'TOTAL_DETAIL_LINES	        = '||TO_CHAR(p_REC.TOTAL_DETAIL_LINES)||', '||g_CRLF
         ||'MPRN_COUNT	                 = '||TO_CHAR(p_REC.MPRN_COUNT)||', '||g_CRLF
         ||'RETAIL_INVOICE_ID	           = '||TO_CHAR(p_REC.RETAIL_INVOICE_ID)||', '||g_CRLF
         ||'NET_CHARGE_AMT_IMPORTED	     = '||TO_CHAR(p_REC.NET_CHARGE_AMT_IMPORTED)||', '||g_CRLF
         ||'GROSS_CHARGE_AMT_IMPORTED    = '||TO_CHAR(p_REC.GROSS_CHARGE_AMT_IMPORTED)||', '||g_CRLF
         ||'RECORDS_IMPORTED	           = '||TO_CHAR(p_REC.RECORDS_IMPORTED)||', '||g_CRLF
         ||'IMPORT_TIMESTAMP	           = '||TEXT_UTIL.TO_CHAR_TIME(p_REC.IMPORT_TIMESTAMP)||g_CRLF
         ||'FILE_NAME	                 = '||p_REC.FILE_NAME||', '||g_CRLF
         ||'PROCESS_ID                   = '||TO_CHAR(p_REC.PROCESS_ID)||'.'||g_CRLF);
END TO_CHAR_TDIE_UOS_INV;


--------------------------------------------------------------------------------
-- This is a private function to format the given table record into a string.
FUNCTION TO_CHAR_TDIE_UOS_INV_DTL(
   p_REC     IN TDIE_UOS_INVOICE_DETAIL%ROWTYPE
   ) RETURN VARCHAR2 IS
BEGIN
   RETURN ('INVOICE_NUMBER         = '||p_REC.INVOICE_NUMBER||', '||g_CRLF
         ||'RECORD_TYPE	           = '||p_REC.RECORD_TYPE||', '||g_CRLF
         ||'MPRN	                 = '||p_REC.MPRN||', '||g_CRLF
         ||'METER_ID_SERIAL_NUMBER = '||p_REC.METER_ID_SERIAL_NUMBER||', '||g_CRLF
         ||'START_DATE	           = '||TEXT_UTIL.TO_CHAR_DATE(p_REC.START_DATE)||g_CRLF
         ||'END_DATE	              = '||TEXT_UTIL.TO_CHAR_DATE(p_REC.END_DATE)||g_CRLF
         ||'UNIT_OF_MEASURE	     = '||p_REC.UNIT_OF_MEASURE||', '||g_CRLF
         ||'TIMESLOT	              = '||p_REC.TIMESLOT_CODE||', '||g_CRLF
         ||'START_READ	           = '||TO_CHAR(p_REC.START_READ)||', '||g_CRLF
         ||'START_READ_TYPE	     = '||p_REC.START_READ_TYPE||', '||g_CRLF
         ||'END_READ	              = '||TO_CHAR(p_REC.END_READ)||', '||g_CRLF
         ||'END_READ_TYPE	        = '||p_REC.END_READ_TYPE||', '||g_CRLF
         ||'TOTAL_UNITS	           = '||TO_CHAR(p_REC.TOTAL_UNITS)||', '||g_CRLF
         ||'ESTIMATED_UNITS	     = '||TO_CHAR(p_REC.ESTIMATED_UNITS)||', '||g_CRLF
         ||'UOS_TARIFF	           = '||p_REC.UOS_TARIFF||', '||g_CRLF
         ||'RATE	                 = '||TO_CHAR(p_REC.RATE)||', '||g_CRLF
         ||'CHARGE	              = '||TO_CHAR(p_REC.CHARGE)||', '||g_CRLF
         ||'LAST_ACTUAL_READ_VALUE = '||TO_CHAR(p_REC.LAST_ACTUAL_READ_VALUE)||', '||g_CRLF
         ||'LAST_ACTUAL_READ_DATE  = '||TEXT_UTIL.TO_CHAR_DATE(p_REC.LAST_ACTUAL_READ_DATE)||'.'||g_CRLF);
END TO_CHAR_TDIE_UOS_INV_DTL;


--------------------------------------------------------------------------------
-- This procedure will update a record from the TDIE_DUOS_INVOICE table.
PROCEDURE UPD_TDIE_DUOS_INVOICE (p_REC IN TDIE_DUOS_INVOICE%ROWTYPE)
IS
   c_PROCEDURE_NAME CONSTANT VARCHAR(30) := 'UPD_TDIE_DUOS_INVOICE';
BEGIN
   ASSERT(p_REC.INVOICE_NUMBER IS NOT NULL,
          'The TDIE_DUOS_INVOICE record must not be null.',
          MSGCODES.c_ERR_ARGUMENT);

   IF LOGS.IS_DEBUG_ENABLED THEN
      LOGS.LOG_DEBUG(g_PACKAGE_NAME||'.'||c_PROCEDURE_NAME);
		LOGS.LOG_DEBUG('p_REC = '||TO_CHAR_TDIE_DUOS_INV(p_REC));
   END IF;

   UPDATE TDIE_DUOS_INVOICE TDI
      SET TDI.SENDER_CID                = p_REC.SENDER_CID,
          TDI.RECIPIENT_CID             = p_REC.RECIPIENT_CID,
          TDI.MARKET_TIMESTAMP          = p_REC.MARKET_TIMESTAMP,
          TDI.CONTROL_TOTAL             = p_REC.CONTROL_TOTAL,
          TDI.TOTAL_RECORDS             = p_REC.TOTAL_RECORDS,
          TDI.NET_CHARGE_AMT_IMPORTED   = p_REC.NET_CHARGE_AMT_IMPORTED,
          TDI.GROSS_CHARGE_AMT_IMPORTED = p_REC.GROSS_CHARGE_AMT_IMPORTED,
          TDI.MPRN_COUNT                = p_REC.MPRN_COUNT,
          TDI.RECORDS_IMPORTED          = p_REC.RECORDS_IMPORTED,
          TDI.IMPORT_TIMESTAMP          = p_REC.IMPORT_TIMESTAMP,
          TDI.FILE_NAME                 = p_REC.FILE_NAME,
          TDI.PROCESS_ID                = p_REC.PROCESS_ID,
          TDI.RETAIL_INVOICE_ID         = p_REC.RETAIL_INVOICE_ID
    WHERE TDI.INVOICE_NUMBER = p_REC.INVOICE_NUMBER;

END UPD_TDIE_DUOS_INVOICE;

--------------------------------------------------------------------------------
-- This procedure will update a record from the TDIE_DUOS_NI_INVOICE table.
PROCEDURE UPD_TDIE_DUOS_NI_INVOICE (p_REC IN TDIE_DUOS_NI_INVOICE%ROWTYPE)
IS
   c_PROCEDURE_NAME CONSTANT VARCHAR(30) := 'UPD_TDIE_DUOS_NI_INVOICE';
BEGIN
   ASSERT(p_REC.INVOICE_NUMBER IS NOT NULL,
          'The TDIE_DUOS_NI_INVOICE record must not be null.',
          MSGCODES.c_ERR_ARGUMENT);

   IF LOGS.IS_DEBUG_ENABLED THEN
      LOGS.LOG_DEBUG(g_PACKAGE_NAME||'.'||c_PROCEDURE_NAME);
		LOGS.LOG_DEBUG('p_REC = '||TO_CHAR_TDIE_DUOS_NI_INV(p_REC));
   END IF;

   UPDATE TDIE_DUOS_NI_INVOICE TDI
      SET TDI.PROVIDER                  = p_REC.PROVIDER,
          TDI.SUPPLIER                  = p_REC.SUPPLIER,
          TDI.MARKET_TIMESTAMP          = p_REC.MARKET_TIMESTAMP,
          TDI.TOTAL_ITEMISED_LINES      = p_REC.TOTAL_ITEMISED_LINES,
          TDI.RECORDS_IMPORTED          = p_REC.RECORDS_IMPORTED,
          TDI.MPRN_COUNT                = p_REC.MPRN_COUNT,
          TDI.IMPORTED_REVENUE          = p_REC.IMPORTED_REVENUE,
          TDI.REVENUE_EXCL_VAT          = p_REC.REVENUE_EXCL_VAT,
          TDI.REVENUE_INC_VAT           = p_REC.REVENUE_INC_VAT,
          TDI.IMPORT_TIMESTAMP          = p_REC.IMPORT_TIMESTAMP,
          TDI.FILE_NAME                 = p_REC.FILE_NAME,
          TDI.PROCESS_ID                = p_REC.PROCESS_ID,
          TDI.RETAIL_INVOICE_ID         = p_REC.RETAIL_INVOICE_ID
    WHERE TDI.INVOICE_NUMBER = p_REC.INVOICE_NUMBER;

END UPD_TDIE_DUOS_NI_INVOICE;


--------------------------------------------------------------------------------
-- This procedure will update a record from the TDIE_TUOS_INVOICE table.
PROCEDURE UPD_TDIE_TUOS_INVOICE (p_REC IN TDIE_TUOS_INVOICE%ROWTYPE)
IS
   c_PROCEDURE_NAME CONSTANT VARCHAR(30) := 'UPD_TDIE_TUOS_INVOICE';
BEGIN
   ASSERT(p_REC.INVOICE_NUMBER IS NOT NULL,
          'The TDIE_UOS_INVOICE record must not be null.',
          MSGCODES.c_ERR_ARGUMENT);

   IF LOGS.IS_DEBUG_ENABLED THEN
      LOGS.LOG_DEBUG(g_PACKAGE_NAME||'.'||c_PROCEDURE_NAME);
		LOGS.LOG_DEBUG('p_REC = '||TO_CHAR_TDIE_TUOS_INV(p_REC));
   END IF;

   UPDATE TDIE_TUOS_INVOICE TTI
      SET TTI.INVOICE_NAME              = p_REC.INVOICE_NAME,
          TTI.INVOICE_TYPE              = p_REC.INVOICE_TYPE,
          TTI.INVOICE_START_DATE        = p_REC.INVOICE_START_DATE,
          TTI.INVOICE_END_DATE          = p_REC.INVOICE_END_DATE,
          TTI.INVOICE_STATUS            = p_REC.INVOICE_STATUS,
          TTI.INVOICE_DATE              = p_REC.INVOICE_DATE,
          TTI.INVOICE_DUE_DATE          = p_REC.INVOICE_DUE_DATE,
          TTI.CUSTOMER_ID               = p_REC.CUSTOMER_ID,
          TTI.CUSTOMER_CATEGORY         = p_REC.CUSTOMER_CATEGORY,
          TTI.CUSTOMER_TYPE             = p_REC.CUSTOMER_TYPE,
          TTI.CUSTOMER_CODE             = p_REC.CUSTOMER_CODE,
          TTI.CUSTOMER_NAME             = p_REC.CUSTOMER_NAME,
          TTI.NET_CHARGE_AMT_IMPORTED   = p_REC.NET_CHARGE_AMT_IMPORTED,
          TTI.GROSS_CHARGE_AMT_IMPORTED = p_REC.GROSS_CHARGE_AMT_IMPORTED,
          TTI.MPRN_COUNT                = p_REC.MPRN_COUNT,
          TTI.SUPPLY_UNIT_COUNT         = p_REC.SUPPLY_UNIT_COUNT,
          TTI.RECORDS_IMPORTED          = p_REC.RECORDS_IMPORTED,
          TTI.IMPORT_TIMESTAMP          = p_REC.IMPORT_TIMESTAMP,
          TTI.FILE_NAME                 = p_REC.FILE_NAME,
          TTI.PROCESS_ID                = p_REC.PROCESS_ID,
          TTI.RETAIL_INVOICE_ID         = p_REC.RETAIL_INVOICE_ID
    WHERE TTI.INVOICE_NUMBER = p_REC.INVOICE_NUMBER;

END UPD_TDIE_TUOS_INVOICE;


--------------------------------------------------------------------------------
-- This procedure will update a record from the TDIE_UOS_INVOICE table.
PROCEDURE UPD_TDIE_UOS_INVOICE (p_REC IN TDIE_UOS_INVOICE%ROWTYPE)
IS
   c_PROCEDURE_NAME CONSTANT VARCHAR(30) := 'UPD_TDIE_UOS_INVOICE';
BEGIN
   ASSERT(p_REC.INVOICE_NUMBER IS NOT NULL,
          'The TDIE_UOS_INVOICE record must not be null.',
          MSGCODES.c_ERR_ARGUMENT);

   IF LOGS.IS_DEBUG_ENABLED THEN
      LOGS.LOG_DEBUG(g_PACKAGE_NAME||'.'||c_PROCEDURE_NAME);
		LOGS.LOG_DEBUG('p_REC = '||TO_CHAR_TDIE_UOS_INV(p_REC));
   END IF;

   UPDATE TDIE_UOS_INVOICE TUI
      SET TUI.SENDER_CID                   = p_REC.SENDER_CID,
          TUI.RECIPIENT_CID                = p_REC.RECIPIENT_CID,
          TUI.MARKET_TIMESTAMP             = p_REC.MARKET_TIMESTAMP,
          TUI.DUE_DATE                     = p_REC.DUE_DATE,
          TUI.TOTAL_CONSUMPTION            = p_REC.TOTAL_CONSUMPTION,
          TUI.TOTAL_CSC                    = p_REC.TOTAL_CSC,
          TUI.TOTAL_REACTIVE               = p_REC.TOTAL_REACTIVE,
          TUI.TOTAL_STANDING_CHARGE        = p_REC.TOTAL_STANDING_CHARGE,
          TUI.TOTAL_TRANSMISSION_REBATE    = p_REC.TOTAL_TRANSMISSION_REBATE,
          TUI.TOTAL_AD_HOC                 = p_REC.TOTAL_AD_HOC,
          TUI.TOTAL_CONSUMPTION_ADJUSTMENT = p_REC.TOTAL_CONSUMPTION_ADJUSTMENT,
          TUI.TOTAL_VAT                    = p_REC.TOTAL_VAT,
          TUI.TOTAL_CANCELED               = p_REC.TOTAL_CANCELED,
          TUI.TOTAL_CONSUMPTION_KWH        = p_REC.TOTAL_CONSUMPTION_KWH,
          TUI.TOTAL_DETAIL_LINES           = p_REC.TOTAL_DETAIL_LINES,
          TUI.NET_CHARGE_AMT_IMPORTED      = p_REC.NET_CHARGE_AMT_IMPORTED,
          TUI.GROSS_CHARGE_AMT_IMPORTED    = p_REC.GROSS_CHARGE_AMT_IMPORTED,
          TUI.MPRN_COUNT                   = p_REC.MPRN_COUNT,
          TUI.RECORDS_IMPORTED             = p_REC.RECORDS_IMPORTED,
          TUI.IMPORT_TIMESTAMP             = p_REC.IMPORT_TIMESTAMP,
          TUI.FILE_NAME                    = p_REC.FILE_NAME,
          TUI.PROCESS_ID                   = p_REC.PROCESS_ID,
          TUI.RETAIL_INVOICE_ID            = p_REC.RETAIL_INVOICE_ID
    WHERE TUI.INVOICE_NUMBER = p_REC.INVOICE_NUMBER;

END UPD_TDIE_UOS_INVOICE;


--------------------------------------------------------------------------------
-- This procedure will delete a record from the TDIE_DUOS_INVOICE table and cascade
-- delete the associated child records from the TDIE_DUOS_INVOICE_DETAIL table.
PROCEDURE DEL_TDIE_DUOS_INVOICE (p_REC IN TDIE_DUOS_INVOICE%ROWTYPE)
IS
   c_PROCEDURE_NAME CONSTANT VARCHAR(30) := 'DEL_TDIE_DUOS_INVOICE';
BEGIN
   ASSERT(p_REC.INVOICE_NUMBER IS NOT NULL, 'The TDIE_DUOS_INVOICE record must not be null.', MSGCODES.c_ERR_ARGUMENT);

   IF LOGS.IS_DEBUG_ENABLED THEN
      LOGS.LOG_DEBUG(g_PACKAGE_NAME||'.'||c_PROCEDURE_NAME);
		LOGS.LOG_DEBUG('p_REC = '||TO_CHAR_TDIE_DUOS_INV(p_REC));
   END IF;

   DELETE FROM TDIE_DUOS_INVOICE TDI
    WHERE TDI.INVOICE_NUMBER = p_REC.INVOICE_NUMBER;

END DEL_TDIE_DUOS_INVOICE;

--------------------------------------------------------------------------------
-- This procedure will delete a record from the TDIE_DUOS_NI_INVOICE table and cascade
-- delete the associated child records from the TDIE_DUOS_NI_INVOICE_DETAIL table.
PROCEDURE DEL_TDIE_DUOS_NI_INVOICE (p_REC IN TDIE_DUOS_INVOICE%ROWTYPE)
IS
   c_PROCEDURE_NAME CONSTANT VARCHAR(30) := 'DEL_TDIE_DUOS_NI_INVOICE';
BEGIN
   ASSERT(p_REC.INVOICE_NUMBER IS NOT NULL, 'The TDIE_DUOS_NI_INVOICE record must not be null.', MSGCODES.c_ERR_ARGUMENT);

   IF LOGS.IS_DEBUG_ENABLED THEN
      LOGS.LOG_DEBUG(g_PACKAGE_NAME||'.'||c_PROCEDURE_NAME);
		LOGS.LOG_DEBUG('p_REC = '||TO_CHAR_TDIE_DUOS_NI_INV(p_REC));
   END IF;

   DELETE FROM TDIE_DUOS_NI_INVOICE TDI
    WHERE TDI.INVOICE_NUMBER = p_REC.INVOICE_NUMBER;

END DEL_TDIE_DUOS_NI_INVOICE;

--------------------------------------------------------------------------------
-- This procedure will delete a record from the TDIE_TUOS_INVOICE table and cascade
-- delete the associated child records from the TDIE_TUOS_INVOICE_DETAIL and the
-- children of the child record from the TDIE_TUOS_INVOICE_CHARGE_DTL table.
PROCEDURE DEL_TDIE_TUOS_INVOICE (p_REC IN TDIE_TUOS_INVOICE%ROWTYPE)
IS
   c_PROCEDURE_NAME CONSTANT VARCHAR(30) := 'DEL_TDIE_TUOS_INVOICE';
BEGIN
   ASSERT(p_REC.INVOICE_NUMBER IS NOT NULL, 'The TDIE_TUOS_INVOICE record must not be null.', MSGCODES.c_ERR_ARGUMENT);

   IF LOGS.IS_DEBUG_ENABLED THEN
      LOGS.LOG_DEBUG(g_PACKAGE_NAME||'.'||c_PROCEDURE_NAME);
		LOGS.LOG_DEBUG('p_REC = '||TO_CHAR_TDIE_TUOS_INV(p_REC));
   END IF;

   DELETE FROM TDIE_TUOS_INVOICE TTI
    WHERE TTI.INVOICE_NUMBER = p_REC.INVOICE_NUMBER;

END DEL_TDIE_TUOS_INVOICE;


--------------------------------------------------------------------------------
-- This procedure will delete a record from the TDIE_UOS_INVOICE table and cascade
-- delete the associated child records from the TDIE_UOS_INVOICE_DETAIL table.
PROCEDURE DEL_TDIE_UOS_INVOICE (p_REC IN TDIE_UOS_INVOICE%ROWTYPE)
IS
   c_PROCEDURE_NAME CONSTANT VARCHAR(30) := 'DEL_TDIE_UOS_INVOICE';
BEGIN
   ASSERT(p_REC.INVOICE_NUMBER IS NOT NULL, 'The TDIE_UOS_INVOICE record must not be null.', MSGCODES.c_ERR_ARGUMENT);

   IF LOGS.IS_DEBUG_ENABLED THEN
      LOGS.LOG_DEBUG(g_PACKAGE_NAME||'.'||c_PROCEDURE_NAME);
		LOGS.LOG_DEBUG('p_REC = '||TO_CHAR_TDIE_UOS_INV(p_REC));
   END IF;

   DELETE FROM TDIE_UOS_INVOICE TUI
    WHERE TUI.INVOICE_NUMBER = p_REC.INVOICE_NUMBER;

END DEL_TDIE_UOS_INVOICE;


--------------------------------------------------------------------------------
-- This procedure inserts a record into the TDIE_DUOS_INVOICE table.
PROCEDURE INS_TDIE_DUOS_INVOICE (p_REC IN TDIE_DUOS_INVOICE%ROWTYPE)
IS
   c_PROCEDURE_NAME CONSTANT VARCHAR(30) := 'INS_TDIE_DUOS_INVOICE';
   v_MISSING_DATA            BOOLEAN := FALSE;
   v_INS_MSG_WARN            VARCHAR2(2000) := 'Missing required/invalid values for TDIE_DUOS_INVOICE: ';
BEGIN
   ASSERT(p_REC.INVOICE_NUMBER IS NOT NULL, 'The TDIE_DUOS_INVOICE record must not be null.', MSGCODES.c_ERR_ARGUMENT);

   IF LOGS.IS_DEBUG_ENABLED THEN
      LOGS.LOG_DEBUG(g_PACKAGE_NAME||'.'||c_PROCEDURE_NAME);
		LOGS.LOG_DEBUG('p_REC = '||TO_CHAR_TDIE_DUOS_INV(p_REC));
   END IF;

   IF p_REC.INVOICE_NUMBER IS NULL THEN
      v_MISSING_DATA := TRUE;
      v_INS_MSG_WARN := v_INS_MSG_WARN||g_CRLF||'* INVOICE_NUMBER,';
   END IF;

   IF p_REC.SENDER_CID IS NULL THEN
      v_MISSING_DATA := TRUE;
      v_INS_MSG_WARN := v_INS_MSG_WARN||g_CRLF||'* SENDER_CID,';
   END IF;

   IF p_REC.RECIPIENT_CID IS NULL THEN
      v_MISSING_DATA := TRUE;
      v_INS_MSG_WARN := v_INS_MSG_WARN||g_CRLF||'* RECIPIENT_CID,';
   END IF;

   IF p_REC.MARKET_TIMESTAMP IS NULL THEN
      v_MISSING_DATA := TRUE;
      v_INS_MSG_WARN := v_INS_MSG_WARN||g_CRLF||'* MARKET_TIMESTAMP,';
   END IF;

   IF p_REC.CONTROL_TOTAL IS NULL THEN
      v_MISSING_DATA := TRUE;
      v_INS_MSG_WARN := v_INS_MSG_WARN||g_CRLF||'* CONTROL_TOTAL,';
   END IF;

   IF p_REC.TOTAL_RECORDS IS NULL THEN
      v_MISSING_DATA := TRUE;
      v_INS_MSG_WARN := v_INS_MSG_WARN||g_CRLF||'* TOTAL_RECORDS,';
   END IF;

   IF p_REC.NET_CHARGE_AMT_IMPORTED IS NULL THEN
      v_MISSING_DATA := TRUE;
      v_INS_MSG_WARN := v_INS_MSG_WARN||g_CRLF||'* NET_CHARGE_AMT_IMPORTED,';
   END IF;

   IF p_REC.GROSS_CHARGE_AMT_IMPORTED IS NULL THEN
      v_MISSING_DATA := TRUE;
      v_INS_MSG_WARN := v_INS_MSG_WARN||g_CRLF||'* GROSS_CHARGE_AMT_IMPORTED,';
   END IF;

   IF p_REC.MPRN_COUNT IS NULL THEN
      v_MISSING_DATA := TRUE;
      v_INS_MSG_WARN := v_INS_MSG_WARN||g_CRLF||'* MPRN_COUNT,';
   END IF;

   IF p_REC.RECORDS_IMPORTED IS NULL THEN
      v_MISSING_DATA := TRUE;
      v_INS_MSG_WARN := v_INS_MSG_WARN||g_CRLF||'* RECORDS_IMPORTED,';
   END IF;

   IF p_REC.IMPORT_TIMESTAMP IS NULL THEN
      v_MISSING_DATA := TRUE;
      v_INS_MSG_WARN := v_INS_MSG_WARN||g_CRLF||'* IMPORT_TIMESTAMP,';
   END IF;

   IF p_REC.FILE_NAME IS NULL THEN
      v_MISSING_DATA := TRUE;
      v_INS_MSG_WARN := v_INS_MSG_WARN||g_CRLF||'* FILE_NAME,';
   END IF;

   IF v_MISSING_DATA THEN
      v_INS_MSG_WARN := SUBSTR(v_INS_MSG_WARN,1,LENGTH(v_INS_MSG_WARN)-1)||'.';
      ERRS.RAISE(p_MESSAGE_CODE => MSGCODES.c_ERR_INVALID_FILE_TYPE,
                 p_EXTRA_MESSAGE => v_INS_MSG_WARN);
   ELSE
      INSERT INTO TDIE_DUOS_INVOICE (INVOICE_NUMBER,
                                     SENDER_CID,
                                     RECIPIENT_CID,
                                     MARKET_TIMESTAMP,
                                     CONTROL_TOTAL,
                                     TOTAL_RECORDS,
                                     NET_CHARGE_AMT_IMPORTED,
                                     GROSS_CHARGE_AMT_IMPORTED,
                                     MPRN_COUNT,
                                     RECORDS_IMPORTED,
                                     IMPORT_TIMESTAMP,
                                     FILE_NAME,
                                     PROCESS_ID,
                                     RETAIL_INVOICE_ID)
         VALUES (p_REC.INVOICE_NUMBER,
                 p_REC.SENDER_CID,
                 p_REC.RECIPIENT_CID,
                 p_REC.MARKET_TIMESTAMP,
                 p_REC.CONTROL_TOTAL,
                 p_REC.TOTAL_RECORDS,
                 p_REC.NET_CHARGE_AMT_IMPORTED,
                 p_REC.GROSS_CHARGE_AMT_IMPORTED,
                 p_REC.MPRN_COUNT,
                 p_REC.RECORDS_IMPORTED,
                 p_REC.IMPORT_TIMESTAMP,
                 p_REC.FILE_NAME,
                 p_REC.PROCESS_ID,
                 p_REC.RETAIL_INVOICE_ID);
   END IF;--IF v_MISSING_DATA THEN

END INS_TDIE_DUOS_INVOICE;

--------------------------------------------------------------------------------
-- This procedure inserts a record into the TDIE_DUOS_INVOICE_DETAIL table.
PROCEDURE INS_TDIE_DUOS_INVOICE_DETAIL (p_REC IN TDIE_DUOS_INVOICE_DETAIL%ROWTYPE)
IS
   c_PROCEDURE_NAME CONSTANT VARCHAR(30) := 'INS_TDIE_DUOS_INVOICE_DETAIL';
   v_MISSING_DATA            BOOLEAN := FALSE;
   v_INS_MSG_WARN            VARCHAR2(2000) := 'Missing required/invalid values for TDIE_DUOS_INVOICE_DETAIL: ';
BEGIN
   ASSERT(p_REC.INVOICE_NUMBER IS NOT NULL, 'The TDIE_DUOS_INVOICE_DETAIL record must not be null.', MSGCODES.c_ERR_ARGUMENT);

   IF LOGS.IS_DEBUG_ENABLED THEN
      LOGS.LOG_DEBUG(g_PACKAGE_NAME||'.'||c_PROCEDURE_NAME);
		LOGS.LOG_DEBUG('p_REC = '||TO_CHAR_TDIE_DUOS_INV_DTL(p_REC));
   END IF;

   IF p_REC.INVOICE_NUMBER IS NULL THEN
      v_MISSING_DATA := TRUE;
      v_INS_MSG_WARN := v_INS_MSG_WARN||g_CRLF||'* INVOICE_NUMBER,';
   END IF;

   IF p_REC.INVOICE_ITEM_NUMBER IS NULL THEN
      v_MISSING_DATA := TRUE;
      v_INS_MSG_WARN := v_INS_MSG_WARN||g_CRLF||'* INVOICE_ITEM_NUMBER,';
   END IF;

   IF p_REC.MPRN IS NULL THEN
      v_MISSING_DATA := TRUE;
      v_INS_MSG_WARN := v_INS_MSG_WARN||g_CRLF||'* MPRN,';
   END IF;

   IF p_REC.INVOICE_TYPE IS NULL THEN
      v_MISSING_DATA := TRUE;
      v_INS_MSG_WARN := v_INS_MSG_WARN||g_CRLF||'* INVOICE_TYPE,';
   END IF;

   IF p_REC.DUOS_GROUP IS NULL THEN
      v_MISSING_DATA := TRUE;
      v_INS_MSG_WARN := v_INS_MSG_WARN||g_CRLF||'* DUOS_GROUP,';
   END IF;

   IF p_REC.BILLING_BEGIN_DATE IS NULL THEN
      v_MISSING_DATA := TRUE;
      v_INS_MSG_WARN := v_INS_MSG_WARN||g_CRLF||'* BILLING_BEGIN_DATE,';
   END IF;

   IF p_REC.BILLING_END_DATE IS NULL THEN
      v_MISSING_DATA := TRUE;
      v_INS_MSG_WARN := v_INS_MSG_WARN||g_CRLF||'* BILLING_END_DATE,';
   END IF;

   IF v_MISSING_DATA THEN
      v_INS_MSG_WARN := SUBSTR(v_INS_MSG_WARN,1,LENGTH(v_INS_MSG_WARN)-1)||'.';
      ERRS.RAISE(p_MESSAGE_CODE => MSGCODES.c_ERR_INVALID_FILE_TYPE,
                 p_EXTRA_MESSAGE => v_INS_MSG_WARN);
   ELSE
      INSERT INTO TDIE_DUOS_INVOICE_DETAIL (INVOICE_NUMBER,
                                            INVOICE_ITEM_NUMBER,
                                            MPRN,
                                            ADJUSTED_REFERENCE,
                                            INVOICE_TYPE,
                                            DUOS_GROUP,
                                            BILLING_BEGIN_DATE,
                                            BILLING_END_DATE,
                                            ENERGY_CONSUMPTION_DAY,
                                            ENERGY_CHARGE_DAY,
                                            ENERGY_CONSUMPTION_NIGHT,
                                            ENERGY_CHARGE_NIGHT,
                                            ENERGY_CONSUMPTION_24HR,
                                            ENERGY_CHARGE_24HR,
                                            STANDING_CHARGE,
                                            CAPACITY_CHARGE,
                                            MAX_IMPORT_CAPACITY,
                                            MAX_KVA,
                                            MIC_SURCHARGE,
                                            REACTIVE_ENERGY,
                                            POWER_FACTOR_SURCHARGE,
                                            NET_AMOUNT,
                                            GROSS_AMOUNT)
         VALUES (p_REC.INVOICE_NUMBER,
                 p_REC.INVOICE_ITEM_NUMBER,
                 p_REC.MPRN,
                 p_REC.ADJUSTED_REFERENCE,
                 p_REC.INVOICE_TYPE,
                 p_REC.DUOS_GROUP,
                 p_REC.BILLING_BEGIN_DATE,
                 p_REC.BILLING_END_DATE,
                 p_REC.ENERGY_CONSUMPTION_DAY,
                 p_REC.ENERGY_CHARGE_DAY,
                 p_REC.ENERGY_CONSUMPTION_NIGHT,
                 p_REC.ENERGY_CHARGE_NIGHT,
                 p_REC.ENERGY_CONSUMPTION_24HR,
                 p_REC.ENERGY_CHARGE_24HR,
                 p_REC.STANDING_CHARGE,
                 p_REC.CAPACITY_CHARGE,
                 p_REC.MAX_IMPORT_CAPACITY,
                 p_REC.MAX_KVA,
                 p_REC.MIC_SURCHARGE,
                 p_REC.REACTIVE_ENERGY,
                 p_REC.POWER_FACTOR_SURCHARGE,
                 p_REC.NET_AMOUNT,
                 p_REC.GROSS_AMOUNT);
   END IF;--IF v_MISSING_DATA THEN

END INS_TDIE_DUOS_INVOICE_DETAIL;

--------------------------------------------------------------------------------
-- This procedure inserts a record into the TDIE_DUOS_INVOICE table.
PROCEDURE INS_TDIE_DUOS_NI_INVOICE (p_REC IN TDIE_DUOS_NI_INVOICE%ROWTYPE)
IS
   c_PROCEDURE_NAME CONSTANT VARCHAR(30) := 'INS_TDIE_DUOS_NI_INVOICE';
   v_MISSING_DATA            BOOLEAN := FALSE;
   v_INS_MSG_WARN            VARCHAR2(2000) := 'Missing required/invalid values for TDIE_DUOS_NI_INVOICE: ';
BEGIN
   ASSERT(p_REC.INVOICE_NUMBER IS NOT NULL, 'The TDIE_DUOS_NI_INVOICE record must not be null.', MSGCODES.c_ERR_ARGUMENT);

   IF LOGS.IS_DEBUG_ENABLED THEN
      LOGS.LOG_DEBUG(g_PACKAGE_NAME||'.'||c_PROCEDURE_NAME);
		LOGS.LOG_DEBUG('p_REC = '||TO_CHAR_TDIE_DUOS_NI_INV(p_REC));
   END IF;

   IF p_REC.INVOICE_NUMBER IS NULL THEN
      v_MISSING_DATA := TRUE;
      v_INS_MSG_WARN := v_INS_MSG_WARN||g_CRLF||'* INVOICE_NUMBER,';
   END IF;

   IF p_REC.PROVIDER IS NULL THEN
      v_MISSING_DATA := TRUE;
      v_INS_MSG_WARN := v_INS_MSG_WARN||g_CRLF||'* PROVIDER,';
   END IF;

   IF p_REC.SUPPLIER IS NULL THEN
      v_MISSING_DATA := TRUE;
      v_INS_MSG_WARN := v_INS_MSG_WARN||g_CRLF||'* SUPPLIER,';
   END IF;

   IF p_REC.MARKET_TIMESTAMP IS NULL THEN
      v_MISSING_DATA := TRUE;
      v_INS_MSG_WARN := v_INS_MSG_WARN||g_CRLF||'* MARKET_TIMESTAMP,';
   END IF;

   IF p_REC.TOTAL_ITEMISED_LINES IS NULL THEN
      v_MISSING_DATA := TRUE;
      v_INS_MSG_WARN := v_INS_MSG_WARN||g_CRLF||'* TOTAL_ITEMISED_LINES,';
   END IF;

   IF p_REC.RECORDS_IMPORTED IS NULL THEN
      v_MISSING_DATA := TRUE;
      v_INS_MSG_WARN := v_INS_MSG_WARN||g_CRLF||'* RECORDS_IMPORTED,';
   END IF;

   IF p_REC.MPRN_COUNT IS NULL THEN
      v_MISSING_DATA := TRUE;
      v_INS_MSG_WARN := v_INS_MSG_WARN||g_CRLF||'* MPRN_COUNT,';
   END IF;

   IF p_REC.IMPORTED_REVENUE IS NULL THEN
      v_MISSING_DATA := TRUE;
      v_INS_MSG_WARN := v_INS_MSG_WARN||g_CRLF||'* IMPORTED_REVENUE,';
   END IF;

   IF p_REC.REVENUE_EXCL_VAT IS NULL THEN
      v_MISSING_DATA := TRUE;
      v_INS_MSG_WARN := v_INS_MSG_WARN||g_CRLF||'* REVENUE_EXCL_VAT,';
   END IF;

   IF p_REC.REVENUE_INC_VAT IS NULL THEN
      v_MISSING_DATA := TRUE;
      v_INS_MSG_WARN := v_INS_MSG_WARN||g_CRLF||'* REVENUE_INC_VAT,';
   END IF;

   IF p_REC.IMPORT_TIMESTAMP IS NULL THEN
      v_MISSING_DATA := TRUE;
      v_INS_MSG_WARN := v_INS_MSG_WARN||g_CRLF||'* IMPORT_TIMESTAMP,';
   END IF;

   IF p_REC.FILE_NAME IS NULL THEN
      v_MISSING_DATA := TRUE;
      v_INS_MSG_WARN := v_INS_MSG_WARN||g_CRLF||'* FILE_NAME,';
   END IF;

   IF v_MISSING_DATA THEN
      v_INS_MSG_WARN := SUBSTR(v_INS_MSG_WARN,1,LENGTH(v_INS_MSG_WARN)-1)||'.';
      ERRS.RAISE(p_MESSAGE_CODE => MSGCODES.c_ERR_INVALID_FILE_TYPE,
                 p_EXTRA_MESSAGE => v_INS_MSG_WARN);
   ELSE
      INSERT INTO TDIE_DUOS_NI_INVOICE (INVOICE_NUMBER,
                                        PROVIDER,
                                        SUPPLIER,
                                        MARKET_TIMESTAMP,
                                        TOTAL_ITEMISED_LINES,
                                        RECORDS_IMPORTED,
                                        MPRN_COUNT,
                                        IMPORTED_REVENUE,
                                        REVENUE_EXCL_VAT,
                                        REVENUE_INC_VAT,
                                        IMPORT_TIMESTAMP,
                                        FILE_NAME,
                                        PROCESS_ID,
                                        RETAIL_INVOICE_ID)
         VALUES (p_REC.INVOICE_NUMBER,
                 p_REC.PROVIDER,
                 p_REC.SUPPLIER,
                 p_REC.MARKET_TIMESTAMP,
                 p_REC.TOTAL_ITEMISED_LINES,
                 p_REC.RECORDS_IMPORTED,
                 p_REC.MPRN_COUNT,
                 p_REC.IMPORTED_REVENUE,
                 p_REC.REVENUE_EXCL_VAT,
                 p_REC.REVENUE_INC_VAT,
                 p_REC.IMPORT_TIMESTAMP,
                 p_REC.FILE_NAME,
                 p_REC.PROCESS_ID,
                 p_REC.RETAIL_INVOICE_ID);
   END IF;--IF v_MISSING_DATA THEN

END INS_TDIE_DUOS_NI_INVOICE;

--------------------------------------------------------------------------------
-- This procedure inserts a record into the TDIE_DUOS_NI_INVOICE_DETAIL table.
PROCEDURE INS_TDIE_DUOS_NI_INVOICE_DTL (p_REC IN TDIE_DUOS_NI_INVOICE_DETAIL%ROWTYPE)
IS
   c_PROCEDURE_NAME CONSTANT VARCHAR(30) := 'INS_TDIE_DUOS_NI_INVOICE_DTL';
   v_MISSING_DATA            BOOLEAN := FALSE;
   v_INS_MSG_WARN            VARCHAR2(2000) := 'Missing required/invalid values for TDIE_DUOS_NI_INVOICE_DETAIL: ';
BEGIN
   ASSERT(p_REC.INVOICE_NUMBER IS NOT NULL, 'The TDIE_DUOS_NI_INVOICE_DETAIL record must not be null.', MSGCODES.c_ERR_ARGUMENT);

   IF LOGS.IS_DEBUG_ENABLED THEN
      LOGS.LOG_DEBUG(g_PACKAGE_NAME||'.'||c_PROCEDURE_NAME);
		LOGS.LOG_DEBUG('p_REC = '||TO_CHAR_TDIE_DUOS_NI_INV_DTL(p_REC));
   END IF;

   IF p_REC.INVOICE_NUMBER IS NULL THEN
      v_MISSING_DATA := TRUE;
      v_INS_MSG_WARN := v_INS_MSG_WARN||g_CRLF||'* INVOICE_NUMBER,';
   END IF;

   IF p_REC.ITEM_NUMBER IS NULL THEN
      v_MISSING_DATA := TRUE;
      v_INS_MSG_WARN := v_INS_MSG_WARN||g_CRLF||'* ITEM_NUMBER,';
   END IF;

   IF p_REC.POD_ID IS NULL THEN
      v_MISSING_DATA := TRUE;
      v_INS_MSG_WARN := v_INS_MSG_WARN||g_CRLF||'* POD_ID,';
   END IF;

   IF p_REC.INVOICE_TYPE IS NULL THEN
      v_MISSING_DATA := TRUE;
      v_INS_MSG_WARN := v_INS_MSG_WARN||g_CRLF||'* INVOICE_TYPE,';
   END IF;

   IF p_REC.DUOS_GROUP IS NULL THEN
      v_MISSING_DATA := TRUE;
      v_INS_MSG_WARN := v_INS_MSG_WARN||g_CRLF||'* DUOS_GROUP,';
   END IF;

   IF p_REC.BILLING_BEGIN_DATE IS NULL THEN
      v_MISSING_DATA := TRUE;
      v_INS_MSG_WARN := v_INS_MSG_WARN||g_CRLF||'* BILLING_BEGIN_DATE,';
   END IF;

   IF p_REC.BILLING_END_DATE IS NULL THEN
      v_MISSING_DATA := TRUE;
      v_INS_MSG_WARN := v_INS_MSG_WARN||g_CRLF||'* BILLING_END_DATE,';
   END IF;

   IF p_REC.RATE_CATEGORY IS NULL THEN
      v_MISSING_DATA := TRUE;
      v_INS_MSG_WARN := v_INS_MSG_WARN||g_CRLF||'* RATE_CATEGORY,';
   END IF;

   IF v_MISSING_DATA THEN
      v_INS_MSG_WARN := SUBSTR(v_INS_MSG_WARN,1,LENGTH(v_INS_MSG_WARN)-1)||'.';
      ERRS.RAISE(p_MESSAGE_CODE => MSGCODES.c_ERR_INVALID_FILE_TYPE,
                 p_EXTRA_MESSAGE => v_INS_MSG_WARN);
   ELSE
      INSERT INTO TDIE_DUOS_NI_INVOICE_DETAIL (INVOICE_NUMBER,
                                            ITEM_NUMBER,
                                            POD_ID,
                                            ADJUST_REF,
                                            INVOICE_TYPE,
                                            DUOS_GROUP,
                                            BILLING_BEGIN_DATE,
                                            BILLING_END_DATE,
                                            RATE_CATEGORY,
                                            STAND_CHARGE,
                                            UNR_VOLUME,
                                            UNR_CHARGE,
                                            D01_VOLUME,
                                            D01_CHARGE,
                                            N01_VOLUME,
                                            N01_CHARGE,
                                            D02_VOLUME,
                                            D02_CHARGE,
                                            N02_VOLUME,
                                            N02_CHARGE,
                                            N03_VOLUME,
                                            N03_CHARGE,
                                            N04_VOLUME,
                                            N04_CHARGE,
                                            HT1_VOLUME,
                                            HT1_CHARGE,
                                            HT2_VOLUME,
                                            HT2_CHARGE,
                                            HT3_VOLUME,
                                            HT3_CHARGE,
                                            W1_VOLUME,
                                            W1_CHARGE,
                                            W2_VOLUME,
                                            W2_CHARGE,
                                            FR1_VOLUME,
                                            FR1_CHARGE,
                                            FR2_VOLUME,
                                            FR2_CHARGE,
                                            FR3_VOLUME,
                                            FR3_CHARGE,
                                            FR4_VOLUME,
                                            FR4_CHARGE,
                                            KP5_VOLUME,
                                            KP5_CHARGE,
                                            KP6_VOLUME,
                                            KP6_CHARGE,
                                            KP7_VOLUME,
                                            KP7_CHARGE,
                                            KP8_VOLUME,
                                            KP8_CHARGE,
                                            R21_VOLUME,
                                            R21_CHARGE,
                                            R22_VOLUME,
                                            R22_CHARGE,
                                            R23_VOLUME,
                                            R23_CHARGE,
                                            R24_VOLUME,
                                            R24_CHARGE,
                                            R25_VOLUME,
                                            R25_CHARGE,
                                            UNMTRD_VOLUME,
                                            UNMTRD_CHARGE,
                                            SMO_VOLUME,
                                            SMO_CHARGE,
                                            NFD_VOLUME,
                                            NFD_CHARGE,
                                            DJD_VOLUME,
                                            DJD_CHARGE,
                                            NKP_VOLUME,
                                            NKP_CHARGE,
                                            DJPK_VOLUME,
                                            DJPK_CHARGE,
                                            EW_VOLUME,
                                            EW_CHARGE,
                                            NT_VOLUME,
                                            NT_CHARGE,
                                            RPC_VOLUME,
                                            RPC_CHARGE,
                                            CSC_VOLUME,
                                            CSC_CHARGE,
                                            MIC_VOLUME,
                                            MIC_CHARGE,
                                            R26_VOLUME,
                                            R26_CHARGE,
                                            TOTAL_REVENUE,
                                            REVENUE_INC_VAT)
         VALUES (p_REC.INVOICE_NUMBER,
                 p_REC.ITEM_NUMBER,
                 p_REC.POD_ID,
                 p_REC.ADJUST_REF,
                 p_REC.INVOICE_TYPE,
                 p_REC.DUOS_GROUP,
                 p_REC.BILLING_BEGIN_DATE,
                 p_REC.BILLING_END_DATE,
                 p_REC.RATE_CATEGORY,
                 p_REC.STAND_CHARGE,
                 p_REC.UNR_VOLUME,
                 p_REC.UNR_CHARGE,
                 p_REC.D01_VOLUME,
                 p_REC.D01_CHARGE,
                 p_REC.N01_VOLUME,
                 p_REC.N01_CHARGE,
                 p_REC.D02_VOLUME,
                 p_REC.D02_CHARGE,
                 p_REC.N02_VOLUME,
                 p_REC.N02_CHARGE,
                 p_REC.N03_VOLUME,
                 p_REC.N03_CHARGE,
                 p_REC.N04_VOLUME,
                 p_REC.N04_CHARGE,
                 p_REC.HT1_VOLUME,
                 p_REC.HT1_CHARGE,
                 p_REC.HT2_VOLUME,
                 p_REC.HT2_CHARGE,
                 p_REC.HT3_VOLUME,
                 p_REC.HT3_CHARGE,
                 p_REC.W1_VOLUME,
                 p_REC.W1_CHARGE,
                 p_REC.W2_VOLUME,
                 p_REC.W2_CHARGE,
                 p_REC.FR1_VOLUME,
                 p_REC.FR1_CHARGE,
                 p_REC.FR2_VOLUME,
                 p_REC.FR2_CHARGE,
                 p_REC.FR3_VOLUME,
                 p_REC.FR3_CHARGE,
                 p_REC.FR4_VOLUME,
                 p_REC.FR4_CHARGE,
                 p_REC.KP5_VOLUME,
                 p_REC.KP5_CHARGE,
                 p_REC.KP6_VOLUME,
                 p_REC.KP6_CHARGE,
                 p_REC.KP7_VOLUME,
                 p_REC.KP7_CHARGE,
                 p_REC.KP8_VOLUME,
                 p_REC.KP8_CHARGE,
                 p_REC.R21_VOLUME,
                 p_REC.R21_CHARGE,
                 p_REC.R22_VOLUME,
                 p_REC.R22_CHARGE,
                 p_REC.R23_VOLUME,
                 p_REC.R23_CHARGE,
                 p_REC.R24_VOLUME,
                 p_REC.R24_CHARGE,
                 p_REC.R25_VOLUME,
                 p_REC.R25_CHARGE,
                 p_REC.UNMTRD_VOLUME,
                 p_REC.UNMTRD_CHARGE,
                 p_REC.SMO_VOLUME,
                 p_REC.SMO_CHARGE,
                 p_REC.NFD_VOLUME,
                 p_REC.NFD_CHARGE,
                 p_REC.DJD_VOLUME,
                 p_REC.DJD_CHARGE,
                 p_REC.NKP_VOLUME,
                 p_REC.NKP_CHARGE,
                 p_REC.DJPK_VOLUME,
                 p_REC.DJPK_CHARGE,
                 p_REC.EW_VOLUME,
                 p_REC.EW_CHARGE,
                 p_REC.NT_VOLUME,
                 p_REC.NT_CHARGE,
                 p_REC.RPC_VOLUME,
                 p_REC.RPC_CHARGE,
                 p_REC.CSC_VOLUME,
                 p_REC.CSC_CHARGE,
                 p_REC.MIC_VOLUME,
                 p_REC.MIC_CHARGE,
                 p_REC.R26_VOLUME,
                 p_REC.R26_CHARGE,
                 p_REC.TOTAL_REVENUE,
                 p_REC.REVENUE_INC_VAT);
   END IF;--IF v_MISSING_DATA THEN

END INS_TDIE_DUOS_NI_INVOICE_DTL;

--------------------------------------------------------------------------------
-- This procedure inserts a record into the TDIE_TUOS_INVOICE table.
PROCEDURE INS_TDIE_TUOS_INVOICE (p_REC IN TDIE_TUOS_INVOICE%ROWTYPE)
IS
   c_PROCEDURE_NAME CONSTANT VARCHAR(30) := 'INS_TDIE_TUOS_INVOICE';
   v_MISSING_DATA            BOOLEAN := FALSE;
   v_INS_MSG_WARN            VARCHAR2(2000) := 'Missing required/invalid values for TDIE_TUOS_INVOICE: ';
BEGIN
   ASSERT(p_REC.INVOICE_NUMBER IS NOT NULL, 'The TDIE_TUOS_INVOICE record must not be null.', MSGCODES.c_ERR_ARGUMENT);

   IF LOGS.IS_DEBUG_ENABLED THEN
      LOGS.LOG_DEBUG(g_PACKAGE_NAME||'.'||c_PROCEDURE_NAME);
		LOGS.LOG_DEBUG('p_REC = '||TO_CHAR_TDIE_TUOS_INV(p_REC));
   END IF;

   IF p_REC.NET_CHARGE_AMT_IMPORTED IS NULL THEN
      v_MISSING_DATA := TRUE;
      v_INS_MSG_WARN := v_INS_MSG_WARN||g_CRLF||'* NET_CHARGE_AMT_IMPORTED,';
   END IF;

   IF p_REC.GROSS_CHARGE_AMT_IMPORTED IS NULL THEN
      v_MISSING_DATA := TRUE;
      v_INS_MSG_WARN := v_INS_MSG_WARN||g_CRLF||'* GROSS_CHARGE_AMT_IMPORTED,';
   END IF;

   IF p_REC.MPRN_COUNT IS NULL THEN
      v_MISSING_DATA := TRUE;
      v_INS_MSG_WARN := v_INS_MSG_WARN||g_CRLF||'* MPRN_COUNT,';
   END IF;

   IF p_REC.SUPPLY_UNIT_COUNT IS NULL THEN
      v_MISSING_DATA := TRUE;
      v_INS_MSG_WARN := v_INS_MSG_WARN||g_CRLF||'* SUPPLY_UNIT_COUNT,';
   END IF;

   IF p_REC.RECORDS_IMPORTED IS NULL THEN
      v_MISSING_DATA := TRUE;
      v_INS_MSG_WARN := v_INS_MSG_WARN||g_CRLF||'* RECORDS_IMPORTED,';
   END IF;

   IF p_REC.IMPORT_TIMESTAMP IS NULL THEN
      v_MISSING_DATA := TRUE;
      v_INS_MSG_WARN := v_INS_MSG_WARN||g_CRLF||'* IMPORT_TIMESTAMP,';
   END IF;

   IF p_REC.FILE_NAME IS NULL THEN
      v_MISSING_DATA := TRUE;
      v_INS_MSG_WARN := v_INS_MSG_WARN||g_CRLF||'* FILE_NAME,';
   END IF;

   IF v_MISSING_DATA THEN
      v_INS_MSG_WARN := SUBSTR(v_INS_MSG_WARN,1,LENGTH(v_INS_MSG_WARN)-1)||'.';
      ERRS.RAISE(p_MESSAGE_CODE => MSGCODES.c_ERR_INVALID_FILE_TYPE,
                 p_EXTRA_MESSAGE => v_INS_MSG_WARN);
   ELSE
      INSERT INTO TDIE_TUOS_INVOICE (INVOICE_NUMBER,
                                     INVOICE_NAME,
                                     --INVOICE_CATEGORY,
                                     INVOICE_TYPE,
                                     INVOICE_START_DATE,
                                     INVOICE_END_DATE,
                                     INVOICE_STATUS,
                                     INVOICE_DATE,
                                     INVOICE_DUE_DATE,
                                     CUSTOMER_ID,
                                     CUSTOMER_CATEGORY,
                                     CUSTOMER_TYPE,
                                     CUSTOMER_CODE,
                                     CUSTOMER_NAME,
                                     NET_CHARGE_AMT_IMPORTED,
                                     GROSS_CHARGE_AMT_IMPORTED,
                                     MPRN_COUNT,
                                     SUPPLY_UNIT_COUNT,
                                     RECORDS_IMPORTED,
                                     IMPORT_TIMESTAMP,
                                     FILE_NAME,
                                     PROCESS_ID,
                                     RETAIL_INVOICE_ID)
         VALUES (p_REC.INVOICE_NUMBER,
                 p_REC.INVOICE_NAME,
                -- p_REC.INVOICE_CATEGORY,
                 p_REC.INVOICE_TYPE,
                 p_REC.INVOICE_START_DATE,
                 p_REC.INVOICE_END_DATE,
                 p_REC.INVOICE_STATUS,
                 p_REC.INVOICE_DATE,
                 p_REC.INVOICE_DUE_DATE,
                 p_REC.CUSTOMER_ID,
                 NVL(p_REC.CUSTOMER_CATEGORY,'n/a'),
                 NVL(p_REC.CUSTOMER_TYPE,'n/a'),
                 p_REC.CUSTOMER_CODE,
                 p_REC.CUSTOMER_NAME,
                 p_REC.NET_CHARGE_AMT_IMPORTED,
                 p_REC.GROSS_CHARGE_AMT_IMPORTED,
                 p_REC.MPRN_COUNT,
                 p_REC.SUPPLY_UNIT_COUNT,
                 p_REC.RECORDS_IMPORTED,
                 p_REC.IMPORT_TIMESTAMP,
                 p_REC.FILE_NAME,
                 p_REC.PROCESS_ID,
                 p_REC.RETAIL_INVOICE_ID);
   END IF;--IF v_MISSING_DATA THEN

END INS_TDIE_TUOS_INVOICE;

--------------------------------------------------------------------------------
-- This procedure inserts a record into the TDIE_TUOS_INVOICE_DETAIL table.
PROCEDURE INS_TDIE_TUOS_INVOICE_DTL (p_REC IN TDIE_TUOS_INVOICE_DETAIL%ROWTYPE)
IS
   c_PROCEDURE_NAME CONSTANT VARCHAR(30) := 'INS_TDIE_TUOS_INVOICE_DTL';
   v_MISSING_DATA            BOOLEAN := FALSE;
   v_INS_MSG_WARN            VARCHAR2(2000) := 'Missing required/invalid values for TDIE_TUOS_INVOICE_DETAIL: ';
BEGIN
   ASSERT(p_REC.INVOICE_NUMBER IS NOT NULL, 'The TDIE_TUOS_INVOICE_DETAIL record must not be null.', MSGCODES.c_ERR_ARGUMENT);

   IF LOGS.IS_DEBUG_ENABLED THEN
      LOGS.LOG_DEBUG(g_PACKAGE_NAME||'.'||c_PROCEDURE_NAME);
		LOGS.LOG_DEBUG('p_REC = '||TO_CHAR_TDIE_TUOS_INV_DTL(p_REC));
   END IF;

   IF p_REC.INVOICE_NUMBER IS NULL THEN
      v_MISSING_DATA := TRUE;
      v_INS_MSG_WARN := v_INS_MSG_WARN||g_CRLF||'* INVOICE_NUMBER,';
   END IF;

   IF p_REC.ACCOUNT_XID IS NULL THEN
      v_MISSING_DATA := TRUE;
      v_INS_MSG_WARN := v_INS_MSG_WARN||g_CRLF||'* ACCOUNT_XID,';
   END IF;

   IF p_REC.METER_NAME IS NULL THEN
      v_MISSING_DATA := TRUE;
      v_INS_MSG_WARN := v_INS_MSG_WARN||g_CRLF||'* METER_NAME,';
   END IF;

   IF v_MISSING_DATA THEN
      v_INS_MSG_WARN := SUBSTR(v_INS_MSG_WARN,1,LENGTH(v_INS_MSG_WARN)-1)||'.';
      ERRS.RAISE(p_MESSAGE_CODE => MSGCODES.c_ERR_INVALID_FILE_TYPE,
                 p_EXTRA_MESSAGE => v_INS_MSG_WARN);
   ELSE
      BEGIN
         INSERT INTO TDIE_TUOS_INVOICE_DETAIL (INVOICE_NUMBER,
                                               ACCOUNT_XID,
                                               METER_NAME,
                                               ACCOUNT_CATEGORY,
                                               ACCOUNT_TYPE,
                                               ACCOUNT_CODE,
                                               ACCOUNT_NAME,
                                               METER_XID,
                                               METER_CATEGORY,
                                               METER_TYPE,
                                               METER_CODE,
                                               BILL_NAME,
                                               BILL_CONTACT,
                                               BILL_ADDRESS1,
                                               BILL_ADDRESS2,
                                               BILL_CITY,
                                               BILL_REGION,
                                               BILL_COUNTRY,
                                               BILL_POSTAL_CODE,
                                               MPRN,
                                               SUPPLY_UNIT)
            VALUES (p_REC.INVOICE_NUMBER,
                    p_REC.ACCOUNT_XID,
                    p_REC.METER_NAME,
                    p_REC.ACCOUNT_CATEGORY,
                    p_REC.ACCOUNT_TYPE,
                    p_REC.ACCOUNT_CODE,
                    p_REC.ACCOUNT_NAME,
                    p_REC.METER_XID,
                    p_REC.METER_CATEGORY,
                    p_REC.METER_TYPE,
                    p_REC.METER_CODE,
                    p_REC.BILL_NAME,
                    p_REC.BILL_CONTACT,
                    p_REC.BILL_ADDRESS1,
                    p_REC.BILL_ADDRESS2,
                    p_REC.BILL_CITY,
                    p_REC.BILL_REGION,
                    p_REC.BILL_COUNTRY,
                    p_REC.BILL_POSTAL_CODE,
                    p_REC.MPRN,
                 p_REC.SUPPLY_UNIT);
      EXCEPTION
         -- Ignore duplicate combination of Invoice Number, Account ID and Meter Name
         WHEN DUP_VAL_ON_INDEX THEN
            NULL;
      END;
   END IF;--IF v_MISSING_DATA THEN

END INS_TDIE_TUOS_INVOICE_DTL;

--------------------------------------------------------------------------------
-- This procedure inserts a record into the TDIE_TUOS_INV_CHARGE_DTL table.
PROCEDURE INS_TDIE_TUOS_INVOICE_CHG_DTL (p_REC IN TDIE_TUOS_INV_CHARGE_DTL%ROWTYPE)
IS
   c_PROCEDURE_NAME CONSTANT VARCHAR(30) := 'INS_TDIE_TUOS_INVOICE_CHG_DTL';
   v_MISSING_DATA            BOOLEAN := FALSE;
   v_INS_MSG_WARN            VARCHAR2(2000) := 'Missing required/invalid values for TDIE_TUOS_INV_CHARGE_DTL: ';
BEGIN
   ASSERT(p_REC.INVOICE_NUMBER IS NOT NULL, 'The TDIE_TUOS_INV_CHARGE_DTL record must not be null.', MSGCODES.c_ERR_ARGUMENT);

   IF LOGS.IS_DEBUG_ENABLED THEN
      LOGS.LOG_DEBUG(g_PACKAGE_NAME||'.'||c_PROCEDURE_NAME);
		LOGS.LOG_DEBUG('p_REC = '||TO_CHAR_TDIE_TUOS_INV_CHG_DTL(p_REC));
   END IF;

   IF p_REC.ACCOUNT_XID IS NULL THEN
      v_MISSING_DATA := TRUE;
      v_INS_MSG_WARN := v_INS_MSG_WARN||g_CRLF||'* ACCOUNT_XID,';
   END IF;

   IF p_REC.METER_NAME IS NULL THEN
      v_MISSING_DATA := TRUE;
      v_INS_MSG_WARN := v_INS_MSG_WARN||g_CRLF||'* METER_NAME,';
   END IF;

   IF p_REC.INV_DET_START_DATE IS NULL THEN
      v_MISSING_DATA := TRUE;
      v_INS_MSG_WARN := v_INS_MSG_WARN||g_CRLF||'* INV_DET_START_DATE,';
   END IF;

   IF p_REC.INV_DET_END_DATE IS NULL THEN
      v_MISSING_DATA := TRUE;
      v_INS_MSG_WARN := v_INS_MSG_WARN||g_CRLF||'* INV_DET_END_DATE,';
   END IF;

   IF p_REC.INV_DET_CATEGORY IS NULL THEN
      v_MISSING_DATA := TRUE;
      v_INS_MSG_WARN := v_INS_MSG_WARN||g_CRLF||'* INV_DET_CATEGORY,';
   END IF;

   IF p_REC.INV_DET_TYPE IS NULL THEN
      v_MISSING_DATA := TRUE;
      v_INS_MSG_WARN := v_INS_MSG_WARN||g_CRLF||'* INV_DET_TYPE,';
   END IF;

   IF p_REC.INV_DET_CODE IS NULL THEN
      v_MISSING_DATA := TRUE;
      v_INS_MSG_WARN := v_INS_MSG_WARN||g_CRLF||'* INV_DET_CODE,';
   END IF;

   IF p_REC.INV_DET_CATEGORY2 IS NULL THEN
      v_MISSING_DATA := TRUE;
      v_INS_MSG_WARN := v_INS_MSG_WARN||g_CRLF||'* INV_DET_CATEGORY2,';
   END IF;

   IF p_REC.INV_DET_SEQ IS NULL THEN
      v_MISSING_DATA := TRUE;
      v_INS_MSG_WARN := v_INS_MSG_WARN||g_CRLF||'* INV_DET_SEQ,';
   END IF;

   IF p_REC.MULTI_CIP_FLAG IS NULL THEN
      v_MISSING_DATA := TRUE;
      v_INS_MSG_WARN := v_INS_MSG_WARN||g_CRLF||'* MULTI_CIP_FLAG,';
   END IF;

   IF p_REC.INV_DET_NOTE_SORT IS NULL THEN
      v_MISSING_DATA := TRUE;
      v_INS_MSG_WARN := v_INS_MSG_WARN||g_CRLF||'* INV_DET_NOTE_SORT,';
   END IF;

   IF v_MISSING_DATA THEN
      v_INS_MSG_WARN := SUBSTR(v_INS_MSG_WARN,1,LENGTH(v_INS_MSG_WARN)-1)||'.';
      ERRS.RAISE(p_MESSAGE_CODE => MSGCODES.c_ERR_INVALID_FILE_TYPE,
                 p_EXTRA_MESSAGE => v_INS_MSG_WARN);
   ELSE
      INSERT INTO TDIE_TUOS_INV_CHARGE_DTL (INVOICE_NUMBER,
                                            ACCOUNT_XID,
                                            METER_NAME,
										              INVOICE_CATEGORY,
                                            INV_DET_START_DATE,
                                            INV_DET_END_DATE,
                                            INV_DET_CATEGORY,
                                            INV_DET_TYPE,
                                            INV_DET_CODE,
                                            INV_DET_CATEGORY2,
                                            INV_DET_SEQ,
                                            INV_DET_NAME,
                                            INV_DET_VALUE,
                                            INV_DET_UOM,
                                            MULTI_CIP_FLAG,
                                            VAT_CHARGE,
                                            INV_DET_VALUE_CHARGE,
                                            INV_DET_VALUE_CHARGE_NO_VAT,
                                            INV_DET_TYPE_SORT,
                                            EIR_RPT_INV_DET_ID,
                                            BILL_DATE,
                                            CIP_DATE,
                                            INV_STATUS_DRAFT,
                                            INV_NUMBER_RELEASED,
                                            INV_DATE_RELEASED,
                                            INV_DET_NOTES,
                                            INV_DET_NOTE_SORT,
                                            DLAFG,
                                            DG)
         VALUES (p_REC.INVOICE_NUMBER,
                 p_REC.ACCOUNT_XID,
                 p_REC.METER_NAME,
			        p_REC.INVOICE_CATEGORY,
                 p_REC.INV_DET_START_DATE,
                 p_REC.INV_DET_END_DATE,
                 p_REC.INV_DET_CATEGORY,
                 p_REC.INV_DET_TYPE,
                 p_REC.INV_DET_CODE,
                 p_REC.INV_DET_CATEGORY2,
                 p_REC.INV_DET_SEQ,
                 p_REC.INV_DET_NAME,
                 p_REC.INV_DET_VALUE,
                 p_REC.INV_DET_UOM,
                 p_REC.MULTI_CIP_FLAG,
                 p_REC.VAT_CHARGE,
                 p_REC.INV_DET_VALUE_CHARGE,
                 p_REC.INV_DET_VALUE_CHARGE_NO_VAT,
                 p_REC.INV_DET_TYPE_SORT,
                 p_REC.EIR_RPT_INV_DET_ID,
                 p_REC.BILL_DATE,
                 p_REC.CIP_DATE,
                 p_REC.INV_STATUS_DRAFT,
                 p_REC.INV_NUMBER_RELEASED,
                 p_REC.INV_DATE_RELEASED,
                 p_REC.INV_DET_NOTES,
                 p_REC.INV_DET_NOTE_SORT,
                 p_REC.DLAFG,
                 p_REC.DG);
  END IF;--IF v_MISSING_DATA THEN

END INS_TDIE_TUOS_INVOICE_CHG_DTL;

--------------------------------------------------------------------------------
-- This procedure inserts a record into the TDIE_UOS_INVOICE table.
PROCEDURE INS_TDIE_UOS_INVOICE (p_REC IN TDIE_UOS_INVOICE%ROWTYPE)
IS
   c_PROCEDURE_NAME CONSTANT VARCHAR(30) := 'INS_TDIE_UOS_INVOICE';
   v_MISSING_DATA            BOOLEAN := FALSE;
   v_INS_MSG_WARN            VARCHAR2(2000) := 'Missing required/invalid values for TDIE_UOS_INVOICE: ';
BEGIN
   ASSERT(p_REC.INVOICE_NUMBER IS NOT NULL, 'The TDIE_UOS_INVOICE record must not be null.', MSGCODES.c_ERR_ARGUMENT);

   IF LOGS.IS_DEBUG_ENABLED THEN
      LOGS.LOG_DEBUG(g_PACKAGE_NAME||'.'||c_PROCEDURE_NAME);
		LOGS.LOG_DEBUG('p_REC = '||TO_CHAR_TDIE_UOS_INV(p_REC));
   END IF;
   IF p_REC.INVOICE_NUMBER IS NULL THEN
      v_MISSING_DATA := TRUE;
      v_INS_MSG_WARN := v_INS_MSG_WARN||g_CRLF||'* INVOICE_NUMBER,';
   END IF;

   IF p_REC.SENDER_CID IS NULL THEN
      v_MISSING_DATA := TRUE;
      v_INS_MSG_WARN := v_INS_MSG_WARN||g_CRLF||'* SENDER_CID,';
   END IF;

   IF p_REC.RECIPIENT_CID IS NULL THEN
      v_MISSING_DATA := TRUE;
      v_INS_MSG_WARN := v_INS_MSG_WARN||g_CRLF||'* RECIPIENT_CID,';
   END IF;

   IF p_REC.MARKET_TIMESTAMP IS NULL THEN
      v_MISSING_DATA := TRUE;
      v_INS_MSG_WARN := v_INS_MSG_WARN||g_CRLF||'* MARKET_TIMESTAMP,';
   END IF;

   IF p_REC.DUE_DATE IS NULL THEN
      v_MISSING_DATA := TRUE;
      v_INS_MSG_WARN := v_INS_MSG_WARN||g_CRLF||'* DUE_DATE,';
   END IF;

   IF p_REC.TOTAL_CONSUMPTION IS NULL THEN
      v_MISSING_DATA := TRUE;
      v_INS_MSG_WARN := v_INS_MSG_WARN||g_CRLF||'* TOTAL_CONSUMPTION,';
   END IF;

   IF p_REC.TOTAL_CSC IS NULL THEN
      v_MISSING_DATA := TRUE;
      v_INS_MSG_WARN := v_INS_MSG_WARN||g_CRLF||'* TOTAL_CSC,';
   END IF;

   IF p_REC.TOTAL_REACTIVE IS NULL THEN
      v_MISSING_DATA := TRUE;
      v_INS_MSG_WARN := v_INS_MSG_WARN||g_CRLF||'* TOTAL_REACTIVE,';
   END IF;

   IF p_REC.TOTAL_STANDING_CHARGE IS NULL THEN
      v_MISSING_DATA := TRUE;
      v_INS_MSG_WARN := v_INS_MSG_WARN||g_CRLF||'* TOTAL_STANDING_CHARGE,';
   END IF;

   IF p_REC.TOTAL_TRANSMISSION_REBATE IS NULL THEN
      v_MISSING_DATA := TRUE;
      v_INS_MSG_WARN := v_INS_MSG_WARN||g_CRLF||'* TOTAL_TRANSMISSION_REBATE,';
   END IF;

   IF p_REC.TOTAL_AD_HOC IS NULL THEN
      v_MISSING_DATA := TRUE;
      v_INS_MSG_WARN := v_INS_MSG_WARN||g_CRLF||'* TOTAL_AD_HOC,';
   END IF;

   IF p_REC.TOTAL_CONSUMPTION_ADJUSTMENT IS NULL THEN
      v_MISSING_DATA := TRUE;
      v_INS_MSG_WARN := v_INS_MSG_WARN||g_CRLF||'* TOTAL_CONSUMPTION_ADJUSTMENT,';
   END IF;

   IF p_REC.TOTAL_VAT IS NULL THEN
      v_MISSING_DATA := TRUE;
      v_INS_MSG_WARN := v_INS_MSG_WARN||g_CRLF||'* TOTAL_VAT,';
   END IF;

   IF p_REC.TOTAL_CANCELED IS NULL THEN
      v_MISSING_DATA := TRUE;
      v_INS_MSG_WARN := v_INS_MSG_WARN||g_CRLF||'* TOTAL_CANCELED,';
   END IF;

   IF p_REC.TOTAL_CONSUMPTION_KWH IS NULL THEN
      v_MISSING_DATA := TRUE;
      v_INS_MSG_WARN := v_INS_MSG_WARN||g_CRLF||'* TOTAL_CONSUMPTION_KWH,';
   END IF;

   IF p_REC.TOTAL_DETAIL_LINES IS NULL THEN
      v_MISSING_DATA := TRUE;
      v_INS_MSG_WARN := v_INS_MSG_WARN||g_CRLF||'* TOTAL_DETAIL_LINES,';
   END IF;

   IF p_REC.NET_CHARGE_AMT_IMPORTED IS NULL THEN
      v_MISSING_DATA := TRUE;
      v_INS_MSG_WARN := v_INS_MSG_WARN||g_CRLF||'* NET_CHARGE_AMT_IMPORTED,';
   END IF;

   IF p_REC.GROSS_CHARGE_AMT_IMPORTED IS NULL THEN
      v_MISSING_DATA := TRUE;
      v_INS_MSG_WARN := v_INS_MSG_WARN||g_CRLF||'* GROSS_CHARGE_AMT_IMPORTED,';
   END IF;

   IF p_REC.MPRN_COUNT IS NULL THEN
      v_MISSING_DATA := TRUE;
      v_INS_MSG_WARN := v_INS_MSG_WARN||g_CRLF||'* MPRN_COUNT,';
   END IF;

   IF p_REC.RECORDS_IMPORTED IS NULL THEN
      v_MISSING_DATA := TRUE;
      v_INS_MSG_WARN := v_INS_MSG_WARN||g_CRLF||'* RECORDS_IMPORTED,';
   END IF;

   IF p_REC.IMPORT_TIMESTAMP IS NULL THEN
      v_MISSING_DATA := TRUE;
      v_INS_MSG_WARN := v_INS_MSG_WARN||g_CRLF||'* IMPORT_TIMESTAMP,';
   END IF;

   IF p_REC.FILE_NAME IS NULL THEN
      v_MISSING_DATA := TRUE;
      v_INS_MSG_WARN := v_INS_MSG_WARN||g_CRLF||'* FILE_NAME,';
   END IF;

   IF v_MISSING_DATA THEN
      v_INS_MSG_WARN := SUBSTR(v_INS_MSG_WARN,1,LENGTH(v_INS_MSG_WARN)-1)||'.';
      ERRS.RAISE(p_MESSAGE_CODE => MSGCODES.c_ERR_INVALID_FILE_TYPE,
                 p_EXTRA_MESSAGE => v_INS_MSG_WARN);
   ELSE
      INSERT INTO TDIE_UOS_INVOICE (INVOICE_NUMBER,
                                    SENDER_CID,
                                    RECIPIENT_CID,
                                    MARKET_TIMESTAMP,
                                    DUE_DATE,
                                    TOTAL_CONSUMPTION,
                                    TOTAL_CSC,
                                    TOTAL_REACTIVE,
                                    TOTAL_STANDING_CHARGE,
                                    TOTAL_TRANSMISSION_REBATE,
                                    TOTAL_AD_HOC,
                                    TOTAL_CONSUMPTION_ADJUSTMENT,
                                    TOTAL_VAT,
                                    TOTAL_CANCELED,
                                    TOTAL_CONSUMPTION_KWH,
                                    TOTAL_DETAIL_LINES,
                                    MPRN_COUNT,
                                    RETAIL_INVOICE_ID,
                                    NET_CHARGE_AMT_IMPORTED,
                                    GROSS_CHARGE_AMT_IMPORTED,
                                    RECORDS_IMPORTED,
                                    IMPORT_TIMESTAMP,
                                    FILE_NAME,
                                    PROCESS_ID)
         VALUES (p_REC.INVOICE_NUMBER,
                 p_REC.SENDER_CID,
                 p_REC.RECIPIENT_CID,
                 p_REC.MARKET_TIMESTAMP,
                 p_REC.DUE_DATE,
                 p_REC.TOTAL_CONSUMPTION,
                 p_REC.TOTAL_CSC,
                 p_REC.TOTAL_REACTIVE,
                 p_REC.TOTAL_STANDING_CHARGE,
                 p_REC.TOTAL_TRANSMISSION_REBATE,
                 p_REC.TOTAL_AD_HOC,
                 p_REC.TOTAL_CONSUMPTION_ADJUSTMENT,
                 p_REC.TOTAL_VAT,
                 p_REC.TOTAL_CANCELED,
                 p_REC.TOTAL_CONSUMPTION_KWH,
                 p_REC.TOTAL_DETAIL_LINES,
                 p_REC.MPRN_COUNT,
                 p_REC.RETAIL_INVOICE_ID,
                 p_REC.NET_CHARGE_AMT_IMPORTED,
                 p_REC.GROSS_CHARGE_AMT_IMPORTED,
                 p_REC.RECORDS_IMPORTED,
                 p_REC.IMPORT_TIMESTAMP,
                 p_REC.FILE_NAME,
                 p_REC.PROCESS_ID);
   END IF;--IF v_MISSING_DATA THEN

END INS_TDIE_UOS_INVOICE;

--------------------------------------------------------------------------------
-- This procedure inserts a record into the TDIE_UOS_INVOICE_DETAIL table.
PROCEDURE INS_TDIE_UOS_INVOICE_DETAIL (p_REC IN TDIE_UOS_INVOICE_DETAIL%ROWTYPE)
IS
   c_PROCEDURE_NAME CONSTANT VARCHAR(30) := 'INS_TDIE_UOS_INVOICE_DETAIL';
   v_MISSING_DATA            BOOLEAN := FALSE;
   v_INS_MSG_WARN            VARCHAR2(2000) := 'Missing required/invalid values for TDIE_UOS_INVOICE_DETAIL: ';
BEGIN
   ASSERT(p_REC.INVOICE_NUMBER IS NOT NULL, 'The TDIE_UOS_INVOICE_DETAIL record must not be null.', MSGCODES.c_ERR_ARGUMENT);

   IF LOGS.IS_DEBUG_ENABLED THEN
      LOGS.LOG_DEBUG(g_PACKAGE_NAME||'.'||c_PROCEDURE_NAME);
		LOGS.LOG_DEBUG('p_REC = '||TO_CHAR_TDIE_UOS_INV_DTL(p_REC));
   END IF;

   IF p_REC.INVOICE_NUMBER IS NULL THEN
      v_MISSING_DATA := TRUE;
      v_INS_MSG_WARN := v_INS_MSG_WARN||g_CRLF||'* INVOICE_NUMBER,';
   END IF;

   IF p_REC.SENDER_CID IS NULL THEN
      v_MISSING_DATA := TRUE;
      v_INS_MSG_WARN := v_INS_MSG_WARN||g_CRLF||'* SENDER_CID,';
   END IF;

   IF p_REC.RECORD_TYPE IS NULL THEN
      v_MISSING_DATA := TRUE;
      v_INS_MSG_WARN := v_INS_MSG_WARN||g_CRLF||'* RECORD_TYPE,';
   END IF;

   IF p_REC.MPRN IS NULL THEN
      v_MISSING_DATA := TRUE;
      v_INS_MSG_WARN := v_INS_MSG_WARN||g_CRLF||'* MPRN,';
   END IF;

   IF p_REC.START_DATE IS NULL THEN
      v_MISSING_DATA := TRUE;
      v_INS_MSG_WARN := v_INS_MSG_WARN||g_CRLF||'* START_DATE,';
   END IF;

   IF p_REC.END_DATE IS NULL THEN
      v_MISSING_DATA := TRUE;
      v_INS_MSG_WARN := v_INS_MSG_WARN||g_CRLF||'* END_DATE,';
   END IF;

   IF p_REC.RATE IS NULL THEN
      v_MISSING_DATA := TRUE;
      v_INS_MSG_WARN := v_INS_MSG_WARN||g_CRLF||'* RATE,';
   END IF;

   IF p_REC.CHARGE IS NULL THEN
      v_MISSING_DATA := TRUE;
      v_INS_MSG_WARN := v_INS_MSG_WARN||g_CRLF||'* CHARGE,';
   END IF;

   IF v_MISSING_DATA THEN
      v_INS_MSG_WARN := SUBSTR(v_INS_MSG_WARN,1,LENGTH(v_INS_MSG_WARN)-1)||'.';
      ERRS.RAISE(p_MESSAGE_CODE => MSGCODES.c_ERR_INVALID_FILE_TYPE,
                 p_EXTRA_MESSAGE => v_INS_MSG_WARN);
   ELSE
      INSERT INTO TDIE_UOS_INVOICE_DETAIL (INVOICE_NUMBER,
                                           SENDER_CID,
                                           RECORD_TYPE,
                                           MPRN,
                                           METER_ID_SERIAL_NUMBER,
                                           START_DATE,
                                           END_DATE,
                                           UNIT_OF_MEASURE,
                                           TIMESLOT_CODE,
                                           START_READ,
                                           START_READ_TYPE,
                                           END_READ,
                                           END_READ_TYPE,
                                           TOTAL_UNITS,
                                           ESTIMATED_UNITS,
                                           UOS_TARIFF,
                                           RATE,
                                           CHARGE,
                                           LAST_ACTUAL_READ_VALUE,
                                           LAST_ACTUAL_READ_DATE)
         VALUES (p_REC.INVOICE_NUMBER,
                 p_REC.SENDER_CID,
                 p_REC.RECORD_TYPE,
                 p_REC.MPRN,
                 p_REC.METER_ID_SERIAL_NUMBER,
                 p_REC.START_DATE,
                 p_REC.END_DATE,
                 p_REC.UNIT_OF_MEASURE,
                 p_REC.TIMESLOT_CODE,
                 p_REC.START_READ,
                 p_REC.START_READ_TYPE,
                 p_REC.END_READ,
                 p_REC.END_READ_TYPE,
                 p_REC.TOTAL_UNITS,
                 p_REC.ESTIMATED_UNITS,
                 p_REC.UOS_TARIFF,
                 p_REC.RATE,
                 p_REC.CHARGE,
                 p_REC.LAST_ACTUAL_READ_VALUE,
                 p_REC.LAST_ACTUAL_READ_DATE);
   END IF;--IF v_MISSING_DATA THEN

END INS_TDIE_UOS_INVOICE_DETAIL;


--------------------------------------------------------------------------------
-- This procedure will be responsible for processing the DUoS Backing Sheet CSV file
-- This procedure will use the PARSE_UTIL library to handle the CSV parsing.
PROCEDURE IMPORT_DUOS (p_IMPORT_FILE IN CLOB)
IS
   c_PROCEDURE_NAME CONSTANT VARCHAR(30) := 'IMPORT_DUOS';
   i                         BINARY_INTEGER := 1;
   v_TDIE_DUOS_INV_REC       TDIE_DUOS_INVOICE%ROWTYPE;
   v_TDIE_DUOS_INV_DTL_REC   TDIE_DUOS_INVOICE_DETAIL%ROWTYPE;
   v_LINES                   PARSE_UTIL.BIG_STRING_TABLE_MP;
   v_LINE_ELEMENTS           PARSE_UTIL.STRING_TABLE;
   v_PROCESSED_REC_CNT       NUMBER;
   v_INV_MSG_TEXT            VARCHAR2(2000) := NULL;
   v_HEADER_REC_FOUND        BOOLEAN := FALSE;
   v_DETAIL_REC_FOUND        BOOLEAN := FALSE;
   v_FOOTER_REC_FOUND        BOOLEAN := FALSE;
BEGIN
   ASSERT(p_IMPORT_FILE IS NOT NULL, 'The import file must not be null.', MSGCODES.c_ERR_ARGUMENT);

	IF LOGS.IS_DEBUG_ENABLED THEN
      LOGS.LOG_DEBUG(g_PACKAGE_NAME||'.'||c_PROCEDURE_NAME);
	END IF;

   PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_IMPORT_FILE, v_LINES);

   i := v_LINES.FIRST;
   v_PROCESSED_REC_CNT := 0;
   WHILE i <= v_LINES.LAST LOOP
      PARSE_UTIL.PARSE_DELIMITED_STRING(v_LINES(i), ',', v_LINE_ELEMENTS);

      CASE
         -- PROCESS Header Record ----------------------------------------------
         WHEN v_LINE_ELEMENTS(1) = 1 AND NVL(v_TDIE_DUOS_INV_REC.INVOICE_NUMBER, -1) <> v_LINE_ELEMENTS(2) THEN

               v_HEADER_REC_FOUND := TRUE;
               v_DETAIL_REC_FOUND := FALSE;
               v_FOOTER_REC_FOUND := FALSE;

               v_TDIE_DUOS_INV_REC.INVOICE_NUMBER            := v_LINE_ELEMENTS(2);
               v_TDIE_DUOS_INV_REC.SENDER_CID                := v_LINE_ELEMENTS(3);
               v_TDIE_DUOS_INV_REC.RECIPIENT_CID             := v_LINE_ELEMENTS(4);
               v_TDIE_DUOS_INV_REC.MARKET_TIMESTAMP          := CONVERT_TO_DATE(v_LINE_ELEMENTS(5), g_CSV_TIMESTAMP_FORMAT);
               v_TDIE_DUOS_INV_REC.CONTROL_TOTAL             := 0;
               v_TDIE_DUOS_INV_REC.TOTAL_RECORDS             := 0;
               v_TDIE_DUOS_INV_REC.NET_CHARGE_AMT_IMPORTED   := 0;
               v_TDIE_DUOS_INV_REC.GROSS_CHARGE_AMT_IMPORTED := 0;
               v_TDIE_DUOS_INV_REC.MPRN_COUNT                := 0;
               v_TDIE_DUOS_INV_REC.RECORDS_IMPORTED          := 0;
               v_TDIE_DUOS_INV_REC.IMPORT_TIMESTAMP          := g_IMPORT_TIMESTAMP;
               v_TDIE_DUOS_INV_REC.FILE_NAME                 := g_IMPORT_FILE_PATH;
               v_TDIE_DUOS_INV_REC.PROCESS_ID                := g_PROCESS_ID;
               v_TDIE_DUOS_INV_REC.RETAIL_INVOICE_ID         := NULL;

               v_INV_MSG_TEXT := 'Invoice Number:   '||v_TDIE_DUOS_INV_REC.INVOICE_NUMBER||g_CRLF||
                                 'Market Timestamp: '||TO_CHAR(v_TDIE_DUOS_INV_REC.MARKET_TIMESTAMP,g_CSV_TIMESTAMP_FORMAT)||g_CRLF||
                                 'Sender CID:       '||v_TDIE_DUOS_INV_REC.SENDER_CID||g_CRLF||
                                 'Recipient CID:    '||v_TDIE_DUOS_INV_REC.RECIPIENT_CID||g_CRLF||
                                 'File Name:        '||v_TDIE_DUOS_INV_REC.FILE_NAME||g_CRLF||
                                 'PROCESS_ID:       '||TO_CHAR(v_TDIE_DUOS_INV_REC.PROCESS_ID)||g_CRLF;

               LOGS.LOG_INFO(p_EVENT_TEXT => v_INV_MSG_TEXT);

               DEL_TDIE_DUOS_INVOICE(v_TDIE_DUOS_INV_REC);
               INS_TDIE_DUOS_INVOICE(v_TDIE_DUOS_INV_REC);

         -- PROCESS Detail Record ----------------------------------------------
         WHEN v_LINE_ELEMENTS(1) = 2 AND v_LINE_ELEMENTS(2) = v_TDIE_DUOS_INV_REC.INVOICE_NUMBER THEN

            IF v_HEADER_REC_FOUND THEN
               v_DETAIL_REC_FOUND := TRUE;
            ELSE
               v_DETAIL_REC_FOUND := FALSE;
            END IF;

            v_PROCESSED_REC_CNT := v_PROCESSED_REC_CNT + 1;

            v_TDIE_DUOS_INV_DTL_REC.INVOICE_NUMBER           := v_LINE_ELEMENTS(2);
            v_TDIE_DUOS_INV_DTL_REC.INVOICE_ITEM_NUMBER      := CONVERT_TO_NUMBER(v_LINE_ELEMENTS(3));
            v_TDIE_DUOS_INV_DTL_REC.MPRN                     := v_LINE_ELEMENTS(4);
            v_TDIE_DUOS_INV_DTL_REC.ADJUSTED_REFERENCE       := CONVERT_TO_NUMBER(v_LINE_ELEMENTS(5));
            v_TDIE_DUOS_INV_DTL_REC.INVOICE_TYPE             := v_LINE_ELEMENTS(6);
            v_TDIE_DUOS_INV_DTL_REC.DUOS_GROUP               := v_LINE_ELEMENTS(7);
            v_TDIE_DUOS_INV_DTL_REC.BILLING_BEGIN_DATE       := CONVERT_TO_DATE(v_LINE_ELEMENTS(8), g_CSV_DATE_FORMAT);
            v_TDIE_DUOS_INV_DTL_REC.BILLING_END_DATE         := CONVERT_TO_DATE(v_LINE_ELEMENTS(9), g_CSV_DATE_FORMAT);
            v_TDIE_DUOS_INV_DTL_REC.ENERGY_CONSUMPTION_DAY   := CASE WHEN INSTR(v_LINE_ELEMENTS(10),'-') > 0 THEN CONVERT_TO_NUMBER(v_LINE_ELEMENTS(10),c_MINUS_NUM_FORMAT) ELSE CONVERT_TO_NUMBER(v_LINE_ELEMENTS(10),c_NUM_FORMAT) END;
            v_TDIE_DUOS_INV_DTL_REC.ENERGY_CHARGE_DAY        := CASE WHEN INSTR(v_LINE_ELEMENTS(11),'-') > 0 THEN CONVERT_TO_NUMBER(v_LINE_ELEMENTS(11),c_MINUS_NUM_FORMAT) ELSE CONVERT_TO_NUMBER(v_LINE_ELEMENTS(11),c_NUM_FORMAT) END;
            v_TDIE_DUOS_INV_DTL_REC.ENERGY_CONSUMPTION_NIGHT := CASE WHEN INSTR(v_LINE_ELEMENTS(12),'-') > 0 THEN CONVERT_TO_NUMBER(v_LINE_ELEMENTS(12),c_MINUS_NUM_FORMAT) ELSE CONVERT_TO_NUMBER(v_LINE_ELEMENTS(12),c_NUM_FORMAT) END;
            v_TDIE_DUOS_INV_DTL_REC.ENERGY_CHARGE_NIGHT      := CASE WHEN INSTR(v_LINE_ELEMENTS(13),'-') > 0 THEN CONVERT_TO_NUMBER(v_LINE_ELEMENTS(13),c_MINUS_NUM_FORMAT) ELSE CONVERT_TO_NUMBER(v_LINE_ELEMENTS(13),c_NUM_FORMAT) END;
            v_TDIE_DUOS_INV_DTL_REC.ENERGY_CONSUMPTION_24HR  := CASE WHEN INSTR(v_LINE_ELEMENTS(14),'-') > 0 THEN CONVERT_TO_NUMBER(v_LINE_ELEMENTS(14),c_MINUS_NUM_FORMAT) ELSE CONVERT_TO_NUMBER(v_LINE_ELEMENTS(14),c_NUM_FORMAT) END;
            v_TDIE_DUOS_INV_DTL_REC.ENERGY_CHARGE_24HR       := CASE WHEN INSTR(v_LINE_ELEMENTS(15),'-') > 0 THEN CONVERT_TO_NUMBER(v_LINE_ELEMENTS(15),c_MINUS_NUM_FORMAT) ELSE CONVERT_TO_NUMBER(v_LINE_ELEMENTS(15),c_NUM_FORMAT) END;
            v_TDIE_DUOS_INV_DTL_REC.STANDING_CHARGE          := CASE WHEN INSTR(v_LINE_ELEMENTS(16),'-') > 0 THEN CONVERT_TO_NUMBER(v_LINE_ELEMENTS(16),c_MINUS_NUM_FORMAT) ELSE CONVERT_TO_NUMBER(v_LINE_ELEMENTS(16),c_NUM_FORMAT) END;
            v_TDIE_DUOS_INV_DTL_REC.CAPACITY_CHARGE          := CASE WHEN INSTR(v_LINE_ELEMENTS(17),'-') > 0 THEN CONVERT_TO_NUMBER(v_LINE_ELEMENTS(17),c_MINUS_NUM_FORMAT) ELSE CONVERT_TO_NUMBER(v_LINE_ELEMENTS(17),c_NUM_FORMAT) END;
            v_TDIE_DUOS_INV_DTL_REC.MAX_IMPORT_CAPACITY      := CASE WHEN INSTR(v_LINE_ELEMENTS(18),'-') > 0 THEN CONVERT_TO_NUMBER(v_LINE_ELEMENTS(18),c_MINUS_NUM_FORMAT) ELSE CONVERT_TO_NUMBER(v_LINE_ELEMENTS(18),c_NUM_FORMAT) END;
            v_TDIE_DUOS_INV_DTL_REC.MAX_KVA                  := CASE WHEN INSTR(v_LINE_ELEMENTS(19),'-') > 0 THEN CONVERT_TO_NUMBER(v_LINE_ELEMENTS(19),c_MINUS_NUM_FORMAT) ELSE CONVERT_TO_NUMBER(v_LINE_ELEMENTS(19),c_NUM_FORMAT) END;
            v_TDIE_DUOS_INV_DTL_REC.MIC_SURCHARGE            := CASE WHEN INSTR(v_LINE_ELEMENTS(20),'-') > 0 THEN CONVERT_TO_NUMBER(v_LINE_ELEMENTS(20),c_MINUS_NUM_FORMAT) ELSE CONVERT_TO_NUMBER(v_LINE_ELEMENTS(20),c_NUM_FORMAT) END;
            v_TDIE_DUOS_INV_DTL_REC.REACTIVE_ENERGY          := CASE WHEN INSTR(v_LINE_ELEMENTS(21),'-') > 0 THEN CONVERT_TO_NUMBER(v_LINE_ELEMENTS(21),c_MINUS_NUM_FORMAT) ELSE CONVERT_TO_NUMBER(v_LINE_ELEMENTS(21),c_NUM_FORMAT) END;
            v_TDIE_DUOS_INV_DTL_REC.POWER_FACTOR_SURCHARGE   := CASE WHEN INSTR(v_LINE_ELEMENTS(22),'-') > 0 THEN CONVERT_TO_NUMBER(v_LINE_ELEMENTS(22),c_MINUS_NUM_FORMAT) ELSE CONVERT_TO_NUMBER(v_LINE_ELEMENTS(22),c_NUM_FORMAT) END;
            v_TDIE_DUOS_INV_DTL_REC.NET_AMOUNT               := CASE WHEN INSTR(v_LINE_ELEMENTS(23),'-') > 0 THEN CONVERT_TO_NUMBER(v_LINE_ELEMENTS(23),c_MINUS_NUM_FORMAT) ELSE CONVERT_TO_NUMBER(v_LINE_ELEMENTS(23),c_NUM_FORMAT) END;
            v_TDIE_DUOS_INV_DTL_REC.GROSS_AMOUNT             := CASE WHEN INSTR(v_LINE_ELEMENTS(24),'-') > 0 THEN CONVERT_TO_NUMBER(v_LINE_ELEMENTS(24),c_MINUS_NUM_FORMAT) ELSE CONVERT_TO_NUMBER(v_LINE_ELEMENTS(24),c_NUM_FORMAT) END;

            INS_TDIE_DUOS_INVOICE_DETAIL(v_TDIE_DUOS_INV_DTL_REC);

         -- PROCESS Footer Record ----------------------------------------------
         WHEN v_LINE_ELEMENTS(1) = 3 THEN
            IF v_HEADER_REC_FOUND THEN
               v_FOOTER_REC_FOUND := TRUE;

               v_TDIE_DUOS_INV_REC.CONTROL_TOTAL             := CASE WHEN INSTR(v_LINE_ELEMENTS(3),'-') > 0 THEN CONVERT_TO_NUMBER(v_LINE_ELEMENTS(3),c_MINUS_NUM_FORMAT) ELSE CONVERT_TO_NUMBER(v_LINE_ELEMENTS(3),c_NUM_FORMAT) END;
               v_TDIE_DUOS_INV_REC.TOTAL_RECORDS             := CASE WHEN INSTR(v_LINE_ELEMENTS(2),'-') > 0 THEN CONVERT_TO_NUMBER(v_LINE_ELEMENTS(2),c_MINUS_NUM_FORMAT) ELSE CONVERT_TO_NUMBER(v_LINE_ELEMENTS(2),c_NUM_FORMAT) END;
               v_TDIE_DUOS_INV_REC.RECORDS_IMPORTED          := v_PROCESSED_REC_CNT;

               -- roll up the totals for NET and GROSS amounts
               BEGIN
                  SELECT SUM(TDID.NET_AMOUNT),
                         SUM(TDID.GROSS_AMOUNT)
                    INTO v_TDIE_DUOS_INV_REC.NET_CHARGE_AMT_IMPORTED,
                         v_TDIE_DUOS_INV_REC.GROSS_CHARGE_AMT_IMPORTED
                    FROM TDIE_DUOS_INVOICE_DETAIL TDID
                   WHERE TDID.INVOICE_NUMBER = v_TDIE_DUOS_INV_REC.INVOICE_NUMBER;

                  EXCEPTION
                     WHEN NO_DATA_FOUND THEN
                        v_TDIE_DUOS_INV_REC.NET_CHARGE_AMT_IMPORTED   := 0;
                        v_TDIE_DUOS_INV_REC.GROSS_CHARGE_AMT_IMPORTED := 0;
               END;

               -- Count the distinct number of MPRNs on this backing sheet.
               SELECT COUNT(a.MPRN)
                 INTO v_TDIE_DUOS_INV_REC.MPRN_COUNT
                 FROM (SELECT DISTINCT TDID.MPRN AS MPRN
                         FROM TDIE_DUOS_INVOICE_DETAIL TDID
                        WHERE TDID.INVOICE_NUMBER = v_TDIE_DUOS_INV_REC.INVOICE_NUMBER
                       ) a;

               UPD_TDIE_DUOS_INVOICE(v_TDIE_DUOS_INV_REC);
            ELSE
               v_FOOTER_REC_FOUND := FALSE;
            END IF;


         ELSE
            -- RAISE INVALID SEGMENT ERROR
            LOGS.LOG_WARN(p_EVENT_TEXT => 'Current record not associated with current invoice.');

      END CASE;--CASE v_LINE_ELEMENTS(1)

      i := i + 1;

   END LOOP;--WHILE i <= v_LINES.LAST LOOP

   IF v_LINE_ELEMENTS(1) >= 2 AND
      NOT v_FOOTER_REC_FOUND THEN
      ERRS.RAISE(p_MESSAGE_CODE => MSGCODES.c_ERR_INVALID_FILE_TYPE,
                 p_EXTRA_MESSAGE => 'The current backing sheet invoice is missing the footer record.');
   END IF;

END IMPORT_DUOS;
--------------------------------------------------------------------------------
-- This procedure will be responsible for processing the NI DUoS Backing Sheet CSV file
-- This procedure will use the PARSE_UTIL library to handle the CSV parsing.
PROCEDURE IMPORT_DUOS_NI (p_IMPORT_FILE IN CLOB)
IS
   c_PROCEDURE_NAME CONSTANT    VARCHAR(30) := 'IMPORT_DUOS_NI';
   i                            BINARY_INTEGER := 1;
   v_TDIE_DUOS_NI_INV_REC       TDIE_DUOS_NI_INVOICE%ROWTYPE;
   v_TDIE_DUOS_NI_INV_DTL_REC   TDIE_DUOS_NI_INVOICE_DETAIL%ROWTYPE;
   v_LINES                      PARSE_UTIL.BIG_STRING_TABLE_MP;
   v_LINE_ELEMENTS              PARSE_UTIL.STRING_TABLE;
   v_PROCESSED_REC_CNT          NUMBER;
   v_INV_MSG_TEXT               VARCHAR2(2000) := NULL;
BEGIN
   ASSERT(p_IMPORT_FILE IS NOT NULL, 'The import file must not be null.', MSGCODES.c_ERR_ARGUMENT);

	IF LOGS.IS_DEBUG_ENABLED THEN
      LOGS.LOG_DEBUG(g_PACKAGE_NAME||'.'||c_PROCEDURE_NAME);
	END IF;

   PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_IMPORT_FILE, v_LINES);

   i := v_LINES.FIRST;
   v_PROCESSED_REC_CNT := 0;
   WHILE i <= v_LINES.LAST LOOP
      PARSE_UTIL.PARSE_DELIMITED_STRING(v_LINES(i), ',', v_LINE_ELEMENTS);

      CASE
         -- PROCESS Header Record ----------------------------------------------
         WHEN i = v_LINES.FIRST AND v_LINE_ELEMENTS(1) = 1 AND NVL(v_TDIE_DUOS_NI_INV_REC.INVOICE_NUMBER, -1) <> v_LINE_ELEMENTS(2) THEN
              ASSERT(v_LINE_ELEMENTS.COUNT = 5 , 'Header row cannot be parsed as a Detail NI DUOS file.', MSGCODES.c_ERR_ARGUMENT);
              LOGS.LOG_INFO(p_EVENT_TEXT => 'Detail NI DUOS report assumed.');

               v_TDIE_DUOS_NI_INV_REC.INVOICE_NUMBER            := v_LINE_ELEMENTS(2);
               v_TDIE_DUOS_NI_INV_REC.PROVIDER                  := v_LINE_ELEMENTS(3);
               v_TDIE_DUOS_NI_INV_REC.SUPPLIER                  := v_LINE_ELEMENTS(4);
               v_TDIE_DUOS_NI_INV_REC.MARKET_TIMESTAMP          := CONVERT_TO_DATE(v_LINE_ELEMENTS(5), g_CSV_TIMESTAMP_FORMAT);
               v_TDIE_DUOS_NI_INV_REC.TOTAL_ITEMISED_LINES      := 0;
               v_TDIE_DUOS_NI_INV_REC.RECORDS_IMPORTED          := 0;
               v_TDIE_DUOS_NI_INV_REC.MPRN_COUNT                := 0;
               v_TDIE_DUOS_NI_INV_REC.IMPORTED_REVENUE          := 0;
               v_TDIE_DUOS_NI_INV_REC.REVENUE_EXCL_VAT          := 0;
               v_TDIE_DUOS_NI_INV_REC.REVENUE_INC_VAT           := 0;
               v_TDIE_DUOS_NI_INV_REC.IMPORT_TIMESTAMP          := g_IMPORT_TIMESTAMP;
               v_TDIE_DUOS_NI_INV_REC.FILE_NAME                 := g_IMPORT_FILE_PATH;
               v_TDIE_DUOS_NI_INV_REC.PROCESS_ID                := g_PROCESS_ID;
               v_TDIE_DUOS_NI_INV_REC.RETAIL_INVOICE_ID         := NULL;

               v_INV_MSG_TEXT := 'Invoice Number:   '||v_TDIE_DUOS_NI_INV_REC.INVOICE_NUMBER||g_CRLF||
                                 'Market Timestamp: '||TO_CHAR(v_TDIE_DUOS_NI_INV_REC.MARKET_TIMESTAMP,g_CSV_TIMESTAMP_FORMAT)||g_CRLF||
                                 'Provider:         '||v_TDIE_DUOS_NI_INV_REC.PROVIDER||g_CRLF||
                                 'Supplier:         '||v_TDIE_DUOS_NI_INV_REC.SUPPLIER||g_CRLF||
                                 'File Name:        '||v_TDIE_DUOS_NI_INV_REC.FILE_NAME||g_CRLF||
                                 'PROCESS_ID:       '||TO_CHAR(v_TDIE_DUOS_NI_INV_REC.PROCESS_ID)||g_CRLF;

               LOGS.LOG_INFO(p_EVENT_TEXT => v_INV_MSG_TEXT);

               DEL_TDIE_DUOS_NI_INVOICE(v_TDIE_DUOS_NI_INV_REC);
               INS_TDIE_DUOS_NI_INVOICE(v_TDIE_DUOS_NI_INV_REC);

         -- PROCESS Detail Record ----------------------------------------------
         WHEN v_LINE_ELEMENTS(1) = 2 AND v_LINE_ELEMENTS(2) = v_TDIE_DUOS_NI_INV_REC.INVOICE_NUMBER THEN

            v_PROCESSED_REC_CNT := v_PROCESSED_REC_CNT + 1;

            v_TDIE_DUOS_NI_INV_DTL_REC.INVOICE_NUMBER           := v_LINE_ELEMENTS(2);
            v_TDIE_DUOS_NI_INV_DTL_REC.ITEM_NUMBER              := CONVERT_TO_NUMBER(v_LINE_ELEMENTS(3));
            v_TDIE_DUOS_NI_INV_DTL_REC.POD_ID                   := v_LINE_ELEMENTS(4);
            v_TDIE_DUOS_NI_INV_DTL_REC.ADJUST_REF               := CONVERT_TO_NUMBER(v_LINE_ELEMENTS(5));
            v_TDIE_DUOS_NI_INV_DTL_REC.INVOICE_TYPE             := v_LINE_ELEMENTS(6);
            v_TDIE_DUOS_NI_INV_DTL_REC.DUOS_GROUP               := v_LINE_ELEMENTS(7);
            v_TDIE_DUOS_NI_INV_DTL_REC.BILLING_BEGIN_DATE       := CONVERT_TO_DATE(v_LINE_ELEMENTS(8), g_CSV_DATE_FORMAT);
            v_TDIE_DUOS_NI_INV_DTL_REC.BILLING_END_DATE         := CONVERT_TO_DATE(v_LINE_ELEMENTS(9), g_CSV_DATE_FORMAT);
            v_TDIE_DUOS_NI_INV_DTL_REC.RATE_CATEGORY            := v_LINE_ELEMENTS(10);
            v_TDIE_DUOS_NI_INV_DTL_REC.STAND_CHARGE             := CASE WHEN INSTR(v_LINE_ELEMENTS(11),'-') > 0 THEN CONVERT_TO_NUMBER(v_LINE_ELEMENTS(11),c_MINUS_NUM_FORMAT) ELSE CONVERT_TO_NUMBER(v_LINE_ELEMENTS(11),c_NUM_FORMAT) END;
            v_TDIE_DUOS_NI_INV_DTL_REC.UNR_VOLUME               := CASE WHEN INSTR(v_LINE_ELEMENTS(12),'-') > 0 THEN CONVERT_TO_NUMBER(v_LINE_ELEMENTS(12),c_MINUS_NUM_FORMAT) ELSE CONVERT_TO_NUMBER(v_LINE_ELEMENTS(12),c_NUM_FORMAT) END;
            v_TDIE_DUOS_NI_INV_DTL_REC.UNR_CHARGE               := CASE WHEN INSTR(v_LINE_ELEMENTS(13),'-') > 0 THEN CONVERT_TO_NUMBER(v_LINE_ELEMENTS(13),c_MINUS_NUM_FORMAT) ELSE CONVERT_TO_NUMBER(v_LINE_ELEMENTS(13),c_NUM_FORMAT) END;
            v_TDIE_DUOS_NI_INV_DTL_REC.D01_VOLUME               := CASE WHEN INSTR(v_LINE_ELEMENTS(14),'-') > 0 THEN CONVERT_TO_NUMBER(v_LINE_ELEMENTS(14),c_MINUS_NUM_FORMAT) ELSE CONVERT_TO_NUMBER(v_LINE_ELEMENTS(14),c_NUM_FORMAT) END;
            v_TDIE_DUOS_NI_INV_DTL_REC.D01_CHARGE               := CASE WHEN INSTR(v_LINE_ELEMENTS(15),'-') > 0 THEN CONVERT_TO_NUMBER(v_LINE_ELEMENTS(15),c_MINUS_NUM_FORMAT) ELSE CONVERT_TO_NUMBER(v_LINE_ELEMENTS(15),c_NUM_FORMAT) END;
            v_TDIE_DUOS_NI_INV_DTL_REC.N01_VOLUME               := CASE WHEN INSTR(v_LINE_ELEMENTS(16),'-') > 0 THEN CONVERT_TO_NUMBER(v_LINE_ELEMENTS(16),c_MINUS_NUM_FORMAT) ELSE CONVERT_TO_NUMBER(v_LINE_ELEMENTS(16),c_NUM_FORMAT) END;
            v_TDIE_DUOS_NI_INV_DTL_REC.N01_CHARGE               := CASE WHEN INSTR(v_LINE_ELEMENTS(17),'-') > 0 THEN CONVERT_TO_NUMBER(v_LINE_ELEMENTS(17),c_MINUS_NUM_FORMAT) ELSE CONVERT_TO_NUMBER(v_LINE_ELEMENTS(17),c_NUM_FORMAT) END;
            v_TDIE_DUOS_NI_INV_DTL_REC.D02_VOLUME               := CASE WHEN INSTR(v_LINE_ELEMENTS(18),'-') > 0 THEN CONVERT_TO_NUMBER(v_LINE_ELEMENTS(18),c_MINUS_NUM_FORMAT) ELSE CONVERT_TO_NUMBER(v_LINE_ELEMENTS(18),c_NUM_FORMAT) END;
            v_TDIE_DUOS_NI_INV_DTL_REC.D02_CHARGE               := CASE WHEN INSTR(v_LINE_ELEMENTS(19),'-') > 0 THEN CONVERT_TO_NUMBER(v_LINE_ELEMENTS(19),c_MINUS_NUM_FORMAT) ELSE CONVERT_TO_NUMBER(v_LINE_ELEMENTS(19),c_NUM_FORMAT) END;
            v_TDIE_DUOS_NI_INV_DTL_REC.N02_VOLUME               := CASE WHEN INSTR(v_LINE_ELEMENTS(20),'-') > 0 THEN CONVERT_TO_NUMBER(v_LINE_ELEMENTS(20),c_MINUS_NUM_FORMAT) ELSE CONVERT_TO_NUMBER(v_LINE_ELEMENTS(20),c_NUM_FORMAT) END;
            v_TDIE_DUOS_NI_INV_DTL_REC.N02_CHARGE               := CASE WHEN INSTR(v_LINE_ELEMENTS(21),'-') > 0 THEN CONVERT_TO_NUMBER(v_LINE_ELEMENTS(21),c_MINUS_NUM_FORMAT) ELSE CONVERT_TO_NUMBER(v_LINE_ELEMENTS(21),c_NUM_FORMAT) END;
            v_TDIE_DUOS_NI_INV_DTL_REC.N03_VOLUME               := CASE WHEN INSTR(v_LINE_ELEMENTS(22),'-') > 0 THEN CONVERT_TO_NUMBER(v_LINE_ELEMENTS(22),c_MINUS_NUM_FORMAT) ELSE CONVERT_TO_NUMBER(v_LINE_ELEMENTS(22),c_NUM_FORMAT) END;
            v_TDIE_DUOS_NI_INV_DTL_REC.N03_CHARGE                := CASE WHEN INSTR(v_LINE_ELEMENTS(23),'-') > 0 THEN CONVERT_TO_NUMBER(v_LINE_ELEMENTS(23),c_MINUS_NUM_FORMAT) ELSE CONVERT_TO_NUMBER(v_LINE_ELEMENTS(23),c_NUM_FORMAT) END;
            v_TDIE_DUOS_NI_INV_DTL_REC.N04_VOLUME               := CASE WHEN INSTR(v_LINE_ELEMENTS(24),'-') > 0 THEN CONVERT_TO_NUMBER(v_LINE_ELEMENTS(24),c_MINUS_NUM_FORMAT) ELSE CONVERT_TO_NUMBER(v_LINE_ELEMENTS(24),c_NUM_FORMAT) END;
            v_TDIE_DUOS_NI_INV_DTL_REC.N04_CHARGE               := CASE WHEN INSTR(v_LINE_ELEMENTS(25),'-') > 0 THEN CONVERT_TO_NUMBER(v_LINE_ELEMENTS(25),c_MINUS_NUM_FORMAT) ELSE CONVERT_TO_NUMBER(v_LINE_ELEMENTS(25),c_NUM_FORMAT) END;
            v_TDIE_DUOS_NI_INV_DTL_REC.HT1_VOLUME               := CASE WHEN INSTR(v_LINE_ELEMENTS(26),'-') > 0 THEN CONVERT_TO_NUMBER(v_LINE_ELEMENTS(26),c_MINUS_NUM_FORMAT) ELSE CONVERT_TO_NUMBER(v_LINE_ELEMENTS(26),c_NUM_FORMAT) END;
            v_TDIE_DUOS_NI_INV_DTL_REC.HT1_CHARGE               := CASE WHEN INSTR(v_LINE_ELEMENTS(27),'-') > 0 THEN CONVERT_TO_NUMBER(v_LINE_ELEMENTS(27),c_MINUS_NUM_FORMAT) ELSE CONVERT_TO_NUMBER(v_LINE_ELEMENTS(27),c_NUM_FORMAT) END;
            v_TDIE_DUOS_NI_INV_DTL_REC.HT2_VOLUME               := CASE WHEN INSTR(v_LINE_ELEMENTS(28),'-') > 0 THEN CONVERT_TO_NUMBER(v_LINE_ELEMENTS(28),c_MINUS_NUM_FORMAT) ELSE CONVERT_TO_NUMBER(v_LINE_ELEMENTS(28),c_NUM_FORMAT) END;
            v_TDIE_DUOS_NI_INV_DTL_REC.HT2_CHARGE               := CASE WHEN INSTR(v_LINE_ELEMENTS(29),'-') > 0 THEN CONVERT_TO_NUMBER(v_LINE_ELEMENTS(29),c_MINUS_NUM_FORMAT) ELSE CONVERT_TO_NUMBER(v_LINE_ELEMENTS(29),c_NUM_FORMAT) END;
            v_TDIE_DUOS_NI_INV_DTL_REC.HT3_VOLUME               := CASE WHEN INSTR(v_LINE_ELEMENTS(30),'-') > 0 THEN CONVERT_TO_NUMBER(v_LINE_ELEMENTS(30),c_MINUS_NUM_FORMAT) ELSE CONVERT_TO_NUMBER(v_LINE_ELEMENTS(30),c_NUM_FORMAT) END;
            v_TDIE_DUOS_NI_INV_DTL_REC.HT3_CHARGE               := CASE WHEN INSTR(v_LINE_ELEMENTS(31),'-') > 0 THEN CONVERT_TO_NUMBER(v_LINE_ELEMENTS(31),c_MINUS_NUM_FORMAT) ELSE CONVERT_TO_NUMBER(v_LINE_ELEMENTS(31),c_NUM_FORMAT) END;
            v_TDIE_DUOS_NI_INV_DTL_REC.W1_VOLUME                := CASE WHEN INSTR(v_LINE_ELEMENTS(32),'-') > 0 THEN CONVERT_TO_NUMBER(v_LINE_ELEMENTS(32),c_MINUS_NUM_FORMAT) ELSE CONVERT_TO_NUMBER(v_LINE_ELEMENTS(32),c_NUM_FORMAT) END;
            v_TDIE_DUOS_NI_INV_DTL_REC.W1_CHARGE                := CASE WHEN INSTR(v_LINE_ELEMENTS(33),'-') > 0 THEN CONVERT_TO_NUMBER(v_LINE_ELEMENTS(33),c_MINUS_NUM_FORMAT) ELSE CONVERT_TO_NUMBER(v_LINE_ELEMENTS(33),c_NUM_FORMAT) END;
            v_TDIE_DUOS_NI_INV_DTL_REC.W2_VOLUME                := CASE WHEN INSTR(v_LINE_ELEMENTS(34),'-') > 0 THEN CONVERT_TO_NUMBER(v_LINE_ELEMENTS(34),c_MINUS_NUM_FORMAT) ELSE CONVERT_TO_NUMBER(v_LINE_ELEMENTS(34),c_NUM_FORMAT) END;
            v_TDIE_DUOS_NI_INV_DTL_REC.W2_CHARGE                := CASE WHEN INSTR(v_LINE_ELEMENTS(35),'-') > 0 THEN CONVERT_TO_NUMBER(v_LINE_ELEMENTS(35),c_MINUS_NUM_FORMAT) ELSE CONVERT_TO_NUMBER(v_LINE_ELEMENTS(35),c_NUM_FORMAT) END;
            v_TDIE_DUOS_NI_INV_DTL_REC.FR1_VOLUME               := CASE WHEN INSTR(v_LINE_ELEMENTS(36),'-') > 0 THEN CONVERT_TO_NUMBER(v_LINE_ELEMENTS(36),c_MINUS_NUM_FORMAT) ELSE CONVERT_TO_NUMBER(v_LINE_ELEMENTS(36),c_NUM_FORMAT) END;
            v_TDIE_DUOS_NI_INV_DTL_REC.FR1_CHARGE               := CASE WHEN INSTR(v_LINE_ELEMENTS(37),'-') > 0 THEN CONVERT_TO_NUMBER(v_LINE_ELEMENTS(37),c_MINUS_NUM_FORMAT) ELSE CONVERT_TO_NUMBER(v_LINE_ELEMENTS(37),c_NUM_FORMAT) END;
            v_TDIE_DUOS_NI_INV_DTL_REC.FR2_VOLUME               := CASE WHEN INSTR(v_LINE_ELEMENTS(38),'-') > 0 THEN CONVERT_TO_NUMBER(v_LINE_ELEMENTS(38),c_MINUS_NUM_FORMAT) ELSE CONVERT_TO_NUMBER(v_LINE_ELEMENTS(38),c_NUM_FORMAT) END;
            v_TDIE_DUOS_NI_INV_DTL_REC.FR2_CHARGE               := CASE WHEN INSTR(v_LINE_ELEMENTS(39),'-') > 0 THEN CONVERT_TO_NUMBER(v_LINE_ELEMENTS(39),c_MINUS_NUM_FORMAT) ELSE CONVERT_TO_NUMBER(v_LINE_ELEMENTS(39),c_NUM_FORMAT) END;
            v_TDIE_DUOS_NI_INV_DTL_REC.FR3_VOLUME               := CASE WHEN INSTR(v_LINE_ELEMENTS(40),'-') > 0 THEN CONVERT_TO_NUMBER(v_LINE_ELEMENTS(40),c_MINUS_NUM_FORMAT) ELSE CONVERT_TO_NUMBER(v_LINE_ELEMENTS(40),c_NUM_FORMAT) END;
            v_TDIE_DUOS_NI_INV_DTL_REC.FR3_CHARGE               := CASE WHEN INSTR(v_LINE_ELEMENTS(41),'-') > 0 THEN CONVERT_TO_NUMBER(v_LINE_ELEMENTS(41),c_MINUS_NUM_FORMAT) ELSE CONVERT_TO_NUMBER(v_LINE_ELEMENTS(41),c_NUM_FORMAT) END;
            v_TDIE_DUOS_NI_INV_DTL_REC.FR4_VOLUME               := CASE WHEN INSTR(v_LINE_ELEMENTS(42),'-') > 0 THEN CONVERT_TO_NUMBER(v_LINE_ELEMENTS(42),c_MINUS_NUM_FORMAT) ELSE CONVERT_TO_NUMBER(v_LINE_ELEMENTS(42),c_NUM_FORMAT) END;
            v_TDIE_DUOS_NI_INV_DTL_REC.FR4_CHARGE               := CASE WHEN INSTR(v_LINE_ELEMENTS(43),'-') > 0 THEN CONVERT_TO_NUMBER(v_LINE_ELEMENTS(43),c_MINUS_NUM_FORMAT) ELSE CONVERT_TO_NUMBER(v_LINE_ELEMENTS(43),c_NUM_FORMAT) END;
            v_TDIE_DUOS_NI_INV_DTL_REC.KP5_VOLUME               := CASE WHEN INSTR(v_LINE_ELEMENTS(44),'-') > 0 THEN CONVERT_TO_NUMBER(v_LINE_ELEMENTS(44),c_MINUS_NUM_FORMAT) ELSE CONVERT_TO_NUMBER(v_LINE_ELEMENTS(44),c_NUM_FORMAT) END;
            v_TDIE_DUOS_NI_INV_DTL_REC.KP5_CHARGE               := CASE WHEN INSTR(v_LINE_ELEMENTS(45),'-') > 0 THEN CONVERT_TO_NUMBER(v_LINE_ELEMENTS(45),c_MINUS_NUM_FORMAT) ELSE CONVERT_TO_NUMBER(v_LINE_ELEMENTS(45),c_NUM_FORMAT) END;
            v_TDIE_DUOS_NI_INV_DTL_REC.KP6_VOLUME               := CASE WHEN INSTR(v_LINE_ELEMENTS(46),'-') > 0 THEN CONVERT_TO_NUMBER(v_LINE_ELEMENTS(46),c_MINUS_NUM_FORMAT) ELSE CONVERT_TO_NUMBER(v_LINE_ELEMENTS(46),c_NUM_FORMAT) END;
            v_TDIE_DUOS_NI_INV_DTL_REC.KP6_CHARGE               := CASE WHEN INSTR(v_LINE_ELEMENTS(47),'-') > 0 THEN CONVERT_TO_NUMBER(v_LINE_ELEMENTS(47),c_MINUS_NUM_FORMAT) ELSE CONVERT_TO_NUMBER(v_LINE_ELEMENTS(47),c_NUM_FORMAT) END;
            v_TDIE_DUOS_NI_INV_DTL_REC.KP7_VOLUME               := CASE WHEN INSTR(v_LINE_ELEMENTS(48),'-') > 0 THEN CONVERT_TO_NUMBER(v_LINE_ELEMENTS(48),c_MINUS_NUM_FORMAT) ELSE CONVERT_TO_NUMBER(v_LINE_ELEMENTS(48),c_NUM_FORMAT) END;
            v_TDIE_DUOS_NI_INV_DTL_REC.KP7_CHARGE               := CASE WHEN INSTR(v_LINE_ELEMENTS(49),'-') > 0 THEN CONVERT_TO_NUMBER(v_LINE_ELEMENTS(49),c_MINUS_NUM_FORMAT) ELSE CONVERT_TO_NUMBER(v_LINE_ELEMENTS(49),c_NUM_FORMAT) END;
            v_TDIE_DUOS_NI_INV_DTL_REC.KP8_VOLUME               := CASE WHEN INSTR(v_LINE_ELEMENTS(50),'-') > 0 THEN CONVERT_TO_NUMBER(v_LINE_ELEMENTS(50),c_MINUS_NUM_FORMAT) ELSE CONVERT_TO_NUMBER(v_LINE_ELEMENTS(50),c_NUM_FORMAT) END;
            v_TDIE_DUOS_NI_INV_DTL_REC.KP8_CHARGE               := CASE WHEN INSTR(v_LINE_ELEMENTS(51),'-') > 0 THEN CONVERT_TO_NUMBER(v_LINE_ELEMENTS(51),c_MINUS_NUM_FORMAT) ELSE CONVERT_TO_NUMBER(v_LINE_ELEMENTS(51),c_NUM_FORMAT) END;
            v_TDIE_DUOS_NI_INV_DTL_REC.R21_VOLUME               := CASE WHEN INSTR(v_LINE_ELEMENTS(52),'-') > 0 THEN CONVERT_TO_NUMBER(v_LINE_ELEMENTS(52),c_MINUS_NUM_FORMAT) ELSE CONVERT_TO_NUMBER(v_LINE_ELEMENTS(52),c_NUM_FORMAT) END;
            v_TDIE_DUOS_NI_INV_DTL_REC.R21_CHARGE               := CASE WHEN INSTR(v_LINE_ELEMENTS(53),'-') > 0 THEN CONVERT_TO_NUMBER(v_LINE_ELEMENTS(53),c_MINUS_NUM_FORMAT) ELSE CONVERT_TO_NUMBER(v_LINE_ELEMENTS(53),c_NUM_FORMAT) END;
            v_TDIE_DUOS_NI_INV_DTL_REC.R22_VOLUME               := CASE WHEN INSTR(v_LINE_ELEMENTS(54),'-') > 0 THEN CONVERT_TO_NUMBER(v_LINE_ELEMENTS(54),c_MINUS_NUM_FORMAT) ELSE CONVERT_TO_NUMBER(v_LINE_ELEMENTS(54),c_NUM_FORMAT) END;
            v_TDIE_DUOS_NI_INV_DTL_REC.R22_CHARGE               := CASE WHEN INSTR(v_LINE_ELEMENTS(55),'-') > 0 THEN CONVERT_TO_NUMBER(v_LINE_ELEMENTS(55),c_MINUS_NUM_FORMAT) ELSE CONVERT_TO_NUMBER(v_LINE_ELEMENTS(55),c_NUM_FORMAT) END;
            v_TDIE_DUOS_NI_INV_DTL_REC.R23_VOLUME               := CASE WHEN INSTR(v_LINE_ELEMENTS(56),'-') > 0 THEN CONVERT_TO_NUMBER(v_LINE_ELEMENTS(56),c_MINUS_NUM_FORMAT) ELSE CONVERT_TO_NUMBER(v_LINE_ELEMENTS(56),c_NUM_FORMAT) END;
            v_TDIE_DUOS_NI_INV_DTL_REC.R23_CHARGE               := CASE WHEN INSTR(v_LINE_ELEMENTS(57),'-') > 0 THEN CONVERT_TO_NUMBER(v_LINE_ELEMENTS(57),c_MINUS_NUM_FORMAT) ELSE CONVERT_TO_NUMBER(v_LINE_ELEMENTS(57),c_NUM_FORMAT) END;
            v_TDIE_DUOS_NI_INV_DTL_REC.R24_VOLUME               := CASE WHEN INSTR(v_LINE_ELEMENTS(58),'-') > 0 THEN CONVERT_TO_NUMBER(v_LINE_ELEMENTS(58),c_MINUS_NUM_FORMAT) ELSE CONVERT_TO_NUMBER(v_LINE_ELEMENTS(58),c_NUM_FORMAT) END;
            v_TDIE_DUOS_NI_INV_DTL_REC.R24_CHARGE               := CASE WHEN INSTR(v_LINE_ELEMENTS(59),'-') > 0 THEN CONVERT_TO_NUMBER(v_LINE_ELEMENTS(59),c_MINUS_NUM_FORMAT) ELSE CONVERT_TO_NUMBER(v_LINE_ELEMENTS(59),c_NUM_FORMAT) END;
            v_TDIE_DUOS_NI_INV_DTL_REC.R25_VOLUME               := CASE WHEN INSTR(v_LINE_ELEMENTS(60),'-') > 0 THEN CONVERT_TO_NUMBER(v_LINE_ELEMENTS(60),c_MINUS_NUM_FORMAT) ELSE CONVERT_TO_NUMBER(v_LINE_ELEMENTS(60),c_NUM_FORMAT) END;
            v_TDIE_DUOS_NI_INV_DTL_REC.R25_CHARGE               := CASE WHEN INSTR(v_LINE_ELEMENTS(61),'-') > 0 THEN CONVERT_TO_NUMBER(v_LINE_ELEMENTS(61),c_MINUS_NUM_FORMAT) ELSE CONVERT_TO_NUMBER(v_LINE_ELEMENTS(61),c_NUM_FORMAT) END;
            v_TDIE_DUOS_NI_INV_DTL_REC.UNMTRD_VOLUME            := CASE WHEN INSTR(v_LINE_ELEMENTS(62),'-') > 0 THEN CONVERT_TO_NUMBER(v_LINE_ELEMENTS(62),c_MINUS_NUM_FORMAT) ELSE CONVERT_TO_NUMBER(v_LINE_ELEMENTS(62),c_NUM_FORMAT) END;
            v_TDIE_DUOS_NI_INV_DTL_REC.UNMTRD_CHARGE            := CASE WHEN INSTR(v_LINE_ELEMENTS(63),'-') > 0 THEN CONVERT_TO_NUMBER(v_LINE_ELEMENTS(63),c_MINUS_NUM_FORMAT) ELSE CONVERT_TO_NUMBER(v_LINE_ELEMENTS(63),c_NUM_FORMAT) END;
            v_TDIE_DUOS_NI_INV_DTL_REC.SMO_VOLUME               := CASE WHEN INSTR(v_LINE_ELEMENTS(64),'-') > 0 THEN CONVERT_TO_NUMBER(v_LINE_ELEMENTS(64),c_MINUS_NUM_FORMAT) ELSE CONVERT_TO_NUMBER(v_LINE_ELEMENTS(64),c_NUM_FORMAT) END;
            v_TDIE_DUOS_NI_INV_DTL_REC.SMO_CHARGE               := CASE WHEN INSTR(v_LINE_ELEMENTS(65),'-') > 0 THEN CONVERT_TO_NUMBER(v_LINE_ELEMENTS(65),c_MINUS_NUM_FORMAT) ELSE CONVERT_TO_NUMBER(v_LINE_ELEMENTS(65),c_NUM_FORMAT) END;
            v_TDIE_DUOS_NI_INV_DTL_REC.NFD_VOLUME               := CASE WHEN INSTR(v_LINE_ELEMENTS(66),'-') > 0 THEN CONVERT_TO_NUMBER(v_LINE_ELEMENTS(66),c_MINUS_NUM_FORMAT) ELSE CONVERT_TO_NUMBER(v_LINE_ELEMENTS(66),c_NUM_FORMAT) END;
            v_TDIE_DUOS_NI_INV_DTL_REC.NFD_CHARGE               := CASE WHEN INSTR(v_LINE_ELEMENTS(67),'-') > 0 THEN CONVERT_TO_NUMBER(v_LINE_ELEMENTS(67),c_MINUS_NUM_FORMAT) ELSE CONVERT_TO_NUMBER(v_LINE_ELEMENTS(67),c_NUM_FORMAT) END;
            v_TDIE_DUOS_NI_INV_DTL_REC.DJD_VOLUME               := CASE WHEN INSTR(v_LINE_ELEMENTS(68),'-') > 0 THEN CONVERT_TO_NUMBER(v_LINE_ELEMENTS(68),c_MINUS_NUM_FORMAT) ELSE CONVERT_TO_NUMBER(v_LINE_ELEMENTS(68),c_NUM_FORMAT) END;
            v_TDIE_DUOS_NI_INV_DTL_REC.DJD_CHARGE               := CASE WHEN INSTR(v_LINE_ELEMENTS(69),'-') > 0 THEN CONVERT_TO_NUMBER(v_LINE_ELEMENTS(69),c_MINUS_NUM_FORMAT) ELSE CONVERT_TO_NUMBER(v_LINE_ELEMENTS(69),c_NUM_FORMAT) END;
            v_TDIE_DUOS_NI_INV_DTL_REC.NKP_VOLUME               := CASE WHEN INSTR(v_LINE_ELEMENTS(70),'-') > 0 THEN CONVERT_TO_NUMBER(v_LINE_ELEMENTS(70),c_MINUS_NUM_FORMAT) ELSE CONVERT_TO_NUMBER(v_LINE_ELEMENTS(70),c_NUM_FORMAT) END;
            v_TDIE_DUOS_NI_INV_DTL_REC.NKP_CHARGE               := CASE WHEN INSTR(v_LINE_ELEMENTS(71),'-') > 0 THEN CONVERT_TO_NUMBER(v_LINE_ELEMENTS(71),c_MINUS_NUM_FORMAT) ELSE CONVERT_TO_NUMBER(v_LINE_ELEMENTS(71),c_NUM_FORMAT) END;
            v_TDIE_DUOS_NI_INV_DTL_REC.DJPK_VOLUME              := CASE WHEN INSTR(v_LINE_ELEMENTS(72),'-') > 0 THEN CONVERT_TO_NUMBER(v_LINE_ELEMENTS(72),c_MINUS_NUM_FORMAT) ELSE CONVERT_TO_NUMBER(v_LINE_ELEMENTS(72),c_NUM_FORMAT) END;
            v_TDIE_DUOS_NI_INV_DTL_REC.DJPK_CHARGE              := CASE WHEN INSTR(v_LINE_ELEMENTS(73),'-') > 0 THEN CONVERT_TO_NUMBER(v_LINE_ELEMENTS(73),c_MINUS_NUM_FORMAT) ELSE CONVERT_TO_NUMBER(v_LINE_ELEMENTS(73),c_NUM_FORMAT) END;
            v_TDIE_DUOS_NI_INV_DTL_REC.EW_VOLUME                := CASE WHEN INSTR(v_LINE_ELEMENTS(74),'-') > 0 THEN CONVERT_TO_NUMBER(v_LINE_ELEMENTS(74),c_MINUS_NUM_FORMAT) ELSE CONVERT_TO_NUMBER(v_LINE_ELEMENTS(74),c_NUM_FORMAT) END;
            v_TDIE_DUOS_NI_INV_DTL_REC.EW_CHARGE                := CASE WHEN INSTR(v_LINE_ELEMENTS(75),'-') > 0 THEN CONVERT_TO_NUMBER(v_LINE_ELEMENTS(75),c_MINUS_NUM_FORMAT) ELSE CONVERT_TO_NUMBER(v_LINE_ELEMENTS(75),c_NUM_FORMAT) END;
            v_TDIE_DUOS_NI_INV_DTL_REC.NT_VOLUME                := CASE WHEN INSTR(v_LINE_ELEMENTS(76),'-') > 0 THEN CONVERT_TO_NUMBER(v_LINE_ELEMENTS(76),c_MINUS_NUM_FORMAT) ELSE CONVERT_TO_NUMBER(v_LINE_ELEMENTS(76),c_NUM_FORMAT) END;
            v_TDIE_DUOS_NI_INV_DTL_REC.NT_CHARGE                := CASE WHEN INSTR(v_LINE_ELEMENTS(77),'-') > 0 THEN CONVERT_TO_NUMBER(v_LINE_ELEMENTS(77),c_MINUS_NUM_FORMAT) ELSE CONVERT_TO_NUMBER(v_LINE_ELEMENTS(77),c_NUM_FORMAT) END;
            v_TDIE_DUOS_NI_INV_DTL_REC.RPC_VOLUME               := CASE WHEN INSTR(v_LINE_ELEMENTS(78),'-') > 0 THEN CONVERT_TO_NUMBER(v_LINE_ELEMENTS(78),c_MINUS_NUM_FORMAT) ELSE CONVERT_TO_NUMBER(v_LINE_ELEMENTS(78),c_NUM_FORMAT) END;
            v_TDIE_DUOS_NI_INV_DTL_REC.RPC_CHARGE               := CASE WHEN INSTR(v_LINE_ELEMENTS(79),'-') > 0 THEN CONVERT_TO_NUMBER(v_LINE_ELEMENTS(79),c_MINUS_NUM_FORMAT) ELSE CONVERT_TO_NUMBER(v_LINE_ELEMENTS(79),c_NUM_FORMAT) END;
            v_TDIE_DUOS_NI_INV_DTL_REC.CSC_VOLUME               := CASE WHEN INSTR(v_LINE_ELEMENTS(80),'-') > 0 THEN CONVERT_TO_NUMBER(v_LINE_ELEMENTS(80),c_MINUS_NUM_FORMAT) ELSE CONVERT_TO_NUMBER(v_LINE_ELEMENTS(80),c_NUM_FORMAT) END;
            v_TDIE_DUOS_NI_INV_DTL_REC.CSC_CHARGE               := CASE WHEN INSTR(v_LINE_ELEMENTS(81),'-') > 0 THEN CONVERT_TO_NUMBER(v_LINE_ELEMENTS(81),c_MINUS_NUM_FORMAT) ELSE CONVERT_TO_NUMBER(v_LINE_ELEMENTS(81),c_NUM_FORMAT) END;
            v_TDIE_DUOS_NI_INV_DTL_REC.MIC_VOLUME               := CASE WHEN INSTR(v_LINE_ELEMENTS(82),'-') > 0 THEN CONVERT_TO_NUMBER(v_LINE_ELEMENTS(82),c_MINUS_NUM_FORMAT) ELSE CONVERT_TO_NUMBER(v_LINE_ELEMENTS(82),c_NUM_FORMAT) END;
            v_TDIE_DUOS_NI_INV_DTL_REC.MIC_CHARGE               := CASE WHEN INSTR(v_LINE_ELEMENTS(83),'-') > 0 THEN CONVERT_TO_NUMBER(v_LINE_ELEMENTS(83),c_MINUS_NUM_FORMAT) ELSE CONVERT_TO_NUMBER(v_LINE_ELEMENTS(83),c_NUM_FORMAT) END;
            v_TDIE_DUOS_NI_INV_DTL_REC.R26_VOLUME               := CASE WHEN INSTR(v_LINE_ELEMENTS(84),'-') > 0 THEN CONVERT_TO_NUMBER(v_LINE_ELEMENTS(84),c_MINUS_NUM_FORMAT) ELSE CONVERT_TO_NUMBER(v_LINE_ELEMENTS(84),c_NUM_FORMAT) END;
            v_TDIE_DUOS_NI_INV_DTL_REC.R26_CHARGE               := CASE WHEN INSTR(v_LINE_ELEMENTS(85),'-') > 0 THEN CONVERT_TO_NUMBER(v_LINE_ELEMENTS(85),c_MINUS_NUM_FORMAT) ELSE CONVERT_TO_NUMBER(v_LINE_ELEMENTS(85),c_NUM_FORMAT) END;
            v_TDIE_DUOS_NI_INV_DTL_REC.TOTAL_REVENUE            := CASE WHEN INSTR(v_LINE_ELEMENTS(86),'-') > 0 THEN CONVERT_TO_NUMBER(v_LINE_ELEMENTS(86),c_MINUS_NUM_FORMAT) ELSE CONVERT_TO_NUMBER(v_LINE_ELEMENTS(86),c_NUM_FORMAT) END;
            v_TDIE_DUOS_NI_INV_DTL_REC.REVENUE_INC_VAT          := CASE WHEN INSTR(v_LINE_ELEMENTS(87),'-') > 0 THEN CONVERT_TO_NUMBER(v_LINE_ELEMENTS(87),c_MINUS_NUM_FORMAT) ELSE CONVERT_TO_NUMBER(v_LINE_ELEMENTS(87),c_NUM_FORMAT) END;



           INS_TDIE_DUOS_NI_INVOICE_DTL(v_TDIE_DUOS_NI_INV_DTL_REC);

         -- PROCESS Footer Record ----------------------------------------------
         WHEN v_LINE_ELEMENTS(1) = 3 THEN
               v_TDIE_DUOS_NI_INV_REC.REVENUE_EXCL_VAT             := CASE WHEN INSTR(v_LINE_ELEMENTS(3),'-') > 0 THEN CONVERT_TO_NUMBER(v_LINE_ELEMENTS(3),c_MINUS_NUM_FORMAT) ELSE CONVERT_TO_NUMBER(v_LINE_ELEMENTS(3),c_NUM_FORMAT) END;
               v_TDIE_DUOS_NI_INV_REC.TOTAL_ITEMISED_LINES         := CASE WHEN INSTR(v_LINE_ELEMENTS(2),'-') > 0 THEN CONVERT_TO_NUMBER(v_LINE_ELEMENTS(2),c_MINUS_NUM_FORMAT) ELSE CONVERT_TO_NUMBER(v_LINE_ELEMENTS(2),c_NUM_FORMAT) END;
               v_TDIE_DUOS_NI_INV_REC.RECORDS_IMPORTED             := v_PROCESSED_REC_CNT;

            -- roll up the total for REVENUE_INC_VAT
            BEGIN
               SELECT NVL(SUM(NVL(NDI.REVENUE_INC_VAT,0)),0)
                 INTO v_TDIE_DUOS_NI_INV_REC.REVENUE_INC_VAT
                 FROM TDIE_DUOS_NI_INVOICE_DETAIL NDI
                WHERE NDI.INVOICE_NUMBER = v_TDIE_DUOS_NI_INV_REC.INVOICE_NUMBER;

            EXCEPTION
                  WHEN NO_DATA_FOUND THEN
                     v_TDIE_DUOS_NI_INV_REC.REVENUE_INC_VAT := 0;
            END;
            -- roll up the total CHARGES
            BEGIN
               SELECT NVL(SUM(NVL(NDI.STAND_CHARGE,0)),0)+
                      NVL(SUM(NVL(NDI.UNR_CHARGE,0)),0)+
                      NVL(SUM(NVL(NDI.D01_CHARGE,0)),0)+
                      NVL(SUM(NVL(NDI.N01_CHARGE,0)),0)+
                      NVL(SUM(NVL(NDI.D02_CHARGE,0)),0)+
                      NVL(SUM(NVL(NDI.N02_CHARGE,0)),0)+
                      NVL(SUM(NVL(NDI.N03_CHARGE,0)),0)+
                      NVL(SUM(NVL(NDI.N04_CHARGE,0)),0)+
                      NVL(SUM(NVL(NDI.HT1_CHARGE,0)),0)+
                      NVL(SUM(NVL(NDI.HT2_CHARGE,0)),0)+
                      NVL(SUM(NVL(NDI.HT3_CHARGE,0)),0)+
                      NVL(SUM(NVL(NDI.W1_CHARGE,0)),0)+
                      NVL(SUM(NVL(NDI.W2_CHARGE,0)),0)+
                      NVL(SUM(NVL(NDI.FR1_CHARGE,0)),0)+
                      NVL(SUM(NVL(NDI.FR2_CHARGE,0)),0)+
                      NVL(SUM(NVL(NDI.FR3_CHARGE,0)),0)+
                      NVL(SUM(NVL(NDI.FR4_CHARGE,0)),0)+
                      NVL(SUM(NVL(NDI.KP5_CHARGE,0)),0)+
                      NVL(SUM(NVL(NDI.KP6_CHARGE,0)),0)+
                      NVL(SUM(NVL(NDI.KP7_CHARGE,0)),0)+
                      NVL(SUM(NVL(NDI.KP8_CHARGE,0)),0)+
                      NVL(SUM(NVL(NDI.R21_CHARGE,0)),0)+
                      NVL(SUM(NVL(NDI.R22_CHARGE,0)),0)+
                      NVL(SUM(NVL(NDI.R23_CHARGE,0)),0)+
                      NVL(SUM(NVL(NDI.R24_CHARGE,0)),0)+
                      NVL(SUM(NVL(NDI.R25_CHARGE,0)),0)+
                      NVL(SUM(NVL(NDI.UNMTRD_CHARGE,0)),0)+
                      NVL(SUM(NVL(NDI.SMO_CHARGE,0)),0)+
                      NVL(SUM(NVL(NDI.NFD_CHARGE,0)),0)+
                      NVL(SUM(NVL(NDI.DJD_CHARGE,0)),0)+
                      NVL(SUM(NVL(NDI.NKP_CHARGE,0)),0)+
                      NVL(SUM(NVL(NDI.DJPK_CHARGE,0)),0)+
                      NVL(SUM(NVL(NDI.EW_CHARGE,0)),0)+
                      NVL(SUM(NVL(NDI.NT_CHARGE,0)),0)+
                      NVL(SUM(NVL(NDI.RPC_CHARGE,0)),0)+
                      NVL(SUM(NVL(NDI.CSC_CHARGE,0)),0)+
                      NVL(SUM(NVL(NDI.MIC_CHARGE,0)),0)+
                      NVL(SUM(NVL(NDI.R26_CHARGE,0)),0)
                 INTO v_TDIE_DUOS_NI_INV_REC.IMPORTED_REVENUE
                 FROM TDIE_DUOS_NI_INVOICE_DETAIL NDI
                WHERE NDI.INVOICE_NUMBER = v_TDIE_DUOS_NI_INV_REC.INVOICE_NUMBER;

            EXCEPTION
                  WHEN NO_DATA_FOUND THEN
                     v_TDIE_DUOS_NI_INV_REC.IMPORTED_REVENUE := 0;
            END;

            -- Count the distinct number of MPRNs on this backing sheet.
            BEGIN
            SELECT COUNT(a.MPRN)
               INTO v_TDIE_DUOS_NI_INV_REC.MPRN_COUNT
               FROM (SELECT DISTINCT NDI.POD_ID AS MPRN
                     FROM TDIE_DUOS_NI_INVOICE_DETAIL NDI
                     WHERE NDI.INVOICE_NUMBER = v_TDIE_DUOS_NI_INV_REC.INVOICE_NUMBER
                     ) a;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                     v_TDIE_DUOS_NI_INV_REC.IMPORTED_REVENUE := 0;
            END;

               UPD_TDIE_DUOS_NI_INVOICE(v_TDIE_DUOS_NI_INV_REC);
         ELSE
            -- RAISE INVALID SEGMENT ERROR
            LOGS.LOG_WARN(p_EVENT_TEXT => 'Current record not associated with current invoice.');

      END CASE;--CASE v_LINE_ELEMENTS(1)

      i := i + 1;

   END LOOP;--WHILE i <= v_LINES.LAST LOOP

END IMPORT_DUOS_NI;

--------------------------------------------------------------------------------
-- This procedure will be responsible for processing the TUoS Backing Sheet CSV file
-- This procedure will use the PARSE_UTIL library to handle the CSV parsing.
PROCEDURE IMPORT_TUOS (p_IMPORT_FILE IN CLOB)
IS
   c_PROCEDURE_NAME              CONSTANT VARCHAR(30) := 'IMPORT_TUOS';
   c_TUOS_FILE_VERSION1          VARCHAR2(2) := 'V1'; -- Orginal version
   c_TUOS_FILE_VERSION2          VARCHAR2(2) := 'V2'; -- Revised TUoS file, columns removed
   c_VERSION2_COLUMN_COUNT       NUMBER := 48;
   i                             BINARY_INTEGER := 1;
   v_TDIE_TUOS_INV_REC           TDIE_TUOS_INVOICE%ROWTYPE;
   v_TDIE_TUOS_INV_DTL_REC       TDIE_TUOS_INVOICE_DETAIL%ROWTYPE;
   v_TDIE_TUOS_INV_CHG_DTL_REC   TDIE_TUOS_INV_CHARGE_DTL%ROWTYPE;
   v_LINES                       PARSE_UTIL.BIG_STRING_TABLE_MP;
   v_LINE_ELEMENTS               PARSE_UTIL.STRING_TABLE;
   v_PROCESSED_REC_CNT           NUMBER;
   v_INV_MSG_TEXT                VARCHAR2(2000) := NULL;
   v_TUOS_FILE_VERSION           VARCHAR2(2) := c_TUOS_FILE_VERSION1;
BEGIN
   ASSERT(p_IMPORT_FILE IS NOT NULL, 'The import file must not be null.', MSGCODES.c_ERR_ARGUMENT);

	IF LOGS.IS_DEBUG_ENABLED THEN
      LOGS.LOG_DEBUG(g_PACKAGE_NAME||'.'||c_PROCEDURE_NAME);
	END IF;

   PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_IMPORT_FILE, v_LINES);

   i := v_LINES.FIRST;
   v_PROCESSED_REC_CNT := 0;
   WHILE i <= v_LINES.LAST LOOP
      PARSE_UTIL.PARSE_DELIMITED_STRING(v_LINES(i), ',', v_LINE_ELEMENTS);
      
      IF i = v_LINES.FIRST AND v_LINE_ELEMENTS.COUNT = c_VERSION2_COLUMN_COUNT THEN
          v_TUOS_FILE_VERSION := c_TUOS_FILE_VERSION2;
          
      END IF;

      IF TRIM(UPPER(v_LINE_ELEMENTS(1))) != 'INV NUMBER' THEN
          IF v_TUOS_FILE_VERSION = c_TUOS_FILE_VERSION2  THEN
              -- PROCESS Invoice Record >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
              IF v_LINE_ELEMENTS(1) <> NVL(v_TDIE_TUOS_INV_REC.INVOICE_NUMBER,-1) THEN

                 v_TDIE_TUOS_INV_REC.INVOICE_NUMBER            := v_LINE_ELEMENTS(1);
                 v_TDIE_TUOS_INV_REC.INVOICE_NAME              := v_LINE_ELEMENTS(2);
                 v_TDIE_TUOS_INV_REC.INVOICE_TYPE              := v_LINE_ELEMENTS(4);
                 v_TDIE_TUOS_INV_REC.INVOICE_START_DATE        := CONVERT_TO_DATE(v_LINE_ELEMENTS(5), g_TUOS_DATE_FORMAT);
                 v_TDIE_TUOS_INV_REC.INVOICE_END_DATE          := CONVERT_TO_DATE(v_LINE_ELEMENTS(6), g_TUOS_DATE_FORMAT);
                 v_TDIE_TUOS_INV_REC.INVOICE_STATUS            := v_LINE_ELEMENTS(7);
                 v_TDIE_TUOS_INV_REC.INVOICE_DATE              := CONVERT_TO_DATE(v_LINE_ELEMENTS(8), g_TUOS_DATE_FORMAT);
                 v_TDIE_TUOS_INV_REC.INVOICE_DUE_DATE          := CONVERT_TO_DATE(v_LINE_ELEMENTS(9), g_TUOS_DATE_FORMAT);
                 v_TDIE_TUOS_INV_REC.CUSTOMER_ID               := v_LINE_ELEMENTS(10);
                 v_TDIE_TUOS_INV_REC.CUSTOMER_CODE             := v_LINE_ELEMENTS(11);
                 v_TDIE_TUOS_INV_REC.CUSTOMER_NAME             := v_LINE_ELEMENTS(12);
                 v_TDIE_TUOS_INV_REC.NET_CHARGE_AMT_IMPORTED   := 0;
                 v_TDIE_TUOS_INV_REC.GROSS_CHARGE_AMT_IMPORTED := 0;
                 v_TDIE_TUOS_INV_REC.MPRN_COUNT                := 0;
                 v_TDIE_TUOS_INV_REC.SUPPLY_UNIT_COUNT         := 0;
                 v_TDIE_TUOS_INV_REC.RECORDS_IMPORTED          := 0;
                 v_TDIE_TUOS_INV_REC.IMPORT_TIMESTAMP          := g_IMPORT_TIMESTAMP;
                 v_TDIE_TUOS_INV_REC.FILE_NAME                 := g_IMPORT_FILE_PATH;
                 v_TDIE_TUOS_INV_REC.PROCESS_ID                := g_PROCESS_ID;
                 v_TDIE_TUOS_INV_REC.RETAIL_INVOICE_ID         := NULL;

                 v_INV_MSG_TEXT := 'Invoice Number:     '||v_TDIE_TUOS_INV_REC.INVOICE_NUMBER||g_CRLF||
                                   'Invoice Start Date: '||TO_CHAR(v_TDIE_TUOS_INV_REC.INVOICE_START_DATE,g_TUOS_DATE_FORMAT)||g_CRLF||
                                   'Invoice End Date:   '||TO_CHAR(v_TDIE_TUOS_INV_REC.INVOICE_END_DATE,g_TUOS_DATE_FORMAT)||g_CRLF||
                                   'Customer Name:      '||v_TDIE_TUOS_INV_REC.CUSTOMER_NAME||g_CRLF||
                                   'File Name:          '||v_TDIE_TUOS_INV_REC.FILE_NAME||g_CRLF||
                                   'PROCESS_ID:         '||TO_CHAR(v_TDIE_TUOS_INV_REC.PROCESS_ID)||g_CRLF;

                 LOGS.LOG_INFO(p_EVENT_TEXT => v_INV_MSG_TEXT);

                 DEL_TDIE_TUOS_INVOICE(v_TDIE_TUOS_INV_REC);

                 INS_TDIE_TUOS_INVOICE(v_TDIE_TUOS_INV_REC);

              END IF;-- PROCESS Invoice Record <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


              -- PROCESS Invoice Detail Record >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
              IF (v_LINE_ELEMENTS(1)  <> NVL(v_TDIE_TUOS_INV_DTL_REC.INVOICE_NUMBER,'-1') OR
                  v_LINE_ELEMENTS(13) <> NVL(v_TDIE_TUOS_INV_DTL_REC.ACCOUNT_XID,'-1') OR
                  v_LINE_ELEMENTS(18) <> NVL(v_TDIE_TUOS_INV_DTL_REC.METER_NAME,'-1')) THEN

                 v_TDIE_TUOS_INV_DTL_REC.INVOICE_NUMBER   := v_TDIE_TUOS_INV_REC.INVOICE_NUMBER;
                 v_TDIE_TUOS_INV_DTL_REC.ACCOUNT_XID      := CONVERT_TO_NUMBER(v_LINE_ELEMENTS(13));
                 v_TDIE_TUOS_INV_DTL_REC.ACCOUNT_TYPE     := v_LINE_ELEMENTS(14);
                 v_TDIE_TUOS_INV_DTL_REC.ACCOUNT_CODE     := v_LINE_ELEMENTS(15);
                 v_TDIE_TUOS_INV_DTL_REC.ACCOUNT_NAME     := v_LINE_ELEMENTS(16);
                 v_TDIE_TUOS_INV_DTL_REC.METER_XID        := CONVERT_TO_NUMBER(v_LINE_ELEMENTS(17));
                 v_TDIE_TUOS_INV_DTL_REC.METER_NAME       := v_LINE_ELEMENTS(18);
                 v_TDIE_TUOS_INV_DTL_REC.BILL_NAME        := v_LINE_ELEMENTS(19);
                 v_TDIE_TUOS_INV_DTL_REC.BILL_CONTACT     := v_LINE_ELEMENTS(20);
                 v_TDIE_TUOS_INV_DTL_REC.BILL_ADDRESS1    := v_LINE_ELEMENTS(21);
                 v_TDIE_TUOS_INV_DTL_REC.BILL_ADDRESS2    := v_LINE_ELEMENTS(22);
                 v_TDIE_TUOS_INV_DTL_REC.BILL_CITY        := v_LINE_ELEMENTS(23);
                 v_TDIE_TUOS_INV_DTL_REC.BILL_REGION      := v_LINE_ELEMENTS(24);
                 v_TDIE_TUOS_INV_DTL_REC.BILL_COUNTRY     := v_LINE_ELEMENTS(25);
                 v_TDIE_TUOS_INV_DTL_REC.BILL_POSTAL_CODE := v_LINE_ELEMENTS(26);
                 v_TDIE_TUOS_INV_DTL_REC.MPRN             := NULL;
                 v_TDIE_TUOS_INV_DTL_REC.SUPPLY_UNIT      := NULL;

                 INS_TDIE_TUOS_INVOICE_DTL(v_TDIE_TUOS_INV_DTL_REC);

              END IF;-- PROCESS Invoice Detail Record <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

              -- PROCESS Charge Detail Record >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
              IF (v_LINE_ELEMENTS(1)  <> NVL(v_TDIE_TUOS_INV_CHG_DTL_REC.INVOICE_NUMBER,'-1')     OR
                  CONVERT_TO_NUMBER(v_LINE_ELEMENTS(13)) <> NVL(v_TDIE_TUOS_INV_CHG_DTL_REC.ACCOUNT_XID,'-1')        OR
                  v_LINE_ELEMENTS(18) <> NVL(v_TDIE_TUOS_INV_CHG_DTL_REC.METER_NAME,'-1')         OR
                  CONVERT_TO_DATE(v_LINE_ELEMENTS(27), g_TUOS_DATE_FORMAT) <> NVL(v_TDIE_TUOS_INV_CHG_DTL_REC.INV_DET_START_DATE, SYSDATE) OR
                  CONVERT_TO_DATE(v_LINE_ELEMENTS(28), g_TUOS_DATE_FORMAT) <> NVL(v_TDIE_TUOS_INV_CHG_DTL_REC.INV_DET_END_DATE, SYSDATE)   OR
                  v_LINE_ELEMENTS(29) <> NVL(v_TDIE_TUOS_INV_CHG_DTL_REC.INV_DET_CATEGORY,'-1')   OR
                  v_LINE_ELEMENTS(30) <> NVL(v_TDIE_TUOS_INV_CHG_DTL_REC.INV_DET_TYPE,'-1')       OR
                  v_LINE_ELEMENTS(31) <> NVL(v_TDIE_TUOS_INV_CHG_DTL_REC.INV_DET_CODE,'-1')       OR
                  v_LINE_ELEMENTS(38) <> NVL(v_TDIE_TUOS_INV_CHG_DTL_REC.INV_DET_CATEGORY2,'-1')  OR
                  v_LINE_ELEMENTS(40) <> NVL(v_TDIE_TUOS_INV_CHG_DTL_REC.INV_DET_SEQ,'-1')		  OR
                  v_LINE_ELEMENTS(46) <> NVL(v_TDIE_TUOS_INV_CHG_DTL_REC.INV_DET_NOTE_SORT, '-1'))  THEN

                 v_TDIE_TUOS_INV_CHG_DTL_REC.INVOICE_NUMBER              := v_TDIE_TUOS_INV_REC.INVOICE_NUMBER;
                 v_TDIE_TUOS_INV_CHG_DTL_REC.ACCOUNT_XID                 := v_TDIE_TUOS_INV_DTL_REC.ACCOUNT_XID;
                 v_TDIE_TUOS_INV_CHG_DTL_REC.METER_NAME                  := v_TDIE_TUOS_INV_DTL_REC.METER_NAME;
                 v_TDIE_TUOS_INV_CHG_DTL_REC.INVOICE_CATEGORY 			 := v_LINE_ELEMENTS(3);
                 v_TDIE_TUOS_INV_CHG_DTL_REC.INV_DET_START_DATE          := CONVERT_TO_DATE(v_LINE_ELEMENTS(27), g_TUOS_DATE_FORMAT);
                 v_TDIE_TUOS_INV_CHG_DTL_REC.INV_DET_END_DATE            := CONVERT_TO_DATE(v_LINE_ELEMENTS(28), g_TUOS_DATE_FORMAT);
                 v_TDIE_TUOS_INV_CHG_DTL_REC.INV_DET_CATEGORY            := v_LINE_ELEMENTS(29);
                 v_TDIE_TUOS_INV_CHG_DTL_REC.INV_DET_TYPE                := v_LINE_ELEMENTS(30);
                 v_TDIE_TUOS_INV_CHG_DTL_REC.INV_DET_CODE                := (CASE v_LINE_ELEMENTS(30)
                                                                                 WHEN c_TUOS_DET_TYPE_CHG_PARM THEN
                                                                                    RTRIM(v_LINE_ELEMENTS(31),' *')
                                                                                 WHEN c_TUOS_DET_TYPE_CHG_INTRVL THEN
                                                                                    CASE
                                                                                       WHEN INSTR(v_LINE_ELEMENTS(31),')') > 0 AND INSTR(v_LINE_ELEMENTS(31),')') < 5 THEN
                                                                                          SUBSTR(v_LINE_ELEMENTS(31), (INSTR(v_LINE_ELEMENTS(31),')') + 2), (LENGTH(v_LINE_ELEMENTS(31)) - INSTR(v_LINE_ELEMENTS(31),')')))
                                                                                       ELSE
                                                                                          v_LINE_ELEMENTS(31)
                                                                                    END
                                                                                 ELSE
                                                                                    v_LINE_ELEMENTS(31)
                                                                               END);
                 v_TDIE_TUOS_INV_CHG_DTL_REC.INV_DET_CATEGORY2           := v_LINE_ELEMENTS(38);
                 v_TDIE_TUOS_INV_CHG_DTL_REC.INV_DET_SEQ                 := v_LINE_ELEMENTS(40);
                 v_TDIE_TUOS_INV_CHG_DTL_REC.INV_DET_NAME                := v_LINE_ELEMENTS(32);
                 v_TDIE_TUOS_INV_CHG_DTL_REC.INV_DET_VALUE               := CONVERT_TO_NUMBER(v_LINE_ELEMENTS(33));
                 v_TDIE_TUOS_INV_CHG_DTL_REC.INV_DET_UOM                 := v_LINE_ELEMENTS(34);
                 v_TDIE_TUOS_INV_CHG_DTL_REC.MULTI_CIP_FLAG              := v_LINE_ELEMENTS(35);
                 v_TDIE_TUOS_INV_CHG_DTL_REC.INV_DET_VALUE_CHARGE        := CONVERT_TO_NUMBER(v_LINE_ELEMENTS(36));
                 v_TDIE_TUOS_INV_CHG_DTL_REC.INV_DET_TYPE_SORT           := v_LINE_ELEMENTS(37);
                 v_TDIE_TUOS_INV_CHG_DTL_REC.EIR_RPT_INV_DET_ID          := CONVERT_TO_NUMBER(v_LINE_ELEMENTS(39));
                 v_TDIE_TUOS_INV_CHG_DTL_REC.BILL_DATE                   := CONVERT_TO_DATE(v_LINE_ELEMENTS(41), 'DD-MM-YYYY');
                 v_TDIE_TUOS_INV_CHG_DTL_REC.CIP_DATE                    := v_LINE_ELEMENTS(42);
                 v_TDIE_TUOS_INV_CHG_DTL_REC.INV_NUMBER_RELEASED         := v_LINE_ELEMENTS(43);
                 v_TDIE_TUOS_INV_CHG_DTL_REC.INV_DATE_RELEASED           := CONVERT_TO_DATE(v_LINE_ELEMENTS(44), g_TUOS_DATE_FORMAT);
                 v_TDIE_TUOS_INV_CHG_DTL_REC.INV_DET_NOTES               := v_LINE_ELEMENTS(45);
                 v_TDIE_TUOS_INV_CHG_DTL_REC.INV_DET_NOTE_SORT           := v_LINE_ELEMENTS(46);
                 v_TDIE_TUOS_INV_CHG_DTL_REC.DLAFG                       := v_LINE_ELEMENTS(47);
                 v_TDIE_TUOS_INV_CHG_DTL_REC.DG                          := v_LINE_ELEMENTS(48);

                 INS_TDIE_TUOS_INVOICE_CHG_DTL(v_TDIE_TUOS_INV_CHG_DTL_REC);

                 v_PROCESSED_REC_CNT := v_PROCESSED_REC_CNT + 1;

              END IF;-- PROCESS Charge Detail Record <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<          
          ELSE
              -- PROCESS Invoice Record >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
              IF v_LINE_ELEMENTS(1) <> NVL(v_TDIE_TUOS_INV_REC.INVOICE_NUMBER,-1) THEN

                 v_TDIE_TUOS_INV_REC.INVOICE_NUMBER            := v_LINE_ELEMENTS(1);
                 v_TDIE_TUOS_INV_REC.INVOICE_NAME              := v_LINE_ELEMENTS(2);
                 v_TDIE_TUOS_INV_REC.INVOICE_TYPE              := v_LINE_ELEMENTS(4);
                 v_TDIE_TUOS_INV_REC.INVOICE_START_DATE        := CONVERT_TO_DATE(v_LINE_ELEMENTS(5), g_TUOS_DATE_FORMAT);
                 v_TDIE_TUOS_INV_REC.INVOICE_END_DATE          := CONVERT_TO_DATE(v_LINE_ELEMENTS(6), g_TUOS_DATE_FORMAT);
                 v_TDIE_TUOS_INV_REC.INVOICE_STATUS            := v_LINE_ELEMENTS(7);
                 v_TDIE_TUOS_INV_REC.INVOICE_DATE              := CONVERT_TO_DATE(v_LINE_ELEMENTS(8), g_TUOS_DATE_FORMAT);
                 v_TDIE_TUOS_INV_REC.INVOICE_DUE_DATE          := CONVERT_TO_DATE(v_LINE_ELEMENTS(9), g_TUOS_DATE_FORMAT);
                 v_TDIE_TUOS_INV_REC.CUSTOMER_ID               := v_LINE_ELEMENTS(10);
                 v_TDIE_TUOS_INV_REC.CUSTOMER_CATEGORY         := v_LINE_ELEMENTS(11);
                 v_TDIE_TUOS_INV_REC.CUSTOMER_TYPE             := v_LINE_ELEMENTS(12);
                 v_TDIE_TUOS_INV_REC.CUSTOMER_CODE             := v_LINE_ELEMENTS(13);
                 v_TDIE_TUOS_INV_REC.CUSTOMER_NAME             := v_LINE_ELEMENTS(14);
                 v_TDIE_TUOS_INV_REC.NET_CHARGE_AMT_IMPORTED   := 0;
                 v_TDIE_TUOS_INV_REC.GROSS_CHARGE_AMT_IMPORTED := 0;
                 v_TDIE_TUOS_INV_REC.MPRN_COUNT                := 0;
                 v_TDIE_TUOS_INV_REC.SUPPLY_UNIT_COUNT         := 0;
                 v_TDIE_TUOS_INV_REC.RECORDS_IMPORTED          := 0;
                 v_TDIE_TUOS_INV_REC.IMPORT_TIMESTAMP          := g_IMPORT_TIMESTAMP;
                 v_TDIE_TUOS_INV_REC.FILE_NAME                 := g_IMPORT_FILE_PATH;
                 v_TDIE_TUOS_INV_REC.PROCESS_ID                := g_PROCESS_ID;
                 v_TDIE_TUOS_INV_REC.RETAIL_INVOICE_ID         := NULL;

                 v_INV_MSG_TEXT := 'Invoice Number:     '||v_TDIE_TUOS_INV_REC.INVOICE_NUMBER||g_CRLF||
                                   'Invoice Start Date: '||TO_CHAR(v_TDIE_TUOS_INV_REC.INVOICE_START_DATE,g_TUOS_DATE_FORMAT)||g_CRLF||
                                   'Invoice End Date:   '||TO_CHAR(v_TDIE_TUOS_INV_REC.INVOICE_END_DATE,g_TUOS_DATE_FORMAT)||g_CRLF||
                                   'Customer Name:      '||v_TDIE_TUOS_INV_REC.CUSTOMER_NAME||g_CRLF||
                                   'File Name:          '||v_TDIE_TUOS_INV_REC.FILE_NAME||g_CRLF||
                                   'PROCESS_ID:         '||TO_CHAR(v_TDIE_TUOS_INV_REC.PROCESS_ID)||g_CRLF;

                 LOGS.LOG_INFO(p_EVENT_TEXT => v_INV_MSG_TEXT);

                 DEL_TDIE_TUOS_INVOICE(v_TDIE_TUOS_INV_REC);

                 INS_TDIE_TUOS_INVOICE(v_TDIE_TUOS_INV_REC);

              END IF;-- PROCESS Invoice Record <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


              -- PROCESS Invoice Detail Record >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
              IF (v_LINE_ELEMENTS(1)  <> NVL(v_TDIE_TUOS_INV_DTL_REC.INVOICE_NUMBER,'-1') OR
                  v_LINE_ELEMENTS(15) <> NVL(v_TDIE_TUOS_INV_DTL_REC.ACCOUNT_XID,'-1') OR
                  v_LINE_ELEMENTS(24) <> NVL(v_TDIE_TUOS_INV_DTL_REC.METER_NAME,'-1')) THEN

                 v_TDIE_TUOS_INV_DTL_REC.INVOICE_NUMBER   := v_TDIE_TUOS_INV_REC.INVOICE_NUMBER;
                 v_TDIE_TUOS_INV_DTL_REC.ACCOUNT_XID      := CONVERT_TO_NUMBER(v_LINE_ELEMENTS(15));
                 v_TDIE_TUOS_INV_DTL_REC.ACCOUNT_CATEGORY := v_LINE_ELEMENTS(16);
                 v_TDIE_TUOS_INV_DTL_REC.ACCOUNT_TYPE     := v_LINE_ELEMENTS(17);
                 v_TDIE_TUOS_INV_DTL_REC.ACCOUNT_CODE     := v_LINE_ELEMENTS(18);
                 v_TDIE_TUOS_INV_DTL_REC.ACCOUNT_NAME     := v_LINE_ELEMENTS(19);
                 v_TDIE_TUOS_INV_DTL_REC.METER_XID        := CONVERT_TO_NUMBER(v_LINE_ELEMENTS(20));
                 v_TDIE_TUOS_INV_DTL_REC.METER_CATEGORY   := v_LINE_ELEMENTS(21);
                 v_TDIE_TUOS_INV_DTL_REC.METER_TYPE       := v_LINE_ELEMENTS(22);
                 v_TDIE_TUOS_INV_DTL_REC.METER_CODE       := v_LINE_ELEMENTS(23);
                 v_TDIE_TUOS_INV_DTL_REC.METER_NAME       := v_LINE_ELEMENTS(24);
                 v_TDIE_TUOS_INV_DTL_REC.BILL_NAME        := v_LINE_ELEMENTS(25);
                 v_TDIE_TUOS_INV_DTL_REC.BILL_CONTACT     := v_LINE_ELEMENTS(26);
                 v_TDIE_TUOS_INV_DTL_REC.BILL_ADDRESS1    := v_LINE_ELEMENTS(27);
                 v_TDIE_TUOS_INV_DTL_REC.BILL_ADDRESS2    := v_LINE_ELEMENTS(28);
                 v_TDIE_TUOS_INV_DTL_REC.BILL_CITY        := v_LINE_ELEMENTS(29);
                 v_TDIE_TUOS_INV_DTL_REC.BILL_REGION      := v_LINE_ELEMENTS(30);
                 v_TDIE_TUOS_INV_DTL_REC.BILL_COUNTRY     := v_LINE_ELEMENTS(31);
                 v_TDIE_TUOS_INV_DTL_REC.BILL_POSTAL_CODE := v_LINE_ELEMENTS(32);
                 v_TDIE_TUOS_INV_DTL_REC.MPRN             := NULL;
                 v_TDIE_TUOS_INV_DTL_REC.SUPPLY_UNIT      := NULL;

                 INS_TDIE_TUOS_INVOICE_DTL(v_TDIE_TUOS_INV_DTL_REC);

              END IF;-- PROCESS Invoice Detail Record <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

              -- PROCESS Charge Detail Record >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
              IF (v_LINE_ELEMENTS(1)  <> NVL(v_TDIE_TUOS_INV_CHG_DTL_REC.INVOICE_NUMBER,'-1')     OR
                  CONVERT_TO_NUMBER(v_LINE_ELEMENTS(15)) <> NVL(v_TDIE_TUOS_INV_CHG_DTL_REC.ACCOUNT_XID,'-1')        OR
                  v_LINE_ELEMENTS(24) <> NVL(v_TDIE_TUOS_INV_CHG_DTL_REC.METER_NAME,'-1')         OR
                  CONVERT_TO_DATE(v_LINE_ELEMENTS(33), g_TUOS_DATE_FORMAT) <> NVL(v_TDIE_TUOS_INV_CHG_DTL_REC.INV_DET_START_DATE, SYSDATE) OR
                  CONVERT_TO_DATE(v_LINE_ELEMENTS(34), g_TUOS_DATE_FORMAT) <> NVL(v_TDIE_TUOS_INV_CHG_DTL_REC.INV_DET_END_DATE, SYSDATE)   OR
                  v_LINE_ELEMENTS(35) <> NVL(v_TDIE_TUOS_INV_CHG_DTL_REC.INV_DET_CATEGORY,'-1')   OR
                  v_LINE_ELEMENTS(36) <> NVL(v_TDIE_TUOS_INV_CHG_DTL_REC.INV_DET_TYPE,'-1')       OR
                  v_LINE_ELEMENTS(37) <> NVL(v_TDIE_TUOS_INV_CHG_DTL_REC.INV_DET_CODE,'-1')       OR
                  v_LINE_ELEMENTS(46) <> NVL(v_TDIE_TUOS_INV_CHG_DTL_REC.INV_DET_CATEGORY2,'-1')  OR
                  v_LINE_ELEMENTS(48) <> NVL(v_TDIE_TUOS_INV_CHG_DTL_REC.INV_DET_SEQ,'-1')		  OR
                  v_LINE_ELEMENTS(55) <> NVL(v_TDIE_TUOS_INV_CHG_DTL_REC.INV_DET_NOTE_SORT, '-1'))  THEN

                 v_TDIE_TUOS_INV_CHG_DTL_REC.INVOICE_NUMBER              := v_TDIE_TUOS_INV_REC.INVOICE_NUMBER;
                 v_TDIE_TUOS_INV_CHG_DTL_REC.ACCOUNT_XID                 := v_TDIE_TUOS_INV_DTL_REC.ACCOUNT_XID;
                 v_TDIE_TUOS_INV_CHG_DTL_REC.METER_NAME                  := v_TDIE_TUOS_INV_DTL_REC.METER_NAME;
                 v_TDIE_TUOS_INV_CHG_DTL_REC.INVOICE_CATEGORY 			 := v_LINE_ELEMENTS(3);
                 v_TDIE_TUOS_INV_CHG_DTL_REC.INV_DET_START_DATE          := CONVERT_TO_DATE(v_LINE_ELEMENTS(33), g_TUOS_DATE_FORMAT);
                 v_TDIE_TUOS_INV_CHG_DTL_REC.INV_DET_END_DATE            := CONVERT_TO_DATE(v_LINE_ELEMENTS(34), g_TUOS_DATE_FORMAT);
                 v_TDIE_TUOS_INV_CHG_DTL_REC.INV_DET_CATEGORY            := v_LINE_ELEMENTS(35);
                 v_TDIE_TUOS_INV_CHG_DTL_REC.INV_DET_TYPE                := v_LINE_ELEMENTS(36);
                 v_TDIE_TUOS_INV_CHG_DTL_REC.INV_DET_CODE                := (CASE v_LINE_ELEMENTS(36)
                                                                                 WHEN c_TUOS_DET_TYPE_CHG_PARM THEN
                                                                                    RTRIM(v_LINE_ELEMENTS(37),' *')
                                                                                 WHEN c_TUOS_DET_TYPE_CHG_INTRVL THEN
                                                                                    CASE
                                                                                       WHEN INSTR(v_LINE_ELEMENTS(37),')') > 0 AND INSTR(v_LINE_ELEMENTS(37),')') < 5 THEN
                                                                                          SUBSTR(v_LINE_ELEMENTS(37), (INSTR(v_LINE_ELEMENTS(37),')') + 2), (LENGTH(v_LINE_ELEMENTS(37)) - INSTR(v_LINE_ELEMENTS(37),')')))
                                                                                       ELSE
                                                                                          v_LINE_ELEMENTS(37)
                                                                                    END
                                                                                 ELSE
                                                                                    v_LINE_ELEMENTS(37)
                                                                               END);
                 v_TDIE_TUOS_INV_CHG_DTL_REC.INV_DET_CATEGORY2           := v_LINE_ELEMENTS(46);
                 v_TDIE_TUOS_INV_CHG_DTL_REC.INV_DET_SEQ                 := v_LINE_ELEMENTS(48);
                 v_TDIE_TUOS_INV_CHG_DTL_REC.INV_DET_NAME                := v_LINE_ELEMENTS(38);
                 v_TDIE_TUOS_INV_CHG_DTL_REC.INV_DET_VALUE               := CONVERT_TO_NUMBER(v_LINE_ELEMENTS(39));
                 v_TDIE_TUOS_INV_CHG_DTL_REC.INV_DET_UOM                 := v_LINE_ELEMENTS(40);
                 v_TDIE_TUOS_INV_CHG_DTL_REC.MULTI_CIP_FLAG              := v_LINE_ELEMENTS(41);
                 v_TDIE_TUOS_INV_CHG_DTL_REC.VAT_CHARGE                  := CONVERT_TO_NUMBER(v_LINE_ELEMENTS(42));
                 v_TDIE_TUOS_INV_CHG_DTL_REC.INV_DET_VALUE_CHARGE        := CONVERT_TO_NUMBER(v_LINE_ELEMENTS(43));
                 v_TDIE_TUOS_INV_CHG_DTL_REC.INV_DET_VALUE_CHARGE_NO_VAT := CONVERT_TO_NUMBER(v_LINE_ELEMENTS(44));
                 v_TDIE_TUOS_INV_CHG_DTL_REC.INV_DET_TYPE_SORT           := v_LINE_ELEMENTS(45);
                 v_TDIE_TUOS_INV_CHG_DTL_REC.EIR_RPT_INV_DET_ID          := CONVERT_TO_NUMBER(v_LINE_ELEMENTS(47));
                 v_TDIE_TUOS_INV_CHG_DTL_REC.BILL_DATE                   := CONVERT_TO_DATE(v_LINE_ELEMENTS(49), 'YYYY-MM');
                 v_TDIE_TUOS_INV_CHG_DTL_REC.CIP_DATE                    := v_LINE_ELEMENTS(50);
                 v_TDIE_TUOS_INV_CHG_DTL_REC.INV_STATUS_DRAFT            := v_LINE_ELEMENTS(51);
                 v_TDIE_TUOS_INV_CHG_DTL_REC.INV_NUMBER_RELEASED         := v_LINE_ELEMENTS(52);
                 v_TDIE_TUOS_INV_CHG_DTL_REC.INV_DATE_RELEASED           := CONVERT_TO_DATE(v_LINE_ELEMENTS(53), g_TUOS_DATE_FORMAT);
                 v_TDIE_TUOS_INV_CHG_DTL_REC.INV_DET_NOTES               := v_LINE_ELEMENTS(54);
                 v_TDIE_TUOS_INV_CHG_DTL_REC.INV_DET_NOTE_SORT           := v_LINE_ELEMENTS(55);

                 INS_TDIE_TUOS_INVOICE_CHG_DTL(v_TDIE_TUOS_INV_CHG_DTL_REC);

                 v_PROCESSED_REC_CNT := v_PROCESSED_REC_CNT + 1;

              END IF;-- PROCESS Charge Detail Record <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
          END IF;
      END IF;
      i := i + 1;

   END LOOP;--WHILE i <= v_LINES.LAST LOOP

   -- Set totals for parent record.
   v_TDIE_TUOS_INV_REC.RECORDS_IMPORTED := v_PROCESSED_REC_CNT;

   BEGIN
      SELECT NVL(SUM(NVL(TTICD.INV_DET_VALUE_CHARGE_NO_VAT,0)),0),
             NVL(SUM(NVL(TTICD.INV_DET_VALUE_CHARGE,0)),0)
        INTO v_TDIE_TUOS_INV_REC.NET_CHARGE_AMT_IMPORTED,
             v_TDIE_TUOS_INV_REC.GROSS_CHARGE_AMT_IMPORTED
        FROM TDIE_TUOS_INV_CHARGE_DTL TTICD
       WHERE TTICD.INV_DET_TYPE = c_TUOS_DET_TYPE_CHG_INTRVL
         AND TTICD.INVOICE_NUMBER = v_TDIE_TUOS_INV_REC.INVOICE_NUMBER;
   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         v_TDIE_TUOS_INV_REC.NET_CHARGE_AMT_IMPORTED   := 0;
         v_TDIE_TUOS_INV_REC.GROSS_CHARGE_AMT_IMPORTED := 0;
   END;

   MAP_TUOS_SUPPLY_UNITS(v_TDIE_TUOS_INV_REC.INVOICE_NUMBER);

   BEGIN
      SELECT COUNT(a.MPRN)
        INTO v_TDIE_TUOS_INV_REC.MPRN_COUNT
        FROM (SELECT DISTINCT TTID.MPRN AS MPRN
                FROM TDIE_TUOS_INVOICE_DETAIL TTID
               WHERE TTID.INVOICE_NUMBER = v_TDIE_TUOS_INV_REC.INVOICE_NUMBER
                 AND TTID.MPRN IS NOT NULL
              ) a;
   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         v_TDIE_TUOS_INV_REC.MPRN_COUNT := 0;
   END;

   BEGIN
      SELECT COUNT(a.SUPPLY_UNIT)
        INTO v_TDIE_TUOS_INV_REC.SUPPLY_UNIT_COUNT
        FROM (SELECT DISTINCT TTID.SUPPLY_UNIT AS SUPPLY_UNIT
                FROM TDIE_TUOS_INVOICE_DETAIL TTID
               WHERE TTID.INVOICE_NUMBER = v_TDIE_TUOS_INV_REC.INVOICE_NUMBER
                 AND TTID.SUPPLY_UNIT IS NOT NULL
              ) a;
   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         v_TDIE_TUOS_INV_REC.SUPPLY_UNIT_COUNT := 0;
   END;

   UPD_TDIE_TUOS_INVOICE(v_TDIE_TUOS_INV_REC);

   MAINTAIN_TUOS_CODES(v_TDIE_TUOS_INV_REC.INVOICE_NUMBER);

END IMPORT_TUOS;


--------------------------------------------------------------------------------
-- This procedure will be responsible for processing the UoS Backing Sheet CSV file
-- This procedure will use the PARSE_UTIL library to handle the CSV parsing.
PROCEDURE IMPORT_UOS (p_IMPORT_FILE IN CLOB)
IS
   c_PROCEDURE_NAME CONSTANT VARCHAR(30) := 'IMPORT_UOS';
   c_TARIFF_CODE_BC CONSTANT VARCHAR(32) := 'BC';
   i                         BINARY_INTEGER := 1;
   v_TDIE_UOS_INV_REC        TDIE_UOS_INVOICE%ROWTYPE;
   v_TDIE_UOS_INV_DTL_REC    TDIE_UOS_INVOICE_DETAIL%ROWTYPE;
   v_LINES                   PARSE_UTIL.BIG_STRING_TABLE_MP;
   v_LINE_ELEMENTS           PARSE_UTIL.STRING_TABLE;
   v_PROCESSED_REC_CNT       NUMBER;
   v_VAT_TOTAL               NUMBER;
   v_INV_MSG_TEXT                VARCHAR2(2000) := NULL;
BEGIN
   ASSERT(p_IMPORT_FILE IS NOT NULL, 'The import file must not be null.', MSGCODES.c_ERR_ARGUMENT);

	IF LOGS.IS_DEBUG_ENABLED THEN
      	LOGS.LOG_DEBUG(g_PACKAGE_NAME||'.'||c_PROCEDURE_NAME);
	END IF;

   PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_IMPORT_FILE, v_LINES);

   i := v_LINES.FIRST;
   v_PROCESSED_REC_CNT := 0;
   WHILE i <= v_LINES.LAST LOOP
      PARSE_UTIL.PARSE_DELIMITED_STRING(v_LINES(i), ',', v_LINE_ELEMENTS);

      CASE
         -- PROCESS Header Record ----------------------------------------------
         WHEN v_LINE_ELEMENTS(2) = 1 AND NVL(v_TDIE_UOS_INV_REC.INVOICE_NUMBER,-1) <> v_LINE_ELEMENTS(1) THEN
               v_TDIE_UOS_INV_REC.INVOICE_NUMBER               := v_LINE_ELEMENTS(1);
               v_TDIE_UOS_INV_REC.SENDER_CID                   := v_LINE_ELEMENTS(3);
               v_TDIE_UOS_INV_REC.RECIPIENT_CID                := v_LINE_ELEMENTS(4);
               v_TDIE_UOS_INV_REC.MARKET_TIMESTAMP             := CONVERT_TO_DATE(v_LINE_ELEMENTS(5), g_UOS_TIMESTAMP_FORMAT);
               v_TDIE_UOS_INV_REC.DUE_DATE                     := CONVERT_TO_DATE(v_LINE_ELEMENTS(6), g_UOS_DATE_FORMAT);
               v_TDIE_UOS_INV_REC.TOTAL_CONSUMPTION            := v_LINE_ELEMENTS(7);
               v_TDIE_UOS_INV_REC.TOTAL_CSC                    := v_LINE_ELEMENTS(8);
               v_TDIE_UOS_INV_REC.TOTAL_REACTIVE               := v_LINE_ELEMENTS(9);
               v_TDIE_UOS_INV_REC.TOTAL_STANDING_CHARGE        := v_LINE_ELEMENTS(10);
               v_TDIE_UOS_INV_REC.TOTAL_TRANSMISSION_REBATE    := v_LINE_ELEMENTS(11);
               v_TDIE_UOS_INV_REC.TOTAL_AD_HOC                 := v_LINE_ELEMENTS(12);
               v_TDIE_UOS_INV_REC.TOTAL_CONSUMPTION_ADJUSTMENT := v_LINE_ELEMENTS(13);
               v_TDIE_UOS_INV_REC.TOTAL_VAT                    := v_LINE_ELEMENTS(14);
               v_TDIE_UOS_INV_REC.TOTAL_CANCELED               := v_LINE_ELEMENTS(15);
               v_TDIE_UOS_INV_REC.TOTAL_CONSUMPTION_KWH        := v_LINE_ELEMENTS(18);
               v_TDIE_UOS_INV_REC.TOTAL_DETAIL_LINES           := 0;
               v_TDIE_UOS_INV_REC.NET_CHARGE_AMT_IMPORTED      := 0;
               v_TDIE_UOS_INV_REC.GROSS_CHARGE_AMT_IMPORTED    := 0;
               v_TDIE_UOS_INV_REC.MPRN_COUNT                   := 0;
               v_TDIE_UOS_INV_REC.RECORDS_IMPORTED             := 0;
               v_TDIE_UOS_INV_REC.IMPORT_TIMESTAMP             := g_IMPORT_TIMESTAMP;
               v_TDIE_UOS_INV_REC.FILE_NAME                    := g_IMPORT_FILE_PATH;
               v_TDIE_UOS_INV_REC.PROCESS_ID                   := g_PROCESS_ID;
               v_TDIE_UOS_INV_REC.RETAIL_INVOICE_ID            := NULL;

               v_INV_MSG_TEXT := 'Invoice Number:   '||v_TDIE_UOS_INV_REC.INVOICE_NUMBER||g_CRLF||
                                 'Market Timestamp: '||TO_CHAR(v_TDIE_UOS_INV_REC.MARKET_TIMESTAMP,g_CSV_TIMESTAMP_FORMAT)||g_CRLF||
                                 'Sender CID:       '||v_TDIE_UOS_INV_REC.SENDER_CID||g_CRLF||
                                 'Recipient CID:    '||v_TDIE_UOS_INV_REC.RECIPIENT_CID||g_CRLF||
                                 'File Name:        '||v_TDIE_UOS_INV_REC.FILE_NAME||g_CRLF||
                                 'PROCESS_ID:       '||TO_CHAR(v_TDIE_UOS_INV_REC.PROCESS_ID)||g_CRLF;

               LOGS.LOG_INFO(p_EVENT_TEXT => v_INV_MSG_TEXT);

               DEL_TDIE_UOS_INVOICE(v_TDIE_UOS_INV_REC);

               INS_TDIE_UOS_INVOICE(v_TDIE_UOS_INV_REC);

         -- PROCESS Detail Record ----------------------------------------------
         WHEN v_LINE_ELEMENTS(2) = 2 AND v_LINE_ELEMENTS(1) = v_TDIE_UOS_INV_REC.INVOICE_NUMBER THEN

            v_PROCESSED_REC_CNT := v_PROCESSED_REC_CNT + 1;

            -- Only process records where the record type is not null. Otherwise dont process but add to count.
            IF v_LINE_ELEMENTS(3) IS NULL OR
               SUBSTR(v_LINE_ELEMENTS(3),1,1) = ' ' OR
               v_LINE_ELEMENTS(3)= '' THEN
              -- Skip this record.
              NULL;
            ELSE
              -- If start and end dates are missing then replace with truncated market timestamp from same file.
              -- Start Date
              IF v_LINE_ELEMENTS(10) IS NULL THEN
                 v_TDIE_UOS_INV_DTL_REC.START_DATE := TRUNC(v_TDIE_UOS_INV_REC.MARKET_TIMESTAMP);
              ELSE
                 v_TDIE_UOS_INV_DTL_REC.START_DATE := CONVERT_TO_DATE(v_LINE_ELEMENTS(10), g_UOS_DATE_FORMAT);
              END IF;

              -- End Date
              IF v_LINE_ELEMENTS(13) IS NULL THEN
                 v_TDIE_UOS_INV_DTL_REC.END_DATE := TRUNC(v_TDIE_UOS_INV_REC.MARKET_TIMESTAMP);
              ELSE
                 v_TDIE_UOS_INV_DTL_REC.END_DATE := CONVERT_TO_DATE(v_LINE_ELEMENTS(13), g_UOS_DATE_FORMAT);
              END IF;

              -- UOS_TARIFF
              -- If the UOS Tariff is NULL the we are assuming it will be BC.
              IF v_LINE_ELEMENTS(16) IS NULL THEN
                 v_TDIE_UOS_INV_DTL_REC.UOS_TARIFF := c_TARIFF_CODE_BC;
              ELSE
                 v_TDIE_UOS_INV_DTL_REC.UOS_TARIFF := v_LINE_ELEMENTS(16);
              END IF;

              v_TDIE_UOS_INV_DTL_REC.INVOICE_NUMBER         := v_TDIE_UOS_INV_REC.INVOICE_NUMBER;
              v_TDIE_UOS_INV_DTL_REC.SENDER_CID             := v_TDIE_UOS_INV_REC.SENDER_CID;
              v_TDIE_UOS_INV_DTL_REC.RECORD_TYPE            := v_LINE_ELEMENTS(3);
              v_TDIE_UOS_INV_DTL_REC.MPRN                   := v_LINE_ELEMENTS(4);
              v_TDIE_UOS_INV_DTL_REC.METER_ID_SERIAL_NUMBER := v_LINE_ELEMENTS(5);
              v_TDIE_UOS_INV_DTL_REC.UNIT_OF_MEASURE        := v_LINE_ELEMENTS(6);
              v_TDIE_UOS_INV_DTL_REC.TIMESLOT_CODE          := v_LINE_ELEMENTS(7);
              v_TDIE_UOS_INV_DTL_REC.START_READ             := v_LINE_ELEMENTS(8);
              v_TDIE_UOS_INV_DTL_REC.START_READ_TYPE        := v_LINE_ELEMENTS(9);
              v_TDIE_UOS_INV_DTL_REC.END_READ               := v_LINE_ELEMENTS(11);
              v_TDIE_UOS_INV_DTL_REC.END_READ_TYPE          := v_LINE_ELEMENTS(12);
              v_TDIE_UOS_INV_DTL_REC.TOTAL_UNITS            := CASE
                                                                  WHEN SUBSTR(v_TDIE_UOS_INV_DTL_REC.RECORD_TYPE,1,3) = 'CAN' THEN
                                                                     '-' ||  v_LINE_ELEMENTS(14)
                                                                  ELSE
                                                                     v_LINE_ELEMENTS(14)
                                                                END;
              v_TDIE_UOS_INV_DTL_REC.ESTIMATED_UNITS        := v_LINE_ELEMENTS(15);
              v_TDIE_UOS_INV_DTL_REC.RATE                   := v_LINE_ELEMENTS(17);
              v_TDIE_UOS_INV_DTL_REC.CHARGE                 := CASE
                                                                  WHEN SUBSTR(v_TDIE_UOS_INV_DTL_REC.RECORD_TYPE,1,3) = 'CAN' THEN
                                                                     '-' ||  v_LINE_ELEMENTS(18)
                                                                  ELSE
                                                                     v_LINE_ELEMENTS(18)
                                                                END;
              v_TDIE_UOS_INV_DTL_REC.LAST_ACTUAL_READ_VALUE := v_LINE_ELEMENTS(19);
              v_TDIE_UOS_INV_DTL_REC.LAST_ACTUAL_READ_DATE  := CASE
                                                                  WHEN v_LINE_ELEMENTS(20) IS NULL THEN
                                                                      NULL
                                                                  ELSE
                                                                      CONVERT_TO_DATE(v_LINE_ELEMENTS(20), g_UOS_DATE_FORMAT)
                                                                END;

              INS_TDIE_UOS_INVOICE_DETAIL(v_TDIE_UOS_INV_DTL_REC);

            END IF;--IF v_LINE_ELEMENTS(3) IS NOT NULL THEN

         -- PROCESS Footer Record ----------------------------------------------
         WHEN v_LINE_ELEMENTS(2) = 3 THEN
            v_TDIE_UOS_INV_REC.RECORDS_IMPORTED          := v_PROCESSED_REC_CNT;
            v_TDIE_UOS_INV_REC.TOTAL_DETAIL_LINES        := v_LINE_ELEMENTS(3);
            v_TDIE_UOS_INV_REC.RECORDS_IMPORTED          := v_PROCESSED_REC_CNT;
            v_TDIE_UOS_INV_REC.NET_CHARGE_AMT_IMPORTED   := 0;
            v_TDIE_UOS_INV_REC.GROSS_CHARGE_AMT_IMPORTED := 0;
            v_VAT_TOTAL                                  := 0;

            -- roll up the totals for GROSS amounts
            BEGIN
               SELECT NVL(SUM(NVL(TUID.CHARGE,0)),0)
                 INTO v_TDIE_UOS_INV_REC.GROSS_CHARGE_AMT_IMPORTED
                 FROM TDIE_UOS_INVOICE_DETAIL TUID
                WHERE TUID.INVOICE_NUMBER = v_TDIE_UOS_INV_REC.INVOICE_NUMBER;

               EXCEPTION
                  WHEN NO_DATA_FOUND THEN
                     v_TDIE_UOS_INV_REC.GROSS_CHARGE_AMT_IMPORTED := 0;
            END;

            -- roll up the totals for NET amounts
            BEGIN
               SELECT NVL(SUM(NVL(TUID.CHARGE,0)),0)
                 INTO v_VAT_TOTAL
                 FROM TDIE_UOS_INVOICE_DETAIL TUID
                WHERE TUID.INVOICE_NUMBER = v_TDIE_UOS_INV_REC.INVOICE_NUMBER
                  AND TUID.RECORD_TYPE    = 'VAT';

               v_TDIE_UOS_INV_REC.NET_CHARGE_AMT_IMPORTED := (  v_TDIE_UOS_INV_REC.GROSS_CHARGE_AMT_IMPORTED
                                                               - v_VAT_TOTAL);

               EXCEPTION
                  WHEN NO_DATA_FOUND THEN
                     v_TDIE_UOS_INV_REC.NET_CHARGE_AMT_IMPORTED := v_TDIE_UOS_INV_REC.GROSS_CHARGE_AMT_IMPORTED;
            END;

            -- Count the distinct number of MPRNs on this backing sheet.
            BEGIN
               SELECT COUNT(a.MPRN)
                 INTO v_TDIE_UOS_INV_REC.MPRN_COUNT
                 FROM (SELECT DISTINCT TUID.MPRN AS MPRN
                         FROM TDIE_UOS_INVOICE_DETAIL TUID
                        WHERE TUID.INVOICE_NUMBER = v_TDIE_UOS_INV_REC.INVOICE_NUMBER
                       ) a;

               EXCEPTION
                  WHEN NO_DATA_FOUND THEN
                     v_TDIE_UOS_INV_REC.MPRN_COUNT := 0;
            END;

            UPD_TDIE_UOS_INVOICE(v_TDIE_UOS_INV_REC);

         ELSE
            -- RAISE INVALID SEGMENT ERROR
            LOGS.LOG_WARN(p_EVENT_TEXT => 'Current record not associated with current invoice.'||
                                          ' Skipping record and continuing to process next record.');

      END CASE;--CASE v_LINE_ELEMENTS(1)

      i := i + 1;

   END LOOP;--WHILE i <= v_LINES.LAST LOOP

END IMPORT_UOS;



--------------------------------------------------------------------------------
--                PUBLIC PROCEDURES AND FUNCTIONS
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
FUNCTION WHAT_VERSION RETURN VARCHAR IS
BEGIN
   RETURN '$Revision: 1.6 $';
END WHAT_VERSION;

--------------------------------------------------------------------------------
PROCEDURE IMPORT
   (
   p_IMPORT_FILE       IN CLOB,
   p_IMPORT_FILE_PATH  IN VARCHAR2,
   p_FILE_TYPE         IN VARCHAR2,
   p_PROCESS_ID       OUT VARCHAR2,
   p_PROCESS_STATUS   OUT NUMBER,
   p_MESSAGE          OUT VARCHAR2
   )
IS
   c_PROCEDURE_NAME CONSTANT VARCHAR(30) := 'IMPORT';
BEGIN
	SAVEPOINT IMPORT_BACKING_SHEET_FILE;

   -- Initialize the global variables.
   g_IMPORT_TIMESTAMP    := NULL;
   g_IMPORT_FILE_PATH    := NULL;
   g_PROCESS_ID          := NULL;

	SELECT CURRENT_TIMESTAMP INTO g_IMPORT_TIMESTAMP FROM DUAL;
	g_IMPORT_FILE_PATH := p_IMPORT_FILE_PATH;

	LOGS.START_PROCESS('Import Backing Sheet');

	SD.VERIFY_ACTION_IS_ALLOWED(MM_TDIE_UTIL.g_ACTION_IMPORT_TDIE);
	ASSERT(p_IMPORT_FILE IS NOT NULL, 'The import file must not be null.', MSGCODES.c_ERR_ARGUMENT);
	ASSERT(p_IMPORT_FILE_PATH IS NOT NULL, 'The import file path must not be null.', MSGCODES.c_ERR_ARGUMENT);

	p_PROCESS_ID := TO_CHAR(LOGS.CURRENT_PROCESS_ID);
	g_PROCESS_ID := p_PROCESS_ID;

	LOGS.LOG_INFO('p_FILE_TYPE = '||TO_CHAR(p_FILE_TYPE) || '');

	IF LOGS.IS_DEBUG_ENABLED THEN
		LOGS.LOG_DEBUG(g_PACKAGE_NAME||'.'||c_PROCEDURE_NAME);
		LOGS.LOG_INFO_MORE_DETAIL(p_EVENT_TEXT => 'TDIE Backing Sheet Import Contents (see attachment)');
		LOGS.POST_EVENT_DETAILS(p_DETAIL_TYPE => 'FILE IMPORT',
		p_CONTENT_TYPE => CONSTANTS.MIME_TYPE_CSV,
		p_CONTENTS => p_IMPORT_FILE);
		LOGS.LOG_DEBUG('p_IMPORT_FILE_PATH = '||p_IMPORT_FILE_PATH);
	END IF;

	CASE p_FILE_TYPE
		WHEN g_backing_sheet_duos THEN
			IMPORT_DUOS(p_IMPORT_FILE);
		WHEN g_backing_sheet_duos_ni THEN
			IMPORT_DUOS_NI(p_IMPORT_FILE);
		WHEN g_backing_sheet_tuos THEN
			IMPORT_TUOS(p_IMPORT_FILE);
		WHEN g_backing_sheet_uos THEN
			IMPORT_UOS(p_IMPORT_FILE);
		ELSE
			ERRS.RAISE_BAD_ARGUMENT('Import File Type',p_FILE_TYPE,'Import File Type must be either DUoS (ROI), TUoS (ROI), or DUoS (NI).');
	END CASE;--CASE p_FILE_TYPE

  p_MESSAGE := 'File completed processing.';
	LOGS.STOP_PROCESS(p_PROCESS_STATUS => p_PROCESS_STATUS,
	                  p_FINISH_TEXT    => p_MESSAGE);
	COMMIT;
EXCEPTION
   WHEN MSGCODES.e_ERR_INVALID_NUMBER  OR
        MSGCODES.e_ERR_INVALID_DATE    OR
        MSGCODES.e_ERR_INVALID_FILE_TYPE THEN

      p_MESSAGE := 'Error(s) occurred while processing the file, possible invalid file type selected on import.';

      ERRS.LOG_AND_CONTINUE(p_EXTRA_MESSAGE => p_MESSAGE,
                            p_SAVEPOINT_NAME => 'IMPORT_BACKING_SHEET_FILE');

	    LOGS.STOP_PROCESS(p_PROCESS_STATUS => p_PROCESS_STATUS,
	                      p_FINISH_TEXT    => p_MESSAGE);

   WHEN OTHERS THEN
		ERRS.ABORT_PROCESS(p_SAVEPOINT_NAME => 'IMPORT_BACKING_SHEET_FILE');
END IMPORT;


END MM_TDIE_BACKING_SHEETS;
/