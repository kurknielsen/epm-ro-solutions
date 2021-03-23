prompt GEOGRAPHY_US_STATES_PROVINCES
@@GEOGRAPHY_US_STATES_PROVINCES.sql
prompt COMMON_TRANSACTION_TRAITS
@@COMMON_TRANSACTION_TRAITS.sql
prompt CONDITIONAL_FORMATS
@@CONDITIONAL_FORMATS.sql

prompt GRANT_EXECUTE_EXCLUSIONS
@@GRANT_EXECUTE_EXCLUSIONS.sql
prompt GRANT_OBJECTS
@@GRANT_OBJECTS.sql

-- Create "Committed" Option ID for IT Assignments
BEGIN
    INSERT INTO IT_ASSIGNMENT_OPTION
    	(OPTION_ID, TO_TRANSACTION_ID, FROM_TRANSACTION_ID, ASSIGNMENT_TYPE, OTHER_TRANSACTION_ID, 
         BEGIN_DATE, END_DATE, STATUS, NOTES, LAST_EVALUATED)
    VALUES
		(0,NULL, NULL, '?', NULL,
		 NULL,NULL,NULL,NULL,NULL);
    COMMIT;
EXCEPTION
	WHEN DUP_VAL_ON_INDEX THEN
		NULL;
END;
/

prompt REACTOR_SETUP
@@REACTOR_SETUP.sql
