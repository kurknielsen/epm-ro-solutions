CREATE OR REPLACE PACKAGE SCHEDULE_MANAGEMENT_SYNC IS
-- $Revision: 1.3 $

FUNCTION WHAT_VERSION RETURN VARCHAR2;

-- Builds an export file to send to Schedule Management.
-- %return	CLOB of file to pass to Schedule Management. Contents will include --		all data present in IT_SCHEDULE_MANGEMENT_STAGING temp table.
FUNCTION BUILD_FILE RETURN CLOB;

-- Submits an export file to Schedule Management.
-- %param p_FILE	A CLOB with the data being sent to Schedule Management.
PROCEDURE SUBMIT_FILE
	(
	p_FILE IN CLOB
	);

-- Submits a set of changes for synchronization with Schedule Management. All
-- data staged in IT_SCHEDULE_MANAGEMENT_STAGING will be sent.
PROCEDURE SUBMIT;


END SCHEDULE_MANAGEMENT_SYNC;
/
CREATE OR REPLACE PACKAGE BODY SCHEDULE_MANAGEMENT_SYNC IS

c_SCHEDULE_MGMT_NAMESPACE CONSTANT VARCHAR2(128) := 'http://epm.ventyx.com/';
c_MARKET_SCHED_MGMT CONSTANT VARCHAR2(64) := 'schedmgmt';
c_ACTION_SCHED_MGMT_SUBMIT CONSTANT VARCHAR2(64) := 'submit';
--------------------------------------------------------------------------------
FUNCTION WHAT_VERSION RETURN VARCHAR2 IS
BEGIN
    RETURN '$Revision: 1.3 $';
END WHAT_VERSION;
---------------------------------------------------------------------------------------------------
FUNCTION BUILD_FILE RETURN CLOB AS
	v_RESULT XMLTYPE;
BEGIN
	-- Build the Schedule XML 
	SELECT XMLELEMENT("scheduleManagementSyncRequest", XMLATTRIBUTES(c_SCHEDULE_MGMT_NAMESPACE AS "xmlns"),
			XMLAGG(
				XMLELEMENT("syncItem",
					XMLELEMENT("scheduleName", S.SCHED_MGMT_CID),
					XMLELEMENT("dataSource", S.SCHED_MGMT_DATA_SOURCE),
					XMLELEMENT("schedule",
						XMLAGG(
							
								XMLELEMENT("scheduleItem",
									XMLELEMENT("startDateTime", DATE_UTIL.TO_CHAR_ISO(CASE WHEN DATE_UTIL.IS_SUB_DAILY_NUM(S.INTERVAL) = 1
																						THEN DATE_UTIL.GET_INTERVAL_BEGIN_DATE(S.SCHEDULE_DATE, GET_INTERVAL_ABBREVIATION(S.INTERVAL))
																						ELSE S.SCHEDULE_DATE END)),
									XMLELEMENT("endDateTime", DATE_UTIL.TO_CHAR_ISO(CASE WHEN DATE_UTIL.IS_SUB_DAILY_NUM(S.INTERVAL) = 1
																						THEN S.SCHEDULE_DATE
																						ELSE DATE_UTIL.GET_INTERVAL_END_DATE(S.SCHEDULE_DATE, GET_INTERVAL_ABBREVIATION(S.INTERVAL)) END)),
									XMLELEMENT("volume", S.AMOUNT)							
							)
						ORDER BY S.SCHEDULE_DATE
						)
					)					
				)
			ORDER BY S.SCHED_MGMT_CID, S.SCHED_MGMT_DATA_SOURCE
			)
		)
	INTO v_RESULT
	FROM IT_SCHEDULE_MANAGEMENT_STAGING S
	GROUP BY S.SCHED_MGMT_CID, S.SCHED_MGMT_DATA_SOURCE;

	RETURN v_RESULT.GETCLOBVAL();
END BUILD_FILE;
--------------------------------------------------------------------------------
PROCEDURE SUBMIT_FILE
	(
	p_FILE IN CLOB
	) AS
BEGIN	
	MEX_UTIL.SEND_MESSAGE(p_MARKET => c_MARKET_SCHED_MGMT,
						 p_ACTION => c_ACTION_SCHED_MGMT_SUBMIT,
						 p_EXTERNAL_SYSTEM_ID => EC.ES_SCHEDULE_MANAGEMENT ,
						 p_EXTERNAL_ACCOUNT_NAME => NULL,
						 p_REQUEST_CLOB => p_FILE); 
END SUBMIT_FILE;
--------------------------------------------------------------------------------
PROCEDURE SUBMIT AS
BEGIN
	SUBMIT_FILE(BUILD_FILE);
END SUBMIT;
--------------------------------------------------------------------------------
END SCHEDULE_MANAGEMENT_SYNC;
/
