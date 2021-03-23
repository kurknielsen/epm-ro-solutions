-- CVS Revision: $Revision: 1.7 $

set serveroutput on

prompt Setting user role to super-user...
@@SU.sql

-- can't proceed if SEM setup hasn't been run
WHENEVER SQLERROR EXIT FAILURE

DECLARE
v_SC_ID NUMBER(9);
BEGIN
	SELECT SC_ID INTO v_SC_ID
	FROM SCHEDULE_COORDINATOR
	WHERE SC_ALIAS = 'SEM';
EXCEPTION
	WHEN NO_DATA_FOUND THEN
		DBMS_OUTPUT.PUT_LINE(' ');
		DBMS_OUTPUT.PUT_LINE('-------------------------------------------------------------');
		DBMS_OUTPUT.PUT_LINE('ERROR: SetupMarket.sql for SEM market must be run first.');
		DBMS_OUTPUT.PUT_LINE('-------------------------------------------------------------');
		DBMS_OUTPUT.PUT_LINE(' ');
		RAISE_APPLICATION_ERROR(-20000, 'ERROR: SetupMarket.sql for SEM market must be run first.');
END;
/

-- restore error handling to SQL*PLUS defaults
WHENEVER SQLERROR CONTINUE NONE



SET DEFINE OFF

prompt Enabling TDIE external system...
BEGIN
UPDATE EXTERNAL_SYSTEM SET IS_ENABLED=1 WHERE EXTERNAL_SYSTEM_ID=EC.ES_TDIE;
END;
/

prompt TDIE System Settings
@@TDIE_system_dictionary.sql

prompt TDIE System Label
@@TDIE_system_label.sql

prompt TDIE Statement Types
@@TDIE_STATEMENT_TYPES.sql

prompt ESBN and NIE SCs, EDCs, PSEs
@@SetupBusinessEntities.sql

prompt Calc Process and Reactor Config for calculating SU net demand
@@SetupCalcProcessAndReactor.sql

prompt TDIE Scheduled Jobs
@@SetupJobs.sql

prompt Setup System Actions
@@SetupSystemActions.sql

prompt Setup Triggers
@@SetupTriggers.sql

prompt Entity Attributes
@@TDIE_EntityAttributes.sql

prompt createTDIESystemConfig.sql
@@createTDIESystemConfig.sql

prompt Layouts
@@LayoutDefaultsTDIE.sql

prompt Indexes
@@TDIE_indexes.sql

commit;

SET DEFINE ON
