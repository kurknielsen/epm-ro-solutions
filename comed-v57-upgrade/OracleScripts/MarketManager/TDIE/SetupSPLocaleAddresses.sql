-- This script is to add the locale address to the NI Jurisdiction and ROI Jurisdiction Service Points
-- It resolves [BZ 30623], where the VAT calculation will not work without the Locale Address being set
-- for these Service Points

-- Note that this script assumes that the Service Points already exist. If they do not exist,
-- it means that you need to import the ROML files first. The required Service Points will 
-- come as part of the ROML import.

 


DECLARE 

-- Procedure to add a Locale Address to an Existing Service Point
PROCEDURE ADD_LOCALE_ADDRESS(p_SP_NAME IN VARCHAR2,
                     p_CAT_NAME IN VARCHAR2,
                     p_GEO_NAME IN VARCHAR2) IS
                     
     v_SP_ID NUMBER;
     v_CAT_ID NUMBER;
     v_GEO_ID NUMBER;
     BEGIN
              v_SP_ID := EI.GET_ID_FROM_NAME(P_SP_NAME,EC.ED_SERVICE_POINT);
              v_CAT_ID := EI.GET_ID_FROM_NAME(p_CAT_NAME,EC.ED_CATEGORY);
              v_GEO_ID := EI.GET_ID_FROM_NAME(P_GEO_NAME,EC.ED_GEOGRAPHY);
              INSERT INTO ENTITY_DOMAIN_ADDRESS VALUES(EC.ED_SERVICE_POINT,v_SP_ID,v_CAT_ID,NULL,NULL,v_GEO_ID,SYSDATE); 
     END;
begin
     ADD_LOCALE_ADDRESS('NI Jurisdiction','Locale','NI');
     ADD_LOCALE_ADDRESS('ROI Jurisdiction','Locale','ROI');  
  
end;
/