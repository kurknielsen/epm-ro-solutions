CREATE OR REPLACE TRIGGER LOAD_PROFILE_WRF_UPDATE 
	BEFORE INSERT OR UPDATE ON LOAD_PROFILE_WRF
	FOR EACH ROW 
BEGIN 
	IF NOT GA.VERSION_PROFILE THEN
		:new.AS_OF_DATE := LOW_DATE; 
	END IF; 
END LOAD_PROFILE_WRF_UPDATE;
/ 
