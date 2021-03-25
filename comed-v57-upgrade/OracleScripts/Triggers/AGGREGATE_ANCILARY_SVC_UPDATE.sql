CREATE OR REPLACE TRIGGER AGGREGATE_ANCILARY_SVC_UPDATE 
	BEFORE INSERT OR UPDATE ON AGGREGATE_ANCILLARY_SERVICE 
	FOR EACH ROW 
BEGIN 
	IF NOT GA.VERSION_AGGREGATE_ANCILARY_SVC THEN
		:new.AS_OF_DATE := LOW_DATE; 
	END IF; 
END AGGREGATE_ANCILARY_SVC_UPDATE;
/ 