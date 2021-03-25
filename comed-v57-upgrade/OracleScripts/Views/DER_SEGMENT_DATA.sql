CREATE OR REPLACE VIEW DER_SEGMENT_DATA AS
  SELECT RST.PROGRAM_ID, RST.SERVICE_ZONE_ID, RST.SUB_STATION_ID, 
  	RST.FEEDER_ID, RST.FEEDER_SEGMENT_ID, RST.EXTERNAL_SYSTEM_ID, 
  	RST.IS_EXTERNAL, RST.SERVICE_CODE, RST.SCENARIO_ID, 
	DT.RESULT_DATE, DT.LOAD_VAL, DT.FAILURE_VAL, DT.OPT_OUT_VAL, 
	DT.OVERRIDE_VAL, DT.TX_LOSS_VAL, DT.DX_LOSS_VAL, DT.DER_COUNT, 
	DT.UNCONSTRAINED_LOAD_VAL, DT.UNCONSTRAINED_TX_LOSS_VAL, 
	DT.UNCONSTRAINED_DX_LOSS_VAL
    FROM DER_SEGMENT_RESULT RST,
		DER_SEGMENT_RESULT_DATA DT
	WHERE DT.DER_SEGMENT_RESULT_ID = RST.DER_SEGMENT_RESULT_ID;