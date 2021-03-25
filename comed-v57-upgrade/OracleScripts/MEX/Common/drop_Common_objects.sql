DROP TYPE MEX_COOKIE_TBL;
DROP TYPE MEX_COOKIE;
DROP TYPE MEX_SCHEDULE_TBL;
DROP TYPE MEX_SCHEDULE;
DROP TYPE MEX_STATUS_TABLE;
DROP TYPE MEX_STATUS_TYPE;
DROP TYPE MEX_QUANTITY_TABLE;
DROP TYPE MEX_QUANTITY_TYPE;
DROP TYPE MEX_PRICE_QUANTITY_TABLE;
DROP TYPE MEX_PRICE_QUANTITY_TYPE;
DROP TYPE CLOB_CHUNK_TABLE;
DROP TYPE CLOB_CHUNK_TYPE;
DROP TYPE EXTERNAL_CREDENTIAL_TBL;
DROP TYPE EXTERNAL_CREDENTIAL;


-- now drop types needed by the switchboard - order matters
-- executed in the wrong order, the drops will fail

prompt Now dropping types for the MEX Switchboard...


prompt Dropping all objects that extend or referenced MEX_LOGGER and MEX_CREDENTIALS
prompt (required prior to dropping MEX_LOGGER and MEX_CREDENTIALS themselves).
prompt You will need to re-compile the following objects after re-building MEX_CREDENTIALS:

select name
from all_dependencies
where owner=user
and type='TYPE'
and referenced_owner=user
and referenced_type='TYPE'
and referenced_name='MEX_CREDENTIALS';

prompt And you will need to re-compile these objects after re-building MEX_LOGGER:

select name
from all_dependencies
where owner=user
and type='TYPE'
and referenced_owner=user
and referenced_type='TYPE'
and referenced_name='MEX_LOGGER';

DECLARE
  PROCEDURE DROP_TYPE(p_TYPE_NAME IN VARCHAR2) IS
    CURSOR c_SUBTYPES IS
	select name
	from all_dependencies
	where owner=user
	and type='TYPE'
	and referenced_owner=user
	and referenced_type='TYPE'
	and referenced_name=p_TYPE_NAME;
    v_COUNT BINARY_INTEGER;
  BEGIN
    -- if named object no longer exists, don't bother
    SELECT COUNT(1) INTO v_COUNT
    FROM ALL_TYPES WHERE OWNER=USER AND TYPE_NAME=p_TYPE_NAME;

    IF v_COUNT > 0 THEN
	-- must first drop all descendants
	FOR v_SUBTYPE IN c_SUBTYPES LOOP
	  DROP_TYPE(v_SUBTYPE.NAME);
	END LOOP;
	-- then drop the type itself
        EXECUTE IMMEDIATE 'DROP TYPE '||p_TYPE_NAME;
    END IF;
  END DROP_TYPE;
BEGIN
  DROP_TYPE('MEX_LOGGER');
  DROP_TYPE('MEX_CREDENTIALS');
END;
/

DROP TYPE MEX_CERTIFICATE_TBL;
DROP TYPE MEX_CERTIFICATE;

DROP TYPE MEX_RESULT;

-- now we can finally drop these last two
DROP TYPE MEX_COOKIE_TBL;
DROP TYPE MEX_COOKIE;