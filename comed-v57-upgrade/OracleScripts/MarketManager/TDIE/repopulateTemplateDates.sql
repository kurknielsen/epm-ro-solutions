/*
* This script programmagically follows the steps required to fix TOU Templates after the migration of a schema. 
* An error on the forecast run is thrown because the migration touches the SEASON_TEMPLATE table, invalidating 
* TEMPLATE_DATES records.
* The steps required in the UI (in order):
* 1) Navigate to each TOU Template in the Entity Manager and click Save
* 2) Re-populate Template Dates for the time-frame in question
* 3) Re-run settlement

* NOTE: This script must be run after the environment is rebuilt by the migration as it relies on the EM and IO APIs.
*/

WHENEVER SQLERROR EXIT SQL.CODE;
SET DEFINE OFF;

DECLARE
	v_PROCESS_ID VARCHAR2(100);
	v_PROCESS_STATUS VARCHAR2(256);
	v_MESSAGE VARCHAR2(256);

	v_TEMP_ID NUMBER(9);
	v_TEMP_MESSAGE VARCHAR2(256);

	v_TOU_LIST STRING_COLLECTION := STRING_COLLECTION('IE T' || CONSTANTS.AMPERSAND || 'D 24H','IE T' || CONSTANTS.AMPERSAND || 'D Day/Night','NI UoS Unit Charges TOU','Anytime TOU Template','NI UoS Reactive Power TOU');

BEGIN

	SECURITY_CONTROLS.SET_CURRENT_USER('ventyxadmin');

	-- For each Template in the string collection, get the ID from the name (EI), call the save method.
	FOR v_IDX IN v_TOU_LIST.FIRST..v_TOU_LIST.LAST LOOP
  	v_TEMP_ID := EI.GET_ID_FROM_NAME(v_TOU_LIST(v_IDX),EC.ED_TEMPLATE);
		EM.VALIDATE_TOU_TEMPLATE(v_TEMP_ID,v_TEMP_MESSAGE);
	END LOOP;


	--Populate Template Dates for the necessary date range
	EM.FILL_TEMPLATE_DATES((DATE '2007-01-01' + INTERVAL '00' HOUR + INTERVAL '00' MINUTE + INTERVAL '00' SECOND),
		(DATE '2013-12-31' + INTERVAL '00' HOUR + INTERVAL '00' MINUTE + INTERVAL '00' SECOND),
		STRING_COLLECTION('EDT'),
		v_PROCESS_ID,
		v_PROCESS_STATUS,
		v_MESSAGE);

END;
/
