create or replace package ET is

TYPE REF_CURSOR IS REF CURSOR;

FUNCTION WHAT_VERSION RETURN VARCHAR;

PROCEDURE GET_CREDENTIALS
	(
	p_CREDENTIALS OUT EXTERNAL_CREDENTIAL,
	p_ERROR_MESSAGE OUT VARCHAR2
	);
	
PROCEDURE READ_XML_FILES
	(
	p_CLOB IN CLOB,
	p_ETAG_ID OUT NUMBER,
    p_STATUS OUT NUMBER,
	p_ERROR_MESSAGE OUT VARCHAR2
	);

PROCEDURE GET_LATEST_ETAG_FILES
	(
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	);

PROCEDURE TEST_DISTRIBUTE_NEW_TAG_XML
	(
	p_ETAG_ID OUT NUMBER,
    p_STATUS OUT NUMBER,
	p_ERROR_MESSAGE OUT VARCHAR2
	);

PROCEDURE TEST_READ_XML_FILES
	(
    p_CLOB_KEY1_NAME IN OUT VARCHAR2,
	p_ETAG_ID OUT NUMBER,
    p_STATUS OUT NUMBER,
	p_ERROR_MESSAGE OUT VARCHAR2
	);

g_TRACE_ON BOOLEAN := TRUE;
g_DATE_TIME_FORMAT VARCHAR2(32) := 'YYYY-MM-DD"T"HH24:MI:SS"Z"';

INSUFFICIENT_PRIVILEGES EXCEPTION;
PRAGMA EXCEPTION_INIT(INSUFFICIENT_PRIVILEGES, -1031);
INVALID_DATE_RANGE EXCEPTION;
PRAGMA EXCEPTION_INIT(INVALID_DATE_RANGE, -20999);

v_DUPLICATE_ENTITY NUMBER := -1;
v_INSUFFICIENT_PRIVILEGES NUMBER := -2;

end ET;
/
create or replace package body ET is

-- ETAG package.

g_PACKAGE_NAME CONSTANT VARCHAR2(8) := 'ET';

g_CIPHER_KEY VARCHAR2(32) := 'password';

---------------------------------------------------------------------------------------------------
FUNCTION WHAT_VERSION RETURN VARCHAR IS
BEGIN
    RETURN '09012005.1';
END WHAT_VERSION;
---------------------------------------------------------------------------------------------------
FUNCTION PACKAGE_NAME RETURN VARCHAR IS
BEGIN
    RETURN g_PACKAGE_NAME;
END PACKAGE_NAME;
---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
PROCEDURE GET_CREDENTIALS
	(
	p_CREDENTIALS OUT EXTERNAL_CREDENTIAL,
	p_ERROR_MESSAGE OUT VARCHAR2
	) AS
	
v_STATUS NUMBER;

BEGIN
	p_CREDENTIALS := EXTERNAL_CREDENTIAL(NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
    p_CREDENTIALS.URL := MODEL_VALUE_AT_KEY(0, 'MarketExchange', 'ETAG', 'URL', 0);
    p_CREDENTIALS.USER_ID := GB.g_OSUSER;
    SA.GET_USER_EXT_CREDENTIALS(p_CREDENTIALS.USER_ID, 'ETAG', p_CREDENTIALS.ISO_USER_ID, p_CREDENTIALS.ISO_PASSWORD, v_STATUS);
    IF v_STATUS < 0 THEN
		p_ERROR_MESSAGE := 'Error ' || TO_CHAR(v_STATUS) || ' while getting credentials for user ' || GB.G_OSUSER;
        RETURN;
    END IF;
	
    p_CREDENTIALS.ISO_PASSWORD := CD.ENDECRYPT(CD.BASE64DECODE(p_CREDENTIALS.ISO_PASSWORD), g_CIPHER_KEY);
    SA.GET_USER_EXT_CREDENTIALS(p_CREDENTIALS.USER_ID, 'ETAG Proxy', p_CREDENTIALS.PROXY_USER_ID, p_CREDENTIALS.PROXY_PASSWORD, v_STATUS);
    IF v_STATUS < 0 THEN
        p_CREDENTIALS.PROXY_USER_ID := NULL;
        p_CREDENTIALS.PROXY_PASSWORD := NULL;
    ELSE
        p_CREDENTIALS.PROXY_PASSWORD := CD.ENDECRYPT(CD.BASE64DECODE(p_CREDENTIALS.PROXY_PASSWORD), g_CIPHER_KEY);
    END IF;
	
EXCEPTION
	WHEN OTHERS THEN
		p_ERROR_MESSAGE := 'Error while getting credentials for user ' || GB.G_OSUSER || ': ' || SQLERRM;
		RETURN;
	
END GET_CREDENTIALS;
-------------------------------------------------------------------------------------
FUNCTION CREATE_TAG_IDENT
	(
	p_GCA_Code IN VARCHAR2,
	p_PSE_Code IN VARCHAR2,
	p_Tag_Code IN VARCHAR2,
	p_LCA_Code IN VARCHAR2
	) RETURN VARCHAR2 IS
	
BEGIN
	
    RETURN p_GCA_Code||'_'||p_PSE_Code||p_Tag_Code||'_'||p_LCA_Code;
	
END CREATE_TAG_IDENT;
-------------------------------------------------------------------------------------
FUNCTION GET_ETAG_ID_FROM_TAG_IDENT
	(
	p_TAG_IDENT IN VARCHAR2
	) RETURN NUMBER IS
	
v_ETAG_ID ETAG.ETAG_ID%TYPE;

BEGIN
	
	v_ETAG_ID := 0;
	
    SELECT ETAG_ID 
	INTO v_ETAG_ID
	FROM ETAG 
	WHERE TAG_IDENT = p_TAG_IDENT;
	
    RETURN v_ETAG_ID;
	
END GET_ETAG_ID_FROM_TAG_IDENT;
-------------------------------------------------------------------------------------
PROCEDURE PUT_ETAG
	(
	o_OID OUT NUMBER,
	p_ETAG_ID IN NUMBER,
	p_GCA_Code IN VARCHAR2,
	p_PSE_Code IN VARCHAR2,
	p_Tag_Code IN VARCHAR2,
	p_LCA_Code IN VARCHAR2,
	p_ETAG_STATUS IN VARCHAR2,
	p_Security_Key IN VARCHAR2,
	p_WSCC_PreSchedule_Flag IN VARCHAR2,
	p_Test_Flag IN VARCHAR2,
	p_Transaction_Type IN VARCHAR2,
	p_Notes IN VARCHAR2,
    p_DELETE_EXISTING IN NUMBER,
    p_STATUS IN OUT NUMBER,
	p_ERROR_MESSAGE IN OUT VARCHAR2
	) AS
	
    v_ProcedureName VARCHAR2(29) := 'PUT_ETAG';
	
	v_TAG_IDENT ETAG.TAG_IDENT%TYPE;
	v_ETAG_NAME ETAG.ETAG_NAME%TYPE;
	v_ETAG_ALIAS ETAG.ETAG_ALIAS%TYPE;
	v_ETAG_DESC ETAG.ETAG_DESC%TYPE;
	

BEGIN
	
    v_TAG_IDENT := CREATE_TAG_IDENT(p_GCA_Code, p_PSE_Code, p_Tag_Code, p_LCA_Code);
	v_ETAG_NAME := v_TAG_IDENT;
	v_ETAG_ALIAS := v_TAG_IDENT;
	v_ETAG_DESC := v_TAG_IDENT;
    
    IF p_DELETE_EXISTING = 1 THEN
        DELETE FROM ETAG WHERE TAG_IDENT = v_TAG_IDENT;
    END IF;
    
    IO.PUT_ETAG
    	(
    	o_OID,
    	v_ETAG_NAME,
    	v_ETAG_ALIAS,
    	v_ETAG_DESC,
    	p_ETAG_ID,
    	v_TAG_IDENT,
    	p_GCA_CODE,
    	p_PSE_CODE,
    	p_TAG_CODE,
    	p_LCA_CODE,
    	NULL, -- p_EXTERNAL_IDENTIFIER,
    	p_ETAG_STATUS,
    	p_SECURITY_KEY,
    	p_WSCC_PRESCHEDULE_FLAG,
    	p_TEST_FLAG,
    	p_TRANSACTION_TYPE,
    	p_NOTES
    	);

    IF o_OID < 0 THEN
	   IF o_OID = v_INSUFFICIENT_PRIVILEGES THEN
    	   RAISE INSUFFICIENT_PRIVILEGES;
	   ELSE
    	   p_STATUS := o_OID;
	   END IF;
	END IF;
	
	
EXCEPTION
	WHEN INSUFFICIENT_PRIVILEGES THEN
		p_STATUS := GA.INSUFFICIENT_PRIVILEGES;
        p_ERROR_MESSAGE := 'Error in '||g_PACKAGE_NAME||'.'||v_ProcedureName||': INSUFFICIENT_PRIVILEGES';
	WHEN OTHERS THEN
        p_STATUS := SQLCODE;
        p_ERROR_MESSAGE := 'Error in '||g_PACKAGE_NAME||'.'||v_ProcedureName||': ' ||SQLERRM;
		RAISE;
	
END PUT_ETAG;
-------------------------------------------------------------------------------------
FUNCTION TIME_OFFSET_TO_MINUTES
	(
	p_TIME_OFFSET IN VARCHAR2
	) RETURN NUMBER IS

v_MINUTES  VARCHAR2(16);
v_POS_T  NUMBER;
v_POS_M  NUMBER;
	
BEGIN
	
    v_POS_T := INSTR(p_TIME_OFFSET,'T',1) + 1;  --1 past the T
    v_POS_M := INSTR(p_TIME_OFFSET,'M', -1);     --last M
    v_MINUTES := SUBSTR(p_TIME_OFFSET, v_POS_T, v_POS_M - v_POS_T);  --in between the T and M
    RETURN TO_NUMBER(v_MINUTES);
	
END TIME_OFFSET_TO_MINUTES;
-------------------------------------------------------------------------------------
PROCEDURE PUT_ETAG_LIST_ITEM
	(
	p_ETAG_ID IN NUMBER,
    p_LIST_ID IN NUMBER,
    p_ITEM_VALUE IN VARCHAR2,
    p_DELETE_EXISTING IN NUMBER,
    p_STATUS OUT NUMBER,
	p_ERROR_MESSAGE OUT VARCHAR2
	) AS
	
    v_ProcedureName VARCHAR2(29) := 'PUT_ETAG_LIST_ITEM';
    
    v_ITEM_ID  NUMBER(9);
    
BEGIN
	
    p_STATUS := 0;
    p_ERROR_MESSAGE := '';
    
    -- ListItem --
        BEGIN    --TRY INSERT
    
            SELECT ETID.NEXTVAL INTO v_ITEM_ID FROM DUAL;
    
            IF p_DELETE_EXISTING = 1 THEN
                DELETE FROM ETAG_LIST_ITEM A
                WHERE ETAG_ID = p_ETAG_ID
                    AND ETAG_ITEM_ID = v_ITEM_ID;
            END IF;
        
    		INSERT INTO ETAG_LIST_ITEM
                (
                ETAG_ID, 
                ETAG_ITEM_ID,
                ETAG_LIST_ID,
                ETAG_ITEM
                )
        	VALUES 
                (
                p_ETAG_ID,
                v_ITEM_ID,
                p_LIST_ID,
                p_ITEM_VALUE
                );
                
    		EXCEPTION
    			WHEN DUP_VAL_ON_INDEX THEN
    				UPDATE ETAG_LIST_ITEM
        				SET 
                            ETAG_LIST_ID = p_LIST_ID,
                            ETAG_ITEM = p_ITEM_VALUE
                        WHERE 
                            ETAG_ID = p_ETAG_ID
                            AND ETAG_ITEM_ID = v_ITEM_ID;
                
            	WHEN OTHERS THEN
                    RAISE;
        END;    --TRY INSERT - LIST_ITEM
    
    
EXCEPTION
	WHEN OTHERS THEN
		IF p_ERROR_MESSAGE IS NULL THEN
            p_STATUS := SQLCODE;
            p_ERROR_MESSAGE := 'Error in '||g_PACKAGE_NAME||'.'||v_ProcedureName||': ' ||SQLERRM;
        END IF;
	
END PUT_ETAG_LIST_ITEM;
-------------------------------------------------------------------------------------
PROCEDURE PUT_SIMPLE_LIST_ITEM
	(
	p_ETAG_ID IN NUMBER,
    p_LIST_ID IN NUMBER,
    p_LIST_XPATH_NAME IN VARCHAR2,
    p_ITEM_XPATH_NAME IN VARCHAR2,
	p_LIST_CLOB IN CLOB,
    p_DELETE_EXISTING IN NUMBER,
    p_STATUS OUT NUMBER,
	p_ERROR_MESSAGE OUT VARCHAR2
	) AS
	
    v_ProcedureName VARCHAR2(29) := 'PUT_SIMPLE_LIST_ITEM';
    
  CURSOR c_XML_ListItem IS
        SELECT		
                EXTRACTVALUE(VALUE(U), '//'||p_ITEM_XPATH_NAME) ItemValue 
        FROM
                TABLE(XMLSEQUENCE(EXTRACT(XMLTYPE.CREATEXML(p_LIST_CLOB), '//'||p_LIST_XPATH_NAME||'/'||p_ITEM_XPATH_NAME))) U;
        
BEGIN
	
    p_STATUS := 0;
    p_ERROR_MESSAGE := '';
    
    -- ListItem --
	FOR v_XML_ListItem IN c_XML_ListItem LOOP
        -- ETAG_List_Item --
        PUT_ETAG_LIST_ITEM
        	(
        	p_ETAG_ID,
            p_LIST_ID,
        	v_XML_ListItem.Itemvalue,
            p_DELETE_EXISTING,
            p_STATUS,
        	p_ERROR_MESSAGE
        	);
    
	END LOOP;
    
    
EXCEPTION
	WHEN OTHERS THEN
		IF p_ERROR_MESSAGE IS NULL THEN
            p_STATUS := SQLCODE;
            p_ERROR_MESSAGE := 'Error in '||g_PACKAGE_NAME||'.'||v_ProcedureName||': ' ||SQLERRM;
        END IF;
	
END PUT_SIMPLE_LIST_ITEM;
-------------------------------------------------------------------------------------
PROCEDURE PUT_ETAG_LIST_ONLY
	(
    p_LIST_OID OUT NUMBER,
	p_ETAG_ID IN NUMBER,
    p_ITEM_XPATH_NAME IN VARCHAR2,
    p_LIST_USED_BY IN VARCHAR2,
    p_DELETE_EXISTING IN NUMBER,
    p_STATUS IN OUT NUMBER,
	p_ERROR_MESSAGE IN OUT VARCHAR2
	) AS
	
    v_ProcedureName VARCHAR2(29) := 'PUT_ETAG_LIST_ONLY';
    
BEGIN
	
    -- ETAG_List --
    BEGIN    --TRY INSERT

        SELECT ETID.NEXTVAL INTO p_LIST_OID FROM DUAL;

        IF p_DELETE_EXISTING = 1 THEN
            DELETE FROM ETAG_LIST A
            WHERE ETAG_ID = p_ETAG_ID
                AND ETAG_LIST_ID = p_LIST_OID;
        END IF;
    
		INSERT INTO ETAG_LIST
            (
            ETAG_ID, 
            ETAG_LIST_ID,
            LIST_TYPE,
            LIST_USED_BY
            )
    	VALUES 
            (
            p_ETAG_ID,
            p_LIST_OID,
            p_ITEM_XPATH_NAME,
            p_LIST_USED_BY
            );
            
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				UPDATE ETAG_LIST
    				SET 
                        LIST_TYPE = p_ITEM_XPATH_NAME,
                        LIST_USED_BY = p_LIST_USED_BY
                    WHERE 
                        ETAG_ID = p_ETAG_ID
                        AND ETAG_LIST_ID = p_LIST_OID;
            
        	WHEN OTHERS THEN
                RAISE;
    END;    --TRY INSERT
    
EXCEPTION
	WHEN OTHERS THEN
		IF p_ERROR_MESSAGE IS NULL THEN
            p_STATUS := SQLCODE;
            p_ERROR_MESSAGE := 'Error in '||g_PACKAGE_NAME||'.'||v_ProcedureName||': ' ||SQLERRM;
        END IF;
	
END PUT_ETAG_LIST_ONLY;
-------------------------------------------------------------------------------------
PROCEDURE PUT_SIMPLE_ETAG_LIST
	(
    p_LIST_OID OUT NUMBER,
	p_ETAG_ID IN NUMBER,
    p_LIST_XPATH_NAME IN VARCHAR2,
    p_ITEM_XPATH_NAME IN VARCHAR2,
    p_LIST_USED_BY IN VARCHAR2,
	p_LIST_CLOB IN CLOB,
    p_DELETE_EXISTING IN NUMBER,
    p_STATUS IN OUT NUMBER,
	p_ERROR_MESSAGE IN OUT VARCHAR2
	) AS
	
    v_ProcedureName VARCHAR2(29) := 'PUT_SIMPLE_ETAG_LIST';
    
BEGIN
	
    
    IF p_LIST_CLOB IS NOT NULL THEN
        -- ETAG_List table--
        PUT_ETAG_LIST_ONLY
        	(
            p_LIST_OID,
        	p_ETAG_ID,
            p_ITEM_XPATH_NAME,
            p_LIST_USED_BY,
            p_DELETE_EXISTING,
            p_STATUS,
        	p_ERROR_MESSAGE
        	);
        
        IF p_STATUS = 0 THEN
            -- ETAG_List_Item --
            PUT_SIMPLE_LIST_ITEM
            	(
            	p_ETAG_ID,
                p_LIST_OID,
                p_LIST_XPATH_NAME,
                p_ITEM_XPATH_NAME,
            	p_LIST_CLOB,
                p_DELETE_EXISTING,
                p_STATUS,
            	p_ERROR_MESSAGE
            	);
        END IF;
    END IF;
    
EXCEPTION
	WHEN OTHERS THEN
		IF p_ERROR_MESSAGE IS NULL THEN
            p_STATUS := SQLCODE;
            p_ERROR_MESSAGE := 'Error in '||g_PACKAGE_NAME||'.'||v_ProcedureName||': ' ||SQLERRM;
        END IF;
	
END PUT_SIMPLE_ETAG_LIST;
-------------------------------------------------------------------------------------
PROCEDURE PUT_MISC_INFO_LIST
	(
    p_LIST_OID OUT NUMBER,
	p_ETAG_ID IN NUMBER,
    p_LIST_XPATH_NAME IN VARCHAR2,
    p_ITEM_XPATH_NAME IN VARCHAR2,
    p_LIST_USED_BY IN VARCHAR2,
	p_LIST_CLOB IN CLOB,
    p_DELETE_EXISTING IN NUMBER,
    p_STATUS IN OUT NUMBER,
	p_ERROR_MESSAGE IN OUT VARCHAR2
	) AS
	
    v_ProcedureName VARCHAR2(29) := 'PUT_MISC_INFO_LIST';
    
  CURSOR c_XML_MiscInfo IS
        SELECT		
                EXTRACTVALUE(VALUE(U), '//Token')  MiscInfoToken, 
                EXTRACTVALUE(VALUE(U), '//Value')  MiscInfoValue
        FROM
                TABLE(XMLSEQUENCE(EXTRACT(XMLTYPE.CREATEXML(p_LIST_CLOB), '//'||p_LIST_XPATH_NAME||'/'||p_ITEM_XPATH_NAME))) U;    -- '//MiscInfoList/MiscInfo'
                --Debug format
                   --TABLE(XMLSEQUENCE(EXTRACT((SELECT XMLTYPE.CREATEXML(clob_data) FROM XML_TRACE WHERE key1 = 'Transmission2'), '//Transmission/MiscInfoList/MiscInfo'))) U
                --end Debug

BEGIN
	
    IF p_LIST_CLOB IS NOT NULL THEN
        -- ETAG_List table--
        PUT_ETAG_LIST_ONLY
        	(
            p_LIST_OID,
        	p_ETAG_ID,
            p_ITEM_XPATH_NAME,
            p_LIST_USED_BY,
            p_DELETE_EXISTING,
            p_STATUS,
        	p_ERROR_MESSAGE
        	);
        
        IF p_STATUS = 0 THEN
        	FOR v_XML_MiscInfo IN c_XML_MiscInfo LOOP
                -- ETAG_List_Item --
                PUT_ETAG_LIST_ITEM
                	(
                	p_ETAG_ID,
                    p_LIST_OID,
                	v_XML_MiscInfo.MiscInfoToken||':'||v_XML_MiscInfo.MiscInfoValue,
                    p_DELETE_EXISTING,
                    p_STATUS,
                	p_ERROR_MESSAGE
                	);
            END LOOP;
        END IF;
    END IF;
    
EXCEPTION
	WHEN OTHERS THEN
		IF p_ERROR_MESSAGE IS NULL THEN
            p_STATUS := SQLCODE;
            p_ERROR_MESSAGE := 'Error in '||g_PACKAGE_NAME||'.'||v_ProcedureName||': ' ||SQLERRM;
        END IF;
	
END PUT_MISC_INFO_LIST;
-------------------------------------------------------------------------------------
PROCEDURE PUT_SCHEDULING_ENTITY_LIST
	(
    p_LIST_OID OUT NUMBER,
	p_ETAG_ID IN NUMBER,
    p_LIST_XPATH_NAME IN VARCHAR2,
    p_ITEM_XPATH_NAME IN VARCHAR2,
    p_LIST_USED_BY IN VARCHAR2,
	p_LIST_CLOB IN CLOB,
    p_DELETE_EXISTING IN NUMBER,
    p_STATUS IN OUT NUMBER,
	p_ERROR_MESSAGE IN OUT VARCHAR2
	) AS
	
    v_ProcedureName VARCHAR2(29) := 'PUT_SCHEDULING_ENTITY_LIST';
    
    CURSOR c_XML_SchedulingEntity IS
        SELECT		
        		XMLTYPE.CREATEXML(EXTRACT(VALUE(U), '/SchedulingEntity/child::node()').GETCLOBVAL()).GetRootElement()  EntityType,
				EXTRACTVALUE(VALUE(U), '//SchedulingEntity/child::node()') EntityCode 
        FROM
                TABLE(XMLSEQUENCE(EXTRACT(XMLTYPE.CREATEXML(p_LIST_CLOB), '//'||p_LIST_XPATH_NAME||'/'||p_ITEM_XPATH_NAME))) U;    -- '//SchedulingEntityList/SchedulingEntity'
                --Debug format
                   --TABLE(XMLSEQUENCE(EXTRACT((SELECT XMLTYPE.CREATEXML(clob_data) FROM XML_TRACE WHERE key1 = 'SchedulingEntityList'), '//SchedulingEntityList/SchedulingEntity'))) U
                --end Debug

BEGIN
	
    IF p_LIST_CLOB IS NOT NULL THEN
        -- ETAG_List table--
        PUT_ETAG_LIST_ONLY
        	(
            p_LIST_OID,
        	p_ETAG_ID,
            p_ITEM_XPATH_NAME,
            p_LIST_USED_BY,
            p_DELETE_EXISTING,
            p_STATUS,
        	p_ERROR_MESSAGE
        	);
        
        IF p_STATUS = 0 THEN
        	FOR v_XML_SchedulingEntity IN c_XML_SchedulingEntity LOOP
                -- ETAG_List_Item --
                PUT_ETAG_LIST_ITEM
                	(
                	p_ETAG_ID,
                    p_LIST_OID,
                	v_XML_SchedulingEntity.EntityType||':'||v_XML_SchedulingEntity.EntityCode,
                    p_DELETE_EXISTING,
                    p_STATUS,
                	p_ERROR_MESSAGE
                	);
            END LOOP;
        END IF;
    END IF;
    
EXCEPTION
	WHEN OTHERS THEN
		IF p_ERROR_MESSAGE IS NULL THEN
            p_STATUS := SQLCODE;
            p_ERROR_MESSAGE := 'Error in '||g_PACKAGE_NAME||'.'||v_ProcedureName||': ' ||SQLERRM;
        END IF;
	
END PUT_SCHEDULING_ENTITY_LIST;
-------------------------------------------------------------------------------------
PROCEDURE PUT_TAGID_LIST
	(
    p_LIST_OID OUT NUMBER,
	p_ETAG_ID IN NUMBER,
    p_PARENT_LIST_TYPE IN VARCHAR2,
    p_LIST_XPATH_NAME IN VARCHAR2,
    p_ITEM_XPATH_NAME IN VARCHAR2,
    p_LIST_USED_BY IN VARCHAR2,
	p_LIST_CLOB IN CLOB,
    p_DELETE_EXISTING IN NUMBER,
    p_STATUS IN OUT NUMBER,
	p_ERROR_MESSAGE IN OUT VARCHAR2
	) AS
	
    v_ProcedureName VARCHAR2(29) := 'PUT_TAGID_LIST';
    
    v_TagID  VARCHAR2(32);
    
  CURSOR c_XML_TagID IS
        SELECT		
                EXTRACTVALUE(VALUE(U), '//GCACode')  GCACode, 
                EXTRACTVALUE(VALUE(U), '//PSECode')  PSECode, 
                EXTRACTVALUE(VALUE(U), '//TagCode')  TagCode, 
                EXTRACTVALUE(VALUE(U), '//LCACode')  LCACode
        FROM
                TABLE(XMLSEQUENCE(EXTRACT(XMLTYPE.CREATEXML(p_LIST_CLOB), '//'||p_LIST_XPATH_NAME||'/'||p_ITEM_XPATH_NAME))) U;    -- '//TagIDList/TagID'
                --Debug format
                --end Debug

BEGIN
	
	FOR v_XML_TagID IN c_XML_TagID LOOP
        v_TagID := CREATE_TAG_IDENT(v_XML_TagID.GCACode, v_XML_TagID.PSECode, v_XML_TagID.TagCode, v_XML_TagID.LCACode);
    END LOOP;
    
    IF p_LIST_CLOB IS NOT NULL THEN
        -- ETAG_List table--
        PUT_ETAG_LIST_ONLY
        	(
            p_LIST_OID,
        	p_ETAG_ID,
            p_ITEM_XPATH_NAME||':'||p_PARENT_LIST_TYPE,
            p_LIST_USED_BY,
            p_DELETE_EXISTING,
            p_STATUS,
        	p_ERROR_MESSAGE
        	);
        
        IF p_STATUS = 0 THEN
        	FOR v_XML_TagID IN c_XML_TagID LOOP
                -- ETAG_List_Item --
                PUT_ETAG_LIST_ITEM
                	(
                	p_ETAG_ID,
                    p_LIST_OID,
                	v_TagID,
                    p_DELETE_EXISTING,
                    p_STATUS,
                	p_ERROR_MESSAGE
                	);
            END LOOP;
        END IF;
    END IF;
    
EXCEPTION
	WHEN OTHERS THEN
		IF p_ERROR_MESSAGE IS NULL THEN
            p_STATUS := SQLCODE;
            p_ERROR_MESSAGE := 'Error in '||g_PACKAGE_NAME||'.'||v_ProcedureName||': ' ||SQLERRM;
        END IF;
	
END PUT_TAGID_LIST;
-------------------------------------------------------------------------------------
PROCEDURE PUT_ETAG_PROFILE_VALUE
	(
    p_PROFILE_KEY_ID IN NUMBER,
    p_START_DATE IN DATE,
    p_END_DATE IN DATE,
    p_MW_LEVEL IN NUMBER,
    p_STATUS IN OUT NUMBER,
	p_ERROR_MESSAGE IN OUT VARCHAR2
	) AS
   
    v_ProcedureName VARCHAR2(29) := 'PUT_ETAG_PROFILE_VALUE';
    
BEGIN
	
    --TRY INSERT
    BEGIN
		INSERT INTO ETAG_PROFILE_VALUE
            (
            PROFILE_KEY_ID,
            START_DATE, 
            END_DATE,
            MW_LEVEL
            )
    	VALUES 
            (
            p_PROFILE_KEY_ID,
            p_START_DATE,
            p_END_DATE,
            p_MW_LEVEL
            );
            
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				UPDATE ETAG_PROFILE_VALUE
    				SET 
                        MW_LEVEL = p_MW_LEVEL 
                    WHERE PROFILE_KEY_ID = p_PROFILE_KEY_ID
                        AND START_DATE = p_START_DATE
                        AND END_DATE = p_END_DATE;
            
        	WHEN OTHERS THEN
                RAISE;
    END;    --TRY INSERT
    
    
EXCEPTION
	WHEN OTHERS THEN
		IF p_ERROR_MESSAGE IS NULL THEN
            p_STATUS := SQLCODE;
            p_ERROR_MESSAGE := 'Error in '||g_PACKAGE_NAME||'.'||v_ProcedureName||': ' ||SQLERRM;
        END IF;
        RAISE;
	
END PUT_ETAG_PROFILE_VALUE;
-------------------------------------------------------------------------------------
PROCEDURE PUT_ABSOLUTE_PROFILE_VALUE
	(
    p_PROFILE_KEY_ID IN NUMBER,
    p_START_DATE_STRING IN VARCHAR2,
    p_STOP_DATE_STRING IN VARCHAR2,
    p_MW_LEVEL IN NUMBER,
    p_STATUS IN OUT NUMBER,
	p_ERROR_MESSAGE IN OUT VARCHAR2
	) AS
   
   v_START_DATE  DATE;
   v_END_DATE  DATE;
	
    v_ProcedureName VARCHAR2(29) := 'PUT_ABSOLUTE_PROFILE_VALUE';
    
BEGIN
	
    v_START_DATE := TO_CUT(TO_DATE(p_START_DATE_STRING, g_DATE_TIME_FORMAT),'GMT');
    v_END_DATE := TO_CUT(TO_DATE(p_STOP_DATE_STRING, g_DATE_TIME_FORMAT),'GMT');
    
    PUT_ETAG_PROFILE_VALUE
    	(
        p_PROFILE_KEY_ID,
        v_START_DATE,
        v_END_DATE,
        p_MW_LEVEL,
        p_STATUS,
    	p_ERROR_MESSAGE
    	);
    
    
EXCEPTION
	WHEN OTHERS THEN
		IF p_ERROR_MESSAGE IS NULL THEN
            p_STATUS := SQLCODE;
            p_ERROR_MESSAGE := 'Error in '||g_PACKAGE_NAME||'.'||v_ProcedureName||': ' ||SQLERRM;
        END IF;
        RAISE;
	
END PUT_ABSOLUTE_PROFILE_VALUE;
-------------------------------------------------------------------------------------
PROCEDURE PUT_RELATIVE_PROFILE_VALUE
	(
    p_PROFILE_KEY_ID IN NUMBER,
    p_DATE_STRING IN VARCHAR2,
    p_START_OFFSET IN VARCHAR2,
    p_STOP_OFFSET IN VARCHAR2,
    p_MW_LEVEL IN NUMBER,
    p_STATUS IN OUT NUMBER,
	p_ERROR_MESSAGE IN OUT VARCHAR2
	) AS
   
   v_CUT_DATE  DATE;
   v_START_DATE  DATE;
   v_END_DATE  DATE;
   v_START_OFFSET_MINUTES NUMBER(5);
   v_STOP_OFFSET_MINUTES NUMBER(5);
	
    v_ProcedureName VARCHAR2(29) := 'PUT_RELATIVE_PROFILE_VALUE';
    
BEGIN
	
    v_CUT_DATE := TO_CUT(TO_DATE(p_DATE_STRING, g_DATE_TIME_FORMAT),'GMT');
    
    v_START_OFFSET_MINUTES := TIME_OFFSET_TO_MINUTES(p_START_OFFSET);
    v_START_DATE := v_CUT_DATE + v_START_OFFSET_MINUTES/1440;
    v_STOP_OFFSET_MINUTES := TIME_OFFSET_TO_MINUTES(p_STOP_OFFSET);
    v_END_DATE := v_CUT_DATE + v_STOP_OFFSET_MINUTES/1440;
    
    PUT_ETAG_PROFILE_VALUE
    	(
        p_PROFILE_KEY_ID,
        v_START_DATE,
        v_END_DATE,
        p_MW_LEVEL,
        p_STATUS,
    	p_ERROR_MESSAGE
    	);
    
    
EXCEPTION
	WHEN OTHERS THEN
		IF p_ERROR_MESSAGE IS NULL THEN
            p_STATUS := SQLCODE;
            p_ERROR_MESSAGE := 'Error in '||g_PACKAGE_NAME||'.'||v_ProcedureName||': ' ||SQLERRM;
        END IF;
        RAISE;
	
END PUT_RELATIVE_PROFILE_VALUE;
-------------------------------------------------------------------------------------
PROCEDURE PUT_ETAG_RELATIVE_PROFILE
	(
    p_PROFILE_KEY_OID OUT NUMBER,
    p_CLOB_XPATH IN VARCHAR2,
	p_ETAG_ID IN NUMBER,
    p_PARENT_NID IN NUMBER,
	p_PROFILE_STYLE IN VARCHAR2,
	p_PARENT_TYPE IN VARCHAR2,
    p_CLOB IN CLOB,
    p_STATUS IN OUT NUMBER,
	p_ERROR_MESSAGE IN OUT VARCHAR2
	) AS
	
    v_ProcedureName VARCHAR2(29) := 'PUT_ETAG_RELATIVE_PROFILE';
    v_PROFILE_TYPE_LIST_ID  NUMBER(9);
    v_STATUS  NUMBER := 0;
    v_ERROR_MESSAGE  VARCHAR2(512) := '';
  
  -- Use cross-product to apply all start-stop offsets and MWLevels to all DateTimes in DateTimeList  
  CURSOR c_XML_ProfileValue IS
        SELECT 
            EXTRACTVALUE(VALUE(W), '//DateTime') DateTime,
            EXTRACTVALUE(VALUE(W), '//DateTime') UTC_DAte,
            TO_CUT(TO_DATE(EXTRACTVALUE(VALUE(W), '//DateTime'), 'YYYY-MM-DD"T"HH24:MI:SS"Z"'),'GMT') Cut_DAte,
            EXTRACTVALUE(VALUE(V), '//RelativeStart/TimeOffset')  StartTimeOffset,      
            EXTRACTVALUE(VALUE(V), '//RelativeStop/TimeOffset')  StopTimeOffset,      
            EXTRACTVALUE(VALUE(V), '//MWLevel') MWLevel
        FROM 
            TABLE(XMLSEQUENCE(EXTRACT(XMLTYPE.CREATEXML(p_CLOB), p_CLOB_XPATH))) U, --'//RelativeProfile'))) U,
            --Debug format
                --TABLE(XMLSEQUENCE(EXTRACT((SELECT XMLTYPE.CREATEXML(clob_data) FROM XML_TRACE WHERE key1 = 'RelativeProfile1'), '//RelativeProfile'))) U,
            --end Debug
            TABLE(XMLSEQUENCE(EXTRACT(VALUE(U),'//RelativeBlockList/RelativeBlock'))) V,
            TABLE(XMLSEQUENCE(EXTRACT(VALUE(U),'//DateTimeList/DateTime'))) W;
    
  CURSOR c_XML_ProfileTypeList IS
        SELECT 
            EXTRACT(VALUE(U), '//ProfileTypeList').GETCLOBVAL() ProfileTypeListCLOB
        FROM 
            TABLE(XMLSEQUENCE(EXTRACT(XMLTYPE.CREATEXML(p_CLOB), '//ProfileTypeList'))) U; 
            --Debug format
                --TABLE(XMLSEQUENCE(EXTRACT((SELECT XMLTYPE.CREATEXML(clob_data) FROM XML_TRACE WHERE key1 = 'RelativeProfile2'), '//ProfileTypeList'))) U
            --end Debug


BEGIN
	
    --Make PROFILE_TYPE_LIST
    FOR v_XML_ProfileTypeList IN c_XML_ProfileTypeList LOOP
        PUT_SIMPLE_ETAG_LIST
        	(
        	v_PROFILE_TYPE_LIST_ID,  -- OUT
            p_ETAG_ID,
        	'ProfileTypeList',
        	'ProfileType',
        	'ETAG_PROFILE',
        	v_XML_ProfileTypeList.ProfileTypeListCLOB,
            1,  --p_DELETE_EXISTING,
            v_STATUS,
        	v_ERROR_MESSAGE
        	);
    END LOOP;
    --TRY INSERT
    BEGIN

        DELETE FROM ETAG_PROFILE P
        WHERE  ETAG_ID = p_ETAG_ID
            AND PROFILE_STYLE = p_PROFILE_STYLE
            AND PARENT_TYPE = p_PARENT_TYPE
            AND PARENT_NID = p_PARENT_NID;

        SELECT ETID.NEXTVAL INTO p_PROFILE_KEY_OID FROM DUAL;
        
		INSERT INTO ETAG_PROFILE
            (
            PROFILE_KEY_ID,
            ETAG_ID, 
            PROFILE_STYLE,
            PARENT_TYPE,
            PARENT_NID, 
            PROFILE_TYPE_LIST_ID
            )
    	VALUES 
            (
            p_PROFILE_KEY_OID,
            p_ETAG_ID,
            p_PROFILE_STYLE,
            p_PARENT_TYPE,
        	p_PARENT_NID,
            v_PROFILE_TYPE_LIST_ID
            );
            
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				UPDATE ETAG_PROFILE
    				SET 
                        ETAG_ID = p_ETAG_ID,
                        PROFILE_STYLE = p_PROFILE_STYLE,
                        PARENT_TYPE = p_PARENT_TYPE ,
                        PARENT_NID = p_PARENT_NID,
                        PROFILE_TYPE_LIST_ID = v_PROFILE_TYPE_LIST_ID
                    WHERE 
                        PROFILE_KEY_ID = p_PROFILE_KEY_OID;
            
        	WHEN OTHERS THEN
                RAISE;
    END;    --TRY INSERT
    
	FOR v_XML_ProfileValue IN c_XML_ProfileValue LOOP
        PUT_RELATIVE_PROFILE_VALUE
        	(
            p_PROFILE_KEY_OID,
            v_XML_ProfileValue.UTC_DAte,
            v_XML_ProfileValue.StartTimeOffset,
            v_XML_ProfileValue.StopTimeOffset,
            v_XML_ProfileValue.MWLevel,
            p_STATUS,
        	p_ERROR_MESSAGE
        	);
    END LOOP;
    
    
EXCEPTION
	WHEN OTHERS THEN
		IF p_ERROR_MESSAGE IS NULL THEN
            p_STATUS := SQLCODE;
            p_ERROR_MESSAGE := 'Error in '||g_PACKAGE_NAME||'.'||v_ProcedureName||': ' ||SQLERRM;
        END IF;
		RAISE;
	
END PUT_ETAG_RELATIVE_PROFILE;
-------------------------------------------------------------------------------------
PROCEDURE PUT_ETAG_STATUS
	(
	p_ETAG_ID IN NUMBER,
    p_MESSAGE_CALL_DATE IN DATE,
    p_REQUEST_REF IN VARCHAR2,
    p_ENTITY_CODE_TYPE IN VARCHAR2,
    p_ENTITY_CODE IN VARCHAR2,
    p_DELIVERY_STATUS IN VARCHAR2,
    p_APPROVAL_STATUS IN VARCHAR2,
    p_APPROVAL_STATUS_TYPE IN VARCHAR2,
    p_APPROVAL_TIME_STAMP IN VARCHAR2,
    p_NOTES IN VARCHAR2,
    p_DELETE_EARLIER IN NUMBER,
    p_STATUS IN OUT NUMBER,
	p_ERROR_MESSAGE IN OUT VARCHAR2
	) AS
	
    v_ProcedureName VARCHAR2(29) := 'PUT_ETAG_STATUS';
    
    v_APPROVAL_DATE DATE;
    
BEGIN
	
    -- ETAG_STATUS --
    BEGIN    --TRY INSERT

        v_APPROVAL_DATE := TO_CUT(TO_DATE(p_APPROVAL_TIME_STAMP, g_DATE_TIME_FORMAT),'GMT');
        
        IF p_DELETE_EARLIER = 1 THEN
            DELETE FROM ETAG_STATUS A
            WHERE ETAG_ID = p_ETAG_ID
                AND MESSAGE_CALL_DATE <= p_MESSAGE_CALL_DATE
                AND ENTITY_CODE_TYPE = p_ENTITY_CODE_TYPE
                AND ENTITY_CODE = p_ENTITY_CODE;
        END IF;
    
		INSERT INTO ETAG_STATUS
            (
            ETAG_ID, 
            MESSAGE_CALL_DATE,
            ENTITY_CODE_TYPE,
            ENTITY_CODE,
            REQUEST_REF,
            DELIVERY_STATUS,
            APPROVAL_STATUS,
            APPROVAL_STATUS_TYPE,
            APPROVAL_DATE,
            NOTES
            )
    	VALUES 
            (
            p_ETAG_ID,
            p_MESSAGE_CALL_DATE,
            p_ENTITY_CODE_TYPE,
            p_ENTITY_CODE,
            p_REQUEST_REF,
            p_DELIVERY_STATUS,
            p_APPROVAL_STATUS,
            p_APPROVAL_STATUS_TYPE,
            v_APPROVAL_DATE,
            p_NOTES
            );
            
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				UPDATE ETAG_STATUS
    				SET 
                        REQUEST_REF = p_REQUEST_REF,
                        DELIVERY_STATUS = p_DELIVERY_STATUS,
                        APPROVAL_STATUS = p_APPROVAL_STATUS,
                        APPROVAL_STATUS_TYPE = p_APPROVAL_STATUS_TYPE,
                        APPROVAL_DATE = v_APPROVAL_DATE,
                        NOTES = p_NOTES
                    WHERE ETAG_ID = p_ETAG_ID 
                        AND MESSAGE_CALL_DATE <= p_MESSAGE_CALL_DATE
                        AND ENTITY_CODE_TYPE = p_ENTITY_CODE_TYPE
                        AND ENTITY_CODE = p_ENTITY_CODE;
            
        	WHEN OTHERS THEN
                RAISE;
    END;    --TRY INSERT
    
EXCEPTION
	WHEN OTHERS THEN
		IF p_ERROR_MESSAGE IS NULL THEN
            p_STATUS := SQLCODE;
            p_ERROR_MESSAGE := 'Error in '||g_PACKAGE_NAME||'.'||v_ProcedureName||': ' ||SQLERRM;
        END IF;
	
END PUT_ETAG_STATUS;
-------------------------------------------------------------------------------------
PROCEDURE PUT_MARKET_SEGMENT
	(
	p_ETAG_ID IN NUMBER,
    p_MARKET_SEGMENT_NID IN NUMBER,
	p_CURRENT_CORRECTION_NID IN NUMBER,
	p_PSE_CODE IN VARCHAR2,
	p_ENERGY_PRODUCT_REF IN NUMBER,
	p_CONTRACT_NUMBER_LIST_CLOB IN CLOB,
	p_MISC_INFO_LIST_CLOB IN CLOB,
    p_LIST_USED_BY IN VARCHAR2,
    p_DELETE_EXISTING IN NUMBER,
    p_STATUS OUT NUMBER,
	p_ERROR_MESSAGE OUT VARCHAR2
	) AS
	
    v_ProcedureName VARCHAR2(29) := 'PUT_MARKET_SEGMENT';
    
	v_CONTRACT_NUMBER_LIST_ID NUMBER(9);
	v_MISC_INFO_LIST_ID NUMBER(9);
    v_STATUS  NUMBER := 0;
    v_ERROR_MESSAGE  VARCHAR2(512) := '';
        
BEGIN
	
    --TRY INSERT
    BEGIN

        p_STATUS := 0;
        p_ERROR_MESSAGE := '';

        IF p_DELETE_EXISTING = 1 THEN
            DELETE FROM ETAG_MARKET_SEGMENT A
            WHERE ETAG_ID = p_ETAG_ID
            AND MARKET_SEGMENT_NID = p_MARKET_SEGMENT_NID;
        END IF;
        
        IF p_CONTRACT_NUMBER_LIST_CLOB IS NOT NULL THEN
            PUT_SIMPLE_ETAG_LIST
            	(
            	v_CONTRACT_NUMBER_LIST_ID,  -- OUT
                p_ETAG_ID,
            	'ContractNumberList',
            	'ContractNumber',
            	p_LIST_USED_BY,
            	p_CONTRACT_NUMBER_LIST_CLOB,
                1, -- p_DELETE_EXISTING,
                v_STATUS,
            	v_ERROR_MESSAGE
            	);
        END IF;  

        IF p_MISC_INFO_LIST_CLOB IS NOT NULL THEN
            PUT_MISC_INFO_LIST
            	(
                v_MISC_INFO_LIST_ID,  -- OUT
            	p_ETAG_ID,
                'MiscInfoList',
                'MiscInfo',
                p_LIST_USED_BY,
            	p_MISC_INFO_LIST_CLOB,
                1, -- p_DELETE_EXISTING,
                v_STATUS,
            	v_ERROR_MESSAGE
            	);
        END IF;  

        UPDATE ETAG_MARKET_SEGMENT SET
            CURRENT_CORRECTION_NID = p_CURRENT_CORRECTION_NID,
            PSE_CODE = NVL(p_PSE_CODE, PSE_CODE),  -- Don't Update with NULL
            ENERGY_PRODUCT_REF = p_ENERGY_PRODUCT_REF,
            CONTRACT_NUMBER_LIST_ID = v_CONTRACT_NUMBER_LIST_ID,
            MISC_INFO_LIST_ID = v_MISC_INFO_LIST_ID
        WHERE 
            ETAG_ID = p_ETAG_ID
            AND MARKET_SEGMENT_NID = p_MARKET_SEGMENT_NID;
        
		IF SQL%NOTFOUND THEN
    		INSERT INTO ETAG_MARKET_SEGMENT
                (
                ETAG_ID, 
                MARKET_SEGMENT_NID,
                CURRENT_CORRECTION_NID,
                PSE_CODE, 
                ENERGY_PRODUCT_REF,
    			CONTRACT_NUMBER_LIST_ID,
    			MISC_INFO_LIST_ID
                )
        	VALUES 
                (
                p_ETAG_ID,
                p_MARKET_SEGMENT_NID,
            	p_CURRENT_CORRECTION_NID,
                p_PSE_CODE,
                p_ENERGY_PRODUCT_REF,
    			v_CONTRACT_NUMBER_LIST_ID,
    			v_MISC_INFO_LIST_ID
                );
        END IF;
		    
		EXCEPTION
        	WHEN OTHERS THEN
                p_STATUS := SQLCODE;
                p_ERROR_MESSAGE := 'Error in '||g_PACKAGE_NAME||'.'||v_ProcedureName||': ' ||SQLERRM;

    END;    --TRY INSERT
    
    
EXCEPTION
	WHEN OTHERS THEN
		IF p_ERROR_MESSAGE IS NULL THEN
            p_STATUS := SQLCODE;
            p_ERROR_MESSAGE := 'Error in '||g_PACKAGE_NAME||'.'||v_ProcedureName||': ' ||SQLERRM;
        END IF;
	
END PUT_MARKET_SEGMENT;
-------------------------------------------------------------------------------------
PROCEDURE PUT_RESOURCE
	(
	p_ETAG_ID IN NUMBER,
    p_PHYSICAL_SEGMENT_NID IN NUMBER,
    p_TAGGING_POINT_NID IN NUMBER,
    p_PROFILE_NID IN NUMBER,
	p_CONTRACT_NUMBER_CLOB IN CLOB,
	p_MISC_INFO_LIST_CLOB IN CLOB,
    p_DELETE_EXISTING IN NUMBER,
    p_STATUS IN OUT NUMBER,
	p_ERROR_MESSAGE IN OUT VARCHAR2
	) AS
	
    v_ProcedureName VARCHAR2(29) := 'PUT_RESOURCE';
    
    v_CONTRACT_NUMBER_LIST_ID  NUMBER(9);
    v_MISC_INFO_LIST_ID  NUMBER(9);
    v_STATUS  NUMBER := 0;
    v_ERROR_MESSAGE  VARCHAR2(512) := '';
    
        
BEGIN
	
    v_STATUS := 0;
    
    -- ContractNumberList --
    -- INSERT INTO ETAG_LIST tables
    IF p_CONTRACT_NUMBER_CLOB IS NOT NULL THEN
        PUT_SIMPLE_ETAG_LIST
        	(
        	v_CONTRACT_NUMBER_LIST_ID,  -- OUT
            p_ETAG_ID,
        	'ContractNumberList',
        	'ContractNumber',
        	'ETAG_RESOURCE',
        	p_CONTRACT_NUMBER_CLOB,
            1,  -- Delete_Existing
            v_STATUS,
        	v_ERROR_MESSAGE
        	);
	END IF;
    
    IF p_MISC_INFO_LIST_CLOB IS NOT NULL THEN
        PUT_MISC_INFO_LIST
        	(
            v_MISC_INFO_LIST_ID,  -- OUT
        	p_ETAG_ID,
            'MiscInfoList',
            'MiscInfo',
        	'ETAG_RESOURCE',
        	p_MISC_INFO_LIST_CLOB,
            1, -- p_DELETE_EXISTING,
            v_STATUS,
        	v_ERROR_MESSAGE
        	);
    END IF;  

    IF v_STATUS = 0 THEN
        -- Resource --  
        IF p_DELETE_EXISTING = 1 THEN
            DELETE FROM ETAG_RESOURCE A
            WHERE ETAG_ID = p_ETAG_ID
            AND PHYSICAL_SEGMENT_NID = p_PHYSICAL_SEGMENT_NID
            AND PROFILE_NID = p_PROFILE_NID;
        END IF;
        
        -- Note: Correction has null p_PROFILE_NID and p_TAGGING_POINT_NID
        UPDATE ETAG_RESOURCE SET
            TAGGING_POINT_NID = NVL(p_TAGGING_POINT_NID, TAGGING_POINT_NID),  -- Don't Update with NULL
            CONTRACT_NUMBER_LIST_ID = v_CONTRACT_NUMBER_LIST_ID,
            MISC_INFO_LIST_ID = v_MISC_INFO_LIST_ID
        WHERE 
            ETAG_ID = p_ETAG_ID
            AND PHYSICAL_SEGMENT_NID = p_PHYSICAL_SEGMENT_NID
            AND PROFILE_NID = NVL(p_PROFILE_NID, PROFILE_NID);  -- Don't match with NULL
                
		IF SQL%NOTFOUND THEN
    		INSERT INTO ETAG_RESOURCE
                (
                ETAG_ID, 
                PHYSICAL_SEGMENT_NID,
                PROFILE_NID,
                TAGGING_POINT_NID,
                CONTRACT_NUMBER_LIST_ID,
				MISC_INFO_LIST_ID
                )
        	VALUES 
                (
                p_ETAG_ID,
                p_PHYSICAL_SEGMENT_NID,
                p_PROFILE_NID,
            	p_TAGGING_POINT_NID,
                v_CONTRACT_NUMBER_LIST_ID,
				v_MISC_INFO_LIST_ID
                );
		END IF;
    
    ELSE
        p_STATUS := v_STATUS;
        p_ERROR_MESSAGE := v_ERROR_MESSAGE;
    END IF;    -- v_STATUS = 0
    
    
EXCEPTION
	WHEN OTHERS THEN
		IF p_ERROR_MESSAGE IS NULL THEN
            p_STATUS := SQLCODE;
            p_ERROR_MESSAGE := 'Error in '||g_PACKAGE_NAME||'.'||v_ProcedureName||': ' ||SQLERRM;
        END IF;
		RAISE;
	
END PUT_RESOURCE;
-------------------------------------------------------------------------------------
PROCEDURE PUT_RESOURCE_SEGMENT
	(
	p_ETAG_ID IN NUMBER,
	p_PHYSICAL_SEGMENT_TYPE IN VARCHAR2,
    p_PHYSICAL_SEGMENT_NID IN NUMBER,
	p_CURRENT_CORRECTION_NID IN NUMBER,
	p_PARENT_MARKET_SEGMENT_REF IN NUMBER,
	p_RESOURCE_CLOB IN CLOB,
    p_DELETE_EXISTING IN NUMBER,
    p_STATUS IN OUT NUMBER,
	p_ERROR_MESSAGE IN OUT VARCHAR2
	) AS
	
    v_ProcedureName VARCHAR2(29) := 'PUT_RESOURCE_SEGMENT';
    
  CURSOR c_XML_Resource IS
        SELECT		
                EXTRACTVALUE(VALUE(V), '//TaggingPointID') TaggingPointID,
                EXTRACTVALUE(VALUE(V), '//ProfileRef') ProfileRef,
        		EXTRACT(VALUE(V), '//ContractNumberList').GETCLOBVAL()  ContractNumberCLOB, 
        		EXTRACT(VALUE(V), '//MiscInfoList').GETCLOBVAL()  MiscInfoListCLOB 
        FROM
                 TABLE(XMLSEQUENCE(EXTRACT(XMLTYPE.CREATEXML(p_RESOURCE_CLOB), '//'||p_PHYSICAL_SEGMENT_TYPE))) U,    -- '//Generation' or  '//Load'
                --Debug format
                   --TABLE(XMLSEQUENCE(EXTRACT((SELECT XMLTYPE.CREATEXML(clob_data) FROM XML_TRACE WHERE key1 = 'Generation1'), '//Generation'))) U,
                --end Debug
                TABLE(XMLSEQUENCE(EXTRACT(VALUE(U),'//ResourceList/Resource'))) V;
        
BEGIN
	
    -- Resource Segment --  '//Generation' or  '//Load'
    BEGIN    --TRY INSERT
        IF p_DELETE_EXISTING = 1 THEN
            DELETE FROM ETAG_RESOURCE_SEGMENT A
            WHERE ETAG_ID = p_ETAG_ID
            AND PHYSICAL_SEGMENT_NID = p_PHYSICAL_SEGMENT_NID;
        END IF;
    
		INSERT INTO ETAG_RESOURCE_SEGMENT
            (
            ETAG_ID, 
            PHYSICAL_SEGMENT_NID,
            SEGMENT_TYPE,
            MARKET_SEGMENT_NID, 
            CURRENT_CORRECTION_NID
            )
    	VALUES 
            (
            p_ETAG_ID,
            p_PHYSICAL_SEGMENT_NID,
            p_PHYSICAL_SEGMENT_TYPE,
            p_PARENT_MARKET_SEGMENT_REF,
        	p_CURRENT_CORRECTION_NID
            );
            
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				UPDATE ETAG_RESOURCE_SEGMENT
    				SET 
                        CURRENT_CORRECTION_NID = p_CURRENT_CORRECTION_NID,
                        SEGMENT_TYPE = p_PHYSICAL_SEGMENT_TYPE,
                        MARKET_SEGMENT_NID = p_PARENT_MARKET_SEGMENT_REF 
                    WHERE 
                        ETAG_ID = p_ETAG_ID
                        AND PHYSICAL_SEGMENT_NID = p_PHYSICAL_SEGMENT_NID;
            
        	WHEN OTHERS THEN
                RAISE;
    END;    --TRY INSERT - Resource
    
	-- Add Resource
	FOR v_XML_Resource IN c_XML_Resource LOOP
		-- INSERT INTO tables
        PUT_RESOURCE
        	(
        	p_ETAG_ID,  -- IN
            p_PHYSICAL_SEGMENT_NID,
        	v_XML_Resource.TaggingPointID,
        	v_XML_Resource.ProfileRef,
        	v_XML_Resource.ContractNumberCLOB,
        	v_XML_Resource.MiscInfoListCLOB,
            p_DELETE_EXISTING,
            p_STATUS,
        	p_ERROR_MESSAGE
        	);
	END LOOP;

    
EXCEPTION
	WHEN OTHERS THEN
		IF p_ERROR_MESSAGE IS NULL THEN
            p_STATUS := SQLCODE;
            p_ERROR_MESSAGE := 'Error in '||g_PACKAGE_NAME||'.'||v_ProcedureName||': ' ||SQLERRM;
        END IF;
		RAISE;
	
END PUT_RESOURCE_SEGMENT;
-------------------------------------------------------------------------------------
PROCEDURE PUT_TRANSMISSION_SEGMENT
	(
	p_ETAG_ID IN NUMBER,
	p_PHYSICAL_SEGMENT_TYPE IN VARCHAR2,
    p_PHYSICAL_SEGMENT_NID IN NUMBER,
	p_CURRENT_CORRECTION_NID IN NUMBER,
	p_PARENT_MARKET_SEGMENT_REF IN NUMBER,
	p_TRANSMISSION_CLOB IN CLOB,
    p_DELETE_EXISTING IN NUMBER,
    p_STATUS IN OUT NUMBER,
	p_ERROR_MESSAGE IN OUT VARCHAR2
	) AS
	
    v_ProcedureName VARCHAR2(29) := 'PUT_TRANSMISSION_SEGMENT';
    v_MISC_INFO_LIST_ID NUMBER;
    v_SCHEDULING_ENTITY_LIST_ID NUMBER;
    v_STATUS  NUMBER;
	v_ERROR_MESSAGE  VARCHAR2(512);
    v_TP_CODE NUMBER(9);
    v_POR_CODE NUMBER(9);
    v_POD_CODE NUMBER(9);
    
  CURSOR c_XML_MiscInfoList IS
        SELECT		
        		EXTRACT(VALUE(V), '//MiscInfoList').GETCLOBVAL()  MiscInfoListCLOB 
        FROM
                TABLE(XMLSEQUENCE(EXTRACT(XMLTYPE.CREATEXML(p_TRANSMISSION_CLOB), '//'||p_PHYSICAL_SEGMENT_TYPE))) U,    -- '//Transmission' or  '//TransmissionCorrection'
                --Debug format
                   --TABLE(XMLSEQUENCE(EXTRACT((SELECT XMLTYPE.CREATEXML(clob_data) FROM XML_TRACE WHERE key1 = 'Transmission2'), '//Transmission'))) U,
                --end Debug
                TABLE(XMLSEQUENCE(EXTRACT(VALUE(U), '//MiscInfoList'))) V;
        
  CURSOR c_XML_SchedulingEntityList IS
        SELECT		
        		EXTRACT(VALUE(V), '//SchedulingEntityList').GETCLOBVAL()  SchedulingEntityListCLOB 
        FROM
            --    TABLE(XMLSEQUENCE(EXTRACT(XMLTYPE.CREATEXML(p_TRANSMISSION_CLOB), '//'||p_PHYSICAL_SEGMENT_TYPE))) U,    -- '//Transmission' or  '//TransmissionCorrection'
                --Debug format
                   TABLE(XMLSEQUENCE(EXTRACT((SELECT XMLTYPE.CREATEXML(clob_data) FROM XML_TRACE WHERE key1 = 'Transmission2'), '//Transmission'))) U,
                --end Debug
                TABLE(XMLSEQUENCE(EXTRACT(VALUE(U), '//SchedulingEntityList'))) V;

  CURSOR c_XML_TransmissionProfileRef IS
        SELECT		
        		EXTRACTVALUE(VALUE(V), '/TransmissionProfile/PORProfile/ProfileRef')  PORProfileRef,
        		EXTRACTVALUE(VALUE(V), '/TransmissionProfile/PODProfile/ProfileRef')  PODProfileRef 
        FROM
                TABLE(XMLSEQUENCE(EXTRACT(XMLTYPE.CREATEXML(p_TRANSMISSION_CLOB), '//'||p_PHYSICAL_SEGMENT_TYPE))) U,    -- '//Transmission'
                --Debug format
                   --TABLE(XMLSEQUENCE(EXTRACT((SELECT XMLTYPE.CREATEXML(clob_data) FROM XML_TRACE WHERE key1 = 'Transmission2'), '//Transmission'))) U,
                --end Debug
                TABLE(XMLSEQUENCE(EXTRACT(VALUE(U), '//TransmissionProfileList/TransmissionProfile'))) V;
        
BEGIN
	
    v_STATUS := 0;
	v_ERROR_MESSAGE := '';

    IF p_PHYSICAL_SEGMENT_TYPE = 'Transmission' THEN
        FOR v_XML_MiscInfoList IN c_XML_MiscInfoList LOOP
            PUT_MISC_INFO_LIST
            	(
                v_MISC_INFO_LIST_ID,  -- OUT
            	p_ETAG_ID,
                'MiscInfoList',
                'MiscInfo',
                'Transmission',
            	v_XML_MiscInfoList.MiscInfoListCLOB,
                p_DELETE_EXISTING,
                v_STATUS,
            	v_ERROR_MESSAGE
            	);
        END LOOP;
                    
        FOR v_XML_SchedulingEntityList IN c_XML_SchedulingEntityList LOOP
            PUT_SCHEDULING_ENTITY_LIST
            	(
                v_SCHEDULING_ENTITY_LIST_ID,  -- OUT
            	p_ETAG_ID,
                'SchedulingEntityList',
                'SchedulingEntity',
                'Transmission',
            	v_XML_SchedulingEntityList.SchedulingEntityListCLOB,
                p_DELETE_EXISTING,
                v_STATUS,
            	v_ERROR_MESSAGE
            	);
        END LOOP;
                    
        BEGIN    --TRY INSERT
            IF p_DELETE_EXISTING = 1 THEN
                DELETE FROM ETAG_TRANSMISSION_SEGMENT A
                WHERE ETAG_ID = p_ETAG_ID
                AND PHYSICAL_SEGMENT_NID = p_PHYSICAL_SEGMENT_NID;
            END IF;
        
            SELECT		
                    EXTRACTVALUE(VALUE(U), '//TPCode') ,
                    EXTRACTVALUE(VALUE(U), '//POR') , 
                    EXTRACTVALUE(VALUE(U), '//POD')  
            INTO v_TP_CODE, v_POR_CODE, v_POD_CODE
            FROM
                    TABLE(XMLSEQUENCE(EXTRACT(XMLTYPE.CREATEXML(p_TRANSMISSION_CLOB), '//'||p_PHYSICAL_SEGMENT_TYPE))) U;    -- '//Transmission'
                    --Debug format
                       --TABLE(XMLSEQUENCE(EXTRACT((SELECT XMLTYPE.CREATEXML(clob_data) FROM XML_TRACE WHERE key1 = 'Transmission2'), '//Transmission'))) U
                    --end Debug
    
    		INSERT INTO ETAG_TRANSMISSION_SEGMENT
                (
                ETAG_ID, 
                PHYSICAL_SEGMENT_NID,
                SEGMENT_TYPE,
                MARKET_SEGMENT_NID,
                TP_CODE,
                POR_CODE,
                POD_CODE,
                CURRENT_CORRECTION_NID,
				SCHEDULING_ENTITY_LIST_ID,
                MISC_INFO_LIST_ID
                )
        	VALUES 
                (
                p_ETAG_ID,
                p_PHYSICAL_SEGMENT_NID,
                p_PHYSICAL_SEGMENT_TYPE,
                p_PARENT_MARKET_SEGMENT_REF,
                v_TP_CODE,
                v_POR_CODE,
                v_POD_CODE,
            	p_CURRENT_CORRECTION_NID,
				v_SCHEDULING_ENTITY_LIST_ID,
                v_MISC_INFO_LIST_ID
                );
                
    		EXCEPTION
    			WHEN DUP_VAL_ON_INDEX THEN
    				UPDATE ETAG_TRANSMISSION_SEGMENT
        				SET 
                            SEGMENT_TYPE = p_PHYSICAL_SEGMENT_TYPE,
							--Don't save NULL p_PARENT_MARKET_SEGMENT_REF (in Correction)
                            MARKET_SEGMENT_NID = NVL(p_PARENT_MARKET_SEGMENT_REF,  MARKET_SEGMENT_NID),
                            TP_CODE = NVL(v_TP_CODE, TP_CODE),	--Don't save NULL v_TP_CODE (in Correction)
                            POR_CODE = v_POR_CODE, 
                            POD_CODE = v_POD_CODE, 
                            CURRENT_CORRECTION_NID = p_CURRENT_CORRECTION_NID,
							SCHEDULING_ENTITY_LIST_ID = v_SCHEDULING_ENTITY_LIST_ID,
							MISC_INFO_LIST_ID = v_MISC_INFO_LIST_ID
                        WHERE 
                            ETAG_ID = p_ETAG_ID
                            AND PHYSICAL_SEGMENT_NID = p_PHYSICAL_SEGMENT_NID;
                
            	WHEN OTHERS THEN
                    RAISE;
        END;    --TRY INSERT - ETAG_TRANSMISSION_SEGMENT

        --Put TRANSMISSION_PROFILE Ref
        FOR v_XML_TransmissionProfileRef IN c_XML_TransmissionProfileRef LOOP
            BEGIN    --TRY INSERT
                IF p_DELETE_EXISTING = 1 THEN
                    DELETE FROM ETAG_TRANSMISSION_PROFILE A
                    WHERE ETAG_ID = p_ETAG_ID
                    AND PHYSICAL_SEGMENT_NID = p_PHYSICAL_SEGMENT_NID
                    AND POR_ETAG_PROFILE_NID = v_XML_TransmissionProfileRef.PORProfileRef
                    AND POD_ETAG_PROFILE_NID = v_XML_TransmissionProfileRef.PODProfileRef;
                END IF;
            
        		INSERT INTO ETAG_TRANSMISSION_PROFILE
                    (
                    ETAG_ID, 
                    PHYSICAL_SEGMENT_NID,
                    POR_ETAG_PROFILE_NID,
                    POD_ETAG_PROFILE_NID
                    )
            	VALUES 
                    (
                    p_ETAG_ID,
                    p_PHYSICAL_SEGMENT_NID,
                    v_XML_TransmissionProfileRef.PORProfileRef,
                    v_XML_TransmissionProfileRef.PODProfileRef
                    );
                    
        		EXCEPTION
        			WHEN DUP_VAL_ON_INDEX THEN
        				NULL;
                    
                	WHEN OTHERS THEN
                        RAISE;
            END;    --TRY INSERT - ETAG_TRANSMISSION_PROFILE
        
        END LOOP;  -- c_XML_TransmissionProfileRef
    
    END IF;   -- p_PHYSICAL_SEGMENT_TYPE = 'Transmission' 
    
EXCEPTION
	WHEN OTHERS THEN
		IF p_ERROR_MESSAGE IS NULL THEN
            p_STATUS := SQLCODE;
            p_ERROR_MESSAGE := 'Error in '||g_PACKAGE_NAME||'.'||v_ProcedureName||': ' ||SQLERRM;
        END IF;
		RAISE;
	
END PUT_TRANSMISSION_SEGMENT;
-------------------------------------------------------------------------------------
PROCEDURE PUT_PHYSICAL_SEGMENT
	(
	p_ETAG_ID IN NUMBER,
    p_PHYSICAL_SEGMENT_NID IN NUMBER,
	p_CURRENT_CORRECTION_NID IN NUMBER,
	p_PARENT_MARKET_SEGMENT_REF IN NUMBER,
	p_GENERATION_CLOB IN CLOB,
	p_TRANSMISSION_CLOB IN CLOB,
	p_LOAD_CLOB IN CLOB,
    p_DELETE_EXISTING IN NUMBER,
    p_STATUS IN OUT NUMBER,
	p_ERROR_MESSAGE IN OUT VARCHAR2
	) AS
	
    v_ProcedureName VARCHAR2(29) := 'PUT_PHYSICAL_SEGMENT';
    
    v_CLOB  CLOB;
    v_CLOB_TYPE  VARCHAR2(32);
        
BEGIN

            IF p_TRANSMISSION_CLOB IS NOT NULL THEN
            	v_CLOB_TYPE := 'Transmission';
                v_CLOB := p_TRANSMISSION_CLOB;
                
                PUT_TRANSMISSION_SEGMENT
                	(
                	p_ETAG_ID,
                	v_CLOB_TYPE,
                	p_PHYSICAL_SEGMENT_NID,
                	p_CURRENT_CORRECTION_NID,
                	p_PARENT_MARKET_SEGMENT_REF,
                	v_CLOB,
                    p_DELETE_EXISTING,
                    p_STATUS,
                	p_ERROR_MESSAGE
                	);
        
            ELSE  --Resource
                IF p_GENERATION_CLOB IS NOT NULL THEN
                	v_CLOB_TYPE := 'Generation';
                    v_CLOB := p_GENERATION_CLOB;
                ELSIF p_LOAD_CLOB IS NOT NULL THEN
                	v_CLOB_TYPE := 'Load';
                    v_CLOB := p_LOAD_CLOB; 
                END IF;
                
                PUT_RESOURCE_SEGMENT
                	(
                	p_ETAG_ID,
                	v_CLOB_TYPE,
                	p_PHYSICAL_SEGMENT_NID,
                	p_CURRENT_CORRECTION_NID,
                	p_PARENT_MARKET_SEGMENT_REF,
                	v_CLOB,
                    p_DELETE_EXISTING,
                    p_STATUS,
                	p_ERROR_MESSAGE
                	);
        
            END IF;
            
EXCEPTION
	WHEN OTHERS THEN
		IF p_ERROR_MESSAGE IS NULL THEN
            p_STATUS := SQLCODE;
            p_ERROR_MESSAGE := 'Error in '||g_PACKAGE_NAME||'.'||v_ProcedureName||': ' ||SQLERRM;
        END IF;
		RAISE;
	
END PUT_PHYSICAL_SEGMENT;
-------------------------------------------------------------------------------------
PROCEDURE PUT_TRANSMISSION_ALLOCATION
	(
	p_ETAG_ID IN NUMBER,
	p_TRANSMISSION_ALLOCATION_NID IN NUMBER,
	p_CURRENT_CORRECTION_NID IN NUMBER,
	p_PARENT_PHYSICAL_SEGMENT_REF IN NUMBER,
	p_TRANS_PRODUCT_REF IN NUMBER,
    p_CONTRACT_NUMBER IN VARCHAR2,
    p_TRANSMISSION_CUSTOMER_CODE IN NUMBER,
	p_ALLOC_BASE_PROFILE_CLOB IN CLOB,
    p_DELETE_EXISTING IN NUMBER,
    p_STATUS OUT NUMBER,
	p_ERROR_MESSAGE OUT VARCHAR2
	) AS
	
    v_ProcedureName VARCHAR2(29) := 'PUT_TRANSMISSION_ALLOCATION';
    v_PROFILE_KEY_ID NUMBER;
    v_STATUS  NUMBER := 0;
	v_ERROR_MESSAGE  VARCHAR2(512) := '';
    
  CURSOR c_XML_AllocationProfile IS
        SELECT		
        		EXTRACT(VALUE(V), '//RelativeAllocationProfile').GETCLOBVAL()  RelativeAllocationProfile--, 
        FROM
                TABLE(XMLSEQUENCE(EXTRACT(XMLTYPE.CREATEXML(p_ALLOC_BASE_PROFILE_CLOB), '//AllocationBaseProfile'))) U,
                --Debug format
                    --TABLE(XMLSEQUENCE(EXTRACT((SELECT XMLTYPE.CREATEXML(clob_data) FROM XML_TRACE WHERE key1 = 'DistributeNewTag'), '//DistributeNewTag/Tag'))) T,
                    --TABLE(XMLSEQUENCE(EXTRACT(VALUE(T),'//TagData/TransmissionAllocationList/TransmissionAllocation/AllocationBaseProfile'))) U,
                    --TABLE(XMLSEQUENCE(EXTRACT((SELECT XMLTYPE.CREATEXML(clob_data) FROM XML_TRACE WHERE key1 = 'RelativeProfileList'), '//RelativeProfileList/RelativeProfile'))) U--,
                --end Debug
                TABLE(XMLSEQUENCE(EXTRACT(VALUE(U),'//RelativeAllocationProfileList/RelativeAllocationProfile'))) V;


BEGIN
	
    p_STATUS := 0;
	p_ERROR_MESSAGE := '';
    
    FOR v_XML_AllocationProfile IN c_XML_AllocationProfile LOOP
        v_STATUS := 0;
    	v_ERROR_MESSAGE := '';
    
		-- INSERT INTO ETAG_PROFILE table
        PUT_ETAG_RELATIVE_PROFILE
        	(
            v_PROFILE_KEY_ID,  --OUT
            '//RelativeAllocationProfile', --v_CLOB_XPATH,  -- 
        	p_ETAG_ID,  -- IN
        	p_TRANSMISSION_ALLOCATION_NID, --ParentOrder,
            'RelativeAllocation',
            'AllocationBaseProfile',
        	v_XML_AllocationProfile.RelativeAllocationProfile,
            v_STATUS,
        	v_ERROR_MESSAGE
        	);
        IF v_STATUS = 0 THEN
            p_STATUS := 0;
        	p_ERROR_MESSAGE := '';
        ELSE
            p_STATUS := v_STATUS;
        	p_ERROR_MESSAGE := v_ERROR_MESSAGE;
        END IF;  -- v_STATUS = 0
    END LOOP;
                
    IF v_STATUS = 0 THEN
        BEGIN    --TRY INSERT
            IF p_DELETE_EXISTING = 1 THEN
                DELETE FROM ETAG_TRANSMISSION_ALLOCATION A
                WHERE ETAG_ID = p_ETAG_ID
                    AND TRANSMISSION_ALLOCATION_NID = p_TRANSMISSION_ALLOCATION_NID;
            END IF;
        
    		INSERT INTO ETAG_TRANSMISSION_ALLOCATION
                (
                ETAG_ID, 
                PHYSICAL_SEGMENT_NID,
                TRANSMISSION_ALLOCATION_NID,
                CURRENT_CORRECTION_NID, 
                TRANSMISSION_PRODUCT_NID,
                CONTRACT_NUMBER,
                TRANSMISSION_CUSTOMER_CODE
                )
        	VALUES 
                (
                p_ETAG_ID,
                p_PARENT_PHYSICAL_SEGMENT_REF,
                p_TRANSMISSION_ALLOCATION_NID,
            	p_CURRENT_CORRECTION_NID,
                p_TRANS_PRODUCT_REF,
                p_CONTRACT_NUMBER,
                p_TRANSMISSION_CUSTOMER_CODE
                );

    		EXCEPTION
    			WHEN DUP_VAL_ON_INDEX THEN
                        UPDATE ETAG_TRANSMISSION_ALLOCATION
            				SET 
                                PHYSICAL_SEGMENT_NID = p_PARENT_PHYSICAL_SEGMENT_REF,
                                CURRENT_CORRECTION_NID = NVL(p_CURRENT_CORRECTION_NID, CURRENT_CORRECTION_NID),  -- Don't Update with NULL
                                TRANSMISSION_PRODUCT_NID = p_TRANS_PRODUCT_REF, 
                                CONTRACT_NUMBER = p_CONTRACT_NUMBER,
                                TRANSMISSION_CUSTOMER_CODE = p_TRANSMISSION_CUSTOMER_CODE
                            WHERE 
                                ETAG_ID = p_ETAG_ID
                                AND TRANSMISSION_ALLOCATION_NID = p_TRANSMISSION_ALLOCATION_NID;
                
            	WHEN OTHERS THEN
                    RAISE;
        END;    --TRY INSERT
    
    END IF;   -- v_STATUS = 0 
    
EXCEPTION
	WHEN OTHERS THEN
		IF p_ERROR_MESSAGE IS NULL THEN
            p_STATUS := SQLCODE;
            p_ERROR_MESSAGE := 'Error in '||g_PACKAGE_NAME||'.'||v_ProcedureName||': ' ||SQLERRM;
        END IF;
		RAISE;
	
END PUT_TRANSMISSION_ALLOCATION;
-------------------------------------------------------------------------------------
PROCEDURE PUT_ETAG_ABSOLUTE_PROFILE
	(
    p_PROFILE_KEY_OID OUT NUMBER,
	p_ETAG_ID IN NUMBER,
    p_PARENT_NID IN NUMBER,
	p_PROFILE_STYLE IN VARCHAR2,
	p_PARENT_TYPE IN VARCHAR2,
    p_CLOB IN CLOB,
    p_STATUS IN OUT NUMBER,
	p_ERROR_MESSAGE IN OUT VARCHAR2
	) AS
	
    v_ProcedureName VARCHAR2(29) := 'PUT_ETAG_ABSOLUTE_PROFILE';
    
    v_PROFILE_TYPE_LIST_ID  NUMBER(9);
    v_STATUS  NUMBER := 0;
    v_ERROR_MESSAGE  VARCHAR2(512) := '';
  
  -- Use cross-product to apply all start-stop offsets and MWLevels to all DateTimes in DateTimeList  
  CURSOR c_XML_ProfileValue IS
        SELECT 
            EXTRACTVALUE(VALUE(U), '//AbsoluteStart/DateTime')  StartDateTime,      
            EXTRACTVALUE(VALUE(U), '//AbsoluteStop/DateTime')  StopDateTime,      
            EXTRACTVALUE(VALUE(U), '//MWLevel') MWLevel
        FROM 
            TABLE(XMLSEQUENCE(EXTRACT(XMLTYPE.CREATEXML(p_CLOB), '//AbsoluteBlock'))) U; --'//AbsoluteAllocationProfile'))) U;
            --Debug formats
                --TABLE(XMLSEQUENCE(EXTRACT((SELECT XMLTYPE.CREATEXML(clob_data) FROM XML_TRACE WHERE key1 = 'AbsoluteAllocationProfile'), '//AbsoluteBlock'))) U
                --TABLE(XMLSEQUENCE(EXTRACT((SELECT XMLTYPE.CREATEXML(clob_data) FROM XML_TRACE WHERE key1 = 'AbsoluteProfile1'), '//AbsoluteBlock'))) U
            --end Debug
    
  CURSOR c_XML_ProfileTypeList IS
        SELECT 
            EXTRACT(VALUE(U), '//ProfileTypeList').GETCLOBVAL() ProfileTypeListCLOB
        FROM 
            TABLE(XMLSEQUENCE(EXTRACT(XMLTYPE.CREATEXML(p_CLOB), '//ProfileTypeList'))) U; 
            --Debug format
                --TABLE(XMLSEQUENCE(EXTRACT((SELECT XMLTYPE.CREATEXML(clob_data) FROM XML_TRACE WHERE key1 = 'AbsoluteProfile2'), '//ProfileTypeList'))) U
            --end Debug


BEGIN
	
    --v_CLOB_ROOT := XMLTYPE.CREATEXML(p_CLOB).GetRootElement();  -- AbsoluteProfile or AbsoluteAllocationProfile
    
    --Make PROFILE_TYPE_LIST
    FOR v_XML_ProfileTypeList IN c_XML_ProfileTypeList LOOP
        PUT_SIMPLE_ETAG_LIST
        	(
        	v_PROFILE_TYPE_LIST_ID,  -- OUT
            p_ETAG_ID,
        	'ProfileTypeList',
        	'ProfileType',
        	'ETAG_PROFILE',
        	v_XML_ProfileTypeList.ProfileTypeListCLOB,
            1, --p_DELETE_EXISTING,
            v_STATUS,
        	v_ERROR_MESSAGE
        	);
    END LOOP;
    
    --TRY INSERT
    BEGIN
        DELETE FROM ETAG_PROFILE P
        WHERE  ETAG_ID = p_ETAG_ID
            AND PROFILE_STYLE = p_PROFILE_STYLE
            AND PARENT_TYPE = p_PARENT_TYPE
            AND PARENT_NID = p_PARENT_NID;

        SELECT ETID.NEXTVAL INTO p_PROFILE_KEY_OID FROM DUAL;
        
		INSERT INTO ETAG_PROFILE
            (
            PROFILE_KEY_ID,
            ETAG_ID, 
            PROFILE_STYLE,
            PARENT_TYPE,
            PARENT_NID, 
            PROFILE_TYPE_LIST_ID
            )
    	VALUES 
            (
            p_PROFILE_KEY_OID,
            p_ETAG_ID,
            p_PROFILE_STYLE,
            p_PARENT_TYPE,
        	p_PARENT_NID,
            v_PROFILE_TYPE_LIST_ID
            );
            
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				UPDATE ETAG_PROFILE
    				SET 
                        ETAG_ID = p_ETAG_ID,
                        PROFILE_STYLE = p_PROFILE_STYLE,
                        PARENT_TYPE = p_PARENT_TYPE ,
                        PARENT_NID = p_PARENT_NID,
                        PROFILE_TYPE_LIST_ID = v_PROFILE_TYPE_LIST_ID
                    WHERE 
                        PROFILE_KEY_ID = p_PROFILE_KEY_OID;
            
        	WHEN OTHERS THEN
                RAISE;
    END;    --TRY INSERT
    
	FOR v_XML_ProfileValue IN c_XML_ProfileValue LOOP
        PUT_ABSOLUTE_PROFILE_VALUE
        	(
            p_PROFILE_KEY_OID,
            v_XML_ProfileValue.StartDateTime,
            v_XML_ProfileValue.StopDateTime,
            v_XML_ProfileValue.MWLevel,
            p_STATUS,
        	p_ERROR_MESSAGE
        	);
    END LOOP;
    
    
EXCEPTION
	WHEN OTHERS THEN
		IF p_ERROR_MESSAGE IS NULL THEN
            p_STATUS := SQLCODE;
            p_ERROR_MESSAGE := 'Error in '||g_PACKAGE_NAME||'.'||v_ProcedureName||': ' ||SQLERRM;
        END IF;
		RAISE;
	
END PUT_ETAG_ABSOLUTE_PROFILE;
-------------------------------------------------------------------------------------
/*FUNCTION ETAG_PROFILE_KEY_ID
	(
	p_ETAG_ID IN NUMBER,
    p_PARENT_TYPE IN VARCHAR2,
	p_PARENT_NID IN NUMBER
    ) RETURN NUMBER AS

    v_ProcedureName VARCHAR2(29) := 'ETAG_PROFILE_KEY_ID';
    v_PROFILE_KEY_ID NUMBER(9);
    
BEGIN
    NULL;
END ETAG_PROFILE_KEY_ID;*/
-------------------------------------------------------------------------------------
PROCEDURE PUT_TRANS_ALLOCATN_EXCEPTION
	(
	p_ETAG_ID IN NUMBER,
	p_TRANSMISSION_ALLOCATION_NID IN NUMBER,
	p_ALLOC_EXCP_PROFILE_CLOB IN CLOB,
    p_STATUS OUT NUMBER,
	p_ERROR_MESSAGE OUT VARCHAR2
	) AS
	
    v_ProcedureName VARCHAR2(29) := 'PUT_TRANS_ALLOCATN_EXCEPTION';
    v_PROFILE_KEY_ID NUMBER;
    v_STATUS  NUMBER := 0;
	v_ERROR_MESSAGE  VARCHAR2(512) := '';
    
  CURSOR c_XML_AllocationExcpProfile IS
        SELECT		
        		EXTRACT(VALUE(V), '/AbsoluteAllocationProfile').GETCLOBVAL()  AbsoluteAllocationProfile--, 
        FROM
                TABLE(XMLSEQUENCE(EXTRACT(XMLTYPE.CREATEXML(p_ALLOC_EXCP_PROFILE_CLOB), '//AllocationExceptionProfile'))) U,
                --Debug format
                    --TABLE(XMLSEQUENCE(EXTRACT((SELECT XMLTYPE.CREATEXML(clob_data) FROM XML_TRACE WHERE key1 = 'TransmissionAllocationException1'), '//AllocationExceptionProfile'))) U,
               --end Debug
                TABLE(XMLSEQUENCE(EXTRACT(VALUE(U),'//AbsoluteAllocationProfileList/AbsoluteAllocationProfile'))) V;


BEGIN
	
    p_STATUS := 0;
	p_ERROR_MESSAGE := '';
    
    FOR v_XML_AllocationExcpProfile IN c_XML_AllocationExcpProfile LOOP
        v_STATUS := 0;
    	v_ERROR_MESSAGE := '';
    
		-- Insert ETAG_PROFILE table
        PUT_ETAG_ABSOLUTE_PROFILE
        	(
            v_PROFILE_KEY_ID,  --OUT
        	p_ETAG_ID,  -- IN
        	p_TRANSMISSION_ALLOCATION_NID, --ParentOrder,
            'AbsoluteAllocation',
            'AllocationExceptionProfile',
        	v_XML_AllocationExcpProfile.AbsoluteAllocationProfile,
            v_STATUS,
        	v_ERROR_MESSAGE
        	);
            
        IF v_STATUS = 0 THEN
            p_STATUS := 0;
        	p_ERROR_MESSAGE := '';
        ELSE
            p_STATUS := v_STATUS;
        	p_ERROR_MESSAGE := v_ERROR_MESSAGE;
        END IF;  -- v_STATUS = 0
    END LOOP;
                
    
EXCEPTION
	WHEN OTHERS THEN
		IF p_ERROR_MESSAGE IS NULL THEN
            p_STATUS := SQLCODE;
            p_ERROR_MESSAGE := 'Error in '||g_PACKAGE_NAME||'.'||v_ProcedureName||': ' ||SQLERRM;
        END IF;
		RAISE;
	
END PUT_TRANS_ALLOCATN_EXCEPTION;
-------------------------------------------------------------------------------------
PROCEDURE PUT_ETAG_PROFILE_LIST
	(
	p_ETAG_ID IN NUMBER,
    p_PROFILE_KEY_ID IN NUMBER,
	p_ETAG_LIST_ID IN VARCHAR2,
    p_STATUS OUT NUMBER,
	p_ERROR_MESSAGE OUT VARCHAR2
	) AS
	
    v_ProcedureName VARCHAR2(29) := 'PUT_ETAG_PROFILE_LIST';
    

BEGIN
	
    INSERT INTO ETAG_PROFILE_LIST
        (
        ETAG_ID, 
        PROFILE_KEY_ID,
        ETAG_LIST_ID
        )
	VALUES 
        (
        p_ETAG_ID,
        p_PROFILE_KEY_ID,
        p_ETAG_LIST_ID
        );
    
    
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
		NULL;  --Don't care - already exists
	WHEN OTHERS THEN
		IF p_ERROR_MESSAGE IS NULL THEN
            p_STATUS := SQLCODE;
            p_ERROR_MESSAGE := 'Error in '||g_PACKAGE_NAME||'.'||v_ProcedureName||': ' ||SQLERRM;
        END IF;
	
END PUT_ETAG_PROFILE_LIST;
-------------------------------------------------------------------------------------
PROCEDURE PUT_EXCEPTION_PROFILE
	(
	p_ETAG_ID IN NUMBER,
	p_PROFILE_NID IN NUMBER,
	p_EXCEPTION_PROFILE_CLOB IN CLOB,
    p_STATUS OUT NUMBER,
	p_ERROR_MESSAGE OUT VARCHAR2
	) AS
	
    v_ProcedureName VARCHAR2(29) := 'PUT_EXCEPTION_PROFILE';
    v_PROFILE_KEY_ID NUMBER(9);
    v_STATUS  NUMBER := 0;
	v_ERROR_MESSAGE  VARCHAR2(512) := '';
    v_RequestID_LIST_ID NUMBER(9);
    
  CURSOR c_XML_ExceptionProfile IS
        SELECT		
        		EXTRACT(VALUE(V), '/AbsoluteProfile').GETCLOBVAL()  AbsoluteProfile, 
        		EXTRACT(VALUE(U), '/ExceptionProfile/RequestIDList').GETCLOBVAL()  RequestIDList
        FROM
                TABLE(XMLSEQUENCE(EXTRACT(XMLTYPE.CREATEXML(p_EXCEPTION_PROFILE_CLOB), '//ExceptionProfile'))) U,
                --Debug format
                    --TABLE(XMLSEQUENCE(EXTRACT((SELECT XMLTYPE.CREATEXML(clob_data) FROM XML_TRACE WHERE key1 = 'ExceptionProfile1'), '//ExceptionProfile'))) U,
               --end Debug
                TABLE(XMLSEQUENCE(EXTRACT(VALUE(U),'//AbsoluteProfileList/AbsoluteProfile'))) V;

BEGIN
	
    p_STATUS := 0;
	p_ERROR_MESSAGE := '';
    
    FOR v_XML_ExceptionProfile IN c_XML_ExceptionProfile LOOP
        v_STATUS := 0;
    	v_ERROR_MESSAGE := '';
    
        -- Put RequestID List
        IF v_XML_ExceptionProfile.RequestIDList IS NOT NULL THEN
            PUT_SIMPLE_ETAG_LIST
            	(
            	v_RequestID_LIST_ID,  -- OUT
                p_ETAG_ID,
            	'RequestIDList',
            	'RequestID',
            	'ExceptionProfile',
            	v_XML_ExceptionProfile.RequestIDList,
                1,  --p_DELETE_EXISTING,
                v_STATUS,
            	v_ERROR_MESSAGE
            	);
        END IF;
        
        v_STATUS := 0;
    	v_ERROR_MESSAGE := '';
    
		-- Insert ETAG_PROFILE table
        PUT_ETAG_ABSOLUTE_PROFILE
        	(
            v_PROFILE_KEY_ID,  --OUT
        	p_ETAG_ID,  -- IN
        	p_PROFILE_NID, --ParentOrder,
            'Absolute',
            'ExceptionProfile',
        	v_XML_ExceptionProfile.AbsoluteProfile,
            v_STATUS,
        	v_ERROR_MESSAGE
        	);
            
    	-- Link ResolutionProfile and RequestIDList
        PUT_ETAG_PROFILE_LIST
            (
        	p_ETAG_ID,
            v_PROFILE_KEY_ID,
        	v_RequestID_LIST_ID,
            p_STATUS,
        	p_ERROR_MESSAGE
        	);
            
        IF v_STATUS = 0 THEN
            p_STATUS := 0;
        	p_ERROR_MESSAGE := '';
        ELSE
            p_STATUS := v_STATUS;
        	p_ERROR_MESSAGE := v_ERROR_MESSAGE;
        END IF;  -- v_STATUS = 0
    END LOOP;
                
    
EXCEPTION
	WHEN OTHERS THEN
		IF p_ERROR_MESSAGE IS NULL THEN
            p_STATUS := SQLCODE;
            p_ERROR_MESSAGE := 'Error in '||g_PACKAGE_NAME||'.'||v_ProcedureName||': ' ||SQLERRM;
        END IF;
		RAISE;
	
END PUT_EXCEPTION_PROFILE;
-------------------------------------------------------------------------------------
PROCEDURE PUT_LOSS_METHOD
	(
	p_ETAG_ID IN NUMBER,
    p_PHYSICAL_SEGMENT_REF IN NUMBER,
	p_START_DATE_TIME IN VARCHAR2,
	p_STOP_DATE_TIME IN VARCHAR2,
	p_LOSS_CORRECTION_NID IN NUMBER,
	p_REQUEST_REF IN NUMBER,
	p_INKIND_CLOB IN CLOB,
	p_FINANCIAL_CLOB IN CLOB,
	p_INTERNAL_CLOB IN CLOB,
	p_EXTERNAL_CLOB IN CLOB,
    p_DELETE_EXISTING IN NUMBER,
    p_STATUS IN OUT NUMBER,
	p_ERROR_MESSAGE IN OUT VARCHAR2
	) AS
	
    v_ProcedureName VARCHAR2(29) := 'PUT_LOSS_METHOD';
    v_CLOB_TYPE  VARCHAR2(64);
    v_CLOB  CLOB;
    v_LIST_ID NUMBER(9);
    v_STATUS  NUMBER := 0;
    v_ERROR_MESSAGE  VARCHAR2(512) := '';
    v_START_DATE DATE;
    v_END_DATE DATE;
        
  CURSOR c_XML_TagIDList IS
        SELECT		
        		EXTRACT(VALUE(V), '//TagIDList').GETCLOBVAL()  TagIDList 
        FROM
                TABLE(XMLSEQUENCE(EXTRACT(XMLTYPE.CREATEXML(v_CLOB), '//'||v_CLOB_TYPE))) V;
                --Debug format
                    --TABLE(XMLSEQUENCE(EXTRACT((SELECT XMLTYPE.CREATEXML(clob_data) FROM XML_TRACE WHERE key1 = 'External'), '//External'))) V;  -- = v_CLOB_TYPE), '//'||v_CLOB_TYPE))) V;
                --end Debug

  CURSOR c_XML_ContractNumberList IS
        SELECT		
        		EXTRACT(VALUE(V), '//ContractNumberList').GETCLOBVAL()  ContractNumberList 
        FROM
                TABLE(XMLSEQUENCE(EXTRACT(XMLTYPE.CREATEXML(v_CLOB), '//Internal'))) V;
                --Debug format
                    --TABLE(XMLSEQUENCE(EXTRACT((SELECT XMLTYPE.CREATEXML(clob_data) FROM XML_TRACE WHERE key1 = 'Internal'), '//Internal'))) V;
                --end Debug

BEGIN

    IF p_INKIND_CLOB IS NOT NULL THEN
    	v_CLOB_TYPE := 'InKind';
        
    ELSIF p_FINANCIAL_CLOB IS NOT NULL THEN
    	v_CLOB_TYPE := 'Financial';
        
    ELSIF p_INTERNAL_CLOB IS NOT NULL THEN
    	v_CLOB_TYPE := 'Internal';
        v_CLOB := p_INTERNAL_CLOB;
        -- ContractNumberList
        FOR v_XML_ContractNumberList IN c_XML_ContractNumberList LOOP
            IF v_XML_ContractNumberList.ContractNumberList IS NOT NULL THEN
                PUT_SIMPLE_ETAG_LIST
                	(
                	v_LIST_ID,  -- OUT
                    p_ETAG_ID,
                	'ContractNumberList',
                	'ContractNumber',
                	'ETAG_LOSS_METHOD',
                	v_XML_ContractNumberList.ContractNumberList,
                    p_DELETE_EXISTING,
                    v_STATUS,
                	v_ERROR_MESSAGE
                	);
              END IF;  
        END LOOP;
        --TagID List
        FOR v_XML_TagIDList IN c_XML_TagIDList LOOP
            IF v_XML_TagIDList.TagIDList IS NOT NULL THEN
                PUT_TAGID_LIST
                	(
                	v_LIST_ID,  -- OUT
                    p_ETAG_ID,
                    v_CLOB_TYPE,
                    'TagIDList',  --p_LIST_XPATH_NAME,
                    'TagID',  --p_ITEM_XPATH_NAME,
                    'ETAG_LOSS_METHOD',  --p_LIST_USED_BY,
                	v_XML_TagIDList.TagIDList,
                    p_DELETE_EXISTING,
                    v_STATUS,
                	v_ERROR_MESSAGE
                	);
                    END IF;
        END LOOP;
         
    ELSIF p_EXTERNAL_CLOB IS NOT NULL THEN
    	v_CLOB_TYPE := 'External';
        v_CLOB := p_EXTERNAL_CLOB;
        --TagID List
            FOR v_XML_TagIDList IN c_XML_TagIDList LOOP
                PUT_TAGID_LIST
                	(
                	v_LIST_ID,  -- OUT
                    p_ETAG_ID,
                    v_CLOB_TYPE,
                    'TagIDList',  --p_LIST_XPATH_NAME,
                    'TagID',  --p_ITEM_XPATH_NAME,
                    'ETAG_LOSS_METHOD',  --p_LIST_USED_BY,
                	v_XML_TagIDList.TagIDList,
                    p_DELETE_EXISTING,
                    v_STATUS,
                	v_ERROR_MESSAGE
                	);
            END LOOP;
        
    END IF;
                
    IF v_STATUS = 0 THEN
        BEGIN    --TRY INSERT
            v_START_DATE := TO_CUT(TO_DATE(p_START_DATE_TIME, g_DATE_TIME_FORMAT),'GMT');
            v_END_DATE := TO_CUT(TO_DATE(p_STOP_DATE_TIME, g_DATE_TIME_FORMAT),'GMT');
            
            IF p_DELETE_EXISTING = 1 THEN
                DELETE FROM ETAG_LOSS_METHOD A
                WHERE ETAG_ID = p_ETAG_ID
                    AND PHYSICAL_SEGMENT_NID = p_PHYSICAL_SEGMENT_REF
                    AND START_DATE = v_START_DATE
                    AND END_DATE = v_END_DATE;

            END IF;
        
    		INSERT INTO ETAG_LOSS_METHOD
                (
                ETAG_ID, 
                PHYSICAL_SEGMENT_NID,
                START_DATE,
                END_DATE,
                LOSS_CORRECTION_NID, 
                REQUEST_REF,
                LOSS_TYPE,
                LOSS_TYPE_LIST_ID
                )
        	VALUES 
                (
                p_ETAG_ID,
                p_PHYSICAL_SEGMENT_REF,
                v_START_DATE,
            	v_END_DATE,
                p_LOSS_CORRECTION_NID,
                p_REQUEST_REF,
                v_CLOB_TYPE,
                v_LIST_ID
                );

    		EXCEPTION
    			WHEN DUP_VAL_ON_INDEX THEN
        				UPDATE ETAG_LOSS_METHOD
            				SET 
                                LOSS_TYPE = v_CLOB_TYPE,
                                LOSS_TYPE_LIST_ID = v_LIST_ID,
                                -- Don't set LOSS_CORRECTION_NID or REQUEST_REF to NULL when Processing Change or Correction
                                LOSS_CORRECTION_NID = NVL(p_LOSS_CORRECTION_NID, LOSS_CORRECTION_NID),  -- Don't Update with NULL
                                REQUEST_REF = NVL(p_REQUEST_REF, REQUEST_REF)
                            WHERE 
                                ETAG_ID = p_ETAG_ID
                                AND PHYSICAL_SEGMENT_NID = p_PHYSICAL_SEGMENT_REF
                                AND START_DATE = v_START_DATE
                                AND END_DATE = v_END_DATE;
                
            	WHEN OTHERS THEN
                    RAISE;
        END;    --TRY INSERT
        
    ELSE
            p_STATUS := v_STATUS;
            p_ERROR_MESSAGE := v_ERROR_MESSAGE;
    END IF;   -- v_STATUS = 0 
            
EXCEPTION
	WHEN OTHERS THEN
		IF p_ERROR_MESSAGE IS NULL THEN
            p_STATUS := SQLCODE;
            p_ERROR_MESSAGE := 'Error in '||g_PACKAGE_NAME||'.'||v_ProcedureName||': ' ||SQLERRM;
        END IF;
		RAISE;
	
END PUT_LOSS_METHOD;
-------------------------------------------------------------------------------------
PROCEDURE PUT_RESOURCE_CORRECTION
	(
	p_ETAG_ID IN NUMBER,
    p_PHYSICAL_SEGMENT_NID IN NUMBER,
	p_CURRENT_CORRECTION_NID IN NUMBER,
	p_RESOURCE_CORRECTION_CLOB IN CLOB,
    p_DELETE_EXISTING IN NUMBER,
    p_STATUS IN OUT NUMBER,
	p_ERROR_MESSAGE IN OUT VARCHAR2
	) AS
	
    v_ProcedureName VARCHAR2(29) := 'PUT_RESOURCE_CORRECTION';
    
  CURSOR c_XML_Resource IS
        SELECT		
                --EXTRACTVALUE(VALUE(U), '//TaggingPointID') TaggingPointID,  --NULL in Correction
        		EXTRACT(VALUE(U), '//ContractNumberList').GETCLOBVAL()  ContractNumberCLOB, 
        		EXTRACT(VALUE(U), '//MiscInfoList').GETCLOBVAL()  MiscInfoListCLOB 
        FROM
                 TABLE(XMLSEQUENCE(EXTRACT(XMLTYPE.CREATEXML(p_RESOURCE_CORRECTION_CLOB), '/ResourceCorrection'))) U;    -- '/ResourceCorrection'
                --Debug format
                   --TABLE(XMLSEQUENCE(EXTRACT((SELECT XMLTYPE.CREATEXML(clob_data) FROM XML_TRACE WHERE key1 = 'ResourceCorrection1'), '/ResourceCorrection'))) U
                --end Debug
        
BEGIN
	
	-- Update Resource
	FOR v_XML_Resource IN c_XML_Resource LOOP
		-- INSERT INTO tables
        PUT_RESOURCE
        	(
        	p_ETAG_ID,  -- IN
            p_PHYSICAL_SEGMENT_NID,
        	NULL,  -- v_XML_Resource.TaggingPointID,  --NULL in Correction
        	NULL,  -- v_XML_Resource.ProfileRef,  --NULL in Correction
        	v_XML_Resource.ContractNumberCLOB,
        	v_XML_Resource.MiscInfoListCLOB,
            p_DELETE_EXISTING,
            p_STATUS,
        	p_ERROR_MESSAGE
        	);
	END LOOP;

    UPDATE ETAG_RESOURCE_SEGMENT
    SET 
        CURRENT_CORRECTION_NID = p_CURRENT_CORRECTION_NID
    WHERE 
        ETAG_ID = p_ETAG_ID
        AND PHYSICAL_SEGMENT_NID = p_PHYSICAL_SEGMENT_NID;
            
    
EXCEPTION
	WHEN OTHERS THEN
		IF p_ERROR_MESSAGE IS NULL THEN
            p_STATUS := SQLCODE;
            p_ERROR_MESSAGE := 'Error in '||g_PACKAGE_NAME||'.'||v_ProcedureName||': ' ||SQLERRM;
        END IF;
		RAISE;
	
END PUT_RESOURCE_CORRECTION;
-------------------------------------------------------------------------------------
PROCEDURE PUT_TRANSMISSION_CORRECTION
	(
	p_ETAG_ID IN NUMBER,
    p_PHYSICAL_SEGMENT_NID IN NUMBER,
	p_CURRENT_CORRECTION_NID IN NUMBER,
	p_TRANS_CORRECTION_CLOB IN CLOB,
    p_DELETE_EXISTING IN NUMBER,
    p_STATUS IN OUT NUMBER,
	p_ERROR_MESSAGE IN OUT VARCHAR2
	) AS
	
    v_ProcedureName VARCHAR2(29) := 'PUT_TRANSMISSION_CORRECTION';
    
        
BEGIN
	
	-- Update TransmissionSegment
	IF p_TRANS_CORRECTION_CLOB IS NOT NULL THEN
		-- INSERT INTO tables
        PUT_TRANSMISSION_SEGMENT
        	(
        	p_ETAG_ID,
        	'TransmissionCorrection',
        	p_PHYSICAL_SEGMENT_NID,
        	p_CURRENT_CORRECTION_NID,
        	NULL,  -- p_PARENT_MARKET_SEGMENT_REF, --NULL in Correction
        	p_TRANS_CORRECTION_CLOB,
            p_DELETE_EXISTING,
            p_STATUS,
        	p_ERROR_MESSAGE
        	);
        
	END IF;

    
EXCEPTION
	WHEN OTHERS THEN
		IF p_ERROR_MESSAGE IS NULL THEN
            p_STATUS := SQLCODE;
            p_ERROR_MESSAGE := 'Error in '||g_PACKAGE_NAME||'.'||v_ProcedureName||': ' ||SQLERRM;
        END IF;
		RAISE;
	
END PUT_TRANSMISSION_CORRECTION;
-------------------------------------------------------------------------------------
PROCEDURE PARSE_DISTRIBUTE_NEW_TAG_XML
	(
	p_CLOB IN CLOB,
	p_ETAG_ID OUT NUMBER,
    p_STATUS OUT NUMBER,
	p_ERROR_MESSAGE OUT VARCHAR2
	) AS

    v_ProcedureName VARCHAR2(29) := 'PARSE_DISTRIBUTE_NEW_TAG_XML';
    
    v_TAG_XPATH  VARCHAR2(32) := '/DistributeNewTag/Tag';
    v_CLOB_XPATH  VARCHAR2(32) := '/RelativeProfile';
    v_KEY_ID  NUMBER(9);

  CURSOR c_XML_TagInfo IS
        SELECT 
            EXTRACTVALUE(VALUE(T), '/Tag/TagID/GCACode')
                ||'_'||EXTRACTVALUE(VALUE(T), '/Tag/TagID/PSECode')
                ||EXTRACTVALUE(VALUE(T), '/Tag/TagID/TagCode')
                ||'_'||EXTRACTVALUE(VALUE(T), '/Tag/TagID/LCACode') TAG_IDENT,
            EXTRACTVALUE(VALUE(M), '/MessageInfo/SecurityKey') Security_Key,
            EXTRACTVALUE(VALUE(T), '/Tag/TagID/GCACode') GCA_Code,
            EXTRACTVALUE(VALUE(T), '/Tag/TagID/PSECode') PSE_Code,
            EXTRACTVALUE(VALUE(T), '/Tag/TagID/TagCode') Tag_Code,
            EXTRACTVALUE(VALUE(T), '/Tag/TagID/LCACode') LCA_Code,
            EXTRACTVALUE(VALUE(T), '/Tag/WSCCPreScheduleFlag') WSCC_PreSchedule_Flag,
            EXTRACTVALUE(VALUE(T), '/Tag/TestFlag') Test_Flag,
            EXTRACTVALUE(VALUE(T), '/Tag/TransactionType') Transaction_Type,
            EXTRACTVALUE(VALUE(T), '/Tag/Notes') Notes
        FROM 
            TABLE(XMLSEQUENCE(EXTRACT(XMLTYPE.CREATEXML(p_CLOB), v_TAG_XPATH))) T, -- '/DistributeNewTag/Tag'))) T,
            TABLE(XMLSEQUENCE(EXTRACT(XMLTYPE.CREATEXML(p_CLOB), '/DistributeNewTag/MessageInfo'))) M;
            ----Debug formats
                --TABLE(XMLSEQUENCE(EXTRACT((SELECT XMLTYPE.CREATEXML(clob_data) from xml_trace WHERE key1 = 'DistributeNewTag'), '//DistributeNewTag/Tag'))) T,
                --TABLE(XMLSEQUENCE(EXTRACT((SELECT XMLTYPE.CREATEXML(clob_data) from xml_trace WHERE key1 = 'DistributeNewTag'), '//DistributeNewTag/MessageInfo', 'xmlns=""'))) M;
                --TABLE(XMLSEQUENCE(EXTRACT((SELECT xml from xml_trace WHERE key1 = 'DistributeNewTag'), '//DistributeNewTag/Tag'))) T,
                --TABLE(XMLSEQUENCE(EXTRACT((SELECT xml from xml_trace WHERE key1 = 'DistributeNewTag'), '//DistributeNewTag/MessageInfo', 'xmlns=""'))) M;
            ----end Debug
        
  CURSOR c_XML_RelativeProfile IS
        SELECT		
                EXTRACTVALUE(VALUE(U), '/BaseProfile/ProfileID') ProfileID,
        		EXTRACT(VALUE(V), '/RelativeProfile').GETCLOBVAL()  RelativeProfile 
        FROM
                TABLE(XMLSEQUENCE(EXTRACT(XMLTYPE.CREATEXML(p_CLOB), '/DistributeNewTag/Tag'))) T,
                --Debug format
                    --TABLE(XMLSEQUENCE(EXTRACT((SELECT XMLTYPE.CREATEXML(clob_data) FROM XML_TRACE WHERE key1 = 'DistributeNewTag'), '/DistributeNewTag/Tag'))) T,
                    --TABLE(XMLSEQUENCE(EXTRACT((SELECT XMLTYPE.CREATEXML(clob_data) FROM XML_TRACE WHERE key1 = 'RelativeProfileList'), '/RelativeProfileList/RelativeProfile'))) U--,
                --end Debug
                TABLE(XMLSEQUENCE(EXTRACT(VALUE(T),'/Tag/TagData/ProfileSet/BaseProfileList/BaseProfile'))) U,
                --TABLE(XMLSEQUENCE(EXTRACT(VALUE(T),'/Tag/TagData/ProfileSet/BaseProfileList/BaseProfile/RelativeProfileList/RelativeProfile'))) V
                TABLE(XMLSEQUENCE(EXTRACT(VALUE(U),'/BaseProfile/RelativeProfileList/RelativeProfile'))) V;

  CURSOR c_XML_MarketSegment IS
        SELECT		
                EXTRACTVALUE(VALUE(U), '/MarketSegment/MarketSegmentID') MarketSegmentID,
                EXTRACTVALUE(VALUE(U), '/MarketSegment/CurrentCorrectionID') CurrentCorrectionID,
                EXTRACTVALUE(VALUE(U), '/MarketSegment/PSECode') PSECode,
                EXTRACTVALUE(VALUE(U), '/MarketSegment/EnergyProductRef') EnergyProductRef,
        		EXTRACT(VALUE(U), '/MarketSegment/ContractNumberList').GETCLOBVAL()  ContractNumberList,
        		EXTRACT(VALUE(U), '/MarketSegment/MiscInfoList').GETCLOBVAL()  MiscInfoList 
        FROM
                TABLE(XMLSEQUENCE(EXTRACT(XMLTYPE.CREATEXML(p_CLOB), '/DistributeNewTag/Tag'))) T,
                --Debug format
                    --TABLE(XMLSEQUENCE(EXTRACT((SELECT XMLTYPE.CREATEXML(clob_data) FROM XML_TRACE WHERE key1 = 'DistributeNewTag'), '/DistributeNewTag/Tag'))) T,
                --end Debug
                TABLE(XMLSEQUENCE(EXTRACT(VALUE(T),'/Tag/TagData/MarketSegmentList/MarketSegment'))) U;

  CURSOR c_XML_PhysicalSegment IS
        SELECT		
                EXTRACTVALUE(VALUE(U), '/PhysicalSegment/PhysicalSegmentID') PhysicalSegmentID,
                EXTRACTVALUE(VALUE(U), '/PhysicalSegment/CurrentCorrectionID') CurrentCorrectionID,
                EXTRACTVALUE(VALUE(U), '/PhysicalSegment/ParentMarketSegmentRef') ParentMarketSegmentRef,
        		EXTRACT(VALUE(U), '/PhysicalSegment/Generation').GETCLOBVAL()  GenerationCLOB, 
        		EXTRACT(VALUE(U), '/PhysicalSegment/Transmission').GETCLOBVAL()  TransmissionCLOB, 
        		EXTRACT(VALUE(U), '/PhysicalSegment/Load').GETCLOBVAL()  LoadCLOB 
        FROM
                TABLE(XMLSEQUENCE(EXTRACT(XMLTYPE.CREATEXML(p_CLOB), '/DistributeNewTag/Tag'))) T,
                --Debug format
                   --TABLE(XMLSEQUENCE(EXTRACT((SELECT XMLTYPE.CREATEXML(clob_data) FROM XML_TRACE WHERE key1 = 'DistributeNewTag'), '/DistributeNewTag/Tag'))) T,
                --end Debug
                TABLE(XMLSEQUENCE(EXTRACT(VALUE(T),'/Tag/TagData/PhysicalSegmentList/PhysicalSegment'))) U;

  CURSOR c_XML_TransmissionAllocation IS
        SELECT		
                EXTRACTVALUE(VALUE(U), '/TransmissionAllocation/TransmissionAllocationID') TransmissionAllocationID,
                EXTRACTVALUE(VALUE(U), '/TransmissionAllocation/CurrentCorrectionID') CurrentCorrectionID,
                EXTRACTVALUE(VALUE(U), '/TransmissionAllocation/ParentSegmentRef') ParentSegmentRef,
                EXTRACTVALUE(VALUE(U), '/TransmissionAllocation/TransProductRef') TransProductRef,
                EXTRACTVALUE(VALUE(U), '/TransmissionAllocation/ContractNumber') ContractNumber,
                EXTRACTVALUE(VALUE(U), '/TransmissionAllocation/TransmissionCustomerCode') TransmissionCustomerCode,
        		EXTRACT(VALUE(U), '/TransmissionAllocation/AllocationBaseProfile').GETCLOBVAL()  AllocationBaseProfile 
        FROM
                TABLE(XMLSEQUENCE(EXTRACT(XMLTYPE.CREATEXML(p_CLOB), '/DistributeNewTag/Tag'))) T,
                --Debug format
                    --TABLE(XMLSEQUENCE(EXTRACT((SELECT XMLTYPE.CREATEXML(clob_data) FROM XML_TRACE WHERE key1 = 'DistributeNewTag'), '/DistributeNewTag/Tag'))) T,
                --end Debug
                TABLE(XMLSEQUENCE(EXTRACT(VALUE(T),'/Tag/TagData/TransmissionAllocationList/TransmissionAllocation'))) U;
    
  CURSOR c_XML_LossAccounting IS
        SELECT		
                EXTRACTVALUE(VALUE(U), '/LossAccounting/PhysicalSegmentRef') PhysicalSegmentRef,
        		EXTRACTVALUE(VALUE(V), '/LossMethodEntry/StartDateTime')  StartDateTime, 
        		EXTRACTVALUE(VALUE(V), '/LossMethodEntry/StopDateTime')  StopDateTime, 
        		EXTRACTVALUE(VALUE(V), '/LossMethodEntry/LossCorrectionID')  LossCorrectionID, 
        		EXTRACTVALUE(VALUE(V), '/LossMethodEntry/RequestRef')  RequestRef, 
        		EXTRACT(VALUE(V), '/LossMethodEntry/InKind').GETCLOBVAL()  InKindCLOB, 
        		EXTRACT(VALUE(V), '/LossMethodEntry/Financial').GETCLOBVAL()  FinancialCLOB, 
        		EXTRACT(VALUE(V), '/LossMethodEntry/Internal').GETCLOBVAL()  InternalCLOB, 
        		EXTRACT(VALUE(V), '/LossMethodEntry/External').GETCLOBVAL()  ExternalCLOB 
        FROM
                TABLE(XMLSEQUENCE(EXTRACT(XMLTYPE.CREATEXML(p_CLOB), '/DistributeNewTag/Tag'))) T,
                --Debug format
                    --TABLE(XMLSEQUENCE(EXTRACT((SELECT XMLTYPE.CREATEXML(clob_data) FROM XML_TRACE WHERE key1 = 'DistributeNewTag'), '/DistributeNewTag/Tag'))) T,
                --end Debug
                TABLE(XMLSEQUENCE(EXTRACT(VALUE(T),'/Tag/TagData/LossAccountingList/LossAccounting'))) U,
                TABLE(XMLSEQUENCE(EXTRACT(VALUE(U),'/LossAccounting/LossMethodEntryList/LossMethodEntry'))) V;

BEGIN

	p_STATUS := 0;
    p_ERROR_MESSAGE := '';

    FOR v_XML_TagInfo IN c_XML_TagInfo LOOP
		-- INSERT INTO ETAG table
        PUT_ETAG
        	(
        	p_ETAG_ID,  -- OUT
        	0,  -- p_ETAG_ID IN NUMBER,
        	v_XML_TagInfo.GCA_Code,
        	v_XML_TagInfo.PSE_Code,
        	v_XML_TagInfo.Tag_Code,
        	v_XML_TagInfo.LCA_Code,
            'NewTag',  -- ETAG_STATUS
        	v_XML_TagInfo.Security_Key,
        	v_XML_TagInfo.WSCC_PreSchedule_Flag,
        	v_XML_TagInfo.Test_Flag,
        	v_XML_TagInfo.Transaction_Type,
        	v_XML_TagInfo.Notes,
            1,  -- Delete_Existing
            p_STATUS,
        	p_ERROR_MESSAGE
        	);

    	-- Add Profiles
    	FOR v_XML_RelativeProfile IN c_XML_RelativeProfile LOOP
    		-- INSERT INTO ETAG_PROFILE table
            PUT_ETAG_RELATIVE_PROFILE
            	(
                v_KEY_ID,  --OUT
                v_CLOB_XPATH,  -- '//RelativeProfile'
            	p_ETAG_ID,  -- IN
            	v_XML_RelativeProfile.ProfileID,
                'Relative',
                'BaseProfile',
            	v_XML_RelativeProfile.RelativeProfile,
                p_STATUS,
            	p_ERROR_MESSAGE
            	);
    	END LOOP;

        
    	-- Add MarketSegments
    	FOR v_XML_MarketSegment IN c_XML_MarketSegment LOOP
    		-- INSERT INTO ETAG_MARKET_SEGMENT table
            PUT_MARKET_SEGMENT
            	(
            	p_ETAG_ID,
            	v_XML_MarketSegment.MarketSegmentID,
            	v_XML_MarketSegment.CurrentCorrectionID,
            	v_XML_MarketSegment.PSECode,
            	v_XML_MarketSegment.EnergyProductRef,
            	v_XML_MarketSegment.ContractNumberList,
            	v_XML_MarketSegment.MiscInfoList,
				'MarketSegment', -- p_LIST_USED_BY
                1,  -- Delete_Existing
                p_STATUS,
            	p_ERROR_MESSAGE
            	);
    	END LOOP;


    	-- Add PhysicalSegments
    	FOR v_XML_PhysicalSegment IN c_XML_PhysicalSegment LOOP
    		-- INSERT INTO tables
            PUT_PHYSICAL_SEGMENT
            	(
            	p_ETAG_ID,
            	v_XML_PhysicalSegment.PhysicalSegmentID,
            	v_XML_PhysicalSegment.CurrentCorrectionID,
            	v_XML_PhysicalSegment.ParentMarketSegmentRef,
            	v_XML_PhysicalSegment.GenerationCLOB,
            	v_XML_PhysicalSegment.TransmissionCLOB,
            	v_XML_PhysicalSegment.LoadCLOB,
                1,  -- Delete_Existing
                p_STATUS,
            	p_ERROR_MESSAGE
            	);
    	END LOOP;

    	-- Add TransmissionAllocations
    	FOR v_XML_TransmissionAllocation IN c_XML_TransmissionAllocation LOOP
    		-- INSERT INTO tables
            PUT_TRANSMISSION_ALLOCATION
            	(
            	p_ETAG_ID,  -- IN
            	v_XML_TransmissionAllocation.TransmissionAllocationID,
            	v_XML_TransmissionAllocation.CurrentCorrectionID,
            	v_XML_TransmissionAllocation.ParentSegmentRef,
            	v_XML_TransmissionAllocation.TransProductRef,
            	v_XML_TransmissionAllocation.ContractNumber,
            	v_XML_TransmissionAllocation.TransmissionCustomerCode,
            	v_XML_TransmissionAllocation.AllocationBaseProfile,
                1,  -- Delete_Existing
                p_STATUS,
            	p_ERROR_MESSAGE
            	);
    	END LOOP;

    
    	-- Add LossAccountings
    	FOR v_XML_LossAccounting IN c_XML_LossAccounting LOOP
    		-- INSERT INTO tables
            PUT_LOSS_METHOD
            	(
            	p_ETAG_ID,  -- IN
            	v_XML_LossAccounting.PhysicalSegmentRef,
            	v_XML_LossAccounting.StartDateTime,
            	v_XML_LossAccounting.StopDateTime,
            	v_XML_LossAccounting.LossCorrectionID,
            	v_XML_LossAccounting.RequestRef,
            	v_XML_LossAccounting.InKindCLOB,
            	v_XML_LossAccounting.FinancialCLOB,
            	v_XML_LossAccounting.InternalCLOB,
            	v_XML_LossAccounting.ExternalCLOB,
                1,  -- Delete_Existing
                p_STATUS,
            	p_ERROR_MESSAGE
            	);
    	END LOOP;

    
	END LOOP;
    
    IF p_STATUS = 0 THEN
        COMMIT;
    ELSE
        ROLLBACK;
    END IF;

EXCEPTION
    WHEN OTHERS THEN
		IF p_ERROR_MESSAGE IS NULL THEN
            p_STATUS := SQLCODE;
            p_ERROR_MESSAGE := 'Error in '||g_PACKAGE_NAME||'.'||v_ProcedureName||': ' ||SQLERRM;
        END IF;
        ROLLBACK;
		RETURN;

END PARSE_DISTRIBUTE_NEW_TAG_XML;
------------------------------------------------------------------------------
PROCEDURE PARSE_DISTRIBUTE_PROF_CHANGE
	(
	p_CLOB IN CLOB,
	p_ETAG_ID OUT NUMBER,
    p_STATUS OUT NUMBER,
	p_ERROR_MESSAGE OUT VARCHAR2
	) AS

    v_ProcedureName VARCHAR2(29) := 'PARSE_DISTRIBUTE_PROF_CHANGE';
    
    v_TAG_XPATH  VARCHAR2(32) := '/DistributeProfileChange';
    --v_CLOB_XPATH  VARCHAR2(32) := '//RelativeProfile';
    v_COUNT  NUMBER := 0;

  CURSOR c_XML_MsgInfo IS
        SELECT 
            EXTRACTVALUE(VALUE(T), '/DistributeProfileChange/TagID/GCACode')
                ||'_'||EXTRACTVALUE(VALUE(T), '/DistributeProfileChange/TagID/PSECode')
                ||EXTRACTVALUE(VALUE(T), '/DistributeProfileChange/TagID/TagCode')
                ||'_'||EXTRACTVALUE(VALUE(T), '/DistributeProfileChange/TagID/LCACode') TAG_IDENT,
            EXTRACTVALUE(VALUE(M), '/MessageInfo/SecurityKey') Security_Key,
            EXTRACTVALUE(VALUE(T), '/DistributeProfileChange/TagID/GCACode') GCA_Code,
            EXTRACTVALUE(VALUE(T), '/DistributeProfileChange/TagID/PSECode') PSE_Code,
            EXTRACTVALUE(VALUE(T), '/DistributeProfileChange/TagID/TagCode') Tag_Code,
            EXTRACTVALUE(VALUE(T), '/DistributeProfileChange/TagID/LCACode') LCA_Code,
            EXTRACTVALUE(VALUE(T), '/DistributeProfileChange/ApprovalRights') ApprovalRights,
            EXTRACTVALUE(VALUE(T), '/DistributeProfileChange/RequestID') RequestID,
            EXTRACTVALUE(VALUE(T), '/DistributeProfileChange/Notes') Notes,
            EXTRACTVALUE(VALUE(T), '/DistributeProfileChange/RequestTimeStamp') RequestTimeStamp,
            EXTRACTVALUE(VALUE(T), '/DistributeProfileChange/Late') Late
        FROM 
            TABLE(XMLSEQUENCE(EXTRACT(XMLTYPE.CREATEXML(p_CLOB), v_TAG_XPATH))) T, -- '/DistributeProfileChange'))) T,
            TABLE(XMLSEQUENCE(EXTRACT(XMLTYPE.CREATEXML(p_CLOB), '/DistributeProfileChange/MessageInfo'))) M;
            ----Debug formats
                --TABLE(XMLSEQUENCE(EXTRACT((SELECT XMLTYPE.CREATEXML(clob_data) from xml_trace WHERE key1 = 'DistributeProfileChange'), '/DistributeProfileChange'))) T,
                --TABLE(XMLSEQUENCE(EXTRACT((SELECT XMLTYPE.CREATEXML(clob_data) from xml_trace WHERE key1 = 'DistributeProfileChange'), '/DistributeProfileChange/MessageInfo'))) M
            ----end Debug
                
  CURSOR c_XML_TransAllocationChange IS
        SELECT		
        		XMLTYPE.CREATEXML(EXTRACT(VALUE(U), '/child::node()').GETCLOBVAL()).GetRootElement()  RootElement, 
        		EXTRACTVALUE(VALUE(U), '/child::node()/TransmissionAllocationID')  TransmissionAllocationID, 
                EXTRACTVALUE(VALUE(U), '/child::node()/ParentSegmentRef') ParentSegmentRef,
                EXTRACTVALUE(VALUE(U), '/child::node()/TransProductRef') TransProductRef,
                EXTRACTVALUE(VALUE(U), '/child::node()/ContractNumber') ContractNumber,
                EXTRACTVALUE(VALUE(U), '/child::node()/TransmissionCustomerCode') TransmissionCustomerCode,
        		EXTRACT(VALUE(U), '/child::node()').GETCLOBVAL()  TransAllocationChange_Child 
        FROM
                TABLE(XMLSEQUENCE(EXTRACT(XMLTYPE.CREATEXML(p_CLOB), '/DistributeProfileChange/TransmissionAllocationChangeList/TransmissionAllocationChange/child::node()'))) U;
                --Debug format
                    --TABLE(XMLSEQUENCE(EXTRACT((SELECT XMLTYPE.CREATEXML(clob_data) FROM XML_TRACE WHERE key1 = 'DistributeProfileChange'), '/DistributeProfileChange/TransmissionAllocationChangeList/TransmissionAllocationChange/child::node()'))) U
                --end Debug
        
  CURSOR c_XML_ExceptionProfile IS
        SELECT		
                EXTRACTVALUE(VALUE(U), '/ExceptionProfile/ProfileRef') ProfileRef,
        		EXTRACT(VALUE(U), '/ExceptionProfile').GETCLOBVAL()  ExceptionProfile 
        FROM
                TABLE(XMLSEQUENCE(EXTRACT(XMLTYPE.CREATEXML(p_CLOB), '/DistributeProfileChange/ExceptionProfileChangeList/ExceptionProfile'))) U;
                --Debug format
                    --TABLE(XMLSEQUENCE(EXTRACT((SELECT XMLTYPE.CREATEXML(clob_data) FROM XML_TRACE WHERE key1 = 'DistributeProfileChange'), '/DistributeProfileChange/ExceptionProfileChangeList/ExceptionProfile'))) U
                --end Debug

  CURSOR c_XML_LossAccounting IS
        SELECT		
                EXTRACTVALUE(VALUE(U), '/LossAccountingChange/PhysicalSegmentRef') PhysicalSegmentRef,
        		EXTRACTVALUE(VALUE(V), '/LossMethodChange/StartDateTime')  StartDateTime, 
        		EXTRACTVALUE(VALUE(V), '/LossMethodChange/StopDateTime')  StopDateTime, 
        		EXTRACTVALUE(VALUE(V), '/LossMethodChange/LossCorrectionID')  LossCorrectionID, 
        		EXTRACTVALUE(VALUE(V), '/LossMethodChange/RequestRef')  RequestRef, 
        		EXTRACT(VALUE(V), '/LossMethodChange/InKind').GETCLOBVAL()  InKindCLOB, 
        		EXTRACT(VALUE(V), '/LossMethodChange/Financial').GETCLOBVAL()  FinancialCLOB, 
        		EXTRACT(VALUE(V), '/LossMethodChange/Internal').GETCLOBVAL()  InternalCLOB, 
        		EXTRACT(VALUE(V), '/LossMethodChange/External').GETCLOBVAL()  ExternalCLOB 
        FROM
                TABLE(XMLSEQUENCE(EXTRACT(XMLTYPE.CREATEXML(p_CLOB), '/DistributeProfileChange'))) T,
                --Debug format
                    --TABLE(XMLSEQUENCE(EXTRACT((SELECT XMLTYPE.CREATEXML(clob_data) FROM XML_TRACE WHERE key1 = 'DistributeProfileChange'), '/DistributeProfileChange'))) T,
                --end Debug
                TABLE(XMLSEQUENCE(EXTRACT(VALUE(T),'//LossAccountingChangeList/LossAccountingChange'))) U,
                TABLE(XMLSEQUENCE(EXTRACT(VALUE(U),'//LossAccountingChange/LossMethodChangeList/LossMethodChange'))) V;
BEGIN

	p_STATUS := 0;
    p_ERROR_MESSAGE := '';

    FOR v_XML_MsgInfo IN c_XML_MsgInfo LOOP
		-- INSERT INTO ETAG table
        p_ETAG_ID := GET_ETAG_ID_FROM_TAG_IDENT(v_XML_MsgInfo.TAG_IDENT);
        
		SELECT COUNT(ETAG_ID)
        INTO v_COUNT 
        FROM ETAG
        WHERE ETAG_ID = p_ETAG_ID;
        
        IF v_COUNT = 0 THEN
            --Add ETAG record
            PUT_ETAG
            	(
            	p_ETAG_ID,  -- OUT
            	0,  -- p_ETAG_ID IN NUMBER,
            	v_XML_MsgInfo.GCA_Code,
            	v_XML_MsgInfo.PSE_Code,
            	v_XML_MsgInfo.Tag_Code,
            	v_XML_MsgInfo.LCA_Code,
                'DistributeProfileChange',  -- ETAG_STATUS
            	v_XML_MsgInfo.Security_Key,
            	NULL,  --v_XML_MsgInfo.WSCC_PreSchedule_Flag,
            	NULL,  --v_XML_MsgInfo.Test_Flag,
            	NULL,  --v_XML_MsgInfo.Transaction_Type,
            	'Created from DistributeProfileChange',  --v_XML_MsgInfo.Notes,
                0,  -- Delete_Existing
                p_STATUS,
            	p_ERROR_MESSAGE
            	);

        END IF;
        

    	-- Add Profiles
    	FOR v_XML_ExceptionProfile IN c_XML_ExceptionProfile LOOP
    		-- INSERT INTO ETAG_PROFILE table
            PUT_EXCEPTION_PROFILE
            	(
            	p_ETAG_ID,  -- IN
            	v_XML_ExceptionProfile.ProfileRef,
            	v_XML_ExceptionProfile.ExceptionProfile,
                p_STATUS,
            	p_ERROR_MESSAGE
            	);

    	END LOOP;

        
    	-- Process TransmissionAllocationChange
    	FOR v_XML_TransAllocationChange IN c_XML_TransAllocationChange LOOP
        	IF v_XML_TransAllocationChange.RootElement = 'BaseTransmissionAllocation' THEN
            	FOR v_XML_TransAllocationChange IN c_XML_TransAllocationChange LOOP
            		-- UPDATE table
                    PUT_TRANSMISSION_ALLOCATION
                    	(
                    	p_ETAG_ID,  -- IN
                    	v_XML_TransAllocationChange.TransmissionAllocationID,
                    	NULL, --CurrentCorrectionID,
                    	v_XML_TransAllocationChange.ParentSegmentRef,
                    	v_XML_TransAllocationChange.TransProductRef,
                    	v_XML_TransAllocationChange.ContractNumber,
                    	v_XML_TransAllocationChange.TransmissionCustomerCode,
                    	v_XML_TransAllocationChange.TransAllocationChange_Child,
                        0,  -- Delete_Existing
                        p_STATUS,
                    	p_ERROR_MESSAGE
                    	);
            	END LOOP;
        	ELSIF v_XML_TransAllocationChange.RootElement = 'TransmissionAllocationException' THEN
            	FOR v_XML_TransAllocationChange IN c_XML_TransAllocationChange LOOP
            		-- UPDATE tables
                    PUT_TRANS_ALLOCATN_EXCEPTION
                    	(
                    	p_ETAG_ID,  -- IN
                    	v_XML_TransAllocationChange.TransmissionAllocationID,
                    	v_XML_TransAllocationChange.TransAllocationChange_Child,
                        p_STATUS,
                    	p_ERROR_MESSAGE
                    	);
            	END LOOP;
            END IF;
        END LOOP;

    
    	-- Add LossAccountings
    	FOR v_XML_LossAccounting IN c_XML_LossAccounting LOOP
    		-- INSERT INTO tables
            PUT_LOSS_METHOD
            	(
            	p_ETAG_ID,  -- IN
            	v_XML_LossAccounting.PhysicalSegmentRef,
            	v_XML_LossAccounting.StartDateTime,
            	v_XML_LossAccounting.StopDateTime,
            	v_XML_LossAccounting.LossCorrectionID,
            	v_XML_LossAccounting.RequestRef,
            	v_XML_LossAccounting.InKindCLOB,
            	v_XML_LossAccounting.FinancialCLOB,
            	v_XML_LossAccounting.InternalCLOB,
            	v_XML_LossAccounting.ExternalCLOB,
                0,  -- Delete_Existing
                p_STATUS,
            	p_ERROR_MESSAGE
            	);
    	END LOOP;

    
	END LOOP;
    
    IF p_STATUS = 0 THEN
        COMMIT;
    ELSE
        ROLLBACK;
    END IF;

EXCEPTION
    WHEN OTHERS THEN
		IF p_ERROR_MESSAGE IS NULL THEN
            p_STATUS := SQLCODE;
            p_ERROR_MESSAGE := 'Error in '||g_PACKAGE_NAME||'.'||v_ProcedureName||': ' ||SQLERRM;
        END IF;
        ROLLBACK;
		RETURN;

END PARSE_DISTRIBUTE_PROF_CHANGE;
------------------------------------------------------------------------------
PROCEDURE PARSE_DISTRIBUTE_RESOLUTION
	(
	p_CLOB IN CLOB,
	p_ETAG_ID OUT NUMBER,
    p_STATUS OUT NUMBER,
	p_ERROR_MESSAGE OUT VARCHAR2
	) AS

    v_ProcedureName VARCHAR2(29) := 'PARSE_DISTRIBUTE_RESOLUTION';
    
    v_TAG_XPATH  VARCHAR2(32) := '/DistributeResolution';
    v_STATUS  NUMBER := 0;
    v_ERROR_MESSAGE  VARCHAR2(512) := '';
    v_RequestID_LIST_ID NUMBER(9);
    v_COUNT  NUMBER := 0;
    v_PROFILE_KEY_ID NUMBER(9);

  CURSOR c_XML_MsgInfo IS
        SELECT 
            EXTRACTVALUE(VALUE(T), '/DistributeResolution/TagID/GCACode')
                ||'_'||EXTRACTVALUE(VALUE(T), '/DistributeResolution/TagID/PSECode')
                ||EXTRACTVALUE(VALUE(T), '/DistributeResolution/TagID/TagCode')
                ||'_'||EXTRACTVALUE(VALUE(T), '/DistributeResolution/TagID/LCACode') TAG_IDENT,
            EXTRACTVALUE(VALUE(M), '/MessageInfo/SecurityKey') Security_Key,
            EXTRACTVALUE(VALUE(T), '/DistributeResolution/TagID/GCACode') GCA_Code,
            EXTRACTVALUE(VALUE(T), '/DistributeResolution/TagID/PSECode') PSE_Code,
            EXTRACTVALUE(VALUE(T), '/DistributeResolution/TagID/TagCode') Tag_Code,
            EXTRACTVALUE(VALUE(T), '/DistributeResolution/TagID/LCACode') LCA_Code,
            EXTRACTVALUE(VALUE(T), '/DistributeResolution/RequestStatus') RequestStatus,
            EXTRACTVALUE(VALUE(T), '/DistributeResolution/RequestRef') RequestRef,
    		EXTRACT(VALUE(T), '/DistributeResolution/ResolutionProfile/ExceptionProfileSet/RequestIDList').GETCLOBVAL()  RequestIDList
        FROM 
            TABLE(XMLSEQUENCE(EXTRACT(XMLTYPE.CREATEXML(p_CLOB), v_TAG_XPATH))) T, -- '/DistributeResolution'))) T,
            TABLE(XMLSEQUENCE(EXTRACT(XMLTYPE.CREATEXML(p_CLOB), '/DistributeResolution/MessageInfo'))) M;
            ----Debug formats
                --TABLE(XMLSEQUENCE(EXTRACT((SELECT XMLTYPE.CREATEXML(clob_data) from xml_trace WHERE key1 = 'DistributeResolution'), '/DistributeResolution'))) T,
                --TABLE(XMLSEQUENCE(EXTRACT((SELECT XMLTYPE.CREATEXML(clob_data) from xml_trace WHERE key1 = 'DistributeResolution'), '/DistributeResolution/MessageInfo'))) M
            ----end Debug
                
  CURSOR c_XML_ExceptionProfile IS
        SELECT		
                EXTRACTVALUE(VALUE(U), '/ExceptionProfile/ProfileRef') ProfileRef,
        		EXTRACT(VALUE(U), '/ExceptionProfile').GETCLOBVAL()  ExceptionProfile 
        FROM
                TABLE(XMLSEQUENCE(EXTRACT(XMLTYPE.CREATEXML(p_CLOB), '/DistributeResolution/ResolutionProfile/ExceptionProfileSet/ExceptionProfileList/ExceptionProfile'))) U;
                --Debug format
                    --TABLE(XMLSEQUENCE(EXTRACT((SELECT XMLTYPE.CREATEXML(clob_data) FROM XML_TRACE WHERE key1 = 'DistributeResolution'), '/DistributeResolution/ResolutionProfile/ExceptionProfileSet/ExceptionProfileList/ExceptionProfile'))) U
                --end Debug


BEGIN

	p_STATUS := 0;
    p_ERROR_MESSAGE := '';

    FOR v_XML_MsgInfo IN c_XML_MsgInfo LOOP
        p_ETAG_ID := GET_ETAG_ID_FROM_TAG_IDENT(v_XML_MsgInfo.TAG_IDENT);
        
		SELECT COUNT(ETAG_ID)
        INTO v_COUNT 
        FROM ETAG
        WHERE ETAG_ID = p_ETAG_ID;
        
        IF v_COUNT = 0 THEN
            --Add ETAG record
            PUT_ETAG
            	(
            	p_ETAG_ID,  -- OUT
            	0,  -- p_ETAG_ID IN NUMBER,
            	v_XML_MsgInfo.GCA_Code,
            	v_XML_MsgInfo.PSE_Code,
            	v_XML_MsgInfo.Tag_Code,
            	v_XML_MsgInfo.LCA_Code,
                'DistributeResolution',  -- ETAG_STATUS
            	v_XML_MsgInfo.Security_Key,
            	NULL,  --v_XML_MsgInfo.WSCC_PreSchedule_Flag,
            	NULL,  --v_XML_MsgInfo.Test_Flag,
            	NULL,  --v_XML_MsgInfo.Transaction_Type,
            	'Created from DistributeResolution',  --v_XML_MsgInfo.Notes,
                0,  -- Delete_Existing
                p_STATUS,
            	p_ERROR_MESSAGE
            	);

        END IF;
        
        -- Put RequestIDList
        IF v_XML_MsgInfo.RequestIDList IS NOT NULL THEN
            PUT_SIMPLE_ETAG_LIST
            	(
            	v_RequestID_LIST_ID,  -- OUT
                p_ETAG_ID,
            	'RequestIDList',
            	'RequestID',
            	'ResolutionProfile',
            	v_XML_MsgInfo.RequestIDList,
                1,  --p_DELETE_EXISTING,
                v_STATUS,
            	v_ERROR_MESSAGE
            	);
        END IF;
    
		-- INSERT placeholder ResolutionProfile INTO ETAG_PROFILE table
        -- to have profile to attach RequestIDList to.
        PUT_ETAG_ABSOLUTE_PROFILE
        	(
            v_PROFILE_KEY_ID,  --OUT
        	p_ETAG_ID,  -- IN
        	NULL, --ParentOrder
            'Absolute',
            'ResolutionProfile',
        	NULL, --ProfileCLOB,
            p_STATUS,
        	p_ERROR_MESSAGE
        	);

    	-- Link ResolutionProfile and RequestIDList
        PUT_ETAG_PROFILE_LIST
            (
        	p_ETAG_ID,
            v_PROFILE_KEY_ID,
        	v_RequestID_LIST_ID,
            p_STATUS,
        	p_ERROR_MESSAGE
        	);
            
        -- Add Exception Profiles
    	FOR v_XML_ExceptionProfile IN c_XML_ExceptionProfile LOOP
    		-- INSERT INTO ETAG_PROFILE table
            PUT_EXCEPTION_PROFILE
            	(
            	p_ETAG_ID,  -- IN
            	v_XML_ExceptionProfile.ProfileRef,
            	v_XML_ExceptionProfile.ExceptionProfile,
                p_STATUS,
            	p_ERROR_MESSAGE
            	);

    	END LOOP;

        
	END LOOP;
    
    IF p_STATUS = 0 THEN
        COMMIT;
    ELSE
        ROLLBACK;
    END IF;

EXCEPTION
    WHEN OTHERS THEN
		IF p_ERROR_MESSAGE IS NULL THEN
            p_STATUS := SQLCODE;
            p_ERROR_MESSAGE := 'Error in '||g_PACKAGE_NAME||'.'||v_ProcedureName||': ' ||SQLERRM;
        END IF;
        ROLLBACK;
		RETURN;

END PARSE_DISTRIBUTE_RESOLUTION;
------------------------------------------------------------------------------
PROCEDURE PARSE_DISTRIBUTE_STATUS
	(
	p_CLOB IN CLOB,
	p_ETAG_ID OUT NUMBER,
    p_STATUS OUT NUMBER,
	p_ERROR_MESSAGE OUT VARCHAR2
	) AS

    v_ProcedureName VARCHAR2(29) := 'PARSE_DISTRIBUTE_STATUS';
    
    v_TAG_XPATH  VARCHAR2(32) := '/DistributeStatus';
    v_STATUS  NUMBER := 0;
    v_ERROR_MESSAGE  VARCHAR2(512) := '';
    v_COUNT  NUMBER := 0;
    v_MESSAGE_CALL_DATE  DATE;

  CURSOR c_XML_MsgInfo IS
        SELECT 
            EXTRACTVALUE(VALUE(T), '/DistributeStatus/TagID/GCACode')
                ||'_'||EXTRACTVALUE(VALUE(T), '/DistributeStatus/TagID/PSECode')
                ||EXTRACTVALUE(VALUE(T), '/DistributeStatus/TagID/TagCode')
                ||'_'||EXTRACTVALUE(VALUE(T), '/DistributeStatus/TagID/LCACode') TAG_IDENT,
            EXTRACTVALUE(VALUE(M), '/MessageInfo/SecurityKey') Security_Key,
            EXTRACTVALUE(VALUE(M), '/MessageInfo/CallTimeStamp') CallTimeStamp,
            EXTRACTVALUE(VALUE(T), '/DistributeStatus/TagID/GCACode') GCA_Code,
            EXTRACTVALUE(VALUE(T), '/DistributeStatus/TagID/PSECode') PSE_Code,
            EXTRACTVALUE(VALUE(T), '/DistributeStatus/TagID/TagCode') Tag_Code,
            EXTRACTVALUE(VALUE(T), '/DistributeStatus/TagID/LCACode') LCA_Code,
            EXTRACTVALUE(VALUE(T), '/DistributeStatus/RequestStatus') RequestStatus,
            EXTRACTVALUE(VALUE(T), '/DistributeStatus/RequestRef') RequestRef
        FROM 
            TABLE(XMLSEQUENCE(EXTRACT(XMLTYPE.CREATEXML(p_CLOB), v_TAG_XPATH))) T, -- '/DistributeStatus'))) T,
            TABLE(XMLSEQUENCE(EXTRACT(XMLTYPE.CREATEXML(p_CLOB), '/DistributeStatus/MessageInfo'))) M;
            ----Debug formats
                --TABLE(XMLSEQUENCE(EXTRACT((SELECT XMLTYPE.CREATEXML(clob_data) from xml_trace WHERE key1 = 'DistributeStatus'), '/DistributeStatus'))) T,
                --TABLE(XMLSEQUENCE(EXTRACT((SELECT XMLTYPE.CREATEXML(clob_data) from xml_trace WHERE key1 = 'DistributeStatus'), '/DistributeStatus/MessageInfo'))) M
            ----end Debug
                
  CURSOR c_XML_Status IS
        SELECT		
                --EXTRACT(VALUE(U), '/Status/Entity/child::node()').GETCLOBVAL()  Entity_CHILD, 
     		    XMLTYPE.CREATEXML(EXTRACT(VALUE(U), '/Status/Entity/child::node()').GETCLOBVAL()).GetRootElement()  EntityType, 
                EXTRACTVALUE(VALUE(U), '/Status/Entity/child::*/child::text()')  EntityCode,
                EXTRACTVALUE(VALUE(U), '/Status/DeliveryStatus')  DeliveryStatus,
                EXTRACTVALUE(VALUE(U), '/Status/ApprovalStatus')  ApprovalStatus,
                EXTRACTVALUE(VALUE(U), '/Status/ApprovalStatusType')  ApprovalStatusType,
                EXTRACTVALUE(VALUE(U), '/Status/ApprovalTimeStamp')  ApprovalTimeStamp,
                EXTRACTVALUE(VALUE(U), '/Status/Notes')  Notes
        FROM
                TABLE(XMLSEQUENCE(EXTRACT(XMLTYPE.CREATEXML(p_CLOB), '/DistributeStatus/StatusList/Status'))) U;
                --Debug format
                    --TABLE(XMLSEQUENCE(EXTRACT((SELECT XMLTYPE.CREATEXML(clob_data) FROM XML_TRACE WHERE key1 = 'DistributeStatus'), '/DistributeStatus/StatusList/Status'))) U
                --end Debug
                

BEGIN

	p_STATUS := 0;
    p_ERROR_MESSAGE := '';

    FOR v_XML_MsgInfo IN c_XML_MsgInfo LOOP
        
        p_ETAG_ID := GET_ETAG_ID_FROM_TAG_IDENT(v_XML_MsgInfo.TAG_IDENT);
        v_MESSAGE_CALL_DATE := TO_CUT(TO_DATE(v_XML_MsgInfo.CallTimeStamp, g_DATE_TIME_FORMAT),'GMT');
        v_STATUS := 0;
    	v_ERROR_MESSAGE := '';
             
		SELECT COUNT(ETAG_ID)
        INTO v_COUNT 
        FROM ETAG
        WHERE ETAG_ID = p_ETAG_ID;
        
        IF v_COUNT = 0 THEN
            --Add ETAG record
            PUT_ETAG
            	(
            	p_ETAG_ID,  -- OUT
            	0,  -- p_ETAG_ID IN NUMBER,
            	v_XML_MsgInfo.GCA_Code,
            	v_XML_MsgInfo.PSE_Code,
            	v_XML_MsgInfo.Tag_Code,
            	v_XML_MsgInfo.LCA_Code,
                'DistributeStatus',  -- ETAG_STATUS
            	v_XML_MsgInfo.Security_Key,
            	NULL,  --v_XML_MsgInfo.WSCC_PreSchedule_Flag,
            	NULL,  --v_XML_MsgInfo.Test_Flag,
            	NULL,  --v_XML_MsgInfo.Transaction_Type,
            	'Created from DistributeStatus',  --v_XML_MsgInfo.Notes,
                0,  -- Delete_Existing
                v_STATUS,
            	v_ERROR_MESSAGE
            	);

        END IF;
        
        IF v_STATUS = 0 THEN
            -- Add ETAG_STATUS records
        	FOR v_XML_Status IN c_XML_Status LOOP
        		-- INSERT INTO ETAG_PROFILE table
                PUT_ETAG_STATUS
                	(
                	p_ETAG_ID,  -- IN
                    v_MESSAGE_CALL_DATE,
                    v_XML_MsgInfo.RequestRef,
                	v_XML_Status.EntityType,
                	v_XML_Status.EntityCode,
                	v_XML_Status.DeliveryStatus,
                	v_XML_Status.ApprovalStatus,
                	v_XML_Status.ApprovalStatusType,
                	v_XML_Status.ApprovalTimeStamp,
                	v_XML_Status.Notes,
                    1, -- Delete_Earlier
                    v_STATUS,
                	v_ERROR_MESSAGE
                	);
    
        	END LOOP;
        END IF;

        IF v_STATUS <> 0 THEN
            p_STATUS := v_STATUS;
        	p_ERROR_MESSAGE := v_ERROR_MESSAGE;
        END IF;
        
	END LOOP;
    
    IF p_STATUS = 0 THEN
        COMMIT;
    ELSE
        ROLLBACK;
    END IF;

EXCEPTION
    WHEN OTHERS THEN
		IF p_ERROR_MESSAGE IS NULL THEN
            p_STATUS := SQLCODE;
            p_ERROR_MESSAGE := 'Error in '||g_PACKAGE_NAME||'.'||v_ProcedureName||': ' ||SQLERRM;
        END IF;
        ROLLBACK;
		RETURN;

END PARSE_DISTRIBUTE_STATUS;
------------------------------------------------------------------------------
PROCEDURE PARSE_DISTRIBUTE_CORRECTION
	(
	p_CLOB IN CLOB,
	p_ETAG_ID OUT NUMBER,
    p_STATUS OUT NUMBER,
	p_ERROR_MESSAGE OUT VARCHAR2
	) AS

    v_ProcedureName VARCHAR2(29) := 'PARSE_DISTRIBUTE_CORRECTION';
    
    v_TAG_XPATH  VARCHAR2(32) := '/DistributeCorrection';
    --v_CLOB_XPATH  VARCHAR2(32) := '/RelativeProfile';
    v_COUNT  NUMBER := 0;

  CURSOR c_XML_MsgInfo IS
        SELECT 
            EXTRACTVALUE(VALUE(T), '/DistributeCorrection/TagID/GCACode')
                ||'_'||EXTRACTVALUE(VALUE(T), '/DistributeCorrection/TagID/PSECode')
                ||EXTRACTVALUE(VALUE(T), '/DistributeCorrection/TagID/TagCode')
                ||'_'||EXTRACTVALUE(VALUE(T), '/DistributeCorrection/TagID/LCACode') TAG_IDENT,
            EXTRACTVALUE(VALUE(M), '/MessageInfo/SecurityKey') Security_Key,
            EXTRACTVALUE(VALUE(T), '/DistributeCorrection/TagID/GCACode') GCA_Code,
            EXTRACTVALUE(VALUE(T), '/DistributeCorrection/TagID/PSECode') PSE_Code,
            EXTRACTVALUE(VALUE(T), '/DistributeCorrection/TagID/TagCode') Tag_Code,
            EXTRACTVALUE(VALUE(T), '/DistributeCorrection/TagID/LCACode') LCA_Code,
            EXTRACTVALUE(VALUE(T), '/DistributeCorrection/Impact') Impact,
            EXTRACTVALUE(VALUE(T), '/DistributeCorrection/Notes') Notes,
            EXTRACTVALUE(VALUE(T), '/DistributeCorrection/RequestTimeStamp') RequestTimeStamp,
            EXTRACTVALUE(VALUE(T), '/DistributeCorrection/Late') Late
        FROM 
            TABLE(XMLSEQUENCE(EXTRACT(XMLTYPE.CREATEXML(p_CLOB), v_TAG_XPATH))) T, -- '/DistributeCorrection'))) T,
            TABLE(XMLSEQUENCE(EXTRACT(XMLTYPE.CREATEXML(p_CLOB), '/DistributeCorrection/MessageInfo'))) M;
            ----Debug formats
                --TABLE(XMLSEQUENCE(EXTRACT((SELECT XMLTYPE.CREATEXML(clob_data) from xml_trace WHERE key1 = '/DistributeCorrection'), '/DistributeCorrection'))) T,
                --TABLE(XMLSEQUENCE(EXTRACT((SELECT XMLTYPE.CREATEXML(clob_data) from xml_trace WHERE key1 = '/DistributeCorrection'), '/DistributeCorrection/MessageInfo'))) M
            ----end Debug
        
  CURSOR c_XML_PhysicalCorrection IS
        SELECT		
        		EXTRACT(VALUE(U), '/PhysicalSegmentCorrection/ResourceCorrection').GETCLOBVAL()  ResourceCorrection, 
        		EXTRACT(VALUE(U), '/PhysicalSegmentCorrection/TransmissionCorrection').GETCLOBVAL()  TransmissionCorrection,
                EXTRACTVALUE(VALUE(U), '/PhysicalSegmentCorrection/PhysicalSegmentID') PhysicalSegmentID,
                EXTRACTVALUE(VALUE(V), '/PhySegCorID/PhysicalSegmentID') CorIDPhysicalSegmentID,
                EXTRACTVALUE(VALUE(V), '/PhySegCorID/CurrentCorrectionID') CurrentCorrectionID 
        FROM
                TABLE(XMLSEQUENCE(EXTRACT(XMLTYPE.CREATEXML(p_CLOB), '/DistributeCorrection'))) T,
                --Debug format
                    --TABLE(XMLSEQUENCE(EXTRACT((SELECT XMLTYPE.CREATEXML(clob_data) FROM XML_TRACE WHERE key1 = 'DistributeCorrection'), '/DistributeCorrection'))) T,
                --end Debug
                TABLE(XMLSEQUENCE(EXTRACT(VALUE(T),'/DistributeCorrection/CorrectionList/Correction/PhysicalSegmentCorrection'))) U,
                TABLE(XMLSEQUENCE(EXTRACT(VALUE(T),'/DistributeCorrection/CorrectionIDList/CorIDSet/PhySegCorID'))) V
        WHERE
				EXTRACTVALUE(VALUE(V), '/PhySegCorID/PhysicalSegmentID')
				 = EXTRACTVALUE(VALUE(U), '/PhysicalSegmentCorrection/PhysicalSegmentID');

  CURSOR c_XML_MarketSegCorrection IS
        SELECT		
                EXTRACT(VALUE(U), '/MarketSegmentCorrection/MarketCorrection').GETCLOBVAL() MarketCorrection,
                EXTRACTVALUE(VALUE(U), '/MarketSegmentCorrection/MarketCorrection/PSECode') PSECode,
                EXTRACTVALUE(VALUE(U), '/MarketSegmentCorrection/MarketCorrection/EnergyProductRef') EnergyProductRef,
                EXTRACTVALUE(VALUE(U), '/MarketSegmentCorrection/MarketSegmentID') MarketSegmentID,
                EXTRACTVALUE(VALUE(V), '/MarSegCorID/MarketSegmentRef') MarketSegmentRef,
                EXTRACTVALUE(VALUE(V), '/MarSegCorID/CurrentCorrectionID') CurrentCorrectionID,
        		EXTRACT(VALUE(U), '/MarketSegmentCorrection/MarketCorrection/ContractNumberList').GETCLOBVAL()  ContractNumberList, 
        		EXTRACT(VALUE(U), '/MarketSegmentCorrection/MarketCorrection/MiscInfoList').GETCLOBVAL()  MiscInfoList 
        FROM
                TABLE(XMLSEQUENCE(EXTRACT(XMLTYPE.CREATEXML(p_CLOB), '/DistributeCorrection'))) T,
                --Debug format
                    --TABLE(XMLSEQUENCE(EXTRACT((SELECT XMLTYPE.CREATEXML(clob_data) FROM XML_TRACE WHERE key1 = 'DistributeCorrection'), '/DistributeCorrection'))) T,
                --end Debug
                TABLE(XMLSEQUENCE(EXTRACT(VALUE(T),'/DistributeCorrection/CorrectionList/Correction/MarketSegmentCorrection'))) U,
                TABLE(XMLSEQUENCE(EXTRACT(VALUE(T),'/DistributeCorrection/CorrectionIDList/CorIDSet/MarSegCorID'))) V
        WHERE
				EXTRACTVALUE(VALUE(V), '/MarSegCorID/MarketSegmentRef')
				 = EXTRACTVALUE(VALUE(U), '/MarketSegmentCorrection/MarketSegmentID');
				 
  CURSOR c_XML_TransAllocCorrection IS
        SELECT		
                EXTRACTVALUE(VALUE(W), '/TransAllocCorID/TransmissionAllocationID') CorIDTransmissionAllocationID,
                EXTRACTVALUE(VALUE(W), '/TransAllocCorID/CurrentCorrectionID') CurrentCorrectionID,
                EXTRACTVALUE(VALUE(U), '/TransmissionAllocationCorrection/TransmissionAllocationID') TransmissionAllocationID,
                EXTRACTVALUE(VALUE(U), '/TransmissionAllocationCorrection/ParentSegmentRef') ParentSegmentRef,
                EXTRACTVALUE(VALUE(U), '/TransmissionAllocationCorrection/TransProductRef') TransProductRef,
                EXTRACTVALUE(VALUE(U), '/TransmissionAllocationCorrection/ContractNumber') ContractNumber,
                EXTRACTVALUE(VALUE(U), '/TransmissionAllocationCorrection/TransmissionCustomerCode') TransmissionCustomerCode
        FROM
                TABLE(XMLSEQUENCE(EXTRACT(XMLTYPE.CREATEXML(p_CLOB), '/DistributeCorrection'))) T,
                --Debug format
                    --TABLE(XMLSEQUENCE(EXTRACT((SELECT XMLTYPE.CREATEXML(clob_data) FROM XML_TRACE WHERE key1 = 'DistributeCorrection'), '/DistributeCorrection'))) T,
                --end Debug
                TABLE(XMLSEQUENCE(EXTRACT(VALUE(T),'/DistributeCorrection/CorrectionList/Correction/TransmissionAllocationCorrection'))) U,
                TABLE(XMLSEQUENCE(EXTRACT(VALUE(T),'/DistributeCorrection/CorrectionIDList/CorIDSet/TransAllocCorID'))) W
        WHERE
				EXTRACTVALUE(VALUE(W), '/TransAllocCorID/TransmissionAllocationID')
				 = EXTRACTVALUE(VALUE(U), '/TransmissionAllocationCorrection/TransmissionAllocationID');
    
  CURSOR c_XML_LossAcctingCorrection IS
        SELECT		
                EXTRACTVALUE(VALUE(U), '/LossAccountingCorrection/PhysicalSegmentID') PhysicalSegmentID,
                EXTRACTVALUE(VALUE(W), '/LossAccCorID/PhysicalSegmentRef') PhysicalSegmentRef,
                EXTRACTVALUE(VALUE(W), '/LossAccCorID/LossCorrectionID') LossCorrectionID,
        		EXTRACTVALUE(VALUE(V), '/LossMethodCorrection/StartDateTime')  StartDateTime, 
        		EXTRACTVALUE(VALUE(V), '/LossMethodCorrection/StopDateTime')  StopDateTime, 
        		EXTRACTVALUE(VALUE(V), '/LossMethodCorrection/RequestRef')  RequestRef, 
        		EXTRACT(VALUE(V), '/LossMethodCorrection/InKind').GETCLOBVAL()  InKindCLOB, 
        		EXTRACT(VALUE(V), '/LossMethodCorrection/Financial').GETCLOBVAL()  FinancialCLOB, 
        		EXTRACT(VALUE(V), '/LossMethodCorrection/Internal').GETCLOBVAL()  InternalCLOB, 
        		EXTRACT(VALUE(V), '/LossMethodCorrection/External').GETCLOBVAL()  ExternalCLOB 
        FROM
                TABLE(XMLSEQUENCE(EXTRACT(XMLTYPE.CREATEXML(p_CLOB), '/DistributeCorrection'))) T,
                --Debug format
                    --TABLE(XMLSEQUENCE(EXTRACT((SELECT XMLTYPE.CREATEXML(clob_data) FROM XML_TRACE WHERE key1 = 'DistributeCorrection'), '/DistributeCorrection'))) T,
                --end Debug
                TABLE(XMLSEQUENCE(EXTRACT(VALUE(T),'/DistributeCorrection/CorrectionList/Correction/LossAccountingCorrection'))) U,
                TABLE(XMLSEQUENCE(EXTRACT(VALUE(U),'/LossAccountingCorrection/LossMethodCorrectionList/LossMethodCorrection'))) V,
                TABLE(XMLSEQUENCE(EXTRACT(VALUE(T),'/DistributeCorrection/CorrectionIDList/CorIDSet/LossAccCorID'))) W
        WHERE
				EXTRACTVALUE(VALUE(W), '/LossAccCorID/PhysicalSegmentRef')
				 = EXTRACTVALUE(VALUE(U), '/LossAccountingCorrection/PhysicalSegmentID');

BEGIN

	p_STATUS := 0;
    p_ERROR_MESSAGE := '';

    FOR v_XML_MsgInfo IN c_XML_MsgInfo LOOP
		-- INSERT INTO ETAG table
        p_ETAG_ID := GET_ETAG_ID_FROM_TAG_IDENT(v_XML_MsgInfo.TAG_IDENT);
        
		SELECT COUNT(ETAG_ID)
        INTO v_COUNT 
        FROM ETAG
        WHERE ETAG_ID = p_ETAG_ID;
        
        IF v_COUNT = 0 THEN
            --Add ETAG record if missing
            PUT_ETAG
            	(
            	p_ETAG_ID,  -- OUT
            	0,  -- p_ETAG_ID IN NUMBER,
            	v_XML_MsgInfo.GCA_Code,
            	v_XML_MsgInfo.PSE_Code,
            	v_XML_MsgInfo.Tag_Code,
            	v_XML_MsgInfo.LCA_Code,
                'DistributeCorrection',  -- ETAG_STATUS
            	v_XML_MsgInfo.Security_Key,
            	NULL,  --v_XML_MsgInfo.WSCC_PreSchedule_Flag,
            	NULL,  --v_XML_MsgInfo.Test_Flag,
            	NULL,  --v_XML_MsgInfo.Transaction_Type,
            	'Created from DistributeCorrection',  --v_XML_MsgInfo.Notes,
                0,  -- Delete_Existing
                p_STATUS,
            	p_ERROR_MESSAGE
            	);

        END IF;
        

    	IF p_STATUS = 0 THEN
    		-- Update MarketSegments
        	FOR v_XML_MarketSegCorrection IN c_XML_MarketSegCorrection LOOP
        		-- Update table
                PUT_MARKET_SEGMENT
                	(
                	p_ETAG_ID,
                	v_XML_MarketSegCorrection.MarketSegmentID,
                	v_XML_MarketSegCorrection.CurrentCorrectionID,
                	v_XML_MarketSegCorrection.PSECode,  -- Will be NULL in Correction
                	v_XML_MarketSegCorrection.EnergyProductRef,
                	v_XML_MarketSegCorrection.ContractNumberList,
                	v_XML_MarketSegCorrection.MiscInfoList,
    				'MarketCorrection', -- p_LIST_USED_BY
                    0,  -- Delete_Existing
                    p_STATUS,
                	p_ERROR_MESSAGE
                	);
        	END LOOP;
		END IF;
    
    
    	IF p_STATUS = 0 THEN
        	-- Update PhysicalSegments
        	FOR v_XML_PhysicalCorrection IN c_XML_PhysicalCorrection LOOP
        		IF v_XML_PhysicalCorrection.ResourceCorrection IS NOT NULL THEN
    			
                    PUT_RESOURCE_CORRECTION
                    	(
                    	p_ETAG_ID,
                    	v_XML_PhysicalCorrection.PhysicalSegmentID,
                    	v_XML_PhysicalCorrection.CurrentCorrectionID,
                    	v_XML_PhysicalCorrection.ResourceCorrection,
                        0,  -- Delete_Existing
                        p_STATUS,
                    	p_ERROR_MESSAGE
                    	);
            	
    			END IF;
    			
        		IF v_XML_PhysicalCorrection.TransmissionCorrection IS NOT NULL THEN
                    PUT_TRANSMISSION_CORRECTION
                    	(
                    	p_ETAG_ID,
                    	v_XML_PhysicalCorrection.PhysicalSegmentID,
                    	v_XML_PhysicalCorrection.CurrentCorrectionID,
                    	v_XML_PhysicalCorrection.TransmissionCorrection,
                        0,  -- Delete_Existing
                        p_STATUS,
                    	p_ERROR_MESSAGE
                    	);
            	
    			END IF;
        	END LOOP;
		END IF;
    
    	IF p_STATUS = 0 THEN
        	-- Add TransmissionAllocations
        	FOR v_XML_TransAllocCorrection IN c_XML_TransAllocCorrection LOOP
        		-- INSERT INTO tables
                PUT_TRANSMISSION_ALLOCATION
                	(
                	p_ETAG_ID,  -- IN
                	v_XML_TransAllocCorrection.TransmissionAllocationID,
                	v_XML_TransAllocCorrection.CurrentCorrectionID,
                	v_XML_TransAllocCorrection.ParentSegmentRef,
                	v_XML_TransAllocCorrection.TransProductRef,
                	v_XML_TransAllocCorrection.ContractNumber,
                	v_XML_TransAllocCorrection.TransmissionCustomerCode,
                	NULL,  -- v_XML_TransAllocCorrection.AllocationBaseProfile,  -- missing in Correction
                    0,  -- Delete_Existing
                    p_STATUS,
                	p_ERROR_MESSAGE
                	);
        	END LOOP;
		END IF;
    
        
    	IF p_STATUS = 0 THEN
        	-- Add LossAccountings
        	FOR v_XML_LossAcctingCorrection IN c_XML_LossAcctingCorrection LOOP
        		-- INSERT INTO tables
                PUT_LOSS_METHOD
                	(
                	p_ETAG_ID,  -- IN
                	v_XML_LossAcctingCorrection.PhysicalSegmentRef,
                	v_XML_LossAcctingCorrection.StartDateTime,
                	v_XML_LossAcctingCorrection.StopDateTime,
                	v_XML_LossAcctingCorrection.LossCorrectionID,
                	v_XML_LossAcctingCorrection.RequestRef,
                	v_XML_LossAcctingCorrection.InKindCLOB,
                	v_XML_LossAcctingCorrection.FinancialCLOB,
                	v_XML_LossAcctingCorrection.InternalCLOB,
                	v_XML_LossAcctingCorrection.ExternalCLOB,
                    0,  -- Delete_Existing
                    p_STATUS,
                	p_ERROR_MESSAGE
                	);
        	END LOOP;
		END IF;

    
	END LOOP;
    
    IF p_STATUS = 0 THEN
        COMMIT;
    ELSE
        ROLLBACK;
    END IF;

EXCEPTION
    WHEN OTHERS THEN
		IF p_ERROR_MESSAGE IS NULL THEN
            p_STATUS := SQLCODE;
            p_ERROR_MESSAGE := 'Error in '||g_PACKAGE_NAME||'.'||v_ProcedureName||': ' ||SQLERRM;
        END IF;
        ROLLBACK;
		RETURN;

END PARSE_DISTRIBUTE_CORRECTION;
------------------------------------------------------------------------------
PROCEDURE TEST_DISTRIBUTE_NEW_TAG_XML
	(
	p_ETAG_ID OUT NUMBER,
    p_STATUS OUT NUMBER,
	p_ERROR_MESSAGE OUT VARCHAR2
	) AS

    v_ProcedureName VARCHAR2(29) := 'TEST_DISTRIBUTE_NEW_TAG_XML';
    
    --v_ETAG_ID ETAG.ETAG_ID%TYPE;
    
    v_CLOB CLOB;


BEGIN

	SELECT x.clob_data
    INTO v_CLOB
    FROM  xml_trace x WHERE key1 = 'DistributeNewTag';
    
	PARSE_DISTRIBUTE_NEW_TAG_XML(v_CLOB, p_ETAG_ID, p_STATUS, p_ERROR_MESSAGE);

EXCEPTION
    WHEN OTHERS THEN
		IF p_ERROR_MESSAGE IS NULL THEN
            p_STATUS := SQLCODE;
            p_ERROR_MESSAGE := 'Error in '||g_PACKAGE_NAME||'.'||v_ProcedureName||': ' ||SQLERRM;
        END IF;

END TEST_DISTRIBUTE_NEW_TAG_XML;
------------------------------------------------------------------------------
PROCEDURE READ_XML_FILES
	(
	p_CLOB IN CLOB,
	p_ETAG_ID OUT NUMBER,
    p_STATUS OUT NUMBER,
	p_ERROR_MESSAGE OUT VARCHAR2
	) AS

  v_ProcedureName VARCHAR2(29) := 'READ_XML_FILES';
  v_CLOB CLOB;
  v_ROOT_ELEMENT VARCHAR2(128);
  v_XML_WRAPPED  XMLTYPE;
  v_XML_UNWRAPPED  XMLTYPE;

BEGIN

	p_STATUS := 0;
    p_ERROR_MESSAGE := '';
    
    --parse the .XML file
	IF g_TRACE_ON THEN
		UT.DEBUG_TRACE(v_ProcedureName);
	END IF;
    
    v_XML_WRAPPED := XMLTYPE.CREATEXML(p_CLOB);
    
    MEX_HTTP.STRIP_SOAP_ENVELOPE(v_XML_WRAPPED, v_XML_UNWRAPPED, p_ERROR_MESSAGE);
    
    v_CLOB := v_XML_UNWRAPPED.GetClobVal();

    v_ROOT_ELEMENT := XMLTYPE.CREATEXML(v_CLOB).GetRootElement();
    --Debug format
    --SELECT XMLTYPE.CREATEXML(clob_data).GetRootElement() FROM xml_trace WHERE key1 = 'DistributeNewTag'	
    -- end Debug
    
    CASE v_ROOT_ELEMENT
        WHEN 'DistributeNewTag' THEN
            PARSE_DISTRIBUTE_NEW_TAG_XML(v_CLOB, p_ETAG_ID, p_STATUS, p_ERROR_MESSAGE);
        WHEN 'DistributeProfileChange' THEN
            PARSE_DISTRIBUTE_PROF_CHANGE(v_CLOB, p_ETAG_ID, p_STATUS, p_ERROR_MESSAGE);
        WHEN 'DistributeResolution' THEN
            PARSE_DISTRIBUTE_RESOLUTION(v_CLOB, p_ETAG_ID, p_STATUS, p_ERROR_MESSAGE);
        WHEN 'DistributeStatus' THEN
            PARSE_DISTRIBUTE_STATUS(v_CLOB, p_ETAG_ID, p_STATUS, p_ERROR_MESSAGE);
        WHEN 'DistributeCorrection' THEN
            PARSE_DISTRIBUTE_CORRECTION(v_CLOB, p_ETAG_ID, p_STATUS, p_ERROR_MESSAGE);
        ELSE
            NULL;
    END CASE;

	IF p_ERROR_MESSAGE IS NOT NULL THEN
		RETURN;
	END IF;

  	IF g_TRACE_ON THEN
		UT.DEBUG_TRACE('XML PARSING COMPLETED.');
	END IF;

EXCEPTION
  WHEN OTHERS THEN
    p_ERROR_MESSAGE := 'Error in '||g_PACKAGE_NAME||'.'||v_ProcedureName||': ' || SQLERRM;
  
END READ_XML_FILES;
----------------------------------------------------------------------------------------------------
PROCEDURE TEST_READ_XML_FILES
	(
    p_CLOB_KEY1_NAME IN OUT VARCHAR2,
	p_ETAG_ID OUT NUMBER,
    p_STATUS OUT NUMBER,
	p_ERROR_MESSAGE OUT VARCHAR2
	) AS

    v_ProcedureName VARCHAR2(29) := 'TEST_READ_XML_FILES';
    
    --v_ETAG_ID ETAG.ETAG_ID%TYPE;
    
    v_CLOB CLOB;


BEGIN

	IF p_CLOB_KEY1_NAME IS NULL THEN
        --p_CLOB_KEY1_NAME := 'DistributeNewTagSOAP';
        --p_CLOB_KEY1_NAME := 'DistributeProfileChangeSOAP';
        --p_CLOB_KEY1_NAME := 'DistributeResolution';
        --p_CLOB_KEY1_NAME := 'DistributeStatus';
        p_CLOB_KEY1_NAME := 'DistributeCorrectionSOAP';
    END IF;
    
    SELECT x.clob_data
    INTO v_CLOB
    FROM  xml_trace x WHERE key1 = p_CLOB_KEY1_NAME;
    
		READ_XML_FILES(v_CLOB, p_ETAG_ID, p_STATUS, p_ERROR_MESSAGE);

EXCEPTION
    WHEN OTHERS THEN
		IF p_ERROR_MESSAGE IS NULL THEN
            p_STATUS := SQLCODE;
            p_ERROR_MESSAGE := 'Error in '||g_PACKAGE_NAME||'.'||v_ProcedureName||': ' ||SQLERRM;
        END IF;

END TEST_READ_XML_FILES;
------------------------------------------------------------------------------
PROCEDURE GET_LATEST_ETAG_FILES
	(
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) AS

  v_ProcedureName VARCHAR2(29) := 'GET_LATEST_ETAG_FILES';
    
  v_CREDENTIALS EXTERNAL_CREDENTIAL;
  v_NO_MESSAGES BOOLEAN;
  v_CLOB CLOB;
  v_ETAG_ID  ETAG.ETAG_ID%TYPE;

BEGIN

	GET_CREDENTIALS(v_CREDENTIALS, p_MESSAGE);
	IF NOT p_MESSAGE IS NULL THEN
		p_STATUS := -1;
		RETURN;
	END IF;

	MEX_HTTP.MESSAGE_QUEUE_START(v_CREDENTIALS, 'etag', p_MESSAGE);
	IF p_MESSAGE IS NOT NULL THEN
		p_STATUS := 2;
		RETURN;
	END IF;
	LOOP
		MEX_HTTP.MESSAGE_QUEUE_NEXT_CLOB(v_NO_MESSAGES, v_CLOB, p_MESSAGE);
		IF p_MESSAGE IS NOT NULL THEN
			p_STATUS := 2;
			RETURN;
		END IF;
	
		EXIT WHEN v_NO_MESSAGES;
		
		READ_XML_FILES(v_CLOB, v_ETAG_ID, p_STATUS, p_MESSAGE);
		COMMIT;
		IF p_MESSAGE IS NOT NULL THEN
			p_STATUS := 2;
			RETURN;
		END IF;
	END LOOP;

EXCEPTION
  WHEN OTHERS THEN
    p_STATUS := SQLCODE;
    p_MESSAGE := 'Error in '||g_PACKAGE_NAME||'.'||v_ProcedureName||': ' || SQLERRM;
  
END GET_LATEST_ETAG_FILES;
-------------------------------------------------------------------------------------
end ET;
/
