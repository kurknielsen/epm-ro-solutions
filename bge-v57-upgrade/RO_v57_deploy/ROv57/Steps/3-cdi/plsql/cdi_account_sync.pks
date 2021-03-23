CREATE OR REPLACE PACKAGE CDI_ACCOUNT_SYNC AS

PROCEDURE RUN_INTERFACE
   (
   p_FROM_DATE IN DATE DEFAULT SYSDATE,
   p_SYNC_DAYS IN PLS_INTEGER DEFAULT NULL,
   p_STATUS   OUT NUMBER,
   p_MESSAGE  OUT VARCHAR2
   );

PROCEDURE DEX_INTERFACE
   (
   p_BEGIN_DATE IN DATE,
   p_END_DATE   IN DATE,
   p_STATUS   OUT NUMBER,
   p_MESSAGE  OUT VARCHAR2
   );

PROCEDURE STAGE_CONTENT(p_FROM_DATE IN DATE, p_SYNC_DAYS IN PLS_INTEGER);

END CDI_ACCOUNT_SYNC;
/

