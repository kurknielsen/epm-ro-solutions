CREATE OR REPLACE PACKAGE CDI_MEX_PJM AS
-- REVISION HISTORY
-- DATE       AUTHOR         DESCRIPTION
------------ -------------- --------------------------------------------------
--2020-11-13 Kurk Nielsen   Changed c_ACTION value from 'Action' to 'action'
------------------------------------------------------------------------------

-- Package Global Constants --
c_DATE         CONSTANT VARCHAR2(8)  := 'Date';
c_ACTION       CONSTANT VARCHAR2(8)  := 'action';
c_START        CONSTANT VARCHAR2(8)  := 'Start';
c_STOP         CONSTANT VARCHAR2(8)  := 'Stop';
c_DEBUG        CONSTANT VARCHAR2(8)  := 'Debug';
c_SANDBOX      CONSTANT VARCHAR2(8)  := 'Sandbox';
c_TYPE         CONSTANT VARCHAR2(8)  := 'Type';
c_ID           CONSTANT VARCHAR2(8)  := 'Id';
c_VERSION      CONSTANT VARCHAR2(8)  := 'Version';
c_CONTENTTYPE  CONSTANT VARCHAR2(8)  := 'text/xml';
c_REPORT_NAME  CONSTANT VARCHAR2(16) := 'ReportName';
c_REPORT_TYPE  CONSTANT VARCHAR2(16) := 'ReportType';
c_REPORT       CONSTANT VARCHAR2(16) := 'Report';
c_FORMAT       CONSTANT VARCHAR2(16) := 'Format';
c_ACCOUNT_TYPE CONSTANT VARCHAR2(16) := 'Account_Type';

PROCEDURE RUN_PJM_BROWSERLESS
   (
   p_CREDENTIALS IN MEX_CREDENTIALS,
   p_BEGIN_DATE IN DATE,
   p_END_DATE IN DATE,
   p_PARAMETER_MAP IN MEX_UTIL.PARAMETER_MAP,
   p_REQUEST_APPLICATION IN VARCHAR2,
   p_REQUEST_DIRECTORY IN VARCHAR2,
   p_REQUEST IN CLOB DEFAULT NULL,
   p_REQUEST_CONTENTTYPE IN VARCHAR2 DEFAULT c_CONTENTTYPE,
   p_LOGGER IN OUT NOCOPY MM_LOGGER_ADAPTER,
   p_RESPONSE OUT CLOB,
   p_STATUS OUT NUMBER
   );

PROCEDURE RUN_PJM_ACTION
   (
   p_CREDENTIALS IN MEX_CREDENTIALS,
   p_ACTION IN VARCHAR2, -- query|submit --
   p_XML_REQUEST_BODY IN XMLTYPE,
   p_PJM_NAMESPACE IN VARCHAR2,
   p_MARKET IN VARCHAR2, -- pjmerpm|pjmemkt|pjmeftr --
   p_XML_RESPONSE_BODY OUT XMLTYPE,
   p_STATUS OUT NUMBER,
   p_ERROR_MESSAGE OUT VARCHAR2,
   p_LOGGER IN OUT NOCOPY MM_LOGGER_ADAPTER
   );

END CDI_MEX_PJM;
/