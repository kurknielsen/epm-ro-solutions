declare
	procedure create_syn(p_syn in varchar2, p_for in varchar2) as
		v_count pls_integer;
	begin
		select count(1) into v_count
		from user_synonyms
		where synonym_name = upper(p_syn);
		
		-- create if it doesn't already exist
		if v_count = 0 then
			execute immediate 'CREATE SYNONYM '||p_syn||' FOR '||p_for;
			dbms_output.put_line('Synonym '||p_syn||' created.');
		end if;
	exception
		when others then
			DBMS_OUTPUT.PUT_LINE(UTL_TCP.CRLF || 'ERROR: Could not create synonym ' || p_syn || ' for ' || p_for);
			DBMS_OUTPUT.PUT_LINE('Details: ' || SQLERRM);
	end create_syn;
begin
	create_syn('DER', 'DISTRIBUTED_ENERGY_RESOURCE');
	create_syn('EDC', 'ENERGY_DISTRIBUTION_COMPANY');
	create_syn('ESP', 'ENERGY_SERVICE_PROVIDER');
	create_syn('MRSP', 'METER_READING_SERVICE_PROVIDER');
	create_syn('PSE', 'PURCHASING_SELLING_ENTITY');
	create_syn('SC', 'SCHEDULE_COORDINATOR');
	create_syn('TP', 'TRANSMISSION_PROVIDER');
	create_syn('VPP', 'VIRTUAL_POWER_PLANT');
end;
/


