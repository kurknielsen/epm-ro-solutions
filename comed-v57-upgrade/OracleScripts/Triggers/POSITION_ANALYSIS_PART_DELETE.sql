CREATE OR REPLACE TRIGGER POSITION_ANALYSIS_PART_DELETE
	AFTER DELETE ON POSITION_ANALYSIS_PARTICIPANT 
	FOR EACH ROW
BEGIN
	DELETE POSITION_ANALYSIS_ENROLLMENT
	WHERE EVALUATION_ID = :old.EVALUATION_ID
		AND PARTICIPANT_ID = :old.PARTICIPANT_ID;
END POSITION_ANALYSIS_PART_DELETE;
/
