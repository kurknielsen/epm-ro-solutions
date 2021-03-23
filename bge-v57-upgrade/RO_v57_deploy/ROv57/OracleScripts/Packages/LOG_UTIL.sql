CREATE OR REPLACE PACKAGE LOG_UTIL IS
-- $Revision: 1.3 $

-- Queries for log events for the specified process and entity.
-- %param p_ENTITY_DOMAIN_ID		The ID of the entity’s domain.
-- %param p_ENTITY_ID			The entity’s ID.
-- %param p_PROCESS_ID			ID of the Process from which to query events.
--			This value is optional: NULL means return events
--			from any and all processes.
-- %param p_BEGIN_DATE			The start of date range of events to query. This 
--			value is optional: NULL means no low constraint on
--			event timestamps.
-- %param p_END_DATE			The end of date range of events to query. This 
--			value is optional: NULL means no high constraint on
--			event timestamps.
-- %param p_CURSOR			Query results. This set will be in the same format
--			as LOG_REPORTS.GET_PROCESS_EVENTS.
FUNCTION WHAT_VERSION RETURN VARCHAR2;

PROCEDURE LOG_EVENTS_BY_ENTITY
	(
	p_ENTITY_DOMAIN_ID IN NUMBER,
	p_ENTITY_ID IN NUMBER,
	p_PROCESS_ID IN NUMBER,
	p_BEGIN_DATE IN TIMESTAMP,
	p_END_DATE IN TIMESTAMP,
	p_CURSOR OUT GA.REFCURSOR,
	p_SOURCE_DATE IN DATE := NULL
	);

END LOG_UTIL;
/
CREATE OR REPLACE PACKAGE BODY LOG_UTIL IS
-----------------------------------------------------------------
FUNCTION WHAT_VERSION RETURN VARCHAR2 IS
BEGIN
    RETURN '$Revision: 1.3 $';
END WHAT_VERSION;
---------------------------------------------------------------------------------------------------
PROCEDURE LOG_EVENTS_BY_ENTITY
	(
	p_ENTITY_DOMAIN_ID IN NUMBER,
	p_ENTITY_ID IN NUMBER,
	p_PROCESS_ID IN NUMBER,
	p_BEGIN_DATE IN TIMESTAMP,
	p_END_DATE IN TIMESTAMP,
	p_CURSOR OUT GA.REFCURSOR,
	p_SOURCE_DATE IN DATE := NULL
	) AS
	
BEGIN

	OPEN p_CURSOR FOR
		SELECT TO_CHAR(E.EVENT_ID) AS EVENT_ID,
			   (SELECT (CASE
						   WHEN COUNT(1) > 0 THEN
							'*'
						   ELSE
							''
					   END)
				FROM PROCESS_LOG_EVENT_DETAIL
				WHERE EVENT_ID = E.EVENT_ID) AS ATTACHMENT_DETAILS_AVAL,
			   CASE
				   WHEN E.MESSAGE_ID IS NULL THEN
					''
				   ELSE
					'->'
			   END AS MESSAGE_DETAILS_AVAL,
			   LOG_REPORTS.GET_LOG_LEVEL_STRING(E.EVENT_LEVEL) AS "LEVEL",
			   E.EVENT_TIMESTAMP AS TIME,
			   E.PROCEDURE_NAME AS "PROCEDURE",
			   E.STEP_NAME AS STEP,
			   LOG_REPORTS.GET_SOURCE_STRING(E.SOURCE_NAME,E.SOURCE_DOMAIN_ID,E.SOURCE_ENTITY_ID,E.SOURCE_DATE) AS "SOURCE",
			   E.EVENT_TEXT AS MESSAGE,
			   E.EVENT_ERRM AS ERROR,
			   E.MESSAGE_ID
		FROM PROCESS_LOG_EVENT E
		WHERE E.PROCESS_ID = NVL(p_PROCESS_ID, E.PROCESS_ID)
			AND E.EVENT_TIMESTAMP BETWEEN NVL(p_BEGIN_DATE, CONSTANTS.LOW_DATE) AND 
											NVL(p_END_DATE, CONSTANTS.HIGH_DATE)
			AND E.SOURCE_DATE = NVL(p_SOURCE_DATE, E.SOURCE_DATE)
			AND E.SOURCE_DOMAIN_ID = p_ENTITY_DOMAIN_ID
			AND E.SOURCE_ENTITY_ID = p_ENTITY_ID
		ORDER BY E.EVENT_TIMESTAMP, E.EVENT_ID;
			
END LOG_EVENTS_BY_ENTITY;
-----------------------------------------------------------------
END LOG_UTIL;
/
