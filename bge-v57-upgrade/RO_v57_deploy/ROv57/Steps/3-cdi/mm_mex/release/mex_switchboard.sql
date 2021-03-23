create or replace package MEX_Switchboard is
-- $Revision: 1.14 $

FUNCTION WHAT_VERSION RETURN VARCHAR2;

c_Empty_Parameter_Map MEX_Util.Parameter_Map;

-- Possible values for MEX_RESULT.STATUS_CODE
c_Status_Success constant number := 0;
c_Status_Error constant number := 1;
c_Status_Access_Denied constant number := 2;
c_Status_File_Not_Found constant number := 3;
c_Status_No_More_Messages constant number := 4;
c_Status_Log_Only constant number := 5;

c_Soap_Namespace CONSTANT VARCHAR2(128) := 'http://schemas.xmlsoap.org/soap/envelope/';
c_Mex_FileList_Namespace CONSTANT VARCHAR2(128) := 'http://newenergyassoc.com/FileList';
c_Mex_FileList_Namespace_Def CONSTANT VARCHAR2(128) := 'xmlns="'||c_Mex_FileList_Namespace||'"';

-- set these globals prior to calling the Invoke() function
Procedure SetupSwitchboard(p_URL in varchar2,
                     p_Username in varchar2,
                          p_Password in varchar2);

Function GetSwitchboardURL return varchar2;
Function GetSwitchboardUsername return varchar2;

-- Call these to actually invoke the MEX Switchboard

-- If there is a request body either p_Request or p_Request_Binary should be set, but not both.
-- If both are set, the CLOB takes precedence and is what will actually be sent.
Function Invoke(p_Market in varchar2,
                p_Action in varchar2,
             p_Logger in out nocopy MEX_Logger,
             p_Cred in MEX_Credentials := NULL,
             p_Parms in MEX_Util.Parameter_Map := c_Empty_Parameter_Map,
             p_Request_ContentType in varchar2 := NULL,
            p_Request in Clob := NULL,
             p_Request_Binary in Blob := NULL,
            p_Log_Only in NUMBER := 0)
                return MEX_Result;

-- these helper methods are shortcuts for MEX Switchboard
-- internal markets/actions

Function FetchFile(p_FilePath in varchar2,
                   p_Logger in out nocopy MEX_Logger,
                   p_Cred in MEX_Credentials := NULL,
               p_Log_Only in NUMBER  :=0)
                     return MEX_Result;

-- If there is a request body either p_Request or p_Request_Binary should be set, but not both.
-- If both are set, the CLOB takes precedence and is what will actually be sent.
Function FetchURL(p_URL_to_Fetch in varchar2,
                 p_Logger in out nocopy MEX_Logger,
                 p_Cred in MEX_Credentials := NULL,
              p_SendAuthorization in boolean := false,
              p_Cookies in MEX_Cookie_Tbl := NULL,
                 p_Request_Headers in MEX_Util.Parameter_Map := c_Empty_Parameter_Map,
                p_Request_ContentType in varchar2 := NULL,
              p_Request in Clob := NULL,
              p_Request_Binary in Blob := NULL,
              p_Log_Only in NUMBER := 0)
                 return MEX_Result;

Function DequeueMessage(p_Message_Category in varchar2,
                      p_Logger in out nocopy MEX_Logger,
                        p_Message_Recipient in varchar2 := NULL,
                     p_Cred in MEX_Credentials := NULL)
                     return MEX_Result;
                  
Function EnqueueMessage(p_Message_Category in varchar2,
                      p_Logger in out MEX_Logger,
                  p_Request_ContentType in varchar2,
                  p_Request in Clob,
                        p_Message_Recipient in varchar2 := NULL,
                     p_Cred in MEX_Credentials := NULL)
                     return MEX_Result;

-- Helper method to get the error message for a particular MEX_Result
Function GetErrorText(p_Result in MEX_Result) return varchar2;

function get_logger
   (
   p_external_system_id in number,
   p_external_account_name in varchar2,
   p_process_name in varchar2,
   p_exchange_name in varchar2,
   p_log_type in number,
   p_trace_on in number
   ) return mm_logger_adapter;

Procedure ParseFileList(
         p_Clob_Resp in clob,
         p_FileNames out string_collection, -- List of files in Zip File
         p_SheetNames out string_collection -- List of Sheets in Excel doc
         );

procedure init_mex
   (
   p_external_system_id in number,
   p_external_account_name in VARCHAR2,
   p_process_name in varchar2,
   p_exchange_name in varchar2,
   p_log_type in number,
   p_trace_on in number,
   p_credentials out mex_credentials,
   p_logger in out nocopy mm_logger_adapter,
   p_is_public   in boolean := false
   );

procedure init_mex
   (
   p_external_system_id in number,
   p_process_name in varchar2,
   p_exchange_name in varchar2,
   p_log_type in number,
   p_trace_on in number,
   p_credentials out mm_credentials_set,
   p_logger in out nocopy mm_logger_adapter,
   p_is_public   in boolean := false
   );
    
FUNCTION TEST_MEX_URL_FETCH RETURN VARCHAR2;

g_log_all constant number(1) := 3;

end MEX_Switchboard;
/
create or replace package body MEX_Switchboard is
---------------------------------------------------------------------------------------------------
g_URL varchar2(512);
g_Username varchar2(32);
g_Password varchar2(32);


g_OTHER_PARM_PREFIX VARCHAR2(4) := 'mex';
----------------------------------------------------------------------------------------------------
FUNCTION WHAT_VERSION RETURN VARCHAR2 IS
BEGIN
    RETURN '$Revision: 1.14 $';
END WHAT_VERSION;
---------------------------------------------------------------------------------------------------
Procedure SetupSwitchboard(p_URL in varchar2,
                     p_Username in varchar2,
                          p_Password in varchar2)
                     as
begin
   g_URL := p_URL;
   g_Username := p_Username;
   g_Password := p_Password;
end SetupSwitchboard;
---------------------------------------------------------------------------------------------------
Procedure Initialize
AS
   v_encoded_password varchar2(32);
   v_message VARCHAR2(64);
begin
   g_URL := get_dictionary_value('URL',0,'MarketExchange');
   security_controls.get_external_uname_password(
                                      security_controls.get_external_credential_id(
                                    ec.es_mex_switchboard,
                                    null),
                                      g_Username,
                                      v_encoded_password);
   g_Password := security_controls.decode(v_encoded_password);
exception
   when others then
      v_message := 'Unable to initialize the URL and external credentials.';
      logs.log_error(v_message);
      errs.raise(msgcodes.c_err_general,v_message);
end Initialize;
---------------------------------------------------------------------------------------------------
Function GetSwitchboardURL return varchar2 is
begin
   return g_URL;
end GetSwitchboardURL;
---------------------------------------------------------------------------------------------------
Function GetSwitchboardUsername return varchar2 is
begin
   return g_Username;
end GetSwitchboardUsername;
---------------------------------------------------------------------------------------------------
Procedure Send_Request(p_Request in Clob,
                  p_Response out Clob,
                  p_HeaderNames out String_Collection,
                  p_HeaderValues out String_Collection,
                  p_ErrorMessage out varchar2)
                  is
v_HTTP_Req utl_http.req;
v_HTTP_Resp utl_http.resp;
v_Request_Len number;
v_Pos number;
v_Count number;
v_Request_Text varchar2(32766);
v_Response_Text varchar2(32766); -- BZ 30450
v_Len number;
v_timeout_text varchar2(36);
v_timeout number;
begin
   LOGS.LOG_DEBUG_MORE_DETAIL('Send_Request: Begininng Send_Request');
   
   -- raise Request_Failed error if an HTTP error occurs
   utl_http.set_response_error_check(true);
   utl_http.set_detailed_excp_support(false);
   
   -- extend timeout
    v_timeout_text := get_dictionary_value('MEX Timeout (sec)', CONSTANTS.GLOBAL_MODEL, 'MarketExchange');
    --If the setting does not exist or is set to Null, time out after 600 secs
    IF v_timeout_text IS NULL 
       THEN v_timeout := 600;
     ELSE 
        BEGIN
        v_timeout := TO_NUMBER(v_timeout_text);
          --The minimum timeout is 1 sec. 
          IF v_timeout <1 THEN
             LOGS.LOG_WARN('MEX timeout minimum is 1 sec ('|| v_timeout ||' set in Global | Market Exchange system setting)');
             v_timeout := 1;
          END IF;
          IF v_timeout  != trunc(v_timeout) THEN
            LOGS.LOG_WARN('MEX timeout must be an integer ('|| v_timeout ||' set in Global | Market Exchange system setting)');
            v_timeout := 600;
        END IF;
        EXCEPTION
           WHEN OTHERS THEN
            LOGS.LOG_WARN('MEX timeout must be an integer ('||v_timeout_text||' set in Global | Market Exchange system setting)');
            v_timeout := 600;
        END;
    END IF;
   utl_http.set_transfer_timeout(v_timeout);

   v_HTTP_Req := utl_http.begin_request(g_URL, 'POST');
   -- disable cookies for this request
   utl_http.set_cookie_support(v_HTTP_Req, false);
   -- authentication
   if g_Username is not null then
      utl_http.set_authentication(v_HTTP_Req, g_Username, g_Password);
   end if;

   LOGS.LOG_DEBUG_MORE_DETAIL('Send_Request: Building HTTP Request');
   -- upload request body
   v_Request_Len := dbms_lob.getlength(p_Request);
    utl_http.set_header(v_HTTP_Req, 'Content-Type', 'application/x-www-form-urlencoded');
    utl_http.set_header(v_HTTP_Req, 'Content-Length', v_REQUEST_LEN);
   -- write the CLOB request data
    v_Pos := 1;
    while v_Pos <= v_Request_Len loop
      v_Len := 8192;
        dbms_lob.read(p_Request, v_Len, v_Pos, v_Request_Text);
      utl_http.write_text(v_HTTP_Req, v_Request_Text);
        v_Pos := v_Pos + v_Len;
    end loop;

   LOGS.LOG_DEBUG_MORE_DETAIL('Send_Request: Request Built. Sending the Request');
   
   -- get the response
   v_HTTP_Resp := utl_http.get_response(v_HTTP_Req);
   
    LOGS.LOG_DEBUG_MORE_DETAIL('Send_Request: Response received');

    -- read it into CLOB
   dbms_lob.createtemporary(p_Response, true);
   dbms_lob.open(p_Response, dbms_lob.lob_readwrite);
   
    LOGS.LOG_DEBUG_MORE_DETAIL('Send_Request: Begin reading text from HTTP Response');
   
    loop
       begin
          utl_http.read_text(v_HTTP_Resp, v_Response_Text, 8192);
        exception
           when utl_http.end_of_body then
               v_Response_Text := '';
        end;
        exit when nvl(length(v_Response_Text),0) = 0;
      
      LOGS.LOG_DEBUG_MORE_DETAIL('Send_Request: begin writeappend');      
        dbms_lob.writeappend(p_Response, length(v_Response_Text), v_Response_Text);
        LOGS.LOG_DEBUG_MORE_DETAIL('Send_Request: writeappend ok');
   end loop;
    dbms_lob.close(p_Response);
   
   LOGS.LOG_DEBUG_MORE_DETAIL('Send_Request: Done reading text from HTTP Response');

   -- gather response headers
   p_HeaderNames := String_Collection();
   p_HeaderValues := String_Collection();
   
   LOGS.LOG_DEBUG_MORE_DETAIL('Send_Request: get header count');
   v_Count := utl_http.get_header_count(v_HTTP_Resp);
   
   v_Pos := 1;
   while v_Pos <= v_Count loop
      p_HeaderNames.extend();
      p_HeaderValues.extend();
      
      LOGS.LOG_DEBUG_MORE_DETAIL('Send_Request: get header: ' || p_HeaderNames(p_HeaderNames.last));
        utl_http.get_header(v_HTTP_Resp, v_Pos, p_HeaderNames(p_HeaderNames.last), p_HeaderValues(p_HeaderValues.last));
      v_Pos := v_Pos+1;
   end loop;

   utl_http.end_response(v_HTTP_Resp);
   -- success!
   p_ErrorMessage := null;

exception
   when utl_http.Request_Failed then
        ERRS.LOG_AND_CONTINUE('Send_Request: Request Failed Exception caught.',p_LOG_LEVEL => LOGS.c_LEVEL_DEBUG_MORE_DETAIL);
        p_ErrorMessage := utl_http.get_detailed_sqlerrm||' ('||utl_http.get_detailed_sqlcode||')';
   when others then
        ERRS.LOG_AND_CONTINUE('Send_Request: Others Exception caught.',p_LOG_LEVEL => LOGS.c_LEVEL_DEBUG_MORE_DETAIL);
        p_ErrorMessage := sqlerrm||' ('||sqlcode||')';

end Send_Request;
---------------------------------------------------------------------------------------------------
Function Invoke(p_Market in varchar2,
                p_Action in varchar2,
             p_Logger in out MEX_Logger,
             p_Cred in MEX_Credentials := NULL,
             p_Parms in MEX_Util.Parameter_Map := c_Empty_Parameter_Map,
             p_Request_ContentType in varchar2 := NULL,
            p_Request in Clob := NULL,
             p_Request_Binary in Blob := NULL,
            p_Log_Only in NUMBER := 0)
                return MEX_Result is
v_Request CLOB;
v_Pretty_Request CLOB;
v_Request_Headers CLOB;
v_Must_Free_CLOBs boolean := false;
v_Response_Headers CLOB := NULL;
v_Response CLOB := NULL;
v_ParmName varchar2(256);
v_HeaderNames String_Collection;
v_HeaderValues String_Collection;
v_ErrorMessage varchar2(32767);
v_Result MEX_Result;
v_Idx number;
begin

   p_Logger.LOG_START(p_Market, p_Action);

    dbms_lob.createtemporary(v_Request, true);
    dbms_lob.createtemporary(v_Request_Headers, true);
   v_Must_Free_CLOBs := true;

   dbms_lob.open(v_Request, dbms_lob.lob_readwrite);
   p_Logger.LOG_DEBUG('Temporary Request CLOB opened');

    -- also track a "pretty" query string - this goes into the log and will be more
    -- readable than actual query string (which is ugly due to url encoding)
   dbms_lob.open(v_Request_Headers, dbms_lob.lob_readwrite);
   p_Logger.LOG_DEBUG('Temporary Request Headers CLOB opened');

   -- start building the request
    cd.build_query_string('market', p_Market, v_Request, v_Request_Headers);
    cd.build_query_string('action', p_Action, v_Request, v_Request_Headers);

   -- credentials
   if p_Cred is NULL then
      MEX_Credentials().ADD_TO_REQUEST(v_Request, v_Request_Headers);
   else
      p_Cred.ADD_TO_REQUEST(v_Request, v_Request_Headers);
      p_Logger.LOG_DEBUG('Added credentials to request for '||nvl(p_Cred.USERNAME,'?'));
   end if;

   -- request contents
   if p_Request is not NULL or p_Request_Binary is not NULL then
       cd.build_query_string('includeRequest', '1', v_Request, v_Request_Headers);
      -- We don't need the request content-type in the "pretty" string as it is redundant. It will
      -- be available as the CONTENT_TYPE field when we log the request body attachment.
       cd.build_query_string('requestContentType', p_Request_ContentType, v_Request, v_Request_Headers, true);
      if p_Request is not NULL then
         if p_Request_Binary is not NULL then
            p_Logger.LOG_WARN('Both character and binary request bodies were specified. Using character request body.');
         end if;
         v_Pretty_Request := p_Request;
         -- character body - final parameter tells routine to encode it via base-64
         -- set the p_EXCLUDE_FROM_PRETTY parameter to true, we do not want the request contents in the Request_Headers clob
          cd.build_query_string('requestContents', p_Request, v_Request, v_Request_Headers, true, null, true);
      else
         v_Pretty_Request := '<Base64>'||CD.BASE64ENCODE(p_Request_Binary)||'</Base64>';
         -- binary body - routine will encode it via base-64
         -- set the p_EXCLUDE_FROM_PRETTY parameter to true, we do not want the request contents in the Request_Headers clob
          cd.build_query_string('requestContents', p_Request_Binary, v_Request, v_Request_Headers, true);
      end if;
      p_Logger.LOG_DEBUG('Added request contents/body to request');
   else
       cd.build_query_string('includeRequest', '0', v_Request, v_Request_Headers);
      v_Pretty_Request := NULL;
   end if;

   -- extra parameters
   v_ParmName := p_Parms.first;
   while p_Parms.exists(v_ParmName) loop
      cd.build_query_string(g_OTHER_PARM_PREFIX||v_ParmName, p_Parms(v_ParmName), v_Request, v_Request_Headers);
      v_ParmName := p_Parms.next(v_ParmName);
   end loop;

   -- done building the request
    dbms_lob.close(v_Request);
    dbms_lob.close(v_Request_Headers);

   -- Log the Request Data
   p_Logger.log_request(v_Request_Headers, v_Pretty_Request, p_Request_ContentType);

   -- perform HTTP request if not log only
   if p_Log_Only = 0 then
      Send_Request(v_Request, v_Response, v_HeaderNames, v_HeaderValues, v_ErrorMessage);
      p_Logger.LOG_DEBUG('HTTP transaction complete');
   else
      p_Logger.LOG_DEBUG('Log only mode');
   end if;

    dbms_lob.freetemporary(v_Request);
    dbms_lob.freetemporary(v_Request_Headers);
   v_Must_Free_CLOBs := false;
   p_Logger.log_debug('Temporary CLOBs have been freed');

   -- create return value
   if v_ErrorMessage is not null then
      v_Result := MEX_Result(v_ErrorMessage);
      p_Logger.LOG_ERROR(v_ErrorMessage);
   elsif p_Log_Only = 0 then
      v_Result := MEX_Result(v_HeaderNames, v_HeaderValues, v_Response);

      -- Build a clob with the response headers to be logged
      v_Idx := v_HeaderNames.first;
      dbms_lob.createtemporary(v_Response_Headers, true);
      dbms_lob.open(v_Response_Headers, dbms_lob.lob_readwrite);
      while v_HeaderNames.exists(v_Idx) loop
         dbms_lob.append(v_Response_Headers, v_HeaderNames(v_Idx)||': '||v_HeaderValues(v_Idx) || UTL_TCP.CRLF || UTL_TCP.CRLF);
         v_Idx := v_HeaderNames.next(v_Idx);
      end loop;
      dbms_lob.close(v_Response_Headers);

      -- Log the Response Data
      p_Logger.log_response(v_Response_Headers, v_Result.RESPONSE,v_Result.RESPONSE_CONTENTTYPE);

      dbms_lob.freetemporary(v_Response_Headers);
   else
      v_Result := mex_result('Log Only mode');
      v_Result.STATUS_CODE := c_Status_Log_Only;
   end if;
   p_Logger.LOG_STOP(v_Result);

   -- done!
   return v_Result;

exception
   when others then
      v_Result := MEX_Result(SQLERRM||' ('||SQLCODE||')');
      begin
         if v_Must_Free_CLOBs then
                dbms_lob.freetemporary(v_Request);
                dbms_lob.freetemporary(v_Request_Headers);
         end if;
         if v_Response is not null then
                dbms_lob.freetemporary(v_Response);
         end if;
         if v_Response_Headers is not null then
                dbms_lob.freetemporary(v_Response_Headers);
         end if;
         p_Logger.LOG_ERROR(SQLERRM||' ('||SQLCODE||')');
         p_Logger.LOG_STOP(v_Result);
      exception
         when others then
            null; -- ignore further exceptions here
      end;
      return v_Result;
end Invoke;
---------------------------------------------------------------------------------------------------
Function FetchFile(p_FilePath in varchar2,
                p_Logger in out MEX_Logger,
                   p_Cred in MEX_Credentials := NULL,
               p_Log_Only in NUMBER :=0)
                   return MEX_Result is
v_Parms MEX_Util.Parameter_Map;
v_return MEX_Result;
begin
   v_Parms('file') := p_FilePath;
   v_return := Invoke(p_Market => 'sys',
                  p_Action => 'fetchfile',
                  p_Logger => p_Logger,
                  p_Cred => p_Cred,
                  p_Parms => v_Parms,
                  p_Log_Only => p_Log_Only);

   -- handle special fetch file response headers if not logonly
   if v_return.STATUS_CODE <> c_Status_Log_Only then
      if upper(v_return.Get_Header('MEX-File-Not-Found')) = 'TRUE' then
         v_return.Status_Code := c_Status_File_Not_Found;
      elsif upper(v_return.Get_Header('MEX-Access-Denied')) = 'TRUE' then
         v_return.Status_Code := c_Status_Access_Denied;
      end if;
   end if;

   -- done!
   return v_return;
end FetchFile;
---------------------------------------------------------------------------------------------------
Function FetchURL(p_URL_to_Fetch in varchar2,
                 p_Logger in out MEX_Logger,
                 p_Cred in MEX_Credentials := NULL,
              p_SendAuthorization in boolean := false,
              p_Cookies in MEX_Cookie_Tbl := NULL,
                 p_Request_Headers in MEX_Util.Parameter_Map := c_Empty_Parameter_Map,
                p_Request_ContentType in varchar2 := NULL,
              p_Request in Clob := NULL,
              p_Request_Binary in Blob := NULL,
              p_Log_Only in NUMBER := 0)
                 return MEX_Result is
v_Parms MEX_Util.Parameter_Map;
v_idx binary_integer;
v_name varchar2(256);
v_cookie_value varchar2(4000) := NULL;
begin
   v_Parms('url') := p_URL_to_Fetch;
   if p_SendAuthorization then
      v_Parms('sendAuth') := '1';
   end if;
   -- add request headers
    v_name := p_Request_Headers.first;
    while p_Request_Headers.exists(v_name) loop
        v_Parms('MEX-REQUEST-HEADER-'||v_name) := p_Request_Headers(v_name);
        v_name := p_Request_Headers.next(v_name);
    end loop;

   -- add cookie header
   if p_Cookies is not NULL then
      v_idx := p_Cookies.first;
      while p_Cookies.exists(v_idx) loop
         if v_cookie_value is not NULL then
            v_cookie_value := v_cookie_value || '; ';
         end if;
         v_cookie_value := v_cookie_value || p_Cookies(v_idx).Name || '=' || p_Cookies(v_idx).Value;
         v_idx := p_Cookies.next(v_idx);
      end loop;
      if v_cookie_value is not NULL then
         v_Parms('MEX-REQUEST-HEADER-Cookie') := v_cookie_value;
      end if;
   end if;

   -- invoke the switchboard
   return Invoke('sys','fetchurl',p_Logger,p_Cred,v_Parms,p_Request_ContentType,p_Request,p_Request_Binary, p_Log_Only);
end FetchURL;
---------------------------------------------------------------------------------------------------
Function DequeueMessage(p_Message_Category in varchar2,
                      p_Logger in out MEX_Logger,
                        p_Message_Recipient in varchar2 := NULL,
                     p_Cred in MEX_Credentials := NULL)
                     return MEX_Result is
v_Parms MEX_Util.Parameter_Map;
v_return MEX_Result;
begin
   v_Parms('category') := p_Message_Category;
   if p_Message_Recipient is not NULL then
      v_Parms('recipient') := p_Message_Recipient;
   end if;
   v_return := Invoke('msg-queue','download',p_Logger,p_Cred,v_Parms);

   -- handle special message queue response headers
   if upper(v_return.Get_Header('MEX-Message-Queue-Empty')) = 'TRUE' then
      v_return.Status_Code := c_Status_No_More_Messages;
   end if;

   -- done!
   return v_return;
end DequeueMessage;
---------------------------------------------------------------------------------------------------
Function EnqueueMessage(p_Message_Category in varchar2,
                      p_Logger in out MEX_Logger,
                  p_Request_ContentType in varchar2,
                  p_Request in Clob,
                        p_Message_Recipient in varchar2 := NULL,
                     p_Cred in MEX_Credentials := NULL)
                     return MEX_Result is
v_Parms MEX_Util.Parameter_Map;
begin
   v_Parms('category') := p_Message_Category;
   if p_Message_Recipient is not NULL then
      v_Parms('recipient') := p_Message_Recipient;
   end if;
   return Invoke('msg-queue','recv',p_Logger,p_Cred,v_Parms,p_Request_ContentType, p_Request);
end EnqueueMessage;
---------------------------------------------------------------------------------------------------
Function GetErrorText(p_Result in MEX_Result) return varchar2 is
begin
   return case p_Result.STATUS_CODE
           when c_Status_Success then
              null
           when c_Status_Error then
              dbms_lob.substr(p_Result.RESPONSE, 4000, 1)
           when c_Status_Access_Denied then
              'Access Denied'
           when c_Status_File_Not_Found then
              'File Not Found'
           when c_Status_No_More_Messages then
              'Message Queue Empty'
           end;
end GetErrorText;
---------------------------------------------------------------------------------------------------
/* This procedure parses the zip or Excel file into FileNames or SheetNames resp.
* It returns either a collection of FileNames or Sheetnames.
* It uses the FileListNameSpace constant declared in this package to parse the xml file
* that we get from the clob.
*/
Procedure ParseFileList(
         p_Clob_Resp in clob,
         p_FileNames out string_collection, -- List of files in Zip File
         p_SheetNames out string_collection -- List of Sheets in Excel doc
         ) AS

   v_xml xmltype;

BEGIN
   IF (P_CLOB_RESP IS NOT NULL) THEN
          -- Build XML type with the clob resp
         v_XML := XMLTYPE.CREATEXML(p_CLOB_RESP);

      SELECT EXTRACTVALUE(VALUE(U), '/File', c_Mex_FileList_Namespace_Def) as
                                   FILE_NAME,
               EXTRACTVALUE(VALUE(U), '/File/@sheetName',
                                   c_Mex_FileList_Namespace_Def) as SHEET_NAME
          BULK COLLECT INTO p_FileNames, p_SheetNames
          FROM TABLE(XMLSEQUENCE(EXTRACT(v_xml,
                             '/soap:Envelope/soap:Body/fl:FileList',
                         'xmlns:soap="' || c_Soap_Namespace || '" xmlns:fl="' ||
                         c_Mex_FileList_Namespace || '"'))) T,
               TABLE(XMLSEQUENCE(EXTRACT(value(T),
                   '/FileList/File',
                   c_Mex_FileList_Namespace_Def))) U;
   END IF;
END ParseFileList;
-------------------------------------------------------------------------------------
function get_logger
   (
   p_external_system_id in number,
   p_external_account_name in varchar2,
   p_process_name in varchar2,
   p_exchange_name in varchar2,
   p_log_type in number,
   p_trace_on in number
   ) return mm_logger_adapter is

v_logger       mm_logger_adapter;

begin
   v_logger := mm_logger_adapter(p_external_system_id,
                          p_external_account_name,
                          substr(p_process_name,1,64),
                          substr(p_exchange_name,1,64),
                          nvl(p_log_type,3),
                          nvl(p_trace_on,0));
   return v_logger;

end get_logger;
-------------------------------------------------------------------------------------
procedure raise_no_credentials
   (
   p_external_system_id in number,
   p_external_account_name in varchar2
   ) as
begin
   -- no credentials found! indicate external system and, if available, account name for missing credentials
   errs.raise(msgcodes.c_err_no_credentials,
         case when nvl(p_external_account_name,'?') <> '?' then p_external_account_name||'@' else null end
         ||text_util.to_char_entity(p_external_system_id, ec.ed_external_system));
end raise_no_credentials;
-------------------------------------------------------------------------------------
function get_mex_credentials
   (
   p_external_system_id in number,
   p_credential_id in number
   ) return mex_credentials is
v_is_using_uname_pw number(1);
v_uname varchar2(64) := null;
v_pwd varchar2(64) := null;
v_number_of_certs number(1);
v_cert_contents clob;
v_cert_pwd varchar2(64);
v_external_account_name external_credentials.external_account_name%type;
v_certs mex_certificate_tbl := mex_certificate_tbl();
begin
   select nvl(a.has_uname_pwd_credentials,0), nvl(a.number_of_certificates,0)
   into v_is_using_uname_pw, v_number_of_certs
   from external_system a
   where a.external_system_id = p_external_system_id;

   select max(b.external_account_name) -- if credential_id = null then this will return null
   into v_external_account_name
   from external_credentials b
   where b.credential_id = p_credential_id;

   if v_is_using_uname_pw = 0 and v_number_of_certs = 0 then
      return null; -- ignore credential information since this system requires nothing
   elsif p_credential_id is null then
      -- no credentials!
      raise_no_credentials(p_external_system_id, v_external_account_name);
   end if;

   -- we don't support the use of more than 2 certs
   assert(v_number_of_certs <= 2,
         text_util.to_char_entity(p_external_system_id, ec.ed_external_system, true)||' requires '||v_number_of_certs||' certificates.'||
         'More than 2 certificates is not supported.');

   if v_is_using_uname_pw <> 0 then
      security_controls.get_external_uname_password(p_credential_id, v_uname, v_pwd);
      -- username or password values are missing?
      if v_uname is null or v_pwd is null then
         raise_no_credentials(p_external_system_id, v_external_account_name);
      end if;
   end if;

   if v_number_of_certs > 0 then
      begin
         security_controls.get_external_certificate(p_credential_id, security_controls.g_auth_cert_type, v_cert_contents, v_cert_pwd);
         v_certs.extend();
         v_certs(v_certs.last) := mex_certificate(v_cert_contents, v_cert_pwd, security_controls.g_auth_cert_type);
      exception
         when no_data_found then
            -- auth certificate not found? raise missing credentials
            raise_no_credentials(p_external_system_id, v_external_account_name);
      end;
   end if;
   if v_number_of_certs > 1 then
      begin
         security_controls.get_external_certificate(p_credential_id, security_controls.g_sig_cert_type, v_cert_contents, v_cert_pwd);
         v_certs.extend();
         v_certs(v_certs.last) := mex_certificate(v_cert_contents, v_cert_pwd, security_controls.g_sig_cert_type);
      exception
         when no_data_found then
            -- signature certificate not found? raise missing credentials
            raise_no_credentials(p_external_system_id, v_external_account_name);
      end;
   end if;

   return mex_credentials(v_is_using_uname_pw, v_uname, v_pwd, v_number_of_certs, v_certs, v_external_account_name);
end get_mex_credentials;
-------------------------------------------------------------------------------------
function get_credentials
   (
   p_external_system_id in number,
   p_external_account_name in varchar2 := null
   ) return mex_credentials is
begin
   return get_mex_credentials(
            p_external_system_id,
                security_controls.get_external_credential_id(
                        p_external_system_id,
                        p_external_account_name
                  )
            );
end get_credentials;
-------------------------------------------------------------------------------------
function get_credentials_all_accounts
   (
   p_external_system_id in number
   ) return mex_credentials_tbl is
v_accounts string_collection;
v_idx binary_integer;
v_credential_id number;
v_credentials mex_credentials_tbl := mex_credentials_tbl();
begin
    -- get the credentials
    v_accounts := security_controls.get_avail_external_accounts(p_external_system_id);
    v_idx      := v_accounts.first;
    -- loop over each external account and fetch the credentials for it
    while v_accounts.exists(v_idx) loop
      v_credential_id := security_controls.get_external_credential_id(
                                    p_external_system_id, v_accounts(v_idx));
        v_credentials.extend();
      v_credentials(v_credentials.last) := get_mex_credentials(p_external_system_id, v_credential_id);
        v_idx := v_accounts.next(v_idx);
    end loop;
      return v_credentials;
end get_credentials_all_accounts;
---------------------------------------------------------------------------------
procedure init_mex
   (
   p_external_system_id in number,
   p_external_account_name in VARCHAR2,
   p_process_name in varchar2,
   p_exchange_name in varchar2,
   p_log_type in number,
   p_trace_on in number,
   p_credentials out mex_credentials,
   p_logger in out nocopy mm_logger_adapter,
   p_is_public   in boolean := false
   ) as
begin
   if p_logger is null then
      -- get a logger object
      p_logger := get_logger(p_external_system_id,
                          p_external_account_name,
                          p_process_name,
                          p_exchange_name,
                          nvl(p_log_type,g_log_all),
                          nvl(p_trace_on,0));
   else
      p_logger.external_system_id := p_external_system_id;
      p_logger.external_account_name := p_external_account_name;
      p_logger.process_name := p_process_name;
      p_logger.exchange_name := p_exchange_name;
      p_logger.log_type := nvl(p_log_type,g_log_all);
      p_logger.trace_on := nvl(p_trace_on,0);
   end if;
   -- get the credentials
   if p_is_public = false then
      p_credentials := get_credentials(p_external_system_id, p_external_account_name);
   end if;

end init_mex;
-------------------------------------------------------------------------------------
procedure init_mex
   (
   p_external_system_id in number,
   p_process_name in varchar2,
   p_exchange_name in varchar2,
   p_log_type in number,
   p_trace_on in number,
   p_credentials out mm_credentials_set,
   p_logger in out nocopy mm_logger_adapter,
   p_is_public   in boolean := false
   ) as
begin
   if p_logger is null then
      -- get a logger object
      p_logger := get_logger(p_external_system_id,
                          null, -- don't know it yet
                          p_process_name,
                          p_exchange_name,
                          nvl(p_log_type, g_log_all),
                          nvl(p_trace_on,0));
   else
      p_logger.external_system_id := p_external_system_id;
      p_logger.external_account_name := null;
      p_logger.process_name := p_process_name;
      p_logger.exchange_name := p_exchange_name;
      p_logger.log_type := nvl(p_log_type,g_log_all);
      p_logger.trace_on := nvl(p_trace_on,0);
   end if;

   -- query for credentials
   if p_is_public = false then
      p_credentials := mm_credentials_set(
                        get_credentials_all_accounts(p_external_system_id),
                        p_logger
                        );
   end if;
end init_mex;
---------------------------------------------------------------------------------
FUNCTION TEST_MEX_URL_FETCH RETURN VARCHAR2 AS
   p_LOGGER        MM_LOGGER_ADAPTER;
   p_CRED          MEX_CREDENTIALS;
   p_PARAM_MAP     MEX_UTIL.PARAMETER_MAP;
   p_MEX_RESULT    MEX_RESULT;
    c_USER_NAME     CONSTANT APPLICATION_USER.USER_NAME%TYPE    := 'ventyxadmin';
    c_URL           CONSTANT VARCHAR2(512)                      := 'http://www.google.com';
BEGIN
   SECURITY_CONTROLS.SET_CURRENT_USER(c_USER_NAME);

   MEX_SWITCHBOARD.INIT_MEX(-1, c_USER_NAME, NULL, NULL, 0, 0, p_CRED, p_LOGGER, TRUE);

   p_MEX_RESULT := MEX_SWITCHBOARD.FETCHURL(c_URL,
                               p_LOGGER,
                               p_CRED,
                               FALSE,
                               NULL,
                               p_PARAM_MAP,
                               '',
                               NULL,
                               NULL,
                               0);

   RETURN p_MEX_RESULT.RESPONSE;
END TEST_MEX_URL_FETCH;
---------------------------------------------------------------------------------
BEGIN
   Initialize;
end MEX_Switchboard;
/
