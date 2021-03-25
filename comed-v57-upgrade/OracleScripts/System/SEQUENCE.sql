declare
	procedure create_seq
			(
			p_name in varchar2,
			p_start_with in number := 1,
			p_increment in number := 1,
			p_min in number := null,
			p_max in number := null,
			p_cache in number := null,
			p_cycle in boolean := false,
			p_order in boolean := false
			) is
		v_count pls_integer;
		v_value number := 0;
	begin
		select count(1) into v_count
		from user_sequences
		where sequence_name = upper(p_name);
		
		-- create if it doesn't already exist
		if v_count = 0 then
			
			execute immediate 'create sequence '||p_name||' start with '||p_start_with||
								' increment by '||p_increment||
								case when p_min is not null then ' minvalue '||p_min else '' end||
								case when p_max is not null then ' maxvalue '||p_max else '' end||
								case when p_cache is not null then ' cache '||p_cache else '' end||
								case when p_cycle then ' cycle ' else '' end||
								case when p_order then ' order ' else '' end;
								
			dbms_output.put_line('Sequence '||p_name||' created.');
		elsif not p_cycle then
			-- roll the sequence to make sure it is seeded properly
			-- (i.e. make sure "nextval" won't return a value lower
			-- than specified p_start_with)
			while v_value < p_start_with loop
				execute immediate 'select '||p_name||'.nextval from dual' into v_value;
			end loop;
			dbms_output.put_line('Sequence '||p_name||' rolled to '||v_value);
		end if;
	exception
		when others then
			DBMS_OUTPUT.PUT_LINE(UTL_TCP.CRLF || 'ERROR: Could not create/update sequence ' || p_name);
			DBMS_OUTPUT.PUT_LINE('Details: ' || SQLERRM);
	end create_seq;
begin
	-- Objects and Entities
	create_seq('OID', 5000);
	-- Customer Entity
	create_seq('EID', 100);
	-- Load Obligation
	create_seq('RID');
	-- Bill Statement
	create_seq('BID');
	-- Invoice
	create_seq('IID');
	-- Quote Management
	create_seq('QID');
	-- Consumption
	create_seq('CID');
	-- Service
	create_seq('SID');
	-- System Object
	create_seq('MID');
	-- Audit Trail Id
	create_seq('AID');
	-- E-mail Log
	create_seq('MLID');
	-- ETAG Id
	create_seq('ETID',100);
	-- Market EXchange Id
	create_seq('MEXID');
	-- Work table Id
	create_seq('WID');
	-- Create sequence for Process_Log
	create_seq('PROCESS_ID',1,1,1,99999,20,true,true);
	-- Create sequence for Process_Log_Events	
	create_seq('EVENT_ID',0,1,0,99999999999,20,true,true);
	-- Create sequence with large cache for Process_Log_Trace and Process_Log_Temp_Trace
	create_seq('TRACE_EVENT_ID',0,1,0,99999999999,1000,true,true);
	-- Create sequence for calculation process runs
	create_seq('RUN_ID');
	-- Create sequence that will be used for generating the names of the AUDIT table constraints
	create_seq('AUDIT_KEY');
	-- Create sequence for the BACKGROUND_CLOB_STAGING and BACKGROUND_BLOB_STAGING tables.
	create_seq('BACKGROUND_LOB_ID');
	-- Create sequence for the JOB_QUEUE_ITEM table used for the Process Queues functionality
	create_seq('JOB_QUEUE_ITEM_ID');
	-- Create sequence for the DER forecasting result IDs
	create_seq('DER_RESULT_ID');
	-- create sequence for DR_EVENT's auto name generation
	create_seq('DR_EVENT_NAME');
	-- create sequence for PROGRAM_BILLING
	create_seq('PROGRAM_BILL_ID');
	-- create sequence for SYSTEM_MESSAGE
	create_seq('SYSTEM_MESSAGE_ID');
	-- create sequence for Retail Settlements
	create_seq('RETAIL_INVOICE_ID');
	-- CREATE SEQUENCE FOR TEMPLATE_DAY_TYPE
	CREATE_SEQ('DAY_TYPE_ID');
	-- create sequence for Retail Invoice Disputes
	CREATE_SEQ('DISPUTE_ID');
end;
/
