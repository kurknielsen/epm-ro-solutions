CREATE OR REPLACE PACKAGE CDI_TASK AS

PROCEDURE IMPORT_SUPPLIER_CONTRACT(p_STATUS OUT NUMBER, p_MESSAGE OUT VARCHAR2);

PROCEDURE LOAD_SUPPLIER_CONTRACT_FILE
   (
   p_IMPORT_FILE      IN CLOB,
   p_IMPORT_FILE_PATH IN VARCHAR2,
   p_STATUS          OUT NUMBER,
   p_MESSAGE         OUT VARCHAR2
   );

PROCEDURE ACCOUNT_DATA_SYNC;

PROCEDURE WEATHER_DATA_IMPORT;

PROCEDURE PERIOD_USAGE_IMPORT;

PROCEDURE INTERVAL_USAGE_IMPORT;

PROCEDURE CUSTOMER_DATA_IMPORT;

PROCEDURE SEND_POLR_7DAY_AHEAD_PLC_EMAIL
   (
   p_BEGIN_DATE IN  DATE,
   p_END_DATE   IN  DATE,
   p_STATUS    OUT NUMBER,
   p_MESSAGE   OUT VARCHAR2
   );

PROCEDURE SEND_POLR_ESCHEDULE_EMAIL
   (
   p_BEGIN_DATE IN DATE,
   p_END_DATE   IN DATE,
   p_STATUS    OUT NUMBER,
   p_MESSAGE   OUT VARCHAR2
   );

PROCEDURE SEND_POLR_RFP_TICKETS_EMAIL
   (
   p_BEGIN_DATE IN DATE,
   p_END_DATE   IN DATE,
   p_STATUS    OUT NUMBER,
   p_MESSAGE   OUT VARCHAR2
   );

PROCEDURE INITIAL_BID_BLOCK_SIZE;

END CDI_TASK;
/
