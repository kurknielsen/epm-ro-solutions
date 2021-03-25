CREATE OR REPLACE TRIGGER LOAD_FORECAST_SCENARIO_DELETE
  BEFORE DELETE ON LOAD_FORECAST_SCENARIO 
  FOR EACH ROW 
  
DECLARE
  
BEGIN

  DELETE FROM SERVICE_LOAD LOAD
  WHERE LOAD.SERVICE_ID IN (SELECT SERVICE_ID
  							FROM SERVICE SERV
							WHERE SERV.SCENARIO_ID = :old.SCENARIO_ID);
							
  DELETE SERVICE
  WHERE SCENARIO_ID = :old.SCENARIO_ID;
  
  DELETE SERVICE_OBLIGATION_LOAD LOAD
  WHERE LOAD.SERVICE_OBLIGATION_ID IN (SELECT OBL.SERVICE_OBLIGATION_ID
  										FROM SERVICE_OBLIGATION OBL
										WHERE OBL.SCENARIO_ID = :old.SCENARIO_ID);
									
  DELETE SERVICE_OBLIGATION
  WHERE SCENARIO_ID = :old.SCENARIO_ID;
  
  DELETE EDC_SYSTEM_UFE_LOAD UFE
  WHERE UFE.SCENARIO_ID = :old.SCENARIO_ID;

END LOAD_FORECAST_SCENARIO_DELETE;
/
