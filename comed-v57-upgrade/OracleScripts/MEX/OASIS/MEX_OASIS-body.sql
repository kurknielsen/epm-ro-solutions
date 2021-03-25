CREATE OR REPLACE PACKAGE BODY MEX_OASIS IS

	-- Private type declarations
	--type <TypeName> is <Datatype>;

	g_VERSION       CONSTANT NUMBER(5, 1) := 1.4;
	g_OUTPUT_FORMAT CONSTANT VARCHAR2(4) := 'DATA';
	g_HEADER_ROWS   CONSTANT NUMBER(2) := 11;
	g_EXCHANGE_TZ	VARCHAR2(3) := 'CD';
	g_CUT_EXCHANGE_TZ	VARCHAR2(3) := 'CS';

	g_LIST_TEMPLATE VARCHAR2(4) := 'LIST';
	g_TRANSSTATUS_TEMPLATE VARCHAR2(11) := 'TRANSSTATUS';
	g_TRANSREQUEST_TEMPLATE VARCHAR2(16) := 'TRANSREQUEST';
	g_TRANSCUST_TEMPLATE VARCHAR2(16) := 'TRANSCUST';
	g_TRANSSELL_TEMPLATE VARCHAR2(16) := 'TRANSSELL';
	g_TRANSASSIGN_TEMPLATE VARCHAR2(16) := 'TRANSASIGN';
	g_TRANSPOST_TEMPLATE VARCHAR2(16) := 'TRANSPOST';
	g_TRANSUPDATE_TEMPLATE VARCHAR2(16) := 'TRANSUPDATE';
	g_DATA_FORMAT VARCHAR2(4) := 'DATA';
	--g_SUBMIT_FORMAT VARCHAR2(16) := 'OASISDATA';

	-- field types will use these formats:
	g_NUMBER_12_FORMAT CONSTANT VARCHAR2(20) := 'FM999999999999'; -- default
	g_NUMBER_9_FORMAT  CONSTANT VARCHAR2(20) := 'FM000000000'; -- DUNS
	g_FLOAT_5_1_FORMAT CONSTANT VARCHAR2(20) := 'FM9999.9';
	g_FLOAT_9_4_FORMAT CONSTANT VARCHAR2(20) := 'FM99999.9999';
	g_DATE_FORMAT_TZ   CONSTANT VARCHAR2(20) := 'YYYYMMDDHH24MISSTZD';
	g_DATE_FORMAT      CONSTANT VARCHAR2(20) := 'YYYYMMDDHH24MISS';

	g_CRLF             CONSTANT VARCHAR2(2) := CHR(13) || CHR(10);
	g_REQUEST_SUCCESS  CONSTANT NUMBER(3) := 200;
	--g_NOTFOUND         CONSTANT NUMBER(1)    := 0;
	g_REQUEST_CONTENT_TYPE CONSTANT  VARCHAR2(16) := 'text/x-oasis-csv';

	TYPE ELEMENT_NAMES_T IS TABLE OF VARCHAR2(30);

	INPUT_HDR_ELEMENTS ELEMENT_NAMES_T := ELEMENT_NAMES_T('VERSION',
														  'TEMPLATE',
														  'OUTPUT_FORMAT',
														  'PRIMARY_PROVIDER_CODE',
														  'PRIMARY_PROVIDER_DUNS',
														  'RETURN_TZ',
														  'DATA_ROWS',
														  'COLUMN_HEADERS');

	RESPONSE_HDR_ELEMENTS ELEMENT_NAMES_T := ELEMENT_NAMES_T('REQUEST_STATUS',
															 'ERROR_MESSAGE',
															 'TIME_STAMP',
															 'VERSION',
															 'TEMPLATE',
															 'OUTPUT_FORMAT',
															 'PRIMARY_PROVIDER_CODE',
															 'PRIMARY_PROVIDER_DUNS',
															 'RETURN_TZ',
															 'DATA_ROWS',
															 'COLUMN_HEADERS');

	TRANSOFFER_QUERY_ELEMENTS ELEMENT_NAMES_T := ELEMENT_NAMES_T('PATH_NAME',
																 'SELLER_CODE',
																 'SELLER_DUNS',
																 'POINT_OF_RECEIPT',
																 'POINT_OF_DELIVERY',
																 'SERVICE_INCREMENT',
																 'TS_CLASS',
																 'TS_TYPE',
																 'TS_PERIOD',
																 'TS_WINDOW',
																 'TS_SUBCLASS',
																 'START_TIME',
																 'STOP_TIME',
																 'POSTING_REF',
																 'TIME_OF_LAST_UPDATE');

	/*TRANSOFFER_RESPONSE_ELEMENTS ELEMENT_NAMES_T := ELEMENT_NAMES_T(
    'TIME_OF_LAST_UPDATE',
    'SELLER_CODE',
    'SELLER_DUNS',
    'PATH_NAME',
    'POINT_OF_RECEIPT',
    'POINT_OF_DELIVERY',
    'INTERFACE_TYPE',
    'OFFER_START_TIME',
    'OFFER_STOP_TIME',
    'START_TIME',
    'STOP_TIME',
    'CAPACITY',
    'SERVICE_INCREMENT',
    'TS_CLASS',
    'TS_TYPE',
    'TS_PERIOD',
    'TS_WINDOW',
    'TS_SUBCLASS',
    'ANC_SVC_REQ',
    'SALE_REF',
    'POSTING_REF',
    'CEILING_PRICE',
    'OFFER_PRICE',
    'PRICE_UNITS',
    'SERVCE_DESCRIPTION',
    'NERC_CURTAILMENT_PRIORITY',
    'OTHER_CURTAILMENT_PRIORITY',
    'SELLER_NAME',
    'SELLER_PHONE',
    'SELLER_FAX',
    'SELLER_EMAIL',
    'SELLER_COMMENTS');*/

	TRANSREQUEST_INPUT_ELEMENTS ELEMENT_NAMES_T := ELEMENT_NAMES_T('CONTINUATION_FLAG',
																   'SELLER_CODE',
																   'SELLER_DUNS',
																   'PATH_NAME',
																   'POINT_OF_RECEIPT',
																   'POINT_OF_DELIVERY',
																   'SOURCE',
																   'SINK',
																   'CAPACITY_REQUESTED',
																   'SERVICE_INCREMENT',
																   'TS_CLASS',
																   'TS_TYPE',
																   'TS_PERIOD',
																   'TS_WINDOW',
																   'TS_SUBCLASS',
																   'STATUS_NOTIFICATION',
																   'START_TIME',
																   'STOP_TIME',
																   'BID_PRICE',
																   'PRECONFIRMED',
																   'ANC_SVC_LINK',
																   'POSTING_REF',
																   'SALE_REF',
																   'REQUEST_REF',
																   'DEAL_REF',
																   'CUSTOMER_COMMENTS',
																   'REQUEST_TYPE',
																   'RELATED_REF');

	/*TRANSREQUEST_RESPONSE_ELEMENTS ELEMENT_NAMES_T := ELEMENT_NAMES_T(
    'RECORD_STATUS',
      'CONTINUATION_FLAG',
      'ASSIGNMENT_REF',
      'SELLER_CODE',
      'SELLER_DUNS',
      'PATH_NAME',
      'POINT_OF_RECEIPT',
      'POINT_OF_DELIVERY',
      'SOURCE',
      'SINK',
      'CAPACITY_REQUESTED',
      'SERVICE_INCREMENT',
      'TS_CLASS',
      'TS_TYPE',
      'TS_PERIOD',
      'TS_WINDOW',
      'TS_SUBCLASS',
      'STATUS_NOTIFICATION',
      'START_TIME',
      'STOP_TIME',
      'BID_PRICE',
      'PRECONFIRMED',
      'ANC_SVC_LINK',
      'POSTING_REF',
      'SALE_REF',
      'REQUEST_REF',
      'DEAL_REF',
      'CUSTOMER_COMMENTS',
      'REQUEST_TYPE',
      'RELATED_REF',
      'ERROR_MESSAGE');*/

	TRANSSTATUS_QUERY_ELEMENTS ELEMENT_NAMES_T := ELEMENT_NAMES_T('SELLER_CODE',
																  'SELLER_DUNS',
																  'CUSTOMER_CODE',
																  'CUSTOMER_DUNS',
																  'PATH_NAME',
																  'POINT_OF_RECEIPT',
																  'POINT_OF_DELIVERY',
																  'SERVICE_INCREMENT',
																  'TS_CLASS',
																  'TS_TYPE',
																  'TS_PERIOD',
																  'TS_WINDOW',
																  'TS_SUBCLASS',
																  'STATUS',
																  'START_TIME',
																  'STOP_TIME',
																  'START_TIME_QUEUED',
																  'STOP_TIME_QUEUED',
																  'NEGOTIATED_PRICE_FLAG',
																  'ASSIGNMENT_REF',
																  'REASSIGNED_REF',
																  'RELATED_REF',
																  'SALE_REF',
																  'REQUEST_REF',
																  'DEAL_REF',
																  'COMPETING_REQUEST_FLAG',
																  'TIME_OF_LAST_UPDATE');

	/*TRANSSTATUS_RESPONSE_ELEMENTS ELEMENT_NAMES_T := ELEMENT_NAMES_T(
    'CONTINUATION_FLAG',
    'ASSIGNMENT_REF',
    'SELLER_CODE',
    'SELLER_DUNS',
    'CUSTOMER_CODE',
    'CUSTOMER_DUNS',
    'AFFILIATE_FLAG',
    'PATH_NAME',
    'POINT_OF_RECEIPT',
    'POINT_OF_DELIVERY',
    'SOURCE',
    'SINK',
    'CAPACITY_REQUESTED',
    'CAPACITY_GRANTED',
    'SERVICE_INCREMENT',
    'TS_CLASS',
    'TS_TYPE',
    'TS_PERIOD',
    'TS_WINDOW',
    'TS_SUBCLASS',
    'NERC_CURTAILEMENT_PRIORITY',
    'OTHER_CURTAILEMENT_PRIORITY',
    'START_TIME',
    'STOP_TIME',
    'CEILING_PRICE',
    'OFFER_PRICE',
    'BID_PRICE',
    'PRICE_UNITS',
    'PRECONFIRMED',
    'ANC_SVC_LINK',
    'ANC_SVC_REQ',
    'POSTING_REF',
    'SALE_REF',
    'REQUEST_REF',
    'DEAL_REF',
    'IMPACTED',
    'COMPETING_REQUEST_FLAG',
    'REQUEST_TYPE',
    'RELATED_REF',
    'NEGOTIATED_PRICE_FLAG',
    'STATUS',
    'STATUS_NOTIFICATION',
    'STATUS_COMMENTS',
    'TIME_QUEUED',
    'RESPONSE_TIME_LIMIT',
    'TIME_OF_LAST_UPDATE',
    'PRIMARY_PROVIDER_COMMENTS',
    'SELLER_REF',
    'SELLER_COMMENTS',
    'CUSTOMER_COMMENTS',
    'SELLER_NAME',
    'SELLER_PHONE',
    'SELLER_FAX',
    'SELLER_EMAIL',
    'CUSTOMER_NAME',
    'CUSTOMER_PHONE',
    'CUSTOMER_FAX',
    'CUSTOMER_EMAIL',
    'REASSIGNED_REF',
    'REASSIGNED_CAPACITY',
    'REASSIGNED_START_TIME',
    'REASSIGNED_STOP_TIME');*/

	TRANSSELL_INPUT_ELEMENTS ELEMENT_NAMES_T := ELEMENT_NAMES_T('CONTINUATION_FLAG',
																'START_TIME',
																'STOP_TIME',
																'OFFER_PRICE',
																'CAPACITY_GRANTED',
																'STATUS',
																'STATUS_COMMENTS',
																'ANC_SVC_LINK',
																'ANC_SVC_REQ',
																'COMPETING_REQUEST_FLAG',
																'NEGOCIATED_PRICE_FLAG',
																'SELLER_REF',
																'SELLER_COMMENTS',
																'RESPONSE_TIME_LIMIT',
																'REASSIGNED_REF',
																'REASSIGNED_CAPACITY',
																'REASSIGNED_START_TIME',
																'REASSIGNED_STOP_TIME');

	/*TRANSSELL_RESPONSE_ELEMENTS ELEMENT_NAMES_T := ELEMENT_NAMES_T(
    'RECORD_STATUS',
    'CONTINUATION_FLAG',
    'START_TIME',
    'STOP_TIME',
    'OFFER_PRICE',
    'CAPACITY_GRANTED',
    'STATUS',
    'STATUS_COMMENTS',
    'ANC_SVC_LINK',
    'ANC_SVC_REQ',
    'COMPETING_REQUEST_FLAG',
    'NEGOCIATED_PRICE_FLAG',
    'SELLER_REF',
    'SELLER_COMMENTS',
    'RESPONSE_TIME_LIMIT',
    'REASSIGNED_REF',
    'REASSIGNED_CAPACITY',
    'REASSIGNED_START_TIME',
    'REASSIGNED_STOP_TIME',
    'ERROR_MESSAGE');*/

	TRANSCUST_INPUT_ELEMENTS ELEMENT_NAMES_T := ELEMENT_NAMES_T('CONTINUATION_FLAG',
																'ASSIGNMENT_REF',
																'START_TIME',
																'STOP_TIME',
																'REQUEST_REF',
																'DEAL_REF',
																'BID_PRICE',
																'PRECONFIRMED',
																'STATUS',
																'STATUS_COMMENTS',
																'ANC_SVC_LINK',
																'STATUS_NOTIFICATION',
																'CUSTOMER_COMMENTS');

	/*TRANSCUST_RESPONSE_ELEMENTS ELEMENT_NAMES_T := ELEMENT_NAMES_T(
        'RECORD_STATUS',
    'CONTINUATION_FLAG',
    'ASSIGNMENT_REF',
    'START_TIME',
    'STOP_TIME',
    'REQUEST_REF',
    'DEAL_REF',
    'BID_PRICE',
    'PRECONFIRMED',
    'STATUS',
    'STATUS_COMMENTS',
    'ANC_SVC_LINK',
    'STATUS_NOTIFICATION',
    'CUSTOMER_COMMENTS',
    'ERROR_MESSAGE');*/

	TRANSASSIGN_INPUT_ELEMENTS ELEMENT_NAMES_T := ELEMENT_NAMES_T('CONTINUATION_FLAG',
																  'CUSTOMER_CODE',
																  'CUSTOMER_DUNS',
																  'PATH_NAME',
																  'POINT_OF_RECEIPT',
																  'POINT_OF_DELIVERY',
																  'SOURCE',
																  'SINK',
																  'CAPACITY_REQUESTED',
																  'CAPACITY_GRANTED',
																  'SERVICE_INCREMENT',
																  'TS_CLASS',
																  'TS_TYPE',
																  'TS_PERIOD',
																  'TS_WINDOW',
																  'TS_SUBCLASS',
																  'START_TIME',
																  'STOP_TIME',
																  'OFFER_PRICE',
																  'ANC_SVC_LINK',
																  'POSTING_NAME',
																  'REASSIGNED_REF',
																  'REASSIGNED_CAPACITY',
																  'REASSIGNED_START_TIME',
																  'REASSIGNED_STOP_TIME',
																  'SELLER_COMMENTS',
																  'SELLER_REF');

	/*TRANSASSIGN_RESPONSE_ELEMENTS ELEMENT_NAMES_T := ELEMENT_NAMES_T(
    'RECORD_STATUS',
    'CONTINUATION_FLAG',
    'CUSTOMER_CODE',
    'CUSTOMER_DUNS',
    'PATH_NAME',
    'POINT_OF_RECEIPT',
    'POINT_OF_DELIVERY',
    'SOURCE',
    'SINK',
    'CAPACITY_REQUESTED',
    'CAPACITY_GRANTED',
    'SERVICE_INCREMENT',
    'TS_CLASS',
    'TS_TYPE',
    'TS_PERIOD',
    'TS_WINDOW',
    'TS_SUBCLASS',
    'START_TIME',
    'STOP_TIME',
    'OFFER_PRICE',
    'ANC_SVC_LINK',
    'POSTING_NAME',
    'REASSIGNED_REF',
    'REASSIGNED_CAPACITY',
    'REASSIGNED_START_TIME',
    'REASSIGNED_STOP_TIME',
    'SELLER_COMMENTS',
    'SELLER_REF',
    'ERROR_MESSAGE');*/

	TRANSPOST_INPUT_ELEMENTS ELEMENT_NAMES_T := ELEMENT_NAMES_T('PATH_NAME',
																'POINT_OF_RECEIPT',
																'POINT_OF_DELIVERY',
																'INTERFACE_TYPE',
																'CAPACITY',
																'SERVICE_INCREMENT',
																'TS_CLASS',
																'TS_TYPE',
																'TS_PERIOD',
																'TS_WINDOW',
																'TS_SUBCLASS',
																'ANC_SVC_REQ',
																'START_TIME',
																'STOP_TIME',
																'OFFER_START_TIME',
																'OFFER_STOP_TIME',
																'SALE_REF',
																'OFFER_PRICE',
																'SERVICE_DESCRIPTION',
																'SELLER_COMMENTS');

	TRANSUPDATE_INPUT_ELEMENTS ELEMENT_NAMES_T := ELEMENT_NAMES_T('POSTING_REF',
																  'CAPACITY',
																  'START_TIME',
																  'STOP_TIME',
																  'OFFER_STAET_TIME',
																  'OFFER_STOP_TIME',
																  'ANC_SVC_REQ',
																  'SALE_REF',
																  'OFFER_PRICE',
																  'SERVICE_DESCRIPTION',
																  'SELLER_COMMENTS');

	ANCOFFER_QUERY_ELEMENTS ELEMENT_NAMES_T := ELEMENT_NAMES_T('SELLER_CODE',
															   'SELLER_DUNS',
															   'CONTROL_AREA',
															   'SERVICE_INCREMENT',
															   'AS_TYPE',
															   'START_TIME',
															   'STOP_TIME',
															   'POSTING_REF',
															   'TIME_OF_LAST_UPDATE');

	ANCREQUEST_INPUT_ELEMENTS ELEMENT_NAMES_T := ELEMENT_NAMES_T('CONTINUATION_FLAG',
																 'SELLER_CODE',
																 'SELLER_DUNS',
																 'CONTROL_AREA',
																 'ANC_SERVICE_POINT',
																 'CAPACITY',
																 'SERVICE_INCREMENT',
																 'AS_TYPE',
																 'STATUS_NOTIFICATION',
																 'START_TIME',
																 'STOP_TIME',
																 'BID_PRICE',
																 'PRECONFIRMED',
																 'POSTING_REF',
																 'SALE_REF',
																 'REQUEST_REF',
																 'DEAL_REF',
																 'CUSTOMER_COMMENTS');

	ANCSTATUS_QUERY_ELEMENTS ELEMENT_NAMES_T := ELEMENT_NAMES_T('SELLER_CODE',
																'SELLER_DUNS',
																'CUSTOMER_CODE',
																'CUSTOMER_DUNS',
																'CONTROL_AREA',
																'ANC_SERVICE_POINT',
																'SERVICE_INCREMENT',
																'AS_TYPE',
																'STATUS',
																'START_TIME',
																'STOP_TIME',
																'START_TIME_QUEUED',
																'STOP_TIME_QUEUED',
																'NEGOTIATED_PRICE_FLAG',
																'ASSIGNMENT_REF',
																'REASSIGNED_REF',
																'SALE_REF',
																'REQUEST_REF',
																'DEAL_REF',
																'TIME_OF_LAST_UPDATE');

	ANCSELL_INPUT_ELEMENTS ELEMENT_NAMES_T := ELEMENT_NAMES_T('CONTINUATION_FLAG',
															  'ASSIGNMENT_REF',
															  'START_TIME',
															  'STOP_TIME',
															  'OFFER_PRICE',
															  'STATUS',
															  'STATUS_COMMENTS',
															  'NEGOTIATED_PRICE_FLAG',
															  'RESPONSE_TIME_LIMIT',
															  'SELLER_COMMENTS',
															  'REASSIGNED_REF',
															  'REASSIGNED_CAPACITY',
															  'REASSIGNED_START_TIME',
															  'REASSIGNED_STOP_TIME');

	ANCCUST_INPUT_ELEMENTS ELEMENT_NAMES_T := ELEMENT_NAMES_T('CONTINUATION_FLAG',
															  'ASSIGNMENT_REF',
															  'START_TIME',
															  'STOP_TIME',
															  'REQUEST_REF',
															  'DEAL_REF',
															  'BID_PRICE',
															  'PRECONFIRMED',
															  'STATUS',
															  'STATUS_COMMENTS',
															  'STATUS_NOTIFICATION',
															  'CUSTOMER_COMMENTS');

	ANCASSIGN_INPUT_ELEMENTS ELEMENT_NAMES_T := ELEMENT_NAMES_T('CONTINUATION_FLAG',
																'CUSTOMER_CODE',
																'CUSTOMER_DUNS',
																'CONTROL_AREA',
																'ANC_SERVICE_POINT',
																'CAPACITY',
																'SERVICE_INCREMENT',
																'AS_TYPE',
																'START_TIME',
																'STOP_TIME',
																'OFFER_PRICE',
																'POSTING_NAME',
																'REASSIGNED_REF',
																'REASSIGNED_CAPACITY',
																'REASSIGNED_START_TIME',
																'REASSIGNED_STOP_TIME',
																'SELLER_COMMENTS');

	ANCPOST_INPUT_ELEMENTS ELEMENT_NAMES_T := ELEMENT_NAMES_T('CONTROL_AREA',
															  'SERVICE_DESCRIPTION',
															  'CAPACITY',
															  'SERVICE_INCREMENT',
															  'AS_TYPE',
															  'START_TIME',
															  'STOP_TIME',
															  'OFFER_START_TIME',
															  'OFFER_STOP_TIME',
															  'SALE_REF',
															  'OFFER_PRICE',
															  'SELLER_COMMENTS');

	ANCUPDATE_INPUT_ELEMENTS ELEMENT_NAMES_T := ELEMENT_NAMES_T('POSTING_REF',
																'CAPACITY',
																'SERVICE_DESCRIPTION',
																'START_TIME',
																'STOP_TIME',
																'OFFER_START_TIME',
																'OFFER_STOP_TIME',
																'SALE_REF',
																'OFFER_PRICE',
																'SELLER_COMMENTS');

	-- Private constant declarations
	--<ConstantName> constant <Datatype> := <Value>;

	-- Private variable declarations
	--<VariableName> <Datatype>;

	-- Function and procedure implementations
	--function <FunctionName>(<Parameter> <Datatype>) return <Datatype> is
	--  <LocalVariable> <Datatype>;
	--begin
	--  <Statement>;
	--  return(<Result>);
	--end;
	--------------------------------------------------------------------------------------------------------------
FUNCTION WHAT_VERSION RETURN VARCHAR2 IS
BEGIN
    RETURN '$Revision: 1.1 $';
END WHAT_VERSION;
---------------------------------------------------------------------------------------------------
	/*FUNCTION FIND_RESPONSE_HDR_KEY(p_name IN VARCHAR) RETURN INTEGER IS
        v_key varchar2(30) := upper(p_name);
      BEGIN
        FOR idx IN response_hdr_elements.FIRST .. response_hdr_elements.LAST LOOP
          IF response_hdr_elements(idx) = v_key THEN
            RETURN idx;
          END IF;
        END LOOP;
        RETURN g_NOTFOUND;
      END;
    --------------------------------------------------------------------------------------------------------------
      FUNCTION FIND_TRANSOFFER_RESPONSE_KEY(p_name IN VARCHAR) RETURN INTEGER IS
        v_key varchar2(30) := upper(p_name);
      BEGIN
        FOR idx IN transoffer_response_elements.FIRST .. transoffer_response_elements.LAST LOOP
          IF transoffer_response_elements(idx) = v_key THEN
            RETURN idx;
          END IF;
        END LOOP;
        RETURN g_NOTFOUND;
      END;
    --------------------------------------------------------------------------------------------------------------
      FUNCTION FIND_TRANSREQUEST_RESPONSE_KEY(p_name IN VARCHAR) RETURN INTEGER IS
        v_key varchar2(30) := upper(p_name);
      BEGIN
        FOR idx IN transrequest_response_elements.FIRST .. transrequest_response_elements.LAST LOOP
          IF transrequest_response_elements(idx) = v_key THEN
            RETURN idx;
          END IF;
        END LOOP;
        RETURN g_NOTFOUND;
      END;
    --------------------------------------------------------------------------------------------------------------
      FUNCTION FIND_TRANSSTATUS_RESPONSE_KEY(p_name IN VARCHAR) RETURN INTEGER IS
        v_key varchar2(30) := upper(p_name);
      BEGIN
        FOR idx IN transstatus_response_elements.FIRST .. transrequest_response_elements.LAST LOOP
          IF transstatus_response_elements(idx) = v_key THEN
            RETURN idx;
          END IF;
        END LOOP;
        RETURN g_NOTFOUND;
      END;
    --------------------------------------------------------------------------------------------------------------
      FUNCTION FIND_TRANSSELL_RESPONSE_KEY(p_name IN VARCHAR) RETURN INTEGER IS
        v_key varchar2(30) := upper(p_name);
      BEGIN
        FOR idx IN transsell_response_elements.FIRST .. transrequest_response_elements.LAST LOOP
          IF transsell_response_elements(idx) = v_key THEN
            RETURN idx;
          END IF;
        END LOOP;
        RETURN g_NOTFOUND;
      END;
    --------------------------------------------------------------------------------------------------------------
      FUNCTION FIND_TRANSCUST_RESPONSE_KEY(p_name IN VARCHAR) RETURN INTEGER IS
        v_key varchar2(30) := upper(p_name);
      BEGIN
        FOR idx IN transcust_response_elements.FIRST .. transrequest_response_elements.LAST LOOP
          IF transcust_response_elements(idx) = v_key THEN
            RETURN idx;
          END IF;
        END LOOP;
        RETURN g_NOTFOUND;
      END;
    --------------------------------------------------------------------------------------------------------------
      FUNCTION FIND_TRANSASSIGN_RESPONSE_KEY(p_name IN VARCHAR) RETURN INTEGER IS
        v_key varchar2(30) := upper(p_name);
      BEGIN
        FOR idx IN transassign_response_elements.FIRST .. transrequest_response_elements.LAST LOOP
          IF transassign_response_elements(idx) = v_key THEN
            RETURN idx;
          END IF;
        END LOOP;
        RETURN g_NOTFOUND;
      END;
    */
	-------------------------------------------------------------------------------------------------------------
	--this is a special parse_clob_into_lines that handles the carriage returns
	--that might occur in custommer or seller comments
	PROCEDURE PARSE_CLOB_INTO_LINES	(p_CLOB IN CLOB,p_LINES OUT PARSE_UTIL.BIG_STRING_TABLE_MP) AS
    v_COUNT BINARY_INTEGER := 0;
    v_BEGIN_POS NUMBER := 1;
    v_END_POS NUMBER := 1;
    v_LENGTH NUMBER;
    v_TOKEN VARCHAR(4000);
    v_LOOP_COUNTER NUMBER;

    BEGIN
    -- If the argument string is empty then exit the procedure
    	v_LENGTH := DBMS_LOB.GETLENGTH(p_CLOB);
    	IF v_LENGTH = 0 THEN
    		RETURN;
    	END IF;

    	v_LOOP_COUNTER := 0;
    	LOOP
    		v_END_POS := DBMS_LOB.INSTR(p_CLOB, CHR(10), v_BEGIN_POS);
    		IF v_END_POS = 0 THEN
    			v_TOKEN := LTRIM(RTRIM(DBMS_LOB.SUBSTR(p_CLOB, 4000, v_BEGIN_POS)));
    			v_END_POS := v_LENGTH;
    		ELSE
            	IF DBMS_LOB.SUBSTR(p_CLOB, 1, v_END_POS-1) = CHR(13) THEN
    				v_TOKEN := LTRIM(RTRIM(DBMS_LOB.SUBSTR(p_CLOB, v_END_POS - v_BEGIN_POS - 1, v_BEGIN_POS)));
                ELSE
    				v_TOKEN := LTRIM(RTRIM(DBMS_LOB.SUBSTR(p_CLOB, v_END_POS - v_BEGIN_POS, v_BEGIN_POS)));
                    IF DBMS_LOB.SUBSTR(p_CLOB, 1, v_END_POS+1) = CHR(13) THEN
                    	v_END_POS := v_END_POS+1;
                    END IF;
                END IF;
    		END IF;

			IF v_TOKEN IS NOT NULL THEN
    			IF (v_LOOP_COUNTER<11) OR (SUBSTR(v_TOKEN,1,1) IN ('Y','N') AND SUBSTR(v_TOKEN,2,1)=',') THEN
    				v_COUNT := v_COUNT + 1;
    				p_LINES(v_COUNT) := v_TOKEN;
    				--DBMS_OUTPUT.put_line ('p_LINES(' || v_COUNT ||')= ' || p_LINES(v_COUNT));
    			ELSE
					--If the line number > 11, and it does not start with Y, or N,
					--then append it to the previous line.
    				p_LINES(v_COUNT) := p_LINES(v_COUNT) || v_TOKEN;
    				--DBMS_OUTPUT.put_line ('p_LINES(' || v_COUNT ||')= ' || p_LINES(v_COUNT));
    			END IF;

    			v_LOOP_COUNTER := v_LOOP_COUNTER + 1;

    			IF v_LOOP_COUNTER > 100000 THEN
    				RAISE_APPLICATION_ERROR(-20901,'RUNAWAY LOOP IN PARSE_UTIL.PARSE_CLOB_INTO_LINES');
    			END IF;
			END IF;
			v_BEGIN_POS := v_END_POS + 1;
    		EXIT WHEN v_BEGIN_POS > v_LENGTH;
    	END LOOP;

    EXCEPTION
        WHEN VALUE_ERROR THEN
    		RAISE_APPLICATION_ERROR(-20901,'VALUE_ERROR: LOOP_COUNTER=' || v_LOOP_COUNTER
    		|| ',TOKEN=' || v_TOKEN
    		|| ',BEGIN_POS=' || TO_CHAR(v_BEGIN_POS)
    		|| ',END_POS=' || TO_CHAR(v_END_POS)
    		|| ',LENGTH=' || TO_CHAR(v_LENGTH));
    	WHEN OTHERS THEN
    		RAISE;
    END PARSE_CLOB_INTO_LINES;
	-------------------------------------------------------------------------------------------------------------
FUNCTION GET_INPUT_LIST
	(
	p_LIST_NAME IN VARCHAR2,
	p_LIST IN VARCHAR2
	) RETURN VARCHAR2 IS
	v_LIST GA.STRING_TABLE;
	v_RTN VARCHAR2(2000);
	i BINARY_INTEGER;
BEGIN

-- SAMPLE: IF MULTIPLE ITEMS IN LIST
--	'&CUSTOMER1=MWE&CUSTOMER2=KCPS&CUSTOMER3=KCPL&CUSTOMER4=KEPC&CUSTOMER5=KMEA&CUSTOMER6=OPPD&CUSTOMER7=OPPM&CUSTOMER8=SECI&CUSTOMER9=SEPC&CUSTOMER10=SPS&CUSTOMER11=SPSM&CUSTOMER12=TNSK&CUSTOMER13=WR&CUSTOMER14=WRGS&CUSTOMER15=MPS&CUSTOMER16=UCU'
-- IF SINGLE ITEM IN LIST:
--  '&CUSTOMER=' || p_CUSTOMER_CODE
	IF p_LIST IS NULL OR p_LIST = '?' THEN
		v_RTN := '&' || p_LIST_NAME || '=';
	ELSE
		UT.TOKENS_FROM_STRING(p_LIST, ',', v_LIST);
		IF v_LIST.FIRST = v_LIST.LAST THEN
			v_RTN := '&' || p_LIST_NAME || '=' || p_LIST;
		ELSE
			FOR i IN v_LIST.FIRST .. v_LIST.LAST LOOP
				v_RTN := v_RTN || '&' || p_LIST_NAME || TO_CHAR(i) || '=' || v_LIST(i);
			END LOOP;
		END IF;
	END IF;

	RETURN v_RTN;

END GET_INPUT_LIST;
	-- return the equivalent Oracle TZ_NAME for the OASIS time zone designator
	-------------------------------------------------------------------------------------------------------------
	FUNCTION GET_TZ_NAME(p_data IN VARCHAR2) RETURN VARCHAR2 IS

		-- OASIS uses 11 values for time zone which are:
		-- UT, AD, AS, ED, ES, CD, CS, MD, MS, PD, PS

		v_data VARCHAR2(3);

	BEGIN

		IF p_data = 'UT' THEN
			v_data := 'GMT';
		ELSE
			v_data := p_data || 'T';
		END IF;

		RETURN v_data;

	EXCEPTION
		WHEN OTHERS THEN
			RETURN NULL;
	END GET_TZ_NAME;
	-------------------------------------------------------------------------------------------------------------
	-- convert_date uses timezone at end of string and returns a cut date
	FUNCTION CONVERT_DATE(p_DATA IN VARCHAR2, p_SERVICE_INCREMENT IN VARCHAR2 := NULL) RETURN DATE IS

		v_TIME_ZONE VARCHAR2(16);
		v_LOCAL_DATE DATE;
		v_CUT_DATE DATE;
	BEGIN

		IF p_DATA IS NULL THEN
			RETURN NULL;
		END IF;

		IF p_SERVICE_INCREMENT IS NULL OR UPPER(p_SERVICE_INCREMENT) = 'HOURLY' THEN
			v_TIME_ZONE := GET_TZ_NAME(SUBSTR(p_DATA, LENGTH(p_DATA) - 1, 2));
			v_LOCAL_DATE := TO_DATE(SUBSTR(p_DATA, 1, LENGTH(p_DATA) - 2), g_DATE_FORMAT);
			v_CUT_DATE := To_Cut(v_LOCAL_DATE, v_TIME_ZONE);
		ELSE
			v_CUT_DATE := TRUNC(TO_DATE(SUBSTR(p_DATA, 1, LENGTH(p_DATA) - 2), g_DATE_FORMAT));
		END IF;

		RETURN v_CUT_DATE;

	END CONVERT_DATE;
	--------------------------------------------------------------------------------------------------------------
	-- convert_number handles nulls
	FUNCTION CONVERT_NUMBER(p_data IN VARCHAR2) RETURN NUMBER IS

	BEGIN

		IF p_data IS NULL THEN
			RETURN NULL;
		END IF;

		RETURN TO_NUMBER(p_data);

	EXCEPTION
		WHEN OTHERS THEN
			RETURN NULL;
	END CONVERT_NUMBER;
	--------------------------------------------------------------------------------------------------------------
	-- convert to CSV for NULL, NUMBER, DATE, and VARCHAR2
	-- return null for null, number for numbers, and
	-- quoted strings with doubled quotes if they contain quotes
	--------------------------------------------------------------------------------------------------------------
	-- convert cut date to string
	FUNCTION TO_CSV(p_DATA IN DATE) RETURN VARCHAR2 IS
		v_DATE DATE;
		v_IS_DST BOOLEAN;
	BEGIN

		IF p_DATA IS NULL THEN
			RETURN NULL;
		END IF;

		--If it is a second past the day, then it is a daily date.  Just trunc it.
		IF TO_CHAR(p_DATA, 'SS') = '01' AND TO_CHAR(p_DATA, 'HH24') = '00' THEN
			v_DATE := TRUNC(p_DATA);
		--Otherwise, change from CUT to the correct time zone.
		ELSE
			v_DATE := From_Cut(p_DATA, GET_TZ_NAME(g_EXCHANGE_TZ));
		END IF;

		v_IS_DST := Is_In_Dst_Time_Period(v_DATE);

		IF v_IS_DST THEN
			RETURN TO_CHAR(v_DATE, g_DATE_FORMAT) || g_EXCHANGE_TZ;
		ELSE
			RETURN TO_CHAR(v_DATE, g_DATE_FORMAT) || g_CUT_EXCHANGE_TZ;
		END IF;

	END TO_CSV;
	--------------------------------------------------------------------------------------------------------------
	FUNCTION TO_CSV(p_data   IN NUMBER,
					p_format IN VARCHAR2 := g_NUMBER_12_FORMAT) RETURN VARCHAR2 IS

		v_result VARCHAR2(20);
	BEGIN

		IF p_data IS NULL THEN
			RETURN NULL;
		END IF;

		v_result := TO_CHAR(p_data, p_format);
		RETURN v_result;

	END TO_CSV;
	--------------------------------------------------------------------------------------------------------------
	FUNCTION TO_CSV(p_data IN VARCHAR2) RETURN VARCHAR2 IS
		v_result VARCHAR2(2000);
	BEGIN

		IF p_data IS NULL THEN
			RETURN NULL;
		END IF;

		v_result := p_data;
		IF INSTR(v_result, '"', 1) > 0 THEN
			v_result := REPLACE(v_result, '"', '""');
			v_result := '"' || v_result || '"';
		ELSIF INSTR(v_result, ',', 1) > 0 THEN
			v_result := '"' || v_result || '"';
		END IF;

		RETURN v_result;

	END TO_CSV;
	--------------------------------------------------------------------------------------------------------------
	-- validate_response may return g_SUCCESS, or on error SQLCODE or g_FAIL in p_STATUS
	-- p_TAB gets populated, and may return modified p_request_status, p_delim, or p_error_message
	-- p_number_lines is used to check if the number of data rows is correct
	-- RESPONSE_STATUS is not extracted

	PROCEDURE VALIDATE_RESPONSE
		(
		p_COLS           IN PARSE_UTIL.STRING_TABLE,
		p_IDX            IN NUMBER,
		p_ERROR          IN VARCHAR,
		p_TEMPLATE       IN VARCHAR,
		p_REQUEST_STATUS IN OUT NUMBER,
		p_ERROR_MESSAGE  IN OUT VARCHAR,
		p_DELIM          IN OUT VARCHAR,
		p_NUMBER_LINES   IN NUMBER,
		p_TAB            IN OUT MEX_OASIS_TRANS
		) IS

		v_number_data_rows NUMBER := 0;


	BEGIN


		-- validate attribute names
		IF p_idx < 12 THEN
			ASSERT(p_COLS.LAST >= 1, p_error ||' invalid header, missing attribute');
			ASSERT(p_COLS.LAST >= 2, p_error ||' invalid header, missing delimiter for ' || p_COLS(1));
			ASSERT(UPPER(p_COLS(1)) = response_hdr_elements(p_idx), p_error || ' invalid header attribute name (' || p_COLS(1) || ')');
		END IF;

		CASE p_idx
			WHEN 1 THEN
				-- remember the status for later processing
				p_REQUEST_STATUS := CONVERT_NUMBER(p_COLS(2));
			WHEN 2 THEN
				p_ERROR_MESSAGE := p_COLS(2);
				ASSERT(p_REQUEST_STATUS = 200, 'OASIS Error ' || TO_CHAR(p_REQUEST_STATUS) || ': ' || p_ERROR_MESSAGE);
			WHEN 3 THEN
				-- time_stamp
				p_TAB.TIME_STAMP := CONVERT_DATE(p_COLS(2));
			WHEN 4 THEN
				-- version
				ASSERT(TO_NUMBER(p_COLS(2)) = g_VERSION, p_error || ' invalid version in header (' || p_COLS(2) || ')');
			WHEN 5 THEN
				-- template
				ASSERT(LOWER(p_COLS(2)) = p_template, p_error || ' invalid template in header (' || p_COLS(2) || ')');
			WHEN 6 THEN
				-- output_format
				ASSERT(UPPER(p_COLS(2)) = 'DATA',p_error || ' invalid output_format in header (' || p_COLS(2) || ')');
			WHEN 7 THEN
				-- primary_provider_code
				p_TAB.PRIMARY_PROVIDER_CODE := p_COLS(2);
			WHEN 8 THEN
				-- primary_provider_duns
				p_TAB.PRIMARY_PROVIDER_DUNS := TO_NUMBER(p_COLS(2));
			WHEN 9 THEN
				-- return_tz
				p_TAB.RETURN_TZ := p_COLS(2);
			WHEN 10 THEN
				-- data_rows
				ASSERT(CONVERT_NUMBER(p_COLS(2)) IS NOT NULL, p_error || ' invalid data_rows value in header (' || p_COLS(2) || ')');
				v_number_data_rows := CONVERT_NUMBER(p_COLS(2));
				-- tolerate missing COLUMN_HEADERS when DATA_ROWS=0
				IF v_number_data_rows != 0 THEN
					--validate row count
					ASSERT(p_number_lines - g_HEADER_ROWS = v_number_data_rows, p_error || ' wrong number of data_rows expected ' ||
										 p_COLS(2) || ' but have ' ||
										 TO_CHAR(p_number_lines - g_HEADER_ROWS));
				END IF;
			WHEN 11 THEN
				-- this is the COLUMN_HEADERS row
				-- switch to data delimiter
				p_delim := ',';
			ELSE
				-- 12 + = data
				NULL;
		END CASE;

	END VALIDATE_RESPONSE;
	--------------------------------------------------------------------------------------------------------------
	PROCEDURE PARSE_TRANSOFFER_RESPONSE
		(
		p_CSV     IN CLOB,
		p_LOGGER  IN OUT NOCOPY MM_LOGGER_ADAPTER,
		p_TAB     OUT MEX_OASIS_TRANS
		) IS

		v_error         CONSTANT VARCHAR2(40) := 'Error in PARSE_TRANSOFFER_RESPONSE: ';
		v_template      CONSTANT VARCHAR2(20) := 'transoffering';
		v_element_count CONSTANT NUMBER(3) := 32;
		v_line_count NUMBER := 0;

		v_LINES          PARSE_UTIL.BIG_STRING_TABLE_MP;
		v_COLS           PARSE_UTIL.STRING_TABLE;
		v_IDX            BINARY_INTEGER;
		v_delim          VARCHAR2(1);
		v_PRO            MEX_OASIS_TRANS_PROFILE_TBL := MEX_OASIS_TRANS_PROFILE_TBL();
		v_DAT            MEX_OASIS_TRANS_DATA_TBL := MEX_OASIS_TRANS_DATA_TBL();
		v_data           MEX_OASIS_TRANS_DATA;
		v_profile        MEX_OASIS_TRANS_PROFILE;
		v_request_status NUMBER(3);
		v_error_message  VARCHAR2(250);

	BEGIN

		PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_CSV, v_LINES);
		v_IDX   := v_LINES.FIRST;
		v_delim := '='; -- header
		p_TAB   := MEX_OASIS_TRANS(NULL, NULL, NULL, NULL, NULL);

		v_line_count := v_LINES.COUNT;

		WHILE v_LINES.EXISTS(v_IDX) LOOP

			parse_util.PARSE_DELIMITED_STRING(v_LINES(v_IDX),
											v_delim,
											v_COLS);

			-- each line contains key=value for the header
			-- then each line contains the series of attributes
			IF v_IDX < 12 THEN

				validate_response(v_COLS,
								  v_IDX,
								  v_error,
								  v_template,
								  v_request_status,
								  v_error_message,
								  v_delim,
								  v_line_count,
								  p_TAB);

			ELSE
				-- process data rows
				IF v_COLS.COUNT != v_element_count THEN
					p_LOGGER.LOG_ERROR(v_error ||
								 'wrong number of data elements in response, found ' ||
								 TO_CHAR(v_COLS.COUNT) || ' but ' ||
								 TO_CHAR(v_element_count) || ' required');
					RETURN;
				END IF;
				-- transoffer_response

				-- no continuation flag is used

				IF v_PRO.COUNT > 0 THEN
					-- save previous data row containing profile_table
					v_data.PROFILE_TABLE := v_PRO;
					v_DAT.EXTEND;
					v_DAT(v_DAT.LAST) := v_data;
					v_PRO.DELETE;
				END IF;

				-- start new data and profile records for a non-continuation row

				v_profile := g_default_profile;
				v_data    := g_default_data;

				v_data.TIME_OF_LAST_UPDATE         := CONVERT_DATE(v_COLS(1));
				v_data.SELLER_CODE                 := v_COLS(2);
				v_data.SELLER_DUNS                 := CONVERT_NUMBER(v_COLS(3));
				v_data.INTERFACE_TYPE              := v_COLS(7);
				v_data.OFFER_START_TIME            := CONVERT_DATE(v_COLS(8));
				v_data.OFFER_STOP_TIME             := CONVERT_DATE(v_COLS(9));
				v_data.SERVICE_INCREMENT           := v_COLS(13);
				v_data.TS_CLASS                    := v_COLS(14);
				v_data.TS_TYPE                     := v_COLS(15);
				v_data.TS_PERIOD                   := v_COLS(16);
				v_data.TS_WINDOW                   := v_COLS(17);
				v_data.TS_SUBCLASS                 := v_COLS(18);
				v_data.ANC_SVC_REQ                 := v_COLS(19);
				v_data.SALE_REF                    := v_COLS(20);
				v_data.POSTING_REF                 := v_COLS(21);
				v_data.CEILING_PRICE               := CONVERT_NUMBER(v_COLS(22));
				v_data.PRICE_UNITS                 := v_COLS(24);
				v_data.SERVICE_DESCRIPTION         := v_COLS(25);
				v_data.NERC_CURTAILEMENT_PRIORITY  := CONVERT_NUMBER(v_COLS(26));
				v_data.OTHER_CURTAILEMENT_PRIORITY := v_COLS(27);
				v_data.SELLER_NAME                 := v_COLS(28);
				v_data.SELLER_PHONE                := v_COLS(29);
				v_data.SELLER_FAX                  := v_COLS(30);
				v_data.SELLER_EMAIL                := v_COLS(31);
				v_data.SELLER_COMMENTS             := v_COLS(32);

				v_profile.PATH_NAME         := v_COLS(4);
				v_profile.POINT_OF_RECEIPT  := v_COLS(5);
				v_profile.POINT_OF_DELIVERY := v_COLS(6);
				v_profile.START_TIME        := CONVERT_DATE(v_COLS(10), v_data.SERVICE_INCREMENT);
				v_profile.STOP_TIME         := CONVERT_DATE(v_COLS(11), v_data.SERVICE_INCREMENT);
				v_profile.OFFER_PRICE       := CONVERT_NUMBER(v_COLS(23));
				v_profile.CAPACITY          := CONVERT_NUMBER(v_COLS(12));

				v_PRO.EXTEND;
				v_PRO(v_PRO.LAST) := v_profile;

			END IF;

			v_IDX := v_LINES.NEXT(v_IDX);

		END LOOP;

		-- save the last data
		IF v_PRO.COUNT > 0 THEN
			-- save previous data row containing profile_table
			v_data.PROFILE_TABLE := v_PRO;
			v_DAT.EXTEND;
			v_DAT(v_DAT.LAST) := v_data;
			v_PRO.DELETE;
		END IF;

		-- assign the only record
		-- other attributes were assigned earlier
		p_TAB.DATA_TABLE := v_DAT;

		IF v_request_status != g_REQUEST_SUCCESS THEN
			p_LOGGER.LOG_ERROR(v_error || 'REQUEST_STATUS = ' ||
						 TO_CHAR(v_request_status) || ', ' ||
						 v_error_message);
		END IF;

	EXCEPTION
		WHEN OTHERS THEN
			p_LOGGER.LOG_ERROR(v_error || ': ' || SQLERRM);
			RAISE;
	END PARSE_TRANSOFFER_RESPONSE;
	--------------------------------------------------------------------------------------------------------------
	PROCEDURE CREATE_TRANSOFFER_QUERY(p_CSV     OUT CLOB,
									  p_TAB     IN MEX_OASIS_TRANS,
									  p_LOGGER  IN OUT NOCOPY mm_logger_adapter) IS

		v_columns        VARCHAR2(2000);
		v_column_headers VARCHAR2(2000);
		v_template       VARCHAR2(20) := 'transoffering';
		v_data_rows      NUMBER := 0;
		v_DAT            MEX_OASIS_TRANS_DATA_TBL;
		v_PRO            MEX_OASIS_TRANS_PROFILE_TBL;
		v_CSV            CLOB;

	BEGIN
		-- data rows
		v_DAT := p_TAB.DATA_TABLE;

		IF v_DAT IS NOT NULL THEN

			FOR v_dat_row IN v_DAT.FIRST .. v_DAT.LAST LOOP
				v_PRO := v_DAT(v_dat_row).PROFILE_TABLE;

				FOR v_pro_row IN v_PRO.FIRST .. v_PRO.LAST LOOP

					v_CSV := v_CSV || TO_CSV(v_PRO(v_pro_row).PATH_NAME) || ',';
					v_CSV := v_CSV || TO_CSV(v_DAT(v_dat_row).SELLER_CODE) || ',';
					v_CSV := v_CSV || TO_CSV(v_DAT(v_dat_row).SELLER_DUNS,
											 g_NUMBER_9_FORMAT) || ',';
					v_CSV := v_CSV ||
							 TO_CSV(v_PRO(v_pro_row).POINT_OF_RECEIPT) || ',';
					v_CSV := v_CSV ||
							 TO_CSV(v_PRO(v_pro_row).POINT_OF_DELIVERY) || ',';
					v_CSV := v_CSV ||
							 TO_CSV(v_DAT(v_dat_row).SERVICE_INCREMENT) || ',';
					v_CSV := v_CSV || TO_CSV(v_DAT(v_dat_row).TS_CLASS) || ',';
					v_CSV := v_CSV || TO_CSV(v_DAT(v_dat_row).TS_TYPE) || ',';
					v_CSV := v_CSV || TO_CSV(v_DAT(v_dat_row).TS_PERIOD) || ',';
					v_CSV := v_CSV || TO_CSV(v_DAT(v_dat_row).TS_WINDOW) || ',';
					v_CSV := v_CSV || TO_CSV(v_DAT(v_dat_row).TS_SUBCLASS) || ',';
					v_CSV := v_CSV || TO_CSV(v_PRO(v_pro_row).START_TIME) || ',';
					v_CSV := v_CSV || TO_CSV(v_PRO(v_pro_row).STOP_TIME) || ',';
					v_CSV := v_CSV || TO_CSV(v_DAT(v_dat_row).POSTING_REF) || ',';
					v_CSV := v_CSV ||
							 TO_CSV(v_DAT(v_dat_row).TIME_OF_LAST_UPDATE) ||
							 g_CRLF;

					v_data_rows := v_data_rows + 1;

				END LOOP; -- profile
			END LOOP; -- data

		END IF;

		-- add header with count
		-- count is sum total of all profile_table rows within all the data_table rows

		FOR idx IN 1 .. transoffer_query_elements.COUNT LOOP
			IF idx < transoffer_query_elements.COUNT THEN
				v_columns := v_columns || transoffer_query_elements(idx) || ',';
			ELSE
				v_columns := v_columns || transoffer_query_elements(idx);
			END IF;
		END LOOP;
		v_column_headers := v_columns;

		-- header row
		p_CSV := input_hdr_elements(1) || '=';
		p_CSV := p_CSV || TO_CSV(g_version, g_FLOAT_5_1_FORMAT) || g_CRLF;
		p_CSV := p_CSV || input_hdr_elements(2) || '=';
		p_CSV := p_CSV || TO_CSV(v_template) || g_CRLF;
		p_CSV := p_CSV || input_hdr_elements(3) || '=';
		p_CSV := p_CSV || TO_CSV(g_output_format) || g_CRLF;
		p_CSV := p_CSV || input_hdr_elements(4) || '=';
		p_CSV := p_CSV || TO_CSV(p_TAB.PRIMARY_PROVIDER_CODE) || g_CRLF;
		p_CSV := p_CSV || input_hdr_elements(5) || '=';
		p_CSV := p_CSV ||
				 TO_CSV(p_TAB.PRIMARY_PROVIDER_DUNS, g_NUMBER_9_FORMAT) ||
				 g_CRLF;
		p_CSV := p_CSV || input_hdr_elements(6) || '=';
		p_CSV := p_CSV || TO_CSV(g_EXCHANGE_TZ) || g_CRLF;
		p_CSV := p_CSV || input_hdr_elements(7) || '=';
		p_CSV := p_CSV || TO_CSV(v_data_rows) || g_CRLF;
		p_CSV := p_CSV || input_hdr_elements(8) || '=';
		p_CSV := p_CSV || v_column_headers || g_CRLF;
		p_CSV := p_CSV || v_CSV; -- append data/profile rows

	EXCEPTION
		WHEN OTHERS THEN
			p_LOGGER.LOG_ERROR('Error in CREATE_TRANSOFFER_QUERY: ' || SQLERRM);
			RAISE;
	END CREATE_TRANSOFFER_QUERY;
	--------------------------------------------------------------------------------------------------------------
	PROCEDURE PARSE_TRANSREQUEST_RESPONSE
		(
		p_CSV     IN CLOB,
		p_LOGGER  IN OUT NOCOPY MM_LOGGER_ADAPTER,
		p_TAB     OUT MEX_OASIS_TRANS) IS

		v_error         CONSTANT VARCHAR2(40) := 'Error in PARSE_TRANSREQUEST_RESPONSE: ';
		v_template      CONSTANT VARCHAR2(20) := 'transrequest';
		v_element_count CONSTANT NUMBER(3) := 31;
		v_line_count NUMBER := 0;

		v_LINES          PARSE_UTIL.BIG_STRING_TABLE_MP;
		v_COLS           PARSE_UTIL.STRING_TABLE;
		v_IDX            BINARY_INTEGER;
		v_delim          VARCHAR2(1);
		v_PRO            MEX_OASIS_TRANS_PROFILE_TBL := MEX_OASIS_TRANS_PROFILE_TBL();
		v_DAT            MEX_OASIS_TRANS_DATA_TBL := MEX_OASIS_TRANS_DATA_TBL();
		v_data           MEX_OASIS_TRANS_DATA;
		v_profile        MEX_OASIS_TRANS_PROFILE;
		v_request_status NUMBER(3);
		v_error_message  VARCHAR2(250);

	BEGIN

		PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_CSV, v_LINES);
		v_IDX   := v_LINES.FIRST;
		v_delim := '='; -- header
		p_TAB   := MEX_OASIS_TRANS(NULL, NULL, NULL, NULL, NULL);

		v_line_count := v_LINES.COUNT;

		WHILE v_LINES.EXISTS(v_IDX) LOOP

			PARSE_UTIL.PARSE_DELIMITED_STRING(v_LINES(v_IDX),
											v_delim,
											v_COLS);

			-- each line contains key=value for the header
			-- then each line contains the series of attributes
			IF v_IDX < 12 THEN

				validate_response(v_COLS,
								  v_IDX,
								  v_error,
								  v_template,
								  v_request_status,
								  v_error_message,
								  v_delim,
								  v_line_count,
								  p_TAB);
			ELSE
				-- process data rows
				IF v_COLS.COUNT != v_element_count THEN
					p_LOGGER.LOG_ERROR(v_error ||
								 'wrong number of data elements in response, found ' ||
								 TO_CHAR(v_COLS.COUNT) || ' but ' ||
								 TO_CHAR(v_element_count) || ' required');
					RETURN;
				END IF;
				-- transrequest_response

				-- continuation_flag
				IF v_COLS(2) = 'N' THEN

					IF v_PRO.COUNT > 0 THEN
						-- save previous data row containing profile_table
						v_data.PROFILE_TABLE := v_PRO;
						v_DAT.EXTEND;
						v_DAT(v_DAT.LAST) := v_data;
						v_PRO.DELETE;
					END IF;

					-- start new data and profile records for a non-continuation row

					v_profile := g_default_profile;
					v_data    := g_default_data;

					v_data.RECORD_STATUS     := CONVERT_NUMBER(v_COLS(1));
					v_data.SELLER_CODE       := v_COLS(4);
					v_data.SELLER_DUNS       := CONVERT_NUMBER(v_COLS(5));
					v_data.SOURCE            := v_COLS(9);
					v_data.SINK              := v_COLS(10);
					v_data.SERVICE_INCREMENT := v_COLS(12);
					v_data.TS_CLASS          := v_COLS(13);
					v_data.TS_TYPE           := v_COLS(14);
					v_data.TS_PERIOD         := v_COLS(15);
					v_data.TS_WINDOW         := v_COLS(16);
					v_data.TS_SUBCLASS       := v_COLS(17);
					v_data.PRECONFIRMED      := v_COLS(22);
					v_data.ANC_SVC_LINK      := v_COLS(23);
					v_data.POSTING_REF       := v_COLS(24);
					v_data.SALE_REF          := v_COLS(25);
					v_data.REQUEST_REF       := v_COLS(26);
					v_data.DEAL_REF          := v_COLS(27);
					v_data.REQUEST_TYPE      := v_COLS(29);
					v_data.RELATED_REF       := v_COLS(30);
					v_data.ERROR_MESSAGE     := v_COLS(31);

					v_profile.ASSIGNMENT_REF     := v_COLS(3);
					v_profile.PATH_NAME          := v_COLS(6);
					v_profile.POINT_OF_RECEIPT   := v_COLS(7);
					v_profile.POINT_OF_DELIVERY  := v_COLS(8);
					v_profile.CAPACITY_REQUESTED := CONVERT_NUMBER(v_COLS(11));
					v_profile.START_TIME         := CONVERT_DATE(v_COLS(19), v_data.SERVICE_INCREMENT);
					v_profile.STOP_TIME          := CONVERT_DATE(v_COLS(20), v_data.SERVICE_INCREMENT);
					v_profile.BID_PRICE          := CONVERT_NUMBER(v_COLS(21));
					v_profile.CUSTOMER_COMMENTS  := v_COLS(28);

					v_PRO.EXTEND;
					v_PRO(v_PRO.LAST) := v_profile;

				ELSIF v_COLS(2) = 'Y' THEN
					-- just extend the profile table

					v_profile.ASSIGNMENT_REF     := v_COLS(3);
					v_profile.PATH_NAME          := v_COLS(6);
					v_profile.POINT_OF_RECEIPT   := v_COLS(7);
					v_profile.POINT_OF_DELIVERY  := v_COLS(8);
					v_profile.CAPACITY_REQUESTED := CONVERT_NUMBER(v_COLS(11));
					v_profile.START_TIME         := CONVERT_DATE(v_COLS(19), v_data.SERVICE_INCREMENT);
					v_profile.STOP_TIME          := CONVERT_DATE(v_COLS(20), v_data.SERVICE_INCREMENT);
					v_profile.BID_PRICE          := CONVERT_NUMBER(v_COLS(21));
					v_profile.CUSTOMER_COMMENTS  := v_COLS(28);

					v_PRO.EXTEND;
					v_PRO(v_PRO.LAST) := v_profile;

				ELSE
					-- error
					NULL;
				END IF;

			END IF;

			v_IDX := v_LINES.NEXT(v_IDX);

		END LOOP;

		-- save the last data (in case it was a continuation row)
		IF v_PRO.COUNT > 0 THEN
			-- save previous data row containing profile_table
			v_data.PROFILE_TABLE := v_PRO;
			v_DAT.EXTEND;
			v_DAT(v_DAT.LAST) := v_data;
			v_PRO.DELETE;
		END IF;

		-- assign the only record
		-- other attributes were assigned earlier
		p_TAB.DATA_TABLE := v_DAT;

		IF v_request_status != g_REQUEST_SUCCESS THEN
			p_LOGGER.LOG_ERROR(v_error || 'REQUEST_STATUS = ' ||
						 TO_CHAR(v_request_status) || ', ' ||
						 v_error_message);
		END IF;

	EXCEPTION
		WHEN OTHERS THEN
			p_LOGGER.LOG_ERROR(v_error || ':' || SQLERRM);
			RAISE;
	END PARSE_TRANSREQUEST_RESPONSE;
	--------------------------------------------------------------------------------------------------------------
	PROCEDURE CREATE_TRANSREQUEST_INPUT(p_CSV     OUT CLOB,
										p_TAB     IN MEX_OASIS_TRANS,
										p_LOGGER  IN OUT NOCOPY mm_logger_adapter) IS

		v_columns        VARCHAR2(2000);
		v_column_headers VARCHAR2(2000);
		v_template       VARCHAR2(20) := 'transrequest';
		v_data_rows      NUMBER := 0;
		v_DAT            MEX_OASIS_TRANS_DATA_TBL;
		v_PRO            MEX_OASIS_TRANS_PROFILE_TBL;
		v_CSV            CLOB;

	BEGIN

	    -- data rows
		v_DAT := p_TAB.DATA_TABLE;

		IF v_DAT IS NOT NULL THEN

			FOR v_dat_row IN v_DAT.FIRST .. v_DAT.LAST LOOP
				v_PRO := v_DAT(v_dat_row).PROFILE_TABLE;

				FOR v_pro_row IN v_PRO.FIRST .. v_PRO.LAST LOOP

					IF v_pro_row = 1 THEN

						v_CSV := v_CSV || 'N' || ',';
						v_CSV := v_CSV ||
								 TO_CSV(v_DAT(v_dat_row).SELLER_CODE) || ',';
						v_CSV := v_CSV ||
								 TO_CSV(v_DAT(v_dat_row).SELLER_DUNS,
										g_NUMBER_9_FORMAT) || ',';
						v_CSV := v_CSV ||
								 TO_CSV(v_PRO(v_pro_row).PATH_NAME) || ',';
						v_CSV := v_CSV ||
								 TO_CSV(v_PRO(v_pro_row).POINT_OF_RECEIPT) || ',';
						v_CSV := v_CSV ||
								 TO_CSV(v_PRO(v_pro_row).POINT_OF_DELIVERY) || ',';
						v_CSV := v_CSV || TO_CSV(v_DAT(v_dat_row).SOURCE) || ',';
						v_CSV := v_CSV || TO_CSV(v_DAT(v_dat_row).SINK) || ',';
						v_CSV := v_CSV ||
								 TO_CSV(v_PRO(v_pro_row).CAPACITY_REQUESTED) || ',';
						v_CSV := v_CSV ||
								 TO_CSV(v_DAT(v_dat_row).SERVICE_INCREMENT) || ',';
						v_CSV := v_CSV || TO_CSV(v_DAT(v_dat_row).TS_CLASS) || ',';
						v_CSV := v_CSV || TO_CSV(v_DAT(v_dat_row).TS_TYPE) || ',';
						v_CSV := v_CSV ||
								 TO_CSV(v_DAT(v_dat_row).TS_PERIOD) || ',';
						v_CSV := v_CSV ||
								 TO_CSV(v_DAT(v_dat_row).TS_WINDOW) || ',';
						v_CSV := v_CSV ||
								 TO_CSV(v_DAT(v_dat_row).TS_SUBCLASS) || ',';
						v_CSV := v_CSV ||
								 TO_CSV(v_DAT(v_dat_row)
										.STATUS_NOTIFICATION) || ',';
						v_CSV := v_CSV ||
								 TO_CSV(v_PRO(v_pro_row).START_TIME) || ',';
						v_CSV := v_CSV ||
								 TO_CSV(v_PRO(v_pro_row).STOP_TIME) || ',';
						v_CSV := v_CSV ||
								 TO_CSV(v_PRO(v_pro_row).BID_PRICE,
										g_FLOAT_9_4_FORMAT) || ',';
						v_CSV := v_CSV ||
								 TO_CSV(v_DAT(v_dat_row).PRECONFIRMED) || ',';
						v_CSV := v_CSV ||
								 TO_CSV(v_DAT(v_dat_row).ANC_SVC_LINK) || ',';
						v_CSV := v_CSV ||
								 TO_CSV(v_DAT(v_dat_row).POSTING_REF) || ',';
						v_CSV := v_CSV || TO_CSV(v_DAT(v_dat_row).SALE_REF) || ',';
						v_CSV := v_CSV ||
								 TO_CSV(v_DAT(v_dat_row).REQUEST_REF) || ',';
						v_CSV := v_CSV || TO_CSV(v_DAT(v_dat_row).DEAL_REF) || ',';
						v_CSV := v_CSV ||
								 TO_CSV(v_PRO(v_pro_row).CUSTOMER_COMMENTS) || ',';
						v_CSV := v_CSV ||
								 TO_CSV(v_DAT(v_dat_row).REQUEST_TYPE) || ',';
						v_CSV := v_CSV ||
								 TO_CSV(v_DAT(v_dat_row).related_ref) ||
								 g_CRLF;

					ELSE

						v_CSV := v_CSV || 'Y' || ',';
						v_CSV := v_CSV || ',';
						v_CSV := v_CSV || ',';
						v_CSV := v_CSV ||
								 TO_CSV(v_PRO(v_pro_row).PATH_NAME) || ',';
						v_CSV := v_CSV ||
								 TO_CSV(v_PRO(v_pro_row).POINT_OF_RECEIPT) || ',';
						v_CSV := v_CSV ||
								 TO_CSV(v_PRO(v_pro_row).POINT_OF_DELIVERY) || ',';
						v_CSV := v_CSV || ',';
						v_CSV := v_CSV || ',';
						v_CSV := v_CSV ||
								 TO_CSV(v_PRO(v_pro_row).CAPACITY_REQUESTED) || ',';
						v_CSV := v_CSV || ',';
						v_CSV := v_CSV || ',';
						v_CSV := v_CSV || ',';
						v_CSV := v_CSV || ',';
						v_CSV := v_CSV || ',';
						v_CSV := v_CSV || ',';
						v_CSV := v_CSV || ',';
						v_CSV := v_CSV ||
								 TO_CSV(v_PRO(v_pro_row).START_TIME) || ',';
						v_CSV := v_CSV ||
								 TO_CSV(v_PRO(v_pro_row).STOP_TIME) || ',';
						v_CSV := v_CSV ||
								 TO_CSV(v_PRO(v_pro_row).BID_PRICE,
										g_FLOAT_9_4_FORMAT) || ',';
						v_CSV := v_CSV || ',';
						v_CSV := v_CSV || ',';
						v_CSV := v_CSV || ',';
						v_CSV := v_CSV || ',';
						v_CSV := v_CSV || ',';
						v_CSV := v_CSV || ',';
						v_CSV := v_CSV ||
								 TO_CSV(v_PRO(v_pro_row).CUSTOMER_COMMENTS) || ',';
						v_CSV := v_CSV || ',';
						v_CSV := v_CSV || g_CRLF;
					END IF;

					v_data_rows := v_data_rows + 1;

				END LOOP; -- profile
			END LOOP; -- data

		END IF;

		-- add header with count
		-- count is sum total of all profile_table rows within all the data_table rows

		FOR idx IN 1 .. transrequest_input_elements.COUNT LOOP
			IF idx < transrequest_input_elements.COUNT THEN
				v_columns := v_columns || transrequest_input_elements(idx) || ',';
			ELSE
				v_columns := v_columns || transrequest_input_elements(idx);
			END IF;
		END LOOP;
		v_column_headers := v_columns;

		-- header row
		p_CSV := input_hdr_elements(1) || '=';
		p_CSV := p_CSV || TO_CSV(g_version, g_FLOAT_5_1_FORMAT) || g_CRLF;
		p_CSV := p_CSV || input_hdr_elements(2) || '=';
		p_CSV := p_CSV || TO_CSV(v_template) || g_CRLF;
		p_CSV := p_CSV || input_hdr_elements(3) || '=';
		p_CSV := p_CSV || TO_CSV(g_output_format) || g_CRLF;
		p_CSV := p_CSV || input_hdr_elements(4) || '=';
		p_CSV := p_CSV || TO_CSV(p_TAB.PRIMARY_PROVIDER_CODE) || g_CRLF;
		p_CSV := p_CSV || input_hdr_elements(5) || '=';
		p_CSV := p_CSV ||
				 TO_CSV(p_TAB.PRIMARY_PROVIDER_DUNS, g_NUMBER_9_FORMAT) ||
				 g_CRLF;
		p_CSV := p_CSV || input_hdr_elements(6) || '=';
		p_CSV := p_CSV || TO_CSV(g_EXCHANGE_TZ) || g_CRLF;
		p_CSV := p_CSV || input_hdr_elements(7) || '=';
		p_CSV := p_CSV || TO_CSV(v_data_rows) || g_CRLF;
		p_CSV := p_CSV || input_hdr_elements(8) || '=';
		p_CSV := p_CSV || v_column_headers || g_CRLF;
		p_CSV := p_CSV || v_CSV; -- append data/profile rows

	EXCEPTION
		WHEN OTHERS THEN
			p_LOGGER.LOG_ERROR('Error in CREATE_TRANSREQUEST_INPUT: ' || SQLERRM);
			RAISE;
	END CREATE_TRANSREQUEST_INPUT;
	--------------------------------------------------------------------------------------------------------------
	PROCEDURE PARSE_TRANSSTATUS_RESPONSE
		(
		p_CSV IN CLOB,
		p_LOGGER IN OUT NOCOPY MM_LOGGER_ADAPTER,
		p_TAB OUT MEX_OASIS_TRANS
		) IS

		v_error         CONSTANT VARCHAR2(40) := 'Error in PARSE_TRANSSTATUS_RESPONSE:';
		v_template      CONSTANT VARCHAR2(20) := 'transstatus';
		--March 28, 2008 - LD - no of columns received in transstatus is now 63
		--one more col. 'SYSTEM_IMPACT_STUDY_OFFERED' added at the end
		--The values from this col are not captured by the current version of the code
		v_element_count CONSTANT NUMBER(3) := 63;
		v_line_count NUMBER := 0;

		v_LINES          PARSE_UTIL.BIG_STRING_TABLE_MP;
		v_COLS           PARSE_UTIL.STRING_TABLE;
		v_IDX            BINARY_INTEGER;
		v_delim          VARCHAR2(1);
		v_PRO            MEX_OASIS_TRANS_PROFILE_TBL := MEX_OASIS_TRANS_PROFILE_TBL();
		v_DAT            MEX_OASIS_TRANS_DATA_TBL := MEX_OASIS_TRANS_DATA_TBL();
		v_data           MEX_OASIS_TRANS_DATA;
		v_profile        MEX_OASIS_TRANS_PROFILE;
		v_request_status NUMBER(3);
		v_error_message  VARCHAR2(250);

	BEGIN

		PARSE_CLOB_INTO_LINES(p_CSV, v_LINES);
		v_IDX   := v_LINES.FIRST;
		v_delim := '='; -- header
		p_TAB   := MEX_OASIS_TRANS(NULL, NULL, NULL, NULL, NULL);

		v_line_count := v_LINES.COUNT;

		WHILE v_LINES.EXISTS(v_IDX) LOOP

			parse_util.PARSE_DELIMITED_STRING(v_LINES(v_IDX),
											v_delim,
											v_COLS);

			-- each line contains key=value for the header
			-- then each line contains the series of attributes
			IF v_IDX < 12 THEN

				validate_response(v_COLS,
								  v_IDX,
								  v_error,
								  v_template,
								  v_request_status,
								  v_error_message,
								  v_delim,
								  v_line_count,
								  p_TAB);

			ELSE
				-- process data rows
				IF v_COLS.COUNT != v_element_count THEN
					p_LOGGER.LOG_ERROR(v_error ||
								 'wrong number of data elements in response, found ' ||
								 TO_CHAR(v_COLS.COUNT) || ' but ' ||
								 TO_CHAR(v_element_count) || ' required');
					RETURN;
				END IF;
				-- transstatus_response

				-- continuation_flag
				IF v_COLS(1) = 'N' THEN

					IF v_PRO.COUNT > 0 THEN
						-- save previous data row containing profile_table
						v_data.PROFILE_TABLE := v_PRO;
						v_DAT.EXTEND;
						v_DAT(v_DAT.LAST) := v_data;
						v_PRO.DELETE;
					END IF;

					-- start new data and profile records for a non-continuation row

					v_profile := g_default_profile;
					v_data    := g_default_data;

					v_data.RECORD_STATUS               := NULL;
					v_data.SELLER_CODE                 := v_COLS(3);
					v_data.SELLER_DUNS                 := CONVERT_NUMBER(v_COLS(4));
					v_data.CUSTOMER_CODE               := v_COLS(5);
					v_data.CUSTOMER_DUNS               := CONVERT_NUMBER(v_COLS(6));
					v_data.AFFILIATE_FLAG              := v_COLS(7);
					v_data.SOURCE                      := v_COLS(11);
					v_data.SINK                        := v_COLS(12);
					v_data.SERVICE_INCREMENT           := v_COLS(15);
					v_data.TS_CLASS                    := v_COLS(16);
					v_data.TS_TYPE                     := v_COLS(17);
					v_data.TS_PERIOD                   := v_COLS(18);
					v_data.TS_WINDOW                   := v_COLS(19);
					v_data.TS_SUBCLASS                 := v_COLS(20);
					v_data.NERC_CURTAILEMENT_PRIORITY  := CONVERT_NUMBER(v_COLS(21));
					v_data.OTHER_CURTAILEMENT_PRIORITY := v_COLS(22);
					v_data.CEILING_PRICE               := CONVERT_NUMBER(v_COLS(25));
					v_data.PRICE_UNITS                 := v_COLS(28);
					v_data.PRECONFIRMED                := v_COLS(29);
					v_data.ANC_SVC_LINK                := v_COLS(30);
					v_data.ANC_SVC_REQ                 := v_COLS(31);
					v_data.POSTING_REF                 := v_COLS(32);
					v_data.SALE_REF                    := v_COLS(33);
					v_data.REQUEST_REF                 := v_COLS(34);
					v_data.DEAL_REF                    := v_COLS(35);
					v_data.IMPACTED                    := CONVERT_NUMBER(v_COLS(36));
					v_data.COMPETING_REQUEST_FLAG      := v_COLS(37);
					v_data.REQUEST_TYPE                := v_COLS(38);
					v_data.RELATED_REF                 := v_COLS(39);
					v_data.NEGOTIATED_PRICE_FLAG       := v_COLS(40);
					v_data.STATUS                      := v_COLS(41);
					v_data.STATUS_NOTIFICATION         := v_COLS(42);
					v_data.STATUS_COMMENTS             := v_COLS(43);
					v_data.TIME_QUEUED                 := CONVERT_DATE(v_COLS(44));
					v_data.RESPONSE_TIME_LIMIT         := CONVERT_DATE(v_COLS(45));
					v_data.TIME_OF_LAST_UPDATE         := CONVERT_DATE(v_COLS(46));
					v_data.PRIMARY_PROVIDER_COMMENTS   := v_COLS(47);
					v_data.SELLER_REF                  := v_COLS(48);
					v_data.SELLER_COMMENTS             := v_COLS(49);
					v_data.SELLER_NAME                 := v_COLS(51);
					v_data.SELLER_PHONE                := v_COLS(52);
					v_data.SELLER_FAX                  := v_COLS(53);
					v_data.SELLER_EMAIL                := v_COLS(54);
					v_data.CUSTOMER_NAME               := v_COLS(55);
					v_data.CUSTOMER_PHONE              := v_COLS(56);
					v_data.CUSTOMER_FAX                := v_COLS(57);
					v_data.CUSTOMER_EMAIL              := v_COLS(58);

					v_profile.ASSIGNMENT_REF        := v_COLS(2);
					v_profile.PATH_NAME             := v_COLS(8);
					v_profile.POINT_OF_RECEIPT      := v_COLS(9);
					v_profile.POINT_OF_DELIVERY     := v_COLS(10);
					v_profile.CAPACITY_REQUESTED    := CONVERT_NUMBER(v_COLS(13));
					v_profile.CAPACITY_GRANTED      := CONVERT_NUMBER(v_COLS(14));
					v_profile.START_TIME            := CONVERT_DATE(v_COLS(23), v_data.SERVICE_INCREMENT);
					v_profile.STOP_TIME             := CONVERT_DATE(v_COLS(24), v_data.SERVICE_INCREMENT);
					v_profile.OFFER_PRICE           := CONVERT_NUMBER(v_COLS(26));
					v_profile.BID_PRICE             := CONVERT_NUMBER(v_COLS(27));
					v_profile.CUSTOMER_COMMENTS     := v_COLS(50);
					v_profile.REASSIGNED_REF        := v_COLS(59);
					v_profile.REASSIGNED_CAPACITY   := CONVERT_NUMBER(v_COLS(60));
					v_profile.REASSIGNED_START_TIME := CONVERT_DATE(v_COLS(61), v_data.SERVICE_INCREMENT);
					v_profile.REASSIGNED_STOP_TIME  := CONVERT_DATE(v_COLS(62), v_data.SERVICE_INCREMENT);

					v_PRO.EXTEND;
					v_PRO(v_PRO.LAST) := v_profile;

				ELSIF v_COLS(1) = 'Y' THEN
					-- just extend the profile table

					v_profile.ASSIGNMENT_REF        := v_COLS(2);
					v_profile.PATH_NAME             := v_COLS(8);
					v_profile.POINT_OF_RECEIPT      := v_COLS(9);
					v_profile.POINT_OF_DELIVERY     := v_COLS(10);
					v_profile.CAPACITY_REQUESTED    := CONVERT_NUMBER(v_COLS(13));
					v_profile.CAPACITY_GRANTED      := CONVERT_NUMBER(v_COLS(14));
					v_profile.START_TIME            := CONVERT_DATE(v_COLS(23), v_data.SERVICE_INCREMENT);
					v_profile.STOP_TIME             := CONVERT_DATE(v_COLS(24), v_data.SERVICE_INCREMENT);
					v_profile.OFFER_PRICE           := CONVERT_NUMBER(v_COLS(26));
					v_profile.BID_PRICE             := CONVERT_NUMBER(v_COLS(27));
					v_profile.CUSTOMER_COMMENTS     := v_COLS(50);
					v_profile.REASSIGNED_REF        := v_COLS(59);
					v_profile.REASSIGNED_CAPACITY   := CONVERT_NUMBER(v_COLS(60));
					v_profile.REASSIGNED_START_TIME := CONVERT_DATE(v_COLS(61), v_data.SERVICE_INCREMENT);
					v_profile.REASSIGNED_STOP_TIME  := CONVERT_DATE(v_COLS(62), v_data.SERVICE_INCREMENT);

					v_PRO.EXTEND;
					v_PRO(v_PRO.LAST) := v_profile;

				ELSE
					-- error
					NULL;
				END IF;

			END IF;

			v_IDX := v_LINES.NEXT(v_IDX);

		END LOOP;

		-- save the last data (in case it was a continuation row)
		IF v_PRO.COUNT > 0 THEN
			-- save previous data row containing profile_table
			v_data.PROFILE_TABLE := v_PRO;
			v_DAT.EXTEND;
			v_DAT(v_DAT.LAST) := v_data;
			v_PRO.DELETE;
		END IF;

		-- assign the only record
		-- other attributes were assigned earlier
		p_TAB.DATA_TABLE := v_DAT;

		IF v_request_status != g_REQUEST_SUCCESS THEN
		p_LOGGER.LOG_ERROR(v_error || 'REQUEST_STATUS = ' ||
						 TO_CHAR(v_request_status) || ', ' ||
						 v_error_message);
		END IF;

	EXCEPTION
		WHEN OTHERS THEN
			p_LOGGER.LOG_ERROR(v_error || ':' || SQLERRM);
			RAISE;
	END PARSE_TRANSSTATUS_RESPONSE;
	--------------------------------------------------------------------------------------------------------------
	PROCEDURE CREATE_TRANSSTATUS_QUERY(p_CSV     OUT CLOB,
									   p_TAB     IN MEX_OASIS_TRANS,
									   p_LOGGER  IN OUT NOCOPY mm_logger_adapter) IS

		v_columns        VARCHAR2(2000);
		v_column_headers VARCHAR2(2000);
		v_template       VARCHAR2(20) := 'transstatus';
		v_data_rows      NUMBER := 0;
		v_DAT            MEX_OASIS_TRANS_DATA_TBL;
		v_PRO            MEX_OASIS_TRANS_PROFILE_TBL;
		v_CSV            CLOB;

	BEGIN

		-- data rows
		v_DAT := p_TAB.DATA_TABLE;

		IF v_DAT IS NOT NULL THEN

			FOR v_dat_row IN v_DAT.FIRST .. v_DAT.LAST LOOP
				v_PRO := v_DAT(v_dat_row).PROFILE_TABLE;

				FOR v_pro_row IN v_PRO.FIRST .. v_PRO.LAST LOOP

					v_CSV := v_CSV || TO_CSV(v_DAT(v_dat_row).SELLER_CODE) || ',';
					v_CSV := v_CSV || TO_CSV(v_DAT(v_dat_row).SELLER_DUNS,
											 g_NUMBER_9_FORMAT) || ',';
					v_CSV := v_CSV ||
							 TO_CSV(v_DAT(v_dat_row).CUSTOMER_CODE) || ',';
					v_CSV := v_CSV || TO_CSV(v_DAT(v_dat_row).CUSTOMER_DUNS,
											 g_NUMBER_9_FORMAT) || ',';
					v_CSV := v_CSV || TO_CSV(v_PRO(v_pro_row).PATH_NAME) || ',';
					v_CSV := v_CSV ||
							 TO_CSV(v_PRO(v_pro_row).POINT_OF_RECEIPT) || ',';
					v_CSV := v_CSV ||
							 TO_CSV(v_PRO(v_pro_row).POINT_OF_DELIVERY) || ',';
					v_CSV := v_CSV ||
							 TO_CSV(v_DAT(v_dat_row).SERVICE_INCREMENT) || ',';
					v_CSV := v_CSV || TO_CSV(v_DAT(v_dat_row).TS_CLASS) || ',';
					v_CSV := v_CSV || TO_CSV(v_DAT(v_dat_row).TS_TYPE) || ',';
					v_CSV := v_CSV || TO_CSV(v_DAT(v_dat_row).TS_PERIOD) || ',';
					v_CSV := v_CSV || TO_CSV(v_DAT(v_dat_row).TS_WINDOW) || ',';
					v_CSV := v_CSV || TO_CSV(v_DAT(v_dat_row).TS_SUBCLASS) || ',';
					v_CSV := v_CSV || TO_CSV(v_DAT(v_dat_row).STATUS) || ',';
					v_CSV := v_CSV || TO_CSV(v_PRO(v_pro_row).START_TIME) || ',';
					v_CSV := v_CSV || TO_CSV(v_PRO(v_pro_row).STOP_TIME) || ',';
					v_CSV := v_CSV ||
							 TO_CSV(v_DAT(v_dat_row).START_TIME_QUEUED) || ',';
					v_CSV := v_CSV ||
							 TO_CSV(v_DAT(v_dat_row).STOP_TIME_QUEUED) || ',';
					v_CSV := v_CSV ||
							 TO_CSV(v_DAT(v_dat_row).NEGOTIATED_PRICE_FLAG) || ',';
					v_CSV := v_CSV ||
							 TO_CSV(v_PRO(v_pro_row).ASSIGNMENT_REF) || ',';
					v_CSV := v_CSV ||
							 TO_CSV(v_PRO(v_pro_row).REASSIGNED_REF) || ',';
					v_CSV := v_CSV || TO_CSV(v_DAT(v_dat_row).RELATED_REF) || ',';
					v_CSV := v_CSV || TO_CSV(v_DAT(v_dat_row).SALE_REF) || ',';
					v_CSV := v_CSV || TO_CSV(v_DAT(v_dat_row).REQUEST_REF) || ',';
					v_CSV := v_CSV || TO_CSV(v_DAT(v_dat_row).DEAL_REF) || ',';
					v_CSV := v_CSV ||
							 TO_CSV(v_DAT(v_dat_row).COMPETING_REQUEST_FLAG) || ',';
					v_CSV := v_CSV ||
							 TO_CSV(v_DAT(v_dat_row).TIME_OF_LAST_UPDATE) ||
							 g_CRLF;

					v_data_rows := v_data_rows + 1;

				END LOOP; -- profile
			END LOOP; -- data

		END IF;

		-- add header with count
		-- count is sum total of all profile_table rows within all the data_table rows

		FOR idx IN 1 .. transstatus_query_elements.COUNT LOOP
			IF idx < transstatus_query_elements.COUNT THEN
				v_columns := v_columns || transstatus_query_elements(idx) || ',';
			ELSE
				v_columns := v_columns || transstatus_query_elements(idx);
			END IF;
		END LOOP;
		v_column_headers := v_columns;

		-- header row
		p_CSV := input_hdr_elements(1) || '=';
		p_CSV := p_CSV || TO_CSV(g_version, g_FLOAT_5_1_FORMAT) || g_CRLF;
		p_CSV := p_CSV || input_hdr_elements(2) || '=';
		p_CSV := p_CSV || TO_CSV(v_template) || g_CRLF;
		p_CSV := p_CSV || input_hdr_elements(3) || '=';
		p_CSV := p_CSV || TO_CSV(g_output_format) || g_CRLF;
		p_CSV := p_CSV || input_hdr_elements(4) || '=';
		p_CSV := p_CSV || TO_CSV(p_TAB.PRIMARY_PROVIDER_CODE) || g_CRLF;
		p_CSV := p_CSV || input_hdr_elements(5) || '=';
		p_CSV := p_CSV ||
				 TO_CSV(p_TAB.PRIMARY_PROVIDER_DUNS, g_NUMBER_9_FORMAT) ||
				 g_CRLF;
		p_CSV := p_CSV || input_hdr_elements(6) || '=';
		p_CSV := p_CSV || TO_CSV(g_EXCHANGE_TZ) || g_CRLF;
		p_CSV := p_CSV || input_hdr_elements(7) || '=';
		p_CSV := p_CSV || TO_CSV(v_data_rows) || g_CRLF;
		p_CSV := p_CSV || input_hdr_elements(8) || '=';
		p_CSV := p_CSV || v_column_headers || g_CRLF;
		p_CSV := p_CSV || v_CSV; -- append data/profile rows

	EXCEPTION
		WHEN OTHERS THEN
			p_LOGGER.LOG_ERROR('Error in CREATE_TRANSSTATUS_QUERY: ' || SQLERRM);
			RAISE;
	END CREATE_TRANSSTATUS_QUERY;
	--------------------------------------------------------------------------------------------------------------
	PROCEDURE PARSE_TRANSSELL_RESPONSE
		(
		p_CSV     IN CLOB,
		p_LOGGER IN OUT NOCOPY MM_LOGGER_ADAPTER,
		p_TAB     OUT MEX_OASIS_TRANS
		) IS

		v_error         CONSTANT VARCHAR2(40) := 'Error in PARSE_TRANSSELL_RESPONSE: ';
		v_template      CONSTANT VARCHAR2(20) := 'transsell';
		v_element_count CONSTANT NUMBER(3) := 20;
		v_line_count NUMBER := 0;

		v_LINES          PARSE_UTIL.BIG_STRING_TABLE_MP;
		v_COLS           PARSE_UTIL.STRING_TABLE;
		v_IDX            BINARY_INTEGER;
		v_delim          VARCHAR2(1);
		v_PRO            MEX_OASIS_TRANS_PROFILE_TBL := MEX_OASIS_TRANS_PROFILE_TBL();
		v_DAT            MEX_OASIS_TRANS_DATA_TBL := MEX_OASIS_TRANS_DATA_TBL();
		v_data           MEX_OASIS_TRANS_DATA;
		v_profile        MEX_OASIS_TRANS_PROFILE;
		v_request_status NUMBER(3);
		v_error_message  VARCHAR2(250);

	BEGIN

		PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_CSV, v_LINES);
		v_IDX   := v_LINES.FIRST;
		v_delim := '='; -- header
		p_TAB   := MEX_OASIS_TRANS(NULL, NULL, NULL, NULL, NULL);

		v_line_count := v_LINES.COUNT;

		WHILE v_LINES.EXISTS(v_IDX) LOOP

			parse_util.PARSE_DELIMITED_STRING(v_LINES(v_IDX),
											v_delim,
											v_COLS);

			-- each line contains key=value for the header
			-- then each line contains the series of attributes
			IF v_IDX < 12 THEN

				validate_response(v_COLS,
								  v_IDX,
								  v_error,
								  v_template,
								  v_request_status,
								  v_error_message,
								  v_delim,
								  v_line_count,
								  p_TAB);

			ELSE
				-- process data rows
				IF v_COLS.COUNT != v_element_count THEN
					p_LOGGER.LOG_ERROR(v_error ||
								 'wrong number of data elements in response, found ' ||
								 TO_CHAR(v_COLS.COUNT) || ' but ' ||
								 TO_CHAR(v_element_count) || ' required');
					RETURN;
				END IF;
				-- transsell_response

				-- continuation_flag
				IF v_COLS(2) = 'N' THEN

					IF v_PRO.COUNT > 0 THEN
						-- save previous data row containing profile_table
						v_data.PROFILE_TABLE := v_PRO;
						v_DAT.EXTEND;
						v_DAT(v_DAT.LAST) := v_data;
						v_PRO.DELETE;
					END IF;

					-- start new data and profile records for a non-continuation row

					v_profile := g_default_profile;
					v_data    := g_default_data;

					v_profile.START_TIME            := CONVERT_DATE(v_COLS(3));
					v_profile.STOP_TIME             := CONVERT_DATE(v_COLS(4));
					v_profile.OFFER_PRICE           := CONVERT_NUMBER(v_COLS(5));
					v_profile.CAPACITY_GRANTED      := CONVERT_NUMBER(v_COLS(6));
					v_profile.REASSIGNED_REF        := v_COLS(16);
					v_profile.REASSIGNED_CAPACITY   := CONVERT_NUMBER(v_COLS(17));
					v_profile.REASSIGNED_START_TIME := CONVERT_DATE(v_COLS(18));
					v_profile.REASSIGNED_STOP_TIME  := CONVERT_DATE(v_COLS(19));

					v_PRO.EXTEND;
					v_PRO(v_PRO.LAST) := v_profile;

					v_data.RECORD_STATUS          := CONVERT_NUMBER(v_COLS(1));
					v_data.STATUS                 := v_COLS(7);
					v_data.STATUS_COMMENTS        := v_COLS(8);
					v_data.ANC_SVC_LINK           := v_COLS(9);
					v_data.ANC_SVC_REQ            := v_COLS(10);
					v_data.COMPETING_REQUEST_FLAG := v_COLS(11);
					v_data.NEGOTIATED_PRICE_FLAG  := v_COLS(12);
					v_data.SELLER_REF             := v_COLS(13);
					v_data.SELLER_COMMENTS        := v_COLS(14);
					v_data.RESPONSE_TIME_LIMIT    := CONVERT_DATE(v_COLS(15));
					v_data.ERROR_MESSAGE          := v_COLS(20);

				ELSIF v_COLS(2) = 'Y' THEN
					-- just extend the profile table

					v_profile.START_TIME            := CONVERT_DATE(v_COLS(3));
					v_profile.STOP_TIME             := CONVERT_DATE(v_COLS(4));
					v_profile.OFFER_PRICE           := CONVERT_NUMBER(v_COLS(5));
					v_profile.CAPACITY_GRANTED      := CONVERT_NUMBER(v_COLS(6));
					v_profile.REASSIGNED_REF        := v_COLS(16);
					v_profile.REASSIGNED_CAPACITY   := CONVERT_NUMBER(v_COLS(17));
					v_profile.REASSIGNED_START_TIME := CONVERT_DATE(v_COLS(18));
					v_profile.REASSIGNED_STOP_TIME  := CONVERT_DATE(v_COLS(19));

					v_PRO.EXTEND;
					v_PRO(v_PRO.LAST) := v_profile;

				ELSE
					-- error
					NULL;
				END IF;

			END IF;

			v_IDX := v_LINES.NEXT(v_IDX);

		END LOOP;

		-- save the last data (in case it was a continuation row)
		IF v_PRO.COUNT > 0 THEN
			-- save previous data row containing profile_table
			v_data.PROFILE_TABLE := v_PRO;
			v_DAT.EXTEND;
			v_DAT(v_DAT.LAST) := v_data;
			v_PRO.DELETE;
		END IF;

		-- assign the only record
		-- other attributes were assigned earlier
		p_TAB.DATA_TABLE := v_DAT;

		IF v_request_status != g_REQUEST_SUCCESS THEN
			p_LOGGER.LOG_ERROR(v_error || 'REQUEST_STATUS = ' ||
						 TO_CHAR(v_request_status) || ', ' ||
						 v_error_message);
		END IF;

	EXCEPTION
		WHEN OTHERS THEN
			p_LOGGER.LOG_ERROR(v_error || ':' || SQLERRM);
			RAISE;
	END PARSE_TRANSSELL_RESPONSE;
	--------------------------------------------------------------------------------------------------------------
	PROCEDURE CREATE_TRANSSELL_INPUT(p_CSV     OUT CLOB,
									 p_TAB     IN MEX_OASIS_TRANS,
									 p_LOGGER IN OUT NOCOPY mm_logger_adapter) IS

		v_columns        VARCHAR2(2000);
		v_column_headers VARCHAR2(2000);
		v_template       VARCHAR2(20) := 'transsell';
		v_data_rows      NUMBER := 0;
		v_DAT            MEX_OASIS_TRANS_DATA_TBL;
		v_PRO            MEX_OASIS_TRANS_PROFILE_TBL;
		v_CSV            CLOB;

	BEGIN

		-- data rows
		v_DAT := p_TAB.DATA_TABLE;

		IF v_DAT IS NOT NULL THEN

			FOR v_dat_row IN v_DAT.FIRST .. v_DAT.LAST LOOP
				v_PRO := v_DAT(v_dat_row).PROFILE_TABLE;

				FOR v_pro_row IN v_PRO.FIRST .. v_PRO.LAST LOOP

					IF v_pro_row = 1 THEN

						v_CSV := v_CSV || 'N' || ',';
						v_CSV := v_CSV ||
								 TO_CSV(v_PRO(v_pro_row).ASSIGNMENT_REF) || ',';
						v_CSV := v_CSV ||
								 TO_CSV(v_PRO(v_pro_row).START_TIME) || ',';
						v_CSV := v_CSV ||
								 TO_CSV(v_PRO(v_pro_row).STOP_TIME) || ',';
						v_CSV := v_CSV ||
								 TO_CSV(v_PRO(v_pro_row).OFFER_PRICE) || ',';
						v_CSV := v_CSV ||
								 TO_CSV(v_PRO(v_pro_row).CAPACITY_GRANTED) || ',';
						v_CSV := v_CSV || TO_CSV(v_DAT(v_dat_row).STATUS) || ',';
						v_CSV := v_CSV ||
								 TO_CSV(v_DAT(v_dat_row).STATUS_COMMENTS) || ',';
						v_CSV := v_CSV ||
								 TO_CSV(v_DAT(v_dat_row).ANC_SVC_LINK) || ',';
						v_CSV := v_CSV ||
								 TO_CSV(v_DAT(v_dat_row).ANC_SVC_REQ) || ',';
						v_CSV := v_CSV ||
								 TO_CSV(v_DAT(v_dat_row)
										.COMPETING_REQUEST_FLAG) || ',';
						v_CSV := v_CSV ||
								 TO_CSV(v_DAT(v_dat_row)
										.NEGOTIATED_PRICE_FLAG) || ',';
						v_CSV := v_CSV ||
								 TO_CSV(v_DAT(v_dat_row).SELLER_REF) || ',';
						v_CSV := v_CSV ||
								 TO_CSV(v_DAT(v_dat_row).SELLER_COMMENTS) || ',';
						v_CSV := v_CSV ||
								 TO_CSV(v_DAT(v_dat_row)
										.RESPONSE_TIME_LIMIT) || ',';
						v_CSV := v_CSV ||
								 TO_CSV(v_PRO(v_pro_row).REASSIGNED_REF) || ',';
						v_CSV := v_CSV ||
								 TO_CSV(v_PRO(v_pro_row)
										.REASSIGNED_CAPACITY) || ',';
						v_CSV := v_CSV ||
								 TO_CSV(v_PRO(v_pro_row)
										.REASSIGNED_START_TIME) || ',';
						v_CSV := v_CSV ||
								 TO_CSV(v_PRO(v_pro_row)
										.REASSIGNED_STOP_TIME) || g_CRLF;

					ELSE

						v_CSV := v_CSV || 'Y' || ',';
						v_CSV := v_CSV ||
								 TO_CSV(v_PRO(v_pro_row).ASSIGNMENT_REF) || ',';
						v_CSV := v_CSV ||
								 TO_CSV(v_PRO(v_pro_row).START_TIME) || ',';
						v_CSV := v_CSV ||
								 TO_CSV(v_PRO(v_pro_row).STOP_TIME) || ',';
						v_CSV := v_CSV ||
								 TO_CSV(v_PRO(v_pro_row).OFFER_PRICE) || ',';
						v_CSV := v_CSV ||
								 TO_CSV(v_PRO(v_pro_row).CAPACITY_GRANTED) || ',';
						v_CSV := v_CSV || ',';
						v_CSV := v_CSV || ',';
						v_CSV := v_CSV || ',';
						v_CSV := v_CSV || ',';
						v_CSV := v_CSV || ',';
						v_CSV := v_CSV || ',';
						v_CSV := v_CSV || ',';
						v_CSV := v_CSV || ',';
						v_CSV := v_CSV || ',';
						v_CSV := v_CSV ||
								 TO_CSV(v_PRO(v_pro_row).REASSIGNED_REF) || ',';
						v_CSV := v_CSV ||
								 TO_CSV(v_PRO(v_pro_row)
										.REASSIGNED_CAPACITY) || ',';
						v_CSV := v_CSV ||
								 TO_CSV(v_PRO(v_pro_row)
										.REASSIGNED_START_TIME) || ',';
						v_CSV := v_CSV ||
								 TO_CSV(v_PRO(v_pro_row)
										.REASSIGNED_STOP_TIME) || g_CRLF;

					END IF;

					v_data_rows := v_data_rows + 1;

				END LOOP; -- profile
			END LOOP; -- data

		END IF;

		-- add header with count
		-- count is sum total of all profile_table rows within all the data_table rows

		FOR idx IN 1 .. transsell_input_elements.COUNT LOOP
			IF idx < transsell_input_elements.COUNT THEN
				v_columns := v_columns || transsell_input_elements(idx) || ',';
			ELSE
				v_columns := v_columns || transsell_input_elements(idx);
			END IF;
		END LOOP;
		v_column_headers := v_columns;

		-- header row
		p_CSV := input_hdr_elements(1) || '=';
		p_CSV := p_CSV || TO_CSV(g_version, g_FLOAT_5_1_FORMAT) || g_CRLF;
		p_CSV := p_CSV || input_hdr_elements(2) || '=';
		p_CSV := p_CSV || TO_CSV(v_template) || g_CRLF;
		p_CSV := p_CSV || input_hdr_elements(3) || '=';
		p_CSV := p_CSV || TO_CSV(g_output_format) || g_CRLF;
		p_CSV := p_CSV || input_hdr_elements(4) || '=';
		p_CSV := p_CSV || TO_CSV(p_TAB.PRIMARY_PROVIDER_CODE) || g_CRLF;
		p_CSV := p_CSV || input_hdr_elements(5) || '=';
		p_CSV := p_CSV ||
				 TO_CSV(p_TAB.PRIMARY_PROVIDER_DUNS, g_NUMBER_9_FORMAT) ||
				 g_CRLF;
		p_CSV := p_CSV || input_hdr_elements(6) || '=';
		p_CSV := p_CSV || TO_CSV(g_EXCHANGE_TZ) || g_CRLF;
		p_CSV := p_CSV || input_hdr_elements(7) || '=';
		p_CSV := p_CSV || TO_CSV(v_data_rows) || g_CRLF;
		p_CSV := p_CSV || input_hdr_elements(8) || '=';
		p_CSV := p_CSV || v_column_headers || g_CRLF;
		p_CSV := p_CSV || v_CSV; -- append data/profile rows

	EXCEPTION
		WHEN OTHERS THEN
			p_LOGGER.LOG_ERROR('Error in CREATE_TRANSSELL_INPUT: ' || SQLERRM);
			RAISE;
	END CREATE_TRANSSELL_INPUT;
	--------------------------------------------------------------------------------------------------------------
	PROCEDURE PARSE_TRANSCUST_RESPONSE
		(
		p_CSV     IN CLOB,
		p_LOGGER IN OUT NOCOPY MM_LOGGER_ADAPTER,
		p_TAB     OUT MEX_OASIS_TRANS
		) IS

		v_error         CONSTANT VARCHAR2(40) := 'Error in PARSE_TRANSCUST_RESPONSE: ';
		v_template      CONSTANT VARCHAR2(20) := 'transcust';
		v_element_count CONSTANT NUMBER(3) := 15;
		v_line_count NUMBER := 0;

		v_LINES          PARSE_UTIL.BIG_STRING_TABLE_MP;
		v_COLS           PARSE_UTIL.STRING_TABLE;
		v_IDX            BINARY_INTEGER;
		v_delim          VARCHAR2(1);
		v_PRO            MEX_OASIS_TRANS_PROFILE_TBL := MEX_OASIS_TRANS_PROFILE_TBL();
		v_DAT            MEX_OASIS_TRANS_DATA_TBL := MEX_OASIS_TRANS_DATA_TBL();
		v_data           MEX_OASIS_TRANS_DATA;
		v_profile        MEX_OASIS_TRANS_PROFILE;
		v_request_status NUMBER(3);
		v_error_message  VARCHAR2(250);

	BEGIN

		PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_CSV, v_LINES);
		v_IDX   := v_LINES.FIRST;
		v_delim := '='; -- header
		p_TAB   := MEX_OASIS_TRANS(NULL, NULL, NULL, NULL, NULL);

		v_line_count := V_LINES.COUNT;

		WHILE v_LINES.EXISTS(v_IDX) LOOP

			parse_util.PARSE_DELIMITED_STRING(v_LINES(v_IDX),
											v_delim,
											v_COLS);

			-- each line contains key=value for the header
			-- then each line contains the series of attributes
			IF v_IDX < 12 THEN

				validate_response(v_COLS,
								  v_IDX,
								  v_error,
								  v_template,
								  v_request_status,
								  v_error_message,
								  v_delim,
								  v_line_count,
								  p_TAB);
			ELSE
				-- process data rows
				IF v_COLS.COUNT != v_element_count THEN
					p_LOGGER.LOG_ERROR(v_error ||
								 'wrong number of data elements in response, found ' ||
								 TO_CHAR(v_COLS.COUNT) || ' but ' ||
								 TO_CHAR(v_element_count) || ' required');
					RETURN;
				END IF;
				-- transcust_response

				-- continuation_flag
				IF v_COLS(2) = 'N' THEN

					IF v_PRO.COUNT > 0 THEN
						-- save previous data row containing profile_table
						v_data.PROFILE_TABLE := v_PRO;
						v_DAT.EXTEND;
						v_DAT(v_DAT.LAST) := v_data;
						v_PRO.DELETE;
					END IF;

					-- start new data and profile records for a non-continuation row

					v_profile := g_default_profile;
					v_data    := g_default_data;

					v_profile.ASSIGNMENT_REF    := v_COLS(3);
					v_profile.START_TIME        := CONVERT_DATE(v_COLS(4));
					v_profile.STOP_TIME         := CONVERT_DATE(v_COLS(5));
					v_profile.BID_PRICE         := CONVERT_NUMBER(v_COLS(8));
					v_profile.CUSTOMER_COMMENTS := v_COLS(14);

					v_PRO.EXTEND;
					v_PRO(v_PRO.LAST) := v_profile;

					v_data.RECORD_STATUS       := CONVERT_NUMBER(v_COLS(1));
					v_data.REQUEST_REF         := v_COLS(6);
					v_data.DEAL_REF            := v_COLS(7);
					v_data.PRECONFIRMED        := v_COLS(9);
					v_data.STATUS              := v_COLS(10);
					v_data.STATUS_COMMENTS     := v_COLS(11);
					v_data.ANC_SVC_LINK        := v_COLS(12);
					v_data.STATUS_NOTIFICATION := v_COLS(13);
					v_data.ERROR_MESSAGE       := v_COLS(15);

				ELSIF v_COLS(2) = 'Y' THEN
					-- just extend the profile table

					v_profile.ASSIGNMENT_REF    := v_COLS(3);
					v_profile.START_TIME        := CONVERT_DATE(v_COLS(4));
					v_profile.STOP_TIME         := CONVERT_DATE(v_COLS(5));
					v_profile.BID_PRICE         := CONVERT_NUMBER(v_COLS(8));
					v_profile.CUSTOMER_COMMENTS := v_COLS(14);

					v_PRO.EXTEND;
					v_PRO(v_PRO.LAST) := v_profile;

				ELSE
					-- error
					NULL;
				END IF;

			END IF;

			v_IDX := v_LINES.NEXT(v_IDX);

		END LOOP;

		-- save the last data (in case it was a continuation row)
		IF v_PRO.COUNT > 0 THEN
			-- save previous data row containing profile_table
			v_data.PROFILE_TABLE := v_PRO;
			v_DAT.EXTEND;
			v_DAT(v_DAT.LAST) := v_data;
			v_PRO.DELETE;
		END IF;

		-- assign the only record
		-- other attributes were assigned earlier
		p_TAB.DATA_TABLE := v_DAT;

		IF v_request_status != g_REQUEST_SUCCESS THEN
			p_LOGGER.LOG_ERROR(v_error || 'REQUEST_STATUS = ' ||
						 TO_CHAR(v_request_status) || ', ' ||
						 v_error_message);
		END IF;

	EXCEPTION
		WHEN OTHERS THEN
			p_LOGGER.LOG_ERROR(v_error || ':' || SQLERRM);
			RAISE;
	END PARSE_TRANSCUST_RESPONSE;
	--------------------------------------------------------------------------------------------------------------
	PROCEDURE CREATE_TRANSCUST_INPUT(p_CSV     OUT CLOB,
									 p_TAB     IN MEX_OASIS_TRANS,
									 p_LOGGER  IN OUT NOCOPY mm_logger_adapter) IS

		v_columns        VARCHAR2(2000);
		v_column_headers VARCHAR2(2000);
		v_template       VARCHAR2(20) := 'transcust';
		v_data_rows      NUMBER := 0;
		v_DAT            MEX_OASIS_TRANS_DATA_TBL;
		v_PRO            MEX_OASIS_TRANS_PROFILE_TBL;
		v_CSV            CLOB;

	BEGIN

		-- data rows
		v_DAT := p_TAB.DATA_TABLE;

		IF v_DAT IS NOT NULL THEN

			FOR v_dat_row IN v_DAT.FIRST .. v_DAT.LAST LOOP
				v_PRO := v_DAT(v_dat_row).PROFILE_TABLE;

				FOR v_pro_row IN v_PRO.FIRST .. v_PRO.LAST LOOP

					IF v_pro_row = 1 THEN

						v_CSV := v_CSV || 'N' || ',';
						v_CSV := v_CSV ||
								 TO_CSV(v_PRO(v_pro_row).ASSIGNMENT_REF) || ',';
						v_CSV := v_CSV ||
								 TO_CSV(v_PRO(v_pro_row).START_TIME) || ',';
						v_CSV := v_CSV ||
								 TO_CSV(v_PRO(v_pro_row).STOP_TIME) || ',';
						v_CSV := v_CSV ||
								 TO_CSV(v_DAT(v_dat_row).REQUEST_REF) || ',';
						v_CSV := v_CSV || TO_CSV(v_DAT(v_dat_row).DEAL_REF) || ',';
						v_CSV := v_CSV ||
								 TO_CSV(v_PRO(v_pro_row).BID_PRICE,
										g_FLOAT_9_4_FORMAT) || ',';
						v_CSV := v_CSV ||
								 TO_CSV(v_DAT(v_dat_row).PRECONFIRMED) || ',';
						v_CSV := v_CSV || TO_CSV(v_DAT(v_dat_row).STATUS) || ',';
						v_CSV := v_CSV ||
								 TO_CSV(v_DAT(v_dat_row).STATUS_COMMENTS) || ',';
						v_CSV := v_CSV ||
								 TO_CSV(v_DAT(v_dat_row).ANC_SVC_LINK) || ',';
						v_CSV := v_CSV ||
								 TO_CSV(v_DAT(v_dat_row)
										.STATUS_NOTIFICATION) || ',';
						v_CSV := v_CSV ||
								 TO_CSV(v_PRO(v_pro_row).CUSTOMER_COMMENTS) ||
								 g_CRLF;

					ELSE

						v_CSV := v_CSV || 'Y' || ',';
						v_CSV := v_CSV || ',';
						v_CSV := v_CSV ||
								 TO_CSV(v_PRO(v_pro_row).START_TIME) || ',';
						v_CSV := v_CSV ||
								 TO_CSV(v_PRO(v_pro_row).STOP_TIME) || ',';
						v_CSV := v_CSV || ',';
						v_CSV := v_CSV || ',';
						v_CSV := v_CSV ||
								 TO_CSV(v_PRO(v_pro_row).BID_PRICE,
										g_FLOAT_9_4_FORMAT) || ',';
						v_CSV := v_CSV || ',';
						v_CSV := v_CSV || ',';
						v_CSV := v_CSV || ',';
						v_CSV := v_CSV || ',';
						v_CSV := v_CSV || ',';
						v_CSV := v_CSV || g_CRLF;

					END IF;

					v_data_rows := v_data_rows + 1;

				END LOOP; -- profile
			END LOOP; -- data

		END IF;

		-- add header with count
		-- count is sum total of all profile_table rows within all the data_table rows

		FOR idx IN 1 .. transcust_input_elements.COUNT LOOP
			IF idx < transcust_input_elements.COUNT THEN
				v_columns := v_columns || transcust_input_elements(idx) || ',';
			ELSE
				v_columns := v_columns || transcust_input_elements(idx);
			END IF;
		END LOOP;
		v_column_headers := v_columns;

		-- header row
		p_CSV := input_hdr_elements(1) || '=';
		p_CSV := p_CSV || TO_CSV(g_version, g_FLOAT_5_1_FORMAT) || g_CRLF;
		p_CSV := p_CSV || input_hdr_elements(2) || '=';
		p_CSV := p_CSV || TO_CSV(v_template) || g_CRLF;
		p_CSV := p_CSV || input_hdr_elements(3) || '=';
		p_CSV := p_CSV || TO_CSV(g_output_format) || g_CRLF;
		p_CSV := p_CSV || input_hdr_elements(4) || '=';
		p_CSV := p_CSV || TO_CSV(p_TAB.PRIMARY_PROVIDER_CODE) || g_CRLF;
		p_CSV := p_CSV || input_hdr_elements(5) || '=';
		p_CSV := p_CSV ||
				 TO_CSV(p_TAB.PRIMARY_PROVIDER_DUNS, g_NUMBER_9_FORMAT) ||
				 g_CRLF;
		p_CSV := p_CSV || input_hdr_elements(6) || '=';
		p_CSV := p_CSV || TO_CSV(g_EXCHANGE_TZ) || g_CRLF;
		p_CSV := p_CSV || input_hdr_elements(7) || '=';
		p_CSV := p_CSV || TO_CSV(v_data_rows) || g_CRLF;
		p_CSV := p_CSV || input_hdr_elements(8) || '=';
		p_CSV := p_CSV || v_column_headers || g_CRLF;
		p_CSV := p_CSV || v_CSV; -- append data/profile rows

	EXCEPTION
		WHEN OTHERS THEN
			p_LOGGER.LOG_ERROR('Error in CREATE_TRANSCUST_INPUT: ' || SQLERRM);
			RAISE;
	END CREATE_TRANSCUST_INPUT;
	--------------------------------------------------------------------------------------------------------------
	PROCEDURE PARSE_TRANSASSIGN_RESPONSE
		(
		p_CSV     IN CLOB,
		p_LOGGER IN OUT NOCOPY MM_LOGGER_ADAPTER,
		p_TAB     OUT MEX_OASIS_TRANS) IS

		v_error         CONSTANT VARCHAR2(40) := 'Error in PARSE_TRANSASSIGN_RESPONSE: ';
		v_template      CONSTANT VARCHAR2(20) := 'transassign';
		v_element_count CONSTANT NUMBER(3) := 29;
		v_line_count NUMBER := 0;

		v_LINES          PARSE_UTIL.BIG_STRING_TABLE_MP;
		v_COLS           PARSE_UTIL.STRING_TABLE;
		v_IDX            BINARY_INTEGER;
		v_delim          VARCHAR2(1);
		v_PRO            MEX_OASIS_TRANS_PROFILE_TBL := MEX_OASIS_TRANS_PROFILE_TBL();
		v_DAT            MEX_OASIS_TRANS_DATA_TBL := MEX_OASIS_TRANS_DATA_TBL();
		v_data           MEX_OASIS_TRANS_DATA;
		v_profile        MEX_OASIS_TRANS_PROFILE;
		v_request_status NUMBER(3);
		v_error_message  VARCHAR2(250);

	BEGIN

		PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_CSV, v_LINES);
		v_IDX   := v_LINES.FIRST;
		v_delim := '='; -- header
		p_TAB   := MEX_OASIS_TRANS(NULL, NULL, NULL, NULL, NULL);

		v_line_count := v_LINES.COUNT;

		WHILE v_LINES.EXISTS(v_IDX) LOOP

			parse_util.PARSE_DELIMITED_STRING(v_LINES(v_IDX),
											v_delim,
											v_COLS);

			-- each line contains key=value for the header
			-- then each line contains the series of attributes
			IF v_IDX < 12 THEN

				validate_response(v_COLS,
								  v_IDX,
								  v_error,
								  v_template,
								  v_request_status,
								  v_error_message,
								  v_delim,
								  v_line_count,
								  p_TAB);

			ELSE
				-- process data rows
				IF v_COLS.COUNT != v_element_count THEN
					p_LOGGER.LOG_ERROR(v_error ||
								 'wrong number of data elements in response, found ' ||
								 TO_CHAR(v_COLS.COUNT) || ' but ' ||
								 TO_CHAR(v_element_count) || ' required');
					RETURN;
				END IF;
				-- transassign_response

				-- continuation_flag
				IF v_COLS(2) = 'N' THEN

					IF v_PRO.COUNT > 0 THEN
						-- save previous data row containing profile_table
						v_data.PROFILE_TABLE := v_PRO;
						v_DAT.EXTEND;
						v_DAT(v_DAT.LAST) := v_data;
						v_PRO.DELETE;
					END IF;

					-- start new data and profile records for a non-continuation row

					v_profile := g_default_profile;
					v_data    := g_default_data;

					v_data.RECORD_STATUS     := CONVERT_NUMBER(v_COLS(1));
					v_data.CUSTOMER_CODE     := v_COLS(3);
					v_data.CUSTOMER_DUNS     := CONVERT_NUMBER(v_COLS(4));
					v_data.SOURCE            := v_COLS(8);
					v_data.SINK              := v_COLS(9);
					v_data.SERVICE_INCREMENT := v_COLS(12);
					v_data.TS_CLASS          := v_COLS(13);
					v_data.TS_TYPE           := v_COLS(14);
					v_data.TS_PERIOD         := v_COLS(15);
					v_data.TS_WINDOW         := v_COLS(16);
					v_data.TS_SUBCLASS       := v_COLS(17);
					v_data.ANC_SVC_LINK      := v_COLS(21);
					v_data.POSTING_NAME      := v_COLS(22);
					v_data.SELLER_COMMENTS   := v_COLS(27);
					v_data.SELLER_REF        := v_COLS(28);
					v_data.ERROR_MESSAGE     := v_COLS(29);

					v_profile.PATH_NAME             := v_COLS(5);
					v_profile.POINT_OF_RECEIPT      := v_COLS(6);
					v_profile.POINT_OF_DELIVERY     := v_COLS(7);
					v_profile.CAPACITY_REQUESTED    := CONVERT_NUMBER(v_COLS(10));
					v_profile.CAPACITY_GRANTED      := CONVERT_NUMBER(v_COLS(11));
					v_profile.START_TIME            := CONVERT_DATE(v_COLS(18), v_data.SERVICE_INCREMENT);
					v_profile.STOP_TIME             := CONVERT_DATE(v_COLS(19), v_data.SERVICE_INCREMENT);
					v_profile.OFFER_PRICE           := CONVERT_NUMBER(v_COLS(20));
					v_profile.REASSIGNED_REF        := v_COLS(23);
					v_profile.REASSIGNED_CAPACITY   := CONVERT_NUMBER(v_COLS(24));
					v_profile.REASSIGNED_START_TIME := CONVERT_DATE(v_COLS(25), v_data.SERVICE_INCREMENT);
					v_profile.REASSIGNED_STOP_TIME  := CONVERT_DATE(v_COLS(26), v_data.SERVICE_INCREMENT);

					v_PRO.EXTEND;
					v_PRO(v_PRO.LAST) := v_profile;

				ELSIF v_COLS(2) = 'Y' THEN
					-- just extend the profile table

					v_profile.PATH_NAME             := v_COLS(5);
					v_profile.POINT_OF_RECEIPT      := v_COLS(6);
					v_profile.POINT_OF_DELIVERY     := v_COLS(7);
					v_profile.CAPACITY_REQUESTED    := CONVERT_NUMBER(v_COLS(10));
					v_profile.CAPACITY_GRANTED      := CONVERT_NUMBER(v_COLS(11));
					v_profile.START_TIME            := CONVERT_DATE(v_COLS(18), v_data.SERVICE_INCREMENT);
					v_profile.STOP_TIME             := CONVERT_DATE(v_COLS(19), v_data.SERVICE_INCREMENT);
					v_profile.OFFER_PRICE           := CONVERT_NUMBER(v_COLS(20));
					v_profile.REASSIGNED_REF        := v_COLS(23);
					v_profile.REASSIGNED_CAPACITY   := CONVERT_NUMBER(v_COLS(24));
					v_profile.REASSIGNED_START_TIME := CONVERT_DATE(v_COLS(25), v_data.SERVICE_INCREMENT);
					v_profile.REASSIGNED_STOP_TIME  := CONVERT_DATE(v_COLS(26), v_data.SERVICE_INCREMENT);

					v_PRO.EXTEND;
					v_PRO(v_PRO.LAST) := v_profile;

				ELSE
					-- error
					NULL;
				END IF;

			END IF;

			v_IDX := v_LINES.NEXT(v_IDX);

		END LOOP;

		-- save the last data (in case it was a continuation row)
		IF v_PRO.COUNT > 0 THEN
			-- save previous data row containing profile_table
			v_data.PROFILE_TABLE := v_PRO;
			v_DAT.EXTEND;
			v_DAT(v_DAT.LAST) := v_data;
			v_PRO.DELETE;
		END IF;

		-- assign the only record
		-- other attributes were assigned earlier
		p_TAB.DATA_TABLE := v_DAT;

		IF v_request_status != g_REQUEST_SUCCESS THEN
			p_LOGGER.LOG_ERROR(v_error || 'REQUEST_STATUS = ' ||
						 TO_CHAR(v_request_status) || ', ' ||
						 v_error_message);
		END IF;

	EXCEPTION
		WHEN OTHERS THEN
			p_LOGGER.LOG_ERROR(v_error || ':' || SQLERRM);
			RAISE;
	END PARSE_TRANSASSIGN_RESPONSE;
	--------------------------------------------------------------------------------------------------------------
	PROCEDURE CREATE_TRANSASSIGN_INPUT(p_CSV     OUT CLOB,
									   p_TAB     IN MEX_OASIS_TRANS,
									   p_LOGGER  IN OUT NOCOPY mm_logger_adapter) IS

		v_columns        VARCHAR2(2000);
		v_column_headers VARCHAR2(2000);
		v_template       VARCHAR2(20) := 'transassign';
		v_data_rows      NUMBER := 0;
		v_DAT            MEX_OASIS_TRANS_DATA_TBL;
		v_PRO            MEX_OASIS_TRANS_PROFILE_TBL;
		v_CSV            CLOB;

	BEGIN
		-- data rows
		v_DAT := p_TAB.DATA_TABLE;

		IF v_DAT IS NOT NULL THEN

			FOR v_dat_row IN v_DAT.FIRST .. v_DAT.LAST LOOP
				v_PRO := v_DAT(v_dat_row).PROFILE_TABLE;

				FOR v_pro_row IN v_PRO.FIRST .. v_PRO.LAST LOOP

					IF v_pro_row = 1 THEN

						v_CSV := v_CSV || 'N' || ',';
						v_CSV := v_CSV ||
								 TO_CSV(v_DAT(v_dat_row).CUSTOMER_CODE) || ',';
						v_CSV := v_CSV ||
								 TO_CSV(v_DAT(v_dat_row).CUSTOMER_DUNS,
										g_NUMBER_9_FORMAT) || ',';
						v_CSV := v_CSV ||
								 TO_CSV(v_PRO(v_pro_row).PATH_NAME) || ',';
						v_CSV := v_CSV ||
								 TO_CSV(v_PRO(v_pro_row).POINT_OF_RECEIPT) || ',';
						v_CSV := v_CSV ||
								 TO_CSV(v_PRO(v_pro_row).POINT_OF_DELIVERY) || ',';
						v_CSV := v_CSV || TO_CSV(v_DAT(v_dat_row).SOURCE) || ',';
						v_CSV := v_CSV || TO_CSV(v_DAT(v_dat_row).SINK) || ',';
						v_CSV := v_CSV ||
								 TO_CSV(v_PRO(v_pro_row).CAPACITY_REQUESTED) || ',';
						v_CSV := v_CSV ||
								 TO_CSV(v_PRO(v_pro_row).CAPACITY_GRANTED) || ',';
						v_CSV := v_CSV ||
								 TO_CSV(v_DAT(v_dat_row).SERVICE_INCREMENT) || ',';
						v_CSV := v_CSV || TO_CSV(v_DAT(v_dat_row).TS_CLASS) || ',';
						v_CSV := v_CSV || TO_CSV(v_DAT(v_dat_row).TS_TYPE) || ',';
						v_CSV := v_CSV ||
								 TO_CSV(v_DAT(v_dat_row).TS_PERIOD) || ',';
						v_CSV := v_CSV ||
								 TO_CSV(v_DAT(v_dat_row).TS_WINDOW) || ',';
						v_CSV := v_CSV ||
								 TO_CSV(v_DAT(v_dat_row).TS_SUBCLASS) || ',';
						v_CSV := v_CSV ||
								 TO_CSV(v_PRO(v_pro_row).START_TIME) || ',';
						v_CSV := v_CSV ||
								 TO_CSV(v_PRO(v_pro_row).STOP_TIME) || ',';
						v_CSV := v_CSV ||
								 TO_CSV(v_PRO(v_pro_row).OFFER_PRICE,
										g_FLOAT_9_4_FORMAT) || ',';
						v_CSV := v_CSV ||
								 TO_CSV(v_DAT(v_dat_row).ANC_SVC_LINK) || ',';
						v_CSV := v_CSV ||
								 TO_CSV(v_DAT(v_dat_row).POSTING_REF) || ',';
						v_CSV := v_CSV ||
								 TO_CSV(v_PRO(v_pro_row).REASSIGNED_REF) || ',';
						v_CSV := v_CSV ||
								 TO_CSV(v_PRO(v_pro_row)
										.REASSIGNED_CAPACITY) || ',';
						v_CSV := v_CSV ||
								 TO_CSV(v_PRO(v_pro_row)
										.REASSIGNED_START_TIME) || ',';
						v_CSV := v_CSV ||
								 TO_CSV(v_PRO(v_pro_row)
										.REASSIGNED_STOP_TIME) || ',';
						v_CSV := v_CSV ||
								 TO_CSV(v_DAT(v_dat_row).SELLER_COMMENTS) || ',';
						v_CSV := v_CSV ||
								 TO_CSV(v_DAT(v_dat_row).SELLER_REF) ||
								 g_CRLF;

					ELSE

						v_CSV := v_CSV || 'Y' || ',';
						v_CSV := v_CSV || ',';
						v_CSV := v_CSV || ',';
						v_CSV := v_CSV || ',';
						v_CSV := v_CSV || ',';
						v_CSV := v_CSV || ',';
						v_CSV := v_CSV || ',';
						v_CSV := v_CSV || ',';
						v_CSV := v_CSV ||
								 TO_CSV(v_PRO(v_pro_row).CAPACITY_REQUESTED) || ',';
						v_CSV := v_CSV ||
								 TO_CSV(v_PRO(v_pro_row).CAPACITY_GRANTED) || ',';
						v_CSV := v_CSV || ',';
						v_CSV := v_CSV || ',';
						v_CSV := v_CSV || ',';
						v_CSV := v_CSV || ',';
						v_CSV := v_CSV || ',';
						v_CSV := v_CSV || ',';
						v_CSV := v_CSV ||
								 TO_CSV(v_PRO(v_pro_row).START_TIME) || ',';
						v_CSV := v_CSV ||
								 TO_CSV(v_PRO(v_pro_row).STOP_TIME) || ',';
						v_CSV := v_CSV || ',';
						v_CSV := v_CSV || ',';
						v_CSV := v_CSV || ',';
						v_CSV := v_CSV ||
								 TO_CSV(v_PRO(v_pro_row).REASSIGNED_REF) || ',';
						v_CSV := v_CSV ||
								 TO_CSV(v_PRO(v_pro_row)
										.REASSIGNED_CAPACITY) || ',';
						v_CSV := v_CSV ||
								 TO_CSV(v_PRO(v_pro_row)
										.REASSIGNED_START_TIME) || ',';
						v_CSV := v_CSV ||
								 TO_CSV(v_PRO(v_pro_row)
										.REASSIGNED_STOP_TIME) || ',';
						v_CSV := v_CSV || ',';
						v_CSV := v_CSV || g_CRLF;

					END IF;

					v_data_rows := v_data_rows + 1;

				END LOOP; -- profile
			END LOOP; -- data

		END IF;

		-- add header with count
		-- count is sum total of all profile_table rows within all the data_table rows

		FOR idx IN 1 .. transassign_input_elements.COUNT LOOP
			IF idx < transassign_input_elements.COUNT THEN
				v_columns := v_columns || transassign_input_elements(idx) || ',';
			ELSE
				v_columns := v_columns || transassign_input_elements(idx);
			END IF;
		END LOOP;
		v_column_headers := v_columns;

		-- header row
		p_CSV := input_hdr_elements(1) || '=';
		p_CSV := p_CSV || TO_CSV(g_version, g_FLOAT_5_1_FORMAT) || g_CRLF;
		p_CSV := p_CSV || input_hdr_elements(2) || '=';
		p_CSV := p_CSV || TO_CSV(v_template) || g_CRLF;
		p_CSV := p_CSV || input_hdr_elements(3) || '=';
		p_CSV := p_CSV || TO_CSV(g_output_format) || g_CRLF;
		p_CSV := p_CSV || input_hdr_elements(4) || '=';
		p_CSV := p_CSV || TO_CSV(p_TAB.PRIMARY_PROVIDER_CODE) || g_CRLF;
		p_CSV := p_CSV || input_hdr_elements(5) || '=';
		p_CSV := p_CSV ||
				 TO_CSV(p_TAB.PRIMARY_PROVIDER_DUNS, g_NUMBER_9_FORMAT) ||
				 g_CRLF;
		p_CSV := p_CSV || input_hdr_elements(6) || '=';
		p_CSV := p_CSV || TO_CSV(g_EXCHANGE_TZ) || g_CRLF;
		p_CSV := p_CSV || input_hdr_elements(7) || '=';
		p_CSV := p_CSV || TO_CSV(v_data_rows) || g_CRLF;
		p_CSV := p_CSV || input_hdr_elements(8) || '=';
		p_CSV := p_CSV || v_column_headers || g_CRLF;
		p_CSV := p_CSV || v_CSV; -- append data/profile rows

	EXCEPTION
		WHEN OTHERS THEN
			p_LOGGER.LOG_ERROR('Error in CREATE_TRANSASSIGN_INPUT: ' || SQLERRM);
			RAISE;
	END CREATE_TRANSASSIGN_INPUT;
	--------------------------------------------------------------------------------------------------------------
	PROCEDURE PARSE_TRANSPOST_RESPONSE
		(
		p_CSV     IN CLOB,
		p_LOGGER IN OUT NOCOPY MM_LOGGER_ADAPTER,
		p_TAB     OUT MEX_OASIS_TRANS
		) IS

		v_error         CONSTANT VARCHAR2(40) := 'Error in PARSE_TRANSPOST_RESPONSE: ';
		v_template      CONSTANT VARCHAR2(20) := 'transpost';
		v_element_count CONSTANT NUMBER(3) := 23;
		v_line_count NUMBER := 0;

		v_LINES          PARSE_UTIL.BIG_STRING_TABLE_MP;
		v_COLS           PARSE_UTIL.STRING_TABLE;
		v_IDX            BINARY_INTEGER;
		v_delim          VARCHAR2(1);
		v_PRO            MEX_OASIS_TRANS_PROFILE_TBL := MEX_OASIS_TRANS_PROFILE_TBL();
		v_DAT            MEX_OASIS_TRANS_DATA_TBL := MEX_OASIS_TRANS_DATA_TBL();
		v_data           MEX_OASIS_TRANS_DATA;
		v_profile        MEX_OASIS_TRANS_PROFILE;
		v_request_status NUMBER(3);
		v_error_message  VARCHAR2(250);

	BEGIN

		PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_CSV, v_LINES);
		v_IDX   := v_LINES.FIRST;
		v_delim := '='; -- header
		p_TAB   := MEX_OASIS_TRANS(NULL, NULL, NULL, NULL, NULL);

		v_line_count := v_LINES.COUNT;

		WHILE v_LINES.EXISTS(v_IDX) LOOP

			parse_util.PARSE_DELIMITED_STRING(v_LINES(v_IDX),
											v_delim,
											v_COLS);

			-- each line contains key=value for the header
			-- then each line contains the series of attributes
			IF v_IDX < 12 THEN

				validate_response(v_COLS,
								  v_IDX,
								  v_error,
								  v_template,
								  v_request_status,
								  v_error_message,
								  v_delim,
								  v_line_count,
								  p_TAB);
			ELSE
				-- process data rows
				IF v_COLS.COUNT != v_element_count THEN
					p_LOGGER.LOG_ERROR(v_error ||
								 'wrong number of data elements in response, found ' ||
								 TO_CHAR(v_COLS.COUNT) || ' but ' ||
								 TO_CHAR(v_element_count) || ' required');
					RETURN;
				END IF;
				-- transpost_response

				-- no continuation flag is used

				IF v_PRO.COUNT > 0 THEN
					-- save previous data row containing profile_table
					v_data.PROFILE_TABLE := v_PRO;
					v_DAT.EXTEND;
					v_DAT(v_DAT.LAST) := v_data;
					v_PRO.DELETE;
				END IF;

				-- start new data and profile records for a non-continuation row

				v_profile := g_default_profile;
				v_data    := g_default_data;

				v_profile.PATH_NAME         := v_COLS(3);
				v_profile.POINT_OF_RECEIPT  := v_COLS(4);
				v_profile.POINT_OF_DELIVERY := v_COLS(5);
				v_profile.CAPACITY          := CONVERT_NUMBER(v_COLS(7));
				v_profile.START_TIME        := CONVERT_DATE(v_COLS(15));
				v_profile.STOP_TIME         := CONVERT_DATE(v_COLS(16));
				v_profile.OFFER_PRICE       := CONVERT_NUMBER(v_COLS(20));

				v_PRO.EXTEND;
				v_PRO(v_PRO.LAST) := v_profile;

				v_data.RECORD_STATUS       := v_COLS(1);
				v_data.POSTING_REF         := v_COLS(2);
				v_data.INTERFACE_TYPE      := v_COLS(6);
				v_data.SERVICE_INCREMENT   := v_COLS(8);
				v_data.TS_CLASS            := v_COLS(9);
				v_data.TS_TYPE             := v_COLS(10);
				v_data.TS_PERIOD           := v_COLS(11);
				v_data.TS_WINDOW           := v_COLS(12);
				v_data.TS_SUBCLASS         := v_COLS(13);
				v_data.ANC_SVC_REQ         := v_COLS(14);
				v_data.OFFER_START_TIME    := CONVERT_DATE(v_COLS(17));
				v_data.OFFER_STOP_TIME     := CONVERT_DATE(v_COLS(18));
				v_data.SALE_REF            := v_COLS(19);
				v_data.SERVICE_DESCRIPTION := v_COLS(21);
				v_data.SELLER_COMMENTS     := v_COLS(22);
				v_data.ERROR_MESSAGE       := v_COLS(23);

			END IF;

			v_IDX := v_LINES.NEXT(v_IDX);

		END LOOP;

		-- save the last data
		IF v_PRO.COUNT > 0 THEN
			-- save previous data row containing profile_table
			v_data.PROFILE_TABLE := v_PRO;
			v_DAT.EXTEND;
			v_DAT(v_DAT.LAST) := v_data;
			v_PRO.DELETE;
		END IF;

		-- assign the only record
		-- other attributes were assigned earlier
		p_TAB.DATA_TABLE := v_DAT;

		IF v_request_status != g_REQUEST_SUCCESS THEN
			p_LOGGER.LOG_ERROR(v_error || 'REQUEST_STATUS = ' ||
						 TO_CHAR(v_request_status) || ', ' ||
						 v_error_message);
		END IF;

	EXCEPTION
		WHEN OTHERS THEN
			p_LOGGER.LOG_ERROR(v_error || ':' || SQLERRM);
			RAISE;
	END PARSE_TRANSPOST_RESPONSE;
	--------------------------------------------------------------------------------------------------------------
	PROCEDURE CREATE_TRANSPOST_INPUT(p_CSV     OUT CLOB,
									 p_TAB     IN MEX_OASIS_TRANS,
									 p_LOGGER  IN OUT NOCOPY mm_logger_adapter) IS

		v_columns        VARCHAR2(2000);
		v_column_headers VARCHAR2(2000);
		v_template       VARCHAR2(20) := 'transpost';
		v_data_rows      NUMBER := 0;
		v_DAT            MEX_OASIS_TRANS_DATA_TBL;
		v_PRO            MEX_OASIS_TRANS_PROFILE_TBL;
		v_CSV            CLOB;

	BEGIN

		-- data rows
		v_DAT := p_TAB.DATA_TABLE;

		IF v_DAT IS NOT NULL THEN

			FOR v_dat_row IN v_DAT.FIRST .. v_DAT.LAST LOOP
				v_PRO := v_DAT(v_dat_row).PROFILE_TABLE;

				FOR v_pro_row IN v_PRO.FIRST .. v_PRO.LAST LOOP

					v_CSV := v_CSV || TO_CSV(v_PRO(v_pro_row).PATH_NAME) || ',';
					v_CSV := v_CSV ||
							 TO_CSV(v_PRO(v_pro_row).POINT_OF_RECEIPT) || ',';
					v_CSV := v_CSV ||
							 TO_CSV(v_PRO(v_pro_row).POINT_OF_DELIVERY) || ',';
					v_CSV := v_CSV ||
							 TO_CSV(v_DAT(v_dat_row).INTERFACE_TYPE) || ',';
					v_CSV := v_CSV || TO_CSV(v_PRO(v_pro_row).CAPACITY) || ',';
					v_CSV := v_CSV ||
							 TO_CSV(v_DAT(v_dat_row).SERVICE_INCREMENT) || ',';
					v_CSV := v_CSV || TO_CSV(v_DAT(v_dat_row).TS_CLASS) || ',';
					v_CSV := v_CSV || TO_CSV(v_DAT(v_dat_row).TS_TYPE) || ',';
					v_CSV := v_CSV || TO_CSV(v_DAT(v_dat_row).TS_PERIOD) || ',';
					v_CSV := v_CSV || TO_CSV(v_DAT(v_dat_row).TS_WINDOW) || ',';
					v_CSV := v_CSV || TO_CSV(v_DAT(v_dat_row).TS_SUBCLASS) || ',';
					v_CSV := v_CSV || TO_CSV(v_DAT(v_dat_row).ANC_SVC_REQ) || ',';
					v_CSV := v_CSV || TO_CSV(v_PRO(v_pro_row).START_TIME) || ',';
					v_CSV := v_CSV || TO_CSV(v_PRO(v_pro_row).STOP_TIME) || ',';
					v_CSV := v_CSV ||
							 TO_CSV(v_DAT(v_dat_row).OFFER_START_TIME) || ',';
					v_CSV := v_CSV ||
							 TO_CSV(v_DAT(v_dat_row).OFFER_STOP_TIME) || ',';
					v_CSV := v_CSV || TO_CSV(v_DAT(v_dat_row).SALE_REF) || ',';
					v_CSV := v_CSV || TO_CSV(v_PRO(v_pro_row).OFFER_PRICE,
											 g_FLOAT_9_4_FORMAT) || ',';
					v_CSV := v_CSV ||
							 TO_CSV(v_DAT(v_dat_row).SERVICE_DESCRIPTION) || ',';
					v_CSV := v_CSV ||
							 TO_CSV(v_DAT(v_dat_row).SELLER_COMMENTS) ||
							 g_CRLF;

					v_data_rows := v_data_rows + 1;

				END LOOP; -- profile
			END LOOP; -- data

		END IF;

		-- add header with count
		-- count is sum total of all profile_table rows within all the data_table rows

		FOR idx IN 1 .. transpost_input_elements.COUNT LOOP
			IF idx < transpost_input_elements.COUNT THEN
				v_columns := v_columns || transpost_input_elements(idx) || ',';
			ELSE
				v_columns := v_columns || transpost_input_elements(idx);
			END IF;
		END LOOP;
		v_column_headers := v_columns;

		-- header row
		p_CSV := input_hdr_elements(1) || '=';
		p_CSV := p_CSV || TO_CSV(g_version, g_FLOAT_5_1_FORMAT) || g_CRLF;
		p_CSV := p_CSV || input_hdr_elements(2) || '=';
		p_CSV := p_CSV || TO_CSV(v_template) || g_CRLF;
		p_CSV := p_CSV || input_hdr_elements(3) || '=';
		p_CSV := p_CSV || TO_CSV(g_output_format) || g_CRLF;
		p_CSV := p_CSV || input_hdr_elements(4) || '=';
		p_CSV := p_CSV || TO_CSV(p_TAB.PRIMARY_PROVIDER_CODE) || g_CRLF;
		p_CSV := p_CSV || input_hdr_elements(5) || '=';
		p_CSV := p_CSV ||
				 TO_CSV(p_TAB.PRIMARY_PROVIDER_DUNS, g_NUMBER_9_FORMAT) ||
				 g_CRLF;
		p_CSV := p_CSV || input_hdr_elements(6) || '=';
		p_CSV := p_CSV || TO_CSV(g_EXCHANGE_TZ) || g_CRLF;
		p_CSV := p_CSV || input_hdr_elements(7) || '=';
		p_CSV := p_CSV || TO_CSV(v_data_rows) || g_CRLF;
		p_CSV := p_CSV || input_hdr_elements(8) || '=';
		p_CSV := p_CSV || v_column_headers || g_CRLF;
		p_CSV := p_CSV || v_CSV; -- append data/profile rows

	EXCEPTION
		WHEN OTHERS THEN
			p_LOGGER.LOG_ERROR('Error in CREATE_TRANSPOST_INPUT: ' || SQLERRM);
			RAISE;
	END CREATE_TRANSPOST_INPUT;
	--------------------------------------------------------------------------------------------------------------
	PROCEDURE PARSE_TRANSUPDATE_RESPONSE
		(
		p_CSV     IN CLOB,
		p_LOGGER IN OUT NOCOPY MM_LOGGER_ADAPTER,
		p_TAB     OUT MEX_OASIS_TRANS
		) IS

		v_error         CONSTANT VARCHAR2(40) := 'Error in PARSE_TRANSUPDATE_RESPONSE: ';
		v_template      CONSTANT VARCHAR2(20) := 'transupdate';
		v_element_count CONSTANT NUMBER(3) := 13;
		v_line_count NUMBER := 0;

		v_LINES          PARSE_UTIL.BIG_STRING_TABLE_MP;
		v_COLS           PARSE_UTIL.STRING_TABLE;
		v_IDX            BINARY_INTEGER;
		v_delim          VARCHAR2(1);
		v_PRO            MEX_OASIS_TRANS_PROFILE_TBL := MEX_OASIS_TRANS_PROFILE_TBL();
		v_DAT            MEX_OASIS_TRANS_DATA_TBL := MEX_OASIS_TRANS_DATA_TBL();
		v_data           MEX_OASIS_TRANS_data;
		v_profile        MEX_OASIS_TRANS_PROFILE;
		v_request_status NUMBER(3);
		v_error_message  VARCHAR2(250);

	BEGIN

		PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_CSV, v_LINES);
		v_IDX   := v_LINES.FIRST;
		v_delim := '='; -- header
		p_TAB   := MEX_OASIS_TRANS(NULL, NULL, NULL, NULL, NULL);

		v_line_count := v_LINES.COUNT;

		WHILE v_LINES.EXISTS(v_IDX) LOOP

			parse_util.PARSE_DELIMITED_STRING(v_LINES(v_IDX),
											v_delim,
											v_COLS);

			-- each line contains key=value for the header
			-- then each line contains the series of attributes
			IF v_IDX < 12 THEN

				validate_response(v_COLS,
								  v_IDX,
								  v_error,
								  v_template,
								  v_request_status,
								  v_error_message,
								  v_delim,
								  v_line_count,
								  p_TAB);
			ELSE
				-- process data rows
				IF v_COLS.COUNT != v_element_count THEN
					p_LOGGER.LOG_ERROR(v_error ||
								 'wrong number of data elements in response, found ' ||
								 TO_CHAR(v_COLS.COUNT) || ' but ' ||
								 TO_CHAR(v_element_count) || ' required');
					RETURN;
				END IF;
				-- transupdate_response

				-- no continuation flag is used

				IF v_PRO.COUNT > 0 THEN
					-- save previous data row containing profile_table
					v_data.PROFILE_TABLE := v_PRO;
					v_DAT.EXTEND;
					v_DAT(v_DAT.LAST) := v_data;
					v_PRO.DELETE;
				END IF;

				-- start new data and profile records for a non-continuation row

				v_profile := g_default_profile;
				v_data    := g_default_data;

				v_profile.CAPACITY    := CONVERT_NUMBER(v_COLS(3));
				v_profile.START_TIME  := CONVERT_DATE(v_COLS(4));
				v_profile.STOP_TIME   := CONVERT_DATE(v_COLS(5));
				v_profile.OFFER_PRICE := CONVERT_NUMBER(v_COLS(10));

				v_PRO.EXTEND;
				v_PRO(v_PRO.LAST) := v_profile;

				v_data.RECORD_STATUS       := v_COLS(1);
				v_data.POSTING_REF         := v_COLS(2);
				v_data.OFFER_START_TIME    := CONVERT_DATE(v_COLS(6));
				v_data.OFFER_STOP_TIME     := CONVERT_DATE(v_COLS(7));
				v_data.ANC_SVC_REQ         := v_COLS(8);
				v_data.SALE_REF            := v_COLS(9);
				v_data.SERVICE_DESCRIPTION := v_COLS(11);
				v_data.SELLER_COMMENTS     := v_COLS(12);
				v_data.ERROR_MESSAGE       := v_COLS(13);

			END IF;

			v_IDX := v_LINES.NEXT(v_IDX);

		END LOOP;

		-- save the last data
		IF v_PRO.COUNT > 0 THEN
			-- save previous data row containing profile_table
			v_data.PROFILE_TABLE := v_PRO;
			v_DAT.EXTEND;
			v_DAT(v_DAT.LAST) := v_data;
			v_PRO.DELETE;
		END IF;

		-- assign the only record
		-- other attributes were assigned earlier
		p_TAB.DATA_TABLE := v_DAT;

		IF v_request_status != g_REQUEST_SUCCESS THEN
			p_LOGGER.LOG_ERROR(v_error || 'REQUEST_STATUS = ' ||
						 TO_CHAR(v_request_status) || ', ' ||
						 v_error_message);
		END IF;

	EXCEPTION
		WHEN OTHERS THEN
			p_LOGGER.LOG_ERROR(v_error || ':' ||SQLERRM);
			RAISE;
	END PARSE_TRANSUPDATE_RESPONSE;
	--------------------------------------------------------------------------------------------------------------
	PROCEDURE CREATE_TRANSUPDATE_INPUT(p_CSV     OUT CLOB,
									   p_TAB     IN MEX_OASIS_TRANS,
									   p_LOGGER  IN OUT NOCOPY mm_logger_adapter) IS

		v_columns        VARCHAR2(2000);
		v_column_headers VARCHAR2(2000);
		v_template       VARCHAR2(20) := 'transupdate';
		v_data_rows      NUMBER := 0;
		v_DAT            MEX_OASIS_TRANS_DATA_TBL;
		v_PRO            MEX_OASIS_TRANS_profile_tbl;
		v_CSV            CLOB;

	BEGIN

		-- data rows
		v_DAT := p_TAB.DATA_TABLE;

		IF v_DAT IS NOT NULL THEN

			FOR v_dat_row IN v_DAT.FIRST .. v_DAT.LAST LOOP
				v_PRO := v_DAT(v_dat_row).PROFILE_TABLE;

				FOR v_pro_row IN v_PRO.FIRST .. v_PRO.LAST LOOP

					v_CSV := v_CSV || TO_CSV(v_DAT(v_dat_row).POSTING_REF) || ',';
					v_CSV := v_CSV || TO_CSV(v_PRO(v_pro_row).CAPACITY) || ',';
					v_CSV := v_CSV || TO_CSV(v_PRO(v_pro_row).START_TIME) || ',';
					v_CSV := v_CSV || TO_CSV(v_PRO(v_pro_row).STOP_TIME) || ',';
					v_CSV := v_CSV ||
							 TO_CSV(v_DAT(v_dat_row).OFFER_START_TIME) || ',';
					v_CSV := v_CSV ||
							 TO_CSV(v_DAT(v_dat_row).OFFER_STOP_TIME) || ',';
					v_CSV := v_CSV || TO_CSV(v_DAT(v_dat_row).ANC_SVC_REQ) || ',';
					v_CSV := v_CSV || TO_CSV(v_DAT(v_dat_row).SALE_REF) || ',';
					v_CSV := v_CSV || TO_CSV(v_PRO(v_pro_row).OFFER_PRICE,
											 g_FLOAT_9_4_FORMAT) || ',';
					v_CSV := v_CSV ||
							 TO_CSV(v_DAT(v_dat_row).SERVICE_DESCRIPTION) || ',';
					v_CSV := v_CSV ||
							 TO_CSV(v_DAT(v_dat_row).SELLER_COMMENTS) ||
							 g_CRLF;

					v_data_rows := v_data_rows + 1;

				END LOOP; -- profile
			END LOOP; -- data

		END IF;

		-- add header with count
		-- count is sum total of all profile_table rows within all the data_table rows

		FOR idx IN 1 .. transupdate_input_elements.COUNT LOOP
			IF idx < transupdate_input_elements.COUNT THEN
				v_columns := v_columns || transupdate_input_elements(idx) || ',';
			ELSE
				v_columns := v_columns || transupdate_input_elements(idx);
			END IF;
		END LOOP;
		v_column_headers := v_columns;

		-- header row
		p_CSV := input_hdr_elements(1) || '=';
		p_CSV := p_CSV || TO_CSV(g_version, g_FLOAT_5_1_FORMAT) || g_CRLF;
		p_CSV := p_CSV || input_hdr_elements(2) || '=';
		p_CSV := p_CSV || TO_CSV(v_template) || g_CRLF;
		p_CSV := p_CSV || input_hdr_elements(3) || '=';
		p_CSV := p_CSV || TO_CSV(g_output_format) || g_CRLF;
		p_CSV := p_CSV || input_hdr_elements(4) || '=';
		p_CSV := p_CSV || TO_CSV(p_TAB.PRIMARY_PROVIDER_CODE) || g_CRLF;
		p_CSV := p_CSV || input_hdr_elements(5) || '=';
		p_CSV := p_CSV ||
				 TO_CSV(p_TAB.PRIMARY_PROVIDER_DUNS, g_NUMBER_9_FORMAT) ||
				 g_CRLF;
		p_CSV := p_CSV || input_hdr_elements(6) || '=';
		p_CSV := p_CSV || TO_CSV(g_EXCHANGE_TZ) || g_CRLF;
		p_CSV := p_CSV || input_hdr_elements(7) || '=';
		p_CSV := p_CSV || TO_CSV(v_data_rows) || g_CRLF;
		p_CSV := p_CSV || input_hdr_elements(8) || '=';
		p_CSV := p_CSV || v_column_headers || g_CRLF;
		p_CSV := p_CSV || v_CSV; -- append data/profile rows

	EXCEPTION
		WHEN OTHERS THEN
			p_LOGGER.LOG_ERROR('Error in CREATE_TRANSUPDATE_INPUT: ' || SQLERRM);
			RAISE;
	END CREATE_TRANSUPDATE_INPUT;
	--------------------------------------------------------------------------------------------------------------
	PROCEDURE PARSE_ANCOFFER_RESPONSE
		(
		p_CSV     IN CLOB,
		p_LOGGER IN OUT NOCOPY MM_LOGGER_ADAPTER,
		p_TAB     OUT MEX_OASIS_TRANS
		) IS

		v_error         CONSTANT VARCHAR2(40) := 'Error in PARSE_ANCOFFER_RESPONSE: ';
		v_template      CONSTANT VARCHAR2(20) := 'ancoffering';
		v_element_count CONSTANT NUMBER(3) := 22;
		v_line_count NUMBER := 0;

		v_LINES          PARSE_UTIL.BIG_STRING_TABLE_MP;
		v_COLS           PARSE_UTIL.STRING_TABLE;
		v_IDX            BINARY_INTEGER;
		v_delim          VARCHAR2(1);
		v_PRO            MEX_OASIS_TRANS_PROFILE_TBL := MEX_OASIS_TRANS_PROFILE_TBL();
		v_DAT            MEX_OASIS_TRANS_DATA_TBL := MEX_OASIS_TRANS_DATA_TBL();
		v_data           MEX_OASIS_TRANS_DATA;
		v_profile        MEX_OASIS_TRANS_PROFILE;
		v_request_status NUMBER(3);
		v_error_message  VARCHAR2(250);

	BEGIN

		PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_CSV, v_LINES);
		v_IDX   := v_LINES.FIRST;
		v_delim := '='; -- header
		p_TAB   := MEX_OASIS_TRANS(NULL, NULL, NULL, NULL, NULL);

		v_line_count := v_LINES.COUNT;

		WHILE v_LINES.EXISTS(v_IDX) LOOP

			parse_util.PARSE_DELIMITED_STRING(v_LINES(v_IDX),
											v_delim,
											v_COLS);

			-- each line contains key=value for the header
			-- then each line contains the series of attributes
			IF v_IDX < 12 THEN

				validate_response(v_COLS,
								  v_IDX,
								  v_error,
								  v_template,
								  v_request_status,
								  v_error_message,
								  v_delim,
								  v_line_count,
								  p_TAB);
			ELSE
				-- process data rows
				IF v_COLS.COUNT != v_element_count THEN
					p_LOGGER.LOG_ERROR(v_error ||
								 'wrong number of data elements in response, found ' ||
								 TO_CHAR(v_COLS.COUNT) || ' but ' ||
								 TO_CHAR(v_element_count) || ' required');
					RETURN;
				END IF;
				-- ancoffer_response

				-- no continuation flag is used

				IF v_PRO.COUNT > 0 THEN
					-- save previous data row containing profile_table
					v_data.PROFILE_TABLE := v_PRO;
					v_DAT.EXTEND;
					v_DAT(v_DAT.LAST) := v_data;
					v_PRO.DELETE;
				END IF;

				-- start new data and profile records for a non-continuation row

				v_profile := g_default_profile;
				v_data    := g_default_data;

				v_profile.START_TIME  := CONVERT_DATE(v_COLS(7));
				v_profile.STOP_TIME   := CONVERT_DATE(v_COLS(8));
				v_profile.CAPACITY    := CONVERT_NUMBER(v_COLS(9));
				v_profile.OFFER_PRICE := CONVERT_NUMBER(v_COLS(15));

				v_PRO.EXTEND;
				v_PRO(v_PRO.LAST) := v_profile;

				v_data.TIME_OF_LAST_UPDATE := CONVERT_DATE(v_COLS(1));
				v_data.SELLER_CODE         := v_COLS(2);
				v_data.SELLER_DUNS         := CONVERT_NUMBER(v_COLS(3));
				v_data.CONTROL_AREA        := v_COLS(4);
				v_data.OFFER_START_TIME    := CONVERT_DATE(v_COLS(5));
				v_data.OFFER_STOP_TIME     := CONVERT_DATE(v_COLS(6));
				v_data.SERVICE_INCREMENT   := v_COLS(10);
				v_data.AS_TYPE             := v_COLS(11);
				v_data.SALE_REF            := v_COLS(12);
				v_data.POSTING_REF         := v_COLS(13);
				v_data.CEILING_PRICE       := CONVERT_NUMBER(v_COLS(14));
				v_data.PRICE_UNITS         := v_COLS(16);
				v_data.SERVICE_DESCRIPTION := v_COLS(17);
				v_data.SELLER_NAME         := v_COLS(18);
				v_data.SELLER_PHONE        := v_COLS(19);
				v_data.SELLER_FAX          := v_COLS(20);
				v_data.SELLER_EMAIL        := v_COLS(21);
				v_data.SELLER_COMMENTS     := v_COLS(22);

			END IF;

			v_IDX := v_LINES.NEXT(v_IDX);

		END LOOP;

		-- save the last data
		IF v_PRO.COUNT > 0 THEN
			-- save previous data row containing profile_table
			v_data.PROFILE_TABLE := v_PRO;
			v_DAT.EXTEND;
			v_DAT(v_DAT.LAST) := v_data;
			v_PRO.DELETE;
		END IF;

		-- assign the only record
		-- other attributes were assigned earlier
		p_TAB.DATA_TABLE := v_DAT;

		IF v_request_status != g_REQUEST_SUCCESS THEN
			p_LOGGER.LOG_ERROR(v_error || 'REQUEST_STATUS = ' ||
						 TO_CHAR(v_request_status) || ', ' ||
						 v_error_message);
		END IF;

	EXCEPTION
		WHEN OTHERS THEN
			p_LOGGER.LOG_ERROR(v_error || ':' || SQLERRM);
			RAISE;
	END PARSE_ANCOFFER_RESPONSE;
	--------------------------------------------------------------------------------------------------------------
	PROCEDURE CREATE_ANCOFFER_QUERY(p_CSV     OUT CLOB,
									p_TAB     IN MEX_OASIS_TRANS,
									p_STATUS  OUT NUMBER,
									P_MESSAGE OUT VARCHAR) IS

		v_columns        VARCHAR2(2000);
		v_column_headers VARCHAR2(2000);
		v_template       VARCHAR2(20) := 'ancoffering';
		v_data_rows      NUMBER := 0;
		v_DAT            MEX_OASIS_TRANS_data_tbl;
		v_PRO            MEX_OASIS_TRANS_PROFILE_TBL;
		v_CSV            CLOB;

	BEGIN

		p_STATUS  := g_SUCCESS;
		p_MESSAGE := '';

		-- data rows
		v_DAT := p_TAB.DATA_TABLE;

		IF v_DAT IS NOT NULL THEN

			FOR v_dat_row IN v_DAT.FIRST .. v_DAT.LAST LOOP
				v_PRO := v_DAT(v_dat_row).PROFILE_TABLE;

				FOR v_pro_row IN v_PRO.FIRST .. v_PRO.LAST LOOP

					v_CSV := v_CSV || TO_CSV(v_DAT(v_dat_row).SELLER_CODE) || ',';
					v_CSV := v_CSV || TO_CSV(v_DAT(v_dat_row).SELLER_DUNS,
											 g_NUMBER_9_FORMAT) || ',';
					v_CSV := v_CSV || TO_CSV(v_DAT(v_dat_row).CONTROL_AREA) || ',';
					v_CSV := v_CSV ||
							 TO_CSV(v_DAT(v_dat_row).SERVICE_INCREMENT) || ',';
					v_CSV := v_CSV || TO_CSV(v_DAT(v_dat_row).AS_TYPE) || ',';
					v_CSV := v_CSV || TO_CSV(v_PRO(v_pro_row).START_TIME) || ',';
					v_CSV := v_CSV || TO_CSV(v_PRO(v_pro_row).STOP_TIME) || ',';
					v_CSV := v_CSV || TO_CSV(v_DAT(v_dat_row).POSTING_REF) || ',';
					v_CSV := v_CSV ||
							 TO_CSV(v_DAT(v_dat_row).TIME_OF_LAST_UPDATE) ||
							 g_CRLF;

					v_data_rows := v_data_rows + 1;

				END LOOP; -- profile
			END LOOP; -- data

		END IF;

		-- add header with count
		-- count is sum total of all profile_table rows within all the data_table rows

		FOR idx IN 1 .. ancoffer_query_elements.COUNT LOOP
			IF idx < ancoffer_query_elements.COUNT THEN
				v_columns := v_columns || ancoffer_query_elements(idx) || ',';
			ELSE
				v_columns := v_columns || ancoffer_query_elements(idx);
			END IF;
		END LOOP;
		v_column_headers := v_columns;

		-- header row
		p_CSV := input_hdr_elements(1) || '=';
		p_CSV := p_CSV || TO_CSV(g_version, g_FLOAT_5_1_FORMAT) || g_CRLF;
		p_CSV := p_CSV || input_hdr_elements(2) || '=';
		p_CSV := p_CSV || TO_CSV(v_template) || g_CRLF;
		p_CSV := p_CSV || input_hdr_elements(3) || '=';
		p_CSV := p_CSV || TO_CSV(g_output_format) || g_CRLF;
		p_CSV := p_CSV || input_hdr_elements(4) || '=';
		p_CSV := p_CSV || TO_CSV(p_TAB.PRIMARY_PROVIDER_CODE) || g_CRLF;
		p_CSV := p_CSV || input_hdr_elements(5) || '=';
		p_CSV := p_CSV ||
				 TO_CSV(p_TAB.PRIMARY_PROVIDER_DUNS, g_NUMBER_9_FORMAT) ||
				 g_CRLF;
		p_CSV := p_CSV || input_hdr_elements(6) || '=';
		p_CSV := p_CSV || TO_CSV(g_EXCHANGE_TZ) || g_CRLF;
		p_CSV := p_CSV || input_hdr_elements(7) || '=';
		p_CSV := p_CSV || TO_CSV(v_data_rows) || g_CRLF;
		p_CSV := p_CSV || input_hdr_elements(8) || '=';
		p_CSV := p_CSV || v_column_headers || g_CRLF;
		p_CSV := p_CSV || v_CSV; -- append data/profile rows

	EXCEPTION
		WHEN OTHERS THEN
			p_STATUS  := SQLCODE;
			p_MESSAGE := 'Error in CREATE_ANCOFFER_QUERY: ' || SQLERRM;
	END CREATE_ANCOFFER_QUERY;
	--------------------------------------------------------------------------------------------------------------
	PROCEDURE PARSE_ANCREQUEST_RESPONSE
		(
		p_CSV     IN CLOB,
		p_LOGGER IN OUT NOCOPY mm_logger_adapter,
		p_TAB     OUT MEX_OASIS_TRANS
		) IS

		v_error         CONSTANT VARCHAR2(40) := 'Error in PARSE_ANCREQUEST_RESPONSE: ';
		v_template      CONSTANT VARCHAR2(20) := 'ancrequest';
		v_element_count CONSTANT NUMBER(3) := 21;
		v_line_count NUMBER := 0;

		v_LINES          PARSE_UTIL.BIG_STRING_TABLE_MP;
		v_COLS           PARSE_UTIL.STRING_TABLE;
		v_IDX            BINARY_INTEGER;
		v_delim          VARCHAR2(1);
		v_PRO            MEX_OASIS_TRANS_PROFILE_TBL := MEX_OASIS_TRANS_PROFILE_TBL();
		v_DAT            MEX_OASIS_TRANS_DATA_TBL := MEX_OASIS_TRANS_DATA_TBL();
		v_data           MEX_OASIS_TRANS_DATA;
		v_profile        MEX_OASIS_TRANS_PROFILE;
		v_request_status NUMBER(3);
		v_error_message  VARCHAR2(250);

	BEGIN

		PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_CSV, v_LINES);
		v_IDX   := v_LINES.FIRST;
		v_delim := '='; -- header
		p_TAB   := MEX_OASIS_TRANS(NULL, NULL, NULL, NULL, NULL);

		v_line_count := v_LINES.COUNT;

		WHILE v_LINES.EXISTS(v_IDX) LOOP

			parse_util.PARSE_DELIMITED_STRING(v_LINES(v_IDX),
											v_delim,
											v_COLS);

			-- each line contains key=value for the header
			-- then each line contains the series of attributes
			IF v_IDX < 12 THEN

				validate_response(v_COLS,
								  v_IDX,
								  v_error,
								  v_template,
								  v_request_status,
								  v_error_message,
								  v_delim,
								  v_line_count,
								  p_TAB);
			ELSE
				-- process data rows
				IF v_COLS.COUNT != v_element_count THEN
					p_LOGGER.LOG_ERROR(v_error ||
								 'wrong number of data elements in response, found ' ||
								 TO_CHAR(v_COLS.COUNT) || ' but ' ||
								 TO_CHAR(v_element_count) || ' required');
					RETURN;
				END IF;
				-- ancrequest_response

				-- continuation_flag
				IF v_COLS(2) = 'N' THEN

					IF v_PRO.COUNT > 0 THEN
						-- save previous data row containing profile_table
						v_data.PROFILE_TABLE := v_PRO;
						v_DAT.EXTEND;
						v_DAT(v_DAT.LAST) := v_data;
						v_PRO.DELETE;
					END IF;

					-- start new data and profile records for a non-continuation row

					v_profile := g_default_profile;
					v_data    := g_default_data;

					v_profile.ASSIGNMENT_REF    := v_COLS(3);
					v_profile.CAPACITY          := CONVERT_NUMBER(v_COLS(8));
					v_profile.START_TIME        := CONVERT_DATE(v_COLS(12));
					v_profile.STOP_TIME         := CONVERT_DATE(v_COLS(13));
					v_profile.BID_PRICE         := CONVERT_NUMBER(v_COLS(14));
					v_profile.CUSTOMER_COMMENTS := v_COLS(20);

					v_PRO.EXTEND;
					v_PRO(v_PRO.LAST) := v_profile;

					v_data.RECORD_STATUS       := CONVERT_NUMBER(v_COLS(1));
					v_data.SELLER_CODE         := v_COLS(4);
					v_data.SELLER_DUNS         := CONVERT_NUMBER(v_COLS(5));
					v_data.CONTROL_AREA        := v_COLS(6);
					v_data.ANC_SERVICE_POINT   := v_COLS(7);
					v_data.SERVICE_INCREMENT   := v_COLS(9);
					v_data.AS_TYPE             := v_COLS(10);
					v_data.STATUS_NOTIFICATION := v_COLS(11);
					v_data.PRECONFIRMED        := v_COLS(15);
					v_data.POSTING_REF         := v_COLS(16);
					v_data.SALE_REF            := v_COLS(17);
					v_data.REQUEST_REF         := v_COLS(18);
					v_data.DEAL_REF            := v_COLS(19);
					v_data.ERROR_MESSAGE       := v_COLS(21);

				ELSIF v_COLS(2) = 'Y' THEN
					-- just extend the profile table

					v_profile.ASSIGNMENT_REF    := v_COLS(3);
					v_profile.CAPACITY          := CONVERT_NUMBER(v_COLS(8));
					v_profile.START_TIME        := CONVERT_DATE(v_COLS(12));
					v_profile.STOP_TIME         := CONVERT_DATE(v_COLS(13));
					v_profile.BID_PRICE         := CONVERT_NUMBER(v_COLS(14));
					v_profile.CUSTOMER_COMMENTS := v_COLS(20);

					v_PRO.EXTEND;
					v_PRO(v_PRO.LAST) := v_profile;

				ELSE
					-- error
					NULL;
				END IF;

			END IF;

			v_IDX := v_LINES.NEXT(v_IDX);

		END LOOP;

		-- save the last data (in case it was a continuation row)
		IF v_PRO.COUNT > 0 THEN
			-- save previous data row containing profile_table
			v_data.PROFILE_TABLE := v_PRO;
			v_DAT.EXTEND;
			v_DAT(v_DAT.LAST) := v_data;
			v_PRO.DELETE;
		END IF;

		-- assign the only record
		-- other attributes were assigned earlier
		p_TAB.DATA_TABLE := v_DAT;

		IF v_request_status != g_REQUEST_SUCCESS THEN
			p_LOGGER.LOG_ERROR(v_error || 'REQUEST_STATUS = ' ||
						 TO_CHAR(v_request_status) || ', ' ||
						 v_error_message);
		END IF;

	EXCEPTION
		WHEN OTHERS THEN
			p_LOGGER.LOG_ERROR(v_error || ':' || SQLERRM);
			RAISE;
	END PARSE_ANCREQUEST_RESPONSE;
	--------------------------------------------------------------------------------------------------------------
	PROCEDURE CREATE_ANCREQUEST_INPUT(p_CSV     OUT CLOB,
									  p_TAB     IN MEX_OASIS_TRANS,
									  p_STATUS  OUT NUMBER,
									  P_MESSAGE OUT VARCHAR) IS

		v_columns        VARCHAR2(2000);
		v_column_headers VARCHAR2(2000);
		v_template       VARCHAR2(20) := 'ancrequest';
		v_data_rows      NUMBER := 0;
		v_DAT            MEX_OASIS_TRANS_DATA_TBL;
		v_PRO            MEX_OASIS_TRANS_PROFILE_TBL;
		v_CSV            CLOB;

	BEGIN

		p_STATUS  := g_SUCCESS;
		p_MESSAGE := '';

		-- data rows
		v_DAT := p_TAB.DATA_TABLE;

		IF v_DAT IS NOT NULL THEN

			FOR v_dat_row IN v_DAT.FIRST .. v_DAT.LAST LOOP
				v_PRO := v_DAT(v_dat_row).PROFILE_TABLE;

				FOR v_pro_row IN v_PRO.FIRST .. v_PRO.LAST LOOP

					IF v_pro_row = 1 THEN

						v_CSV := v_CSV || 'N' || ',';
						v_CSV := v_CSV ||
								 TO_CSV(v_DAT(v_dat_row).SELLER_CODE) || ',';
						v_CSV := v_CSV ||
								 TO_CSV(v_DAT(v_dat_row).SELLER_DUNS,
										g_NUMBER_9_FORMAT) || ',';
						v_CSV := v_CSV ||
								 TO_CSV(v_DAT(v_dat_row).CONTROL_AREA) || ',';
						v_CSV := v_CSV ||
								 TO_CSV(v_DAT(v_dat_row).ANC_SERVICE_POINT) || ',';
						v_CSV := v_CSV || TO_CSV(v_PRO(v_pro_row).CAPACITY) || ',';
						v_CSV := v_CSV ||
								 TO_CSV(v_DAT(v_dat_row).SERVICE_INCREMENT) || ',';
						v_CSV := v_CSV || TO_CSV(v_DAT(v_dat_row).AS_TYPE) || ',';
						v_CSV := v_CSV ||
								 TO_CSV(v_DAT(v_dat_row)
										.STATUS_NOTIFICATION) || ',';
						v_CSV := v_CSV ||
								 TO_CSV(v_PRO(v_pro_row).START_TIME) || ',';
						v_CSV := v_CSV ||
								 TO_CSV(v_PRO(v_pro_row).STOP_TIME) || ',';
						v_CSV := v_CSV ||
								 TO_CSV(v_PRO(v_pro_row).BID_PRICE,
										g_FLOAT_9_4_FORMAT) || ',';
						v_CSV := v_CSV ||
								 TO_CSV(v_DAT(v_dat_row).PRECONFIRMED) || ',';
						v_CSV := v_CSV ||
								 TO_CSV(v_DAT(v_dat_row).POSTING_REF) || ',';
						v_CSV := v_CSV || TO_CSV(v_DAT(v_dat_row).SALE_REF) || ',';
						v_CSV := v_CSV ||
								 TO_CSV(v_DAT(v_dat_row).REQUEST_REF) || ',';
						v_CSV := v_CSV || TO_CSV(v_DAT(v_dat_row).DEAL_REF) || ',';
						v_CSV := v_CSV ||
								 TO_CSV(v_PRO(v_pro_row).CUSTOMER_COMMENTS) ||
								 g_CRLF;

					ELSE

						v_CSV := v_CSV || 'Y' || ',';
						v_CSV := v_CSV || ',';
						v_CSV := v_CSV || ',';
						v_CSV := v_CSV || ',';
						v_CSV := v_CSV || ',';
						v_CSV := v_CSV || TO_CSV(v_PRO(v_pro_row).CAPACITY) || ',';
						v_CSV := v_CSV || ',';
						v_CSV := v_CSV || ',';
						v_CSV := v_CSV || ',';
						v_CSV := v_CSV ||
								 TO_CSV(v_PRO(v_pro_row).START_TIME) || ',';
						v_CSV := v_CSV ||
								 TO_CSV(v_PRO(v_pro_row).STOP_TIME) || ',';
						v_CSV := v_CSV ||
								 TO_CSV(v_PRO(v_pro_row).BID_PRICE,
										g_FLOAT_9_4_FORMAT) || ',';
						v_CSV := v_CSV || ',';
						v_CSV := v_CSV || ',';
						v_CSV := v_CSV || ',';
						v_CSV := v_CSV || ',';
						v_CSV := v_CSV || ',';
						v_CSV := v_CSV ||
								 TO_CSV(v_PRO(v_pro_row).CUSTOMER_COMMENTS) ||
								 g_CRLF;
					END IF;

					v_data_rows := v_data_rows + 1;

				END LOOP; -- profile
			END LOOP; -- data

		END IF;

		-- add header with count
		-- count is sum total of all profile_table rows within all the data_table rows

		FOR idx IN 1 .. ancrequest_input_elements.COUNT LOOP
			IF idx < ancrequest_input_elements.COUNT THEN
				v_columns := v_columns || ancrequest_input_elements(idx) || ',';
			ELSE
				v_columns := v_columns || ancrequest_input_elements(idx);
			END IF;
		END LOOP;
		v_column_headers := v_columns;

		-- header row
		p_CSV := input_hdr_elements(1) || '=';
		p_CSV := p_CSV || TO_CSV(g_version, g_FLOAT_5_1_FORMAT) || g_CRLF;
		p_CSV := p_CSV || input_hdr_elements(2) || '=';
		p_CSV := p_CSV || TO_CSV(v_template) || g_CRLF;
		p_CSV := p_CSV || input_hdr_elements(3) || '=';
		p_CSV := p_CSV || TO_CSV(g_output_format) || g_CRLF;
		p_CSV := p_CSV || input_hdr_elements(4) || '=';
		p_CSV := p_CSV || TO_CSV(p_TAB.PRIMARY_PROVIDER_CODE) || g_CRLF;
		p_CSV := p_CSV || input_hdr_elements(5) || '=';
		p_CSV := p_CSV ||
				 TO_CSV(p_TAB.PRIMARY_PROVIDER_DUNS, g_NUMBER_9_FORMAT) ||
				 g_CRLF;
		p_CSV := p_CSV || input_hdr_elements(6) || '=';
		p_CSV := p_CSV || TO_CSV(g_EXCHANGE_TZ) || g_CRLF;
		p_CSV := p_CSV || input_hdr_elements(7) || '=';
		p_CSV := p_CSV || TO_CSV(v_data_rows) || g_CRLF;
		p_CSV := p_CSV || input_hdr_elements(8) || '=';
		p_CSV := p_CSV || v_column_headers || g_CRLF;
		p_CSV := p_CSV || v_CSV; -- append data/profile rows

	EXCEPTION
		WHEN OTHERS THEN
			p_STATUS  := SQLCODE;
			p_MESSAGE := 'Error in CREATE_ANCREQUEST_INPUT: ' || SQLERRM;
	END CREATE_ANCREQUEST_INPUT;
	--------------------------------------------------------------------------------------------------------------
	PROCEDURE PARSE_ANCSTATUS_RESPONSE
		(
		p_CSV     IN CLOB,
		p_LOGGER IN OUT NOCOPY mm_logger_adapter,
		p_TAB     OUT MEX_OASIS_TRANS
		) IS

		v_error         CONSTANT VARCHAR2(40) := 'Error in PARSE_ANCSTATUS_RESPONSE:';
		v_template      CONSTANT VARCHAR2(20) := 'ancstatus';
		v_element_count CONSTANT NUMBER(3) := 45;
		v_line_count NUMBER := 0;

		v_LINES          PARSE_UTIL.BIG_STRING_TABLE_MP;
		v_COLS           PARSE_UTIL.STRING_TABLE;
		v_IDX            BINARY_INTEGER;
		v_delim          VARCHAR2(1);
		v_PRO            MEX_OASIS_TRANS_PROFILE_TBL := MEX_OASIS_TRANS_PROFILE_TBL();
		v_DAT            MEX_OASIS_TRANS_DATA_TBL := MEX_OASIS_TRANS_DATA_TBL();
		v_data           MEX_OASIS_TRANS_DATA;
		v_profile        MEX_OASIS_TRANS_PROFILE;
		v_request_status NUMBER(3);
		v_error_message  VARCHAR2(250);

	BEGIN

		PARSE_CLOB_INTO_LINES(p_CSV, v_LINES);
		v_IDX   := v_LINES.FIRST;
		v_delim := '='; -- header
		p_TAB   := MEX_OASIS_TRANS(NULL, NULL, NULL, NULL, NULL);

		v_line_count := v_LINES.COUNT;

		WHILE v_LINES.EXISTS(v_IDX) LOOP

			parse_util.PARSE_DELIMITED_STRING(v_LINES(v_IDX),
											v_delim,
											v_COLS);

			-- each line contains key=value for the header
			-- then each line contains the series of attributes
			IF v_IDX < 12 THEN

				validate_response(v_COLS,
								  v_IDX,
								  v_error,
								  v_template,
								  v_request_status,
								  v_error_message,
								  v_delim,
								  v_line_count,
								  p_TAB);
			ELSE
				-- process data rows
				IF v_COLS.COUNT != v_element_count THEN
					p_LOGGER.LOG_ERROR(v_error ||
								 'wrong number of data elements in response, found ' ||
								 TO_CHAR(v_COLS.COUNT) || ' but ' ||
								 TO_CHAR(v_element_count) || ' required');
					RETURN;
				END IF;
				-- ancstatus_response

				-- continuation_flag
				IF v_COLS(1) = 'N' THEN

					IF v_PRO.COUNT > 0 THEN
						-- save previous data row containing profile_table
						v_data.PROFILE_TABLE := v_PRO;
						v_DAT.EXTEND;
						v_DAT(v_DAT.LAST) := v_data;
						v_PRO.DELETE;
					END IF;

					-- start new data and profile records for a non-continuation row

					v_profile := g_default_profile;
					v_data    := g_default_data;

					v_data.RECORD_STATUS             := NULL;
					v_data.SELLER_CODE               := v_COLS(3);
					v_data.SELLER_DUNS               := CONVERT_NUMBER(v_COLS(4));
					v_data.CUSTOMER_CODE             := v_COLS(5);
					v_data.CUSTOMER_DUNS             := CONVERT_NUMBER(v_COLS(6));
					v_data.AFFILIATE_FLAG            := v_COLS(7);
					v_data.CONTROL_AREA              := v_COLS(8);
					v_data.ANC_SERVICE_POINT         := v_COLS(9);
					v_data.SERVICE_INCREMENT         := v_COLS(11);
					v_data.AS_TYPE                   := v_COLS(12);
					v_data.CEILING_PRICE             := CONVERT_NUMBER(v_COLS(15));
					v_data.PRICE_UNITS               := v_COLS(18);
					v_data.PRECONFIRMED              := v_COLS(19);
					v_data.POSTING_REF               := v_COLS(20);
					v_data.SALE_REF                  := v_COLS(21);
					v_data.REQUEST_REF               := v_COLS(22);
					v_data.DEAL_REF                  := v_COLS(23);
					v_data.NEGOTIATED_PRICE_FLAG     := v_COLS(24);
					v_data.STATUS                    := v_COLS(25);
					v_data.STATUS_NOTIFICATION       := v_COLS(26);
					v_data.STATUS_COMMENTS           := v_COLS(27);
					v_data.TIME_QUEUED               := CONVERT_DATE(v_COLS(28));
					v_data.RESPONSE_TIME_LIMIT       := CONVERT_DATE(v_COLS(29));
					v_data.TIME_OF_LAST_UPDATE       := CONVERT_DATE(v_COLS(30));
					v_data.PRIMARY_PROVIDER_COMMENTS := v_COLS(31);
					v_data.SELLER_COMMENTS           := v_COLS(32);
					v_data.SELLER_NAME               := v_COLS(34);
					v_data.SELLER_PHONE              := v_COLS(35);
					v_data.SELLER_FAX                := v_COLS(36);
					v_data.SELLER_EMAIL              := v_COLS(37);
					v_data.CUSTOMER_NAME             := v_COLS(38);
					v_data.CUSTOMER_PHONE            := v_COLS(39);
					v_data.CUSTOMER_FAX              := v_COLS(40);
					v_data.CUSTOMER_EMAIL            := v_COLS(41);

					v_profile.ASSIGNMENT_REF        := v_COLS(2);
					v_profile.CAPACITY              := CONVERT_NUMBER(v_COLS(10));
					v_profile.START_TIME            := CONVERT_DATE(v_COLS(13), v_data.SERVICE_INCREMENT);
					v_profile.STOP_TIME             := CONVERT_DATE(v_COLS(14), v_data.SERVICE_INCREMENT);
					v_profile.OFFER_PRICE           := CONVERT_NUMBER(v_COLS(16));
					v_profile.BID_PRICE             := CONVERT_NUMBER(v_COLS(17));
					v_profile.CUSTOMER_COMMENTS     := v_COLS(33);
					v_profile.REASSIGNED_REF        := v_COLS(42);
					v_profile.REASSIGNED_CAPACITY   := CONVERT_NUMBER(v_COLS(43));
					v_profile.REASSIGNED_START_TIME := CONVERT_DATE(v_COLS(44), v_data.SERVICE_INCREMENT);
					v_profile.REASSIGNED_STOP_TIME  := CONVERT_DATE(v_COLS(45), v_data.SERVICE_INCREMENT);

					v_PRO.EXTEND;
					v_PRO(v_PRO.LAST) := v_profile;

				ELSIF v_COLS(1) = 'Y' THEN
					-- just extend the profile table

					v_profile.ASSIGNMENT_REF        := v_COLS(2);
					v_profile.CAPACITY              := CONVERT_NUMBER(v_COLS(10));
					v_profile.START_TIME            := CONVERT_DATE(v_COLS(13), v_data.SERVICE_INCREMENT);
					v_profile.STOP_TIME             := CONVERT_DATE(v_COLS(14), v_data.SERVICE_INCREMENT);
					v_profile.OFFER_PRICE           := CONVERT_NUMBER(v_COLS(16));
					v_profile.BID_PRICE             := CONVERT_NUMBER(v_COLS(17));
					v_profile.CUSTOMER_COMMENTS     := v_COLS(33);
					v_profile.REASSIGNED_REF        := v_COLS(42);
					v_profile.REASSIGNED_CAPACITY   := CONVERT_NUMBER(v_COLS(43));
					v_profile.REASSIGNED_START_TIME := CONVERT_DATE(v_COLS(44), v_data.SERVICE_INCREMENT);
					v_profile.REASSIGNED_STOP_TIME  := CONVERT_DATE(v_COLS(45), v_data.SERVICE_INCREMENT);

					v_PRO.EXTEND;
					v_PRO(v_PRO.LAST) := v_profile;

				ELSE
					-- error
					NULL;
				END IF;

			END IF;

			v_IDX := v_LINES.NEXT(v_IDX);

		END LOOP;

		-- save the last data (in case it was a continuation row)
		IF v_PRO.COUNT > 0 THEN
			-- save previous data row containing profile_table
			v_data.PROFILE_TABLE := v_PRO;
			v_DAT.EXTEND;
			v_DAT(v_DAT.LAST) := v_data;
			v_PRO.DELETE;
		END IF;

		-- assign the only record
		-- other attributes were assigned earlier
		p_TAB.DATA_TABLE := v_DAT;

		IF v_request_status != g_REQUEST_SUCCESS THEN
			p_LOGGER.LOG_ERROR(v_error || 'REQUEST_STATUS = ' ||
						 TO_CHAR(v_request_status) || ', ' ||
						 v_error_message);
		END IF;

	EXCEPTION
		WHEN OTHERS THEN
			p_LOGGER.LOG_ERROR(v_error || ':' || SQLERRM);
			RAISE;
	END PARSE_ANCSTATUS_RESPONSE;
	--------------------------------------------------------------------------------------------------------------
	PROCEDURE CREATE_ANCSTATUS_QUERY(p_CSV     OUT CLOB,
									 p_TAB     IN MEX_OASIS_TRANS,
									 p_STATUS  OUT NUMBER,
									 P_MESSAGE OUT VARCHAR) IS

		v_columns        VARCHAR2(2000);
		v_column_headers VARCHAR2(2000);
		v_template       VARCHAR2(20) := 'ancstatus';
		v_data_rows      NUMBER := 0;
		v_DAT            MEX_OASIS_TRANS_DATA_TBL;
		v_PRO            MEX_OASIS_TRANS_PROFILE_TBL;
		v_CSV            CLOB;

	BEGIN

		p_STATUS  := g_SUCCESS;
		p_MESSAGE := '';

		-- data rows
		v_DAT := p_TAB.DATA_TABLE;

		IF v_DAT IS NOT NULL THEN

			FOR v_dat_row IN v_DAT.FIRST .. v_DAT.LAST LOOP
				v_PRO := v_DAT(v_dat_row).PROFILE_TABLE;

				FOR v_pro_row IN v_PRO.FIRST .. v_PRO.LAST LOOP

					v_CSV := v_CSV || TO_CSV(v_DAT(v_dat_row).SELLER_CODE) || ',';
					v_CSV := v_CSV || TO_CSV(v_DAT(v_dat_row).SELLER_DUNS,
											 g_NUMBER_9_FORMAT) || ',';
					v_CSV := v_CSV ||
							 TO_CSV(v_DAT(v_dat_row).CUSTOMER_CODE) || ',';
					v_CSV := v_CSV || TO_CSV(v_DAT(v_dat_row).CUSTOMER_DUNS,
											 g_NUMBER_9_FORMAT) || ',';
					v_CSV := v_CSV || TO_CSV(v_DAT(v_dat_row).CONTROL_AREA) || ',';
					v_CSV := v_CSV ||
							 TO_CSV(v_DAT(v_dat_row).ANC_SERVICE_POINT) || ',';
					v_CSV := v_CSV ||
							 TO_CSV(v_DAT(v_dat_row).SERVICE_INCREMENT) || ',';
					v_CSV := v_CSV || TO_CSV(v_DAT(v_dat_row).AS_TYPE) || ',';
					v_CSV := v_CSV || TO_CSV(v_DAT(v_dat_row).STATUS) || ',';
					v_CSV := v_CSV || TO_CSV(v_PRO(v_pro_row).START_TIME) || ',';
					v_CSV := v_CSV || TO_CSV(v_PRO(v_pro_row).STOP_TIME) || ',';
					v_CSV := v_CSV ||
							 TO_CSV(v_DAT(v_dat_row).START_TIME_QUEUED) || ',';
					v_CSV := v_CSV ||
							 TO_CSV(v_DAT(v_dat_row).STOP_TIME_QUEUED) || ',';
					v_CSV := v_CSV ||
							 TO_CSV(v_DAT(v_dat_row).NEGOTIATED_PRICE_FLAG) || ',';
					v_CSV := v_CSV ||
							 TO_CSV(v_PRO(v_pro_row).ASSIGNMENT_REF) || ',';
					v_CSV := v_CSV ||
							 TO_CSV(v_PRO(v_pro_row).REASSIGNED_REF) || ',';
					v_CSV := v_CSV || TO_CSV(v_DAT(v_dat_row).SALE_REF) || ',';
					v_CSV := v_CSV || TO_CSV(v_DAT(v_dat_row).REQUEST_REF) || ',';
					v_CSV := v_CSV || TO_CSV(v_DAT(v_dat_row).DEAL_REF) || ',';
					v_CSV := v_CSV ||
							 TO_CSV(v_DAT(v_dat_row).TIME_OF_LAST_UPDATE) ||
							 g_CRLF;

					v_data_rows := v_data_rows + 1;

				END LOOP; -- profile
			END LOOP; -- data

		END IF;

		-- add header with count
		-- count is sum total of all profile_table rows within all the data_table rows

		FOR idx IN 1 .. ancstatus_query_elements.COUNT LOOP
			IF idx < ancstatus_query_elements.COUNT THEN
				v_columns := v_columns || ancstatus_query_elements(idx) || ',';
			ELSE
				v_columns := v_columns || ancstatus_query_elements(idx);
			END IF;
		END LOOP;
		v_column_headers := v_columns;

		-- header row
		p_CSV := input_hdr_elements(1) || '=';
		p_CSV := p_CSV || TO_CSV(g_version, g_FLOAT_5_1_FORMAT) || g_CRLF;
		p_CSV := p_CSV || input_hdr_elements(2) || '=';
		p_CSV := p_CSV || TO_CSV(v_template) || g_CRLF;
		p_CSV := p_CSV || input_hdr_elements(3) || '=';
		p_CSV := p_CSV || TO_CSV(g_output_format) || g_CRLF;
		p_CSV := p_CSV || input_hdr_elements(4) || '=';
		p_CSV := p_CSV || TO_CSV(p_TAB.PRIMARY_PROVIDER_CODE) || g_CRLF;
		p_CSV := p_CSV || input_hdr_elements(5) || '=';
		p_CSV := p_CSV ||
				 TO_CSV(p_TAB.PRIMARY_PROVIDER_DUNS, g_NUMBER_9_FORMAT) ||
				 g_CRLF;
		p_CSV := p_CSV || input_hdr_elements(6) || '=';
		p_CSV := p_CSV || TO_CSV(g_EXCHANGE_TZ) || g_CRLF;
		p_CSV := p_CSV || input_hdr_elements(7) || '=';
		p_CSV := p_CSV || TO_CSV(v_data_rows) || g_CRLF;
		p_CSV := p_CSV || input_hdr_elements(8) || '=';
		p_CSV := p_CSV || v_column_headers || g_CRLF;
		p_CSV := p_CSV || v_CSV; -- append data/profile rows

	EXCEPTION
		WHEN OTHERS THEN
			p_STATUS  := SQLCODE;
			p_MESSAGE := 'Error in CREATE_ANCSTATUS_QUERY: ' || SQLERRM;
	END CREATE_ANCSTATUS_QUERY;
	--------------------------------------------------------------------------------------------------------------
	PROCEDURE PARSE_ANCSELL_RESPONSE
		(
		p_CSV     IN CLOB,
		p_LOGGER IN OUT NOCOPY mm_logger_adapter,
		p_TAB     OUT MEX_OASIS_TRANS
		) IS

		v_error         CONSTANT VARCHAR2(40) := 'Error in PARSE_ANCSELL_RESPONSE: ';
		v_template      CONSTANT VARCHAR2(20) := 'ancsell';
		v_element_count CONSTANT NUMBER(3) := 16;
		v_line_count NUMBER := 0;

		v_LINES          PARSE_UTIL.BIG_STRING_TABLE_MP;
		v_COLS           PARSE_UTIL.STRING_TABLE;
		v_IDX            BINARY_INTEGER;
		v_delim          VARCHAR2(1);
		v_PRO            MEX_OASIS_TRANS_PROFILE_TBL := MEX_OASIS_TRANS_PROFILE_TBL();
		v_DAT            MEX_OASIS_TRANS_DATA_TBL := MEX_OASIS_TRANS_DATA_TBL();
		v_data           MEX_OASIS_TRANS_DATA;
		v_profile        MEX_OASIS_TRANS_PROFILE;
		v_request_status NUMBER(3);
		v_error_message  VARCHAR2(250);

	BEGIN

		PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_CSV, v_LINES);
		v_IDX   := v_LINES.FIRST;
		v_delim := '='; -- header
		p_TAB   := MEX_OASIS_TRANS(NULL, NULL, NULL, NULL, NULL);

		v_line_count := v_LINES.COUNT;

		WHILE v_LINES.EXISTS(v_IDX) LOOP

			parse_util.PARSE_DELIMITED_STRING(v_LINES(v_IDX),
											v_delim,
											v_COLS);

			-- each line contains key=value for the header
			-- then each line contains the series of attributes
			IF v_IDX < 12 THEN

				validate_response(v_COLS,
								  v_IDX,
								  v_error,
								  v_template,
								  v_request_status,
								  v_error_message,
								  v_delim,
								  v_line_count,
								  p_TAB);
			ELSE
				-- process data rows
				IF v_COLS.COUNT != v_element_count THEN
					p_LOGGER.LOG_ERROR(v_error ||
								 'wrong number of data elements in response, found ' ||
								 TO_CHAR(v_COLS.COUNT) || ' but ' ||
								 TO_CHAR(v_element_count) || ' required');
					RETURN;
				END IF;
				-- ancsell_response

				-- continuation_flag
				IF v_COLS(2) = 'N' THEN

					IF v_PRO.COUNT > 0 THEN
						-- save previous data row containing profile_table
						v_data.PROFILE_TABLE := v_PRO;
						v_DAT.EXTEND;
						v_DAT(v_DAT.LAST) := v_data;
						v_PRO.DELETE;
					END IF;

					-- start new data and profile records for a non-continuation row

					v_profile := g_default_profile;
					v_data    := g_default_data;

					v_profile.ASSIGNMENT_REF        := v_COLS(3);
					v_profile.START_TIME            := CONVERT_DATE(v_COLS(4));
					v_profile.STOP_TIME             := CONVERT_DATE(v_COLS(5));
					v_profile.OFFER_PRICE           := CONVERT_NUMBER(v_COLS(6));
					v_profile.REASSIGNED_REF        := v_COLS(12);
					v_profile.REASSIGNED_CAPACITY   := CONVERT_NUMBER(v_COLS(13));
					v_profile.REASSIGNED_START_TIME := CONVERT_DATE(v_COLS(14));
					v_profile.REASSIGNED_STOP_TIME  := CONVERT_DATE(v_COLS(15));

					v_PRO.EXTEND;
					v_PRO(v_PRO.LAST) := v_profile;

					v_data.RECORD_STATUS         := CONVERT_NUMBER(v_COLS(1));
					v_data.STATUS                := v_COLS(7);
					v_data.STATUS_COMMENTS       := v_COLS(8);
					v_data.NEGOTIATED_PRICE_FLAG := v_COLS(9);
					v_data.RESPONSE_TIME_LIMIT   := CONVERT_DATE(v_COLS(10));
					v_data.SELLER_COMMENTS       := v_COLS(11);
					v_data.ERROR_MESSAGE         := v_COLS(16);

				ELSIF v_COLS(2) = 'Y' THEN
					-- just extend the profile table

					v_profile.ASSIGNMENT_REF        := v_COLS(3);
					v_profile.START_TIME            := CONVERT_DATE(v_COLS(4));
					v_profile.STOP_TIME             := CONVERT_DATE(v_COLS(5));
					v_profile.OFFER_PRICE           := CONVERT_NUMBER(v_COLS(6));
					v_profile.REASSIGNED_REF        := v_COLS(12);
					v_profile.REASSIGNED_CAPACITY   := CONVERT_NUMBER(v_COLS(13));
					v_profile.REASSIGNED_START_TIME := CONVERT_DATE(v_COLS(14));
					v_profile.REASSIGNED_STOP_TIME  := CONVERT_DATE(v_COLS(15));

					v_PRO.EXTEND;
					v_PRO(v_PRO.LAST) := v_profile;

				ELSE
					-- error
					NULL;
				END IF;

			END IF;

			v_IDX := v_LINES.NEXT(v_IDX);

		END LOOP;

		-- save the last data (in case it was a continuation row)
		IF v_PRO.COUNT > 0 THEN
			-- save previous data row containing profile_table
			v_data.PROFILE_TABLE := v_PRO;
			v_DAT.EXTEND;
			v_DAT(v_DAT.LAST) := v_data;
			v_PRO.DELETE;
		END IF;

		-- assign the only record
		-- other attributes were assigned earlier
		p_TAB.DATA_TABLE := v_DAT;

		IF v_request_status != g_REQUEST_SUCCESS THEN
			p_LOGGER.LOG_ERROR(v_error || 'REQUEST_STATUS = ' ||
						 TO_CHAR(v_request_status) || ', ' ||
						 v_error_message);
		END IF;

	EXCEPTION
		WHEN OTHERS THEN
			p_LOGGER.LOG_ERROR(v_error || ':' || SQLERRM);
			RAISE;
	END PARSE_ANCSELL_RESPONSE;
	--------------------------------------------------------------------------------------------------------------
	PROCEDURE CREATE_ANCSELL_INPUT(p_CSV     OUT CLOB,
								   p_TAB     IN MEX_OASIS_TRANS,
								   p_STATUS  OUT NUMBER,
								   P_MESSAGE OUT VARCHAR) IS

		v_columns        VARCHAR2(2000);
		v_column_headers VARCHAR2(2000);
		v_template       VARCHAR2(20) := 'ancsell';
		v_data_rows      NUMBER := 0;
		v_DAT            MEX_OASIS_TRANS_DATA_TBL;
		v_PRO            MEX_OASIS_TRANS_PROFILE_TBL;
		v_CSV            CLOB;

	BEGIN

		p_STATUS  := g_SUCCESS;
		p_MESSAGE := '';

		-- data rows
		v_DAT := p_TAB.DATA_TABLE;

		IF v_DAT IS NOT NULL THEN

			FOR v_dat_row IN v_DAT.FIRST .. v_DAT.LAST LOOP
				v_PRO := v_DAT(v_dat_row).PROFILE_TABLE;

				FOR v_pro_row IN v_PRO.FIRST .. v_PRO.LAST LOOP

					IF v_pro_row = 1 THEN

						v_CSV := v_CSV || 'N' || ',';
						v_CSV := v_CSV ||
								 TO_CSV(v_PRO(v_pro_row).ASSIGNMENT_REF) || ',';
						v_CSV := v_CSV ||
								 TO_CSV(v_PRO(v_pro_row).start_time) || ',';
						v_CSV := v_CSV ||
								 TO_CSV(v_PRO(v_pro_row).STOP_TIME) || ',';
						v_CSV := v_CSV ||
								 TO_CSV(v_PRO(v_pro_row).OFFER_PRICE) || ',';
						v_CSV := v_CSV || TO_CSV(v_DAT(v_dat_row).STATUS) || ',';
						v_CSV := v_CSV ||
								 TO_CSV(v_DAT(v_dat_row).STATUS_COMMENTS) || ',';
						v_CSV := v_CSV ||
								 TO_CSV(v_DAT(v_dat_row)
										.NEGOTIATED_PRICE_FLAG) || ',';
						v_CSV := v_CSV ||
								 TO_CSV(v_DAT(v_dat_row)
										.RESPONSE_TIME_LIMIT) || ',';
						v_CSV := v_CSV ||
								 TO_CSV(v_DAT(v_dat_row).SELLER_COMMENTS) || ',';
						v_CSV := v_CSV ||
								 TO_CSV(v_PRO(v_pro_row).REASSIGNED_REF) || ',';
						v_CSV := v_CSV ||
								 TO_CSV(v_PRO(v_pro_row)
										.REASSIGNED_CAPACITY) || ',';
						v_CSV := v_CSV ||
								 TO_CSV(v_PRO(v_pro_row)
										.REASSIGNED_START_TIME) || ',';
						v_CSV := v_CSV ||
								 TO_CSV(v_PRO(v_pro_row)
										.REASSIGNED_STOP_TIME) || g_CRLF;

					ELSE

						v_CSV := v_CSV || 'Y' || ',';
						v_CSV := v_CSV ||
								 TO_CSV(v_PRO(v_pro_row).ASSIGNMENT_REF) || ',';
						v_CSV := v_CSV ||
								 TO_CSV(v_PRO(v_pro_row).START_TIME) || ',';
						v_CSV := v_CSV ||
								 TO_CSV(v_PRO(v_pro_row).STOP_TIME) || ',';
						v_CSV := v_CSV ||
								 TO_CSV(v_PRO(v_pro_row).OFFER_PRICE) || ',';
						v_CSV := v_CSV || ',';
						v_CSV := v_CSV || ',';
						v_CSV := v_CSV || ',';
						v_CSV := v_CSV || ',';
						v_CSV := v_CSV || ',';
						v_CSV := v_CSV ||
								 TO_CSV(v_PRO(v_pro_row).REASSIGNED_REF) || ',';
						v_CSV := v_CSV ||
								 TO_CSV(v_PRO(v_pro_row)
										.REASSIGNED_CAPACITY) || ',';
						v_CSV := v_CSV ||
								 TO_CSV(v_PRO(v_pro_row)
										.REASSIGNED_START_TIME) || ',';
						v_CSV := v_CSV ||
								 TO_CSV(v_PRO(v_pro_row)
										.REASSIGNED_STOP_TIME) || g_CRLF;

					END IF;

					v_data_rows := v_data_rows + 1;

				END LOOP; -- profile
			END LOOP; -- data

		END IF;

		-- add header with count
		-- count is sum total of all profile_table rows within all the data_table rows

		FOR idx IN 1 .. ancsell_input_elements.COUNT LOOP
			IF idx < ancsell_input_elements.COUNT THEN
				v_columns := v_columns || ancsell_input_elements(idx) || ',';
			ELSE
				v_columns := v_columns || ancsell_input_elements(idx);
			END IF;
		END LOOP;
		v_column_headers := v_columns;

		-- header row
		p_CSV := input_hdr_elements(1) || '=';
		p_CSV := p_CSV || TO_CSV(g_version, g_FLOAT_5_1_FORMAT) || g_CRLF;
		p_CSV := p_CSV || input_hdr_elements(2) || '=';
		p_CSV := p_CSV || TO_CSV(v_template) || g_CRLF;
		p_CSV := p_CSV || input_hdr_elements(3) || '=';
		p_CSV := p_CSV || TO_CSV(g_output_format) || g_CRLF;
		p_CSV := p_CSV || input_hdr_elements(4) || '=';
		p_CSV := p_CSV || TO_CSV(p_TAB.PRIMARY_PROVIDER_CODE) || g_CRLF;
		p_CSV := p_CSV || input_hdr_elements(5) || '=';
		p_CSV := p_CSV ||
				 TO_CSV(p_TAB.PRIMARY_PROVIDER_DUNS, g_NUMBER_9_FORMAT) ||
				 g_CRLF;
		p_CSV := p_CSV || input_hdr_elements(6) || '=';
		p_CSV := p_CSV || TO_CSV(g_EXCHANGE_TZ) || g_CRLF;
		p_CSV := p_CSV || input_hdr_elements(7) || '=';
		p_CSV := p_CSV || TO_CSV(v_data_rows) || g_CRLF;
		p_CSV := p_CSV || input_hdr_elements(8) || '=';
		p_CSV := p_CSV || v_column_headers || g_CRLF;
		p_CSV := p_CSV || v_CSV; -- append data/profile rows

	EXCEPTION
		WHEN OTHERS THEN
			p_STATUS  := SQLCODE;
			p_MESSAGE := 'Error in CREATE_ANCSELL_INPUT: ' || SQLERRM;
	END CREATE_ANCSELL_INPUT;
	--------------------------------------------------------------------------------------------------------------
	PROCEDURE PARSE_ANCCUST_RESPONSE
		(
		p_CSV     IN CLOB,
		p_LOGGER IN OUT NOCOPY mm_logger_adapter,
		p_TAB     OUT MEX_OASIS_TRANS) IS

		v_error         CONSTANT VARCHAR2(40) := 'Error in parse_anccust_response: ';
		v_template      CONSTANT VARCHAR2(20) := 'anccust';
		v_element_count CONSTANT NUMBER(3) := 14;
		v_line_count NUMBER := 0;

		v_LINES          PARSE_UTIL.BIG_STRING_TABLE_MP;
		v_COLS           PARSE_UTIL.STRING_TABLE;
		v_IDX            BINARY_INTEGER;
		v_delim          VARCHAR2(1);
		v_PRO            MEX_OASIS_TRANS_PROFILE_TBL := MEX_OASIS_TRANS_PROFILE_TBL();
		v_DAT            MEX_OASIS_TRANS_DATA_TBL := MEX_OASIS_TRANS_DATA_TBL();
		v_data           MEX_OASIS_TRANS_DATA;
		v_profile        MEX_OASIS_TRANS_PROFILE;
		v_request_status NUMBER(3);
		v_error_message  VARCHAR2(250);

	BEGIN

		PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_CSV, v_LINES);
		v_IDX   := v_LINES.FIRST;
		v_delim := '='; -- header
		p_TAB   := MEX_OASIS_TRANS(NULL, NULL, NULL, NULL, NULL);

		v_line_count := v_LINES.COUNT;

		WHILE v_LINES.EXISTS(v_IDX) LOOP

			parse_util.PARSE_DELIMITED_STRING(v_LINES(v_IDX),
											v_delim,
											v_COLS);

			-- each line contains key=value for the header
			-- then each line contains the series of attributes
			IF v_IDX < 12 THEN

				validate_response(v_COLS,
								  v_IDX,
								  v_error,
								  v_template,
								  v_request_status,
								  v_error_message,
								  v_delim,
								  v_line_count,
								  p_TAB);

			ELSE
				-- process data rows
				IF v_COLS.COUNT != v_element_count THEN
					p_LOGGER.LOG_ERROR(v_error ||
								 'wrong number of data elements in response, found ' ||
								 TO_CHAR(v_COLS.COUNT) || ' but ' ||
								 TO_CHAR(v_element_count) || ' required');
					RETURN;
				END IF;
				-- anccust_response

				-- continuation_flag
				IF v_COLS(2) = 'N' THEN

					IF v_PRO.COUNT > 0 THEN
						-- save previous data row containing profile_table
						v_data.PROFILE_TABLE := v_PRO;
						v_DAT.EXTEND;
						v_DAT(v_DAT.LAST) := v_data;
						v_PRO.DELETE;
					END IF;

					-- start new data and profile records for a non-continuation row

					v_profile := g_default_profile;
					v_data    := g_default_data;

					v_profile.ASSIGNMENT_REF    := v_COLS(3);
					v_profile.START_TIME        := CONVERT_DATE(v_COLS(4));
					v_profile.STOP_TIME         := CONVERT_DATE(v_COLS(5));
					v_profile.BID_PRICE         := CONVERT_NUMBER(v_COLS(8));
					v_profile.CUSTOMER_COMMENTS := v_COLS(13);

					v_PRO.EXTEND;
					v_PRO(v_PRO.LAST) := v_profile;

					v_data.RECORD_STATUS       := CONVERT_NUMBER(v_COLS(1));
					v_data.REQUEST_REF         := v_COLS(6);
					v_data.DEAL_REF            := v_COLS(7);
					v_data.PRECONFIRMED        := v_COLS(9);
					v_data.STATUS              := v_COLS(10);
					v_data.STATUS_COMMENTS     := v_COLS(11);
					v_data.STATUS_NOTIFICATION := v_COLS(12);
					v_data.ERROR_MESSAGE       := v_COLS(14);

				ELSIF v_COLS(2) = 'Y' THEN
					-- just extend the profile table

					v_profile.ASSIGNMENT_REF    := v_COLS(3);
					v_profile.START_TIME        := CONVERT_DATE(v_COLS(4));
					v_profile.STOP_TIME         := CONVERT_DATE(v_COLS(5));
					v_profile.BID_PRICE         := CONVERT_NUMBER(v_COLS(8));
					v_profile.CUSTOMER_COMMENTS := v_COLS(13);

					v_PRO.EXTEND;
					v_PRO(v_PRO.LAST) := v_profile;

				ELSE
					-- error
					NULL;
				END IF;

			END IF;

			v_IDX := v_LINES.NEXT(v_IDX);

		END LOOP;

		-- save the last data (in case it was a continuation row)
		IF v_PRO.COUNT > 0 THEN
			-- save previous data row containing profile_table
			v_data.PROFILE_TABLE := v_PRO;
			v_DAT.EXTEND;
			v_DAT(v_DAT.LAST) := v_data;
			v_PRO.DELETE;
		END IF;

		-- assign the only record
		-- other attributes were assigned earlier
		p_TAB.DATA_TABLE := v_DAT;

		IF v_request_status != g_REQUEST_SUCCESS THEN
			p_LOGGER.LOG_ERROR(v_error || 'REQUEST_STATUS = ' ||
						 TO_CHAR(v_request_status) || ', ' ||
						 v_error_message);
		END IF;

	EXCEPTION
		WHEN OTHERS THEN
			p_LOGGER.LOG_ERROR(v_error || ':' || SQLERRM);
			RAISE;
	END PARSE_ANCCUST_RESPONSE;
	--------------------------------------------------------------------------------------------------------------
	PROCEDURE CREATE_ANCCUST_INPUT(p_CSV     OUT CLOB,
								   p_TAB     IN MEX_OASIS_TRANS,
								   p_STATUS  OUT NUMBER,
								   P_MESSAGE OUT VARCHAR) IS

		v_columns        VARCHAR2(2000);
		v_column_headers VARCHAR2(2000);
		v_template       VARCHAR2(20) := 'anccust';
		v_data_rows      NUMBER := 0;
		v_DAT            MEX_OASIS_TRANS_DATA_TBL;
		v_PRO            MEX_OASIS_TRANS_PROFILE_TBL;
		v_CSV            CLOB;

	BEGIN

		p_STATUS  := g_SUCCESS;
		p_MESSAGE := '';

		-- data rows
		v_DAT := p_TAB.DATA_TABLE;

		IF v_DAT IS NOT NULL THEN

			FOR v_dat_row IN v_DAT.FIRST .. v_DAT.LAST LOOP
				v_PRO := v_DAT(v_dat_row).PROFILE_TABLE;

				FOR v_pro_row IN v_PRO.FIRST .. v_PRO.LAST LOOP

					IF v_pro_row = 1 THEN

						v_CSV := v_CSV || 'N' || ',';
						v_CSV := v_CSV ||
								 TO_CSV(v_PRO(v_pro_row).ASSIGNMENT_REF) || ',';
						v_CSV := v_CSV ||
								 TO_CSV(v_PRO(v_pro_row).START_TIME) || ',';
						v_CSV := v_CSV ||
								 TO_CSV(v_PRO(v_pro_row).STOP_TIME) || ',';
						v_CSV := v_CSV ||
								 TO_CSV(v_DAT(v_dat_row).REQUEST_REF) || ',';
						v_CSV := v_CSV || TO_CSV(v_DAT(v_dat_row).DEAL_REF) || ',';
						v_CSV := v_CSV ||
								 TO_CSV(v_PRO(v_pro_row).BID_PRICE,
										g_FLOAT_9_4_FORMAT) || ',';
						v_CSV := v_CSV ||
								 TO_CSV(v_DAT(v_dat_row).PRECONFIRMED) || ',';
						v_CSV := v_CSV || TO_CSV(v_DAT(v_dat_row).STATUS) || ',';
						v_CSV := v_CSV ||
								 TO_CSV(v_DAT(v_dat_row).STATUS_COMMENTS) || ',';
						v_CSV := v_CSV ||
								 TO_CSV(v_DAT(v_dat_row)
										.STATUS_NOTIFICATION) || ',';
						v_CSV := v_CSV ||
								 TO_CSV(v_PRO(v_pro_row).CUSTOMER_COMMENTS) ||
								 g_CRLF;

					ELSE

						v_CSV := v_CSV || 'Y' || ',';
						v_CSV := v_CSV || ',';
						v_CSV := v_CSV ||
								 TO_CSV(v_PRO(v_pro_row).START_TIME) || ',';
						v_CSV := v_CSV ||
								 TO_CSV(v_PRO(v_pro_row).STOP_TIME) || ',';
						v_CSV := v_CSV || ',';
						v_CSV := v_CSV || ',';
						v_CSV := v_CSV ||
								 TO_CSV(v_PRO(v_pro_row).BID_PRICE,
										g_FLOAT_9_4_FORMAT) || ',';
						v_CSV := v_CSV || ',';
						v_CSV := v_CSV || ',';
						v_CSV := v_CSV || ',';
						v_CSV := v_CSV || ',';
						v_CSV := v_CSV || g_CRLF;

					END IF;

					v_data_rows := v_data_rows + 1;

				END LOOP; -- profile
			END LOOP; -- data

		END IF;

		-- add header with count
		-- count is sum total of all profile_table rows within all the data_table rows

		FOR idx IN 1 .. anccust_input_elements.COUNT LOOP
			IF idx < anccust_input_elements.COUNT THEN
				v_columns := v_columns || anccust_input_elements(idx) || ',';
			ELSE
				v_columns := v_columns || anccust_input_elements(idx);
			END IF;
		END LOOP;
		v_column_headers := v_columns;

		-- header row
		p_CSV := input_hdr_elements(1) || '=';
		p_CSV := p_CSV || TO_CSV(g_version, g_FLOAT_5_1_FORMAT) || g_CRLF;
		p_CSV := p_CSV || input_hdr_elements(2) || '=';
		p_CSV := p_CSV || TO_CSV(v_template) || g_CRLF;
		p_CSV := p_CSV || input_hdr_elements(3) || '=';
		p_CSV := p_CSV || TO_CSV(g_output_format) || g_CRLF;
		p_CSV := p_CSV || input_hdr_elements(4) || '=';
		p_CSV := p_CSV || TO_CSV(p_TAB.PRIMARY_PROVIDER_CODE) || g_CRLF;
		p_CSV := p_CSV || input_hdr_elements(5) || '=';
		p_CSV := p_CSV ||
				 TO_CSV(p_TAB.PRIMARY_PROVIDER_DUNS, g_NUMBER_9_FORMAT) ||
				 g_CRLF;
		p_CSV := p_CSV || input_hdr_elements(6) || '=';
		p_CSV := p_CSV || TO_CSV(g_EXCHANGE_TZ) || g_CRLF;
		p_CSV := p_CSV || input_hdr_elements(7) || '=';
		p_CSV := p_CSV || TO_CSV(v_data_rows) || g_CRLF;
		p_CSV := p_CSV || input_hdr_elements(8) || '=';
		p_CSV := p_CSV || v_column_headers || g_CRLF;
		p_CSV := p_CSV || v_CSV; -- append data/profile rows

	EXCEPTION
		WHEN OTHERS THEN
			p_STATUS  := SQLCODE;
			p_MESSAGE := 'Error in CREATE_ANCCUST_INPUT: ' || SQLERRM;
	END CREATE_ANCCUST_INPUT;
	--------------------------------------------------------------------------------------------------------------
	PROCEDURE PARSE_ANCASSIGN_RESPONSE
		(
		p_CSV     IN CLOB,
		p_LOGGER IN OUT NOCOPY mm_logger_adapter,
		p_TAB     OUT MEX_OASIS_TRANS
		) IS
		v_error         CONSTANT VARCHAR2(40) := 'Error in PARSE_ANCASSIGN_RESPONSE: ';
		v_template      CONSTANT VARCHAR2(20) := 'ancassign';
		v_element_count CONSTANT NUMBER(3) := 20;
		v_line_count NUMBER := 0;

		v_LINES          PARSE_UTIL.BIG_STRING_TABLE_MP;
		v_COLS           PARSE_UTIL.STRING_TABLE;
		v_IDX            BINARY_INTEGER;
		v_delim          VARCHAR2(1);
		v_PRO            MEX_OASIS_TRANS_PROFILE_TBL := MEX_OASIS_TRANS_PROFILE_TBL();
		v_DAT            MEX_OASIS_TRANS_DATA_TBL := MEX_OASIS_TRANS_DATA_TBL();
		v_data           MEX_OASIS_TRANS_DATA;
		v_profile        MEX_OASIS_TRANS_PROFILE;
		v_request_status NUMBER(3);
		v_error_message  VARCHAR2(250);

	BEGIN

		PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_CSV, v_LINES);
		v_IDX   := v_LINES.FIRST;
		v_delim := '='; -- header
		p_TAB   := MEX_OASIS_TRANS(NULL, NULL, NULL, NULL, NULL);

		v_line_count := v_LINES.COUNT;

		WHILE v_LINES.EXISTS(v_IDX) LOOP

			parse_util.PARSE_DELIMITED_STRING(v_LINES(v_IDX),
											v_delim,
											v_COLS);

			-- each line contains key=value for the header
			-- then each line contains the series of attributes
			IF v_IDX < 12 THEN

				validate_response(v_COLS,
								  v_IDX,
								  v_error,
								  v_template,
								  v_request_status,
								  v_error_message,
								  v_delim,
								  v_line_count,
								  p_TAB);
			ELSE
				-- process data rows
				IF v_COLS.COUNT != v_element_count THEN
					p_LOGGER.LOG_ERROR(v_error ||
								 'wrong number of data elements in response, found ' ||
								 TO_CHAR(v_COLS.COUNT) || ' but ' ||
								 TO_CHAR(v_element_count) || ' required');
					RETURN;
				END IF;
				-- ancassign_response

				-- continuation_flag
				IF v_COLS(2) = 'N' THEN

					IF v_PRO.COUNT > 0 THEN
						-- save previous data row containing profile_table
						v_data.PROFILE_TABLE := v_PRO;
						v_DAT.EXTEND;
						v_DAT(v_DAT.LAST) := v_data;
						v_PRO.DELETE;
					END IF;

					-- start new data and profile records for a non-continuation row

					v_profile := g_default_profile;
					v_data    := g_default_data;

					v_data.RECORD_STATUS     := CONVERT_NUMBER(v_COLS(1));
					v_data.CUSTOMER_CODE     := v_COLS(4);
					v_data.CUSTOMER_DUNS     := CONVERT_NUMBER(v_COLS(5));
					v_data.CONTROL_AREA      := v_COLS(6);
					v_data.ANC_SERVICE_POINT := v_COLS(7);
					v_data.SERVICE_INCREMENT := v_COLS(9);
					v_data.AS_TYPE           := v_COLS(10);
					v_data.POSTING_NAME      := v_COLS(14);
					v_data.SELLER_COMMENTS   := v_COLS(19);
					v_data.ERROR_MESSAGE     := v_COLS(20);

					v_profile.ASSIGNMENT_REF        := v_COLS(3);
					v_profile.CAPACITY              := CONVERT_NUMBER(v_COLS(8));
					v_profile.START_TIME            := CONVERT_DATE(v_COLS(11), v_data.SERVICE_INCREMENT);
					v_profile.STOP_TIME             := CONVERT_DATE(v_COLS(12), v_data.SERVICE_INCREMENT);
					v_profile.OFFER_PRICE           := CONVERT_NUMBER(v_COLS(13));
					v_profile.REASSIGNED_REF        := v_COLS(15);
					v_profile.REASSIGNED_CAPACITY   := CONVERT_NUMBER(v_COLS(16));
					v_profile.REASSIGNED_START_TIME := CONVERT_DATE(v_COLS(17), v_data.SERVICE_INCREMENT);
					v_profile.REASSIGNED_STOP_TIME  := CONVERT_DATE(v_COLS(18), v_data.SERVICE_INCREMENT);

					v_PRO.EXTEND;
					v_PRO(v_PRO.LAST) := v_profile;

				ELSIF v_COLS(2) = 'Y' THEN
					-- just extend the profile table

					v_profile.ASSIGNMENT_REF        := v_COLS(3);
					v_profile.CAPACITY              := CONVERT_NUMBER(v_COLS(8));
					v_profile.START_TIME            := CONVERT_DATE(v_COLS(11), v_data.SERVICE_INCREMENT);
					v_profile.STOP_TIME             := CONVERT_DATE(v_COLS(12), v_data.SERVICE_INCREMENT);
					v_profile.OFFER_PRICE           := CONVERT_NUMBER(v_COLS(13));
					v_profile.REASSIGNED_REF        := v_COLS(15);
					v_profile.REASSIGNED_CAPACITY   := CONVERT_NUMBER(v_COLS(16));
					v_profile.REASSIGNED_START_TIME := CONVERT_DATE(v_COLS(17), v_data.SERVICE_INCREMENT);
					v_profile.REASSIGNED_STOP_TIME  := CONVERT_DATE(v_COLS(18), v_data.SERVICE_INCREMENT);

					v_PRO.EXTEND;
					v_PRO(v_PRO.LAST) := v_profile;

				ELSE
					-- error
					NULL;
				END IF;

			END IF;

			v_IDX := v_LINES.NEXT(v_IDX);

		END LOOP;

		-- save the last data (in case it was a continuation row)
		IF v_PRO.COUNT > 0 THEN
			-- save previous data row containing profile_table
			v_data.PROFILE_TABLE := v_PRO;
			v_DAT.EXTEND;
			v_DAT(v_DAT.LAST) := v_data;
			v_PRO.DELETE;
		END IF;

		-- assign the only record
		-- other attributes were assigned earlier
		p_TAB.DATA_TABLE := v_DAT;

		IF v_request_status != g_REQUEST_SUCCESS THEN
			p_LOGGER.LOG_ERROR(v_error || 'REQUEST_STATUS = ' ||
						 TO_CHAR(v_request_status) || ', ' ||
						 v_error_message);
		END IF;

	EXCEPTION
		WHEN OTHERS THEN
			p_LOGGER.LOG_ERROR(v_error || ':' || SQLERRM);
			RAISE;
	END PARSE_ANCASSIGN_RESPONSE;
	--------------------------------------------------------------------------------------------------------------
	PROCEDURE CREATE_ANCASSIGN_INPUT(p_CSV     OUT CLOB,
									 p_TAB     IN MEX_OASIS_TRANS,
									 p_STATUS  OUT NUMBER,
									 P_MESSAGE OUT VARCHAR) IS
		v_columns        VARCHAR2(2000);
		v_column_headers VARCHAR2(2000);
		v_template       VARCHAR2(20) := 'ancassign';
		v_data_rows      NUMBER := 0;
		v_DAT            MEX_OASIS_TRANS_DATA_TBL;
		v_PRO            MEX_OASIS_TRANS_PROFILE_TBL;
		v_CSV            CLOB;

	BEGIN

		p_STATUS  := g_SUCCESS;
		p_MESSAGE := '';

		-- data rows
		v_DAT := p_TAB.DATA_TABLE;

		IF v_DAT IS NOT NULL THEN

			FOR v_dat_row IN v_DAT.FIRST .. v_DAT.LAST LOOP
				v_PRO := v_DAT(v_dat_row).PROFILE_TABLE;

				FOR v_pro_row IN v_PRO.FIRST .. v_PRO.LAST LOOP

					IF v_pro_row = 1 THEN

						v_CSV := v_CSV || 'N' || ',';
						v_CSV := v_CSV ||
								 TO_CSV(v_DAT(v_dat_row).CUSTOMER_CODE) || ',';
						v_CSV := v_CSV ||
								 TO_CSV(v_DAT(v_dat_row).CUSTOMER_DUNS,
										g_NUMBER_9_FORMAT) || ',';
						v_CSV := v_CSV ||
								 TO_CSV(v_DAT(v_dat_row).CONTROL_AREA) || ',';
						v_CSV := v_CSV ||
								 TO_CSV(v_DAT(v_dat_row).ANC_SERVICE_POINT) || ',';
						v_CSV := v_CSV || TO_CSV(v_PRO(v_pro_row).CAPACITY) || ',';
						v_CSV := v_CSV ||
								 TO_CSV(v_DAT(v_dat_row).SERVICE_INCREMENT) || ',';
						v_CSV := v_CSV || TO_CSV(v_DAT(v_dat_row).AS_TYPE) || ',';
						v_CSV := v_CSV ||
								 TO_CSV(v_PRO(v_pro_row).START_TIME) || ',';
						v_CSV := v_CSV ||
								 TO_CSV(v_PRO(v_pro_row).STOP_TIME) || ',';
						v_CSV := v_CSV ||
								 TO_CSV(v_PRO(v_pro_row).OFFER_PRICE,
										g_FLOAT_9_4_FORMAT) || ',';
						v_CSV := v_CSV ||
								 TO_CSV(v_DAT(v_dat_row).POSTING_NAME) || ',';
						v_CSV := v_CSV ||
								 TO_CSV(v_PRO(v_pro_row).REASSIGNED_REF) || ',';
						v_CSV := v_CSV ||
								 TO_CSV(v_PRO(v_pro_row)
										.REASSIGNED_CAPACITY) || ',';
						v_CSV := v_CSV ||
								 TO_CSV(v_PRO(v_pro_row)
										.REASSIGNED_START_TIME) || ',';
						v_CSV := v_CSV ||
								 TO_CSV(v_PRO(v_pro_row)
										.REASSIGNED_STOP_TIME) || ',';
						v_CSV := v_CSV ||
								 TO_CSV(v_DAT(v_dat_row).SELLER_COMMENTS) ||
								 g_CRLF;

					ELSE

						v_CSV := v_CSV || 'Y' || ',';
						v_CSV := v_CSV || ',';
						v_CSV := v_CSV || ',';
						v_CSV := v_CSV || ',';
						v_CSV := v_CSV || ',';
						v_CSV := v_CSV || TO_CSV(v_PRO(v_pro_row).CAPACITY) || ',';
						v_CSV := v_CSV || ',';
						v_CSV := v_CSV || ',';
						v_CSV := v_CSV ||
								 TO_CSV(v_PRO(v_pro_row).START_TIME) || ',';
						v_CSV := v_CSV ||
								 TO_CSV(v_PRO(v_pro_row).STOP_TIME) || ',';
						v_CSV := v_CSV || ',';
						v_CSV := v_CSV || ',';
						v_CSV := v_CSV ||
								 TO_CSV(v_PRO(v_pro_row).REASSIGNED_REF) || ',';
						v_CSV := v_CSV ||
								 TO_CSV(v_PRO(v_pro_row)
										.REASSIGNED_CAPACITY) || ',';
						v_CSV := v_CSV ||
								 TO_CSV(v_PRO(v_pro_row)
										.REASSIGNED_START_TIME) || ',';
						v_CSV := v_CSV ||
								 TO_CSV(v_PRO(v_pro_row)
										.REASSIGNED_STOP_TIME) || ',';
						v_CSV := v_CSV || g_CRLF;

					END IF;

					v_data_rows := v_data_rows + 1;

				END LOOP; -- profile
			END LOOP; -- data

		END IF;

		-- add header with count
		-- count is sum total of all profile_table rows within all the data_table rows

		FOR idx IN 1 .. ancassign_input_elements.COUNT LOOP
			IF idx < ancassign_input_elements.COUNT THEN
				v_columns := v_columns || ancassign_input_elements(idx) || ',';
			ELSE
				v_columns := v_columns || ancassign_input_elements(idx);
			END IF;
		END LOOP;
		v_column_headers := v_columns;

		-- header row
		p_CSV := input_hdr_elements(1) || '=';
		p_CSV := p_CSV || TO_CSV(g_version, g_FLOAT_5_1_FORMAT) || g_CRLF;
		p_CSV := p_CSV || input_hdr_elements(2) || '=';
		p_CSV := p_CSV || TO_CSV(v_template) || g_CRLF;
		p_CSV := p_CSV || input_hdr_elements(3) || '=';
		p_CSV := p_CSV || TO_CSV(g_output_format) || g_CRLF;
		p_CSV := p_CSV || input_hdr_elements(4) || '=';
		p_CSV := p_CSV || TO_CSV(p_TAB.PRIMARY_PROVIDER_CODE) || g_CRLF;
		p_CSV := p_CSV || input_hdr_elements(5) || '=';
		p_CSV := p_CSV ||
				 TO_CSV(p_TAB.PRIMARY_PROVIDER_DUNS, g_NUMBER_9_FORMAT) ||
				 g_CRLF;
		p_CSV := p_CSV || input_hdr_elements(6) || '=';
		p_CSV := p_CSV || TO_CSV(g_EXCHANGE_TZ) || g_CRLF;
		p_CSV := p_CSV || input_hdr_elements(7) || '=';
		p_CSV := p_CSV || TO_CSV(v_data_rows) || g_CRLF;
		p_CSV := p_CSV || input_hdr_elements(8) || '=';
		p_CSV := p_CSV || v_column_headers || g_CRLF;
		p_CSV := p_CSV || v_CSV; -- append data/profile rows

	EXCEPTION
		WHEN OTHERS THEN
			p_STATUS  := SQLCODE;
			p_MESSAGE := 'Error in CREATE_ANCASSIGN_INPUT: ' || SQLERRM;
	END CREATE_ANCASSIGN_INPUT;
	--------------------------------------------------------------------------------------------------------------
	PROCEDURE PARSE_ANCPOST_RESPONSE
		(
		p_CSV     IN CLOB,
		p_LOGGER IN OUT NOCOPY mm_logger_adapter,
		p_TAB     OUT MEX_OASIS_TRANS
		) IS
		v_error         CONSTANT VARCHAR2(40) := 'Error in PARSE_ANCPOST_RESPONSE: ';
		v_template      CONSTANT VARCHAR2(20) := 'ancpost';
		v_element_count CONSTANT NUMBER(3) := 15;
		v_line_count NUMBER := 0;

		v_LINES          PARSE_UTIL.BIG_STRING_TABLE_MP;
		v_COLS           PARSE_UTIL.STRING_TABLE;
		v_IDX            BINARY_INTEGER;
		v_delim          VARCHAR2(1);
		v_PRO            MEX_OASIS_TRANS_PROFILE_TBL := MEX_OASIS_TRANS_PROFILE_TBL();
		v_DAT            MEX_OASIS_TRANS_DATA_TBL := MEX_OASIS_TRANS_DATA_TBL();
		v_data           MEX_OASIS_TRANS_DATA;
		v_profile        MEX_OASIS_TRANS_PROFILE;
		v_request_status NUMBER(3);
		v_error_message  VARCHAR2(250);

	BEGIN

		PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_CSV, v_LINES);
		v_IDX   := v_LINES.FIRST;
		v_delim := '='; -- header
		p_TAB   := MEX_OASIS_TRANS(NULL, NULL, NULL, NULL, NULL);

		v_line_count := v_LINES.COUNT;

		WHILE v_LINES.EXISTS(v_IDX) LOOP

			parse_util.PARSE_DELIMITED_STRING(v_LINES(v_IDX),
											v_delim,
											v_COLS);

			-- each line contains key=value for the header
			-- then each line contains the series of attributes
			IF v_IDX < 12 THEN

				validate_response(v_COLS,
								  v_IDX,
								  v_error,
								  v_template,
								  v_request_status,
								  v_error_message,
								  v_delim,
								  v_line_count,
								  p_TAB);
			ELSE
				-- process data rows
				IF v_COLS.COUNT != v_element_count THEN
					p_LOGGER.LOG_ERROR(v_error ||
								 'wrong number of data elements in response, found ' ||
								 TO_CHAR(v_COLS.COUNT) || ' but ' ||
								 TO_CHAR(v_element_count) || ' required');
					RETURN;
				END IF;
				-- ancpost_response

				-- no continuation flag is used

				IF v_PRO.COUNT > 0 THEN
					-- save previous data row containing profile_table
					v_data.PROFILE_TABLE := v_PRO;
					v_DAT.EXTEND;
					v_DAT(v_DAT.LAST) := v_data;
					v_PRO.DELETE;
				END IF;

				-- start new data and profile records for a non-continuation row

				v_profile := g_default_profile;
				v_data    := g_default_data;

				v_data.RECORD_STATUS       := v_COLS(1);
				v_data.POSTING_REF         := v_COLS(2);
				v_data.CONTROL_AREA        := v_COLS(3);
				v_data.SERVICE_DESCRIPTION := v_COLS(4);
				v_data.SERVICE_INCREMENT   := v_COLS(6);
				v_data.AS_TYPE             := v_COLS(7);
				v_data.OFFER_START_TIME    := CONVERT_DATE(v_COLS(10));
				v_data.OFFER_STOP_TIME     := CONVERT_DATE(v_COLS(11));
				v_data.SALE_REF            := v_COLS(12);
				v_data.SELLER_COMMENTS     := v_COLS(14);
				v_data.ERROR_MESSAGE       := v_COLS(15);

				v_profile.CAPACITY    := CONVERT_NUMBER(v_COLS(5));
				v_profile.START_TIME  := CONVERT_DATE(v_COLS(8), v_data.SERVICE_INCREMENT);
				v_profile.STOP_TIME   := CONVERT_DATE(v_COLS(9), v_data.SERVICE_INCREMENT);
				v_profile.OFFER_PRICE := CONVERT_NUMBER(v_COLS(13));

				v_PRO.EXTEND;
				v_PRO(v_PRO.LAST) := v_profile;

			END IF;

			v_IDX := v_LINES.NEXT(v_IDX);

		END LOOP;

		-- save the last data
		IF v_PRO.COUNT > 0 THEN
			-- save previous data row containing profile_table
			v_data.PROFILE_TABLE := v_PRO;
			v_DAT.EXTEND;
			v_DAT(v_DAT.LAST) := v_data;
			v_PRO.DELETE;
		END IF;

		-- assign the only record
		-- other attributes were assigned earlier
		p_TAB.DATA_TABLE := v_DAT;

		IF v_request_status != g_REQUEST_SUCCESS THEN
			p_LOGGER.LOG_ERROR(v_error || 'REQUEST_STATUS = ' ||
						 TO_CHAR(v_request_status) || ', ' ||
						 v_error_message);
		END IF;

	EXCEPTION
		WHEN OTHERS THEN
			p_LOGGER.LOG_ERROR(v_error || ':' || SQLERRM);
			RAISE;
	END PARSE_ANCPOST_RESPONSE;
	--------------------------------------------------------------------------------------------------------------
	PROCEDURE CREATE_ANCPOST_INPUT(p_CSV     OUT CLOB,
								   p_TAB     IN MEX_OASIS_TRANS,
								   p_STATUS  OUT NUMBER,
								   P_MESSAGE OUT VARCHAR) IS

		v_columns        VARCHAR2(2000);
		v_column_headers VARCHAR2(2000);
		v_template       VARCHAR2(20) := 'ancpost';
		v_data_rows      NUMBER := 0;
		v_DAT            MEX_OASIS_TRANS_DATA_TBL;
		v_PRO            MEX_OASIS_TRANS_PROFILE_TBL;
		v_CSV            CLOB;

	BEGIN

		p_STATUS  := g_SUCCESS;
		p_MESSAGE := '';

		-- data rows
		v_DAT := p_TAB.DATA_TABLE;

		IF v_DAT IS NOT NULL THEN

			FOR v_dat_row IN v_DAT.FIRST .. v_DAT.LAST LOOP
				v_PRO := v_DAT(v_dat_row).PROFILE_TABLE;

				FOR v_pro_row IN v_PRO.FIRST .. v_PRO.LAST LOOP

					v_CSV := v_CSV || TO_CSV(v_DAT(v_dat_row).CONTROL_AREA) || ',';
					v_CSV := v_CSV ||
							 TO_CSV(v_DAT(v_dat_row).SERVICE_DESCRIPTION) || ',';
					v_CSV := v_CSV || TO_CSV(v_PRO(v_pro_row).CAPACITY) || ',';
					v_CSV := v_CSV ||
							 TO_CSV(v_DAT(v_dat_row).SERVICE_INCREMENT) || ',';
					v_CSV := v_CSV || TO_CSV(v_DAT(v_dat_row).AS_TYPE) || ',';
					v_CSV := v_CSV || TO_CSV(v_PRO(v_pro_row).START_TIME) || ',';
					v_CSV := v_CSV || TO_CSV(v_PRO(v_pro_row).STOP_TIME) || ',';
					v_CSV := v_CSV ||
							 TO_CSV(v_DAT(v_dat_row).OFFER_START_TIME) || ',';
					v_CSV := v_CSV ||
							 TO_CSV(v_DAT(v_dat_row).OFFER_STOP_TIME) || ',';
					v_CSV := v_CSV || TO_CSV(v_DAT(v_dat_row).SALE_REF) || ',';
					v_CSV := v_CSV || TO_CSV(v_PRO(v_pro_row).OFFER_PRICE,
											 g_FLOAT_9_4_FORMAT) || ',';
					v_CSV := v_CSV ||
							 TO_CSV(v_DAT(v_dat_row).SELLER_COMMENTS) ||
							 g_CRLF;

					v_data_rows := v_data_rows + 1;

				END LOOP; -- profile
			END LOOP; -- data

		END IF;

		-- add header with count
		-- count is sum total of all profile_table rows within all the data_table rows

		FOR idx IN 1 .. ancpost_input_elements.COUNT LOOP
			IF idx < ancpost_input_elements.COUNT THEN
				v_columns := v_columns || ancpost_input_elements(idx) || ',';
			ELSE
				v_columns := v_columns || ancpost_input_elements(idx);
			END IF;
		END LOOP;
		v_column_headers := v_columns;

		-- header row
		p_CSV := input_hdr_elements(1) || '=';
		p_CSV := p_CSV || TO_CSV(g_version, g_FLOAT_5_1_FORMAT) || g_CRLF;
		p_CSV := p_CSV || input_hdr_elements(2) || '=';
		p_CSV := p_CSV || TO_CSV(v_template) || g_CRLF;
		p_CSV := p_CSV || input_hdr_elements(3) || '=';
		p_CSV := p_CSV || TO_CSV(g_output_format) || g_CRLF;
		p_CSV := p_CSV || input_hdr_elements(4) || '=';
		p_CSV := p_CSV || TO_CSV(p_TAB.PRIMARY_PROVIDER_CODE) || g_CRLF;
		p_CSV := p_CSV || input_hdr_elements(5) || '=';
		p_CSV := p_CSV ||
				 TO_CSV(p_TAB.PRIMARY_PROVIDER_DUNS, g_NUMBER_9_FORMAT) ||
				 g_CRLF;
		p_CSV := p_CSV || input_hdr_elements(6) || '=';
		p_CSV := p_CSV || TO_CSV(g_EXCHANGE_TZ) || g_CRLF;
		p_CSV := p_CSV || input_hdr_elements(7) || '=';
		p_CSV := p_CSV || TO_CSV(v_data_rows) || g_CRLF;
		p_CSV := p_CSV || input_hdr_elements(8) || '=';
		p_CSV := p_CSV || v_column_headers || g_CRLF;
		p_CSV := p_CSV || v_CSV; -- append data/profile rows

	EXCEPTION
		WHEN OTHERS THEN
			p_STATUS  := SQLCODE;
			p_MESSAGE := 'Error in CREATE_ANCPOST_INPUT: ' || SQLERRM;
	END CREATE_ANCPOST_INPUT;
	--------------------------------------------------------------------------------------------------------------
	PROCEDURE PARSE_ANCUPDATE_RESPONSE
		(
		p_CSV     IN CLOB,
		p_LOGGER IN OUT NOCOPY mm_logger_adapter,
		p_TAB     OUT MEX_OASIS_TRANS) IS

		v_error         CONSTANT VARCHAR2(40) := 'Error in PARSE_ANCUPDATE_RESPONSE: ';
		v_template      CONSTANT VARCHAR2(20) := 'ancupdate';
		v_element_count CONSTANT NUMBER(3) := 12;
		v_line_count NUMBER := 0;

		v_LINES          PARSE_UTIL.BIG_STRING_TABLE_MP;
		v_COLS           PARSE_UTIL.STRING_TABLE;
		v_IDX            BINARY_INTEGER;
		v_delim          VARCHAR2(1);
		v_PRO            MEX_OASIS_TRANS_PROFILE_TBL := MEX_OASIS_TRANS_PROFILE_TBL();
		v_DAT            MEX_OASIS_TRANS_DATA_TBL := MEX_OASIS_TRANS_DATA_TBL();
		v_data           MEX_OASIS_TRANS_DATA;
		v_profile        MEX_OASIS_TRANS_PROFILE;
		v_request_status NUMBER(3);
		v_error_message  VARCHAR2(250);

	BEGIN

		PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_CSV, v_LINES);
		v_IDX   := v_LINES.FIRST;
		v_delim := '='; -- header
		p_TAB   := MEX_OASIS_TRANS(NULL, NULL, NULL, NULL, NULL);

		v_line_count := v_LINES.COUNT;

		WHILE v_LINES.EXISTS(v_IDX) LOOP

			parse_util.PARSE_DELIMITED_STRING(v_LINES(v_IDX),
											v_delim,
											v_COLS);

			-- each line contains key=value for the header
			-- then each line contains the series of attributes
			IF v_IDX < 12 THEN

				validate_response(v_COLS,
								  v_IDX,
								  v_error,
								  v_template,
								  v_request_status,
								  v_error_message,
								  v_delim,
								  v_line_count,
								  p_TAB);
			ELSE
				-- process data rows
				IF v_COLS.COUNT != v_element_count THEN
					p_LOGGER.LOG_ERROR(v_error ||
								 'wrong number of data elements in response, found ' ||
								 TO_CHAR(v_COLS.COUNT) || ' but ' ||
								 TO_CHAR(v_element_count) || ' required');
					RETURN;
				END IF;
				-- ancupdate_response

				-- no continuation flag is used

				IF v_PRO.COUNT > 0 THEN
					-- save previous data row containing profile_table
					v_data.PROFILE_TABLE := v_PRO;
					v_DAT.EXTEND;
					v_DAT(v_DAT.LAST) := v_data;
					v_PRO.DELETE;
				END IF;

				-- start new data and profile records for a non-continuation row

				v_profile := g_default_profile;
				v_data    := g_default_data;

				v_profile.CAPACITY    := CONVERT_NUMBER(v_COLS(3));
				v_profile.START_TIME  := CONVERT_DATE(v_COLS(5));
				v_profile.STOP_TIME   := CONVERT_DATE(v_COLS(6));
				v_profile.OFFER_PRICE := CONVERT_NUMBER(v_COLS(10));

				v_PRO.EXTEND;
				v_PRO(v_PRO.LAST) := v_profile;

				v_data.RECORD_STATUS       := v_COLS(1);
				v_data.POSTING_REF         := v_COLS(2);
				v_data.SERVICE_DESCRIPTION := v_COLS(4);
				v_data.OFFER_START_TIME    := CONVERT_DATE(v_COLS(7));
				v_data.OFFER_STOP_TIME     := CONVERT_DATE(v_COLS(8));
				v_data.SALE_REF            := v_COLS(9);
				v_data.SELLER_COMMENTS     := v_COLS(11);
				v_data.ERROR_MESSAGE       := v_COLS(12);

			END IF;

			v_IDX := v_LINES.NEXT(v_IDX);

		END LOOP;

		-- save the last data
		IF v_PRO.COUNT > 0 THEN
			-- save previous data row containing profile_table
			v_data.PROFILE_TABLE := v_PRO;
			v_DAT.EXTEND;
			v_DAT(v_DAT.LAST) := v_data;
			v_PRO.DELETE;
		END IF;

		-- assign the only record
		-- other attributes were assigned earlier
		p_TAB.DATA_TABLE := v_DAT;

		IF v_request_status != g_REQUEST_SUCCESS THEN
			p_LOGGER.LOG_ERROR(v_error || 'REQUEST_STATUS = ' ||
						 TO_CHAR(v_request_status) || ', ' ||
						 v_error_message);
		END IF;

	EXCEPTION
		WHEN OTHERS THEN
			p_LOGGER.LOG_ERROR(v_error || ':' || SQLERRM);
			RAISE;
	END PARSE_ANCUPDATE_RESPONSE;
	--------------------------------------------------------------------------------------------------------------
	PROCEDURE CREATE_ANCUPDATE_INPUT(p_CSV     OUT CLOB,
									 p_TAB     IN MEX_OASIS_TRANS,
									 p_LOGGER  IN OUT NOCOPY mm_logger_adapter) IS

		v_columns        VARCHAR2(2000);
		v_column_headers VARCHAR2(2000);
		v_template       VARCHAR2(20) := 'ancupdate';
		v_data_rows      NUMBER := 0;
		v_DAT            MEX_OASIS_TRANS_DATA_TBL;
		v_PRO            MEX_OASIS_TRANS_PROFILE_TBL;
		v_CSV            CLOB;

	BEGIN

		-- data rows
		v_DAT := p_TAB.DATA_TABLE;

		IF v_DAT IS NOT NULL THEN

			FOR v_dat_row IN v_DAT.FIRST .. v_DAT.LAST LOOP
				v_PRO := v_DAT(v_dat_row).PROFILE_TABLE;

				FOR v_pro_row IN v_PRO.FIRST .. v_PRO.LAST LOOP

					v_CSV := v_CSV || TO_CSV(v_DAT(v_dat_row).POSTING_REF) || ',';
					v_CSV := v_CSV || TO_CSV(v_PRO(v_pro_row).CAPACITY) || ',';
					v_CSV := v_CSV ||
							 TO_CSV(v_DAT(v_dat_row).SERVICE_DESCRIPTION) || ',';
					v_CSV := v_CSV || TO_CSV(v_PRO(v_pro_row).START_TIME) || ',';
					v_CSV := v_CSV || TO_CSV(v_PRO(v_pro_row).STOP_TIME) || ',';
					v_CSV := v_CSV ||
							 TO_CSV(v_DAT(v_dat_row).OFFER_START_TIME) || ',';
					v_CSV := v_CSV ||
							 TO_CSV(v_DAT(v_dat_row).OFFER_STOP_TIME) || ',';
					v_CSV := v_CSV || TO_CSV(v_DAT(v_dat_row).SALE_REF) || ',';
					v_CSV := v_CSV || TO_CSV(v_PRO(v_pro_row).OFFER_PRICE,
											 g_FLOAT_9_4_FORMAT) || ',';
					v_CSV := v_CSV ||
							 TO_CSV(v_DAT(v_dat_row).SELLER_COMMENTS) ||
							 g_CRLF;

					v_data_rows := v_data_rows + 1;

				END LOOP; -- profile
			END LOOP; -- data

		END IF;

		-- add header with count
		-- count is sum total of all profile_table rows within all the data_table rows

		FOR idx IN 1 .. ancupdate_input_elements.COUNT LOOP
			IF idx < ancupdate_input_elements.COUNT THEN
				v_columns := v_columns || ancupdate_input_elements(idx) || ',';
			ELSE
				v_columns := v_columns || ancupdate_input_elements(idx);
			END IF;
		END LOOP;
		v_column_headers := v_columns;

		-- header row
		p_CSV := input_hdr_elements(1) || '=';
		p_CSV := p_CSV || TO_CSV(g_version, g_FLOAT_5_1_FORMAT) || g_CRLF;
		p_CSV := p_CSV || input_hdr_elements(2) || '=';
		p_CSV := p_CSV || TO_CSV(v_template) || g_CRLF;
		p_CSV := p_CSV || input_hdr_elements(3) || '=';
		p_CSV := p_CSV || TO_CSV(g_output_format) || g_CRLF;
		p_CSV := p_CSV || input_hdr_elements(4) || '=';
		p_CSV := p_CSV || TO_CSV(p_TAB.PRIMARY_PROVIDER_CODE) || g_CRLF;
		p_CSV := p_CSV || input_hdr_elements(5) || '=';
		p_CSV := p_CSV ||
				 TO_CSV(p_TAB.PRIMARY_PROVIDER_DUNS, g_NUMBER_9_FORMAT) ||
				 g_CRLF;
		p_CSV := p_CSV || input_hdr_elements(6) || '=';
		p_CSV := p_CSV || TO_CSV(g_EXCHANGE_TZ) || g_CRLF;
		p_CSV := p_CSV || input_hdr_elements(7) || '=';
		p_CSV := p_CSV || TO_CSV(v_data_rows) || g_CRLF;
		p_CSV := p_CSV || input_hdr_elements(8) || '=';
		p_CSV := p_CSV || v_column_headers || g_CRLF;
		p_CSV := p_CSV || v_CSV; -- append data/profile rows

	EXCEPTION
		WHEN OTHERS THEN
			p_LOGGER.LOG_ERROR('Error in CREATE_ANCUPDATE_INPUT: ' || SQLERRM);
			RAISE;
	END CREATE_ANCUPDATE_INPUT;
	--------------------------------------------------------------------------------------------------------------
	PROCEDURE PARSE_LIST_OF_LISTS(p_CLOB    IN CLOB,
								  p_LOGGER IN OUT NOCOPY mm_logger_adapter,
								  p_RECORDS OUT MEX_OASIS_LIST_ELEM_TBL) IS

		v_LST_ITEM VARCHAR2(50);
		v_LINES    PARSE_UTIL.BIG_STRING_TABLE_MP;
		v_COLS     PARSE_UTIL.STRING_TABLE;
		v_IDX      BINARY_INTEGER;
		v_DELIM    VARCHAR2(1) := ',';

	BEGIN

		p_RECORDS := MEX_OASIS_LIST_ELEM_TBL();

		PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_CLOB, v_LINES);
		v_IDX := v_LINES.FIRST;

		WHILE v_LINES.EXISTS(v_IDX) LOOP

			--Ignore the header and get just the data
			IF v_IDX > 11 THEN
				parse_util.PARSE_DELIMITED_STRING(v_LINES(v_IDX),
												v_delim,
												v_COLS);

				--get the name of the list elem
				v_LST_ITEM := v_COLS(3);
				p_RECORDS.EXTEND();
				p_RECORDS(p_RECORDS.LAST) := MEX_OASIS_LIST_ELEM(LIST_NAME => v_LST_ITEM);

			END IF;

			v_IDX := v_LINES.NEXT(v_IDX);

		END LOOP;

	EXCEPTION
		WHEN OTHERS THEN
			p_LOGGER.LOG_ERROR('ERROR OCCURED IN MEX_OASIS.PARSE_LIST_OF_LISTS ' || SQLERRM);
			RAISE;
	END PARSE_LIST_OF_LISTS;
	--------------------------------------------------------------------------------------------------------------
	PROCEDURE PARSE_LIST_ELEM(p_CLOB    IN CLOB,
							  p_LOGGER IN OUT NOCOPY mm_logger_adapter,
							  p_RECORDS IN OUT MEX_OASIS_LIST_RES_TBL
	                          ) IS

		v_LST_NAME      VARCHAR2(50);
		v_LST_ITEM      VARCHAR2(50);
		v_LST_ITEM_DESC VARCHAR2(2000);
		v_LINES         PARSE_UTIL.BIG_STRING_TABLE_MP;
		v_COLS          PARSE_UTIL.STRING_TABLE;
		v_IDX           BINARY_INTEGER;
		v_DELIM         VARCHAR2(1) := ','; -- header

	BEGIN


		PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_CLOB, v_LINES);
		v_IDX := v_LINES.FIRST;

		WHILE v_LINES.EXISTS(v_IDX) LOOP

			--Ignore the header and get just the data
			IF v_IDX > 11 THEN

				parse_util.PARSE_DELIMITED_STRING(v_LINES(v_IDX),
												v_delim,
												v_COLS);

				--get the name of the list elem
				v_LST_NAME      := v_COLS(2);
				v_LST_ITEM      := v_COLS(3);
				v_LST_ITEM_DESC := v_COLS(4);

				p_RECORDS.EXTEND();
				p_RECORDS(p_RECORDS.LAST) := MEX_OASIS_LIST_RES(LIST_NAME      => v_LST_NAME,
																LIST_ITEM      => v_LST_ITEM,
																LIST_ITEM_DESC => v_LST_ITEM_DESC);

			END IF;

			v_IDX := v_LINES.NEXT(v_IDX);

		END LOOP;

	EXCEPTION
		WHEN OTHERS THEN
			p_LOGGER.LOG_ERROR('ERROR OCCURED IN MEX_OASIS.PARSE_LIST_ELEM ' || SQLERRM);
			RAISE;
	END PARSE_LIST_ELEM;
	--------------------------------------------------------------------------------------------------------------
  PROCEDURE OASIS_LIST_GET
  (
      p_CRED          IN MEX_CREDENTIALS,
      p_PROVIDER_CODE IN VARCHAR2,
      p_PROVIDER_DUNS IN NUMBER,
      p_URL           IN VARCHAR2,
      p_RETURN_TZ     IN VARCHAR2,
      p_LIST_NAME     IN VARCHAR2,
      p_CLOB_RESPONSE OUT CLOB,
      p_LOGGER        IN OUT NOCOPY MM_LOGGER_ADAPTER
  ) AS

      v_FETCH_URL VARCHAR2(255);

  BEGIN

      --https://sppoasis.spp.org/OASIS/SWPP/data/list?VERSION=1.4&TEMPLATE=list&OUTPUT_FORMAT=data&
      --PRIMARY_PROVIDER_CODE=SWPP&PRIMARY_PROVIDER_DUNS=77396224&RETURN_TZ=ES&LIST=PATH_NAME&TIME_OF_LAST_UPDATE=

      v_FETCH_URL := p_URL || p_PROVIDER_CODE || '/' || g_DATA_FORMAT || '/' ||
                     g_LIST_TEMPLATE || '?VERSION=' || g_VERSION ||
                     '&TEMPLATE=' || g_LIST_TEMPLATE || '&OUTPUT_FORMAT=' ||
                     g_OUTPUT_FORMAT || '&PRIMARY_PROVIDER_CODE=' ||
                     p_PROVIDER_CODE || '&PRIMARY_PROVIDER_DUNS=' ||
                     TO_CHAR(p_PROVIDER_DUNS) || '&RETURN_TZ=' || p_RETURN_TZ ||
                     '&LIST=' || p_LIST_NAME || '&TIME_OF_LAST_UPDATE= ';

      RUN_OASIS_EXCHANGE(p_FETCH_URL         => v_FETCH_URL,
                         p_REQUEST_TYPE      => MM_OASIS_UTIL.g_MEX_ACTION_QUERY,--'query',
                         p_CRED              => p_CRED,
                         p_REQUEST_DIRECTION => g_DOWNLOAD,
                         p_CLOB_REQUEST      => NULL,
                         p_LOGGER            => p_LOGGER,
                         p_CLOB_RESPONSE     => p_CLOB_RESPONSE);
	 IF p_CLOB_RESPONSE IS NOT NULL THEN
	 	p_LOGGER.LOG_INFO('OASIS ' || p_LIST_NAME || ' List succesfully downloaded.');
	 ELSE
	 	p_LOGGER.LOG_ERROR('Failed to retrieve the OASIS ' || p_LIST_NAME || ' List.');
	 END IF;

  EXCEPTION
      WHEN OTHERS THEN
        p_LOGGER.LOG_ERROR('Error in MEX_OASIS.OASIS_LIST_GET: ' || SQLERRM);
      	RAISE;
  END OASIS_LIST_GET;
----------------------------------------------------------------------------------------------------
PROCEDURE FETCH_TRANSSTATUS
(
    p_CREDENTIALS       IN MEX_CREDENTIALS,
    p_PROVIDER_CODE     IN VARCHAR2,
    p_OASIS_URL         IN VARCHAR2,
    p_BEGIN_DATE        IN DATE,
    p_END_DATE          IN DATE,
    p_RECORDS           IN OUT MEX_OASIS_TRANS,
    p_LOGGER            IN OUT NOCOPY MM_LOGGER_ADAPTER,
    p_OASIS_STATUS_LIST IN VARCHAR2 DEFAULT NULL,
    p_CUSTOMER_LIST     IN VARCHAR2 DEFAULT NULL,
    p_ASSIGNMENT_REF    IN VARCHAR2 DEFAULT NULL,
	p_STATUS            OUT NUMBER
) IS

    v_CLOB_RESPONSE CLOB;
    v_FETCH_URL     VARCHAR2(2000);
    v_START_TIME    VARCHAR2(16);
    v_STOP_TIME     VARCHAR2(16);
    v_CUSTOMER_LIST VARCHAR2(2000);
    v_STATUS_LIST   VARCHAR2(2000);
BEGIN
	p_STATUS := GA.SUCCESS;
    --https://sppoasis.spp.org/OASIS/SWPP/data/transstatus?VERSION=1.4&TEMPLATE=transstatus&
    --OUTPUT_FORMAT=data&SELLER=&SELLER_DUNS=&CUSTOMER=MIDW&CUSTOMER_DUNS=042379594
    --&POINT_OF_RECEIPT=&POINT_OF_DELIVERY=&PATH_NAME=&SERVICE_INCREMENT=
    --&TS_CLASS=&TS_TYPE=&TS_PERIOD=&TS_WINDOW=&TS_SUBCLASS=&STATUS=&NEGOCIATED_PRICE_FLAG=
    --&REQUEST_TYPE=&START_TIME=20051012000000CD&STOP_TIME=&START_TIME_QUEUED=
    --&STOP_TIME_QUEUED&TIME_OF_LAST_UPDATE=&RETURN_TZ=CD&ASSIGNMENT_REF=
    --&DEAL_REF=&REASSIGNED_REF=&REQUEST_REF=&SALE_REF=&RELATED_REF=

    --Create time string that have the zone appended at the end
    v_START_TIME := TO_CSV(p_BEGIN_DATE);
    v_STOP_TIME  := TO_CSV(p_END_DATE);

    v_CUSTOMER_LIST := GET_INPUT_LIST('CUSTOMER', p_CUSTOMER_LIST);
    v_STATUS_LIST   := GET_INPUT_LIST('STATUS', p_OASIS_STATUS_LIST);
    -- create the query
    v_FETCH_URL := p_OASIS_URL || p_PROVIDER_CODE || '/' || g_DATA_FORMAT || '/' ||
                   g_TRANSSTATUS_TEMPLATE || '?VERSION=' || g_VERSION ||
                   '&TEMPLATE=' || g_TRANSSTATUS_TEMPLATE || '&OUTPUT_FORMAT=' ||
                   g_OUTPUT_FORMAT || '&SELLER=' || '&SELLER_DUNS=' ||
                   v_CUSTOMER_LIST || '&CUSTOMER_DUNS=' || '&POINT_OF_RECEIPT=' ||
                   '&POINT_OF_DELIVERY=' || '&PATH_NAME=' ||
                   '&SERVICE_INCREMENT=' || '&TS_CLASS=' || '&TS_TYPE=' ||
                   '&TS_PERIOD=' || '&TS_WINDOW=' || '&TS_SUBCLASS=' ||
                   v_STATUS_LIST || '&NEGOCIATED_PRICE_FLAG' ||
                   '&REQUEST_TYPE=' || '&START_TIME=' || v_START_TIME ||
                   '&STOP_TIME=' || v_STOP_TIME || '&START_TIME_QUEUED=' ||
                   '&STOP_TIME_QUEUED=' || '&TIME_OF_LAST_UPDATE=' ||
                   '&RETURN_TZ=' || g_EXCHANGE_TZ || '&ASSIGNMENT_REF=' ||
                   p_ASSIGNMENT_REF || '&DEAL_REF=' || '&REASSIGNED_REF=' ||
                   '&REQUEST_REF=' || '&SALE_REF=' || '&RELATED_REF=';

    -- send the query, get the response CSV and return it
    p_LOGGER.LOG_INFO('Attempting to fetch Transmission Status Notifications');
    RUN_OASIS_EXCHANGE(p_FETCH_URL         => v_FETCH_URL,
                       p_REQUEST_TYPE      => MM_OASIS_UTIL.g_MEX_ACTION_QUERY, --'query',
                       p_CRED              => p_CREDENTIALS,
                       p_REQUEST_DIRECTION => g_DOWNLOAD,
                       p_CLOB_REQUEST      => NULL,
                       p_LOGGER            => p_LOGGER,
                       p_CLOB_RESPONSE     => v_CLOB_RESPONSE);

    IF v_CLOB_RESPONSE IS NOT NULL THEN
        p_LOGGER.LOG_INFO('Transmission Status Notifications succesfully downloaded.');
        p_RECORDS := MEX_OASIS_TRANS(NULL, NULL, NULL, NULL, NULL); -- reset
        PARSE_TRANSSTATUS_RESPONSE(v_CLOB_RESPONSE,p_LOGGER, p_RECORDS);
    ELSE
		p_STATUS := MEX_UTIL.g_FAILURE;
        p_LOGGER.LOG_ERROR('Failed to retrieve the Transmission Status Notifications');
    END IF;


EXCEPTION
    WHEN OTHERS THEN
		p_STATUS := MEX_UTIL.g_FAILURE;
        p_LOGGER.LOG_ERROR('Error in MEX_OASIS.FETCH_TRANSSTATUS ' || SQLERRM);

END FETCH_TRANSSTATUS;
	----------------------------------------------------------------------------------------------
    PROCEDURE FETCH_OASIS_LIST
    (
        p_EXT_CREDS     IN MEX_CREDENTIALS,
        p_PROVIDER_CODE IN VARCHAR2,
        p_PROVIDER_DUNS IN NUMBER,
        p_URL           IN VARCHAR2,
        p_RECORDS       IN OUT MEX_OASIS_LIST_RES_TBL,
        p_LOGGER        IN OUT NOCOPY MM_LOGGER_ADAPTER,
		p_STATUS        OUT NUMBER
    ) IS

        v_LIST_NAME   VARCHAR2(50);
        v_RESPONSE_CLOB CLOB;
        v_LIST_TBL    MEX_OASIS_LIST_ELEM_TBL;
        v_LIST_DATA   MEX_OASIS_LIST_ELEM;
        i             BINARY_INTEGER;

    BEGIN
		p_STATUS := GA.SUCCESS;
		p_LOGGER.LOG_INFO('Getting OASIS LIST');

        -- Get the list of lists
        v_LIST_NAME := 'LIST';
        p_LOGGER.LOG_INFO('Getting [' || v_LIST_NAME || '] ');

        -- Connect to source and request list, returns with CSV
        OASIS_LIST_GET(p_EXT_CREDS,
                       p_PROVIDER_CODE,
                       p_PROVIDER_DUNS,
                       p_URL,
                       g_EXCHANGE_TZ,
                       v_LIST_NAME,
                       v_RESPONSE_CLOB,
                       p_LOGGER);

        -- Parse CSV and return table of data
        IF v_RESPONSE_CLOB IS NOT NULL  THEN
            --Store the list of lists
            PARSE_LIST_OF_LISTS(v_RESPONSE_CLOB, p_LOGGER, v_LIST_TBL);

                --Loop through list of lists and get individual lists
                FOR I IN v_LIST_TBL.FIRST .. v_LIST_TBL.LAST LOOP
                    v_LIST_DATA := v_LIST_TBL(i);
                    v_LIST_NAME := v_LIST_DATA.LIST_NAME;

                    --Skip 'LIST', this elem doesn't have sublists
                    IF v_LIST_NAME != 'LIST' THEN
                        p_LOGGER.LOG_INFO('Getting [' || v_LIST_NAME || '] ');

                        -- Connect to source and request list, returns with CSV
                        OASIS_LIST_GET(p_EXT_CREDS,
                                       p_PROVIDER_CODE,
                                       p_PROVIDER_DUNS,
                                       p_URL,
                                       g_EXCHANGE_TZ,
                                       v_LIST_NAME,
                                       v_RESPONSE_CLOB,
                                       p_LOGGER);

                    IF v_RESPONSE_CLOB IS NOT NULL THEN
						p_LOGGER.LOG_INFO('Parsing [' || v_LIST_NAME || '] ' );
                            PARSE_LIST_ELEM(v_RESPONSE_CLOB, p_LOGGER, p_RECORDS);
					ELSE
						--Failed to retrieve the List; Set the status to Failure
						p_STATUS := MEX_UTIL.g_FAILURE;
                        END IF;

                    END IF;

                END LOOP;
		ELSE
			--Failed to retrieve the List; Set the status to Failure
			p_STATUS := MEX_UTIL.g_FAILURE;
        END IF;

    EXCEPTION
        WHEN OTHERS THEN
            p_LOGGER.LOG_ERROR('Error in processing OASIS [' || v_LIST_NAME || '] List: ' || SQLERRM);
			p_STATUS := MEX_UTIL.g_FAILURE;
    END FETCH_OASIS_LIST;
-------------------------------------------------------------------------------------------------------------------------
-- Transmission Services
-------------------------------------------------------------------------------------------------------------------------
	PROCEDURE SUBMIT_TRANSOFFERING(p_TAB      IN OUT MEX_OASIS_TRANS,
								   p_ExtCreds IN MEX_CREDENTIALS,
								   p_LOGGER IN OUT NOCOPY MM_LOGGER_ADAPTER) IS


		v_CSV CLOB;

	BEGIN
		NULL;
-- 		-- create the query CSV from the table
-- 		CREATE_TRANSOFFER_QUERY(v_CSV, p_TAB, p_Status, p_Message);
--
-- 		IF p_Status = g_Success THEN
-- 			-- send the query, get the response CSV and return it
--
--
-- 			RUN_OASIS_EXCHANGE(p_REQUEST_APP        => 'mex',
-- 							   p_REQUEST_TYPE       => 'oasis',
-- 							   p_CREDENTIALS        => p_ExtCreds,
-- 							   p_REQUEST_DIRECTION  => 'In',
-- 							   p_REQUEST_DATA       => v_CSV,
-- 							   p_CLOB_RESPONSE      => v_CSV,
-- 							   p_RESPONSE_EXTENSION => 'txt',
-- 							   p_LOG_ONLY           => 0,
-- 							   p_STATUS             => p_Status,
-- 							   p_MESSAGE            => p_Message);
--
-- 			IF p_Status = g_Success THEN
-- 				p_TAB := MEX_OASIS_TRANS(NULL, NULL, NULL, NULL, NULL); -- reset
-- 				PARSE_TRANSOFFER_RESPONSE(v_CSV,
-- 										  p_TAB,
-- 										  p_Status,
-- 										  p_Message);
-- 			END IF;
--
-- 		END IF;
	END SUBMIT_TRANSOFFERING;
-------------------------------------------------------------------------------------------------------------------------
PROCEDURE SUBMIT_TRANSREQUEST
(
    p_TAB         IN OUT MEX_OASIS_TRANS,
    p_CREDENTIALS IN MEX_CREDENTIALS,
    p_URL         IN VARCHAR2,
    p_LOGGER      IN OUT NOCOPY MM_LOGGER_ADAPTER,
	p_STATUS      OUT NUMBER
) IS

    v_CLOB_RESPONSE CLOB;
    v_CLOB_REQUEST  CLOB;
    v_FETCH_URL     VARCHAR2(4000);

BEGIN
    -- create the query CSV from the table
    CREATE_TRANSREQUEST_INPUT(v_CLOB_REQUEST, p_TAB, p_LOGGER);

        -- send the request, get the response CSV and return it
        v_FETCH_URL := p_URL || p_TAB.PRIMARY_PROVIDER_CODE || '/' || g_DATA_FORMAT || '/' || g_TRANSREQUEST_TEMPLATE;

        p_LOGGER.LOG_INFO('Attempting to submit a trasmission request');
        RUN_OASIS_EXCHANGE(p_FETCH_URL         => v_FETCH_URL,
                       p_REQUEST_TYPE      => MM_OASIS_UTIL.g_MEX_ACTION_SUBMIT, --'submit'
                           p_CRED              => p_CREDENTIALS,
                           p_REQUEST_DIRECTION => g_UPLOAD,
                           p_CLOB_REQUEST      => v_CLOB_REQUEST,
                           p_LOGGER            => p_LOGGER,
                           p_CLOB_RESPONSE     => v_CLOB_RESPONSE);

    IF v_CLOB_RESPONSE IS NOT NULL THEN
            p_LOGGER.LOG_INFO('Transmission request succesfully submitted.');
            p_TAB := MEX_OASIS_TRANS(NULL, NULL, NULL, NULL, NULL); -- reset
            PARSE_TRANSREQUEST_RESPONSE(v_CLOB_RESPONSE, p_LOGGER, p_TAB);
		p_STATUS := GA.SUCCESS;
        ELSE
            p_LOGGER.LOG_ERROR('Failed to submit a Transmission request');
		p_STATUS := MEX_UTIL.g_FAILURE;
        END IF;

END SUBMIT_TRANSREQUEST;
-------------------------------------------------------------------------------------------------------------------------
PROCEDURE SUBMIT_TRANSSELL
	(
	p_TAB IN OUT MEX_OASIS_TRANS,
	p_CREDENTIALS IN MEX_CREDENTIALS,
	p_URL IN VARCHAR2,
	p_LOGGER IN OUT NOCOPY MM_LOGGER_ADAPTER,
	p_STATUS      OUT NUMBER
	) IS

	v_CLOB_REQUEST CLOB;
	v_CLOB_RESPONSE CLOB;
	v_FETCH_URL VARCHAR2(4000);

BEGIN
	-- create the query CSV from the table
	CREATE_TRANSSELL_INPUT(v_CLOB_REQUEST, p_TAB, p_LOGGER);

		-- send the request, get the response CSV and return it
		v_FETCH_URL := p_URL || p_TAB.PRIMARY_PROVIDER_CODE || '/' || g_DATA_FORMAT || '/' || g_TRANSSELL_TEMPLATE;

		p_LOGGER.LOG_INFO('Attempting to submit a trasmission sell');
		RUN_OASIS_EXCHANGE(p_FETCH_URL   => v_FETCH_URL,
    			p_REQUEST_TYPE       => MM_OASIS_UTIL.g_MEX_ACTION_SUBMIT,--'submit',
				p_CRED               => p_CREDENTIALS,
				p_REQUEST_DIRECTION  => g_UPLOAD,
				p_CLOB_REQUEST       => v_CLOB_REQUEST,
				p_LOGGER 			 => p_LOGGER,
				p_CLOB_RESPONSE      => v_CLOB_RESPONSE);

    IF v_CLOB_RESPONSE IS NOT NULL THEN
			p_LOGGER.LOG_INFO('Transmission sell succesfully submitted.');
			p_TAB := MEX_OASIS_TRANS(NULL, NULL, NULL, NULL, NULL); -- reset
			PARSE_TRANSSELL_RESPONSE(v_CLOB_RESPONSE, p_LOGGER, p_TAB);
		p_STATUS := GA.SUCCESS;
		ELSE
            p_LOGGER.LOG_ERROR('Failed to submit a Transmission sell.');
		p_STATUS := MEX_UTIL.g_FAILURE;
        END IF;

END SUBMIT_TRANSSELL;
-------------------------------------------------------------------------------------------------------------------------
PROCEDURE SUBMIT_TRANSCUST
	(
	p_TAB IN OUT MEX_OASIS_TRANS,
	p_CREDENTIALS IN MEX_CREDENTIALS,
	p_URL IN VARCHAR2,
	p_LOGGER IN OUT NOCOPY mm_logger_adapter,
	p_STATUS      OUT NUMBER
	) IS

	v_CLOB_RESPONSE CLOB;
    v_CLOB_REQUEST  CLOB;
	v_FETCH_URL VARCHAR2(4000);

BEGIN
	-- create the query CSV from the table
	CREATE_TRANSCUST_INPUT(v_CLOB_REQUEST, p_TAB, p_LOGGER);

		-- send the request, get the response CSV and return it
		v_FETCH_URL := p_URL || p_TAB.PRIMARY_PROVIDER_CODE || '/' || g_DATA_FORMAT || '/' || g_TRANSCUST_TEMPLATE;
		p_LOGGER.LOG_INFO('Attempting to submit a trasmission customer request');
		RUN_OASIS_EXCHANGE(p_FETCH_URL         => v_FETCH_URL,
                           p_REQUEST_TYPE      => MM_OASIS_UTIL.g_MEX_ACTION_SUBMIT, --'submit'
                           p_CRED              => p_CREDENTIALS,
                           p_REQUEST_DIRECTION => g_UPLOAD,
                           p_CLOB_REQUEST      => v_CLOB_REQUEST,
                           p_LOGGER            => p_LOGGER,
                           p_CLOB_RESPONSE     => v_CLOB_RESPONSE);

    IF v_CLOB_RESPONSE IS NOT NULL THEN
			p_LOGGER.LOG_INFO('Transmission customer request succesfully submitted.');
			p_TAB := MEX_OASIS_TRANS(NULL, NULL, NULL, NULL, NULL); -- reset
			PARSE_TRANSCUST_RESPONSE(v_CLOB_RESPONSE, p_LOGGER, p_TAB);
		p_STATUS := GA.SUCCESS;
		ELSE
			p_LOGGER.LOG_ERROR('Failed to submit a Transmission customer request');
		p_STATUS := MEX_UTIL.g_FAILURE;
		END IF;


END SUBMIT_TRANSCUST;
-------------------------------------------------------------------------------------------------------------------------
PROCEDURE SUBMIT_TRANSASSIGN
	(
	p_TAB IN OUT MEX_OASIS_TRANS,
	p_CREDENTIALS IN MEX_CREDENTIALS,
	p_URL IN VARCHAR2,
	p_LOGGER IN OUT NOCOPY mm_logger_adapter,
	p_STATUS      OUT NUMBER
	) IS

	v_CLOB_RESPONSE CLOB;
    v_CLOB_REQUEST  CLOB;
	v_FETCH_URL VARCHAR2(4000);

BEGIN
	-- create the query CSV from the table
	CREATE_TRANSASSIGN_INPUT(v_CLOB_REQUEST, p_TAB, p_LOGGER);

		-- send the request, get the response CSV and return it
		v_FETCH_URL := p_URL || p_TAB.PRIMARY_PROVIDER_CODE || '/' || g_DATA_FORMAT || '/' || g_TRANSASSIGN_TEMPLATE;

		p_LOGGER.LOG_INFO('Attempting to submit a trasmission assign request');
        RUN_OASIS_EXCHANGE(p_FETCH_URL         => v_FETCH_URL,
                           p_REQUEST_TYPE      => MM_OASIS_UTIL.g_MEX_ACTION_SUBMIT, --'submit'
                           p_CRED              => p_CREDENTIALS,
                           p_REQUEST_DIRECTION => g_UPLOAD,
                           p_CLOB_REQUEST      => v_CLOB_REQUEST,
                           p_LOGGER            => p_LOGGER,
                           p_CLOB_RESPONSE     => v_CLOB_RESPONSE);

	IF v_CLOB_RESPONSE IS NOT NULL THEN
            p_LOGGER.LOG_INFO('Transmission assign request succesfully submitted.');
            p_TAB := MEX_OASIS_TRANS(NULL, NULL, NULL, NULL, NULL); -- reset
			PARSE_TRANSASSIGN_RESPONSE(v_CLOB_RESPONSE, p_LOGGER, p_TAB);
		p_STATUS := GA.SUCCESS;
        ELSE
            p_LOGGER.LOG_ERROR('Failed to submit a Transmission assign request');
		p_STATUS := MEX_UTIL.g_FAILURE;
        END IF;

END SUBMIT_TRANSASSIGN;
-------------------------------------------------------------------------------------------------------------------------
PROCEDURE SUBMIT_TRANSPOST
	(
	p_TAB IN OUT MEX_OASIS_TRANS,
	p_CREDENTIALS IN MEX_CREDENTIALS,
	p_URL IN VARCHAR2,
	p_LOGGER IN OUT NOCOPY mm_logger_adapter,
	p_STATUS      OUT NUMBER
	) IS

	v_CLOB_RESPONSE CLOB;
    v_CLOB_REQUEST  CLOB;
	v_FETCH_URL VARCHAR2(4000);

BEGIN
	-- create the query CSV from the table
	CREATE_TRANSPOST_INPUT(v_CLOB_REQUEST, p_TAB, p_LOGGER);


		-- send the request, get the response CSV and return it
		v_FETCH_URL := p_URL || p_TAB.PRIMARY_PROVIDER_CODE || '/' || g_DATA_FORMAT || '/' || g_TRANSPOST_TEMPLATE;

		p_LOGGER.LOG_INFO('Attempting to submit a trasmission post request');
        RUN_OASIS_EXCHANGE(p_FETCH_URL         => v_FETCH_URL,
                           p_REQUEST_TYPE      => MM_OASIS_UTIL.g_MEX_ACTION_SUBMIT, --'submit'
                           p_CRED              => p_CREDENTIALS,
                           p_REQUEST_DIRECTION => g_UPLOAD,
                           p_CLOB_REQUEST      => v_CLOB_REQUEST,
                           p_LOGGER            => p_LOGGER,
                           p_CLOB_RESPONSE     => v_CLOB_RESPONSE);

        IF v_CLOB_RESPONSE IS NOT NULL THEN
			p_LOGGER.LOG_INFO('Transmission oost request succesfully submitted.');
			p_TAB := MEX_OASIS_TRANS(NULL, NULL, NULL, NULL, NULL); -- reset
			PARSE_TRANSPOST_RESPONSE(v_CLOB_RESPONSE, p_LOGGER, p_TAB);
			p_STATUS := GA.SUCCESS;
		ELSE
			p_LOGGER.LOG_ERROR('Failed to submit a Transmission post request');
			p_STATUS := MEX_UTIL.g_FAILURE;
		END IF;


END SUBMIT_TRANSPOST;
-------------------------------------------------------------------------------------------------------------------------
PROCEDURE SUBMIT_TRANSUPDATE
	(
	p_TAB IN OUT MEX_OASIS_TRANS,
	p_CREDENTIALS IN MEX_CREDENTIALS,
	p_URL IN VARCHAR2,
	p_LOGGER IN OUT NOCOPY mm_logger_adapter,
	p_STATUS      OUT NUMBER
	) IS

	v_CLOB_RESPONSE CLOB;
    v_CLOB_REQUEST  CLOB;
	v_FETCH_URL VARCHAR2(4000);

BEGIN
	-- create the query CSV from the table
	CREATE_TRANSUPDATE_INPUT(v_CLOB_REQUEST, p_TAB, p_LOGGER);


		-- send the request, get the response CSV and return it
		v_FETCH_URL := p_URL || p_TAB.PRIMARY_PROVIDER_CODE || '/' || g_DATA_FORMAT || '/' || g_TRANSUPDATE_TEMPLATE;

		p_LOGGER.LOG_INFO('Attempting to submit a trasmission update request');
        RUN_OASIS_EXCHANGE(p_FETCH_URL         => v_FETCH_URL,
                           p_REQUEST_TYPE      => MM_OASIS_UTIL.g_MEX_ACTION_SUBMIT, --'submit'
                           p_CRED              => p_CREDENTIALS,
                           p_REQUEST_DIRECTION => g_UPLOAD,
                           p_CLOB_REQUEST      => v_CLOB_REQUEST,
                           p_LOGGER            => p_LOGGER,
                           p_CLOB_RESPONSE     => v_CLOB_RESPONSE);

        IF v_CLOB_RESPONSE IS NOT NULL THEN
            p_LOGGER.LOG_INFO('Transmission update request succesfully submitted.');
			p_TAB := MEX_OASIS_TRANS(NULL, NULL, NULL, NULL, NULL); -- reset
			PARSE_TRANSUPDATE_RESPONSE(v_CLOB_RESPONSE, p_LOGGER, p_TAB);
			p_STATUS := GA.SUCCESS;
		ELSE
			p_LOGGER.LOG_ERROR('Failed to submit a Transmission update request');
			p_STATUS := MEX_UTIL.g_FAILURE;
		END IF;

END SUBMIT_TRANSUPDATE;
-------------------------------------------------------------------------------------------------------------------------
-- Ancillary Services
-------------------------------------------------------------------------------------------------------------------------
/*
	PROCEDURE SUBMIT_ANCOFFERING(p_TAB      IN OUT MEX_OASIS_TRANS,
								 p_ExtCreds IN MEX_CREDENTIALS,
								 p_STATUS   OUT NUMBER,
								 P_MESSAGE  OUT VARCHAR2) IS

		v_CSV CLOB;

	BEGIN
		-- create the query CSV from the table
		CREATE_ANCOFFER_QUERY(v_CSV, p_TAB, p_Status, p_Message);

		IF p_Status = g_Success THEN
			-- send the query, get the response CSV and return it

			RUN_OASIS_EXCHANGE(p_REQUEST_APP        => 'mex',
							   p_REQUEST_TYPE       => 'oasis',
							   p_CREDENTIALS        => p_ExtCreds,
							   p_REQUEST_DIRECTION  => 'In',
							   p_REQUEST_DATA       => v_CSV,
							   p_CLOB_RESPONSE      => v_CSV,
							   p_RESPONSE_EXTENSION => 'txt',
							   p_LOG_ONLY           => 0,
							   p_STATUS             => p_Status,
							   p_MESSAGE            => p_Message);

			IF p_Status = g_Success THEN
				p_TAB := MEX_OASIS_TRANS(NULL, NULL, NULL, NULL, NULL); -- reset
				PARSE_ANCOFFER_RESPONSE(v_CSV, p_TAB, p_Status, p_Message);
			END IF;

		END IF;
	END SUBMIT_ANCOFFERING;
	-------------------------------------------------------------------------------------------------------------------------
	PROCEDURE SUBMIT_ANCREQUEST(p_TAB      IN OUT MEX_OASIS_TRANS,
								p_ExtCreds IN MEX_CREDENTIALS,
								p_STATUS   OUT NUMBER,
								P_MESSAGE  OUT VARCHAR2) IS

		v_CSV CLOB;

	BEGIN
		-- create the query CSV from the table
		CREATE_ANCREQUEST_INPUT(v_CSV, p_TAB, p_Status, p_Message);

		IF p_Status = g_Success THEN
			-- send the query, get the response CSV and return it

			RUN_OASIS_EXCHANGE(p_REQUEST_APP        => 'mex',
							   p_REQUEST_TYPE       => 'oasis',
							   p_CREDENTIALS        => p_ExtCreds,
							   p_REQUEST_DIRECTION  => 'In',
							   p_REQUEST_DATA       => v_CSV,
							   p_CLOB_RESPONSE      => v_CSV,
							   p_RESPONSE_EXTENSION => 'txt',
							   p_LOG_ONLY           => 0,
							   p_STATUS             => p_Status,
							   p_MESSAGE            => p_Message);

			IF p_Status = g_Success THEN
				p_TAB := MEX_OASIS_TRANS(NULL, NULL, NULL, NULL, NULL); -- reset
				PARSE_ANCREQUEST_RESPONSE(v_CSV,
										  p_TAB,
										  p_Status,
										  p_Message);
			END IF;

		END IF;
	END SUBMIT_ANCREQUEST;
	-------------------------------------------------------------------------------------------------------------------------
	PROCEDURE SUBMIT_ANCSTATUS(p_TAB      IN OUT MEX_OASIS_TRANS,
							   p_ExtCreds IN MEX_CREDENTIALS,
							   p_STATUS   OUT NUMBER,
							   P_MESSAGE  OUT VARCHAR2) IS

		v_CSV CLOB;

	BEGIN
		-- create the query CSV from the table
		CREATE_ANCSTATUS_QUERY(v_CSV, p_TAB, p_Status, p_Message);

		IF p_Status = g_Success THEN
			-- send the query, get the response CSV and return it

			RUN_OASIS_EXCHANGE(p_REQUEST_APP        => 'mex',
							   p_REQUEST_TYPE       => 'oasis',
							   p_CREDENTIALS        => p_ExtCreds,
							   p_REQUEST_DIRECTION  => 'In',
							   p_REQUEST_DATA       => v_CSV,
							   p_CLOB_RESPONSE      => v_CSV,
							   p_RESPONSE_EXTENSION => 'txt',
							   p_LOG_ONLY           => 0,
							   p_STATUS             => p_Status,
							   p_MESSAGE            => p_Message);

			IF p_Status = g_Success THEN
				p_TAB := MEX_OASIS_TRANS(NULL, NULL, NULL, NULL, NULL); -- reset
				PARSE_ANCSTATUS_RESPONSE(v_CSV, p_TAB, p_Status, p_Message);
			END IF;

		END IF;
	END SUBMIT_ANCSTATUS;
	-------------------------------------------------------------------------------------------------------------------------
	PROCEDURE SUBMIT_ANCSELL(p_TAB      IN OUT MEX_OASIS_TRANS,
							 p_ExtCreds IN MEX_CREDENTIALS,
							 p_STATUS   OUT NUMBER,
							 P_MESSAGE  OUT VARCHAR2) IS

		v_CSV CLOB;

	BEGIN
		-- create the query CSV from the table
		CREATE_ANCSELL_INPUT(v_CSV, p_TAB, p_Status, p_Message);

		IF p_Status = g_Success THEN
			-- send the query, get the response CSV and return it

			RUN_OASIS_EXCHANGE(p_REQUEST_APP        => 'mex',
							   p_REQUEST_TYPE       => 'oasis',
							   p_CREDENTIALS        => p_ExtCreds,
							   p_REQUEST_DIRECTION  => 'In',
							   p_REQUEST_DATA       => v_CSV,
							   p_CLOB_RESPONSE      => v_CSV,
							   p_RESPONSE_EXTENSION => 'txt',
							   p_LOG_ONLY           => 0,
							   p_STATUS             => p_Status,
							   p_MESSAGE            => p_Message);

			IF p_Status = g_Success THEN
				p_TAB := MEX_OASIS_TRANS(NULL, NULL, NULL, NULL, NULL); -- reset
				PARSE_ANCSELL_RESPONSE(v_CSV, p_TAB, p_Status, p_Message);
			END IF;

		END IF;
	END SUBMIT_ANCSELL;
	-------------------------------------------------------------------------------------------------------------------------
	PROCEDURE SUBMIT_ANCCUST(p_TAB      IN OUT MEX_OASIS_TRANS,
							 p_ExtCreds IN MEX_CREDENTIALS,
							 p_STATUS   OUT NUMBER,
							 P_MESSAGE  OUT VARCHAR2) IS

		v_CSV CLOB;

	BEGIN
		-- create the query CSV from the table
		CREATE_ANCCUST_INPUT(v_CSV, p_TAB, p_Status, p_Message);

		IF p_Status = g_Success THEN
			-- send the query, get the response CSV and return it

			RUN_OASIS_EXCHANGE(p_REQUEST_APP        => 'mex',
							   p_REQUEST_TYPE       => 'oasis',
							   p_CREDENTIALS        => p_ExtCreds,
							   p_REQUEST_DIRECTION  => 'In',
							   p_REQUEST_DATA       => v_CSV,
							   p_CLOB_RESPONSE      => v_CSV,
							   p_RESPONSE_EXTENSION => 'txt',
							   p_LOG_ONLY           => 0,
							   p_STATUS             => p_Status,
							   p_MESSAGE            => p_Message);

			IF p_Status = g_Success THEN
				p_TAB := MEX_OASIS_TRANS(NULL, NULL, NULL, NULL, NULL); -- reset
				PARSE_ANCCUST_RESPONSE(v_CSV, p_TAB, p_Status, p_Message);
			END IF;

		END IF;
	END SUBMIT_ANCCUST;
	-------------------------------------------------------------------------------------------------------------------------
	PROCEDURE SUBMIT_ANCASSIGN(p_TAB      IN OUT MEX_OASIS_TRANS,
							   p_ExtCreds IN MEX_CREDENTIALS,
							   p_STATUS   OUT NUMBER,
							   P_MESSAGE  OUT VARCHAR2) IS

		v_CSV CLOB;

	BEGIN
		-- create the query CSV from the table
		CREATE_ANCASSIGN_INPUT(v_CSV, p_TAB, p_Status, p_Message);

		IF p_Status = g_Success THEN
			-- send the query, get the response CSV and return it

			RUN_OASIS_EXCHANGE(p_REQUEST_APP        => 'mex',
							   p_REQUEST_TYPE       => 'oasis',
							   p_CREDENTIALS        => p_ExtCreds,
							   p_REQUEST_DIRECTION  => 'In',
							   p_REQUEST_DATA       => v_CSV,
							   p_CLOB_RESPONSE      => v_CSV,
							   p_RESPONSE_EXTENSION => 'txt',
							   p_LOG_ONLY           => 0,
							   p_STATUS             => p_Status,
							   p_MESSAGE            => p_Message);

			IF p_Status = g_Success THEN
				p_TAB := MEX_OASIS_TRANS(NULL, NULL, NULL, NULL, NULL); -- reset
				PARSE_ANCASSIGN_RESPONSE(v_CSV, p_TAB, p_Status, p_Message);
			END IF;

		END IF;
	END SUBMIT_ANCASSIGN;
	-------------------------------------------------------------------------------------------------------------------------
	PROCEDURE SUBMIT_ANCPOST(p_TAB      IN OUT MEX_OASIS_TRANS,
							 p_ExtCreds IN MEX_CREDENTIALS,
							 p_STATUS   OUT NUMBER,
							 P_MESSAGE  OUT VARCHAR2) IS

		v_CSV CLOB;

	BEGIN
		-- create the query CSV from the table
		CREATE_ANCPOST_INPUT(v_CSV, p_TAB, p_Status, p_Message);

		IF p_Status = g_Success THEN
			-- send the query, get the response CSV and return it

			RUN_OASIS_EXCHANGE(p_REQUEST_APP        => 'mex',
							   p_REQUEST_TYPE       => NULL,
							   p_CREDENTIALS        => p_ExtCreds,
							   p_REQUEST_DIRECTION  => 'In',
							   p_REQUEST_DATA       => v_CSV,
							   p_CLOB_RESPONSE      => v_CSV,
							   p_RESPONSE_EXTENSION => 'txt',
							   p_LOG_ONLY           => 0,
							   p_STATUS             => p_Status,
							   p_MESSAGE            => p_Message);

			IF p_Status = g_Success THEN
				p_TAB := MEX_OASIS_TRANS(NULL, NULL, NULL, NULL, NULL); -- reset
				PARSE_ANCPOST_RESPONSE(v_CSV, p_TAB, p_Status, p_Message);
			END IF;

		END IF;
	END SUBMIT_ANCPOST;
	-------------------------------------------------------------------------------------------------------------------------
	PROCEDURE SUBMIT_ANCUPDATE(p_TAB      IN OUT MEX_OASIS_TRANS,
							   p_ExtCreds IN MEX_CREDENTIALS,
							   p_STATUS   OUT NUMBER,
							   P_MESSAGE  OUT VARCHAR2) IS

		v_CSV CLOB;

	BEGIN
		-- create the query CSV from the table
		CREATE_ANCUPDATE_INPUT(v_CSV, p_TAB, p_Status, p_Message);

		IF p_Status = g_Success THEN
			-- send the query, get the response CSV and return it

			RUN_OASIS_EXCHANGE(p_REQUEST_APP        => NULL,
							   p_REQUEST_TYPE       => 'oasis',
							   p_CREDENTIALS        => p_ExtCreds,
							   p_REQUEST_DIRECTION  => 'In',
							   p_REQUEST_DATA       => v_CSV,
							   p_CLOB_RESPONSE      => v_CSV,
							   p_RESPONSE_EXTENSION => 'txt',
							   p_LOG_ONLY           => 0,
							   p_STATUS             => p_Status,
							   p_MESSAGE            => p_Message);

			IF p_Status = g_Success THEN
				p_TAB := MEX_OASIS_TRANS(NULL, NULL, NULL, NULL, NULL); -- reset
				PARSE_ANCUPDATE_RESPONSE(v_CSV, p_TAB, p_Status, p_Message);
			END IF;

		END IF;
	END SUBMIT_ANCUPDATE;
*/
-------------------------------------------------------------------------------------------------------------------------
-- Communications
----------------------------------------------------------------------------------------------------
FUNCTION IS_CONNECTION_LIVE RETURN BOOLEAN IS
BEGIN
	RETURN Get_Dictionary_Value('IsoConnectionLive', 0, 'MarketExchange', 'OASIS') = 1;
EXCEPTION
	WHEN OTHERS THEN
		RETURN FALSE;
END IS_CONNECTION_LIVE;
----------------------------------------------------------------------------------------------------
PROCEDURE RUN_OASIS_EXCHANGE
(
    p_FETCH_URL          IN VARCHAR2,
    p_REQUEST_TYPE       IN VARCHAR2,
    p_CRED               IN MEX_CREDENTIALS,
    p_REQUEST_DIRECTION  IN VARCHAR2,
    p_CLOB_REQUEST       IN CLOB,
	p_LOGGER             IN OUT NOCOPY MM_LOGGER_ADAPTER,
    p_CLOB_RESPONSE      OUT CLOB
) AS

    v_PARAMETER_MAP MEX_UTIL.PARAMETER_MAP;
    v_CLOB_REQUEST  CLOB;
    v_RESULT       MEX_RESULT;


BEGIN

    --Add appropiatge qstring parameters to map
    v_PARAMETER_MAP('url') := p_FETCH_URL;


	IF MM_OASIS_UTIL.g_LOG_ONLY THEN
        p_CLOB_RESPONSE := NULL;

        p_LOGGER.LOG_START('test.' || MM_OASIS_UTIL.g_MEX_MARKET, p_REQUEST_TYPE);
        p_LOGGER.LOG_ATTACHMENT('Request Body', g_REQUEST_CONTENT_TYPE, v_CLOB_REQUEST);
        p_LOGGER.LOG_STOP(0, 'Success');

    ELSE
        --Invoke the MEX Switchboard
        v_RESULT := MEX_SWITCHBOARD.Invoke(p_Market => MM_OASIS_UTIL.g_MEX_MARKET,
							           p_Action => p_REQUEST_TYPE,
									   p_Logger => p_LOGGER,
									   p_Cred => p_CRED,
									   p_Parms => v_PARAMETER_MAP,
									   p_Request_ContentType => g_REQUEST_CONTENT_TYPE,
									   p_Request => p_CLOB_REQUEST);

        IF v_RESULT.STATUS_CODE <> MEX_Switchboard.c_Status_Success THEN
            p_CLOB_RESPONSE := NULL; -- this indicates failure - MEX_Switchboard.Invoke will have already logged error message
        ELSE
            p_CLOB_RESPONSE := v_RESULT.RESPONSE;
        END IF;
    END IF;

END RUN_OASIS_EXCHANGE;
------------------------------------------------------------------------------------------------------------

END MEX_OASIS;
/
