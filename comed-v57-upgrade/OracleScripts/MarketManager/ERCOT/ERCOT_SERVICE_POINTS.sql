DECLARE 
    -- $Revision $
    PROCEDURE CREATE_SERVICE_POINT
	(
	p_SERVICE_POINT_NAME IN VARCHAR2,
	p_EXTERNAL_IDENTIFIER IN VARCHAR2,
    p_NODE_TYPE IN VARCHAR2
	) AS
	v_SP_ID NUMBER(9);
    BEGIN
	    ID.ID_FOR_SERVICE_POINT(p_SERVICE_POINT_NAME, FALSE, v_SP_ID);
	    IF v_SP_ID <= 0 THEN
		    IO.PUT_SERVICE_POINT(o_OID => v_SP_ID,
				    p_SERVICE_POINT_NAME      => p_SERVICE_POINT_NAME,
				    p_SERVICE_POINT_ALIAS     => p_SERVICE_POINT_NAME,
				    p_SERVICE_POINT_DESC      => 'Created by Market Manager via ERCOT_Service_Point script',
				    p_SERVICE_POINT_ID        => 0,
				    p_SERVICE_POINT_TYPE      => 'Wholesale',
				    p_TP_ID                   => 0,
				    p_CA_ID                   => 0,
				    p_EDC_ID                  => 0,
				    p_ROLLUP_ID               => 0,
				    p_SERVICE_REGION_ID       => 0,
				    p_SERVICE_AREA_ID         => 0,
				    p_SERVICE_ZONE_ID         => 0,
				    p_TIME_ZONE               => 0,
				    p_LATITUDE                => NULL,
				    p_LONGITUDE               => NULL,
				    p_EXTERNAL_IDENTIFIER     => p_EXTERNAL_IDENTIFIER,
				    p_IS_INTERCONNECT         => 0,
				    p_NODE_TYPE               => p_NODE_TYPE,
				    p_SERVICE_POINT_NERC_CODE => NULL,
				    p_PIPELINE_ID => 0,
      				p_MILE_MARKER => 0);
	    END IF;
        EXCEPTION WHEN OTHERS THEN 
		NULL;
	END CREATE_SERVICE_POINT;
BEGIN
    --Service Points for Markewt Clearing Price for Energy
    CREATE_SERVICE_POINT('South','S','Zone');
    CREATE_SERVICE_POINT('North','N', 'Zone');
    CREATE_SERVICE_POINT('Houston','H', 'Zone');
    CREATE_SERVICE_POINT('West','W', 'Zone');
    CREATE_SERVICE_POINT('Northeast','E', 'Zone');
    
    --Service Points for Shadow Clearing Price for Balancing Energy
    CREATE_SERVICE_POINT('West to North','WN','Interface');
    CREATE_SERVICE_POINT('South to North','SN','Interface');
    CREATE_SERVICE_POINT('South to Houston','SH','Interface');
    CREATE_SERVICE_POINT('North to Houston','NH','Interface');
    CREATE_SERVICE_POINT('Northest to North','EN','Interface');
    CREATE_SERVICE_POINT('North to West','NW','Interface');
    CREATE_SERVICE_POINT('North to South','NS','Interface');
    
    COMMIT;
END;
/
